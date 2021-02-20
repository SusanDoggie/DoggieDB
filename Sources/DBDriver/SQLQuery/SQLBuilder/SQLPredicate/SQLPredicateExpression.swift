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
    
    case like(SQLPredicateValue, String)
    
    case notLike(SQLPredicateValue, String)
    
    case and(SQLPredicateExpression, SQLPredicateExpression)
    
    case or(SQLPredicateExpression, SQLPredicateExpression)
}

extension SQLPredicateExpression {
    
    func serialize() -> SQLRaw {
        switch self {
        case let .not(x): return "NOT (" + x.serialize() + ")"
        case let .equal(lhs, rhs): return ""
        case let .notEqual(lhs, rhs): return ""
        case let .lessThan(lhs, rhs): return ""
        case let .greaterThan(lhs, rhs): return ""
        case let .greaterThanOrEqualTo(lhs, rhs): return ""
        case let .lessThanOrEqualTo(lhs, rhs): return ""
        case let .between(x, from, to): return ""
        case let .notBetween(x, from, to): return ""
        case let .like(x, pattern): return ""
        case let .notLike(x, pattern): return ""
        case let .and(lhs, rhs): return "(" + lhs.serialize() + " && " + rhs.serialize() + ")"
        case let .or(lhs, rhs): return "(" + lhs.serialize() + " || " + rhs.serialize() + ")"
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
