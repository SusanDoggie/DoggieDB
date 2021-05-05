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
    
    case matching(MongoPredicateValue, MongoPredicateValue)
    
    case and(MongoPredicateExpression, MongoPredicateExpression)
    
    case or(MongoPredicateExpression, MongoPredicateExpression)
}

public enum MongoPredicateValue {
    
    case key(String)
    
    case value(BSONConvertible)
}

extension MongoPredicateValue {
    
    static func key(_ key: MongoPredicateKey) -> MongoPredicateValue {
        return .key(key.key)
    }
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
    
    public func toBSONDocument() throws -> BSONDocument {
        
        switch self {
        case let .not(x):
            
            return try ["$not": BSON(x.toBSONDocument())]
            
        case let .equal(.key(lhs), .key(rhs)):
            
            return ["$expr": ["$eq": ["$\(lhs)".toBSON(), "$\(rhs)".toBSON()]]]
            
        case let .equal(.key(key), .value(value)),
             let .equal(.value(value), .key(key)):
            
            return [key: ["$eq": value.toBSON()]]
            
        case let .notEqual(.key(lhs), .key(rhs)):
            
            return ["$expr": ["$ne": ["$\(lhs)".toBSON(), "$\(rhs)".toBSON()]]]
            
        case let .notEqual(.key(key), .value(value)),
             let .notEqual(.value(value), .key(key)):
            
            return [key: ["$ne": value.toBSON()]]
            
        case let .lessThan(.key(lhs), .key(rhs)):
            
            return ["$expr": ["$lt": ["$\(lhs)".toBSON(), "$\(rhs)".toBSON()]]]
            
        case let .lessThan(.key(key), .value(value)),
             let .lessThan(.value(value), .key(key)):
            
            return [key: ["$lt": value.toBSON()]]
            
        case let .greaterThan(.key(lhs), .key(rhs)):
            
            return ["$expr": ["$gt": ["$\(lhs)".toBSON(), "$\(rhs)".toBSON()]]]
            
        case let .greaterThan(.key(key), .value(value)),
             let .greaterThan(.value(value), .key(key)):
            
            return [key: ["$gt": value.toBSON()]]
            
        case let .lessThanOrEqualTo(.key(lhs), .key(rhs)):
            
            return ["$expr": ["$lte": ["$\(lhs)".toBSON(), "$\(rhs)".toBSON()]]]
            
        case let .lessThanOrEqualTo(.key(key), .value(value)),
             let .lessThanOrEqualTo(.value(value), .key(key)):
            
            return [key: ["$lte": value.toBSON()]]
            
        case let .greaterThanOrEqualTo(.key(lhs), .key(rhs)):
            
            return ["$expr": ["$gte": ["$\(lhs)".toBSON(), "$\(rhs)".toBSON()]]]
            
        case let .greaterThanOrEqualTo(.key(key), .value(value)),
             let .greaterThanOrEqualTo(.value(value), .key(key)):
            
            return [key: ["$gte": value.toBSON()]]
            
        case let .containsIn(.key(lhs), .key(rhs)):
            
            return ["$expr": ["$in": ["$\(lhs)".toBSON(), "$\(rhs)".toBSON()]]]
            
        case let .containsIn(.value(value), .key(key)):
            
            return ["$expr": ["$in": [value.toBSON(), "$\(key)".toBSON()]]]
            
        case let .containsIn(.key(key), .value(value)):
            
            return [key: ["$in": value.toBSON()]]
            
        case let .notContainsIn(.key(lhs), .key(rhs)):
            
            return ["$expr": ["$not": [["$in": ["$\(lhs)".toBSON(), "$\(rhs)".toBSON()]]]]]
            
        case let .notContainsIn(.value(value), .key(key)):
            
            return ["$expr": ["$not": [["$in": [value.toBSON(), "$\(key)".toBSON()]]]]]
            
        case let .notContainsIn(.key(key), .value(value)):
            
            return [key: ["$nin": value.toBSON()]]
            
        case let .matching(.key(lhs), .key(rhs)):
            
            return ["$expr": ["$regexMatch": ["input": "$\(lhs)".toBSON(), "regex": "$\(rhs)".toBSON()]]]
            
        case let .matching(.key(key), .value(value)):
        
            return [key: ["$regex": value.toBSON()]]
            
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

public func == (lhs: MongoPredicateKey, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .equal(.key(lhs), .key(rhs))
}

public func != (lhs: MongoPredicateKey, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .notEqual(.key(lhs), .key(rhs))
}

public func < (lhs: MongoPredicateKey, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .lessThan(.key(lhs), .key(rhs))
}

public func > (lhs: MongoPredicateKey, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .greaterThan(.key(lhs), .key(rhs))
}

public func <= (lhs: MongoPredicateKey, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .lessThanOrEqualTo(.key(lhs), .key(rhs))
}

public func >= (lhs: MongoPredicateKey, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .greaterThanOrEqualTo(.key(lhs), .key(rhs))
}

public func == (lhs: MongoPredicateKey, rhs: _OptionalNilComparisonType) -> MongoPredicateExpression {
    return .equal(.key(lhs), .value(BSON.null))
}

public func != (lhs: MongoPredicateKey, rhs: _OptionalNilComparisonType) -> MongoPredicateExpression {
    return .notEqual(.key(lhs), .value(BSON.null))
}

public func == <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: T) -> MongoPredicateExpression {
    return .equal(.key(lhs), .value(rhs))
}

public func != <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: T) -> MongoPredicateExpression {
    return .notEqual(.key(lhs), .value(rhs))
}

public func < <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: T) -> MongoPredicateExpression {
    return .lessThan(.key(lhs), .value(rhs))
}

