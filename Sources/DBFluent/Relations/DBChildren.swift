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
    
    public let parentKey: ParentKey
    
    public internal(set) var children: EventLoopFuture<[To]>?
    
    public init(parentKey: KeyPath<To, To.Parent<From>>) {
        self.parentKey = .required(parentKey)
        self.children = nil
    }
    
    public init(parentKey: KeyPath<To, To.Parent<From?>>) {
        self.parentKey = .optional(parentKey)
        self.children = nil
    }
    
    public var wrappedValue: [To] {
        if self.children == nil {
            logger.warning("property accessed before being initialized")
        }
        return try! children?.wait() ?? []
    }
    
    public var projectedValue: DBChildren<From, To> {
        return self
    }
}

extension DBChildren {
    
    public var eventLoop: EventLoop? {
        return children?.eventLoop
    }
}

extension DBChildren {
    
    public func wait() throws -> [To] {
        return try children?.wait() ?? []
    }
}
