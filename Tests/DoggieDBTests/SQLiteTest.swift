//
//  SQLiteTest.swift
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
import DBSQLite
import XCTest

class SQLiteTest: XCTestCase {
    
    var threadPool: NIOThreadPool!
    var eventLoopGroup: MultiThreadedEventLoopGroup!
    var connection: DBSQLConnection!
    
    override func setUpWithError() throws {
        
        do {
            
            threadPool = NIOThreadPool(numberOfThreads: 2)
            eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
            
            self.connection = try Database.createSQLite(threadPool: threadPool, on: eventLoopGroup).wait() as? DBSQLConnection
            print("SQLITE:", try connection.version().wait())
            
        } catch {
            
            print(error)
            throw error
        }
    }
    
    override func tearDownWithError() throws {
        
        do {
            
            try self.connection.close().wait()
            try eventLoopGroup.syncShutdownGracefully()
            try threadPool.syncShutdownGracefully()
            
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
            
            XCTAssertEqual(contact_id.type, "INTEGER")
            XCTAssertEqual(first_name.type, "TEXT")
            XCTAssertEqual(last_name.type, "TEXT")
            XCTAssertEqual(email.type, "TEXT")
            XCTAssertEqual(phone.type, "TEXT")
            
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
}
