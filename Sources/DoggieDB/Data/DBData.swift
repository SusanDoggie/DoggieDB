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

@frozen
public struct DBData {
    
    @usableFromInline
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
    
    @usableFromInline
    let base: Base
    
    @inlinable
    public init(_ value: Bool) {
        self.base = .boolean(value)
    }
    
    @inlinable
    public init(_ value: String) {
        self.base = .string(value)
    }
    
    @inlinable
    public init<S: StringProtocol>(_ value: S) {
        self.base = .string(String(value))
    }
    
    @inlinable
    public init(_ value: Regex) {
        self.base = .regex(value)
    }
    
    @inlinable
    public init(_ value: NSRegularExpression) {
        self.base = .regex(Regex(value))
    }
    
    @inlinable
    public init<T: FixedWidthInteger & SignedInteger>(_ value: T) {
        self.base = .signed(Int64(value))
    }
    
    @inlinable
    public init<T: FixedWidthInteger & UnsignedInteger>(_ value: T) {
        self.base = .unsigned(UInt64(value))
    }
    
    @inlinable
    public init<T: BinaryFloatingPoint>(_ value: T) {
        self.base = .number(Double(value))
    }
    
    @inlinable
    public init(_ value: Decimal) {
        self.base = .decimal(value)
    }
    
    @inlinable
    public init(
        _ value: Date,
        calendar: Calendar = Calendar(identifier: .iso8601),
        timeZone: TimeZone = TimeZone(identifier: "UTC")!
    ) {
        self.base = .date(calendar.dateComponents(in: timeZone, from: value))
    }
    
    @inlinable
    public init(_ value: DateComponents) {
        self.base = .date(value)
    }
    
    @inlinable
    public init(_ binary: Data) {
        self.base = .binary(binary)
    }
    
    @inlinable
    public init(_ uuid: UUID) {
        self.base = .uuid(uuid)
    }
    
    @inlinable
    public init<S: Sequence>(_ elements: S) where S.Element == DBData {
        self.base = .array(Array(elements))
    }
    
    @inlinable
    public init(_ elements: [String: DBData]) {
        self.base = .dictionary(elements)
    }
}

extension DBData: ExpressibleByNilLiteral {
    
    @inlinable
    public init(nilLiteral value: Void) {
        self.base = .null
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

extension DBData: ExpressibleByStringLiteral {
    
    @inlinable
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
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
        switch self.base {
        case .null: return "nil"
        case let .boolean(value): return "\(value)"
        case let .string(value): return "\"\(value.escaped(asASCII: false))\""
        case let .regex(value): return "\(value)"
        case let .signed(value): return "\(value)"
        case let .unsigned(value): return "\(value)"
        case let .number(value): return "\(value)"
        case let .decimal(value): return "\(value)"
        case let .date(value): return "\(value)"
        case let .binary(value): return "\(value)"
        case let .uuid(value): return "\(value)"
        case let .array(value): return "\(value)"
        case let .dictionary(value): return "\(value)"
        }
    }
}

extension DBData: Hashable {
    
    @inlinable
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
    
    @inlinable
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
    
    @inlinable
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
    
    @inlinable
    public var isNil: Bool {
        switch self.base {
        case .null: return true
        default: return false
        }
    }
    
    @inlinable
    public var isBool: Bool {
        switch self.base {
        case .boolean: return true
        default: return false
        }
    }
    
    @inlinable
    public var isString: Bool {
        switch self.base {
        case .string: return true
        default: return false
        }
    }
    
    @inlinable
    public var isRegex: Bool {
        switch self.base {
        case .regex: return true
        default: return false
        }
    }
    
    @inlinable
    public var isArray: Bool {
        switch self.base {
        case .array: return true
        default: return false
        }
    }
    
    @inlinable
    public var isObject: Bool {
        switch self.base {
        case .dictionary: return true
        default: return false
        }
    }
    
    @inlinable
    public var isSigned: Bool {
        switch self.base {
        case .signed: return true
        default: return false
        }
    }
    
    @inlinable
    public var isUnsigned: Bool {
        switch self.base {
        case .unsigned: return true
        default: return false
        }
    }
    
    @inlinable
    public var isNumber: Bool {
        switch self.base {
        case .number: return true
        default: return false
        }
    }
    
    @inlinable
    public var isDecimal: Bool {
        switch self.base {
        case .decimal: return true
        default: return false
        }
    }
    
    @inlinable
    public var isNumeric: Bool {
        switch self.base {
        case .signed: return true
        case .unsigned: return true
        case .number: return true
        default: return false
        }
    }
    
