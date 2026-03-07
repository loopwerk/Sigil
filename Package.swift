// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "Sigil",
  products: [
    .library(name: "Sigil", targets: ["Sigil"]),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-docc-symbolkit", branch: "main"),
  ],
  targets: [
    .target(
      name: "Sigil",
      dependencies: [
        .product(name: "SymbolKit", package: "swift-docc-symbolkit"),
      ]
    ),
    .testTarget(
      name: "SigilTests",
      dependencies: ["Sigil"],
      resources: [
        .copy("Fixtures"),
      ]
    ),
  ]
)
