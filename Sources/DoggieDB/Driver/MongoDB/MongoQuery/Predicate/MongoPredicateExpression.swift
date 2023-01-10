//
//  MongoPredicateExpression.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2023 Susan Cheng. All rights reserved.
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

@frozen
public indirect enum MongoPredicateExpression: Sendable {
    
    case not(MongoPredicateExpression)
    
    case equal(MongoPredicateValue, MongoPredicateValue)
    
    case notEqual(MongoPredicateValue, MongoPredicateValue)
    
    case lessThan(MongoPredicateValue, MongoPredicateValue)
    
    case greaterThan(MongoPredicateValue, MongoPredicateValue)
    
    case lessThanOrEqualTo(MongoPredicateValue, MongoPredicateValue)
    
    case greaterThanOrEqualTo(MongoPredicateValue, MongoPredicateValue)
    
    case containsIn(MongoPredicateValue, MongoPredicateValue)
    
    case notContainsIn(MongoPredicateValue, MongoPredicateValue)
    
    case matching(MongoPredicateKey, MongoPredicateValue)
    
    case startsWith(MongoPredicateKey, String, options: NSRegularExpression.Options = [])
    
    case endsWith(MongoPredicateKey, String, options: NSRegularExpression.Options = [])
    
    case contains(MongoPredicateKey, String, options: NSRegularExpression.Options = [])
    
    case and([MongoPredicateExpression])
    
    case or([MongoPredicateExpression])
}

@frozen
public enum MongoPredicateValue: @unchecked Sendable {
    
    case key(String)
    
    case value(BSONConvertible)
}

extension NSRegularExpression.Options: @unchecked Sendable { }

extension MongoPredicateValue {
    
    @inlinable
    static func key(_ key: MongoPredicateKey) -> MongoPredicateValue {
        return .key(key.key)
    }
}

private let regexOptsMap: [Character: NSRegularExpression.Options] = [
    "i": .caseInsensitive,
    "m": .anchorsMatchLines,
    "s": .dotMatchesLineSeparators,
    "u": .useUnicodeWordBoundaries,
    "x": .allowCommentsAndWhitespace
]

extension NSRegularExpression.Options {
    
    var stringOptions: String {
        var optsString = ""
        for (char, o) in regexOptsMap { if self.contains(o) { optsString += String(char) } }
        return String(optsString.sorted())
    }
}

private func quote(_ str: String) -> String {
    return "\\Q\(str.replace(regex: "\\\\E", template: "\\\\E\\\\\\\\E\\\\Q"))\\E"
}

extension MongoPredicateExpression {
    
    var _andList: [MongoPredicateExpression]? {
        switch self {
        case let .and(list): return list.flatMap { $0._andList ?? [$0] }
        default: return nil
        }
    }
    
    var _orList: [MongoPredicateExpression]? {
        switch self {
        case let .or(list): return list.flatMap { $0._orList ?? [$0] }
        default: return nil
        }
    }
    
