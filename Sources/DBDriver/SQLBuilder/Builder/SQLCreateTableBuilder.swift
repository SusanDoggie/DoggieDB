//
//  SQLCreateTableBuilder.swift
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

public struct SQLCreateTableOptions: OptionSet {
    
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let temporary         = SQLCreateTableOptions(rawValue: 1 << 0)
    public static let ifNotExists       = SQLCreateTableOptions(rawValue: 1 << 1)
}

public struct SQLCreateTableBuilder: SQLBuilderProtocol {
    
    public var builder: SQLBuilder
    
    var flag = false
    
    init(builder: SQLBuilder, table: String, options: SQLCreateTableOptions = []) {
        self.builder = builder
        self.builder.append("CREATE")
        if options.contains(.temporary) {
            self.builder.append("TEMP")
        }
        self.builder.append("TABLE")
        if options.contains(.ifNotExists) {
            self.builder.append("IF NOT EXISTS")
        }
        self.builder.append("\(table) (")
    }
}

extension SQLCreateTableBuilder {
    
    public func execute() -> EventLoopFuture<[DBQueryRow]> {
        var builder = self.builder
        builder.append(")")
        return builder.execute()
    }
    
    public func execute(onRow: @escaping (DBQueryRow) -> Void) -> EventLoopFuture<DBQueryMetadata> {
        var builder = self.builder
        builder.append(")")
        return builder.execute(onRow: onRow)
    }
}

extension SQLCreateTableBuilder {
    
    public func column(
        name: String,
        type: String,
        optional: Bool = true,
        default: DBData? = nil,
        autoIncrement: Bool = false
    ) -> SQLCreateTableBuilder {
        
        var builder = self
        
        if flag {
            builder.builder.append(",")
        }
        
        builder.builder.append(name)
        builder.builder.append(type)
        
        if !optional {
            builder.builder.append("NOT NULL")
        }
        if let `default` = `default` {
            builder.builder.append("DEFAULT")
            builder.builder.append(`default`)
        }
        if autoIncrement {
            builder.builder.append(.autoIncrement)
        }
        
        builder.flag = true
        
        return builder
    }
}

extension SQLCreateTableBuilder {
    
    public func unique(_ column: String) -> SQLCreateTableBuilder {
        
        var builder = self
        
        if flag {
            builder.builder.append(",")
        }
        
        builder.builder.append("UNIQUE (\(column))")
        
        builder.flag = true
        
        return builder
    }
    
    public func unique(_ column: String, _ column2: String, _ res: String ...) -> SQLCreateTableBuilder {
        
        var builder = self
        
        if flag {
            builder.builder.append(",")
        }
        
        let columns = [column, column2] + res
        
        builder.builder.append("UNIQUE (\(columns.joined(separator: ", ")))")
        
        builder.flag = true
        
        return builder
    }
}

extension SQLCreateTableBuilder {
    
    public func primaryKey(_ column: String) -> SQLCreateTableBuilder {
        
        var builder = self
        
        if flag {
            builder.builder.append(",")
        }
        
        builder.builder.append("PRIMARY KEY (\(column))")
        
        builder.flag = true
        
        return builder
    }
    
    public func primaryKey(_ column: String, _ column2: String, _ res: String ...) -> SQLCreateTableBuilder {
        
        var builder = self
        
        if flag {
            builder.builder.append(",")
        }
        
        let columns = [column, column2] + res
        
        builder.builder.append("PRIMARY KEY (\(columns.joined(separator: ", ")))")
        
        builder.flag = true
        
        return builder
    }
}

public struct SQLForeignKey: Hashable {
    
    public var table: String
    
    public var column: String
    
    public init(table: String, column: String) {
        self.table = table
        self.column = column
    }
}

public enum SQLForeignKeyAction {
    
    case restrict
    
    case cascade
    
    case setNull
    
    case setDefault
}

extension SQLCreateTableBuilder {
    
    public func foreignKey(
        _ column: String,
        _ reference: SQLForeignKey,
        onUpdate: SQLForeignKeyAction? = nil,
        onDelete: SQLForeignKeyAction? = nil
    ) -> SQLCreateTableBuilder {
        
        var builder = self
        
        if flag {
            builder.builder.append(",")
        }
        
        builder.builder.append("FOREIGN KEY (\(column)) REFERENCES \(reference.table)(\(reference.column))")
        
        if let onDelete = onDelete {
            switch onDelete {
            case .restrict: builder.builder.append("ON DELETE RESTRICT")
            case .cascade: builder.builder.append("ON DELETE CASCADE")
            case .setNull: builder.builder.append("ON DELETE SET NULL")
            case .setDefault: builder.builder.append("ON DELETE SET DEFAULT")
            }
        }
        if let onUpdate = onUpdate {
            switch onUpdate {
            case .restrict: builder.builder.append("ON UPDATE RESTRICT")
            case .cascade: builder.builder.append("ON UPDATE CASCADE")
            case .setNull: builder.builder.append("ON UPDATE SET NULL")
            case .setDefault: builder.builder.append("ON UPDATE SET DEFAULT")
            }
        }
        
        builder.flag = true
        
        return builder
    }
}
