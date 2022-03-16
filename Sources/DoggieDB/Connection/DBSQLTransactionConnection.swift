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

actor DBSQLTransactionConnection: DBSQLConnection {
    
    let base: DBSQLConnection
    
    let counter: Int
    
    init(base: DBSQLConnection, counter: Int) {
        self.base = base
        self.counter = counter
    }
}

extension DBSQLTransactionConnection {
    
    nonisolated var driver: DBDriver {
        return base.driver
    }
    
    nonisolated var logger: Logger {
        return base.logger
    }
    
    nonisolated var eventLoopGroup: EventLoopGroup {
        return base.eventLoopGroup
    }
}

extension DBSQLTransactionConnection {
    
    var columnInfoHook: ((DBSQLConnection, String) async throws -> [DBSQLColumnInfo])? {
        get async {
            return await base.columnInfoHook
        }
    }
    
    func setColumnInfoHook(_ hook: ((DBSQLConnection, String) async throws -> [DBSQLColumnInfo])?) async {
        await base.setColumnInfoHook(hook)
    }
    
    var primaryKeyHook: ((DBSQLConnection, String) async throws -> [String])? {
        get async {
            return await base.primaryKeyHook
        }
    }
    
    func setPrimaryKeyHook(_ hook: ((DBSQLConnection, String) async throws -> [String])?) async {
        await base.setPrimaryKeyHook(hook)
    }
}

extension DBSQLTransactionConnection {
    
    func close() async throws {
        try await base.close()
    }
}

extension DBSQLTransactionConnection {
    
    func version() async throws -> String {
        return try await base.version()
    }
    
    func databases() async throws -> [String] {
        return try await base.databases()
    }
    
    func tables() async throws -> [String] {
        return try await base.tables()
    }
    
    func views() async throws -> [String] {
        return try await base.views()
    }
    
    func materializedViews() async throws -> [String] {
        return try await base.materializedViews()
    }
    
    func columns(of table: String) async throws -> [DBSQLColumnInfo] {
        return try await base.columns(of: table)
    }
    
    func primaryKey(of table: String) async throws -> [String] {
        return try await base.primaryKey(of: table)
    }
    
    func indices(of table: String) async throws -> [[String: DBData]] {
        return try await base.indices(of: table)
    }
    
    func foreignKeys(of table: String) async throws -> [[String: DBData]] {
        return try await base.foreignKeys(of: table)
    }
}

extension DBSQLTransactionConnection {
    
    func startTransaction() async throws {
        try await base.startTransaction()
    }
    
    func commitTransaction() async throws {
        try await base.commitTransaction()
    }
    
    func abortTransaction() async throws {
        try await base.abortTransaction()
    }
    
    func createSavepoint(_ name: String) async throws {
        try await base.createSavepoint(name)
    }
    
    func rollbackToSavepoint(_ name: String) async throws {
        try await base.rollbackToSavepoint(name)
    }
    
    func releaseSavepoint(_ name: String) async throws {
        try await base.releaseSavepoint(name)
    }
    
}

extension DBSQLTransactionConnection {
    
    func execute(
        _ sql: SQLRaw
    ) async throws -> [[String: DBData]] {
        
        return try await base.execute(sql)
    }
    
    func execute(
        _ sql: SQLRaw,
        onRow: @escaping ([String: DBData]) throws -> Void
    ) async throws -> SQLQueryMetadata {
        
        return try await base.execute(sql, onRow: onRow)
    }
}

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