    func _expression() throws -> BSONDocument {
        
        switch self {
        case let .not(x):
            
            return try ["$not": BSON(x._expression())]
            
        case let .equal(.key(lhs), .key(rhs)):
            
            return ["$eq": ["$\(lhs)".toBSON(), "$\(rhs)".toBSON()]]
            
        case let .equal(.key(key), .value(value)),
             let .equal(.value(value), .key(key)):
            
            return ["$eq": ["$\(key)".toBSON(), value.toBSON()]]
            
        case let .notEqual(.key(lhs), .key(rhs)):
            
            return ["$ne": ["$\(lhs)".toBSON(), "$\(rhs)".toBSON()]]
            
        case let .notEqual(.key(key), .value(value)),
             let .notEqual(.value(value), .key(key)):
            
            return ["$ne": ["$\(key)".toBSON(), value.toBSON()]]
            
        case let .lessThan(.key(lhs), .key(rhs)):
            
            return ["$lt": ["$\(lhs)".toBSON(), "$\(rhs)".toBSON()]]
            
        case let .lessThan(.key(key), .value(value)),
             let .greaterThan(.value(value), .key(key)):
            
            return ["$lt": ["$\(key)".toBSON(), value.toBSON()]]
            
        case let .greaterThan(.key(lhs), .key(rhs)):
            
            return ["$gt": ["$\(lhs)".toBSON(), "$\(rhs)".toBSON()]]
            
        case let .greaterThan(.key(key), .value(value)),
             let .lessThan(.value(value), .key(key)):
            
            return ["$gt": ["$\(key)".toBSON(), value.toBSON()]]
            
        case let .lessThanOrEqualTo(.key(lhs), .key(rhs)):
            
            return ["$lte": ["$\(lhs)".toBSON(), "$\(rhs)".toBSON()]]
            
        case let .lessThanOrEqualTo(.key(key), .value(value)),
             let .greaterThanOrEqualTo(.value(value), .key(key)):
            
            return ["$lte": ["$\(key)".toBSON(), value.toBSON()]]
            
        case let .greaterThanOrEqualTo(.key(lhs), .key(rhs)):
            
            return ["$gte": ["$\(lhs)".toBSON(), "$\(rhs)".toBSON()]]
            
        case let .greaterThanOrEqualTo(.key(key), .value(value)),
             let .lessThanOrEqualTo(.value(value), .key(key)):
            
            return ["$gte": ["$\(key)".toBSON(), value.toBSON()]]
            
        case let .containsIn(.key(lhs), .key(rhs)):
            
            return ["$in": ["$\(lhs)".toBSON(), "$\(rhs)".toBSON()]]
            
        case let .containsIn(.value(value), .key(key)):
            
            return ["$in": [value.toBSON(), "$\(key)".toBSON()]]
            
        case let .containsIn(.key(key), .value(value)):
            
            return ["$in": ["$\(key)".toBSON(), value.toBSON()]]
            
        case let .notContainsIn(.key(lhs), .key(rhs)):
            
            return ["$not": [["$in": ["$\(lhs)".toBSON(), "$\(rhs)".toBSON()]]]]
            
        case let .notContainsIn(.value(value), .key(key)):
            
            return ["$not": [["$in": [value.toBSON(), "$\(key)".toBSON()]]]]
            
        case let .notContainsIn(.key(key), .value(value)):
            
            return ["$not": [["$in": ["$\(key)".toBSON(), value.toBSON()]]]]
            
        case let .matching(lhs, .key(rhs)):
            
            return ["$regexMatch": ["input": "$\(lhs.key)".toBSON(), "regex": "$\(rhs)".toBSON()]]
            
        case let .matching(lhs, .value(value)):
            
            return ["$regexMatch": ["input": "$\(lhs.key)".toBSON(), "regex": value.toBSON()]]
            
        case let .startsWith(lhs, str, options):
            
            return ["$regexMatch": ["input": "$\(lhs.key)".toBSON(), "regex": "^\(quote(str))".toBSON(), "options": options.stringOptions.toBSON()]]
            
        case let .endsWith(lhs, str, options):
            
            return ["$regexMatch": ["input": "$\(lhs.key)".toBSON(), "regex": "\(quote(str))$".toBSON(), "options": options.stringOptions.toBSON()]]
            
        case let .contains(lhs, str, options):
            
            return ["$regexMatch": ["input": "$\(lhs.key)".toBSON(), "regex": quote(str).toBSON(), "options": options.stringOptions.toBSON()]]
            
        case let .and(list):
            
            let list = list.flatMap { $0._andList ?? [$0] }
            
            switch list.count {
            case 0: throw Database.Error.invalidExpression
            case 1: return try list[0]._expression()
            default: return try ["$and": BSON(list.map { try $0._expression() })]
            }
            
        case let .or(list):
            
            let list = list.flatMap { $0._orList ?? [$0] }
            
            switch list.count {
            case 0: throw Database.Error.invalidExpression
            case 1: return try list[0]._expression()
            default: return try ["$or": BSON(list.map { try $0._expression() })]
            }
            
        default: throw Database.Error.invalidExpression
        }
    }
    
