//
//  DBDataDecoder.swift
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

extension DBData {
    
    /// The strategy to use for decoding `Date` values.
    public enum DateDecodingStrategy {
        
        /// Decode the `Date` as a UNIX timestamp from a number.
        case secondsSince1970
        
        /// Decode the `Date` as UNIX millisecond timestamp from a number.
        case millisecondsSince1970
        
        /// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        case iso8601
        
        /// Decode the `Date` as a string parsed by the given formatter.
        case formatted(DateFormatter)
        
        /// Decode the `Date` as a custom value decoded by the given closure.
        case custom((Decoder) throws -> Date)
    }
    
    public struct DecoderOptions {
        
        public var dateDecodingStrategy: DateDecodingStrategy
        
        public var calendar: Calendar
        
        public var timeZone: TimeZone
        
        public var userInfo: [CodingUserInfoKey: Any]
        
        public init(
            dateDecodingStrategy: DateDecodingStrategy = .iso8601,
            calendar: Calendar = Calendar(identifier: .iso8601),
            timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!,
            userInfo: [CodingUserInfoKey: Any] = [:]) {
                self.dateDecodingStrategy = dateDecodingStrategy
                self.calendar = calendar
                self.timeZone = timeZone
                self.userInfo = userInfo
            }
    }
}

extension DBData {
    
    public func decode<T: Decodable>(_ type: T.Type, options: DecoderOptions = DecoderOptions()) throws -> T {
        return try T(from: _Decoder(value: self, codingPath: [], options: options))
    }
    
    struct _Decoder: Decoder {
        
        let value: DBData
        
        let codingPath: [Swift.CodingKey]
        
        let options: DecoderOptions
        
        init(value: DBData, codingPath: [Swift.CodingKey], options: DecoderOptions) {
            self.value = value
            self.codingPath = codingPath
            self.options = options
        }
        
        func container<Key: Swift.CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
            
            guard !value.isNil else { throw Database.Error.valueNotFound }
            guard case let .dictionary(dictionary) = value else { throw Database.Error.unsupportedType }
            
            let container = _KeyedDecodingContainer<Key>(dictionary: dictionary, codingPath: codingPath, options: options)
            return KeyedDecodingContainer(container)
        }
        
        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            
            guard !value.isNil else { throw Database.Error.valueNotFound }
            guard case let .array(array) = value else { throw Database.Error.unsupportedType }
            
            return _UnkeyedDecodingContainer(array: array, codingPath: codingPath, options: options)
        }
        
        func singleValueContainer() throws -> SingleValueDecodingContainer {
            return self
        }
    }
    
    struct _KeyedDecodingContainer<Key: Swift.CodingKey> {
        
        let value: [String: DBData]
        
        let codingPath: [Swift.CodingKey]
        
        let options: DecoderOptions
        
        init(dictionary: [String: DBData], codingPath: [Swift.CodingKey], options: DecoderOptions) {
            self.value = dictionary
            self.codingPath = codingPath
            self.options = options
        }
    }
    
    struct _UnkeyedDecodingContainer {
        
        let value: [DBData]
        
        let codingPath: [Swift.CodingKey]
        
        let options: DecoderOptions
        
        var currentIndex: Int = 0
        
        init(array: [DBData], codingPath: [Swift.CodingKey], options: DecoderOptions) {
            self.value = array
            self.codingPath = codingPath
            self.options = options
        }
    }
}

extension DBData._Decoder: SingleValueDecodingContainer {
    
    var userInfo: [CodingUserInfoKey: Any] {
        return options.userInfo
    }
    
    func decodeNil() -> Bool {
        return value.isNil
    }
    
