//
//  DBMongoUpdateExpression.swift
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

public struct DBMongoUpdateExpression<T: Codable>: DBMongoExpression {
    
    let query: DBMongoCollection<T>
    
    public let type: OperationType
    
    public var filter: BSONDocument
    
    public var update: BSONDocument?
    
    public var options: UpdateOptions = UpdateOptions()
}

extension DBMongoUpdateExpression: DBMongoFilterOptions {}


extension DBMongoUpdateExpression {
    
    public enum OperationType {
        
        case updateOne
        
        case updateMany
    }
    
}

extension DBMongoCollectionExpression {
    
    public func updateOne() -> DBMongoUpdateExpression<T> {
        return DBMongoUpdateExpression(query: query(), type: .updateOne, filter: filter)
    }
    
    public func updateMany() -> DBMongoUpdateExpression<T> {
        return DBMongoUpdateExpression(query: query(), type: .updateMany, filter: filter)
    }
}

extension DBMongoUpdateExpression {
    
    public func update(_ update: BSONDocument) -> Self {
        var result = self
        result.update = update
        return result
    }
}

extension DBMongoUpdateExpression {
    
    public func execute() -> EventLoopFuture<UpdateResult?> {
        guard let update = self.update else { fatalError() }
        switch type {
        case .updateOne: return query.collection.updateOne(filter: filter, update: update, options: options, session: query.session)
        case .updateMany: return query.collection.updateMany(filter: filter, update: update, options: options, session: query.session)
        }
    }
}

extension UpdateOptions: DBMongoArrayFiltersOptions {}
extension UpdateOptions: DBMongoCollationOptions {}
extension UpdateOptions: DBMongoBypassDocumentValidationOptions {}
extension UpdateOptions: DBMongoUpsertOptions {}
extension UpdateOptions: DBMongoWriteConcernOptions {}
