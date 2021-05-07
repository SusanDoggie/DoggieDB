//
//  DBQuery.swift
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

public struct DBQuery {
    
    public let connection: DBConnection
    
    public var filters: [DBQueryPredicateExpression] = []
    
    public var skip: Int = 0
    
    public var limit: Int = .max
    
    public var sort: OrderedDictionary<String, SortOrder> = [:]
    
    public var returning: Returning = .after
    
    init(connection: DBConnection) {
        self.connection = connection
    }
}

extension DBQuery {
    
    public var eventLoop: EventLoop {
        return connection.eventLoop
    }
}

extension DBConnection where Self: DBSQLConnection {
    
    public func query() -> DBQuery {
        return DBQuery(connection: self)
    }
}

extension DBQuery {
    
    public func filter(_ predicate: (DBQueryPredicateBuilder) -> DBQueryPredicateExpression) throws -> Self {
        var result = self
        result.filters.append(predicate(DBQueryPredicateBuilder()))
        return result
    }
}

extension DBQuery {
    
    public func limit(_ limit: Int) -> Self {
        var result = self
        result.limit = limit
        return result
    }
    
    public func skip(_ skip: Int) -> Self {
        var result = self
        result.skip = skip
        return result
    }
}

extension DBQuery {
    
    public enum SortOrder {
        
        case ascending
        
        case descending
    }
    
    public func sort(_ sort: OrderedDictionary<String, SortOrder>) -> Self {
        var result = self
        result.sort = sort
        return result
    }
}

extension DBQuery {
    
    public enum Returning {
        
        case before
        
        case after
    }
    
    public func returning(_ returning: Returning) -> Self {
        var result = self
        result.returning = returning
        return result
    }
}
