//
//  SQLBuilder.swift
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

public protocol SQLBuilderProtocol {
    
    var builder: SQLBuilder { get set }
    
    func execute() -> EventLoopFuture<[DBQueryRow]>
    
    func execute(onRow: @escaping (DBQueryRow) -> Void) -> EventLoopFuture<DBQueryMetadata>
    
    func execute(onRow: @escaping (DBQueryRow) throws -> Void) -> EventLoopFuture<DBQueryMetadata>
}

extension SQLBuilderProtocol {
    
    public func execute() -> EventLoopFuture<[DBQueryRow]> {
        return builder.execute()
    }
    
    public func execute(onRow: @escaping (DBQueryRow) -> Void) -> EventLoopFuture<DBQueryMetadata> {
        return builder.execute(onRow: onRow)
    }
    
    public func execute(onRow: @escaping (DBQueryRow) throws -> Void) -> EventLoopFuture<DBQueryMetadata> {
        return builder.execute(onRow: onRow)
    }
}

enum SQLBuilderComponent {
    
    case raw(SQLRaw)
    
    case string(String)
    
    case value(DBData)
    
    case autoIncrement
    
    case nullSafeEqual(SQLPredicateValue, SQLPredicateValue)
    
    case nullSafeNotEqual(SQLPredicateValue, SQLPredicateValue)
}

public struct SQLBuilder {
    
    let connection: DBConnection?
    
    let dialect: SQLDialect.Type?
    
    var components: [SQLBuilderComponent] = []
    
    init() {
        self.connection = nil
        self.dialect = nil
    }
    
    init(connection: DBConnection) {
        self.connection = connection
        self.dialect = connection.dialect
    }
}

extension DBConnection where Self: DBSQLConnection {
    
    public func sqlQuery() -> SQLBuilder {
        return SQLBuilder(connection: self)
    }
}

extension SQLRawComponent {
    
    var string: String? {
        switch self {
        case let .string(string): return string
        default: return nil
        }
    }
}

extension SQLBuilder: SQLBuilderProtocol {
    
    public var builder: SQLBuilder {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
    
    var raw: SQLRaw? {
        
        guard let dialect = self.dialect else { return nil }
        
        var raw = SQLRaw()
        
        for component in components {
            
            if !raw.isEmpty && raw.components.last?.string?.last != " " {
                raw.appendLiteral(" ")
            }
            
            switch component {
            case let .raw(value): raw.append(value)
            case let .string(value): raw.appendLiteral(value)
            case let .value(value): raw.append(value)
            case .autoIncrement: raw.appendLiteral(dialect.autoIncrementClause)
            case let .nullSafeEqual(lhs, rhs): raw.append(dialect.nullSafeEqual(lhs, rhs))
            case let .nullSafeNotEqual(lhs, rhs): raw.append(dialect.nullSafeNotEqual(lhs, rhs))
            }
        }
        
        return raw
    }
    
    public func execute() -> EventLoopFuture<[DBQueryRow]> {
        
        guard let connection = self.connection else { fatalError() }
        
        guard let raw = self.raw else {
            return connection.eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
        }
        
        return connection.execute(raw)
    }
    
    public func execute(onRow: @escaping (DBQueryRow) -> Void) -> EventLoopFuture<DBQueryMetadata> {
        
        guard let connection = self.connection else { fatalError() }
        
        guard let raw = self.raw else {
            return connection.eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
        }
        
        return connection.execute(raw, onRow: onRow)
    }
    
    public func execute(onRow: @escaping (DBQueryRow) throws -> Void) -> EventLoopFuture<DBQueryMetadata> {
        
        guard let connection = self.connection else { fatalError() }
        
        guard let raw = self.raw else {
            return connection.eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
        }
        
        return connection.execute(raw, onRow: onRow)
    }
}

extension SQLBuilder {
    
    mutating func append(_ other: SQLBuilder) {
        self.components.append(contentsOf: other.components)
    }
    
    mutating func append(_ raw: SQLRaw) {
        self.components.append(.raw(raw))
    }
    
    mutating func append(_ value: SQLBuilderComponent) {
        self.components.append(value)
    }
    
    mutating func append<T: StringProtocol>(_ value: T) {
        self.components.append(.string(String(value)))
    }
    
    mutating func append(_ value: DBData) {
        self.components.append(.value(value))
    }
}

extension SQLBuilder: SQLWithModifyingExpression { }
extension SQLBuilder: SQLValuesExpression { }
extension SQLBuilder: SQLSelectExpression { }

extension SQLBuilder {
    
    /// Creates a new `SQLDeleteBuilder`.
    public func delete(_ table: String, as alias: String? = nil) -> SQLDeleteBuilder {
        return SQLDeleteBuilder(builder: self, table: table, alias: alias)
    }
    
    /// Creates a new `SQLUpdateBuilder`.
    public func update(_ table: String, as alias: String? = nil) -> SQLUpdateBuilder {
        return SQLUpdateBuilder(builder: self, table: table, alias: alias)
    }
    
    /// Creates a new `SQLInsertBuilder`.
    public func insert(_ table: String, as alias: String? = nil) -> SQLInsertBuilder {
        return SQLInsertBuilder(builder: self, table: table, alias: alias)
    }
}

extension SQLBuilder {
    
    public struct SQLDropTableOptions: OptionSet {
        