    public func toBSONDocument() throws -> BSONDocument {
        
        switch self {
        case let .not(x):
            
            return try ["$not": BSON(["$expr": BSON(x._expression())])]
            
        case let .equal(.key(key), .value(value)),
             let .equal(.value(value), .key(key)):
            
            let value = value.toBSON()
            
            switch value {
            case .undefined: return [key: ["$exists": false]]
            default: return [key: ["$eq": value]]
            }
            
        case let .notEqual(.key(key), .value(value)),
             let .notEqual(.value(value), .key(key)):
            
            let value = value.toBSON()
            
            switch value {
            case .undefined: return [key: ["$exists": true]]
            default: return [key: ["$ne": value]]
            }
            
        case let .lessThan(.key(key), .value(value)),
             let .greaterThan(.value(value), .key(key)):
            
            return [key: ["$lt": value.toBSON()]]
            
        case let .greaterThan(.key(key), .value(value)),
             let .lessThan(.value(value), .key(key)):
            
            return [key: ["$gt": value.toBSON()]]
            
        case let .lessThanOrEqualTo(.key(key), .value(value)),
             let .greaterThanOrEqualTo(.value(value), .key(key)):
            
            return [key: ["$lte": value.toBSON()]]
            
        case let .greaterThanOrEqualTo(.key(key), .value(value)),
             let .lessThanOrEqualTo(.value(value), .key(key)):
            
            return [key: ["$gte": value.toBSON()]]
            
        case let .containsIn(.value(value), .key(key)):
            
            return [key: ["$in": [value.toBSON()].toBSON()]]
            
        case let .containsIn(.key(key), .value(value)):
            
            return [key: ["$in": value.toBSON()]]
            
        case let .notContainsIn(.value(value), .key(key)):
            
            return [key: ["$nin": [value.toBSON()].toBSON()]]
            
        case let .notContainsIn(.key(key), .value(value)):
            
            return [key: ["$nin": value.toBSON()]]
            
        case let .matching(lhs, .value(value)):
            
            return [lhs.key: ["$regex": value.toBSON()]]
            
        case let .startsWith(lhs, str, options):
            
            return [lhs.key: ["$regex": "^\(quote(str))".toBSON(), "$options": options.stringOptions.toBSON()]]
            
        case let .endsWith(lhs, str, options):
            
            return [lhs.key: ["$regex": "\(quote(str))$".toBSON(), "$options": options.stringOptions.toBSON()]]
            
        case let .contains(lhs, str, options):
            
            return [lhs.key: ["$regex": quote(str).toBSON(), "$options": options.stringOptions.toBSON()]]
            
        case let .and(list):
            
            let list = list.flatMap { $0._andList ?? [$0] }
            
            switch list.count {
            case 0: throw Database.Error.invalidExpression
            case 1: return try list[0].toBSONDocument()
            default: return try ["$and": BSON(list.map { try $0.toBSONDocument() })]
            }
            
        case let .or(list):
            
            let list = list.flatMap { $0._orList ?? [$0] }
            
            switch list.count {
            case 0: throw Database.Error.invalidExpression
            case 1: return try list[0].toBSONDocument()
            default: return try ["$or": BSON(list.map { try $0.toBSONDocument() })]
            }
            
        default: return try ["$expr": BSON(_expression())]
        }
    }
}

@inlinable
public func == (lhs: MongoPredicateKey, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .equal(.key(lhs), .key(rhs))
}

@inlinable
public func != (lhs: MongoPredicateKey, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .notEqual(.key(lhs), .key(rhs))
}

@inlinable
public func < (lhs: MongoPredicateKey, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .lessThan(.key(lhs), .key(rhs))
}

@inlinable
public func > (lhs: MongoPredicateKey, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .greaterThan(.key(lhs), .key(rhs))
}

@inlinable
public func <= (lhs: MongoPredicateKey, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .lessThanOrEqualTo(.key(lhs), .key(rhs))
}

@inlinable
public func >= (lhs: MongoPredicateKey, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .greaterThanOrEqualTo(.key(lhs), .key(rhs))
}

@inlinable
public func == (lhs: MongoPredicateKey, rhs: _OptionalNilComparisonType) -> MongoPredicateExpression {
    return .equal(.key(lhs), .value(BSON.null))
}

@inlinable
public func != (lhs: MongoPredicateKey, rhs: _OptionalNilComparisonType) -> MongoPredicateExpression {
    return .notEqual(.key(lhs), .value(BSON.null))
}

@inlinable
public func == <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: T) -> MongoPredicateExpression {
    return .equal(.key(lhs), .value(rhs))
}

@inlinable
public func != <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: T) -> MongoPredicateExpression {
    return .notEqual(.key(lhs), .value(rhs))
}

@inlinable
public func < <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: T) -> MongoPredicateExpression {
    return .lessThan(.key(lhs), .value(rhs))
}

@inlinable
public func > <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: T) -> MongoPredicateExpression {
    return .greaterThan(.key(lhs), .value(rhs))
}

@inlinable
public func <= <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: T) -> MongoPredicateExpression {
    return .lessThanOrEqualTo(.key(lhs), .value(rhs))
}

@inlinable
public func >= <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: T) -> MongoPredicateExpression {
    return .greaterThanOrEqualTo(.key(lhs), .value(rhs))
}

@inlinable
public func == (lhs: _OptionalNilComparisonType, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .equal(.value(BSON.null), .key(rhs))
}

@inlinable
public func != (lhs: _OptionalNilComparisonType, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .notEqual(.value(BSON.null), .key(rhs))
}

