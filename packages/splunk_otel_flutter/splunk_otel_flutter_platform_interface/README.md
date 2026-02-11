# splunk_otel_flutter_platform_interface

Platform interface package for Splunk OpenTelemetry Flutter SDK.

This package defines the platform interface contracts used for communication between Flutter and native platforms (Android/iOS) via Pigeon code generation.

## Overview

This package provides:

- Platform interface definitions for the Splunk RUM SDK
- Data models and configuration classes
- Pigeon message definitions for native communication
- Abstract platform implementation contracts

## Usage

This package is typically used as a dependency by the main `splunk_otel_flutter` package and platform-specific implementations. End users should depend on `splunk_otel_flutter` instead.

## Requirements

- Dart SDK: `>=3.8.0 <4.0.0`
- Flutter SDK: `>=3.32.0`

## License

Copyright 2025 Splunk Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
