//
//  DBMongoReplaceOneExpression.swift
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

public struct DBMongoReplaceOneExpression<T: Codable>: DBMongoExpression {
    
    let query: DBMongoCollection<T>
    
    public var filters: [BSONDocument]
    
    public var replacement: T?
    
    public var options: ReplaceOptions = ReplaceOptions()
}

extension DBMongoReplaceOneExpression: DBMongoFilterOption {}

extension DBMongoCollectionExpression {
    
    public func replaceOne() -> DBMongoReplaceOneExpression<T> {
        return DBMongoReplaceOneExpression(query: query(), filters: filters)
    }
}

extension DBMongoReplaceOneExpression {
    
    public func replacement(_ replacement: T) -> Self {
        var result = self
        result.replacement = replacement
        return result
    }
}

extension DBMongoReplaceOneExpression {
    
    public func execute() -> EventLoopFuture<UpdateResult?> {
        guard let replacement = self.replacement else { fatalError() }
        return query.collection.replaceOne(filter: _filter, replacement: replacement, options: options, session: query.session)
    }
}

extension ReplaceOptions: DBMongoBypassDocumentValidationOption {}
extension ReplaceOptions: DBMongoCollationOption {}
extension ReplaceOptions: DBMongoUpsertOption {}
extension ReplaceOptions: DBMongoWriteConcernOption {}
