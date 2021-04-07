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
    
    case raw(SQLRaw)
}

extension SQLPredicateValue {
    
    public func between(from: SQLPredicateValue, to: SQLPredicateValue) -> SQLPredicateExpression {
        return .between(self, from, to)
    }
    
    public func notBetween(from: SQLPredicateValue, to: SQLPredicateValue) -> SQLPredicateExpression {
        return .notBetween(self, from, to)
    }
    
    public func like(_ pattern: String) -> SQLPredicateExpression {
        return .like(self, pattern)
    }
    
    public func notLike(_ pattern: String) -> SQLPredicateExpression {
        return .notLike(self, pattern)
    }
}

extension SQLRaw.StringInterpolation {
    
    mutating func appendInterpolation(_ value: SQLPredicateValue) {
        switch value {
        case let .name(name): self.appendLiteral(name)
        case let .value(value): self.appendInterpolation(value)
        case let .raw(raw): self.appendInterpolation(raw)
        }
    }
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
