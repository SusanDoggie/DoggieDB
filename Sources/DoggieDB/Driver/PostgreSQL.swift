//
//  PostgreSQL.swift
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

import PostgresNIO

struct PostgreSQLDriver: DatabaseDriverProtocol {
    
    static var defaultPort: Int { 5432 }
}

extension PostgreSQLDriver {
    
    class Connection: DatabaseConnection {
        
        let connection: PostgresConnection
        
        var eventLoop: EventLoop { connection.eventLoop }
        
        init(_ connection: PostgresConnection) {
            self.connection = connection
        }
        
        func close() -> EventLoopFuture<Void> {
            return connection.close()
        }
    }
}

extension PostgreSQLDriver {
    
    static func connect(
        config: Database.Configuration,
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<DatabaseConnection> {
        
        guard let username = config.username else {
            return eventLoop.makeFailedFuture(Database.Error.invalidConfiguration(message: "username is missing."))
        }
        
        let connection = PostgresConnection.connect(
            to: config.socketAddress,
            tlsConfiguration: config.tlsConfiguration,
            logger: logger,
            on: eventLoop
        )
        
        return connection.flatMap { connection in
            
            connection.authenticate(
                username: username,
                database: config.database,
                password: config.password,
                logger: logger
            ).map { Connection(connection) }
        }
    }
}

extension PostgreSQLDriver.Connection {
    
    func query(
        _ string: String,
        _ binds: [PostgresData]
    ) -> EventLoopFuture<[QueryRow]> {
        if binds.isEmpty {
            return self.connection.simpleQuery(string).map{ $0.map(QueryRow.init) }
        }
        return self.connection.query(string, binds).map{ $0.rows.map(QueryRow.init) }
    }
    
    func query(
        _ string: String,
        _ binds: [PostgresData],
        onRow: @escaping (QueryRow) throws -> ()
    ) -> EventLoopFuture<QueryMetadata> {
        var metadata: PostgresQueryMetadata?
        
        return self.connection.query(
            string,
            binds,
            onMetadata: { metadata = $0 },
            onRow: { try onRow(QueryRow($0)) }
        ).map { metadata.map(QueryMetadata.init) ?? QueryMetadata(metadata: [:]) }
    }
}

extension QueryMetadata {
    
    init(_ metadata: PostgresQueryMetadata) {
        self.init(metadata: [
            "command": QueryData(metadata.command),
            "oid": QueryData(metadata.oid),
            "rows": QueryData(metadata.rows),
        ])
    }
}

extension PostgresRow: QueryRowConvertable {
    
    public var count: Int {
        return self.rowDescription.fields.count
    }
    
    public var allColumns: [String] {
        return self.rowDescription.fields.map { $0.name }
    }
    
    public func contains(column: String) -> Bool {
        return self.rowDescription.fields.contains { $0.name == column }
    }
    
    public func value(_ column: String) -> QueryData? {
        return self.column(column).map(QueryData.init)
    }
}

extension PostgresData: QueryDataConvertable {
    
}
