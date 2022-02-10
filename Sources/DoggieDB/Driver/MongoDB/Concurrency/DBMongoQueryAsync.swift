//
//  DBMongoQueryAsync.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2022 Susan Cheng. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import MongoSwift

#if compiler(>=5.5.2) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension ClientSession {
    
    public func withTransaction<T>(
        _ transactionBody: () async throws -> T
    ) async throws -> T {
        
        try await self.startTransaction().get()
        
        do {
            
            let result = try await transactionBody()
            
            try await self.commitTransaction().get()
            
            return result
            
        } catch {
            
            try await self.abortTransaction().get()
            
            throw error
        }
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension DBMongoQuery {
    
    public func withSession<T>(
        options: ClientSessionOptions? = nil,
        _ sessionBody: (DBMongoQuery) async throws -> T
    ) async throws -> T {
        
        let session = self.connection.startSession(options: options)
        
        do {
            
            var query = self
            query.session = session
            
            let result = try await sessionBody(query)
            
            try await session.end().get()
            
            return result
            
        } catch {
            
            try await session.end().get()
            
            throw error
        }
    }
    
    public func withTransaction<T>(
        options: ClientSessionOptions? = nil,
        _ transactionBody: (DBMongoQuery) async throws -> T
    ) async throws -> T {
        
        if let session = self.session {
            return try await session.withTransaction { try await transactionBody(self) }
        }
        
        return try await self.withSession(options: options) { query in
            guard let session = query.session else { throw Database.Error.unknown }
            return try await session.withTransaction { try await transactionBody(query) }
        }
    }
}

#endif
