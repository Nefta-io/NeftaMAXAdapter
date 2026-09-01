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
    targets: [
        .target(
            name: "NeftaMAXAdapter",
            dependencies: ["NeftaSDK"],
            publicHeadersPath: "."
        ),
        .binaryTarget(
            name: "NeftaSDK",
            url: "https://github.com/Nefta-io/NeftaSDK-iOS/releases/download/REL_4.6.10/NeftaSDK.xcframework-4.6.10.zip",
            checksum: "a94b51bc20b3c4692491c2913e96710dfd17bd73438aa9ee4ee8ff48833b7e26"
        )
    ]
)
