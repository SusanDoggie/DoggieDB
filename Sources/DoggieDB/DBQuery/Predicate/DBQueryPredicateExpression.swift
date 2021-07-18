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
    
    case key(String)
    
    case value(DBDataConvertible)
}

extension DBQueryPredicateValue {
    
    static func key(_ key: DBQueryPredicateKey) -> DBQueryPredicateValue {
        return .key(key.key)
    }
}

extension SQLRaw.StringInterpolation {
    
    public mutating func appendInterpolation(_ value: DBQueryPredicateValue) {
        switch value {
        case let .key(key): self.appendInterpolation(identifier: key)
        case let .value(value): self.appendInterpolation(value.toDBData())
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
    
    func serialize(_ dialect: SQLDialect.Type) throws -> SQLRaw {
        
        switch self {
        case let .not(x): return try "NOT (\(x.serialize(dialect)))"
        case let .equal(lhs, rhs): return dialect.nullSafeEqual(lhs, rhs)
        case let .notEqual(lhs, rhs): return dialect.nullSafeNotEqual(lhs, rhs)
        case let .lessThan(lhs, rhs): return "\(lhs) < \(rhs)"
        case let .greaterThan(lhs, rhs): return "\(lhs) > \(rhs)"
        case let .lessThanOrEqualTo(lhs, rhs): return "\(lhs) <= \(rhs)"
        case let .greaterThanOrEqualTo(lhs, rhs): return "\(lhs) >= \(rhs)"
        case let .between(x, from, to): return "\(x) BETWEEN \(from) AND \(to)"
        case let .notBetween(x, from, to): return "\(x) NOT BETWEEN \(from) AND \(to)"
        case let .containsIn(x, .value(list)):
            
            guard let array = list.toDBData().array else { throw Database.Error.invalidExpression }
            return "\(x) IN (\(array.map { "\($0)" as SQLRaw }.joined(separator: ",")))"
            
        case let .notContainsIn(x, .value(list)):
            
            guard let array = list.toDBData().array else { throw Database.Error.invalidExpression }
            return "\(x) NOT IN (\(array.map { "\($0)" as SQLRaw }.joined(separator: ",")))"
            
        case let .like(x, pattern): return "\(x) LIKE \(pattern)"
        case let .notLike(x, pattern): return "\(x) NOT LIKE \(pattern)"
        case let .and(list):
            
            let list = list.flatMap { $0._andList ?? [$0] }
            
            switch list.count {
            case 0: fatalError("invalid expression")
            case 1: return try list[0].serialize(dialect)
            default: return try "\(list.map { try "(\($0.serialize(dialect)))" as SQLRaw }.joined(separator: " AND "))"
            }
            
        case let .or(list):
            
            let list = list.flatMap { $0._orList ?? [$0] }
            
            switch list.count {
            case 0: fatalError("invalid expression")
            case 1: return try list[0].serialize(dialect)
            default: return try "\(list.map { try "(\($0.serialize(dialect)))" as SQLRaw }.joined(separator: " OR "))"
            }
            
        default: throw Database.Error.invalidExpression
        }
    }
}

extension Collection where Element == DBQueryPredicateExpression {
    
    func serialize(_ dialect: SQLDialect.Type) throws -> SQLRaw {
        return try DBQueryPredicateExpression.and(Array(self)).serialize(dialect)
    }
}

public func == (lhs: DBQueryPredicateKey, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .equal(.key(lhs), .key(rhs))
}

public func != (lhs: DBQueryPredicateKey, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .notEqual(.key(lhs), .key(rhs))
}

public func < (lhs: DBQueryPredicateKey, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .lessThan(.key(lhs), .key(rhs))
}

public func > (lhs: DBQueryPredicateKey, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .greaterThan(.key(lhs), .key(rhs))
}

public func <= (lhs: DBQueryPredicateKey, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .lessThanOrEqualTo(.key(lhs), .key(rhs))
}

public func >= (lhs: DBQueryPredicateKey, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .greaterThanOrEqualTo(.key(lhs), .key(rhs))
}

public func == (lhs: DBQueryPredicateKey, rhs: _OptionalNilComparisonType) -> DBQueryPredicateExpression {
    return .equal(.key(lhs), .value(nil as DBData))
}

public func != (lhs: DBQueryPredicateKey, rhs: _OptionalNilComparisonType) -> DBQueryPredicateExpression {
    return .notEqual(.key(lhs), .value(nil as DBData))
}

public func == <T: DBDataConvertible>(lhs: DBQueryPredicateKey, rhs: T) -> DBQueryPredicateExpression {
    return .equal(.key(lhs), .value(rhs))
}

public func != <T: DBDataConvertible>(lhs: DBQueryPredicateKey, rhs: T) -> DBQueryPredicateExpression {
    return .notEqual(.key(lhs), .value(rhs))
}

public func < <T: DBDataConvertible>(lhs: DBQueryPredicateKey, rhs: T) -> DBQueryPredicateExpression {
    return .lessThan(.key(lhs), .value(rhs))
}

public func > <T: DBDataConvertible>(lhs: DBQueryPredicateKey, rhs: T) -> DBQueryPredicateExpression {
    return .greaterThan(.key(lhs), .value(rhs))
}

public func <= <T: DBDataConvertible>(lhs: DBQueryPredicateKey, rhs: T) -> DBQueryPredicateExpression {
    return .lessThanOrEqualTo(.key(lhs), .value(rhs))
}

public func >= <T: DBDataConvertible>(lhs: DBQueryPredicateKey, rhs: T) -> DBQueryPredicateExpression {
    return .greaterThanOrEqualTo(.key(lhs), .value(rhs))
}

public func == (lhs: _OptionalNilComparisonType, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .equal(.value(nil as DBData), .key(rhs))
}

public func != (lhs: _OptionalNilComparisonType, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .notEqual(.value(nil as DBData), .key(rhs))
}

public func == <T: DBDataConvertible>(lhs: T, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .equal(.value(lhs), .key(rhs))
}

public func != <T: DBDataConvertible>(lhs: T, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .notEqual(.value(lhs), .key(rhs))
}

public func < <T: DBDataConvertible>(lhs: T, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .lessThan(.value(lhs), .key(rhs))
}

public func > <T: DBDataConvertible>(lhs: T, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .greaterThan(.value(lhs), .key(rhs))
}

public func <= <T: DBDataConvertible>(lhs: T, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .lessThanOrEqualTo(.value(lhs), .key(rhs))
}

public func >= <T: DBDataConvertible>(lhs: T, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .greaterThanOrEqualTo(.value(lhs), .key(rhs))
}

public func ~= (lhs: String, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .like(.key(rhs), lhs)
}

public func ~= (lhs: NSRegularExpression, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .matching(.key(rhs), .value(lhs))
}

public func ~= (lhs: Regex, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .matching(.key(rhs), .value(lhs))
}

public func ~= (lhs: DBQueryPredicateKey, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .containsIn(.key(rhs), .key(lhs))
}

public func ~= <T: DBDataConvertible>(lhs: DBQueryPredicateKey, rhs: T) -> DBQueryPredicateExpression {
    return .containsIn(.value(rhs), .key(lhs))
}

public func ~= <C: Collection>(lhs: C, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression where C.Element: DBDataConvertible {
    return .containsIn(.key(rhs), .value(Array(lhs)))
}

public func ~= <T: DBDataConvertible>(lhs: Range<T>, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .between(.key(rhs), .value(lhs.lowerBound.toDBData()), .value(lhs.upperBound.toDBData()))
}

public func ~= <T: DBDataConvertible>(lhs: ClosedRange<T>, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return lhs.lowerBound <= rhs && rhs <= lhs.upperBound
}

public func ~= <T: DBDataConvertible>(lhs: PartialRangeFrom<T>, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return lhs.lowerBound <= rhs
}

public func ~= <T: DBDataConvertible>(lhs: PartialRangeUpTo<T>, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return rhs < lhs.upperBound
}

public func ~= <T: DBDataConvertible>(lhs: PartialRangeThrough<T>, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return rhs <= lhs.upperBound
}

public func =~ (lhs: DBQueryPredicateKey, rhs: String) -> DBQueryPredicateExpression {
    return .like(.key(lhs), rhs)
}

public func =~ (lhs: DBQueryPredicateKey, rhs: NSRegularExpression) -> DBQueryPredicateExpression {
    return .matching(.key(lhs), .value(rhs))
}

public func =~ (lhs: DBQueryPredicateKey, rhs: Regex) -> DBQueryPredicateExpression {
    return .matching(.key(lhs), .value(rhs))
}

public func =~ (lhs: DBQueryPredicateKey, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .containsIn(.key(lhs), .key(rhs))
}

public func =~ <T: DBDataConvertible>(lhs: T, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .containsIn(.value(lhs), .key(rhs))
}

public func =~ <C: Collection>(lhs: DBQueryPredicateKey, rhs: C) -> DBQueryPredicateExpression where C.Element: DBDataConvertible {
    return .containsIn(.key(lhs), .value(Array(rhs)))
}

public func =~ <T: DBDataConvertible>(lhs: DBQueryPredicateKey, rhs: Range<T>) -> DBQueryPredicateExpression {
    return .between(.key(lhs), .value(rhs.lowerBound.toDBData()), .value(rhs.upperBound.toDBData()))
}

public func =~ <T: DBDataConvertible>(lhs: DBQueryPredicateKey, rhs: ClosedRange<T>) -> DBQueryPredicateExpression {
    return rhs.lowerBound <= lhs && lhs <= rhs.upperBound
}

public func =~ <T: DBDataConvertible>(lhs: DBQueryPredicateKey, rhs: PartialRangeFrom<T>) -> DBQueryPredicateExpression {
    return rhs.lowerBound <= lhs
}

public func =~ <T: DBDataConvertible>(lhs: DBQueryPredicateKey, rhs: PartialRangeUpTo<T>) -> DBQueryPredicateExpression {
    return lhs < rhs.upperBound
}

public func =~ <T: DBDataConvertible>(lhs: DBQueryPredicateKey, rhs: PartialRangeThrough<T>) -> DBQueryPredicateExpression {
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
