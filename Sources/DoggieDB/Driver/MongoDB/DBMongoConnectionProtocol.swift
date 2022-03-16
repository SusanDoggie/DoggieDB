//
//  DBMongoConnectionProtocol.swift
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

protocol DBMongoConnectionProtocol: DBConnection {
    
    var database: String? { get }
    
    func _database() -> MongoDatabase?
    
    func _bind(to eventLoop: EventLoop) -> DBMongoConnectionProtocol
    
    func withSession<T>(
        options: ClientSessionOptions?,
        _ sessionBody: (SessionBoundConnection) throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T>
    
    #if compiler(>=5.5.2) && canImport(_Concurrency)
    
    func withSession<T>(
        options: ClientSessionOptions?,
        _ sessionBody: (SessionBoundConnection) async throws -> T
    ) async throws -> T
    
    #endif
}

extension DBMongoConnectionProtocol {
    
    func bind(to eventLoop: EventLoop) -> DBConnection {
        return self._bind(to: eventLoop)
    }
}

extension ClientSession {
    
    public func withTransaction<T>(
        options: TransactionOptions? = nil,
        _ transactionBody: @escaping () throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        
        let transaction = self.startTransaction(options: options)
        let promise = transaction.eventLoop.makePromise(of: T.self)
        
        return transaction.flatMap {
            
            do {
                
                let bodyFuture = try transactionBody()
                
                bodyFuture.flatMap { _ in
                    self.commitTransaction()
                }.flatMapError { _ in
                    self.abortTransaction()
                }.whenComplete { _ in
                    promise.completeWith(bodyFuture)
                }
                
            } catch {
                
                self.abortTransaction().whenComplete { _ in
                    promise.fail(error)
                }
            }
            
            return promise.futureResult
        }
    }
}

extension DBMongoConnectionProtocol {
    
    public func withTransaction<T>(
        _ transactionBody: @escaping (DBConnection) throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        
        if let connection = self as? SessionBoundConnection {
            return connection.session.withTransaction { try transactionBody(connection) }
        }
        
        return self.withSession(options: nil) { connection in
            return connection.session.withTransaction { try transactionBody(connection) }
        }
    }
}
