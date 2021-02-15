//
//  SQLJoinExpression.swift
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

public enum SQLJoinMethod {
    
    case inner
    case outer
    case left
    case right
    
    func serialize() -> String {
        switch self {
        case .inner: return "INNER"
        case .outer: return "OUTER"
        case .left: return "LEFT"
        case .right: return "RIGHT"
        }
    }
}

public protocol SQLJoinExpression: SQLBuilderProtocol {
    
}

extension SQLJoinExpression {
    
    public func join(_ table: String, method: SQLJoinMethod? = nil, on predicate: BuilderClosure<SQLPredicateBuilder>) -> Self {
        
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
        query: BuilderClosure<SQLSelectBuilder>,
        on predicate: BuilderClosure<SQLPredicateBuilder>
    ) -> Self {
        
        guard let dialect = self.dialect else { return self }
        
        var builder = self
        
        if let method = method {
            builder.builder.append("\(method.serialize()) JOIN")
        } else {
            builder.builder.append("JOIN")
        }
        
        builder.builder.append("(")
        builder.builder = query(SQLSelectBuilder(builder: builder.builder)).builder
        builder.builder.append(") \(alias)")
        
        builder.builder.append("ON \(predicate(SQLPredicateBuilder(dialect: dialect)).serialize())")
        
        return builder
    }
}
