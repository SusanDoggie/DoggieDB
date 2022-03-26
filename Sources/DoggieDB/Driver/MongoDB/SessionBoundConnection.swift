//
//  SessionBoundConnection.swift
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

@preconcurrency
import MongoSwift

final class SessionBoundConnection: DBMongoConnectionProtocol {
    
    let connection: DBMongoConnectionProtocol
    
    let session: ClientSession
    
    init(connection: DBMongoConnectionProtocol, session: ClientSession) {
        self.connection = connection
        self.session = session
    }
}

extension SessionBoundConnection {
    
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
        return connection.eventLoopGroup
    }
    
    var _mongoPubSub: DBMongoPubSub {
        return connection._mongoPubSub
    }
    
    func _database() -> MongoDatabase? {
        return connection._database()
    }
}

extension SessionBoundConnection {
    
    func withSession<T>(
        options: ClientSessionOptions?,
        _ sessionBody: (SessionBoundConnection) async throws -> T
    ) async throws -> T {
        return try await connection.withSession(options: options, sessionBody)
    }
}

extension SessionBoundConnection {
    
    func close() async throws {
        return try await connection.close()
    }
}

extension SessionBoundConnection {
    
    func _bind(to eventLoop: EventLoop) -> DBMongoConnectionProtocol {
        return SessionBoundConnection(connection: connection._bind(to: eventLoop), session: session)
    }
}

extension SessionBoundConnection {
    
    func version() async throws -> String {
        return try await connection.version()
    }
    
    func databases() async throws -> [String] {
        return try await connection.databases()
    }
}
