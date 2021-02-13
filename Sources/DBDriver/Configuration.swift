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
        
        public var tlsConfiguration: TLSConfiguration?
        
        public init(
            socketAddress: SocketAddress,
            username: String? = nil,
            password: String? = nil,
            database: String? = nil,
            tlsConfiguration: TLSConfiguration? = nil
        ) {
            self.socketAddress = socketAddress
            self.username = username
            self.database = database
            self.password = password
            self.tlsConfiguration = tlsConfiguration
        }
        
        public init(
            unixDomainSocketPath: String,
            username: String? = nil,
            password: String? = nil,
            database: String? = nil
        ) throws {
            self.socketAddress = try .init(unixDomainSocketPath: unixDomainSocketPath)
            self.username = username
            self.password = password
            self.database = database
            self.tlsConfiguration = nil
        }
        
        public init(
            hostname: String,
            port: Int,
            username: String? = nil,
            password: String? = nil,
            database: String? = nil,
            tlsConfiguration: TLSConfiguration? = nil
        ) throws {
            self.socketAddress = try .makeAddressResolvingHost(hostname, port: port)
            self.username = username
            self.database = database
            self.password = password
            self.tlsConfiguration = tlsConfiguration
        }
    }
}
