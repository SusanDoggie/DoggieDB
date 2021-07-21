//
//  DBQueryPredicateExpression.swift
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

public indirect enum DBQueryPredicateExpression {
    
    case not(DBQueryPredicateExpression)
    
    case equal(DBQueryPredicateValue, DBQueryPredicateValue)
    
    case notEqual(DBQueryPredicateValue, DBQueryPredicateValue)
    
    case lessThan(DBQueryPredicateValue, DBQueryPredicateValue)
    
    case greaterThan(DBQueryPredicateValue, DBQueryPredicateValue)
    
    case lessThanOrEqualTo(DBQueryPredicateValue, DBQueryPredicateValue)
    
    case greaterThanOrEqualTo(DBQueryPredicateValue, DBQueryPredicateValue)
    
    case containsIn(DBQueryPredicateValue, DBQueryPredicateValue)
    
    case notContainsIn(DBQueryPredicateValue, DBQueryPredicateValue)
    
    case between(DBQueryPredicateValue, DBQueryPredicateValue, DBQueryPredicateValue)
    
    case notBetween(DBQueryPredicateValue, DBQueryPredicateValue, DBQueryPredicateValue)
    
    case like(DBQueryPredicateValue, String)
    
    case notLike(DBQueryPredicateValue, String)
    
    case matching(DBQueryPredicateValue, DBQueryPredicateValue)
    
    case startsWith(DBQueryPredicateValue, String, options: NSRegularExpression.Options = [])
    
    case endsWith(DBQueryPredicateValue, String, options: NSRegularExpression.Options = [])
    
    case contains(DBQueryPredicateValue, String, options: NSRegularExpression.Options = [])
    
    case and([DBQueryPredicateExpression])
    
    case or([DBQueryPredicateExpression])
}

public enum DBQueryPredicateValue {
    
    case objectId
    
    case key(String)
    
    case value(DBDataConvertible)
}

extension DBQueryPredicateValue {
    
    var isObjectId: Bool {
        switch self {
        case .objectId: return true
        default: return false
        }
    }
    
    public func serialize() throws -> SQLRaw {
        switch self {
        case let .key(key): return "\(identifier: key)"
        case let .value(value): return "\(value.toDBData())"
        default: throw Database.Error.invalidExpression
        }
    }
}

extension DBQueryPredicateExpression {
    
    var _andList: [DBQueryPredicateExpression]? {
        switch self {
        case let .and(list): return list.flatMap { $0._andList ?? [$0] }
        default: return nil
        }
    }
    
    var _orList: [DBQueryPredicateExpression]? {
        switch self {
        case let .or(list): return list.flatMap { $0._orList ?? [$0] }
        default: return nil
        }
    }
    
    var requiredPrimaryKeys: Bool {
        switch self {
        case let .not(x): return x.requiredPrimaryKeys
        case let .equal(lhs, rhs): return lhs.isObjectId || rhs.isObjectId
        case let .notEqual(lhs, rhs): return lhs.isObjectId || rhs.isObjectId
        case let .lessThan(lhs, rhs): return lhs.isObjectId || rhs.isObjectId
        case let .greaterThan(lhs, rhs): return lhs.isObjectId || rhs.isObjectId
        case let .lessThanOrEqualTo(lhs, rhs): return lhs.isObjectId || rhs.isObjectId
        case let .greaterThanOrEqualTo(lhs, rhs): return lhs.isObjectId || rhs.isObjectId
        case let .containsIn(lhs, rhs): return lhs.isObjectId || rhs.isObjectId
        case let .notContainsIn(lhs, rhs): return lhs.isObjectId || rhs.isObjectId
        case let .between(x, from, to): return x.isObjectId || from.isObjectId || to.isObjectId
        case let .notBetween(x, from, to): return x.isObjectId || from.isObjectId || to.isObjectId
        case let .like(x, _): return x.isObjectId
        case let .notLike(x, _): return x.isObjectId
        case let .matching(lhs, rhs): return lhs.isObjectId || rhs.isObjectId
        case let .startsWith(x, _, _): return x.isObjectId
        case let .endsWith(x, _, _): return x.isObjectId
        case let .contains(x, _, _): return x.isObjectId
        case let .and(list): return list.contains { $0.requiredPrimaryKeys }
        case let .or(list): return list.contains { $0.requiredPrimaryKeys }
        }
    }
    
