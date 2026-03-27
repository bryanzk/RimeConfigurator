// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RimeConfigurator",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.14.0")
    ],
    targets: [
        .executableTarget(
            name: "RimeConfigurator",
            dependencies: ["Yams"],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        ),
        .testTarget(
            name: "RimeConfiguratorTests",
            dependencies: [
                "RimeConfigurator",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests/RimeConfiguratorTests"
        )
    ]
)
