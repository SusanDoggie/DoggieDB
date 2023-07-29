//
//  PostgreSQL.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2023 Susan Cheng. All rights reserved.
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

import NIOConcurrencyHelpers
import PostgresNIO

struct PostgreSQLDriver: DBDriverProtocol {
    
    static var defaultPort: Int { 5432 }
    
    static var sqlDialect: SQLDialect.Type? {
        return PostgreSQLDialect.self
    }
}

extension PostgreSQLDriver {
    
    final class Connection: DBSQLConnection {
        
        var driver: DBDriver { return .postgreSQL }
        
        let connection: PostgresConnection
        
        var eventLoopGroup: EventLoopGroup { connection.eventLoop }
        
        let subscribers: Subscribers = Subscribers()
        
        let _runloop = SerialRunLoop()
        
        let hooks: DBSQLConnectionHooks = DBSQLConnectionHooks()
        
        init(_ connection: PostgresConnection) {
            self.connection = connection
        }
        
        func close() async throws {
            await subscribers.removeAll()
            try await connection.close()
        }
    }
}

extension PostgresConnection.Configuration.TLS {
    
    init(_ config: TLSConfiguration) throws {
        self = try config.certificateVerification == .none ? .prefer(.init(configuration: config)) : .require(.init(configuration: config))
    }
}

extension PostgreSQLDriver {
    
    private static let idGenerator = ManagedAtomic(0)
    
    static func connect(
        config: Database.Configuration,
        logger: Logger,
        on eventLoopGroup: EventLoopGroup
    ) async throws -> DBConnection {
        
        guard let user = config.user else {
            throw Database.Error.invalidConfiguration(message: "user is missing.")
        }
        
        guard let address = config.socketAddress.first,
              let host = address.host,
              let port = address.port else { throw Database.Error.invalidConfiguration(message: "unknown host.") }
        
        let _config = try PostgresConnection.Configuration(
            connection: .init(host: host, port: port),
            authentication: .init(
                username: user,
                database: config.database,
                password: config.password
            ),
            tls: config.tlsConfiguration.map { try .init($0) } ?? .disable
        )
        
        let connection = try await PostgresConnection.connect(
            on: eventLoopGroup.next(),
            configuration: _config,
            id: idGenerator.loadThenWrappingIncrement(by: 1, ordering: .relaxed),
            logger: logger
        )
        
        return Connection(connection)
    }
}

extension PostgreSQLDriver.Connection {
    
    var logger: Logger {
        return self.connection.logger
    }
}

extension PostgreSQLDriver.Connection {
    
    func version() async throws -> String {
        return try await self.execute("SELECT version()")[0]["version"]!.string!
    }
    
    func databases() async throws -> [String] {
        return try await self.execute("SELECT dbname FROM pg_catalog.pg_database").compactMap { $0["dbname"]!.string! }
    }
    
    func tables() async throws -> [String] {
        return try await self.execute("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema'").map { $0["tablename"]!.string! }
    }
    
    func views() async throws -> [String] {
        return try await self.execute("SELECT viewname FROM pg_catalog.pg_views WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema'").map { $0["viewname"]!.string! }
    }
    
    func materializedViews() async throws -> [String] {
        return try await self.execute("SELECT matviewname FROM pg_catalog.pg_matviews WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema'").map { $0["matviewname"]!.string! }
    }
    
    func columns(of table: String) async throws -> [DBSQLColumnInfo] {
        
        let table = table.lowercased()
        
        var sql: SQLRaw = """
            SELECT
                a.attname AS column_name,
                format_type(a.atttypid, a.atttypmod) AS data_type,
                a.attnum ,
                a.attnotnull
            FROM
                pg_namespace n,
                pg_class t,
                pg_attribute a
            WHERE
                a.attnum > 0
                AND n.oid = t.relnamespace
                AND a.attrelid = t.oid
                AND NOT a.attisdropped
            """
        
        if let split = table.firstIndex(of: ".") {
            
            let _schema = table.prefix(upTo: split)
            let _name = table.suffix(from: split).dropFirst()
            
            sql.append(" AND n.nspname = \(_schema) AND t.relname = \(_name)")
            
        } else {
            
            sql.append(" AND t.relname = \(table)")
        }
        
        return try await self.execute(sql).map {
            DBSQLColumnInfo(
                name: $0["column_name"]?.string ?? "",
                type: $0["data_type"]?.string ?? "",
                isOptional: $0["attnotnull"]?.boolValue == false
            )
        }
    }
    
