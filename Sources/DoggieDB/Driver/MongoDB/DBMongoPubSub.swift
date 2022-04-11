//
//  DBMongoPubSub.swift
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

public struct DBMongoPubSub: Sendable {
    
    let connection: DBMongoConnectionProtocol
    
}

extension DBMongoPubSub {
    
    public var eventLoopGroup: EventLoopGroup {
        return connection.eventLoopGroup
    }
}

extension DBConnection {
    
    public func mongoPubSub() -> DBMongoPubSub {
        guard let connection = self as? DBMongoConnectionProtocol else { fatalError("unsupported operation") }
        return DBMongoPubSub(connection: connection)
    }
}

extension MongoDBDriver {
    
    actor Subscribers {
        
        var runloops: [String: Task<Void, Never>] = [:]
        
        var callbacks: [String: [@Sendable (DBConnection, BSON) -> Void]] = [:]
        
    }
}

extension MongoDBDriver.Subscribers {
    
    func closed() {
        for runloop in runloops.values {
            runloop.cancel()
        }
        runloops = [:]
        callbacks = [:]
    }
}

extension DBMongoConnectionProtocol {
    
    fileprivate func create_capped_collection(
        name: String,
        size: Int,
        documentsCount: Int
    ) async throws {
        
        do {
            
            var query = self.mongoQuery()
                .createCollection(name)
                .capped(true)
                .size(size)
            
            if documentsCount != .max {
                query = query.max(documentsCount)
            }
            
            try await query.execute()
            
            try await self.mongoQuery().collection(name).insertOne().value([:]).execute()
            
        } catch let error as MongoError.CommandError {
            
            if error.code == 48 { // Collection already exists
                return
            }
            
            throw error
        }
    }
}

extension MongoDBDriver.Subscribers {
    
    fileprivate func subscribe(
        connection: DBMongoConnectionProtocol,
        channel: String,
        size: Int,
        documentsCount: Int,
        handler: @Sendable @escaping (_ connection: DBConnection, _ channel: String, _ message: BSON) -> Void
    ) async throws {
        
        if runloops[channel] == nil {
            
            try await connection.create_capped_collection(name: channel, size: size, documentsCount: documentsCount)
            
            runloops[channel] = Task.detached { [weak self] in
                
                let start_time = Date()
                
                while !Task.isCancelled {
                    
                    do {
                        
                        let queue = try await connection.mongoQuery().collection(channel).find().cursorType(.tailable).execute()
                        
                        try await withTaskCancellationHandler {
                            
                            while let message = try await queue.next() {
                                
                                guard let callbacks = await self?.callbacks[channel] else { return }
                                
                                guard let timestamp = message["timestamp"]?.dateValue, timestamp > start_time else { continue }
                                guard let message = message["message"] else { continue }
                                
                                for callback in callbacks {
                                    callback(connection, message)
                                }
                            }
                            
                        } onCancel: { _ = queue.kill() }
                        
                    } catch {
                        
                        connection.logger.error("\(error)")
                    }
                }
            }
        }
        
        callbacks[channel, default: []].append { handler($0, channel, $1) }
    }
    
    fileprivate func unsubscribe(channel: String) {
        runloops[channel]?.cancel()
        runloops[channel] = nil
        callbacks[channel] = nil
    }
}

extension DBMongoPubSub {
    
    public static let default_capped_size: Int = 4096
    
    public func publish(
        _ message: BSON,
        size: Int = default_capped_size,
        documentsCount: Int = .max,
        to channel: String
    ) async throws {
        
        try await connection.create_capped_collection(name: channel, size: size, documentsCount: documentsCount)
        
        try await connection.mongoQuery().collection(channel).insertOne().value(["message": message, "timestamp": BSON(Date())]).execute()
    }
    
    public func subscribe(
        channel: String,
        size: Int = default_capped_size,
        documentsCount: Int = .max,
        handler: @Sendable @escaping (_ connection: DBConnection, _ channel: String, _ message: BSON) -> Void
    ) async throws {
        try await connection.subscribers.subscribe(connection: connection, channel: channel, size: size, documentsCount: documentsCount, handler: handler)
    }
    
    public func unsubscribe(channel: String) async {
        await connection.subscribers.unsubscribe(channel: channel)
    }
}
