// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Copyright 2020 Thumbtack, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import PackageDescription

let package = Package(
    name: "SwiftTypeAdoptionReporter",
    platforms: [
        SupportedPlatform.macOS(.v11),
    ],
    products: [
        .executable(
            name: "star",
            targets: [
                "star",
            ]
        ),
        .library(
            name: "STARLib",
            type: .static,
            targets: [
                "STARLib",
            ]
        ),
    ],
    dependencies: [
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", .upToNextMajor(from: "0.50500.0")), // Minor releases correspond to Swift versions (i.e., use 0.50x000.y with Swift 5.x)
        .package(name: "swift-argument-parser", url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "0.2.0")),
    ],
    targets: [
        .executableTarget(
            name: "star",
            dependencies: ["STARLib"]
        ),
        .target(
            name: "STARLib",
            dependencies: [
                "SwiftSyntax",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "STARLibTests",
            dependencies: ["STARLib"]
        ),
    ]
)
