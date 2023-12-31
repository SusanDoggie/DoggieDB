//
//  MongoQueryLauncher.swift
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

extension Dictionary where Key == String, Value == DBUpdateOption {
    
    fileprivate func toBSONDictionary() throws -> [String: BSON] {
        
        var update: [String: BSON] = [:]
        
        for (key, value) in self {
            switch value {
            case let .set(value):
                
                if value.toDBData() == nil {
                    update["$unset", default: [:]][key] = ""
                } else {
                    update["$set", default: [:]][key] = try BSON(value.toDBData())
                }
                
            case let .increment(value): update["$inc", default: [:]][key] = try BSON(value.toDBData())
            case let .decrement(value):
                
                guard case let .number(value) = value.toDBData() else { throw Database.Error.unsupportedOperation }
                
                switch value {
                case let .signed(value): update["$inc", default: [:]][key] = BSON(-value)
                case let .unsigned(value): update["$inc", default: [:]][key] = BSON(-Int64(value))
                case let .number(value): update["$inc", default: [:]][key] = BSON(-value)
                case let .decimal(value): update["$inc", default: [:]][key] = BSON(-value)
                }
                
            case let .multiply(value): update["$mul", default: [:]][key] = try BSON(value.toDBData())
            case let .divide(value):
                
                guard case let .number(value) = value.toDBData() else { throw Database.Error.unsupportedOperation }
                
                switch value {
                case let .signed(value): update["$mul", default: [:]][key] = BSON(1 / Double(value))
                case let .unsigned(value): update["$mul", default: [:]][key] = BSON(1 / Double(value))
                case let .number(value): update["$mul", default: [:]][key] = BSON(1 / value)
                case let .decimal(value): update["$mul", default: [:]][key] = BSON(1 / value)
                }
                
            case let .min(value): update["$min", default: [:]][key] = try BSON(value.toDBData())
            case let .max(value): update["$max", default: [:]][key] = try BSON(value.toDBData())
            case let .addToSet(value):
                
                switch value.count {
                case 0: break
                case 1: update["$addToSet", default: [:]][key] = try BSON(value[0].toDBData())
                default: update["$addToSet", default: [:]][key] = try ["$each": BSON(value.map { try BSON($0.toDBData()) })]
                }
                
            case let .push(value):
                
                switch value.count {
                case 0: break
                case 1: update["$push", default: [:]][key] = try BSON(value[0].toDBData())
                default: update["$push", default: [:]][key] = try ["$each": BSON(value.map { try BSON($0.toDBData()) })]
                }
                
            case let .removeAll(value):
                
                switch value.count {
                case 0: break
                case 1: update["$pull", default: [:]][key] = try BSON(value[0].toDBData())
                default: update["$pullAll", default: [:]][key] = try BSON(value.map { try BSON($0.toDBData()) })
                }
                
            case .popFirst: update["$pop", default: [:]][key] = -1
            case .popLast: update["$pop", default: [:]][key] = 1
            }
        }
        
        return update
    }
    
    fileprivate func toBSONDocument() throws -> BSONDocument {
        return try BSONDocument(self.toBSONDictionary())
    }
}

struct MongoQueryLauncher: DBQueryLauncher {
    
    let connection: DBMongoConnectionProtocol
    
    func count(_ query: DBFindExpression) async throws -> Int {
        
        let filter = try query.filters.map { try MongoPredicateExpression($0).toBSONDocument() }
        
        return try await connection.mongoQuery().collection(query.class).count().filter(filter).execute()
    }
    
    func _find(_ query: DBFindExpression) throws -> DBMongoFindExpression<BSONDocument> {
        
        let filter = try query.filters.map { try MongoPredicateExpression($0).toBSONDocument() }
        
        var mongoQuery = connection.mongoQuery().collection(query.class).find().filter(filter)
        
        if !query.sort.isEmpty {
            mongoQuery = mongoQuery.sort(query.sort.mapValues(DBMongoSortOrder.init))
        }
        if query.skip > 0 {
            mongoQuery = mongoQuery.skip(query.skip)
        }
        if query.limit != .max {
            mongoQuery = mongoQuery.limit(query.limit)
        }
        
        if let includes = query.includes {
            let projection = Dictionary(uniqueKeysWithValues: includes.map { ($0, 1) })
            mongoQuery = mongoQuery.projection(BSONDocument(projection))
        }
        
        return mongoQuery
    }
    
