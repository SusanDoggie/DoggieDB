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
import XCTest

class SQLiteTest: XCTestCase {
    
    let threadPool = NIOThreadPool(numberOfThreads: 2)
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    
    var connection: DBConnection!
    
    override func setUpWithError() throws {
        
        do {
            
            self.connection = try Database.createSQLite(threadPool: threadPool, on: eventLoopGroup.next()).wait()
            print("SQLITE:", try connection.version().wait())
            
        } catch let error {
            
            print(error)
            throw error
        }
    }
    
    override func tearDownWithError() throws {
        
        do {
            
            try self.connection.close().wait()
            try eventLoopGroup.syncShutdownGracefully()
            try threadPool.syncShutdownGracefully()
            
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
                first_name TEXT NOT NULL,
                last_name TEXT,
                email TEXT NOT NULL UNIQUE,
                phone TEXT NOT NULL UNIQUE
            );
            """).wait()
            
            XCTAssertTrue(try connection.tables().wait().contains("contacts"))
            
            let tableInfo = try connection.tableInfo("contacts").wait()
            
            guard let contact_id = tableInfo.first(where: { $0["name"] == "contact_id" }) else { XCTFail(); return }
            guard let first_name = tableInfo.first(where: { $0["name"] == "first_name" }) else { XCTFail(); return }
            guard let last_name = tableInfo.first(where: { $0["name"] == "last_name" }) else { XCTFail(); return }
            guard let email = tableInfo.first(where: { $0["name"] == "email" }) else { XCTFail(); return }
            guard let phone = tableInfo.first(where: { $0["name"] == "phone" }) else { XCTFail(); return }
            
            XCTAssertEqual(contact_id["type"], "INTEGER")
            XCTAssertEqual(first_name["type"], "TEXT")
            XCTAssertEqual(last_name["type"], "TEXT")
            XCTAssertEqual(email["type"], "TEXT")
            XCTAssertEqual(phone["type"], "TEXT")
            
            XCTAssertEqual(contact_id["pk"], 1)
            XCTAssertEqual(first_name["pk"], 0)
            XCTAssertEqual(last_name["pk"], 0)
            XCTAssertEqual(email["pk"], 0)
            XCTAssertEqual(phone["pk"], 0)
            
            XCTAssertEqual(contact_id["notnull"], 1)
            XCTAssertEqual(first_name["notnull"], 1)
            XCTAssertEqual(last_name["notnull"], 0)
            XCTAssertEqual(email["notnull"], 1)
            XCTAssertEqual(phone["notnull"], 1)
            
        } catch let error {
            
            print(error)
            throw error
        }
    }
    
}
