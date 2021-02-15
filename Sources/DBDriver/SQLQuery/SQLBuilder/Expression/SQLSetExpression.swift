//
//  SQLWhereExpression.swift
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

public protocol SQLSetExpression: SQLBuilderProtocol {
    
}

extension SQLSetExpression {
    
    public var set: SQLSetExpressionBuilder<Self> {
        return SQLSetExpressionBuilder(expression: self)
    }
}

@dynamicCallable
public struct SQLSetExpressionBuilder<Expression: SQLSetExpression> {
    
    let expression: Expression
    
    public func dynamicallyCall(withKeywordArguments args: KeyValuePairs<String, SQLLiteral>) -> Expression {
        
        guard self.expression.dialect != nil else { return self.expression }
        
        var expression = self.expression
        
        expression.builder.append("SET")
        for (i, (key, value)) in args.enumerated() {
            expression.builder.append(i == 0 ? "\(key) =" : ", \(key) =")
            expression.builder.append(value)
        }
        
        return expression
    }
}
