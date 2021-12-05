//
//  MySQLDialect.swift
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

struct MySQLDialect: SQLDialect {
    
    static var rowId: String? {
        return "ROWID"
    }
    
    static func identifier(_ str: String) -> String {
        return "`\(str)`"
    }
    
    static var repeatablePlaceholder: Bool {
        return false
    }
    
    static func bindPlaceholder(at position: Int) -> String {
        return "?"
    }
    
    static func nullSafeEqual(_ lhs: DBPredicateValue, _ rhs: DBPredicateValue) throws -> SQLRaw {
        return try "\(lhs.serialize()) <=> \(rhs.serialize())"
    }
    
    static func nullSafeNotEqual(_ lhs: DBPredicateValue, _ rhs: DBPredicateValue) throws -> SQLRaw {
        return try "NOT \(lhs.serialize()) <=> \(rhs.serialize())"
    }
    
    public static func matching(_ column: String, _ pattern: SQLDialectPatternMatching) throws -> SQLRaw {
        throw Database.Error.unsupportedOperation
    }
    
    static func literalBoolean(_ value: Bool) -> String {
        return value ? "1" : "0"
    }
    
    static func updateLock() throws -> SQLRaw {
        return "FOR UPDATE"
    }
    
    static func updateOperation(_ column: String, _ columnType: String, _ operation: SQLDialectUpdateOperation) throws -> SQLRaw {
        
        switch operation {
        
        case let .increment(value): return "\(identifier: column) + \(value)"
        case let .decrement(value): return "\(identifier: column) - \(value)"
        case let .multiply(value): return "\(identifier: column) * \(value)"
        case let .divide(value): return "\(identifier: column) / \(value)"
        case let .min(value): return "LEAST(\(identifier: column),\(value))"
        case let .max(value): return "GREATEST(\(identifier: column),\(value))"
            
        default: throw Database.Error.unsupportedOperation
        }
    }
    
}
