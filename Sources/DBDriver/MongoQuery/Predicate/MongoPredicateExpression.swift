//
//  MongoPredicateExpression.swift
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

public indirect enum MongoPredicateExpression {
    
    case not(MongoPredicateExpression)
    
    case equal(MongoPredicateValue, MongoPredicateValue)
    
    case notEqual(MongoPredicateValue, MongoPredicateValue)
    
    case lessThan(MongoPredicateValue, MongoPredicateValue)
    
    case greaterThan(MongoPredicateValue, MongoPredicateValue)
    
    case lessThanOrEqualTo(MongoPredicateValue, MongoPredicateValue)
    
    case greaterThanOrEqualTo(MongoPredicateValue, MongoPredicateValue)
    
    case containsIn(MongoPredicateValue, MongoPredicateValue)
    
    case notContainsIn(MongoPredicateValue, MongoPredicateValue)
    
    case matching(MongoPredicateValue, Regex)
    
    case and(MongoPredicateExpression, MongoPredicateExpression)
    
    case or(MongoPredicateExpression, MongoPredicateExpression)
}

public enum MongoPredicateValue {
    
    case key(String)
    
    case value(BSONConvertible)
}

extension MongoPredicateExpression {
    
    var _andList: [MongoPredicateExpression]? {
        switch self {
        case let .and(lhs, rhs):
            let _lhs = lhs._andList ?? [lhs]
            let _rhs = rhs._andList ?? [rhs]
            return _lhs + _rhs
        default: return nil
        }
    }
    
    var _orList: [MongoPredicateExpression]? {
        switch self {
        case let .or(lhs, rhs):
            let _lhs = lhs._orList ?? [lhs]
            let _rhs = rhs._orList ?? [rhs]
            return _lhs + _rhs
        default: return nil
        }
    }
    
    func toBSONDocument() throws -> BSONDocument {
        
        switch self {
        case let .not(x):
            
            return try ["$not": BSON(x.toBSONDocument())]
            
        case let .equal(.key(key), .value(value)),
             let .equal(.value(value), .key(key)):
            
            return try [key: ["$eq": value.toBSON()]]
            
        case let .notEqual(.key(key), .value(value)),
             let .notEqual(.value(value), .key(key)):
            
            return try [key: ["$ne": value.toBSON()]]
            
        case let .lessThan(.key(key), .value(value)),
             let .lessThan(.value(value), .key(key)):
            
            return try [key: ["$lt": value.toBSON()]]
            
        case let .greaterThan(.key(key), .value(value)),
             let .greaterThan(.value(value), .key(key)):
            
            return try [key: ["$gt": value.toBSON()]]
            
        case let .lessThanOrEqualTo(.key(key), .value(value)),
             let .lessThanOrEqualTo(.value(value), .key(key)):
            
            return try [key: ["$lte": value.toBSON()]]
            
        case let .greaterThanOrEqualTo(.key(key), .value(value)),
             let .greaterThanOrEqualTo(.value(value), .key(key)):
            
            return try [key: ["$gte": value.toBSON()]]
            
        case let .containsIn(.key(key), .value(value)):
            
            return try [key: ["$in": value.toBSON()]]
            
        case let .notContainsIn(.key(key), .value(value)):
            
            return try [key: ["$nin": value.toBSON()]]
            
        case let .matching(.key(key), regex):
        
            return try [key: ["$regex": regex.toBSON()]]
            
        case let .and(lhs, rhs):
            
            let _lhs = lhs._andList ?? [lhs]
            let _rhs = rhs._andList ?? [rhs]
            let list = _lhs + _rhs
            return try ["$and": BSON(list.map { try $0.toBSONDocument() })]
            
        case let .or(lhs, rhs):
            
            let _lhs = lhs._orList ?? [lhs]
            let _rhs = rhs._orList ?? [rhs]
            let list = _lhs + _rhs
            return try ["$or": BSON(list.map { try $0.toBSONDocument() })]
            
        default: throw Database.Error.invalidExpression
        }
    }
}

public func == (lhs: MongoPredicateValue, rhs: _OptionalNilComparisonType) -> MongoPredicateExpression {
    return .equal(lhs, .value(BSON.null))
}

public func != (lhs: MongoPredicateValue, rhs: _OptionalNilComparisonType) -> MongoPredicateExpression {
    return .notEqual(lhs, .value(BSON.null))
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

public func == (lhs: _OptionalNilComparisonType, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return .equal(.value(BSON.null), rhs)
}

public func != (lhs: _OptionalNilComparisonType, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return .notEqual(.value(BSON.null), rhs)
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

public func ~= (lhs: NSRegularExpression, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return .matching(rhs, Regex(lhs))
}

public func ~= (lhs: Regex, rhs: MongoPredicateValue) -> MongoPredicateExpression {
    return .matching(rhs, lhs)
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

public func =~ (lhs: MongoPredicateValue, rhs: NSRegularExpression) -> MongoPredicateExpression {
    return .matching(lhs, Regex(rhs))
}

public func =~ (lhs: MongoPredicateValue, rhs: Regex) -> MongoPredicateExpression {
    return .matching(lhs, rhs)
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

public prefix func !(x: MongoPredicateExpression) -> MongoPredicateExpression {
    return .not(x)
}

public func && (lhs: MongoPredicateExpression, rhs: MongoPredicateExpression) -> MongoPredicateExpression {
    return .and(lhs, rhs)
}

public func || (lhs: MongoPredicateExpression, rhs: MongoPredicateExpression) -> MongoPredicateExpression {
    return .or(lhs, rhs)
}
