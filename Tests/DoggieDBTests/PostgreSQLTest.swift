//
//  PostgreSQLTest.swift
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

class PostgreSQLTest: XCTestCase {
    
    var eventLoopGroup: MultiThreadedEventLoopGroup!
    var connection: DBSQLConnection!
    
    override func setUpWithError() throws {
        
        do {
            
            eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            
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
            
            self.connection = try Database.connect(url: url, on: eventLoopGroup).wait() as? DBSQLConnection
            
            print("POSTGRES:", try connection.version().wait())
            
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
    
    func testCreateTable() throws {
        
        do {
            
            _ = try connection.execute("""
                CREATE TABLE contacts (
                    contact_id INTEGER NOT NULL PRIMARY KEY,
                    first_name TEXT NOT NULL,
                    last_name TEXT,
                    email TEXT NOT NULL UNIQUE,
                    phone TEXT NOT NULL UNIQUE
                )
                """).wait()
            
            XCTAssertTrue(try connection.tables().wait().contains("contacts"))
            
            let tableInfo = try connection.columns(of: "contacts").wait()
            
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
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testPrimaryKey() throws {
        
        do {
            
            _ = try connection.execute("""
                CREATE TABLE testPrimaryKey (
                    column_1 INTEGER NOT NULL,
                    column_2 TEXT NOT NULL,
                    column_3 TEXT NOT NULL,
                    column_4 TEXT,
                    column_5 TEXT NOT NULL UNIQUE,
                    PRIMARY KEY (column_1, column_3, column_2)
                )
                """).wait()
            
            let primaryKey = try connection.primaryKey(of: "testPrimaryKey").wait()
            
            XCTAssertEqual(primaryKey, ["column_1", "column_3", "column_2"])
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testBindInt() throws {
        
        do {
            
            let int = 42
            
            let result = try connection.execute("SELECT \(int) as value").wait()
            
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result[0]["value"]?.intValue, int)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testBindInt2() throws {
        
        do {
            
            let int = 42
            
            let result = try connection.execute("SELECT \(bind: int) as value").wait()
            
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result[0]["value"]?.intValue, int)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testBindUUID() throws {
        
        do {
            
            let uuid = UUID()
            
            let result = try connection.execute("SELECT \(uuid) as uuid").wait()
            
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result[0]["uuid"]?.uuid, uuid)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testBindString() throws {
        
        do {
            
            let str = "Hello, world"
            
            let result = try connection.execute("SELECT \(str) as str").wait()
            
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result[0]["str"]?.string, str)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testBindArray() throws {
        
        do {
            
            let array: [DBData] = [1, 2, 3]
            
            let result = try connection.execute("SELECT \(array) as array").wait()
            
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result[0]["array"]?.array, array)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testBindJson() throws {
        
        do {
            
            let array: [DBData] = [1.0, 2.0, "foo", nil]
            
            let result = try connection.execute("SELECT \(array) as array").wait()
            
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result[0]["array"]?.array, array)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testBindTimestamp() throws {
        
        do {
            
            let timestamp = Date()
            
            let result = try connection.execute("SELECT \(timestamp) as \"now\"").wait()
            
            XCTAssertEqual(result[0]["now"]?.date, timestamp)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testBindDate() throws {
        
        do {
            
            let date = DateComponents(year: 2000, month: 1, day: 1)
            
            let result = try connection.execute("SELECT \(date)::date as \"date\"").wait()
            
            print(result[0]["date"]?.dateComponents == date)
            XCTAssertEqual(result[0]["date"]?.dateComponents?.year, date.year)
            XCTAssertEqual(result[0]["date"]?.dateComponents?.month, date.month)
            XCTAssertEqual(result[0]["date"]?.dateComponents?.day, date.day)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testBindTime() throws {
        
        do {
            
            let time = DateComponents(hour: 21, minute: 16, second: 32, nanosecond: 0)
            
            let result = try connection.execute("SELECT \(time)::time as \"time\"").wait()
            
            XCTAssertEqual(result[0]["time"]?.dateComponents?.timeZone?.secondsFromGMT(), 0)
            XCTAssertEqual(result[0]["time"]?.dateComponents?.hour, time.hour)
            XCTAssertEqual(result[0]["time"]?.dateComponents?.minute, time.minute)
            XCTAssertEqual(result[0]["time"]?.dateComponents?.second, time.second)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testBindTimetz() throws {
        
        do {
            
            let timeZone = TimeZone(secondsFromGMT: 28800)
            
            let time = DateComponents(timeZone: timeZone, hour: 21, minute: 16, second: 32, nanosecond: 0)
            
            let result = try connection.execute("SELECT \(time)::timetz as \"time\"").wait()
            
            XCTAssertEqual(result[0]["time"]?.dateComponents?.timeZone?.secondsFromGMT(), timeZone?.secondsFromGMT())
            XCTAssertEqual(result[0]["time"]?.dateComponents?.hour, time.hour)
            XCTAssertEqual(result[0]["time"]?.dateComponents?.minute, time.minute)
            XCTAssertEqual(result[0]["time"]?.dateComponents?.second, time.second)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testBindTimetz2() throws {
        
        do {
            
            let result = try connection.execute("SELECT '21:16:32+08:00'::timetz as \"time\"").wait()
            
            XCTAssertEqual(result[0]["time"]?.dateComponents?.timeZone?.secondsFromGMT(), 28800)
            XCTAssertEqual(result[0]["time"]?.dateComponents?.hour, 21)
            XCTAssertEqual(result[0]["time"]?.dateComponents?.minute, 16)
            XCTAssertEqual(result[0]["time"]?.dateComponents?.second, 32)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testBindMultiple() throws {
        
        do {
            
            let int = 42
            let uuid = UUID()
            let uuid2 = UUID()
            let str = "Hello, world"
            
            let result = try connection.execute("SELECT \(bind: int) as value, \(uuid) as uuid, \(uuid2) as uuid2, \(str) as str, \(str) as str2").wait()
            
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result[0]["value"]?.intValue, int)
            XCTAssertEqual(result[0]["uuid"]?.uuid, uuid)
            XCTAssertEqual(result[0]["uuid2"]?.uuid, uuid2)
            XCTAssertEqual(result[0]["str"]?.string, str)
            XCTAssertEqual(result[0]["str2"]?.string, str)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testRecursive() throws {
        
        do {
            
            let result = try connection.execute("""
                WITH RECURSIVE test AS (
                    SELECT 1 AS n
                    UNION
                    SELECT n+1 AS n FROM test
                )
                SELECT n FROM test
                LIMIT 10
                """).wait()
            
            for (i, row) in result.enumerated() {
                XCTAssertEqual(row["n"]?.intValue, i + 1)
            }
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testTransaction() throws {
        
        do {
            
            _ = try connection.execute("BEGIN").wait()
            
            let result = try connection.execute("SELECT \(1) as value").wait()
            
            _ = try connection.execute("COMMIT").wait()
            
            XCTAssertEqual(result[0]["value"]?.intValue, 1)
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testQuery() throws {
        
        do {
            
            _ = try connection.execute("""
                CREATE TABLE testQuery (
                    id INTEGER NOT NULL PRIMARY KEY,
                    first_name TEXT,
                    last_name TEXT,
                    email TEXT,
                    phone TEXT
                )
                """).wait()
            
            var obj = DBObject(class: "testQuery")
            obj["id"] = 1
            
            obj = try obj.save(on: connection).wait()
            
            obj["last_name"] = "Susan"
            
            obj = try obj.save(on: connection).wait()
            
            XCTAssertEqual(obj["id"]?.intValue, 1)
            XCTAssertEqual(obj["last_name"]?.string, "Susan")
            
            let list = try connection.query().find("testQuery").toArray().wait()
            
            XCTAssertEqual(list.count, 1)
            
            XCTAssertEqual(list[0]["id"]?.intValue, 1)
            XCTAssertEqual(list[0]["last_name"]?.string, "Susan")
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    func testQueryArrayOperation() throws {
        
        do {
            
            _ = try connection.execute("""
                CREATE TABLE testQueryArrayOperation (
                    id INTEGER NOT NULL PRIMARY KEY,
                    int_array INTEGER[],
                    json_array JSON,
                    jsonb_array JSONB
                )
                """).wait()
            
            var obj = DBObject(class: "testQueryArrayOperation")
            obj["id"] = 1
            obj["int_array"] = []
            obj["json_array"] = []
            obj["jsonb_array"] = []
            
            obj = try obj.save(on: connection).wait()
            
            obj.push("int_array", with: 1)
            obj.push("json_array", with: 1)
            obj.push("jsonb_array", with: 1)
            
            obj = try obj.save(on: connection).wait()
            
            XCTAssertEqual(obj["id"]?.intValue, 1)
            XCTAssertEqual(obj["int_array"]?.array, [1])
            XCTAssertEqual(obj["json_array"]?.array, [1])
            XCTAssertEqual(obj["jsonb_array"]?.array, [1])
            
        } catch {
            
            print(error)
            throw error
        }
    }
}
