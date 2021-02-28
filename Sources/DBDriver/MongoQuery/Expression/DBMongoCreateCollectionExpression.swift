//
//  DBMongoCreateCollectionExpression.swift
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

public struct DBMongoCreateCollectionExpression<T: Codable>: DBMongoExpression {
    
    public let database: MongoDatabase
    
    public let session: ClientSession?
    
    public let name: String
    
    public var options = CreateCollectionOptions()
}

extension DBMongoCreateCollectionExpression {
    
    public func withType<U>(_: U.Type) -> DBMongoCreateCollectionExpression<U> {
        return DBMongoCreateCollectionExpression<U>(database: database, session: session, name: name, options: options)
    }
}

extension DBMongoCreateCollectionExpression {
    
    public func execute() -> EventLoopFuture<MongoCollection<T>> {
        return database.createCollection(name, withType: T.self, options: options, session: session)
    }
}

extension CreateCollectionOptions: DBMongoCollationOptions {}
extension CreateCollectionOptions: DBMongoWriteConcernOptions {}
extension CreateCollectionOptions: DBMongoDataCodingStrategyOptions {}
extension CreateCollectionOptions: DBMongoDateCodingStrategyOptions {}
extension CreateCollectionOptions: DBMongoUUIDCodingStrategyOptions {}

extension DBMongoCreateCollectionExpression {
    
    public func pipeline(_ pipeline: [BSONDocument]) -> Self {
        var result = self
        result.options.pipeline = pipeline
        return result
    }
    
    public func capped(_ capped: Bool) -> Self {
        var result = self
        result.options.capped = capped
        return result
    }
    
    public func indexOptionDefaults(_ indexOptionDefaults: BSONDocument) -> Self {
        var result = self
        result.options.indexOptionDefaults = indexOptionDefaults
        return result
    }
    
    public func max(_ max: Int) -> Self {
        var result = self
        result.options.max = max
        return result
    }
    
    public func size(_ size: Int) -> Self {
        var result = self
        result.options.size = size
        return result
    }
    
    public func storageEngine(_ storageEngine: BSONDocument) -> Self {
        var result = self
        result.options.storageEngine = storageEngine
        return result
    }
    
    public func validationAction(_ validationAction: String) -> Self {
        var result = self
        result.options.validationAction = validationAction
        return result
    }
    
    public func validationLevel(_ validationLevel: String) -> Self {
        var result = self
        result.options.validationLevel = validationLevel
        return result
    }
    
    public func validator(_ validator: BSONDocument) -> Self {
        var result = self
        result.options.validator = validator
        return result
    }
    
    public func viewOn(_ viewOn: String) -> Self {
        var result = self
        result.options.viewOn = viewOn
        return result
    }
    
}
