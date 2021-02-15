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

public struct SQLBuilder {
    
    let connection: DBConnection
    
    let dialect: SQLDialect.Type?
    
    private var raw: SQLRaw = SQLRaw()
    
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

extension SQLBuilder {
    
    func execute() -> EventLoopFuture<[DBQueryRow]> {
        
        guard dialect != nil else {
            return connection.eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
        }
        
        return connection.execute(raw)
    }
    
    func execute(onRow: @escaping (DBQueryRow) -> Void) -> EventLoopFuture<DBQueryMetadata> {
        
        guard dialect != nil else {
            return connection.eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
        }
        
        return connection.execute(raw, onRow: onRow)
    }
}

extension SQLBuilder {
    
    private mutating func appendSpaceIfNeed() {
        
        guard self.dialect != nil else { return }
        guard !self.raw.isEmpty else { return }
        
        switch self.raw.components.last {
        
        case let .string(string):
            
            if string.last != " " {
                self.raw.append(" ")
            }
            
        default:
            
            self.raw.append(" ")
        }
    }
    
    public mutating func append(_ raw: SQLRaw) {
        
        guard self.dialect != nil else { return }
        
        self.appendSpaceIfNeed()
        self.raw.append(raw)
    }
    
    mutating func append<T: StringProtocol>(_ value: T) {
        
        guard self.dialect != nil else { return }
        
        self.appendSpaceIfNeed()
        self.raw.append(value)
    }
    
    mutating func append(_ value: DBData) {
        
        guard self.dialect != nil else { return }
        
        self.appendSpaceIfNeed()
        self.raw.append(value)
    }
    
    mutating func append(bind value: DBData) {
        
        guard self.dialect != nil else { return }
        
        self.appendSpaceIfNeed()
        self.raw.append(bind: value)
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
