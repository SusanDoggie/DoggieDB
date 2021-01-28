//
//  BSON.swift
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

import MongoSwift

extension DBData {
    
    init(_ value: BSON) throws {
        switch value {
        case .null: self = nil
        case .undefined: self = nil
        case let .int32(value): self.init(value)
        case let .int64(value): self.init(value)
        case let .double(value): self.init(value)
        case let .decimal128(value):
            
            guard let decimal = Decimal(string: value.description) else { throw Database.Error.unsupportedType }
            self.init(decimal)
            
        case let .string(value): self.init(value)
        case let .document(value): self.init(Dictionary(value))
        case let .array(value): try self.init(value.map(DBData.init))
        case let .binary(value):
            switch value.subtype {
            case .generic, .binaryDeprecated: self.init(Data(buffer: value.data))
            case .uuidDeprecated, .uuid: try! self.init(value.toUUID())
            default: throw Database.Error.unsupportedType
            }
        case let .bool(value): self.init(value)
        case let .datetime(value): self.init(value)
        default: throw Database.Error.unsupportedType
        }
    }
}

extension BSON {
    
    init(_ value: DBData) throws {
        switch value.base {
        case .null: self = .null
        case let .boolean(value): self = .bool(value)
        case let .string(value): self = .string(value)
        case let .signed(value): self = .int64(value)
        case let .unsigned(value):
            
            guard let int64 = Int64(exactly: value) else { throw Database.Error.unsupportedType }
            self = .int64(int64)
            
        case let .number(value): self = .double(value)
            
        case let .decimal(value):
            
            guard let decimal = try? BSONDecimal128("\(value)") else { throw Database.Error.unsupportedType }
            self = .decimal128(decimal)
            
        case let .date(value):
            
            guard let date = value.date else { throw Database.Error.unsupportedType }
            self = .datetime(date)
            
        case let .binary(value): self = try .binary(BSONBinary(data: value, subtype: .generic))
        case let .uuid(value): self = try .binary(BSONBinary(from: value))
        case let .array(value): self = try .array(value.map(BSON.init))
        case let .dictionary(value): self = try .document(BSONDocument(value))
        }
    }
}