        public var rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let ifExists = SQLDropTableOptions(rawValue: 1 << 0)
    }
    
    public struct SQLDropIndexOptions: OptionSet {
        
        public var rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let ifExists = SQLDropIndexOptions(rawValue: 1 << 0)
    }
    
    public struct SQLDropViewOptions: OptionSet {
        
        public var rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let ifExists = SQLDropViewOptions(rawValue: 1 << 0)
    }
    
    public struct SQLRefreshViewOptions: OptionSet {
        
        public var rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let concurrent = SQLRefreshViewOptions(rawValue: 1 << 0)
    }
}

extension SQLBuilder {
    
    /// Creates a new `SQLCreateTableBuilder`.
    public func createTable(_ table: String, options: SQLCreateTableOptions = []) -> SQLCreateTableBuilder {
        return SQLCreateTableBuilder(builder: self, table: table, options: options)
    }
    
    /// Creates a new `SQLCreateTableBuilder`.
    public func createTable(_ table: String, options: SQLCreateTableOptions = []) -> SQLCreateTableAsBuilder {
        return SQLCreateTableAsBuilder(builder: self, table: table, options: options)
    }
    
    /// Creates a new `SQLAlterTableBuilder`.
    public func alterTable(_ table: String, options: SQLAlterTableOptions = []) -> SQLAlterTableBuilder {
        return SQLAlterTableBuilder(builder: self, table: table, options: options)
    }
    
    public func dropTable(_ table: String, options: SQLDropTableOptions = []) -> SQLFinalizedBuilder {
        
        var builder = self
        
        builder.append("DROP TABLE")
        if options.contains(.ifExists) {
            builder.append("IF EXISTS")
        }
        builder.append("\(identifier: table)" as SQLRaw)
        
        return SQLFinalizedBuilder(builder: builder)
    }
}

extension SQLBuilder {
    
    /// Creates a new `SQLCreateIndexBuilder`.
    public func createIndex(on table: String, options: SQLCreateIndexOptions = []) -> SQLCreateIndexBuilder {
        return SQLCreateIndexBuilder(builder: self, index: nil, table: table, options: options)
    }
    
    /// Creates a new `SQLCreateIndexBuilder`.
    public func createIndex(_ index: String, on table: String, options: SQLCreateIndexOptions = []) -> SQLCreateIndexBuilder {
        return SQLCreateIndexBuilder(builder: self, index: index, table: table, options: options)
    }
    
    public func dropIndex(_ index: String, options: SQLDropIndexOptions = []) -> SQLFinalizedBuilder {
        
        var builder = self
        
        builder.append("DROP INDEX")
        if options.contains(.ifExists) {
            builder.append("IF EXISTS")
        }
        builder.append("\(identifier: index)" as SQLRaw)
        
        return SQLFinalizedBuilder(builder: builder)
    }
}

extension SQLBuilder {
    
    /// Creates a new `SQLCreateViewBuilder`.
    public func createView(_ view: String, options: SQLCreateViewOptions = []) -> SQLCreateViewBuilder {
        return SQLCreateViewBuilder(builder: self, view: view, options: options)
    }
    
    public func dropView(_ view: String, options: SQLDropViewOptions = []) -> SQLFinalizedBuilder {
        
        var builder = self
        
        builder.append("DROP VIEW")
        if options.contains(.ifExists) {
            builder.append("IF EXISTS")
        }
        builder.append("\(identifier: view)" as SQLRaw)
        
        return SQLFinalizedBuilder(builder: builder)
    }
}

extension SQLBuilder {
    
    /// Creates a new `SQLCreateMaterializedViewBuilder`.
    public func createMaterializedView(_ view: String, options: SQLCreateMaterializedViewOptions = []) -> SQLCreateMaterializedViewBuilder {
        return SQLCreateMaterializedViewBuilder(builder: self, view: view, options: options)
    }
    
    public func dropMaterializedView(_ view: String, options: SQLDropViewOptions = []) -> SQLFinalizedBuilder {
        
        var builder = self
        
        builder.append("DROP MATERIALIZED VIEW")
        if options.contains(.ifExists) {
            builder.append("IF EXISTS")
        }
        builder.append("\(identifier: view)" as SQLRaw)
        
        return SQLFinalizedBuilder(builder: builder)
    }
    
    public func refreshMaterializedView(_ view: String, options: SQLRefreshViewOptions = []) -> SQLFinalizedBuilder {
        
        var builder = self
        
        builder.append("REFRESH MATERIALIZED VIEW")
        if options.contains(.concurrent) {
            builder.append("CONCURRENTLY")
        }
        builder.append("\(identifier: view)" as SQLRaw)
        
        return SQLFinalizedBuilder(builder: builder)
    }
}

extension SQLBuilder {
    
    public func beginTransaction() -> SQLFinalizedBuilder {
        
        var builder = self
        
        builder.append("BEGIN")
        
        return SQLFinalizedBuilder(builder: builder)
    }
    
    public func commit() -> SQLFinalizedBuilder {
        
        var builder = self
        
        builder.append("COMMIT")
        
        return SQLFinalizedBuilder(builder: builder)
    }
    
    public func rollback() -> SQLFinalizedBuilder {
        
        var builder = self
        
        builder.append("ROLLBACK")
        
        return SQLFinalizedBuilder(builder: builder)
    }
}
