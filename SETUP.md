# Development Setup

This document helps you set up your local environment and Git hooks for this repository. It ensures consistent conventional commits and catches Flutter/Dart issues early, mirroring CI checks.

## Prerequisites

- **Flutter SDK** (`>=3.32.0`) with `flutter` and `dart` on your PATH (or use [FVM](https://fvm.app/) for version management).
- **Melos** for monorepo workspace management:

```bash
dart pub global activate melos
```

Verify your toolchain:

```bash
flutter --version
dart --version
melos --version
```

## Workspace Setup

This repository uses **Dart 3 workspaces** combined with **Melos**. All packages are linked through the root `pubspec.yaml` workspace definition.

After cloning, bootstrap the monorepo:

```bash
melos bootstrap
```

This resolves dependencies and links all local packages. Always use `melos bootstrap` instead of `flutter pub get` in individual packages.

### Platform-Specific Setup

The SDK packages require additional platform configuration (Android desugaring, iOS Swift Package Manager, etc.). See the READMEs in each package for full instructions:

- [splunk_otel_flutter README](packages/splunk_otel_flutter/splunk_otel_flutter/README.md)
- [splunk_otel_flutter_session_replay README](packages/splunk_otel_flutter_session_replay/splunk_otel_flutter_session_replay/README.md)

## Melos Scripts

All common development tasks are available as Melos scripts:

```bash
melos analyze               # Run Dart analyzer with --fatal-warnings
melos test                  # Run tests across all packages
melos format                # Format code across all packages
melos clean                 # Clean Flutter builds across all packages
melos run generate_pigeon   # Regenerate Pigeon platform interface code
melos run run_example       # Run the example application
```

Note: `melos analyze` and `melos test` skip example apps and session replay packages by default (configured in `melos.ignore`).

## Git Hooks (Pre-commit and Commit Message)

The hooks are versioned and committed under `.githooks/`. You do not need to create these files -- just enable them once per clone. After enabling, the hooks will run automatically on `git commit`.

Run the setup script after cloning to enable the hooks:

```bash
bash .githooks/setup-hooks.sh
```

Verify:

```bash
git config --get core.hooksPath   # should print .githooks
git commit --allow-empty -m "ci: verify hooks"   # hooks should run
```

### Pre-commit Hook

The pre-commit hook mirrors CI checks locally:

1. Runs `melos bootstrap` to ensure dependencies are resolved.
2. Checks Dart formatting on staged files (`dart format --set-exit-if-changed`).
3. Runs `flutter analyze --fatal-warnings` across all Melos packages.

If FVM is installed, the hook uses it automatically; otherwise it falls back to the system Flutter.

### Commit Message Hook

Enforces [conventional commit](https://www.conventionalcommits.org/) style:

- Format: `<type>(<scope>)?: <subject>`
- Types: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`
- Header max 72 characters, body/footer lines max 100 characters.
- Blank line required between header and body.
