//
//  MongoDBTest.swift
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

class MongoDBTest: XCTestCase {
    
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
            
            url.queryItems = queryItems.isEmpty ? nil : queryItems
            
            var logger = Logger(label: "com.SusanDoggie.DoggieDB")
            logger.logLevel = .debug
            
            self.connection = try Database.connect(url: url, logger: logger, on: eventLoopGroup).wait()
            
            print("MONGO:", try connection.version().wait())
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    override func tearDownWithError() throws {
        
        do {
            
            try self.connection.close().wait()
            try eventLoopGroup.syncShutdownGracefully()
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testSetAndGet() throws {
        
        do {
            
            let value = Contact(name: "John", email: "john@example.com", phone: "98765432")
            
            _ = try connection.mongoQuery().createCollection("contacts").withType(Contact.self).execute().wait()
            
            _ = try connection.mongoQuery().collection("contacts").withType(Contact.self).insertOne().value(value).execute().wait()
            
            let result = try connection.mongoQuery().collection("contacts").withType(Contact.self).findOne().execute().wait()
            
            XCTAssertEqual(value, result)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testQuery() throws {
        
        do {
            
            _ = try connection.mongoQuery().createCollection("testQuery").execute().wait()
            
            var obj = DBObject(class: "testQuery")
            obj["_id"] = "1"
            
            obj = try obj.save(on: connection).wait()
            
            obj["last_name"] = "Susan"
            
            obj = try obj.save(on: connection).wait()
            
            XCTAssertEqual(obj["_id"].string, "1")
            XCTAssertEqual(obj["last_name"].string, "Susan")
            
            let list = try connection.query().find("testQuery").toArray().wait()
            
            XCTAssertEqual(list.count, 1)
            
            XCTAssertEqual(list[0]["_id"].string, "1")
            XCTAssertEqual(list[0]["last_name"].string, "Susan")
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testJSON() throws {
        
        do {
            
            _ = try connection.mongoQuery().createCollection("testJSON").execute().wait()
            
            let json: DBData = [
                "boolean": true,
                "string": "",
                "number": 1.0,
                "array": [],
                "dictionary": [:],
            ]
            
            let obj1 = try connection.query().insert("testJSON", ["id": 1, "col": json]).wait()
            
            XCTAssertEqual(obj1["id"].intValue, 1)
            XCTAssertEqual(obj1["col"], json)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testPatternMatchingQuery() throws {
        
        do {
            
            _ = try connection.mongoQuery().createCollection("testPatternMatchingQuery").execute().wait()
            
            _ = try connection.query().insert("testPatternMatchingQuery", ["id": 1, "col": "text to be search"]).wait()
            _ = try connection.query().insert("testPatternMatchingQuery", ["id": 2, "col": "long long' string%"]).wait()
            _ = try connection.query().insert("testPatternMatchingQuery", ["id": 3, "col": "long long' string%, hello"]).wait()
            
            let res1 = try connection.query()
                .find("testPatternMatchingQuery")
                .filter { .startsWith($0["col"], "text to ") }
                .toArray().wait()
            
            XCTAssertEqual(res1.count, 1)
            XCTAssertEqual(res1.first?["id"].intValue, 1)
            
            let res2 = try connection.query()
                .find("testPatternMatchingQuery")
                .filter { .endsWith($0["col"], "ong' string%") }
                .toArray().wait()
            
            XCTAssertEqual(res2.count, 1)
            XCTAssertEqual(res2.first?["id"].intValue, 2)
            
            let res3 = try connection.query()
                .find("testPatternMatchingQuery")
                .filter { .contains($0["col"], "long' s") }
                .toArray().wait()
            
            XCTAssertEqual(res3.count, 2)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testUpdateQuery() throws {
        
        do {
            
            _ = try connection.mongoQuery().createCollection("testUpdateQuery").execute().wait()
            
            var obj = DBObject(class: "testUpdateQuery")
            obj["_id"] = "1"
            
            obj = try obj.save(on: connection).wait()
            
            obj["col"] = "text_1"
            
            obj = try obj.save(on: connection).wait()
            
            XCTAssertEqual(obj["_id"].string, "1")
            XCTAssertEqual(obj["col"].string, "text_1")
            
            let obj2 = try connection.query()
                .findOne("testUpdateQuery")
                .filter { $0.objectId ==  "1" }
                .update([
                    "col": .set("text_2")
                ]).wait()
            
            XCTAssertEqual(obj2?["_id"].string, "1")
            XCTAssertEqual(obj2?["col"].string, "text_2")
            
            let obj3 = try connection.query()
                .findOne("testUpdateQuery")
                .filter { $0.objectId ==  "1" }
                .returning(.before)
                .update([
                    "col": .set("text_3")
                ]).wait()
            
            XCTAssertEqual(obj3?["_id"].string, "1")
            XCTAssertEqual(obj3?["col"].string, "text_2")
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testUpsertQuery() throws {
        
        do {
            
            _ = try connection.mongoQuery().createCollection("testUpsertQuery").execute().wait()
            
            let obj = try connection.query()
                .findOne("testUpsertQuery")
                .filter { $0.objectId ==  "1" }
                .upsert([
                    "col": .set("text_1")
                ], setOnInsert: [
                    "_id": "1"
                ]).wait()
            
            XCTAssertEqual(obj?["_id"].string, "1")
            XCTAssertEqual(obj?["col"].string, "text_1")
            
            let obj2 = try connection.query()
                .findOne("testUpsertQuery")
                .filter { $0.objectId ==  "1" }
                .upsert([
                    "col": .set("text_2")
                ], setOnInsert: [
                    "_id": "1"
                ]).wait()
            
            XCTAssertEqual(obj2?["_id"].string, "1")
            XCTAssertEqual(obj2?["col"].string, "text_2")
            
            let obj3 = try connection.query()
                .findOne("testUpsertQuery")
                .filter { $0.objectId ==  "1" }
                .returning(.before)
                .upsert([
                    "col": .set("text_3")
                ], setOnInsert: [
                    "_id": "1"
                ]).wait()
            
            XCTAssertEqual(obj3?["_id"].string, "1")
            XCTAssertEqual(obj3?["col"].string, "text_2")
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testIncludesQuery() throws {
        
        do {
            
            _ = try connection.mongoQuery().createCollection("testIncludesQuery").execute().wait()
            
            let obj = try connection.query()
                .findOne("testIncludesQuery")
                .filter { $0.objectId ==  "1" }
                .includes(["dummy1", "dummy2"])
                .upsert([
                    "dummy1": .set(1),
                    "dummy2": .set(2),
                    "dummy3": .set(3),
                    "dummy4": .set(4),
                ], setOnInsert: [
                    "_id": "1"
                ]).wait()
            
            XCTAssertEqual(obj?.keys, ["_id", "dummy1", "dummy2"])
            
            let obj2 = try connection.query()
                .findOne("testIncludesQuery")
                .filter { $0.objectId ==  "2" }
                .includes(["dummy1", "dummy2"])
                .returning(.before)
                .upsert([
                    "dummy1": .set(1),
                    "dummy2": .set(2),
                    "dummy3": .set(3),
                    "dummy4": .set(4),
                ], setOnInsert: [
                    "_id": "2"
                ]).wait()
            
            XCTAssertNil(obj2)
            
            let obj3 = try connection.query()
                .findOne("testIncludesQuery")
                .filter { $0.objectId ==  "1" }
                .includes(["dummy1", "dummy2"])
                .upsert([
                    "dummy1": .set(1),
                    "dummy2": .set(2),
                    "dummy3": .set(3),
                    "dummy4": .set(4),
                ], setOnInsert: [
                    "_id": "1"
                ]).wait()
            
            XCTAssertEqual(obj3?.keys, ["_id", "dummy1", "dummy2"])
            
            let obj4 = try connection.query()
                .findOne("testIncludesQuery")
                .filter { $0.objectId ==  "2" }
                .includes(["dummy1", "dummy2"])
                .returning(.before)
                .upsert([
                    "dummy1": .set(1),
                    "dummy2": .set(2),
                    "dummy3": .set(3),
                    "dummy4": .set(4),
                ], setOnInsert: [
                    "_id": "2"
                ]).wait()
            
            XCTAssertEqual(obj4?.keys, ["_id", "dummy1", "dummy2"])
            
            let obj5 = try connection.query()
                .findOne("testIncludesQuery")
                .filter { $0.objectId ==  "1" }
                .includes(["dummy1", "dummy2"])
                .update([
                    "dummy1": .set(1),
                    "dummy2": .set(2),
                    "dummy3": .set(3),
                    "dummy4": .set(4),
                ]).wait()
            
            XCTAssertEqual(obj5?.keys, ["_id", "dummy1", "dummy2"])
            
            let obj6 = try connection.query()
                .findOne("testIncludesQuery")
                .filter { $0.objectId ==  "2" }
                .includes(["dummy1", "dummy2"])
                .returning(.before)
                .update([
                    "dummy1": .set(1),
                    "dummy2": .set(2),
                    "dummy3": .set(3),
                    "dummy4": .set(4),
                ]).wait()
            
            XCTAssertEqual(obj6?.keys, ["_id", "dummy1", "dummy2"])
            
            let obj7 = try connection.query()
                .find("testIncludesQuery")
                .filter { $0.objectId ==  "1" }
                .includes(["dummy1", "dummy2"])
                .first()
                .wait()
            
            XCTAssertEqual(obj7?.keys, ["_id", "dummy1", "dummy2"])
            
            let obj8 = try connection.query()
                .findOne("testIncludesQuery")
                .filter { $0.objectId ==  "1" }
                .includes(["dummy1", "dummy2"])
                .delete()
                .wait()
            
            XCTAssertEqual(obj8?.keys, ["_id", "dummy1", "dummy2"])
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testQueryNumberOperation() throws {
        
        do {
            
            _ = try connection.mongoQuery().createCollection("testQueryNumberOperation").execute().wait()
            
            var obj = DBObject(class: "testQueryNumberOperation")
            obj["_id"] = "1"
            obj["col_1"] = 1
            obj["col_2"] = 1
            obj["col_3"] = 1
            obj["col_4"] = 1
            
            obj = try obj.save(on: connection).wait()
            
            obj.increment("col_1", by: 2)
            obj.decrement("col_2", by: 2)
            obj.multiply("col_3", by: 2)
            obj.divide("col_4", by: 2)
            
            obj = try obj.save(on: connection).wait()
            
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
    
    func testQueryArrayOperation() throws {
        
        do {
            
            _ = try connection.mongoQuery().createCollection("testQueryArrayOperation").execute().wait()
            
            var obj = DBObject(class: "testQueryArrayOperation")
            obj["_id"] = "1"
            obj["int_array"] = []
            
            obj = try obj.save(on: connection).wait()
            
            obj.push("int_array", values: [1 as DBData, 2.0, 3])
            
            obj = try obj.save(on: connection).wait()
            
            XCTAssertEqual(obj["_id"].string, "1")
            XCTAssertEqual(obj["int_array"].array, [1, 2.0, 3])
            
            obj.popFirst(for: "int_array")
            
            obj = try obj.save(on: connection).wait()
            
            XCTAssertEqual(obj["int_array"].array, [2.0, 3])
            
            obj.popLast(for: "int_array")
            
            obj = try obj.save(on: connection).wait()
            
            XCTAssertEqual(obj["int_array"].array, [2.0])
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testQueryArrayOperation2() throws {
        
        do {
            
            _ = try connection.mongoQuery().createCollection("testQueryArrayOperation2").execute().wait()
            
            var obj = DBObject(class: "testQueryArrayOperation2")
            obj["_id"] = "1"
            obj["int_array"] = [1, 2, 2, 3, 5, 5]
            
            obj = try obj.save(on: connection).wait()
            
            obj.addToSet("int_array", values: [2, 3, 4, 4])
            
            obj = try obj.save(on: connection).wait()
            
            XCTAssertEqual(obj["_id"].string, "1")
            XCTAssertEqual(obj["int_array"].array, [1, 2, 2, 3, 5, 5, 4])
            
            obj.removeAll("int_array", values: [2, 3])
            
            obj = try obj.save(on: connection).wait()
            
            XCTAssertEqual(obj["_id"].string, "1")
            XCTAssertEqual(obj["int_array"].array, [1, 5, 5, 4])
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
}
