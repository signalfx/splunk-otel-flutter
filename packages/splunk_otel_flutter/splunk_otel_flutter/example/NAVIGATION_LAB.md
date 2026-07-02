# Navigation Lab

Manual test harness for the `SplunkNavigatorObserver` across the three supported
navigation approaches. Each routing library gets its own entrypoint but shares
the same presentational screens (`lib/navigation_lab/lab_views.dart`) and the
same RUM install (`lib/navigation_lab/rum_setup.dart`, native auto-tracking OFF).

## Run

```bash
# Navigator 1.0 (imperative, named routes)
flutter run -t lib/main_navigator.dart \
  --dart-define=REALM=<realm> --dart-define=RUM_ACCESS_TOKEN=<token>

# go_router (declarative / Navigator 2.0)
flutter run -t lib/main_go_router.dart \
  --dart-define=REALM=<realm> --dart-define=RUM_ACCESS_TOKEN=<token>

# auto_route (codegen). Generate routes once, then run:
dart run build_runner build
flutter run -t lib/main_auto_route.dart \
  --dart-define=REALM=<realm> --dart-define=RUM_ACCESS_TOKEN=<token>
```

The original full-feature demo remains at `lib/main.dart` (also Navigator 1.0).

## How each entrypoint wires the observer

| Entrypoint | Connection point |
|---|---|
| `main_navigator.dart` | `MaterialApp(navigatorObservers: [SplunkNavigatorObserver()])` |
| `main_go_router.dart` | `GoRouter(observers: [SplunkNavigatorObserver()])` |
| `main_auto_route.dart` | `appRouter.config(navigatorObservers: () => [SplunkNavigatorObserver()])` |

No entrypoint makes the SDK depend on the routing library: the app passes the
observer into each library's observer slot.

## What to verify (in Splunk RUM: "UI Navigation" / `screen.name`)

| Action | Expected |
|---|---|
| App launch | One navigation event for the initial screen (`Home`). |
| Open Details | `screen.name` = `Details/42` (Navigator) or `Details` (go_router/auto_route). |
| Push Details again | New event (Navigator uses per-id names; go_router/auto_route use the static `Details` name, so a consecutive push is deduplicated by name). |
| Back from a screen | Event for the revealed screen (pop path). |
| Open Settings | `screen.name` = `Settings`. |
| Open Tabs, switch tabs | Navigation event for `Tabs` on entry; switching tabs emits NOTHING (IndexedStack pushes no route). |
| Show Dialog | No navigation event (popup routes are ignored by default). |
| Manual track() | `screen.name` = `ManualScreen` with a custom `source` attribute. |
| Any later span/log | Inherits the most recent `screen.name`. |

Notes:
- Session replay is enabled (`SessionReplayModuleConfiguration(samplingRate: 1.0)`
  + `SplunkSessionReplay.instance.start()` in `rum_setup.dart`), so you can also
  watch the recorded session in Splunk RUM and confirm screen names line up with
  the replay timeline.
- Attribute forwarding requires the bumped native pins (Android `2.3.1`, iOS
  `2.3.1`); run `flutter clean` if you have stale caches.
- Popup routes are ignored by default; pass `SplunkNavigatorObserver(trackPopupRoutes: true)` to include them. Even then, unnamed popups need a `viewNamePredicate` to produce a name.
- To rename/suppress screens or attach route attributes, use the
  `viewNamePredicate` / `shouldTrackView` / `attributesFromRoute` hooks.
