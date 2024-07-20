// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "ContentBlockRuleList",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "ContentBlockRuleList",
      targets: ["ContentBlockRuleList"]),
  ],
  dependencies: [
    .package(url: "https://github.com/duckduckgo/TrackerRadarKit.git", from: "2.1.2")
  ],
  targets: [
    .target(
      name: "ContentBlockRuleList",
      dependencies: ["TrackerRadarKit"],
      resources: [
        .process("Resources/blockingRules.json"),
        .process("Resources/duckduckgoTrackerBlocklists.json")
      ]),
    .testTarget(
      name: "ContentBlockRuleListTests",
      dependencies: ["ContentBlockRuleList"]),
  ]
)
