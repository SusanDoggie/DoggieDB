//
//  RESPValue.swift
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

import Utils
import RediStack

extension DBData {
    
    init(_ value: RESPValue) throws {
        switch value {
        case .null: self = nil
            
        case let .simpleString(buffer),
             let .bulkString(.some(buffer)):
            
            if let value = String(fromRESP: value) {
                self.init(value)
            } else {
                self.init(buffer)
            }
            
        case .bulkString(.none): self.init(Data())
            
        case let .integer(value): self.init(value)
        case let .array(array): try self.init(array.map(DBData.init))
        case let .error(error): throw error
        }
    }
}

extension RESPValue {
    
    init(_ value: DBData) throws {
        switch value.base {
        case .null: self = .null
        case let .boolean(value): self = .integer(value ? 1 : 0)
        case let .string(value): self = value.convertedToRESPValue()
        case let .signed(value): self = value.convertedToRESPValue()
        case let .unsigned(value): self = value.convertedToRESPValue()
        case let .number(value): self = value.convertedToRESPValue()
        case let .decimal(value): self = "\(value)".convertedToRESPValue()
        case let .timestamp(value):
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = .withInternetDateTime
            
            self = formatter.string(from: value).convertedToRESPValue()
            
        case let .date(value):
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = .withInternetDateTime
            
            let calendar = value.calendar ?? Calendar.iso8601
            guard let date = calendar.date(from: value) else { throw Database.Error.unsupportedType }
            
            self = formatter.string(from: date).convertedToRESPValue()
            
        case let .binary(value): self = value.convertedToRESPValue()
        case let .uuid(value): self = value.uuidString.convertedToRESPValue()
        case let .objectID(value): self = value.hex.convertedToRESPValue()
        case let .array(value): self = try value.map(RESPValue.init).convertedToRESPValue()
        default: throw Database.Error.unsupportedType
        }
    }
}
