//
//  SQLReturningExpression.swift
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

public protocol SQLReturningExpression: SQLBuilderProtocol {
    
}

extension SQLReturningExpression {
    
    /// Specify a list of columns to be part of the result set of the query.
    /// Each provided name is a string assumed to be a valid SQL identifier and
    /// is not qualified.
    public func returning(_ column: String) -> SQLFinalizedBuilder {
        
        var builder = self
        
        if column == "*" {
            builder.builder.append("RETURNING *" as SQLRaw)
        } else {
            builder.builder.append("RETURNING \(identifier: column)" as SQLRaw)
        }
        
        return SQLFinalizedBuilder(builder: builder.builder)
    }
    
    /// Specify a list of columns to be part of the result set of the query.
    /// Each provided name is a string assumed to be a valid SQL identifier and
    /// is not qualified.
    public func returning(_ columns: [String]) -> SQLFinalizedBuilder {
        
        var builder = self
        
        builder.builder.append("RETURNING")
        builder.builder.append(columns.map { "\(identifier: $0)" as SQLRaw }.joined(separator: ", "))
        
        return SQLFinalizedBuilder(builder: builder.builder)
    }
    
    /// Specify a list of columns to be part of the result set of the query.
    /// Each provided name is a string assumed to be a valid SQL identifier and
    /// is not qualified.
    public func returning(_ column: String, _ column2: String, _ res: String ...) -> SQLFinalizedBuilder {
        
        var builder = self
        
        builder.builder.append("RETURNING \(identifier: column), \(identifier: column2)" as SQLRaw)
        
        for column in res {
            builder.builder.append(", \(identifier: column)" as SQLRaw)
        }
        
        return SQLFinalizedBuilder(builder: builder.builder)
    }
}
