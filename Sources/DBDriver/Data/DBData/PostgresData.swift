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

import Utils
import PostgresNIO

private let psqlDateStart = Date(timeIntervalSince1970: 946_684_800)
private let secondsInDay: TimeInterval = 24 * 60 * 60

extension PostgresData {
    
    static func _decodeDateString(_ string: String) -> DateComponents? {
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        
        return formatter.date(from: string).map { Calendar.iso8601.dateComponents(Calendar.componentsOfDate, from: $0) }
    }
    
    static func _decodeTimeString(_ string: String, withTimeZone: Bool) -> DateComponents? {
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullTime]
        
        if withTimeZone {
            formatter.formatOptions.formUnion(.withTimeZone)
        }
        
        if let timestamp = formatter.date(from: withTimeZone ? string : "\(string)Z") {
            return Calendar.iso8601.dateComponents(Calendar.componentsOfTime, from: timestamp)
        }
        
        formatter.formatOptions.formUnion(.withFractionalSeconds)
        
        return formatter.date(from: withTimeZone ? string : "\(string)Z").map { Calendar.iso8601.dateComponents(Calendar.componentsOfTime, from: $0) }
    }
    
    static func _decodeTimestampString(_ string: String, withTimeZone: Bool) -> Date? {
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withSpaceBetweenDateAndTime]
        
        if withTimeZone {
            formatter.formatOptions.formUnion(.withTimeZone)
        }
        
        if let timestamp = formatter.date(from: withTimeZone ? string : "\(string)Z") {
            return timestamp
        }
        
        formatter.formatOptions.formUnion(.withFractionalSeconds)
        
        return formatter.date(from: withTimeZone ? string : "\(string)Z")
    }
}

extension DBData {
    
    init(_ value: PostgresData) throws {
        switch value.type {
        case .null: self = nil
        case .bool:
            
            guard let bool = value.bool else { throw Database.Error.unsupportedType }
            self = DBData(bool)
            
        case .bytea:
            
            guard let bytes = value.bytes else { throw Database.Error.unsupportedType }
            self = DBData(Data(bytes))
            
        case .char:
            
            guard let value = value.uint8 else { throw Database.Error.unsupportedType }
            self = DBData(value)
            
        case .int8:
            
            guard let value = value.int64 else { throw Database.Error.unsupportedType }
            self = DBData(value)
            
        case .int2:
            
            guard let value = value.int16 else { throw Database.Error.unsupportedType }
            self = DBData(value)
            
        case .int4:
            
            guard let value = value.int32 else { throw Database.Error.unsupportedType }
            self = DBData(value)
            
            
        case .name,
             .bpchar,
             .varchar,
             .text:
            
            guard let string = value.string else { throw Database.Error.unsupportedType }
            self = DBData(string)
            
        case .float4:
            
            guard let float = value.float else { throw Database.Error.unsupportedType }
            self = DBData(float)
            
        case .float8:
            
            guard let double = value.double else { throw Database.Error.unsupportedType }
            self = DBData(double)
            
        case .money,
             .numeric:
            
            guard let decimal = value.decimal else { throw Database.Error.unsupportedType }
            self = DBData(decimal)
            
        case .date:
            
            switch value.formatCode {
            case .text:
                
                guard let string = value.string else { throw Database.Error.unsupportedType }
                guard let dateComponents = PostgresData._decodeDateString(string) else { throw Database.Error.unsupportedType }
                
                self = DBData(dateComponents)
                
            case .binary:
                self = value.date.map { DBData($0) } ?? nil
            }
            
        case .time:
            
            switch value.formatCode {
            case .text:
                
                guard let string = value.string else { throw Database.Error.unsupportedType }
                guard let dateComponents = PostgresData._decodeTimeString(string, withTimeZone: false) else { throw Database.Error.unsupportedType }
                
                self = DBData(dateComponents)
                
            case .binary:
                
                guard var value = value.value else { throw Database.Error.unsupportedType }
                
                let microseconds = value.readInteger(as: Int64.self)!
                
                let dateComponents = DateComponents(
                    calendar: Calendar.iso8601,
                    timeZone: TimeZone(secondsFromGMT: 0),
                    hour: Int(microseconds / 3_600_000_000) % 60,
                    minute: Int(microseconds / 60_000_000) % 60,
                    second: Int(microseconds / 1_000_000) % 60,
                    nanosecond: Int(microseconds % 1_000_000) * 1000)
                
                self = DBData(dateComponents)
            }
            
        case .timetz:
            
            switch value.formatCode {
            case .text:
                
                guard let string = value.string else { throw Database.Error.unsupportedType }
                guard let dateComponents = PostgresData._decodeTimeString(string, withTimeZone: true) else { throw Database.Error.unsupportedType }
                
                self = DBData(dateComponents)
                
            case .binary:
                
                guard var value = value.value else { throw Database.Error.unsupportedType }
                
                let microseconds = value.readInteger(as: Int64.self)!
                let zone = value.readInteger(as: Int32.self)!
                
                let timeZone = TimeZone(secondsFromGMT: Int(-zone))!
                
                var calendar = Calendar.iso8601
                calendar.timeZone = timeZone
                
                let dateComponents = DateComponents(
                    calendar: calendar,
                    timeZone: timeZone,
                    hour: Int(microseconds / 3_600_000_000) % 60,
                    minute: Int(microseconds / 60_000_000) % 60,
                    second: Int(microseconds / 1_000_000) % 60,
                    nanosecond: Int(microseconds % 1_000_000) * 1000)
                
                self = DBData(dateComponents)
            }
            
        case .timestamp:
            
            switch value.formatCode {
            case .text:
                
                guard let string = value.string else { throw Database.Error.unsupportedType }
                guard let date = PostgresData._decodeTimestampString(string, withTimeZone: false) else { throw Database.Error.unsupportedType }
                
                self = DBData(date)
                
            case .binary:
                self = value.date.map { DBData($0) } ?? nil
            }
            
        case .timestamptz:
            
            switch value.formatCode {
            case .text:
                
                guard let string = value.string else { throw Database.Error.unsupportedType }
                guard let date = PostgresData._decodeTimestampString(string, withTimeZone: true) else { throw Database.Error.unsupportedType }
                
                self = DBData(date)
                
            case .binary:
                self = value.date.map { DBData($0) } ?? nil
            }
            
        case .uuid:
            
            guard let uuid = value.uuid else { throw Database.Error.unsupportedType }
            self = DBData(uuid)
            
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
             .jsonbArray:
            
            guard let array = value.array else { throw Database.Error.unsupportedType }
            self = try DBData(array.map { try DBData($0) })
            
        case .json:
            
            guard let json = try? value.json(as: Json.self) else { throw Database.Error.unsupportedType }
            self = DBData(json)
            
        case .jsonb:
            
            guard let json = try? value.jsonb(as: Json.self) else { throw Database.Error.unsupportedType }
            self = DBData(json)
            
        default:
            
            switch value.formatCode {
            case .text:
                
                guard let string = value.string else { throw Database.Error.unsupportedType }
                self = DBData(string)
                
            case .binary: throw Database.Error.unsupportedType
            }
        }
    }
}

