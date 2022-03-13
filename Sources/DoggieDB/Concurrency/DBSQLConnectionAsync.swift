//
//  DBSQLConnectionAsync.swift
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

#if compiler(>=5.5.2) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension DBSQLConnection {
    
    public func tables() async throws -> [String] {
        return try await self.tables().get()
    }
    
    public func views() async throws -> [String] {
        return try await self.views().get()
    }
    
    public func materializedViews() async throws -> [String] {
        return try await self.materializedViews().get()
    }
    
    public func columns(of table: String) async throws -> [DBSQLColumnInfo] {
        return try await self.columns(of: table).get()
    }
    
    public func primaryKey(of table: String) async throws -> [String] {
        return try await self.primaryKey(of: table).get()
    }
    
    public func indices(of table: String) async throws -> [[String: DBData]] {
        return try await self.indices(of: table).get()
    }
    
    public func foreignKeys(of table: String) async throws -> [[String: DBData]] {
        return try await self.foreignKeys(of: table).get()
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension DBSQLConnection {
    
    public func startTransaction() async throws {
        try await self.startTransaction().get()
    }
    
    public func commitTransaction() async throws {
        try await self.commitTransaction().get()
    }
    
    public func abortTransaction() async throws {
        try await self.abortTransaction().get()
    }
    
    public func createSavepoint(_ name: String) async throws {
        try await self.createSavepoint(name).get()
    }
    
    public func rollbackToSavepoint(_ name: String) async throws {
        try await self.rollbackToSavepoint(name).get()
    }
    
    public func releaseSavepoint(_ name: String) async throws {
        try await self.releaseSavepoint(name).get()
    }
    
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension DBSQLConnection {
    
    public func execute(
        _ sql: SQLRaw
    ) async throws -> [[String: DBData]] {
        return try await self.execute(sql).get()
    }
    
    @discardableResult
    public func execute(
        _ sql: SQLRaw,
        onRow: @escaping ([String: DBData]) throws -> Void
    ) async throws -> SQLQueryMetadata {
        return try await self.execute(sql, onRow: onRow).get()
    }
    
    public func execute(
        _ sql: SQLRaw
    ) -> AsyncThrowingStream<[String: DBData], Error> {
        
        return AsyncThrowingStream { continuation in
            
            self.execute(sql) { continuation.yield($0) }.whenComplete { result in
                switch result {
                case .success: continuation.finish()
                case let .failure(error): continuation.finish(throwing: error)
                }
            }
        }
    }
}

#endif
