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
    
    init(_ value: PostgresData) {
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
                 .text: self = value.string.map { DBData($0) } ?? nil
                
            case .float4: self = value.float.map { DBData($0) } ?? nil
            case .float8: self = value.double.map { DBData($0) } ?? nil
                
            case .money,
                 .numeric: self = value.decimal.map { DBData($0) } ?? nil
                
            case .date,
                 .timestamp,
                 .timestamptz: self = value.date.map { DBData($0) } ?? nil
                
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
                 .jsonbArray: self = value.array.map { DBData($0.map { DBData($0) }) } ?? nil
                
            case .json:
                
                if let json = try? value.json(as: Json.self) {
                    self = DBData(json)
                } else {
                    self = nil
                }
                
            case .jsonb:
                
                if let json = try? value.jsonb(as: Json.self) {
                    self = DBData(json)
                } else {
                    self = nil
                }
                
            case .regproc:
            case .oid:
            case .pgNodeTree:
            case .point:
            case .time:
            case .timetz:
            case .timestampArray:
            }
        case .text: self = value.string.map { DBData($0) } ?? nil
        }
    }
}

extension PostgresData {
    
    init(_ value: DBData) throws {
        
    }
}
