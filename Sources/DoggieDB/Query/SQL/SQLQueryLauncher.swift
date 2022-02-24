//
//  SQLQueryLauncher.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2022 Susan Cheng. All rights reserved.
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

extension OrderedDictionary where Key == String, Value == DBSortOrderOption {
    
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

extension Dictionary where Key == String, Value == DBUpdateOption {
    
    fileprivate func serialize(_ table: String, _ columnInfos: [DBSQLColumnInfo], _ dialect: SQLDialect.Type) throws -> [String: SQLRaw] {
        
        var update: [String: SQLRaw] = [:]
        
        for (key, value) in self {
            
            if let column_info = columnInfos.first(where: { $0.name == key }) {
                
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
                
            } else {
                
                switch value {
                case let .set(value):
                    
                    if !value.toDBData().isNil {
                        throw Database.Error.columnNotExist
                    }
                    
                default: throw Database.Error.columnNotExist
                }
            }
        }
        
        return update
    }
}

extension DBObject {
    
    fileprivate init(table: String, primaryKeys: [String], object: SQLQueryRow) {
        var _columns: [String: DBData] = [:]
        for key in object.keys {
            guard let value = object[key] else { continue }
            _columns[key] = value
        }
        self.init(class: table, primaryKeys: Set(primaryKeys), columns: _columns)
    }
}

extension DBSQLConnection {
    
    private func _columns(of table: String) -> EventLoopFuture<[DBSQLColumnInfo]> {
        return self.columnInfoHook?(self, table).hop(to: self.eventLoopGroup.next()) ?? self.columns(of: table)
    }
    
    private func _primaryKey(of table: String) -> EventLoopFuture<[String]> {
        return self.primaryKeyHook?(self, table).hop(to: self.eventLoopGroup.next()) ?? self.primaryKey(of: table)
    }
    
    fileprivate func _columnsAndPrimaryKey(of table: String) -> EventLoopFuture<([DBSQLColumnInfo], [String])> {
        return self._columns(of: table).and(self._primaryKey(of: table))
    }
}

struct SQLQueryLauncher: DBQueryLauncher {
    
    let connection: DBSQLConnection
    
