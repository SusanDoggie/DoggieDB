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

extension OrderedDictionary where Key == String, Value == DBQuerySortOrder {
    
    func serialize() -> SQLRaw {
        guard !self.isEmpty else { return "" }
        let list: [SQLRaw] = self.map {
            switch $1 {
            case .ascending: return "\(identifier: $0) ASC"
            case .descending: return "\(identifier: $0) DESC"
            }
        }
        return list.joined(separator: ",")
    }
}

struct SQLQueryLauncher: _DBQueryLauncher {
    
    let connection: DBSQLConnection
    
    func count<Query>(_ query: Query) -> EventLoopFuture<Int> {
        
        guard let query = query as? DBQueryFindExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        do {
            
            guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
            
            let sql: SQLRaw = try """
                SELECT COUNT(*)
                FROM \(identifier: query.class)
                WHERE \(query.filters.serialize(dialect.self))
                """
            
            return connection.execute(sql).map { $0.first.flatMap { $0[$0.keys[0]]?.intValue } ?? 0 }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func _find<Query>(_ query: Query) -> EventLoopFuture<(SQLRaw, [String])> {
        
        guard let query = query as? DBQueryFindExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        do {
            
            guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
            
            return connection.primaryKey(of: query.class).flatMapThrowing { primaryKeys in
                
                var sql: SQLRaw = ""
                
                if query.includes.isEmpty {
                    sql += "SELECT * "
                } else {
                    let includes = query.includes.union(primaryKeys)
                    sql += "SELECT \(includes.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ",")) "
                }
                
                sql += try """
                    FROM \(identifier: query.class)
                    WHERE \(query.filters.serialize(dialect.self))
                    ORDER BY \(query.sort.serialize())
                    """
                
                if query.limit != .max {
                    sql += " LIMIT \(query.limit)"
                }
                if query.skip > 0 {
                    sql += " OFFSET \(query.skip)"
                }
                
                return (sql, primaryKeys)
            }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func find<Query>(_ query: Query) -> EventLoopFuture<[_DBObject]> {
        
        guard let query = query as? DBQueryFindExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        return self._find(query).flatMap { sql, primaryKeys in
            connection.execute(sql).map { $0.map { _DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
        }
    }
    
    func find<Query>(_ query: Query, forEach: @escaping (_DBObject) -> Void) -> EventLoopFuture<Void> {
        
        guard let query = query as? DBQueryFindExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        return self._find(query).flatMap { sql, primaryKeys in
            
            connection.execute(sql) {
                
                forEach(_DBObject(table: query.class, primaryKeys: primaryKeys, object: $0))
                
            }.map { _ in }
        }
    }
    
    func find<Query>(_ query: Query, forEach: @escaping (_DBObject) throws -> Void) -> EventLoopFuture<Void> {
        
        guard let query = query as? DBQueryFindExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        return self._find(query).flatMap { sql, primaryKeys in
            
            connection.execute(sql) {
                
                try forEach(_DBObject(table: query.class, primaryKeys: primaryKeys, object: $0))
                
            }.map { _ in }
        }
    }
    
    func findAndDelete<Query>(_ query: Query) -> EventLoopFuture<Int?> {
        
        guard let query = query as? DBQueryFindExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        do {
            
            guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
            
            let sql: SQLRaw = try """
                DELETE FROM \(identifier: query.class)
                WHERE \(query.filters.serialize(dialect.self))
                RETURNING 0
                """
            
            return connection.execute(sql).map { $0.count }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func _findOne(_ query: DBQueryFindOneExpression) throws -> SQLRaw {
        
        guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
        guard let rowId = dialect.rowId else { throw Database.Error.unsupportedOperation }
        
        return try """
            SELECT \(identifier: rowId)
            FROM \(identifier: query.class)
            WHERE \(query.filters.serialize(dialect.self))
            ORDER BY \(query.sort.serialize())
            LIMIT 1
            """
    }
    
    func findOneAndUpdate<Query>(_ query: Query) -> EventLoopFuture<_DBObject?> {
        
        guard let query = query as? DBQueryFindOneExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        do {
            
            if query.upsert {
                return self.findOneAndUpsert(query)
            }
            
            guard let rowId = connection.driver.sqlDialect?.rowId else { throw Database.Error.unsupportedOperation }
            
            var update: [String: SQLRaw] = [:]
            for (key, value) in query.update {
                switch value {
                case let .set(value): update[key] = "\(value)"
                case let .inc(value): update[key] = "\(identifier: key) + \(value)"
                case let .mul(value): update[key] = "\(identifier: key) * \(value)"
                case let .min(value): update[key] = "\(identifier: key) + \(value)"
                case let .max(value): update[key] = "\(identifier: key) + \(value)"
                default: throw Database.Error.unsupportedOperation
                }
            }
            
            var sql: SQLRaw = try """
                UPDATE \(identifier: query.class)
                SET \(update.map { "\(identifier: $0) = \($1)" as SQLRaw }.joined(separator: ","))
                WHERE \(identifier: rowId) IN (\(self._findOne(query)))
                """
            
            return connection.primaryKey(of: query.class).flatMap { primaryKeys in
                
                if query.includes.isEmpty {
                    sql += " RETURNING *"
                } else {
                    let includes = query.includes.union(primaryKeys)
                    sql += " RETURNING \(includes.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ",")) "
                }
                
                return connection.execute(sql).map { $0.first.map { _DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
            }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findOneAndUpsert<Query>(_ query: Query) -> EventLoopFuture<_DBObject?> {
        
        return connection.eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
    }
    
    func findOneAndDelete<Query>(_ query: Query) -> EventLoopFuture<_DBObject?> {
        
        guard let query = query as? DBQueryFindOneExpression else { fatalError() }
        guard self.connection === query.connection else { fatalError() }
        
        do {
            
            guard let rowId = connection.driver.sqlDialect?.rowId else { throw Database.Error.unsupportedOperation }
            
            var sql: SQLRaw = try """
                DELETE FROM \(identifier: query.class)
                WHERE \(identifier: rowId) IN (\(self._findOne(query)))
                """
            
            return connection.primaryKey(of: query.class).flatMap { primaryKeys in
                
                if query.includes.isEmpty {
                    sql += " RETURNING *"
                } else {
                    let includes = query.includes.union(primaryKeys)
                    sql += " RETURNING \(includes.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ",")) "
                }
                
                return connection.execute(sql).map { $0.first.map { _DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
            }
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func insert<Data>(_ class: String, _ data: [String: Data]) -> EventLoopFuture<(_DBObject, Bool)?> {
        
        guard let data = data as? [String: DBData] else { fatalError() }
        
        var columns: [String] = []
        var values: [DBData] = []
        
        for (key, value) in data {
            columns.append(key)
            values.append(value)
        }
        
        let sql: SQLRaw = """
            INSERT INTO \(identifier: `class`)
            (\(columns.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ",")))
            VALUES (\(values.map { "\($0)" as SQLRaw }.joined(separator: ",")))
            RETURNING *
            """
        
        return connection.primaryKey(of: `class`).flatMap { primaryKeys in
            connection.execute(sql).map { $0.first.map { (_DBObject(table: `class`, primaryKeys: primaryKeys, object: $0), true) } }
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
