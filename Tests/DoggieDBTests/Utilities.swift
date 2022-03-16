//
//  Utilities.swift
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

import DoggieDB
import XCTest

func env(_ name: String) -> String? {
    getenv(name).flatMap { String(cString: $0) }
}

class DoggieDBTestCase: XCTestCase {
    
    var connection_url: URLComponents! { return nil }
    
    private var eventLoopGroup: MultiThreadedEventLoopGroup!
    private(set) var connection: DBSQLConnection!
    
    override func setUp() async throws {
        
        do {
            
            eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            self.addTeardownBlock { try self.eventLoopGroup.syncShutdownGracefully() }
            
            var logger = Logger(label: "com.SusanDoggie.DoggieDB")
            logger.logLevel = .debug
            
            self.connection = try await Database.connect(url: connection_url, logger: logger, on: eventLoopGroup) as? DBSQLConnection
            self.addTeardownBlock { try await self.connection.close() }
            
            print(connection_url.scheme!, try await connection.version())
            
        } catch {
            
            print(error)
            throw error
        }
    }
}
