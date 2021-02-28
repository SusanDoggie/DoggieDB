//
//  RedisTest.swift
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
    
    override func setUpWithError() throws {
        
        do {
            
            eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            
            var url = URLComponents()
            url.scheme = "redis"
            url.host = env("REDIS_HOST") ?? "localhost"
            url.user = env("REDIS_USERNAME")
            url.password = env("REDIS_PASSWORD")
            url.path = "/\(env("REDIS_DATABASE") ?? "")"
            
            if let ssl_mode = env("REDIS_SSLMODE") {
                url.queryItems = [
                    URLQueryItem(name: "ssl", value: "true"),
                    URLQueryItem(name: "sslmode", value: ssl_mode),
                ]
            }
            
            self.connection = try Database.connect(url: url, on: eventLoopGroup.next()).wait()
            
        } catch let error {
            
            print(error)
            throw error
        }
    }
    
    override func tearDownWithError() throws {
        
        do {
            
            try self.connection.close().wait()
            try eventLoopGroup.syncShutdownGracefully()
            
        } catch let error {
            
            print(error)
            throw error
        }
    }
    
    func testSetAndGet() throws {
        
        do {
            
            let value = Contact(name: "John", email: "john@example.com", phone: "98765432")
            
            try connection.redisQuery().set("contact", value: value).wait()
            
            let result = try connection.redisQuery().get("contact", as: Contact.self).wait()
            
            XCTAssertEqual(value, result)
            
        } catch let error {
            
            print(error)
            throw error
        }
    }
    
}
