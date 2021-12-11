// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "BootstrappKit",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "BootstrappKit", targets: ["BootstrappKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/yonaskolb/XcodeGen.git", .exact("2.25.0")),
        .package(url: "https://github.com/apparata/Markin.git", .exact("0.7.0")),
        .package(url: "https://github.com/apparata/TemplateKit.git", .exact("0.5.0"))
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
        .testTarget(name: "BootstrappKitTests", dependencies: ["BootstrappKit"]),
    ]
)
