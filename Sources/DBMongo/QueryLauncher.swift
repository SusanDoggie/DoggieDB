//
//  QueryLauncher.swift
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

extension Dictionary where Key == String, Value == DBQueryUpdateOperation {
    
    fileprivate func toBSONDocument() throws -> BSONDocument {
        
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
                
                switch value.toDBData().type {
                case .signed, .unsigned:
                    
                    guard let value = value.toDBData().intValue else { throw Database.Error.unsupportedOperation }
                    update["$inc", default: [:]][key] = BSON(-value)
                    
                case .number:
                    
                    guard let value = value.toDBData().doubleValue else { throw Database.Error.unsupportedOperation }
                    update["$inc", default: [:]][key] = BSON(-value)
                    
                case .decimal:
                    
                    guard let value = value.toDBData().decimalValue else { throw Database.Error.unsupportedOperation }
                    update["$inc", default: [:]][key] = BSON(-value)
                    
                default: throw Database.Error.unsupportedOperation
                }
                
            case let .multiply(value): update["$mul", default: [:]][key] = try BSON(value.toDBData())
            case let .divide(value):
                
                switch value.toDBData().type {
                case .signed, .unsigned, .number:
                    
                    guard let value = value.toDBData().doubleValue else { throw Database.Error.unsupportedOperation }
                    update["$mul", default: [:]][key] = BSON(1 / value)
                    
                case .decimal:
                    
                    guard let value = value.toDBData().decimalValue else { throw Database.Error.unsupportedOperation }
                    update["$mul", default: [:]][key] = BSON(1 / value)
                    
                default: throw Database.Error.unsupportedOperation
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
        
        return BSONDocument(update)
    }
    
}

extension _DBQuery {
    
    fileprivate var filters: [DBQueryPredicateExpression] {
        return self["filters"] as! Array
    }
    fileprivate var sort: OrderedDictionary<String, DBQuerySortOrder> {
        return self["sort"] as! OrderedDictionary
    }
    fileprivate var skip: Int {
        return self["skip"] as! Int
    }
    fileprivate var limit: Int {
        return self["limit"] as! Int
    }
    fileprivate var includes: Set<String> {
        return self["includes"] as! Set
    }
    fileprivate var returning: DBQueryReturning {
        return self["returning"] as! DBQueryReturning
    }
}

struct QueryLauncher: _DBQueryLauncher {
    
    let connection: MongoDBDriver.Connection
    
