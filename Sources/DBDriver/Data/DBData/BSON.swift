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

extension Dictionary where Key == String, Value == DBData {
    
    init(_ document: BSONDocument) throws {
        self.init()
        for (key, value) in document {
            self[key] = try DBData(value)
        }
    }
}

extension BSONDocument {
    
    public init(_ dictionary: [String: BSON]) {
        self.init()
        for (key, value) in dictionary {
            self[key] = value
        }
    }
    
    public init(_ dictionary: [String: DBData]) throws {
        try self.init(dictionary.mapValues(BSON.init))
    }
}

extension BSON {
    
    public init(_ document: BSONDocument) {
        self = .document(document)
    }
    
    public init(_ array: [BSONDocument]) {
        self = .array(array.map(BSON.init))
    }
    
    public init(_ array: [BSON]) {
        self = .array(array)
    }
}

extension DBData {
    
    init(_ value: BSON) throws {
        switch value {
        case .null: self = nil
        case .undefined: self = nil
        case let .int32(value): self.init(value)
        case let .int64(value): self.init(value)
        case let .double(value): self.init(value)
        case let .decimal128(value):
            
            let str = value.description
            
            switch str {
            case "Infinity": self.init(Double.infinity)
            case "-Infinity": self.init(-Double.infinity)
            case "NaN": self.init(Decimal.nan)
            default:
                guard let decimal = Decimal(string: str) else { throw Database.Error.unsupportedType }
                self.init(decimal)
            }
            
        case let .string(value): self.init(value)
        case let .document(value): try self.init(Dictionary(value))
        case let .array(value): try self.init(value.map(DBData.init))
        case let .binary(value):
            switch value.subtype {
            case .generic, .binaryDeprecated: self.init(value.data)
            case .uuidDeprecated, .uuid:
                
                guard let uuid = try? value.toUUID() else { throw Database.Error.unsupportedType }
                self.init(uuid)
                
            default: throw Database.Error.unsupportedType
            }
        case let .bool(value): self.init(value)
        case let .objectID(value): self.init(value.hex)
        case let .regex(value):
            
            guard let regex = try? value.toNSRegularExpression() else { throw Database.Error.unsupportedType }
            self.init(regex)
            
        case let .datetime(value): self.init(value)
        case let .timestamp(value): self.init(Date(timeIntervalSince1970: TimeInterval(value.timestamp + value.increment)))
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
        case let .regex(value): self = .regex(BSONRegularExpression(from: value.nsRegex))
        case let .signed(value): self = .int64(value)
        case let .unsigned(value):
            
            guard let int64 = Int64(exactly: value) else { throw Database.Error.unsupportedType }
            self = .int64(int64)
            
        case let .number(value): self = .double(value)
            
        case let .decimal(value):
            
            guard let decimal = try? BSONDecimal128("\(value)") else { throw Database.Error.unsupportedType }
            self = .decimal128(decimal)
            
        case let .date(value):
            
            guard let date = DBData.calendar.date(from: value) else { throw Database.Error.unsupportedType }
            self = .datetime(date)
            
        case let .binary(value): self = try .binary(BSONBinary(data: value, subtype: .generic))
        case let .uuid(value): self = try .binary(BSONBinary(from: value))
        case let .array(value): self = try .array(value.map(BSON.init))
        case let .dictionary(value): self = try .document(BSONDocument(value))
        }
    }
}
