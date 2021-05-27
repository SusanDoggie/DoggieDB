//
//  EventLoopConnectionPool.swift
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

public class DBConnectionPoolItem: ConnectionPoolItem {
    
    public let connection: DBConnection
    
    init(connection: DBConnection) {
        self.connection = connection
    }
    
    public var eventLoop: EventLoop {
        return connection.eventLoopGroup.next()
    }
    
    public var isClosed: Bool {
        return connection.isClosed
    }
    
    public func close() -> EventLoopFuture<Void> {
        return connection.close()
    }
}

public struct DBConnectionPoolSource: ConnectionPoolSource {
    
    let generator: (Logger, EventLoop) -> EventLoopFuture<DBConnection>
    
    public func makeConnection(logger: Logger, on eventLoop: EventLoop) -> EventLoopFuture<DBConnectionPoolItem> {
        return generator(logger, eventLoop).map { DBConnectionPoolItem(connection: $0) }
    }
}

extension EventLoopConnectionPool where Source == DBConnectionPoolSource {
    
    public convenience init(
        source: DBConnectionSource,
        maxConnections: Int,
        requestTimeout: TimeAmount = .seconds(10),
        logger: Logger = .init(label: "com.SusanDoggie.DBVapor"),
        on eventLoop: EventLoop
    ) {
        
        if source.driver.isSessionSupported {
            
            let connection = Database.connect(
                config: source.configuration,
                logger: logger,
                driver: source.driver,
                on: eventLoop)
            
            self.init(
                source: DBConnectionPoolSource(generator: { _, _ in connection.map { $0.withSession() } }),
                maxConnections: maxConnections,
                requestTimeout: requestTimeout,
                logger: logger,
                on: eventLoop
            )
            
        } else {
            
            self.init(
                source: DBConnectionPoolSource(generator: { logger, eventLoop in
                    Database.connect(
                        config: source.configuration,
                        logger: logger,
                        driver: source.driver,
                        on: eventLoop)
                }),
                maxConnections: maxConnections,
                requestTimeout: requestTimeout,
                logger: logger,
                on: eventLoop
            )
        }
    }
}

extension EventLoopGroupConnectionPool where Source == DBConnectionPoolSource {
    
    public convenience init(
        source: DBConnectionSource,
        maxConnectionsPerEventLoop: Int = 1,
        requestTimeout: TimeAmount = .seconds(10),
        logger: Logger = .init(label: "com.SusanDoggie.DBVapor"),
        on eventLoopGroup: EventLoopGroup
    ) {
        
        if source.driver.isSessionSupported {
            
            let connection = Database.connect(
                config: source.configuration,
                logger: logger,
                driver: source.driver,
                on: eventLoopGroup)
            
            self.init(
                source: DBConnectionPoolSource(generator: { _, _ in connection.map { $0.withSession() } }),
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
                requestTimeout: requestTimeout,
                logger: logger,
                on: eventLoopGroup
            )
            
        } else {
            
            self.init(
                source: DBConnectionPoolSource(generator: { logger, eventLoop in
                    Database.connect(
                        config: source.configuration,
                        logger: logger,
                        driver: source.driver,
                        on: eventLoop)
                }),
                maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
                requestTimeout: requestTimeout,
                logger: logger,
                on: eventLoopGroup
            )
        }
    }
}
