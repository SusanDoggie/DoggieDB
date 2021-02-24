//
//  DBMongoCollection.swift
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

public struct DBMongoCollection<T: Codable> {
    
    let collection: MongoCollection<T>
    
    let session: ClientSession?
}

extension DBMongoCollection {
    
    public func count(
        _ filter: BSONDocument = [:],
        options: CountDocumentsOptions? = nil
    ) -> EventLoopFuture<Int> {
        return collection.countDocuments(filter, options: options, session: session)
    }
    
    public func find(
        _ filter: BSONDocument = [:],
        options: FindOptions? = nil
    ) -> EventLoopFuture<MongoCursor<T>> {
        return collection.find(filter, options: options, session: session)
    }
    
    public func first(
        _ filter: BSONDocument = [:],
        options: FindOneOptions? = nil
    ) -> EventLoopFuture<T?> {
        return collection.findOne(filter, options: options, session: session)
    }
}

extension DBMongoCollection {
    
    public func aggregate(
        _ pipeline: [BSONDocument],
        options: AggregateOptions? = nil
    ) -> EventLoopFuture<MongoCursor<BSONDocument>> {
        return collection.aggregate(pipeline, options: options, session: session)
    }
}

extension DBMongoCollection {
    
    public func bulkWrite(
        _ requests: [WriteModel<T>],
        options: BulkWriteOptions? = nil
    ) -> EventLoopFuture<BulkWriteResult?> {
        return collection.bulkWrite(requests, options: options, session: session)
    }
}

extension DBMongoCollection {
    
    public func deleteOne(
        _ filter: BSONDocument,
        options: DeleteOptions? = nil
    ) -> EventLoopFuture<DeleteResult?> {
        return collection.deleteOne(filter, options: options, session: session)
    }
    
    public func deleteMany(
        _ filter: BSONDocument,
        options: DeleteOptions? = nil
    ) -> EventLoopFuture<DeleteResult?> {
        return collection.deleteMany(filter, options: options, session: session)
    }
}

extension DBMongoCollection {
    
    public func createIndex(
        _ model: IndexModel,
        options: CreateIndexOptions? = nil
    ) -> EventLoopFuture<String> {
        return collection.createIndex(model, options: options, session: session)
    }
    
    public func createIndexes(
        _ models: [IndexModel],
        options: CreateIndexOptions? = nil
    ) -> EventLoopFuture<[String]> {
        return collection.createIndexes(models, options: options, session: session)
    }
}

extension DBMongoCollection {
    
    public func drop(
        options: DropCollectionOptions? = nil
    ) -> EventLoopFuture<Void> {
        return collection.drop(options: options, session: session)
    }
}

extension DBMongoCollection {
    
    public func indexNames() -> EventLoopFuture<[String]> {
        return collection.listIndexNames(session: session)
    }
    
    public func indexes() -> EventLoopFuture<MongoCursor<IndexModel>> {
        return collection.listIndexes(session: session)
    }
}

extension DBMongoCollection {
    
    public func dropIndex(
        _ name: String,
        options: DropIndexOptions? = nil
    ) -> EventLoopFuture<Void> {
        return collection.dropIndex(name, options: options, session: session)
    }
    
    public func dropIndex(
        _ keys: BSONDocument,
        options: DropIndexOptions? = nil
    ) -> EventLoopFuture<Void> {
        return collection.dropIndex(keys, options: options, session: session)
    }
    
    public func dropIndex(
        _ model: IndexModel,
        options: DropIndexOptions? = nil
    ) -> EventLoopFuture<Void> {
        return collection.dropIndex(model, options: options, session: session)
    }
    
    public func dropIndexes(
        options: DropIndexOptions? = nil
    ) -> EventLoopFuture<Void> {
        return collection.dropIndexes(options: options, session: session)
    }
}

extension DBMongoCollection {
    
    public func deleteFirst(
        _ filter: BSONDocument,
        options: FindOneAndDeleteOptions? = nil
    ) -> EventLoopFuture<T?> {
        return collection.findOneAndDelete(filter, options: options, session: session)
    }
    
    public func updateFirst(
        filter: BSONDocument,
        update: BSONDocument,
        options: FindOneAndUpdateOptions? = nil
    ) -> EventLoopFuture<T?> {
        return collection.findOneAndUpdate(filter: filter, update: update, options: options, session: session)
    }
    
    public func replaceFirst(
        filter: BSONDocument,
        replacement: T,
        options: FindOneAndReplaceOptions? = nil
    ) -> EventLoopFuture<T?> {
        return collection.findOneAndReplace(filter: filter, replacement: replacement, options: options, session: session)
    }
}

extension DBMongoCollection {
    
    public func insertOne(
        _ value: T,
        options: InsertOneOptions? = nil
    ) -> EventLoopFuture<InsertOneResult?> {
        return collection.insertOne(value, options: options, session: session)
    }
    
    public func insertMany(
        _ values: [T],
        options: InsertManyOptions? = nil
    ) -> EventLoopFuture<InsertManyResult?> {
        return collection.insertMany(values, options: options, session: session)
    }
}

extension DBMongoCollection {
    
    public func replaceOne(
        filter: BSONDocument,
        replacement: T,
        options: ReplaceOptions? = nil
    ) -> EventLoopFuture<UpdateResult?> {
        return collection.replaceOne(filter: filter, replacement: replacement, options: options, session: session)
    }
}

extension DBMongoCollection {
    
    public func updateMany(
        filter: BSONDocument,
        update: BSONDocument,
        options: UpdateOptions? = nil
    ) -> EventLoopFuture<UpdateResult?> {
        return collection.updateMany(filter: filter, update: update, options: options, session: session)
    }
    
    public func updateOne(
        filter: BSONDocument,
        update: BSONDocument,
        options: UpdateOptions? = nil
    ) -> EventLoopFuture<UpdateResult?> {
        return collection.updateOne(filter: filter, update: update, options: options, session: session)
    }
}

extension DBMongoCollection {
    
    public func distinct(
        fieldName: String,
        filter: BSONDocument = [:],
        options: DistinctOptions? = nil
    ) -> EventLoopFuture<[BSON]> {
        return collection.distinct(fieldName: fieldName, filter: filter, options: options, session: session)
    }
}
