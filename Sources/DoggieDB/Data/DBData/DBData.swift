//
//  QueryData.swift
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

public enum DBDataType: Hashable {
    
    case null
    case boolean
    case string
    case regex
    case signed
    case unsigned
    case number
    case decimal
    case date
    case binary
    case uuid
    case array
    case dictionary
}

public struct DBData {
    
    indirect enum Base {
        case null
        case boolean(Bool)
        case string(String)
        case regex(Regex)
        case signed(Int64)
        case unsigned(UInt64)
        case number(Double)
        case decimal(Decimal)
        case date(DateComponents)
        case binary(Data)
        case uuid(UUID)
        case array([DBData])
        case dictionary([String: DBData])
    }
    
    let base: Base
    
    public init(_ value: Bool) {
        self.base = .boolean(value)
    }
    
    public init(_ value: String) {
        self.base = .string(value)
    }
    
    public init<S: StringProtocol>(_ value: S) {
        self.base = .string(String(value))
    }
    
    public init(_ value: Regex) {
        self.base = .regex(value)
    }
    
    public init(_ value: NSRegularExpression) {
        self.base = .regex(Regex(value))
    }
    
    public init<T: FixedWidthInteger & SignedInteger>(_ value: T) {
        self.base = .signed(Int64(value))
    }
    
    public init<T: FixedWidthInteger & UnsignedInteger>(_ value: T) {
        self.base = .unsigned(UInt64(value))
    }
    
    public init<T: BinaryFloatingPoint>(_ value: T) {
        self.base = .number(Double(value))
    }
    
    public init(_ value: Decimal) {
        self.base = .decimal(value)
    }
    
    public init(
        _ value: Date,
        calendar: Calendar = Calendar(identifier: .iso8601),
        timeZone: TimeZone = TimeZone(identifier: "UTC")!
    ) {
        self.base = .date(calendar.dateComponents(in: timeZone, from: value))
    }
    
    public init(_ value: DateComponents) {
        self.base = .date(value)
    }
    
    public init(_ binary: Data) {
        self.base = .binary(binary)
    }
    
    public init(_ uuid: UUID) {
        self.base = .uuid(uuid)
    }
    
    public init<S: Sequence>(_ elements: S) where S.Element: DBDataConvertible {
        self.base = .array(elements.map { $0.toDBData() })
    }
    
    public init<Value: DBDataConvertible>(_ elements: [String: Value]) {
        self.base = .dictionary(elements.mapValues { $0.toDBData() })
    }
}

extension DBData: ExpressibleByNilLiteral {
    
    public init(nilLiteral value: Void) {
        self.base = .null
    }
}

extension DBData: ExpressibleByBooleanLiteral {
    
    public init(booleanLiteral value: BooleanLiteralType) {
        self.init(value)
    }
}

extension DBData: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
}

extension DBData: ExpressibleByFloatLiteral {
    
    public init(floatLiteral value: FloatLiteralType) {
        self.init(value)
    }
}

extension DBData: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}

extension DBData: ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: DBData ...) {
        self.init(elements)
    }
}

extension DBData: ExpressibleByDictionaryLiteral {
    
