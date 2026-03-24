# Release Process

This document describes how to release packages to pub.dev using GitLab CI/CD with support for dev, alpha, and stable releases.

## Prerequisites

1. **pub.dev Account**: You need a pub.dev account with publish permissions for the packages
2. **GitLab CI/CD Variables**: Configure the `PUB_CREDENTIALS` variable in GitLab

## Setting Up GitLab CI/CD Variables

1. Go to your GitLab project: **Settings > CI/CD > Variables**
2. Click **Add variable**
3. Set the following:
   - **Key**: `PUB_CREDENTIALS`
   - **Value**: Your pub.dev credentials JSON (see below for how to get this)
   - **Type**: Variable
   - **Environment scope**: `*` (or specific environments)
   - **Protect variable**: ✅ (recommended - only available on protected branches/tags)
   - **Mask variable**: ✅ (recommended - hides value in logs)
   - **Expand variable reference**: ✅

### Getting Your pub.dev Credentials

To get your `PUB_CREDENTIALS` value:

1. **Option 1: Using Flutter CLI** (Recommended)
   ```bash
   flutter pub token add https://pub.dev
   ```
   This will prompt you to authenticate and save the token locally.

2. **Option 2: Manual Token**
   - Go to https://pub.dev/account/tokens
   - Create a new token
   - Copy the token value

3. **Get the credentials JSON**:
   The credentials file is typically located at `~/.pub-cache/credentials.json` and contains:
   ```json
   {
     "accessToken": "your-token-here",
     "refreshToken": "your-refresh-token-here",
     "tokenEndpoint": "https://accounts.google.com/o/oauth2/token",
     "scopes": ["https://www.googleapis.com/auth/userinfo.email", "openid"],
     "expiration": 1234567890
   }
   ```
   
   Copy the entire JSON content and paste it as the `PUB_CREDENTIALS` variable value in GitLab.

## Release Types

The CI/CD pipeline supports three release types:

1. **Dev Releases**: Pre-release versions for development/testing
   - Format: `X.Y.Z-dev.N` (e.g., `1.0.0-dev.1`, `1.0.0-dev.2`)
   - Tag format: `vX.Y.Z-dev.N` (e.g., `v1.0.0-dev.1`)

2. **Alpha Releases**: Early pre-release versions
   - Format: `X.Y.Z-alpha.N` (e.g., `1.0.0-alpha.1`, `1.0.0-alpha.2`)
   - Tag format: `vX.Y.Z-alpha.N` (e.g., `v1.0.0-alpha.1`)

3. **Stable Releases**: Production-ready versions
   - Format: `X.Y.Z` (e.g., `1.0.0`, `1.0.1`, `1.1.0`)
   - Tag format: `vX.Y.Z` (e.g., `v1.0.0`)

## Release Process

### Step 1: Update Version Numbers

Before releasing, update the version numbers in **both** package `pubspec.yaml` files to the version you want to release:

- `packages/splunk_otel_flutter/splunk_otel_flutter_platform_interface/pubspec.yaml`
- `packages/splunk_otel_flutter/splunk_otel_flutter/pubspec.yaml`

Also keep the `rum.sdk.flutter.version` telemetry value in sync with the package version by updating it in all three locations:

- Dart: `rumSdkFlutterVersion` constant in `packages/splunk_otel_flutter/splunk_otel_flutter/lib/src/rum_sdk_version.dart`
- Android: `rumSdkFlutterVersion` in `packages/splunk_otel_flutter/splunk_otel_flutter/android/build.gradle` (BuildConfig `RUM_SDK_FLUTTER_VERSION`)
- iOS: `rumSdkFlutterVersion` in `packages/splunk_otel_flutter/splunk_otel_flutter/ios/splunk_otel_flutter/Sources/splunk_otel_flutter/SplunkRumFlutterVersions.generated.swift`

**Important**: Both packages must have the same version number!

Examples:
- **Dev release**: Update both to `1.0.0-dev.1`
- **Alpha release**: Update both to `1.0.0-alpha.1`
- **Stable release**: Update both to `1.0.0`

### Step 2: Commit and Push

Commit your version changes and push to GitLab (can be from GitHub mirror):

```bash
git add packages/splunk_otel_flutter/splunk_otel_flutter_platform_interface/pubspec.yaml
git add packages/splunk_otel_flutter/splunk_otel_flutter/pubspec.yaml
git commit -m "chore: bump version to 1.0.0-dev.1"
git push origin main  # or push to GitHub and let it mirror to GitLab
```

**Note**: No tags needed! The version is read directly from `pubspec.yaml` files.

### Step 3: Trigger Pipeline

1. Go to **CI/CD > Pipelines** in GitLab
2. Click **Run pipeline** button
3. Select the branch/commit you want to release from (e.g., `main`, `release/1.0.0`, or a specific commit SHA)
4. Click **Run pipeline**

