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
extension DBMongoQuery {
    
    public func withSession<T>(
        options: ClientSessionOptions? = nil,
        _ sessionBody: @escaping (ClientSession) async throws -> T
    ) async throws -> T {
        
        let promise = self.eventLoopGroup.next().makePromise(of: T.self)
        
        return try await self.withSession(options: options, { session in
            
            promise.completeWithTask { try await sessionBody(session) }
            
            return promise.futureResult
            
        }).get()
    }
    
    public func withTransaction<T>(
        options: ClientSessionOptions? = nil,
        _ transactionBody: @escaping (ClientSession) async throws -> T
    ) async throws -> T {
        
        let promise = self.eventLoopGroup.next().makePromise(of: T.self)
        
        return try await self.withTransaction(options: options, { session in
            
            promise.completeWithTask { try await transactionBody(session) }
            
            return promise.futureResult
            
        }).get()
    }
}

#endif
