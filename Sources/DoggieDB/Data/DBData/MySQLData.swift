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

import MySQLNIO

extension DBData {
    
    init(_ value: MySQLData) throws {
        switch value.type {
        case .null: self = nil
            
        case .tiny,
             .bit:
            if value.isUnsigned {
                self = value.uint8.map { DBData($0) } ?? nil
            } else {
                self = value.int8.map { DBData($0) } ?? nil
            }
        case .short:
            if value.isUnsigned {
                self = value.uint16.map { DBData($0) } ?? nil
            } else {
                self = value.int16.map { DBData($0) } ?? nil
            }
        case .long:
            if value.isUnsigned {
                self = value.uint32.map { DBData($0) } ?? nil
            } else {
                self = value.int32.map { DBData($0) } ?? nil
            }
        case .int24:
            if value.isUnsigned {
                self = value.uint32.map { DBData($0) } ?? nil
            } else {
                self = value.int32.map { DBData($0) } ?? nil
            }
        case .longlong:
            if value.isUnsigned {
                self = value.uint64.map { DBData($0) } ?? nil
            } else {
                self = value.int64.map { DBData($0) } ?? nil
            }
        case .float: self = value.float.map { DBData($0) } ?? nil
        case .double: self = value.double.map { DBData($0) } ?? nil
            
        case .decimal,
             .newdecimal:
            
            self = value.decimal.map { DBData($0) } ?? nil
            
        case .varchar,
             .varString,
             .string:
            
            self = value.string.map { DBData($0) } ?? nil
            
        case .timestamp,
             .datetime,
             .date,
             .time,
             .newdate,
             .timestamp2,
             .datetime2,
             .time2:
            
            if let time = value.time {
                
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
                
                self.init(dateComponents)
                
            } else {
                self = nil
            }
            
        case .tinyBlob,
             .mediumBlob,
             .longBlob,
             .blob:
            
            self = value.buffer.map { DBData(Data(buffer: $0)) } ?? nil
            
        case .json:
            
            guard let json = try? value.json(as: Json.self) else { throw Database.Error.unsupportedType }
            self = DBData(json)
            
        default: throw Database.Error.unsupportedType
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
        case let .date(value):
            
            let calendar = value.calendar ?? DBData.calendar
            
            if !value.containsDate() && value.containsTime() {
                
                var value = value
                value.timeZone = .current
                value.year = 2000
                value.month = 1
                value.day = 1
                
                guard let date = calendar.date(from: value) else { throw Database.Error.unsupportedType }
                
                let utc_time = DBData.calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
                
                self.init(time: MySQLTime(
                    hour: utc_time.hour.map(UInt16.init),
                    minute: utc_time.minute.map(UInt16.init),
                    second: utc_time.second.map(UInt16.init),
                    microsecond: utc_time.nanosecond.map { UInt32($0 / 1000) }
                ))
                
            } else if value.containsDate() && !value.containsTime() {
                
                var value = value
                value.timeZone = .current
                
                guard let date = calendar.date(from: value) else { throw Database.Error.unsupportedType }
                
                let utc_time = DBData.calendar.dateComponents([.year, .month, .day], from: date)
                
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
        case let .array(value):
            
            guard let json = try? MySQLData(json: value) else { throw Database.Error.unsupportedType }
            self = json
            
        case let .dictionary(value):
            
            guard let json = try? MySQLData(json: value) else { throw Database.Error.unsupportedType }
            self = json
            
        default: throw Database.Error.unsupportedType
        }
    }
}
