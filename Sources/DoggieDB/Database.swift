//
//  Database.swift
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

public struct Database: Hashable {
    
    var rawValue: DatabaseDriver.Type
    
    init(rawValue: DatabaseDriver.Type) {
        self.rawValue = rawValue
    }
}

extension Database {
    
    public var identifier: ObjectIdentifier {
        return ObjectIdentifier(rawValue)
    }
    
    public static func == (lhs: Database, rhs: Database) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

extension Database {
    
    public static let mongoDB = Database(rawValue: MongoDBDriver.self)
    
    public static let mySQL = Database(rawValue: MySQLDriver.self)
    
    public static let postgreSQL = Database(rawValue: PostgreSQLDriver.self)
    
    public static let redis = Database(rawValue: RedisDriver.self)
    
    public static let sqlite = Database(rawValue: SQLiteDriver.self)
}
