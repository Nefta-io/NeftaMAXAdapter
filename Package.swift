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
            url: "https://github.com/Nefta-io/NeftaSDK-iOS/releases/download/REL_4.7.4/NeftaSDK.xcframework-4.7.4.zip",
    ],
    targets: [
        .target(
            name: "NeftaMAXAdapter",
            dependencies: ["NeftaSDK", .product(name: "AppLovinSDK", package: "AppLovin-MAX-Swift-Package")],
            publicHeadersPath: "."
        ),
        .binaryTarget(
            name: "NeftaSDK",
            url: "https://github.com/Nefta-io/NeftaSDK-iOS/releases/download/REL_4.7.4/NeftaSDK.xcframework-4.7.4.zip",
            checksum: "6c67be98735bbf2933466766025b814772cfbdea397ccfd92f994954d65e4e46"
        )
    ]
)