    func _decode(_ type: Bool.Type) throws -> Bool {
        switch value {
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
    
    func _decode<T: BinaryFloatingPoint>(_ type: T.Type) throws -> T {
        switch value {
        case .null: throw Database.Error.valueNotFound
            
        case let .number(value):
            
            switch value {
                
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
            }
            
        case let .string(string):
            
            guard let double = Double(string) else { throw Database.Error.unsupportedType }
            guard let value = T(exactly: double) else { throw Database.Error.unsupportedType }
            return value
            
        default: throw Database.Error.unsupportedType
        }
    }
    
    func _decode<T: FixedWidthInteger>(_ type: T.Type) throws -> T {
        switch value {
        case .null: throw Database.Error.valueNotFound
            
        case let .number(value):
            
            switch value {
                
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
            }
            
        case let .string(string):
            
            guard let value = T(string) else { throw Database.Error.unsupportedType }
            return value
            
        default: throw Database.Error.unsupportedType
        }
    }
    
    func _decode(_ type: Decimal.Type) throws -> Decimal {
        switch value {
        case .null: throw Database.Error.valueNotFound
            
        case let .number(value):
            
            switch value {
            case let .signed(value): return Decimal(value)
            case let .unsigned(value): return Decimal(value)
            case let .number(value): return Decimal(value)
            case let .decimal(decimal): return decimal
            }
            
        case let .string(string):
            
            guard let value = Decimal(string: string, locale: Locale(identifier: "en_US")) else { throw Database.Error.unsupportedType }
            return value
            
        default: throw Database.Error.unsupportedType
        }
    }
    
    func _decode(_ type: String.Type) throws -> String {
        switch value {
        case .null: throw Database.Error.valueNotFound
        case let .string(string): return string
        case let .binary(data):
            
            guard let string = String(bytes: data, encoding: .utf8) else { throw Database.Error.unsupportedType }
            return string
            
        default: throw Database.Error.unsupportedType
        }
    }
    
    func _decode(_ type: UUID.Type) throws -> UUID {
        switch value {
        case .null: throw Database.Error.valueNotFound
            
        case let .uuid(uuid): return uuid
            
        case let .string(string):
            
            guard let value = string.count == 32 ? UUID(hexString: string) : UUID(uuidString: string) else { throw Database.Error.unsupportedType }
            return value
            
        case let .binary(data):
            
            guard data.count == 16 else { throw Database.Error.unsupportedType }
            return UUID(uuid: data.load(as: uuid_t.self))
            
        default: throw Database.Error.unsupportedType
        }
    }
    
    func _decode(_ type: BSONObjectID.Type) throws -> BSONObjectID {
        switch value {
        case .null: throw Database.Error.valueNotFound
        case let .objectID(objectID): return objectID
        case let .string(string): return try BSONObjectID(string)
        default: throw Database.Error.unsupportedType
        }
    }
    
    func _decode(_ type: Date.Type) throws -> Date {
        switch value {
        case .null: throw Database.Error.valueNotFound
            
        case let .timestamp(date):
            
            return date
            
        case let .date(date):
            
            guard let value = date.date else { throw Database.Error.unsupportedType }
            return value
            
        case let .number(value):
            
            switch value {
            case let .signed(value):
                
                switch options.dateDecodingStrategy {
                case .secondsSince1970: return Date(timeIntervalSince1970: Double(value))
                case .millisecondsSince1970: return Date(timeIntervalSince1970: Double(value) / 1000.0)
                case let .custom(closure): return try closure(self)
                default: throw Database.Error.unsupportedType
                }
                
            case let .unsigned(value):
                
                switch options.dateDecodingStrategy {
                case .secondsSince1970: return Date(timeIntervalSince1970: Double(value))
                case .millisecondsSince1970: return Date(timeIntervalSince1970: Double(value) / 1000.0)
                case let .custom(closure): return try closure(self)
                default: throw Database.Error.unsupportedType
                }
                
            case let .number(value):
                
                switch options.dateDecodingStrategy {
                case .secondsSince1970: return Date(timeIntervalSince1970: value)
                case .millisecondsSince1970: return Date(timeIntervalSince1970: value / 1000.0)
                case let .custom(closure): return try closure(self)
                default: throw Database.Error.unsupportedType
                }
                
            case let .decimal(value):
                
                switch options.dateDecodingStrategy {
                case .secondsSince1970: return Date(timeIntervalSince1970: value.doubleValue)
                case .millisecondsSince1970: return Date(timeIntervalSince1970: value.doubleValue / 1000.0)
                case let .custom(closure): return try closure(self)
                default: throw Database.Error.unsupportedType
                }
            }
            
        case let .string(string):
            
            switch options.dateDecodingStrategy {
                
            case .iso8601:
                
                guard let value = string.iso8601 else { throw Database.Error.invalidDateFormat }
                return value
                
            case let .formatted(formatter):
                
                guard let value = formatter.date(from: string) else { throw Database.Error.invalidDateFormat }
                return value
                
            case let .custom(closure): return try closure(self)
                
            default: throw Database.Error.unsupportedType
            }
            
        default: throw Database.Error.unsupportedType
        }
    }
    
    func _decode(_ type: DateComponents.Type) throws -> DateComponents {
        switch value {
        case .null: throw Database.Error.valueNotFound
        case let .timestamp(date): return Calendar.iso8601.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)
        case let .date(date): return date
        default: return try options.calendar.dateComponents(in: options.timeZone, from: self._decode(Date.self))
        }
    }
    
    func _decode(_ type: Data.Type) throws -> Data {
        switch value {
        case .null: throw Database.Error.valueNotFound
        case let .binary(data): return data
        default: throw Database.Error.unsupportedType
        }
    }
    
    func _decode(_ type: ByteBuffer.Type) throws -> ByteBuffer {
        switch value {
        case .null: throw Database.Error.valueNotFound
        case let .binary(data): return ByteBuffer(data: data)
        default: throw Database.Error.unsupportedType
        }
    }
    
    func _decode(_ type: ByteBufferView.Type) throws -> ByteBufferView {
        switch value {
        case .null: throw Database.Error.valueNotFound
        case let .binary(data): return ByteBufferView(data)
        default: throw Database.Error.unsupportedType
        }
    }
    
    func _decode(_ type: Json.Number.Type) throws -> Json.Number {
        switch value {
        case .null: throw Database.Error.valueNotFound
        case let .number(value): return Json.Number(value)
        default: throw Database.Error.unsupportedType
        }
    }
    
    func _decode(_ type: DBData.Number.Type) throws -> DBData.Number {
        switch value {
        case .null: throw Database.Error.valueNotFound
        case let .number(value): return value
        default: throw Database.Error.unsupportedType
        }
    }
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        switch type {
        case is DBData.Type: return self as! T
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
        case is Decimal.Type: return try self._decode(Decimal.self) as! T
        case is String.Type: return try self._decode(String.self) as! T
        case is UUID.Type: return try self._decode(UUID.self) as! T
        case is BSONObjectID.Type: return try self._decode(BSONObjectID.self) as! T
        case is Date.Type: return try self._decode(Date.self) as! T
        case is DateComponents.Type: return try self._decode(DateComponents.self) as! T
        case is Data.Type: return try self._decode(Data.self) as! T
        case is Json.Number.Type: return try self._decode(Json.Number.self) as! T
        case is DBData.Number.Type: return try self._decode(DBData.Number.self) as! T
        default: throw Database.Error.unsupportedType
        }
    }
}

