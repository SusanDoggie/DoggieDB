//
//  DBTimestamp.swift
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

public enum DBTimestampTrigger {
    
    case create
    case update
    case delete
    case none
}

public protocol DBTimestamp {
    
    init(_ date: Date)
}

extension Date: DBTimestamp {
    
    public init(_ date: Date) {
        self = date
    }
}

extension DateComponents: DBTimestamp {
    
    public init(_ date: Date) {
        self = Calendar.iso8601.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)
    }
}

extension Optional: DBTimestamp where Wrapped: DBTimestamp {
    
    public init(_ date: Date) {
        self = .some(Wrapped(date))
    }
}

extension DBField where Value: DBTimestamp {
    
    public init(
        name: String,
        type: String? = nil,
        isUnique: Bool = false,
        withTimeZone: Bool = false,
        on trigger: DBTimestampTrigger = .none,
        default: Default? = nil
    ) {
        self.name = name
        self.type = type
        self.isUnique = isUnique
        self.default = `default`
        self.modifier = withTimeZone ? [.withTimeZone] : []
        self.trigger = trigger
    }
    
    public var withTimeZone: Bool {
        return self.modifier.contains(.withTimeZone)
    }
}