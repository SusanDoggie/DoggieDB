//
//  decoder.swift
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

import RediStack
import SwiftBSON

public protocol _Decoder {
    
    func decode<Value: Decodable>(_ type: Value.Type, from value: RESPValue) throws -> Value
}

extension ExpressibleByNilLiteral {
    
    fileprivate static var null: ExpressibleByNilLiteral {
        return Self(nilLiteral: ()) as ExpressibleByNilLiteral
    }
}

public struct RedisDecoder: _Decoder {
    
    public init() { }
    
    public func decode<Value: Decodable>(_ type: Value.Type, from value: RESPValue) throws -> Value {
        switch value {
        case .null:
            
            guard let _Value = Value.self as? ExpressibleByNilLiteral.Type else { throw Database.Error.unsupportedType }
            return _Value.null as! Value
            
        case let .simpleString(buffer),
             let .bulkString(.some(buffer)):
            
            if let value = String(fromRESP: value) {
                return try DBData(value).decode(type)
            } else {
                return try BSONDecoder().decode(type, from: buffer.data)
            }
            
        default: return try DBData(value).decode(type)
        }
    }
}

extension BSONDecoder: _Decoder {
    
    public func decode<Value>(_ type: Value.Type, from value: RESPValue) throws -> Value where Value : Decodable {
        guard let bson = Data(fromRESP: value) else { throw Database.Error.unsupportedType }
        return try self.decode(type, from: bson)
    }
}

extension JSONDecoder: _Decoder {
    
    public func decode<Value>(_ type: Value.Type, from value: RESPValue) throws -> Value where Value : Decodable {
        guard let json = Data(fromRESP: value) else { throw Database.Error.unsupportedType }
        return try self.decode(type, from: json)
    }
}

extension ExtendedJSONDecoder: _Decoder {
    
    public func decode<Value>(_ type: Value.Type, from value: RESPValue) throws -> Value where Value : Decodable {
        guard let json = Data(fromRESP: value) else { throw Database.Error.unsupportedType }
        return try self.decode(type, from: json)
    }
}


