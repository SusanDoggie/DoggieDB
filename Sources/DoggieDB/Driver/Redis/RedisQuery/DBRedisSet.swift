//
//  DBRedisSetQuery.swift
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

public struct DBRedisSet<Value: Codable> {
    
    let connection: RedisDriver.Connection
    
    public let client: RedisConnection
    
    public let key: String
    
    var encoder: RedisEncoderProtocol = RedisEncoder()
    
    var decoder: RedisDecoderProtocol = RedisDecoder()
}

extension DBRedisSet {
    
    public func withEncoder(_ encoder: RedisEncoderProtocol) -> DBRedisSet {
        var builder = self
        builder.encoder = encoder
        return builder
    }
    
    public func withDecoder(_ decoder: RedisDecoderProtocol) -> DBRedisSet {
        var builder = self
        builder.decoder = decoder
        return builder
    }
}

extension DBRedisQuery {
    
    public func set<Value>(of key: String, as type: Value.Type) -> DBRedisSet<Value> {
        return DBRedisSet(connection: connection, client: client, key: key)
    }
}

extension DBRedisSet {
    
    public func toArray() -> EventLoopFuture<[Value]> {
        return self.client.smembers(of: RedisKey(key)).flatMapThrowing { try $0.map { try decoder.decode(Value.self, from: $0) } }
    }
}

extension DBRedisSet {
    
    public func count() -> EventLoopFuture<Int> {
        return self.client.scard(of: RedisKey(key))
    }
}

extension DBRedisSet {
    
    public func contains(_ value: Value) -> EventLoopFuture<Bool> {
        do {
            return try self.client.sismember(encoder.encode(value, as: RESPValue.self), of: RedisKey(key))
        } catch {
            return self.client.eventLoop.makeFailedFuture(error)
        }
    }
}

extension DBRedisSet {
    
    public func insert(_ value: Value) -> EventLoopFuture<Int> {
        do {
            return try self.client.sadd(encoder.encode(value, as: RESPValue.self), to: RedisKey(key))
        } catch {
            return self.client.eventLoop.makeFailedFuture(error)
        }
    }
    
    public func insert<C: Collection>(_ values: C) -> EventLoopFuture<Int> where C.Element == Value {
        do {
            return try self.client.sadd(values.map { try encoder.encode($0, as: RESPValue.self) }, to: RedisKey(key))
        } catch {
            return self.client.eventLoop.makeFailedFuture(error)
        }
    }
}

extension DBRedisSet {
    
    public func remove(_ value: Value) -> EventLoopFuture<Int> {
        do {
            return try self.client.srem(encoder.encode(value, as: RESPValue.self), from: RedisKey(key))
        } catch {
            return self.client.eventLoop.makeFailedFuture(error)
        }
    }
    
    public func remove<C: Collection>(_ values: C) -> EventLoopFuture<Int> where C.Element == Value {
        do {
            return try self.client.srem(values.map { try encoder.encode($0, as: RESPValue.self) }, from: RedisKey(key))
        } catch {
            return self.client.eventLoop.makeFailedFuture(error)
        }
    }
}

extension DBRedisSet {
    
    public func randomElement() -> EventLoopFuture<Value?> {
        return self.client.srandmember(from: RedisKey(key)).flatMapThrowing { try decoder.decode(Optional<Value>.self, from: $0[0]) }
    }
    
    public func randomElements(_ count: Int) -> EventLoopFuture<[Value]> {
        return self.client.srandmember(from: RedisKey(key), max: count).flatMapThrowing { try $0.map { try decoder.decode(Value.self, from: $0) } }
    }
}

extension DBRedisSet {
    
    public func union(to others: DBRedisSet...) -> EventLoopFuture<[Value]> {
        return self.client.sunion(of: others.map { RedisKey($0.key) }).flatMapThrowing { try $0.map { try decoder.decode(Value.self, from: $0) } }
    }
    
    public func formUnion(to others: DBRedisSet...) -> EventLoopFuture<Int> {
        return self.client.sunionstore(as: RedisKey(key), sources: [RedisKey(key)] + others.map { RedisKey($0.key) })
    }
}

extension DBRedisSet {
    
    public func intersection(to others: DBRedisSet...) -> EventLoopFuture<[Value]> {
        return self.client.sinter(of: others.map { RedisKey($0.key) }).flatMapThrowing { try $0.map { try decoder.decode(Value.self, from: $0) } }
    }
    
    public func formIntersection(to others: DBRedisSet...) -> EventLoopFuture<Int> {
        return self.client.sinterstore(as: RedisKey(key), sources: [RedisKey(key)] + others.map { RedisKey($0.key) })
    }
}

extension DBRedisSet {
    
    public func subtracting(to others: DBRedisSet...) -> EventLoopFuture<[Value]> {
        return self.client.sdiff(of: others.map { RedisKey($0.key) }).flatMapThrowing { try $0.map { try decoder.decode(Value.self, from: $0) } }
    }
    
    public func subtract(to others: DBRedisSet...) -> EventLoopFuture<Int> {
        return self.client.sdiffstore(as: RedisKey(key), sources: [RedisKey(key)] + others.map { RedisKey($0.key) })
    }
}
