//
//  DBRedisPubSub.swift
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

import RediStack

public struct DBRedisPubSub {
    
    let connection: RedisDriver.Connection
    
}

extension DBConnection {
    
    public func redisPubSub() -> DBRedisPubSub {
        guard let connection = self as? RedisDriver.Connection else { fatalError("unsupported operation") }
        return DBRedisPubSub(connection: connection)
    }
}

extension DBRedisPubSub {
    
    public var eventLoop: EventLoop {
        return connection.client.eventLoop
    }
}

extension DBRedisPubSub {
    
    public var allowSubscriptions: Bool {
        get {
            return self.connection.client.allowSubscriptions
        }
        set {
            self.connection.client.allowSubscriptions = newValue
        }
    }
    
    public var isSubscribed: Bool {
        return self.connection.client.isSubscribed
    }
    
    public func activeChannels(matching match: String? = nil) async throws -> [String] {
        return try await self.connection.client.activeChannels(matching: match).map { $0.map { $0.rawValue } }.get()
    }
    
    public func publish(
        _ message: String,
        to channel: String
    ) async throws -> Int {
        return try await self.connection.client.publish(message.convertedToRESPValue(), to: RedisChannelName(channel)).get()
    }
    
    public func subscriberCount(forChannels channels: [String]) async throws -> [String: Int] {
        let channels = channels.map { RedisChannelName($0) }
        return try await self.connection.client.subscriberCount(forChannels:channels).map { Dictionary(uniqueKeysWithValues: $0.map { ($0.key.rawValue, $0.value) }) }.get()
    }
    
    public func subscribe(
        toChannels channels: [String],
        messageReceiver receiver: @escaping (_ connection: DBConnection, _ channel: String, _ message: String) -> Void,
        onSubscribe subscribeHandler: ((_ connection: DBConnection, _ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)? = nil,
        onUnsubscribe unsubscribeHandler: ((_ connection: DBConnection, _ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)? = nil
    ) async throws {
        
        try await self.connection.client.subscribe(
            to: channels.map { RedisChannelName($0) },
            messageReceiver: { [weak connection] publisher, message in
                guard let connection = connection else { return }
                message.string.map { receiver(connection, publisher.rawValue, $0) }
            },
            onSubscribe: subscribeHandler.map { subscribeHandler in { [weak connection] subscriptionKey, currentSubscriptionCount in
                guard let connection = connection else { return }
                subscribeHandler(connection, subscriptionKey, currentSubscriptionCount)
            } },
            onUnsubscribe: unsubscribeHandler.map { unsubscribeHandler in { [weak connection] subscriptionKey, currentSubscriptionCount in
                guard let connection = connection else { return }
                unsubscribeHandler(connection, subscriptionKey, currentSubscriptionCount)
            } }
        ).get()
    }
    
    public func unsubscribe(fromChannels channels: [String]) async throws {
        try await self.connection.client.unsubscribe(from: channels.map { RedisChannelName($0) }).get()
    }
    
    public func subscribe(
        toPatterns patterns: [String],
        messageReceiver receiver: @escaping (_ connection: DBConnection, _ channel: String, _ message: String) -> Void,
        onSubscribe subscribeHandler: ((_ connection: DBConnection, _ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)? = nil,
        onUnsubscribe unsubscribeHandler: ((_ connection: DBConnection, _ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)? = nil
    ) async throws {
        
        try await self.connection.client.psubscribe(
            to: patterns,
            messageReceiver: { [weak connection] publisher, message in
                guard let connection = connection else { return }
                message.string.map { receiver(connection, publisher.rawValue, $0) }
            },
            onSubscribe: subscribeHandler.map { subscribeHandler in { [weak connection] subscriptionKey, currentSubscriptionCount in
                guard let connection = connection else { return }
                subscribeHandler(connection, subscriptionKey, currentSubscriptionCount)
            } },
            onUnsubscribe: unsubscribeHandler.map { unsubscribeHandler in { [weak connection] subscriptionKey, currentSubscriptionCount in
                guard let connection = connection else { return }
                unsubscribeHandler(connection, subscriptionKey, currentSubscriptionCount)
            } }
        ).get()
    }
    
    public func unsubscribe(fromPatterns patterns: [String]) async throws {
        try await self.connection.client.punsubscribe(from: patterns).get()
    }
}
