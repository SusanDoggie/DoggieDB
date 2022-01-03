//
//  Calendar.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2022 Susan Cheng. All rights reserved.
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

extension Calendar {
    
    @usableFromInline
    static let iso8601: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
}

extension Calendar {
    
    static var componentsOfDate: Set<Calendar.Component> {
        return [
            .era,
            .year,
            .month,
            .day,
            .weekday,
            .weekdayOrdinal,
            .quarter,
            .weekOfMonth,
            .weekOfYear,
            .yearForWeekOfYear,
        ]
    }
    
    static var componentsOfTime: Set<Calendar.Component> {
        return [
            .hour,
            .minute,
            .second,
            .nanosecond,
            .timeZone,
        ]
    }
    
    static var componentsOfTimestamp: Set<Calendar.Component> {
        return [
            .era,
            .year,
            .month,
            .day,
            .hour,
            .minute,
            .second,
            .nanosecond,
            .weekday,
            .weekdayOrdinal,
            .quarter,
            .weekOfMonth,
            .weekOfYear,
            .yearForWeekOfYear,
            .timeZone,
        ]
    }
}
