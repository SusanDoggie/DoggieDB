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

struct PostgreSQLDriver: DBDriverProtocol {
    
    static var defaultPort: Int { 5432 }
}

extension PostgreSQLDriver {
    
    class Connection: DBConnection {
        
        var driver: DBDriver { return .postgreSQL }
        
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
    ) -> EventLoopFuture<DBConnection> {
        
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
    
    func version() -> EventLoopFuture<String> {
        return self.query("SELECT version();", []).map { $0[0]["version()"]!.string! }
    }
    
    func databases() -> EventLoopFuture<[String]> {
        return self.query("SELECT datname FROM pg_catalog.pg_database;", []).map { $0.compactMap { $0["datname"]!.string! } }
    }
    
    func tables() -> EventLoopFuture<[String]> {
        return self.query("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';", []).map { $0.map { $0["tablename"]!.string! } }
    }
    
    func views() -> EventLoopFuture<[String]> {
        return self.query("SELECT viewname FROM pg_catalog.pg_views WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';", []).map { $0.map { $0["viewname"]!.string! } }
    }
    
    func materializedViews() -> EventLoopFuture<[String]> {
        return self.query("SELECT matviewname FROM pg_catalog.pg_matviews WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';", []).map { $0.map { $0["matviewname"]!.string! } }
    }
    
    func tableInfo(_ table: String) -> EventLoopFuture<[DBQueryRow]> {
        return self.query("SELECT * FROM information_schema.columns WHERE table_name = $1;", [DBData(table)])
    }
}

extension PostgreSQLDriver.Connection {
    
    func query(
        _ string: String,
        _ binds: [DBData]
    ) -> EventLoopFuture<[DBQueryRow]> {
        
        do {
            
            if binds.isEmpty {
                
                return self.connection.simpleQuery(string).map{ $0.map(DBQueryRow.init) }
            }
            
            let binds = try binds.map(PostgresData.init)
            
            return self.connection.query(string, binds).map{ $0.rows.map(DBQueryRow.init) }
            
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
            
            var metadata: PostgresQueryMetadata?
            let binds = try binds.map(PostgresData.init)
            
            return self.connection.query(
                string,
                binds,
                onMetadata: { metadata = $0 },
                onRow: { onRow(DBQueryRow($0)) }
            ).map { metadata.map(DBQueryMetadata.init) ?? DBQueryMetadata(metadata: [:]) }
            
        } catch let error {
            
            return eventLoop.makeFailedFuture(error)
        }
    }
}

extension DBQueryMetadata {
    
    init(_ metadata: PostgresQueryMetadata) {
        self.init(metadata: [
            "command": DBData(metadata.command),
            "oid": metadata.oid.map(DBData.init) ?? nil,
            "rows": metadata.rows.map(DBData.init) ?? nil,
        ])
    }
}

extension PostgresRow: DBRowConvertable {
    
    @inlinable
    public var count: Int {
        return self.rowDescription.fields.count
    }
    
    @inlinable
    public var keys: [String] {
        return self.rowDescription.fields.map { $0.name }
    }
    
    @inlinable
    public func contains(column: String) -> Bool {
        return self.rowDescription.fields.contains { $0.name == column }
    }
    
    public func value(_ column: String) -> DBData? {
        return try? self.column(column).map(DBData.init)
    }
}
