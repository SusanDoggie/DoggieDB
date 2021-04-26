//
//  DBAnyField.swift
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

private protocol _DBField {
    
    var name: String? { get }
    
    var type: String? { get }
    
    var isUnique: Bool { get }
    
    var modifier: Set<DBFieldModifier> { get }
    
    var trigger: DBTimestampTrigger { get }
    
    var isDirty: Bool? { get }
    
    var isOptional: Bool { get }
    
    var onUpdate: SQLForeignKeyAction { get }
    
    var onDelete: SQLForeignKeyAction { get }
    
    func _data() -> DBValue?
}

private protocol _Optional { }
extension Optional: _Optional { }

extension DBField: _DBField {
    
    public var isOptional: Bool {
        return Value.self is _Optional.Type
    }
    
    fileprivate func _data() -> DBValue? {
        return self.value?.toDBValue()
    }
    
    fileprivate var onUpdate: SQLForeignKeyAction {
        return .restrict
    }
    
    fileprivate var onDelete: SQLForeignKeyAction {
        return .restrict
    }
    
}

extension DBParent: _DBField {
    
    public var name: String? {
        return $id.name
    }
    
    public var isOptional: Bool {
        return $id.isOptional
    }
    
    public var type: String? {
        return $id.type
    }
    
    public var isUnique: Bool {
        return $id.isUnique
    }
    
    public var modifier: Set<DBFieldModifier> {
        return $id.modifier
    }
    
    public var trigger: DBTimestampTrigger {
        return $id.trigger
    }
    
    public var isDirty: Bool? {
        return $id.isDirty
    }
    
    fileprivate func _data() -> DBValue? {
        return $id._data()
    }
}

public struct DBAnyField<Model: DBModel> {
    
    private let label: String
    
    private let box: _DBField
    
    fileprivate init?(_ mirror: Mirror.Child) {
        guard let label = mirror.label, label.hasPrefix("_") else { return nil }
        guard let box = mirror.value as? _DBField else { return nil }
        self.label = String(label.dropFirst())
        self.box = box
    }
}

extension DBAnyField {
    
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
    
    public var isDirty: Bool? {
        return box.isDirty
    }
    
    public var isOptional: Bool {
        return box.isOptional
    }
    
    public var onUpdate: SQLForeignKeyAction {
        return box.onUpdate
    }
    
    public var onDelete: SQLForeignKeyAction {
        return box.onDelete
    }
    
    public var value: DBValue? {
        return box._data()
    }
}

extension DBModel {
    
    public var _$fields: [DBAnyField<Self>] {
        return Mirror(reflecting: self).children.compactMap { DBAnyField($0) }
    }
    
    public var isDirty: Bool {
        return _$fields.contains { $0.isDirty == true }
    }
}
