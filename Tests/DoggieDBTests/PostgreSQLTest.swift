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
    
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    
    var connection: DBConnection!
    
    override func setUpWithError() throws {
        
        do {
            
            let host = env("POSTGRES_HOST") ?? "localhost"
            let user = env("POSTGRES_USERNAME")
            let password = env("POSTGRES_PASSWORD")
            let database = env("POSTGRES_DATABASE") ?? ""
            
            print("POSTGRES_HOST:", host)
            print("POSTGRES_USERNAME:", user ?? "")
            print("POSTGRES_PASSWORD:", password ?? "")
            print("POSTGRES_DATABASE:", database)
            
            var url = URLComponents()
            url.scheme = "postgres"
            url.host = host
            url.user = user
            url.password = password
            url.path = "/\(database)"
            
            print("POSTGRES:", url)
            
            self.connection = try Database.connect(url: url, on: eventLoopGroup.next()).wait()
            
            print("POSTGRES:", try connection.version().wait())
            
        } catch let error {
            
            print(error)
            throw error
        }
    }
    
    override func tearDownWithError() throws {
        try self.connection.close().wait()
        try eventLoopGroup.syncShutdownGracefully()
    }
    
    func testCreateTable() throws {
        
        do {
            
            let query = """
            CREATE TABLE contacts (
                contact_id INTEGER PRIMARY KEY NOT NULL,
                first_name TEXT NOT NULL,
                last_name TEXT,
                email TEXT NOT NULL UNIQUE,
                phone TEXT NOT NULL UNIQUE
            );
            """
            
            _ = try connection.query(query, []).wait()
            
            print(try connection.tables().wait())
            
            XCTAssertTrue(try connection.tables().wait().contains("contacts"))
            
            let tableInfo = try connection.tableInfo("contacts").wait()
            
            print(tableInfo)
            
            guard let contact_id = tableInfo.first(where: { $0["column_name"] == "contact_id" }) else { XCTFail(); return }
            guard let first_name = tableInfo.first(where: { $0["column_name"] == "first_name" }) else { XCTFail(); return }
            guard let last_name = tableInfo.first(where: { $0["column_name"] == "last_name" }) else { XCTFail(); return }
            guard let email = tableInfo.first(where: { $0["column_name"] == "email" }) else { XCTFail(); return }
            guard let phone = tableInfo.first(where: { $0["column_name"] == "phone" }) else { XCTFail(); return }
            
            XCTAssertEqual(contact_id["data_type"], "integer")
            XCTAssertEqual(first_name["data_type"], "text")
            XCTAssertEqual(last_name["data_type"], "text")
            XCTAssertEqual(email["data_type"], "text")
            XCTAssertEqual(phone["data_type"], "text")
            
            XCTAssertEqual(contact_id["is_nullable"], false)
            XCTAssertEqual(first_name["is_nullable"], false)
            XCTAssertEqual(last_name["is_nullable"], true)
            XCTAssertEqual(email["is_nullable"], false)
            XCTAssertEqual(phone["is_nullable"], false)
            
        } catch let error {
            
            print(error)
            throw error
        }
    }
    
}
