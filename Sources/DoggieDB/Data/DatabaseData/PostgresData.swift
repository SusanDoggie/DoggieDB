//
//  PostgresData.swift
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

import PostgresNIO

extension DBData {
    
    init(_ value: PostgresData) throws {
        switch value.formatCode {
        case .binary:
            switch value.type {
            case .null: self = nil
            case .bool: self = value.bool.map { DBData($0) } ?? nil
            case .bytea: self = value.bytes.map { DBData(Data($0)) } ?? nil
            case .char: self = value.uint8.map { DBData($0) } ?? nil
            case .int8: self = value.int64.map { DBData($0) } ?? nil
            case .int2: self = value.int16.map { DBData($0) } ?? nil
            case .int4: self = value.int32.map { DBData($0) } ?? nil
                
            case .name,
                 .bpchar,
                 .varchar,
                 .text:
                
                self = value.string.map { DBData($0) } ?? nil
                
            case .float4: self = value.float.map { DBData($0) } ?? nil
            case .float8: self = value.double.map { DBData($0) } ?? nil
                
            case .money,
                 .numeric:
                
                self = value.decimal.map { DBData($0) } ?? nil
                
            case .date,
                 .timestamp,
                 .timestamptz:
                
                self = value.date.map { DBData($0) } ?? nil
                
            case .uuid: self = value.uuid.map { DBData($0) } ?? nil
                
            case .boolArray,
                 .byteaArray,
                 .charArray,
                 .nameArray,
                 .int2Array,
                 .int4Array,
                 .textArray,
                 .varcharArray,
                 .int8Array,
                 .pointArray,
                 .float4Array,
                 .float8Array,
                 .aclitemArray,
                 .uuidArray,
                 .jsonbArray:
                
                self = try value.array.map { try DBData($0.map { try DBData($0) }) } ?? nil
                
            case .json:
                
                guard let json = try? value.json(as: Json.self) else { throw Database.Error.unsupportedType }
                self = DBData(json)
                
            case .jsonb:
                
                guard let json = try? value.jsonb(as: Json.self) else { throw Database.Error.unsupportedType }
                self = DBData(json)
                
            default: throw Database.Error.unsupportedType
            }
        case .text: self = value.string.map { DBData($0) } ?? nil
        }
    }
}

extension PostgresData {
    
    init(_ value: DBData) throws {
        switch value.base {
        case .null: self = .null
        case let .boolean(value): self.init(bool: value)
        case let .string(value): self.init(string: value)
        case let .signed(value): self.init(int64: value)
        case let .unsigned(value):
            
            guard let int = Int64(exactly: value) else { throw Database.Error.unsupportedType }
            self.init(int64: int)
            
        case let .number(value): self.init(double: value)
        case let .decimal(value): self.init(decimal: value)
        case let .date(value):
            
            if let date = value.date {
                self.init(date: date)
            } else {
                throw Database.Error.unsupportedType
            }
            
        case let .binary(value): self.init(bytes: value)
        case let .uuid(value): self.init(uuid: value)
        case let .array(value):
            
            if let (array, elementType) = value._postgresArray {
                
                self.init(array: array, elementType: elementType)
                
            } else {
                
                guard let json = try? PostgresData(jsonb: value) else { throw Database.Error.unsupportedType }
                self = json
            }
            
        case let .dictionary(value):
            
            guard let json = try? PostgresData(jsonb: value) else { throw Database.Error.unsupportedType }
            self = json
            
        default: throw Database.Error.unsupportedType
        }
    }
}

extension DBData {
    
    fileprivate var _elementType: PostgresDataType? {
        switch self.base {
        case .boolean: return .bool
        case .binary: return .bytea
        case .string: return .text
        case .signed: return .int8
        case .unsigned: return .int8
        case .number: return .float8
        case .uuid: return .uuid
        case .array: return .jsonb
        case .dictionary: return .jsonb
        default: return nil
        }
    }
}

extension Array where Element == DBData {
    
    fileprivate var _postgresArray: ([PostgresData], PostgresDataType)? {
        guard let type = self.first?._elementType else { return nil }
        guard self.dropFirst().allSatisfy({ $0._elementType == type }) else { return nil }
        guard let array = try? self.map({ try PostgresData($0) }) else { return nil }
        return (array, type)
    }
}
