// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ETPattern",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "ETPatternCore",
            targets: ["ETPatternCore"]
        ),
    ],
    dependencies: [
        // Add external dependencies here when needed
    ],
    targets: [
        .target(
            name: "ETPatternCore",
            dependencies: [],
            path: "Sources/ETPatternCore",
            exclude: [
                // Exclude files that require UIKit/CoreData when building for macOS
            ]
        ),
        .testTarget(
            name: "ETPatternTests",
            dependencies: ["ETPatternCore"]
        ),
    ]
)