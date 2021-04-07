//
//  SQLPredicateValue.swift
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

public enum SQLPredicateValue {
    
    case name(String)
    
    case value(DBData)
}

public func == (lhs: SQLPredicateValue, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return .equal(lhs, rhs)
}

public func != (lhs: SQLPredicateValue, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return .notEqual(lhs, rhs)
}

public func < (lhs: SQLPredicateValue, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return .lessThan(lhs, rhs)
}

public func > (lhs: SQLPredicateValue, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return .greaterThan(lhs, rhs)
}

public func <= (lhs: SQLPredicateValue, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return .lessThanOrEqualTo(lhs, rhs)
}

public func >= (lhs: SQLPredicateValue, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return .greaterThanOrEqualTo(lhs, rhs)
}

public func == <T: DBDataConvertible>(lhs: SQLPredicateValue, rhs: T) -> SQLPredicateExpression {
    return .equal(lhs, .value(rhs.toDBData()))
}

public func != <T: DBDataConvertible>(lhs: SQLPredicateValue, rhs: T) -> SQLPredicateExpression {
    return .notEqual(lhs, .value(rhs.toDBData()))
}

public func < <T: DBDataConvertible>(lhs: SQLPredicateValue, rhs: T) -> SQLPredicateExpression {
    return .lessThan(lhs, .value(rhs.toDBData()))
}

public func > <T: DBDataConvertible>(lhs: SQLPredicateValue, rhs: T) -> SQLPredicateExpression {
    return .greaterThan(lhs, .value(rhs.toDBData()))
}

public func <= <T: DBDataConvertible>(lhs: SQLPredicateValue, rhs: T) -> SQLPredicateExpression {
    return .lessThanOrEqualTo(lhs, .value(rhs.toDBData()))
}

public func >= <T: DBDataConvertible>(lhs: SQLPredicateValue, rhs: T) -> SQLPredicateExpression {
    return .greaterThanOrEqualTo(lhs, .value(rhs.toDBData()))
}

public func == <T: DBDataConvertible>(lhs: T, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return .equal(.value(lhs.toDBData()), rhs)
}

public func != <T: DBDataConvertible>(lhs: T, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return .notEqual(.value(lhs.toDBData()), rhs)
}

public func < <T: DBDataConvertible>(lhs: T, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return .lessThan(.value(lhs.toDBData()), rhs)
}

public func > <T: DBDataConvertible>(lhs: T, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return .greaterThan(.value(lhs.toDBData()), rhs)
}

public func <= <T: DBDataConvertible>(lhs: T, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return .lessThanOrEqualTo(.value(lhs.toDBData()), rhs)
}

public func >= <T: DBDataConvertible>(lhs: T, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return .greaterThanOrEqualTo(.value(lhs.toDBData()), rhs)
}

public func ~= (lhs: String, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return .like(rhs, lhs)
}

public func ~= <C: Collection>(lhs: C, rhs: SQLPredicateValue) -> SQLPredicateExpression where C.Element: DBDataConvertible {
    return .containsIn(rhs, lhs.map { $0.toDBData() })
}

public func ~= <T: DBDataConvertible>(lhs: Range<T>, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return .between(rhs, .value(lhs.lowerBound.toDBData()), .value(lhs.upperBound.toDBData()))
}

public func ~= <T: DBDataConvertible>(lhs: ClosedRange<T>, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return rhs <= lhs.lowerBound && lhs.upperBound <= rhs
}

public func ~= <T: DBDataConvertible>(lhs: PartialRangeFrom<T>, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return rhs <= lhs.lowerBound
}

public func ~= <T: DBDataConvertible>(lhs: PartialRangeUpTo<T>, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return lhs.upperBound < rhs
}

public func ~= <T: DBDataConvertible>(lhs: PartialRangeThrough<T>, rhs: SQLPredicateValue) -> SQLPredicateExpression {
    return lhs.upperBound <= rhs
}

infix operator =~: ComparisonPrecedence

public func =~ (lhs: SQLPredicateValue, rhs: String) -> SQLPredicateExpression {
    return .like(lhs, rhs)
}

public func =~ <C: Collection>(lhs: SQLPredicateValue, rhs: C) -> SQLPredicateExpression where C.Element: DBDataConvertible {
    return .containsIn(lhs, rhs.map { $0.toDBData() })
}

public func =~ <T: DBDataConvertible>(lhs: SQLPredicateValue, rhs: Range<T>) -> SQLPredicateExpression {
    return .between(lhs, .value(rhs.lowerBound.toDBData()), .value(rhs.upperBound.toDBData()))
}

public func =~ <T: DBDataConvertible>(lhs: SQLPredicateValue, rhs: ClosedRange<T>) -> SQLPredicateExpression {
    return lhs <= rhs.lowerBound && rhs.upperBound <= lhs
}

public func =~ <T: DBDataConvertible>(lhs: SQLPredicateValue, rhs: PartialRangeFrom<T>) -> SQLPredicateExpression {
    return lhs <= rhs.lowerBound
}

public func =~ <T: DBDataConvertible>(lhs: SQLPredicateValue, rhs: PartialRangeUpTo<T>) -> SQLPredicateExpression {
    return rhs.upperBound < lhs
}

public func =~ <T: DBDataConvertible>(lhs: SQLPredicateValue, rhs: PartialRangeThrough<T>) -> SQLPredicateExpression {
    return rhs.upperBound <= lhs
}
