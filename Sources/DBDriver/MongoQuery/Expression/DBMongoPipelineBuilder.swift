//
//  DBMongoPipelineBuilder.swift
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

import MongoSwift

public protocol DBMongoPipelineBuilder {
    
    var pipeline: [BSONDocument] { get set }
    
    func pipeline(_ pipeline: [BSONDocument]) -> Self
    
}

extension DBMongoPipelineBuilder {
    
    public func _appended(_ pipeline: BSONDocument) -> Self {
        var result = self
        result.pipeline.append(pipeline)
        return result
    }
}

extension DBMongoPipelineBuilder {
    
    public func count(_ name: String) -> Self {
        return self._appended(["$count": .string(name)])
    }
    
    public func limit(_ n: Int) -> Self {
        return self._appended(["$limit": .int64(Int64(n))])
    }
    
    public func skip(_ n: Int) -> Self {
        return self._appended(["$skip": .int64(Int64(n))])
    }
}

extension DBMongoPipelineBuilder {
    
    public func unwind(_ path: String, includeArrayIndex: String? = nil, preserveNullAndEmptyArrays: Bool? = nil) -> Self {
        var options: BSONDocument = ["path": .string(path)]
        if let includeArrayIndex = includeArrayIndex {
            options["includeArrayIndex"] = .string(includeArrayIndex)
        }
        if let preserveNullAndEmptyArrays = preserveNullAndEmptyArrays {
            options["preserveNullAndEmptyArrays"] = .bool(preserveNullAndEmptyArrays)
        }
        return self._appended(["$unwind": .document(options)])
    }
}

extension DBMongoPipelineBuilder {
    
    public func out(_ collection: String, database: String? = nil) -> Self {
        var options: BSONDocument = ["coll": .string(collection)]
        if let database = database {
            options["db"] = .string(database)
        }
        return self._appended(["$out": .document(options)])
    }
}
