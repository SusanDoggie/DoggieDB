//
//  SQLite.swift
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

import SQLiteNIO

struct SQLiteDriver: DBDriverProtocol {
    
    static var defaultPort: Int { 0 }
}

extension SQLiteDriver {
    
    class Connection: DBConnection {
        
        var driver: DBDriver { return .sqlite }
        
        let connection: SQLiteConnection
        
        var eventLoop: EventLoop { connection.eventLoop }
        
        init(_ connection: SQLiteConnection) {
            self.connection = connection
        }
        
        func close() -> EventLoopFuture<Void> {
            return connection.close()
        }
    }
}

extension SQLiteDriver {
    
    static func connect(config: Database.Configuration, logger: Logger, on eventLoop: EventLoop) -> EventLoopFuture<DBConnection> {
        fatalError()
    }
    
    static func create(
        storage: SQLiteConnection.Storage,
        logger: Logger,
        threadPool: NIOThreadPool,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<DBConnection> {
        
        let connection = SQLiteConnection.open(
            storage: storage,
            threadPool: threadPool,
            logger: logger,
            on: eventLoop
        )
        
        return connection.map(Connection.init)
    }
}

extension SQLiteDriver.Connection {
    
    var isClosed: Bool {
        return self.connection.isClosed
    }
}

extension SQLiteDriver.Connection {
    
    func version() -> EventLoopFuture<String> {
        return self.query("SELECT sqlite_version();", []).map { $0[0]["sqlite_version()"]!.string! }
    }
    
    func tables() -> EventLoopFuture<[String]> {
        return self.query("SELECT name FROM sqlite_master WHERE type = 'table';", []).map { $0.map { $0["name"]!.string! } }
    }
    
    func views() -> EventLoopFuture<[String]> {
        return self.query("SELECT name FROM sqlite_master WHERE type = 'view';", []).map { $0.map { $0["name"]!.string! } }
    }
    
    func tableInfo(_ table: String) -> EventLoopFuture<[DBQueryRow]> {
        return self.query("pragma table_info(\(table));", [])
    }
}

extension SQLiteDriver.Connection {
    
    func lastAutoincrementID() -> EventLoopFuture<Int> {
        return self.connection.lastAutoincrementID()
    }
    
    func query(
        _ string: String,
        _ binds: [DBData]
    ) -> EventLoopFuture<[DBQueryRow]> {
        
        do {
            
            let binds = try binds.map(SQLiteData.init)
            
            return self.connection.query(string, binds).map{ $0.map(DBQueryRow.init) }
            
        } catch let error {
            
            return eventLoop.makeFailedFuture(error)
        }
    }
    
    func query(
        _ string: String,
        _ binds: [DBData],
        onRow: @escaping (DBQueryRow) -> Void
    ) -> EventLoopFuture<DBQueryMetadata> {
        
        do {
            
            let binds = try binds.map(SQLiteData.init)
            
            return self.connection.query(string, binds, { onRow(DBQueryRow($0)) }).map { DBQueryMetadata(metadata: [:]) }
            
        } catch let error {
            
            return eventLoop.makeFailedFuture(error)
        }
    }
}

extension SQLiteRow: DBRowConvertable {
    
    @inlinable
    public var count: Int {
        return self.columns.count
    }
    
    @inlinable
    public var keys: [String] {
        return self.columns.map { $0.name }
    }
    
    @inlinable
    public func contains(column: String) -> Bool {
        return self.columns.contains { $0.name == column }
    }
    
    public func value(_ column: String) -> DBData? {
        return self.column(column).map(DBData.init)
    }
}
