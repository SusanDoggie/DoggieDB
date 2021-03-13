//
//  DBRedisDictionaryQuery.swift
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

public struct DBRedisDictionaryQuery {
    
    public let connection: RedisConnection
    
    public let key: String
}

extension DBRedisQuery {
    
    public func dictionary(of key: String) -> DBRedisDictionaryQuery {
        return DBRedisDictionaryQuery(connection: connection, key: key)
    }
}

extension DBRedisDictionaryQuery {
    
    public func toDictionary<D: Decodable>(as type: D.Type, decoder: _Decoder = BSONDecoder()) -> EventLoopFuture<[String: D]> {
        return self.connection.hgetall(from: RedisKey(key), as: Data.self).flatMapThrowing { try $0.compactMapValues { try $0.map { try decoder.decode(D.self, from: $0) } } }
    }
}

extension DBRedisDictionaryQuery {
    
    public func keys() -> EventLoopFuture<[String]> {
        return self.connection.hkeys(in: RedisKey(key))
    }
    
    public func values<D: Decodable>(as type: D.Type, decoder: _Decoder = BSONDecoder()) -> EventLoopFuture<[D]> {
        return self.connection.hvals(in: RedisKey(key), as: Data.self).flatMapThrowing { try $0.compactMap { try $0.map { try decoder.decode(D.self, from: $0) } } }
    }
}

extension DBRedisDictionaryQuery {
    
    public func exists(_ field: String) -> EventLoopFuture<Bool> {
        return self.connection.hexists(field, in: RedisKey(key))
    }
    
    public func delete(_ fields: [String]) -> EventLoopFuture<Int> {
        return self.connection.hdel(fields, from: RedisKey(key))
    }
}

extension DBRedisDictionaryQuery {
    
    public func fetch<D: Decodable>(_ field: String, as type: D.Type, decoder: _Decoder = BSONDecoder()) -> EventLoopFuture<D?> {
        return self.connection.hget(field, from: RedisKey(key), as: Data.self).flatMapThrowing { try $0.flatMap { try decoder.decode(D.self, from: $0) } }
    }
    
    public func store<E: Encodable>(_ field: String, value: E, encoder: _Encoder = BSONEncoder()) -> EventLoopFuture<Bool> {
        do {
            return try self.connection.hset(field, to: encoder.encode(value), in: RedisKey(key))
        } catch {
            return self.connection.eventLoop.makeFailedFuture(error)
        }
    }
}

extension DBRedisDictionaryQuery {
    
    public func increment<T: FixedWidthInteger>(_ field: String, by amount: T) -> EventLoopFuture<T> {
        return self.connection.hincrby(Int64(amount), field: field, in: RedisKey(key)).map { T($0) }
    }
    
    public func increment<T: BinaryFloatingPoint>(_ field: String, by amount: T) -> EventLoopFuture<T> {
        return self.connection.hincrbyfloat(Double(amount), field: field, in: RedisKey(key)).map(T.init)
    }
}
