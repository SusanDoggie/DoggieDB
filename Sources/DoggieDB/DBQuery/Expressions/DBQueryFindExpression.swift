//
//  DBQueryFindExpression.swift
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

public struct DBQueryFindExpression: DBQueryProtocol {
    
    public let connection: DBConnection
    
    public let table: String
    
    public var filters: [DBQueryPredicateExpression] = []
    
    public var skip: Int = 0
    
    public var limit: Int = .max
    
    public var sort: OrderedDictionary<String, DBQuerySortOrder> = [:]
    
    public var includes: Set<String> = []
    
    init(connection: DBConnection, table: String) {
        self.connection = connection
        self.table = table
    }
}

extension DBQuery {
    
    public func find(_ table: String) -> DBQueryFindExpression {
        return DBQueryFindExpression(connection: connection, table: table)
    }
}

extension DBQueryFindExpression {
    
    public func count() -> EventLoopFuture<Int> {
        guard let launcher = self.connection.launcher else {
            return eventLoopGroup.next().makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
        }
        return launcher.count(self)
    }
}

extension DBQueryFindExpression {
    
    public func toArray() -> EventLoopFuture<[DBObject]> {
        guard let launcher = self.connection.launcher else {
            return eventLoopGroup.next().makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
        }
        return launcher.find(self)
    }
    
    public func first() -> EventLoopFuture<DBObject?> {
        return self.limit(1).toArray().map { $0.first }
    }
}

extension DBQueryFindExpression {
    
    public func delete() -> EventLoopFuture<[DBObject]> {
        guard let launcher = self.connection.launcher else {
            return eventLoopGroup.next().makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
        }
        return launcher.findAndDelete(self)
    }
}

extension DBQueryFindExpression: DBQueryFilterOption { }
extension DBQueryFindExpression: DBQuerySkipOptions { }
extension DBQueryFindExpression: DBQueryLimitOption { }
extension DBQueryFindExpression: DBQuerySortOption { }
extension DBQueryFindExpression: DBQueryIncludesOption { }
