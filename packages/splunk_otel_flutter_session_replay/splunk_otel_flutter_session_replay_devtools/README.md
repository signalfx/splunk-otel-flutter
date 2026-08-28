# splunk_otel_flutter_session_replay_devtools

Development-only tooling for inspecting what the Splunk session replay capture
engine produces, drawn back over the running application.

This package is not published, and never ships inside a consuming application.
It reads the capture engine's internals on purpose, so it is pinned to a single
minor line of `splunk_otel_flutter_session_replay` and must move with it.

Because nothing but this repository depends on it, it is free to use `dart:io`
and anything else it needs. The capture engine it inspects carries no such
dependency, so applications targeting the web are unaffected.

## Usage

Install the overlay through `MaterialApp.builder`, so that it sits above the
navigator and stays mounted across route changes:

```dart
MaterialApp(
  builder: (context, child) => SessionReplayDebugOverlay(child: child!),
  home: const HomeScreen(),
);
```

A floating button appears in debug builds. Drag it out of the way, or tap it to
open the inspector.

## What it shows

The toolbar switches between three overlay modes:

- **off** — no drawing; capture stops entirely, since nothing is consuming it.
- **bounds** — node rectangles drawn over the live interface. Use this to check
  that captured geometry lines up with what is actually on screen; any
  coordinate-space mistake shows up immediately as a visible offset.
- **replay** — captured fills drawn on an opaque backdrop, showing the wireframe
  roughly as a replay consumer receives it.

Nodes masked for privacy are marked in red in both drawing modes, so it is
possible to confirm at a glance that masking covered what was intended.

Below the toolbar are per-frame statistics and a tree explorer. Selecting a node
highlights it in the overlay. The copy button puts the current frame on the
clipboard as indented JSON, in the same envelope the debug transport uses.

## Streaming to a browser

Passing `streamPort` serves a self-contained player over a local WebSocket:

```dart
SessionReplayDebugOverlay(streamPort: 8090, child: child!);
```

The panel then shows the address to open, along with the number of connected
browsers. The player renders frames to a canvas, keeps the last 600 for the
timeline scrubber, and lets you click either the canvas or the tree to inspect a
node. It reconnects on its own when the application restarts.

The server binds to loopback, which an iOS simulator shares with the host, so
there it works as-is. On Android, carry the host's port to the device's:

```bash
adb forward tcp:8090 tcp:8090
```

Note the direction. `adb reverse` is the opposite, for a device reaching a
server on the host, and will not work here.

Streaming keeps capture running whether or not the panel is open, since the
browser is a consumer in its own right.

### Exposure

This streams the application's interface, including any text that capture was
not asked to mask. It is refused outright in release builds, binds to loopback
unless told otherwise, and holds browser clients to same-origin with a
literal-address `Host` so that a page the user happens to be visiting cannot
open a socket against it and read the interface out of the application.

Binding to a non-loopback address puts that interface on the network in the
clear. Prefer forwarding a port.

## Notes

- The inspector is enabled only in debug builds by default. Pass `enabled` to
  override that.
- Its own interface is wrapped in `ExcludedFromCapture`, so it never appears in
  the frames it is displaying.
- Capture runs only while the overlay or the panel is visible.
