// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NeftaMAXAdapter",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "NeftaMAXAdapter",
            targets: ["NeftaMAXAdapter"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/AppLovin/AppLovin-MAX-Swift-Package.git", from: "12.0.0")
    ],
    targets: [
        .target(
            name: "NeftaMAXAdapter",
            dependencies: ["NeftaSDK", .product(name: "AppLovinSDK", package: "AppLovin-MAX-Swift-Package")],
            publicHeadersPath: "."
        ),
        .binaryTarget(
            name: "NeftaSDK",
            url: "https://github.com/Nefta-io/NeftaSDK-iOS/releases/download/REL_4.7.1/NeftaSDK.xcframework-4.7.1.zip",
            checksum: "87fc8661f0c1f7d60815a5269b93cf6a7af3cf14f06b3cf6b9248f5b726fa762"
        )
    ]
)
