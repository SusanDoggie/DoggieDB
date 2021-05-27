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
    
    let connection: DBMongoConnection
    
    public let database: MongoDatabase
    
    public let session: ClientSession?
    
    public let name: String
    
    public var options = CreateCollectionOptions()
}

extension DBMongoCreateCollectionExpression {
    
    public func withType<U>(_: U.Type) -> DBMongoCreateCollectionExpression<U> {
        return DBMongoCreateCollectionExpression<U>(connection: connection, database: database, session: session, name: name, options: options)
    }
}

extension DBMongoCreateCollectionExpression {
    
    public func execute() -> EventLoopFuture<MongoCollection<T>> {
        return database.createCollection(name, withType: T.self, options: options, session: session)
    }
}

extension DBMongoCreateCollectionExpression: DBMongoPipelineBuilder {
    
    public var pipeline: [BSONDocument] {
        get {
            return options.pipeline ?? []
        }
        set {
            options.pipeline = newValue
        }
    }
}

extension CreateCollectionOptions: DBMongoCollationOption {}
extension CreateCollectionOptions: DBMongoWriteConcernOption {}
extension CreateCollectionOptions: DBMongoDataCodingStrategyOption {}
extension CreateCollectionOptions: DBMongoDateCodingStrategyOption {}
extension CreateCollectionOptions: DBMongoUUIDCodingStrategyOption {}

extension DBMongoCreateCollectionExpression {
    
    /// An array consisting of aggregation pipeline stages. When used with `viewOn`, will create the view by applying
    /// this pipeline to the source collection or view.
    public func pipeline(_ pipeline: [BSONDocument]) -> Self {
        var result = self
        result.options.pipeline = pipeline
        return result
    }
    
    /// Indicates whether this will be a capped collection.
    public func capped(_ capped: Bool) -> Self {
        var result = self
        result.options.capped = capped
        return result
    }
    
    /// Specify a default configuration for indexes created on this collection.
    public func indexOptionDefaults(_ indexOptionDefaults: BSONDocument) -> Self {
        var result = self
        result.options.indexOptionDefaults = indexOptionDefaults
        return result
    }
    
    /// Maximum number of documents allowed in the collection (if capped).
    public func max(_ max: Int) -> Self {
        var result = self
        result.options.max = max
        return result
    }
    
    /// Maximum size, in bytes, of this collection (if capped).
    public func size(_ size: Int) -> Self {
        var result = self
        result.options.size = size
        return result
    }
    
    /// Specifies storage engine configuration for this collection.
    public func storageEngine(_ storageEngine: BSONDocument) -> Self {
        var result = self
        result.options.storageEngine = storageEngine
        return result
    }
    
    /// Determines whether to error on invalid documents or just warn about the violations but allow invalid documents
    /// to be inserted.
    public func validationAction(_ validationAction: String) -> Self {
        var result = self
        result.options.validationAction = validationAction
        return result
    }
    
    /// Determines how strictly MongoDB applies the validation rules to existing documents during an update.
    public func validationLevel(_ validationLevel: String) -> Self {
        var result = self
        result.options.validationLevel = validationLevel
        return result
    }
    
    /// What validator should be used for the collection.
    public func validator(_ validator: BSONDocument) -> Self {
        var result = self
        result.options.validator = validator
        return result
    }
    
    /// The name of the source collection or view from which to create the view.
    public func viewOn(_ viewOn: String) -> Self {
        var result = self
        result.options.viewOn = viewOn
        return result
    }
    
}