public func > <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: T) -> MongoPredicateExpression {
    return .greaterThan(.key(lhs), .value(rhs))
}

public func <= <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: T) -> MongoPredicateExpression {
    return .lessThanOrEqualTo(.key(lhs), .value(rhs))
}

public func >= <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: T) -> MongoPredicateExpression {
    return .greaterThanOrEqualTo(.key(lhs), .value(rhs))
}

public func == (lhs: _OptionalNilComparisonType, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .equal(.value(BSON.null), .key(rhs))
}

public func != (lhs: _OptionalNilComparisonType, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .notEqual(.value(BSON.null), .key(rhs))
}

public func == <T: BSONConvertible>(lhs: T, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .equal(.value(lhs), .key(rhs))
}

public func != <T: BSONConvertible>(lhs: T, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .notEqual(.value(lhs), .key(rhs))
}

public func < <T: BSONConvertible>(lhs: T, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .lessThan(.value(lhs), .key(rhs))
}

public func > <T: BSONConvertible>(lhs: T, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .greaterThan(.value(lhs), .key(rhs))
}

public func <= <T: BSONConvertible>(lhs: T, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .lessThanOrEqualTo(.value(lhs), .key(rhs))
}

public func >= <T: BSONConvertible>(lhs: T, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .greaterThanOrEqualTo(.value(lhs), .key(rhs))
}

public func ~= (lhs: NSRegularExpression, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .matching(.key(rhs), .value(lhs))
}

public func ~= (lhs: Regex, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .matching(.key(rhs), .value(lhs))
}

public func ~= (lhs: MongoPredicateKey, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .containsIn(.key(rhs), .key(lhs))
}

public func ~= <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: T) -> MongoPredicateExpression {
    return .containsIn(.value(rhs), .key(lhs))
}

public func ~= <C: Collection>(lhs: C, rhs: MongoPredicateKey) -> MongoPredicateExpression where C.Element: BSONConvertible {
    return .containsIn(.key(rhs), .value(Array(lhs)))
}

public func ~= <T: BSONConvertible>(lhs: Range<T>, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return rhs <= lhs.lowerBound && lhs.upperBound < rhs
}

public func ~= <T: BSONConvertible>(lhs: ClosedRange<T>, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return rhs <= lhs.lowerBound && lhs.upperBound <= rhs
}

public func ~= <T: BSONConvertible>(lhs: PartialRangeFrom<T>, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return rhs <= lhs.lowerBound
}

public func ~= <T: BSONConvertible>(lhs: PartialRangeUpTo<T>, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return lhs.upperBound < rhs
}

public func ~= <T: BSONConvertible>(lhs: PartialRangeThrough<T>, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return lhs.upperBound <= rhs
}

public func =~ (lhs: MongoPredicateKey, rhs: NSRegularExpression) -> MongoPredicateExpression {
    return .matching(.key(lhs), .value(rhs))
}

public func =~ (lhs: MongoPredicateKey, rhs: Regex) -> MongoPredicateExpression {
    return .matching(.key(lhs), .value(rhs))
}

public func =~ (lhs: MongoPredicateKey, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .containsIn(.key(lhs), .key(rhs))
}

public func =~ <T: BSONConvertible>(lhs: T, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .containsIn(.value(lhs), .key(rhs))
}

public func =~ <C: Collection>(lhs: MongoPredicateKey, rhs: C) -> MongoPredicateExpression where C.Element: BSONConvertible {
    return .containsIn(.key(lhs), .value(Array(rhs)))
}

public func =~ <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: Range<T>) -> MongoPredicateExpression {
    return lhs <= rhs.lowerBound && rhs.upperBound < lhs
}

public func =~ <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: ClosedRange<T>) -> MongoPredicateExpression {
    return lhs <= rhs.lowerBound && rhs.upperBound <= lhs
}

public func =~ <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: PartialRangeFrom<T>) -> MongoPredicateExpression {
    return lhs <= rhs.lowerBound
}

public func =~ <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: PartialRangeUpTo<T>) -> MongoPredicateExpression {
    return rhs.upperBound < lhs
}

public func =~ <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: PartialRangeThrough<T>) -> MongoPredicateExpression {
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
