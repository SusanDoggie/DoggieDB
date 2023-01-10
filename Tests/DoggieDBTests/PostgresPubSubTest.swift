//
//  PostgresPubSubTest.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2023 Susan Cheng. All rights reserved.
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

class PostgresPubSubTest: DoggieDBTestCase {
    
    override var connection_url: URLComponents! {
        
        var url = URLComponents()
        url.scheme = "postgres"
        url.host = env("POSTGRES_HOST") ?? "localhost"
        url.user = env("POSTGRES_USERNAME")
        url.password = env("POSTGRES_PASSWORD")
        url.path = "/\(env("POSTGRES_DATABASE") ?? "")"
        
        if let ssl_mode = env("POSTGRES_SSLMODE") {
            url.queryItems = [
                URLQueryItem(name: "ssl", value: "true"),
                URLQueryItem(name: "sslmode", value: ssl_mode),
            ]
        }
        
        return url
    }
    
    func testPubSub() async throws {
        
        var _continuation: AsyncStream<String>.Continuation!
        let stream = AsyncStream { _continuation = $0 }
        
        let continuation = _continuation!
        
        try await connection.postgresPubSub().subscribe(channel: "test") { connection, channel, message in
            
            continuation.yield(message)
            
        }
        
        try await connection.postgresPubSub().publish("hello1", to: "test")
        try await connection.postgresPubSub().publish("hello2", to: "test")
        try await connection.postgresPubSub().publish("hello3", to: "test")
        
        var iterator = stream.makeAsyncIterator()
        
        let result1 = await iterator.next()
        let result2 = await iterator.next()
        let result3 = await iterator.next()
        
        XCTAssertEqual(result1, "hello1")
        XCTAssertEqual(result2, "hello2")
        XCTAssertEqual(result3, "hello3")
    }
    
}
