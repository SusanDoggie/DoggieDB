//
//  DBDataEncoder.swift
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

public class DBDataEncoder {
    
    let userInfo: [CodingUserInfoKey: Any]
    
    public init(userInfo: [CodingUserInfoKey: Any] = [:]) {
        self.userInfo = userInfo
    }
}

extension DBDataEncoder {
    
    public func encode<T: Encodable>(_ value: T) throws -> DBData {
        
        let encoder = _Encoder(codingPath: [], userInfo: userInfo, storage: nil)
        try value.encode(to: encoder)
        
        return encoder.storage?.value ?? nil
    }
}

extension DBDataEncoder {
    
    class _Encoder: Encoder {
        
        var codingPath: [Swift.CodingKey]
        
        let userInfo: [CodingUserInfoKey: Any]
        
        var storage: _EncoderStorage?
        
        init(codingPath: [Swift.CodingKey], userInfo: [CodingUserInfoKey: Any], storage: _EncoderStorage?) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.storage = storage
        }
    }
    
    enum _EncoderValue {
        
        case value(DBData)
        
        case storage(_EncoderStorage)
        
        var value: DBData {
            switch self {
            case let .value(value): return value
            case let .storage(storage): return storage.value
            }
        }
    }
    
    class _EncoderStorage {
        
        let codingPath: [CodingKey]
        
        let userInfo: [CodingUserInfoKey: Any]
        
        var value: DBData { return nil }
        
        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
    }
    
    struct _KeyedEncodingContainer<Key: CodingKey> {
        
        let ref: _RefObject
        
        var codingPath: [CodingKey] { ref.codingPath }
        
    }
    
    class _RefObject: _EncoderStorage {
        
        var object: [String: _EncoderValue] = [:]
        
        override var value: DBData { return DBData(object.mapValues { $0.value }) }
        
    }
    
    class _RefArray: _EncoderStorage {
        
        var array: [_EncoderValue] = []
        
        var count: Int { array.count }
        
        override var value: DBData { return DBData(array.map { $0.value }) }
        
    }
    
    class _RefValue: _EncoderStorage {
        
        var _value: _EncoderValue?
        
        override var value: DBData { return _value?.value ?? nil }
        
    }
}

extension DBDataEncoder._Encoder {
    
    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        
        if let storage = self.storage as? DBDataEncoder._RefObject {
            return KeyedEncodingContainer(DBDataEncoder._KeyedEncodingContainer(ref: storage))
        }
        
        guard storage == nil else { preconditionFailure() }
        
        let value = DBDataEncoder._RefObject(codingPath: codingPath, userInfo: userInfo)
        self.storage = value
        return KeyedEncodingContainer(DBDataEncoder._KeyedEncodingContainer(ref: value))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        
        if let storage = self.storage as? DBDataEncoder._RefArray {
            return storage
        }
        
        guard storage == nil else { preconditionFailure() }
        
        let value = DBDataEncoder._RefArray(codingPath: codingPath, userInfo: userInfo)
        self.storage = value
        return value
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        
        if let storage = self.storage as? DBDataEncoder._RefValue {
            return storage
        }
        
        guard storage == nil else { preconditionFailure() }
        
        let value = DBDataEncoder._RefValue(codingPath: codingPath, userInfo: userInfo)
        self.storage = value
        return value
    }
}

private struct _AnyEncodable: Encodable {
    
    let value: Encodable
    
    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

private protocol _CollectionEncodableMarker: Encodable {
    
    var _array: [Encodable] { get }
}

extension _CollectionEncodableMarker where Self: Collection, Element: Encodable {
    
    fileprivate var _array: [Encodable] { return Array(self) }
}

extension Array: _CollectionEncodableMarker where Element: Encodable { }
extension Set: _CollectionEncodableMarker where Element: Encodable { }
extension OrderedSet: _CollectionEncodableMarker where Element: Encodable { }

private protocol _StringDictionaryEncodableMarker: Encodable {
    
    var _dictionary: [String: Encodable] { get }
}
extension Dictionary: _StringDictionaryEncodableMarker where Key == String, Value: Encodable {
    
    fileprivate var _dictionary: [String: Encodable] { return self }
}
extension OrderedDictionary: _StringDictionaryEncodableMarker where Key == String, Value: Encodable {
    
    fileprivate var _dictionary: [String: Encodable] { return Dictionary(self) }
}

extension DBDataEncoder._EncoderStorage {
    
