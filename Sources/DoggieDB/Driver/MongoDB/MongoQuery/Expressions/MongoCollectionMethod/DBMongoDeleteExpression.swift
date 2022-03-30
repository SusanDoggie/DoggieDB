//
//  DBMongoDeleteExpression.swift
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

public struct DBMongoDeleteExpression<T: Codable>: DBMongoExpression {
    
    let query: DBMongoCollection<T>
    
    public let type: OperationType
    
    public var filters: [BSONDocument]
    
    public var options: DeleteOptions = DeleteOptions()
}

extension DBMongoDeleteExpression: DBMongoFilterOption {}


extension DBMongoDeleteExpression {
    
    public enum OperationType: CaseIterable {
        
        case deleteOne
        
        case deleteMany
    }
    
}

extension DBMongoCollectionExpression {
    
    public func deleteOne() -> DBMongoDeleteExpression<T> {
        return DBMongoDeleteExpression(query: query(), type: .deleteOne, filters: filters)
    }
    
    public func deleteMany() -> DBMongoDeleteExpression<T> {
        return DBMongoDeleteExpression(query: query(), type: .deleteMany, filters: filters)
    }
}

extension DBMongoDeleteExpression {
    
    @discardableResult
    public func execute() async throws -> DeleteResult? {
        switch type {
        case .deleteOne: return try await query.collection.deleteOne(_filter, options: options, session: query.session).get()
        case .deleteMany: return try await query.collection.deleteMany(_filter, options: options, session: query.session).get()
        }
    }
}

extension DeleteOptions: DBMongoCollationOption {}
extension DeleteOptions: DBMongoWriteConcernOption {}
