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
    
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    
    var connection: DBConnection!
    
    override func setUpWithError() throws {
        
        do {
            
            var url_components = URLComponents()
            url_components.scheme = "redis"
            url_components.host = env("REDIS_HOST") ?? "localhost"
            url_components.user = env("REDIS_USERNAME")
            url_components.password = env("REDIS_PASSWORD")
            url_components.path = env("REDIS_DATABASE").map { "/\($0)" } ?? "/"
            
            let url = url_components.url!
            
            print("REDIS:", url)
            
            self.connection = try Database.connect(url: url, on: eventLoopGroup.next()).wait()
            
        } catch let error {
            
            print(error)
            throw error
        }
    }
    
    override func tearDownWithError() throws {
        try self.connection.close().wait()
        try eventLoopGroup.syncShutdownGracefully()
    }
    
}
