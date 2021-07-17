//
//  SQLQueryLauncher.swift
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

struct SQLQueryLauncher: _DBQueryLauncher {
    
    let connection: DBSQLConnection
    
    func count<Query>(_ query: Query) -> EventLoopFuture<Int> {
        
        guard let query = query as? DBQueryFindExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        do {
            
            let filter = try SQLPredicateExpression(.and(query.filters))
            
            let sqlQuery = connection.sqlQuery().select().columns("COUNT(*)").from(query.class).where { _ in filter }
            
            return sqlQuery.execute().map { $0.first.flatMap { $0[$0.keys[0]]?.intValue } ?? 0 }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func find<Query>(_ query: Query) -> EventLoopFuture<[_DBObject]> {
        
        guard let query = query as? DBQueryFindExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        do {
            
            let filter = try SQLPredicateExpression(.and(query.filters))
            
            return connection.primaryKey(of: query.class).flatMap { primaryKeys in
                
                var sqlQuery = connection.sqlQuery().select()
                
                if query.includes.isEmpty {
                    sqlQuery = sqlQuery.columns("COUNT(*)")
                } else {
                    let includes = query.includes.union(primaryKeys)
                    sqlQuery = sqlQuery.columns(includes.map { "\(identifier: $0)" })
                }
                
                sqlQuery = sqlQuery.from(query.class).where { _ in filter }
                
                if !query.sort.isEmpty {
                    sqlQuery = sqlQuery.orderBy(query.sort.map {
                        switch $1 {
                        case .ascending: return "\(identifier: $0) ASC"
                        case .descending: return "\(identifier: $0) DESC"
                        }
                    })
                }
                if query.limit != .max {
                    sqlQuery = sqlQuery.limit(query.limit)
                }
                if query.skip > 0 {
                    sqlQuery = sqlQuery.offset(query.skip)
                }
                
                return sqlQuery.execute().map { $0.map { _DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
            }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findAndDelete<Query>(_ query: Query) -> EventLoopFuture<[_DBObject]> {
        
        guard let query = query as? DBQueryFindExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        do {
            
            let filter = try SQLPredicateExpression(.and(query.filters))
            
            return connection.primaryKey(of: query.class).flatMap { primaryKeys in
                
                let sqlQuery = connection.sqlQuery().delete(query.class).where { _ in filter }.returning("*")
                
                return sqlQuery.execute().map { $0.map { _DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
            }
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findOneAndUpdate<Query>(_ query: Query) -> EventLoopFuture<_DBObject?> {
        fatalError()
    }
    
    func findOneAndDelete<Query>(_ query: Query) -> EventLoopFuture<_DBObject?> {
        
        guard let query = query as? DBQueryFindExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        do {
            
            guard let rowId = connection.driver.sqlDialect?.rowId else { throw Database.Error.unsupportedOperation }
            
            let filter = try SQLPredicateExpression(.and(query.filters))
            
            return connection.primaryKey(of: query.class).flatMap { primaryKeys in
                
                let select = SQLSelectBuilder.select().columns("\(identifier: rowId)").from(query.class).where { _ in filter }.limit(1)
                
                let sqlQuery = connection.sqlQuery().delete(query.class).where { _ in .containsInSelect(.key(rowId), select) }.returning("*")
                
                return sqlQuery.execute().map { $0.first.map { _DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
            }
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func insert<Data>(_ class: String, _ data: [String: Data]) -> EventLoopFuture<(_DBObject, Bool)?> {
        
        guard let data = data as? [String: DBData] else { fatalError() }
        
        return connection.primaryKey(of: `class`).flatMap { primaryKeys in
            
            var columns: [String] = []
            var values: [DBData] = []
            
            for (key, value) in data {
                columns.append(key)
                values.append(value)
            }
            
            let sqlQuery = connection.sqlQuery().insert(`class`).columns(columns).values(values.map { "\($0)" }).returning("*")
            
            return sqlQuery.execute().map { $0.first.map { (_DBObject(table: `class`, primaryKeys: primaryKeys, object: $0), true) } }
        }
    }
}

extension _DBObject {
    
    init(table: String, primaryKeys: [String], object: DBQueryRow) {
        
        var _columns: [String: DBData] = [:]
        for key in object.keys {
            guard let value = object[key] else { continue }
            _columns[key] = value
        }
        
        self.init(class: table, primaryKeys: Set(primaryKeys), columns: _columns)
    }
}

extension SQLPredicateExpression {
    
    init(_ expression: DBQueryPredicateExpression) throws {
        switch expression {
        case let .not(expr): self = try .not(SQLPredicateExpression(expr))
        case let .equal(lhs, rhs): self = .equal(SQLPredicateValue(lhs), SQLPredicateValue(rhs))
        case let .notEqual(lhs, rhs): self = .notEqual(SQLPredicateValue(lhs), SQLPredicateValue(rhs))
        case let .lessThan(lhs, rhs): self = .lessThan(SQLPredicateValue(lhs), SQLPredicateValue(rhs))
        case let .greaterThan(lhs, rhs): self = .greaterThan(SQLPredicateValue(lhs), SQLPredicateValue(rhs))
        case let .lessThanOrEqualTo(lhs, rhs): self = .lessThanOrEqualTo(SQLPredicateValue(lhs), SQLPredicateValue(rhs))
        case let .greaterThanOrEqualTo(lhs, rhs): self = .greaterThanOrEqualTo(SQLPredicateValue(lhs), SQLPredicateValue(rhs))
        case let .between(x, from, to): self = .between(SQLPredicateValue(x), SQLPredicateValue(from), SQLPredicateValue(to))
        case let .notBetween(x, from, to): self = .notBetween(SQLPredicateValue(x), SQLPredicateValue(from), SQLPredicateValue(to))
        case let .containsIn(x, .value(list)):
            
            guard let array = list.toDBData().array else { throw Database.Error.invalidExpression }
            self = .containsIn(SQLPredicateValue(x), array)
            
        case let .notContainsIn(x, .value(list)):
            
            guard let array = list.toDBData().array else { throw Database.Error.invalidExpression }
            self = .notContainsIn(SQLPredicateValue(x), array)
            
        case let .like(value, pattern): self = .like(SQLPredicateValue(value), pattern)
        case let .notLike(value, pattern): self = .notLike(SQLPredicateValue(value), pattern)
        case let .and(list): self = try .and(list.map(SQLPredicateExpression.init))
        case let .or(list): self = try .or(list.map(SQLPredicateExpression.init))
        default: throw Database.Error.invalidExpression
        }
    }
}

extension SQLPredicateValue {
    
    init(_ value: DBQueryPredicateValue) {
        switch value {
        case let .key(key): self = .key(key)
        case let .value(value): self = .value(value.toDBData())
        }
    }
}
