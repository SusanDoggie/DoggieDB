//
//  DBMongoSortOption.swift
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

public protocol DBMongoSortOption {
    
    var sort: BSONDocument? { get set }
    
}

public enum DBMongoSortOrder {
    
    case ascending
    
    case descending
}

extension OrderedDictionary where Key == String, Value == DBMongoSortOrder {
    
    public func toBSONDocument() -> BSONDocument {
        var document: BSONDocument = [:]
        for (key, value) in self {
            switch value {
            case .ascending: document[key] = 1
            case .descending: document[key] = -1
            }
        }
        return document
    }
}

extension DBMongoExpression where Options: DBMongoSortOption {
    
    /// The order in which to return matching documents.
    public func sort(_ sort: BSONDocument) -> Self {
        var result = self
        result.options.sort = sort
        return result
    }
    
    /// The order in which to return matching documents.
    public func sort(_ sort: OrderedDictionary<String, DBMongoSortOrder>) -> Self {
        var result = self
        result.options.sort = sort.toBSONDocument()
        return result
    }
    
}
