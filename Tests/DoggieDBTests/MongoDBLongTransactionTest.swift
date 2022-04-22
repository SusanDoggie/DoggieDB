//
//  MongoDBLongTransactionTest.swift
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

class MongoDBLongTransactionTest: DoggieDBTestCase {
    
    override var connection_url: URLComponents! {
        
        var url = URLComponents()
        url.scheme = "mongodb"
        url.host = env("MONGO_HOST") ?? "localhost"
        url.user = env("MONGO_USERNAME")
        url.password = env("MONGO_PASSWORD")
        url.path = "/\(env("MONGO_DATABASE") ?? "")"
        
        var queryItems: [URLQueryItem] = []
        
        if let authSource = env("MONGO_AUTHSOURCE") {
            queryItems.append(URLQueryItem(name: "authSource", value: authSource))
        }
        
        if let ssl_mode = env("MONGO_SSLMODE") {
            queryItems.append(URLQueryItem(name: "ssl", value: "true"))
            queryItems.append(URLQueryItem(name: "sslmode", value: ssl_mode))
        }
        
        if let replicaSet = env("MONGO_REPLICA_SET") {
            queryItems.append(URLQueryItem(name: "replicaSet", value: replicaSet))
        }
        
        url.queryItems = queryItems.isEmpty ? nil : queryItems
        
        return url
    }
    
    func testLongTransaction() async throws {
        
        try await connection.mongoQuery().createCollection("testLongTransaction").execute()
        
        _ = try await connection.query().insert("testLongTransaction", ["col": 0])
        
        var connections: [DBConnection] = []
        
        for _ in 0..<10 {
            try await connections.append(self._create_connection())
        }
        
        let result: Set<Int> = try await withThrowingTaskGroup(of: DBObject.self) { group in
            
            for connection in connections {
                
                group.addTask {
                    
                    try await connection.withTransaction(DBTransactionOptions(
                        mode: .serialize,
                        retryOnConflict: true
                    )) { connection in
                        
                        var obj = try await connection.query().find("testLongTransaction").first()!
                        var value = obj["col"].intValue!
                        
                        value += 1
                        obj["col"] = DBData(value)
                        
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        
                        try await obj.save(on: connection)
                        
                        value += 1
                        obj["col"] = DBData(value)
                        
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        
                        try await obj.save(on: connection)
                        
                        return obj
                    }
                }
            }
            
            var result: Set<Int> = []
            
            for try await item in group {
                result.insert(item["col"].intValue!)
            }
            
            return result
        }
        
        XCTAssertEqual(result, [2, 4, 6, 8, 10, 12, 14, 16, 18, 20])
        
        for connection in connections {
            try await connection.close()
        }
    }
    
}
