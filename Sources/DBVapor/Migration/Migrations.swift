//
//  Migrations.swift
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

public final class Migrations {
    
    struct Item {
        
        var id: DatabaseID?
        var migration: Migration
    }
    
    var storage: [Item]
    var databases: Set<DatabaseID?> { Set(self.storage.map(\.id)) }
    
    public init() {
        self.storage = []
    }
    
    public func add(_ migration: Migration, to id: DatabaseID? = nil) {
        self.storage.append(.init(id: id, migration: migration))
    }
    
    @inlinable
    public func add(_ migrations: Migration..., to id: DatabaseID? = nil) {
        self.add(migrations, to: id)
    }
    
    public func add(_ migrations: [Migration], to id: DatabaseID? = nil) {
        self.storage.append(contentsOf: migrations.map { .init(id: id, migration: $0) })
    }
}
