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

extension DBMongoQuery {
    
    public func withTransaction<T>(
        options: ClientSessionOptions? = nil,
        _ transactionBody: (DBMongoQuery) async throws -> T
    ) async throws -> T {
        
        if let session = self.session {
            return try await session.withTransaction { try await transactionBody(self) }
        }
        
        return try await connection.withSession(options: options) { connection in
            let query = connection.mongoQuery()
            return try await connection.session.withTransaction { try await transactionBody(query) }
        }
    }
}

extension DBConnection {
    
    public func withMongoSession<T>(
        options: ClientSessionOptions?,
        _ sessionBody: (DBConnection) async throws -> T
    ) async throws -> T {
        guard let connection = self as? DBMongoConnectionProtocol else { fatalError("unsupported operation") }
        return try await connection.withSession(options: options, sessionBody)
    }
}

extension DBMongoConnectionProtocol {
    
    public func withTransaction<T>(
        _ transactionBody: (DBConnection) async throws -> T
    ) async throws -> T {
        
        return try await self.withMongoSession(options: nil) { connection in
            
            guard let connection = connection as? SessionBoundConnection else { fatalError("unknown error") }
            
            return try await connection.session.withTransaction { try await transactionBody(connection) }
        }
    }
}

#endif
