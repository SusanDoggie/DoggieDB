//
//  DBDataConvertible.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2024 Susan Cheng. All rights reserved.
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

public protocol DBDataConvertible {
    
    func toDBData() -> DBData
}

extension DBData: DBDataConvertible {
    
    @inlinable
    public func toDBData() -> DBData {
        return self
    }
}

extension Optional: DBDataConvertible where Wrapped: DBDataConvertible {
    
    @inlinable
    public func toDBData() -> DBData {
        return self?.toDBData() ?? .null
    }
}

extension Bool: DBDataConvertible {
    
    @inlinable
    public func toDBData() -> DBData {
        return .boolean(self)
    }
}

extension SignedInteger where Self: FixedWidthInteger {
    
    @inlinable
    public func toDBData() -> DBData {
        return .number(DBData.Number(self))
    }
}

extension UnsignedInteger where Self: FixedWidthInteger {
    
    @inlinable
    public func toDBData() -> DBData {
        return .number(DBData.Number(self))
    }
}

extension UInt: DBDataConvertible { }
extension UInt8: DBDataConvertible { }
extension UInt16: DBDataConvertible { }
extension UInt32: DBDataConvertible { }
extension UInt64: DBDataConvertible { }
extension Int: DBDataConvertible { }
extension Int8: DBDataConvertible { }
extension Int16: DBDataConvertible { }
extension Int32: DBDataConvertible { }
extension Int64: DBDataConvertible { }

extension BinaryFloatingPoint {
    
    @inlinable
    public func toDBData() -> DBData {
        return .number(DBData.Number(self))
    }
}

#if swift(>=5.3) && !os(macOS) && !targetEnvironment(macCatalyst)

@available(iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension Float16: DBDataConvertible { }

#endif

extension float16: DBDataConvertible { }
extension Float: DBDataConvertible { }
extension Double: DBDataConvertible { }

extension Decimal: DBDataConvertible {
    
    @inlinable
    public func toDBData() -> DBData {
        return .number(.decimal(self))
    }
}

extension DBData.Number: DBDataConvertible {
    
    @inlinable
    public func toDBData() -> DBData {
        return .number(self)
    }
}

extension StringProtocol {
    
    @inlinable
    public func toDBData() -> DBData {
        return .string(String(self))
    }
}

extension String: DBDataConvertible {
    
    @inlinable
    public func toDBData() -> DBData {
        return .string(self)
    }
}

extension Substring: DBDataConvertible { }

extension Date: DBDataConvertible {
    
    @inlinable
    public func toDBData() -> DBData {
        return .timestamp(self)
    }
}

extension Data: DBDataConvertible {
    
    @inlinable
    public func toDBData() -> DBData {
        return .binary(self)
    }
}

extension ByteBuffer: DBDataConvertible {
    
    @inlinable
    public func toDBData() -> DBData {
        return .binary(self.data)
    }
}

extension ByteBufferView: DBDataConvertible {
    
    @inlinable
    public func toDBData() -> DBData {
        return .binary(Data(self))
    }
}

extension DateComponents: DBDataConvertible {
    
    @inlinable
    public func toDBData() -> DBData {
        return .date(self)
    }
}

extension UUID: DBDataConvertible {
    
    @inlinable
    public func toDBData() -> DBData {
        return .uuid(self)
    }
}

extension BSONObjectID: DBDataConvertible {
    
    @inlinable
    public func toDBData() -> DBData {
        return .objectID(self)
    }
}

extension Array: DBDataConvertible where Element: DBDataConvertible {
    
    @inlinable
    public func toDBData() -> DBData {
        return .array(self.map { $0.toDBData() })
    }
}

extension Dictionary: DBDataConvertible where Key == String, Value: DBDataConvertible {
    
    @inlinable
    public func toDBData() -> DBData {
        return .dictionary(self.mapValues { $0.toDBData() })
    }
}

extension OrderedDictionary: DBDataConvertible where Key == String, Value: DBDataConvertible {
    
    @inlinable
    public func toDBData() -> DBData {
        return .dictionary(Dictionary(self.mapValues { $0.toDBData() }))
    }
}