    func count(_ query: DBFindExpression) -> EventLoopFuture<Int> {
        
        do {
            
            guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
            
            return connection._columnsAndPrimaryKey(of: query.class).flatMap { (columnInfos, primaryKeys) in
                
                do {
                    
                    var sql: SQLRaw = "SELECT COUNT(*) FROM \(identifier: query.class)"
                    
                    if !query.filters.isEmpty {
                        
                        let filter = try query.filters.serialize(dialect.self, columnInfos, primaryKeys)
                        
                        switch filter {
                        case .true: break
                        case .false: return connection.eventLoopGroup.next().makeSucceededFuture(0)
                        case let .sql(filter): sql += "WHERE \(filter)"
                        }
                    }
                    
                    return connection.execute(sql).map { $0.first.flatMap { $0[$0.keys[0]]?.intValue } ?? 0 }
                    
                } catch {
                    
                    return connection.eventLoopGroup.next().makeFailedFuture(error)
                }
            }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func _find(_ query: DBFindExpression) -> EventLoopFuture<(SQLRaw?, [String])> {
        
        do {
            
            guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
            
            return connection._columnsAndPrimaryKey(of: query.class).flatMapThrowing { (columnInfos, primaryKeys) in
                
                var sql: SQLRaw
                
                if let includes = query.includes {
                    
                    let _includes = includes.intersection(columnInfos.map { $0.name }).union(primaryKeys)
                    sql = "SELECT \(_includes.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ","))"
                    
                } else {
                    
                    sql = "SELECT *"
                }
                
                sql += "FROM \(identifier: query.class)"
                
                if !query.filters.isEmpty {
                    
                    let filter = try query.filters.serialize(dialect.self, columnInfos, primaryKeys)
                    
                    switch filter {
                    case .true: break
                    case .false: return (nil, primaryKeys)
                    case let .sql(filter): sql += "WHERE \(filter)"
                    }
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
    
    func find(_ query: DBFindExpression) -> EventLoopFuture<[DBObject]> {
        
        return self._find(query).flatMap { sql, primaryKeys in
            
            guard let sql = sql else { return connection.eventLoopGroup.next().makeSucceededFuture([]) }
            
            return connection.execute(sql).map { $0.map { DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
        }
    }
    
    func find(_ query: DBFindExpression, forEach: @escaping (DBObject) throws -> Void) -> EventLoopFuture<Void> {
        
        return self._find(query).flatMap { sql, primaryKeys in
            
            guard let sql = sql else { return connection.eventLoopGroup.next().makeSucceededVoidFuture() }
            
            return connection.execute(sql) {
                
                try forEach(DBObject(table: query.class, primaryKeys: primaryKeys, object: $0))
                
            }.map { _ in }
        }
    }
    
    func findAndDelete(_ query: DBFindExpression) -> EventLoopFuture<Int?> {
        
        do {
            
            guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
            
            return connection._columnsAndPrimaryKey(of: query.class).flatMap { (columnInfos, primaryKeys) in
                
                do {
                    
                    var sql: SQLRaw = "DELETE FROM \(identifier: query.class)"
                    
                    if !query.filters.isEmpty {
                        
                        let filter = try query.filters.serialize(dialect.self, columnInfos, primaryKeys)
                        
                        switch filter {
                        case .true: break
                        case .false: return connection.eventLoopGroup.next().makeSucceededFuture(0)
                        case let .sql(filter): sql += "WHERE \(filter)"
                        }
                    }
                    
                    sql += "RETURNING 0"
                    
                    return connection.execute(sql).map { $0.count }
                    
                } catch {
                    
                    return connection.eventLoopGroup.next().makeFailedFuture(error)
                }
            }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func _findOne(_ query: DBFindOneExpression, _ columnInfos: [DBSQLColumnInfo], _ primaryKeys: [String], withData: Bool) throws -> SQLRaw? {
        
        guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
        guard let rowId = dialect.rowId else { throw Database.Error.unsupportedOperation }
        
        var sql: SQLRaw
        
        if withData {
            sql = "SELECT \(identifier: rowId), * FROM \(identifier: query.class)"
        } else {
            sql = "SELECT \(identifier: rowId) FROM \(identifier: query.class)"
        }
        
        if !query.filters.isEmpty {
            
            let filter = try query.filters.serialize(dialect.self, columnInfos, primaryKeys)
            
            switch filter {
            case .true: break
            case .false: return nil
            case let .sql(filter): sql += "WHERE \(filter)"
            }
        }
        
        if !query.sort.isEmpty {
            sql += "ORDER BY \(query.sort.serialize())"
        }
        
        sql += "LIMIT 1"
        sql += try dialect.updateLock()
        
        return sql
    }
    
    func _findOneAndUpdate(_ query: DBFindOneExpression, _ update: [String: DBUpdateOption]) -> EventLoopFuture<(SQLRaw?, [DBSQLColumnInfo], [String])> {
        
        switch query.returning {
            
        case .before:
            
            var temp: String
            var counter = 0
            repeat {
                counter += 1
                temp = "temp_\(counter)"
            } while temp == query.class
            
            return connection._columnsAndPrimaryKey(of: query.class).flatMapThrowing { (columnInfos, primaryKeys) in
                
                guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
                guard let rowId = dialect.rowId else { throw Database.Error.unsupportedOperation }
                
                guard let _query = try self._findOne(query, columnInfos, primaryKeys, withData: true) else { return (nil, columnInfos, primaryKeys) }
                
                var sql: SQLRaw = try """
                    UPDATE \(identifier: query.class)
                    SET \(update.serialize(query.class, columnInfos, dialect).map { "\(identifier: $0) = \($1)" as SQLRaw }.joined(separator: ","))
                    FROM (\(_query)) AS \(identifier: temp)
                    WHERE \(identifier: query.class).\(identifier: rowId) = \(identifier: temp).\(identifier: rowId)
                    """
                
                let includes = query.includes?.intersection(columnInfos.map { $0.name }).union(primaryKeys) ?? Set(columnInfos.map { $0.name })
                sql += "RETURNING \(includes.map { "\(identifier: temp).\(identifier: $0)" as SQLRaw }.joined(separator: ","))"
                
                return (sql, columnInfos, primaryKeys)
            }
            
        case .after:
            
            return connection._columnsAndPrimaryKey(of: query.class).flatMapThrowing { (columnInfos, primaryKeys) in
                
                guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
                guard let rowId = dialect.rowId else { throw Database.Error.unsupportedOperation }
                
                guard let _query = try self._findOne(query, columnInfos, primaryKeys, withData: false) else { return (nil, columnInfos, primaryKeys) }
                
                var sql: SQLRaw = try """
                    UPDATE \(identifier: query.class)
                    SET \(update.serialize(query.class, columnInfos, dialect).map { "\(identifier: $0) = \($1)" as SQLRaw }.joined(separator: ","))
                    WHERE \(identifier: rowId) IN (\(_query))
                    """
                
                if let includes = query.includes {
                    let _includes = includes.intersection(columnInfos.map { $0.name }).union(primaryKeys)
                    sql += "RETURNING \(_includes.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ","))"
                } else {
                    sql += "RETURNING *"
                }
                
                return (sql, columnInfos, primaryKeys)
            }
        }
    }
    
    func findOneAndUpdate(_ query: DBFindOneExpression, _ update: [String: DBUpdateOption]) -> EventLoopFuture<DBObject?> {
        
        return self._findOneAndUpdate(query, update).flatMap { sql, _, primaryKeys in
            
            guard let sql = sql else { return connection.eventLoopGroup.next().makeSucceededFuture(nil) }
            
            return connection.execute(sql).map { $0.first.map { DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
        }
    }
    
    func findOneAndUpsert(_ query: DBFindOneExpression, _ update: [String : DBUpdateOption], _ setOnInsert: [String : DBDataConvertible]) -> EventLoopFuture<DBObject?> {
        
        var update_temp: String
        var counter = 0
        repeat {
            counter += 1
            update_temp = "temp_\(counter)"
        } while update_temp == query.class
        
        var duplicate_check_temp: String
        repeat {
            counter += 1
            duplicate_check_temp = "temp_\(counter)"
        } while duplicate_check_temp == query.class
        
        var insert_temp: String
        repeat {
            counter += 1
            insert_temp = "temp_\(counter)"
        } while insert_temp == query.class
        
        return self._findOneAndUpdate(query, update).flatMap { updateSQL, columnInfos, primaryKeys in
            
            do {
                
                guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
                
                let insert = update.compactMapValues { $0.value }.merging(setOnInsert) { _, rhs in rhs }
                
                guard let updateSQL = updateSQL else {
                    switch query.returning {
                    case .before: return self._insert(query.class, columnInfos, primaryKeys, insert.mapValues { $0.toDBData() }).map { _ in nil }
                    case .after: return self._insert(query.class, columnInfos, primaryKeys, insert.mapValues { $0.toDBData() })
                    }
                }
                
                var _insert: OrderedDictionary<String, SQLRaw> = [:]
                var _primaryKeys: [String: DBData] = [:]
                
                for (key, value) in insert {
                    
                    let value = value.toDBData()
                    
                    if primaryKeys.contains(key) {
                        _primaryKeys[key] = value
                    }
                    
                    if let column_info = columnInfos.first(where: { $0.name == key }) {
                        
                        _insert[key] = try dialect.typeCast(value, column_info.type)
                        
                    } else if !value.isNil {
                        
                        throw Database.Error.columnNotExist
                    }
                }
                
                let _primaryKeysFilter: DBPredicateExpression = .equal(.objectId, .value(primaryKeys.count == 1 ? _primaryKeys[primaryKeys[0]] : _primaryKeys))
                
                var is_duplicated: String
                repeat {
                    counter += 1
                    is_duplicated = "is_duplicated_\(counter)"
                } while columnInfos.contains(where: { $0.name == is_duplicated })
                
                let includes = query.includes?.intersection(columnInfos.map { $0.name }).union(primaryKeys) ?? Set(columnInfos.map { $0.name })
                let _includes: SQLRaw = "\(includes.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ","))"
                
                switch query.returning {
                    
                case .before:
                    
                    let sql: SQLRaw = try """
                        WITH \(identifier: update_temp) AS (\(updateSQL)),
                        \(identifier: duplicate_check_temp) AS (
                            SELECT \(_includes) FROM \(identifier: query.class)
                            WHERE \(_primaryKeysFilter.serialize(dialect.self, columnInfos, primaryKeys)._sql())
                            AND NOT EXISTS(SELECT * FROM \(identifier: update_temp))
                        ),
                        \(identifier: insert_temp) AS (
                            INSERT INTO \(identifier: query.class)(\(_insert.keys.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ",")))
                            SELECT \(_insert.map { "\($1) AS \(identifier: $0)" as SQLRaw }.joined(separator: ","))
                            WHERE NOT EXISTS(SELECT * FROM \(identifier: update_temp))
                        )
                        SELECT \(_includes), \(nil) AS \(identifier: is_duplicated) FROM \(identifier: update_temp)
                        UNION
                        SELECT \(_includes), \(true) AS \(identifier: is_duplicated) FROM \(identifier: duplicate_check_temp)
                        """
                    
                    return connection.execute(sql)
                        .map { $0.first.map { DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
                        .flatMapThrowing { obj in
                            guard obj?[is_duplicated] != true else { throw Database.Error.duplicatedPrimaryKey }
                            return obj
                        }
                    
                case .after:
                    
                    let sql: SQLRaw = try """
                        WITH \(identifier: update_temp) AS (\(updateSQL)),
                        \(identifier: duplicate_check_temp) AS (
                            SELECT \(_includes) FROM \(identifier: query.class)
                            WHERE \(_primaryKeysFilter.serialize(dialect.self, columnInfos, primaryKeys)._sql())
                            AND NOT EXISTS(SELECT * FROM \(identifier: update_temp))
                        ),
                        \(identifier: insert_temp) AS (
                            INSERT INTO \(identifier: query.class)(\(_insert.keys.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ",")))
                            SELECT \(_insert.map { "\($1) AS \(identifier: $0)" as SQLRaw }.joined(separator: ","))
                            WHERE NOT EXISTS(SELECT * FROM \(identifier: update_temp))
                            AND NOT EXISTS(SELECT * FROM \(identifier: duplicate_check_temp))
                            RETURNING \(_includes)
                        )
                        SELECT \(_includes), \(nil) AS \(identifier: is_duplicated) FROM \(identifier: update_temp)
                        UNION
                        SELECT \(_includes), \(true) AS \(identifier: is_duplicated) FROM \(identifier: duplicate_check_temp)
                        UNION
                        SELECT \(_includes), \(nil) AS \(identifier: is_duplicated) FROM \(identifier: insert_temp)
                        """
                    
                    return connection.execute(sql)
                        .map { $0.first.map { DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
                        .flatMapThrowing { obj in
                            guard obj?[is_duplicated] != true else { throw Database.Error.duplicatedPrimaryKey }
                            return obj
                        }
                }
                
            } catch {
                
                return connection.eventLoopGroup.next().makeFailedFuture(error)
            }
        }
    }
    
    func findOneAndDelete(_ query: DBFindOneExpression) -> EventLoopFuture<DBObject?> {
        
        do {
            
            guard let rowId = connection.driver.sqlDialect?.rowId else { throw Database.Error.unsupportedOperation }
            
            return connection._columnsAndPrimaryKey(of: query.class).flatMap { (columnInfos, primaryKeys) in
                
                do {
                    
                    guard let _query = try self._findOne(query, columnInfos, primaryKeys, withData: false) else {
                        return connection.eventLoopGroup.next().makeSucceededFuture(nil)
                    }
                    
                    if let includes = query.includes {
                        
                        var sql: SQLRaw = """
                            DELETE FROM \(identifier: query.class)
                            WHERE \(identifier: rowId) IN (\(_query))
                            """
                        
                        let _includes = includes.intersection(columnInfos.map { $0.name }).union(primaryKeys)
                        sql += "RETURNING \(_includes.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ","))"
                        
                        return connection.execute(sql).map { $0.first.map { DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
                        
                    } else {
                        
                        let sql: SQLRaw = """
                            DELETE FROM \(identifier: query.class)
                            WHERE \(identifier: rowId) IN (\(_query))
                            RETURNING *
                            """
                        
                        return connection.execute(sql).map { $0.first.map { DBObject(table: query.class, primaryKeys: primaryKeys, object: $0) } }
                    }
                    
                } catch {
                    
                    return connection.eventLoopGroup.next().makeFailedFuture(error)
                }
            }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    private func _insert(_ class: String, _ columnInfos: [DBSQLColumnInfo], _ primaryKeys: [String], _ data: [String: DBData]) -> EventLoopFuture<DBObject?> {
        
        do {
            
            guard let dialect = connection.driver.sqlDialect else { throw Database.Error.unsupportedOperation }
            
            var duplicate_check_temp: String
            var counter = 0
            repeat {
                counter += 1
                duplicate_check_temp = "temp_\(counter)"
            } while duplicate_check_temp == `class`
            
            var insert_temp: String
            repeat {
                counter += 1
                insert_temp = "temp_\(counter)"
            } while insert_temp == `class`
            
            var columns: [String] = []
            var values: [SQLRaw] = []
            
            var _primaryKeys: [String: DBData] = [:]
            
            for (key, value) in data {
                
                if primaryKeys.contains(key) {
                    _primaryKeys[key] = value
                }
                
                if let column_info = columnInfos.first(where: { $0.name == key }) {
                    
                    columns.append(key)
                    try values.append(dialect.typeCast(value, column_info.type))
                    
                } else if !value.isNil {
                    
                    throw Database.Error.columnNotExist
                }
            }
            
            let _primaryKeysFilter: DBPredicateExpression = .equal(.objectId, .value(primaryKeys.count == 1 ? _primaryKeys[primaryKeys[0]] : _primaryKeys))
            
            var is_duplicated: String
            repeat {
                counter += 1
                is_duplicated = "is_duplicated_\(counter)"
            } while columnInfos.contains(where: { $0.name == is_duplicated })
            
            let _includes: SQLRaw = "\(columnInfos.map { "\(identifier: $0.name)" as SQLRaw }.joined(separator: ","))"
            
            let sql: SQLRaw = try """
                    WITH \(identifier: duplicate_check_temp) AS (
                        SELECT \(_includes) FROM \(identifier: `class`)
                        WHERE \(_primaryKeysFilter.serialize(dialect.self, columnInfos, primaryKeys)._sql())
                    ),
                    \(identifier: insert_temp) AS (
                        INSERT INTO \(identifier: `class`)
                        (\(columns.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ",")))
                        SELECT \(zip(columns, values).map { "\($1) AS \(identifier: $0)" as SQLRaw }.joined(separator: ","))
                        WHERE NOT EXISTS(SELECT * FROM \(identifier: duplicate_check_temp))
                        RETURNING \(_includes)
                    )
                    SELECT \(_includes), \(true) AS \(identifier: is_duplicated) FROM \(identifier: duplicate_check_temp)
                    UNION
                    SELECT \(_includes), \(nil) AS \(identifier: is_duplicated) FROM \(identifier: insert_temp)
                    """
            
            return connection.execute(sql)
                .map { $0.first.map { DBObject(table: `class`, primaryKeys: primaryKeys, object: $0) } }
                .flatMapThrowing { obj in
                    guard obj?[is_duplicated] != true else { throw Database.Error.duplicatedPrimaryKey }
                    return obj
                }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func insert<Data>(_ class: String, _ data: [String: Data]) -> EventLoopFuture<DBObject?> {
        
        guard let data = data as? [String: DBData] else { fatalError() }
        
        return connection._columnsAndPrimaryKey(of: `class`).flatMap { (columnInfos, primaryKeys) in
            
            self._insert(`class`, columnInfos, primaryKeys, data)
        }
    }
}
