//
//  DBPredicateExpression.swift
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

@frozen
public indirect enum DBPredicateExpression {
    
    case not(DBPredicateExpression)
    
    case equal(DBPredicateValue, DBPredicateValue)
    
    case notEqual(DBPredicateValue, DBPredicateValue)
    
    case lessThan(DBPredicateValue, DBPredicateValue)
    
    case greaterThan(DBPredicateValue, DBPredicateValue)
    
    case lessThanOrEqualTo(DBPredicateValue, DBPredicateValue)
    
    case greaterThanOrEqualTo(DBPredicateValue, DBPredicateValue)
    
    case containsIn(DBPredicateValue, DBPredicateValue)
    
    case notContainsIn(DBPredicateValue, DBPredicateValue)
    
    case between(DBPredicateValue, DBPredicateValue, DBPredicateValue)
    
    case notBetween(DBPredicateValue, DBPredicateValue, DBPredicateValue)
    
    case startsWith(DBPredicateKey, String)
    
    case endsWith(DBPredicateKey, String)
    
    case contains(DBPredicateKey, String)
    
    case and([DBPredicateExpression])
    
    case or([DBPredicateExpression])
}

@frozen
public enum DBPredicateValue {
    
    case objectId
    
    case key(String)
    
    case value(DBDataConvertible)
}

extension DBPredicateValue {
    
    @inlinable
    static func key(_ key: DBPredicateKey) -> DBPredicateValue {
        switch key {
        case .objectId: return .objectId
        case let .key(key): return .key(key)
        }
    }
}

extension DBPredicateValue {
    
    @inlinable
    var isObjectId: Bool {
        switch self {
        case .objectId: return true
        default: return false
        }
    }
    
    @inlinable
    public func serialize() throws -> SQLRaw {
        switch self {
        case let .key(key): return "\(identifier: key)"
        case let .value(value): return "\(value.toDBData())"
        default: throw Database.Error.invalidExpression
        }
    }
}

extension DBPredicateExpression {
    
    var _andList: [DBPredicateExpression]? {
        switch self {
        case let .and(list): return list.flatMap { $0._andList ?? [$0] }
        default: return nil
        }
    }
    
    var _orList: [DBPredicateExpression]? {
        switch self {
        case let .or(list): return list.flatMap { $0._orList ?? [$0] }
        default: return nil
        }
    }
    
    func serialize(_ dialect: SQLDialect.Type, _ columnInfos: [DBSQLColumnInfo], _ primaryKeys: [String]) throws -> SQLRaw {
        
        switch self {
        case let .not(x): return try "NOT (\(x.serialize(dialect, columnInfos, primaryKeys)))"
        case let .equal(.objectId, .value(value)),
             let .equal(.value(value), .objectId):
            
            let expression: DBPredicateExpression
            
            switch primaryKeys.count {
            case 0: throw Database.Error.invalidExpression
            case 1: expression = .equal(.key(primaryKeys[0]), .value(value))
            default:
                let value = value.toDBData()
                expression = .and(primaryKeys.map { .equal(.key($0), .value(value[$0])) })
            }
            
            return try expression.serialize(dialect, columnInfos, primaryKeys)
            
        case let .notEqual(.objectId, .value(value)),
             let .notEqual(.value(value), .objectId):
            
            let expression: DBPredicateExpression
            
            switch primaryKeys.count {
            case 0: throw Database.Error.invalidExpression
            case 1: expression = .notEqual(.key(primaryKeys[0]), .value(value))
            default:
                let value = value.toDBData()
                expression = .or(primaryKeys.map { .notEqual(.key($0), .value(value[$0])) })
            }
            
            return try expression.serialize(dialect, columnInfos, primaryKeys)
            
        case let .equal(lhs, rhs): return try dialect.nullSafeEqual(lhs, rhs)
        case let .notEqual(lhs, rhs): return try dialect.nullSafeNotEqual(lhs, rhs)
        case let .lessThan(lhs, rhs): return try "\(lhs.serialize()) < \(rhs.serialize())"
        case let .greaterThan(lhs, rhs): return try "\(lhs.serialize()) > \(rhs.serialize())"
        case let .lessThanOrEqualTo(lhs, rhs): return try "\(lhs.serialize()) <= \(rhs.serialize())"
        case let .greaterThanOrEqualTo(lhs, rhs): return try "\(lhs.serialize()) >= \(rhs.serialize())"
        case let .between(x, from, to): return try "\(x.serialize()) BETWEEN \(from.serialize()) AND \(to.serialize())"
        case let .notBetween(x, from, to): return try "\(x.serialize()) NOT BETWEEN \(from.serialize()) AND \(to.serialize())"
            
        case let .startsWith(.objectId, str):
            
            guard primaryKeys.count == 1 else { throw Database.Error.invalidExpression }
            return try dialect.matching(primaryKeys[0], .startsWith(str))
            
        case let .startsWith(.key(key), str):
            
            return try dialect.matching(key, .startsWith(str))
            
        case let .endsWith(.objectId, str):
            
            guard primaryKeys.count == 1 else { throw Database.Error.invalidExpression }
            return try dialect.matching(primaryKeys[0], .endsWith(str))
            
        case let .endsWith(.key(key), str):
            
            return try dialect.matching(key, .endsWith(str))
            
        case let .contains(.objectId, str):
            
            guard primaryKeys.count == 1 else { throw Database.Error.invalidExpression }
            return try dialect.matching(primaryKeys[0], .contains(str))
            
        case let .contains(.key(key), str):
            
            return try dialect.matching(key, .contains(str))
            
        case let .containsIn(.objectId, .value(list)):
            
            guard primaryKeys.count == 1 else { throw Database.Error.invalidExpression }
            
            guard let array = list.toDBData().array else { throw Database.Error.invalidExpression }
            return "\(identifier: primaryKeys[0]) IN (\(array.map { "\($0)" as SQLRaw }.joined(separator: ",")))"
            
        case let .containsIn(x, .value(list)):
            
            guard let array = list.toDBData().array else { throw Database.Error.invalidExpression }
            return try "\(x.serialize()) IN (\(array.map { "\($0)" as SQLRaw }.joined(separator: ",")))"
            
        case let .notContainsIn(.objectId, .value(list)):
            
            guard primaryKeys.count == 1 else { throw Database.Error.invalidExpression }
            
            guard let array = list.toDBData().array else { throw Database.Error.invalidExpression }
            return "\(identifier: primaryKeys[0]) NOT IN (\(array.map { "\($0)" as SQLRaw }.joined(separator: ",")))"
            
        case let .notContainsIn(x, .value(list)):
            
            guard let array = list.toDBData().array else { throw Database.Error.invalidExpression }
            return try "\(x.serialize()) NOT IN (\(array.map { "\($0)" as SQLRaw }.joined(separator: ",")))"
            
        case let .and(list):
            
            let list = list.flatMap { $0._andList ?? [$0] }
            
            switch list.count {
            case 0: throw Database.Error.invalidExpression
            case 1: return try list[0].serialize(dialect, columnInfos, primaryKeys)
            default: return try "\(list.map { try "(\($0.serialize(dialect, columnInfos, primaryKeys)))" as SQLRaw }.joined(separator: " AND "))"
            }
            
        case let .or(list):
            
            let list = list.flatMap { $0._orList ?? [$0] }
            
            switch list.count {
            case 0: throw Database.Error.invalidExpression
            case 1: return try list[0].serialize(dialect, columnInfos, primaryKeys)
            default: return try "\(list.map { try "(\($0.serialize(dialect, columnInfos, primaryKeys)))" as SQLRaw }.joined(separator: " OR "))"
            }
            
        default: throw Database.Error.invalidExpression
        }
    }
}

