# splunk_otel_flutter_session_replay_devtools

Development-only tooling for inspecting what the Splunk session replay capture
engine produces, drawn back over the running application.

This package is not published. It reads the capture engine's internals on
purpose, so it is pinned to a single minor line of
`splunk_otel_flutter_session_replay` and must move with it.

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

## Notes

- The inspector is enabled only in debug builds by default. Pass `enabled` to
  override that.
- Its own interface is wrapped in `ExcludedFromCapture`, so it never appears in
  the frames it is displaying.
- Capture runs only while the overlay or the panel is visible.
