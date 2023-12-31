//
//  SQLRaw.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2024 Susan Cheng. All rights reserved.
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

enum SQLRawComponent: Hashable, Sendable {
    
    case identifier(String)
    
    case string(String)
    
    case null
    
    case boolean(Bool)
    
    case signed(Int64)
    
    case unsigned(UInt64)
    
    case number(Double)
    
    case decimal(Decimal)
    
    case bind(DBData)
}

extension SQLRawComponent {
    
    init(_ value: DBData.Number) {
        switch value {
        case let .signed(value): self = .signed(value)
        case let .unsigned(value): self = .unsigned(value)
        case let .number(value): self = value.isFinite ? .number(value) : .bind(DBData(value))
        case let .decimal(value): self = value.isFinite ? .decimal(value) : .bind(DBData(value))
        }
    }
    
    init(_ value: DBData) {
        switch value {
        case .null: self = .null
        case let .boolean(value): self = .boolean(value)
        case let .number(value): self.init(value)
        default: self = .bind(value)
        }
    }
}

extension SQLRawComponent {
    
    var isEmpty: Bool {
        switch self {
        case let .string(string): return string.isEmpty
        default: return false
        }
    }
}

extension Array where Element == SQLRawComponent {
    
    func simplify() -> [SQLRawComponent] {
        
        var components: [SQLRawComponent] = []
        var last_string = ""
        
        for component in self {
            switch component {
            case let .string(string): last_string.append(string)
            default:
                if !last_string.isEmpty {
                    components.append(.string(last_string))
                    last_string = ""
                }
                components.append(component)
            }
        }
        
        if !last_string.isEmpty {
            components.append(.string(last_string))
        }
        
        return components
    }
}

public struct SQLRaw: Hashable, Sendable {
    
    var components: [SQLRawComponent]
    
    init(components: [SQLRawComponent]) {
        self.components = components.simplify()
    }
    
    public init() {
        self.components = []
    }
    
    public init<S: StringProtocol>(_ string: S) {
        self.components = string.isEmpty ? [] : [.string(String(string))]
    }
    
    public init(_ value: DBData) {
        self.components = [SQLRawComponent(value)]
    }
    
    public init(bind value: DBData) {
        self.components = [.bind(value)]
    }
}

extension SQLRaw: ExpressibleByStringInterpolation {
    
    public init(stringLiteral value: String) {
        self.init(value)
    }
    
    public struct StringInterpolation: StringInterpolationProtocol, Sendable {
        
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
        
        public mutating func appendInterpolation<T: StringProtocol>(identifier: T) {
            
            if let split = identifier.firstIndex(of: ".") {
                
                let schema = identifier.prefix(upTo: split)
                let name = identifier.suffix(from: split).dropFirst()
                
                self.components.append(.identifier(String(schema)))
                self.components.append(.string("."))
                self.components.append(.identifier(String(name)))
                
            } else {
                
                self.components.append(.identifier(String(identifier)))
            }
        }
        
        public mutating func appendInterpolation(_ raw: SQLRaw) {
            self.components.append(contentsOf: raw.components)
        }
        
        public mutating func appendInterpolation(_ value: DBData) {
            self.components.append(SQLRawComponent(value))
        }
        
        public mutating func appendInterpolation<T: DBDataConvertible>(_ value: T) {
            self.components.append(SQLRawComponent(value.toDBData()))
        }
        
        public mutating func appendInterpolation(bind value: DBData) {
            self.components.append(.bind(value))
        }
        
        public mutating func appendInterpolation<T: DBDataConvertible>(bind value: T) {
            self.components.append(.bind(value.toDBData()))
        }
    }
    
    public init(stringInterpolation: StringInterpolation) {
        self.components = stringInterpolation.components.simplify()
    }
}

extension SQLRaw: CustomStringConvertible {
    
    public var description: String {
        
        var result = ""
        
        for component in components {
            switch component {
            case let .identifier(value): result.append("\"\(value)\"")
            case let .string(value): result.append(value)
            case .null: result.append("NULL")
            case let .boolean(value): result.append(value ? "TRUE" : "FALSE")
            case let .signed(value): result.append("\(value)")
            case let .unsigned(value): result.append("\(value)")
            case let .number(value): result.append("\(value)")
            case let .decimal(value): result.append("\(value)")
            case let .bind(value): result.append("${\(value)}")
            }
        }
        
        return result
    }
}

extension SQLRaw {
    
    public var isEmpty: Bool {
        return self.components.isEmpty
    }
}

extension Character {
    
    fileprivate var isWhitespaceOrNewline: Bool {
        return self.isNewline || self.isWhitespace
    }
}

extension SQLRaw {
    
    fileprivate var first_char: Character? {
        guard case let .string(string) = self.components.first else { return nil }
        return string.first
    }
    
    fileprivate var last_char: Character? {
        guard case let .string(string) = self.components.last else { return nil }
        return string.last
    }
}

extension SQLRaw {
    
    public mutating func appendLiteral<T: StringProtocol>(_ value: T) {
        if case var .string(last_string) = self.components.last {
            last_string.append(String(value))
            self.components[self.components.count - 1] = .string(last_string)
        } else {
            self.components.append(.string(String(value)))
        }
    }
    
    public mutating func append(_ other: SQLRaw) {
        if self.last_char?.isWhitespaceOrNewline != true && other.first_char?.isWhitespaceOrNewline != true {
            self.components.append(.string(" "))
        }
        self.components.append(contentsOf: other.components)
        self.components = self.components.simplify()
    }
}

extension Collection where Element == SQLRaw {
    
    public func joined(separator: SQLRaw) -> SQLRaw {
        return SQLRaw(components: self.reduce([]) { $0.isEmpty ? $1.components : $0 + separator.components + $1.components })
    }
}

public func +(lhs: SQLRaw, rhs: SQLRaw) -> SQLRaw {
    var result = lhs
    result.append(rhs)
    return result
}

public func +=(lhs: inout SQLRaw, rhs: SQLRaw) {
    lhs.append(rhs)
}
