//
//  Configuration.swift
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

extension Database {
    
    public struct Configuration {
        
        public let socketAddress: [SocketAddress]
        
        public var user: String?
        public var password: String?
        public var database: String?
        
        public var queryItems: [URLQueryItem]?
        
        public var tlsConfiguration: TLSConfiguration?
        
        public init(
            socketAddress: SocketAddress,
            user: String? = nil,
            password: String? = nil,
            database: String? = nil,
            queryItems: [URLQueryItem]? = nil,
            tlsConfiguration: TLSConfiguration? = nil
        ) {
            self.socketAddress = [socketAddress]
            self.user = user
            self.password = password
            self.database = database
            self.queryItems = queryItems
            self.tlsConfiguration = tlsConfiguration
        }
        
        public init(
            socketAddress address: SocketAddress,
            _ address2: SocketAddress,
            _ res: SocketAddress...,
            user: String? = nil,
            password: String? = nil,
            database: String? = nil,
            queryItems: [URLQueryItem]? = nil,
            tlsConfiguration: TLSConfiguration? = nil
        ) {
            self.socketAddress = [address, address2] + res
            self.user = user
            self.password = password
            self.database = database
            self.queryItems = queryItems
            self.tlsConfiguration = tlsConfiguration
        }
        
        public init(
            socketAddress: [SocketAddress],
            user: String? = nil,
            password: String? = nil,
            database: String? = nil,
            queryItems: [URLQueryItem]? = nil,
            tlsConfiguration: TLSConfiguration? = nil
        ) {
            self.socketAddress = socketAddress
            self.user = user
            self.password = password
            self.database = database
            self.queryItems = queryItems
            self.tlsConfiguration = tlsConfiguration
        }
        
        public init(
            unixDomainSocketPath: String,
            user: String? = nil,
            password: String? = nil,
            database: String? = nil,
            queryItems: [URLQueryItem]? = nil
        ) throws {
            self.socketAddress = try [.init(unixDomainSocketPath: unixDomainSocketPath)]
            self.user = user
            self.password = password
            self.database = database
            self.queryItems = queryItems
            self.tlsConfiguration = nil
        }
        
        public init(
            hostname: String,
            port: Int,
            user: String? = nil,
            password: String? = nil,
            database: String? = nil,
            queryItems: [URLQueryItem]? = nil,
            tlsConfiguration: TLSConfiguration? = nil
        ) throws {
            self.socketAddress = try [.makeAddressResolvingHost(hostname, port: port)]
            self.user = user
            self.password = password
            self.database = database
            self.queryItems = queryItems
            self.tlsConfiguration = tlsConfiguration
        }
    }
}

extension URL {
    
    public func driver() throws -> DBDriver {
        switch scheme {
        case "redis": return .redis
        case "postgres": return .postgreSQL
        case "mongodb": return .mongoDB
        default: throw Database.Error.invalidURL
        }
    }
}

extension URLComponents {
    
    public func driver() throws -> DBDriver {
        switch scheme {
        case "redis": return .redis
        case "postgres": return .postgreSQL
        case "mongodb": return .mongoDB
        default: throw Database.Error.invalidURL
        }
    }
}

extension URL {
    
    var multipleHosts: [(host: String, port: Int?)] {
        
        guard let root = URL(string: "/", relativeTo: self)?.absoluteURL else { return [] }
        guard var _str = URL(string: "/", relativeTo: self)?.absoluteString else { return [] }
        
        if _str.last == "/" {
            _str.removeLast()
        }
        
        if let scheme = root.scheme {
            guard _str.starts(with: "\(scheme)://") else { return [] }
            _str.removeFirst("\(scheme)://".count)
        } else {
            guard _str.starts(with: "//") else { return [] }
            _str.removeFirst(2)
        }
        
        var components = URLComponents()
        components.user = root.user
        components.password = root.password
        
        if let user = components.percentEncodedUser, let password = components.percentEncodedPassword {
            guard _str.starts(with: "\(user):\(password)@") else { return [] }
            _str.removeFirst("\(user):\(password)@".count)
        } else {
            guard root.user == nil && root.password == nil else { return [] }
        }
        
        var hosts: [(String, Int?)] = []
        
        for part in _str.split(separator: ",") {
            
            guard let url = URLComponents(string: "//\(part)") else { return [] }
            guard let host = url.host else { return [] }
            hosts.append((host, url.port))
        }
        
        return hosts
    }
}

extension Database.Configuration {
    
    public init(string: String) throws {
        guard let url = URL(string: string) else { throw Database.Error.invalidURL }
        try self.init(url: url)
    }
    
    public init(url: URL) throws {
        
        if let url = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            try self.init(url: url)
            return
        }
        
        let driver = try url.driver()
        var tlsConfiguration: TLSConfiguration?
        
        let socketAddress = try url.multipleHosts.map { try SocketAddress.makeAddressResolvingHost($0.host, port: $0.port ?? driver.rawValue.defaultPort) }
        
        guard !socketAddress.isEmpty else { throw Database.Error.invalidURL }
        
        var components = URLComponents()
        components.query = url.query
        
        let enable_ssl = components.queryItems?.last { $0.name == "ssl" }?.value
        let ssl_mode = components.queryItems?.last { $0.name == "sslmode" }?.value
        
        if enable_ssl == "true" {
            
            let certificateVerification: CertificateVerification
            
            switch ssl_mode {
            case "none": certificateVerification = .none
            case "require": certificateVerification = .noHostnameVerification
            case "verify-full": certificateVerification = .fullVerification
            default: certificateVerification = .fullVerification
            }
            
            tlsConfiguration = TLSConfiguration.clientDefault
            tlsConfiguration?.certificateVerification = certificateVerification
            
        } else {
            
            tlsConfiguration = nil
        }
        
        let lastPathComponent = url.lastPathComponent
        
        self.init(
            socketAddress: socketAddress,
            user: url.user,
            password: url.password,
            database: lastPathComponent == "/" ? nil : lastPathComponent,
            queryItems: components.queryItems,
            tlsConfiguration: tlsConfiguration
        )
    }
    
    public init(url: URLComponents) throws {
        
        guard let hostname = url.host else { throw Database.Error.invalidURL }
        
        let driver = try url.driver()
        var tlsConfiguration: TLSConfiguration?
        
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
            
            tlsConfiguration = TLSConfiguration.clientDefault
            tlsConfiguration?.certificateVerification = certificateVerification
            
        } else {
            
            tlsConfiguration = nil
        }
        
        let lastPathComponent = url.lastPathComponent
        
        try self.init(
            hostname: hostname,
            port: url.port ?? driver.rawValue.defaultPort,
            user: url.user,
            password: url.password,
            database: lastPathComponent == "/" ? nil : lastPathComponent,
            queryItems: url.queryItems,
            tlsConfiguration: tlsConfiguration
        )
    }
}
