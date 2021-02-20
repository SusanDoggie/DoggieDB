//
//  SQLUpdateBuilder.swift
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

public struct SQLCreateViewOptions: OptionSet {
    
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let replacing = SQLCreateViewOptions(rawValue: 1 << 1)
    public static let temporary = SQLCreateViewOptions(rawValue: 1 << 2)
    public static let recursive = SQLCreateViewOptions(rawValue: 1 << 3)
    public static let ifNotExists = SQLCreateViewOptions(rawValue: 1 << 4)
}

public struct SQLCreateViewBuilder: SQLBuilderProtocol {
    
    public var builder: SQLBuilder
    
    init(builder: SQLBuilder, view: String, options: SQLCreateViewOptions = []) {
        self.builder = builder
        self.builder.append("CREATE")
        if options.contains(.replacing) {
            self.builder.append("OR REPLACE")
        }
        if options.contains(.temporary) {
            self.builder.append("TEMP")
        }
        if options.contains(.recursive) {
            self.builder.append("RECURSIVE")
        }
        if options.contains(.ifNotExists) {
            self.builder.append("IF NOT EXISTS")
        }
        self.builder.append("VIEW \(view) AS")
    }
}

extension SQLCreateViewBuilder: SQLWithExpression { }

extension SQLCreateViewBuilder {
    
    public func select() -> SQLSelectBuilder {
        return SQLSelectBuilder(builder: self.builder)
    }
}
