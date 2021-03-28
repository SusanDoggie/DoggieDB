//
//  SQLInsertBuilder.swift
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

public struct SQLInsertBuilder: SQLBuilderProtocol {
    
    public var builder: SQLBuilder
    
    init(builder: SQLBuilder, table: String, alias: String?) {
        self.builder = builder
        self.builder.append("INSERT INTO \(table: table)" as SQLRaw)
        
        if let alias = alias {
            self.builder.append("AS \(identifier: alias)" as SQLRaw)
        }
    }
}

extension SQLInsertBuilder {
    
    public func columns(_ column: String) -> SQLInsertBuilder {
        
        var builder = self
        
        builder.builder.append("(\(identifier: column))" as SQLRaw)
        
        return builder
    }
    
    public func columns(_ column: String, _ column2: String, _ res: String ...) -> SQLInsertBuilder {
        
        var builder = self
        
        builder.builder.append("(\(identifier: column), \(identifier: column2)" as SQLRaw)
        
        for column in res {
            builder.builder.append(", \(identifier: column)" as SQLRaw)
        }
        
        builder.builder.append(")")
        
        return builder
    }
}

extension SQLInsertBuilder: SQLValuesExpression { }

extension SQLInsertBuilder {
    
    public func select() -> SQLInsertSelectBuilder {
        return SQLInsertSelectBuilder(builder: self.builder)
    }
}

public struct SQLInsertSelectBuilder: SQLSelectBuilderProtocol {
    
    public var builder: SQLBuilder
    
    init(builder: SQLBuilder) {
        self.builder = builder
        self.builder.append("SELECT")
    }
}

extension SQLInsertSelectBuilder: SQLReturningExpression {}
