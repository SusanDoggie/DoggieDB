//
//  Query.swift
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

public struct _DBObject {
    
    public let `class`: String
    
    public let primaryKeys: Set<String>
    
    public let columns: [String: Any]
    
    public init(
        class: String,
        primaryKeys: Set<String>,
        columns: [String: Any]
    ) {
        self.class = `class`
        self.primaryKeys = primaryKeys
        self.columns = columns
    }
}

public struct _DBQuery {
    
    public let `class`: String
    
    public let query: [String: Any]
    
    public init(class: String, query: [String: Any]) {
        self.class = `class`
        self.query = query
    }
    
    public subscript(_ key: String) -> Any? {
        return query[key]
    }
}

public protocol _DBQueryLauncher {
    
    func count(_ query: _DBQuery) -> EventLoopFuture<Int>
    
    func find(_ query: _DBQuery) -> EventLoopFuture<[_DBObject]>
    
    func find(_ query: _DBQuery, forEach: @escaping (_DBObject) -> Void) -> EventLoopFuture<Void>
    
    func find(_ query: _DBQuery, forEach: @escaping (_DBObject) throws -> Void) -> EventLoopFuture<Void>
    
    func findAndDelete(_ query: _DBQuery) -> EventLoopFuture<Int?>
    
    func findOneAndUpdate<Update>(_ query: _DBQuery, _ update: [String: Update]) -> EventLoopFuture<_DBObject?>
    
    func findOneAndUpsert<Update, Data>(_ query: _DBQuery, _ update: [String: Update], _ setOnInsert: [String: Data]) -> EventLoopFuture<_DBObject?>
    
    func findOneAndDelete(_ query: _DBQuery) -> EventLoopFuture<_DBObject?>
    
    func insert<Data>(_ class: String, _ data: [String: Data]) -> EventLoopFuture<(_DBObject, Bool)?>
}
