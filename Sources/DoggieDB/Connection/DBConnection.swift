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

public protocol DBConnection: AnyObject {
    
    var driver: DBDriver { get }
    
    var logger: Logger { get }
    
    var eventLoopGroup: EventLoopGroup { get }
    
    var isClosed: Bool { get }
    
    func bind(to eventLoop: EventLoop) -> DBConnection
    
    func close() -> EventLoopFuture<Void>
    
    func version() -> EventLoopFuture<String>
    
    func databases() -> EventLoopFuture<[String]>
    
    func redisQuery() -> DBRedisQuery
    
    func redisPubSub() -> DBRedisPubSub
    
    func postgresPubSub() -> DBPostgresPubSub
    
    func withTransaction<T>(
        _ transactionBody: @escaping (DBConnection) throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T>
    
    #if compiler(>=5.5.2) && canImport(_Concurrency)
    
    func withTransaction<T>(
        _ transactionBody: (DBConnection) async throws -> T
    ) async throws -> T
    
    #endif

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
    
    public func version() -> EventLoopFuture<String> {
        return eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
    }
    
    public func databases() -> EventLoopFuture<[String]> {
        return eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
    }
}
