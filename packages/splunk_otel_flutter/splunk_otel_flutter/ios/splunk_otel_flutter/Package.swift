// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

/*
Copyright 2026 Splunk Inc.

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
        // TODO(iOS): bump to the splunk-otel-ios release that ships the explicit
        // `trackError(typeName:message:stacktrace:attributes:)` API. That API is
        // still unreleased upstream, so we stay on the last published pin and the
        // native trackError bridge is only exercised on Android for now.
        // For local verification, point this at a checkout of the SDK instead
        // (absolute path required, because Flutter consumes this plugin via a
        // symlink under ios/Flutter/ephemeral/Packages/.packages):
        //   .package(path: "/absolute/path/to/splunk-otel-ios")
        .package(url: "https://github.com/signalfx/splunk-otel-ios", exact: "2.3.1")
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
