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

extension SQLRaw.StringInterpolation {
    
    mutating func appendInterpolation(_ value: SQLPredicateValue) {
        switch value {
        case let .name(name): self.appendLiteral(name)
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
    
    func serialize(into builder: inout SQLBuilder) {
        switch self {
        case let .not(x): builder.append("NOT (\(x))")
        case let .equal(lhs, rhs): builder.builder.append(.nullSafeEqual(lhs, rhs))
        case let .notEqual(lhs, rhs): builder.builder.append(.nullSafeNotEqual(lhs, rhs))
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
                    builder.builder.append(",")
                }
                builder.builder.append(item)
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

public prefix func !(x: SQLPredicateExpression) -> SQLPredicateExpression {
    return .not(x)
}

public func && (lhs: SQLPredicateExpression, rhs: SQLPredicateExpression) -> SQLPredicateExpression {
    return .and(lhs, rhs)
}

public func || (lhs: SQLPredicateExpression, rhs: SQLPredicateExpression) -> SQLPredicateExpression {
    return .or(lhs, rhs)
}
