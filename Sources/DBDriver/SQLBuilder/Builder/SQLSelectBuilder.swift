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

public protocol SQLSelectBuilderProtocol: SQLFromExpression, SQLWhereExpression, SQLJoinExpression, SQLOrderByExpression, SQLGroupByExpression {

    
}

public struct SQLSelectBuilder: SQLSelectBuilderProtocol {
    
    public var builder: SQLBuilder
    
    init(builder: SQLBuilder) {
        self.builder = builder
        self.builder.append("SELECT")
    }
}

extension SQLSelectBuilderProtocol {
    
    public static func select() -> SQLSelectBuilder {
        return SQLSelectBuilder(builder: SQLBuilder())
    }
}

extension SQLSelectBuilderProtocol {
    
    public func distinct() -> Self {
        
        var builder = self
        
        builder.builder.append("DISTINCT")
        
        return builder
    }
    
    public func union() -> SQLUnionBuilder  {
        return SQLUnionBuilder(builder: self.builder)
    }
}

extension SQLSelectBuilderProtocol {
    
    public func columns(_ column: SQLRaw) -> Self {
        
        var builder = self
        
        builder.builder.append(column)
        
        return builder
    }
    
    public func columns(_ column: SQLRaw, _ column2: SQLRaw, _ res: SQLRaw ...) -> Self {
        
        var builder = self
        
        let columns = [column, column2] + res
        
        builder.builder.append(columns.joined(separator: ", "))
        
        return builder
    }
}

extension SQLSelectBuilderProtocol {
    
    /// Adds a column to column comparison to this builder's `HAVING`.
    public func having(_ predicate: (SQLPredicateBuilder) -> SQLPredicateExpression) -> Self {
        
        var builder = self
        
        builder.builder.append("HAVING")
        predicate(SQLPredicateBuilder()).serialize(into: &builder.builder)
        
        return builder
    }
}

extension SQLSelectBuilderProtocol {
    
    /// Adds a `LIMIT` clause to the statement.
    public func limit(_ limit: Int) -> Self {
        
        var builder = self
        
        builder.builder.append("LIMIT \(limit)")
        
        return builder
    }
    
    /// Adds a `OFFSET` clause to the statement.
    public func offset(_ offset: Int) -> Self {
        
        var builder = self
        
        builder.builder.append("OFFSET \(offset)")
        
        return builder
    }
}

/// General locking expressions for a SQL locking clause.
public enum SQLLockingClause {
    
    /// `UPDATE`
    case update
    
    /// `SHARE`
    case share
    
    func serialize() -> String {
        switch self {
        case .share: return "SHARE"
        case .update: return "UPDATE"
        }
    }
}

extension SQLSelectBuilderProtocol {
    
    /// Adds a locking expression to this statement.
    public func locking(_ lock: SQLLockingClause) -> Self {
        
        var builder = self
        
        builder.builder.append("FOR \(lock.serialize())")
        
        return builder
    }
}
