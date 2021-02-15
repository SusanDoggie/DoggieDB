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

public struct SQLBuilder {
    
    let connection: DBConnection
    
    let dialect: SQLDialect.Type?
    
    var raw: SQLRaw = SQLRaw()
    
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
    
    public func excute() -> EventLoopFuture<[DBQueryRow]> {
        
        guard dialect != nil else {
            return connection.eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
        }
        
        return connection.execute(raw)
    }
    
    public func execute(onRow: @escaping (DBQueryRow) -> Void) -> EventLoopFuture<DBQueryMetadata> {
        
        guard dialect != nil else {
            return connection.eventLoop.makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
        }
        
        return connection.execute(raw, onRow: onRow)
    }
}

extension SQLBuilder {
    
    private func build(_ block: (inout SQLRaw, SQLDialect.Type) -> Void) -> SQLBuilder {
        guard let dialect = self.dialect else { return self }
        var builder = self
        if !builder.raw.isEmpty {
            builder.raw.append(" ")
        }
        block(&builder.raw, dialect)
        return builder
    }
    
    public func select() -> SQLBuilder {
        return self.build { sql, dialect in sql.append("SELECT") }
    }
    
    public func distinct() -> SQLBuilder {
        return self.build { sql, dialect in sql.append("DISTINCT") }
    }
    
    public func column(_ columns: String ...) -> SQLBuilder {
        return self.build { sql, dialect in sql.append(columns.joined(separator: ", ")) }
    }
    
    public func from(_ tables: String ...) -> SQLBuilder {
        return self.build { sql, dialect in sql.append("FROM \(tables.joined(separator: ", "))") }
    }
    
    public func join(_ table: String, on predicate: (SQLPredicateBuilder) -> SQLPredicateBuilder) -> SQLBuilder {
        return self.build { sql, dialect in sql.append("JOIN \(table) ON \(predicate(SQLPredicateBuilder(dialect: dialect)).serialize())") }
    }
    
    public func `where`(_ predicate: (SQLPredicateBuilder) -> SQLPredicateBuilder) -> SQLBuilder {
        return self.build { sql, dialect in sql.append("WHERE \(predicate(SQLPredicateBuilder(dialect: dialect)).serialize())") }
    }
    
    public func groupBy(_ groupBy: String ...) -> SQLBuilder {
        return self.build { sql, dialect in sql.append("GROUP BY \(groupBy.joined(separator: ", "))") }
    }
    
    public func having(_ predicate: (SQLPredicateBuilder) -> SQLPredicateBuilder) -> SQLBuilder {
        return self.build { sql, dialect in sql.append("HAVING \(predicate(SQLPredicateBuilder(dialect: dialect)).serialize())") }
    }
    
    public func orderBy(_ orderBy: String ...) -> SQLBuilder {
        return self.build { sql, dialect in sql.append("ORDER BY \(orderBy.joined(separator: ", "))") }
    }
    
    public func limit(_ limit: Int) -> SQLBuilder {
        return self.build { sql, dialect in sql.append("LIMIT \(limit)") }
    }
    
    public func offset(_ offset: Int) -> SQLBuilder {
        return self.build { sql, dialect in sql.append("OFFSET \(offset)") }
    }
}
