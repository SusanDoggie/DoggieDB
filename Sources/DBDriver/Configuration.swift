//
//  Configuration.swift
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

extension Database {
    
    public struct Configuration {
        
        public var socketAddress: SocketAddress
        
        public var username: String?
        public var password: String?
        public var database: String?
        
        public var queryItems: [URLQueryItem]?
        
        public var tlsConfiguration: TLSConfiguration?
        
        public init(
            socketAddress: SocketAddress,
            username: String? = nil,
            password: String? = nil,
            database: String? = nil,
            queryItems: [URLQueryItem]? = nil,
            tlsConfiguration: TLSConfiguration? = nil
        ) {
            self.socketAddress = socketAddress
            self.username = username
            self.password = password
            self.database = database
            self.queryItems = queryItems
            self.tlsConfiguration = tlsConfiguration
        }
        
        public init(
            unixDomainSocketPath: String,
            username: String? = nil,
            password: String? = nil,
            database: String? = nil,
            queryItems: [URLQueryItem]? = nil
        ) throws {
            self.socketAddress = try .init(unixDomainSocketPath: unixDomainSocketPath)
            self.username = username
            self.password = password
            self.database = database
            self.queryItems = queryItems
            self.tlsConfiguration = nil
        }
        
        public init(
            hostname: String,
            port: Int,
            username: String? = nil,
            password: String? = nil,
            database: String? = nil,
            queryItems: [URLQueryItem]? = nil,
            tlsConfiguration: TLSConfiguration? = nil
        ) throws {
            self.socketAddress = try .makeAddressResolvingHost(hostname, port: port)
            self.username = username
            self.password = password
            self.database = database
            self.queryItems = queryItems
            self.tlsConfiguration = tlsConfiguration
        }
    }
}

extension URLComponents {
    
    func driver() throws -> DBDriver {
        switch scheme {
        case "redis": return .redis
        case "mysql": return .mySQL
        case "postgres": return .postgreSQL
        case "mongodb": return .mongoDB
        default: throw Database.Error.invalidURL
        }
    }
}

extension Database.Configuration {
    
    public init(url: URL) throws {
        guard let url = URLComponents(url: url, resolvingAgainstBaseURL: true) else { throw Database.Error.invalidURL }
        try self.init(url: url)
    }
    
    public init(url: URLComponents) throws {
        
        guard let hostname = url.host else { throw Database.Error.invalidURL }
        
        let driver = try url.driver()
        let tlsConfiguration: TLSConfiguration?
        
        let enable_ssl = url.queryItems?.last { $0.name == "ssl" }?.value
        let ssl_mode = url.queryItems?.last { $0.name == "sslmode" }?.value
        
        if enable_ssl == "true" {
            
            let certificateVerification: CertificateVerification
            
            switch ssl_mode {
            case "none": certificateVerification = .none
            case "require": certificateVerification = .noHostnameVerification
            case "verify-full": certificateVerification = .fullVerification
            default: certificateVerification = .fullVerification
            }
            
            tlsConfiguration = .forClient(certificateVerification: certificateVerification)
            
        } else {
            
            tlsConfiguration = nil
        }
        
        let lastPathComponent = url.lastPathComponent
        
        try self.init(
            hostname: hostname,
            port: url.port ?? driver.rawValue.defaultPort,
            username: url.user,
            password: url.password,
            database: lastPathComponent == "/" ? nil : lastPathComponent,
            queryItems: url.queryItems,
            tlsConfiguration: tlsConfiguration
        )
    }
}
