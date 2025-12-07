// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MenuBarWorldClock",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "MenuBarWorldClock", targets: ["MenuBarWorldClock"])
    ],
    targets: [
        .executableTarget(
            name: "MenuBarWorldClock",
            path: "MenuBarWorldClock",
            exclude: ["Info.plist", "WorldClock.entitlements"]
        ),
        .testTarget(
            name: "MenuBarWorldClockTests",
            dependencies: ["MenuBarWorldClock"],
            path: "MenuBarWorldClockTests"
        )
    ]
)
