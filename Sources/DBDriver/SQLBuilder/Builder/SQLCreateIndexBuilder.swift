//
//  SQLCreateIndexBuilder.swift
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

public struct SQLCreateIndexOptions: OptionSet {
    
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let unique            = SQLCreateIndexOptions(rawValue: 1 << 0)
    
    public static let ifNotExists       = SQLCreateIndexOptions(rawValue: 1 << 1)
    
    public static let concurrent       = SQLCreateIndexOptions(rawValue: 1 << 2)
}

public struct SQLCreateIndexBuilder: SQLBuilderProtocol {
    
    public var builder: SQLBuilder
    
    var flag = false
    
    init(builder: SQLBuilder, index: String?, table: String, options: SQLCreateIndexOptions) {
        self.builder = builder
        self.builder.append("CREATE")
        if options.contains(.unique) {
            self.builder.append("UNIQUE")
        }
        self.builder.append("INDEX")
        if options.contains(.concurrent) {
            self.builder.append("CONCURRENTLY")
        }
        if options.contains(.ifNotExists) {
            self.builder.append("IF NOT EXISTS")
        }
        if let index = index {
            self.builder.append("\(identifier: index)" as SQLRaw)
        }
        self.builder.append("ON \(identifier: table)" as SQLRaw)
    }
}

extension SQLCreateIndexBuilder {
    
    public func columns(_ column: SQLRaw) -> SQLCreateIndexBuilder {
        
        var builder = self
        
        builder.builder.append("(")
        builder.builder.append(column)
        builder.builder.append(")")
        
        return builder
    }
    
    public func columns(_ column: SQLRaw, _ column2: SQLRaw, _ res: SQLRaw ...) -> SQLCreateIndexBuilder {
        
        var builder = self
        
        let columns = [column, column2] + res
        
        builder.builder.append("(")
        builder.builder.append(columns.joined(separator: ", "))
        builder.builder.append(")")
        
        return builder
    }
}
