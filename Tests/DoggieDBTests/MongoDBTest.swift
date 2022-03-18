//
//  MongoDBTest.swift
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

class MongoDBTest: DoggieDBTestCase {
    
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
    
    struct Contact: Codable, Equatable {
        
        var name: String
        
        var email: String
        
        var phone: String
        
    }
    
    func testSetAndGet() async throws {
        
        do {
            
            let value = Contact(name: "John", email: "john@example.com", phone: "98765432")
            
            _ = try await connection.mongoQuery().createCollection("contacts").withType(Contact.self).execute()
            
            _ = try await connection.mongoQuery().collection("contacts").withType(Contact.self).insertOne().value(value).execute()
            
            let result = try await connection.mongoQuery().collection("contacts").withType(Contact.self).findOne().execute()
            
            XCTAssertEqual(value, result)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testQuery() async throws {
        
        do {
            
            _ = try await connection.mongoQuery().createCollection("testQuery").execute()
            
            var obj = DBObject(class: "testQuery")
            obj["_id"] = "1"
            
            try await obj.save(on: connection)
            
            obj["last_name"] = "Susan"
            
            try await obj.save(on: connection)
            
            XCTAssertEqual(obj["_id"].string, "1")
            XCTAssertEqual(obj["last_name"].string, "Susan")
            
            let list = try await connection.query().find("testQuery").toArray()
            
            XCTAssertEqual(list.count, 1)
            
            XCTAssertEqual(list[0]["_id"].string, "1")
            XCTAssertEqual(list[0]["last_name"].string, "Susan")
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testJSON() async throws {
        
        do {
            
            _ = try await connection.mongoQuery().createCollection("testJSON").execute()
            
            let json: DBData = [
                "boolean": true,
                "string": "",
                "number": 1.0,
                "array": [],
                "dictionary": [:],
            ]
            
            let obj1 = try await connection.query().insert("testJSON", ["id": 1, "col": json])
            
            XCTAssertEqual(obj1["id"].intValue, 1)
            XCTAssertEqual(obj1["col"], json)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testPatternMatchingQuery() async throws {
        
        do {
            
            _ = try await connection.mongoQuery().createCollection("testPatternMatchingQuery").execute()
            
            _ = try await connection.query().insert("testPatternMatchingQuery", ["id": 1, "col": "text to be search"])
            _ = try await connection.query().insert("testPatternMatchingQuery", ["id": 2, "col": "long long' string%"])
            _ = try await connection.query().insert("testPatternMatchingQuery", ["id": 3, "col": "long long' string%, hello"])
            
            let res1 = try await connection.query()
                .find("testPatternMatchingQuery")
                .filter { .startsWith($0["col"], "text to ") }
                .toArray()
            
            XCTAssertEqual(res1.count, 1)
            XCTAssertEqual(res1.first?["id"].intValue, 1)
            
            let res2 = try await connection.query()
                .find("testPatternMatchingQuery")
                .filter { .endsWith($0["col"], "ong' string%") }
                .toArray()
            
            XCTAssertEqual(res2.count, 1)
            XCTAssertEqual(res2.first?["id"].intValue, 2)
            
            let res3 = try await connection.query()
                .find("testPatternMatchingQuery")
                .filter { .contains($0["col"], "long' s") }
                .toArray()
            
            XCTAssertEqual(res3.count, 2)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testUpdateQuery() async throws {
        
        do {
            
            _ = try await connection.mongoQuery().createCollection("testUpdateQuery").execute()
            
            var obj = DBObject(class: "testUpdateQuery")
            obj["_id"] = "1"
            
            try await obj.save(on: connection)
            
            obj["col"] = "text_1"
            
            try await obj.save(on: connection)
            
            XCTAssertEqual(obj["_id"].string, "1")
            XCTAssertEqual(obj["col"].string, "text_1")
            
            let obj2 = try await connection.query()
                .findOne("testUpdateQuery")
                .filter { $0.objectId ==  "1" }
                .update([
                    "col": .set("text_2")
                ])
            
            XCTAssertEqual(obj2?["_id"].string, "1")
            XCTAssertEqual(obj2?["col"].string, "text_2")
            
            let obj3 = try await connection.query()
                .findOne("testUpdateQuery")
                .filter { $0.objectId ==  "1" }
                .returning(.before)
                .update([
                    "col": .set("text_3")
                ])
            
            XCTAssertEqual(obj3?["_id"].string, "1")
            XCTAssertEqual(obj3?["col"].string, "text_2")
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testUpsertQuery() async throws {
        
        do {
            
            _ = try await connection.mongoQuery().createCollection("testUpsertQuery").execute()
            
            let obj = try await connection.query()
                .findOne("testUpsertQuery")
                .filter { $0.objectId ==  "1" }
                .upsert([
                    "_id": .setOnInsert("1"),
                    "col": .set("text_1"),
                ])
            
            XCTAssertEqual(obj?["_id"].string, "1")
            XCTAssertEqual(obj?["col"].string, "text_1")
            
            let obj2 = try await connection.query()
                .findOne("testUpsertQuery")
                .filter { $0.objectId ==  "1" }
                .upsert([
                    "_id": .setOnInsert("1"),
                    "col": .set("text_2"),
                ])
            
            XCTAssertEqual(obj2?["_id"].string, "1")
            XCTAssertEqual(obj2?["col"].string, "text_2")
            
            let obj3 = try await connection.query()
                .findOne("testUpsertQuery")
                .filter { $0.objectId ==  "1" }
                .returning(.before)
                .upsert([
                    "_id": .setOnInsert("1"),
                    "col": .set("text_3"),
                ])
            
            XCTAssertEqual(obj3?["_id"].string, "1")
            XCTAssertEqual(obj3?["col"].string, "text_2")
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testIncludesQuery() async throws {
        
        do {
            
            _ = try await connection.mongoQuery().createCollection("testIncludesQuery").execute()
            
            let obj = try await connection.query()
                .findOne("testIncludesQuery")
                .filter { $0.objectId ==  "1" }
                .includes(["dummy1", "dummy2"])
                .upsert([
                    "_id": .setOnInsert("1"),
                    "dummy1": .set(1),
                    "dummy2": .set(2),
                    "dummy3": .set(3),
                    "dummy4": .set(4),
                ])
            
            XCTAssertEqual(obj?.keys, ["_id", "dummy1", "dummy2"])
            
            let obj2 = try await connection.query()
                .findOne("testIncludesQuery")
                .filter { $0.objectId ==  "2" }
                .includes(["dummy1", "dummy2"])
                .returning(.before)
                .upsert([
                    "_id": .setOnInsert("2"),
                    "dummy1": .set(1),
                    "dummy2": .set(2),
                    "dummy3": .set(3),
                    "dummy4": .set(4),
                ])
            
            XCTAssertNil(obj2)
            
            let obj3 = try await connection.query()
                .findOne("testIncludesQuery")
                .filter { $0.objectId ==  "1" }
                .includes(["dummy1", "dummy2"])
                .upsert([
                    "_id": .setOnInsert("1"),
                    "dummy1": .set(1),
                    "dummy2": .set(2),
                    "dummy3": .set(3),
                    "dummy4": .set(4),
                ])
            
            XCTAssertEqual(obj3?.keys, ["_id", "dummy1", "dummy2"])
            
            let obj4 = try await connection.query()
                .findOne("testIncludesQuery")
                .filter { $0.objectId ==  "2" }
                .includes(["dummy1", "dummy2"])
                .returning(.before)
                .upsert([
                    "_id": .setOnInsert("2"),
                    "dummy1": .set(1),
                    "dummy2": .set(2),
                    "dummy3": .set(3),
                    "dummy4": .set(4),
                ])
            
            XCTAssertEqual(obj4?.keys, ["_id", "dummy1", "dummy2"])
            
            let obj5 = try await connection.query()
                .findOne("testIncludesQuery")
                .filter { $0.objectId ==  "1" }
                .includes(["dummy1", "dummy2"])
                .update([
                    "dummy1": .set(1),
                    "dummy2": .set(2),
                    "dummy3": .set(3),
                    "dummy4": .set(4),
                ])
            
            XCTAssertEqual(obj5?.keys, ["_id", "dummy1", "dummy2"])
            
            let obj6 = try await connection.query()
                .findOne("testIncludesQuery")
                .filter { $0.objectId ==  "2" }
                .includes(["dummy1", "dummy2"])
                .returning(.before)
                .update([
                    "dummy1": .set(1),
                    "dummy2": .set(2),
                    "dummy3": .set(3),
                    "dummy4": .set(4),
                ])
            
            XCTAssertEqual(obj6?.keys, ["_id", "dummy1", "dummy2"])
            
            let obj7 = try await connection.query()
                .find("testIncludesQuery")
                .filter { $0.objectId ==  "1" }
                .includes(["dummy1", "dummy2"])
                .first()
                
            
            XCTAssertEqual(obj7?.keys, ["_id", "dummy1", "dummy2"])
            
            let obj8 = try await connection.query()
                .findOne("testIncludesQuery")
                .filter { $0.objectId ==  "1" }
                .includes(["dummy1", "dummy2"])
                .delete()
                
            
            XCTAssertEqual(obj8?.keys, ["_id", "dummy1", "dummy2"])
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testQueryNumberOperation() async throws {
        
        do {
            
            _ = try await connection.mongoQuery().createCollection("testQueryNumberOperation").execute()
            
            var obj = DBObject(class: "testQueryNumberOperation")
            obj["_id"] = "1"
            obj["col_1"] = 1
            obj["col_2"] = 1
            obj["col_3"] = 1
            obj["col_4"] = 1
            
            try await obj.save(on: connection)
            
            obj.increment("col_1", by: 2)
            obj.decrement("col_2", by: 2)
            obj.multiply("col_3", by: 2)
            obj.divide("col_4", by: 2)
            
            try await obj.save(on: connection)
            
            XCTAssertEqual(obj["_id"].string, "1")
            XCTAssertEqual(obj["col_1"].intValue, 3)
            XCTAssertEqual(obj["col_2"].intValue, -1)
            XCTAssertEqual(obj["col_3"].intValue, 2)
            XCTAssertEqual(obj["col_4"].doubleValue, 0.5)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testQueryArrayOperation() async throws {
        
        do {
            
            _ = try await connection.mongoQuery().createCollection("testQueryArrayOperation").execute()
            
            var obj = DBObject(class: "testQueryArrayOperation")
            obj["_id"] = "1"
            obj["int_array"] = []
            
            try await obj.save(on: connection)
            
            obj.push("int_array", values: [1 as DBData, 2.0, 3])
            
            try await obj.save(on: connection)
            
            XCTAssertEqual(obj["_id"].string, "1")
            XCTAssertEqual(obj["int_array"].array, [1, 2.0, 3])
            
            obj.popFirst(for: "int_array")
            
            try await obj.save(on: connection)
            
            XCTAssertEqual(obj["int_array"].array, [2.0, 3])
            
            obj.popLast(for: "int_array")
            
            try await obj.save(on: connection)
            
            XCTAssertEqual(obj["int_array"].array, [2.0])
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testQueryArrayOperation2() async throws {
        
        do {
            
            _ = try await connection.mongoQuery().createCollection("testQueryArrayOperation2").execute()
            
            var obj = DBObject(class: "testQueryArrayOperation2")
            obj["_id"] = "1"
            obj["int_array"] = [1, 2, 2, 3, 5, 5]
            
            try await obj.save(on: connection)
            
            obj.addToSet("int_array", values: [2, 3, 4, 4])
            
            try await obj.save(on: connection)
            
            XCTAssertEqual(obj["_id"].string, "1")
            XCTAssertEqual(obj["int_array"].array, [1, 2, 2, 3, 5, 5, 4])
            
            obj.removeAll("int_array", values: [2, 3])
            
            try await obj.save(on: connection)
            
            XCTAssertEqual(obj["_id"].string, "1")
            XCTAssertEqual(obj["int_array"].array, [1, 5, 5, 4])
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
}
