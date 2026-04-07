# SmartCinema - Splunk Flutter SDK Demo App

A demo cinema app that showcases the **modular Splunk Flutter SDK architecture** with `splunk_otel_flutter` (core RUM) and `splunk_otel_flutter_session_replay` (session replay) as separate packages sharing the same native singleton.

## Running

```bash
flutter run \
  --dart-define=REALM=your_realm \
  --dart-define=RUM_ACCESS_TOKEN=your_token
```

## How to Use the App

### Happy Path

1. **Welcome Screen** - Tap **"Get Started"**.
2. **Login Screen** - Enter one of the valid emails (`jan@smartlook.com`, `ondrej@smartlook.com`, or `pavel@smartlook.com`) with any password, then tap **"Login"**.
3. **Home Screen** - Browse the movie catalog.

### Testing Failed Login

On the **Login Screen**, enter any email containing `@` that is not one of the three valid emails above, then tap **"Login"**. A snackbar appears: *"Login failed. Please try it again."* This is tracked as a custom event with `status: failed`.

### Testing Forgot Password

On the **Login Screen**, tap **"Forgot Password?"**. Enter one of the valid emails and tap **"Submit"** for a success bottom sheet, or any other `@` email for a failure bottom sheet.

### Intentional Crashes

The app has two places where it deliberately calls `exit(0)` to simulate a crash, useful for testing crash reporting:

- **Login Screen** - Enter text **without an `@` symbol** (e.g., `test`) and tap **"Login"**. The app terminates immediately.
- **Forgot Password Screen** - Enter text **without an `@` symbol** and tap **"Submit"**. Same behavior.

These force-exit scenarios let you verify that the native crash reporting module captures the termination and that session replay records the user's actions leading up to the crash.

## SDK Integration Overview

### Initialization (`main.dart`)

The app initializes both SDK packages sequentially at startup:

1. **Core RUM agent** - `SplunkRum.instance.install(...)` initializes the native singleton with endpoint configuration, app name, and deployment environment.
2. **Session replay start** - `SplunkSessionReplay.instance.start()` begins recording via the shared native singleton.
3. **State verification** - Queries `state.getStatus()` to confirm session replay is active.
4. **Recording mask** - Sets a `RecordingMaskList` with two elements: a `covering` mask (200x100 at origin) and an `erasing` mask (100x50 at offset 50,50). Then reads it back to verify the round-trip through the Pigeon bridge.

### Sensitive Screen - Stop/Start Recording (`forgot_password.dart`)

The **Forgot Password** screen demonstrates pausing session replay on sensitive screens. It uses Flutter's `RouteAware` mixin with a global `RouteObserver` to detect all navigation transitions:

- **`didPush`** - User navigated to this screen: **stops** recording.
- **`didPopNext`** - User returned to this screen after popping a pushed route: **stops** recording again.
- **`didPop`** - User left this screen by pressing back: **resumes** recording.
- **`didPushNext`** - Another screen was pushed on top: **resumes** recording.

This ensures recording is always paused while the sensitive screen is visible, and always resumed when leaving it - regardless of whether the user goes forward or pops back.

### Navigation Tracking

Manual screen tracking via `SplunkRum.instance.navigation.track(screenName:)` is called on each navigation transition (Welcome -> Login, Login -> Forgot Password, Login -> Home).

### Custom Events (`login_screen.dart`, `forgot_password.dart`)

Login success/failure and password reset events are tracked via `SplunkRum.instance.customTracking.trackCustomEvent(...)` with structured attributes (status, reason, user email).

### Intentional UI Bug - Welcome Screen Overflow

The **Welcome Screen** has a known layout issue: on devices with safe area insets (notch, Dynamic Island, home indicator), the `Column` inside `CustomScaffold` overflows by ~18 pixels at the bottom. This is **intentionally left as a demonstration** of the kind of visual bug that session replay helps identify - the yellow/black overflow stripe is captured in the session recording, making it easy to spot in replay without needing to reproduce it on a specific device.

## App Flow

```
Welcome Screen ──> Login Screen ──> Home (Movies)
                        │
                        └──> Forgot Password (sensitive - recording paused)
                                    │
                                    └──> Back to Login (recording resumed)
```

## Architecture

This app uses both Flutter SDK packages simultaneously, proving the modular architecture:

- `splunk_otel_flutter` - Core RUM (initialization, navigation, custom tracking, global attributes)
- `splunk_otel_flutter_session_replay` - Session replay (start, stop, status, rendering mode, recording masks)

Both packages bridge to the same native `SplunkRum` singleton via separate Pigeon channels.
