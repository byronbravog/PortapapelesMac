// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Portapapeles",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Portapapeles",
            targets: ["Portapapeles"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Portapapeles",
            dependencies: [],
            path: "Sources"
        )
    ]
)