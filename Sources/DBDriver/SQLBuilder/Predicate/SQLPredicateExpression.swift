//
//  SQLPredicateExpression.swift
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

public indirect enum SQLPredicateExpression {
    
    case not(SQLPredicateExpression)
    
    case equal(SQLPredicateValue, SQLPredicateValue)
    
    case notEqual(SQLPredicateValue, SQLPredicateValue)
    
    case lessThan(SQLPredicateValue, SQLPredicateValue)
    
    case greaterThan(SQLPredicateValue, SQLPredicateValue)
    
    case lessThanOrEqualTo(SQLPredicateValue, SQLPredicateValue)
    
    case greaterThanOrEqualTo(SQLPredicateValue, SQLPredicateValue)
    
    case between(SQLPredicateValue, SQLPredicateValue, SQLPredicateValue)
    
    case notBetween(SQLPredicateValue, SQLPredicateValue, SQLPredicateValue)
    
    case containsIn(SQLPredicateValue, [DBData])
    
    case like(SQLPredicateValue, String)
    
    case notLike(SQLPredicateValue, String)
    
    case and(SQLPredicateExpression, SQLPredicateExpression)
    
    case or(SQLPredicateExpression, SQLPredicateExpression)
}

public enum SQLPredicateValue {
    
    case key(String)
    
    case value(DBData)
}

extension SQLPredicateValue {
    
    static func key(_ key: SQLPredicateKey) -> SQLPredicateValue {
        return .key(key.key)
    }
}

extension SQLRaw.StringInterpolation {
    
    public mutating func appendInterpolation(_ value: SQLPredicateValue) {
        switch value {
        case let .key(key): self.appendInterpolation(identifier: key)
        case let .value(value): self.appendInterpolation(value)
        }
    }
}

extension SQLPredicateExpression {
    
    var isAndOperator: Bool {
        switch self {
        case .and: return true
        default: return false
        }
    }
    
    var isOrOperator: Bool {
        switch self {
        case .or: return true
        default: return false
        }
    }
    
    public func serialize(into builder: inout SQLBuilder) {
        switch self {
        case let .not(x):
            
            builder.append("NOT (")
            x.serialize(into: &builder)
            builder.append(")")
            
        case let .equal(lhs, rhs): builder.append(.nullSafeEqual(lhs, rhs))
        case let .notEqual(lhs, rhs): builder.append(.nullSafeNotEqual(lhs, rhs))
        case let .lessThan(lhs, rhs): builder.append("\(lhs) < \(rhs)" as SQLRaw)
        case let .greaterThan(lhs, rhs): builder.append("\(lhs) > \(rhs)" as SQLRaw)
        case let .lessThanOrEqualTo(lhs, rhs): builder.append("\(lhs) <= \(rhs)" as SQLRaw)
        case let .greaterThanOrEqualTo(lhs, rhs): builder.append("\(lhs) >= \(rhs)" as SQLRaw)
        case let .between(x, from, to): builder.append("\(x) BETWEEN \(from) AND \(to)" as SQLRaw)
        case let .notBetween(x, from, to): builder.append("\(x) NOT BETWEEN \(from) AND \(to)" as SQLRaw)
        case let .containsIn(x, list):
            
            builder.append("\(x) IN (" as SQLRaw)
            for (i, item) in list.enumerated() {
                if i != 0 {
                    builder.append(",")
                }
                builder.append(item)
            }
            builder.append(")")
            
        case let .like(x, pattern): builder.append("\(x) LIKE \(pattern)" as SQLRaw)
        case let .notLike(x, pattern): builder.append("\(x) NOT LIKE \(pattern)" as SQLRaw)
        case let .and(lhs, rhs):
            
            if lhs.isOrOperator {
                if rhs.isOrOperator {
                    builder.append("(")
                    lhs.serialize(into: &builder)
                    builder.append(") AND (")
                    rhs.serialize(into: &builder)
                    builder.append(")")
                } else {
                    builder.append("(")
                    lhs.serialize(into: &builder)
                    builder.append(") AND ")
                    rhs.serialize(into: &builder)
                }
            } else {
                if rhs.isOrOperator {
                    lhs.serialize(into: &builder)
                    builder.append(" AND (")
                    rhs.serialize(into: &builder)
                    builder.append(")")
                } else {
                    lhs.serialize(into: &builder)
                    builder.append(" AND ")
                    rhs.serialize(into: &builder)
                }
            }
            
        case let .or(lhs, rhs):
            
            if lhs.isAndOperator {
                if rhs.isAndOperator {
                    builder.append("(")
                    lhs.serialize(into: &builder)
                    builder.append(") OR (")
                    rhs.serialize(into: &builder)
                    builder.append(")")
                } else {
                    builder.append("(")
                    lhs.serialize(into: &builder)
                    builder.append(") OR ")
                    rhs.serialize(into: &builder)
                }
            } else {
                if rhs.isAndOperator {
                    lhs.serialize(into: &builder)
                    builder.append(" OR (")
                    rhs.serialize(into: &builder)
                    builder.append(")")
                } else {
                    lhs.serialize(into: &builder)
                    builder.append(" OR ")
                    rhs.serialize(into: &builder)
                }
            }
        }
    }
}

