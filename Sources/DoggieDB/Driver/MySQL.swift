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
    
    class Connection: DatabaseConnection {
        
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
        config: DatabaseConfiguration,
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<DatabaseConnection> {
        
        guard let username = config.username else {
            return eventLoop.makeFailedFuture(DatabaseError.invalidConfiguration(message: "username is missing."))
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
    
    func query(
        _ string: String,
        _ binds: [MySQLData] = []
    ) -> EventLoopFuture<[MySQLRow]> {
        if binds.isEmpty {
            return self.connection.simpleQuery(string)
        }
        return self.connection.query(string, binds)
    }
    
    func query(
        _ string: String,
        _ binds: [MySQLData] = [],
        onRow: @escaping (MySQLRow) throws -> (),
        onMetadata: @escaping (MySQLQueryMetadata) -> () = { _ in }
    ) -> NIO.EventLoopFuture<Void> {
        return self.connection.query(string, binds, onRow: onRow, onMetadata: onMetadata)
    }
}
