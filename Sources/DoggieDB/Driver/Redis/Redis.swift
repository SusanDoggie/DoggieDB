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
    
    final class Connection: DBConnection, @unchecked Sendable {
        
        var driver: DBDriver { return .redis }
        
        let client: RedisConnection
        
        let logger: Logger
        
        var eventLoopGroup: EventLoopGroup { client.eventLoop }
        
        init(_ client: RedisConnection, _ logger: Logger) {
            self.client = client
            self.logger = logger
        }
        
        func close() async throws {
            try await client.close().get()
        }
    }
}

extension RedisDriver {
    
    static func connect(
        config: Database.Configuration,
        logger: Logger,
        on eventLoopGroup: EventLoopGroup
    ) async throws -> DBConnection {
        
        let _config = try RedisConnection.Configuration(
            address: config.socketAddress[0],
            password: config.password,
            initialDatabase: config.database.flatMap(Int.init),
            defaultLogger: logger
        )
        
        let connection = try await RedisConnection.make(
            configuration: _config,
            boundEventLoop: eventLoopGroup.next()
        ).get()
        
        return Connection(connection, logger)
    }
}

extension RedisDriver.Connection {
    
    func withTransaction<T>(
        _ transactionBody: (DBConnection) async throws -> T
    ) async throws -> T {
        
        fatalError("unsupported operation")
    }
}

extension RedisDriver.Connection {
    
    func runCommand(
        _ string: String,
        _ binds: [RESPValue]
    ) async throws -> RESPValue {
        
        let result = try await binds.isEmpty ? self.client.send(command: string).get() : self.client.send(command: string, with: binds).get()
        
        if case let .error(error) = result {
            throw error
        }
        
        return result
    }
}
