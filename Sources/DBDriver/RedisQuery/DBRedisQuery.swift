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
import SwiftBSON

public struct DBRedisQuery {
    
    let connection: RedisConnection
}

extension RedisDriver.Connection {
    
    public func redisQuery() -> DBRedisQuery {
        return DBRedisQuery(connection: connection)
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
    
    public func fetch<Value: Codable>(_ keys: Set<String>, as: Value.Type, decoder: RedisDecoderProtocol = RedisDecoder()) -> EventLoopFuture<[String: Value]> {
        let keys = Array(keys)
        return self.connection.mget(keys.map { RedisKey($0) }).flatMapThrowing { try Dictionary(uniqueKeysWithValues: zip(keys, $0.map { try decoder.decode(Value.self, from: $0) })) }
    }
    
    public func store<Value: Codable>(_ values: [String: Value], encoder: RedisEncoderProtocol = RedisEncoder()) -> EventLoopFuture<Void> {
        do {
            return try self.connection.mset(Dictionary(uniqueKeysWithValues: values.map { try (RedisKey($0.key), encoder.encode($0.value, as: RESPValue.self)) }))
        } catch {
            return self.connection.eventLoop.makeFailedFuture(error)
        }
    }
}
