// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Reactor",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "Reactor",
            targets: ["Reactor"]
        ),
    ],
    dependencies: [
        // No external dependencies needed - using AppKit and Foundation
    ],
    targets: [
        .executableTarget(
            name: "Reactor",
            dependencies: [],
            path: "Sources/Reactor",
            exclude: ["Models/Notifications.swift"]
        ),
    ]
)