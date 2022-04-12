//
//  DBData.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2022 Susan Cheng. All rights reserved.
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
public enum DBData: Hashable, Sendable {
    
    case null
    
    case boolean(Bool)
    
    case string(String)
    
    case number(Number)
    
    case timestamp(Date)
    
    case date(DateComponents)
    
    case binary(Data)
    
    case uuid(UUID)
    
    case objectID(BSONObjectID)
    
    case array([DBData])
    
    case dictionary([String: DBData])
}

extension DBData {
    
    @inlinable
    public init(_ value: Bool) {
        self = .boolean(value)
    }
    
    @inlinable
    public init(_ value: String) {
        self = .string(value)
    }
    
    @inlinable
    public init<S: StringProtocol>(_ value: S) {
        self = .string(String(value))
    }
    
    @inlinable
    public init<T: FixedWidthInteger & SignedInteger>(_ value: T) {
        self = .number(Number(value))
    }
    
    @inlinable
    public init<T: FixedWidthInteger & UnsignedInteger>(_ value: T) {
        self = .number(Number(value))
    }
    
    @inlinable
    public init<T: BinaryFloatingPoint>(_ value: T) {
        self = .number(Number(value))
    }
    
    @inlinable
    public init(_ value: Decimal) {
        self = .number(Number(value))
    }
    
    @inlinable
    public init(_ value: Number) {
        self = .number(value)
    }
    
    @inlinable
    public init(_ value: Date) {
        self = .timestamp(value)
    }
    
    @inlinable
    public init(_ value: DateComponents) {
        self = .date(value)
    }
    
    @inlinable
    public init(_ binary: Data) {
        self = .binary(binary)
    }
    
    @inlinable
    public init(_ binary: ByteBuffer) {
        self = .binary(binary.data)
    }
    
    @inlinable
    public init(_ binary: ByteBufferView) {
        self = .binary(Data(binary))
    }
    
    @inlinable
    public init(_ uuid: UUID) {
        self = .uuid(uuid)
    }
    
    @inlinable
    public init(_ objectID: BSONObjectID) {
        self = .objectID(objectID)
    }
    
    @inlinable
    public init<Wrapped: DBDataConvertible>(_ value: Wrapped?) {
        self = value.toDBData()
    }
    
    @inlinable
    public init<S: Sequence>(_ elements: S) where S.Element: DBDataConvertible {
        self = .array(elements.map { $0.toDBData() })
    }
    
    @inlinable
    public init<Value: DBDataConvertible>(_ elements: [String: Value]) {
        self = .dictionary(elements.mapValues { $0.toDBData() })
    }
    
    @inlinable
    public init<Value: DBDataConvertible>(_ elements: OrderedDictionary<String, Value>) {
        self = .dictionary(Dictionary(elements.mapValues { $0.toDBData() }))
    }
}

extension DBData: ExpressibleByNilLiteral {
    
    @inlinable
    public init(nilLiteral value: Void) {
        self = .null
    }
}

extension DBData: ExpressibleByBooleanLiteral {
    
    @inlinable
    public init(booleanLiteral value: BooleanLiteralType) {
        self.init(value)
    }
}

extension DBData: ExpressibleByIntegerLiteral {
    
    @inlinable
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
}

extension DBData: ExpressibleByFloatLiteral {
    
    @inlinable
    public init(floatLiteral value: FloatLiteralType) {
        self.init(value)
    }
}

extension DBData: ExpressibleByStringInterpolation {
    
    @inlinable
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    @inlinable
    public init(stringInterpolation: String.StringInterpolation) {
        self.init(String(stringInterpolation: stringInterpolation))
    }
}

extension DBData: ExpressibleByArrayLiteral {
    
    @inlinable
    public init(arrayLiteral elements: DBData ...) {
        self.init(elements)
    }
}

extension DBData: ExpressibleByDictionaryLiteral {
    