extension DBData._KeyedDecodingContainer: KeyedDecodingContainerProtocol {
    
    var allKeys: [Key] {
        return value.keys.compactMap { Key(stringValue: $0) }
    }
    
    func contains(_ key: Key) -> Bool {
        return value.keys.contains(key.stringValue)
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        guard let entry = value[key.stringValue] else { throw Database.Error.valueNotFound }
        return entry.isNil
    }
    
    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        guard let entry = value[key.stringValue] else { throw Database.Error.valueNotFound }
        return try entry.decode(type)
    }
    
    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        
        guard let entry = self.value[key.stringValue] else { throw Database.Error.valueNotFound }
        guard case let .dictionary(dictionary) = entry else { throw Database.Error.unsupportedType }
        
        var codingPath = self.codingPath
        codingPath.append(key)
        
        let container = DBData._KeyedDecodingContainer<NestedKey>(dictionary: dictionary, codingPath: codingPath, options: options)
        return KeyedDecodingContainer(container)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        
        guard let entry = self.value[key.stringValue] else { throw Database.Error.valueNotFound }
        guard case let .array(array) = entry else { throw Database.Error.unsupportedType }
        
        var codingPath = self.codingPath
        codingPath.append(key)
        
        return DBData._UnkeyedDecodingContainer(array: array, codingPath: codingPath, options: options)
    }
    
    func _superDecoder(forKey key: __owned CodingKey) throws -> Decoder {
        
        guard let entry = value[key.stringValue] else { throw Database.Error.valueNotFound }
        
        var codingPath = self.codingPath
        codingPath.append(key)
        
        return DBData._Decoder(value: entry, codingPath: codingPath, options: options)
    }
    
    func superDecoder() throws -> Decoder {
        return try _superDecoder(forKey: DBData.CodingKey(stringValue: "super"))
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        return try _superDecoder(forKey: key)
    }
}

extension DBData._UnkeyedDecodingContainer: UnkeyedDecodingContainer {
    
    var count: Int? {
        return value.count
    }
    
    var isAtEnd: Bool {
        return self.currentIndex >= value.count
    }
    
    mutating func decodeNil() throws -> Bool {
        
        guard !self.isAtEnd else { throw Database.Error.valueNotFound }
        
        let value = self.value[self.currentIndex]
        
        if value.isNil {
            self.currentIndex += 1
            return true
        } else {
            return false
        }
    }
    
    mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
        
        guard !self.isAtEnd else { throw Database.Error.valueNotFound }
        
        let decoded = try value[self.currentIndex].decode(type)
        
        self.currentIndex += 1
        return decoded
    }
    
    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        
        guard !self.isAtEnd else { throw Database.Error.valueNotFound }
        
        guard case let .dictionary(dictionary) = self.value[self.currentIndex] else { throw Database.Error.unsupportedType }
        
        var codingPath = self.codingPath
        codingPath.append(DBData.CodingKey(intValue: self.currentIndex))
        
        self.currentIndex += 1
        
        let container = DBData._KeyedDecodingContainer<NestedKey>(dictionary: dictionary, codingPath: codingPath, options: options)
        return KeyedDecodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        
        guard !self.isAtEnd else { throw Database.Error.valueNotFound }
        
        guard case let .array(array) = self.value[self.currentIndex] else { throw Database.Error.unsupportedType }
        
        var codingPath = self.codingPath
        codingPath.append(DBData.CodingKey(intValue: self.currentIndex))
        
        self.currentIndex += 1
        return DBData._UnkeyedDecodingContainer(array: array, codingPath: codingPath, options: options)
    }
    
    mutating func superDecoder() throws -> Decoder {
        
        guard !self.isAtEnd else { throw Database.Error.valueNotFound }
        
        let value = self.value[self.currentIndex]
        
        var codingPath = self.codingPath
        codingPath.append(DBData.CodingKey(intValue: self.currentIndex))
        
        self.currentIndex += 1
        return DBData._Decoder(value: value, codingPath: codingPath, options: options)
    }
}
