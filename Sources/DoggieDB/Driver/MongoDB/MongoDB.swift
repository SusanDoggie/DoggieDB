//
//  MongoDB.swift
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

import MongoSwift

struct MongoDBDriver: DBDriverProtocol {
    
    static var isThreadBased: Bool { true }
    
    static var defaultPort: Int { 27017 }
}

extension MongoDBDriver {
    
    final class Connection: DBMongoConnectionProtocol, @unchecked Sendable {
        
        var driver: DBDriver { return .mongoDB }
        
        let client: MongoClient
        let database: String?
        
        let logger: Logger
        
        let eventLoopGroup: EventLoopGroup
        
        init(client: MongoClient, database: String?, logger: Logger, eventLoopGroup: EventLoopGroup) {
            self.client = client
            self.database = database
            self.logger = logger
            self.eventLoopGroup = eventLoopGroup
        }
        
        func close() async throws {
            try await client.close().get()
        }
    }
}

extension Database.Configuration {
    
    func mongo_connection_string() throws -> String {
        
        var url = URLComponents()
        url.user = self.user
        url.password = self.password
        url.queryItems = self.queryItems
        
        var connectionString = "mongodb://"
        
        if self.user != nil && self.password != nil {
            connectionString += "\(url.percentEncodedUser ?? ""):\(url.percentEncodedPassword ?? "")@"
        }
        
        for (i, socketAddress) in self.socketAddress.enumerated() {
            
            guard let host = socketAddress.host else {
                throw Database.Error.invalidConfiguration(message: "unsupprted socket address")
            }
            
            if i != 0 {
                connectionString += ","
            }
            
            url.host = host
            connectionString += url.percentEncodedHost ?? ""
            
            if let port = socketAddress.port {
                connectionString += ":\(port)"
            }
        }
        
        if let database = self.database {
            connectionString += "/\(database)"
        }
        
        if self.queryItems?.isEmpty == false {
            connectionString += "?\(url.percentEncodedQuery ?? "")"
        }
        
        return connectionString
    }
}

extension MongoDBDriver {
    
    static func connect(
        config: Database.Configuration,
        logger: Logger,
        on eventLoopGroup: EventLoopGroup
    ) async throws -> DBConnection {
        
        let connectionString = try config.mongo_connection_string()
        
        let client = try MongoClient(connectionString, using: eventLoopGroup, options: nil)
        
        return Connection(
            client: client,
            database: config.database,
            logger: logger,
            eventLoopGroup: eventLoopGroup
        )
    }
}

extension MongoDBDriver.Connection {
    
    func _database() -> MongoDatabase? {
        return self.database.map { client.db($0) }
    }
}

extension MongoDBDriver.Connection {
    
    func withSession<T>(
        options: ClientSessionOptions?,
        _ sessionBody: (SessionBoundConnection) async throws -> T
    ) async throws -> T {
        
        let session = client.startSession(options: options)
        
        do {
            
            let result = try await sessionBody(SessionBoundConnection(connection: self, session: session))
            
            try await session.end().get()
            
            return result
            
        } catch {
            
            try await session.end().get()
            
            throw error
        }
    }
}

extension MongoDBDriver.Connection {
    
    func _bind(to eventLoop: EventLoop) -> DBMongoConnectionProtocol {
        let client = self.client.bound(to: eventLoop)
        return DBMongoEventLoopBoundConnection(connection: self, client: client)
    }
}

extension MongoDBDriver.Connection {
    
    func version() async throws -> String {
        guard let database = self._database() else { fatalError("database not selected.") }
        return try await database.runCommand(["buildInfo": 1]).get()["version"]!.stringValue!
    }
    
    func databases() async throws -> [String] {
        return try await self.client.listDatabaseNames().get()
    }
}