    func serialize(_ dialect: SQLDialect.Type, _ primaryKeys: [String]) throws -> SQLRaw {
        
        switch self {
        case let .not(x): return try "NOT (\(x.serialize(dialect, primaryKeys)))"
        case let .equal(.objectId, .value(value)),
             let .equal(.value(value), .objectId):
            
            let expression: DBQueryPredicateExpression
            
            switch primaryKeys.count {
            case 0: fatalError("invalid expression")
            case 1: expression = .equal(.key(primaryKeys[0]), .value(value))
            default:
                let value = value.toDBData()
                expression = .and(primaryKeys.map { .equal(.key($0), .value(value[$0])) })
            }
            
            return try expression.serialize(dialect, primaryKeys)
            
        case let .notEqual(.objectId, .value(value)),
             let .notEqual(.value(value), .objectId):
            
            let expression: DBQueryPredicateExpression
            
            switch primaryKeys.count {
            case 0: fatalError("invalid expression")
            case 1: expression = .notEqual(.key(primaryKeys[0]), .value(value))
            default:
                let value = value.toDBData()
                expression = .or(primaryKeys.map { .notEqual(.key($0), .value(value[$0])) })
            }
            
            return try expression.serialize(dialect, primaryKeys)
            
        case let .equal(lhs, rhs): return try dialect.nullSafeEqual(lhs, rhs)
        case let .notEqual(lhs, rhs): return try dialect.nullSafeNotEqual(lhs, rhs)
        case let .lessThan(lhs, rhs): return try "\(lhs.serialize()) < \(rhs.serialize())"
        case let .greaterThan(lhs, rhs): return try "\(lhs.serialize()) > \(rhs.serialize())"
        case let .lessThanOrEqualTo(lhs, rhs): return try "\(lhs.serialize()) <= \(rhs.serialize())"
        case let .greaterThanOrEqualTo(lhs, rhs): return try "\(lhs.serialize()) >= \(rhs.serialize())"
        case let .between(x, from, to): return try "\(x.serialize()) BETWEEN \(from.serialize()) AND \(to.serialize())"
        case let .notBetween(x, from, to): return try "\(x.serialize()) NOT BETWEEN \(from.serialize()) AND \(to.serialize())"
        case let .containsIn(x, .value(list)):
            
            guard let array = list.toDBData().array else { throw Database.Error.invalidExpression }
            return try "\(x.serialize()) IN (\(array.map { "\($0)" as SQLRaw }.joined(separator: ",")))"
            
        case let .notContainsIn(x, .value(list)):
            
            guard let array = list.toDBData().array else { throw Database.Error.invalidExpression }
            return try "\(x.serialize()) NOT IN (\(array.map { "\($0)" as SQLRaw }.joined(separator: ",")))"
            
        case let .like(x, pattern): return try "\(x.serialize()) LIKE \(pattern)"
        case let .notLike(x, pattern): return try "\(x.serialize()) NOT LIKE \(pattern)"
        case let .and(list):
            
            let list = list.flatMap { $0._andList ?? [$0] }
            
            switch list.count {
            case 0: fatalError("invalid expression")
            case 1: return try list[0].serialize(dialect, primaryKeys)
            default: return try "\(list.map { try "(\($0.serialize(dialect, primaryKeys)))" as SQLRaw }.joined(separator: " AND "))"
            }
            
        case let .or(list):
            
            let list = list.flatMap { $0._orList ?? [$0] }
            
            switch list.count {
            case 0: fatalError("invalid expression")
            case 1: return try list[0].serialize(dialect, primaryKeys)
            default: return try "\(list.map { try "(\($0.serialize(dialect, primaryKeys)))" as SQLRaw }.joined(separator: " OR "))"
            }
            
        default: throw Database.Error.invalidExpression
        }
    }
}

