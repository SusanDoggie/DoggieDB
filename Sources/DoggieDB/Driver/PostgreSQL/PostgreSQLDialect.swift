//
//  PostgreSQLDialect.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2024 Susan Cheng. All rights reserved.
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
    
    static func nullSafeEqual(_ lhs: DBPredicateValue, _ rhs: DBPredicateValue) throws -> SQLRaw {
        return try "\(lhs.serialize()) IS NOT DISTINCT FROM \(rhs.serialize())"
    }
    
    static func nullSafeNotEqual(_ lhs: DBPredicateValue, _ rhs: DBPredicateValue) throws -> SQLRaw {
        return try "\(lhs.serialize()) IS DISTINCT FROM \(rhs.serialize())"
    }
    
    public static func matching(_ column: String, _ pattern: SQLDialectPatternMatching) throws -> SQLRaw {
        
        func escape(_ pattern: String) -> String {
            var _pattern = ""
            for char in pattern {
                switch char {
                case "\\", "%", "_": _pattern.append("\\")
                default: break
                }
                _pattern.append(char)
            }
            return _pattern
        }
        
        switch pattern {
            
        case let .startsWith(pattern):
            
            let _pattern = "\(escape(pattern))%"
            
            return "\(identifier: column) LIKE \(_pattern)"
            
        case let .endsWith(pattern):
            
            let _pattern = "%\(escape(pattern))"
            
            return "\(identifier: column) LIKE \(_pattern)"
            
        case let .contains(pattern):
            
            let _pattern = "%\(escape(pattern))%"
            
            return "\(identifier: column) LIKE \(_pattern)"
        }
    }
    
    static func literalBoolean(_ value: Bool) -> String {
        return value ? "true" : "false"
    }
    
    static func typeCast(_ value: DBData, _ columnType: String) throws -> SQLRaw {
        
        guard value != nil else { return "\(value)" }
        
        switch columnType {
        case "json": return "to_json(\(value))"
        case "jsonb": return "to_jsonb(\(value))"
        default:
            
            if columnType.hasSuffix("[]") && value.array?._postgresArray == nil {
                return "CAST(ARRAY(SELECT jsonb_array_elements(\(value))) AS \(literal: columnType))"
            }
            
            return "CAST(\(value) AS \(literal: columnType))"
        }
    }
    
    static func updateLock() throws -> SQLRaw {
        return "FOR UPDATE"
    }
    
    static func updateOperation(_ column: String, _ columnType: String, _ operation: SQLDialectUpdateOperation) throws -> SQLRaw {
        
        switch operation {
        
        case let .increment(value): return try "\(identifier: column) + \(typeCast(value, columnType))"
        case let .decrement(value): return try "\(identifier: column) - \(typeCast(value, columnType))"
        case let .multiply(value): return try "\(identifier: column) * \(typeCast(value, columnType))"
        case let .divide(value): return try "\(identifier: column) / \(typeCast(value, columnType))"
        case let .min(value): return try "LEAST(\(identifier: column),\(typeCast(value, columnType)))"
        case let .max(value): return try "GREATEST(\(identifier: column),\(typeCast(value, columnType)))"
            
        case let .addToSet(list):
            
            if columnType.hasSuffix("[]") {
                
                return try """
                    ARRAY(
                        SELECT unnest(\(identifier: column))
                        UNION ALL
                        (
                            SELECT unnest(\(typeCast(DBData(list), columnType)))
                            EXCEPT
                            SELECT unnest(\(identifier: column))
                        )
                    )
                    """
                
            } else {
                throw Database.Error.unsupportedOperation
            }
            
        case let .push(list):
            
            if columnType.hasSuffix("[]") {
                
                return try "\(identifier: column) || \(typeCast(DBData(list), columnType))"
                
            } else if columnType == "json" {
                
                return "(\(identifier: column)::jsonb || to_jsonb(\(list)))::json"
                
            } else if columnType == "jsonb" {
                
                return "\(identifier: column) || to_jsonb(\(list))"
                
            } else {
                throw Database.Error.unsupportedOperation
            }
            
        case let .removeAll(list):
            
            if columnType.hasSuffix("[]") {
                
                return try """
                    ARRAY(
                        SELECT unnest(\(identifier: column))
                        EXCEPT
                        SELECT unnest(\(typeCast(DBData(list), columnType)))
                    )
                    """
                
            } else {
                throw Database.Error.unsupportedOperation
            }
            
        case .popFirst:
            
            if columnType.hasSuffix("[]") {
                
                return "\(identifier: column)[2:]"
                
            } else if columnType == "json" {
                
                return "(\(identifier: column)::jsonb - 0)::json"
                
            } else if columnType == "jsonb" {
                
                return "(\(identifier: column) - 0)"
                
            } else {
                throw Database.Error.unsupportedOperation
            }
            
        case .popLast:
            
            if columnType.hasSuffix("[]") {
                
                return "\(identifier: column)[:array_upper(\(identifier: column), 1) - 1]"
                
            } else if columnType == "json" {
                
                return "(\(identifier: column)::jsonb - -1)::json"
                
            } else if columnType == "jsonb" {
                
                return "(\(identifier: column) - -1)"
                
            } else {
                throw Database.Error.unsupportedOperation
            }
            
        }
    }
    
}
