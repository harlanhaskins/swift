// swift-tools-version:4.1

import PackageDescription

let package = Package(
  name: "swift-format",
  dependencies: [
  ],
  targets: [
    .target(
      name: "PrettyPrint",
      dependencies: []
    ),
    .target(
      name: "swift-format",
      dependencies: ["PrettyPrint"]
    ),
  ]
)