    func find(_ query: DBFindExpression) async throws -> [DBObject] {
        
        return try await self._find(query).execute().toArray().map { DBObject(class: query.class, object: $0) }
    }
    
    func find(_ query: DBFindExpression, forEach: @escaping (DBObject) throws -> Void) async throws {
        
        try await self._find(query).execute().forEach { try forEach(DBObject(class: query.class, object: $0)) }
    }
    
    func findAndDelete(_ query: DBFindExpression) async throws -> Int? {
        
        let filter = try query.filters.map { try MongoPredicateExpression($0).toBSONDocument() }
        
        let mongoQuery = connection.mongoQuery().collection(query.class).deleteMany().filter(filter)
        
        return try await mongoQuery.execute()?.deletedCount
    }
    
    func findOneAndUpdate(_ query: DBFindOneExpression, _ update: [String: DBUpdateOption]) async throws -> DBObject? {
        
        let filter = try query.filters.map { try MongoPredicateExpression($0).toBSONDocument() }
        
        var mongoQuery = connection.mongoQuery().collection(query.class).findOneAndUpdate().filter(filter)
        
        mongoQuery = try mongoQuery.update(update.toBSONDocument())
        
        switch query.returning {
        case .before: mongoQuery = mongoQuery.returnDocument(.before)
        case .after: mongoQuery = mongoQuery.returnDocument(.after)
        }
        
        if !query.sort.isEmpty {
            mongoQuery = mongoQuery.sort(query.sort.mapValues(DBMongoSortOrder.init))
        }
        
        if let includes = query.includes {
            let projection = Dictionary(uniqueKeysWithValues: includes.map { ($0, 1) })
            mongoQuery = mongoQuery.projection(BSONDocument(projection))
        }
        
        return try await mongoQuery.execute().map { DBObject(class: query.class, object: $0) }
    }
    
    func findOneAndReplace(_ query: DBFindOneExpression, _ replacement: [String: DBDataConvertible]) async throws -> DBObject? {
        
        let filter = try query.filters.map { try MongoPredicateExpression($0).toBSONDocument() }
        
        var mongoQuery = connection.mongoQuery().collection(query.class).findOneAndReplace().filter(filter)
        
        mongoQuery = try mongoQuery.replacement(BSONDocument(replacement.mapValues { $0.toDBData() }))
        
        switch query.returning {
        case .before: mongoQuery = mongoQuery.returnDocument(.before)
        case .after: mongoQuery = mongoQuery.returnDocument(.after)
        }
        
        if !query.sort.isEmpty {
            mongoQuery = mongoQuery.sort(query.sort.mapValues(DBMongoSortOrder.init))
        }
        
        if let includes = query.includes {
            let projection = Dictionary(uniqueKeysWithValues: includes.map { ($0, 1) })
            mongoQuery = mongoQuery.projection(BSONDocument(projection))
        }
        
        return try await mongoQuery.execute().map { DBObject(class: query.class, object: $0) }
    }
    
    func findOneAndUpsert(_ query: DBFindOneExpression, _ update: [String : DBUpdateOption], _ setOnInsert: [String : DBDataConvertible]) async throws -> DBObject? {
        
        let filter = try query.filters.map { try MongoPredicateExpression($0).toBSONDocument() }
        
        var mongoQuery = connection.mongoQuery().collection(query.class).findOneAndUpdate().filter(filter)
        
        var _update = try update.toBSONDictionary()
        for case let (key, value) in setOnInsert where value.toDBData() != nil {
            _update["$setOnInsert", default: [:]][key] = try BSON(value.toDBData())
        }
        
        mongoQuery = mongoQuery.update(BSONDocument(_update))
        mongoQuery = mongoQuery.upsert(true)
        
        switch query.returning {
        case .before: mongoQuery = mongoQuery.returnDocument(.before)
        case .after: mongoQuery = mongoQuery.returnDocument(.after)
        }
        
        if !query.sort.isEmpty {
            mongoQuery = mongoQuery.sort(query.sort.mapValues(DBMongoSortOrder.init))
        }
        
        if let includes = query.includes {
            let projection = Dictionary(uniqueKeysWithValues: includes.map { ($0, 1) })
            mongoQuery = mongoQuery.projection(BSONDocument(projection))
        }
        
        return try await mongoQuery.execute().map { DBObject(class: query.class, object: $0) }
    }
    
