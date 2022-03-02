//
//  DBDataTest.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2022 Susan Cheng. All rights reserved.
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

extension DBData {
    
    var isDecimal: Bool {
        switch self {
        case .number(.decimal): return true
        default: return false
        }
    }
}

class DBDataTest: XCTestCase {
    
    func testDecimalCoding() throws {
        
        let decimal: DBData = .number(.decimal(1.5))
        
        let encoder = ExtendedJSONEncoder()
        let decoder = ExtendedJSONDecoder()
        
        let result = try decoder.decode(DBData.self, from: encoder.encode(decimal))
        
        XCTAssertTrue(result.isDecimal)
        XCTAssertEqual(result, decimal)
    }
    
    func testEncoder() throws {
        
        let array: DBData = [
            .number(.decimal(1.5))
        ]
        
        let result = try DBDataEncoder().encode(array)
        
        XCTAssertEqual(result, array)
    }
    
    func testEncoder2() throws {
        
        let array: DBData = [
            .number(.decimal(1.5))
        ]
        
        struct Test: Encodable {
            
            var value = [Decimal(1.5)]
        }
        
        let test = Test()
        
        let result = try DBDataEncoder().encode(test)
        
        XCTAssertEqual(result, ["value": array])
    }
    
    func testEncoder3() throws {
        
        let dict: DBData = [
            "hello": .number(.decimal(1.5))
        ]
        
        let result = try DBDataEncoder().encode(dict)
        
        XCTAssertEqual(result, dict)
    }
    
    func testEncoder4() throws {
        
        let dict: DBData = [
            "hello": .number(.decimal(1.5))
        ]
        
        struct Test: Encodable {
            
            var value = ["hello": Decimal(1.5)]
        }
        
        let test = Test()
        
        let result = try DBDataEncoder().encode(test)
        
        XCTAssertEqual(result, ["value": dict])
    }
    
    func testEncoder5() throws {
        
        let dict: DBData = [
            "hello": .number(.decimal(1.5))
        ]
        
        struct Test: Encodable {
            
            var value: OrderedDictionary = ["hello": Decimal(1.5)]
        }
        
        let test = Test()
        
        let result = try DBDataEncoder().encode(test)
        
        XCTAssertEqual(result, ["value": dict])
    }
}
