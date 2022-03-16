//
//  DBMongoFindOneAndDeleteExpression.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2022 Susan Cheng. All rights reserved.
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

public struct DBMongoFindOneAndDeleteExpression<T: Codable>: DBMongoExpression {
    
    let query: DBMongoCollection<T>
    
    public var filters: [BSONDocument]
    
    public var options: FindOneAndDeleteOptions = FindOneAndDeleteOptions()
}

extension DBMongoFindOneAndDeleteExpression: DBMongoFilterOption {}

extension DBMongoCollectionExpression {
    
    public func findOneAndDelete() -> DBMongoFindOneAndDeleteExpression<T> {
        return DBMongoFindOneAndDeleteExpression(query: query(), filters: filters)
    }
}

extension DBMongoFindOneAndDeleteExpression {
    
    public func execute() async throws -> T? {
        return try await query.collection.findOneAndDelete(_filter, options: options, session: query.session).get()
    }
}

extension FindOneAndDeleteOptions: DBMongoCollationOption {}
extension FindOneAndDeleteOptions: DBMongoMaxTimeMSOption {}
extension FindOneAndDeleteOptions: DBMongoProjectionOption {}
extension FindOneAndDeleteOptions: DBMongoSortOption {}
extension FindOneAndDeleteOptions: DBMongoWriteConcernOption {}
