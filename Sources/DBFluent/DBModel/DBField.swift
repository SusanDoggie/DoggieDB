//
//  DBField.swift
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

extension DBModel {
    
    public typealias Field<Value: DBDataConvertible> = DBField<Self, Value>
}

@propertyWrapper
public struct DBField<Model: DBModel, Value: DBDataConvertible> {
    
    public let name: String?
    
    public let type: String?
    
    public let isUnique: Bool
    
    public let `default`: Default?
    
    public let modifier: Set<DBFieldModifier>
    
    public internal(set) var isDirty: Bool?
    
    public internal(set) var value: Value?
    
    public init(
        name: String? = nil,
        type: String? = nil,
        isUnique: Bool = false,
        default: Default? = nil
    ) {
        self.name = name
        self.type = type
        self.isUnique = isUnique
        self.default = `default`
        self.modifier = []
    }
    
    public var wrappedValue: Value {
        get {
            guard let value = self.value else { fatalError("property accessed before being initialized") }
            return value
        }
        set {
            self.value = newValue
            self.isDirty = true
        }
    }
    
    public var projectedValue: DBField {
        return self
    }
}

extension DBField: Decodable where Value: Decodable {
    
    public init(from decoder: Decoder) throws {
        self.init()
        self.value = try Value(from: decoder)
    }
}

extension DBField: Encodable where Value: Encodable {
    
    public func encode(to encoder: Encoder) throws {
        try self.value?.encode(to: encoder)
    }
}

extension DBField: Equatable where Value: Equatable {
    
    public static func == (lhs: DBField, rhs: DBField) -> Bool {
        return lhs.value == rhs.value
    }
}

extension DBField: Hashable where Value: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.value)
    }
}
