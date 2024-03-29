//
//  DBMongoFindExpression.swift
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

public struct DBMongoFindExpression<T: Codable>: DBMongoExpression {
    
    let query: DBMongoCollection<T>
    
    public var filters: [BSONDocument]
    
    public var options: FindOptions = FindOptions()
}

extension DBMongoFindExpression: DBMongoFilterOption {}


extension DBMongoCollectionExpression {
    
    public func find() -> DBMongoFindExpression<T> {
        return DBMongoFindExpression(query: query(), filters: filters)
    }
}

extension DBMongoFindExpression {
    
    public func execute() async throws -> MongoCursor<T> {
        return try await query.collection.find(_filter, options: options, session: query.session).get()
    }
}

extension FindOptions: DBMongoAllowDiskUseOption {}
extension FindOptions: DBMongoAllowPartialResultsOption {}
extension FindOptions: DBMongoBatchSizeOption {}
extension FindOptions: DBMongoCollationOption {}
extension FindOptions: DBMongoCommentOption {}
extension FindOptions: DBMongoCursorTypeOption {}
extension FindOptions: DBMongoIndexHintOption {}
extension FindOptions: DBMongoLimitOption {}
extension FindOptions: DBMongoMaxOption {}
extension FindOptions: DBMongoMaxAwaitTimeMSOption {}
extension FindOptions: DBMongoMaxTimeMSOption {}
extension FindOptions: DBMongoMinOption {}
extension FindOptions: DBMongoNoCursorTimeoutOption {}
extension FindOptions: DBMongoProjectionOption {}
extension FindOptions: DBMongoReadConcernOption {}
extension FindOptions: DBMongoReadPreferenceOption {}
extension FindOptions: DBMongoReturnKeyOption {}
extension FindOptions: DBMongoShowRecordIDOption {}
extension FindOptions: DBMongoSkipOption {}
extension FindOptions: DBMongoSortOption {}
