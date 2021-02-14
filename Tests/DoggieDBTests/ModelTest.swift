//
//  ModelTest.swift
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

import DoggieDB
import XCTest

struct Contact: DBModel {
    
    static let schema: String = "Contact"
    
    @Field(default: .random)
    var id: UUID
    
    @Field(name: "nick_name")
    var name: String
    
    @Field(default: .now)
    var createdAt: Date
    
    @Field(default: .now)
    var updatedAt: Date
    
    @Field
    var deletedAt: Date?
    
    init() {}
    
    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

struct Star: DBModel {
    
    static let schema: String = "Star"
    
    @Field(default: .random)
    var id: UUID
    
    @Children(parentKey: \.$star)
    var planets: [Planet]
}

struct Planet: DBModel {
    
    static let schema: String = "Planet"
    
    @Field(default: .random)
    var id: UUID
    
    @Parent
    var star: Star?
    
    @Siblings(through: PlanetTag.self, from: \.$planet, to: \.$tag)
    var tags: [Tag]
}

struct PlanetTag: DBModel {
    
    static let schema = "PlanetTag"
    
    @Field(default: .random)
    var id: UUID
    
    @Parent
    var planet: Planet
    
    @Parent
    var tag: Tag
}

struct Tag: DBModel {
    
    static let schema = "Tag"
    
    @Field(default: .random)
    var id: UUID
    
    @Siblings(through: PlanetTag.self, from: \.$tag, to: \.$planet)
    var planets: [Planet]
}

class ModelTest: XCTestCase {
    
    func testModel() {
        
        let contact = Contact(id: UUID(), name: "John")
        
        let fields = contact._$fields
        
        XCTAssertEqual(fields.count, 5)
        
        XCTAssertEqual(fields.first { $0.name == "id" }?.value, DBData(contact.id))
        XCTAssertEqual(fields.first { $0.name == "nick_name" }?.value, DBData(contact.name))
        
        XCTAssertEqual(fields.first { $0.name == "id" }?.isOptional, false)
        XCTAssertEqual(fields.first { $0.name == "nick_name" }?.isOptional, false)
        XCTAssertEqual(fields.first { $0.name == "createdAt" }?.isOptional, false)
        XCTAssertEqual(fields.first { $0.name == "updatedAt" }?.isOptional, false)
        XCTAssertEqual(fields.first { $0.name == "deletedAt" }?.isOptional, true)
        
    }
    
    func testParentRelation() {
        
        let planet = Planet()
        
        let fields = planet._$fields
        
        XCTAssertNotNil(fields.first { $0.name == "star" })
    }
}