extension Collection where Element == DBQueryPredicateExpression {
    
    var requiredPrimaryKeys: Bool {
        return self.contains { $0.requiredPrimaryKeys }
    }
    
    func serialize(_ dialect: SQLDialect.Type, _ primaryKeys: [String]) throws -> SQLRaw {
        return try DBQueryPredicateExpression.and(Array(self)).serialize(dialect, primaryKeys)
    }
}

public func == (lhs: DBQueryPredicateValue, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .equal(lhs, rhs)
}

public func != (lhs: DBQueryPredicateValue, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .notEqual(lhs, rhs)
}

public func < (lhs: DBQueryPredicateValue, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .lessThan(lhs, rhs)
}

public func > (lhs: DBQueryPredicateValue, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .greaterThan(lhs, rhs)
}

public func <= (lhs: DBQueryPredicateValue, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .lessThanOrEqualTo(lhs, rhs)
}

public func >= (lhs: DBQueryPredicateValue, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .greaterThanOrEqualTo(lhs, rhs)
}

public func == (lhs: DBQueryPredicateValue, rhs: _OptionalNilComparisonType) -> DBQueryPredicateExpression {
    return .equal(lhs, .value(nil as DBData))
}

public func != (lhs: DBQueryPredicateValue, rhs: _OptionalNilComparisonType) -> DBQueryPredicateExpression {
    return .notEqual(lhs, .value(nil as DBData))
}

public func == <T: DBDataConvertible>(lhs: DBQueryPredicateValue, rhs: T) -> DBQueryPredicateExpression {
    return .equal(lhs, .value(rhs))
}

public func != <T: DBDataConvertible>(lhs: DBQueryPredicateValue, rhs: T) -> DBQueryPredicateExpression {
    return .notEqual(lhs, .value(rhs))
}

public func < <T: DBDataConvertible>(lhs: DBQueryPredicateValue, rhs: T) -> DBQueryPredicateExpression {
    return .lessThan(lhs, .value(rhs))
}

public func > <T: DBDataConvertible>(lhs: DBQueryPredicateValue, rhs: T) -> DBQueryPredicateExpression {
    return .greaterThan(lhs, .value(rhs))
}

public func <= <T: DBDataConvertible>(lhs: DBQueryPredicateValue, rhs: T) -> DBQueryPredicateExpression {
    return .lessThanOrEqualTo(lhs, .value(rhs))
}

public func >= <T: DBDataConvertible>(lhs: DBQueryPredicateValue, rhs: T) -> DBQueryPredicateExpression {
    return .greaterThanOrEqualTo(lhs, .value(rhs))
}

public func == (lhs: _OptionalNilComparisonType, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .equal(.value(nil as DBData), rhs)
}

public func != (lhs: _OptionalNilComparisonType, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .notEqual(.value(nil as DBData), rhs)
}

public func == <T: DBDataConvertible>(lhs: T, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .equal(.value(lhs), rhs)
}

public func != <T: DBDataConvertible>(lhs: T, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .notEqual(.value(lhs), rhs)
}

public func < <T: DBDataConvertible>(lhs: T, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .lessThan(.value(lhs), rhs)
}

public func > <T: DBDataConvertible>(lhs: T, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .greaterThan(.value(lhs), rhs)
}

public func <= <T: DBDataConvertible>(lhs: T, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .lessThanOrEqualTo(.value(lhs), rhs)
}

public func >= <T: DBDataConvertible>(lhs: T, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .greaterThanOrEqualTo(.value(lhs), rhs)
}

public func ~= (lhs: String, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .like(rhs, lhs)
}

public func ~= (lhs: NSRegularExpression, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .matching(rhs, .value(lhs))
}

