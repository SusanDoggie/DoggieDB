//
//  DBModel.swift
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

public protocol _DBModel {
    
    associatedtype ID
    
    var id: ID { get }
}

public protocol DBModel: _DBModel, Identifiable where ID: DBDataConvertible {
    
    static var schema: String { get }
    
    init()
    
    var id: ID { get set }
    
    var _$id: Field<ID> { get }
    
    var _$fields: [DBAnyField<Self>] { get }
    
    var isDirty: Bool { get }
}

extension DBModel {
    
    public var _$id: Field<ID> {
        guard let id = Mirror(reflecting: self).descendant("_id") as? Field<ID> else { fatalError("id must be declared using @DBField") }
        return id
    }
}
