//
//  DBPostgresPubSub.swift
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

public struct DBPostgresPubSub {
    
    let connection: PostgreSQLDriver.Connection
}

extension DBPostgresPubSub {
    
    public var eventLoopGroup: EventLoopGroup {
        return connection.eventLoopGroup
    }
}

extension DBConnection {
    
    public func postgresPubSub() -> DBPostgresPubSub {
        guard let connection = self as? PostgreSQLDriver.Connection else { fatalError("unsupported operation") }
        return DBPostgresPubSub(connection: connection)
    }
}

extension DBPostgresPubSub {
    
    public func publish(
        _ message: String,
        to channel: String
    ) async throws {
        return try await self.connection.publish(message, to: channel)
    }
    
    public func subscribe(
        channel: String,
        handler: @escaping (_ connection: DBConnection, _ channel: String, _ message: String) -> Void
    ) async throws {
        
        return try await self.connection.subscribe(channel: channel) { [weak connection] channel, message in
            guard let connection = connection else { return }
            handler(connection, channel, message)
        }
    }
    
    public func unsubscribe(channel: String) async throws {
        return try await self.connection.unsubscribe(channel: channel)
    }
}