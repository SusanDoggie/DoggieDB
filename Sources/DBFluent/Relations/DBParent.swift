//
//  DBParent.swift
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
    
    public typealias Parent<To: _DBModel> = DBParent<Self, To> where To.Key: Hashable, To.Key: DBDataConvertible
}

extension Optional: _DBModel where Wrapped: DBModel {
    
    public var id: Wrapped.Key? {
        return self?.id
    }
}

@propertyWrapper
public struct DBParent<From: DBModel, To: _DBModel> where To.Key: Hashable, To.Key: DBDataConvertible {
    
    public typealias ParentKey = To.Key
    
    @DBField<From, ParentKey>
    public internal(set) var id: ParentKey
    
    public let onUpdate: DBForeignKeyAction
    public let onDelete: DBForeignKeyAction

    var _parent: EventLoopFuture<To>!
    
    public init(
        name: String? = nil,
        type: String? = nil,
        isUnique: Bool = false,
        default: DBField<From, ParentKey>.Default? = nil,
        onUpdate: DBForeignKeyAction = .restrict,
        onDelete: DBForeignKeyAction = .restrict
    ) {
        self._id = DBField(name: name, type: type, isUnique: isUnique, default: `default`)
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._parent = nil
    }
    
    public var wrappedValue: To {
        get {
            return try! parent.wait()
        }
        set {
            id = newValue.id
            _parent = _parent?.eventLoop.makeSucceededFuture(newValue)
        }
    }
    
    public var projectedValue: DBParent<From, To> {
        return self
    }
}

extension DBParent {
    
    public var eventLoop: EventLoop {
        return parent.eventLoop
    }
}

extension DBParent {
    
    public var parent: EventLoopFuture<To> {
        return _parent
    }
}

extension DBParent {
    
    public func wait() throws -> To {
        return try parent.wait()
    }
}