    func count(_ query: _DBQuery) -> EventLoopFuture<Int> {
        
        do {
            
            let filter = try query.filters.map { try MongoPredicateExpression($0).toBSONDocument() }
            
            return connection.mongoQuery().collection(query.class).count().filter(filter).execute()
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func _find(_ query: _DBQuery) throws -> DBMongoFindExpression<BSONDocument> {
        
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
        
        if !query.includes.isEmpty {
            let projection = Dictionary(uniqueKeysWithValues: query.includes.map { ($0, 1) })
            mongoQuery = mongoQuery.projection(BSONDocument(projection))
        }
        
        return mongoQuery
    }
    
    func find(_ query: _DBQuery) -> EventLoopFuture<[_DBObject]> {
        
        do {
            
            return try self._find(query).execute().flatMap { $0.toArray() }.map { $0.map { _DBObject(class: query.class, object: $0) } }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func find(_ query: _DBQuery, forEach: @escaping (_DBObject) throws -> Void) -> EventLoopFuture<Void> {
        
        do {
            
            return try self._find(query).execute().flatMap { $0.forEach { try forEach(_DBObject(class: query.class, object: $0)) } }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findAndDelete(_ query: _DBQuery) -> EventLoopFuture<Int?> {
        
        do {
            
            let filter = try query.filters.map { try MongoPredicateExpression($0).toBSONDocument() }
            
            let mongoQuery = connection.mongoQuery().collection(query.class).deleteMany().filter(filter)
            
            return mongoQuery.execute().map { $0?.deletedCount }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findOneAndUpdate<Update>(_ query: _DBQuery, _ update: [String: Update]) -> EventLoopFuture<_DBObject?> {
        
        guard let update = update as? [String: DBQueryUpdateOperation] else { fatalError() }
        
        do {
            
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
            
            if !query.includes.isEmpty {
                let projection = Dictionary(uniqueKeysWithValues: query.includes.map { ($0, 1) })
                mongoQuery = mongoQuery.projection(BSONDocument(projection))
            }
            
            return mongoQuery.execute().map { $0.map { _DBObject(class: query.class, object: $0) } }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findOneAndUpsert<Update, Data>(_ query: _DBQuery, _ update: [String: Update], _ setOnInsert: [String: Data]) -> EventLoopFuture<_DBObject?> {
        
        guard let update = update as? [String: DBQueryUpdateOperation] else { fatalError() }
        guard let setOnInsert = setOnInsert as? [String: DBDataConvertible] else { fatalError() }
        
        do {
            
            let filter = try query.filters.map { try MongoPredicateExpression($0).toBSONDocument() }
            
            var mongoQuery = connection.mongoQuery().collection(query.class).findOneAndUpdate().filter(filter)
            
            var _update = try update.toBSONDocument()
            
            if !setOnInsert.isEmpty {
                _update["$setOnInsert"] = try BSON(setOnInsert.mapValues { try BSON($0.toDBData()) })
            }
            
            mongoQuery = mongoQuery.update(_update)
            mongoQuery = mongoQuery.upsert(true)
            
            switch query.returning {
            case .before: mongoQuery = mongoQuery.returnDocument(.before)
            case .after: mongoQuery = mongoQuery.returnDocument(.after)
            }
            
            if !query.sort.isEmpty {
                mongoQuery = mongoQuery.sort(query.sort.mapValues(DBMongoSortOrder.init))
            }
            
            if !query.includes.isEmpty {
                let projection = Dictionary(uniqueKeysWithValues: query.includes.map { ($0, 1) })
                mongoQuery = mongoQuery.projection(BSONDocument(projection))
            }
            
            return mongoQuery.execute().map { $0.map { _DBObject(class: query.class, object: $0) } }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func findOneAndDelete(_ query: _DBQuery) -> EventLoopFuture<_DBObject?> {
        
        do {
            
            let filter = try query.filters.map { try MongoPredicateExpression($0).toBSONDocument() }
            
            var mongoQuery = connection.mongoQuery().collection(query.class).findOneAndDelete().filter(filter)
            
            if !query.sort.isEmpty {
                mongoQuery = mongoQuery.sort(query.sort.mapValues(DBMongoSortOrder.init))
            }
            
            if !query.includes.isEmpty {
                let projection = Dictionary(uniqueKeysWithValues: query.includes.map { ($0, 1) })
                mongoQuery = mongoQuery.projection(BSONDocument(projection))
            }
            
            return mongoQuery.execute().map { $0.map { _DBObject(class: query.class, object: $0) } }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
    
    func insert<Data>(_ class: String, _ data: [String: Data]) -> EventLoopFuture<(_DBObject, Bool)?> {
        
        guard let data = data as? [String: DBData] else { fatalError() }
        
        do {
            
            return try connection.mongoQuery().collection(`class`)
                .insertOne().value(BSONDocument(data))
                .execute().map { $0.map { (_DBObject(class: `class`, object: ["_id": $0.insertedID]), false) }  }
            
        } catch {
            
            return connection.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
}

extension _DBObject {
    
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
    
    fileprivate init(_ expression: DBQueryPredicateExpression) throws {
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
            
        case let .matching(lhs, rhs): self = try .matching(MongoPredicateValue(lhs), MongoPredicateValue(rhs))
        case let .startsWith(value, pattern, options): self = try .startsWith(MongoPredicateValue(value), pattern, options: options)
        case let .endsWith(value, pattern, options): self = try .endsWith(MongoPredicateValue(value), pattern, options: options)
        case let .contains(value, pattern, options): self = try .contains(MongoPredicateValue(value), pattern, options: options)
        case let .and(list): self = try .and(list.map(MongoPredicateExpression.init))
        case let .or(list): self = try .or(list.map(MongoPredicateExpression.init))
        default: throw Database.Error.invalidExpression
        }
    }
}

extension MongoPredicateValue {
    
    fileprivate init(_ value: DBQueryPredicateValue) throws {
        switch value {
        case .objectId: self = .key("_id")
        case let .key(key): self = .key(key)
        case let .value(value): self = try .value(BSON(value.toDBData()))
        }
    }
}

extension DBMongoSortOrder {
    
    fileprivate init(_ order: DBQuerySortOrder) {
        switch order {
        case .ascending: self = .ascending
        case .descending: self = .descending
        }
    }
}

extension MongoDBDriver.Connection: DBQueryLauncherProvider {
    
    var _launcher: Any {
        return QueryLauncher(connection: self)
    }
}
