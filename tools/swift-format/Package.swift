// swift-tools-version:4.1

import PackageDescription

let package = Package(
  name: "swiftformat",
  dependencies: [
    .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.1.0")
  ],
  targets: [
    .target(
      name: "swiftformat",
      dependencies: ["Rules", "Core", "Configuration", "Utility"]),
    .target(
      name: "generate-pipeline",
      dependencies: []),
    .target(
      name: "Rules",
      dependencies: ["Core", "Configuration"]),
    .target(
      name: "Core",
      dependencies: ["Configuration"]),
    .target(
      name: "Configuration",
      dependencies: []),
    .testTarget(
      name: "SwiftFormatTests",
      dependencies: []),
  ]
)
