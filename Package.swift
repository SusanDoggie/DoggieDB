// swift-tools-version:5.3
//
//  Package.swift
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

import PackageDescription

let package = Package(
    name: "DoggieDB",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "DoggieDB", targets: ["DoggieDB"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SusanDoggie/Doggie.git", .branch("main")),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/mongodb/mongo-swift-driver.git", from: "1.0.0"),
        .package(url: "https://gitlab.com/mordil/RediStack.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/sqlite-nio.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/mysql-nio.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "DoggieDB",
            dependencies: [
                .product(name: "DoggieCore", package: "Doggie"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "MongoSwift", package: "mongo-swift-driver"),
                .product(name: "RediStack", package: "RediStack"),
                .product(name: "SQLiteNIO", package: "sqlite-nio"),
                .product(name: "MySQLNIO", package: "mysql-nio"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
            ]
        ),
    ]
)
