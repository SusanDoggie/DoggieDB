//
//  MySQLData.swift
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

@_implementationOnly import Private
import MySQLNIO

extension DBData {
    
    init(_ value: MySQLData) throws {
        switch value.type {
        case .null: self = nil
            
        case .tiny,
             .bit:
            
            if value.isUnsigned {
                guard let value = value.uint8 else { throw Database.Error.unsupportedType }
                self = DBData(value)
            } else {
                guard let value = value.int8 else { throw Database.Error.unsupportedType }
                self = DBData(value)
            }
            
        case .short:
            
            if value.isUnsigned {
                guard let value = value.uint16 else { throw Database.Error.unsupportedType }
                self = DBData(value)
            } else {
                guard let value = value.int16 else { throw Database.Error.unsupportedType }
                self = DBData(value)
            }
            
        case .int24, .long:
            
            if value.isUnsigned {
                guard let value = value.uint32 else { throw Database.Error.unsupportedType }
                self = DBData(value)
            } else {
                guard let value = value.int32 else { throw Database.Error.unsupportedType }
                self = DBData(value)
            }
            
        case .longlong:
            
            if value.isUnsigned {
                guard let value = value.uint64 else { throw Database.Error.unsupportedType }
                self = DBData(value)
            } else {
                guard let value = value.int64 else { throw Database.Error.unsupportedType }
                self = DBData(value)
            }
            
        case .float:
            
            guard let float = value.float else { throw Database.Error.unsupportedType }
            self = DBData(float)
            
        case .double:
            
            guard let double = value.double else { throw Database.Error.unsupportedType }
            self = DBData(double)
            
        case .decimal,
             .newdecimal:
            
            guard let decimal = value.decimal else { throw Database.Error.unsupportedType }
            self = DBData(decimal)
            
        case .varchar,
             .varString,
             .string:
            
            guard let string = value.string else { throw Database.Error.unsupportedType }
            self = DBData(string)
            
        case .timestamp,
             .datetime,
             .date,
             .time,
             .newdate,
             .timestamp2,
             .datetime2,
             .time2:
            
            guard let time = value.time else { throw Database.Error.unsupportedType }
                
            let calendar = Calendar(identifier: .iso8601)
            let timeZone = TimeZone(secondsFromGMT: 0)!
            
            let dateComponents = DateComponents(
                calendar: calendar,
                timeZone: timeZone,
                year: time.year.map(Int.init),
                month: time.month.map(Int.init),
                day: time.day.map(Int.init),
                hour: time.hour.map(Int.init),
                minute: time.minute.map(Int.init),
                second: time.second.map(Int.init),
                nanosecond: time.microsecond.map { Int($0) * 1000 }
            )
            
            if dateComponents.containsDate() && dateComponents.containsTime(), let date = Calendar.iso8601.date(from: dateComponents) {
                self.init(date)
            } else {
                self.init(dateComponents)
            }
            
        case .tinyBlob,
             .mediumBlob,
             .longBlob,
             .blob:
            
            guard let buffer = value.buffer else { throw Database.Error.unsupportedType }
            self = DBData(buffer)
            
        case .json:
            
            guard let json = try? value.json(as: Json.self) else { throw Database.Error.unsupportedType }
            self = DBData(json)
            
        default:
            
            switch value.format {
            case .text:
                
                guard let string = value.string else { throw Database.Error.unsupportedType }
                self = DBData(string)
                
            case .binary: throw Database.Error.unsupportedType
            }
        }
    }
}

extension MySQLData {
    
    init(_ value: DBData) throws {
        switch value.base {
        case .null: self = .null
        case let .boolean(value): self.init(bool: value)
        case let .string(value): self.init(string: value)
        case let .signed(value):
            
            guard let int = Int(exactly: value) else { throw Database.Error.unsupportedType }
            self.init(int: int)
            
        case let .unsigned(value):
            
            guard let int = Int(exactly: value) else { throw Database.Error.unsupportedType }
            self.init(int: int)
            
        case let .number(value): self.init(double: value)
        case let .decimal(value): self.init(decimal: value)
        case let .timestamp(value): self.init(date: value)
        case let .date(value):
            
            let calendar = value.calendar ?? Calendar.iso8601
            
            if !value.containsDate() && value.containsTime() {
                
                var value = value
                value.timeZone = value.timeZone ?? calendar.timeZone
                value.year = 2000
                value.month = 1
                value.day = 1
                
                guard let date = calendar.date(from: value) else { throw Database.Error.unsupportedType }
                
                let utc_time = Calendar.iso8601.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
                
                self.init(time: MySQLTime(
                    hour: utc_time.hour.map(UInt16.init),
                    minute: utc_time.minute.map(UInt16.init),
                    second: utc_time.second.map(UInt16.init),
                    microsecond: utc_time.nanosecond.map { UInt32($0 / 1000) }
                ))
                
            } else if value.containsDate() && !value.containsTime() {
                
                var value = value
                value.timeZone = value.timeZone ?? calendar.timeZone
                
                guard let date = calendar.date(from: value) else { throw Database.Error.unsupportedType }
                
                let utc_time = Calendar.iso8601.dateComponents([.year, .month, .day], from: date)
                
                self.init(time: MySQLTime(
                    year: utc_time.year.map(UInt16.init),
                    month: utc_time.month.map(UInt16.init),
                    day: utc_time.day.map(UInt16.init)
                ))
                
            } else if let date = calendar.date(from: value) {
                self.init(date: date)
            } else {
                throw Database.Error.unsupportedType
            }
            
        case let .binary(value): self.init(type: .blob, buffer: ByteBuffer(data: value))
        case let .uuid(value): self.init(uuid: value)
        case let .objectID(value): self.init(string: value.hex)
        case let .array(value):
            
            guard let json = try? MySQLData(json: value) else { throw Database.Error.unsupportedType }
            self = json
            
        case let .dictionary(value):
            
            guard let json = try? MySQLData(json: Dictionary(value)) else { throw Database.Error.unsupportedType }
            self = json
            
        default: throw Database.Error.unsupportedType
        }
    }
}
