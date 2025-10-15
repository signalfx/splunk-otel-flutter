// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "splunk_otel_flutter",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "splunk-otel-flutter",
        targets: ["splunk_otel_flutter"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/signalfx/splunk-otel-ios", exact: "2.0.1")
    ],
    targets: [
        .target(
            name: "splunk_otel_flutter",
            dependencies: [
                .product(name: "SplunkAgent", package: "splunk-otel-ios")
            ],
            resources: []
        )
    ]
)
