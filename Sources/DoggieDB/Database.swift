//
//  Database.swift
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

public enum Database {
    
}

extension Database {
    
    public static func createSQLite(
        path: String? = nil,
        logger: Logger = .init(label: "com.SusanDoggie.DoggieDB"),
        threadPool: NIOThreadPool,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<DatabaseConnection> {
        
        return SQLiteDriver.create(storage: path.map { .file(path: $0) } ?? .memory, logger: logger, threadPool: threadPool, on: eventLoop)
    }
}

extension Database {
    
    public static func connect(
        config: DatabaseConfiguration,
        logger: Logger = .init(label: "com.SusanDoggie.DoggieDB"),
        driver: DatabaseDriver,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<DatabaseConnection> {
        
        return driver.rawValue.connect(config: config, logger: logger, on: eventLoop)
    }
    
    public static func connect(
        url: URL,
        logger: Logger = .init(label: "com.SusanDoggie.DoggieDB"),
        on eventLoop: EventLoop
    ) -> EventLoopFuture<DatabaseConnection> {
        
        do {
            
            guard let hostname = url.host else {
                return eventLoop.makeFailedFuture(DatabaseError.invalidConnectionURL)
            }
            
            let driver: DatabaseDriver
            
            switch url.scheme {
            case "redis": driver = .redis
            case "mysql": driver = .mySQL
            case "postgres": driver = .postgreSQL
            case "mongodb": driver = .mongoDB
            default: return eventLoop.makeFailedFuture(DatabaseError.invalidConnectionURL)
            }
            
            let tlsConfiguration: TLSConfiguration?
            if url.query?.contains("ssl=false") == true {
                tlsConfiguration = nil
            } else {
                tlsConfiguration = .forClient()
            }
            
            let config = try DatabaseConfiguration(
                hostname: hostname,
                port: url.port ?? driver.rawValue.defaultPort,
                username: url.user,
                password: url.password,
                database: url.lastPathComponent,
                tlsConfiguration: tlsConfiguration
            )
            
            return self.connect(config: config, logger: logger, driver: driver, on: eventLoop)
            
        } catch let error {
            
            return eventLoop.makeFailedFuture(error)
        }
    }
}
