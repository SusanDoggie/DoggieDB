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

import MongoSwift

public actor DBMongoPubSub {
    
    weak var connection: DBMongoConnectionProtocol?
    
    var subscribes: [String: MongoCursor<BSONDocument>] = [:]
    var callbacks: [String: [(DBConnection, BSON) -> Void]] = [:]
    
    init(connection: DBMongoConnectionProtocol) {
        self.connection = connection
    }
    
    deinit {
        subscribes.values.forEach { _ = $0.kill() }
    }
}

extension DBConnection {
    
    public func mongoPubSub() -> DBMongoPubSub {
        guard let connection = self as? DBMongoConnectionProtocol else { fatalError("unsupported operation") }
        return connection._mongoPubSub
    }
}

extension DBMongoPubSub {
    
    private func create_capped_collection(
        name: String,
        size: Int,
        documentsCount: Int?
    ) async throws {
        
        guard let connection = self.connection else { return }
        
        do {
            
            var query = connection.mongoQuery()
                .createCollection(name)
                .capped(true)
                .size(size)
            
            if let documentsCount = documentsCount {
                query = query.max(documentsCount)
            }
            
            try await query.execute()
            
        } catch let error as MongoError.CommandError {
            
            if error.code == 48 { // Collection already exists
                return
            }
            
            throw error
        }
    }
}

extension DBMongoPubSub {
    
    public func publish(
        _ message: BSON,
        size: Int,
        documentsCount: Int? = nil,
        to channel: String
    ) async throws {
        
        guard let connection = self.connection else { return }
        
        try await self.create_capped_collection(name: channel, size: size, documentsCount: documentsCount)
        
        try await connection.mongoQuery().collection(channel).insertOne().value(["message": message]).execute()
    }
    
    public func subscribe(
        channel: String,
        size: Int,
        documentsCount: Int? = nil,
        handler: @escaping (_ connection: DBConnection, _ channel: String, _ message: BSON) -> Void
    ) async throws {
        
        guard let connection = self.connection else { return }
        
        if subscribes[channel] == nil {
            
            try await self.create_capped_collection(name: channel, size: size, documentsCount: documentsCount)
            let queue = try await connection.mongoQuery().collection(channel).find().execute()
            
            subscribes[channel] = queue
            
            Task { [weak self] in
                
                while let message = try? await queue.next().get()?["message"] {
                    
                    guard let connection = await self?.connection else { return }
                    guard let callbacks = await self?.callbacks[channel] else { return }
                    
                    for callback in callbacks {
                        callback(connection, message)
                    }
                }
            }
        }
        
        callbacks[channel, default: []].append { handler($0, channel, $1) }
    }
    
    public func unsubscribe(channel: String) async throws {
        try await subscribes[channel]?.kill().get()
        subscribes[channel] = nil
        callbacks[channel] = nil
    }
}
