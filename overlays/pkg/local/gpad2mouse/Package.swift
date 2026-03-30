// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "gpad2mouse",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "gpad2mouse",
            path: "Sources/gpad2mouse",
            linkerSettings: [
                .linkedFramework("GameController"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("AppKit"),
            ]
        ),
    ]
)
