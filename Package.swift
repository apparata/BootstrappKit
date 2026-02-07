// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "BootstrappKit",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "BootstrappKit", targets: ["BootstrappKit"]),
        .executable(name: "bootstrapp-cli", targets: ["bootstrapp-cli"]),
    ],
    dependencies: [
        .package(url: "https://github.com/yonaskolb/XcodeGen.git", branch: "synced_folder"),
        //.package(url: "https://github.com/yonaskolb/XcodeGen.git", exact: "2.38.0"),
        .package(url: "https://github.com/apparata/Markin.git", exact: "0.7.1"),
        .package(url: "https://github.com/apparata/TemplateKit.git", exact: "0.6.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "BootstrappKit",
            dependencies: [
                .product(name: "Markin", package: "Markin"),
                .product(name: "TemplateKit", package: "TemplateKit"),
                .product(name: "XcodeGenKit", package: "XcodeGen"),
                .product(name: "ProjectSpec", package: "XcodeGen")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release)),
                .define("SWIFT_PACKAGE")
            ]),
        .executableTarget(
            name: "bootstrapp-cli",
            dependencies: [
                "BootstrappKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .testTarget(name: "BootstrappKitTests", dependencies: ["BootstrappKit"]),
    ]
)
