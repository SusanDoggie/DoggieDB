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
    
    static var defaultPort: Int { 27017 }
}

extension MongoDBDriver {
    
    class Connection: DBConnection {
        
        var driver: DBDriver { return .mongoDB }
        
        private(set) var isClosed: Bool = false
        
        let client: MongoClient
        let database: MongoDatabase?
        
        let eventLoop: EventLoop
        
        init(client: MongoClient, database: MongoDatabase?, eventLoop: EventLoop) {
            self.client = client
            self.database = database
            self.eventLoop = eventLoop
        }
        
        func close() -> EventLoopFuture<Void> {
            let closeResult = client.close()
            closeResult.whenComplete { _ in self.isClosed = true }
            return closeResult
        }
    }
}

extension MongoDBDriver {
    
    static func connect(
        config: Database.Configuration,
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<DBConnection> {
        
        guard let host = config.socketAddress.host else {
            return eventLoop.makeFailedFuture(Database.Error.invalidConfiguration(message: "unsupprted socket address"))
        }
        
        var url = URLComponents()
        url.scheme = "mongodb"
        url.host = host
        url.port = config.socketAddress.port
        url.user = config.username
        url.password = config.password
        
        guard let connectionString = url.string else {
            return eventLoop.makeFailedFuture(Database.Error.unknown)
        }
        
        do {
            
            let client = try MongoClient(connectionString, using: eventLoop, options: nil)
            
            return eventLoop.makeSucceededFuture(Connection(client: client, database: config.database.map { client.db($0, options: nil) }, eventLoop: eventLoop))
            
        } catch let error {
            
            return eventLoop.makeFailedFuture(error)
        }
    }
}

extension MongoDBDriver.Connection {
    
    func databases() -> EventLoopFuture<[String]> {
        return self.client.listDatabaseNames()
    }
}

extension MongoDBDriver.Connection {
    
    func runCommand(
        _ command: BSONDocument,
        options: RunCommandOptions?
    ) -> EventLoopFuture<BSONDocument> {
        guard let database = self.database else {
            return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "database not selected."))
        }
        return database.runCommand(command, options: options)
    }
}