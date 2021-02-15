//
//  SQLSelect.swift
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

public struct SQLSelect: SQLExpression {
    
    public var columns: [SQLLiteral] = []
    
    public var tables: [SQLExpression] = []
    
    public var isDistinct: Bool = false
    
    public var joins: [SQLJoin]
    
    public var predicate: SQLPredicate?
    
    public var groupBy: [SQLLiteral]
    
    public var having: SQLPredicate?
    
    public var orderBy: [SQLLiteral]
    
    public var limit: Int?
    
    public var offset: Int?
    
    public var lockingClause: SQLExpression?
    
    public func serialize(to serializer: inout SQLSerializer) {
        
        serializer.write("SELECT")
        
        if self.isDistinct {
            serializer.write("DISTINCT")
        }
        
        serializer.write(self.columns, separator: ",")
        
        serializer.write("FROM")
        
        serializer.write(self.tables, separator: ",")
        
        if !self.joins.isEmpty {
            serializer.write(self.joins)
        }
        
        if let predicate = self.predicate {
            serializer.write("WHERE")
            predicate.serialize(to: &serializer)
        }
        
        if !self.groupBy.isEmpty {
            serializer.write("GROUP BY")
            serializer.write(self.groupBy, separator: ",")
        }
        
        if let having = self.having {
            serializer.write("HAVING")
            having.serialize(to: &serializer)
        }
        
        if !self.orderBy.isEmpty {
            serializer.write("ORDER BY")
            serializer.write(self.orderBy, separator: ",")
        }
        
        if let limit = self.limit {
            serializer.write("LIMIT")
            serializer.write(limit.description)
        }
        
        if let offset = self.offset {
            serializer.write("OFFSET")
            serializer.write(offset.description)
        }
        
        if let lockingClause = self.lockingClause {
            lockingClause.serialize(to: &serializer)
        }
    }
}
