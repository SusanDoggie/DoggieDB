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
    
    public internal(set) var pivots: EventLoopFuture<[Through]>!
    
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
        return try! siblings.wait()
    }
    
    public var projectedValue: DBSiblings<From, To, Through> {
        return self
    }
}

extension DBSiblings {
    
    public var siblings: EventLoopFuture<[To]> {
        let eventLoop = pivots.eventLoop
        let siblings = pivots.map { $0.map { $0[keyPath: toKey].parent! } }
        return siblings.flatMap { EventLoopFuture.reduce(into: [], $0, on: eventLoop) { $0.append($1) } }
    }
}
