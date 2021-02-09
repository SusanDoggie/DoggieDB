//
//  SQLRaw.swift
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

enum SQLRawComponent: Hashable {
    
    case string(String)
    
    case boolean(Bool)
    
    case signed(Int64)
    
    case unsigned(UInt64)
    
    case number(Double)
    
    case decimal(Decimal)
    
    case bind(DBData)
}

public struct SQLRaw: Hashable {
    
    var components: [SQLRawComponent]
    
    init(components: [SQLRawComponent]) {
        self.components = components
    }
    
    public init<S: StringProtocol>(_ string: S) {
        self.components = [.string(String(string))]
    }
}

extension SQLRaw: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension SQLRaw: ExpressibleByStringInterpolation {
    
    public struct StringInterpolation: StringInterpolationProtocol {
        
        var components: [SQLRawComponent]
        
        public init(literalCapacity: Int, interpolationCount: Int) {
            self.components = []
        }
        
        public mutating func appendLiteral(_ literal: String) {
            self.components.append(.string(literal))
        }
        
        public mutating func appendInterpolation<T: StringProtocol>(literal value: T) {
            self.components.append(.string(String(value)))
        }
        
        public mutating func appendInterpolation<T: DBDataConvertible>(_ value: T) {
            let value = value.toDBData()
            switch value.base {
            case let .boolean(value): self.components.append(.boolean(value))
            case let .signed(value): self.components.append(.signed(value))
            case let .unsigned(value): self.components.append(.unsigned(value))
            case let .number(value): self.components.append(value.isFinite ? .number(value) : .bind(DBData(value)))
            case let .decimal(value): self.components.append(value.isFinite ? .decimal(value) : .bind(DBData(value)))
            default: self.components.append(.bind(value))
            }
        }
        
        public mutating func appendInterpolation<T: DBDataConvertible>(bind value: T) {
            self.components.append(.bind(value.toDBData()))
        }
    }
    
    public init(stringInterpolation: StringInterpolation) {
        self.components = stringInterpolation.components
    }
}

extension SQLRaw {
    
    public mutating func append(_ other: SQLRaw) {
        self.components.append(contentsOf: other.components)
    }
}

extension Array where Element == SQLRaw {
    
    public func joined(separator: SQLRaw) -> SQLRaw {
        return self.reduce { $0 + separator + $1 } ?? ""
    }
}

public func +(lhs: SQLRaw, rhs: SQLRaw) -> SQLRaw {
    return SQLRaw(components: lhs.components + rhs.components)
}

public func +=(lhs: inout SQLRaw, rhs: SQLRaw) {
    lhs.components += rhs.components
}
