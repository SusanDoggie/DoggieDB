//
//  Application.swift
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

extension Application {
    
    final class Storage {
        
        let databases: Databases
        let migrations: Migrations
        
        init(threadPool: NIOThreadPool, on eventLoopGroup: EventLoopGroup) {
            self.databases = Databases(threadPool: threadPool, on: eventLoopGroup)
            self.migrations = Migrations()
        }
    }
    
    struct Key: StorageKey {
        
        typealias Value = Storage
    }
    
    struct Signature: CommandSignature {
        
        @Flag(name: "auto-migrate", help: "If true, Fluent will automatically migrate your database on boot")
        var autoMigrate: Bool
        
        @Flag(name: "auto-revert", help: "If true, Fluent will automatically revert your database on boot")
        var autoRevert: Bool
        
    }
    
    struct Lifecycle: LifecycleHandler {
        
        func willBoot(_ application: Application) throws {
            
            let signature = try Signature(from: &application.environment.commandInput)
            if signature.autoRevert {
                try application.autoRevert().wait()
            }
            if signature.autoMigrate {
                try application.autoMigrate().wait()
            }
        }
        
        func shutdown(_ application: Application) {
            application.databases.shutdown()
        }
    }
}

extension Request {
    
    public func database(_ id: DatabaseID? = nil) -> DatabasePool {
        return self.application.database(id)
    }
    
    public var databases: Databases {
        return self.application.databases
    }
}

extension Application {
    
    private var _storage: Storage {
        if self.storage[Key.self] == nil {
            self.storage[Key.self] = Storage(threadPool: self.threadPool, on: self.eventLoopGroup)
            self.lifecycle.use(Lifecycle())
            self.commands.use(MigrateCommand(), as: "migrate")
        }
        return self.storage[Key.self]!
    }
    
    public func database(_ id: DatabaseID? = nil) -> DatabasePool {
        return self.databases.database(id, logger: self.logger, on: self.eventLoopGroup.next())
    }
    
    public var databases: Databases {
        return self._storage.databases
    }
    
    public var migrations: Migrations {
        return self._storage.migrations
    }
    
    public var migrator: Migrator {
        return Migrator(
            databases: self.databases,
            migrations: self.migrations,
            logger: self.logger,
            on: self.eventLoopGroup.next()
        )
    }
    
    /// Automatically runs forward migrations without confirmation.
    /// This can be triggered by passing `--auto-migrate` flag.
    public func autoMigrate() -> EventLoopFuture<Void> {
        self.migrator.setupIfNeeded().flatMap {
            self.migrator.prepareBatch()
        }
    }
    
    /// Automatically runs reverse migrations without confirmation.
    /// This can be triggered by passing `--auto-revert` during boot.
    public func autoRevert() -> EventLoopFuture<Void> {
        self.migrator.setupIfNeeded().flatMap {
            self.migrator.revertAllBatches()
        }
    }
}
