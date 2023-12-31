//
//  DBMongoCollectionExpression.swift
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

public struct DBMongoCollectionExpression<T: Codable>: DBMongoExpression {
    
    let connection: DBMongoConnectionProtocol
    
    public let database: MongoDatabase
    
    public let session: ClientSession?
    
    public let name: String
    
    public var filters: [BSONDocument] = []
    
    public var options = MongoCollectionOptions()
}

extension DBMongoCollectionExpression {
    
    public func withType<U>(_: U.Type) -> DBMongoCollectionExpression<U> {
        return DBMongoCollectionExpression<U>(connection: connection, database: database, session: session, name: name, options: options)
    }
}

extension MongoCollectionOptions: DBMongoReadConcernOption {}
extension MongoCollectionOptions: DBMongoReadPreferenceOption {}
extension MongoCollectionOptions: DBMongoWriteConcernOption {}
extension MongoCollectionOptions: DBMongoDataCodingStrategyOption {}
extension MongoCollectionOptions: DBMongoDateCodingStrategyOption {}
extension MongoCollectionOptions: DBMongoUUIDCodingStrategyOption {}
extension DBMongoCollectionExpression: DBMongoFilterOption {}

struct DBMongoCollection<T: Codable> {
    
    let collection: MongoCollection<T>
    
    let session: ClientSession?
}

extension DBMongoCollectionExpression {
    
    func query() -> DBMongoCollection<T> {
        return DBMongoCollection(collection: database.collection(name, withType: T.self, options: options), session: session)
    }
}