extension Collection where Element == DBPredicateExpression {
    
    func serialize(_ dialect: SQLDialect.Type, _ columnInfos: [DBSQLColumnInfo], _ primaryKeys: [String]) throws -> SQLRaw {
        return try DBPredicateExpression.and(Array(self)).serialize(dialect, columnInfos, primaryKeys)
    }
}

@inlinable
public func == (lhs: DBPredicateKey, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .equal(.key(lhs), .key(rhs))
}

@inlinable
public func != (lhs: DBPredicateKey, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .notEqual(.key(lhs), .key(rhs))
}

@inlinable
public func < (lhs: DBPredicateKey, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .lessThan(.key(lhs), .key(rhs))
}

@inlinable
public func > (lhs: DBPredicateKey, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .greaterThan(.key(lhs), .key(rhs))
}

@inlinable
public func <= (lhs: DBPredicateKey, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .lessThanOrEqualTo(.key(lhs), .key(rhs))
}

@inlinable
public func >= (lhs: DBPredicateKey, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .greaterThanOrEqualTo(.key(lhs), .key(rhs))
}

@inlinable
public func == (lhs: DBPredicateKey, rhs: _OptionalNilComparisonType) -> DBPredicateExpression {
    return .equal(.key(lhs), .value(nil as DBData))
}

@inlinable
public func != (lhs: DBPredicateKey, rhs: _OptionalNilComparisonType) -> DBPredicateExpression {
    return .notEqual(.key(lhs), .value(nil as DBData))
}

@inlinable
public func == <T: DBDataConvertible>(lhs: DBPredicateKey, rhs: T) -> DBPredicateExpression {
    return .equal(.key(lhs), .value(rhs))
}

@inlinable
public func != <T: DBDataConvertible>(lhs: DBPredicateKey, rhs: T) -> DBPredicateExpression {
    return .notEqual(.key(lhs), .value(rhs))
}

@inlinable
public func < <T: DBDataConvertible>(lhs: DBPredicateKey, rhs: T) -> DBPredicateExpression {
    return .lessThan(.key(lhs), .value(rhs))
}

@inlinable
public func > <T: DBDataConvertible>(lhs: DBPredicateKey, rhs: T) -> DBPredicateExpression {
    return .greaterThan(.key(lhs), .value(rhs))
}

@inlinable
public func <= <T: DBDataConvertible>(lhs: DBPredicateKey, rhs: T) -> DBPredicateExpression {
    return .lessThanOrEqualTo(.key(lhs), .value(rhs))
}