    func findOneAndDelete(_ query: DBFindOneExpression) async throws -> DBObject? {
        
        let filter = try query.filters.map { try MongoPredicateExpression($0).toBSONDocument() }
        
        var mongoQuery = connection.mongoQuery().collection(query.class).findOneAndDelete().filter(filter)
        
        if !query.sort.isEmpty {
            mongoQuery = mongoQuery.sort(query.sort.mapValues(DBMongoSortOrder.init))
        }
        
        if let includes = query.includes {
            let projection = Dictionary(uniqueKeysWithValues: includes.map { ($0, 1) })
            mongoQuery = mongoQuery.projection(BSONDocument(projection))
        }
        
        return try await mongoQuery.execute().map { DBObject(class: query.class, object: $0) }
    }
    
    func insert<Data>(_ class: String, _ data: [String: Data]) async throws -> DBObject? {
        
        guard let data = data as? [String: DBData] else { fatalError() }
        
        var values = try BSONDocument(data)
        
        guard let id = try await connection.mongoQuery().collection(`class`)
            .insertOne().value(values)
            .execute()?.insertedID else { return nil }
        
        values["_id"] = id
        
        return DBObject(class: `class`, object: values)
    }
}

extension DBObject {
    
    fileprivate init(class: String, object: BSONDocument) {
        var _columns: [String: DBData] = [:]
        for (key, value) in object {
            guard let value = try? DBData(value) else { continue }
            _columns[key] = value
        }
        self.init(class: `class`, primaryKeys: ["_id"], columns: _columns)
    }
}

extension MongoPredicateExpression {
    
    fileprivate init(_ expression: DBPredicateExpression) throws {
        switch expression {
        case let .not(expr): self = try .not(MongoPredicateExpression(expr))
        case let .equal(lhs, rhs): self = try .equal(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .notEqual(lhs, rhs): self = try .notEqual(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .lessThan(lhs, rhs): self = try .lessThan(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .greaterThan(lhs, rhs): self = try .greaterThan(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .lessThanOrEqualTo(lhs, rhs): self = try .lessThanOrEqualTo(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .greaterThanOrEqualTo(lhs, rhs): self = try .greaterThanOrEqualTo(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .containsIn(lhs, rhs): self = try .containsIn(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .notContainsIn(lhs, rhs): self = try .notContainsIn(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
            
        case let .between(x, from, to):
            
            self = try .and([
                .greaterThanOrEqualTo(MongoPredicateValue(from), MongoPredicateValue(x)),
                .lessThanOrEqualTo(MongoPredicateValue(to), MongoPredicateValue(x)),
            ])
            
        case let .notBetween(x, from, to):
            
            self = try .or([
                .lessThan(MongoPredicateValue(from), MongoPredicateValue(x)),
                .greaterThan(MongoPredicateValue(to), MongoPredicateValue(x)),
            ])
            
        case let .startsWith(value, pattern): self = .startsWith(MongoPredicateKey(value), pattern)
        case let .endsWith(value, pattern): self = .endsWith(MongoPredicateKey(value), pattern)
        case let .contains(value, pattern): self = .contains(MongoPredicateKey(value), pattern)
        case let .and(list): self = try .and(list.map(MongoPredicateExpression.init))
        case let .or(list): self = try .or(list.map(MongoPredicateExpression.init))
        }
    }
}

extension MongoPredicateValue {
    
    fileprivate init(_ value: DBPredicateValue) throws {
        switch value {
        case .objectId: self = .key("_id")
        case let .key(key): self = .key(key)
        case let .value(value): self = try .value(BSON(value.toDBData()))
        }
    }
}

extension MongoPredicateKey {
    
    fileprivate init(_ value: DBPredicateKey) {
        switch value {
        case .objectId: self.init(key: "_id")
        case let .key(key): self.init(key: key)
        }
    }
}

extension DBMongoSortOrder {
    
    fileprivate init(_ order: DBSortOrderOption) {
        switch order {
        case .ascending: self = .ascending
        case .descending: self = .descending
        }
    }
}
