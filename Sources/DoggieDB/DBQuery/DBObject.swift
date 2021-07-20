//
//  DBObject.swift
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

@_implementationOnly import Private

public struct DBObject {
    
    public let `class`: String
    
    public let primaryKeys: Set<String>
    
    private let _columns: [String: DBData]
    
    private var _updates: [String: DBQueryUpdateOperation]
}

extension DBObject {
    
    public init(class: String) {
        self.class = `class`
        self.primaryKeys = []
        self._columns = [:]
        self._updates = [:]
    }
    
    init(_ object: _DBObject) {
        self.class = object.class
        self.primaryKeys = object.primaryKeys
        self._columns = object.columns as? [String: DBData] ?? [:]
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
    
    public subscript(column: String) -> DBData? {
        get {
            if primaryKeys.contains(column) {
                return _columns[column]
            }
            if let value = _updates[column]?.value {
                return value == nil ? nil : value
            }
            return _columns[column]
        }
        set {
            guard !primaryKeys.contains(column) else { return }
            _updates[column] = .set(newValue ?? nil)
        }
    }
}

extension DBObject {
    
    public mutating func set<T: DBDataConvertible>(_ key: String, _ value: T) {
        _updates[key] = .set(value.toDBData())
    }
    
    public mutating func increment<T: DBDataConvertible & Numeric>(_ key: String, by amount: T) {
        _updates[key] = .inc(amount.toDBData())
    }
    
    public mutating func multiply<T: DBDataConvertible & Numeric>(_ key: String, by amount: T) {
        _updates[key] = .mul(amount.toDBData())
    }
    
    public mutating func max<T: DBDataConvertible>(_ key: String, by value: T) {
        _updates[key] = .max(value.toDBData())
    }
    
    public mutating func min<T: DBDataConvertible>(_ key: String, by value: T) {
        _updates[key] = .min(value.toDBData())
    }
    
    public mutating func addToSet<T: DBDataConvertible>(_ key: String, with value: T, _ res: T...) {
        _updates[key] = .addToSet([value.toDBData()] + res.map { $0.toDBData() })
    }
    
    public mutating func push<T: DBDataConvertible>(_ key: String, with value: T, _ res: T...) {
        _updates[key] = .push([value.toDBData()] + res.map { $0.toDBData() })
    }
    
    public mutating func removeAll<T: DBDataConvertible>(_ key: String, _ value: T, _ res: T...) {
        _updates[key] = .removeAll([value.toDBData()] + res.map { $0.toDBData() })
    }
    
    public mutating func popFirst(for key: String) {
        _updates[key] = .popFirst
    }
    
    public mutating func popLast(for key: String) {
        _updates[key] = .popLast
    }
}

extension DBObject {
    
    public func fetch(on connection: DBConnection) -> EventLoopFuture<DBObject> {
        
        let objectId = self._columns.filter { primaryKeys.contains($0.key) }
        
        if objectId.count == primaryKeys.count {
            
            return connection.query().find(self.class)
                .filter { object in .and(objectId.map { object[$0] == $1 }) }
                .first()
                .flatMapThrowing { object in
                    guard let object = object else { throw Database.Error.objectNotFound }
                    return object
                }
            
        } else {
            return connection.eventLoopGroup.next().makeFailedFuture(Database.Error.invalidObjectId)
        }
    }
    
    public func save(on connection: DBConnection) -> EventLoopFuture<DBObject> {
        
        let objectId = self._columns.filter { primaryKeys.contains($0.key) }
        
        if objectId.isEmpty {
            
            guard let launcher = connection.launcher else {
                return connection.eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
            }
            
            let result = launcher.insert(self.class, _updates.compactMapValues { $0.value })
            
            return result.flatMap {
                
                guard let (object, is_complete) = $0 else { return connection.eventLoopGroup.next().makeFailedFuture(Database.Error.unknown) }
                
                if is_complete {
                    return connection.eventLoopGroup.next().makeSucceededFuture(DBObject(object))
                }
                
                return DBObject(object).fetch(on: connection)
            }
        }
        
        if objectId.count == primaryKeys.count {
            
            return connection.query().findOne(self.class)
                .filter { object in .and(objectId.map { object[$0] == $1 }) }
                .update(_updates)
                .flatMapThrowing { object in
                    guard let object = object else { throw Database.Error.objectNotFound }
                    return object
                }
            
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
                .delete()
                .flatMapThrowing { object in
                    guard let object = object else { throw Database.Error.objectNotFound }
                    return object
                }
            
        } else {
            return connection.eventLoopGroup.next().makeFailedFuture(Database.Error.invalidObjectId)
        }
    }
}
