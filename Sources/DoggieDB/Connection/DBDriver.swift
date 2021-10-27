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

public protocol DBDriverProtocol {
    
    static var defaultPort: Int { get }
    
    static var isThreadBased: Bool { get }
    
    static var sqlDialect: SQLDialect.Type? { get }
    
    static func connect(
        config: Database.Configuration,
        logger: Logger,
        on eventLoopGroup: EventLoopGroup
    ) -> EventLoopFuture<DBConnection>
}

extension DBDriverProtocol {
    
    public static var isThreadBased: Bool {
        return false
    }
    
    public static var sqlDialect: SQLDialect.Type? {
        return nil
    }
}

public struct DBDriver: Hashable {
    
    public var rawValue: DBDriverProtocol.Type
    
    public init(rawValue: DBDriverProtocol.Type) {
        self.rawValue = rawValue
    }
}

extension DBDriver {
    
    public var isThreadBased: Bool {
        return rawValue.isThreadBased
    }
    
    public var defaultPort: Int {
        return rawValue.defaultPort
    }
    
    public var sqlDialect: SQLDialect.Type? {
        return rawValue.sqlDialect
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
    
    public static let postgreSQL = DBDriver(rawValue: PostgreSQLDriver.self)
    
    public static let redis = DBDriver(rawValue: RedisDriver.self)
}
