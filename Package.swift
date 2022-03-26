// swift-tools-version:5.6
//
//  Package.swift
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

import PackageDescription

let package = Package(
    name: "DoggieDB",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "DoggieDB", targets: ["DoggieDB"]),
        .library(name: "DBVapor", targets: ["DBVapor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.0.1"),
        .package(url: "https://github.com/SusanDoggie/Doggie.git", from: "6.6.20"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.38.0"),
        .package(url: "https://github.com/mongodb/swift-bson.git", from: "3.0.2"),
        .package(url: "https://github.com/mongodb/mongo-swift-driver.git", from: "1.2.0"),
        .package(url: "https://gitlab.com/mordil/RediStack.git", from: "1.2.1"),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.8.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.55.2"),
    ],
    targets: [
        .target(
            name: "DoggieDB",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "DoggieCore", package: "Doggie"),
                .product(name: "SwiftBSON", package: "swift-bson"),
                .product(name: "RediStack", package: "RediStack"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "MongoSwift", package: "mongo-swift-driver"),
            ]
        ),
        .target(
            name: "DBVapor",
            dependencies: [
                .target(name: "DoggieDB"),
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .testTarget(
            name: "DoggieDBTests",
            dependencies: [
                .target(name: "DoggieDB"),
            ]
        ),
    ]
)
