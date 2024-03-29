//
//  PostgreSQLTest.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2024 Susan Cheng. All rights reserved.
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

class PostgreSQLTest: DoggieDBTestCase {
    
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
    
    var sqlconnection: DBSQLConnection { self.connection as! DBSQLConnection }
    
    func testCreateTable() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE contacts (
                contact_id INTEGER NOT NULL PRIMARY KEY,
                first_name TEXT NOT NULL,
                last_name TEXT,
                email TEXT NOT NULL UNIQUE,
                phone TEXT NOT NULL UNIQUE
            )
            """)
        
        let tables = try await sqlconnection.tables()
        XCTAssertTrue(tables.contains("contacts"))
        
        let tableInfo = try await sqlconnection.columns(of: "contacts")
        
        guard let contact_id = tableInfo.first(where: { $0.name == "contact_id" }) else { XCTFail(); return }
        guard let first_name = tableInfo.first(where: { $0.name == "first_name" }) else { XCTFail(); return }
        guard let last_name = tableInfo.first(where: { $0.name == "last_name" }) else { XCTFail(); return }
        guard let email = tableInfo.first(where: { $0.name == "email" }) else { XCTFail(); return }
        guard let phone = tableInfo.first(where: { $0.name == "phone" }) else { XCTFail(); return }
        
        XCTAssertEqual(contact_id.type, "integer")
        XCTAssertEqual(first_name.type, "text")
        XCTAssertEqual(last_name.type, "text")
        XCTAssertEqual(email.type, "text")
        XCTAssertEqual(phone.type, "text")
        
        XCTAssertEqual(contact_id.isOptional, false)
        XCTAssertEqual(first_name.isOptional, false)
        XCTAssertEqual(last_name.isOptional, true)
        XCTAssertEqual(email.isOptional, false)
        XCTAssertEqual(phone.isOptional, false)
    }
    
    func testTableSize() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testTableSize (
                column_1 INTEGER NOT NULL PRIMARY KEY
            )
            """)
        
        _ = try await sqlconnection.size(of: "testTableSize")
    }
    
    func testPrimaryKey() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testPrimaryKey (
                column_1 INTEGER NOT NULL,
                column_2 TEXT NOT NULL,
                column_3 TEXT NOT NULL,
                column_4 TEXT,
                column_5 TEXT NOT NULL UNIQUE,
                PRIMARY KEY (column_1, column_3, column_2)
            )
            """)
        
        let primaryKey = try await sqlconnection.primaryKey(of: "testPrimaryKey")
        
        XCTAssertEqual(primaryKey, ["column_1", "column_3", "column_2"])
    }
    
    func testBindInt() async throws {
        
        let int = 42
        
        let result = try await sqlconnection.execute("SELECT \(int) as value")
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0]["value"]?.intValue, int)
    }
    
    func testBindInt2() async throws {
        
        let int = 42
        
        let result = try await sqlconnection.execute("SELECT \(bind: int) as value")
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0]["value"]?.intValue, int)
    }
    
    func testBindUUID() async throws {
        
        let uuid = UUID()
        
        let result = try await sqlconnection.execute("SELECT \(uuid) as uuid")
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0]["uuid"]?.uuid, uuid)
    }
    
    func testBindString() async throws {
        
        let str = "Hello, world"
        
        let result = try await sqlconnection.execute("SELECT \(str) as str")
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0]["str"]?.string, str)
    }
    
    func testBindArray() async throws {
        
        let array: [DBData] = [1, 2, 3]
        
        let result = try await sqlconnection.execute("SELECT \(array) as array")
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0]["array"]?.array, array)
    }
    
    func testBindJson() async throws {
        
        let array: [DBData] = [1.0, 2.0, "foo", nil]
        
        let result = try await sqlconnection.execute("SELECT \(array) as array")
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0]["array"]?.array, array)
    }
    
    func testBindTimestamp() async throws {
        
        let timestamp = Date()
        
        let result = try await sqlconnection.execute("SELECT \(timestamp) as \"now\"")
        
        XCTAssertEqual(result[0]["now"]?.date, timestamp)
    }
    
    func testBindDate() async throws {
        
        let date = DateComponents(year: 2000, month: 1, day: 1)
        
        let result = try await sqlconnection.execute("SELECT \(date)::date as \"date\"")
        
        XCTAssertEqual(result[0]["date"]?.dateComponents?.year, date.year)
        XCTAssertEqual(result[0]["date"]?.dateComponents?.month, date.month)
        XCTAssertEqual(result[0]["date"]?.dateComponents?.day, date.day)
    }
    
    func testBindTime() async throws {
        
        let time = DateComponents(hour: 21, minute: 16, second: 32, nanosecond: 0)
        
        let result = try await sqlconnection.execute("SELECT \(time)::time as \"time\"")
        
        XCTAssertEqual(result[0]["time"]?.dateComponents?.timeZone?.secondsFromGMT(), 0)
        XCTAssertEqual(result[0]["time"]?.dateComponents?.hour, time.hour)
        XCTAssertEqual(result[0]["time"]?.dateComponents?.minute, time.minute)
        XCTAssertEqual(result[0]["time"]?.dateComponents?.second, time.second)
    }
    
    func testBindTimetz() async throws {
        
        let timeZone = TimeZone(secondsFromGMT: 28800)
        
        let time = DateComponents(timeZone: timeZone, hour: 21, minute: 16, second: 32, nanosecond: 0)
        
        let result = try await sqlconnection.execute("SELECT \(time)::timetz as \"time\"")
        
        XCTAssertEqual(result[0]["time"]?.dateComponents?.timeZone?.secondsFromGMT(), timeZone?.secondsFromGMT())
        XCTAssertEqual(result[0]["time"]?.dateComponents?.hour, time.hour)
        XCTAssertEqual(result[0]["time"]?.dateComponents?.minute, time.minute)
        XCTAssertEqual(result[0]["time"]?.dateComponents?.second, time.second)
    }
    
    func testBindTimetz2() async throws {
        
        let result = try await sqlconnection.execute("SELECT '21:16:32+08:00'::timetz as \"time\"")
        
        XCTAssertEqual(result[0]["time"]?.dateComponents?.timeZone?.secondsFromGMT(), 28800)
        XCTAssertEqual(result[0]["time"]?.dateComponents?.hour, 21)
        XCTAssertEqual(result[0]["time"]?.dateComponents?.minute, 16)
        XCTAssertEqual(result[0]["time"]?.dateComponents?.second, 32)
    }
    
    func testBindMultiple() async throws {
        
        let int = 42
        let uuid = UUID()
        let uuid2 = UUID()
        let str = "Hello, world"
        
        let result = try await sqlconnection.execute("SELECT \(bind: int) as value, \(uuid) as uuid, \(uuid2) as uuid2, \(str) as str, \(str) as str2")
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0]["value"]?.intValue, int)
        XCTAssertEqual(result[0]["uuid"]?.uuid, uuid)
        XCTAssertEqual(result[0]["uuid2"]?.uuid, uuid2)
        XCTAssertEqual(result[0]["str"]?.string, str)
        XCTAssertEqual(result[0]["str2"]?.string, str)
    }
    
    func testRecursive() async throws {
        
        let result = try await sqlconnection.execute("""
            WITH RECURSIVE test AS (
                SELECT 1 AS n
                UNION
                SELECT n+1 AS n FROM test
            )
            SELECT n FROM test
            LIMIT 10
            """)
        
        for (i, row) in result.enumerated() {
            XCTAssertEqual(row["n"]?.intValue, i + 1)
        }
    }
    
    func testTransaction() async throws {
        
        _ = try await sqlconnection.execute("BEGIN")
        
        let result = try await sqlconnection.execute("SELECT \(1) as value")
        
        _ = try await sqlconnection.execute("COMMIT")
        
        XCTAssertEqual(result[0]["value"]?.intValue, 1)
    }
    
    func testTransaction2() async throws {
        
        let result = try await sqlconnection.withTransaction { connection in
            
            try await (connection as! DBSQLConnection).execute("SELECT \(1) as value")
            
        }
        
        XCTAssertEqual(result[0]["value"]?.intValue, 1)
    }
    
    func testTransaction3() async throws {
        
        let result = try await sqlconnection.withTransaction { connection in
            
            try await connection.withTransaction { connection in
                
                try await (connection as! DBSQLConnection).execute("SELECT \(1) as value")
                
            }
            
        }
        
        XCTAssertEqual(result[0]["value"]?.intValue, 1)
    }
    
    func testTransaction4() async throws {
        
        do {
            
            let connection = sqlconnection
            
            let _ = try await connection.withTransaction { _ in
                
                try await connection.withTransaction { _ in
                    
                    try await connection.execute("SELECT \(1) as value")
                    
                }
                
            }
            
            XCTFail()
            
        } catch {
            
            XCTAssertEqual(error as? Database.Error, Database.Error.transactionDeadlocks)
        }
    }
    
    func testQuery() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testQuery (
                id INTEGER NOT NULL PRIMARY KEY,
                first_name TEXT,
                last_name TEXT,
                email TEXT,
                phone TEXT
            )
            """)
        
        var obj = DBObject(class: "testQuery")
        obj["id"] = 1
        
        try await obj.save(on: sqlconnection)
        
        obj["last_name"] = "Susan"
        
        try await obj.save(on: sqlconnection)
        
        XCTAssertEqual(obj["id"].intValue, 1)
        XCTAssertEqual(obj["last_name"].string, "Susan")
        
        let list = try await sqlconnection.query().find("testQuery").toArray()
        
        XCTAssertEqual(list.count, 1)
        
        XCTAssertEqual(list[0]["id"].intValue, 1)
        XCTAssertEqual(list[0]["last_name"].string, "Susan")
    }
    
    func testJSON() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testJSON (
                id INTEGER NOT NULL PRIMARY KEY,
                col JSONB
            )
            """)
        
        let json: DBData = [
            "boolean": true,
            "string": "",
            "number": 1.0,
            "array": [],
            "dictionary": [:],
        ]
        
        let obj1 = try await sqlconnection.query().insert("testJSON", ["id": 1, "col": json])
        
        XCTAssertEqual(obj1["id"].intValue, 1)
        XCTAssertEqual(obj1["col"], json)
    }
    
    func testPatternMatchingQuery() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testPatternMatchingQuery (
                id INTEGER NOT NULL PRIMARY KEY,
                col TEXT
            )
            """)
        
        _ = try await sqlconnection.query().insert("testPatternMatchingQuery", ["id": 1, "col": "text to be search"])
        _ = try await sqlconnection.query().insert("testPatternMatchingQuery", ["id": 2, "col": "long long' string%"])
        _ = try await sqlconnection.query().insert("testPatternMatchingQuery", ["id": 3, "col": "long long' string%, hello"])
        
        let res1 = try await sqlconnection.query()
            .find("testPatternMatchingQuery")
            .filter { .startsWith($0["col"], "text to ") }
            .toArray()
        
        XCTAssertEqual(res1.count, 1)
        XCTAssertEqual(res1.first?["id"].intValue, 1)
        
        let res2 = try await sqlconnection.query()
            .find("testPatternMatchingQuery")
            .filter { .endsWith($0["col"], "ong' string%") }
            .toArray()
        
        XCTAssertEqual(res2.count, 1)
        XCTAssertEqual(res2.first?["id"].intValue, 2)
        
        let res3 = try await sqlconnection.query()
            .find("testPatternMatchingQuery")
            .filter { .contains($0["col"], "long' s") }
            .toArray()
        
        XCTAssertEqual(res3.count, 2)
    }
    
    func testUpdateQuery() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testUpdateQuery (
                id INTEGER NOT NULL PRIMARY KEY,
                col TEXT
            )
            """)
        
        var obj = DBObject(class: "testUpdateQuery")
        obj["id"] = 1
        
        try await obj.save(on: sqlconnection)
        
        obj["col"] = "text_1"
        
        try await obj.save(on: sqlconnection)
        
        XCTAssertEqual(obj["id"].intValue, 1)
        XCTAssertEqual(obj["col"].string, "text_1")
        
        let obj2 = try await sqlconnection.query()
            .findOne("testUpdateQuery")
            .filter { $0.objectId == 1 }
            .update([
                "col": .set("text_2")
            ])
        
        XCTAssertEqual(obj2?["id"].intValue, 1)
        XCTAssertEqual(obj2?["col"].string, "text_2")
        
        let obj3 = try await sqlconnection.query()
            .findOne("testUpdateQuery")
            .filter { $0.objectId == 1 }
            .returning(.before)
            .update([
                "col": .set("text_3")
            ])
        
        XCTAssertEqual(obj3?["id"].intValue, 1)
        XCTAssertEqual(obj3?["col"].string, "text_2")
    }
    
    func testUpsertQuery() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testUpsertQuery (
                id INTEGER NOT NULL PRIMARY KEY,
                col TEXT
            )
            """)
        
        let obj = try await sqlconnection.query()
            .findOne("testUpsertQuery")
            .filter { $0.objectId == 1 }
            .upsert([
                "id": .setOnInsert(1),
                "col": .set("text_1"),
            ])
        
        XCTAssertEqual(obj?["id"].intValue, 1)
        XCTAssertEqual(obj?["col"].string, "text_1")
        
        let obj2 = try await sqlconnection.query()
            .findOne("testUpsertQuery")
            .filter { $0.objectId == 1 }
            .upsert([
                "id": .setOnInsert(1),
                "col": .set("text_2"),
            ])
        
        XCTAssertEqual(obj2?["id"].intValue, 1)
        XCTAssertEqual(obj2?["col"].string, "text_2")
        
        let obj3 = try await sqlconnection.query()
            .findOne("testUpsertQuery")
            .filter { $0.objectId == 1 }
            .returning(.before)
            .upsert([
                "id": .setOnInsert(1),
                "col": .set("text_3"),
            ])
        
        XCTAssertEqual(obj3?["id"].intValue, 1)
        XCTAssertEqual(obj3?["col"].string, "text_2")
    }
    
    func testIncludesQuery() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testIncludesQuery (
                id INTEGER NOT NULL PRIMARY KEY,
                dummy1 INTEGER,
                dummy2 INTEGER,
                dummy3 INTEGER,
                dummy4 INTEGER
            )
            """)
        
        let obj = try await sqlconnection.query()
            .findOne("testIncludesQuery")
            .filter { $0.objectId == 1 }
            .includes(["dummy1", "dummy2"])
            .upsert([
                "id": .setOnInsert(1),
                "dummy1": .set(1),
                "dummy2": .set(2),
                "dummy3": .set(3),
                "dummy4": .set(4),
            ])
        
        XCTAssertEqual(obj?.keys, ["id", "dummy1", "dummy2"])
        
        let obj2 = try await sqlconnection.query()
            .findOne("testIncludesQuery")
            .filter { $0.objectId == 2 }
            .includes(["dummy1", "dummy2"])
            .returning(.before)
            .upsert([
                "id": .setOnInsert(2),
                "dummy1": .set(1),
                "dummy2": .set(2),
                "dummy3": .set(3),
                "dummy4": .set(4),
            ])
        
        XCTAssertNil(obj2)
        
        let obj3 = try await sqlconnection.query()
            .findOne("testIncludesQuery")
            .filter { $0.objectId == 1 }
            .includes(["dummy1", "dummy2"])
            .upsert([
                "id": .setOnInsert(1),
                "dummy1": .set(1),
                "dummy2": .set(2),
                "dummy3": .set(3),
                "dummy4": .set(4),
            ])
        
        XCTAssertEqual(obj3?.keys, ["id", "dummy1", "dummy2"])
        
        let obj4 = try await sqlconnection.query()
            .findOne("testIncludesQuery")
            .filter { $0.objectId == 2 }
            .includes(["dummy1", "dummy2"])
            .returning(.before)
            .upsert([
                "id": .setOnInsert(2),
                "dummy1": .set(1),
                "dummy2": .set(2),
                "dummy3": .set(3),
                "dummy4": .set(4),
            ])
        
        XCTAssertEqual(obj4?.keys, ["id", "dummy1", "dummy2"])
        
        let obj5 = try await sqlconnection.query()
            .findOne("testIncludesQuery")
            .filter { $0.objectId == 1 }
            .includes(["dummy1", "dummy2"])
            .update([
                "dummy1": .set(1),
                "dummy2": .set(2),
                "dummy3": .set(3),
                "dummy4": .set(4),
            ])
        
        XCTAssertEqual(obj5?.keys, ["id", "dummy1", "dummy2"])
        
        let obj6 = try await sqlconnection.query()
            .findOne("testIncludesQuery")
            .filter { $0.objectId == 2 }
            .includes(["dummy1", "dummy2"])
            .returning(.before)
            .update([
                "dummy1": .set(1),
                "dummy2": .set(2),
                "dummy3": .set(3),
                "dummy4": .set(4),
            ])
        
        XCTAssertEqual(obj6?.keys, ["id", "dummy1", "dummy2"])
        
        let obj7 = try await sqlconnection.query()
            .find("testIncludesQuery")
            .filter { $0.objectId == 1 }
            .includes(["dummy1", "dummy2"])
            .first()
        
        
        XCTAssertEqual(obj7?.keys, ["id", "dummy1", "dummy2"])
        
        let obj8 = try await sqlconnection.query()
            .findOne("testIncludesQuery")
            .filter { $0.objectId == 1 }
            .includes(["dummy1", "dummy2"])
            .delete()
        
        
        XCTAssertEqual(obj8?.keys, ["id", "dummy1", "dummy2"])
    }
    
    func testQueryNumberOperation() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testQueryNumberOperation (
                id INTEGER NOT NULL PRIMARY KEY,
                col_1 INTEGER,
                col_2 DECIMAL,
                col_3 REAL
            )
            """)
        
        var obj = DBObject(class: "testQueryNumberOperation")
        obj["id"] = 1
        obj["col_1"] = 1
        obj["col_2"] = 1
        obj["col_3"] = 1
        
        try await obj.save(on: sqlconnection)
        
        obj.increment("col_1", by: 2)
        obj.increment("col_2", by: 2)
        obj.increment("col_3", by: 2)
        
        try await obj.save(on: sqlconnection)
        
        XCTAssertEqual(obj["id"].intValue, 1)
        XCTAssertEqual(obj["col_1"].intValue, 3)
        XCTAssertEqual(obj["col_2"].intValue, 3)
        XCTAssertEqual(obj["col_3"].intValue, 3)
    }
    
    func testQueryArrayOperation() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testQueryArrayOperation (
                id INTEGER NOT NULL PRIMARY KEY,
                int_array INTEGER[],
                jsonb_array JSONB
            )
            """)
        
        var obj = DBObject(class: "testQueryArrayOperation")
        obj["id"] = 1
        obj["int_array"] = []
        obj["jsonb_array"] = []
        
        try await obj.save(on: sqlconnection)
        
        obj.push("int_array", values: [1 as DBData, 2.0, 3])
        obj.push("jsonb_array", values: [1, 2.0, 3])
        
        try await obj.save(on: sqlconnection)
        
        XCTAssertEqual(obj["id"].intValue, 1)
        XCTAssertEqual(obj["int_array"].array, [1, 2, 3])
        XCTAssertEqual(obj["jsonb_array"].array, [1.0, 2.0, 3.0])
        
        obj.popFirst(for: "int_array")
        obj.popFirst(for: "jsonb_array")
        
        try await obj.save(on: sqlconnection)
        
        XCTAssertEqual(obj["int_array"].array, [2, 3])
        XCTAssertEqual(obj["jsonb_array"].array, [2.0, 3.0])
        
        obj.popLast(for: "int_array")
        obj.popLast(for: "jsonb_array")
        
        try await obj.save(on: sqlconnection)
        
        XCTAssertEqual(obj["int_array"].array, [2])
        XCTAssertEqual(obj["jsonb_array"].array, [2.0])
    }
    
    func testQueryArrayOperation2() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testQueryArrayOperation2 (
                id INTEGER NOT NULL PRIMARY KEY,
                int_array INTEGER[],
                jsonb_array JSONB
            )
            """)
        
        var obj = DBObject(class: "testQueryArrayOperation2")
        obj["id"] = 1
        obj["int_array"] = []
        obj["jsonb_array"] = []
        
        try await obj.save(on: sqlconnection)
        
        obj.popFirst(for: "int_array")
        obj.popFirst(for: "jsonb_array")
        
        try await obj.save(on: sqlconnection)
        
        XCTAssertEqual(obj["int_array"].array ?? [], [])
        XCTAssertEqual(obj["jsonb_array"].array, [])
        
        obj.popLast(for: "int_array")
        obj.popLast(for: "jsonb_array")
        
        try await obj.save(on: sqlconnection)
        
        XCTAssertEqual(obj["int_array"].array ?? [], [])
        XCTAssertEqual(obj["jsonb_array"].array, [])
    }
    
    func testQueryArrayOperation3() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testQueryArrayOperation3 (
                id INTEGER NOT NULL PRIMARY KEY,
                int_array INTEGER[]
            )
            """)
        
        var obj = DBObject(class: "testQueryArrayOperation3")
        obj["id"] = 1
        obj["int_array"] = [1, 2, 2, 3, 5, 5]
        
        try await obj.save(on: sqlconnection)
        
        obj.addToSet("int_array", values: [2, 3, 4, 4])
        
        try await obj.save(on: sqlconnection)
        
        XCTAssertEqual(obj["id"].intValue, 1)
        XCTAssertEqual(obj["int_array"].array, [1, 2, 2, 3, 5, 5, 4])
        
        obj.removeAll("int_array", values: [2, 3])
        
        try await obj.save(on: sqlconnection)
        
        XCTAssertEqual(obj["id"].intValue, 1)
        XCTAssertEqual(obj["int_array"].array, [1, 5, 4])
    }
    
    func testLongTransaction() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testLongTransaction (
                id INTEGER NOT NULL PRIMARY KEY,
                col INTEGER NOT NULL
            )
            """)
        
        _ = try await sqlconnection.query().insert("testLongTransaction", ["id": 1, "col": 0])
        
        var connections: [DBConnection] = []
        
        for _ in 0..<4 {
            try await connections.append(self._create_connection())
        }
        
        let result: Set<Int> = try await withThrowingTaskGroup(of: DBObject.self) { group in
            
            for connection in connections {
                
                group.addTask {
                    
                    try await connection.withTransaction(DBTransactionOptions(
                        mode: .repeatable,
                        retryOnConflict: true
                    )) { connection in
                        
                        var obj = try await connection.query().find("testLongTransaction").forUpdate().first()!
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
        
        XCTAssertEqual(result, [2, 4, 6, 8])
        
        for connection in connections {
            try await connection.close()
        }
    }
    
    func testLongTransaction2() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testLongTransaction2 (
                id INTEGER NOT NULL PRIMARY KEY,
                col INTEGER NOT NULL
            )
            """)
        
        _ = try await sqlconnection.query().insert("testLongTransaction2", ["id": 1, "col": 0])
        
        var connections: [DBConnection] = []
        
        for _ in 0..<4 {
            try await connections.append(self._create_connection())
        }
        
        let result: Set<Int> = try await withThrowingTaskGroup(of: DBObject.self) { group in
            
            for connection in connections {
                
                group.addTask {
                    
                    try await connection.withTransaction(DBTransactionOptions(
                        mode: .repeatable,
                        retryOnConflict: true
                    )) { connection in
                        
                        var obj = try await connection.query().find("testLongTransaction2").forUpdate().first()!
                        var value = obj["col"].intValue!
                        
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        
                        value += 1
                        obj = try await connection.query().findOne("testLongTransaction2")
                            .filter { $0.objectId == obj.objectId }
                            .update(["col": value])!
                        
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        
                        value += 1
                        obj = try await connection.query().findOne("testLongTransaction2")
                            .filter { $0.objectId == obj.objectId }
                            .update(["col": value])!
                        
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
        
        XCTAssertEqual(result, [2, 4, 6, 8])
        
        for connection in connections {
            try await connection.close()
        }
    }
    
    func testLongTransaction3() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testLongTransaction3 (
                id INTEGER NOT NULL PRIMARY KEY,
                col INTEGER NOT NULL
            )
            """)
        
        _ = try await sqlconnection.query().insert("testLongTransaction3", ["id": 1, "col": 0])
        
        var connections: [DBConnection] = []
        
        for _ in 0..<4 {
            try await connections.append(self._create_connection())
        }
        
        let result: Set<Int> = try await withThrowingTaskGroup(of: DBObject.self) { group in
            
            for connection in connections {
                
                group.addTask {
                    
                    try await connection.withTransaction(DBTransactionOptions(
                        mode: .repeatable,
                        retryOnConflict: true
                    )) { connection in
                        
                        var obj = try await connection.query().find("testLongTransaction3").forUpdate().first()!
                        var value = obj["col"].intValue!
                        
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        
                        value += 1
                        obj = try await connection.query().findOne("testLongTransaction3")
                            .filter { $0.objectId == obj.objectId }
                            .upsert(["col": value])!
                        
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        
                        value += 1
                        obj = try await connection.query().findOne("testLongTransaction3")
                            .filter { $0.objectId == obj.objectId }
                            .upsert(["col": value])!
                        
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
        
        XCTAssertEqual(result, [2, 4, 6, 8])
        
        for connection in connections {
            try await connection.close()
        }
    }
    
    func testLongTransaction4() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testLongTransaction4 (
                id INTEGER NOT NULL PRIMARY KEY,
                col INTEGER NOT NULL
            )
            """)
        
        _ = try await sqlconnection.query().insert("testLongTransaction4", ["id": 1, "col": 0])
        
        var connections: [DBConnection] = []
        
        for _ in 0..<4 {
            try await connections.append(self._create_connection())
        }
        
        let result: Set<Int> = try await withThrowingTaskGroup(of: DBObject.self) { group in
            
            for connection in connections {
                
                group.addTask {
                    
                    try await connection.withTransaction(DBTransactionOptions(
                        mode: .serializable,
                        retryOnConflict: true
                    )) { connection in
                        
                        var obj = try await connection.query().find("testLongTransaction4").forUpdate().first()!
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
        
        XCTAssertEqual(result, [2, 4, 6, 8])
        
        for connection in connections {
            try await connection.close()
        }
    }
    
    func testLongTransaction5() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testLongTransaction5 (
                id INTEGER NOT NULL PRIMARY KEY,
                col INTEGER NOT NULL
            )
            """)
        
        _ = try await sqlconnection.query().insert("testLongTransaction5", ["id": 1, "col": 0])
        
        var connections: [DBConnection] = []
        
        for _ in 0..<4 {
            try await connections.append(self._create_connection())
        }
        
        let result: Set<Int> = try await withThrowingTaskGroup(of: DBObject.self) { group in
            
            for connection in connections {
                
                group.addTask {
                    
                    try await connection.withTransaction(DBTransactionOptions(
                        mode: .serializable,
                        retryOnConflict: true
                    )) { connection in
                        
                        var obj = try await connection.query().find("testLongTransaction5").forUpdate().first()!
                        var value = obj["col"].intValue!
                        
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        
                        value += 1
                        obj = try await connection.query().findOne("testLongTransaction5")
                            .filter { $0.objectId == obj.objectId }
                            .update(["col": value])!
                        
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        
                        value += 1
                        obj = try await connection.query().findOne("testLongTransaction5")
                            .filter { $0.objectId == obj.objectId }
                            .update(["col": value])!
                        
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
        
        XCTAssertEqual(result, [2, 4, 6, 8])
        
        for connection in connections {
            try await connection.close()
        }
    }
    
    func testLongTransaction6() async throws {
        
        _ = try await sqlconnection.execute("""
            CREATE TABLE testLongTransaction6 (
                id INTEGER NOT NULL PRIMARY KEY,
                col INTEGER NOT NULL
            )
            """)
        
        _ = try await sqlconnection.query().insert("testLongTransaction6", ["id": 1, "col": 0])
        
        var connections: [DBConnection] = []
        
        for _ in 0..<4 {
            try await connections.append(self._create_connection())
        }
        
        let result: Set<Int> = try await withThrowingTaskGroup(of: DBObject.self) { group in
            
            for connection in connections {
                
                group.addTask {
                    
                    try await connection.withTransaction(DBTransactionOptions(
                        mode: .serializable,
                        retryOnConflict: true
                    )) { connection in
                        
                        var obj = try await connection.query().find("testLongTransaction6").forUpdate().first()!
                        var value = obj["col"].intValue!
                        
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        
                        value += 1
                        obj = try await connection.query().findOne("testLongTransaction6")
                            .filter { $0.objectId == obj.objectId }
                            .upsert(["col": value])!
                        
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        
                        value += 1
                        obj = try await connection.query().findOne("testLongTransaction6")
                            .filter { $0.objectId == obj.objectId }
                            .upsert(["col": value])!
                        
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
        
        XCTAssertEqual(result, [2, 4, 6, 8])
        
        for connection in connections {
            try await connection.close()
        }
    }
    
}
