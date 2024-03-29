//
//  Utilities.swift
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

import DoggieDB
import XCTest

func env(_ name: String) -> String? {
    getenv(name).flatMap { String(cString: $0) }
}

class DoggieDBTestCase: XCTestCase {
    
    var connection_url: URLComponents! { return nil }
    
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private(set) var connection: DBConnection!
    
    private lazy var logger: Logger = {
        
        var logger = Logger(label: "com.SusanDoggie.DoggieDB")
        logger.logLevel = .debug
        
        logger.info("connection url: \(connection_url!)")
        
        return logger
    }()
    
    override func setUp() async throws {
        
        self.connection = try await self._create_connection()
        
        let version = try await connection.version()
        logger.info("\(connection_url.scheme!) \(version)")
    }
    
    func _create_connection() async throws -> DBConnection {
        return try await Database.connect(url: connection_url, logger: logger, on: eventLoopGroup)
    }
    
    override func tearDown() async throws {
        
        try await self.connection.close()
        try eventLoopGroup.syncShutdownGracefully()
    }
}
