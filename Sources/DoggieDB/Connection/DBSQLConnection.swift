//
//  DBSQLConnection.swift
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
    
    func indices(of table: String) -> EventLoopFuture<[[String: DBData]]>
    
    func foreignKeys(of table: String) -> EventLoopFuture<[[String: DBData]]>
    
    func startTransaction() -> EventLoopFuture<Void>
    
    func commitTransaction() -> EventLoopFuture<Void>
    
    func abortTransaction() -> EventLoopFuture<Void>
    
    func createSavepoint(_ name: String) -> EventLoopFuture<Void>
    
    func rollbackToSavepoint(_ name: String) -> EventLoopFuture<Void>
    
    func releaseSavepoint(_ name: String) -> EventLoopFuture<Void>
    
    func execute(
        _ sql: SQLRaw
    ) -> EventLoopFuture<[[String: DBData]]>
    
    func execute(
        _ sql: SQLRaw,
        onRow: @escaping ([String: DBData]) throws -> Void
    ) -> EventLoopFuture<SQLQueryMetadata>
}

extension DBSQLConnection {
    
    public func execute(
        _ sql: SQLRaw
    ) -> EventLoopFuture<[[String: DBData]]> {
        return eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
    }
    
    public func execute(
        _ sql: SQLRaw,
        onRow: @escaping ([String: DBData]) throws -> Void
    ) -> EventLoopFuture<SQLQueryMetadata> {
        return eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
    }
}

extension DBSQLConnection {
    
    public func withTransaction<T>(
        _ transactionBody: @escaping (DBConnection) throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        
        let transaction = self.startTransaction()
        let promise = transaction.eventLoop.makePromise(of: T.self)
        
        return transaction.flatMap {
            
            do {
                
                let bodyFuture = try transactionBody(DBSQLTransactionConnection(base: self, counter: 0))
                
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

#if compiler(>=5.5.2) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension DBSQLConnection {
    
    public func withTransaction<T>(
        _ transactionBody: (DBConnection) async throws -> T
    ) async throws -> T {
        
        try await self.startTransaction()
        
        do {
            
            let result = try await transactionBody(self)
            
            try await self.commitTransaction()
            
            return result
            
        } catch {
            
            try await self.abortTransaction()
            
            throw error
        }
    }
}

#endif
