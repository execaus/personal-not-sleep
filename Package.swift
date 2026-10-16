// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PersonalNotSleep",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "PersonalNotSleep", targets: ["PersonalNotSleep"]),
               .executable(name: "PersonalNotSleepCheck", targets: ["PersonalNotSleepCheck"])],
    dependencies: [.package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0")],
    targets: [
        .target(name: "PersonalNotSleepCore"),
        .executableTarget(name: "PersonalNotSleep", dependencies: [
            "PersonalNotSleepCore", .product(name: "Sparkle", package: "Sparkle")
        ]),
        .executableTarget(name: "PersonalNotSleepCheck", dependencies: ["PersonalNotSleepCore"])
    ]
)