    @inlinable
    public var isDate: Bool {
        switch self.base {
        case .date: return true
        default: return false
        }
    }
    
    @inlinable
    public var isBinary: Bool {
        switch self.base {
        case .binary: return true
        default: return false
        }
    }
    
    @inlinable
    public var isUUID: Bool {
        switch self.base {
        case .uuid: return true
        default: return false
        }
    }
}

extension DBData {
    
    @inlinable
    public var boolValue: Bool? {
        switch self.base {
        case let .boolean(value): return value
        default: return nil
        }
    }
    
    @inlinable
    public var int8Value: Int8? {
        switch self.base {
        case let .signed(value): return Int8(exactly: value)
        case let .unsigned(value): return Int8(exactly: value)
        case let .number(value): return Int8(exactly: value)
        case let .decimal(value): return Int64(exactly: value).flatMap { Int8(exactly: $0) }
        default: return nil
        }
    }
    
    @inlinable
    public var uint8Value: UInt8? {
        switch self.base {
        case let .signed(value): return UInt8(exactly: value)
        case let .unsigned(value): return UInt8(exactly: value)
        case let .number(value): return UInt8(exactly: value)
        case let .decimal(value): return UInt64(exactly: value).flatMap { UInt8(exactly: $0) }
        default: return nil
        }
    }
    
    @inlinable
    public var int16Value: Int16? {
        switch self.base {
        case let .signed(value): return Int16(exactly: value)
        case let .unsigned(value): return Int16(exactly: value)
        case let .number(value): return Int16(exactly: value)
        case let .decimal(value): return Int64(exactly: value).flatMap { Int16(exactly: $0) }
        default: return nil
        }
    }
    
    @inlinable
    public var uint16Value: UInt16? {
        switch self.base {
        case let .signed(value): return UInt16(exactly: value)
        case let .unsigned(value): return UInt16(exactly: value)
        case let .number(value): return UInt16(exactly: value)
        case let .decimal(value): return UInt64(exactly: value).flatMap { UInt16(exactly: $0) }
        default: return nil
        }
    }
    
    @inlinable
    public var int32Value: Int32? {
        switch self.base {
        case let .signed(value): return Int32(exactly: value)
        case let .unsigned(value): return Int32(exactly: value)
        case let .number(value): return Int32(exactly: value)
        case let .decimal(value): return Int64(exactly: value).flatMap { Int32(exactly: $0) }
        default: return nil
        }
    }
    
    @inlinable
    public var uint32Value: UInt32? {
        switch self.base {
        case let .signed(value): return UInt32(exactly: value)
        case let .unsigned(value): return UInt32(exactly: value)
        case let .number(value): return UInt32(exactly: value)
        case let .decimal(value): return UInt64(exactly: value).flatMap { UInt32(exactly: $0) }
        default: return nil
        }
    }
    
    @inlinable
    public var int64Value: Int64? {
        switch self.base {
        case let .signed(value): return value
        case let .unsigned(value): return Int64(exactly: value)
        case let .number(value): return Int64(exactly: value)
        case let .decimal(value): return Int64(exactly: value)
        default: return nil
        }
    }
    
    @inlinable
    public var uint64Value: UInt64? {
        switch self.base {
        case let .signed(value): return UInt64(exactly: value)
        case let .unsigned(value): return value
        case let .number(value): return UInt64(exactly: value)
        case let .decimal(value): return UInt64(exactly: value)
        default: return nil
        }
    }
    
    @inlinable
    public var intValue: Int? {
        switch self.base {
        case let .signed(value): return Int(exactly: value)
        case let .unsigned(value): return Int(exactly: value)
        case let .number(value): return Int(exactly: value)
        case let .decimal(value): return Int64(exactly: value).flatMap { Int(exactly: $0) }
        default: return nil
        }
    }
    
    @inlinable
    public var uintValue: UInt? {
        switch self.base {
        case let .signed(value): return UInt(exactly: value)
        case let .unsigned(value): return UInt(exactly: value)
        case let .number(value): return UInt(exactly: value)
        case let .decimal(value): return UInt64(exactly: value).flatMap { UInt(exactly: $0) }
        default: return nil
        }
    }
    
    @inlinable
    public var floatValue: Float? {
        switch self.base {
        case let .signed(value): return Float(exactly: value)
        case let .unsigned(value): return Float(exactly: value)
        case let .number(value): return Float(value)
        case let .decimal(value): return Double(exactly: value).flatMap { Float(exactly: $0) }
        default: return nil
        }
    }
    
