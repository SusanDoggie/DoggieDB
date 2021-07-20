//
//  DBQueryFindOneExpression.swift
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

public struct DBQueryFindOneExpression: DBQueryProtocol {
    
    public let connection: DBConnection
    
    public let `class`: String
    
    public var filters: [DBQueryPredicateExpression] = []
    
    public var sort: OrderedDictionary<String, DBQuerySortOrder> = [:]
    
    public var includes: Set<String> = []
    
    public var returning: DBQueryReturning = .after
    
    init(connection: DBConnection, class: String) {
        self.connection = connection
        self.class = `class`
    }
}

extension DBQuery {
    
    public func findOne(_ class: String) -> DBQueryFindOneExpression {
        return DBQueryFindOneExpression(connection: connection, class: `class`)
    }
}

extension DBQueryFindOneExpression {
    
    public func update(_ update: [String: DBData]) -> EventLoopFuture<DBObject?> {
        return self.update(update.mapValues { .set($0) })
    }
    
    public func update(_ update: [String: DBQueryUpdateOperation]) -> EventLoopFuture<DBObject?> {
        guard let launcher = self.connection.launcher else {
            return eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
        }
        return launcher.findOneAndUpdate(self, update).map { $0.map(DBObject.init) }
    }
}

extension DBQueryFindOneExpression {
    
    public func upsert(_ update: [String: DBData], setOnInsert: [String: DBData] = [:]) -> EventLoopFuture<DBObject?> {
        return self.upsert(update.mapValues { .set($0) }, setOnInsert: setOnInsert)
    }
    
    public func upsert(_ update: [String: DBQueryUpdateOperation], setOnInsert: [String: DBData] = [:]) -> EventLoopFuture<DBObject?> {
        guard let launcher = self.connection.launcher else {
            return eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
        }
        return launcher.findOneAndUpsert(self, update, setOnInsert).map { $0.map(DBObject.init) }
    }
}

extension DBQueryFindOneExpression {
    
    public func delete() -> EventLoopFuture<DBObject?> {
        guard let launcher = self.connection.launcher else {
            return eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
        }
        return launcher.findOneAndDelete(self).map { $0.map(DBObject.init) }
    }
}

extension DBQueryFindOneExpression: DBQueryFilterOption { }
extension DBQueryFindOneExpression: DBQuerySortOption { }
extension DBQueryFindOneExpression: DBQueryIncludesOption { }
