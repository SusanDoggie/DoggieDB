//
//  Migrator.swift
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

public struct Migrator {

    public let databaseFactory: (DatabaseID?) -> EventLoopFuture<DBConnection>
    public let migrations: Migrations
    public let eventLoop: EventLoop
    
    public init(
        databaseFactory: @escaping (DatabaseID?) -> EventLoopFuture<DBConnection>,
        migrations: Migrations,
        on eventLoop: EventLoop
    ) {
        self.databaseFactory = databaseFactory
        self.migrations = migrations
        self.eventLoop = eventLoop
    }
    
    public init(
        databases: Databases,
        migrations: Migrations,
        logger: Logger,
        on eventLoop: EventLoop
    ) {
        self.init(
            databaseFactory: { databases.database($0, logger: logger, on: eventLoop) },
            migrations: migrations,
            on: eventLoop
        )
    }
}

extension Migrator {
    
    public func setupIfNeeded() -> EventLoopFuture<Void> {
        fatalError()
    }
    
    public func prepareBatch() -> EventLoopFuture<Void> {
        fatalError()
    }
    
    public func revertLastBatch() -> EventLoopFuture<Void> {
        fatalError()
    }
    
    public func revertBatch(number: Int) -> EventLoopFuture<Void> {
        fatalError()
    }
    
    public func revertAllBatches() -> EventLoopFuture<Void> {
        fatalError()
    }
    
    public func previewPrepareBatch() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        fatalError()
    }
    
    public func previewRevertLastBatch() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        fatalError()
    }
    
    public func previewRevertBatch() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        fatalError()
    }
    
    public func previewRevertAllBatches() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        fatalError()
    }
}
