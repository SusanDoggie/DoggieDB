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
    
    fileprivate func serialize() -> SQLRaw {
        let list: [SQLRaw] = self.map {
            switch $1 {
            case .ascending: return "\(identifier: $0) ASC"
            case .descending: return "\(identifier: $0) DESC"
            }
        }
        return list.joined(separator: ",")
    }
}

extension _DBQuery {
    
    fileprivate var filters: [DBQueryPredicateExpression] {
        return self["filters"] as! Array
    }
    fileprivate var sort: OrderedDictionary<String, DBQuerySortOrder> {
        return self["sort"] as! OrderedDictionary
    }
    fileprivate var skip: Int {
        return self["skip"] as! Int
    }
    fileprivate var limit: Int {
        return self["limit"] as! Int
    }
    fileprivate var includes: Set<String> {
        return self["includes"] as! Set
    }
    fileprivate var returning: DBQueryReturning {
        return self["returning"] as! DBQueryReturning
    }
}

extension Dictionary where Key == String, Value == DBQueryUpdateOperation {
    
    fileprivate func serialize(_ table: String, _ columnInfos: [DBSQLColumnInfo], _ dialect: SQLDialect.Type) throws -> [String: SQLRaw] {
        
        var update: [String: SQLRaw] = [:]
        
        for (key, value) in self {
            
            guard let column_info = columnInfos.first(where: { $0.name == key }) else { throw Database.Error.columnNotExist }
            
            switch value {
            case let .set(value): update[key] = try dialect.typeCast(value.toDBData(), column_info.type)
            case let .increment(value): update[key] = try dialect.updateOperation("\(table).\(key)", column_info.type, .increment(value.toDBData()))
            case let .decrement(value): update[key] = try dialect.updateOperation("\(table).\(key)", column_info.type, .decrement(value.toDBData()))
            case let .multiply(value): update[key] = try dialect.updateOperation("\(table).\(key)", column_info.type, .multiply(value.toDBData()))
            case let .divide(value): update[key] = try dialect.updateOperation("\(table).\(key)", column_info.type, .divide(value.toDBData()))
            case let .min(value): update[key] = try dialect.updateOperation("\(table).\(key)", column_info.type, .min(value.toDBData()))
            case let .max(value): update[key] = try dialect.updateOperation("\(table).\(key)", column_info.type, .max(value.toDBData()))
            case let .addToSet(list): update[key] = try dialect.updateOperation("\(table).\(key)", column_info.type, .addToSet(list.map { $0.toDBData() }))
            case let .push(list): update[key] = try dialect.updateOperation("\(table).\(key)", column_info.type, .push(list.map { $0.toDBData() }))
            case let .removeAll(list): update[key] = try dialect.updateOperation("\(table).\(key)", column_info.type, .removeAll(list.map { $0.toDBData() }))
            case .popFirst: update[key] = try dialect.updateOperation("\(table).\(key)", column_info.type, .popFirst)
            case .popLast: update[key] = try dialect.updateOperation("\(table).\(key)", column_info.type, .popLast)
            }
        }
        
        return update
    }
}

extension _DBObject {
    
    fileprivate init(table: String, primaryKeys: [String], object: DBQueryRow) {
        
        var _columns: [String: DBData] = [:]
        for key in object.keys {
            guard let value = object[key] else { continue }
            _columns[key] = value
        }
        
        self.init(class: table, primaryKeys: Set(primaryKeys), columns: _columns)
    }
}

struct SQLQueryLauncher: _DBQueryLauncher {
    
    let connection: DBSQLConnection
    
