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

struct MongoDBDriver: DatabaseDriverProtocol {
    
    static var defaultPort: Int { 27017 }
}

extension MongoDBDriver {
    
    class Connection: DatabaseConnection {
        
        let client: MongoClient
        
        init(_ client: MongoClient) {
            self.client = client
        }
        
        func close() -> EventLoopFuture<Void> {
            return client.close()
        }
    }
}

extension MongoDBDriver {
    
    static func connect(
        config: DatabaseConfiguration,
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<DatabaseConnection> {
        
        guard let host = config.socketAddress.host else {
            return eventLoop.makeFailedFuture(DatabaseError.invalidConfiguration(message: "unsupprted socket address"))
        }
        
        var url = URLComponents()
        url.scheme = "mongodb"
        url.host = host
        url.port = config.socketAddress.port
        url.user = config.username
        url.password = config.password
        
        guard let connectionString = url.string else {
            return eventLoop.makeFailedFuture(DatabaseError.unknown)
        }
        
        do {
            
            let client = try MongoClient(connectionString, using: eventLoop, options: nil)
            
            return eventLoop.makeSucceededFuture(Connection(client))
            
        } catch let error {
            
            return eventLoop.makeFailedFuture(error)
        }
    }
}
