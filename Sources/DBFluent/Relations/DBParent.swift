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

extension ExpressibleByNilLiteral {
    
    fileprivate static var null: ExpressibleByNilLiteral {
        return Self(nilLiteral: ()) as ExpressibleByNilLiteral
    }
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
    
    public let onUpdate: SQLForeignKeyAction
    public let onDelete: SQLForeignKeyAction

    public private(set) var parent: Future<To>?
    
    var loader: ((ParentKey) -> EventLoopFuture<To>)! {
        didSet {
            self.reload()
        }
    }
    
    public init(
        name: String? = nil,
        type: String? = nil,
        isUnique: Bool = false,
        default: DBField<From, ParentKey>.Default? = nil,
        onUpdate: SQLForeignKeyAction = .restrict,
        onDelete: SQLForeignKeyAction = .restrict
    ) {
        self._id = DBField(name: name, type: type, isUnique: isUnique, default: `default`)
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.parent = nil
    }
    
    public var wrappedValue: To {
        get {
            return try! self.wait()
        }
        set {
            id = newValue.id
            if let eventLoop = parent?.eventLoop {
                parent = .future(eventLoop.makeSucceededFuture(newValue))
            } else {
                parent = .value(newValue)
            }
        }
    }
    
    public var projectedValue: DBParent {
        return self
    }
}

extension DBParent: Decodable where To: Decodable {
    
    public init(from decoder: Decoder) throws {
        self.init()
        self.wrappedValue = try To(from: decoder)
    }
}

extension DBParent: Encodable where To: Encodable {
    
    public func encode(to encoder: Encoder) throws {
        try self.wait().encode(to: encoder)
    }
}

extension DBParent: Equatable where To: Equatable {
    
    public static func == (lhs: DBParent, rhs: DBParent) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}

extension DBParent: Hashable where To: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.wrappedValue)
    }
}

extension DBParent {
    
    @discardableResult
    public mutating func reload() -> EventLoopFuture<To> {
        let future = loader(self.id)
        self.parent = .future(future)
        return future
    }
}

extension DBParent {
    
    public var eventLoop: EventLoop? {
        return parent?.eventLoop
    }
}

extension DBParent {
    
    public func wait() throws -> To {
        if self.parent == nil {
            logger.warning("property accessed before being initialized")
        }
        if let parent = self.parent {
            return try parent.wait()
        }
        guard let _To = To.self as? ExpressibleByNilLiteral.Type else { fatalError() }
        return _To.null as! To
    }
}
