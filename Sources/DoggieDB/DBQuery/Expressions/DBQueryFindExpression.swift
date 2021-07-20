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

@_implementationOnly import Private

public struct DBQueryFindExpression: DBQueryProtocol {
    
    public let connection: DBConnection
    
    public let `class`: String
    
    var filters: [DBQueryPredicateExpression] = []
    
    var skip: Int = 0
    
    var limit: Int = .max
    
    var sort: OrderedDictionary<String, DBQuerySortOrder> = [:]
    
    var includes: Set<String> = []
    
    init(connection: DBConnection, class: String) {
        self.connection = connection
        self.class = `class`
    }
}

extension DBQuery {
    
    public func find(_ class: String) -> DBQueryFindExpression {
        return DBQueryFindExpression(connection: connection, class: `class`)
    }
}

extension _DBQuery {
    
    init(_ query: DBQueryFindExpression) {
        self.init(class: query.class, query: [
            "filters": query.filters,
            "skip": query.skip,
            "limit": query.limit,
            "sort": query.sort,
            "includes": query.includes,
        ])
    }
}

extension DBQueryFindExpression {
    
    public func count() -> EventLoopFuture<Int> {
        guard let launcher = self.connection.launcher else {
            return eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
        }
        return launcher.count(_DBQuery(self))
    }
}

extension DBQueryFindExpression {
    
    public func toArray() -> EventLoopFuture<[DBObject]> {
        guard let launcher = self.connection.launcher else {
            return eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
        }
        return launcher.find(_DBQuery(self)).map { $0.map(DBObject.init) }
    }
    
    public func forEach(_ body: @escaping (DBObject) -> Void) -> EventLoopFuture<Void> {
        guard let launcher = self.connection.launcher else {
            return eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
        }
        return launcher.find(_DBQuery(self)) { body(DBObject($0)) }
    }
    
    public func forEach(_ body: @escaping (DBObject) throws -> Void) -> EventLoopFuture<Void> {
        guard let launcher = self.connection.launcher else {
            return eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
        }
        return launcher.find(_DBQuery(self)) { try body(DBObject($0)) }
    }
    
    public func first() -> EventLoopFuture<DBObject?> {
        return self.limit(1).toArray().map { $0.first }
    }
}

extension DBQueryFindExpression {
    
    public func delete() -> EventLoopFuture<Int?> {
        guard let launcher = self.connection.launcher else {
            return eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
        }
        return launcher.findAndDelete(_DBQuery(self))
    }
}

extension DBQueryFindExpression {
    
    public func filter(_ predicate: (DBQueryPredicateBuilder) -> DBQueryPredicateExpression) -> Self {
        var result = self
        result.filters.append(predicate(DBQueryPredicateBuilder()))
        return result
    }
    
    public func skip(_ skip: Int) -> Self {
        var result = self
        result.skip = skip
        return result
    }
    
    public func limit(_ limit: Int) -> Self {
        var result = self
        result.limit = limit
        return result
    }
    
    public func sort(_ sort: OrderedDictionary<String, DBQuerySortOrder>) -> Self {
        var result = self
        result.sort = sort
        return result
    }
    
    public func includes(_ includes: Set<String>) -> Self {
        var result = self
        result.includes = includes
        return result
    }
}
