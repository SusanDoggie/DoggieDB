//
//  DBRedisQuery.swift
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

public struct DBRedisQuery {
    
    let connection: RedisDriver.Connection
    
}

extension DBConnection {
    
    public func redisQuery() -> DBRedisQuery {
        guard let connection = self as? RedisDriver.Connection else { fatalError("unsupported operation") }
        return DBRedisQuery(connection: connection)
    }
}

extension DBRedisQuery {
    
    public var client: RedisConnection {
        return connection.client
    }
    
    public var eventLoopGroup: EventLoopGroup {
        return connection.eventLoopGroup
    }
}

extension DBRedisQuery {
    
    public func exists(_ keys: [String]) async throws -> Int {
        return try await self.client.exists(keys.map { RedisKey($0) }).get()
    }
    
    public func delete(_ keys: [String]) async throws -> Int {
        return try await self.client.delete(keys.map { RedisKey($0) }).get()
    }
}

extension DBRedisQuery {
    
    public func fetch<Value: Codable>(_ keys: Set<String>, as: Value.Type, decoder: RedisDecoderProtocol = RedisDecoder()) async throws -> [String: Value] {
        let keys = Array(keys)
        return try await self.client.mget(keys.map { RedisKey($0) }).flatMapThrowing { try Dictionary(uniqueKeysWithValues: zip(keys, $0.map { try decoder.decode(Value.self, from: $0) })) }.get()
    }
    
    public func store<Value: Codable>(_ values: [String: Value], encoder: RedisEncoderProtocol = RedisEncoder()) async throws {
        try await self.client.mset(Dictionary(uniqueKeysWithValues: values.map { try (RedisKey($0.key), encoder.encode($0.value, as: RESPValue.self)) })).get()
    }
}
