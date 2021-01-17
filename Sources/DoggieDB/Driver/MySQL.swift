//
//  MySQL.swift
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

import MySQLNIO

struct MySQLDriver: DatabaseDriverProtocol {
    
    static var defaultPort: Int { 3306 }
}

extension MySQLDriver {
    
    class Connection: SQLDatabaseConnection {
        
        let connection: MySQLConnection
        
        var eventLoop: EventLoop { connection.eventLoop }
        
        init(_ connection: MySQLConnection) {
            self.connection = connection
        }
        
        func close() -> EventLoopFuture<Void> {
            return connection.close()
        }
    }
}

extension MySQLDriver {
    
    static func connect(
        config: Database.Configuration,
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<DatabaseConnection> {
        
        guard let username = config.username else {
            return eventLoop.makeFailedFuture(Database.Error.invalidConfiguration(message: "username is missing."))
        }
        
        let connection = MySQLConnection.connect(
            to: config.socketAddress,
            username: username,
            database: config.database ?? username,
            password: config.password,
            tlsConfiguration: config.tlsConfiguration,
            logger: logger,
            on: eventLoop
        )
        
        return connection.map(Connection.init)
    }
}

extension MySQLDriver.Connection {
    
    func _query(
        _ string: String,
        _ binds: [MySQLData]
    ) -> EventLoopFuture<[QueryRow]> {
        if binds.isEmpty {
            return self.connection.simpleQuery(string).map{ $0.map(QueryRow.init) }
        }
        return self.connection.query(string, binds).map{ $0.map(QueryRow.init) }
    }
    
    func _query(
        _ string: String,
        _ binds: [MySQLData],
        onRow: @escaping (QueryRow) throws -> Void
    ) -> EventLoopFuture<QueryMetadata> {
        var metadata: MySQLQueryMetadata?
        
        return self.connection.query(
            string,
            binds,
            onRow: { try onRow(QueryRow($0)) },
            onMetadata: { metadata = $0 }
        ).map { metadata.map(QueryMetadata.init) ?? QueryMetadata(metadata: [:]) }
    }
}

extension QueryMetadata {
    
    init(_ metadata: MySQLQueryMetadata) {
        self.init(metadata: [
            "affectedRows": QueryData(metadata.affectedRows),
            "lastInsertID": QueryData(metadata.lastInsertID),
        ])
    }
}

extension MySQLRow: QueryRowConvertable {
    
    public var count: Int {
        return self.columnDefinitions.count
    }
    
    public var allColumns: [String] {
        return self.columnDefinitions.map { $0.name }
    }
    
    public func contains(column: String) -> Bool {
        return self.columnDefinitions.contains { $0.name == column }
    }
    
    public func value(_ column: String) -> QueryData? {
        return self.column(column).map(QueryData.init)
    }
}

extension MySQLData: QueryDataConvertable {
    
}
