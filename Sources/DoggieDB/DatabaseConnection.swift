//
//  DatabaseConnection.swift
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

public protocol DatabaseConnection: AnyObject {
    
    var eventLoop: EventLoop { get }
    
    func close() -> EventLoopFuture<Void>
    
    func databases() -> EventLoopFuture<[DatabaseConnection]>
    
    func query(
        _ string: String,
        _ binds: [QueryData]
    ) -> EventLoopFuture<[QueryRow]>
    
    func query(
        _ string: String,
        _ binds: [QueryData],
        onRow: @escaping (QueryRow) -> Void
    ) -> EventLoopFuture<QueryMetadata>
    
    func subscribe(
        toChannels channels: [String],
        messageReceiver receiver: @escaping (_ publisher: String, _ message: QueryData) -> Void,
        onSubscribe subscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)?,
        onUnsubscribe unsubscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)?
    ) -> EventLoopFuture<Void>
    
    func unsubscribe(fromChannels channels: [String]) -> EventLoopFuture<Void>
    
    func subscribe(
        toPatterns patterns: [String],
        messageReceiver receiver: @escaping (_ publisher: String, _ message: QueryData) -> Void,
        onSubscribe subscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)?,
        onUnsubscribe unsubscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)?
    ) -> EventLoopFuture<Void>
    
    func unsubscribe(fromPatterns patterns: [String]) -> EventLoopFuture<Void>
    
    func get<D>(_ key: String, as type: D.Type) -> EventLoopFuture<D?> where D: Decodable
    
    func set<E>(_ key: String, as type: E) -> EventLoopFuture<Void> where E: Encodable
}

extension DatabaseConnection {
    
    public func databases() -> EventLoopFuture<[DatabaseConnection]> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
}

extension DatabaseConnection {
    
    public func query(
        _ string: String,
        _ binds: [QueryData],
        onRow: @escaping (QueryRow) -> Void
    ) -> EventLoopFuture<QueryMetadata> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
}

extension DatabaseConnection {
    
    func subscribe(
        toChannels channels: [String],
        messageReceiver receiver: @escaping (_ publisher: String, _ message: QueryData) -> Void,
        onSubscribe subscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)?,
        onUnsubscribe unsubscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)?
    ) -> EventLoopFuture<Void> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
    
    func unsubscribe(fromChannels channels: [String]) -> EventLoopFuture<Void> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
    
    func subscribe(
        toPatterns patterns: [String],
        messageReceiver receiver: @escaping (_ publisher: String, _ message: QueryData) -> Void,
        onSubscribe subscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)?,
        onUnsubscribe unsubscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)?
    ) -> EventLoopFuture<Void> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
    
    func unsubscribe(fromPatterns patterns: [String]) -> EventLoopFuture<Void> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
}

extension DatabaseConnection {
    
    public func get<D>(_ key: String, as type: D.Type) -> EventLoopFuture<D?> where D: Decodable {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
    
    public func set<E>(_ key: String, as type: E) -> EventLoopFuture<Void> where E: Encodable {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
}

protocol SQLDatabaseConnection: DatabaseConnection {
    
}
