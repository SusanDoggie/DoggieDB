//
//  DBMongoQuery.swift
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

public struct DBMongoQuery {
    
    let connection: DBMongoConnectionProtocol
    
    var session: ClientSession?
}

extension DBMongoQuery {
    
    public var eventLoopGroup: EventLoopGroup {
        return connection.eventLoopGroup
    }
}

extension DBConnection {
    
    public func mongoQuery() -> DBMongoQuery {
        guard let connection = self as? DBMongoConnectionProtocol else { fatalError("unsupported operation") }
        return DBMongoQuery(connection: connection, session: nil)
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

extension DBMongoQuery {
    
    public func runCommand(_ command: BSONDocument, options: RunCommandOptions? = nil) -> EventLoopFuture<BSONDocument> {
        guard let database = connection._database() else { fatalError("database not selected.") }
        return database.runCommand(command, options: options, session: session)
    }
}

extension DBMongoQuery {
    
    public func startSession(options: ClientSessionOptions? = nil) -> ClientSession {
        return connection.startSession(options: options)
    }
    
    public func session(_ session: ClientSession) -> Self {
        var result = self
        result.session = session
        return result
    }
    
    public func withSession<T>(
        options: ClientSessionOptions? = nil,
        _ sessionBody: (ClientSession) throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        return connection.withSession(options: options, sessionBody)
    }
    
    public func withTransaction<T>(
        options: ClientSessionOptions? = nil,
        _ transactionBody: @escaping (ClientSession) throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        
        return connection.withSession(options: options) { session in
            session.withTransaction { try transactionBody(session) }
        }
    }
}

extension DBMongoQuery {
    
    public func collection(_ name: String) -> DBMongoCollectionExpression<BSONDocument> {
        guard let database = connection._database() else { fatalError("database not selected.") }
        return DBMongoCollectionExpression(connection: connection, database: database, session: session, name: name)
    }
    
    public func createCollection(_ name: String) -> DBMongoCreateCollectionExpression<BSONDocument> {
        guard let database = connection._database() else { fatalError("database not selected.") }
        return DBMongoCreateCollectionExpression(connection: connection, database: database, session: session, name: name)
    }
    
    public func collections() -> DBMongoListCollectionsExpression<BSONDocument> {
        guard let database = connection._database() else { fatalError("database not selected.") }
        return DBMongoListCollectionsExpression(connection: connection, database: database, session: session)
    }
}
