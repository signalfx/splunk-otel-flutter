# Splunk RUM SDK for Flutter - AI Assistant Context

This document provides context for AI assistants working on this codebase.

## Critical Rules

### 1. No New External Dependencies

**Under NO circumstances should you add any new dependency to the SDK.**

- The Splunk RUM SDK must remain lightweight and minimize its footprint in customer applications.
- Adding dependencies increases artifact size and can introduce version conflicts for SDK consumers.
- All allowed dependencies are defined in the `pubspec.yaml` files of each package.
- If a task seems to require a new dependency, **stop and ask the user** for an alternative approach.

### 2. Public API Immutability

**The public API is stable and must NOT be changed without explicit user confirmation.**

#### What is Public API?

- The barrel export `packages/splunk_otel_flutter/splunk_otel_flutter/lib/splunk_otel_flutter.dart` and all types it re-exports.
- Public classes: `SplunkRum`, `AgentConfiguration`, `EndpointConfiguration`, `CustomTracking`, `GlobalAttributes`, `WorkflowHandle`, `MutableAttributes`, `ModuleConfiguration`, and related models.
- The equivalent public surface in `packages/splunk_otel_flutter_session_replay/`.

#### What constitutes a Public API change?

- Method/function signatures (name, parameters, defaults, return types)
- Behavior, semantics, and side effects
- Public constants and exported symbols
- Data classes and configuration models
- Visibility changes (public to private)
- Deprecations or removals

#### The Rule

> **Default assumption: Public API is immutable unless the user explicitly asks for the change and confirms it.**

If a task appears to require changing any public type or method:
1. **STOP** and inform the user
2. **Document** what would need to change and why
3. **Wait** for explicit user confirmation before proceeding
4. Explore alternative approaches that don't modify public API

### 3. Platform Interface Stability

The Pigeon-generated platform interfaces (`*_platform_interface` packages) are contracts between Dart and native iOS/Android code. Changing them requires regenerating Pigeon code and updating native implementations on both platforms. Always ask before modifying.

### 4. Backwards Compatibility

**All changes must maintain backwards compatibility.**

- SDK consumers should be able to update to new versions without code changes.
- Deprecated APIs must continue to function (mark with `@Deprecated` annotation with migration guidance).
- Default behaviors must not change in ways that break existing integrations.
- New features should be opt-in, not opt-out.

---

## Project Overview

**Splunk RUM SDK for Flutter** is a multi-package workspace for Real User Monitoring (RUM). It instruments Flutter applications to collect telemetry data and sends it to Splunk Observability Cloud.

- **Language**: Dart 3 / Flutter
- **SDK constraint**: `>=3.8.0 <4.0.0`
- **Flutter constraint**: `>=3.32.0`
- **Monorepo tooling**: Dart 3 workspaces + Melos
- **Platform communication**: Pigeon (type-safe host API codegen)
- **Core dependency**: OpenTelemetry (via native iOS/Android SDKs)

---

## Project Structure

```
splunk-otel-flutter/
├── packages/
│   ├── splunk_otel_flutter/
│   │   ├── splunk_otel_flutter/                # Main SDK (app-facing API)
│   │   │   ├── lib/
│   │   │   │   ├── splunk_otel_flutter.dart     # Barrel export (PUBLIC API)
│   │   │   │   └── src/                         # Implementation
│   │   │   ├── example/                         # SDK example app
│   │   │   └── test/                            # SDK tests
│   │   └── splunk_otel_flutter_platform_interface/  # Pigeon contract
│   │       ├── lib/src/
│   │       │   ├── pigeon/messages.pigeon.dart   # Generated Pigeon code
│   │       │   ├── model/                        # Data models
│   │       │   └── implementation/               # Platform implementation
│   │       ├── pigeons/messages.dart             # Pigeon definition
│   │       └── test/                             # Platform interface tests
│   └── splunk_otel_flutter_session_replay/
│       ├── splunk_otel_flutter_session_replay/           # Session replay plugin
│       └── splunk_otel_flutter_session_replay_platform_interface/  # Session replay Pigeon contract
├── splunk_otel_flutter_root_example_app/         # Root example app
├── pubspec.yaml                                  # Workspace root + Melos config
├── analysis_options.yaml                         # Shared lint rules
└── .github/workflows/                            # CI (PR checks)
```

### Federated Plugin Pattern

The SDK follows Flutter's federated plugin architecture:

1. **`splunk_otel_flutter`** - App-facing Dart API (`SplunkRum.instance`)
2. **`splunk_otel_flutter_platform_interface`** - Pigeon-defined contract between Dart and native
3. **Native iOS/Android** - Platform-specific OpenTelemetry instrumentation (in separate repos)

The same pattern applies to the session replay packages.

---

## Architecture

### Singleton Entry Point

The SDK uses a singleton pattern. All access goes through `SplunkRum.instance`:

