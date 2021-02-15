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
    
}

extension SQLBuilderProtocol {
    
    public typealias BuilderClosure<T> = (T) -> T
    
    var dialect: SQLDialect.Type? {
        return builder.dialect
    }
    
    public func execute() -> EventLoopFuture<[DBQueryRow]> {
        return builder.execute()
    }
    
    public func execute(onRow: @escaping (DBQueryRow) -> Void) -> EventLoopFuture<DBQueryMetadata> {
        return builder.execute(onRow: onRow)
    }
}

enum SQLBuilderComponent {
    case raw(SQLRaw)
    case string(String)
    case literal(SQLLiteral)
    case value(DBData)
}

public struct SQLBuilder {
    
    public typealias BuilderClosure<T> = (T) -> T
    
    let connection: DBConnection?
    
    let dialect: SQLDialect.Type?
    
    private var components: [SQLBuilderComponent] = []
    
    init() {
        self.connection = nil
        self.dialect = nil
    }
    
    init(connection: DBConnection) {
        self.connection = connection
        self.dialect = connection.dialect
    }
}

extension DBConnection {
    
    public func sql() -> SQLBuilder {
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

extension SQLBuilder {
    
    var raw: SQLRaw? {
        
        guard let dialect = self.dialect else { return nil }
        
        var raw = SQLRaw()
        
        for component in components {
            
            if !raw.isEmpty && raw.components.last?.string?.last != " " {
                raw.append(" ")
            }
            
            switch component {
            case let .raw(value): raw.append(value)
            case let .string(value): raw.append(value)
            case let .literal(value): raw.append(value, dialect)
            case let .value(value): raw.append(value)
            }
        }
        
        return raw
    }
    
    func execute() -> EventLoopFuture<[DBQueryRow]> {
        
        guard let connection = self.connection else { fatalError() }
        
        guard let raw = self.raw else {
            return connection.eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
        }
        
        return connection.execute(raw)
    }
    
    func execute(onRow: @escaping (DBQueryRow) -> Void) -> EventLoopFuture<DBQueryMetadata> {
        
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
    
    mutating func append(_ literal: SQLLiteral) {
        self.components.append(.literal(literal))
    }
    
    mutating func append<T: StringProtocol>(_ value: T) {
        self.components.append(.string(String(value)))
    }
    
    mutating func append(_ value: DBData) {
        self.components.append(.value(value))
    }
}

extension SQLBuilder {
    
    public func select() -> SQLSelectBuilder {
        return SQLSelectBuilder(builder: self)
    }
    
    public func delete(_ table: String, alias: String? = nil) -> SQLDeleteBuilder {
        return SQLDeleteBuilder(builder: self, table: table, alias: alias)
    }
    
    public func update(_ table: String, alias: String? = nil) -> SQLUpdateBuilder {
        return SQLUpdateBuilder(builder: self, table: table, alias: alias)
    }
    
    public func insert(_ table: String, alias: String? = nil) -> SQLInsertBuilder {
        return SQLInsertBuilder(builder: self, table: table, alias: alias)
    }
}
