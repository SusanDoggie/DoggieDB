//
//  DBFindOneExpression.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2022 Susan Cheng. All rights reserved.
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

@preconcurrency
import Collections

public struct DBFindOneExpression: DBExpressionProtocol {
    
    public let connection: DBConnection
    
    public let `class`: String
    
    var filters: [DBPredicateExpression] = []
    
    var sort: OrderedDictionary<String, DBSortOrderOption> = [:]
    
    var includes: Set<String>?
    
    var returning: DBReturningOption = .after
    
    init(connection: DBConnection, class: String) {
        self.connection = connection
        self.class = `class`
    }
}

extension DBQuery {
    
    public func findOne(_ class: String) -> DBFindOneExpression {
        return DBFindOneExpression(connection: connection, class: `class`)
    }
}

extension DBFindOneExpression {
    
    @discardableResult
    public func update(_ update: [String: DBDataConvertible]) async throws -> DBObject? {
        return try await self.update(update.mapValues { .set($0) })
    }
    
    @discardableResult
    public func update(_ update: [String: DBUpdateOption]) async throws -> DBObject? {
        guard let launcher = self.connection.launcher else { throw Database.Error.unsupportedOperation }
        return try await launcher.findOneAndUpdate(self, update)
    }
}

extension DBFindOneExpression {
    
    @discardableResult
    public func upsert(_ upsert: [String: DBDataConvertible]) async throws -> DBObject? {
        return try await self.upsert(upsert.mapValues { .set($0) })
    }
    
    @discardableResult
    public func upsert(_ upsert: [String: DBUpsertOption]) async throws -> DBObject? {
        return try await self.upsert(upsert.compactMapValues { $0.update }, setOnInsert: upsert.compactMapValues { $0.setOnInsert })
    }
    
    @discardableResult
    public func upsert(_ update: [String: DBDataConvertible], setOnInsert: [String : DBDataConvertible]) async throws -> DBObject? {
        return try await self.upsert(update.mapValues { .set($0) }, setOnInsert: setOnInsert)
    }
    
    @discardableResult
    public func upsert(_ update: [String : DBUpdateOption], setOnInsert: [String : DBDataConvertible]) async throws -> DBObject? {
        guard let launcher = self.connection.launcher else { throw Database.Error.unsupportedOperation }
        return try await launcher.findOneAndUpsert(self, update, setOnInsert)
    }
}

extension DBFindOneExpression {
    
    @discardableResult
    public func delete() async throws -> DBObject? {
        guard let launcher = self.connection.launcher else { throw Database.Error.unsupportedOperation }
        return try await launcher.findOneAndDelete(self)
    }
}

extension DBFindOneExpression {
    
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
    
    public func returning(_ returning: DBReturningOption) -> Self {
        var result = self
        result.returning = returning
        return result
    }
}
