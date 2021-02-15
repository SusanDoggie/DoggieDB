//
//  MySQLTest.swift
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

class MySQLTest: XCTestCase {
    
    var eventLoopGroup: MultiThreadedEventLoopGroup!
    var connection: DBConnection!
    
    override func setUpWithError() throws {
        
        do {
            
            eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            
            var url = URLComponents()
            url.scheme = "mysql"
            url.host = env("MYSQL_HOST") ?? "localhost"
            url.user = env("MYSQL_USERNAME")
            url.password = env("MYSQL_PASSWORD")
            url.path = "/\(env("MYSQL_DATABASE") ?? "")"
            
            if let ssl_mode = env("MYSQL_SSLMODE") {
                url.queryItems = [
                    URLQueryItem(name: "ssl", value: "true"),
                    URLQueryItem(name: "sslmode", value: ssl_mode),
                ]
            }
            
            self.connection = try Database.connect(url: url, on: eventLoopGroup.next()).wait()
            
            print("MYSQL:", try connection.version().wait())
            
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
            
            _ = try connection.execute("""
            CREATE TABLE contacts (
                contact_id INTEGER PRIMARY KEY NOT NULL,
                first_name VARCHAR(255) NOT NULL,
                last_name VARCHAR(255),
                email VARCHAR(255) NOT NULL UNIQUE,
                phone VARCHAR(255) NOT NULL UNIQUE
            )
            """).wait()
            
            XCTAssertTrue(try connection.tables().wait().contains("contacts"))
            
            let tableInfo = try connection.tableInfo("contacts").wait()
            
            guard let contact_id = tableInfo.first(where: { $0["Field"] == "contact_id" }) else { XCTFail(); return }
            guard let first_name = tableInfo.first(where: { $0["Field"] == "first_name" }) else { XCTFail(); return }
            guard let last_name = tableInfo.first(where: { $0["Field"] == "last_name" }) else { XCTFail(); return }
            guard let email = tableInfo.first(where: { $0["Field"] == "email" }) else { XCTFail(); return }
            guard let phone = tableInfo.first(where: { $0["Field"] == "phone" }) else { XCTFail(); return }
            
            XCTAssertEqual(contact_id["Type"]?.string?.prefix(3), "int")
            XCTAssertEqual(first_name["Type"]?.string, "varchar(255)")
            XCTAssertEqual(last_name["Type"]?.string, "varchar(255)")
            XCTAssertEqual(email["Type"]?.string, "varchar(255)")
            XCTAssertEqual(phone["Type"]?.string, "varchar(255)")
            
            XCTAssertEqual(contact_id["Key"]?.string, "PRI")
            XCTAssertEqual(first_name["Key"]?.string, "")
            XCTAssertEqual(last_name["Key"]?.string, "")
            XCTAssertEqual(email["Key"]?.string, "UNI")
            XCTAssertEqual(phone["Key"]?.string, "UNI")
            
            XCTAssertEqual(contact_id["Null"]?.string, "NO")
            XCTAssertEqual(first_name["Null"]?.string, "NO")
            XCTAssertEqual(last_name["Null"]?.string, "YES")
            XCTAssertEqual(email["Null"]?.string, "NO")
            XCTAssertEqual(phone["Null"]?.string, "NO")
            
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
            
            let result = try connection.execute("SELECT CAST(\(bind: int) AS SIGNED) as value").wait()
            
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
            
            let result = try connection.execute("SELECT HEX(CAST(\(uuid) AS BINARY(16))) as uuid").wait()
            
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
            
            let result = try connection.execute("SELECT CAST(\(str) AS CHAR CHARACTER SET utf8mb4) as str").wait()
            
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result[0]["str"]?.string, str)
            
        } catch let error {
            
            print(error)
            throw error
        }
    }
    func testBindTimestamp() throws {
        
        do {
            
            let timestamp = Date(timeIntervalSince1970: round(Date().timeIntervalSince1970))
            
            let result = try connection.execute("SELECT CAST(\(timestamp) AS DATETIME) as \"now\"").wait()
            
            XCTAssertEqual(result[0]["now"]?.date, timestamp)
            
        } catch let error {
            
            print(error)
            throw error
        }
    }
    
    func testBindDate() throws {
        
        do {
            
            let date = DateComponents(year: 2000, month: 1, day: 1)
            
            let result = try connection.execute("SELECT CAST(\(date) AS DATE) as \"date\"").wait()
            
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
            
            let time = DateComponents(hour: 21, minute: 0, second: 0, nanosecond: 0)
            
            let result = try connection.execute("SELECT CAST(\(time) AS TIME) as \"time\"").wait()
            
            XCTAssertEqual(result[0]["time"]?.dateComponents?.hour, time.hour)
            XCTAssertEqual(result[0]["time"]?.dateComponents?.minute, time.minute)
            XCTAssertEqual(result[0]["time"]?.dateComponents?.second, time.second)
            
        } catch let error {
            
            print(error)
            throw error
        }
    }
    
    func testRecursive() throws {
        
        do {
            
            let result = try connection.sql()
                .withRecursive(test: { $0.columns("1 AS n").union().columns("n+1 AS n").from("test") })
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
}
