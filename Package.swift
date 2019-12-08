// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Bootstrapp",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "BootstrappKit", targets: ["BootstrappKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/yonaskolb/XcodeGen.git", .upToNextMajor(from: "2.10.0")),
        .package(url: "https://github.com/apparata/Markin.git", .upToNextMajor(from: "0.6.0")),
        .package(url: "https://github.com/apparata/TemplateKit.git", .upToNextMajor(from: "0.3.3"))
    ],
    targets: [
        .target(
            name: "BootstrappKit",
            dependencies: [
                "XcodeGenKit",
                "ProjectSpec",
                "TemplateKit",
                "Markin"
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release)),
                .define("SWIFT_PACKAGE")
            ]),
        .testTarget(name: "BootstrappKitTests", dependencies: ["BootstrappKit"]),
    ]
)
