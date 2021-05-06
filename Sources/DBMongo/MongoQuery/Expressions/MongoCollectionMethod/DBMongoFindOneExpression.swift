//
//  DBMongoFindOneExpression.swift
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

public struct DBMongoFindOneExpression<T: Codable>: DBMongoExpression {
    
    let query: DBMongoCollection<T>
    
    public var filter: BSONDocument
    
    public var options: FindOneOptions = FindOneOptions()
}

extension DBMongoFindOneExpression: DBMongoFilterOption {}


extension DBMongoCollectionExpression {
    
    public func findOne() -> DBMongoFindOneExpression<T> {
        return DBMongoFindOneExpression(query: query(), filter: filter)
    }
}

extension DBMongoFindOneExpression {
    
    public func execute() -> EventLoopFuture<T?> {
        return query.collection.findOne(filter, options: options, session: query.session)
    }
}

extension FindOneOptions: DBMongoAllowPartialResultsOption {}
extension FindOneOptions: DBMongoCollationOption {}
extension FindOneOptions: DBMongoCommentOption {}
extension FindOneOptions: DBMongoIndexHintOption {}
extension FindOneOptions: DBMongoMaxOption {}
extension FindOneOptions: DBMongoMaxTimeMSOption {}
extension FindOneOptions: DBMongoMinOption {}
extension FindOneOptions: DBMongoProjectionOption {}
extension FindOneOptions: DBMongoReadConcernOption {}
extension FindOneOptions: DBMongoReadPreferenceOption {}
extension FindOneOptions: DBMongoReturnKeyOption {}
extension FindOneOptions: DBMongoShowRecordIDOption {}
extension FindOneOptions: DBMongoSkipOption {}
extension FindOneOptions: DBMongoSortOption {}
