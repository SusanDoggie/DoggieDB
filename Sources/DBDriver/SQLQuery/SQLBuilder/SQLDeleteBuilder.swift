//
//  SQLDeleteBuilder.swift
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

public struct SQLDeleteBuilder: SQLBuilderProtocol {
    
    public var builder: SQLBuilder
    
    init(builder: SQLBuilder, table: String, alias: String?) {
        self.builder = builder
        self.builder.append("DELETE FROM \(table)")
        
        if let alias = alias {
            self.builder.append("AS \(alias)")
        }
    }
}

extension SQLDeleteBuilder: SQLWhereExpression {}
extension SQLDeleteBuilder: SQLReturningExpression {}

extension SQLDeleteBuilder {
    
    public func using(_ table: String, alias: String? = nil) -> SQLDeleteBuilder {
        
        guard self.dialect != nil else { return self }
        
        var builder = self
        
        builder.builder.append("USING \(table)")
        
        if let alias = alias {
            builder.builder.append("AS \(alias)")
        }
        
        return builder
    }
    
    public func using(_ alias: String, _ block: (SQLSelectBuilder) -> SQLSelectBuilder) -> SQLDeleteBuilder {
        
        guard self.dialect != nil else { return self }
        
        var builder = self
        
        builder.builder.append("USING (")
        builder.builder = block(SQLSelectBuilder(builder: builder.builder)).builder
        builder.builder.append(") \(alias)")
        
        return builder
    }
}
