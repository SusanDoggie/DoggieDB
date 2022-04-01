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

public struct DBSQLTableStats {
    
    public var table: Int
    
    public var indexes: Int
    
    public var total: Int
    
}

public actor DBSQLConnectionHooks {
    
    var columnInfoHook: ((DBSQLConnection, String) async throws -> [DBSQLColumnInfo])?
    
    var primaryKeyHook: ((DBSQLConnection, String) async throws -> [String])?
    
}

extension DBSQLConnectionHooks {
    
    public func setColumnInfoHook(_ hook: ((DBSQLConnection, String) async throws -> [DBSQLColumnInfo])?) {
        self.columnInfoHook = hook
    }
    
    public func setPrimaryKeyHook(_ hook: ((DBSQLConnection, String) async throws -> [String])?) {
        self.primaryKeyHook = hook
    }
}

public protocol DBSQLConnection: DBConnection {
    
    var hooks: DBSQLConnectionHooks { get }
    
    var _runloop: SerialRunLoop { get }
    
    func tables() async throws -> [String]
    
    func views() async throws -> [String]
    
    func materializedViews() async throws -> [String]
    
    func columns(of table: String) async throws -> [DBSQLColumnInfo]
    
    func primaryKey(of table: String) async throws -> [String]
    
    func indices(of table: String) async throws -> [[String: DBData]]
    
    func foreignKeys(of table: String) async throws -> [[String: DBData]]
    
    func size(of table: String) async throws -> DBSQLTableStats
    
    func startTransaction() async throws
    
    func commitTransaction() async throws
    
    func abortTransaction() async throws
    
    func createSavepoint(_ name: String) async throws
    
    func rollbackToSavepoint(_ name: String) async throws
    
    func releaseSavepoint(_ name: String) async throws
    
    @discardableResult
    func execute(
        _ sql: SQLRaw
    ) async throws -> [[String: DBData]]
    
    @discardableResult
    func execute(
        _ sql: SQLRaw,
        onRow: @escaping ([String: DBData]) throws -> Void
    ) async throws -> SQLQueryMetadata
}

extension DBSQLConnection {
    
    @discardableResult
    public func execute(
        _ sql: SQLRaw
    ) async throws -> [[String: DBData]] {
        throw Database.Error.unsupportedOperation
    }
    
    @discardableResult
    public func execute(
        _ sql: SQLRaw,
        onRow: @escaping ([String: DBData]) throws -> Void
    ) async throws -> SQLQueryMetadata {
        throw Database.Error.unsupportedOperation
    }
}

extension DBSQLConnection {
    
    public func execute(
        _ sql: SQLRaw
    ) -> AsyncThrowingStream<[String: DBData], Error> {
        
        return AsyncThrowingStream { continuation in
            
            Task {
                
                do {
                    
                    try await self.execute(sql) { continuation.yield($0) }
                    
                    continuation.finish()
                    
                } catch {
                    
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

extension DBSQLConnection {
    
    public func withTransaction<T>(
        _ transactionBody: @escaping (DBConnection) async throws -> T
    ) async throws -> T {
        
        guard !_runloop.inRunloop else { throw Database.Error.transactionDeadlocks }
        
        return try await _runloop.perform {
            
            try await self.startTransaction()
            
            do {
                
                let result = try await transactionBody(DBSQLTransactionConnection(base: self, counter: 0))
                
                try await self.commitTransaction()
                
                return result
                
            } catch {
                
                try await self.abortTransaction()
                
                throw error
            }
        }
    }
}
