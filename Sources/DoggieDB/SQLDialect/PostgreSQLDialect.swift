//
//  PostgreSQLDialect.swift
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

struct PostgreSQLDialect: SQLDialect {
    
    static var rowId: String? {
        return "CTID"
    }
    
    static func identifier(_ str: String) -> String {
        return "\"\(str.lowercased())\""
    }
    
    static var repeatablePlaceholder: Bool {
        return true
    }
    
    static func bindPlaceholder(at position: Int) -> String {
        return "$\(position)"
    }
    
    static func nullSafeEqual(_ lhs: DBQueryPredicateValue, _ rhs: DBQueryPredicateValue) -> SQLRaw {
        return "\(lhs) IS NOT DISTINCT FROM \(rhs)"
    }
    
    static func nullSafeNotEqual(_ lhs: DBQueryPredicateValue, _ rhs: DBQueryPredicateValue) -> SQLRaw {
        return "\(lhs) IS DISTINCT FROM \(rhs)"
    }
    
    static func literalBoolean(_ value: Bool) -> String {
        return value ? "true" : "false"
    }
    
    static func typeCast(_ value: DBData, _ columnType: String) throws -> SQLRaw {
        
        if columnType.hasSuffix("[]") && value.array?._postgresArray == nil {
            return "CAST(ARRAY(SELECT jsonb_array_elements(\(value))) AS \(literal: columnType))"
        }
        
        return "CAST(\(value) AS \(literal: columnType))"
    }
    
    static func updateOperation(_ column: String, _ columnType: String, _ operation: SQLDialectUpdateOperation) throws -> SQLRaw {
        
        switch operation {
        
        case let .inc(value): return "\(identifier: column) + \(value)"
        case let .mul(value): return "\(identifier: column) * \(value)"
        case let .min(value): return "LEAST(\(identifier: column),\(value))"
        case let .max(value): return "GREATEST(\(identifier: column),\(value))"
            
        case let .push(list):
            
            if columnType.hasSuffix("[]") {
                
                return try "\(identifier: column) || \(typeCast(DBData(list), columnType))"
                
            } else if columnType == "json" {
                
                return "(\(identifier: column)::jsonb || array_to_json(\(list))::jsonb)::json"
                
            } else if columnType == "jsonb" {
                
                return "\(identifier: column) || array_to_json(\(list))::jsonb"
                
            } else {
                throw Database.Error.unsupportedOperation
            }
            
        default: throw Database.Error.unsupportedOperation
        }
    }
    
}
