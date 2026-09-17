// swift-tools-version: 6.2
import PackageDescription

// A file may only use what it imports ITSELF. This is not pedantry: SwiftPM's incremental
// build tracks dependencies through direct imports only. When the catalog reached the tokens
// through a re-export (`@_exported import`), changing a token struct's layout left the
// catalog un-rebuilt, and the next test run segfaulted. Now a missing import is a compile error.
let strictImports: [SwiftSetting] = [.enableUpcomingFeature("MemberImportVisibility")]

// Everything that draws views runs on the main actor by default.
// TrembusTokens deliberately does NOT get this: tokens are plain, thread-safe values
// (SwiftUI resolves shape styles off the main thread).
let mainActorByDefault: [SwiftSetting] = strictImports + [.defaultIsolation(MainActor.self)]

let package = Package(
    name: "trembus-swift",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "TrembusTokens", targets: ["TrembusTokens"]),
        .library(name: "TrembusUI", targets: ["TrembusUI"]),
        .executable(name: "TrembusGallery", targets: ["TrembusGallery"]),
        .executable(name: "TrembusSnap", targets: ["TrembusSnap"]),
    ],
    targets: [
        // tokens → primitives → components. No third-party dependencies, on purpose.
        .target(name: "TrembusTokens", swiftSettings: strictImports),
        .target(name: "TrembusUI", dependencies: ["TrembusTokens"], swiftSettings: mainActorByDefault),

        // The catalog is the Storybook equivalent: one registry of specimens feeds the
        // gallery app, the snapshot CLI, Xcode previews, and the test gate.
        .target(
            name: "TrembusCatalog", dependencies: ["TrembusTokens", "TrembusUI"],
            swiftSettings: mainActorByDefault),
        .executableTarget(
            name: "TrembusGallery", dependencies: ["TrembusTokens", "TrembusUI", "TrembusCatalog"],
            swiftSettings: mainActorByDefault),
        .executableTarget(
            name: "TrembusSnap", dependencies: ["TrembusTokens", "TrembusUI", "TrembusCatalog"],
            swiftSettings: mainActorByDefault),

        .testTarget(
            name: "TrembusTokensTests", dependencies: ["TrembusTokens"], swiftSettings: strictImports),
        .testTarget(
            name: "TrembusUITests", dependencies: ["TrembusTokens", "TrembusUI", "TrembusCatalog"],
            swiftSettings: mainActorByDefault),
    ]
)
