//
//  SQLFromExpression.swift
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

public protocol SQLFromExpression: SQLBuilderProtocol {
    
}

extension SQLFromExpression {
    
    public func from(_ table: String, _ res: String ...) -> Self {
        
        guard self.dialect != nil else { return self }
        
        var builder = self
        
        let tables = [table] + res
        
        builder.builder.append("FROM \(tables.joined(separator: ", "))")
        
        return builder
    }
    
    public func from(_ alias: String, _ block: BuilderClosure<SQLSelectBuilder>) -> Self {
        
        guard self.dialect != nil else { return self }
        
        var builder = self
        
        builder.builder.append("(")
        builder.builder = block(SQLSelectBuilder(builder: builder.builder)).builder
        builder.builder.append(") \(alias)")
        
        return builder
    }
}