    func primaryKey(of table: String) async throws -> [String] {
        
        let table = table.lowercased()
        
        var sql: SQLRaw = """
            SELECT
                a.attname AS column_name,
                k.indseq AS seq
            FROM
                pg_class t,
                pg_index ix,
                UNNEST(ix.indkey) WITH ORDINALITY k(attnum, indseq),
                pg_attribute a
            WHERE
                t.oid = ix.indrelid
                AND ix.indisprimary
                AND a.attrelid = t.oid
                AND a.attnum = k.attnum
                AND t.relkind = 'r'
            """
        
        if let split = table.firstIndex(of: ".") {
            
            let _schema = table.prefix(upTo: split)
            let _name = table.suffix(from: split).dropFirst()
            
            sql.append(" AND n.nspname = \(_schema) AND t.relname = \(_name)")
            
        } else {
            
            sql.append(" AND t.relname = \(table)")
        }
        
        return try await self.execute(sql).sorted { $0["seq"]?.intValue ?? .max }.compactMap { $0["column_name"]?.string }
    }
    
    func indices(of table: String) async throws -> [[String: DBData]] {
        
        let table = table.lowercased()
        
        var sql: SQLRaw = """
            SELECT
                n.nspname AS schema_name,
                t.relname AS table_name,
                i.relname AS index_name,
                ix.indisprimary AS is_primary,
                ix.indisunique AS is_unique,
                a.attname AS column_name,
                k.indseq AS seq
            FROM
                pg_namespace n,
                pg_class t,
                pg_class i,
                pg_index ix,
                UNNEST(ix.indkey) WITH ORDINALITY k(attnum, indseq),
                pg_attribute a
            WHERE
                t.oid = ix.indrelid
                AND n.oid = t.relnamespace
                AND i.oid = ix.indexrelid
                AND a.attrelid = t.oid
                AND a.attnum = k.attnum
                AND t.relkind = 'r'
            """
        
        if let split = table.firstIndex(of: ".") {
            
            let _schema = table.prefix(upTo: split)
            let _name = table.suffix(from: split).dropFirst()
            
            sql.append(" AND n.nspname = \(_schema) AND t.relname = \(_name)")
            
        } else {
            
            sql.append(" AND t.relname = \(table)")
        }
        
        return try await self.execute(sql)
    }
    
    func foreignKeys(of table: String) async throws -> [[String: DBData]] {
        
        let table = table.lowercased()
        
        var sql: SQLRaw = """
            SELECT kcu.table_schema AS table_schema,
                kcu.table_name AS table_name,
                rel_kcu.table_schema AS ref_table_schema,
                rel_kcu.table_name AS ref_table_name,
                kcu.ordinal_position AS seq,
                kcu.position_in_unique_constraint AS ref_seq,
                kcu.column_name AS column,
                rel_kcu.column_name AS ref_column,
                kcu.constraint_name AS constraint_name
            FROM information_schema.table_constraints tco
            JOIN information_schema.key_column_usage kcu
                ON tco.constraint_schema = kcu.constraint_schema
                AND tco.constraint_name = kcu.constraint_name
            JOIN information_schema.referential_constraints rco
                ON tco.constraint_schema = rco.constraint_schema
                AND tco.constraint_name = rco.constraint_name
            JOIN information_schema.key_column_usage rel_kcu
                ON rco.unique_constraint_schema = rel_kcu.constraint_schema
                AND rco.unique_constraint_name = rel_kcu.constraint_name
                AND kcu.ordinal_position = rel_kcu.ordinal_position
            WHERE tco.constraint_type = 'FOREIGN KEY'
            """
        
        if let split = table.firstIndex(of: ".") {
            
            let _schema = table.prefix(upTo: split)
            let _name = table.suffix(from: split).dropFirst()
            
            sql.append(" AND kcu.table_schema = \(_schema) AND kcu.table_name = \(_name)")
            
        } else {
            
            sql.append(" AND kcu.table_name = \(table)")
        }
        
        return try await self.execute(sql)
    }
}

extension PostgreSQLDriver.Connection {
    
    func size(of table: String) async throws -> DBSQLTableStats {
        
        let sql: SQLRaw = """
            SELECT pg_table_size(\(table)) AS table,
                pg_indexes_size(\(table)) AS indexes,
                pg_total_relation_size(\(table)) AS total
            """
        
        guard let result = try await self.execute(sql).first else { throw Database.Error.unknown }
        
        guard let table = result["table"]?.intValue else { throw Database.Error.unknown }
        guard let indexes = result["indexes"]?.intValue else { throw Database.Error.unknown }
        guard let total = result["total"]?.intValue else { throw Database.Error.unknown }
        
        return DBSQLTableStats(table: table, indexes: indexes, total: total)
    }
}

extension PostgreSQLDriver.Connection {
    
