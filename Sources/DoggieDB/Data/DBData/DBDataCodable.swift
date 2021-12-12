//
//  DBDataCodable.swift
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

extension DBData: Encodable {
    
    struct CodingKey: Swift.CodingKey {
        
        var stringValue: String
        
        var intValue: Int?
        
        init(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        init(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        
        switch self {
        case .null:
            
            var container = encoder.singleValueContainer()
            try container.encodeNil()
            
        case let .boolean(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .string(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .signed(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .unsigned(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .number(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .decimal(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .timestamp(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .date(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .binary(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .uuid(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .objectID(value):
            
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case let .array(value):
            
            var container = encoder.unkeyedContainer()
            try container.encode(contentsOf: value)
            
        case let .dictionary(value):
            
            var container = encoder.container(keyedBy: CodingKey.self)
            
            for (key, value) in value {
                try container.encode(value, forKey: CodingKey(stringValue: key))
            }
        }
    }
}

extension DBData: Decodable {
    
    private static func _decode_number(_ container: SingleValueDecodingContainer) -> DBData? {
        
        if let double = try? container.decode(Double.self) {
            
            if let uint64 = try? container.decode(UInt64.self), Double(uint64) == double {
                return .unsigned(uint64)
            } else if let int64 = try? container.decode(Int64.self), Double(int64) == double {
                return .signed(int64)
            } else if let decimal = try? container.decode(Decimal.self), decimal.doubleValue == double {
                return .decimal(decimal)
            } else {
                return .number(double)
            }
        }
        
        if let uint64 = try? container.decode(UInt64.self) {
            return .unsigned(uint64)
        }
        
        if let int64 = try? container.decode(Int64.self) {
            return .signed(int64)
        }
        
        if let decimal = try? container.decode(Decimal.self) {
            return .decimal(decimal)
        }
        
        return nil
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
            return
        }
        
        if let bool = try? container.decode(Bool.self) {
            self = .boolean(bool)
            return
        }
        
        if let number = DBData._decode_number(container) {
            self = number
            return
        }
        
        if let string = try? container.decode(String.self) {
            self = .string(string)
            return
        }
        
        if let timestamp = try? container.decode(Date.self) {
            self = .timestamp(timestamp)
            return
        }
        
        if let data = try? container.decode(Data.self) {
            self = .binary(data)
            return
        }
        
        if let uuid = try? container.decode(UUID.self) {
            self = .uuid(uuid)
            return
        }
        
        if let objectID = try? container.decode(BSONObjectID.self) {
            self = .objectID(objectID)
            return
        }
        
        if let array = try? container.decode([DBData].self) {
            self = .array(array)
            return
        }
        
        if let object = try? container.decode([String: DBData].self) {
            self = .dictionary(object)
            return
        }
        
        throw DecodingError.dataCorrupted(DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "Attempted to decode DBData from unknown structure.")
        )
    }
}
