//
//  DBRedisValue.swift
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

public struct DBRedisValue<Value: Codable> {
    
    public let connection: RedisConnection
    
    public let key: String
    
    var encoder: RedisEncoderProtocol = RedisEncoder()
    
    var decoder: RedisDecoderProtocol = RedisDecoder()
}

extension DBRedisValue {
    
    public func withEncoder(_ encoder: RedisEncoderProtocol) -> DBRedisValue {
        var builder = self
        builder.encoder = encoder
        return builder
    }
    
    public func withDecoder(_ decoder: RedisDecoderProtocol) -> DBRedisValue {
        var builder = self
        builder.decoder = decoder
        return builder
    }
}

extension DBRedisQuery {
    
    public func value<Value>(of key: String, as type: Value.Type) -> DBRedisValue<Value> {
        return DBRedisValue(connection: connection, key: key)
    }
}

extension DBRedisValue {
    
    public func fetch() -> EventLoopFuture<Value?> {
        return self.connection.get(RedisKey(key)).flatMapThrowing { try decoder.decode(Optional<Value>.self, from: $0) }
    }
    
    public func store(_ value: Value) -> EventLoopFuture<Void> {
        do {
            return try self.connection.set(RedisKey(key), to: encoder.encode(value, as: RESPValue.self))
        } catch {
            return self.connection.eventLoop.makeFailedFuture(error)
        }
    }
}

extension DBRedisValue {
    
    public func increment() -> EventLoopFuture<Int> {
        return self.connection.increment(RedisKey(key))
    }
    
    public func decrement() -> EventLoopFuture<Int> {
        return self.connection.decrement(RedisKey(key))
    }
    
    public func increment<T: FixedWidthInteger>(by amount: T) -> EventLoopFuture<T> {
        return self.connection.increment(RedisKey(key), by: Int64(amount)).map { T($0) }
    }
    
    public func decrement<T: FixedWidthInteger>(by amount: T) -> EventLoopFuture<T> {
        return self.connection.decrement(RedisKey(key), by: Int64(amount)).map { T($0) }
    }
    
    public func increment<T: BinaryFloatingPoint>(by amount: T) -> EventLoopFuture<T> {
        return self.connection.increment(RedisKey(key), by: Double(amount)).map(T.init)
    }
}
