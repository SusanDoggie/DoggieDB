//
//  EventLoopBoundConnection.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2024 Susan Cheng. All rights reserved.
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

@preconcurrency import MongoSwift

final class DBMongoEventLoopBoundConnection: DBMongoConnectionProtocol {
    
    let connection: MongoDBDriver.Connection
    
    let client: EventLoopBoundMongoClient
    
    init(connection: MongoDBDriver.Connection, client: EventLoopBoundMongoClient) {
        self.connection = connection
        self.client = client
    }
}

extension DBMongoEventLoopBoundConnection {
    
    var driver: DBDriver {
        return connection.driver
    }
    
    var logger: Logger {
        return connection.logger
    }
    
    var database: String? {
        return connection.database
    }
    
    var eventLoopGroup: EventLoopGroup {
        return client.eventLoop
    }
    
    var subscribers: MongoDBDriver.Subscribers {
        return connection.subscribers
    }
    
    func _database() -> MongoDatabase? {
        return database.map { client.db($0) }
    }
}

extension DBMongoEventLoopBoundConnection {
    
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

extension DBMongoEventLoopBoundConnection {
    
    func close() async throws { }
}

extension DBMongoEventLoopBoundConnection {
    
    func _bind(to eventLoop: EventLoop) -> DBMongoConnectionProtocol {
        return connection._bind(to: eventLoop)
    }
}

extension DBMongoEventLoopBoundConnection {
    
    func version() async throws -> String {
        return try await connection.version()
    }
    
    func databases() async throws -> [String] {
        return try await client.listDatabaseNames().get()
    }
}
