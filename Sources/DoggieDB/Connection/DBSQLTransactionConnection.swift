//
//  DBSQLTransactionConnection.swift
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

class DBSQLTransactionConnection: DBSQLConnection {
    
    let base: DBSQLConnection
    
    let counter: Int
    
    init(base: DBSQLConnection, counter: Int) {
        self.base = base
        self.counter = counter
    }
}

extension DBSQLTransactionConnection {
    
    var driver: DBDriver {
        return base.driver
    }
    
    var logger: Logger {
        return base.logger
    }
    
    var eventLoopGroup: EventLoopGroup {
        return base.eventLoopGroup
    }
    
    var isClosed: Bool {
        return base.isClosed
    }
}

extension DBSQLTransactionConnection {
    
    var columnInfoHook: ((DBSQLConnection, String) -> EventLoopFuture<[DBSQLColumnInfo]>)? {
        get {
            return base.columnInfoHook
        }
        set {
            base.columnInfoHook = newValue
        }
    }
    
    var primaryKeyHook: ((DBSQLConnection, String) -> EventLoopFuture<[String]>)? {
        get {
            return base.primaryKeyHook
        }
        set {
            base.primaryKeyHook = newValue
        }
    }
}

extension DBSQLTransactionConnection {
    
    func close() -> EventLoopFuture<Void> {
        return base.close()
    }
}

extension DBSQLTransactionConnection {
    
    func version() -> EventLoopFuture<String> {
        return base.version()
    }
    
    func databases() -> EventLoopFuture<[String]> {
        return base.databases()
    }
    
    func tables() -> EventLoopFuture<[String]> {
        return base.tables()
    }
    
    func views() -> EventLoopFuture<[String]> {
        return base.views()
    }
    
    func materializedViews() -> EventLoopFuture<[String]> {
        return base.materializedViews()
    }
    
    func columns(of table: String) -> EventLoopFuture<[DBSQLColumnInfo]> {
        return base.columns(of: table)
    }
    
    func primaryKey(of table: String) -> EventLoopFuture<[String]> {
        return base.primaryKey(of: table)
    }
    
    func indices(of table: String) -> EventLoopFuture<[[String: DBData]]> {
        return base.indices(of: table)
    }
    
    func foreignKeys(of table: String) -> EventLoopFuture<[[String: DBData]]> {
        return base.foreignKeys(of: table)
    }
}

extension DBSQLTransactionConnection {
    
    func startTransaction() -> EventLoopFuture<Void> {
        return base.startTransaction()
    }
    
    func commitTransaction() -> EventLoopFuture<Void> {
        return base.commitTransaction()
    }
    
    func abortTransaction() -> EventLoopFuture<Void> {
        return base.abortTransaction()
    }
    
    func createSavepoint(_ name: String) -> EventLoopFuture<Void> {
        return base.createSavepoint(name)
    }
    
    func rollbackToSavepoint(_ name: String) -> EventLoopFuture<Void> {
        return base.rollbackToSavepoint(name)
    }
    
    func releaseSavepoint(_ name: String) -> EventLoopFuture<Void> {
        return base.releaseSavepoint(name)
    }
    
}

extension DBSQLTransactionConnection {
    
    func execute(
        _ sql: SQLRaw
    ) -> EventLoopFuture<[[String: DBData]]> {
        
        return base.execute(sql)
    }
    
    func execute(
        _ sql: SQLRaw,
        onRow: @escaping ([String: DBData]) throws -> Void
    ) -> EventLoopFuture<SQLQueryMetadata> {
        
        return base.execute(sql, onRow: onRow)
    }
}

extension DBSQLTransactionConnection {
    
    func withTransaction<T>(
        _ transactionBody: @escaping (DBConnection) throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        
        let counter = self.counter
        
        let transaction = self.base.createSavepoint("savepoint_\(counter)")
        let promise = transaction.eventLoop.makePromise(of: T.self)
        
        return transaction.flatMap {
            
            do {
                
                let bodyFuture = try transactionBody(DBSQLTransactionConnection(base: self.base, counter: counter + 1))
                
                bodyFuture.flatMap { _ in
                    self.base.releaseSavepoint("savepoint_\(counter)")
                }.flatMapError { _ in
                    self.base.rollbackToSavepoint("savepoint_\(counter)")
                }.whenComplete { _ in
                    promise.completeWith(bodyFuture)
                }
                
            } catch {
                
                self.base.rollbackToSavepoint("savepoint_\(counter)").whenComplete { _ in
                    promise.fail(error)
                }
            }
            
            return promise.futureResult
        }
    }
}

#if compiler(>=5.5.2) && canImport(_Concurrency)

extension DBSQLTransactionConnection {
    
    func withTransaction<T>(
        _ transactionBody: (DBConnection) async throws -> T
    ) async throws -> T {
        
        try await self.base.createSavepoint("savepoint_\(counter)")
        
        do {
            
            let result = try await transactionBody(DBSQLTransactionConnection(base: self.base, counter: counter + 1))
            
            try await self.base.releaseSavepoint("savepoint_\(counter)")
            
            return result
            
        } catch {
            
            try await self.base.rollbackToSavepoint("savepoint_\(counter)")
            
            throw error
        }
    }
}

#endif
