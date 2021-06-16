//
//  EventLoopBoundConnection.swift
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

protocol DBMongoConnectionProtocol: DBConnection {
    
    var database: String? { get }
    
    func _database() -> MongoDatabase?
    
    func startSession(options: ClientSessionOptions?) -> ClientSession
    
    func withSession<T>(
        options: ClientSessionOptions?,
        _ sessionBody: (ClientSession) throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T>
}

class DBMongoEventLoopBoundConnection: DBMongoConnectionProtocol {
    
    let connection: MongoDBDriver.Connection
    
    let client: EventLoopBoundMongoClient
    
    private(set) var isClosed: Bool = false
    
    init(connection: MongoDBDriver.Connection, client: EventLoopBoundMongoClient) {
        self.connection = connection
        self.client = client
    }
}

extension DBMongoEventLoopBoundConnection {
    
    var driver: DBDriver {
        return connection.driver
    }
    
    var database: String? {
        return connection.database
    }
    
    var eventLoopGroup: EventLoopGroup {
        return client.eventLoop
    }
    
    func _database() -> MongoDatabase? {
        return database.map { client.db($0) }
    }
    
    func startSession(options: ClientSessionOptions?) -> ClientSession {
        return client.startSession(options: options)
    }
    
    func withSession<T>(
        options: ClientSessionOptions?,
        _ sessionBody: (ClientSession) throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        return client.withSession(options: options, sessionBody)
    }
}

extension DBMongoEventLoopBoundConnection {
    
    func close() -> EventLoopFuture<Void> {
        let closeResult = eventLoopGroup.next().makeSucceededVoidFuture()
        closeResult.whenComplete { _ in self.isClosed = true }
        return closeResult
    }
}

extension DBMongoEventLoopBoundConnection {
    
    func bind(to eventLoop: EventLoop) -> DBConnection {
        return connection.bind(to: eventLoop)
    }
}

extension DBMongoEventLoopBoundConnection {
    
    func version() -> EventLoopFuture<String> {
        return connection.version()
    }
    
    func databases() -> EventLoopFuture<[String]> {
        return client.listDatabaseNames()
    }
}
