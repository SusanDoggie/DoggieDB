//
//  DBMongoConnectionProtocol.swift
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

import MongoSwift

protocol DBMongoConnectionProtocol: DBConnection {
    
    var database: String? { get }
    
    var subscribers: MongoDBDriver.Subscribers { get }
    
    func _database() -> MongoDatabase?
    
    func _bind(to eventLoop: EventLoop) -> DBMongoConnectionProtocol
    
    func withSession<T>(
        options: ClientSessionOptions?,
        _ sessionBody: (SessionBoundConnection) async throws -> T
    ) async throws -> T
}

extension DBMongoConnectionProtocol {
    
    func bind(to eventLoop: EventLoop) -> DBConnection {
        return self._bind(to: eventLoop)
    }
}

extension ClientSession {
    
    private func _withTransaction<T>(
        _ options: DBTransactionOptions,
        _ transactionBody: () async throws -> T
    ) async throws -> T {
        
        var _options = TransactionOptions(writeConcern: .majority)
        switch options.mode {
        case .default: _options.readConcern = .serverDefault
        case .committed: _options.readConcern = .majority
        case .repeatable: _options.readConcern = .majority
        case .serializable: _options.readConcern = .majority
        }
        
        try await self.startTransaction(options: _options).get()
        
        do {
            
            let result = try await transactionBody()
            
            try await self.commitTransaction().get()
            
            return result
            
        } catch {
            
            try await self.abortTransaction().get()
            
            throw error
        }
    }
    
    public func withTransaction<T>(
        _ options: DBTransactionOptions,
        _ transactionBody: () async throws -> T
    ) async throws -> T {
        
        guard options.retryOnConflict else { return try await self._withTransaction(options, transactionBody) }
        
        do {
            
            return try await self._withTransaction(options, transactionBody)
            
        } catch let error as MongoError.CommandError {
            
            if error.code == 112 && error.codeName == "WriteConflict" {
                return try await self.withTransaction(options, transactionBody)
            }
            
            throw error
        }
    }
}

extension DBMongoConnectionProtocol {
    
    public func withTransaction<T>(
        _ options: DBTransactionOptions,
        _ transactionBody: (DBConnection) async throws -> T
    ) async throws -> T {
        
        return try await self.withMongoSession(options: nil) { connection in
            
            guard let connection = connection as? SessionBoundConnection else { fatalError("unknown error") }
            
            return try await connection.session.withTransaction(options) { try await transactionBody(connection) }
        }
    }
}
