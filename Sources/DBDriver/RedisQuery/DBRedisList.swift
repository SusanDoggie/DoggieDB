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

public struct DBRedisList<Value: Codable> {
    
    public let connection: RedisConnection
    
    public let key: String
    
    var encoder: RedisEncoderProtocol = RedisEncoder()
    
    var decoder: RedisDecoderProtocol = RedisDecoder()
}

extension DBRedisList {
    
    public func withEncoder(_ encoder: RedisEncoderProtocol) -> DBRedisList {
        var builder = self
        builder.encoder = encoder
        return builder
    }
    
    public func withDecoder(_ decoder: RedisDecoderProtocol) -> DBRedisList {
        var builder = self
        builder.decoder = decoder
        return builder
    }
}

extension DBRedisQuery {
    
    public func list<Value>(of key: String, as type: Value.Type) -> DBRedisList<Value> {
        return DBRedisList(connection: connection, key: key)
    }
}

extension DBRedisList {
    
    public func toArray() -> EventLoopFuture<[Value]> {
        return self.subrange(0...)
    }
}

extension DBRedisList {
    
    public func count() -> EventLoopFuture<Int> {
        return self.connection.llen(of: RedisKey(key))
    }
}

extension DBRedisList {
    
    public func subrange(_ range: PartialRangeFrom<Int>) -> EventLoopFuture<[Value]> {
        return self.connection.lrange(from: RedisKey(key), fromIndex: range.lowerBound).flatMapThrowing { try $0.map { try decoder.decode(Value.self, from: $0) } }
    }
    
    public func subrange(_ range: PartialRangeUpTo<Int>) -> EventLoopFuture<[Value]> {
        return self.connection.lrange(from: RedisKey(key), upToIndex: range.upperBound).flatMapThrowing { try $0.map { try decoder.decode(Value.self, from: $0) } }
    }
    
    public func subrange(_ range: PartialRangeThrough<Int>) -> EventLoopFuture<[Value]> {
        return self.connection.lrange(from: RedisKey(key), throughIndex: range.upperBound).flatMapThrowing { try $0.map { try decoder.decode(Value.self, from: $0) } }
    }
    
    public func subrange(_ range: Range<Int>) -> EventLoopFuture<[Value]> {
        return self.connection.lrange(from: RedisKey(key), indices: range).flatMapThrowing { try $0.map { try decoder.decode(Value.self, from: $0) } }
    }
    
    public func subrange(_ range: ClosedRange<Int>) -> EventLoopFuture<[Value]> {
        return self.connection.lrange(from: RedisKey(key), indices: range).flatMapThrowing { try $0.map { try decoder.decode(Value.self, from: $0) } }
    }
}

extension DBRedisList {
    
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

extension DBRedisList {
    
    public func insertFirst(_ value: Value) -> EventLoopFuture<Int> {
        do {
            return try self.connection.lpush(encoder.encode(value, as: RESPValue.self), into: RedisKey(key))
        } catch {
            return self.connection.eventLoop.makeFailedFuture(error)
        }
    }
    
    public func insertFirst<C: Collection>(contentsOf values: C) -> EventLoopFuture<Int> where C.Element == Value {
        do {
            return try self.connection.lpush(values.map { try encoder.encode($0, as: RESPValue.self) }, into: RedisKey(key))
        } catch {
            return self.connection.eventLoop.makeFailedFuture(error)
        }
    }
}

extension DBRedisList {
    
    public func append(_ value: Value) -> EventLoopFuture<Int> {
        do {
            return try self.connection.rpush(encoder.encode(value, as: RESPValue.self), into: RedisKey(key))
        } catch {
            return self.connection.eventLoop.makeFailedFuture(error)
        }
    }
    
    public func append<C: Collection>(contentsOf values: C) -> EventLoopFuture<Int> where C.Element == Value {
        do {
            return try self.connection.rpush(values.map { try encoder.encode($0, as: RESPValue.self) }, into: RedisKey(key))
        } catch {
            return self.connection.eventLoop.makeFailedFuture(error)
        }
    }
}

extension DBRedisList {
    
    public func popFirst() -> EventLoopFuture<Value?> {
        return self.connection.lpop(from: RedisKey(key)).flatMapThrowing { try decoder.decode(Optional<Value>.self, from: $0) }
    }
    
    public func popLast() -> EventLoopFuture<Value?> {
        return self.connection.rpop(from: RedisKey(key)).flatMapThrowing { try decoder.decode(Optional<Value>.self, from: $0) }
    }
    
    public func popPush(to other: DBRedisList) -> EventLoopFuture<Value?> {
        return self.connection.rpoplpush(from: RedisKey(key), to: RedisKey(other.key)).flatMapThrowing { try decoder.decode(Optional<Value>.self, from: $0) }
    }
}

extension DBRedisList {
    
    public func fetch(_ index: Int) -> EventLoopFuture<Value?> {
        return self.connection.lindex(index, from: RedisKey(key)).flatMapThrowing { try decoder.decode(Optional<Value>.self, from: $0) }
    }
    
    public func store(_ index: Int, value: Value) -> EventLoopFuture<Void> {
        do {
            return try self.connection.lset(index: index, to: encoder.encode(value, as: RESPValue.self), in: RedisKey(key))
        } catch {
            return self.connection.eventLoop.makeFailedFuture(error)
        }
    }
}
