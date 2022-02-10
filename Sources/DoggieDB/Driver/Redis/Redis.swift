//
//  Redis.swift
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

struct RedisDriver: DBDriverProtocol {
    
    static var defaultPort: Int { 6379 }
}

extension RedisDriver {
    
    class Connection: DBConnection {
        
        var driver: DBDriver { return .redis }
        
        let client: RedisConnection
        
        let logger: Logger
        
        var eventLoopGroup: EventLoopGroup { client.eventLoop }
        
        init(_ client: RedisConnection, _ logger: Logger) {
            self.client = client
            self.logger = logger
        }
        
        func close() -> EventLoopFuture<Void> {
            return client.close()
        }
    }
}

extension RedisDriver {
    
    static func connect(
        config: Database.Configuration,
        logger: Logger,
        on eventLoopGroup: EventLoopGroup
    ) -> EventLoopFuture<DBConnection> {
        
        do {
            
            let _config = try RedisConnection.Configuration(
                address: config.socketAddress[0],
                password: config.password,
                initialDatabase: config.database.flatMap(Int.init),
                defaultLogger: logger
            )
            
            return RedisConnection.make(
                configuration: _config,
                boundEventLoop: eventLoopGroup.next()
            ).map { Connection($0, logger) }
            
        } catch {
            
            return eventLoopGroup.next().makeFailedFuture(error)
        }
    }
}

extension RedisDriver.Connection {
    
    var isClosed: Bool {
        return !self.client.isConnected
    }
}

extension RedisDriver.Connection {
    
    func withTransaction<T>(
        _ transactionBody: @escaping (DBConnection) throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        
        fatalError("unsupported operation")
    }
    
    #if compiler(>=5.5.2) && canImport(_Concurrency)
    
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    func withTransaction<T>(
        _ transactionBody: (DBConnection) async throws -> T
    ) async throws -> T {
        
        fatalError("unsupported operation")
    }
    
    #endif
    
}

extension RedisDriver.Connection {
    
    func runCommand(
        _ string: String,
        _ binds: [RESPValue]
    ) -> EventLoopFuture<RESPValue> {
        
        let result = binds.isEmpty ? self.client.send(command: string) : self.client.send(command: string, with: binds)
        
        return result.flatMapResult { result in
            Result {
                if case let .error(error) = result {
                    throw error
                }
                return result
            }
        }
    }
}
