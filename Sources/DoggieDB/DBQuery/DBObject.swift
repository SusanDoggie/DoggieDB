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
}

extension DBObject {
    
    public init(class: String, object: BSONDocument) {
        
        var _columns: [String: DBData] = [:]
        for (key, value) in object {
            guard let value = try? DBData(value) else { continue }
            _columns[key] = value
        }
        
        self.class = `class`
        self.primaryKeys = ["_id"]
        self._columns = _columns
        self._updates = [:]
    }
    
    init(table: String, primaryKeys: [String], object: DBQueryRow) {
        
        var _columns: [String: DBData] = [:]
        for key in object.keys {
            guard let value = object[key] else { continue }
            _columns[key] = value
        }
        
        self.class = table
        self.primaryKeys = Set(primaryKeys)
        self._columns = _columns
        self._updates = [:]
    }
}

extension DBObject {
    
    public var objectId: DBData? {
        if primaryKeys.count == 1, let objectId = primaryKeys.first {
            return _columns[objectId]
        }
        return DBData(self._columns.filter { primaryKeys.contains($0.key) })
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
    
    public func fetch(on connection: DBConnection) -> EventLoopFuture<DBObject> {
        
        let objectId = self._columns.filter { primaryKeys.contains($0.key) }
        
        if objectId.count == primaryKeys.count {
            
            return connection.query().findOne(self.class)
                .filter { object in .and(objectId.map { object[$0] == $1 }) }
                .execute()
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
                return connection.eventLoopGroup.next().makeFailedFuture(Database.Error.invalidOperation(message: "unsupported operation"))
            }
            
            let result: EventLoopFuture<[String: DBData]?> = launcher.insert(self.class, _updates.compactMapValues { $0.value })
            
            return result.flatMapThrowing { objectId -> DBObject in
                
                guard let objectId = objectId else { throw Database.Error.unknown }
                return DBObject(class: self.class, primaryKeys: Set(objectId.keys), _columns: objectId, _updates: [:])
                
            }.flatMap { $0.fetch(on: connection) }
        }
        
        if objectId.count == primaryKeys.count {
            
            return connection.query().findOne(self.class)
                .filter { object in .and(objectId.map { object[$0] == $1 }) }
                .update(_updates)
                .execute()
                .flatMapThrowing { object in
                    guard let object = object else { throw Database.Error.objectNotFound }
                    return object
                }
            
        } else {
            return connection.eventLoopGroup.next().makeFailedFuture(Database.Error.invalidObjectId)
        }
    }
}