public func == (lhs: SQLPredicateKey, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return .equal(.key(lhs), .key(rhs))
}

public func != (lhs: SQLPredicateKey, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return .notEqual(.key(lhs), .key(rhs))
}

public func < (lhs: SQLPredicateKey, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return .lessThan(.key(lhs), .key(rhs))
}

public func > (lhs: SQLPredicateKey, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return .greaterThan(.key(lhs), .key(rhs))
}

public func <= (lhs: SQLPredicateKey, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return .lessThanOrEqualTo(.key(lhs), .key(rhs))
}

public func >= (lhs: SQLPredicateKey, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return .greaterThanOrEqualTo(.key(lhs), .key(rhs))
}

public func == (lhs: SQLPredicateKey, rhs: _OptionalNilComparisonType) -> SQLPredicateExpression {
    return .equal(.key(lhs), .value(nil))
}

public func != (lhs: SQLPredicateKey, rhs: _OptionalNilComparisonType) -> SQLPredicateExpression {
    return .notEqual(.key(lhs), .value(nil))
}

public func == <T: DBDataConvertible>(lhs: SQLPredicateKey, rhs: T) -> SQLPredicateExpression {
    return .equal(.key(lhs), .value(rhs.toDBData()))
}

public func != <T: DBDataConvertible>(lhs: SQLPredicateKey, rhs: T) -> SQLPredicateExpression {
    return .notEqual(.key(lhs), .value(rhs.toDBData()))
}

public func < <T: DBDataConvertible>(lhs: SQLPredicateKey, rhs: T) -> SQLPredicateExpression {
    return .lessThan(.key(lhs), .value(rhs.toDBData()))
}

public func > <T: DBDataConvertible>(lhs: SQLPredicateKey, rhs: T) -> SQLPredicateExpression {
    return .greaterThan(.key(lhs), .value(rhs.toDBData()))
}

public func <= <T: DBDataConvertible>(lhs: SQLPredicateKey, rhs: T) -> SQLPredicateExpression {
    return .lessThanOrEqualTo(.key(lhs), .value(rhs.toDBData()))
}

public func >= <T: DBDataConvertible>(lhs: SQLPredicateKey, rhs: T) -> SQLPredicateExpression {
    return .greaterThanOrEqualTo(.key(lhs), .value(rhs.toDBData()))
}

public func == (lhs: _OptionalNilComparisonType, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return .equal(.value(nil), .key(rhs))
}

public func != (lhs: _OptionalNilComparisonType, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return .notEqual(.value(nil), .key(rhs))
}

