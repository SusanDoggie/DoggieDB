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
        .library(name: "DBMongo", targets: ["DBMongo"]),
        .library(name: "DBSQLite", targets: ["DBSQLite"]),
        .library(name: "DBVapor", targets: ["DBVapor"]),
        .executable(name: "DBBrowser", targets: ["DBBrowser"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SusanDoggie/Doggie.git", from: "6.3.0"),
        .package(url: "https://github.com/SusanDoggie/SwiftJS.git", from: "1.2.2"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.27.0"),
        .package(url: "https://github.com/mongodb/swift-bson.git", from: "3.0.0"),
        .package(url: "https://github.com/mongodb/mongo-swift-driver.git", from: "1.1.0"),
        .package(url: "https://gitlab.com/mordil/RediStack.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/sqlite-nio.git", from: "1.1.0"),
        .package(url: "https://github.com/vapor/mysql-nio.git", from: "1.3.0"),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.5.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.44.0"),
    ],
    targets: [
        .target(
            name: "Utils",
            dependencies: [
                .product(name: "DoggieCore", package: "Doggie"),
            ]
        ),
        .target(
            name: "DBDriver",
            dependencies: [
                .target(name: "Utils"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "DoggieCore", package: "Doggie"),
                .product(name: "SwiftBSON", package: "swift-bson"),
                .product(name: "RediStack", package: "RediStack"),
                .product(name: "MySQLNIO", package: "mysql-nio"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
            ]
        ),
        .target(
            name: "DBMongo",
            dependencies: [
                .target(name: "DBDriver"),
                .product(name: "MongoSwift", package: "mongo-swift-driver"),
            ]
        ),
        .target(
            name: "DBSQLite",
            dependencies: [
                .target(name: "Utils"),
                .target(name: "DBDriver"),
                .product(name: "SQLiteNIO", package: "sqlite-nio"),
            ]
        ),
        .target(
            name: "DBFluent",
            dependencies: [
                .target(name: "DBDriver"),
            ]
        ),
        .target(
            name: "DoggieDB",
            dependencies: [
                .target(name: "DBDriver"),
                .target(name: "DBFluent"),
            ]
        ),
        .target(
            name: "DBVapor",
            dependencies: [
                .target(name: "DBDriver"),
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .target(
            name: "DBBrowser",
            dependencies: [
                .target(name: "DoggieDB"),
                .target(name: "DBMongo"),
                .target(name: "DBSQLite"),
                .target(name: "DBVapor"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "SwiftJS", package: "SwiftJS"),
            ],
            exclude: [
                "js",
                "asserts",
            ],
            resources: [
                .copy("Public"),
            ],
            swiftSettings: [
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "DoggieDBTests",
            dependencies: [
                .target(name: "DoggieDB"),
                .target(name: "DBMongo"),
                .target(name: "DBSQLite"),
            ]
        ),
    ]
)
