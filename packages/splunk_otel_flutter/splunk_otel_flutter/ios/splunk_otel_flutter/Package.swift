// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

/*
Copyright 2025 Splunk Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

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
        .package(url: "https://github.com/signalfx/splunk-otel-ios", exact: "2.0.5")
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
