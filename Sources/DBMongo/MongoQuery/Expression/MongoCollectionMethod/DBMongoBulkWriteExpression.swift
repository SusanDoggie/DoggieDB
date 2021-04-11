//
//  DBMongoBulkWriteExpression.swift
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

public struct DBMongoBulkWriteExpression<T: Codable>: DBMongoExpression {
    
    let query: DBMongoCollection<T>
    
    public var requests: [WriteModel<T>] = []
    
    public var options: BulkWriteOptions = BulkWriteOptions()
}

extension DBMongoCollectionExpression {
    
    public func bulkWrite() -> DBMongoBulkWriteExpression<T> {
        return DBMongoBulkWriteExpression(query: query())
    }
}

extension DBMongoBulkWriteExpression {
    
    public func requests(_ requests: [WriteModel<T>]) -> Self {
        var result = self
        result.requests = requests
        return result
    }
}

extension DBMongoBulkWriteExpression {
    
    public func execute() -> EventLoopFuture<BulkWriteResult?> {
        guard !requests.isEmpty else { fatalError() }
        return query.collection.bulkWrite(requests, options: options, session: query.session)
    }
}

extension BulkWriteOptions: DBMongoBypassDocumentValidationOptions {}
extension BulkWriteOptions: DBMongoWriteConcernOptions {}

extension DBMongoBulkWriteExpression {
    
    /**
     * If `true` (the default), operations will be executed serially in order
     * and a write error will abort execution of the entire bulk write. If
     * `false`, operations may execute in an arbitrary order and execution will
     * not stop after encountering a write error (i.e. multiple errors may be
     * reported after all operations have been attempted).
     */
    public func ordered(_ ordered: Bool) -> Self {
        var result = self
        result.options.ordered = ordered
        return result
    }
    
}
