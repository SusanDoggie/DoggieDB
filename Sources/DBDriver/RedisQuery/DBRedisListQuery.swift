//
//  DBRedisListQuery.swift
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

public struct DBRedisListQuery {
    
    public let connection: RedisConnection
    
    public let key: String
}

extension DBRedisQuery {
    
    public func list(of key: String) -> DBRedisListQuery {
        return DBRedisListQuery(connection: connection, key: key)
    }
}

extension DBRedisListQuery {
    
    public func toArray<D: Decodable>(as type: D.Type, decoder: _Decoder = BSONDecoder()) -> EventLoopFuture<[D]> {
        return self.subrange(0..., as: type, decoder: decoder)
    }
}

extension DBRedisListQuery {
    
    public func count() -> EventLoopFuture<Int> {
        return self.connection.llen(of: RedisKey(key))
    }
}

extension DBRedisListQuery {
    
    public func subrange<D: Decodable>(_ range: PartialRangeFrom<Int>, as type: D.Type, decoder: _Decoder = BSONDecoder()) -> EventLoopFuture<[D]> {
        return self.connection.lrange(from: RedisKey(key), fromIndex: range.lowerBound, as: Data.self).flatMapThrowing { try $0.compactMap { try $0.map { try decoder.decode(D.self, from: $0) } } }
    }
    
    public func subrange<D: Decodable>(_ range: PartialRangeUpTo<Int>, as type: D.Type, decoder: _Decoder = BSONDecoder()) -> EventLoopFuture<[D]> {
        return self.connection.lrange(from: RedisKey(key), upToIndex: range.upperBound, as: Data.self).flatMapThrowing { try $0.compactMap { try $0.map { try decoder.decode(D.self, from: $0) } } }
    }
    
    public func subrange<D: Decodable>(_ range: PartialRangeThrough<Int>, as type: D.Type, decoder: _Decoder = BSONDecoder()) -> EventLoopFuture<[D]> {
        return self.connection.lrange(from: RedisKey(key), throughIndex: range.upperBound, as: Data.self).flatMapThrowing { try $0.compactMap { try $0.map { try decoder.decode(D.self, from: $0) } } }
    }
    
    public func subrange<D: Decodable>(_ range: Range<Int>, as type: D.Type, decoder: _Decoder = BSONDecoder()) -> EventLoopFuture<[D]> {
        return self.connection.lrange(from: RedisKey(key), indices: range, as: Data.self).flatMapThrowing { try $0.compactMap { try $0.map { try decoder.decode(D.self, from: $0) } } }
    }
    
    public func subrange<D: Decodable>(_ range: ClosedRange<Int>, as type: D.Type, decoder: _Decoder = BSONDecoder()) -> EventLoopFuture<[D]> {
        return self.connection.lrange(from: RedisKey(key), indices: range, as: Data.self).flatMapThrowing { try $0.compactMap { try $0.map { try decoder.decode(D.self, from: $0) } } }
    }
}

extension DBRedisListQuery {
    
    public func trim(_ range: PartialRangeFrom<Int>) -> EventLoopFuture<Void> {
        return self.connection.ltrim(RedisKey(key), keepingIndices: range)
    }
    
    public func trim(_ range: PartialRangeUpTo<Int>) -> EventLoopFuture<Void> {
        return self.connection.ltrim(RedisKey(key), keepingIndices: range)
    }
    
    public func trim(_ range: PartialRangeThrough<Int>) -> EventLoopFuture<Void> {
        return self.connection.ltrim(RedisKey(key), keepingIndices: range)
    }
    
    public func trim(_ range: Range<Int>) -> EventLoopFuture<Void> {
        return self.connection.ltrim(RedisKey(key), keepingIndices: range)
    }
    
    public func trim(_ range: ClosedRange<Int>) -> EventLoopFuture<Void> {
        return self.connection.ltrim(RedisKey(key), keepingIndices: range)
    }
}

extension DBRedisListQuery {
    
    public func insertFirst<E: Encodable>(_ value: E, encoder: _Encoder = BSONEncoder()) -> EventLoopFuture<Int> {
        do {
            return try self.connection.lpush([encoder.encode(value)], into: RedisKey(key))
        } catch {
            return self.connection.eventLoop.makeFailedFuture(error)
        }
    }
    
    public func insertFirst<C: Collection>(contentsOf values: C, encoder: _Encoder = BSONEncoder()) -> EventLoopFuture<Int> where C.Element: Encodable {
        do {
            return try self.connection.lpush(values.map { try encoder.encode($0) }, into: RedisKey(key))
        } catch {
            return self.connection.eventLoop.makeFailedFuture(error)
        }
    }
}

extension DBRedisListQuery {
    
    public func append<E: Encodable>(_ value: E, encoder: _Encoder = BSONEncoder()) -> EventLoopFuture<Int> {
        do {
            return try self.connection.rpush([encoder.encode(value)], into: RedisKey(key))
        } catch {
            return self.connection.eventLoop.makeFailedFuture(error)
        }
    }
    
    public func append<C: Collection>(contentsOf values: C, encoder: _Encoder = BSONEncoder()) -> EventLoopFuture<Int> where C.Element: Encodable {
        do {
            return try self.connection.rpush(values.map { try encoder.encode($0) }, into: RedisKey(key))
        } catch {
            return self.connection.eventLoop.makeFailedFuture(error)
        }
    }
}

extension DBRedisListQuery {
    
    public func popFirst<D: Decodable>(as type: D.Type, decoder: _Decoder = BSONDecoder()) -> EventLoopFuture<D?> {
        return self.connection.lpop(from: RedisKey(key), as: Data.self).flatMapThrowing { try $0.map { try decoder.decode(D.self, from: $0) } }
    }
    
    public func popLast<D: Decodable>(as type: D.Type, decoder: _Decoder = BSONDecoder()) -> EventLoopFuture<D?> {
        return self.connection.rpop(from: RedisKey(key), as: Data.self).flatMapThrowing { try $0.map { try decoder.decode(D.self, from: $0) } }
    }
    
    public func popPush<D: Decodable>(to other: DBRedisListQuery, as type: D.Type, decoder: _Decoder = BSONDecoder()) -> EventLoopFuture<D?> {
        return self.connection.rpoplpush(from: RedisKey(key), to: RedisKey(other.key), valueType: Data.self).flatMapThrowing { try $0.map { try decoder.decode(D.self, from: $0) } }
    }
}

extension DBRedisListQuery {
    
    public func get<D: Decodable>(_ index: Int, as type: D.Type, decoder: _Decoder = BSONDecoder()) -> EventLoopFuture<D?> {
        return self.connection.lindex(index, from: RedisKey(key), as: Data.self).flatMapThrowing { try $0.map { try decoder.decode(D.self, from: $0) } }
    }
    
    public func set<E: Encodable>(_ index: Int, value: E, encoder: _Encoder = BSONEncoder()) -> EventLoopFuture<Void> {
        do {
            return try self.connection.lset(index: index, to: encoder.encode(value), in: RedisKey(key))
        } catch {
            return self.connection.eventLoop.makeFailedFuture(error)
        }
    }
}