    @inlinable
    public var doubleValue: Double? {
        switch self.base {
        case let .signed(value): return Double(exactly: value)
        case let .unsigned(value): return Double(exactly: value)
        case let .number(value): return value
        case let .decimal(value): return Double(exactly: value)
        default: return nil
        }
    }
    
    @inlinable
    public var decimalValue: Decimal? {
        switch self.base {
        case let .signed(value): return Decimal(value)
        case let .unsigned(value): return Decimal(value)
        case let .number(value): return Int64(exactly: value).map { Decimal($0) }
        case let .decimal(value): return value
        default: return nil
        }
    }
    
    @inlinable
    public var string: String? {
        switch self.base {
        case let .string(value): return value
        default: return nil
        }
    }
    
    @inlinable
    public var regex: Regex? {
        switch self.base {
        case let .regex(value): return value
        default: return nil
        }
    }
    
    @inlinable
    public var date: Date? {
        switch self.base {
        case let .date(value): return value.date
        default: return nil
        }
    }
    
    @inlinable
    public var dateComponents: DateComponents? {
        switch self.base {
        case let .date(value): return value
        default: return nil
        }
    }
    
    @inlinable
    public var binary: Data? {
        switch self.base {
        case let .binary(value): return value
        default: return nil
        }
    }
    
    @inlinable
    public var uuid: UUID? {
        switch self.base {
        case let .uuid(value): return value
        default: return nil
        }
    }
    
    @inlinable
    public var dictionary: [String: DBData]? {
        switch self.base {
        case let .dictionary(value): return value
        default: return nil
        }
    }
}

extension DBData {
    
    @inlinable
    public var count: Int {
        switch self.base {
        case let .array(value): return value.count
        case let .dictionary(value): return value.count
        default: fatalError("Not an array or object.")
        }
    }
    
    @inlinable
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
    
    @inlinable
    public var keys: Dictionary<String, DBData>.Keys {
        switch self.base {
        case let .dictionary(value): return value.keys
        default: return [:].keys
        }
    }
    
    @inlinable
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

extension DBData: Encodable {
    
    @frozen
    @usableFromInline
    struct CodingKey: Swift.CodingKey {
        
        @usableFromInline
        var stringValue: String
        
        @usableFromInline
        var intValue: Int?
        
