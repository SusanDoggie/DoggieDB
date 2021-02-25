//
//  DBSiblings.swift
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
    
    public typealias Siblings<To: DBModel, Through: DBModel> = DBSiblings<Self, To, Through>
}

@propertyWrapper
public struct DBSiblings<From: DBModel, To: DBModel, Through: DBModel> {
    
    public let fromKey: KeyPath<Through, Through.Parent<From>>
    
    public let toKey: KeyPath<Through, Through.Parent<To>>
    
    public private(set) var pivots: EventLoopFuture<[Through]>?
    
    var loader: (() -> EventLoopFuture<[Through]>)! {
        didSet {
            self.reload()
        }
    }
    
    public init(
        through _: Through.Type,
        from: KeyPath<Through, Through.Parent<From>>,
        to: KeyPath<Through, Through.Parent<To>>
    ) {
        self.fromKey = from
        self.toKey = to
        self.pivots = nil
    }
    
    public var wrappedValue: [To] {
        return try! self.wait()
    }
    
    public var projectedValue: DBSiblings {
        return self
    }
}

extension DBSiblings: Encodable where To: Encodable {
    
    public func encode(to encoder: Encoder) throws {
        try self.wait().encode(to: encoder)
    }
}

extension DBSiblings: Equatable where To: Equatable {
    
    public static func == (lhs: DBSiblings, rhs: DBSiblings) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}

extension DBSiblings: Hashable where To: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.wrappedValue)
    }
}

extension DBSiblings {
    
    @discardableResult
    public mutating func reload() -> EventLoopFuture<[Through]> {
        let future = loader()
        self.pivots = future
        return future
    }
}

extension DBSiblings {
    
    public var eventLoop: EventLoop? {
        return pivots?.eventLoop
    }
}

extension DBSiblings {
    
    public var siblings: EventLoopFuture<[To]>? {
        guard let pivots = self.pivots else { return nil }
        let eventLoop = pivots.eventLoop
        let siblings = pivots.map { $0.compactMap { $0[keyPath: toKey].parent?.hop(to: eventLoop) } }
        return siblings.flatMap { EventLoopFuture.reduce(into: [], $0, on: eventLoop) { $0.append($1) } }
    }
}

extension DBSiblings {
    
    public func wait() throws -> [To] {
        if self.siblings == nil {
            logger.warning("property accessed before being initialized")
        }
        return try siblings?.wait() ?? []
    }
}
