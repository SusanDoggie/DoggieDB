//
//  DBSQLTransactionConnection.swift
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

class DBSQLTransactionConnection: DBConnection {
    
    let base: DBSQLConnection
    
    let counter: Int
    
    init(base: DBSQLConnection, counter: Int) {
        self.base = base
        self.counter = counter
    }
}

extension DBSQLTransactionConnection {
    
    var driver: DBDriver {
        return base.driver
    }
    
    var logger: Logger {
        return base.logger
    }
    
    var eventLoopGroup: EventLoopGroup {
        return base.eventLoopGroup
    }
    
    var isClosed: Bool {
        return base.isClosed
    }
}

extension DBSQLTransactionConnection {
    
    func close() -> EventLoopFuture<Void> {
        return base.close()
    }
}

extension DBSQLTransactionConnection {
    
    func version() -> EventLoopFuture<String> {
        return base.version()
    }
    
    func databases() -> EventLoopFuture<[String]> {
        return base.databases()
    }
}

extension DBSQLTransactionConnection {
    
    func withTransaction<T>(
        _ transactionBody: @escaping (DBConnection) throws -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        
        let counter = self.counter
        
        let transaction = self.base.savepoint("savepoint_\(counter)")
        let promise = transaction.eventLoop.makePromise(of: T.self)
        
        return transaction.flatMap {
            
            do {
                
                let bodyFuture = try transactionBody(DBSQLTransactionConnection(base: self.base, counter: counter + 1))
                
                bodyFuture.flatMap { _ in
                    self.base.releaseSavepoint("savepoint_\(counter)")
                }.flatMapError { _ in
                    self.base.rollbackSavepoint("savepoint_\(counter)")
                }.whenComplete { _ in
                    promise.completeWith(bodyFuture)
                }
                
            } catch {
                
                self.base.rollbackSavepoint("savepoint_\(counter)").whenComplete { _ in
                    promise.fail(error)
                }
            }
            
            return promise.futureResult
        }
    }
}

#if compiler(>=5.5.2) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension DBSQLTransactionConnection {
    
    func withTransaction<T>(
        _ transactionBody: (DBConnection) async throws -> T
    ) async throws -> T {
        
        try await self.base.savepoint("savepoint_\(counter)")
        
        do {
            
            let result = try await transactionBody(DBSQLTransactionConnection(base: self.base, counter: counter + 1))
            
            try await self.base.releaseSavepoint("savepoint_\(counter)")
            
            return result
            
        } catch {
            
            try await self.base.rollbackSavepoint("savepoint_\(counter)")
            
            throw error
        }
    }
}

#endif
