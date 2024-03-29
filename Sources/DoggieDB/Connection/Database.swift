//
//  Database.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2024 Susan Cheng. All rights reserved.
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
    
    public static func connect(
        config: Database.Configuration,
        logger: Logger = .init(label: "com.SusanDoggie.DoggieDB"),
        driver: DBDriver,
        on eventLoopGroup: EventLoopGroup
    ) async throws -> DBConnection {
        
        return try await driver.rawValue.connect(config: config, logger: logger, on: eventLoopGroup)
    }
    
    public static func connect(
        url: URL,
        logger: Logger = .init(label: "com.SusanDoggie.DoggieDB"),
        on eventLoopGroup: EventLoopGroup
    ) async throws -> DBConnection {
        
        let driver = try url.driver()
        let config = try Database.Configuration(url: url)
        
        return try await self.connect(config: config, logger: logger, driver: driver, on: eventLoopGroup)
    }
    
    public static func connect(
        url: URLComponents,
        logger: Logger = .init(label: "com.SusanDoggie.DoggieDB"),
        on eventLoopGroup: EventLoopGroup
    ) async throws -> DBConnection {
        
        let driver = try url.driver()
        let config = try Database.Configuration(url: url)
        
        return try await self.connect(config: config, logger: logger, driver: driver, on: eventLoopGroup)
    }
}