public func == <T: DBDataConvertible>(lhs: T, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return .equal(.value(lhs.toDBData()), .key(rhs))
}

public func != <T: DBDataConvertible>(lhs: T, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return .notEqual(.value(lhs.toDBData()), .key(rhs))
}

public func < <T: DBDataConvertible>(lhs: T, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return .lessThan(.value(lhs.toDBData()), .key(rhs))
}

public func > <T: DBDataConvertible>(lhs: T, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return .greaterThan(.value(lhs.toDBData()), .key(rhs))
}

public func <= <T: DBDataConvertible>(lhs: T, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return .lessThanOrEqualTo(.value(lhs.toDBData()), .key(rhs))
}

public func >= <T: DBDataConvertible>(lhs: T, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return .greaterThanOrEqualTo(.value(lhs.toDBData()), .key(rhs))
}

public func ~= (lhs: String, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return .like(.key(rhs), lhs)
}

public func ~= <C: Collection>(lhs: C, rhs: SQLPredicateKey) -> SQLPredicateExpression where C.Element: DBDataConvertible {
    return .containsIn(.key(rhs), lhs.map { $0.toDBData() })
}

public func ~= <T: DBDataConvertible>(lhs: Range<T>, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return .between(.key(rhs), .value(lhs.lowerBound.toDBData()), .value(lhs.upperBound.toDBData()))
}

public func ~= <T: DBDataConvertible>(lhs: ClosedRange<T>, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return rhs <= lhs.lowerBound && lhs.upperBound <= rhs
}

public func ~= <T: DBDataConvertible>(lhs: PartialRangeFrom<T>, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return rhs <= lhs.lowerBound
}

public func ~= <T: DBDataConvertible>(lhs: PartialRangeUpTo<T>, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return lhs.upperBound < rhs
}

public func ~= <T: DBDataConvertible>(lhs: PartialRangeThrough<T>, rhs: SQLPredicateKey) -> SQLPredicateExpression {
    return lhs.upperBound <= rhs
}

public func =~ (lhs: SQLPredicateKey, rhs: String) -> SQLPredicateExpression {
    return .like(.key(lhs), rhs)
}

public func =~ <C: Collection>(lhs: SQLPredicateKey, rhs: C) -> SQLPredicateExpression where C.Element: DBDataConvertible {
    return .containsIn(.key(lhs), rhs.map { $0.toDBData() })
}

public func =~ <T: DBDataConvertible>(lhs: SQLPredicateKey, rhs: Range<T>) -> SQLPredicateExpression {
    return .between(.key(lhs), .value(rhs.lowerBound.toDBData()), .value(rhs.upperBound.toDBData()))
}

public func =~ <T: DBDataConvertible>(lhs: SQLPredicateKey, rhs: ClosedRange<T>) -> SQLPredicateExpression {
    return lhs <= rhs.lowerBound && rhs.upperBound <= lhs
}

public func =~ <T: DBDataConvertible>(lhs: SQLPredicateKey, rhs: PartialRangeFrom<T>) -> SQLPredicateExpression {
    return lhs <= rhs.lowerBound
}

public func =~ <T: DBDataConvertible>(lhs: SQLPredicateKey, rhs: PartialRangeUpTo<T>) -> SQLPredicateExpression {
    return rhs.upperBound < lhs
}

public func =~ <T: DBDataConvertible>(lhs: SQLPredicateKey, rhs: PartialRangeThrough<T>) -> SQLPredicateExpression {
    return rhs.upperBound <= lhs
}

public prefix func !(x: SQLPredicateExpression) -> SQLPredicateExpression {
    return .not(x)
}

public func && (lhs: SQLPredicateExpression, rhs: SQLPredicateExpression) -> SQLPredicateExpression {
    return .and(lhs, rhs)
}

public func || (lhs: SQLPredicateExpression, rhs: SQLPredicateExpression) -> SQLPredicateExpression {
    return .or(lhs, rhs)
}
