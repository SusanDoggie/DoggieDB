//
//  QueryLauncher.swift
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

struct QueryLauncher: DBQueryLauncher {
    
    let connection: MongoDBDriver.Connection
    
    func count<Query>(_ query: Query) -> EventLoopFuture<Int> {
        
        guard let query = query as? DBQueryFindExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        do {
            
            let filter = try self.filterBSONDocument(query)
            
            return connection.mongoQuery().collection(query.table).count().filter(filter).execute()
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func execute<Query, Result>(_ query: Query) -> EventLoopFuture<[Result]> {
        
        do {
            
            switch (query, Result.self) {
            
            case let (_query, _) as (DBQueryFindExpression, DBObject.Type):
                
                let filter = try self.filterBSONDocument(_query)
                
                var query = connection.mongoQuery().collection(_query.table).find().filter(filter)
                
                if !_query.sort.isEmpty {
                    query = query.sort(_query.sort.mapValues(DBMongoSortOrder.init))
                }
                if _query.skip > 0 {
                    query = query.skip(_query.skip)
                }
                if _query.limit != .max {
                    query = query.limit(_query.limit)
                }
                
                if !_query.includes.isEmpty {
                    let projection = Dictionary(uniqueKeysWithValues: _query.includes.map { ($0, 1) })
                    query = query.projection(BSONDocument(projection))
                }
                
                return query.execute().flatMap { $0.toArray() }.map { $0.map { DBObject($0) as! Result } }
                
            default: fatalError()
            }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
}

extension DBObject {
    
    init(_ object: BSONDocument) {
        self.init()
    }
}

extension QueryLauncher {
    
    func filterBSONDocument(_ query: DBQueryFindExpression) throws -> BSONDocument {
        return try query.filters.map(MongoPredicateExpression.init).reduce { $0 && $1 }?.toBSONDocument() ?? [:]
    }
}

extension MongoPredicateExpression {
    
    init(_ expression: DBQueryPredicateExpression) throws {
        switch expression {
        case let .not(expr): self = try .not(MongoPredicateExpression(expr))
        case let .equal(lhs, rhs): self = try .equal(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .notEqual(lhs, rhs): self = try .notEqual(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .lessThan(lhs, rhs): self = try .lessThan(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .greaterThan(lhs, rhs): self = try .greaterThan(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .lessThanOrEqualTo(lhs, rhs): self = try .lessThanOrEqualTo(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .greaterThanOrEqualTo(lhs, rhs): self = try .greaterThanOrEqualTo(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .containsIn(lhs, rhs): self = try .containsIn(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .notContainsIn(lhs, rhs): self = try .notContainsIn(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .matching(lhs, rhs): self = try .matching(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .startsWith(value, pattern, options): self = try .startsWith(MongoPredicateValue(value), pattern, options: options)
        case let .endsWith(value, pattern, options): self = try .endsWith(MongoPredicateValue(value), pattern, options: options)
        case let .contains(value, pattern, options): self = try .contains(MongoPredicateValue(value), pattern, options: options)
        case let .and(list): self = try .and(list.map(MongoPredicateExpression.init))
        case let .or(list): self = try .or(list.map(MongoPredicateExpression.init))
        default: throw Database.Error.invalidExpression
        }
    }
}

extension MongoPredicateValue {
    
    init(_ value: DBQueryPredicateValue) throws {
        switch value {
        case let .key(key): self = .key(key)
        case let .value(value): self = try .value(BSON(value.toDBData()))
        }
    }
}

extension DBMongoSortOrder {
    
    init(_ order: DBQuerySortOrder) {
        switch order {
        case .ascending: self = .ascending
        case .descending: self = .descending
        }
    }
}

extension MongoDBDriver.Connection: DBQueryLauncherProvider {
    
    var _launcher: Any {
        return QueryLauncher(connection: self)
    }
}
