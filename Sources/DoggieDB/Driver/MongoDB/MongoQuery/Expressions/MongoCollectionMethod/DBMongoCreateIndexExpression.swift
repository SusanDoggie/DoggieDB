//
//  DBMongoCreateIndexExpression.swift
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

import MongoSwift

public struct DBMongoCreateIndexExpression<T: Codable>: DBMongoExpression {
    
    let query: DBMongoCollection<T>
    
    public var model: IndexModel?
    
    public var options: CreateIndexOptions = CreateIndexOptions()
}

extension DBMongoCollectionExpression {
    
    public func createIndex() -> DBMongoCreateIndexExpression<T> {
        return DBMongoCreateIndexExpression(query: query())
    }
}

extension DBMongoCreateIndexExpression {
    
    public func index(_ keys: BSONDocument, options: IndexOptions? = nil) -> Self {
        var result = self
        result.model = IndexModel(keys: keys, options: options)
        return result
    }
    
    public func index(_ model: IndexModel) -> Self {
        var result = self
        result.model = model
        return result
    }
}

extension DBMongoCreateIndexExpression {
    
    public func execute() async throws -> String {
        guard let model = self.model else { fatalError() }
        return try await query.collection.createIndex(model, options: options, session: query.session).get()
    }
}

extension DBMongoCreateIndexExpression {
    
    public func background(_ background: Bool) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.background = background
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func bits(_ bits: Int) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.bits = bits
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func bucketSize(_ bucketSize: Int) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.bucketSize = bucketSize
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func collation(_ collation: BSONDocument) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.collation = collation
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func defaultLanguage(_ defaultLanguage: String) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.defaultLanguage = defaultLanguage
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func expireAfterSeconds(_ expireAfterSeconds: Int) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.expireAfterSeconds = expireAfterSeconds
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func hidden(_ hidden: Bool) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.hidden = hidden
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func languageOverride(_ languageOverride: String) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.languageOverride = languageOverride
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func max(_ max: Double) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.max = max
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func min(_ min: Double) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.min = min
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func name(_ name: String) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.name = name
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func partialFilterExpression(_ partialFilterExpression: BSONDocument) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.partialFilterExpression = partialFilterExpression
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func sparse(_ sparse: Bool) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.sparse = sparse
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func sphereIndexVersion(_ sphereIndexVersion: Int) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.sphereIndexVersion = sphereIndexVersion
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func storageEngine(_ storageEngine: BSONDocument) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.storageEngine = storageEngine
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func textIndexVersion(_ textIndexVersion: Int) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.textIndexVersion = textIndexVersion
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func unique(_ unique: Bool) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.unique = unique
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func version(_ version: Int) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.version = version
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func weights(_ weights: BSONDocument) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.weights = weights
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
    
    public func wildcardProjection(_ wildcardProjection: BSONDocument) -> Self {
        var result = self
        if let model = result.model {
            var options = model.options ?? IndexOptions()
            options.wildcardProjection = wildcardProjection
            result.model = IndexModel(keys: model.keys, options: options)
        }
        return result
    }
}
