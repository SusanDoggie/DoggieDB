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

public protocol DBConnection: AnyObject {
    
    var driver: DBDriver { get }
    
    var eventLoop: EventLoop { get }
    
    var isClosed: Bool { get }
    
    func close() -> EventLoopFuture<Void>
    
    func version() -> EventLoopFuture<String>
    
    func databases() -> EventLoopFuture<[String]>
    
    func tables() -> EventLoopFuture<[String]>
    
    func views() -> EventLoopFuture<[String]>
    
    func materializedViews() -> EventLoopFuture<[String]>
    
    func tableInfo(_ table: String) -> EventLoopFuture<[DBQueryRow]>
    
    func execute(
        _ string: String,
        _ binds: [DBData]
    ) -> EventLoopFuture<[DBQueryRow]>
    
    func execute(
        _ string: String,
        _ binds: [DBData],
        onRow: @escaping (DBQueryRow) -> Void
    ) -> EventLoopFuture<DBQueryMetadata>
    
    var allowSubscriptions: Bool { get set }
    
    var isSubscribed: Bool { get }
    
    func activeChannels(matching match: String?) -> EventLoopFuture<[String]>
    
    func subscribe(
        toChannels channels: [String],
        messageReceiver receiver: @escaping (_ publisher: String, _ message: Result<DBData, Error>) -> Void,
        onSubscribe subscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)?,
        onUnsubscribe unsubscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)?
    ) -> EventLoopFuture<Void>
    
    func unsubscribe(fromChannels channels: [String]) -> EventLoopFuture<Void>
    
    func subscribe(
        toPatterns patterns: [String],
        messageReceiver receiver: @escaping (_ publisher: String, _ message: Result<DBData, Error>) -> Void,
        onSubscribe subscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)?,
        onUnsubscribe unsubscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)?
    ) -> EventLoopFuture<Void>
    
    func unsubscribe(fromPatterns patterns: [String]) -> EventLoopFuture<Void>
    
    func get<D: Decodable>(_ key: String, as type: D.Type) -> EventLoopFuture<D?>
    
    func set<E: Encodable>(_ key: String, as type: E) -> EventLoopFuture<Void>
}

extension DBConnection {
    
    public func version() -> EventLoopFuture<String> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
    
    public func databases() -> EventLoopFuture<[String]> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
    
    public func tables() -> EventLoopFuture<[String]> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
    
    public func views() -> EventLoopFuture<[String]> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
    
    public func materializedViews() -> EventLoopFuture<[String]> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
    
    public func tableInfo(_ table: String) -> EventLoopFuture<[DBQueryRow]> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
}

extension DBConnection {
    
    public func execute(
        _ string: String,
        _ binds: [DBData]
    ) -> EventLoopFuture<[DBQueryRow]> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
    
    public func execute(
        _ string: String,
        _ binds: [DBData],
        onRow: @escaping (DBQueryRow) -> Void
    ) -> EventLoopFuture<DBQueryMetadata> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
}

extension DBConnection {
    
    public var allowSubscriptions: Bool {
        get {
            return false
        }
        set {
            fatalError("unsupported operation")
        }
    }
    
    public var isSubscribed: Bool {
        return false
    }
    
    public func activeChannels(matching match: String? = nil) -> EventLoopFuture<[String]> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
    
    public func subscribe(
        toChannels channels: [String],
        messageReceiver receiver: @escaping (_ publisher: String, _ message: Result<DBData, Error>) -> Void,
        onSubscribe subscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)? = nil,
        onUnsubscribe unsubscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)? = nil
    ) -> EventLoopFuture<Void> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
    
    public func unsubscribe(fromChannels channels: [String]) -> EventLoopFuture<Void> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
    
    public func subscribe(
        toPatterns patterns: [String],
        messageReceiver receiver: @escaping (_ publisher: String, _ message: Result<DBData, Error>) -> Void,
        onSubscribe subscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)? = nil,
        onUnsubscribe unsubscribeHandler: ((_ subscriptionKey: String, _ currentSubscriptionCount: Int) -> Void)? = nil
    ) -> EventLoopFuture<Void> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
    
    public func unsubscribe(fromPatterns patterns: [String]) -> EventLoopFuture<Void> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
}

extension DBConnection {
    
    public func get<D: Decodable>(_ key: String, as type: D.Type) -> EventLoopFuture<D?> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
    
    public func set<E: Encodable>(_ key: String, as type: E) -> EventLoopFuture<Void> {
        return eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
    }
}
