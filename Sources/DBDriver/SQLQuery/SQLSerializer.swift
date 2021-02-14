//
//  SQLSerializer.swift
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

enum SQLSerializerComponent: Hashable {
    
    case string(String)
    
    case bind(DBData)
}

public struct SQLSerializer {
    
    public let dialect: SQLDialect.Type
    
    var components: [SQLSerializerComponent]
    
    init(dialect: SQLDialect.Type) {
        self.dialect = dialect
        self.components = []
    }
}

extension SQLSerializer {
    
    fileprivate var raw: SQLRaw {
        return components.map {
            switch $0 {
            case let .string(string): return SQLRaw(string)
            case let .bind(data): return SQLRaw(data)
            }
        }.joined(separator: " ")
    }
}

extension DBConnection {
    
    public func execute(
        _ sql: SQLExpression
    ) -> EventLoopFuture<[DBQueryRow]> {
        
        do {
            
            guard let dialect = self.sqlDialect else {
                throw Database.Error.invalidOperation(message: "unsupported operation")
            }
            
            var serializer = SQLSerializer(dialect: dialect)
            
            sql.serialize(to: &serializer)
            
            return self.execute(serializer.raw)
            
        } catch let error {
            
            return eventLoop.makeFailedFuture(error)
        }
    }
    
    public func execute(
        _ sql: SQLExpression,
        onRow: @escaping (DBQueryRow) -> Void
    ) -> EventLoopFuture<DBQueryMetadata> {
        
        do {
            
            guard let dialect = self.sqlDialect else {
                throw Database.Error.invalidOperation(message: "unsupported operation")
            }
            
            var serializer = SQLSerializer(dialect: dialect)
            
            sql.serialize(to: &serializer)
            
            return self.execute(serializer.raw, onRow: onRow)
            
        } catch let error {
            
            return eventLoop.makeFailedFuture(error)
        }
    }
}

extension SQLSerializer {
    
    public mutating func write<T: StringProtocol>(_ value: T) {
        self.components.append(.string(value.trimmingCharacters(in: .whitespacesAndNewlines)))
    }
    
    public mutating func write(_ value: DBData) {
        self.components.append(.bind(value))
    }
}
