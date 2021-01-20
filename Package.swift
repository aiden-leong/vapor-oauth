// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "VaporOAuth",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
//        .package(url: "https://github.com/vapor/auth-provider.git", .upToNextMajor(from: "1.2.0")),
    ],
    products: [
        .library(name: "VaporOAuth", targets: ["VaporOAuth"]),
    ],
    targets: [
        .target(name: "VaporOAuth", dependencies: ["Vapor"]),
    ]
)
