//
//  SQLDialect.swift
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

public enum SQLDialectUpdateOperation {
    
    case increment(DBData)
    
    case decrement(DBData)
    
    case multiply(DBData)
    
    case divide(DBData)
    
    case min(DBData)
    
    case max(DBData)
    
    case addToSet([DBData])
    
    case push([DBData])
    
    case removeAll([DBData])
    
    case popFirst
    
    case popLast
    
}

public enum SQLDialectPatternMatching {
    
    case startsWith(String)
    
    case endsWith(String)
    
    case contains(String)
    
}

public protocol SQLDialect {
    
    static var rowId: String? { get }
    
    static func identifier(_ str: String) -> String
    
    static var repeatablePlaceholder: Bool { get }
    
    static func bindPlaceholder(at position: Int) -> String
    
    static func nullSafeEqual(_ lhs: DBPredicateValue, _ rhs: DBPredicateValue) throws -> SQLRaw
    
    static func nullSafeNotEqual(_ lhs: DBPredicateValue, _ rhs: DBPredicateValue) throws -> SQLRaw
    
    static func matching(_ column: String, _ pattern: SQLDialectPatternMatching) throws -> SQLRaw
    
    static var literalNull: String { get }
    
    static func literalBoolean(_ value: Bool) -> String
    
    static func typeCast(_ value: DBData, _ columnType: String) throws -> SQLRaw
    
    static func updateLock() throws -> SQLRaw
    
    static func updateOperation(_ column: String, _ columnType: String, _ operation: SQLDialectUpdateOperation) throws -> SQLRaw
    
}

extension SQLDialect {
    
    static var rowId: String? {
        return nil
    }
    
    static var literalNull: String {
        return "NULL"
    }
    
    static func typeCast(_ value: DBData, _ columnType: String) throws -> SQLRaw {
        throw Database.Error.unsupportedOperation
    }
    
    static func updateLock() throws -> SQLRaw {
        throw Database.Error.unsupportedOperation
    }
    
    static func updateOperation(_ column: String, _ columnType: String, _ operation: SQLDialectUpdateOperation) throws -> SQLRaw {
        throw Database.Error.unsupportedOperation
    }
}

extension DBConnection {
    
    func serialize(_ sql: SQLRaw) -> (String, [DBData])? {
        
        guard let dialect = self.driver.sqlDialect else { return nil }
        
        var raw = ""
        var binds: [DBData] = []
        
        if dialect.repeatablePlaceholder {
            
            var mapping: [DBData: String] = [:]
            
            for component in sql.components {
                switch component {
                case .null: raw.append(dialect.literalNull)
                case let .identifier(string): raw.append(dialect.identifier(string))
                case let .string(string): raw.append(string)
                case let .boolean(bool): raw.append(dialect.literalBoolean(bool))
                case let .signed(value): raw.append("\(value)")
                case let .unsigned(value): raw.append("\(value)")
                case let .number(value): raw.append("\(Decimal(value))")
                case let .decimal(value): raw.append("\(value)")
                case let .bind(value):
                    
                    var placeholder = mapping[value]
                    
                    if placeholder == nil {
                        binds.append(value)
                        placeholder = dialect.bindPlaceholder(at: binds.count)
                        mapping[value] = placeholder
                    }
                    
                    raw.append(placeholder!)
                }
            }
            
        } else {
            
            for component in sql.components {
                switch component {
                case .null: raw.append(dialect.literalNull)
                case let .identifier(string): raw.append(dialect.identifier(string))
                case let .string(string): raw.append(string)
                case let .boolean(bool): raw.append(dialect.literalBoolean(bool))
                case let .signed(value): raw.append("\(value)")
                case let .unsigned(value): raw.append("\(value)")
                case let .number(value): raw.append("\(Decimal(value))")
                case let .decimal(value): raw.append("\(value)")
                case let .bind(value):
                    binds.append(value)
                    raw.append(dialect.bindPlaceholder(at: binds.count))
                }
            }
        }
        
        return (raw, binds)
    }
}
