//
//  DBMongoFilterOption.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2024 Susan Cheng. All rights reserved.
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

public protocol DBMongoFilterOption {
    
    var filters: [BSONDocument] { get set }
    
}

extension DBMongoFilterOption {
    
    /// a `BSONDocument`, the filter that documents must match
    public func filter(_ filter: BSONDocument) -> Self {
        var result = self
        result.filters.append(filter)
        return result
    }
    
    /// a `BSONDocument`, the filter that documents must match
    public func filter(_ filter: [BSONDocument]) -> Self {
        var result = self
        result.filters.append(contentsOf: filter)
        return result
    }
    
    public func filter(_ predicate: (MongoPredicateBuilder) -> MongoPredicateExpression) throws -> Self {
        var result = self
        try result.filters.append(predicate(MongoPredicateBuilder()).toBSONDocument())
        return result
    }
}

extension DBMongoFilterOption {
    
    var _filter: BSONDocument {
        switch filters.count {
        case 0: return [:]
        case 1: return filters[0]
        default: return ["$and": BSON(filters)]
        }
    }
}
