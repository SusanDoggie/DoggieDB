//
//  DatabaseDriver.swift
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

protocol DBDriverProtocol {
    
    static var defaultPort: Int { get }
    
    static func connect(
        config: Database.Configuration,
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<DBConnection>
}

public struct DBDriver: Hashable {
    
    var rawValue: DBDriverProtocol.Type
    
    init(rawValue: DBDriverProtocol.Type) {
        self.rawValue = rawValue
    }
}

extension DBDriver {
    
    public var defaultPort: Int {
        return rawValue.defaultPort
    }
}

extension DBDriver {
    
    public var identifier: ObjectIdentifier {
        return ObjectIdentifier(rawValue)
    }
    
    public static func == (lhs: DBDriver, rhs: DBDriver) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

extension DBDriver {
    
    public static let mongoDB = DBDriver(rawValue: MongoDBDriver.self)
    
    public static let mySQL = DBDriver(rawValue: MySQLDriver.self)
    
    public static let postgreSQL = DBDriver(rawValue: PostgreSQLDriver.self)
    
    public static let redis = DBDriver(rawValue: RedisDriver.self)
    
    public static let sqlite = DBDriver(rawValue: SQLiteDriver.self)
}