The pipeline will automatically:
1. **Setup**: Install Flutter dependencies
2. **Build**: Validate packages (analyze and test)

### Step 4: Run Dry Run

After the pipeline starts:

1. Find the **dry_run** job
2. Click **Play** button to run it manually

This will validate that:
- Versions match between both packages
- Packages can be published
- Dependencies are correct
- No publishing errors occur

**Important**: Always run the dry run first before the actual release!

### Step 5: Publish to pub.dev

If the dry run succeeds:

1. Find the **release** job
2. Click **Play** button to run it manually

This will:
1. Validate versions match between packages
2. Publish `splunk_otel_flutter_platform_interface` first (since it's a dependency)
3. Wait 15 seconds for pub.dev to process it
4. Publish `splunk_otel_flutter`

**Warning**: This will actually publish to pub.dev!

## CI/CD Job Details

### `setup_dependencies`
- Installs Flutter dependencies
- Caches dependencies for faster builds
- Runs automatically when pipeline is triggered

### `build_artifacts`
- Validates packages with `flutter analyze`
- Runs tests with `flutter test`
- Runs automatically when pipeline is triggered
- Creates artifacts for subsequent jobs
- Can be run from any branch/commit

### Dry Run Job

#### `dry_run`
- Tests publishing without actually publishing
- Can be run from any branch/commit
- Reads version from `pubspec.yaml` files
- Validates that both packages have the same version
- Validates that packages can be published
- Manual trigger only
- Safe to run multiple times

### Release Job

#### `release`
- Actually publishes packages to pub.dev
- Can be run from any branch/commit
- Reads version from `pubspec.yaml` files
- Validates that both packages have the same version
- Publishes in dependency order (platform interface first, then main package)
- Manual trigger only
- **Warning**: This will publish to pub.dev!

## Version Naming Examples

Simply update the version in both `pubspec.yaml` files to the version you want to release:

### Dev Releases
```
Version in pubspec.yaml: 1.0.0-dev.1
Branch/Commit: Any branch or commit
Job to run: dry_run → release

Version in pubspec.yaml: 1.0.0-dev.2
Job to run: dry_run → release
```

### Alpha Releases
```
Version in pubspec.yaml: 1.0.0-alpha.1
Branch/Commit: Any branch or commit
Job to run: dry_run → release

Version in pubspec.yaml: 1.0.0-alpha.2
Job to run: dry_run → release
```

### Stable Releases
```
Version in pubspec.yaml: 1.0.0
Branch/Commit: Any branch or commit
Job to run: dry_run → release

Version in pubspec.yaml: 1.0.1  (patch release)
Job to run: dry_run → release

Version in pubspec.yaml: 1.1.0  (minor release)
Job to run: dry_run → release

Version in pubspec.yaml: 2.0.0  (major release)
Job to run: dry_run → release
```

**Note**: 
- No tags needed! Just update `pubspec.yaml` and run the pipeline from any branch/commit.
- Always use the same two jobs: `dry_run` and `release`
- For stable releases, use semantic versioning:
  - **Patch** (1.0.0 → 1.0.1): Bug fixes
  - **Minor** (1.0.0 → 1.1.0): New features, backward compatible
  - **Major** (1.0.0 → 2.0.0): Breaking changes

## Troubleshooting

### Error: PUB_CREDENTIALS not set
- Ensure the `PUB_CREDENTIALS` variable is configured in GitLab CI/CD settings
- Check that the variable is not protected if you're testing on unprotected branches

### Error: Version mismatch between packages
- Ensure both `pubspec.yaml` files have the exact same version
- Check `packages/splunk_otel_flutter/splunk_otel_flutter_platform_interface/pubspec.yaml`
- Check `packages/splunk_otel_flutter/splunk_otel_flutter/pubspec.yaml`
- Both must have identical version strings

### Error: Package already exists
- Check if the version already exists on pub.dev
- Update the version number in `pubspec.yaml` files
- For dev/alpha, increment the number (e.g., `-dev.1` → `-dev.2`)

### Error: Dependency not found
- Ensure `splunk_otel_flutter_platform_interface` is published before `splunk_otel_flutter`
- The CI pipeline handles this automatically, but manual publishing requires correct order

### Dry run passes but release fails
- Check pub.dev status page
- Verify credentials are still valid
- Check package names and versions match pub.dev requirements
- Ensure both packages have the same version number

## Security Notes

- **Never commit credentials** to the repository
- Always use GitLab CI/CD variables for sensitive data
- Mark `PUB_CREDENTIALS` as protected and masked
- Rotate credentials periodically
- Use separate credentials for different environments if needed

## Related Files

- `.gitlab-ci.yml` - GitLab CI/CD configuration
- `packages/splunk_otel_flutter/splunk_otel_flutter/pubspec.yaml` - Main package configuration
- `packages/splunk_otel_flutter/splunk_otel_flutter_platform_interface/pubspec.yaml` - Platform interface configuration
