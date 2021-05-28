//
//  DBMongoConnection.swift
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
    
    var session: ClientSession? { get }
    
    func _database() -> MongoDatabase?
}

class DBMongoConnection: DBMongoConnectionProtocol {
    
    let connection: MongoDBDriver.Connection
    
    let client: EventLoopBoundMongoClient?
    
    let session: ClientSession?
    
    private(set) var isClosed: Bool = false
    
    init(connection: MongoDBDriver.Connection, client: EventLoopBoundMongoClient?, session: ClientSession?) {
        self.connection = connection
        self.client = client
        self.session = session
    }
}

extension DBMongoConnection {
    
    var driver: DBDriver {
        return connection.driver
    }
    
    var database: String? {
        return connection.database
    }
    
    var eventLoopGroup: EventLoopGroup {
        return client?.eventLoop ?? connection.eventLoopGroup
    }
    
    func _database() -> MongoDatabase? {
        return database.map { client?.db($0) ?? connection.client.db($0) }
    }
}

extension DBMongoConnection {
    
    func close() -> EventLoopFuture<Void> {
        guard let session = session else { return eventLoopGroup.next().makeSucceededVoidFuture() }
        let closeResult = session.end()
        closeResult.whenComplete { _ in self.isClosed = true }
        return closeResult
    }
}

extension DBMongoConnection {
    
    func bind(to eventLoop: EventLoop) -> DBConnection {
        return connection.bind(to: eventLoop)
    }
    
    func withSession(on eventLoop: EventLoop?) -> DBConnection {
        return connection.withSession(on: eventLoop)
    }
}

extension DBMongoConnection {
    
    func databases() -> EventLoopFuture<[String]> {
        return client?.listDatabaseNames() ?? connection.databases()
    }
}
