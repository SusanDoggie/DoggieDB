//
//  ModelTest.swift
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

class ModelTest: XCTestCase {
    
    func testModel() {
        
        struct TestModel: DBModel {
            
            static let schema: String = "test_model"
            
            @DBField(default: .random)
            var id: UUID
            
            @DBField(name: "nick_name")
            var name: String
            
            @DBField(default: .now)
            var createdAt: Date
            
            @DBField(default: .now)
            var updatedAt: Date
            
            @DBField()
            var deletedAt: Date?
            
            init(id: UUID, name: String) {
                self.id = id
                self.name = name
            }
        }

        let object = TestModel(id: UUID(), name: "John")
        
        let fields = object._$fields
        
        XCTAssertEqual(fields.count, 5)
        
        XCTAssertEqual(fields.first { $0.name == "id" }?.value, DBData(object.id))
        XCTAssertEqual(fields.first { $0.name == "nick_name" }?.value, DBData(object.name))
        
        XCTAssertEqual(fields.first { $0.name == "id" }?.isOptional, false)
        XCTAssertEqual(fields.first { $0.name == "nick_name" }?.isOptional, false)
        XCTAssertEqual(fields.first { $0.name == "createdAt" }?.isOptional, false)
        XCTAssertEqual(fields.first { $0.name == "updatedAt" }?.isOptional, false)
        XCTAssertEqual(fields.first { $0.name == "deletedAt" }?.isOptional, true)
        
    }
}
