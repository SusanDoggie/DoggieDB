//
//  Redis.swift
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

import RediStack

struct RedisDriver: DatabaseDriverProtocol {
    
    static var defaultPort: Int { 6379 }
}

extension RedisDriver {
    
    class Connection: DatabaseConnection {
        
        let connection: RedisConnection
        
        var eventLoop: EventLoop { connection.eventLoop }
        
        init(_ connection: RedisConnection) {
            self.connection = connection
        }
        
        func close() -> EventLoopFuture<Void> {
            return connection.close()
        }
    }
}

extension RedisDriver {
    
    static func connect(
        config: Database.Configuration,
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<DatabaseConnection> {
        
        do {
            
            let _config = try RedisConnection.Configuration(
                address: config.socketAddress,
                password: config.password,
                initialDatabase: config.database.flatMap(Int.init),
                defaultLogger: logger
            )
            
            return RedisConnection.make(
                configuration: _config,
                boundEventLoop: eventLoop
            ).map(Connection.init)
            
        } catch let error {
            
            return eventLoop.makeFailedFuture(error)
        }
    }
}

extension RedisDriver.Connection {
    
    func runCommand(
        _ string: String,
        _ binds: [RESPValue]
    ) -> EventLoopFuture<RESPValue> {
        if binds.isEmpty {
            return self.connection.send(command: string)
        }
        return self.connection.send(command: string, with: binds)
    }
}

extension RedisDriver.Connection {
    
    func subscribe(
        to channels: [RedisChannelName],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        
        return self.connection.subscribe(to: channels, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
    }
    
    func unsubscribe(from channels: [RedisChannelName]) -> EventLoopFuture<Void> {
        
        return self.connection.unsubscribe(from: channels)
    }
    
    func psubscribe(
        to patterns: [String],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        
        return self.connection.psubscribe(to: patterns, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
    }
    
    func punsubscribe(from patterns: [String]) -> EventLoopFuture<Void> {
        
        return self.connection.punsubscribe(from: patterns)
    }
}

extension RedisDriver.Connection {
    
    func get<D>(_ key: String, as type: D.Type) -> EventLoopFuture<D?> where D: Decodable {
        return self.connection.get(RedisKey(key), as: Data.self).flatMapThrowing { data in try data.flatMap { try JSONDecoder().decode(D.self, from: $0) } }
    }
    
    func set<E>(_ key: String, as type: E) -> EventLoopFuture<Void> where E: Encodable {
        do {
            return try self.connection.set(RedisKey(key), to: JSONEncoder().encode(type))
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }
}
