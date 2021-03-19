//
//  DBConnectionSource.swift
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

public struct DBConnectionSource {
    
    public let driver: DBDriver
    
    public let configuration: Database.Configuration
    
    public init(driver: DBDriver, configuration: Database.Configuration) {
        self.driver = driver
        self.configuration = configuration
    }
}

extension DBConnectionSource {
    
    public init(url: URL) throws {
        guard let url = URLComponents(url: url, resolvingAgainstBaseURL: true) else { throw Database.Error.invalidURL }
        try self.init(url: url)
    }
    
    public init(url: URLComponents) throws {
        self.driver = try url.driver()
        self.configuration = try Database.Configuration(url: url)
    }
}

extension DBConnectionSource {
    
    public func makeConnection(
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<DBConnection> {
        return Database.connect(config: configuration, logger: logger, driver: driver, on: eventLoop)
    }
}
