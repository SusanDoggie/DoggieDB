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
    
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    
    var connection: DBConnection!
    
    override func setUpWithError() throws {
        
        do {
            
            var url_components = URLComponents()
            url_components.scheme = "redis"
            url_components.host = env("MYSQL_HOST") ?? "localhost"
            url_components.user = env("MYSQL_USERNAME")
            url_components.password = env("MYSQL_PASSWORD")
            url_components.path = env("MYSQL_DATABASE") ?? ""
            
            let url = url_components.url!
            
            self.connection = try Database.connect(url: url, on: eventLoopGroup.next()).wait()
            
            print("MYSQL:", try connection.version().wait())
            
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
        
        XCTAssertTrue(try connection.tables().wait().contains("contacts"))
        
        let tableInfo = try connection.tableInfo("contacts").wait()
        
        guard let contact_id = tableInfo.first(where: { $0["Field"] == "contact_id" }) else { XCTFail(); return }
        guard let first_name = tableInfo.first(where: { $0["Field"] == "first_name" }) else { XCTFail(); return }
        guard let last_name = tableInfo.first(where: { $0["Field"] == "last_name" }) else { XCTFail(); return }
        guard let email = tableInfo.first(where: { $0["Field"] == "email" }) else { XCTFail(); return }
        guard let phone = tableInfo.first(where: { $0["Field"] == "phone" }) else { XCTFail(); return }
        
        XCTAssertEqual(contact_id["Type"], "int(11)")
        XCTAssertEqual(first_name["Type"], "text")
        XCTAssertEqual(last_name["Type"], "text")
        XCTAssertEqual(email["Type"], "text")
        XCTAssertEqual(phone["Type"], "text")
        
        XCTAssertEqual(contact_id["Key"], "PRI")
        XCTAssertEqual(first_name["Key"], nil)
        XCTAssertEqual(last_name["Key"], nil)
        XCTAssertEqual(email["Key"], "UNI")
        XCTAssertEqual(phone["Key"], "UNI")
        
        XCTAssertEqual(contact_id["Null"], false)
        XCTAssertEqual(first_name["Null"], false)
        XCTAssertEqual(last_name["Null"], true)
        XCTAssertEqual(email["Null"], false)
        XCTAssertEqual(phone["Null"], false)
    }
    
}
