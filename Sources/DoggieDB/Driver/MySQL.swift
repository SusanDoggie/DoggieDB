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
}

extension MySQLDriver {
    
    class Connection: DBConnection {
        
        var driver: DBDriver { return .mySQL }
        
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
    ) -> EventLoopFuture<DBConnection> {
        
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
    
    var isClosed: Bool {
        return self.connection.isClosed
    }
}

extension MySQLDriver.Connection {
    
    func version() -> EventLoopFuture<String> {
        return self.execute("SELECT version();").map { $0[0]["version()"]!.string! }
    }
    
    func databases() -> EventLoopFuture<[String]> {
        return self.execute("SHOW DATABASES;").map { $0.map { $0["Database"]!.string! } }
    }
    
    func tables() -> EventLoopFuture<[String]> {
        return self.execute("SHOW FULL TABLES WHERE Table_type = 'BASE TABLE';").map { $0.map { $0[$0.keys.first { $0.hasPrefix("Tables_in_") }!]!.string! } }
    }
    
    func views() -> EventLoopFuture<[String]> {
        return self.execute("SHOW FULL TABLES WHERE Table_type = 'VIEW';").map { $0.map { $0[$0.keys.first { $0.hasPrefix("Tables_in_") }!]!.string! } }
    }
    
    func tableInfo(_ table: String) -> EventLoopFuture<[DBQueryRow]> {
        return self.execute("SHOW COLUMNS FROM \(literal: table);")
    }
}

extension MySQLDriver.Connection {
    
    func execute(
        _ sql: SQLRaw
    ) -> EventLoopFuture<[DBQueryRow]> {
        
        do {
            
            guard let (raw, binds) = self.serialize(sql) else {
                throw Database.Error.invalidOperation(message: "unsupported operation")
            }
            
            if binds.isEmpty {
                
                return self.connection.simpleQuery(raw).map { $0.map(DBQueryRow.init) }
            }
            
            let _binds = try binds.map(MySQLData.init)
            
            return self.connection.query(raw, _binds).map { $0.map(DBQueryRow.init) }
            
        } catch let error {
            
            return eventLoop.makeFailedFuture(error)
        }
    }
    
    func execute(
        _ sql: SQLRaw,
        onRow: @escaping (DBQueryRow) -> Void
    ) -> EventLoopFuture<DBQueryMetadata> {
        
        do {
            
            guard let (raw, binds) = self.serialize(sql) else {
                throw Database.Error.invalidOperation(message: "unsupported operation")
            }
            
            var metadata: MySQLQueryMetadata?
            let _binds = try binds.map(MySQLData.init)
            
            return self.connection.query(
                raw,
                _binds,
                onRow: { onRow(DBQueryRow($0)) },
                onMetadata: { metadata = $0 }
            ).map { metadata.map(DBQueryMetadata.init) ?? DBQueryMetadata(metadata: [:]) }
            
        } catch let error {
            
            return eventLoop.makeFailedFuture(error)
        }
    }
}

extension DBQueryMetadata {
    
    init(_ metadata: MySQLQueryMetadata) {
        self.init(metadata: [
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
