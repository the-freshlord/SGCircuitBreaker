// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SGCircuitBreaker",
    products: [
        .library(
            name: "SGCircuitBreaker",
            targets: ["SGCircuitBreaker"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SGCircuitBreaker",
            dependencies: []),
        .testTarget(
            name: "SGCircuitBreakerTests",
            dependencies: ["SGCircuitBreaker"]),
    ]
)
