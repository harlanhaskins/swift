// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "swift-format",
  dependencies: [
  ],
  targets: [
    .target(
      name: "SwiftFormat",
      dependencies: []),
    .target(
      name: "swift-format",
      dependencies: ["SwiftFormat"]),
    .testTarget(
      name: "SwiftFormatTests",
      dependencies: ["SwiftFormat"]),
  ]
)