public func ~= (lhs: Regex, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .matching(rhs, .value(lhs))
}

public func ~= (lhs: DBQueryPredicateValue, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .containsIn(rhs, lhs)
}

public func ~= <T: DBDataConvertible>(lhs: DBQueryPredicateValue, rhs: T) -> DBQueryPredicateExpression {
    return .containsIn(.value(rhs), lhs)
}

public func ~= <C: Collection>(lhs: C, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression where C.Element: DBDataConvertible {
    return .containsIn(rhs, .value(Array(lhs)))
}

public func ~= <T: DBDataConvertible>(lhs: Range<T>, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .between(rhs, .value(lhs.lowerBound.toDBData()), .value(lhs.upperBound.toDBData()))
}

public func ~= <T: DBDataConvertible>(lhs: ClosedRange<T>, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return lhs.lowerBound <= rhs && rhs <= lhs.upperBound
}

public func ~= <T: DBDataConvertible>(lhs: PartialRangeFrom<T>, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return lhs.lowerBound <= rhs
}

public func ~= <T: DBDataConvertible>(lhs: PartialRangeUpTo<T>, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return rhs < lhs.upperBound
}

public func ~= <T: DBDataConvertible>(lhs: PartialRangeThrough<T>, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return rhs <= lhs.upperBound
}

public func =~ (lhs: DBQueryPredicateValue, rhs: String) -> DBQueryPredicateExpression {
    return .like(lhs, rhs)
}

public func =~ (lhs: DBQueryPredicateValue, rhs: NSRegularExpression) -> DBQueryPredicateExpression {
    return .matching(lhs, .value(rhs))
}

public func =~ (lhs: DBQueryPredicateValue, rhs: Regex) -> DBQueryPredicateExpression {
    return .matching(lhs, .value(rhs))
}

public func =~ (lhs: DBQueryPredicateValue, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .containsIn(lhs, rhs)
}

public func =~ <T: DBDataConvertible>(lhs: T, rhs: DBQueryPredicateValue) -> DBQueryPredicateExpression {
    return .containsIn(.value(lhs), rhs)
}

public func =~ <C: Collection>(lhs: DBQueryPredicateValue, rhs: C) -> DBQueryPredicateExpression where C.Element: DBDataConvertible {
    return .containsIn(lhs, .value(Array(rhs)))
}

public func =~ <T: DBDataConvertible>(lhs: DBQueryPredicateValue, rhs: Range<T>) -> DBQueryPredicateExpression {
    return .between(lhs, .value(rhs.lowerBound.toDBData()), .value(rhs.upperBound.toDBData()))
}

public func =~ <T: DBDataConvertible>(lhs: DBQueryPredicateValue, rhs: ClosedRange<T>) -> DBQueryPredicateExpression {
    return rhs.lowerBound <= lhs && lhs <= rhs.upperBound
}

public func =~ <T: DBDataConvertible>(lhs: DBQueryPredicateValue, rhs: PartialRangeFrom<T>) -> DBQueryPredicateExpression {
    return rhs.lowerBound <= lhs
}

public func =~ <T: DBDataConvertible>(lhs: DBQueryPredicateValue, rhs: PartialRangeUpTo<T>) -> DBQueryPredicateExpression {
    return lhs < rhs.upperBound
}

public func =~ <T: DBDataConvertible>(lhs: DBQueryPredicateValue, rhs: PartialRangeThrough<T>) -> DBQueryPredicateExpression {
    return lhs <= rhs.upperBound
}

public prefix func !(x: DBQueryPredicateExpression) -> DBQueryPredicateExpression {
    return .not(x)
}

public func && (lhs: DBQueryPredicateExpression, rhs: DBQueryPredicateExpression) -> DBQueryPredicateExpression {
    return .and([lhs, rhs])
}

public func || (lhs: DBQueryPredicateExpression, rhs: DBQueryPredicateExpression) -> DBQueryPredicateExpression {
    return .or([lhs, rhs])
}