```dart
SplunkRum.instance.install(agentConfiguration: ..., moduleConfigurations: [...]);
SplunkRum.instance.globalAttributes.setString(key: 'k', value: 'v');
SplunkRum.instance.customTracking.trackCustomEvent(name: 'event');
```

### Platform Delegation

`SplunkRum` delegates to `SplunkOtelFlutterPlatformImplementation.instance`, which communicates with native code via Pigeon-generated host APIs. The implementation groups methods by concern: State, Preferences, Session, User, Global Attributes, Custom Tracking, Navigation.

### Module System

Features are configured via `ModuleConfiguration` subclasses passed to `install()`:

```dart
moduleConfigurations: [
  CrashReportsModuleConfiguration(),
  NavigationModuleConfiguration(isAutomatedTrackingEnabled: true),
  NetworkMonitorModuleConfiguration(),
  SlowRenderingModuleConfiguration(interval: const Duration(seconds: 1)),
]
```

---

## Dart Code Style

### Imports

- **Production code**: Always use package imports (`import 'package:splunk_otel_flutter/src/...'`).
- **Test code**: Relative imports are acceptable for local test helpers (`import '../../mock_api.dart'`).
- **Ordering**: `dart:` core libraries, then `package:` imports, then relative imports. Each group separated by a blank line.

### Naming Conventions

- **Files**: `snake_case.dart` (e.g., `agent_configuration.dart`, `custom_tracking.dart`)
- **Classes / Types**: `PascalCase` (e.g., `SplunkRum`, `AgentConfiguration`, `MutableAttributes`)
- **Methods / Variables**: `camelCase` (e.g., `trackCustomEvent`, `rumAccessToken`)
- **Private members**: Prefix with `_` (e.g., `_delegate`, `_instance`, `_internal`)
- **Constants**: `camelCase` for top-level and static constants
- **No abbreviations** except widely recognized ones (API, URL, HTTP, ID)

### File Organization

1. License header (Apache 2.0)
2. Imports (`dart:`, `package:`, relative -- each group separated by blank line)
3. Library-level documentation (if barrel file)
4. Classes in logical dependency order
5. Extensions
6. Private helpers

### Immutability

- Use `const` constructors and literals wherever possible (enforced by lint as error).
- Use `final` for local variables and fields (enforced by `prefer_final_locals`, `prefer_final_fields`).
- Use `late` primarily in test `setUp` for mock initialization.

### Null Safety

- Codebase is fully null-safe.
- Use nullable types (`String?`, `Future<UserTrackingMode?>`) for optional values.
- Use null-aware operators: `?.`, `??`, `??=`.
- Avoid force-unwraps (`!`) in production code.

### Documentation

- Use `///` doc comments on all public APIs.
- Include a brief description, parameter documentation, and usage examples where helpful.
- End doc comment sentences with a period.

### Early Returns

Prefer early return to reduce nesting depth:

```dart
// Good
Future<void> process(String? input) async {
  if (input == null) {
    return;
  }

  await doWork(input);
}

// Avoid
Future<void> process(String? input) async {
  if (input != null) {
    await doWork(input);
  }
}
```

### Blank Line Before Terminal Statements

When a `return` statement or completion callback follows other code in the same block, add a blank line before it for visual breathing room:

```dart
// Good
final appVersion = SplunkRum.instance.state.appVersion;

callback(Result.success(appVersion));

// Good
final value = computeResult();

return value;

// Bad
final appVersion = SplunkRum.instance.state.appVersion;
callback(Result.success(appVersion));

// Bad
final value = computeResult();
return value;
```

### Error Handling

- Use `ArgumentError` for invalid input validation in constructors/methods.
- Define custom `Exception` classes for domain-specific errors (e.g., `InvalidEndpointConfigurationException`).
- Use `try/catch` for platform calls where failures are expected.
- Propagate errors via `Future` rather than swallowing them silently.

### Linting

Configured in the root `analysis_options.yaml`:

- Base: `package:flutter_lints/flutter.yaml`
- Strict inference and strict raw types enabled
- No implicit casts, no implicit dynamic
- Key rules promoted to error: `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, `missing_required_param`, `missing_return`
- Additional enabled rules: `avoid_print`, `prefer_final_locals`, `prefer_final_fields`, `prefer_spread_collections`, `prefer_if_null_operators`, `unnecessary_string_interpolations`, `unnecessary_parenthesis`

---

## Testing Patterns

### Framework

Tests use `flutter_test` with `TestWidgetsFlutterBinding.ensureInitialized()`.

### Structure

```dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClassName', () {
    late MockApi mockApi;

    setUp(() {
      mockApi = MockApi();
      TestHostApi.setUp(mockApi);
    });

    tearDown(() {
      TestHostApi.setUp(null);
    });

    group('featureGroup', () {
      test('should describe expected behavior', () {
        // Arrange, Act, Assert
      });
    });
  });
}
```

### Naming

- **Test files**: Mirror the source file name with `_test` suffix (e.g., `splunk_otel_flutter_test.dart`).
- **Test names**: Descriptive, sentence-like (`'should return same instance'`, `'should call install with correct agent configuration'`).

### Layout

- `test/unit/` - Unit tests organized by concern (`implementation/`, `model/`)
- `test/integration/` - Integration tests
- `test/pigeon/` - Pigeon-generated test harness

### Mocks

Pigeon generates test API classes used as mock interfaces. Custom mocks implement those interfaces in `test/` helper files.

---

## Build and Development Commands

All commands use Melos (configured in root `pubspec.yaml`):

```bash
# Bootstrap workspace (install deps + link packages)
melos bootstrap

