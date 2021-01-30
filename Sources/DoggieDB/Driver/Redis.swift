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

struct RedisDriver: DBDriverProtocol {
    
    static var defaultPort: Int { 6379 }
}

extension RedisDriver {
    
    class Connection: DBConnection {
        
        var driver: DBDriver { return .redis }
        
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
    ) -> EventLoopFuture<DBConnection> {
        
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
        
        let result = binds.isEmpty ? self.connection.send(command: string) : self.connection.send(command: string, with: binds)
        
        return result.flatMapResult { result in
            Result {
                if case let .error(error) = result {
                    throw error
                }
                return result
            }
        }
    }
}

extension RedisDriver.Connection {
    
    var allowSubscriptions: Bool {
        get {
            return self.connection.allowSubscriptions
        }
        set {
            self.connection.allowSubscriptions = newValue
        }
    }
    
    var isSubscribed: Bool {
        return self.connection.isSubscribed
    }
    
    func activeChannels(matching match: String? = nil) -> EventLoopFuture<[String]> {
        return self.connection.activeChannels(matching: match).map { $0.map { $0.rawValue } }
    }
    
    func subscribe(
        toChannels channels: [String],
        messageReceiver receiver: @escaping (_ publisher: String, _ message: Result<DBData, Error>) -> Void,
        onSubscribe subscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)?,
        onUnsubscribe unsubscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)?
    ) -> EventLoopFuture<Void> {
        
        return self.connection.subscribe(
            to: channels.map { RedisChannelName($0) },
            messageReceiver: { publisher, message in receiver(publisher.rawValue, Result { try DBData(message) }) },
            onSubscribe: subscribeHandler,
            onUnsubscribe: unsubscribeHandler
        )
    }
    
    func unsubscribe(fromChannels channels: [String]) -> EventLoopFuture<Void> {
        return self.connection.unsubscribe(from: channels.map { RedisChannelName($0) })
    }
    
    func subscribe(
        toPatterns patterns: [String],
        messageReceiver receiver: @escaping (_ publisher: String, _ message: Result<DBData, Error>) -> Void,
        onSubscribe subscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)?,
        onUnsubscribe unsubscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)?
    ) -> EventLoopFuture<Void> {
        
        return self.connection.psubscribe(
            to: patterns,
            messageReceiver: { publisher, message in receiver(publisher.rawValue, Result { try DBData(message) }) },
            onSubscribe: subscribeHandler,
            onUnsubscribe: unsubscribeHandler
        )
    }
    
    func unsubscribe(fromPatterns patterns: [String]) -> EventLoopFuture<Void> {
        return self.connection.punsubscribe(from: patterns)
    }
}

extension RedisDriver.Connection {
    
    func get<D: Decodable>(_ key: String, as type: D.Type) -> EventLoopFuture<D?> {
        return self.connection.get(RedisKey(key), as: Data.self).flatMapThrowing { data in try data.flatMap { try JSONDecoder().decode(D.self, from: $0) } }
    }
    
    func set<E: Encodable>(_ key: String, as type: E) -> EventLoopFuture<Void> {
        do {
            return try self.connection.set(RedisKey(key), to: JSONEncoder().encode(type))
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }
}
