//
//  DBQueryLauncher.swift
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

protocol DBQueryLauncher {
    
    func count(_ query: DBFindExpression) -> EventLoopFuture<Int>
    
    func find(_ query: DBFindExpression) -> EventLoopFuture<[DBObject]>
    
    func find(_ query: DBFindExpression, forEach: @escaping (DBObject) throws -> Void) -> EventLoopFuture<Void>
    
    func findAndDelete(_ query: DBFindExpression) -> EventLoopFuture<Int?>
    
    func findOneAndUpdate(_ query: DBFindOneExpression, _ update: [String: DBUpdateOption]) -> EventLoopFuture<DBObject?>
    
    func findOneAndUpsert(_ query: DBFindOneExpression, _ update: [String : DBUpdateOption], _ setOnInsert: [String : DBDataConvertible]) -> EventLoopFuture<DBObject?>
    
    func findOneAndDelete(_ query: DBFindOneExpression) -> EventLoopFuture<DBObject?>
    
    func insert<Data>(_ class: String, _ data: [String: Data]) -> EventLoopFuture<DBObject?>
}

extension DBConnection {
    
    var launcher: DBQueryLauncher? {
        
        if let connection = self as? MongoDBDriver.Connection {
            return MongoQueryLauncher(connection: connection)
        }
        
        if let connection = self as? DBSQLConnection {
            return SQLQueryLauncher(connection: connection)
        }
        
        if let connection = self as? DBSQLTransactionConnection {
            return SQLQueryLauncher(connection: connection.base)
        }
        
        return nil
    }
}
