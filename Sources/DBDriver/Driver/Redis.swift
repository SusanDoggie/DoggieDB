//
//  Redis.swift
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

public struct RedisDriver: DBDriverProtocol {
    
    static var defaultPort: Int { 6379 }
}

extension RedisDriver {
    
    public class Connection: DBConnection {
        
        public var driver: DBDriver { return .redis }
        
        let connection: RedisConnection
        
        public var eventLoop: EventLoop { connection.eventLoop }
        
        init(_ connection: RedisConnection) {
            self.connection = connection
        }
        
        public func close() -> EventLoopFuture<Void> {
            return connection.close()
        }
    }
}

extension RedisDriver {
    
    static func connect(
        config: Database.Configuration,
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<DBConnection> {
        
        do {
            
            let _config = try RedisConnection.Configuration(
                address: config.socketAddress,
                password: config.password,
                initialDatabase: config.database.flatMap(Int.init),
                defaultLogger: logger
            )
            
            return RedisConnection.make(
                configuration: _config,
                boundEventLoop: eventLoop
            ).map(Connection.init)
            
        } catch let error {
            
            return eventLoop.makeFailedFuture(error)
        }
    }
}

extension RedisDriver.Connection {
    
    public var isClosed: Bool {
        return !self.connection.isConnected
    }
}

extension RedisDriver.Connection {
    
    func runCommand(
        _ string: String,
        _ binds: [RESPValue]
    ) -> EventLoopFuture<RESPValue> {
        
        let result = binds.isEmpty ? self.connection.send(command: string) : self.connection.send(command: string, with: binds)
        
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
