// swift-tools-version:4.2

import PackageDescription

let package = Package(
  name: "RPiPWM",
  dependencies: [
    .package(url: "https://github.com/uraimo/SwiftyGPIO.git", from: "1.0.0")
  ],
  targets: [
    .target(
      name: "RPiPWM",
      dependencies: ["SwiftyGPIO"]),
    ]
)
