//
//  DBConnection.swift
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

public protocol DBConnection: AnyObject, Sendable {
    
    var driver: DBDriver { get }
    
    var logger: Logger { get }
    
    var eventLoopGroup: EventLoopGroup { get }
    
    func bind(to eventLoop: EventLoop) -> DBConnection
    
    func close() async throws
    
    func version() async throws -> String
    
    func databases() async throws -> [String]
    
    func redisQuery() -> DBRedisQuery
    
    func redisPubSub() -> DBRedisPubSub
    
    func postgresPubSub() -> DBPostgresPubSub
    
    func withTransaction<T>(
        _ transactionBody: @escaping (DBConnection) async throws -> T
    ) async throws -> T
    
}

extension DBConnection {
    
    public func bind(to eventLoop: EventLoop) -> DBConnection {
        fatalError("unsupported operation")
    }
}

extension DBConnection {
    
    public func redisQuery() -> DBRedisQuery {
        fatalError("unsupported operation")
    }
    
    public func redisPubSub() -> DBRedisPubSub {
        fatalError("unsupported operation")
    }
}

extension DBConnection {
    
    public func postgresPubSub() -> DBPostgresPubSub {
        fatalError("unsupported operation")
    }
}

extension DBConnection {
    
    public func version() async throws -> String {
        throw Database.Error.unsupportedOperation
    }
    
    public func databases() async throws -> [String] {
        throw Database.Error.unsupportedOperation
    }
}