        @inlinable
        init(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        @inlinable
        init(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }
    
    @inlinable
    public func encode(to encoder: Encoder) throws {
        
        switch self.base {
        case .null:
            
            var container = encoder.singleValueContainer()
            try container.encodeNil()
            
        case let .boolean(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .string(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .signed(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .unsigned(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .number(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .decimal(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .date(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .binary(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .uuid(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .array(value):
            
            var container = encoder.unkeyedContainer()
            try container.encode(contentsOf: value)
            
        case let .dictionary(value):
            
            var container = encoder.container(keyedBy: CodingKey.self)
            
            for (key, value) in value {
                try container.encode(value, forKey: CodingKey(stringValue: key))
            }
            
        default: throw Database.Error.unsupportedType
        }
    }
}

extension DBData {
    
    @inlinable
    public func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        return try T(from: _Decoder(value: self))
    }
    
    @frozen
    @usableFromInline
    struct _Decoder: Decoder {
        
        @usableFromInline
        let value: DBData
        
        @usableFromInline
        let codingPath: [Swift.CodingKey]
        
        @usableFromInline
        let userInfo: [CodingUserInfoKey: Any]
        
        @inlinable
        init(value: DBData, codingPath: [Swift.CodingKey] = [], userInfo: [CodingUserInfoKey: Any] = [:]) {
            self.value = value
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
        
        @inlinable
        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: Swift.CodingKey {
            
            guard !value.isNil else { throw Database.Error.valueNotFound }
            guard case let .dictionary(dictionary) = value.base else { throw Database.Error.unsupportedType }
            
            let container = _KeyedDecodingContainer<Key>(dictionary: dictionary, codingPath: codingPath, userInfo: userInfo)
            return KeyedDecodingContainer(container)
        }
        
        @inlinable
        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            
            guard !value.isNil else { throw Database.Error.valueNotFound }
            guard case let .array(array) = value.base else { throw Database.Error.unsupportedType }
            
            return _UnkeyedDecodingContainer(array: array, codingPath: codingPath, userInfo: userInfo)
        }
        
        @inlinable
        func singleValueContainer() throws -> SingleValueDecodingContainer {
            return self
        }
    }
    
    @frozen
    @usableFromInline
    struct _KeyedDecodingContainer<Key: Swift.CodingKey> {
        
        @usableFromInline
        let dictionary: [String : DBData]
        
        @usableFromInline
        let codingPath: [Swift.CodingKey]
        
        @usableFromInline
        let userInfo: [CodingUserInfoKey: Any]
        
        @inlinable
        init(dictionary: [String : DBData], codingPath: [Swift.CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.dictionary = dictionary
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
    }
    
    @frozen
    @usableFromInline
    struct _UnkeyedDecodingContainer {
        
        @usableFromInline
        let array: [DBData]
        
        @usableFromInline
        let codingPath: [Swift.CodingKey]
        
        @usableFromInline
        let userInfo: [CodingUserInfoKey: Any]
        
        @usableFromInline
        var currentIndex: Int = 0
        
        @inlinable
        init(array: [DBData], codingPath: [Swift.CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.array = array
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
    }
}

extension DBData._Decoder: SingleValueDecodingContainer {
    
    @inlinable
    func decodeNil() -> Bool {
        return value.isNil
    }
    
    @inlinable
    func _decode(_ type: Bool.Type) throws -> Bool {
        switch value.base {
        case .null: throw Database.Error.valueNotFound
            
        case let .boolean(value): return value
            
        case let .string(string):
            
            switch string {
            case "true", "1": return true
            case "false", "0": return false
            default: throw Database.Error.unsupportedType
            }
            
        default: throw Database.Error.unsupportedType
        }
    }
    
    @inlinable
    func _decode<T: BinaryFloatingPoint>(_ type: T.Type) throws -> T {
        switch value.base {
        case .null: throw Database.Error.valueNotFound
            
        case let .signed(value):
            
            guard let value = T(exactly: value) else { throw Database.Error.unsupportedType }
            return value
            
        case let .unsigned(value):
            
            guard let value = T(exactly: value) else { throw Database.Error.unsupportedType }
            return value
            
        case let .number(value):
            
            guard let value = T(exactly: value) else { throw Database.Error.unsupportedType }
            return value
            
        case let .decimal(value):
            
            guard let double = Double(exactly: value) else { throw Database.Error.unsupportedType }
            guard let value = T(exactly: double) else { throw Database.Error.unsupportedType }
            return value
            
        case let .string(string):
            
            guard let double = Double(string) else { throw Database.Error.unsupportedType }
            guard let value = T(exactly: double) else { throw Database.Error.unsupportedType }
            return value
            
        default: throw Database.Error.unsupportedType
        }
    }
    
    @inlinable
    func _decode<T: FixedWidthInteger>(_ type: T.Type) throws -> T {
        switch value.base {
        case .null: throw Database.Error.valueNotFound
            
        case let .signed(value):
            
            guard let value = T(exactly: value) else { throw Database.Error.unsupportedType }
            return value
            
        case let .unsigned(value):
            
            guard let value = T(exactly: value) else { throw Database.Error.unsupportedType }
            return value
            
        case let .number(value):
            
            guard let value = T(exactly: value) else { throw Database.Error.unsupportedType }
            return value
            
        case let .decimal(value):
            
            guard let int64 = Int64(exactly: value) else { throw Database.Error.unsupportedType }
            guard let value = T(exactly: int64) else { throw Database.Error.unsupportedType }
            return value
            
        case let .string(string):
            
            guard let value = T(string) else { throw Database.Error.unsupportedType }
            return value
            
        default: throw Database.Error.unsupportedType
        }
    }
    
    @inlinable
    func _decode(_ type: String.Type) throws -> String {
        switch value.base {
        case .null: throw Database.Error.valueNotFound
        case let .string(string): return string
        default: throw Database.Error.unsupportedType
        }
    }
    
    @inlinable
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        switch type {
        case is Bool.Type: return try self._decode(Bool.self) as! T
        case is Float.Type: return try self._decode(Float.self) as! T
        case is Double.Type: return try self._decode(Double.self) as! T
        case is Int.Type: return try self._decode(Int.self) as! T
        case is Int8.Type: return try self._decode(Int8.self) as! T
        case is Int16.Type: return try self._decode(Int16.self) as! T
        case is Int32.Type: return try self._decode(Int32.self) as! T
        case is Int64.Type: return try self._decode(Int64.self) as! T
        case is UInt.Type: return try self._decode(UInt.self) as! T
        case is UInt8.Type: return try self._decode(UInt8.self) as! T
        case is UInt16.Type: return try self._decode(UInt16.self) as! T
        case is UInt32.Type: return try self._decode(UInt32.self) as! T
        case is UInt64.Type: return try self._decode(UInt64.self) as! T
        case is String.Type: return try self._decode(String.self) as! T
        default: throw Database.Error.unsupportedType
        }
    }
}

extension DBData._KeyedDecodingContainer: KeyedDecodingContainerProtocol {
    
    @inlinable
    var allKeys: [Key] {
        return dictionary.keys.compactMap { Key(stringValue: $0) }
    }
    
    @inlinable
    func contains(_ key: Key) -> Bool {
        return dictionary.keys.contains(key.stringValue)
    }
    
    @inlinable
    func decodeNil(forKey key: Key) throws -> Bool {
        guard let entry = dictionary[key.stringValue] else { throw Database.Error.valueNotFound }
        return entry.isNil
    }
    
    @inlinable
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        guard let entry = dictionary[key.stringValue] else { throw Database.Error.valueNotFound }
        return try entry.decode(type)
    }
    
    @inlinable
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        
        guard let entry = self.dictionary[key.stringValue] else { throw Database.Error.valueNotFound }
        guard case let .dictionary(dictionary) = entry.base else { throw Database.Error.unsupportedType }
        
        var codingPath = self.codingPath
        codingPath.append(key)
        
        let container = DBData._KeyedDecodingContainer<NestedKey>(dictionary: dictionary, codingPath: codingPath, userInfo: userInfo)
        return KeyedDecodingContainer(container)
    }
    
    @inlinable
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        
        guard let entry = self.dictionary[key.stringValue] else { throw Database.Error.valueNotFound }
        guard case let .array(array) = entry.base else { throw Database.Error.unsupportedType }
        
        var codingPath = self.codingPath
        codingPath.append(key)
        
        return DBData._UnkeyedDecodingContainer(array: array, codingPath: codingPath, userInfo: userInfo)
    }
    
    @inlinable
    func _superDecoder(forKey key: __owned CodingKey) throws -> Decoder {
        
        guard let entry = dictionary[key.stringValue] else { throw Database.Error.valueNotFound }
        
        var codingPath = self.codingPath
        codingPath.append(key)
        
        return DBData._Decoder(value: entry, codingPath: codingPath, userInfo: userInfo)
    }
    
    @inlinable
    func superDecoder() throws -> Decoder {
        return try _superDecoder(forKey: DBData.CodingKey(stringValue: "super"))
    }
    
    @inlinable
    func superDecoder(forKey key: Key) throws -> Decoder {
        return try _superDecoder(forKey: key)
    }
}

extension DBData._UnkeyedDecodingContainer: UnkeyedDecodingContainer {
    
    @inlinable
    var count: Int? {
        return array.count
    }
    
    @inlinable
    var isAtEnd: Bool {
        return self.currentIndex >= array.count
    }
    
    @inlinable
    mutating func decodeNil() throws -> Bool {
        
        guard !self.isAtEnd else { throw Database.Error.valueNotFound }
        
        let value = array[self.currentIndex]
        
        if value.isNil {
            self.currentIndex += 1
            return true
        } else {
            return false
        }
    }
    
    @inlinable
    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        
        guard !self.isAtEnd else { throw Database.Error.valueNotFound }
        
        let decoded = try array[self.currentIndex].decode(type)
        
        self.currentIndex += 1
        return decoded
    }
    
    @inlinable
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        
        guard !self.isAtEnd else { throw Database.Error.valueNotFound }
        
        guard case let .dictionary(dictionary) = self.array[self.currentIndex].base else { throw Database.Error.unsupportedType }
        
        var codingPath = self.codingPath
        codingPath.append(DBData.CodingKey(intValue: self.currentIndex))
        
        self.currentIndex += 1
        
        let container = DBData._KeyedDecodingContainer<NestedKey>(dictionary: dictionary, codingPath: codingPath, userInfo: userInfo)
        return KeyedDecodingContainer(container)
    }
    
    @inlinable
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        
        guard !self.isAtEnd else { throw Database.Error.valueNotFound }
        
        guard case let .array(array) = self.array[self.currentIndex].base else { throw Database.Error.unsupportedType }
        
        var codingPath = self.codingPath
        codingPath.append(DBData.CodingKey(intValue: self.currentIndex))
        
        self.currentIndex += 1
        return DBData._UnkeyedDecodingContainer(array: array, codingPath: codingPath, userInfo: userInfo)
    }
    
    @inlinable
    mutating func superDecoder() throws -> Decoder {
        
        guard !self.isAtEnd else { throw Database.Error.valueNotFound }
        
        let value = array[self.currentIndex]
        
        var codingPath = self.codingPath
        codingPath.append(DBData.CodingKey(intValue: self.currentIndex))
        
        self.currentIndex += 1
        return DBData._Decoder(value: value, codingPath: codingPath, userInfo: userInfo)
    }
}
