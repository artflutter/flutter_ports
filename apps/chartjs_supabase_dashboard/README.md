# chartjs_supabase_dashboard

A proof of concept of a live dashboard: one line chart of `flutter_chartjs_port` on a Supabase table.

- When the page opens, it signs in as an anonymous Supabase user. The session stays in the storage of the browser, so a reload keeps it. The status bar shows the start of its id.
- Each session sees the shared 6-hour history and its own rows only, and writes its own rows only. Row level security does this in the database, also for Realtime. A job deletes the rows of a session after one day.
- The page loads the newest page of the rows that it can see and starts the realtime channel of the table. A page is the rows of one cell of a grid of 5000 seconds in time. The cell has 1000 slots of 5 seconds, so a page has at most 1000 rows.
- The page asks the table for a new row in each slot of 5 seconds, through the database function `pump_metric`. The function gives a session at most one row in a slot, with the start of the slot as its time. The database makes each value (`metric_value`: smooth value noise of several time scales, with calm and busy periods, that never repeats), so the rows of all open pages give one line. The function inserts at most 200 rows in a slot (40 a second) over all clients. Supabase Realtime sends each new row to the open pages of its session.
- The line has monotone cubic curves (`MonotoneCubicInterpolationMode`): smooth, with no overshoot of the values.
- The view scrolls with the clock in each frame. Its right edge is the newest time that all rows reached, so a new row comes in from the right. The y range eases to the values in view, and the time labels stay on fixed steps of time: an `afterBuildTicks` hook gives the time axis only the ticks of that grid, so the axis makes no tick for each second or millisecond of the range. Each frame changes only the ranges (`chart.updateRanges`), and a new row gives one full update. The points are in the internal form of Chart.js (`parsing: false`, `normalized: true`), and the live view gets only the rows of the last two widths of the view, so an update stays short with many rows in memory. A zoom keeps that List while it holds the view. The chart area keeps one size: the x axis adds no padding for its edge labels, and the y axis has a fixed width. Else the plot jumps each time a tick comes in at an edge.
- A drag, a mouse wheel or a trackpad scroll pans the time axis. A pinch, or Ctrl and the wheel, zooms it around the pointer. The frame ticker applies the wheel pan and the wheel zoom (a trackpad pinch is a wheel zoom), so a frame has one chart update. `flutter_chartjs_plugin_zoom_port` does the drag and the touch pinch. When the left edge of the view comes near the oldest row in memory, the page loads the cell of the newest row before the oldest page. A cell with no row gives no page. An amber vertical line with the label `page <n>` marks the start of each loaded page on the grid, so the lines are at uniform distances. Page 1 is the newest page.
- The toolbar above the chart zooms the time axis: zoom out, the widths 30 s, 2 min, 10 min and 1 h (on a wide chart), and zoom in. The live view keeps its right edge on the newest time, and the history view keeps its center.
- When the view is not at the newest row, the chart stays in place while rows arrive. The button **Live** moves it back. Each button move takes an ease-in-out curve (350 ms for a zoom, 500 to 1400 ms for **Live**, by the distance), and a drag, a wheel or a pinch stops it.
- The bar above the chart shows the realtime state, the rows in memory and the pages, the values sent and received, the time from an insert to its row in the realtime channel, and the frame rate.

## Supabase set-up

1. Turn on "Allow anonymous sign-ins" in Authentication, Sign In / Providers.
2. Open the SQL editor of the project and run [supabase/schema.sql](supabase/schema.sql). The script makes the table, the row level security policies, the functions and the realtime publication. It writes 6 hours of shared history (one value each 5 seconds) into an empty table. A table of an earlier version of the script has rows at other times: the script deletes all rows of such a table first. It also schedules a `pg_cron` job that deletes the rows of a session after one day.
3. Copy `supabase.example.json` to `supabase.json`, and write the project URL and the publishable key into it (Project Settings, API Keys). Git ignores `supabase.json`.

A session can read the shared rows and its own rows, and call `pump_metric`. No client can write the table directly.

## The typed schema

The app uses the pre-release `supabase_flutter` 3.0.0-dev.17 and its typed queries. `lib/supabase_schema.g.dart` holds the row type, the column constants and the typed call of each database function. The Supabase CLI (3.0.0 or newer) generates it from the database with the dev dependency `supabase_typegen`. Run this command in this folder after each change of `supabase/schema.sql`, and commit the file:

```sh
SUPABASE_DB_PASSWORD='<database password>' supabase gen types --lang dart --remote=<project ref> > lib/supabase_schema.g.dart
dart format lib/supabase_schema.g.dart
```

Do not edit the file by hand. The password skips the temporary login role of the CLI, which the database of this project refuses (`DbConfigLoginRoleMissingPrivilegedRoleError`). On Flutter 3.50.0-0.4.pre, the `dart format` call inside the generator does not end: stop that process, and the generator formats with its own formatter. The `dart format` command above then gives the format of the SDK.

## Run

```sh
dart run melos run dashboard
```

The script runs `flutter run -d chrome --dart-define-from-file=supabase.json` in this folder. A debug web build is slow: to judge the motion, add `--release`. The app also runs on macOS: `flutter run -d macos --dart-define-from-file=supabase.json`.

## Deploy

The workflow `pages` (`.github/workflows/pages.yaml`) builds the app on the newest stable, beta and master Flutter, each with WebAssembly and the JavaScript fallback. It deploys them at `https://artflutter.github.io/flutter_ports/dashboard/stable/` (also `beta/` and `master/`). The page `https://artflutter.github.io/flutter_ports/dashboard/` (`tool/pages/dashboard.html`) has one link for each build: `?build=wasm` or `?build=js` selects the build (`web/flutter_bootstrap.js`). The builds read the project URL and the publishable key from the repository variables `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`.

The workflow builds with `--web-content-hash`: the bundle and the assets get a content hash in their file names (`main.dart.<hash>.js`), so a new build misses the cache of the browser. `index.html` and `flutter_bootstrap.js` keep their names, and GitHub Pages lets a browser keep them for up to 10 minutes.

GitHub Pages cannot send the COOP and COEP headers that the WebAssembly renderer needs. `web/isolate.js` adds them through a service worker, as in the lab. A local test of the WebAssembly build needs a server that sends them.

## Code

- `lib/src/metric_source.dart`: the row class and the interface of the table.
- `lib/supabase_schema.g.dart`: the generated typed schema (above).
- `lib/src/supabase_metric_source.dart`: the table through the typed API: `selectOnly` of the columns `id`, `ts` and `value`, the realtime inserts of the same columns (`onTableChangesOnly`) and `rpc.pumpMetric()`. A page goes by `ts`: the time of the newest row before a time, then the rows of its cell.
- `lib/src/live_series.dart`: the rows in memory, the pages, the realtime rows and the pump. The line joins two rows that are at most 1 hour apart (`gapThreshold`). A dashed line joins two rows that are more than 1 hour and at most 2 hours apart (`dashThreshold`, `_drawGaps` of `lib/src/live_chart.dart`). Rows more than 2 hours apart have no line between them.
- `lib/src/live_chart.dart`: the chart, the frame ticker of the live view, the pan, the zoom and the page loads.
- `lib/src/dashboard_page.dart`: the app and the status bar.

The tests use an in-memory table (`test/support/memory_metric_source.dart`) and need no network.
