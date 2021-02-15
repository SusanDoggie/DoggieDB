//
//  SQLSelectBuilder.swift
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

public struct SQLSelectBuilder: SQLBuilderProtocol {
    
    public var builder: SQLBuilder
    
    init(builder: SQLBuilder) {
        self.builder = builder
        self.builder.append("SELECT")
    }
}

extension SQLSelectBuilder: SQLFromExpression {}
extension SQLSelectBuilder: SQLWhereExpression {}

extension SQLSelectBuilder {
    
    public func distinct() -> SQLSelectBuilder {
        
        guard self.dialect != nil else { return self }
        
        var builder = self
        
        builder.builder.append("DISTINCT")
        
        return builder
    }
    
    public func column(_ columns: String ...) -> SQLSelectBuilder {
        
        guard self.dialect != nil else { return self }
        
        var builder = self
        
        builder.builder.append(columns.joined(separator: ", "))
        
        return builder
    }
    
    public func group(_ block: (SQLSelectBuilder) -> SQLSelectBuilder) -> SQLSelectBuilder {
        
        guard self.dialect != nil else { return self }
        
        var builder = self
        
        builder.builder.append("(")
        builder = block(builder)
        builder.builder.append(")")
        
        return builder
    }
    
    public func join(_ table: String, method: SQLJoinMethod? = nil, on predicate: (SQLPredicateBuilder) -> SQLPredicateBuilder) -> SQLSelectBuilder {
        
        guard let dialect = self.dialect else { return self }
        
        var builder = self
        
        if let method = method {
            builder.builder.append("\(method.serialize()) JOIN \(table) ON \(predicate(SQLPredicateBuilder(dialect: dialect)).serialize())")
        } else {
            builder.builder.append("JOIN \(table) ON \(predicate(SQLPredicateBuilder(dialect: dialect)).serialize())")
        }
        
        return builder
    }
    
    public func join(
        _ alias: String,
        method: SQLJoinMethod? = nil,
        query: (SQLSelectBuilder) -> SQLSelectBuilder,
        on predicate: (SQLPredicateBuilder) -> SQLPredicateBuilder
    ) -> SQLSelectBuilder {
        
        guard let dialect = self.dialect else { return self }
        
        var builder = self
        
        if let method = method {
            builder.builder.append("\(method.serialize()) JOIN")
        } else {
            builder.builder.append("JOIN")
        }
        
        builder.builder.append("(")
        builder = query(SQLSelectBuilder(builder: builder.builder))
        builder.builder.append(") \(alias)")
        
        builder.builder.append("ON \(predicate(SQLPredicateBuilder(dialect: dialect)).serialize())")
        
        return builder
    }
    
    public func groupBy(_ groupBy: String ...) -> SQLSelectBuilder {
        
        guard self.dialect != nil else { return self }
        
        var builder = self
        
        builder.builder.append("GROUP BY \(groupBy.joined(separator: ", "))")
        
        return builder
    }
    
    public func having(_ predicate: (SQLPredicateBuilder) -> SQLPredicateBuilder) -> SQLSelectBuilder {
        
        guard let dialect = self.dialect else { return self }
        
        var builder = self
        
        builder.builder.append("HAVING \(predicate(SQLPredicateBuilder(dialect: dialect)).serialize())")
        
        return builder
    }
    
    public func orderBy(_ orderBy: String ...) -> SQLSelectBuilder {
        
        guard self.dialect != nil else { return self }
        
        var builder = self
        
        builder.builder.append("ORDER BY \(orderBy.joined(separator: ", "))")
        
        return builder
    }
    
    public func limit(_ limit: Int) -> SQLSelectBuilder {
        
        guard self.dialect != nil else { return self }
        
        var builder = self
        
        builder.builder.append("LIMIT \(limit)")
        
        return builder
    }
    
    public func offset(_ offset: Int) -> SQLSelectBuilder {
        
        guard self.dialect != nil else { return self }
        
        var builder = self
        
        builder.builder.append("OFFSET \(offset)")
        
        return builder
    }
    
    public func locking(_ lock: SQLLockingClause) -> SQLSelectBuilder {
        
        guard self.dialect != nil else { return self }
        
        var builder = self
        
        builder.builder.append("FOR \(lock.serialize())")
        
        return builder
    }
}
