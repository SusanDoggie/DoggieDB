//
//  DBMongoListCollectionsExpression.swift
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

public struct DBMongoListCollectionsExpression<T>: DBMongoExpression {
    
    let connection: DBMongoConnectionProtocol
    
    public let database: MongoDatabase
    
    public let session: ClientSession?
    
    public var filter: BSONDocument?
    
    public var options = ListCollectionsOptions()
}

extension DBMongoListCollectionsExpression {
    
    public func execute() async throws -> MongoCursor<CollectionSpecification> {
        return try await database.listCollections(filter, options: options, session: session).get()
    }
}

extension ListCollectionsOptions: DBMongoBatchSizeOption {}

extension DBMongoListCollectionsExpression {
    
    /// a `BSONDocument`, the filter that documents must match
    public func filter(_ filter: BSONDocument) -> Self {
        var result = self
        result.filter = filter
        return result
    }
    
}