# Run Dart analyzer with fatal warnings
melos analyze

# Run all tests (excludes examples and session replay)
melos test

# Format all Dart code
melos format

# Regenerate Pigeon platform interfaces
melos run generate_pigeon

# Clean all build artifacts
melos clean

# Run the example app
melos run run_example
```

Note: Melos `analyze` and `test` scripts ignore example and session replay packages by default (configured in `melos.ignore`).

---

## Iteration Loop

After making any change, follow this workflow:

### 1. Format Code
```bash
melos format
```

### 2. Run Analyzer
```bash
melos analyze
```

### 3. Run Tests
```bash
melos test
```

### 4. Verify Build
Build the affected package or example app to ensure no compilation errors.

---

## Allowed vs Disallowed Changes

| Action | Allowed? | Notes |
|--------|----------|-------|
| Add new dependency | NO | Never without explicit user request |
| Modify public API | ASK | Requires user confirmation |
| Change platform interface (Pigeon) | ASK | Affects native iOS/Android code |
| Change default behavior | ASK | Could break existing integrations |
| Internal refactoring | YES | If it doesn't affect public behavior |
| Add tests | YES | Always encouraged |
| Fix bugs (API-preserving) | YES | Maintain backwards compatibility |
| Performance optimization | YES | If behavior is identical |
| Update documentation | YES | Always encouraged |

---

## Common Tasks

### Adding a New Feature to the SDK

1. Add implementation in `packages/splunk_otel_flutter/splunk_otel_flutter/lib/src/`
2. If it requires native platform communication, update the Pigeon definition in `*_platform_interface/pigeons/messages.dart`
3. Run `melos run generate_pigeon` to regenerate platform code
4. Export new public types from the barrel file `splunk_otel_flutter.dart` (requires user confirmation since it changes public API)
5. Add unit tests in the corresponding `test/` directory
6. Update documentation

### Modifying the Platform Interface

1. Edit the Pigeon definition in `*_platform_interface/pigeons/messages.dart`
2. Run `melos run generate_pigeon`
3. Update `SplunkOtelFlutterPlatformImplementation` to implement any new/changed methods
4. Coordinate with native iOS/Android repos for native-side changes

### Adding a New Example Screen

1. Create a new screen file in `splunk_otel_flutter_root_example_app/lib/screen/`
2. Follow the existing pattern: `StatefulWidget` with local state management
3. Wire up navigation from the appropriate parent screen

---

## CI/CD

### GitHub Actions (PRs)

Triggered on pull requests to `main` and `develop`:

1. **Commitlint** - Validates conventional commit format
2. **Flutter Analyze** - `melos bootstrap` + `melos analyze`
3. **Flutter Test** - `melos test`

### GitLab CI (Publishing)

Used for publishing to pub.dev:

1. **Build** - Analyze and test the main SDK packages
2. **Dry-run** - Manual `flutter pub publish --dry-run`
3. **Release** - Manual publish to pub.dev

### Commit Message Format

Conventional commits are enforced: `<type>(<scope>)?: <subject>`

Types: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`

- Header max 72 characters
- Blank line between header and body
- Body lines max 100 characters

---

## Key Files

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Workspace root, Melos config, dev dependencies |
| `analysis_options.yaml` | Shared Dart lint rules for all packages |
| `packages/splunk_otel_flutter/splunk_otel_flutter/lib/splunk_otel_flutter.dart` | Public API barrel export |
| `packages/splunk_otel_flutter/splunk_otel_flutter/lib/src/splunk_otel_flutter.dart` | `SplunkRum` singleton implementation |
| `packages/splunk_otel_flutter/splunk_otel_flutter_platform_interface/pigeons/messages.dart` | Pigeon definition (Dart-to-native contract) |
| `.github/workflows/pr.yaml` | PR CI checks |
| `.commitlintrc.yml` | Commit message lint rules |
| `CONTRIBUTING.md` | Contribution guidelines |
| `SETUP.md` | Development environment setup |
| `RELEASE.md` | Release process for pub.dev |

---

## License

Apache License 2.0. All source files must include the Splunk copyright header.

When creating a new file or modifying an existing file, the copyright year must be the **current year**:

```dart
/*
 * Copyright 2026 Splunk Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
```

---

## Updating This Guide

If you discover new patterns, conventions, or important information that would help future AI agents work with this repository, update this guide accordingly.
