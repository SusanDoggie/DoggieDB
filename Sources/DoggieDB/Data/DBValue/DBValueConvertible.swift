//
//  DBValueConvertible.swift
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

public protocol DBValueConvertible {
    
    func toDBValue() -> DBValue
}

extension DBValue: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return self
    }
}

extension Optional: DBValueConvertible where Wrapped: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return self?.toDBValue() ?? nil
    }
}

extension Bool: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

extension SignedInteger where Self: FixedWidthInteger {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

extension UnsignedInteger where Self: FixedWidthInteger {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

extension UInt: DBValueConvertible { }
extension UInt8: DBValueConvertible { }
extension UInt16: DBValueConvertible { }
extension UInt32: DBValueConvertible { }
extension UInt64: DBValueConvertible { }
extension Int: DBValueConvertible { }
extension Int8: DBValueConvertible { }
extension Int16: DBValueConvertible { }
extension Int32: DBValueConvertible { }
extension Int64: DBValueConvertible { }

extension BinaryFloatingPoint {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

#if swift(>=5.3) && !os(macOS) && !targetEnvironment(macCatalyst)

@available(iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension Float16: DBValueConvertible { }

#endif

extension float16: DBValueConvertible { }
extension Float: DBValueConvertible { }
extension Double: DBValueConvertible { }

extension Decimal: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

extension StringProtocol {
    
    public func toDBValue() -> DBValue {
        return DBValue(String(self))
    }
}

extension String: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

extension Substring: DBValueConvertible { }

extension Date: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

extension Data: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

extension ByteBuffer: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

extension ByteBufferView: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

extension DateComponents: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

extension UUID: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

extension BSONObjectID: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

extension NSRegularExpression: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

extension Regex: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

extension Array: DBValueConvertible where Element: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

extension Dictionary: DBValueConvertible where Key == String, Value: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}

extension OrderedDictionary: DBValueConvertible where Key == String, Value: DBValueConvertible {
    
    public func toDBValue() -> DBValue {
        return DBValue(self)
    }
}
