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

import MongoSwift

class SessionBoundConnection: DBMongoConnectionProtocol {
    
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
    
    var isClosed: Bool {
        return connection.isClosed
    }
    
    var eventLoopGroup: EventLoopGroup {
        return connection.eventLoopGroup
    }
    
    func _database() -> MongoDatabase? {
        return connection._database()
    }
}

extension SessionBoundConnection {
    
    func withSession<T>(
        options: ClientSessionOptions?,
        _ sessionBody: (SessionBoundConnection) throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        return connection.withSession(options: options, sessionBody)
    }
}

#if compiler(>=5.5.2) && canImport(_Concurrency)

extension SessionBoundConnection {
    
    func withSession<T>(
        options: ClientSessionOptions?,
        _ sessionBody: (SessionBoundConnection) async throws -> T
    ) async throws -> T {
        return try await connection.withSession(options: options, sessionBody)
    }
}

#endif

extension SessionBoundConnection {
    
    func close() -> EventLoopFuture<Void> {
        return connection.close()
    }
}

extension SessionBoundConnection {
    
    func _bind(to eventLoop: EventLoop) -> DBMongoConnectionProtocol {
        return SessionBoundConnection(connection: connection._bind(to: eventLoop), session: session)
    }
}

extension SessionBoundConnection {
    
    func version() -> EventLoopFuture<String> {
        return connection.version()
    }
    
    func databases() -> EventLoopFuture<[String]> {
        return connection.databases()
    }
}
