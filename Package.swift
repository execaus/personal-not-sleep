// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PersonalNotSleep",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "PersonalNotSleep", targets: ["PersonalNotSleep"]),
               .executable(name: "PersonalNotSleepCheck", targets: ["PersonalNotSleepCheck"])],
    targets: [
        .target(name: "PersonalNotSleepCore"),
        .executableTarget(name: "PersonalNotSleep", dependencies: ["PersonalNotSleepCore"]),
        .executableTarget(name: "PersonalNotSleepCheck", dependencies: ["PersonalNotSleepCore"])
    ]
)
