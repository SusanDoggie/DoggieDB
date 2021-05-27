//
//  RedisPubSubTest.swift
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

class RedisPubSubTest: XCTestCase {
    
    var eventLoopGroup: MultiThreadedEventLoopGroup!
    var connection: DBConnection!
    var connection2: DBConnection!
    
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
            
            self.connection = try Database.connect(url: url, on: eventLoopGroup).wait()
            self.connection2 = try Database.connect(url: url, on: eventLoopGroup.next()).wait()
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    override func tearDownWithError() throws {
        
        do {
            
            try self.connection.close().wait()
            try self.connection2.close().wait()
            try eventLoopGroup.syncShutdownGracefully()
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testPubSub() throws {
        
        do {
            
            let promise = connection.eventLoopGroup.next().makePromise(of: String.self)
            
            try connection.redisPubSub().subscribe(toChannels: ["Test"]) { channel, message in
                
                promise.completeWith(message.map { $0.string ?? "" })
                
            }.wait()
            
            _ = try connection2.redisPubSub().publish("hello", to: "Test").wait()
            
            let result = try promise.futureResult.wait()
            
            XCTAssertEqual("hello", result)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
}
