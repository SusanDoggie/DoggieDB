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

struct QueryLauncher: _DBQueryLauncher {
    
    let connection: MongoDBDriver.Connection
    
    func count<Query>(_ query: Query) -> EventLoopFuture<Int> {
        
        guard let query = query as? DBQueryFindExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        do {
            
            let filter = try MongoPredicateExpression(.and(query.filters)).toBSONDocument()
            
            return connection.mongoQuery().collection(query.class).count().filter(filter).execute()
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func find<Query>(_ query: Query) -> EventLoopFuture<[_DBObject]> {
        
        guard let query = query as? DBQueryFindExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        do {
            
            let filter = try MongoPredicateExpression(.and(query.filters)).toBSONDocument()
            
            var mongoQuery = connection.mongoQuery().collection(query.class).find().filter(filter)
            
            if !query.sort.isEmpty {
                mongoQuery = mongoQuery.sort(query.sort.mapValues(DBMongoSortOrder.init))
            }
            if query.skip > 0 {
                mongoQuery = mongoQuery.skip(query.skip)
            }
            if query.limit != .max {
                mongoQuery = mongoQuery.limit(query.limit)
            }
            
            if !query.includes.isEmpty {
                let projection = Dictionary(uniqueKeysWithValues: query.includes.map { ($0, 1) })
                mongoQuery = mongoQuery.projection(BSONDocument(projection))
            }
            
            return mongoQuery.execute().flatMap { $0.toArray() }.map { $0.map { _DBObject(class: query.class, object: $0) } }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findAndDelete<Query>(_ query: Query) -> EventLoopFuture<[_DBObject]> {
        return connection.eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
    }
    
    func findOneAndUpdate<Query>(_ query: Query) -> EventLoopFuture<_DBObject?> {
        
        guard let query = query as? DBQueryFindOneExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        do {
            
            let filter = try MongoPredicateExpression(.and(query.filters)).toBSONDocument()
            
            var mongoQuery = connection.mongoQuery().collection(query.class).findOneAndUpdate().filter(filter)
            
            mongoQuery = mongoQuery.upsert(query.upsert)
            
            if !query.sort.isEmpty {
                mongoQuery = mongoQuery.sort(query.sort.mapValues(DBMongoSortOrder.init))
            }
            
            if !query.includes.isEmpty {
                let projection = Dictionary(uniqueKeysWithValues: query.includes.map { ($0, 1) })
                mongoQuery = mongoQuery.projection(BSONDocument(projection))
            }
            
            return mongoQuery.execute().map { $0.map { _DBObject(class: query.class, object: $0) } }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findOneAndDelete<Query>(_ query: Query) -> EventLoopFuture<_DBObject?> {
        
        guard let query = query as? DBQueryFindOneExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        do {
            
            let filter = try MongoPredicateExpression(.and(query.filters)).toBSONDocument()
            
            var mongoQuery = connection.mongoQuery().collection(query.class).findOneAndDelete().filter(filter)
            
            if !query.sort.isEmpty {
                mongoQuery = mongoQuery.sort(query.sort.mapValues(DBMongoSortOrder.init))
            }
            
            if !query.includes.isEmpty {
                let projection = Dictionary(uniqueKeysWithValues: query.includes.map { ($0, 1) })
                mongoQuery = mongoQuery.projection(BSONDocument(projection))
            }
            
            return mongoQuery.execute().map { $0.map { _DBObject(class: query.class, object: $0) } }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func insert<Data>(_ class: String, _ data: [String: Data]) -> EventLoopFuture<(_DBObject, Bool)?> {
        
        guard let data = data as? [String: DBData] else { fatalError() }
        
        do {
            
            return try connection.mongoQuery().collection(`class`)
                .insertOne().value(BSONDocument(data))
                .execute().map { $0.map { (_DBObject(class: `class`, object: ["_id": $0.insertedID]), false) }  }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
}

extension _DBObject {
    
    init(class: String, object: BSONDocument) {
        
        var _columns: [String: DBData] = [:]
        for (key, value) in object {
            guard let value = try? DBData(value) else { continue }
            _columns[key] = value
        }
        
        self.init(class: `class`, primaryKeys: ["_id"], columns: _columns)
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
            
        case let .between(x, from, to):
            
            self = try .and([
                .greaterThanOrEqualTo(MongoPredicateValue(from), MongoPredicateValue(x)),
                .lessThanOrEqualTo(MongoPredicateValue(to), MongoPredicateValue(x)),
            ])
            
        case let .notBetween(x, from, to):
            
            self = try .or([
                .lessThan(MongoPredicateValue(from), MongoPredicateValue(x)),
                .greaterThan(MongoPredicateValue(to), MongoPredicateValue(x)),
            ])
            
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
