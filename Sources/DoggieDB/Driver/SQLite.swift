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

struct SQLiteDriver {
    
}

extension SQLiteDriver {
    
    class Connection: DatabaseConnection {
        
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
    
    static func create(
        storage: SQLiteConnection.Storage,
        logger: Logger,
        threadPool: NIOThreadPool,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<DatabaseConnection> {
        
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
    
    func query(
        _ string: String,
        _ binds: [SQLiteData]
    ) -> EventLoopFuture<[QueryRow]> {
        return self.connection.query(string, binds).map{ $0.map(QueryRow.init) }
    }
    
    func query(
        _ string: String,
        _ binds: [SQLiteData],
        onRow: @escaping (QueryRow) -> ()
    ) -> EventLoopFuture<QueryMetadata> {
        return self.connection.query(string, binds, { onRow(QueryRow($0)) }).map { QueryMetadata(metadata: [:]) }
    }
}

extension SQLiteRow: QueryRowConvertable {
    
    public var count: Int {
        return self.columns.count
    }
    
    public var allColumns: [String] {
        return self.columns.map { $0.name }
    }
    
    public func contains(column: String) -> Bool {
        return self.columns.contains { $0.name == column }
    }
    
    public func value(_ column: String) -> QueryData? {
        return self.column(column).map(QueryData.init)
    }
}

extension SQLiteData: QueryDataConvertable {
    
}
