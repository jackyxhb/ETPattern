// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ETPattern",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "ETPatternModels", targets: ["ETPatternModels"]),
        .library(name: "ETPatternCore", targets: ["ETPatternCore"]),
        .library(name: "ETPatternServices", targets: ["ETPatternServices"]),
        .library(name: "ETPatternFeatures", targets: ["ETPatternFeatures"]),
        .executable(name: "ETPatternApp", targets: ["ETPatternApp"]),
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
        .target(
            name: "ETPatternFeatures",
            dependencies: ["ETPatternModels", "ETPatternCore", "ETPatternServices"],
            path: "Sources/ETPatternFeatures"
        ),
        .executableTarget(
            name: "ETPatternApp",
            dependencies: ["ETPatternFeatures", "ETPatternServices", "ETPatternCore", "ETPatternModels"],
            path: "ETPattern",
            resources: [
                .process("Assets.xcassets"),
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ETPatternTests",
            dependencies: ["ETPatternModels", "ETPatternCore", "ETPatternServices", "ETPatternFeatures"]
        ),
    ]
)