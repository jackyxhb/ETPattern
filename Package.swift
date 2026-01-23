// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ETPattern",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(name: "ETPatternModels", targets: ["ETPatternModels"]),
        .library(name: "ETPatternCore", targets: ["ETPatternCore"]),
        .library(name: "ETPatternServices", targets: ["ETPatternServices"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ETPatternModels",
            dependencies: [],
            path: "Sources/ETPatternModels"
        ),
        .target(
            name: "ETPatternCore",
            dependencies: ["ETPatternModels"],
            path: "Sources/ETPatternCore"
        ),
        .target(
            name: "ETPatternServices",
            dependencies: ["ETPatternModels", "ETPatternCore"],
            path: "Sources/ETPatternServices"
        ),
        .testTarget(
            name: "ETPatternTests",
            dependencies: ["ETPatternModels", "ETPatternCore", "ETPatternServices"]
        ),
    ]
)