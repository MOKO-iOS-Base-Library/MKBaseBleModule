// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MKBaseBleModule",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "MKBaseBleModule",
            targets: ["MKBaseBleModule"]
        )
    ],
    targets: [
        .target(
            name: "MKBaseBleModule",
            path: "MKBaseBleModule/Classes",
            publicHeadersPath: ".",
            linkerSettings: [
                .linkedFramework("CoreBluetooth")
            ]
        )
    ]
)