extension PostgresData {
    
    init(_ value: DBData) throws {
        switch value.base {
        case .null: self = .null
        case let .boolean(value): self.init(bool: value)
        case let .string(value): self.init(string: value)
        case let .signed(value): self.init(int64: value)
        case let .unsigned(value):
            
            guard let int = Int64(exactly: value) else { throw Database.Error.unsupportedType }
            self.init(int64: int)
            
        case let .number(value): self.init(double: value)
        case let .decimal(value): self.init(decimal: value)
        case let .timestamp(value): self.init(date: value)
        case let .date(value):
            
            let calendar = value.calendar ?? Calendar.iso8601
            
            if !value.containsDate() && value.containsTime() {
                
                let hour = value.hour.map(Int64.init) ?? 0
                let minute = value.minute.map(Int64.init) ?? 0
                let second = value.second.map(Int64.init) ?? 0
                let microsecond = value.nanosecond.map { Int64($0 / 1000) } ?? 0
                
                let time = ((hour * 60 + minute) * 60 + second) * 1_000_000 + microsecond
                
                var buffer = ByteBufferAllocator().buffer(capacity: value.timeZone == nil ? 8 : 12)
                buffer.writeInteger(time)
                
                if let timeZone = value.timeZone {
                    buffer.writeInteger(Int32(-timeZone.secondsFromGMT()))
                }
                
                self.init(type: value.timeZone == nil ? .time : .timetz, formatCode: .binary, value: buffer)
                
            } else if value.containsDate() && !value.containsTime() {
                
                var value = value
                value.timeZone = value.timeZone ?? calendar.timeZone
                
                guard let date = calendar.date(from: value) else { throw Database.Error.unsupportedType }
                
                let days = Int32(floor(date.timeIntervalSince(psqlDateStart) / secondsInDay))
                
                var buffer = ByteBufferAllocator().buffer(capacity: 4)
                buffer.writeInteger(days)
                self.init(type: .date, formatCode: .binary, value: buffer)
                
            } else if let date = calendar.date(from: value) {
                self.init(date: date)
            } else {
                throw Database.Error.unsupportedType
            }
            
        case let .binary(value): self.init(bytes: value)
        case let .uuid(value): self.init(uuid: value)
        case let .array(value):
            
            if let (array, elementType) = value._postgresArray {
                
                self.init(array: array, elementType: elementType)
                
            } else {
                
                guard let json = try? PostgresData(jsonb: value) else { throw Database.Error.unsupportedType }
                self = json
            }
            
        case let .dictionary(value):
            
            guard let json = try? PostgresData(jsonb: value) else { throw Database.Error.unsupportedType }
            self = json
            
        default: throw Database.Error.unsupportedType
        }
    }
}

extension DBData {
    
    fileprivate var _elementType: PostgresDataType? {
        switch self.base {
        case .boolean: return .bool
        case .binary: return .bytea
        case .string: return .text
        case .signed: return .int8
        case .unsigned: return .int8
        case .number: return .float8
        case .uuid: return .uuid
        case .array: return .jsonb
        case .dictionary: return .jsonb
        default: return nil
        }
    }
}

extension Array where Element == DBData {
    
    fileprivate var _postgresArray: ([PostgresData], PostgresDataType)? {
        guard let type = self.first?._elementType else { return nil }
        guard self.dropFirst().allSatisfy({ $0._elementType == type }) else { return nil }
        guard let array = try? self.map({ try PostgresData($0) }) else { return nil }
        return (array, type)
    }
}
