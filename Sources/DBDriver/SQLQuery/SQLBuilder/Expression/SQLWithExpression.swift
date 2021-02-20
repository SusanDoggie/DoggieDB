//
//  SQLWithExpression.swift
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

public protocol SQLWithExpression: SQLBuilderProtocol {
    
}

extension SQLWithExpression {
    
    public func with(_ queries: [String: SQLSelectBuilder]) -> SQLWithBuilder<Self> {
        
        var builder = self.builder
        
        builder.append("WITH")
        for (i, (key, query)) in queries.enumerated() {
            builder.append(i == 0 ? "\(key) AS (" : ", \(key) AS (")
            builder.append(query.builder)
            builder.append(")")
        }
        
        return SQLWithBuilder(builder: builder)
    }
    
    public func withRecursive(_ queries: [String: SQLSelectBuilder]) -> SQLWithBuilder<Self> {
        
        var builder = self.builder
        
        builder.append("WITH RECURSIVE")
        for (i, (key, query)) in queries.enumerated() {
            builder.append(i == 0 ? "\(key) AS (" : ", \(key) AS (")
            builder.append(query.builder)
            builder.append(")")
        }
        
        return SQLWithBuilder(builder: builder)
    }
}

public struct SQLWithBuilder<Base>: SQLBuilderProtocol {
    
    public var builder: SQLBuilder
    
    init(builder: SQLBuilder) {
        self.builder = builder
    }
}

extension SQLWithBuilder {
    
    public func select() -> SQLSelectBuilder {
        return SQLSelectBuilder(builder: self.builder)
    }
}

public protocol SQLWithModifyingExpression: SQLWithExpression {
    
}

extension SQLWithBuilder where Base: SQLWithModifyingExpression {
    
    public func delete(_ table: String, as alias: String? = nil) -> SQLDeleteBuilder {
        return SQLDeleteBuilder(builder: self.builder, table: table, alias: alias)
    }
    
    public func update(_ table: String, as alias: String? = nil) -> SQLUpdateBuilder {
        return SQLUpdateBuilder(builder: self.builder, table: table, alias: alias)
    }
    
    public func insert(_ table: String, as alias: String? = nil) -> SQLInsertBuilder {
        return SQLInsertBuilder(builder: self.builder, table: table, alias: alias)
    }
}
