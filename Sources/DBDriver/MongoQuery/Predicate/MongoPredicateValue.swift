//
//  MongoPredicateValue.swift
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

public enum MongoPredicateValue {
    
    case key(String)
    
    case value(BSONConvertible)
}

public func == (lhs: MongoPredicateValue, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return .equal(lhs, rhs)
}

public func != (lhs: MongoPredicateValue, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return .notEqual(lhs, rhs)
}

public func < (lhs: MongoPredicateValue, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return .lessThan(lhs, rhs)
}

public func > (lhs: MongoPredicateValue, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return .greaterThan(lhs, rhs)
}

public func <= (lhs: MongoPredicateValue, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return .lessThanOrEqualTo(lhs, rhs)
}

public func >= (lhs: MongoPredicateValue, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return .greaterThanOrEqualTo(lhs, rhs)
}

public func == <T: BSONConvertible>(lhs: MongoPredicateValue, rhs: T) -> MongoPredicateExpression {
    return .equal(lhs, .value(rhs))
}

public func != <T: BSONConvertible>(lhs: MongoPredicateValue, rhs: T) -> MongoPredicateExpression {
    return .notEqual(lhs, .value(rhs))
}

public func < <T: BSONConvertible>(lhs: MongoPredicateValue, rhs: T) -> MongoPredicateExpression {
    return .lessThan(lhs, .value(rhs))
}

public func > <T: BSONConvertible>(lhs: MongoPredicateValue, rhs: T) -> MongoPredicateExpression {
    return .greaterThan(lhs, .value(rhs))
}

public func <= <T: BSONConvertible>(lhs: MongoPredicateValue, rhs: T) -> MongoPredicateExpression {
    return .lessThanOrEqualTo(lhs, .value(rhs))
}

public func >= <T: BSONConvertible>(lhs: MongoPredicateValue, rhs: T) -> MongoPredicateExpression {
    return .greaterThanOrEqualTo(lhs, .value(rhs))
}

public func == <T: BSONConvertible>(lhs: T, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return .equal(.value(lhs), rhs)
}

public func != <T: BSONConvertible>(lhs: T, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return .notEqual(.value(lhs), rhs)
}

public func < <T: BSONConvertible>(lhs: T, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return .lessThan(.value(lhs), rhs)
}

public func > <T: BSONConvertible>(lhs: T, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return .greaterThan(.value(lhs), rhs)
}

public func <= <T: BSONConvertible>(lhs: T, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return .lessThanOrEqualTo(.value(lhs), rhs)
}

public func >= <T: BSONConvertible>(lhs: T, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return .greaterThanOrEqualTo(.value(lhs), rhs)
}

public func ~= <C: Collection>(lhs: C, rhs: MongoPredicateValue) -> MongoPredicateExpression where C.Element: BSONConvertible {
    return .containsIn(.value(Array(lhs)), rhs)
}

public func ~= <T: BSONConvertible>(lhs: Range<T>, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return rhs <= lhs.lowerBound && lhs.upperBound < rhs
}

public func ~= <T: BSONConvertible>(lhs: ClosedRange<T>, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return rhs <= lhs.lowerBound && lhs.upperBound <= rhs
}

public func ~= <T: BSONConvertible>(lhs: PartialRangeFrom<T>, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return rhs <= lhs.lowerBound
}

public func ~= <T: BSONConvertible>(lhs: PartialRangeUpTo<T>, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return lhs.upperBound < rhs
}

public func ~= <T: BSONConvertible>(lhs: PartialRangeThrough<T>, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return lhs.upperBound <= rhs
}

public func =~ <C: Collection>(lhs: MongoPredicateValue, rhs: C) -> MongoPredicateExpression where C.Element: BSONConvertible {
    return .containsIn(lhs, .value(Array(rhs)))
}

public func =~ <T: BSONConvertible>(lhs: MongoPredicateValue, rhs: Range<T>) -> MongoPredicateExpression {
    return lhs <= rhs.lowerBound && rhs.upperBound < lhs
}

public func =~ <T: BSONConvertible>(lhs: MongoPredicateValue, rhs: ClosedRange<T>) -> MongoPredicateExpression {
    return lhs <= rhs.lowerBound && rhs.upperBound <= lhs
}

public func =~ <T: BSONConvertible>(lhs: MongoPredicateValue, rhs: PartialRangeFrom<T>) -> MongoPredicateExpression {
    return lhs <= rhs.lowerBound
}

public func =~ <T: BSONConvertible>(lhs: MongoPredicateValue, rhs: PartialRangeUpTo<T>) -> MongoPredicateExpression {
    return rhs.upperBound < lhs
}

public func =~ <T: BSONConvertible>(lhs: MongoPredicateValue, rhs: PartialRangeThrough<T>) -> MongoPredicateExpression {
    return rhs.upperBound <= lhs
}