    public init(dictionaryLiteral elements: (String, DBData) ...) {
        self.init(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension DBData: CustomStringConvertible {
    
    public var description: String {
        switch self.base {
        case .null: return "nil"
        case let .boolean(value): return "\(value)"
        case let .string(value): return "\"\(value.escaped(asASCII: false))\""
        case let .regex(value): return "\(value)"
        case let .signed(value): return "\(value)"
        case let .unsigned(value): return "\(value)"
        case let .number(value): return "\(value)"
        case let .decimal(value): return "\(value)"
        case let .date(value): return value.date.map { "\($0)" } ?? "\(value)"
        case let .binary(value): return "\(value)"
        case let .uuid(value): return "\(value)"
        case let .array(value): return "\(value)"
        case let .dictionary(value): return "\(value)"
        }
    }
}

extension DBData: Hashable {
    
    public static func == (lhs: DBData, rhs: DBData) -> Bool {
        switch (lhs.base, rhs.base) {
        case (.null, .null): return true
        case let (.boolean(lhs), .boolean(rhs)): return lhs == rhs
        case let (.string(lhs), .string(rhs)): return lhs == rhs
        case let (.regex(lhs), .regex(rhs)): return lhs == rhs
        case let (.signed(lhs), .signed(rhs)): return lhs == rhs
        case let (.unsigned(lhs), .unsigned(rhs)): return lhs == rhs
        case let (.number(lhs), .number(rhs)): return lhs == rhs
        case let (.date(lhs), .date(rhs)): return lhs == rhs
        case let (.binary(lhs), .binary(rhs)): return lhs == rhs
        case let (.uuid(lhs), .uuid(rhs)): return lhs == rhs
        case let (.array(lhs), .array(rhs)): return lhs == rhs
        case let (.dictionary(lhs), .dictionary(rhs)): return lhs == rhs
        default: return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        switch self.base {
        case let .boolean(value): hasher.combine(value)
        case let .string(value): hasher.combine(value)
        case let .regex(value): hasher.combine(value)
        case let .signed(value): hasher.combine(value)
        case let .unsigned(value): hasher.combine(value)
        case let .number(value): hasher.combine(value)
        case let .date(value): hasher.combine(value)
        case let .binary(value): hasher.combine(value)
        case let .uuid(value): hasher.combine(value)
        case let .array(value): hasher.combine(value)
        case let .dictionary(value): hasher.combine(value)
        default: break
        }
    }
}

extension DBData {
    
    public var type: DBDataType {
        switch self.base {
        case .null: return .null
        case .boolean: return .boolean
        case .string: return .string
        case .regex: return .regex
        case .signed: return .signed
        case .unsigned: return .unsigned
        case .number: return .number
        case .decimal: return .decimal
        case .date: return .date
        case .binary: return .binary
        case .uuid: return .uuid
        case .array: return .array
        case .dictionary: return .dictionary
        }
    }
    
    public var isNil: Bool {
        switch self.base {
        case .null: return true
        default: return false
        }
    }
    
    public var isBool: Bool {
        switch self.base {
        case .boolean: return true
        default: return false
        }
    }
    
    public var isString: Bool {
        switch self.base {
        case .string: return true
        default: return false
        }
    }
    
    public var isRegex: Bool {
        switch self.base {
        case .regex: return true
        default: return false
        }
    }
    
    public var isArray: Bool {
        switch self.base {
        case .array: return true
        default: return false
        }
    }
    
    public var isObject: Bool {
        switch self.base {
        case .dictionary: return true
        default: return false
        }
    }
    
    public var isSigned: Bool {
        switch self.base {
        case .signed: return true
        default: return false
        }
    }
    
    public var isUnsigned: Bool {
        switch self.base {
        case .unsigned: return true
        default: return false
        }
    }
    
    public var isNumber: Bool {
        switch self.base {
        case .number: return true
        default: return false
        }
    }
    
    public var isDecimal: Bool {
        switch self.base {
        case .decimal: return true
        default: return false
        }
    }
    
    public var isNumeric: Bool {
        switch self.base {
        case .signed: return true
        case .unsigned: return true
        case .number: return true
        default: return false
        }
    }
    
    public var isDate: Bool {
        switch self.base {
        case .date: return true
        default: return false
        }
    }
    
    public var isBinary: Bool {
        switch self.base {
        case .binary: return true
        default: return false
        }
    }
    
    public var isUUID: Bool {
        switch self.base {
        case .uuid: return true
        default: return false
        }
    }
}

extension DBData {
    
    public var boolValue: Bool? {
        switch self.base {
        case let .boolean(value): return value
        default: return nil
        }
    }
    
    public var int8Value: Int8? {
        switch self.base {
        case let .signed(value): return Int8(exactly: value)
        case let .unsigned(value): return Int8(exactly: value)
        case let .number(value): return Int8(exactly: value)
        case let .decimal(value): return Int64(exactly: value).flatMap { Int8(exactly: $0) }
        case let .string(string): return Int8(string)
        default: return nil
        }
    }
    
    public var uint8Value: UInt8? {
        switch self.base {
        case let .signed(value): return UInt8(exactly: value)
        case let .unsigned(value): return UInt8(exactly: value)
        case let .number(value): return UInt8(exactly: value)
        case let .decimal(value): return UInt64(exactly: value).flatMap { UInt8(exactly: $0) }
        case let .string(string): return UInt8(string)
        default: return nil
        }
    }
    
    public var int16Value: Int16? {
        switch self.base {
        case let .signed(value): return Int16(exactly: value)
        case let .unsigned(value): return Int16(exactly: value)
        case let .number(value): return Int16(exactly: value)
        case let .decimal(value): return Int64(exactly: value).flatMap { Int16(exactly: $0) }
        case let .string(string): return Int16(string)
        default: return nil
        }
    }
    
    public var uint16Value: UInt16? {
        switch self.base {
        case let .signed(value): return UInt16(exactly: value)
        case let .unsigned(value): return UInt16(exactly: value)
        case let .number(value): return UInt16(exactly: value)
        case let .decimal(value): return UInt64(exactly: value).flatMap { UInt16(exactly: $0) }
        case let .string(string): return UInt16(string)
        default: return nil
        }
    }
    
    public var int32Value: Int32? {
        switch self.base {
        case let .signed(value): return Int32(exactly: value)
        case let .unsigned(value): return Int32(exactly: value)
        case let .number(value): return Int32(exactly: value)
        case let .decimal(value): return Int64(exactly: value).flatMap { Int32(exactly: $0) }
        case let .string(string): return Int32(string)
        default: return nil
        }
    }
    
    public var uint32Value: UInt32? {
        switch self.base {
        case let .signed(value): return UInt32(exactly: value)
        case let .unsigned(value): return UInt32(exactly: value)
        case let .number(value): return UInt32(exactly: value)
        case let .decimal(value): return UInt64(exactly: value).flatMap { UInt32(exactly: $0) }
        case let .string(string): return UInt32(string)
        default: return nil
        }
    }
    
    public var int64Value: Int64? {
        switch self.base {
        case let .signed(value): return value
        case let .unsigned(value): return Int64(exactly: value)
        case let .number(value): return Int64(exactly: value)
        case let .decimal(value): return Int64(exactly: value)
        case let .string(string): return Int64(string)
        default: return nil
        }
    }
    
    public var uint64Value: UInt64? {
        switch self.base {
        case let .signed(value): return UInt64(exactly: value)
        case let .unsigned(value): return value
        case let .number(value): return UInt64(exactly: value)
        case let .decimal(value): return UInt64(exactly: value)
        case let .string(string): return UInt64(string)
        default: return nil
        }
    }
    
    public var intValue: Int? {
        switch self.base {
        case let .signed(value): return Int(exactly: value)
        case let .unsigned(value): return Int(exactly: value)
        case let .number(value): return Int(exactly: value)
        case let .decimal(value): return Int64(exactly: value).flatMap { Int(exactly: $0) }
        case let .string(string): return Int(string)
        default: return nil
        }
    }
    
    public var uintValue: UInt? {
        switch self.base {
        case let .signed(value): return UInt(exactly: value)
        case let .unsigned(value): return UInt(exactly: value)
        case let .number(value): return UInt(exactly: value)
        case let .decimal(value): return UInt64(exactly: value).flatMap { UInt(exactly: $0) }
        case let .string(string): return UInt(string)
        default: return nil
        }
    }
    
    public var floatValue: Float? {
        switch self.base {
        case let .signed(value): return Float(exactly: value)
        case let .unsigned(value): return Float(exactly: value)
        case let .number(value): return Float(value)
        case let .decimal(value): return Double(exactly: value).flatMap { Float(exactly: $0) }
        case let .string(string): return Float(string)
        default: return nil
        }
    }
    
    public var doubleValue: Double? {
        switch self.base {
        case let .signed(value): return Double(exactly: value)
        case let .unsigned(value): return Double(exactly: value)
        case let .number(value): return value
        case let .decimal(value): return Double(exactly: value)
        case let .string(string): return Double(string)
        default: return nil
        }
    }
    
    public var decimalValue: Decimal? {
        switch self.base {
        case let .signed(value): return Decimal(value)
        case let .unsigned(value): return Decimal(value)
        case let .number(value): return Decimal(value)
        case let .decimal(value): return value
        case let .string(string): return Decimal(string: string)
        default: return nil
        }
    }
    
    public var string: String? {
        switch self.base {
        case let .string(value): return value
        default: return nil
        }
    }
    
    public var regex: Regex? {
        switch self.base {
        case let .regex(value): return value
        default: return nil
        }
    }
    
    public var date: Date? {
        switch self.base {
        case let .date(value): return value.date
        default: return nil
        }
    }
    
    public var dateComponents: DateComponents? {
        switch self.base {
        case let .date(value): return value
        default: return nil
        }
    }
    
    public var binary: Data? {
        switch self.base {
        case let .binary(value): return value
        default: return nil
        }
    }
    
    public var uuid: UUID? {
        switch self.base {
        case let .uuid(value): return value
        case let .string(string): return UUID(uuidString: string)
        case let .binary(data):
            guard data.count == 16 else { return nil }
            return UUID(uuid: data.load(as: uuid_t.self))
        default: return nil
        }
    }
    
    public var dictionary: [String: DBData]? {
        switch self.base {
        case let .dictionary(value): return value
        default: return nil
        }
    }
}

extension DBData {
    
    public var count: Int {
        switch self.base {
        case let .array(value): return value.count
        case let .dictionary(value): return value.count
        default: fatalError("Not an array or object.")
        }
    }
    
    public subscript(index: Int) -> DBData {
        get {
            guard 0..<count ~= index else { return nil }
            switch self.base {
            case let .array(value): return value[index]
            default: return nil
            }
        }
        set {
            switch self.base {
            case var .array(value):
                
                if index >= value.count {
                    value.append(contentsOf: repeatElement(nil, count: index - value.count + 1))
                }
                value[index] = newValue
                self = DBData(value)
                
            default: fatalError("Not an array.")
            }
        }
    }
    
    public var keys: Dictionary<String, DBData>.Keys {
        switch self.base {
        case let .dictionary(value): return value.keys
        default: return [:].keys
        }
    }
    
    public subscript(key: String) -> DBData {
        get {
            switch self.base {
            case let .dictionary(value): return value[key] ?? nil
            default: return nil
            }
        }
        set {
            switch self.base {
            case var .dictionary(value):
                
                value[key] = newValue.isNil ? nil : newValue
                self = DBData(value)
                
            default: fatalError("Not an object.")
            }
        }
    }
}
