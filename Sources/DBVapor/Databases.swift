//
//  Databases.swift
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

public struct DatabaseID: Hashable, Codable {
    
    public let string: String
    
    public init(string: String) {
        self.string = string
    }
}

public class Databases {
    
    public let eventLoopGroup: EventLoopGroup
    public let threadPool: NIOThreadPool
    
    private var configurations: [DatabaseID: DBConnectionSource]
    private var defaultID: DatabaseID?
    
    private var pools: [DatabaseID: EventLoopGroupConnectionPool<DBConnectionPoolSource>]
    
    private var lock: Lock
    
    public init(threadPool: NIOThreadPool, on eventLoopGroup: EventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
        self.threadPool = threadPool
        self.configurations = [:]
        self.pools = [:]
        self.lock = .init()
    }
}

extension Databases {
    
    private func _requireConfiguration(for id: DatabaseID) -> DBConnectionSource {
        guard let configuration = self.configurations[id] else {
            fatalError("No datatabase configuration registered for \(id).")
        }
        return configuration
    }
    
    private func _requireDefaultID() -> DatabaseID {
        guard let id = self.defaultID else {
            fatalError("No default database configured.")
        }
        return id
    }
}

extension Databases {
    
    public func use(
        _ config: DBConnectionSource,
        as id: DatabaseID,
        isDefault: Bool? = nil
    ) {
        self.lock.lock()
        defer { self.lock.unlock() }
        
        self.configurations[id] = config
        
        if isDefault == true || (self.defaultID == nil && isDefault != false) {
            self.defaultID = id
        }
    }
    
    public func `default`(to id: DatabaseID) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.defaultID = id
    }
    
    public func configuration(for id: DatabaseID? = nil) -> DBConnectionSource? {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.configurations[id ?? self._requireDefaultID()]
    }
    
    public func ids() -> Set<DatabaseID> {
        return self.lock.withLock { Set(self.configurations.keys) }
    }
    
    public func shutdown() {
        self.lock.lock()
        defer { self.lock.unlock() }
        for driver in self.pools.values {
            driver.shutdown()
        }
        self.pools = [:]
    }
}

extension Databases {
    
    public func database(
        _ id: DatabaseID? = nil,
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<DBConnection> {
        
        self.lock.lock()
        defer { self.lock.unlock() }
        
        let id = id ?? self._requireDefaultID()
        let configuration = self._requireConfiguration(for: id)
        
        var logger = logger
        logger[metadataKey: "database-id"] = .string(id.string)
        
        let pool: EventLoopGroupConnectionPool<DBConnectionPoolSource>
        
        if let existing = self.pools[id] {
            
            pool = existing
            
        } else {
            
            pool = .init(source: configuration, on: eventLoopGroup)
            self.pools[id] = pool
        }
        
        return pool.requestConnection(logger: logger, on: eventLoop).map { $0.connection }
    }
}
