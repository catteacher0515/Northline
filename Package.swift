// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PersonalSystem",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "PersonalSystem",
            targets: ["PersonalSystem"]
        )
    ],
    targets: [
        .executableTarget(
            name: "PersonalSystem",
            path: "Sources/PersonalSystem"
        ),
        .testTarget(
            name: "PersonalSystemTests",
            dependencies: ["PersonalSystem"],
            path: "Tests/PersonalSystemTests"
        )
    ]
)
