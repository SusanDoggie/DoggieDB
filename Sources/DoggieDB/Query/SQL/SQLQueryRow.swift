//
//  SQLQueryRow.swift
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

protocol DBRowConvertable {
    
    var count: Int { get }
    
    var keys: [String] { get }
    
    func contains(column: String) -> Bool
    
    func value(_ column: String) -> DBData?
}

public struct SQLQueryRow {
    
    let row: DBRowConvertable
    
    init<C: DBRowConvertable>(_ row: C) {
        self.row = row
    }
}

extension SQLQueryRow: CustomStringConvertible {
    
    public var description: String {
        var dict: [String: DBData] = [:]
        for key in row.keys {
            dict[key] = row.value(key)
        }
        return "\(dict)"
    }
}

extension SQLQueryRow {
    
    public var count: Int {
        return self.row.count
    }
    
    public var keys: [String] {
        return self.row.keys
    }
    
    public func contains(column: String) -> Bool {
        return self.row.contains(column: column)
    }
    
    public subscript(_ column: String) -> DBData? {
        return self.row.value(column)
    }
    
    public func decode<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        return try self.row.value(key)?.decode(type)
    }
}

extension BSONDocument {
    
    public init(_ row: SQLQueryRow) throws {
        self.init()
        for key in row.keys {
            self[key] = try row[key].map { try BSON($0) } ?? .undefined
        }
    }
}

extension DBData {
    
    public init(_ row: SQLQueryRow) {
        var dict: [String: DBData] = [:]
        for key in row.keys {
            dict[key] = row[key] ?? DBData(nilLiteral: ())
        }
        self.init(dict)
    }
}