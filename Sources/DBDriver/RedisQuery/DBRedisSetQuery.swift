//
//  DBRedisSetQuery.swift
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

public struct DBRedisSetQuery {
    
    public let connection: RedisConnection
    
    public let key: String
}

extension DBRedisQuery {
    
    public func set(of key: String) -> DBRedisSetQuery {
        return DBRedisSetQuery(connection: connection, key: key)
    }
}

extension DBRedisSetQuery {
    
    public func toArray() -> EventLoopFuture<[RESPValue]> {
        return self.connection.smembers(of: RedisKey(key))
    }
}

extension DBRedisSetQuery {
    
    public func count() -> EventLoopFuture<Int> {
        return self.connection.scard(of: RedisKey(key))
    }
}

extension DBRedisSetQuery {
    
    public func contains(_ value: RESPValue) -> EventLoopFuture<Bool> {
        return self.connection.sismember(value, of: RedisKey(key))
    }
}

extension DBRedisSetQuery {
    
    public func insert(_ value: RESPValue) -> EventLoopFuture<Int> {
        return self.connection.sadd([value], to: RedisKey(key))
    }
    
    public func insert<C: Collection>(_ values: C) -> EventLoopFuture<Int> where C.Element == RESPValue {
        return self.connection.sadd(Array(values), to: RedisKey(key))
    }
}

extension DBRedisSetQuery {
    
    public func randomElement() -> EventLoopFuture<RESPValue?> {
        return self.connection.srandmember(from: RedisKey(key)).map { $0[0] }
    }
    
    public func randomElements(_ count: Int) -> EventLoopFuture<[RESPValue]> {
        return self.connection.srandmember(from: RedisKey(key), max: count)
    }
}
