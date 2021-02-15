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

extension SQLSelectBuilder {
    
    public static func select() -> SQLSelectBuilder {
        return SQLSelectBuilder(builder: SQLBuilder())
    }
}

extension SQLSelectBuilder: SQLFromExpression {}
extension SQLSelectBuilder: SQLWhereExpression {}
extension SQLSelectBuilder: SQLJoinExpression {}

extension SQLSelectBuilder {
    
    public func distinct() -> SQLSelectBuilder {
        
        var builder = self
        
        builder.builder.append("DISTINCT")
        
        return builder
    }
    
    public func union() -> SQLUnionBuilder  {
        return SQLUnionBuilder(builder: self.builder)
    }
    
    public func columns(_ column: String, _ res: String ...) -> SQLSelectBuilder {
        
        var builder = self
        
        let columns = [column] + res
        
        builder.builder.append(columns.joined(separator: ", "))
        
        return builder
    }
    
    public func groupBy(_ groupBy: String, _ res: String ...) -> SQLSelectBuilder {
        
        var builder = self
        
        let list = [groupBy] + res
        
        builder.builder.append("GROUP BY \(list.joined(separator: ", "))")
        
        return builder
    }
    
    public func having(_ predicate: BuilderClosure<SQLPredicateBuilder>) -> SQLSelectBuilder {
        
        var builder = self
        
        builder.builder.append("HAVING \(predicate(SQLPredicateBuilder()).serialize())")
        
        return builder
    }
    
    public func orderBy(_ orderBy: String, _ res: String ...) -> SQLSelectBuilder {
        
        var builder = self
        
        let list = [orderBy] + res
        
        builder.builder.append("ORDER BY \(list.joined(separator: ", "))")
        
        return builder
    }
    
    public func limit(_ limit: Int) -> SQLSelectBuilder {
        
        var builder = self
        
        builder.builder.append("LIMIT \(limit)")
        
        return builder
    }
    
    public func offset(_ offset: Int) -> SQLSelectBuilder {
        
        var builder = self
        
        builder.builder.append("OFFSET \(offset)")
        
        return builder
    }
    
    public func locking(_ lock: SQLLockingClause) -> SQLSelectBuilder {
        
        var builder = self
        
        builder.builder.append("FOR \(lock.serialize())")
        
        return builder
    }
}
