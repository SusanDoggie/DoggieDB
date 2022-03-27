//
//  RedisPubSubTest.swift
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

class RedisPubSubTest: DoggieDBTestCase {
    
    override var connection_url: URLComponents! {
        
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
        
        return url
    }
    
    func testPubSub() async throws {
        
        var continuation: AsyncStream<String>.Continuation!
        let stream = AsyncStream { continuation = $0 }
        
        try await connection.redisPubSub().subscribe(toChannels: ["Test"]) { connection, channel, message in
            
            continuation.yield(message)
            
        }
        
        try await connection.redisPubSub().publish("hello1", to: "Test")
        try await connection.redisPubSub().publish("hello2", to: "Test")
        try await connection.redisPubSub().publish("hello3", to: "Test")
        
        var iterator = stream.makeAsyncIterator()
        
        let result1 = await iterator.next()
        let result2 = await iterator.next()
        let result3 = await iterator.next()
        
        XCTAssertEqual(result1, "hello1")
        XCTAssertEqual(result2, "hello2")
        XCTAssertEqual(result3, "hello3")
    }
    
}
