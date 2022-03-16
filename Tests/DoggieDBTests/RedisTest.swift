//
//  RedisTest.swift
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

class RedisTest: XCTestCase {
    
    struct Contact: Codable, Equatable {
        
        var name: String
        
        var email: String
        
        var phone: String
        
    }
    
    var eventLoopGroup: MultiThreadedEventLoopGroup!
    var connection: DBConnection!
    
    override func setUp() async throws {
        
        do {
            
            eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            self.addTeardownBlock { try self.eventLoopGroup.syncShutdownGracefully() }
            
            var url = URLComponents()
            url.scheme = "redis"
            url.host = env("REDIS_HOST") ?? "localhost"
            url.user = env("REDIS_USERNAME")
            url.password = env("REDIS_PASSWORD")
            url.path = "/\(env("REDIS_DATABASE") ?? "0")"
            
            if let ssl_mode = env("REDIS_SSLMODE") {
                url.queryItems = [
                    URLQueryItem(name: "ssl", value: "true"),
                    URLQueryItem(name: "sslmode", value: ssl_mode),
                ]
            }
            
            var logger = Logger(label: "com.SusanDoggie.DoggieDB")
            logger.logLevel = .debug
            
            self.connection = try await Database.connect(url: url, logger: logger, on: eventLoopGroup)
            self.addTeardownBlock { try await self.connection.close() }
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testFetchStore() async throws {
        
        do {
            
            let value = Contact(name: "John", email: "john@example.com", phone: "98765432")
            
            try await connection.redisQuery().value(of: "contact", as: Contact.self).store(value)
            
            let result = try await connection.redisQuery().value(of: "contact", as: Contact.self).fetch()
            
            XCTAssertEqual(value, result)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
}
