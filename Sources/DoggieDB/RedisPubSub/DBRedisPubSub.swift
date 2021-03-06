//
//  DBRedisPubSub.swift
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

public struct DBRedisPubSub {
    
    let connection: RedisConnection
}

extension DBRedisPubSub {
    
    public var eventLoop: EventLoop {
        return connection.eventLoop
    }
}

extension RedisDriver.Connection {
    
    public func redisPubSub() -> DBRedisPubSub {
        return DBRedisPubSub(connection: client)
    }
}

extension DBRedisPubSub {
    
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
    
    public func publish(
        _ message: String,
        to channel: String
    ) -> EventLoopFuture<Int> {
        return self.connection.publish(message.convertedToRESPValue(), to: RedisChannelName(channel))
    }
    
    public func subscriberCount(forChannels channels: [String]) -> EventLoopFuture<[String: Int]> {
        let channels = channels.map { RedisChannelName($0) }
        return self.connection.subscriberCount(forChannels:channels).map { Dictionary(uniqueKeysWithValues: $0.map { ($0.key.rawValue, $0.value) }) }
    }
    
    public func subscribe(
        toChannels channels: [String],
        messageReceiver receiver: @escaping (_ channel: String, _ message: String) -> Void,
        onSubscribe subscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)? = nil,
        onUnsubscribe unsubscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)? = nil
    ) -> EventLoopFuture<Void> {
        
        return self.connection.subscribe(
            to: channels.map { RedisChannelName($0) },
            messageReceiver: { publisher, message in message.string.map { receiver(publisher.rawValue, $0) } },
            onSubscribe: subscribeHandler,
            onUnsubscribe: unsubscribeHandler
        )
    }
    
    public func unsubscribe(fromChannels channels: [String]) -> EventLoopFuture<Void> {
        return self.connection.unsubscribe(from: channels.map { RedisChannelName($0) })
    }
    
    public func subscribe(
        toPatterns patterns: [String],
        messageReceiver receiver: @escaping (_ channel: String, _ message: String) -> Void,
        onSubscribe subscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)? = nil,
        onUnsubscribe unsubscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)? = nil
    ) -> EventLoopFuture<Void> {
        
        return self.connection.psubscribe(
            to: patterns,
            messageReceiver: { publisher, message in message.string.map { receiver(publisher.rawValue, $0) } },
            onSubscribe: subscribeHandler,
            onUnsubscribe: unsubscribeHandler
        )
    }
    
    public func unsubscribe(fromPatterns patterns: [String]) -> EventLoopFuture<Void> {
        return self.connection.punsubscribe(from: patterns)
    }
}
