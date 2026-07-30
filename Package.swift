// swift-tools-version:6.0
//
// Taskly — a Noise-based reimplementation of rtaskly.
//
// This SPM manifest lets you build the macOS app with `swift build` once the
// Racket backend artifacts exist (run `make` first):
//
//   make                                 # produces Taskly/res/core.zo
//   swift build -c release               # builds the SwiftUI app
//   open .build/release/Taskly.app       # (or run the binary directly)
//
// Noise is expected as a sibling directory at ../Noise, with its SwiftPM
// package under ../Noise/SwiftNoise (the same layout as the Noise repo).
// The xcframeworks must be built once: `make -C ../Noise/SwiftNoise`.

import PackageDescription

let package = Package(
  name: "Taskly",
  platforms: [.macOS(.v14)],
  targets: [
    // The macOS app. Sources live under Taskly/ (including the generated
    // Taskly/Backend.swift). The embedded runtime core.zo is copied into
    // the bundle as a resource at build time (see Makefile / Xcode setup).
    .executableTarget(
      name: "Taskly",
      dependencies: [
        .product(name: "Noise", package: "SwiftNoise"),
        .product(name: "NoiseBackend", package: "SwiftNoise"),
        .product(name: "NoiseSerde", package: "SwiftNoise"),
      ],
      path: "Taskly",
      exclude: ["res"],
      resources: [
        .copy("res"),
      ]
    ),
  ]
)

// Local dependency on Noise (clone of github.com/turinglambdaai/Noise).
package.dependencies = [
  .package(path: "../Noise/SwiftNoise"),
]
