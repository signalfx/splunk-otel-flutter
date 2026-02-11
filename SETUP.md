# Development Setup

This document helps you set up your local environment and Git hooks for this repository. It ensures consistent conventional commits and catches Flutter/Dart issues early, mirroring CI checks.

## Flutter Setup

- Install the Flutter SDK and ensure `flutter` and `dart` are on your PATH (or use FVM).
  - From the repo root, install dependencies:
     - `flutter pub get`
  - Verify your toolchain:
     - `flutter --version`
     - `dart --version`

## Git Hooks (Pre-commit and Commit Message)

The hooks are versioned and committed under `.githooks/`. You do not need to create these files—just enable them once per clone. After enabling, the hooks will run automatically on `git commit`.

- Pre-commit:
   - Checks Dart formatting (`dart format --set-exit-if-changed`).
   - Runs Flutter analysis and fails on warnings.
  - Commit message:
     - Enforces conventional commit style.
     - Limits header to 72 chars and requires a blank line before the body.

Run the setup script after cloning to enable the hooks:
- `bash .githooks/setup-hooks.sh`

Verify:
- `git config --get core.hooksPath` → should be `.githooks`.
  - `git commit --allow-empty -m "ci: verify hooks"` → hooks should run.
