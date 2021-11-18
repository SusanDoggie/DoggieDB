//
//  DBQuery.swift
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

public protocol DBQueryProtocol {
    
    var connection: DBConnection { get }
}

extension DBQueryProtocol {
    
    public var eventLoopGroup: EventLoopGroup {
        return connection.eventLoopGroup
    }
}

public struct DBQuery {
    
    public let connection: DBConnection
    
    init(connection: DBConnection) {
        self.connection = connection
    }
}

extension DBConnection {
    
    public func query() -> DBQuery {
        return DBQuery(connection: self)
    }
}

extension DBQuery {
    
    public func insert(_ class: String, _ data: [String: DBData]) -> EventLoopFuture<DBObject> {
        
        guard let launcher = connection.launcher else {
            return connection.eventLoopGroup.next().makeFailedFuture(Database.Error.unsupportedOperation)
        }
        
        return launcher.insert(`class`, data).flatMap {
            
            guard let (object, is_complete) = $0 else { return connection.eventLoopGroup.next().makeFailedFuture(Database.Error.unknown) }
            
            if is_complete {
                return connection.eventLoopGroup.next().makeSucceededFuture(DBObject(object))
            }
            
            return DBObject(object).fetch(on: connection)
        }
    }
}
