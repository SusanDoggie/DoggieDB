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
        case let .string(value): self.init(value)
        case let .document(value): self.init(value)
        case let .array(value): self.init(value.map(DBData.init))
        case let .binary(value):
            switch value.subtype {
            case .generic, .binaryDeprecated: self.init(Data(buffer: value.data))
            case .uuidDeprecated, .uuid:
            case .md5:
            default: self.init(type: "BSONBinary", value: ["subtype": DBData(value.subtype.rawValue), "data": DBData(Data(buffer: value.data))])
            }
        case let .objectID(value): self.init(type: "BSONObjectID", value: DBData(value.hex))
        case let .bool(value): self.init(value)
        case let .datetime(value): self.init(value)
        case let .regex(value): self.init(type: "BSONRegularExpression", value: ["pattern": DBData(value.pattern), "options": DBData(value.options)])
        case let .dbPointer(value): self.init(type: "BSONPointer", value: ["ref": DBData(value.ref), "id": DBData(value.id.hex)])
        case let .symbol(value): self.init(type: "BSONSymbol", value: DBData(value.stringValue))
        case let .code(value): self.init(type: "BSONCode", value: DBData(value.code))
        case let .codeWithScope(value): self.init(type: "BSONCodeWithScope", value: ["scope": DBData(value.scope), "code": DBData(value.code)])
        case let .timestamp(value):
        case .minKey: self.init(type: "BSONMinKey", value: [:])
        case .maxKey: self.init(type: "BSONMaxKey", value: [:])
        }
    }
}

extension BSON {
    
    init(_ value: DBData) throws {
        
    }
}
