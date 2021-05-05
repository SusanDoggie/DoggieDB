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
    
    case and(DBQueryPredicateExpression, DBQueryPredicateExpression)
    
    case or(DBQueryPredicateExpression, DBQueryPredicateExpression)
}

public enum DBQueryPredicateValue {
    
    case key(String)
    
    case value(DBValueConvertible)
}

extension DBQueryPredicateValue {
    
    static func key(_ key: DBQueryPredicateKey) -> DBQueryPredicateValue {
        return .key(key.key)
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
    return .equal(.key(lhs), .value(nil as DBValue))
}

public func != (lhs: DBQueryPredicateKey, rhs: _OptionalNilComparisonType) -> DBQueryPredicateExpression {
    return .notEqual(.key(lhs), .value(nil as DBValue))
}

public func == <T: DBValueConvertible>(lhs: DBQueryPredicateKey, rhs: T) -> DBQueryPredicateExpression {
    return .equal(.key(lhs), .value(rhs))
}

public func != <T: DBValueConvertible>(lhs: DBQueryPredicateKey, rhs: T) -> DBQueryPredicateExpression {
    return .notEqual(.key(lhs), .value(rhs))
}

public func < <T: DBValueConvertible>(lhs: DBQueryPredicateKey, rhs: T) -> DBQueryPredicateExpression {
    return .lessThan(.key(lhs), .value(rhs))
}

public func > <T: DBValueConvertible>(lhs: DBQueryPredicateKey, rhs: T) -> DBQueryPredicateExpression {
    return .greaterThan(.key(lhs), .value(rhs))
}

public func <= <T: DBValueConvertible>(lhs: DBQueryPredicateKey, rhs: T) -> DBQueryPredicateExpression {
    return .lessThanOrEqualTo(.key(lhs), .value(rhs))
}

public func >= <T: DBValueConvertible>(lhs: DBQueryPredicateKey, rhs: T) -> DBQueryPredicateExpression {
    return .greaterThanOrEqualTo(.key(lhs), .value(rhs))
}

public func == (lhs: _OptionalNilComparisonType, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .equal(.value(nil as DBValue), .key(rhs))
}

public func != (lhs: _OptionalNilComparisonType, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .notEqual(.value(nil as DBValue), .key(rhs))
}

public func == <T: DBValueConvertible>(lhs: T, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .equal(.value(lhs), .key(rhs))
}

public func != <T: DBValueConvertible>(lhs: T, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .notEqual(.value(lhs), .key(rhs))
}

public func < <T: DBValueConvertible>(lhs: T, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .lessThan(.value(lhs), .key(rhs))
}

public func > <T: DBValueConvertible>(lhs: T, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .greaterThan(.value(lhs), .key(rhs))
}

public func <= <T: DBValueConvertible>(lhs: T, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .lessThanOrEqualTo(.value(lhs), .key(rhs))
}

public func >= <T: DBValueConvertible>(lhs: T, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
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

public func ~= <T: DBValueConvertible>(lhs: DBQueryPredicateKey, rhs: T) -> DBQueryPredicateExpression {
    return .containsIn(.value(rhs), .key(lhs))
}

public func ~= <C: Collection>(lhs: C, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression where C.Element: DBValueConvertible {
    return .containsIn(.key(rhs), .value(Array(lhs)))
}

public func ~= <T: DBValueConvertible>(lhs: Range<T>, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .between(.key(rhs), .value(lhs.lowerBound.toDBValue()), .value(lhs.upperBound.toDBValue()))
}

public func ~= <T: DBValueConvertible>(lhs: ClosedRange<T>, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return rhs <= lhs.lowerBound && lhs.upperBound <= rhs
}

public func ~= <T: DBValueConvertible>(lhs: PartialRangeFrom<T>, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return rhs <= lhs.lowerBound
}

public func ~= <T: DBValueConvertible>(lhs: PartialRangeUpTo<T>, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return lhs.upperBound < rhs
}

public func ~= <T: DBValueConvertible>(lhs: PartialRangeThrough<T>, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return lhs.upperBound <= rhs
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

public func =~ <T: DBValueConvertible>(lhs: T, rhs: DBQueryPredicateKey) -> DBQueryPredicateExpression {
    return .containsIn(.value(lhs), .key(rhs))
}

public func =~ <C: Collection>(lhs: DBQueryPredicateKey, rhs: C) -> DBQueryPredicateExpression where C.Element: DBValueConvertible {
    return .containsIn(.key(lhs), .value(Array(rhs)))
}

public func =~ <T: DBValueConvertible>(lhs: DBQueryPredicateKey, rhs: Range<T>) -> DBQueryPredicateExpression {
    return .between(.key(lhs), .value(rhs.lowerBound.toDBValue()), .value(rhs.upperBound.toDBValue()))
}

public func =~ <T: DBValueConvertible>(lhs: DBQueryPredicateKey, rhs: ClosedRange<T>) -> DBQueryPredicateExpression {
    return lhs <= rhs.lowerBound && rhs.upperBound <= lhs
}

public func =~ <T: DBValueConvertible>(lhs: DBQueryPredicateKey, rhs: PartialRangeFrom<T>) -> DBQueryPredicateExpression {
    return lhs <= rhs.lowerBound
}

public func =~ <T: DBValueConvertible>(lhs: DBQueryPredicateKey, rhs: PartialRangeUpTo<T>) -> DBQueryPredicateExpression {
    return rhs.upperBound < lhs
}

public func =~ <T: DBValueConvertible>(lhs: DBQueryPredicateKey, rhs: PartialRangeThrough<T>) -> DBQueryPredicateExpression {
    return rhs.upperBound <= lhs
}

public prefix func !(x: DBQueryPredicateExpression) -> DBQueryPredicateExpression {
    return .not(x)
}

public func && (lhs: DBQueryPredicateExpression, rhs: DBQueryPredicateExpression) -> DBQueryPredicateExpression {
    return .and(lhs, rhs)
}

public func || (lhs: DBQueryPredicateExpression, rhs: DBQueryPredicateExpression) -> DBQueryPredicateExpression {
    return .or(lhs, rhs)
}
