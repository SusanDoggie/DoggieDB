//
//  DBMongoQuery.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2021 Susan Cheng. All rights reserved.
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
    
    let connection: DBMongoConnection
}

extension DBMongoQuery {
    
    var session: ClientSession? {
        return connection.session
    }
    
    public var eventLoopGroup: EventLoopGroup {
        return connection.eventLoopGroup
    }
}

extension DBMongoConnection {
    
    public func mongoQuery() -> DBMongoQuery {
        return DBMongoQuery(connection: self)
    }
}

extension ClientSession {
    
    public func withTransaction<T>(
        options: ClientSessionOptions? = nil,
        _ transactionBody: @escaping () throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        
        let transaction = self.startTransaction()
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
    
    public func withTransaction<T>(
        _ transactionBody: @escaping (DBMongoQuery) throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        guard let session = self.session else { fatalError("session not available.") }
        return session.withTransaction { try transactionBody(self) }
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
