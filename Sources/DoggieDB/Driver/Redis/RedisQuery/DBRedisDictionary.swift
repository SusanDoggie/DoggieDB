//
//  DBRedisDictionaryQuery.swift
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

public struct DBRedisDictionary<Value: Codable> {
    
    let connection: RedisDriver.Connection
    
    public let client: RedisConnection
    
    public let key: String
    
    var encoder: RedisEncoderProtocol = RedisEncoder()
    
    var decoder: RedisDecoderProtocol = RedisDecoder()
}

extension DBRedisDictionary {
    
    public func withEncoder(_ encoder: RedisEncoderProtocol) -> DBRedisDictionary {
        var builder = self
        builder.encoder = encoder
        return builder
    }
    
    public func withDecoder(_ decoder: RedisDecoderProtocol) -> DBRedisDictionary {
        var builder = self
        builder.decoder = decoder
        return builder
    }
}

extension DBRedisQuery {
    
    public func dictionary<Value>(of key: String, as type: Value.Type) -> DBRedisDictionary<Value> {
        return DBRedisDictionary(connection: connection, client: client, key: key)
    }
}

extension DBRedisDictionary {
    
    public func toDictionary() -> EventLoopFuture<[String: Value]> {
        return self.client.hgetall(from: RedisKey(key)).flatMapThrowing { try $0.mapValues { try decoder.decode(Value.self, from: $0) } }
    }
}

extension DBRedisDictionary {
    
    public func keys() -> EventLoopFuture<[String]> {
        return self.client.hkeys(in: RedisKey(key))
    }
    
    public func values() -> EventLoopFuture<[Value]> {
        return self.client.hvals(in: RedisKey(key)).flatMapThrowing { try $0.map { try decoder.decode(Value.self, from: $0) } }
    }
}

extension DBRedisDictionary {
    
    public func exists(_ field: String) -> EventLoopFuture<Bool> {
        return self.client.hexists(field, in: RedisKey(key))
    }
    
    public func delete(_ fields: [String]) -> EventLoopFuture<Int> {
        return self.client.hdel(fields, from: RedisKey(key))
    }
}

extension DBRedisDictionary {
    
    public func fetch(_ field: String) -> EventLoopFuture<Value?> {
        return self.client.hget(field, from: RedisKey(key)).flatMapThrowing { try decoder.decode(Optional<Value>.self, from: $0) }
    }
    
    public func store(_ field: String, value: Value) -> EventLoopFuture<Bool> {
        do {
            return try self.client.hset(field, to: encoder.encode(value, as: RESPValue.self), in: RedisKey(key))
        } catch {
            return self.client.eventLoop.makeFailedFuture(error)
        }
    }
}

extension DBRedisDictionary {
    
    public func increment<T: FixedWidthInteger>(_ field: String, by amount: T) -> EventLoopFuture<T> {
        return self.client.hincrby(Int64(amount), field: field, in: RedisKey(key)).map { T($0) }
    }
    
    public func increment<T: BinaryFloatingPoint>(_ field: String, by amount: T) -> EventLoopFuture<T> {
        return self.client.hincrbyfloat(Double(amount), field: field, in: RedisKey(key)).map(T.init)
    }
}