@inlinable
public func >= <T: DBDataConvertible>(lhs: DBPredicateKey, rhs: T) -> DBPredicateExpression {
    return .greaterThanOrEqualTo(.key(lhs), .value(rhs))
}

@inlinable
public func == (lhs: _OptionalNilComparisonType, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .equal(.value(nil as DBData), .key(rhs))
}

@inlinable
public func != (lhs: _OptionalNilComparisonType, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .notEqual(.value(nil as DBData), .key(rhs))
}

@inlinable
public func == <T: DBDataConvertible>(lhs: T, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .equal(.value(lhs), .key(rhs))
}

@inlinable
public func != <T: DBDataConvertible>(lhs: T, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .notEqual(.value(lhs), .key(rhs))
}

@inlinable
public func < <T: DBDataConvertible>(lhs: T, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .lessThan(.value(lhs), .key(rhs))
}

@inlinable
public func > <T: DBDataConvertible>(lhs: T, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .greaterThan(.value(lhs), .key(rhs))
}

@inlinable
public func <= <T: DBDataConvertible>(lhs: T, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .lessThanOrEqualTo(.value(lhs), .key(rhs))
}

@inlinable
public func >= <T: DBDataConvertible>(lhs: T, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .greaterThanOrEqualTo(.value(lhs), .key(rhs))
}

@inlinable
public func ~= (lhs: DBPredicateKey, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .containsIn(.key(rhs), .key(lhs))
}

@inlinable
public func ~= <T: DBDataConvertible>(lhs: DBPredicateKey, rhs: T) -> DBPredicateExpression {
    return .containsIn(.value(rhs), .key(lhs))
}

@inlinable
public func ~= <C: Collection>(lhs: C, rhs: DBPredicateKey) -> DBPredicateExpression where C.Element: DBDataConvertible {
    return .containsIn(.key(rhs), .value(Array(lhs)))
}

@inlinable
public func ~= <T: DBDataConvertible>(lhs: Range<T>, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .between(.key(rhs), .value(lhs.lowerBound), .value(lhs.upperBound))
}

@inlinable
public func ~= <T: DBDataConvertible>(lhs: ClosedRange<T>, rhs: DBPredicateKey) -> DBPredicateExpression {
    return lhs.lowerBound <= rhs && rhs <= lhs.upperBound
}

@inlinable
public func ~= <T: DBDataConvertible>(lhs: PartialRangeFrom<T>, rhs: DBPredicateKey) -> DBPredicateExpression {
    return lhs.lowerBound <= rhs
}

@inlinable
public func ~= <T: DBDataConvertible>(lhs: PartialRangeUpTo<T>, rhs: DBPredicateKey) -> DBPredicateExpression {
    return rhs < lhs.upperBound
}

@inlinable
public func ~= <T: DBDataConvertible>(lhs: PartialRangeThrough<T>, rhs: DBPredicateKey) -> DBPredicateExpression {
    return rhs <= lhs.upperBound
}

@inlinable
public func =~ (lhs: DBPredicateKey, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .containsIn(.key(lhs), .key(rhs))
}

@inlinable
public func =~ <T: DBDataConvertible>(lhs: T, rhs: DBPredicateKey) -> DBPredicateExpression {
    return .containsIn(.value(lhs), .key(rhs))
}

@inlinable
public func =~ <C: Collection>(lhs: DBPredicateKey, rhs: C) -> DBPredicateExpression where C.Element: DBDataConvertible {
    return .containsIn(.key(lhs), .value(Array(rhs)))
}

@inlinable
public func =~ <T: DBDataConvertible>(lhs: DBPredicateKey, rhs: Range<T>) -> DBPredicateExpression {
    return .between(.key(lhs), .value(rhs.lowerBound.toDBData()), .value(rhs.upperBound.toDBData()))
}

@inlinable
public func =~ <T: DBDataConvertible>(lhs: DBPredicateKey, rhs: ClosedRange<T>) -> DBPredicateExpression {
    return rhs.lowerBound <= lhs && lhs <= rhs.upperBound
}

@inlinable
public func =~ <T: DBDataConvertible>(lhs: DBPredicateKey, rhs: PartialRangeFrom<T>) -> DBPredicateExpression {
    return rhs.lowerBound <= lhs
}

@inlinable
public func =~ <T: DBDataConvertible>(lhs: DBPredicateKey, rhs: PartialRangeUpTo<T>) -> DBPredicateExpression {
    return lhs < rhs.upperBound
}

@inlinable
public func =~ <T: DBDataConvertible>(lhs: DBPredicateKey, rhs: PartialRangeThrough<T>) -> DBPredicateExpression {
    return lhs <= rhs.upperBound
}

@inlinable
public prefix func !(x: DBPredicateExpression) -> DBPredicateExpression {
    return .not(x)
}

@inlinable
public func && (lhs: DBPredicateExpression, rhs: DBPredicateExpression) -> DBPredicateExpression {
    return .and([lhs, rhs])
}

@inlinable
public func || (lhs: DBPredicateExpression, rhs: DBPredicateExpression) -> DBPredicateExpression {
    return .or([lhs, rhs])
}
