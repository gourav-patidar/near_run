# NearRun

Offline-first run tracker built with Flutter. Records your GPS route, distance,
pace, and elevation into a local SQLite database — no account, no internet
required after the first app launch.

## What it does

- **Home** — big Start Run button, your most recent run's route, a rotating
  training tip.
- **Active run** — live map with OSM tiles, animated route polyline, pace /
  duration / elevation stats, pause/resume, foreground notification so the
  OS doesn't kill tracking when the screen locks.
- **Run Summary** — shown after you stop a run. Choose Save or Discard. Also
  reachable from History (Close / Delete) or the Last Run card on Home.
- **History** — every saved run as a card with its real route drawn inline.
- **Profile** — total distance, total runs, current day-streak, weekly
  intensity bars, earned badges. All derived from your actual runs.

## Architecture

```
lib/
├── main.dart                        # App shell, 3-tab IndexedStack
├── core/
│   ├── models/run_model.dart        # RunModel, LocationPoint, RunStats
│   ├── services/
│   │   ├── gps_tracking_service.dart  # Permission flow + GPS stream
│   │   └── database_service.dart      # sqflite CRUD + aggregates
│   ├── theme/                       # M3 color + text theme
│   └── widgets/
│       ├── app_bottom_nav.dart      # Glass-blur 3-tab nav
│       └── route_preview.dart       # Offline route renderer (canvas)
└── features/
    ├── home/                        # Start-run landing + last-run preview
    ├── active_run/                  # Live GPS + map screen
    ├── run_summary/                 # Post-run save/discard or read-only view
    ├── history/                     # All saved runs
    └── profile/                     # Stats, streak, badges, weekly bars
```

Each feature follows **view + ViewModel (`ChangeNotifier`)**, wired via
`provider`. The services are singletons (`GpsTrackingService.instance`,
`DatabaseService.instance`).

## Data flow at a glance

1. User taps **Start Run** → `ActiveRunViewModel` requests location
   permission, starts `flutter_foreground_task`, subscribes to the GPS stream.
2. Every position update appends to an in-memory route and recomputes distance /
   pace / elevation. UI rebuilds once per second.
3. Long-press **Hold to Stop** → VM returns an unsaved `RunModel`; screen
   pushes `RunSummaryScreen` with it.
4. **Save** writes to SQLite via `DatabaseService.createRun`. **Discard**
   throws it away.
5. Home / History / Profile all read back from SQLite on focus.

## Offline-first design choices

- Maps: `flutter_map` + OpenStreetMap tiles. Missing tiles render blank so the
  route polyline still shows. No network = still records runs.
- Route previews in Home / History / Summary are drawn with a plain `CustomPainter` (`RoutePreview`). Zero tile fetches, works in airplane mode.
- No analytics, crash reporters, weather APIs, or any other network call.
- Database lives in the app's private storage — your runs stay on your device.

## Permissions

### Android

| Permission | Why |
|---|---|
| `ACCESS_FINE_LOCATION` | GPS route |
| `ACCESS_COARSE_LOCATION` | Fallback / initial lock |
| `ACCESS_BACKGROUND_LOCATION` | Tracking when screen is off (optional) |
| `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_LOCATION` | Persistent GPS |
| `POST_NOTIFICATIONS` | Android 13+ foreground-service notification |
| `INTERNET` | Tile downloads (optional — app works offline) |
| `WAKE_LOCK` | Keep CPU awake for GPS updates |

The permission flow requests **foreground location first**. Background is
*optional* — requested in the background, never blocks. This fixes the Samsung
issue where chaining foreground + background requests caused the OS to swallow
the prompt silently.

### iOS

- `NSLocationWhenInUseUsageDescription` + `NSLocationAlwaysUsageDescription`
- `UIBackgroundModes: location`

## Getting started

```bash
flutter pub get
flutter run
```

Min Flutter version: 3.35.5 / Dart 3.9.2.

## Limitations / not yet implemented

- No Bluetooth heart-rate sensor integration (BPM is always 0; UI shows "no HR
  data" in Profile).
- OSM tiles are not persistently cached to disk. Once a region is loaded
  you'll see it again in the same session, but after restart tiles re-download
  when online. The route itself is always drawn from local data.
- No user profile editing yet — the name defaults to "Runner".

## Tech stack

- `flutter` 3.35.5
- `provider` — state management
- `geolocator` + `permission_handler` — GPS + runtime permissions
- `flutter_foreground_task` — background GPS survival on Android
- `flutter_map` + `latlong2` — interactive map with OSM tiles
- `sqflite` + `path_provider` — local persistence
- `wakelock_plus` — keeps the screen awake during an active run
- `intl` — date formatting
- `google_fonts` — Plus Jakarta Sans typography

## License

Private / proprietary.
