//
//  DBMongoUpdateExpression.swift
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

public struct DBMongoUpdateExpression<T: Codable>: DBMongoExpression {
    
    let query: DBMongoCollection<T>
    
    public let type: OperationType
    
    public var filters: [BSONDocument]
    
    public var update: BSONDocument?
    
    public var options: UpdateOptions = UpdateOptions()
}

extension DBMongoUpdateExpression: DBMongoFilterOption {}


extension DBMongoUpdateExpression {
    
    public enum OperationType {
        
        case updateOne
        
        case updateMany
    }
    
}

extension DBMongoCollectionExpression {
    
    public func updateOne() -> DBMongoUpdateExpression<T> {
        return DBMongoUpdateExpression(query: query(), type: .updateOne, filters: filters)
    }
    
    public func updateMany() -> DBMongoUpdateExpression<T> {
        return DBMongoUpdateExpression(query: query(), type: .updateMany, filters: filters)
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
    
    @discardableResult
    public func execute() async throws -> UpdateResult? {
        guard let update = self.update else { fatalError() }
        switch type {
        case .updateOne: return try await query.collection.updateOne(filter: _filter, update: update, options: options, session: query.session).get()
        case .updateMany: return try await query.collection.updateMany(filter: _filter, update: update, options: options, session: query.session).get()
        }
    }
}

extension UpdateOptions: DBMongoArrayFiltersOption {}
extension UpdateOptions: DBMongoCollationOption {}
extension UpdateOptions: DBMongoBypassDocumentValidationOption {}
extension UpdateOptions: DBMongoUpsertOption {}
extension UpdateOptions: DBMongoWriteConcernOption {}