    @inlinable
    public init(dictionaryLiteral elements: (String, DBData) ...) {
        self.init(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension DBData: CustomStringConvertible {
    
    @inlinable
    public var description: String {
        switch self {
        case .null: return "nil"
        case let .boolean(value): return "\(value)"
        case let .string(value): return "\"\(value.escaped(asASCII: false))\""
        case let .number(value): return "\(value)"
        case let .timestamp(value): return "\(value)"
        case let .date(value):
            let calendar = value.calendar ?? Calendar.iso8601
            return calendar.date(from: value).map { "\($0)" } ?? "\(value)"
        case let .binary(value): return "\(value)"
        case let .uuid(value): return "\(value)"
        case let .objectID(value): return "\(value)"
        case let .array(value): return "\(value)"
        case let .dictionary(value): return "\(value)"
        }
    }
}

extension DBData {
    
    @inlinable
    public var isNil: Bool {
        switch self {
        case .null: return true
        default: return false
        }
    }
    
    @inlinable
    public var isBool: Bool {
        switch self {
        case .boolean: return true
        default: return false
        }
    }
    
    @inlinable
    public var isString: Bool {
        switch self {
        case .string: return true
        default: return false
        }
    }
    
    @inlinable
    public var isArray: Bool {
        switch self {
        case .array: return true
        default: return false
        }
    }
    
    @inlinable
    public var isObject: Bool {
        switch self {
        case .dictionary: return true
        default: return false
        }
    }
    
    @inlinable
    public var isNumber: Bool {
        switch self {
        case .number: return true
        default: return false
        }
    }
    
    @inlinable
    public var isTimestamp: Bool {
        switch self {
        case .timestamp: return true
        default: return false
        }
    }
    
    @inlinable
    public var isDate: Bool {
        switch self {
        case .timestamp: return true
        case .date: return true
        default: return false
        }
    }
    
    @inlinable
    public var isBinary: Bool {
        switch self {
        case .binary: return true
        default: return false
        }
    }
    
    @inlinable
    public var isUUID: Bool {
        switch self {
        case .uuid: return true
        default: return false
        }
    }
    
    @inlinable
    public var isObjectID: Bool {
        switch self {
        case .objectID: return true
        default: return false
        }
    }
}

extension DBData {
    
    @inlinable
    public var boolValue: Bool? {
        switch self {
        case let .boolean(value): return value
        default: return nil
        }
    }
    
    @inlinable
    public var int8Value: Int8? {
        switch self {
        case let .number(value): return value.int8Value
        case let .string(string): return Int8(string)
        default: return nil
        }
    }
    
    @inlinable
    public var uint8Value: UInt8? {
        switch self {
        case let .number(value): return value.uint8Value
        case let .string(string): return UInt8(string)
        default: return nil
        }
    }
    
    @inlinable
    public var int16Value: Int16? {
        switch self {
        case let .number(value): return value.int16Value
        case let .string(string): return Int16(string)
        default: return nil
        }
    }
    
    @inlinable
    public var uint16Value: UInt16? {
        switch self {
        case let .number(value): return value.uint16Value
        case let .string(string): return UInt16(string)
        default: return nil
        }
    }
    
    @inlinable
    public var int32Value: Int32? {
        switch self {
        case let .number(value): return value.int32Value
        case let .string(string): return Int32(string)
        default: return nil
        }
    }
    
    @inlinable
    public var uint32Value: UInt32? {
        switch self {
        case let .number(value): return value.uint32Value
        case let .string(string): return UInt32(string)
        default: return nil
        }
    }
    
    @inlinable
    public var int64Value: Int64? {
        switch self {
        case let .number(value): return value.int64Value
        case let .string(string): return Int64(string)
        default: return nil
        }
    }
    
    @inlinable
    public var uint64Value: UInt64? {
        switch self {
        case let .number(value): return value.uint64Value
        case let .string(string): return UInt64(string)
        default: return nil
        }
    }
    
    @inlinable
    public var intValue: Int? {
        switch self {
        case let .number(value): return value.intValue
        case let .string(string): return Int(string)
        default: return nil
        }
    }
    
    @inlinable
    public var uintValue: UInt? {
        switch self {
        case let .number(value): return value.uintValue
        case let .string(string): return UInt(string)
        default: return nil
        }
    }
    
    @inlinable
    public var floatValue: Float? {
        switch self {
        case let .number(value): return value.floatValue
        case let .string(string): return Float(string)
        default: return nil
        }
    }
    
    @inlinable
    public var doubleValue: Double? {
        switch self {
        case let .number(value): return value.doubleValue
        case let .string(string): return Double(string)
        default: return nil
        }
    }
    
    @inlinable
    public var decimalValue: Decimal? {
        switch self {
        case let .number(value): return value.decimalValue
        case let .string(string): return Decimal(exactly: string)
        default: return nil
        }
    }
    
    @inlinable
    public var numberValue: Number? {
        switch self {
        case let .number(value): return value
        default: return nil
        }
    }
    
    @inlinable
    public var string: String? {
        switch self {
        case let .string(value): return value
        case let .binary(value): return String(bytes: value, encoding: .utf8)
        default: return nil
        }
    }
    
    @inlinable
    public var date: Date? {
        switch self {
        case let .timestamp(value): return value
        case let .date(value):
            
            let calendar = value.calendar ?? Calendar.iso8601
            return calendar.date(from: value)
            
        case let .string(value): return value.iso8601
        default: return nil
        }
    }
    
    @inlinable
    public var dateComponents: DateComponents? {
        switch self {
        case let .timestamp(value): return Calendar.iso8601.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: value)
        case let .date(value): return value
        case let .string(value): return value.iso8601.map { Calendar.iso8601.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: $0) }
        default: return nil
        }
    }
    
    @inlinable
    public var binary: Data? {
        switch self {
        case let .binary(value): return value
        default: return nil
        }
    }
    
    @inlinable
    public var uuid: UUID? {
        switch self {
        case let .uuid(value): return value
        case let .string(string): return string.count == 32 ? UUID(hexString: string) : UUID(uuidString: string)
        case let .binary(data):
            guard data.count == 16 else { return nil }
            return UUID(uuid: data.load(as: uuid_t.self))
        default: return nil
        }
    }
    
    @inlinable
    public var objectID: BSONObjectID? {
        switch self {
        case let .objectID(value): return value
        case let .string(string): return try? BSONObjectID(string)
        default: return nil
        }
    }
    
    @inlinable
    public var array: [DBData]? {
        switch self {
        case let .array(value): return value
        default: return nil
        }
    }
    
    @inlinable
    public var dictionary: [String: DBData]? {
        switch self {
        case let .dictionary(value): return value
        default: return nil
        }
    }
}

extension DBData {
    
    @inlinable
    public var count: Int {
        switch self {
        case let .array(value): return value.count
        case let .dictionary(value): return value.count
        default: fatalError("Not an array or object.")
        }
    }
    
    @inlinable
    public subscript(index: Int) -> DBData {
        get {
            guard 0..<count ~= index else { return nil }
            switch self {
            case let .array(value): return value[index]
            default: return nil
            }
        }
        set {
            switch self {
            case var .array(value):
                
                if index >= value.count {
                    value.append(contentsOf: repeatElement(nil, count: index - value.count + 1))
                }
                value[index] = newValue
                self = .array(value)
                
            default: fatalError("Not an array.")
            }
        }
    }
    
    @inlinable
    public var keys: Dictionary<String, DBData>.Keys {
        switch self {
        case let .dictionary(value): return value.keys
        default: return [:].keys
        }
    }
    
    @inlinable
    public subscript(key: String) -> DBData {
        get {
            switch self {
            case let .dictionary(value): return value[key] ?? nil
            default: return nil
            }
        }
        set {
            switch self {
            case var .dictionary(value):
                
                value[key] = newValue.isNil ? nil : newValue
                self = .dictionary(value)
                
            default: fatalError("Not an object.")
            }
        }
    }
}
