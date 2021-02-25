//
//  DBChildren.swift
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
    
    public typealias Children<To: DBModel> = DBChildren<Self, To>
}

@propertyWrapper
public struct DBChildren<From: DBModel, To: DBModel> {
    
    public enum ParentKey {
        case required(KeyPath<To, To.Parent<From>>)
        case optional(KeyPath<To, To.Parent<From?>>)
    }
    
    private let _parentKey: ParentKey!
    
    public var parentKey: ParentKey {
        return _parentKey
    }
    
    public private(set) var children: Future<[To]>?
    
    var loader: (() -> EventLoopFuture<[To]>)! {
        didSet {
            self.reload()
        }
    }
    
    public init(parentKey: KeyPath<To, To.Parent<From>>) {
        self._parentKey = .required(parentKey)
        self.children = nil
    }
    
    public init(parentKey: KeyPath<To, To.Parent<From?>>) {
        self._parentKey = .optional(parentKey)
        self.children = nil
    }
    
    public var wrappedValue: [To] {
        get {
            return try! self.wait()
        }
        set {
            if let eventLoop = children?.eventLoop {
                children = .future(eventLoop.makeSucceededFuture(newValue))
            } else {
                children = .value(newValue)
            }
        }
    }
    
    public var projectedValue: DBChildren {
        return self
    }
}

extension DBChildren: Decodable where To: Decodable {
    
    public init(from decoder: Decoder) throws {
        self._parentKey = nil
        self.children = nil
        self.wrappedValue = try [To](from: decoder)
    }
}

extension DBChildren: Encodable where To: Encodable {
    
    public func encode(to encoder: Encoder) throws {
        try self.wait().encode(to: encoder)
    }
}

extension DBChildren: Equatable where To: Equatable {
    
    public static func == (lhs: DBChildren, rhs: DBChildren) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}

extension DBChildren: Hashable where To: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.wrappedValue)
    }
}

extension DBChildren {
    
    @discardableResult
    public mutating func reload() -> EventLoopFuture<[To]> {
        let future = loader()
        self.children = .future(future)
        return future
    }
}

extension DBChildren {
    
    public var eventLoop: EventLoop? {
        return children?.eventLoop
    }
}

extension DBChildren {
    
    public func wait() throws -> [To] {
        if self.children == nil {
            logger.warning("property accessed before being initialized")
        }
        return try children?.wait() ?? []
    }
}
