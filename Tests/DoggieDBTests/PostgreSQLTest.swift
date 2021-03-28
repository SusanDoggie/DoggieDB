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
    var connection: DBConnection!
    
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
            
            self.connection = try Database.connect(url: url, on: eventLoopGroup.next()).wait()
            
            print("POSTGRES:", try connection.version().wait())
            
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
    
    func testCreateTable() throws {
        
        do {
            
            _ = try connection.sql().createTable("contacts")
                .column(name: "contact_id", type: "INTEGER", optional: false, primaryKey: true)
                .column(name: "first_name", type: "TEXT", optional: false)
                .column(name: "last_name", type: "TEXT")
                .column(name: "email", type: "TEXT", optional: false, unique: true)
                .column(name: "phone", type: "TEXT", optional: false, unique: true)
                .execute().wait()
            
            XCTAssertTrue(try connection.tables().wait().contains("contacts"))
            
            let tableInfo = try connection.columns("contacts").wait()
            
            guard let contact_id = tableInfo.first(where: { $0["column_name"] == "contact_id" }) else { XCTFail(); return }
            guard let first_name = tableInfo.first(where: { $0["column_name"] == "first_name" }) else { XCTFail(); return }
            guard let last_name = tableInfo.first(where: { $0["column_name"] == "last_name" }) else { XCTFail(); return }
            guard let email = tableInfo.first(where: { $0["column_name"] == "email" }) else { XCTFail(); return }
            guard let phone = tableInfo.first(where: { $0["column_name"] == "phone" }) else { XCTFail(); return }
            
            XCTAssertEqual(contact_id["data_type"]?.string, "integer")
            XCTAssertEqual(first_name["data_type"]?.string, "text")
            XCTAssertEqual(last_name["data_type"]?.string, "text")
            XCTAssertEqual(email["data_type"]?.string, "text")
            XCTAssertEqual(phone["data_type"]?.string, "text")
            
            XCTAssertEqual(contact_id["is_nullable"]?.string, "NO")
            XCTAssertEqual(first_name["is_nullable"]?.string, "NO")
            XCTAssertEqual(last_name["is_nullable"]?.string, "YES")
            XCTAssertEqual(email["is_nullable"]?.string, "NO")
            XCTAssertEqual(phone["is_nullable"]?.string, "NO")
            
        } catch let error {
            
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
            
        } catch let error {
            
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
            
        } catch let error {
            
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
            
        } catch let error {
            
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
            
        } catch let error {
            
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
            
        } catch let error {
            
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
            
        } catch let error {
            
            print(error)
            throw error
        }
    }
    
    func testBindTimestamp() throws {
        
        do {
            
            let timestamp = Date()
            
            let result = try connection.execute("SELECT \(timestamp) as \"now\"").wait()
            
            XCTAssertEqual(result[0]["now"]?.date, timestamp)
            
        } catch let error {
            
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
            
        } catch let error {
            
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
            
        } catch let error {
            
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
            
        } catch let error {
            
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
            
        } catch let error {
            
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
            
        } catch let error {
            
            print(error)
            throw error
        }
    }
    
    func testRecursive() throws {
        
        do {
            
            let result = try connection.sql()
                .withRecursive([
                    "test": SQLSelectBuilder.select().columns("1 AS n").union().select().columns("n+1 AS n").from("test")
                ])
                .select().columns("n").from("test")
                .limit(10)
                .execute().wait()
            
            for (i, row) in result.enumerated() {
                XCTAssertEqual(row["n"]?.intValue, i + 1)
            }
            
        } catch let error {
            
            print(error)
            throw error
        }
    }
    
    func testTransaction() throws {
        
        do {
            
            _ = try connection.sql().beginTransaction().execute().wait()
            
            let result = try connection.execute("SELECT \(1) as value").wait()
            
            _ = try connection.sql().commit().execute().wait()
            
            XCTAssertEqual(result[0]["value"]?.intValue, 1)
            
        } catch let error {
            
            print(error)
            throw error
        }
    }
}
