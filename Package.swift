// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MasterVoice",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "master-voice", targets: ["MasterVoice"]),
        .executable(name: "master-voice-cli", targets: ["MasterVoiceCLI"]),
        .library(name: "MasterVoiceCore", targets: ["MasterVoiceCore"])
    ],
    targets: [
        .target(
            name: "MasterVoiceCore"
        ),
        .executableTarget(
            name: "MasterVoice",
            dependencies: ["MasterVoiceCore"],
            exclude: ["Resources/Info.plist"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/MasterVoice/Resources/Info.plist"
                ])
            ]
        ),
        .executableTarget(
            name: "MasterVoiceCLI",
            dependencies: ["MasterVoiceCore"]
        ),
        .testTarget(
            name: "MasterVoiceCoreTests",
            dependencies: ["MasterVoiceCore"]
        )
    ]
)
