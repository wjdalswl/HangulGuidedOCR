// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "HangulGuidedOCR",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "HangulGuidedOCR",
            targets: ["HangulGuidedOCR"]
        ),
    ],
    targets: [
        .target(
            name: "HangulGuidedOCR",
            path: "Sources/HangulGuidedOCR"
        ),
        .testTarget(
            name: "HangulGuidedOCRTests",
            dependencies: ["HangulGuidedOCR"],
            path: "Tests/HangulGuidedOCRTests"
        ),
    ]
)
