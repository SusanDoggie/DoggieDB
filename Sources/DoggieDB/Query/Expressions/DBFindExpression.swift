//
//  DBFindExpression.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2024 Susan Cheng. All rights reserved.
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

public struct DBFindExpression: DBExpressionProtocol {
    
    public let connection: DBConnection
    
    public let `class`: String
    
    var filters: [DBPredicateExpression] = []
    
    var skip: Int = 0
    
    var limit: Int = .max
    
    var sort: OrderedDictionary<String, DBSortOrderOption> = [:]
    
    var includes: Set<String>?
    
    var updateLock: Bool = false
    
    init(connection: DBConnection, class: String) {
        self.connection = connection
        self.class = `class`
    }
}

extension DBQuery {
    
    public func find(_ class: String) -> DBFindExpression {
        return DBFindExpression(connection: connection, class: `class`)
    }
}

extension DBFindExpression {
    
    public func count() async throws -> Int {
        guard let launcher = connection.launcher else { throw Database.Error.unsupportedOperation }
        return try await launcher.count(self)
    }
}

extension DBFindExpression {
    
    public func toArray() async throws -> [DBObject] {
        guard let launcher = connection.launcher else { throw Database.Error.unsupportedOperation }
        return try await launcher.find(self)
    }
    
    public func forEach(_ body: @escaping (DBObject) throws -> Void) async throws {
        guard let launcher = connection.launcher else { throw Database.Error.unsupportedOperation }
        return try await launcher.find(self) { try body($0) }
    }
    
    public func first() async throws -> DBObject? {
        return try await self.limit(1).toArray().first
    }
}

extension DBFindExpression {
    
    public func toStream() -> AsyncThrowingStream<DBObject, Error> {
        
        return AsyncThrowingStream { continuation in
            
            Task {
                
                do {
                    
                    try await self.forEach { continuation.yield($0) }
                    
                    continuation.finish()
                    
                } catch {
                    
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

extension DBFindExpression {
    
    @discardableResult
    public func delete() async throws -> Int? {
        guard let launcher = connection.launcher else { throw Database.Error.unsupportedOperation }
        return try await launcher.findAndDelete(self)
    }
}

extension DBFindExpression {
    
    public func filter(_ filter: DBPredicateExpression) -> Self {
        var result = self
        result.filters.append(filter)
        return result
    }
    
    public func filter(_ filter: [DBPredicateExpression]) -> Self {
        var result = self
        result.filters.append(contentsOf: filter)
        return result
    }
    
    public func filter(_ predicate: (DBPredicateBuilder) -> DBPredicateExpression) -> Self {
        var result = self
        result.filters.append(predicate(DBPredicateBuilder()))
        return result
    }
    
    public func skip(_ skip: Int) -> Self {
        var result = self
        result.skip = skip
        return result
    }
    
    public func limit(_ limit: Int) -> Self {
        var result = self
        result.limit = limit
        return result
    }
    
    public func sort(_ sort: OrderedDictionary<String, DBSortOrderOption>) -> Self {
        var result = self
        result.sort = sort
        return result
    }
    
    public func includes(_ keys: String ...) -> Self {
        var result = self
        result.includes = includes?.union(keys) ?? Set(keys)
        return result
    }
    
    public func includes<S: Sequence>(_ keys: S) -> Self where S.Element == String {
        var result = self
        result.includes = includes?.union(keys) ?? Set(keys)
        return result
    }
    
    public func forUpdate() -> Self {
        var result = self
        result.updateLock = true
        return result
    }
}
