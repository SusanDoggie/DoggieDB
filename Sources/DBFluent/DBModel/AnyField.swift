//
//  AnyField.swift
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

private protocol AnyFieldBox {
    
    var name: String? { get }
    
    var type: String? { get }
    
    var isUnique: Bool { get }
    
    var modifier: Set<DBFieldModifier> { get }
    
    var isOptional: Bool { get }
    
    func _data() -> DBData?
}

private protocol _Optional { }
extension Optional: _Optional { }

extension DBField: AnyFieldBox {
    
    public var isOptional: Bool {
        return Value.self is _Optional.Type
    }
    
    fileprivate func _data() -> DBData? {
        return self.value?.toDBData()
    }
}

public struct AnyField<Model: DBModel> {
    
    private let label: String
    
    private let box: AnyFieldBox
    
    fileprivate init?(_ mirror: Mirror.Child) {
        guard let label = mirror.label, label.hasPrefix("_") else { return nil }
        guard let box = mirror.value as? AnyFieldBox else { return nil }
        self.label = String(label.dropFirst())
        self.box = box
    }
}

extension AnyField {
    
    public var name: String {
        return box.name ?? label
    }
    
    public var type: String? {
        return box.type
    }
    
    public var isUnique: Bool {
        return box.isUnique
    }
    
    public var modifier: Set<DBFieldModifier> {
        return box.modifier
    }
    
    public var isOptional: Bool {
        return box.isOptional
    }
    
    public var value: DBData? {
        return box._data()
    }
}

extension DBModel {
    
    public var _$fields: [AnyField<Self>] {
        return Mirror(reflecting: self).children.compactMap { AnyField($0) }
    }
}
