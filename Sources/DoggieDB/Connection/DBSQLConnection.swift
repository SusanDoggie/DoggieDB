//
//  DBSQLConnection.swift
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

public struct DBSQLColumnInfo {
    
    public var name: String
    
    public var type: String
    
    public var isOptional: Bool
    
    public init(
        name: String,
        type: String,
        isOptional: Bool
    ) {
        self.name = name
        self.type = type
        self.isOptional = isOptional
    }
}

public protocol DBSQLConnection: DBConnection {
    
    var columnInfoHook: ((DBSQLConnection, String) -> EventLoopFuture<[DBSQLColumnInfo]>)? { get set }
    
    var primaryKeyHook: ((DBSQLConnection, String) -> EventLoopFuture<[String]>)? { get set }
    
    func tables() -> EventLoopFuture<[String]>
    
    func views() -> EventLoopFuture<[String]>
    
    func materializedViews() -> EventLoopFuture<[String]>
    
    func columns(of table: String) -> EventLoopFuture<[DBSQLColumnInfo]>
    
    func primaryKey(of table: String) -> EventLoopFuture<[String]>
    
    func indices(of table: String) -> EventLoopFuture<[SQLQueryRow]>
    
    func foreignKeys(of table: String) -> EventLoopFuture<[SQLQueryRow]>
    
    func startTransaction() -> EventLoopFuture<Void>
    
    func commitTransaction() -> EventLoopFuture<Void>
    
    func abortTransaction() -> EventLoopFuture<Void>
    
    func execute(
        _ sql: SQLRaw
    ) -> EventLoopFuture<[SQLQueryRow]>
    
    func execute(
        _ sql: SQLRaw,
        onRow: @escaping (SQLQueryRow) throws -> Void
    ) -> EventLoopFuture<SQLQueryMetadata>
}

extension DBSQLConnection {
    
    public func execute(
        _ sql: SQLRaw
    ) -> EventLoopFuture<[SQLQueryRow]> {
        return eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
    }
    
    public func execute(
        _ sql: SQLRaw,
        onRow: @escaping (SQLQueryRow) throws -> Void
    ) -> EventLoopFuture<SQLQueryMetadata> {
        return eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
    }
}

extension DBSQLConnection {
    
    public func withTransaction<T>(
        _ transactionBody: @escaping (DBSQLConnection) throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        
        let transaction = self.startTransaction()
        let promise = transaction.eventLoop.makePromise(of: T.self)
        
        return transaction.flatMap {
            
            do {
                
                let bodyFuture = try transactionBody(self)
                
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
