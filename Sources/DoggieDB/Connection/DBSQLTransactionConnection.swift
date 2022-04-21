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

final class DBSQLTransactionConnection: DBSQLConnection {
    
    let base: DBSQLConnection
    
    let counter: Int
    
    let _runloop = SerialRunLoop()
    
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
}

extension DBSQLTransactionConnection {
    
    var hooks: DBSQLConnectionHooks {
        return base.hooks
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
    
    func size(of table: String) async throws -> DBSQLTableStats {
        return try await base.size(of: table)
    }
}

extension DBSQLTransactionConnection {
    
    func startTransaction(_ mode: DBTransactionOptions.Mode) async throws {
        try await base.startTransaction(mode)
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
        _ options: DBTransactionOptions,
        @UnsafeSendable _ transactionBody: @escaping (DBConnection) async throws -> T
    ) async throws -> T {
        
        let base = self.base
        let counter = self.counter
        
        guard !_runloop.inRunloop else { throw Database.Error.transactionDeadlocks }
        
        let wrapped: UnsafeSendable<T> = try await _runloop.perform {
            
            try await base.createSavepoint("savepoint_\(counter)")
            
            do {
                
                let result = try await $transactionBody.wrappedValue(DBSQLTransactionConnection(base: base, counter: counter + 1))
                
                try await base.releaseSavepoint("savepoint_\(counter)")
                
                return UnsafeSendable(wrappedValue: result)
                
            } catch {
                
                try await base.rollbackToSavepoint("savepoint_\(counter)")
                
                throw error
            }
        }
        
        return wrapped.wrappedValue
    }
}
