// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "CodexQuotaBar",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "CodexQuotaBar", targets: ["CodexQuotaBar"])
    ],
    targets: [
        .executableTarget(name: "CodexQuotaBar"),
        .testTarget(
            name: "CodexQuotaBarTests",
            dependencies: ["CodexQuotaBar"]
        )
    ]
)
