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
    name: "splunk_otel_flutter_session_replay",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "splunk-otel-flutter-session-replay", targets: ["splunk_otel_flutter_session_replay"])
    ],
    dependencies: [
        // TODO(iOS): bump to the splunk-otel-ios release that ships the explicit
        // `trackError` API, in lockstep with the main splunk_otel_flutter plugin.
        // Both plugins share the `splunk-otel-ios` package identity, so they must
        // always resolve the same source (mixing a local path with a remote URL
        // causes an SPM conflict). For local verification use an absolute path:
        //   .package(path: "/absolute/path/to/splunk-otel-ios")
        .package(url: "https://github.com/signalfx/splunk-otel-ios", exact: "2.3.1")
    ],
    targets: [
        .target(
            name: "splunk_otel_flutter_session_replay",
            dependencies: [
                .product(name: "SplunkAgent", package: "splunk-otel-ios")
            ],
            resources: []
        )
    ]
)
