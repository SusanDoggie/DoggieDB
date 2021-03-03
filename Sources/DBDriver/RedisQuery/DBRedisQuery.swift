//
//  DBRedisQuery.swift
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

public struct DBRedisQuery {
    
    let connection: RedisConnection
}

extension RedisDriver.Connection {
    
    public func redisQuery() -> DBRedisQuery {
        return DBRedisQuery(connection: connection)
    }
}

extension DBRedisQuery {
    
    public var allowSubscriptions: Bool {
        get {
            return self.connection.allowSubscriptions
        }
        set {
            self.connection.allowSubscriptions = newValue
        }
    }
    
    public var isSubscribed: Bool {
        return self.connection.isSubscribed
    }
    
    public func activeChannels(matching match: String? = nil) -> EventLoopFuture<[String]> {
        return self.connection.activeChannels(matching: match).map { $0.map { $0.rawValue } }
    }
    
    public func subscribe(
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
    
    public func unsubscribe(fromChannels channels: [String]) -> EventLoopFuture<Void> {
        return self.connection.unsubscribe(from: channels.map { RedisChannelName($0) })
    }
    
    public func subscribe(
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
    
    public func unsubscribe(fromPatterns patterns: [String]) -> EventLoopFuture<Void> {
        return self.connection.punsubscribe(from: patterns)
    }
}

extension DBRedisQuery {
    
    public func increment(_ key: String) -> EventLoopFuture<Int> {
        return self.connection.increment(RedisKey(key))
    }
    
    public func decrement(_ key: String) -> EventLoopFuture<Int> {
        return self.connection.decrement(RedisKey(key))
    }
    
    public func increment(_ key: String, by count: Int) -> EventLoopFuture<Int> {
        return self.connection.increment(RedisKey(key), by: count)
    }
    
    public func decrement(_ key: String, by count: Int) -> EventLoopFuture<Int> {
        return self.connection.decrement(RedisKey(key), by: count)
    }
}

extension DBRedisQuery {
    
    public func echo(_ message: String) -> EventLoopFuture<String> {
        return self.connection.echo(message)
    }
    
    public func ping(with message: String? = nil) -> EventLoopFuture<String> {
        return self.connection.ping(with: message)
    }
}

extension DBRedisQuery {
    
    public func exists(_ keys: [String]) -> EventLoopFuture<Int> {
        return self.connection.exists(keys.map { RedisKey($0) })
    }
    
    public func delete(_ keys: [String]) -> EventLoopFuture<Int> {
        return self.connection.delete(keys.map { RedisKey($0) })
    }
}

extension DBRedisQuery {
    
    public func get<D: Decodable>(_ key: String, as type: D.Type) -> EventLoopFuture<D?> {
        return self.connection.get(RedisKey(key), as: Data.self).flatMapThrowing { data in try data.flatMap { try JSONDecoder().decode(D.self, from: $0) } }
    }
    
    public func set<E: Encodable>(_ key: String, value: E) -> EventLoopFuture<Void> {
        do {
            return try self.connection.set(RedisKey(key), to: JSONEncoder().encode(value))
        } catch {
            return self.connection.eventLoop.makeFailedFuture(error)
        }
    }
}