    func _count(_ query: _DBQuery, _ primaryKeys: [String]) -> EventLoopFuture<Int> {
        
        do {
            
            guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
            
            var sql: SQLRaw = "SELECT COUNT(*) FROM \(identifier: query.class)"
            
            if !query.filters.isEmpty {
                sql += try "WHERE \(query.filters.serialize(dialect.self, primaryKeys))"
            }
            
            return connection.execute(sql).map { $0.first.flatMap { $0[$0.keys[0]]?.intValue } ?? 0 }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    func count(_ query: _DBQuery) -> EventLoopFuture<Int> {
        
        if query.filters.requiredPrimaryKeys {
            
            return connection.primaryKey(of: query.class).flatMap { primaryKeys in
                
                self._count(query, primaryKeys)
            }
            
        } else {
            
            return self._count(query, [])
        }
    }
    
    func _find(_ query: _DBQuery) -> EventLoopFuture<(SQLRaw, [String])> {
        
        do {
            
            guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
            
            return connection.primaryKey(of: query.class).flatMapThrowing { primaryKeys in
                
                var sql: SQLRaw = ""
                
                if query.includes.isEmpty {
                    sql += "SELECT *"
                } else {
                    let includes = query.includes.union(primaryKeys)
                    sql += "SELECT \(includes.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ","))"
                }
                
                sql += "FROM \(identifier: query.class)"
                
                if !query.filters.isEmpty {
                    sql += try "WHERE \(query.filters.serialize(dialect.self, primaryKeys))"
                }
                
                if !query.sort.isEmpty {
                    sql += "ORDER BY \(query.sort.serialize())"
                }
                
                if query.limit != .max {
                    sql += "LIMIT \(query.limit)"
                }
                if query.skip > 0 {
                    sql += "OFFSET \(query.skip)"
                }
                
                return (sql, primaryKeys)
            }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func find(_ query: _DBQuery) -> EventLoopFuture<[_DBObject]> {
        
        return self._find(query).flatMap { sql, primaryKeys in
            connection.execute(sql).map { $0.map { _DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
        }
    }
    
    func find(_ query: _DBQuery, forEach: @escaping (_DBObject) -> Void) -> EventLoopFuture<Void> {
        
        return self._find(query).flatMap { sql, primaryKeys in
            
            connection.execute(sql) {
                
                forEach(_DBObject(table: query.class, primaryKeys: primaryKeys, object: $0))
                
            }.map { _ in }
        }
    }
    
    func find(_ query: _DBQuery, forEach: @escaping (_DBObject) throws -> Void) -> EventLoopFuture<Void> {
        
        return self._find(query).flatMap { sql, primaryKeys in
            
            connection.execute(sql) {
                
                try forEach(_DBObject(table: query.class, primaryKeys: primaryKeys, object: $0))
                
            }.map { _ in }
        }
    }
    
    func _findAndDelete(_ query: _DBQuery, _ primaryKeys: [String]) -> EventLoopFuture<Int?> {
        
        do {
            
            guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
            
            var sql: SQLRaw = "DELETE FROM \(identifier: query.class)"
            
            if !query.filters.isEmpty {
                sql += try "WHERE \(query.filters.serialize(dialect.self, primaryKeys))"
            }
            
            sql += "RETURNING 0"
            
            return connection.execute(sql).map { $0.count }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findAndDelete(_ query: _DBQuery) -> EventLoopFuture<Int?> {
        
        if query.filters.requiredPrimaryKeys {
            
            return connection.primaryKey(of: query.class).flatMap { primaryKeys in
                
                self._findAndDelete(query, primaryKeys)
            }
            
        } else {
            
            return self._findAndDelete(query, [])
        }
    }
    
    func _findOne(_ query: _DBQuery, _ primaryKeys: [String], withData: Bool) throws -> SQLRaw {
        
        guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
        guard let rowId = dialect.rowId else { throw Database.Error.unsupportedOperation }
        
        var sql: SQLRaw
        
        if withData {
            sql = "SELECT \(identifier: rowId), * FROM \(identifier: query.class)"
        } else {
            sql = "SELECT \(identifier: rowId) FROM \(identifier: query.class)"
        }
        
        if !query.filters.isEmpty {
            sql += try "WHERE \(query.filters.serialize(dialect.self, primaryKeys))"
        }
        
        if !query.sort.isEmpty {
            sql += "ORDER BY \(query.sort.serialize())"
        }
        
        return sql + "LIMIT 1"
    }
    
    func _findOneAndUpdate<Update>(_ query: _DBQuery, _ update: [String: Update]) -> EventLoopFuture<(SQLRaw, [String], [DBSQLColumnInfo])> {
        
        guard let update = update as? [String: DBQueryUpdateOperation] else { fatalError() }
        
        switch query.returning {
        
        case .before:
            
            var temp: String
            var counter = 0
            repeat {
                temp = "temp_\(counter)"
                counter += 1
            } while temp == query.class
            
            return connection.columns(of: query.class).flatMap { columnInfos in
                
                connection.primaryKey(of: query.class).flatMapThrowing { primaryKeys in
                    
                    guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
                    guard let rowId = dialect.rowId else { throw Database.Error.unsupportedOperation }
                    
                    var sql: SQLRaw = try """
                        UPDATE \(identifier: query.class)
                        SET \(update.serialize(query.class, columnInfos, dialect).map { "\(identifier: $0) = \($1)" as SQLRaw }.joined(separator: ","))
                        FROM (\(self._findOne(query, primaryKeys, withData: true))) AS \(identifier: temp)
                        WHERE \(identifier: query.class).\(identifier: rowId) = \(identifier: temp).\(identifier: rowId)
                        """
                    
                    let includes = query.includes.isEmpty ? Set(columnInfos.map { $0.name }) : query.includes.union(primaryKeys)
                    sql += "RETURNING \(includes.map { "\(identifier: temp).\(identifier: $0)" as SQLRaw }.joined(separator: ","))"
                    
                    return (sql, primaryKeys, columnInfos)
                }
            }
            
        case .after:
            
            return connection.columns(of: query.class).flatMap { columnInfos in
                
                connection.primaryKey(of: query.class).flatMapThrowing { primaryKeys in
                    
                    guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
                    guard let rowId = dialect.rowId else { throw Database.Error.unsupportedOperation }
                    
                    var sql: SQLRaw = try """
                        UPDATE \(identifier: query.class)
                        SET \(update.serialize(query.class, columnInfos, dialect).map { "\(identifier: $0) = \($1)" as SQLRaw }.joined(separator: ","))
                        WHERE \(identifier: rowId) IN (\(self._findOne(query, primaryKeys, withData: false)))
                        """
                    
                    if query.includes.isEmpty {
                        sql += "RETURNING *"
                    } else {
                        let includes = query.includes.union(primaryKeys)
                        sql += "RETURNING \(includes.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ","))"
                    }
                    
                    return (sql, primaryKeys, columnInfos)
                }
            }
        }
    }
    
    func findOneAndUpdate<Update>(_ query: _DBQuery, _ update: [String: Update]) -> EventLoopFuture<_DBObject?> {
        
        return self._findOneAndUpdate(query, update).flatMap { sql, primaryKeys, _ in
            
            connection.execute(sql).map { $0.first.map { _DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
        }
    }
    
    func findOneAndUpsert<Update, Data>(_ query: _DBQuery, _ update: [String: Update], _ setOnInsert: [String: Data]) -> EventLoopFuture<_DBObject?> {
        
        guard let update = update as? [String: DBQueryUpdateOperation] else { fatalError() }
        guard let setOnInsert = setOnInsert as? [String: DBDataConvertible] else { fatalError() }
        
        var update_temp: String
        var counter = 0
        repeat {
            update_temp = "temp_\(counter)"
            counter += 1
        } while update_temp == query.class
        
        var insert_temp: String
        repeat {
            insert_temp = "temp_\(counter)"
            counter += 1
        } while insert_temp == update_temp || insert_temp == query.class
        
        return self._findOneAndUpdate(query, update).flatMap { updateSQL, primaryKeys, columnInfos in
            
            do {
                
                guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
                
                let insert = update.compactMapValues { $0.value }.merging(setOnInsert) { _, rhs in rhs }
                var _insert: OrderedDictionary<String, SQLRaw> = [:]
                
                for (key, value) in insert {
                    guard let column_info = columnInfos.first(where: { $0.name == key }) else { throw Database.Error.columnNotExist }
                    _insert[key] = try dialect.typeCast(value.toDBData(), column_info.type)
                }
                
                switch query.returning {
                
                case .before:
                    
                    let sql: SQLRaw = """
                        WITH \(identifier: update_temp) AS (\(updateSQL)),
                        \(identifier: insert_temp) AS (
                            INSERT INTO \(identifier: query.class)(\(_insert.keys.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ",")))
                            SELECT \(_insert.map { "\($1) AS \(identifier: $0)" as SQLRaw }.joined(separator: ","))
                            WHERE NOT EXISTS(SELECT * FROM \(identifier: update_temp))
                        )
                        SELECT * FROM \(identifier: update_temp)
                        """
                    
                    return connection.execute(sql).map { $0.first.map { _DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
                    
                case .after:
                    
                    let includes = query.includes.isEmpty ? Set(columnInfos.map { $0.name }) : query.includes.union(primaryKeys)
                    let _includes: SQLRaw = "\(includes.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ","))"
                    
                    let sql: SQLRaw = """
                        WITH \(identifier: update_temp) AS (\(updateSQL)),
                        \(identifier: insert_temp) AS (
                            INSERT INTO \(identifier: query.class)(\(_insert.keys.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ",")))
                            SELECT \(_insert.map { "\($1) AS \(identifier: $0)" as SQLRaw }.joined(separator: ","))
                            WHERE NOT EXISTS(SELECT * FROM \(identifier: update_temp))
                            RETURNING \(_includes)
                        )
                        SELECT \(_includes) FROM \(identifier: update_temp)
                        UNION
                        SELECT \(_includes) FROM \(identifier: insert_temp)
                        """
                    
                    return connection.execute(sql).map { $0.first.map { _DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
                }
                
            } catch {
                
                return connection.eventLoopGroup.next().makeFailedFuture(error)
            }
        }
    }
    
    func findOneAndDelete(_ query: _DBQuery) -> EventLoopFuture<_DBObject?> {
        
        return connection.primaryKey(of: query.class).flatMap { primaryKeys in
            
            do {
                
                guard let rowId = connection.driver.sqlDialect?.rowId else { throw Database.Error.unsupportedOperation }
                
                var sql: SQLRaw = try """
                    DELETE FROM \(identifier: query.class)
                    WHERE \(identifier: rowId) IN (\(self._findOne(query, primaryKeys, withData: false)))
                    """
                
                if query.includes.isEmpty {
                    sql += "RETURNING *"
                } else {
                    let includes = query.includes.union(primaryKeys)
                    sql += "RETURNING \(includes.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ","))"
                }
                
                return connection.execute(sql).map { $0.first.map { _DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
                
            } catch {
                
                return connection.eventLoopGroup.next().makeFailedFuture(error)
            }
        }
    }
    
    func insert<Data>(_ class: String, _ data: [String: Data]) -> EventLoopFuture<(_DBObject, Bool)?> {
        
        guard let data = data as? [String: DBData] else { fatalError() }
        
        return connection.columns(of: `class`).flatMap { columnInfos in
            
            do {
                
                guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
                
                var columns: [String] = []
                var values: [SQLRaw] = []
                
                for (key, value) in data {
                    guard let column_info = columnInfos.first(where: { $0.name == key }) else { throw Database.Error.columnNotExist }
                    columns.append(key)
                    try values.append(dialect.typeCast(value, column_info.type))
                }
                
                let sql: SQLRaw = """
                    INSERT INTO \(identifier: `class`)
                    (\(columns.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ",")))
                    VALUES (\(values.joined(separator: ",")))
                    RETURNING *
                    """
                
                return connection.primaryKey(of: `class`).flatMap { primaryKeys in
                    connection.execute(sql).map { $0.first.map { (_DBObject(table: `class`, primaryKeys: primaryKeys, object: $0), true) } }
                }
                
            } catch {
                
                return connection.eventLoopGroup.next().makeFailedFuture(error)
            }
        }
    }
}
