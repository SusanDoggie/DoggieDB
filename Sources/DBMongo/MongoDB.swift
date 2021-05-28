//
//  MongoDB.swift
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

import MongoSwift

struct MongoDBDriver: DBDriverProtocol {
    
    static var isSessionSupported: Bool { true }
    
    static var defaultPort: Int { 27017 }
}

extension MongoDBDriver {
    
    class Connection: DBMongoConnectionProtocol {
        
        var driver: DBDriver { return .mongoDB }
        
        private(set) var isClosed: Bool = false
        
        let client: MongoClient
        let database: String?
        
        let eventLoopGroup: EventLoopGroup
        
        init(client: MongoClient, database: String?, eventLoopGroup: EventLoopGroup) {
            self.client = client
            self.database = database
            self.eventLoopGroup = eventLoopGroup
        }
        
        func close() -> EventLoopFuture<Void> {
            let closeResult = client.close()
            closeResult.whenComplete { _ in self.isClosed = true }
            return closeResult
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
            
            if let port = url.port {
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
    ) -> EventLoopFuture<DBConnection> {
        
        do {
            
            let connectionString = try config.mongo_connection_string()
            
            let client = try MongoClient(connectionString, using: eventLoopGroup, options: nil)
            
            return eventLoopGroup.next().makeSucceededFuture(
                Connection(
                    client: client,
                    database: config.database,
                    eventLoopGroup: eventLoopGroup
                )
            )
            
        } catch {
            
            return eventLoopGroup.next().makeFailedFuture(error)
        }
    }
}

extension MongoDBDriver.Connection {
    
    var connection: MongoDBDriver.Connection {
        return self
    }
    
    var session: ClientSession? {
        return nil
    }
    
    func _database() -> MongoDatabase? {
        return self.database.map { client.db($0) }
    }
    
    func bind(to eventLoop: EventLoop) -> DBConnection {
        let client = self.client.bound(to: eventLoop)
        return DBMongoConnection(connection: self, client: client, session: nil)
    }
    
    func withSession(on eventLoop: EventLoop?) -> DBConnection {
        if let eventLoop = eventLoop {
            let client = self.client.bound(to: eventLoop)
            let session = client.startSession()
            return DBMongoConnection(connection: self, client: client, session: session)
        } else {
            let session = self.client.startSession()
            return DBMongoConnection(connection: self, client: nil, session: session)
        }
    }
}

extension MongoDBDriver.Connection {
    
    func databases() -> EventLoopFuture<[String]> {
        return self.client.listDatabaseNames()
    }
}
