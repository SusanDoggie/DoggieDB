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

struct MySQLDriver: DBDriverProtocol {
    
    static var defaultPort: Int { 3306 }
    
    static var sqlDialect: SQLDialect.Type? {
        return MySQLDialect.self
    }
}

extension MySQLDriver {
    
    class Connection: DBSQLConnection {
        
        var driver: DBDriver { return .mySQL }
        
        let connection: MySQLConnection
        
        var eventLoopGroup: EventLoopGroup { connection.eventLoop }
        
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
        on eventLoopGroup: EventLoopGroup
    ) -> EventLoopFuture<DBConnection> {
        
        guard let user = config.user else {
            return eventLoopGroup.next().makeFailedFuture(Database.Error.invalidConfiguration(message: "user is missing."))
        }
        
        let connection = MySQLConnection.connect(
            to: config.socketAddress[0],
            username: user,
            database: config.database ?? user,
            password: config.password,
            tlsConfiguration: config.tlsConfiguration,
            logger: logger,
            on: eventLoopGroup.next()
        )
        
        return connection.map(Connection.init)
    }
}

extension MySQLDriver.Connection {
    
    var isClosed: Bool {
        return self.connection.isClosed
    }
}

extension MySQLDriver.Connection {
    
    func version() -> EventLoopFuture<String> {
        return self.execute("SELECT version()").map { $0[0]["version()"]!.string! }
    }
    
    func databases() -> EventLoopFuture<[String]> {
        return self.execute("SHOW DATABASES").map { $0.map { $0["Database"]!.string! } }
    }
    
    func tables() -> EventLoopFuture<[String]> {
        return self.execute("SHOW FULL TABLES WHERE Table_type = 'BASE TABLE'").map { $0.map { $0[$0.keys.first { $0.hasPrefix("Tables_in_") }!]!.string! } }
    }
    
    func views() -> EventLoopFuture<[String]> {
        return self.execute("SHOW FULL TABLES WHERE Table_type = 'VIEW'").map { $0.map { $0[$0.keys.first { $0.hasPrefix("Tables_in_") }!]!.string! } }
    }
    
    func materializedViews() -> EventLoopFuture<[String]> {
        return eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
    }
    
    func columns(of table: String) -> EventLoopFuture<[DBQueryRow]> {
        return self.execute("SHOW COLUMNS FROM \(identifier: table)")
    }
    
    func primaryKey(of table: String) -> EventLoopFuture<[String]> {
        
        var sql: SQLRaw = """
            SELECT
                COLUMN_NAME,
                SEQ_IN_INDEX
            FROM
                INFORMATION_SCHEMA.STATISTICS
            WHERE
                INDEX_NAME = 'PRIMARY'
            """
        
        if let split = table.firstIndex(of: ".") {
            
            let _schema = table.prefix(upTo: split)
            let _name = table.suffix(from: split).dropFirst()
            
            sql.append(" AND TABLE_SCHEMA = \(_schema) AND TABLE_NAME = \(_name)")
            
        } else {
            
            sql.append(" AND TABLE_NAME = \(table)")
        }
        
        return self.execute(sql).map {
            $0.sorted { $0["SEQ_IN_INDEX"]?.intValue ?? .max }.compactMap { $0["COLUMN_NAME"]?.string }
        }
    }
    
    func indices(of table: String) -> EventLoopFuture<[DBQueryRow]> {
        
        var sql: SQLRaw = "SELECT * FROM INFORMATION_SCHEMA.STATISTICS"
        
        if let split = table.firstIndex(of: ".") {
            
            let _schema = table.prefix(upTo: split)
            let _name = table.suffix(from: split).dropFirst()
            
            sql.append(" WHERE TABLE_SCHEMA = \(_schema) AND TABLE_NAME = \(_name)")
            
        } else {
            
            sql.append(" WHERE TABLE_NAME = \(table)")
        }
        
        return self.execute(sql)
    }
    
    func foreignKeys(of table: String) -> EventLoopFuture<[DBQueryRow]> {
        
        var sql: SQLRaw = "SELECT * FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE"
        
        if let split = table.firstIndex(of: ".") {
            
            let _schema = table.prefix(upTo: split)
            let _name = table.suffix(from: split).dropFirst()
            
            sql.append(" WHERE TABLE_SCHEMA = \(_schema) AND TABLE_NAME = \(_name)")
            
        } else {
            
            sql.append(" WHERE TABLE_NAME = \(table)")
        }
        
        sql.appendLiteral(" AND REFERENCED_COLUMN_NAME IS NOT NULL")
        
        return self.execute(sql)
    }
}

extension MySQLDriver.Connection {
    
    func execute(
        _ sql: SQLRaw
    ) -> EventLoopFuture<[DBQueryRow]> {
        
        do {
            
            guard let (raw, binds) = self.serialize(sql) else {
                throw Database.Error.unsupportedOperation
            }
            
            if binds.isEmpty {
                
                return self.connection.simpleQuery(raw).map { $0.map(DBQueryRow.init) }
            }
            
            let _binds = try binds.map(MySQLData.init)
            
            return self.connection.query(raw, _binds).map { $0.map(DBQueryRow.init) }
            
        } catch {
            
            return eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func execute(
        _ sql: SQLRaw,
        onRow: @escaping (DBQueryRow) throws -> Void
    ) -> EventLoopFuture<DBQueryMetadata> {
        
        do {
            
            guard let (raw, binds) = self.serialize(sql) else {
                throw Database.Error.unsupportedOperation
            }
            
            var metadata: MySQLQueryMetadata?
            let _binds = try binds.map(MySQLData.init)
            
            return self.connection.query(
                raw,
                _binds,
                onRow: { try onRow(DBQueryRow($0)) },
                onMetadata: { metadata = $0 }
            ).map { metadata.map(DBQueryMetadata.init) ?? DBQueryMetadata() }
            
        } catch {
            
            return eventLoopGroup.next().makeFailedFuture(error)
        }
    }
}

extension DBQueryMetadata {
    
    init(_ metadata: MySQLQueryMetadata) {
        self.init([
            "affectedRows": DBData(metadata.affectedRows),
            "lastInsertID": metadata.lastInsertID.map(DBData.init) ?? nil,
        ])
    }
}

extension MySQLRow: DBRowConvertable {
    
    public var count: Int {
        return self.columnDefinitions.count
    }
    
    public var keys: [String] {
        return self.columnDefinitions.map { $0.name }
    }
    
    public func contains(column: String) -> Bool {
        return self.columnDefinitions.contains { $0.name == column }
    }
    
    public func value(_ column: String) -> DBData? {
        return try? self.column(column).map(DBData.init)
    }
}
