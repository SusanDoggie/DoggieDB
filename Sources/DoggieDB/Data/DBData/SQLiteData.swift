//
//  SQLiteData.swift
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

import SQLiteNIO

extension DBData {
    
    init(_ value: SQLiteData) {
        switch value {
        case .null: self = nil
        case let .integer(value): self.init(value)
        case let .float(value): self.init(value)
        case let .text(value): self.init(value)
        case let .blob(value): self.init(Data(buffer: value))
        }
    }
}

extension SQLiteData {
    
    init(_ value: DBData) throws {
        switch value.base {
        case .null: self = .null
        case let .boolean(value): self = .integer(value ? 1 : 0)
        case let .string(value): self = .text(value)
            
        case let .signed(value):
            
            guard let _value = Int(exactly: value) else { throw Database.Error.unsupportedType }
            self = .integer(_value)
            
        case let .unsigned(value):
            
            guard let _value = Int(exactly: value) else { throw Database.Error.unsupportedType }
            self = .integer(_value)
            
        case let .number(value): self = .float(value)
        case let .decimal(value):
            
            guard let _value = Double(exactly: value) else { throw Database.Error.unsupportedType }
            self = .float(_value)
            
        case let .uuid(value): self = .text(value.uuidString)
        case let .binary(value): self = .blob(ByteBuffer(data: value))
        default: throw Database.Error.unsupportedType
        }
    }
}
