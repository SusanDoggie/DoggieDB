//
//  encoder.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2023 Susan Cheng. All rights reserved.
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

public protocol RedisEncoderProtocol {
    
    func encode<Value: Encodable>(_ value: Value, as: RESPValue.Type) throws -> RESPValue
}

public struct RedisEncoder: RedisEncoderProtocol {
    
    private static let encoder = ExtendedJSONEncoder()
    
    public init() { }
    
    public func encode<Value: Encodable>(_ value: Value, as: RESPValue.Type) throws -> RESPValue {
        
        if let value = value as? RESPValue {
            return value
        }
        
        if let value = value as? RESPValueConvertible {
            return value.convertedToRESPValue()
        }
        
        return try RedisEncoder.encoder.encode(value, as: RESPValue.self).convertedToRESPValue()
    }
}

extension BSONEncoder: RedisEncoderProtocol {
    
    public func encode<Value: Encodable>(_ value: Value, as: RESPValue.Type) throws -> RESPValue {
        return try self.encode(value).toData().convertedToRESPValue()
    }
}

extension JSONEncoder: RedisEncoderProtocol {
    
    public func encode<Value: Encodable>(_ value: Value, as: RESPValue.Type) throws -> RESPValue {
        return try self.encode(value).convertedToRESPValue()
    }
}

extension ExtendedJSONEncoder: RedisEncoderProtocol {
    
    public func encode<Value: Encodable>(_ value: Value, as: RESPValue.Type) throws -> RESPValue {
        return try self.encode(value).convertedToRESPValue()
    }
}