@inlinable
public func == <T: BSONConvertible>(lhs: T, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .equal(.value(lhs), .key(rhs))
}

@inlinable
public func != <T: BSONConvertible>(lhs: T, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .notEqual(.value(lhs), .key(rhs))
}

@inlinable
public func < <T: BSONConvertible>(lhs: T, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .lessThan(.value(lhs), .key(rhs))
}

@inlinable
public func > <T: BSONConvertible>(lhs: T, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .greaterThan(.value(lhs), .key(rhs))
}

@inlinable
public func <= <T: BSONConvertible>(lhs: T, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .lessThanOrEqualTo(.value(lhs), .key(rhs))
}

@inlinable
public func >= <T: BSONConvertible>(lhs: T, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .greaterThanOrEqualTo(.value(lhs), .key(rhs))
}

@inlinable
public func ~= (lhs: NSRegularExpression, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .matching(rhs, .value(lhs))
}

@inlinable
public func ~= (lhs: Regex, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .matching(rhs, .value(lhs))
}

@inlinable
public func ~= (lhs: MongoPredicateKey, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .containsIn(.key(rhs), .key(lhs))
}

@inlinable
public func ~= <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: T) -> MongoPredicateExpression {
    return .containsIn(.value(rhs), .key(lhs))
}

@inlinable
public func ~= <C: Collection>(lhs: C, rhs: MongoPredicateKey) -> MongoPredicateExpression where C.Element: BSONConvertible {
    return .containsIn(.key(rhs), .value(Array(lhs)))
}

@inlinable
public func ~= <T: BSONConvertible>(lhs: Range<T>, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return lhs.lowerBound <= rhs && rhs < lhs.upperBound
}

@inlinable
public func ~= <T: BSONConvertible>(lhs: ClosedRange<T>, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return lhs.lowerBound <= rhs && rhs <= lhs.upperBound
}

@inlinable
public func ~= <T: BSONConvertible>(lhs: PartialRangeFrom<T>, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return lhs.lowerBound <= rhs
}

@inlinable
public func ~= <T: BSONConvertible>(lhs: PartialRangeUpTo<T>, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return rhs < lhs.upperBound
}

@inlinable
public func ~= <T: BSONConvertible>(lhs: PartialRangeThrough<T>, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return rhs <= lhs.upperBound
}

@inlinable
public func =~ (lhs: MongoPredicateKey, rhs: NSRegularExpression) -> MongoPredicateExpression {
    return .matching(lhs, .value(rhs))
}

@inlinable
public func =~ (lhs: MongoPredicateKey, rhs: Regex) -> MongoPredicateExpression {
    return .matching(lhs, .value(rhs))
}

@inlinable
public func =~ (lhs: MongoPredicateKey, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .containsIn(.key(lhs), .key(rhs))
}

@inlinable
public func =~ <T: BSONConvertible>(lhs: T, rhs: MongoPredicateKey) -> MongoPredicateExpression {
    return .containsIn(.value(lhs), .key(rhs))
}

@inlinable
public func =~ <C: Collection>(lhs: MongoPredicateKey, rhs: C) -> MongoPredicateExpression where C.Element: BSONConvertible {
    return .containsIn(.key(lhs), .value(Array(rhs)))
}

@inlinable
public func =~ <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: Range<T>) -> MongoPredicateExpression {
    return rhs.lowerBound <= lhs && lhs < rhs.upperBound
}

@inlinable
public func =~ <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: ClosedRange<T>) -> MongoPredicateExpression {
    return rhs.lowerBound <= lhs && lhs <= rhs.upperBound
}

@inlinable
public func =~ <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: PartialRangeFrom<T>) -> MongoPredicateExpression {
    return rhs.lowerBound <= lhs
}

@inlinable
public func =~ <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: PartialRangeUpTo<T>) -> MongoPredicateExpression {
    return lhs < rhs.upperBound
}

@inlinable
public func =~ <T: BSONConvertible>(lhs: MongoPredicateKey, rhs: PartialRangeThrough<T>) -> MongoPredicateExpression {
    return lhs <= rhs.upperBound
}

@inlinable
public prefix func !(x: MongoPredicateExpression) -> MongoPredicateExpression {
    return .not(x)
}

@inlinable
public func && (lhs: MongoPredicateExpression, rhs: MongoPredicateExpression) -> MongoPredicateExpression {
    return .and([lhs, rhs])
}

@inlinable
public func || (lhs: MongoPredicateExpression, rhs: MongoPredicateExpression) -> MongoPredicateExpression {
    return .or([lhs, rhs])
}
