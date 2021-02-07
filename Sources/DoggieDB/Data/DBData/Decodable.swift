//
//  Decodable.swift
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
    func _decode(_ type: Decimal.Type) throws -> Decimal {
        switch value.base {
        case .null: throw Database.Error.valueNotFound
            
        case let .signed(value): return Decimal(value)
        case let .unsigned(value): return Decimal(value)
        case let .number(value): return Decimal(value)
        case let .decimal(decimal): return decimal
            
        case let .string(string):
            
            guard let value = Decimal(string: string) else { throw Database.Error.unsupportedType }
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
    func _decode(_ type: UUID.Type) throws -> UUID {
        switch value.base {
        case .null: throw Database.Error.valueNotFound
            
        case let .uuid(uuid): return uuid
            
        case let .string(string):
            
            guard let value = UUID(uuidString: string) else { throw Database.Error.unsupportedType }
            return value
            
        default: throw Database.Error.unsupportedType
        }
    }
    
    @inlinable
    func _decode(_ type: Date.Type) throws -> Date {
        switch value.base {
        case .null: throw Database.Error.valueNotFound
            
        case let .date(date):
            
            guard let value = date.date else { throw Database.Error.unsupportedType }
            return value
            
        default: throw Database.Error.unsupportedType
        }
    }
    
    @inlinable
    func _decode(_ type: DateComponents.Type) throws -> DateComponents {
        switch value.base {
        case .null: throw Database.Error.valueNotFound
        case let .date(date): return date
        default: throw Database.Error.unsupportedType
        }
    }
    
    @inlinable
    func _decode(_ type: Data.Type) throws -> Data {
        switch value.base {
        case .null: throw Database.Error.valueNotFound
        case let .binary(data): return data
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
        case is Decimal.Type: return try self._decode(Decimal.self) as! T
        case is String.Type: return try self._decode(String.self) as! T
        case is UUID.Type: return try self._decode(UUID.self) as! T
        case is Date.Type: return try self._decode(Date.self) as! T
        case is DateComponents.Type: return try self._decode(DateComponents.self) as! T
        case is Data.Type: return try self._decode(Data.self) as! T
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
