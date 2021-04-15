//
//  BSONConvertible.swift
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

public protocol BSONConvertible {
    
    func toBSON() -> BSON
}

extension BSON: BSONConvertible {
    
    public func toBSON() -> BSON {
        return self
    }
}

extension BSONDocument: BSONConvertible {
    
    public func toBSON() -> BSON {
        return BSON(self)
    }
}

extension Optional: BSONConvertible where Wrapped: BSONConvertible {
    
    public func toBSON() -> BSON {
        return self?.toBSON() ?? .null
    }
}

extension Bool: BSONConvertible {
    
    public func toBSON() -> BSON {
        return .bool(self)
    }
}

extension SignedInteger where Self: FixedWidthInteger {
    
    public func toBSON() -> BSON {
        return MemoryLayout<Self>.size > 4 ? .int64(Int64(self)) : .int32(Int32(self))
    }
}

extension UnsignedInteger where Self: FixedWidthInteger {
    
    public func toBSON() -> BSON {
        return MemoryLayout<Self>.size < 4 ? .int32(Int32(self)) : .int64(Int64(self))
    }
}

extension UInt: BSONConvertible { }
extension UInt8: BSONConvertible { }
extension UInt16: BSONConvertible { }
extension UInt32: BSONConvertible { }
extension UInt64: BSONConvertible { }
extension Int: BSONConvertible { }
extension Int8: BSONConvertible { }
extension Int16: BSONConvertible { }
extension Int32: BSONConvertible { }
extension Int64: BSONConvertible { }

extension BinaryFloatingPoint {
    
    public func toBSON() -> BSON {
        return .double(Double(self))
    }
}

#if swift(>=5.3) && !os(macOS) && !targetEnvironment(macCatalyst)

@available(iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension Float16: BSONConvertible { }

#endif

extension float16: BSONConvertible { }
extension Float: BSONConvertible { }
extension Double: BSONConvertible { }

extension Decimal: BSONConvertible {
    
    public func toBSON() -> BSON {
        return try! .decimal128(BSONDecimal128("\(self)"))
    }
}

extension StringProtocol {
    
    public func toBSON() -> BSON {
        return .string(String(self))
    }
}

extension String: BSONConvertible {
    
    public func toBSON() -> BSON {
        return .string(self)
    }
}

extension Substring: BSONConvertible { }

extension Date: BSONConvertible {
    
    public func toBSON() -> BSON {
        return .datetime(self)
    }
}

extension Data: BSONConvertible {
    
    public func toBSON() -> BSON {
        return try! .binary(BSONBinary(data: self, subtype: .generic))
    }
}

extension ByteBuffer: BSONConvertible {
    
    public func toBSON() -> BSON {
        return try! .binary(BSONBinary(data: self.data, subtype: .generic))
    }
}

extension ByteBufferView: BSONConvertible {
    
    public func toBSON() -> BSON {
        return try! .binary(BSONBinary(data: Data(self), subtype: .generic))
    }
}

extension DateComponents: BSONConvertible {
    
    public func toBSON() -> BSON {
        return .datetime(DBData.calendar.date(from: self)!)
    }
}

extension UUID: BSONConvertible {
    
    public func toBSON() -> BSON {
        return try! .binary(BSONBinary(from: self))
    }
}

extension NSRegularExpression: BSONConvertible {
    
    public func toBSON() -> BSON {
        return .regex(BSONRegularExpression(from: self))
    }
}

extension Regex: BSONConvertible {
    
    public func toBSON() -> BSON {
        return .regex(BSONRegularExpression(from: self.nsRegex))
    }
}

extension Array: BSONConvertible where Element: BSONConvertible {
    
    public func toBSON() -> BSON {
        return .array(self.map { $0.toBSON() })
    }
}

extension Dictionary: BSONConvertible where Key == String, Value: BSONConvertible {
    
    public func toBSON() -> BSON {
        return .document(BSONDocument(self.mapValues { $0.toBSON() }))
    }
}

extension OrderedDictionary: BSONConvertible where Key == String, Value: BSONConvertible {
    
    public func toBSON() -> BSON {
        return .document(BSONDocument(self.mapValues { $0.toBSON() }))
    }
}
