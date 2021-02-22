//
//  SQLOrderByExpression.swift
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

public protocol SQLOrderByExpression: SQLBuilderProtocol {
    
}

extension SQLOrderByExpression {
    
    public func orderBy(_ orderBy: SQLRaw) -> Self {
        
        var builder = self
        
        builder.builder.append("ORDER BY \(orderBy)")
        
        return builder
    }
    
    public func orderBy(_ orderBy: SQLRaw, _ orderBy2: SQLRaw, _ res: SQLRaw ...) -> Self {
        
        var builder = self
        
        let list = [orderBy, orderBy2] + res
        
        builder.builder.append("ORDER BY \(list.joined(separator: ", "))")
        
        return builder
    }
}
