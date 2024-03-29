//
//  DBConnectionSource.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2024 Susan Cheng. All rights reserved.
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
    
    public var maxConnectionsPerEventLoop: Int
    
    public var requestTimeout: TimeAmount
    
    public init(
        driver: DBDriver,
        configuration: Database.Configuration,
        maxConnectionsPerEventLoop: Int = 1,
        requestTimeout: TimeAmount = .seconds(10)
    ) {
        self.driver = driver
        self.configuration = configuration
        self.maxConnectionsPerEventLoop = maxConnectionsPerEventLoop
        self.requestTimeout = requestTimeout
    }
}

extension DBConnectionSource {
    
    public init(
        string: String,
        maxConnectionsPerEventLoop: Int = 1,
        requestTimeout: TimeAmount = .seconds(10)
    ) throws {
        guard let url = URL(string: string) else { throw Database.Error.invalidURL }
        self.driver = try url.driver()
        self.configuration = try Database.Configuration(url: url)
        self.maxConnectionsPerEventLoop = maxConnectionsPerEventLoop
        self.requestTimeout = requestTimeout
    }
    
    public init(
        url: URL,
        maxConnectionsPerEventLoop: Int = 1,
        requestTimeout: TimeAmount = .seconds(10)
    ) throws {
        self.driver = try url.driver()
        self.configuration = try Database.Configuration(url: url)
        self.maxConnectionsPerEventLoop = maxConnectionsPerEventLoop
        self.requestTimeout = requestTimeout
    }
    
    public init(
        url: URLComponents,
        maxConnectionsPerEventLoop: Int = 1,
        requestTimeout: TimeAmount = .seconds(10)
    ) throws {
        self.driver = try url.driver()
        self.configuration = try Database.Configuration(url: url)
        self.maxConnectionsPerEventLoop = maxConnectionsPerEventLoop
        self.requestTimeout = requestTimeout
    }
}
