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
    
    private let _id: Set<String>
    
    private let _columns: [String: DBData]
    
    private var _updates: [String: DBQueryUpdateOperation]
}

extension DBObject {
    
    public init(class: String, object: BSONDocument) {
        
        var _columns: [String: DBData] = [:]
        for (key, value) in object {
            guard let value = try? DBData(value) else { continue }
            _columns[key] = value
        }
        
        self.class = `class`
        self._id = ["_id"]
        self._columns = _columns
        self._updates = [:]
    }
    
    init(table: String, object: DBQueryRow) {
        
        var _columns: [String: DBData] = [:]
        for key in object.keys {
            guard let value = object[key] else { continue }
            _columns[key] = value
        }
        
        self.class = table
        self._id = []
        self._columns = _columns
        self._updates = [:]
    }
}

extension DBObject {
    
    public var id: DBData? {
        if _id.count == 1, let _id = _id.first {
            return _columns[_id]
        }
        return DBData(self._columns.filter { _id.contains($0.key) })
    }
}

extension DBObject {
    
    public var keys: Set<String> {
        return Set(_columns.keys).union(_updates.keys)
    }
    
    public subscript(column: String) -> DBData? {
        get {
            if let value = _updates[column]?.value {
                return value == nil ? nil : value
            }
            return _columns[column]
        }
        set {
            guard !_id.contains(column) else { return }
            _updates[column] = .set(newValue ?? nil)
        }
    }
}
