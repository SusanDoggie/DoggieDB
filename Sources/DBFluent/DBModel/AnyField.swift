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

protocol AnyFieldBox {
    
    var name: String? { get }
    
    var size: DBFieldSize? { get }
    
    var isUnique: Bool { get }
    
    var modifier: Set<DBFieldModifier> { get }
    
    var isOptional: Bool { get }
    
    func _data() -> DBData?
}

struct AnyField<Model: DBModel> {
    
    let label: String
    
    let box: AnyFieldBox
    
    init?(_ mirror: Mirror.Child) {
        guard let label = mirror.label, label.hasPrefix("_") else { return nil }
        guard let box = mirror.value as? AnyFieldBox else { return nil }
        self.label = String(label.dropFirst())
        self.box = box
    }
}

extension AnyField {
    
    var name: String {
        return box.name ?? label
    }
    
    var size: DBFieldSize? {
        return box.size
    }
    
    var isUnique: Bool {
        return box.isUnique
    }
    
    var modifier: Set<DBFieldModifier> {
        return box.modifier
    }
    
    var isOptional: Bool {
        return box.isOptional
    }
    
    var value: DBData? {
        return box._data()
    }
}
