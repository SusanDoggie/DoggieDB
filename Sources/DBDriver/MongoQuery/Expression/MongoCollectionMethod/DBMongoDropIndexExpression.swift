//
//  DBMongoDropIndexExpression.swift
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

import MongoSwift

public struct DBMongoDropIndexExpression<T: Codable>: DBMongoExpression {
    
    let query: DBMongoCollection<T>
    
    public var keys: Keys?
    
    public var options: DropIndexOptions = DropIndexOptions()
}

extension DBMongoCollectionExpression {
    
    public func dropIndex() -> DBMongoDropIndexExpression<T> {
        return DBMongoDropIndexExpression(query: query())
    }
}

extension DBMongoDropIndexExpression {
    
    public enum Keys {
        
        case name(String)
        
        case document(BSONDocument)
        
        case model(IndexModel)
    }
}

extension DBMongoDropIndexExpression {
    
    public func index(_ name: String) -> Self {
        var result = self
        result.keys = .name(name)
        return result
    }
    
    public func index(_ keys: BSONDocument) -> Self {
        var result = self
        result.keys = .document(keys)
        return result
    }
    
    public func index(_ model: IndexModel) -> Self {
        var result = self
        result.keys = .model(model)
        return result
    }
}

extension DBMongoDropIndexExpression {
    
    public func execute() -> EventLoopFuture<Void> {
        guard let keys = self.keys else { fatalError() }
        switch keys {
        case let .name(name): return query.collection.dropIndex(name, options: options, session: query.session)
        case let .document(keys): return query.collection.dropIndex(keys, options: options, session: query.session)
        case let .model(model): return query.collection.dropIndex(model, options: options, session: query.session)
        }
    }
}
