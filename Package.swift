// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "clip-vault",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ClipVault",
            path: "Sources/clip-vault"
        )
    ]
)
