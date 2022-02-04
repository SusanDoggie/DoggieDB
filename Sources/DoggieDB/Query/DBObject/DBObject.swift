//
//  DBObject.swift
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

public struct DBObject {
    
    public let `class`: String
    
    public let primaryKeys: Set<String>
    
    let _columns: [String: DBData]
    
    private(set) var _updates: [String: DBUpdateOption]
}

extension DBObject {
    
    public init(class: String) {
        self.class = `class`
        self.primaryKeys = []
        self._columns = [:]
        self._updates = [:]
    }
    
    init(
        class: String,
        primaryKeys: Set<String>,
        columns: [String: DBData]
    ) {
        self.class = `class`
        self.primaryKeys = primaryKeys
        self._columns = columns
        self._updates = [:]
    }
}

extension DBObject {
    
    public var objectId: DBData? {
        switch primaryKeys.count {
        case 0: return nil
        case 1: return _columns[primaryKeys.first!]
        default:
            let objectId = self._columns.filter { primaryKeys.contains($0.key) }
            return objectId.count == primaryKeys.count ? DBData(objectId) : nil
        }
    }
}

extension DBObject {
    
    public var keys: Set<String> {
        return Set(_columns.keys).union(_updates.keys)
    }
    
    public subscript(column: String) -> DBData {
        get {
            if primaryKeys.contains(column) {
                return _columns[column] ?? nil
            }
            return _updates[column]?.value ?? _columns[column] ?? nil
        }
        set {
            guard !primaryKeys.contains(column) else { return }
            _updates[column] = .set(newValue)
        }
    }
}

extension DBObject {
    
    public mutating func set(_ key: String, _ value: DBDataConvertible) {
        _updates[key] = .set(value)
    }
    
    public mutating func increment<T: DBDataConvertible & Numeric>(_ key: String, by amount: T) {
        _updates[key] = .increment(amount)
    }
    
    public mutating func decrement<T: DBDataConvertible & Numeric>(_ key: String, by amount: T) {
        _updates[key] = .decrement(amount)
    }
    
    public mutating func multiply<T: DBDataConvertible & Numeric>(_ key: String, by amount: T) {
        _updates[key] = .multiply(amount)
    }
    
    public mutating func divide<T: DBDataConvertible & Numeric>(_ key: String, by amount: T) {
        _updates[key] = .divide(amount)
    }
    
    public mutating func max(_ key: String, by value: DBDataConvertible) {
        _updates[key] = .max(value)
    }
    
    public mutating func min(_ key: String, by value: DBDataConvertible) {
        _updates[key] = .min(value)
    }
    
    public mutating func addToSet(_ key: String, _ value: DBDataConvertible) {
        _updates[key] = .addToSet([value])
    }
    
    public mutating func addToSet(_ key: String, values: [DBDataConvertible]) {
        _updates[key] = .addToSet(values)
    }
    
    public mutating func push(_ key: String, _ value: DBDataConvertible) {
        _updates[key] = .push([value])
    }
    
    public mutating func push(_ key: String, values: [DBDataConvertible]) {
        _updates[key] = .push(values)
    }
    
    public mutating func removeAll(_ key: String, _ value: DBDataConvertible) {
        _updates[key] = .removeAll([value])
    }
    
    public mutating func removeAll(_ key: String, values: [DBDataConvertible]) {
        _updates[key] = .removeAll(values)
    }
    
    public mutating func popFirst(for key: String) {
        _updates[key] = .popFirst
    }
    
    public mutating func popLast(for key: String) {
        _updates[key] = .popLast
    }
}

extension DBObject {
    
    public func fetch<S: Sequence>(_ keys: S, on connection: DBConnection) -> EventLoopFuture<DBObject> where S.Element == String {
        
        let objectId = self._columns.filter { primaryKeys.contains($0.key) }
        
        if objectId.count == primaryKeys.count {
            
            return connection.query().find(self.class)
                .filter { object in .and(objectId.map { object[$0] == $1 }) }
                .includes(Set(keys))
                .first()
                .unwrap(orError: Database.Error.objectNotFound)
            
        } else {
            return connection.eventLoopGroup.next().makeFailedFuture(Database.Error.invalidObjectId)
        }
    }
    
    public func fetch(on connection: DBConnection) -> EventLoopFuture<DBObject> {
        
        let objectId = self._columns.filter { primaryKeys.contains($0.key) }
        
        if objectId.count == primaryKeys.count {
            
            return connection.query().find(self.class)
                .filter { object in .and(objectId.map { object[$0] == $1 }) }
                .first()
                .unwrap(orError: Database.Error.objectNotFound)
            
        } else {
            return connection.eventLoopGroup.next().makeFailedFuture(Database.Error.invalidObjectId)
        }
    }
    
    public func save(on connection: DBConnection) -> EventLoopFuture<DBObject> {
        
        let objectId = self._columns.filter { primaryKeys.contains($0.key) }
        
        if objectId.isEmpty {
            return connection.query().insert(self.class, _updates.compactMapValues { $0.value })
        }
        
        if objectId.count == primaryKeys.count {
            
            return connection.query().findOne(self.class)
                .filter { object in .and(objectId.map { object[$0] == $1 }) }
                .includes(self.keys)
                .update(_updates)
                .unwrap(orError: Database.Error.objectNotFound)
            
        } else {
            return connection.eventLoopGroup.next().makeFailedFuture(Database.Error.invalidObjectId)
        }
    }
    
    public func delete(on connection: DBConnection) -> EventLoopFuture<DBObject> {
        
        let objectId = self._columns.filter { primaryKeys.contains($0.key) }
        
        if objectId.isEmpty {
            return connection.eventLoopGroup.next().makeFailedFuture(Database.Error.invalidObjectId)
        }
        
        if objectId.count == primaryKeys.count {
            
            return connection.query().findOne(self.class)
                .filter { object in .and(objectId.map { object[$0] == $1 }) }
                .includes(self.keys)
                .delete()
                .unwrap(orError: Database.Error.objectNotFound)
            
        } else {
            return connection.eventLoopGroup.next().makeFailedFuture(Database.Error.invalidObjectId)
        }
    }
}
