// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "VaporOAuth",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "VaporOAuth", targets: ["VaporOAuth"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "VaporOAuth",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
            ]
        )
    ]
)
