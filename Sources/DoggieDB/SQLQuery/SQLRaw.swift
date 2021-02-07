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

enum SQLRawComponent {
    
    case string(String)
    
    case bool(Bool)
    
    case bind(DBData)
}

public struct SQLRaw {
    
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
        
        public mutating func appendInterpolation(literal value: String) {
            self.components.append(.string(value))
        }
        
        public mutating func appendInterpolation(_ value: Bool) {
            self.components.append(.bool(value))
        }
        
        public mutating func appendInterpolation<T: DBDataConvertible>(_ value: T) {
            self.components.append(.bind(value.toDBData()))
        }
    }
    
    public init(stringInterpolation: StringInterpolation) {
        self.components = stringInterpolation.components
    }
}

extension SQLRaw {
    
    public static func +(lhs: SQLRaw, rhs: SQLRaw) -> SQLRaw {
        return SQLRaw(components: lhs.components + rhs.components)
    }
}

extension Array where Element == SQLRaw {
    
    public func joined(separator: String) -> SQLRaw {
        return self.reduce { $0 + SQLRaw(separator) + $1 } ?? ""
    }
}
