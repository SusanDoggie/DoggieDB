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

    public let databaseFactory: (DatabaseID?) -> DatabasePool
    public let migrations: Migrations
    public let eventLoop: EventLoop
    
    public init(
        databaseFactory: @escaping (DatabaseID?) -> DatabasePool,
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
        return self.migrators() { $0.setupIfNeeded() }.transform(to: ())
    }
    
    public func prepareBatch() -> EventLoopFuture<Void> {
        return self.migrators() { $0.prepareBatch() }.transform(to: ())
    }
    
    public func revertLastBatch() -> EventLoopFuture<Void> {
        return self.migrators() { $0.revertLastBatch() }.transform(to: ())
    }
    
    public func revertBatch(number: Int) -> EventLoopFuture<Void> {
        return self.migrators() { $0.revertBatch(number: number) }.transform(to: ())
    }
    
    public func revertAllBatches() -> EventLoopFuture<Void> {
        return self.migrators() { $0.revertAllBatches() }.transform(to: ())
    }
    
    public func previewPrepareBatch() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        return self.migrators() { migrator in
            return migrator.previewPrepareBatch().and(value: migrator.id)
        }.map { items in
            return items.reduce(into: []) { result, batch in
                let pairs = batch.0.map { ($0, batch.1) }
                result.append(contentsOf: pairs)
            }
        }
    }
    
    public func previewRevertLastBatch() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        return self.migrators() { migrator in
            return migrator.previewRevertLastBatch().and(value: migrator.id)
        }.map { items in
            return items.reduce(into: []) { result, batch in
                let pairs = batch.0.map { ($0, batch.1) }
                result.append(contentsOf: pairs)
            }
        }
    }
    
    public func previewRevertBatch() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        return self.migrators() { migrator in
            return migrator.previewPrepareBatch().and(value: migrator.id)
        }.map { items in
            return items.reduce(into: []) { result, batch in
                let pairs = batch.0.map { ($0, batch.1) }
                result.append(contentsOf: pairs)
            }
        }
    }
    
    public func previewRevertAllBatches() -> EventLoopFuture<[(Migration, DatabaseID?)]> {
        return self.migrators() { migrator in
            return migrator.previewRevertAllBatches().and(value: migrator.id)
        }.map { items in
            return items.reduce(into: []) { result, batch in
                let pairs = batch.0.map { ($0, batch.1) }
                result.append(contentsOf: pairs)
            }
        }
    }
    
    private func migrators<Result>(
        _ handler: (DatabaseMigrator) -> EventLoopFuture<Result>
    ) -> EventLoopFuture<[Result]> {
        return self.migrations.databases.map { id in
            let migrations = self.migrations.storage.compactMap { item -> Migration? in
                guard item.id == id else { return nil }
                return item.migration
            }
            
            let migrator = DatabaseMigrator(id: id, database: self.databaseFactory(id), migrations: migrations)
            return handler(migrator)
        }.flatten(on: self.eventLoop)
    }
}

private struct DatabaseMigrator {
    
    let id: DatabaseID?
    let database: DatabasePool
    let migrations: [Migration]
    
    init(id: DatabaseID?, database: DatabasePool, migrations: [Migration]) {
        self.id = id
        self.database = database
        self.migrations = migrations
    }
}

extension DatabaseMigrator {
    
    func setupIfNeeded() -> EventLoopFuture<Void> {
        fatalError()
    }
    
    func prepareBatch() -> EventLoopFuture<Void> {
        fatalError()
    }
    
    func revertLastBatch() -> EventLoopFuture<Void> {
        fatalError()
    }
    
    func revertBatch(number: Int) -> EventLoopFuture<Void> {
        fatalError()
    }
    
    func revertAllBatches() -> EventLoopFuture<Void> {
        fatalError()
    }
    
    func previewPrepareBatch() -> EventLoopFuture<[Migration]> {
        fatalError()
    }
    
    func previewRevertLastBatch() -> EventLoopFuture<[Migration]> {
        fatalError()
    }
    
    func previewRevertBatch() -> EventLoopFuture<[Migration]> {
        fatalError()
    }
    
    func previewRevertAllBatches() -> EventLoopFuture<[Migration]> {
        fatalError()
    }
}
