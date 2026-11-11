# chartjs_gallery

Gallery and visual test bed for [`flutter_chartjs_port`](../../packages/flutter_chartjs_port), on Android,
iOS, web and macOS. It shows every Chart.js chart type with the charts of the
[Chart.js docs](https://www.chartjs.org/docs/latest/charts/) and runs each one through the ported
controllers and plugins. Each chart shows the legend, and the tooltip on a hover or a tap. With
the keyboard focus, the arrow keys move over the legend items and the elements, Enter or Space
clicks, and Escape clears the hover. The app follows the platform brightness, and the charts take
the light or the dark chart theme. The Area page has the fill actions `origin`, `start`, `end` and
`false` of the Area sample as its variants. The page "Phase 3: canvas and host" has the canvas,
element, core and scale demos and the stress tests.

The type pages and the core and scale demos show their chart in the public widget `ChartView` and
import `package:flutter_chartjs_port/flutter_chartjs_port.dart`. The demos that draw without a
chart, the stress host `HOST=canvas` and the white-box tests also import files of `lib/src/`: the
comment above each such import gives the reason.

From the repository root:

```sh
dart run melos run gallery                # Chrome
dart run melos run gallery:macos          # macOS
dart run melos run gallery:device         # connected Android/iOS device, emulator or simulator
dart run melos run gallery:build:web      # web build (WebAssembly with a JavaScript fallback)
dart run melos run gallery:build:android  # debug APK
dart run melos run gallery:build:ios      # iOS build without code signing
```

CI builds the web, Android and iOS targets on every push and pull request.

`web/flutter_bootstrap.js` sets `preferWebParagraph: true`
([flutter/flutter#172561](https://github.com/flutter/flutter/issues/172561),
from Flutter 3.50): the browser lays out and draws the text with the fonts of
the system. That path needs CanvasKit and the Enhanced TextMetrics API, which
Chrome has behind the flag
`chrome://flags/#enable-experimental-web-platform-features`. A browser with the
API takes the JavaScript build with CanvasKit. Each other browser keeps its
default build. `dart run melos run gallery` starts Chrome with the API.

Not published (`publish_to: none`).

## Indexed-color stress test

Open **Phase 3: canvas and host → Stress → Charts**, select **Line**, **Bar** or
**Radar**, choose **5k** items and **Full update**, then expand **Options** and
turn on **Indexed colors**. The colors alternate blue/pink, matching **Scriptable
colors**. These switches are mutually exclusive; turn both off for a static color.
Use **Run test** if paused, and expand **Diagnostics** to compare update timings.
Use a profile or release build for performance comparisons.

From this directory, launch the profile directly:

```sh
flutter run -d macos --profile -t lib/main_stress.dart \
  --dart-define=MODE=chart --dart-define=TYPE=line \
  --dart-define=CALL=update --dart-define=SCENARIO=5000x0 \
  --dart-define=INDEXED=1
```

`INDEXED` defaults to 0 and cannot be combined with `SCRIPTABLE=1`. Indexed runs
add `indexed: true` to their `STRESS` output; existing benchmark cases and default
profiling configurations keep their previous colors.

## Official-site design drafts

Three Flutter-only directions for the broader flutter_ports initiative:
**Signal** (blue and white), **Workbench** (dark and lime), and **Fieldnotes**
(warm editorial). Switch designs in the preview toolbar. Chart.js is the first
live demo, not the scope of the initiative.

Run from this directory:

```sh
flutter run -d web-server --web-port 8791 --target lib/main_site_drafts.dart
```

Open `http://localhost:8791` in VS Code's built-in browser. Direct selections use
`?design=signal`, `?design=workbench`, or `?design=fieldnotes`.

For a release preview with WebAssembly and Flutter's JavaScript fallback:

```sh
flutter build web --wasm --target lib/main_site_drafts.dart --output build/site_drafts
python3 -m http.server 8791 --directory build/site_drafts
```

The **Awesome Flutter Ports** section credits independent community projects.
Its initial entries were checked against their maintainers' package descriptions:
[highlighting](https://pub.dev/packages/highlighting),
[turf](https://pub.dev/packages/turf), and
[supercluster](https://pub.dev/packages/supercluster).
Project and suggestion buttons show copyable destinations in these design drafts;
they do not submit suggestions. Community packages are not bundled in the demo.

Validate the layouts and interactions with
`flutter test test/site_drafts_test.dart`. These are local design drafts, not a
published official site.

### Package activity snapshots

Every port and community entry shows its last default-branch commit, commits in
the trailing 90 days, latest pub.dev release, and separate open issue and PR
counts (draft PRs included). Our monorepo activity is filtered by package path;
issue/PR totals are shared repository counts. Community activity is repository
wide. Commits include docs and maintenance, not only features.

Refresh the public metadata before building the preview:

```sh
python3 tool/refresh_site_stats.py
```

The tool uses `gh api` for GitHub and the public pub.dev API for releases. It
writes `assets/site_drafts/package_stats.json`, which Flutter bundles for offline
rendering. API failures become unknown values, not zero counts; the command exits
nonzero if any lookup failed. Only a pub.dev 404 means unpublished. No API token
or runtime network request is included in the app. The checked timestamp is shown
in UTC; snapshots older than seven days are labeled "Older snapshot". This draft
has a manual refresh, not a scheduled background service.
