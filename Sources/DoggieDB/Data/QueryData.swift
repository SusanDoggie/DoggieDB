//
//  QueryData.swift
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

public protocol QueryDataConvertable {
    
}

public struct QueryData {
    
    let value: QueryDataConvertable
    
    public init<C: QueryDataConvertable>(_ value: C) {
        self.value = value
    }
}

extension Optional: QueryDataConvertable where Wrapped: QueryDataConvertable {
    
}

extension Bool: QueryDataConvertable {
    
}

extension Int8: QueryDataConvertable {
    
}

extension Int16: QueryDataConvertable {
    
}

extension Int32: QueryDataConvertable {
    
}

extension Int64: QueryDataConvertable {
    
}

extension Int: QueryDataConvertable {
    
}

extension UInt8: QueryDataConvertable {
    
}

extension UInt16: QueryDataConvertable {
    
}

extension UInt32: QueryDataConvertable {
    
}

extension UInt64: QueryDataConvertable {
    
}

extension UInt: QueryDataConvertable {
    
}

extension Float: QueryDataConvertable {
    
}

extension Double: QueryDataConvertable {
    
}

extension Decimal: QueryDataConvertable {
    
}

extension String: QueryDataConvertable {
    
}

extension Data: QueryDataConvertable {
    
}

extension UUID: QueryDataConvertable {
    
}

extension Date: QueryDataConvertable {
    
}