    func startTransaction(_ mode: DBTransactionOptions.Mode) async throws {
        switch mode {
        case .default: try await self.execute("BEGIN")
        case .committed: try await self.execute("BEGIN ISOLATION LEVEL READ COMMITTED")
        case .repeatable: try await self.execute("BEGIN ISOLATION LEVEL REPEATABLE READ")
        case .serializable: try await self.execute("BEGIN ISOLATION LEVEL SERIALIZABLE")
        }
    }
    
    func commitTransaction() async throws {
        try await self.execute("COMMIT")
    }
    
    func abortTransaction() async throws {
        try await self.execute("ROLLBACK")
    }
    
    func createSavepoint(_ name: String) async throws {
        try await self.execute("SAVEPOINT \(identifier: name)")
    }
    
    func rollbackToSavepoint(_ name: String) async throws {
        try await self.execute("ROLLBACK TO SAVEPOINT \(identifier: name)")
    }
    
    func releaseSavepoint(_ name: String) async throws {
        try await self.execute("RELEASE SAVEPOINT \(identifier: name)")
    }
    
}

extension PostgreSQLDriver.Connection {
    
    @discardableResult
    func execute(
        _ sql: SQLRaw
    ) async throws -> [[String: DBData]] {
        
        guard let (raw, binds) = self.serialize(sql) else {
            throw Database.Error.unsupportedOperation
        }
        
        do {
            
            if binds.isEmpty {
                return try await self.connection.simpleQuery(raw).get().map(Dictionary.init)
            }
            
            let _binds = try binds.map(PostgresData.init)
            return try await self.connection.query(raw, _binds).get().rows.map(Dictionary.init)
            
        } catch {
            
            self.logger.debug("SQL execution error: \(error)\n\(sql)")
            
            throw error
        }
    }
    
    @discardableResult
    func execute(
        _ sql: SQLRaw,
        onRow: @escaping ([String: DBData]) throws -> Void
    ) async throws -> SQLQueryMetadata {
        
        guard let (raw, binds) = self.serialize(sql) else {
            throw Database.Error.unsupportedOperation
        }
        
        do {
            
            var metadata: PostgresQueryMetadata?
            let _binds = try binds.map(PostgresData.init)
            
            try await self.connection.query(raw, _binds, onMetadata: { metadata = $0 }, onRow: { try onRow(Dictionary($0)) }).get()
            
            return metadata.map(SQLQueryMetadata.init) ?? SQLQueryMetadata()
            
        } catch {
            
            self.logger.debug("SQL execution error: \(error)\n\(sql)")
            
            throw error
        }
    }
}

extension PostgreSQLDriver.Connection {
    
    private func _withTransaction<T>(
        _ options: DBTransactionOptions,
        @UnsafeSendable _ transactionBody: @escaping (DBConnection) async throws -> T
    ) async throws -> T {
        
        guard !_runloop.inRunloop else { throw Database.Error.transactionDeadlocks }
        
        let wrapped: UnsafeSendable<T> = try await _runloop.perform {
            
            try await self.startTransaction(options.mode)
            
            do {
                
                let result = try await $transactionBody.wrappedValue(DBSQLTransactionConnection(base: self, counter: 0))
                
                try await self.commitTransaction()
                
                return UnsafeSendable(wrappedValue: result)
                
            } catch {
                
                try await self.abortTransaction()
                
                throw error
            }
        }
        
        return wrapped.wrappedValue
    }
    
    public func withTransaction<T>(
        _ options: DBTransactionOptions,
        @UnsafeSendable _ transactionBody: @escaping (DBConnection) async throws -> T
    ) async throws -> T {
        
        guard options.retryOnConflict else { return try await self._withTransaction(options, transactionBody) }
        
        do {
            
            return try await self._withTransaction(options, transactionBody)
            
        } catch let error as PostgresError {
            
            if error.code == .serializationFailure || error.code == .deadlockDetected {
                return try await self.withTransaction(options, transactionBody)
            }
            
            throw error
        }
    }
}

extension Dictionary where Key == String, Value == DBData {
    
    init(_ row: PostgresRow) {
        self.init(row.makeRandomAccess())
    }
    
    init(_ row: PostgresRandomAccessRow) {
        self.init(minimumCapacity: row.count)
        for (idx, column) in row.indexed() {
            self[column.columnName] = try? DBData(row[data: idx])
        }
    }
}

extension SQLQueryMetadata {
    
    init(_ metadata: PostgresQueryMetadata) {
        self.init([
            "command": DBData(metadata.command),
            "oid": metadata.oid.map(DBData.init) ?? nil,
            "rows": metadata.rows.map(DBData.init) ?? nil,
        ])
    }
}