    func _encode(_ value: Encodable) throws -> DBData {
        switch value {
        case let value as DBData: return value
        case let value as Bool: return DBData(value)
        case let value as Float: return DBData(value)
        case let value as Double: return DBData(value)
        case let value as Int: return DBData(value)
        case let value as Int8: return DBData(value)
        case let value as Int16: return DBData(value)
        case let value as Int32: return DBData(value)
        case let value as Int64: return DBData(value)
        case let value as UInt: return DBData(value)
        case let value as UInt8: return DBData(value)
        case let value as UInt16: return DBData(value)
        case let value as UInt32: return DBData(value)
        case let value as UInt64: return DBData(value)
        case let value as Decimal: return DBData(value)
        case let value as String: return DBData(value)
        case let value as UUID: return DBData(value)
        case let value as BSONObjectID: return DBData(value)
        case let value as Date: return DBData(value)
        case let value as DateComponents: return DBData(value)
        case let value as Data: return DBData(value)
        case let value as Json.Number: return .number(.init(value))
        case let value as DBData.Number: return DBData(value)
        case let value as _CollectionEncodableMarker:
            
            let storage = DBDataEncoder._RefArray(codingPath: codingPath, userInfo: userInfo)
            
            for item in value._array {
                try storage.encode(_AnyEncodable(value: item))
            }
            
            return storage.value
            
        case let value as _StringDictionaryEncodableMarker:
            
            let storage = DBDataEncoder._RefObject(codingPath: codingPath, userInfo: userInfo)
            let container = DBDataEncoder._KeyedEncodingContainer<DBData.CodingKey>(ref: storage)
            
            for (key, item) in value._dictionary {
                try container.encode(_AnyEncodable(value: item), forKey: DBData.CodingKey(stringValue: key))
            }
            
            return storage.value
            
        case let value as _AnyEncodable: return try self._encode(value.value)
        case let value as DBDataConvertible: return value.toDBData()
        default: throw Database.Error.unsupportedType
        }
    }
}

extension DBDataEncoder._KeyedEncodingContainer: KeyedEncodingContainerProtocol {
    
    func encodeNil(forKey key: Key) throws {
        ref.object[key.stringValue] = nil
    }
    
    func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        ref.object[key.stringValue] = try .value(ref._encode(value))
    }
    
    func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let codingPath = self.codingPath + [key]
        let value = DBDataEncoder._RefObject(codingPath: codingPath, userInfo: ref.userInfo)
        ref.object[key.stringValue] = .storage(value)
        return KeyedEncodingContainer<NestedKey>(DBDataEncoder._KeyedEncodingContainer(ref: value))
    }
    
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let codingPath = self.codingPath + [key]
        let value = DBDataEncoder._RefArray(codingPath: codingPath, userInfo: ref.userInfo)
        ref.object[key.stringValue] = .storage(value)
        return value
    }
    
    func superEncoder() -> Encoder {
        fatalError("unimplemented")
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        fatalError("unimplemented")
    }
}

extension DBDataEncoder._RefArray: UnkeyedEncodingContainer {
    
    func encodeNil() throws {
        array.append(.value(nil))
    }
    
    func encode<T: Encodable>(_ value: T) throws {
        try array.append(.value(self._encode(value)))
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let codingPath = self.codingPath + [DBData.CodingKey(intValue: array.count)]
        let value = DBDataEncoder._RefObject(codingPath: codingPath, userInfo: userInfo)
        array.append(.storage(value))
        return KeyedEncodingContainer<NestedKey>(DBDataEncoder._KeyedEncodingContainer(ref: value))
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let codingPath = self.codingPath + [DBData.CodingKey(intValue: array.count)]
        let value = DBDataEncoder._RefArray(codingPath: codingPath, userInfo: userInfo)
        array.append(.storage(value))
        return value
    }
    
    func superEncoder() -> Encoder {
        fatalError("unimplemented")
    }
}

extension DBDataEncoder._RefValue: SingleValueEncodingContainer {
    
    func encodeNil() throws {
        self.preconditionCanEncodeNewValue()
        self._value = .value(nil)
    }
    
    func encode<T: Encodable>(_ value: T) throws {
        self.preconditionCanEncodeNewValue()
        self._value = try .value(self._encode(value))
    }
    
    func preconditionCanEncodeNewValue() {
        precondition(self._value == nil, "Attempt to encode value through single value container when previously value already encoded.")
    }
    
}
