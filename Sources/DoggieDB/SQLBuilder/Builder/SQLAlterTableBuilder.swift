//
//  SQLAlterTableBuilder.swift
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

public struct SQLAlterTableOptions: OptionSet {
    
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let ifExists = SQLAlterTableOptions(rawValue: 1 << 0)
}

public struct SQLAlterTableBuilder: SQLBuilderProtocol {
    
    public var builder: SQLBuilder
    
    init(builder: SQLBuilder, table: String, options: SQLAlterTableOptions) {
        self.builder = builder
        self.builder.append("ALTER TABLE")
        if options.contains(.ifExists) {
            self.builder.append("IF EXISTS")
        }
        self.builder.append(table)
    }
}

extension SQLAlterTableBuilder {
    
    public struct Options: OptionSet {
        
        public var rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let ifExists = Options(rawValue: 1 << 0)
    }
}

extension SQLAlterTableBuilder {
    
    public func rename(_ new_name: String) -> SQLFinalizedBuilder {
        
        var builder = self.builder
        
        builder.append("RENAME TO \(identifier: new_name)" as SQLRaw)
        
        return SQLFinalizedBuilder(builder: builder)
    }
    
    public func rename(_ column: String, to new_name: String) -> SQLFinalizedBuilder {
        
        var builder = self.builder
        
        builder.append("RENAME COLUMN \(identifier: column) TO \(identifier: new_name)" as SQLRaw)
        
        return SQLFinalizedBuilder(builder: builder)
    }
    
    public func dropColumn(_ column: String, options: Options = []) -> SQLFinalizedBuilder {
        
        var builder = self.builder
        
        builder.append("DROP COLUMN")
        
        if options.contains(.ifExists) {
            builder.append("IF EXISTS")
        }
        
        builder.append(column)
        
        return SQLFinalizedBuilder(builder: builder)
    }
    
}

extension SQLAlterTableBuilder {
    
    public func addColumn(
        name: String,
        type: String,
        optional: Bool = true,
        default: DBValue? = nil,
        autoIncrement: Bool = false,
        unique: Bool = false,
        primaryKey: Bool = false,
        reference: SQLForeignKey? = nil,
        onUpdate: SQLForeignKeyAction? = nil,
        onDelete: SQLForeignKeyAction? = nil
    ) -> SQLFinalizedBuilder {
        
        var builder = self.builder
        
        builder.append("ADD COLUMN")
        
        builder.append(name)
        builder.append(type)
        
        if !optional {
            builder.append("NOT NULL")
        }
        if let `default` = `default` {
            builder.append("DEFAULT")
            builder.append(`default`)
        }
        if autoIncrement {
            builder.append(.autoIncrement)
        }
        if unique {
            builder.append("UNIQUE")
        }
        if primaryKey {
            builder.append("PRIMARY KEY")
        }
        
        if let reference = reference {
            
            builder.append("REFERENCES \(reference.table)(\(reference.column))")
            
            if let onDelete = onDelete {
                switch onDelete {
                case .restrict: builder.append("ON DELETE RESTRICT")
                case .cascade: builder.append("ON DELETE CASCADE")
                case .setNull: builder.append("ON DELETE SET NULL")
                case .setDefault: builder.append("ON DELETE SET DEFAULT")
                }
            }
            if let onUpdate = onUpdate {
                switch onUpdate {
                case .restrict: builder.append("ON UPDATE RESTRICT")
                case .cascade: builder.append("ON UPDATE CASCADE")
                case .setNull: builder.append("ON UPDATE SET NULL")
                case .setDefault: builder.append("ON UPDATE SET DEFAULT")
                }
            }
        }
        
        return SQLFinalizedBuilder(builder: builder)
    }
}
