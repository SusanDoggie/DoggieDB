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
    
    init(_ value: BSON) {
        switch value {
        case .null: self = nil
        case .undefined: self = nil
        case let .int32(value): self.init(value)
        case let .int64(value): self.init(value)
        case let .double(value): self.init(value)
        case let .decimal128(value):
            if let decimal = Decimal(string: value.description) {
                self.init(decimal)
            } else {
                self.init(type: "BSONDecimal128", value: DBData(value.description))
            }
        case let .string(value): self.init(value)
        case let .document(value): self.init(Dictionary(value))
        case let .array(value): self.init(value.map(DBData.init))
        case let .binary(value):
            switch value.subtype {
            case .generic, .binaryDeprecated: self.init(Data(buffer: value.data))
            case .uuidDeprecated, .uuid: try! self.init(value.toUUID())
            default: self.init(type: "BSONBinary", value: ["subtype": DBData(value.subtype.rawValue), "data": DBData(Data(buffer: value.data))])
            }
        case let .objectID(value): self.init(type: "BSONObjectID", value: DBData(value.hex))
        case let .bool(value): self.init(value)
        case let .datetime(value): self.init(value)
        case let .regex(value): self.init(type: "BSONRegularExpression", value: ["pattern": DBData(value.pattern), "options": DBData(value.options)])
        case let .dbPointer(value): self.init(type: "BSONPointer", value: ["ref": DBData(value.ref), "id": DBData(value.id.hex)])
        case let .symbol(value): self.init(type: "BSONSymbol", value: DBData(value.stringValue))
        case let .code(value): self.init(type: "BSONCode", value: DBData(value.code))
        case let .codeWithScope(value): self.init(type: "BSONCodeWithScope", value: ["scope": DBData(Dictionary(value.scope)), "code": DBData(value.code)])
        case let .timestamp(value): self.init(type: "BSONTimestamp", value: ["timestamp": DBData(value.timestamp), "increment": DBData(value.increment)])
        case .minKey: self.init(type: "BSONMinKey", value: [:])
        case .maxKey: self.init(type: "BSONMaxKey", value: [:])
        }
    }
}

extension BSON {
    
    init(_ value: DBData) throws {
        switch value.base {
        case .null: self = .undefined
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
        case let .dictionary(value):self = try .document(BSONDocument(value))
        case let .custom("BSONDecimal128", value):
            
            guard let decimal = try? value.string.map(BSONDecimal128.init) else { throw Database.Error.unsupportedType }
            self = .decimal128(decimal)
            
        case let .custom("BSONBinary", value):
            
            guard let subtype = try? value["subtype"].intValue.map(BSONBinary.Subtype.userDefined) else { throw Database.Error.unsupportedType }
            guard let data = value["data"].binary else { throw Database.Error.unsupportedType }
            guard let binary = try? BSONBinary(data: data, subtype: subtype) else { throw Database.Error.unsupportedType }
            self = .binary(binary)
            
        case let .custom("BSONObjectID", value):
            
            guard let objectId = try? value.string.map(BSONObjectID.init) else { throw Database.Error.unsupportedType }
            self = .objectID(objectId)
            
        case let .custom("BSONRegularExpression", value):
            
            guard let pattern = value["pattern"].string, let options = value["options"].string else { throw Database.Error.unsupportedType }
            self = .regex(BSONRegularExpression(pattern: pattern, options: options))
            
        case let .custom("BSONCode", value):
            
            guard let code = value.string.map(BSONCode.init) else { throw Database.Error.unsupportedType }
            self = .code(code)
            
        case let .custom("BSONCodeWithScope", value):
            
            guard let scope = try? value["scope"].dictionary.map(BSONDocument.init), let code = value["code"].string else { throw Database.Error.unsupportedType }
            self = .codeWithScope(BSONCodeWithScope(code: code, scope: scope))
            
        case let .custom("BSONTimestamp", value):
            
            guard let timestamp = value["timestamp"].uint32Value, let increment = value["increment"].uint32Value else { throw Database.Error.unsupportedType }
            self = .timestamp(BSONTimestamp(timestamp: timestamp, inc: increment))
            
        case .custom("BSONMinKey", [:]): self = .minKey
        case .custom("BSONMaxKey", [:]): self = .maxKey
        default: throw Database.Error.unsupportedType
        }
    }
}
