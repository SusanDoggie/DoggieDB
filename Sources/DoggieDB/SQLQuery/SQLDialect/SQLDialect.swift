//
//  SQLDialect.swift
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

protocol SQLDialect {
    
    static func bindPlaceholder(at position: Int) -> String
    
    static func literalBoolean(_ value: Bool) -> String
    
}

extension DBConnection {
    
    var sqlDialect: SQLDialect.Type? {
        switch driver {
        case .mySQL: return MySQLDialect.self
        case .postgreSQL: return PostgreSQLDialect.self
        case .sqlite: return SQLiteDialect.self
        default: return nil
        }
    }
}

extension DBConnection {
    
    func serialize(_ sql: SQLRaw) -> (String, [DBData])? {
        
        guard let dialect = self.sqlDialect else { return nil }
        
        var raw = ""
        var binds: [DBData] = []
        
        for component in sql.components {
            switch component {
            case let .string(string): raw.append(string)
            case let .boolean(bool): raw.append(dialect.literalBoolean(bool))
            case let .signed(value): raw.append("\(value)")
            case let .unsigned(value): raw.append("\(value)")
            case let .number(value): raw.append("\(value)")
            case let .decimal(value): raw.append("\(value)")
            case let .bind(value):
                binds.append(value)
                raw.append(dialect.bindPlaceholder(at: binds.count))
            }
        }
        
        return (raw, binds)
    }
}
