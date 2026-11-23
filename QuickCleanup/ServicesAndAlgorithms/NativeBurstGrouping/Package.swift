// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NativeBurstGrouping",
    platforms: [.iOS("16.4"), .macOS(.v14)],
    products: [
        .library(name: "BurstPhotoGrouping", targets: ["BurstPhotoGrouping"])
    ],
    targets: [
        .target(
            name: "BurstPhotoGrouping",
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "BurstPhotoGroupingTests",
            dependencies: ["BurstPhotoGrouping"]
        )
    ],
    swiftLanguageModes: [.v5]
)
