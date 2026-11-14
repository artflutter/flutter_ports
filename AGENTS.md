# Agent onboarding

Dart pub workspace + Melos 8 monorepo of native Dart/Flutter ports of JavaScript chart
libraries. First port: Chart.js v4.6.1 →
`packages/flutter_chartjs_port`. Second port: D3 v7.9.0 →
`packages/flutter_d3_port`, in phase 0 (scaffold and design, no ported code). Third port: Apache
ECharts 6.1.0 with its renderer zrender 6.1.0 → `packages/flutter_echarts_port`, in phase 0
(scaffold and design, no ported code). Fourth port: chartjs-plugin-zoom 2.2.0+fb81d331, an add-on
of the Chart.js port (ADR 0009) → `packages/flutter_chartjs_plugin_zoom_port`, phases 1-4 done
(each file of `src/` ported; the specs, the fixtures and the tests of real input pass), phase 5
next. Fifth port: chartjs-chart-sankey 0.19.1, an add-on of the Chart.js port and the first chart
type of another package → `packages/flutter_chartjs_chart_sankey_port`, phases 0-4 done (each
file of `src/` ported; the unit tests, the specs and the fixtures pass; a gallery page), phase 5
next. Sixth port: @kurkle/color 0.3.2, the color library of the Chart.js port →
`packages/flutter_kurkle_color_port`, a package of its own (version 0.1.0, on pub.dev), with no
import of another port.

## Commands

Run from the repository root. `melos` is a dev dependency: use `dart run melos …`.

Chart.js ADR 0061: the historical "pure layer" names below now mean framework-free
core layers. They may use `dart:ui.Color`, but no `package:flutter` framework APIs.
One exception: a core layer can import `package:flutter/animation.dart` for the curve
classes (`Curve`, `Curves`), the value of the option `easing` (row `adapt-flutter-curves`).
A second exception: a core layer can import `package:flutter/painting.dart` with `show` of
`EdgeInsets`, `TextStyle` and `TextOverflow`, for padding and fonts (Chart.js ADRs 0123 and 0116).
The chart core and harness run through Flutter; standalone Dart execution is no
longer supported. No global color installer exists. Paint options carry `ChartPaint` end to end (ADR 0128); solid paints contain Flutter `Color`. Theme tokens, palette entries, shadow colors and gradient stops remain `Color`.

- `flutter pub get`: resolve the whole workspace (single root `pubspec.lock`).
- `dart run melos run format` / `format:check`
- `dart run melos run analyze`: `dart analyze --fatal-infos` over the workspace.
- `dart run melos run test --no-select`: `flutter test --exclude-tags fixtures,golden` in every
  package with a `test/` dir, with up to two packages running in parallel. Flutter keeps its
  default test-file concurrency within each package. `--no-select` skips the interactive package
  picker. Options after `--` go to each `flutter test` call, for example
  `dart run melos run test --no-select -- --experimental-faster-testing --total-shards=3 --shard-index=0`.
  Without `--`, melos stops with an error. The CI job `test` runs this command with the shard
  indexes 0, 1 and 2 on each OS, in bash. `--experimental-faster-testing` compiles the test files of a package into one test app and runs
  each file in its own engine. Flutter ignores the flag for a package with one test file. On a
  16-core Mac, the flag makes the local run slower. Thus the script does not set it. The flag writes
  Dart files into `build/isolate_spawning_tester/` of each package, and `format:check` fails on
  them. Delete these folders before `format:check`. package:test puts a part of the tests of each
  file in each shard, in the order of the file ([Tests](#tests)). A shard with no tests fails. On
  ubuntu, CI also fetches the three Chart.js submodules, `third_party/d3`, the two ECharts
  submodules, `third_party/chartjs-plugin-zoom` and `third_party/chartjs-chart-sankey` by path in
  each shard, for the `test/upstream_test.dart` of `flutter_chartjs_port`, `flutter_d3_port`,
  `flutter_echarts_port`, `flutter_chartjs_plugin_zoom_port` and
  `flutter_chartjs_chart_sankey_port`.
- `dart run melos run test:web`: the `flutter_chartjs_port`, `chartjs_test_utils` and
  `flutter_kurkle_color_port` tests without
  `@TestOn('vm')`, in Chrome through Flutter (JavaScript/DDC and WebAssembly). `tool/test_web.dart`
  selects browser-capable files before compilation. A leg fails when it ends by a signal or exits
  with 0 without the summary of a run that passed: `flutter test` exits with 0 when a SIGTERM stops
  it. It needs a local Google Chrome. CI job: `test-web`.
- `dart run melos run check:port`: the port checks of
  `packages/flutter_chartjs_port/doc/porting-flow.md` §4 (tools 1-3 and the checks of tools 6 and 8)
  and tool 9, and `options:gen:check`, as melos steps. The CI job `port-checks` runs the seven
  checks with a shallow checkout of the three Chart.js submodules,
  `third_party/chartjs-plugin-zoom` and `third_party/chartjs-chart-sankey`. `check:lib-imports`,
  `check:headers` and `check:js-semantics` also examine the add-on ports
  `flutter_chartjs_plugin_zoom_port` and `flutter_chartjs_chart_sankey_port` (ADR 0009 item 6).
  The other four checks examine only `flutter_chartjs_port`.
  Each check can also run alone:
  - `check:lib-imports`: the import allowlists of `lib/`, of the pure layers and of the tests that
    the web legs compile. It also fails when a ported file imports `lib/src/theme/`, and when a
    file of `lib/src/widgets/` imports a file of `controllers/`, `scales/`, `elements/` or
    `plugins/`, or `lib/src/index.dart`: the widget registers no
    component (Chart.js ADR 0048 §3). It fails when a ported file imports `lib/src/typed/`, and
    when a file of `lib/src/typed/` imports a library outside the allowlist of Chart.js ADR 0052
    §8. It fails when a core layer imports `package:flutter/painting.dart` with a name other
    than `EdgeInsets`, `TextStyle` and `TextOverflow` (Chart.js ADRs 0123 and 0116). It keeps the
    `lib/pure.dart` closure of `packages/chartjs_test_utils` a pure layer. An
    add-on port names its host in the top-level key `host` of its `tool/port_sources.yaml`. Its
    `lib/` and `test/` import only the libraries directly in the `lib/` of the host
    (`package:<host>/<name>.dart`), never `package:<host>/src/` (ADR 0009 item 3). Its `test/`
    imports only `package:chartjs_test_utils/flutter.dart` and `pure.dart` of the harness. The
    script passes `packages/flutter_chartjs_port packages/flutter_chartjs_plugin_zoom_port
    packages/flutter_chartjs_chart_sankey_port`, host first: the check examines the harness closure
    with the host only.
  - `check:headers`: the line-1 header of each Dart file in `lib/`, `test/` and `tool/` of the home
    package and of each package that a `dart` target of its `tool/port_sources.yaml` names. The
    script runs it four times: `flutter_chartjs_port` with `chartjs_test_utils`, then
    `packages/flutter_chartjs_plugin_zoom_port` alone, then
    `packages/flutter_chartjs_chart_sankey_port` alone, then `packages/flutter_kurkle_color_port`
    alone. The primary project of the home is the
    entry whose `version_source` is `<constant> in <home>/lib/src/upstream.dart` (Chart.js,
    chartjs-plugin-zoom, chartjs-chart-sankey, @kurkle/color). Its `version` is `v<constant value>`, the port-only marker names it, and
    a backport line names the `<owner>/<repo>` of its `url`. The top-level key `marker` of the file
    gives the tag of the `DIVERGES(<tag>)` markers (default `chartjs`). A directory target maps
    `.tests.js` and `.spec.js` to `_test.dart`. Only a `differences.md` table with the first
    header cell `ID` has rows; a `Reserved ID` table has none. It compares the project, license
    and holder with the `tool/port_sources.yaml` of the home, the `LICENSE` of the package that
    contains the file and `REUSE.toml`. It also fails on a source path that is not at the pin, or
    on a Dart path that is not the mapped path. A port-only file at the mapped path of a pinned
    source also fails. It compares each submodule gitlink with its `commit` in
    `port_sources.yaml`.
  - `check:js-semantics`: Dart forms that give other results than JavaScript. It examines the
    `lib/` and `test/` files of the given packages and of `chartjs_test_utils` whose header names a
    `js` project. It reads the `language` of each project from the `tool/port_sources.yaml` of
    each given package; the first entry of a project counts. Its advice names the JS runtime:
    `lib/src/js/`, or `package:flutter_chartjs_port/js_semantics.dart` in an add-on. It resolves
    types with `package:analyzer` to find the interpolation of
    `double` and `num` values. It also fails on `DateTime.now(`: ported code reads the time with
    `clock.now()` of package:clock (Chart.js ADR 0143).
  - `port:next:check`: the check mode of tool 8 (`port:next`, below).
  - `parity:check`: the check mode of tool 6 (`parity`, below).
  - `check:typed-reads`: tool 9, the ratchet of the by-name forms (Chart.js ADR 0054). For each
    file of `packages/flutter_chartjs_port/lib/src` outside `lib/src/js/` and
    `lib/src/options/`, it counts in the code (not in comments or strings) `jsGet(`, `jsGetKey(`,
    an index with one string literal (read or write), a call of `jsCall*`, `jsObjectKeys(`,
    `extends MapBase`, `with MapMixin` and `Map` in an `implements` clause. `jsGetIndex` does not
    count. It fails when a count is above its baseline in `tool/typed_reads/<path>.txt` (one file
    for each source file, one line `<form> <count>` for each form; no file means 0), and on a
    stale or bad baseline. A lower count passes with a note. `-- --update` writes the baselines
    from the tree and keeps their `#` lines. Since the close step of Chart.js ADR 0054, each
    baseline is an allowlist entry: its `#` lines give the reason of each by-name form that stays
    (an object of the user, the generic walk of the resolvers, a function of the user, a
    dictionary by name of upstream). No change raises a count without a reason line. The
    structural rule: a class, a mixin or an extension type of `lib/src` outside `lib/src/js/`
    (also of `lib/src/options/`) with a Map supertype (`Map`, or a name that ends with `Map`,
    `MapBase`, `MapMixin` or `MapView`) is an error, with no baseline.
  - `options:gen:check`: the check mode of `options:gen` (below).
- `dart run melos run options:gen`: writes the typed option scopes of `flutter_chartjs_port`
  (`lib/src/options/option_keys.g.dart`, `scope_kinds.g.dart` and `scopes.g.dart`) and the
  resolved element options (`resolved.g.dart`) from the
  hand-written schema `tool/options_schema.yaml` through `tool/options_gen.dart`, formatted
  (Chart.js ADR 0054 §2). Edit the schema, never a `.g.dart` file. `options:gen:check` generates
  into `.dart_tool/options_gen_check/` and fails when a committed file differs or when
  `lib/src/options/` has a `.g.dart` file that the generator does not write. The analyzer
  excludes `**/*.g.dart`.
- `dart run melos run test:cases`: tool 5. It runs `test/specs/` and reports each upstream case of
  `doc/upstream/manifest.json` as passed, failed, skipped or missing. It fails on an unknown test
  name, a bad skip reason and a missing case of a `ported` module. CI runs it in the ubuntu `test`
  leg of shard 0. It passes `--exclude-tags fixtures`, as tool 6 does. It also fails on a stale
  `blocked: <module>` skip literal in `test/` (each `src/` row of the module `ported`), on an
  unknown module and on a `blocked:` literal in another form than `blocked: <module>` (Chart.js ADR
  0041). The check reads the string literals of `test/` without `test/tool/` and without the
  generated `*_reference*.dart` files. `test:fixtures` runs the same check.
- `dart run melos run test:fixtures`: tool 7, the fixture smoke tests of `flutter_chartjs_port`
  (Chart.js ADR 0029). It is tool 5 with `--fixtures`: it runs the tests with the tag `fixtures` of
  the spec files with a fixture group and of `test/port/fixtures/`. It reports each upstream fixture
  as passed, failed, skipped or missing, and prints the 10 slowest tests. It fails on a failed,
  missing or unknown fixture, on a fixture group that no Dart file calls and on a bad skip reason.
  It also runs the stale-block check of `test:cases` (Chart.js ADR 0041). The runner compares the
  SHA-256 of each upstream fixture file `third_party/Chart.js/test/fixtures/<path>` with the
  manifest. Without the submodule, each fixture skips with `'n/a: the submodule third_party/Chart.js
  is not checked out'`. With `FIXTURES_REQUIRED=1`, it fails. The CI job `fixtures` makes a shallow
  checkout of `third_party/Chart.js` and sets `FIXTURES_REQUIRED=1`.
- `dart run melos run test:fixtures:zoom`: the 12 fixtures of `flutter_chartjs_plugin_zoom_port`
  (`test/specs/fixtures_test.dart`, the tag `fixtures`, seam H24). Each fixture runs its upstream
  steps on a chart and compares the scale ranges at its snapshot points with
  `test/fixtures/fixtures_reference.dart`, not an image (row `harness-fixture-observations`).
  Without the submodule `third_party/chartjs-plugin-zoom`, each fixture skips with a reason that
  names it; with `FIXTURES_REQUIRED=1`, it fails. The CI job `fixtures` also checks out that
  submodule and runs the script with `FIXTURES_REQUIRED=1`. `test --no-select` excludes the tag.
- `dart run melos run test:fixtures:sankey`: the 44 fixtures of
  `flutter_chartjs_chart_sankey_port` (`test/specs/fixtures_test.dart`, the tag `fixtures`). Each
  fixture builds its chart and compares the nodes, the flows and the draw calls with
  `test/fixtures/fixtures_reference.dart`, the values of the JavaScript chart, not an image (row
  `harness-fixture-observations`). Without the submodule `third_party/chartjs-chart-sankey`, each
  fixture skips with a reason that names it; with `FIXTURES_REQUIRED=1`, it fails. The CI job
  `fixtures` runs it with `FIXTURES_REQUIRED=1`. `test --no-select` excludes the tag.
- `dart run melos run test:zoom:range-only`: the tests of `flutter_chartjs_plugin_zoom_port`, the
  fixtures among them, with `--dart-define=ZOOM_RANGE_ONLY_UPDATES=true`: `test/flutter_test_config.dart`
  writes the zoom option `rangeOnlyUpdates: true` into `Chart.defaults.plugins.zoom`, so each zoom
  and pan takes `chart.updateRanges` (Chart.js ADR 0111). The results are those of the run
  without it; the spec `defaults` expects the key. The CI job `fixtures` runs it with
  `FIXTURES_REQUIRED=1`.
- `dart run melos run test:goldens`: the theme goldens of `flutter_chartjs_port`
  (`test/port/theme/goldens_test.dart`, the tag `golden`, theming.md §8 test 9, Chart.js ADR 0050).
  They skip unless `CHART_GOLDENS=1`. Their pinned runner is the CI job `fixtures` on
  `ubuntu-24.04`, because the font manager of the platform rasterizes the text. A local Mac never
  writes the golden files. Only a `workflow_dispatch` run of CI with the input `update_goldens`
  writes them (`-- --update-goldens`). That run uploads them as the artifact `theme-goldens`. The
  input `flutter_version` writes `.fvmrc` first, for a move to a new Flutter. The golden files are
  `test/port/theme/goldens/bar_light.png` and `bar_dark.png`. On each other run, the job `fixtures`
  compares them after `test:fixtures`. A failed compare uploads the `failures/` images.
- `dart run melos run parity`: tool 6. It writes `packages/flutter_chartjs_port/doc/parity.md` from
  `doc/status.yaml`, the files of the pinned `third_party/` copies, the rule-2 headers, the spec
  case results of tool 5 and `doc/differences.md`. It runs the spec tests and needs the
  submodules (`upstream`). Do not edit `parity.md`. Edit `doc/status.yaml`. Placeholders in its
  texts give the derived values: `{{differences}}`, `{{passed}}`, `{{cases}}`,
  `{{skipped:<reason>}}`, `{{platforms}}`, `{{files:<glob>}}` and `{{rows:<area>:<status>}}`
  (`tool/src/parity.dart`). Put options after `--`. `-- --dry-run` prints the output.
  `-- --import` reads the cells of `parity.md` back into `doc/status.yaml`.
  `-- --import --base <file>` keeps the edits of both files. `-- --results <file>` reads the JSON
  reporter output of the spec tests from a file. `parity:check` fails when `parity.md` differs
  from the output, or on an error in `doc/status.yaml`. `check:port` and the CI job `port-checks`
  run it.
- `dart run melos run port:next`: tool 8. It lists the modules of `third_party/Chart.js/src` that
  are ready to port, in the phase order of `packages/flutter_chartjs_port/doc/porting-flow.md` §5. Each
  ready module comes with its line count and the interfaces that its type-only imports need. The
  list also gives the modules in progress, and the blocked modules with their missing imports. The
  port state comes from the rule-2 headers of the Dart files in `lib/` and from the status column
  of `doc/parity.md`. It needs the submodule (`upstream`). Without it, the tool exits with 2. Put
  options after `--`: `-- --json` prints the same data as JSON. `port:next:check` runs
  `-- --check`. It fails when tool 8 cannot read a module, a header line of `lib/` or a
  `parity.md` status. It also fails when an import does not resolve. `check:port` and the CI job
  `port-checks` run it.
- `dart run melos run docs` / `docs:build:web`: run the documentation site in Chrome / build it for the web
  with WebAssembly.
- `dart run melos run upstream`: check out the pinned reference sources (every `third_party/`
  submodule, at depth 1). These are the three Chart.js submodules, the 34 D3 submodules, the
  two ECharts submodules, the chartjs-plugin-zoom submodule and the chartjs-chart-sankey submodule.
- `dart run melos run upstream:manifest`: tool 4. It writes
  `packages/flutter_chartjs_port/doc/upstream/` from `third_party/Chart.js`. It needs Node.js 22.18 or
  later. The CI job `upstream-manifest` fails when the committed files differ.
- `dart run melos run upstream:check`: fail unless `third_party/Chart.js` is pinned to the release
  tag named by `chartJsVersion`. For a commit pin (`<last version>+<sha8>`), the gitlink must
  start with `<sha8>`, and the tag `v<last version>` must exist. CI runs it too. It also fails
  unless `third_party/d3` is at the tag `v<d3Version>`. Each other D3 gitlink must be the commit
  of its `ref` and equal its `commit` in `packages/flutter_d3_port/tool/port_sources.yaml`. It
  also fails unless `third_party/echarts` and `third_party/zrender` are at the tags
  `<echartsVersion>` and `<zrenderVersion>` (no `v` prefix) and equal their `commit` in
  `packages/flutter_echarts_port/tool/port_sources.yaml`. It also fails unless
  `third_party/chartjs-plugin-zoom` is at the commit of `chartjsPluginZoomVersion`: for the commit
  pin `<last version>+<sha8>`, a gitlink that starts with `<sha8>`, equals the `ref` and the
  `commit` in `packages/flutter_chartjs_plugin_zoom_port/tool/port_sources.yaml`, and is not the
  commit of the tag `v<last version>`, which must exist. It also fails unless
  `third_party/chartjs-chart-sankey` is at the release tag `v<chartjsChartSankeyVersion>` and
  equals the `commit` in `packages/flutter_chartjs_chart_sankey_port/tool/port_sources.yaml`. The
  script reads the gitlinks from the
  index and the tags with `git ls-remote`. It needs no submodule checkout. It also fails on a submodule of `.gitmodules` that no entry of a
  `packages/*/tool/port_sources.yaml` pins. The pin readers (the script and the
  `test/upstream_test.dart` of each port) skip the top-level keys of a `port_sources.yaml` other
  than `sources`.
- `dart run melos run gallery` (Chrome) / `gallery:macos` / `gallery:device` (Android/iOS):
  run the gallery.
- `dart run melos run gallery:build:web` / `gallery:build:android` / `gallery:build:ios`: build the
  gallery the way CI does (web with WebAssembly, debug APK, iOS without code signing).

Before a push, run `format:check`, `analyze`, `test --no-select`, `test:web`, `test:cases`,
`test:fixtures`, `test:fixtures:zoom`, `test:fixtures:sankey`, `test:zoom:range-only` and
`check:port`.

## Layout

- `packages/flutter_chartjs_port`: the Chart.js port (library, version 0.1.0). Its layout, its internal
  rules, its tests and its docs are in `packages/flutter_chartjs_port/AGENTS.md`. Read that file before a
  change in the package, in `packages/chartjs_test_utils`, in an add-on port or in an app that uses the
  port.
- `packages/chartjs_test_utils`: the test harness, a port of chartjs-test-utils 0.4.0
  (`publish_to: none`, a dev_dependency of `flutter_chartjs_port`). The ported files are in `lib/src/`.
  `flutter_test` and `clock` are regular dependencies of the package, for `lib/src/dom.dart`.
  - `lib/pure.dart`: the framework-free core part (legacy filename). It has
    `setUpSpecs()`, the spec set-up for Flutter core tests,
    `setUpDefaultsRestore()`, `createMockContext`, `MockContext` and the matchers
    (`toBeCloseToPixel`, `toBeCloseToPoint`, `toEqualOneOf`, `toEqualOptions`, `toBeValidChart`,
    `toBeChartOfSize`). `createMockContext` is in `lib/src/context.dart` (the row
    `harness-index-pure-split`). It also has `setUpBuiltins()` and `removeBuiltins()` (the row
    `harness-register-builtins`). `setUpSpecs()` calls `removeBuiltins()` and then
    `setUpDefaultsRestore()`.
  - `lib/flutter.dart`: the part that needs the Flutter engine, for `flutter test` only. It has
    `installTestFont()`. It also has the DOM stand-in of `lib/src/dom.dart` and the chart helpers
    `acquireChart`, `releaseChart`, `releaseCharts`, `afterEvent`, `waitForResize` and
    `triggerMouseEvent` (Chart.js ADR 0022). `acquireChart` takes the config Map of a spec;
    `acquireChartRoot` takes the typed root scope of a typed config (`ChartConfigLowering`,
    Chart.js ADR 0054 §7). The DOM stand-in exports are `document`, `window`,
    `HarnessDocument`, `HarnessElement`, `HarnessWindow`, `setTimeout`, `afterEachChart`,
    `pumpFrames`, `pumpFrame`, `waitForDone`, `frameInterval`, `specTimeout`, and the extensions
    `CanvasParentElement` and `CssProperties`. Only one `pumpFrames` loop pumps at a time: a loop
    that starts while another loop pumps awaits each step of that loop. It also exports the fixture
    runner of `lib/src/fixture.dart`.
  - `lib/src/fixture.dart` ports `src/fixture.js` (Chart.js ADR 0029): `specsFromFixtures`,
    `specFromFixture` and `FixtureSource` (the manifest and `fixtures.json` of tool 4, the folder
    `upstream` of the upstream fixture files, `requireUpstream` and `submodule`, the submodule that
    the skip reason of a missing checkout names, Chart.js ADR 0108 §11). Each fixture test has the tag
    `fixtures`. The rows are `harness-fixture-sources` and `harness-fixture-frame`. It is not a
    pure layer. `test/fixture_test.dart` runs the probe `test/fixture_probe/probe_fixture.dart` in
    a nested `flutter test --tags fixtures` with `FIXTURES_REQUIRED=1` and `FIXTURE_PROBE_CRLF` (a
    temporary folder with a CRLF copy). The folder `test/fixture_probe/upstream/` stands for the
    upstream fixture files.
  - `lib/src/utils.dart` ports `src/utils.js`: `acquireChart` and `releaseChart` (the ports of
    `_acquireChart` and `_releaseChart`), `waitForResize`, `afterEvent`, `_resolveElementPoint` and
    `triggerMouseEvent`. `triggerMouseEvent` builds its event with `bubbles: true`,
    `cancelable: true` and the client point `rect.left + x`, `rect.top + y` of
    `canvas.getBoundingClientRect()`, and calls `canvas.dispatchEvent` (Chart.js ADR 0108 §11, row
    `harness-trigger-mouse-event`). The DOM stand-in reads `left` and `top` (px) of an element with
    `position: absolute`. `lib/src/index.dart` ports `src/index.js`: `acquireChart`, `releaseChart`,
    `releaseCharts` and the registry `charts`. It imports `utils.dart` with the prefix `utils`
    (Chart.js ADR 0012, Collisions). Neither file is a pure layer.
  - `lib/fonts/`: the test font, Liberation Sans 2.1.5 (SIL OFL 1.1), with its `LICENSE`
    (Chart.js ADR 0015).
- `apps/chartjs_gallery`: gallery app (Android, iOS, web, macOS); every Chart.js chart type
  (Chart.js ADR 0031). Each chart of the gallery runs a ported controller. No gallery class
  extends `DatasetController`.
  - The home list (`lib/main.dart`) has the nine entries of `galleryChartTypes`
    (`lib/charts/chart_types.dart`), in the order of the docs. Each tile is enabled and opens
    `ChartTypePage` (`lib/charts/chart_type_page.dart`). The variants of a page are the configs of
    the 11 `chart-editor` blocks of `docs/charts/*.md` in `lib/docs/charts/` and of the Area sample
    `lib/docs/samples/area/line_boundaries.dart`. These files have rule-2 headers. Each tile has
    the icon `check_circle_outline` and its docs source as the subtitle, and no entry has a note.
    The gallery registers `registerables` with the seven plugins, as the docs do: each chart shows
    the legend and the tooltip with their defaults, the filler fills the Radar chart and the Area
    variants `origin`, `start` and `end`, and no page prints the `fill` warning. The Area page has
    the four fill actions of `docs/samples/area/line-boundaries.md:39-74` as its variants:
    `origin` (the first), `start`, `end` and `false` (Chart.js ADR 0031, Open "The Area `fill`
    control").
  - A type page has at most one control line (the variant), then the chart, the readout (the
    datasets, and the hover text of `getLabelAndValue`) and the help text. The help text gives the
    docs source and the input: a hover or a tap on an element shows the tooltip, a tap outside the
    chart hides it, and a tap on a legend item hides or shows its data. Its last line gives the
    keys of Chart.js ADR 0051. The chart is a `ChartView.raw` with the config that the page makes
    once for each variant, and `onChartCreated` gives the chart to the page. The chart has the
    semantics label `<title> chart: <variant>`. The app follows the platform brightness: its builder puts a `ChartTheme` above each route, with the
    light preset or the dark preset over the surface of the dark color scheme (Chart.js ADR 0050).
    The host has no height: the platform gives the aspect of the docs (2, or 1 for doughnut, pie,
    polar area and radar). The page body caps its width at 600. The keys are
    `gallery.type.<stem>`, `type.<stem>.variant.<variant>`, `type.<stem>.host`,
    `type.<stem>.readout` and `type.<stem>.help`.
  - `lib/demo/gallery_components.dart` has `registerGalleryComponents` (it registers
    `registerables` once), `registerZoomComponents` (it also registers `zoomPlugin` of
    `flutter_chartjs_plugin_zoom_port` once for all charts, as the upstream docs of the plugin do;
    the zoom page and the input probe call it, so the stress entry and the benchmark cases
    outside the mode `zoom` run no zoom hook) and `unitScales` (the two hidden unit scales).
  - After the tile "Zoom and pan", the home list has the tile "Sankey" (key
    `gallery.chart.sankey`). It opens `lib/plugins/sankey_page.dart`, a `ChartView.raw` of the type
    `sankey`. Its variants are the ports of four samples of the docs of chartjs-chart-sankey
    (`src/content/docs/samples/basic.md`, `vertical.md`, `flow-colors.md` and `node-labels.md`) in
    `lib/docs/sankey/samples/`, with rule-2 headers; `lib/docs/sankey/scripts/utils.dart` ports
    `docs/scripts/utils.js`. Only that page calls `registerSankeyComponents` of
    `lib/demo/gallery_components.dart`, which registers `sankeyRegisterables` once.
    `test/sankey_page_test.dart` pins the page.
  - After the nine entries, the home list has the tile "Zoom and pan" (key `gallery.plugin.zoom`).
    It opens the zoom page `lib/plugins/zoom_page.dart`. Its variants are the ports of four samples
    of the docs of chartjs-plugin-zoom (`docs/samples/basic.md`, `drag/linear.md`,
    `wheel/category.md` and `pan/toggle.md`) in `lib/docs/zoom/samples/`, with rule-2 headers. The
    chart is a `ChartView.raw`. The actions of a sample, for example "Reset zoom", call the zoom
    API on the chart of `onChartCreated`. `test/zoom_page_test.dart` pins the page (seam H20).
  - The page "Phase 3: canvas and host" has the tabs Canvas, Events, Text, Stress, Elements, Core
    and Axes. The Core tab (`lib/demo/core_demo.dart`) runs a `LineController` chart with the
    typed config of Chart.js ADR 0052 §13, on two hidden linear axes (the typed form of
    `unitScales()`). `build` makes the `ChartConfig` from the control values: a control changes a
    value in `setState`, and the data commands give new data Lists. `interaction.axis` and
    `elements.point.hoverBorderWidth` go through `extra`. The duration of the hover transition is a
    `HoverTransition` of `ChartConfig.transitions`. Thus `gallery:build:web` compiles the typed path with dart2wasm. Its controls are
    above the chart: `mode`, `axis`, one line of toggles and commands, `hover` and `update`. The
    Axes tab (`lib/demo/axes_demo.dart`) runs a `LineController` chart on the scales of phase 6.
    `x`, `y` and `N` are above the chart, and the other parameters are after the readout
    (Chart.js ADR 0031 §10.7, Open). The plugins of
    `registerables` run with their defaults in both tabs: the legend and the tooltip show. A legend
    click in the Core tab also updates the dataset segments: the inline plugin of the tab gets each
    event in its `afterEvent` hook. Each tab shows its chart in a `ChartView` in a `SizedBox` of
    the height, with `maintainAspectRatio: false`. The keys `core.host` and `axes.host` are on the
    box.
  - The gallery imports the app library `package:flutter_chartjs_port/flutter_chartjs_port.dart`,
    and `helpers.dart` with a `show` list. `lib/demo/elements_demo.dart` also imports
    `package:flutter_chartjs_port/chartjs.dart` `as chartjs show Element`. A file of `lib/` with an
    import of `package:flutter_chartjs_port/src/` has `// ignore_for_file: implementation_imports`
    after the line `// The reason of each import of lib/src is the comment above it.`, and one
    reason line above each such import. A test file has only the reason lines: the lint reports
    only `lib/`.
    `lib/demo/demo_common.dart` has `jsNumberText`, the JS text of a number for the readouts.
  - `lib/demo/chart_canvas.dart` hosts a real chart for the stress host `HOST=canvas` (the side A
    of the night series A-N1 of Chart.js ADR 0049) and for `_StressChart`, a chart class that
    times its own draws. It connects `ChartHost.onTickerModeChanged` to `animator.mute` and
    `animator.unmute`. It goes after the night record.
  - The modes `chart` and `axes` of the Stress tab measure the real chart path. The mode `chart`
    takes the chart type (the define `TYPE`, 8 types, the `type` line of icon segments). Line and
    scatter draw the points of phase 5 on two hidden unit scales. `axes` adds real scales
    (`lib/demo/stress_axes.dart`) to a `LineController` chart. The stress and benchmark configs
    disable the legend plugin (`plugins.legend: false`, `stressPluginOptions` of
    `lib/demo/stress_chart_config.dart`, Chart.js ADR 0031 Open). The other plugins run; the filler
    fills the radar of the mode `chart`. `lib/demo/stress_timing.dart` has `StressChartTiming`, with
    the parts `elements`, `layout`, `datasetsUpdate` and `datasetsDraw`. `lib/main_stress.dart` is
    the profiling entry. In the modes `chart`, `axes` and `plugins`, its define `HOST` selects the
    host: `canvas` (`ChartCanvas`, the default) or `view` (`ChartView`). `BATCHES` (15) splits the
    timed window into batches, and each `STRESS` line has the batch figures `buildP50Ms`,
    `buildP90Ms`, `rasterP50Ms` and `rasterP90Ms`. Only the `STRESS` lines of the modes `chart`,
    `axes` and `plugins` have the key `host`. Its defines `SEMANTICS` and
    `WINDOWS` serve the night series B-N1 of
    phase 9: `SEMANTICS=1` turns the semantics on, and `WINDOWS=1` prints a line
    `STRESS_WINDOW {json}` for each window of 1 second. With `SEMANTICS` (0 or 1), the toolbar and
    the readout of `StressDemo` are out of the semantics tree (`chartSemanticsOnly`), so that B-N1
    measures the chart node. `lib/main_bench.dart` with
    `lib/bench/chart_bench.dart` is the frameless benchmark of the same cases
    (`packages/flutter_chartjs_port/doc/performance.md` §6). Its mode `motion` (`motion.line` and
    `motion.bar`) times an animated `update`, and its mode `theme` (`theme.switch`, `theme.anim`
    and `theme.equal`) runs the internal theme switch of `ChartView`. Its mode `zoom`
    (`chartBenchZoomCases`, 1000 and 20000 points) times the plugin of chartjs-plugin-zoom on a
    line chart with visible scales: `zoom.base` and `zoom.idle` (without and with the plugin),
    and one input in each step (`zoom.wheel`, `zoom.pan`, `zoom.drag` and `zoom.pinch` dispatch
    one event with `canvas.dispatchEvent`; `zoom.api` and `zoom.apiPan` call the zoom API). Each
    zoom case registers the plugin for its own run only, puts the scale ranges back outside the
    timing before each pair of steps, and gives `steps`, `stepP50Ms`, `stepP90Ms` and
    `stepMaxMs`. The define `PROFILE_MARKS=true` prints `BENCH_MARK {json}` with `Timeline.now`
    before and after the timed window of each case. The define `ZOOM_RANGE_UPDATES=true`
    (`chartBenchZoomRangeUpdates`, default off) writes the zoom option `rangeOnlyUpdates: true`
    into the input cases (`chartBenchZoomCasesWith`), so each step takes `chart.updateRanges` of
    Chart.js ADR 0111; each zoom BENCH line has the key `rangeUpdates`. performance.md §69 has the
    figures of the zoom cases.
  - `lib/main_input_probe.dart` is the input probe of Chart.js ADR 0112: one `ChartView.raw` line
    chart of 20000 points (`--dart-define=POINTS=<n>`) with `animation: false` and the zoom plugin
    (`registerZoomComponents`; wheel, pinch, pan `'xy'`). For each frame it counts the
    `PointerMoveEvent`s of each pointer (a global route of the pointer router), the
    `PointerScrollEvent`s, the `PointerPanZoomUpdateEvent`s, and the chart updates
    (`afterUpdate`) and draws (`afterDraw`) of an inline plugin. Once per second with work it
    shows a summary and prints `PROBE {json}` (`frames`, `active`, `frameNumbers`, `pointers`,
    `{mean, max, hist}` of `movesPerPointer`, `moves`, `scrolls`, `panZooms`, `updates`, `draws`,
    and the p50 and p90 of the `FrameTiming` build and raster). `FrameTiming` leaves the input
    work out: the frame rate shows it. Build it with `flutter build apk --profile -t
    lib/main_input_probe.dart --android-skip-build-dependency-validation` and read
    `adb logcat -s flutter:I`. `test/input_probe_test.dart` pins the counts.
  - `lib/main_sankey_bench.dart` is the sankey benchmark entry (`performance.md` of the sankey
    port). It times a sankey chart with no host on a bitmap of 800 x 480: the data functions and
    the layout alone, `chart.update('none')` with new flow sizes (with the parts parse, element
    update and draw of a timed controller subclass), the draw alone, the hit test and a hover.
    Its frame cases show a `ChartView.raw` with new data in each frame and read the `FrameTiming`
    build and raster times. It prints one line `SANKEY {json}` for each case. With
    `--dart-define=SERVE=true` it runs nothing at its start: the service extension
    `ext.sankey.run` runs one case for each call, also with the prototype variants of its header,
    and gives the timed windows for a CPU profile of the VM service. No test pins it.
  - The layout rule (Chart.js ADR 0031 §10) applies to the nine type pages and to the
    Core and Axes tabs: each parameter is a full-width `SegmentChoice` or
    `SegmentToggles` line of `lib/demo/demo_controls.dart`, with short text or icons. A
    `SegmentChoice` item with an `icon` shows the icon only, else its short text. No chip, slider,
    popup menu, dropdown or horizontal scroll. The chart host is fully in view after the first frame
    at 412 x 915. The type pages are also in view at 360 x 640. A widget test pins each page.
    `test/chart_types_test.dart` also pins, on each variant of each type page at 412 x 915, the
    input of Chart.js ADR 0037 §15: a tap on an element shows the tooltip and the readout, a tap on
    the help text hides them, and two taps on legend item 0 hide and show its data. On each variant
    it also pins the keys of Chart.js ADR 0051: Tab focuses the chart, Down and Down show the
    tooltip and the readout of element 0 of dataset 0, Escape hides them, and Down and Enter hide
    the data of legend item 0. It pins the help text and the semantics label of each variant, the
    keys of the host, the readout, the help text and each variant segment, and the title and the
    filler source of each Area variant.
  - Stress follows Chart.js ADR 0075: Charts / Drawing / Axes / Plugins targets,
    readable wrapping choices, paired Items / Overlay labels fields, explicit
    operation names and Run/Pause actions. Interactive item choices are always
    100 / 1k / 5k / 20k; target and type changes preserve the selected count.
    Named optional controls expand from
    Options; rendering traces and detailed timings live under Diagnostics.
    Preserve control keys, benchmark behavior and the 412 x 915 host viewport.
  - Each control has a `ValueKey`. A test finds a segment by its key.
- `apps/chart_benchmark_lab`: the independent cross-library public-widget test
  bed (the eight Chart.js types and the sankey chart of chartjs-chart-sankey; Chart.js
  port, fl_chart, Graphic and Syncfusion).
  `ChartLibrary.supports` excludes the Syncfusion radar: that package has no radar
  series, so the lab shows a message and a batch skips it. Do not draw a stand-in.
  Only the Chart.js port has the sankey chart, through
  `flutter_chartjs_chart_sankey_port`: `sankeyFlows` of `lib/benchmark/data.dart` gives
  one flow for each item between nodes in three columns, and `_chartJsSankey` of the
  adapter registers `sankeyRegisterables` once and draws a `ChartView.raw` (the typed
  config takes no dataset of another package), so each tick is a full update. The
  sankey chart has no visible axes and no shadow (`ChartType.hasShadow`,
  `BenchmarkConfig.shadows`); its zoom and pan act on its hidden x scale, the node columns.
  `ChartLibrary.runs` applies the same rule to the series shadow: fl_chart draws it
  only on a line chart, Graphic only as a blurred Material elevation of a filled
  mark, and Syncfusion not at all. The settings hide a feature that the chart type
  does not have. A run disables the features that the settings show.
  `ChartLibrary.zoomsWith` gives the zoom and pan of the x axis (line, bar, scatter
  and bubble): the Chart.js port through the zoom port, which the adapter registers
  only for a chart with zoom, fl_chart
  `transformationConfig`, Graphic `RectCoord.horizontalRangeUpdater` and Syncfusion
  `ZoomPanBehavior`, each inside the data and at most `chartMaxZoom` times. The
  adapter claims each wheel over a chart with zoom, so the page does not scroll
  and a test goes on. A desktop trackpad differs by library (the host of the
  Chart.js port maps it to `wheel` events while the toggle "Trackpad gestures",
  `BenchmarkConfig.trackpad`, is on): `zoomsWith` states it.
  Run `dart run melos run benchmark:macos` for profile measurements. Dependencies
  are pinned; Syncfusion is included under the owner's confirmed eligible license.
  Shared seeded data and controls live in `lib/benchmark`, adapters in
  `lib/charts`, dashboard in `lib/ui`. One engine is mounted at a time.
  `chart_adapter.dart` imports the adapters of fl_chart, Graphic and
  Syncfusion (`*_adapter.dart`) as deferred libraries. The controller loads
  one (`BenchmarkChart.load`) before its chart shows or a run starts, never
  in a timed window. A test that draws them calls `BenchmarkChart.loadAll` in
  `setUpAll`. The workflow `pages` and `benchmark:build:web` build with
  `--enable-wasm-deferred-loading` when the Flutter has the flag. `web/index.html`
  preloads the font files that the engine reads before the first frame.
  Preserve warmup/timestamp filtering, viewport/visibility cancellation and
  comparable-run keys. Engine build timing excludes some deferred work: retain
  frame-interval metrics and full-window FPS. Do not silently downsample an engine.
  `tool/smoke.dart` drives the real UI/controller in native profile mode.
  Each section of `lib/ui/benchmark_page.dart` is one widget instance that rebuilds
  through `_Selected`: its `select` must cover each value that its builder reads.
  `test/page_work_test.dart` has the budgets of the page and fails on a stale section.
  `tool/perf_page.dart` times the page in profile mode. An idle resize keeps the chart
  mounted, except a Graphic bar chart. Each test still starts with a new chart.
- `apps/chartjs_docs`: the documentation site of the Chart.js port (web). The line chart page has the
  section structure of `docs/charts/line.md`, with Dart text and live charts.
  `lib/pages/line_chart_page.dart` has the text and the table of options. `lib/examples/line_examples.dart`
  has the code of the charts. The app also loads this file as an asset, and a code panel shows the lines
  between `// #docregion <name>` and `// #enddocregion <name>`. Thus a panel shows the code that draws its
  chart. `test/line_chart_page_test.dart` compares the table with the chart defaults and the parameters of
  `LineDataset`. The workflow `pages` deploys the site.
  - `docPages` of `lib/main.dart` lists the pages with their routes (`/`, `/migrate/fl_chart`,
    `/migrate/graphic`, `/migrate/syncfusion`) and their groups in the sidebar. The browser address
    `#/<route>` opens a page.
  - The pages "Migrate from" rebuild the line chart demos of fl_chart 1.3.0 (13), Graphic 2.7.0 and
    Syncfusion 35.1.43 with the port. `migrationPage` of `lib/ui/replica_block.dart` gives the intro, a
    table of the names that map and one section for each demo: notes, the live replica and its code on
    a tap. Each replica is one file of `lib/migrate/<library>/` with one region. `Snippets.load` reads
    the regions of each Dart file of `snippetFolders`, and `pubspec.yaml` lists each folder as assets.
  - The replicas are new code. The Syncfusion replicas use no Syncfusion code. The data of the fl_chart
    samples 12 and 13 (`assets/flchart/`) and `lib/migrate/graphic/graphic_data.dart` are MIT copies:
    the `LICENSE` of the app and `REUSE.toml` name their holders.
    `test/migrate_pages_test.dart` builds each page, also at phone width, and finds each region.
- `packages/flutter_d3_port`: the D3 port (library, `publish_to: none` until 0.1.0, ISC). Phase 0
  has no ported code. `doc/README.md` has the plan and the roadmap.
  - `lib/flutter_d3_port.dart`: the public library. `lib/src/upstream.dart` has `d3Version`
    (`7.9.0`). Both files are port-only.
  - `test/upstream_test.dart` (`@TestOn('vm')`) compares `d3Version` with
    `third_party/d3/package.json`. It also compares each D3 gitlink with its `commit`. It fails
    on a submodule of `.gitmodules` that no entry of the two `tool/port_sources.yaml` files pins.
  - `tool/port_sources.yaml`: the 34 pins in the schema of the Chart.js file (D3 ADR 0001). Each
    entry gives the tag, the commit, the license and the holder of one repository.
  - Paths (D3 ADR 0002): `third_party/<repo>/src/<path>.js` becomes `lib/src/<repo>/<path>.dart`.
    `<repo>` keeps its hyphens. A spec `<repo>/test/<path>-test.js` becomes
    `test/specs/<repo>/<path>_test.dart`. Port-only tests go in `test/port/<repo>/`.
  - `doc/`: all D3 port docs: `README.md` (overview, roadmap, decisions), `porting-flow.md`
    (proposed), `parity.md`, `differences.md`, `upstream-ledger.md` (one section for each
    repository) and the prior-art survey `prior-art/`.
    - `doc/adr/`: D3 ADRs 0001-0006, all proposed. D3 ADR 0001 (upstream sources) has gate 0.
      D3 ADRs 0002 (file naming and layout), 0003 (number to string), 0004 (spec harness) and
      0006 (generators, accessors and JS values) have gate 1. D3 ADR 0005 (path context) has
      gate 1 for the pure interface and gate 4 for the `dart:ui` builder.
  - `check:port`, `test:web`, `test:cases`, `parity` and `port:next` do not examine the package
    yet. `test --no-select` runs its tests. In D3 phase 1, ADR 0008 adds the package to tools 1-3.
- `packages/flutter_echarts_port`: the Apache ECharts port (library, `publish_to: none` until
  0.1.0, Apache-2.0). Phase 0 has no ported code. `doc/README.md` has the plan and the roadmap of
  phases 0-10.
  - `lib/flutter_echarts_port.dart`: the public library. `lib/src/upstream.dart` has
    `echartsVersion` and `zrenderVersion` (both `6.1.0`). Both files are port-only.
  - `test/upstream_test.dart` (`@TestOn('vm')`) compares `echartsVersion` with
    `third_party/echarts/package.json`, and `zrenderVersion` with the zrender dependency of that
    file and with `third_party/zrender/package.json`. It also compares each gitlink with its
    `commit`. It fails on a submodule of `.gitmodules` that no `packages/*/tool/port_sources.yaml`
    pins. The D3 test reads the same files.
  - `tool/port_sources.yaml`: the two pins, Apache ECharts and zrender, in the schema of the
    Chart.js file (ECharts ADR 0001). The `language` of both is `js`.
  - Paths (ECharts ADR 0002): `third_party/echarts/src/<path>.ts` becomes
    `lib/src/echarts/<path>.dart`, and `third_party/zrender/src/<path>.ts` becomes
    `lib/src/zrender/<path>.dart`. A spec `test/ut/spec/<path>.test.ts` becomes
    `test/specs/echarts/<path>_test.dart` or `test/specs/zrender/<path>_test.dart`. Port-only
    tests go in `test/port/echarts/` and `test/port/zrender/`. The harness is in `test/support/`.
    The name `echarts_test_utils` is reserved. `apps/echarts_gallery` comes in ECharts phase 6.
  - `NOTICE`: the port line and the unchanged notice of Apache ECharts (Apache-2.0 section 4(d)).
  - `doc/`: all ECharts port docs: `README.md` (overview, roadmap, decisions), `porting-flow.md`
    (proposed), `parity.md`, `differences.md`, `upstream-ledger.md` (one section for each
    repository) and the prior-art survey `prior-art/`.
    - `doc/adr/`: ECharts ADRs 0001-0009, all proposed. ECharts ADR 0001 (upstream sources) has
      gate 0. ECharts ADRs 0002 (file naming and layout), 0003 (numbers and JS semantics), 0004
      (JS values, classes and options) and 0005 (spec harness and reference tests) have gate 1.
      ECharts ADR 0006 (renderer and canvas layer) has gate 3. ECharts ADR 0007 (environment,
      host and input events) has gates 1, 3 and 5. ECharts ADR 0008 (dates, locales and
      formatting) has gate 4. ECharts ADR 0009 (DOM-bound features, app hooks and theming) has
      gate 6 and later gates.
  - `check:port`, `test:web`, `test:cases`, `parity` and `port:next` do not examine the package
    yet. `test --no-select` runs its tests.
- `packages/flutter_chartjs_plugin_zoom_port`: the chartjs-plugin-zoom port (library,
  `publish_to: none` until 0.1.0, MIT), the first add-on port (ADR 0009). Zoom phases 1-4 are
  done (2026-11-10): each file of `src/` is ported, and the specs, the fixtures and the tests of
  real input pass. One item stays open: the device check of seam H8 on Android and iOS (Chart.js
  ADR 0108 Open 1). `doc/README.md` has the plan and the roadmap of phases 0-6. Phase 5, next, adds
  the typed options slot (H18) and the theme extension (H19), each after its Chart.js ADR.
  - It depends on `flutter_chartjs_port` with a path dependency, and imports only its public
    libraries, `js_semantics.dart` among them (Zoom ADR 0003, Chart.js ADR 0108).
  - `lib/flutter_chartjs_plugin_zoom_port.dart`: the public library (port-only): `zoomPlugin`, the
    functions `pan`, `zoom`, `zoomRect`, `zoomScale` and `resetZoom`, the extension `ZoomChart`
    (the ten chart methods of `bindApi`, row `adapt-chart-methods-extension`), `ZoomAmount` and
    `PanAmount` (row `adapt-amount-classes`, `chart.zoom(.all(1.5))`), `ScaleRange`, the option
    facades, the enums `Mode`, `ModifierKey` and `DrawTime` (row `adapt-zoom-option-enums`; a
    name in a raw config stops a debug build), `ZoomTrigger`, the callback contexts (records) and
    typedefs, `GestureEvent`, `ActivePointer`, the three function tables and `lib/src/upstream.dart`.
    `lib/src/upstream.dart` has `chartjsPluginZoomVersion` (`2.2.0+fb81d331`, a commit pin) and
    `chartjsPluginZoomPackageVersion` (`2.2.0`), port-only. An app gives the options in
    `ChartConfig.extra` as `{'plugins': {'zoom': {...}}}` or in a raw config, and registers the
    plugin with `Chart.register([zoomPlugin])`, or gives it inline in `ChartConfig.plugins` or in
    the `plugins` of a raw config (seam H18). The port-only zoom option `rangeOnlyUpdates: true` (no default) makes the
    five update calls of `core.dart` (`_updateChart`) call `chart.updateRanges(transition)` of
    Chart.js ADR 0111 in place of `chart.update(transition)`; the app keeps the contract of
    `updateRanges` (row `adapt-range-only-updates`, seam H28).
  - `lib/src/`: the 12 files of `src/` at their mapped paths: `types`, `options`, `defaults`,
    `state`, `utils`, `scale.types`, `core`, `handlers`, `gestures`, `plugin` and `index`;
    `src/index.umd.ts` has no Dart file (Zoom ADR 0002 item 8, Chart.js ADR 0120). `zoomPlugin` (`plugin.dart`) is a native `Plugin<ZoomPluginOptions>` of the host
    (Chart.js ADR 0144) with the upstream hooks in order and `supportsDataUpdates: true` (row
    `adapt-typed-plugin-object`, seam H25); its hooks get the facade `ZoomPluginOptions`, take
    `Object chart` and narrow it with `chart as Chart`. The upstream keys `version`,
    `panFunctions`, `zoomFunctions` and `zoomRectFunctions` are top-level names of the library. The options are extension-type facades
    over the resolver of the host (`ZoomPluginOptions` of `options.dart`), read live. A callback
    option (`onZoomStart`, `onZoom`, `onPanComplete`, ...) and a `ModeFn` hold the function of
    their typedef, and the plugin calls them directly; a start callback returns `bool`, and a
    function of another type stops a debug build (Zoom ADR 0004). The state of a chart
    is an `Expando<State>` (`state.dart`); the gesture managers are an `Expando` too. The listeners
    use `canvas.eventTarget` and `canvas.ownerDocument` of Chart.js ADR 0108 (row
    `adapt-canvas-event-target`): after a drag, the `keydown` listener stays on the document until
    `removeListeners` or the hook `stop`, as upstream. `debounce` runs on a `Timer`; each wheel zoom
    updates the chart, and `beforeUpdate` puts a new debounced handler into the state, so each
    wheel event gives its own `onZoomComplete` 250 ms later, as upstream. A limit is a number
    (`jsToNumber`, row `js-semantics-numeric-limits`). The default drag colors are `Color` values
    (row `adapt-native-colors`).
  - `test/flutter_test_config.dart` ports `test/index.js`: the set-up of the host tests (DPR 1 and
    800 x 600, the date zone UTC, the built-in components and `Chart.register([zoomPlugin])`, the
    colors plugin off, the defaults restore, the release of the charts and the test font) and the
    event helpers `EventInit`, `triggerWheelEvent`, `dispatchEvent`, `dispatchPointer`,
    `simulatePan`, `simulatePinch` (a named `done`) and a synchronous
    `triggerMouseEvent(chart, type, (x: x, y: y))` (rows `harness-dom-events` and
    `harness-trigger-mouse-event-sync`). Each helper builds a bubbling, cancelable `NativeEvent`
    and calls `canvas.dispatchEvent`. `test/support/jasmine.dart` (port-only) has the spies and
    the matchers of the specs, with the `toBeCloseTo` of jasmine-core 5.4.0.
  - `test/specs/`: the 8 specs of `test/specs/*.spec.js` (83 cases) and the 2 unit tests of
    `src/*.test.ts` (20 cases; the 4 category pan cases run on a real chart, row
    `harness-category-scale-fake`), with no skip. `test/specs/fixtures_test.dart` runs the
    fixtures of `test/fixtures/`: the registry `index.dart`, `manifest.json`, the hand ports
    `hand/pan/*.dart` and `hand/zoom/*.dart` of the 12 fixture configs, and
    `fixtures_reference.dart`, written by `tool/reference/fixtures_reference.mjs` from the upstream
    fixtures (`test:fixtures:zoom`).
  - `test/port/` (port-only): `plugin_test.dart` (the range-only updates of Chart.js ADR 0111:
    twins of each flow with and without the option; the data-only updates of a `ChartView`, the
    warnings of `start`, the range in the scale options), `public_library_test.dart` (the zoom
    library next to the app library of the host and `material_ui.dart`), `handlers_smoke_test.dart`
    (the listeners with synthetic events) and the tests of real input. `handlers_test.dart`,
    `gestures_test.dart` and `index_test.dart` drive a `ChartView` with the pointer and key events
    of Flutter through the input path of the host: a wheel in a `ListView` zooms and does not
    scroll it, a mouse drag that lifts outside the box zooms, a press on the legend starts no drag,
    Escape cancels a drag with no focus, Enter, Enter on a keyboard target leaves no drag state, a
    one-finger pan and a two-finger pinch with `touch-action: none` in a vertical `ListView` do
    not scroll it, and the range stays across an equal config and new data and goes at another
    option and at a theme switch (row `theme-switch-zoom-range`).
  - `test/upstream_test.dart` (`@TestOn('vm')`) compares `chartjsPluginZoomPackageVersion` with
    `third_party/chartjs-plugin-zoom/package.json`, the entry of `tool/port_sources.yaml` with the
    version and the gitlink with its `commit`. It fails on a submodule of `.gitmodules` that no
    `packages/*/tool/port_sources.yaml` pins. It also checks the top-level keys `marker: zoom` and
    `host: flutter_chartjs_port`, and that its reader skips the top-level keys.
  - `tool/port_sources.yaml`: the pin in the schema of the Chart.js file (Zoom ADR 0001), with the
    top-level keys `marker: zoom` (the tag of `DIVERGES(zoom)`) and `host: flutter_chartjs_port`
    (ADR 0009). For the commit pin, `ref` and `commit` are the full commit. The entry has no
    `files`: `check:headers` reads the source paths from the submodule. `tool/reference/` has the
    Node.js generator of the fixture data.
  - `doc/`: all zoom port docs: `README.md` (overview, roadmap with the state of each phase,
    decisions), `host-seams.md` (each use of `chart.js` and of the DOM by the plugin, with the state
    of the host port, `connects`, `zoom-side`, `gap` or `examine`, and the tests that pin it),
    `parity.md` (a person writes it), `differences.md` (its table of the reserved IDs has the
    header cell `Reserved ID`, so `check:headers` reads no rows from it) and `upstream-ledger.md`.
    `prior-art/README.md` is the prior-art survey (2026-11-10).
    - `doc/adr/`: Zoom ADRs 0001-0004. Zoom ADRs 0001-0003 are proposed. Zoom ADR 0001 (upstream
      source, name and license) has gate 0. Zoom ADR 0002 (file naming and layout) has gate 1.
      Zoom ADR 0003 (the connection to the host port) has gates 1 and 2. Zoom ADR 0004 (native
      zoom and pan callbacks) is accepted (2026-11-13): its code passes the tests. It supersedes
      the user-function bullet of Zoom ADR 0003 item 9. Docs name them "Zoom ADR NNNN".
  - `check:lib-imports`, `check:headers` and `check:js-semantics` examine the package (ADR 0009
    item 6). `test:fixtures:zoom` runs its fixtures. `test:web`, `test:cases`, `test:fixtures`,
    `parity`, `port:next` and `check:typed-reads` do not examine it. `test --no-select` runs its
    tests without the tag `fixtures`.
- `packages/flutter_chartjs_chart_sankey_port`: the chartjs-chart-sankey port (library,
  `publish_to: none` until 0.1.0, MIT), the second add-on port (ADR 0009) and the first chart type
  of another package. Sankey phases 0-4 are done (2026-11-13). `doc/README.md` has the plan and the
  roadmap. Phase 5, next, is the work on the public API of the host for its seams.
  - It depends on `flutter_chartjs_port` with a path dependency, and imports only its public
    libraries (Sankey ADR 0003). Chart.js ADRs 0132 and 0133 are the host changes for it.
  - `lib/flutter_chartjs_chart_sankey_port.dart`: the public library (port-only). It exports
    `lib/src/index.esm.dart` (`SankeyController`, `Flow`, `SankeyDataPoint`, `SankeyNode`,
    `FromToElement`, `SankeyNodeGap`, `SankeyNodeCallback`, `SankeyParsedCustom` and the six
    enums) and `lib/src/upstream.dart` (`chartjsChartSankeyVersion`, `0.19.1`), and has the
    port-only List `sankeyRegisterables`. An app calls `Chart.register(sankeyRegisterables)` once
    and gives a `ChartView.raw` the type `sankey`: the typed `ChartConfig` takes no dataset class
    of another package (seam S9). `Flow` is also a Flutter widget name: a library that imports Flutter
    and names the element imports the port with a prefix (seam S21).
  - `lib/src/`: the files of `src/` at their mapped paths: `types`, `lib/helpers`, `lib/core`,
    `lib/layout`, `labels`, `flow`, `controller` and `index.esm`; `src/index.ts`, the entry that
    registers at its import, has no Dart file (Sankey ADR 0002).
    - A string union of an option is an enum (`SankeyOrientation`, `SankeyLabelPosition`,
      `SankeyColorMode`, `SankeyModeX`, `SankeyNodePaddingMode`, `SankeySize`, row
      `adapt-sankey-option-enums`); a name in a raw config stops a debug build. A color is a
      `ChartPaint` or a `Color` (row `adapt-sankey-native-colors`). The static `defaults` and
      `overrides` are Maps with the Dart objects of the host options (row
      `adapt-sankey-native-defaults`).
    - `SankeyNode` has `inFlow` and `outFlow` for the upstream `in` and `out` (row
      `adapt-sankey-node-fields`). A data item is a `SankeyDataPoint`, or a Map that the keys of
      `parsing` read (row `adapt-sankey-data-point`). A parsed item is a `ParsedItem` of the host
      with a `SankeyParsedCustom` as `custom` (row `adapt-sankey-parsed-item`).
    - The options are objects of the host resolver, read by name through extension-type facades
      (`SankeyControllerDatasetOptions`, `FlowOptionsFace`). A Map option (`labels`, `column`,
      `priority`, a node-scoped option by node key) comes from the resolver as a view of the Map,
      not as a `Map`: read it with `jsGet`, never with an `is Map` test (seam S10).
      `resolveNodeOption<T>` of `labels.dart` reads a node-scoped option: a value, a Map by node
      key or a `SankeyNodeCallback<T>` (row `adapt-sankey-node-option`).
    - The layout sorts with `jsSort`: the order of two equal nodes decides their positions.
    - `SankeyController.nodes` gives the nodes of the last parse (the upstream `_nodes`).
    - Four forms are faster than the upstream lines, with the same layout and pixels
      (`doc/performance.md`). The default layout counts the downstream flows of each node one
      time, before the sort that reads the count (row `adapt-sankey-node-count-memo`). The parse
      reads the offset of a flow by its data index (row `adapt-sankey-flow-by-index`). The keys
      `hoverColorFrom` and `hoverColorTo` are not scriptable by their own names, so the options
      of the flows with plain values resolve one time: in the default mode, the two keys of the
      options of a flow hold the function, and the active mode reads the hover colors as
      `colorFrom` and `colorTo` (row `adapt-sankey-hover-color-keys`). The flows with equal ends,
      colors and alpha share one gradient object (row `adapt-sankey-shared-gradients`).
  - `test/flutter_test_config.dart` ports `test/setup.js`: DPR 1 and 800 x 600, the built-in
    components and `sankeyRegisterables`, the colors plugin off, the defaults restore, the
    release of the charts and the test font.
  - `test/specs/`: the 5 unit tests of `src/**/*.test.ts` (`lib/helpers_test.dart`,
    `lib/core_test.dart`, `lib/layout_test.dart`, `labels_test.dart`, `flow_test.dart`) and the 5
    specs of `test/specs/*.spec.js`. `resize_test.dart` reads the progress of the flows, not
    pixels (row `harness-resize-ink`). `test/specs/fixtures_test.dart` runs the fixtures of
    `test/fixtures/`: the registry `index.dart`, `manifest.json`, the hand ports `hand/**.dart`
    of the 44 fixture configs, and `fixtures_reference.dart`, written by
    `tool/reference/fixtures_reference.mjs` from the upstream sources (`test:fixtures:sankey`).
    `test/support/fake_context.dart` is the context of the two element unit tests.
    `test/port/public_library_test.dart` imports the library next to the app library of the host
    and `material_ui.dart`, and draws a chart of `SankeyDataPoint` items in a `ChartView.raw`.
    `test/port/lib/layout_test.dart`, `test/port/controller_test.dart` and
    `test/port/flow_test.dart` pin the four faster forms of `doc/performance.md`.
  - `test/upstream_test.dart` (`@TestOn('vm')`) compares the entry of `tool/port_sources.yaml`
    with `chartjsChartSankeyVersion`, and the gitlink with its `commit`.
  - `tool/port_sources.yaml`: the pin, with the top-level keys `marker: sankey` and
    `host: flutter_chartjs_port`. A unit test `src/**/*.test.ts` has a file target.
  - `doc/`: `README.md` (overview, use, roadmap), `host-seams.md` (each place where a chart type of
    another package needs a part of the host, with the state `connects`, `sankey-side` or `gap`:
    the input for the work on the public API of the host), `parity.md` (a person writes it),
    `differences.md`, `performance.md` (the figures of each faster form, and the open items),
    `upstream-ledger.md` and `prior-art/README.md` (2026-11-13: no Dart port of
    this library exists).
    - `doc/adr/`: Sankey ADRs 0001-0003, all proposed: 0001 (upstream source, name and license),
      0002 (file naming, layout and the Dart forms) and 0003 (the connection to the host port).
  - `check:lib-imports`, `check:headers` and `check:js-semantics` examine the package (ADR 0009
    item 6). `test:fixtures:sankey` runs its fixtures. `test:web`, `test:cases`, `test:fixtures`,
    `parity`, `port:next` and `check:typed-reads` do not examine it. `test --no-select` runs its
    tests without the tag `fixtures`.
- `packages/flutter_kurkle_color_port`: the @kurkle/color 0.3.2 port (library, version 0.1.0,
  MIT), the color library of the Chart.js port. Its pubspec has no `publish_to`: it is on pub.dev.
  It depends only on Flutter (`dart:ui`, for the Flutter `Color` input of the `Color`
  constructor) and imports no other port. `flutter_chartjs_port` depends on it with `^0.1.0`, which
  the workspace resolves to the package; `chartjs_test_utils` and the gallery name it as a path
  dependency. Its `.pubignore` keeps `doc/`, `tool/` and `build/` out of the archive.
  - `lib/flutter_kurkle_color_port.dart`: the public library (port-only). It exports
    `lib/src/index.esm.dart` (the names of `src/index.esm.js`: `Color`, `RGBA`, `color` and the
    functions of `byte`, `hex`, `hue`, `names` and `rgb`) and `lib/src/upstream.dart`
    (`kurkleColorVersion`). The app library of `flutter_chartjs_port` exports it with
    `hide Color, color`.
  - `lib/src/`: the files of `src/` and `packed.js` at their mapped paths, `simple_parse.dart`
    (the guarded comma notation) and `numbers.dart` (port-only): the plain Dart forms of `x | 0`
    (`toInt32`), the number of an input value (`toNumber`), the test `if (x)` of a number
    (`isNonZero`) and the text of a number in a CSS string (`numberText`). The package uses no JS
    runtime. Dart `null` stands for JS `undefined`: `Color(null)` is a color that is not valid,
    and a string method of such a color gives `null`. The constructor takes no CSS text (row
    `adapt-direct-colors`); `hexParse`, `nameParse`, `rgbParse` and `hueParse` read it.
  - `test/index_test.dart` ports `test/index.js`; `test/port/` has the port-only tests;
    `test/support/reference.dart` has `cssColor` (the string branch of the upstream constructor)
    and an independent ToInt32 reference. The tests use `package:test` and run on the VM and in
    `test:web`.
  - `tool/port_sources.yaml`: the pin of `third_party/kurkle-color`, with the top-level key
    `marker: kurkle` (the tag of `DIVERGES(kurkle)`). `doc/differences.md` has its rows.
  - `check:headers` examines the package as its own home. `test:web` and `test --no-select` run
    its tests. `check:lib-imports`, `check:js-semantics`, `test:cases`, `parity`, `port:next` and
    `check:typed-reads` do not examine it. The core layers of `flutter_chartjs_port` may import its
    public library (`colorLibrary` of `tool/src/lib_imports.dart`).
- `third_party/`: reference sources only: never imported, built or shipped. Excluded from
  analysis.
  - Shallow git submodules: `Chart.js` at the tag `v4.6.1`
    (`packages/flutter_chartjs_port/doc/upstream-tracking.md` §2.4), and `kurkle-color` (`v0.3.2`) and
    `chartjs-test-utils` (`v0.4.0`) at release tags. The last two come from Chart.js ADR 0035.
  - The 34 D3 submodules, also shallow at release tags (D3 ADR 0001): `d3` (`v7.9.0`), the 30
    `d3-*` modules, `internmap`, `delaunator` (`v5.1.0`) and `robust-predicates` (`v3.0.3`).
    `packages/flutter_d3_port/tool/port_sources.yaml` gives the tag and the commit of each.
  - The 2 ECharts submodules, also shallow at release tags (ECharts ADR 0001): `echarts`
    (`6.1.0`) and `zrender` (`6.1.0`, the exact version that the ECharts `package.json` requires).
    The tags have no `v` prefix. `packages/flutter_echarts_port/tool/port_sources.yaml` gives the
    tag and the commit of each.
  - `chartjs-plugin-zoom`, also shallow, at the commit `fb81d331` of `master`, 34 commits after the
    tag `v2.2.0` (Zoom ADR 0001). `packages/flutter_chartjs_plugin_zoom_port/tool/port_sources.yaml`
    gives the commit.
  - `chartjs-chart-sankey`, also shallow, at the release tag `v0.19.1` (Sankey ADR 0001).
    `packages/flutter_chartjs_chart_sankey_port/tool/port_sources.yaml` gives the commit. The
    `version` of its `package.json` is a placeholder: the release version is the tag name.
- `tool/`: repository scripts (`check_upstream_pin.sh`). `tool/pages/index.html` is the root page of
  the GitHub Pages site, a template that the workflow `pages` fills in.
- `docs/`: docs for all ports only. `docs/adr/`: decisions for all ports. `docs/prior-art/`: prior
  art for future ports. Docs for one port go in the `doc/` folder of its package.
  - ADR 0007 (package names) is accepted (2026-10-22). It supersedes ADR 0003. ADR 0010 (primary
    constructors) is accepted (2026-11-13). ADR 0008 (shared
    JS runtime and port tools) is proposed. The gate of ADR 0008 is D3 phase 1. ADR 0009 (ports of
    add-on libraries) is proposed. Its gate is zoom phase 0. An add-on port depends on its host
    port and imports only the public libraries of the host. ADR 0008 item 1 has the clause for it.

The other callback options hold typed functions in raw and typed configs (Chart.js ADR 0130, row
`adapt-native-callbacks`): the chart `onClick` and `onHover` (`ChartEventHandler`) and `onResize`
(`ChartResizeHandler`, a Flutter `Size`), the animation `onProgress` and `onComplete`
(`AnimationEventHandler`) and `fn` (`Interpolator`), the 14 scale hooks (`ScaleHook`), the legend
`onClick`, `onHover` and `onLeave` (`LegendEventHandler`), `labels.generateLabels`
(`LegendLabelsGenerator`, a `List<LegendItem>` out), `labels.filter` (`LegendItemFilter`) and
`labels.sort` (`LegendItemComparator`), the function form of the time `parser` (`TimeParser`) and the
radial `pointLabels.callback` (`PointLabelCallback`, an `int` index). The port calls each one directly,
with no `this` and no JS arity; `functionOption` of `helpers.config.dart` reads it. A function of
another type, also one with another parameter count, stops a debug build, and a release build makes no
call. The typed API takes the same types; `ChartEventDetails`, `ChartLegendEventDetails` and
`ChartAnimationDetails` are removed. A test closure with `Object?` parameters stays valid. The recorder
of the oracle O1 wraps the three legend label callbacks in typed closures.

A point label of a radial linear scale is its lines (Chart.js ADR 0131, row `adapt-native-point-labels`):
`RadialLinearScale.pointLabels` is a `List<List<String>>`, and `pointLabels.callback` holds a
`PointLabelCallback` of `core.scale.dart`, `List<String> Function(Scale scale, List<String> label, int index)`.
The scale turns each item of `data.labels` into lines first; `['']` is one empty line and `[]` no line. The typed
API has `RadialLinearAxis.pointLabelsCallback`. The radial reference test maps each upstream point label to its
lines (`_nativePointLabels`).

Tooltip callbacks use the native `TooltipCallbacks` object in chart and dataset configs (Chart.js ADR 0125).
Its 14 hooks are typed functions with an explicit tooltip argument. Text hooks return `List<String>?`: null invokes
the built-in default, and an empty list emits no lines. Fields merge with `other.field ?? field`. A hook gets the
native `TooltipItem`. Result paints/styles are native values; default producers resolve their
rendered forms. The typed API uses `ChartTooltip.callbacks` and `Dataset.tooltipCallbacks`; the old `titleText`,
`labelText` and `footerText` parameters are removed. Reference generators emit native expected values; no callback
Map adapter is present in the runtime.

A tooltip item is the native extensible class `TooltipItem` of `lib/src/types/tooltip_item.dart` (row
`adapt-native-tooltip-item`, doc/native-tooltip-item-design-draft.md). It is immutable: `datasetIndex` and
`dataIndex` are `int`, `label` is the `List<String>` of the lines of the label, `formattedValue` is a `String`,
`element` is nullable, and `dataset`, `parsed` and `raw` are values of the app. A body item is the final class
`TooltipBodyItem` with the `List<String>` fields `before`, `lines` and `after`. `TooltipModel.dataPoints` is a
`List<TooltipItem>?`, `body` is a `List<TooltipBodyItem>?`, and the four text lists are `List<String>?`.
`getLabelAndValue` of a dataset controller returns `({List<String> label, String value})`: a falsy label is the
empty List (`dataLabelLinesOf`). The tooltip options `filter`, `itemSort` and `external` hold the typed functions
`TooltipItemFilter`, `TooltipItemComparator` and `TooltipExternal` of `tooltip_callbacks.dart`, also in a raw
config, with no `this`; a function of another type stops a debug build. The typed API has `ChartTooltip.filter`,
`itemSort` and `external`. `types.TypedTooltipItem`, `ChartTooltipItem` and the two records of
`plugin.tooltip.dart` are removed. In the tests, `test/support/data_label.dart` gives the native label of a
reference label (`nativeDataLabel`) and the plain forms of the native items.

An active element is the native extensible class `ActiveElement` of `lib/src/types/active_element.dart` (row
`adapt-native-active-element`, doc/native-active-element-design-draft.md): `datasetIndex` and `index` are `int`,
and `element` is nullable. The interaction modes make it, `getActiveElements` gives it, and `setActiveElements`
of the chart and of the tooltip take a `List<ActiveElement>` with no element. `InteractionItem`,
`ActiveDataPoint` and the typed view `ChartHit` are removed.

An index is an `int` (Chart.js ADR 0129, row `adapt-int-indexes`): a dataset index, a data index, and the start
and the count of a range of data elements, in the chart methods (`getDatasetMeta`, `hide`, `show`,
`toggleDataVisibility`), `ChartMeta.index`, the dataset controller and the eight controllers (`getParsed`,
`getLabelAndValue`, `getStyle`, `getContext`, `updateElements`, `parse`), the interaction modes, the context keys
`index`, `dataIndex` and `datasetIndex`, the hook arguments and `each`. An absent index is Dart `null`. The four
angle methods of the radial linear scale take a `num`. The decimation algorithms and the line segments keep
their inner numbers. Ported code writes no `i.toDouble()` or `i * 1.0` for an index.

A tick is the native extensible class `Tick` of `lib/src/types/tick.dart` (row `adapt-native-tick`,
doc/native-tick-design-draft.md): `value` is a `double`, `label` is the `List<String>?` of its lines, `major` is a
`bool`. The option `ticks.callback` holds a `TickCallback` of `core.scale.dart`, also in a raw config:
`List<String>? Function(Scale scale, double value, int index, List<Tick> ticks)`. The scale is the first
argument, null removes the tick, and an empty list keeps it with no line. A function of another type stops a
debug build; `false` stays no callback. The three formatters of `core.ticks.dart` are functions of that type.
The typed API has `AxisTicks.callback`; `AxisTicks.format` and `AxisTickInfo` are removed. In the tests,
`test/support/tick_label.dart` gives the upstream form of a native label (`upstreamTickLabel`) and the native
label of a reference label (`nativeTickLabel`); a tick callback of a test is a native function.

Text direction options hold `dart:ui.TextDirection` in raw and typed configs (Chart.js ADR 0124). The canvas
`direction` is nullable: null selects inherited element direction. `overrideTextDirection` returns the previous
native value, and legend/tooltip restore it in finally blocks. They write no CSS direction. `prevTextDirectionOf`
is removed. The fix corresponds to upstream PR #12371 without changing the pin.

Padding options hold `EdgeInsets` through raw and typed configs (Chart.js ADR 0123). A supplied inset replaces all
four sides; omitted options inherit. Scalar label spacing remains numeric. `PaddingScope` and `toPadding` remain
for border widths and internal minimum padding, not padding option conversion.

The dataset option `clip` holds a `ChartClip` of `lib/src/types/chart_meta.dart` in raw and typed configs (row
`adapt-chart-clip-option`): `ChartClip.all(5)` is `clip: 5`, `ChartClip.none` is `clip: false`, and
`ChartClip(left: 5, right: -2)` sets sides; a null or omitted side has no clip. A number, a bool or a Map stops a debug
build. The typed API has `Dataset.clip`. The scale option `clip` stays a bool. `getMaxOverflow` of a dataset
controller gives a `double?`, where Dart `null` is the JS `false` (row `adapt-max-overflow`).

The line option `segment` holds a `LineSegmentStyle` of `lib/src/types/line_segment_style.dart` in raw and typed configs
(Chart.js ADR 0142, row `adapt-native-line-segment-style`): seven typed functions of a `ScriptableLineSegmentContext`
(typed `p0`, `p1`, `p0DataIndex`, `p1DataIndex` and `datasetIndex`), for example
`LineSegmentStyle(borderColor: (s) => s.p0.skip == true ? red : null)`. `_doSplitByStyles` calls them in the key order of
`readStyle`; a null function or result keeps the line style. The scopes merge with `LineSegmentStyle.merge`, as fonts merge
(`nativeMergeKind` and `mergeNativeOptionValues` of `helpers.core.dart`, `_mergeNativeOptions` of `helpers.config.dart`).
A Map or a constant stops a debug build. The typed API has `segment` on `LineDataset`, `ScatterDataset`, `RadarDataset`
and `LineElementStyle`; `lib/chartjs.dart` exports both classes. The reference tests make the style from the `segment` Maps
of the generators and compare the names of its functions (`test/support/segment_style.dart`).

## Porting rules

1. **Port from the pinned source.** Read the upstream file in `third_party/Chart.js` (check it out
   first). Never port from memory, from upstream `master`, or from other Dart chart libraries.
2. **Mirror upstream structure.** Same module split and names (Dart-cased), so upstream releases can
   be diffed and replayed. Each ported file starts with a header naming its source, license and
   holder, `// Ported from <project> <version> <path> (<SPDX license>, <copyright holder>).`, e.g.
   `// Ported from Chart.js v4.6.1 src/helpers/helpers.math.ts (MIT, Chart.js Contributors).`
   Under a commit pin, the version is `v<last version>+<sha8>`. A file with no upstream source
   starts with the port-only marker `// Original code, not ported from Chart.js: <reason>.`
   instead. All files under `test/port/` and `tool/` are port-only. `check:headers` enforces
   line 1.
3. **Port the specs.** Upstream `test/specs/<module>.tests.js` becomes a test file in `test/specs/`
   (see below). Behaviour without an upstream spec still needs tests.
4. **Track parity.** Update the status text of the module in
   `packages/flutter_chartjs_port/doc/status.yaml` in the same change. Then run
   `dart run melos run parity`. Tool 6 writes `doc/parity.md`. Do not edit it by hand.
5. **No JavaScript at runtime.** No WebView, no JS engine, no `dart:js_interop` in library code
   (ADR 0001). Library code must compile for every Flutter platform and for web WebAssembly.
   `check:lib-imports` fails on a `lib/` import outside its allowlist.
6. **Bumping upstream** is its own change (ADR 0005). The submodule is a shallow clone without
   tags, so fetch both tags first:
   `git -C third_party/Chart.js fetch --depth 1 origin tag <old-tag> tag <new-tag>`,
   `git -C third_party/Chart.js checkout <new-tag>`, review
   `git -C third_party/Chart.js diff <old-tag> <new-tag> -- src test/specs test/fixtures`, and the
   bump report once it exists. A commit pin (`packages/flutter_chartjs_port/doc/upstream-tracking.md`
   §2.4) fetches the full commit in place of `<new-tag>`: then `chartJsVersion` is
   `<last version>+<sha8>`, and the Chart.js `ref` and `commit` are the full commit. Then run
   `git add third_party/Chart.js` and update `chartJsVersion` and the Chart.js `version`, `ref`
   and `commit` in `packages/flutter_chartjs_port/tool/port_sources.yaml`. Run `upstream:manifest`.
   Port the diff for every started module. Close the ledger rows of the range. Move the Chart.js
   citations of `doc/differences.md` to the new pin (`upstream-tracking.md` §4.9). Restamp the
   headers (`packages/flutter_chartjs_port/doc/upstream-tracking.md` §4.8). Update the status texts in
   `doc/status.yaml` and run `dart run melos run parity`. Backports follow ADR 0006. They never
   move the submodule. `upstream:check` and `packages/flutter_chartjs_port/test/upstream_test.dart`
   fail on a mismatch.

The rules below come from the accepted ADRs and from two plans. The plans, `porting-flow.md` and
`upstream-tracking.md`, are still proposed. The doc paths are relative to
`packages/flutter_chartjs_port/doc/`.

- Backports from upstream `master`: ADR 0006 and `upstream-tracking.md` §2.2 (proposed).
- The backport header line `// Upstream backport: chartjs/Chart.js@<sha8> (#<PR>).`:
  `upstream-tracking.md` §2.5 (proposed). `check:headers` already accepts the line.
- The module status values of the `parity.md` legend: `porting-flow.md` §1 step 7 (proposed).
- `// DIVERGES(chartjs): <row id>, <reason>` markers and their `differences.md` rows:
  `porting-flow.md` §4 (proposed). `check:headers` already pairs markers with rows.
- The JS numeric translation rules: Chart.js ADR 0045. Number formatting: Chart.js ADR 0119
  (package:intl as it is, with no correction of its defects).
  Emulate JavaScript only where the result changes behavior (Chart.js ADR 0034): the ticks, the
  hit element, the item order, the resolved option, a throw, or a value that reaches a layout, a
  scale, an element property, a hit test, a discrete decision or a public return value. Do not
  emulate JavaScript for exact digits or pixels only. `check:js-semantics` already fails on the
  flagged forms. A kept form carries `// js-ok: <reason>`.
- Deferred plans (`porting-flow.md` §5.1), for example
  `packages/flutter_chartjs_port/doc/canvas-cuts-plan.md`: do not do their work in a phase. A change
  that edits a file that a deferred plan cites updates the plan in the same commit (the
  references, the inventory, the pinning tests, the estimates). A trigger of §5.1 brings the plan
  forward.
- Performance (`porting-flow.md` §1.1, proposed): when two Dart forms give the upstream behavior,
  choose the form with the larger measured gain. The priority is the upstream behavior, then
  performance, then the upstream structure, then less code of our own. A faster form that changes
  the upstream structure gets a `DIVERGES` marker and an `adapt` row. Record the figures in
  `performance.md`.
- The JS runtime in `lib/src/js/`: `jsObjectKeys` (`Object.keys` order), `jsSort` (the stable
  `Array.prototype.sort`), `jsCall` (a call of a JS function value with JS arity), `jsGet` (the
  property read `object[key]`), `jsOrZero` (`value || 0` before arithmetic, Chart.js ADR 0017 §8),
  `jsAdd` (the operator `a + b` on a raw option value: a string operand joins, else the numbers
  add), `jsGetKey` (the read `object[key]` of a parsed item, a data item or a stack object, with the
  `jsGet` result; a read of a resolver stays `jsGet`), `jsGetIndex` (the read `object[index]` with a
  number index: a List gives the item at a whole index in range, else `undefined`), `jsSetIndex`
  (the write `list[index] = value`: a write at the length appends, a write past it or at a negative
  index throws a `RangeError`), `jsLessThan` (the operator `a < b` on raw values: two strings
  compare by their code units, a `DateTime` by its time value) (Chart.js ADR 0036) and the
  `undefined` sentinel (Chart.js ADR 0043). `Math.hypot(a, b)` has no runtime function: it is
  `math.sqrt(a * a + b * b)` (Chart.js ADR 0135). `Math.round(x)` is `x.roundToDouble()` (Chart.js
  ADR 0138), and `Math.pow(x, 2)` is `math.pow(x, 2.0)` (Chart.js ADR 0136). `Math.max` and
  `Math.min` have no
  runtime function: they are `dart:math` `max` and `min` with the type argument `double`, explicit
  or inferred (`math.max<double>(x, 0)`; a call in arithmetic infers `num`), and
  `check:js-semantics` flags a `num` type argument (Chart.js ADR 0134). `lib/js_semantics.dart` exports each
  name of `lib/src/js/` for add-on ports (Chart.js ADR 0132). `JsStringList` of `js_array.dart` is a string
  as an array-like value: the reads `s[i]` and `s.length`, and a `TypeError` for each write.
  `_dataCheck` keeps a string `data` in it.
  `jsToString` of a `DateTime` gives the `Date.prototype.toString` text in the platform zone, with
  the V8 zone name on the web and in UTC on the VM (Chart.js ADR 0036, differences.md row
  `platform-date-zone-name`). The conversions of `js_webidl.dart` (`canvasStyle`, `canvasNumber`,
  `canvasLineCap`, `canvasLineJoin` and `canvasLineDash`) apply the WebIDL
  conversion of a Canvas 2D setter or of `setLineDash` to an option value (Chart.js ADR 0017 §8).
  The options `borderCapStyle` and `borderJoinStyle` (also their hover keys of a line), and
  `lineCap` and `lineJoin` of the canvas interface and of a legend item, hold the Flutter enums `StrokeCap` and `StrokeJoin` (row
  `adapt-flutter-stroke-enums`, the schema shapes `strokeCap` and `strokeJoin`), also in a raw
  config: `lib/` has no keyword of a cap or a join and no table from a keyword to an enum value. A
  keyword stops a debug build in `canvasLineCap` or `canvasLineJoin`. The enums are the complete
  set that the engine draws, so they need no class for plugins. The mock context of the tests
  records the name of the enum value, which is the upstream keyword. The typed API has
  `borderCapStyle` and `borderJoinStyle` on the line datasets and on `LineElementStyle`. Ported code calls them where upstream
  uses the JS builtin or gives an option value to the canvas. A typed Map read stays `map[key]`. Use
  `jsGet` when the receiver can be a value that is not a Map, or when an absent key must give
  `undefined` and not `null`. `helpers.merge` also writes into a `types.PropertyAccess` target, for
  example an element (Chart.js ADR 0039 §10). `clone` and `mergeIf` keep an element as a leaf.
  Ported code tests for the sentinel with `identical(value, undefined)`. The runtime also has these
  parts:
  - `JsClass` of `js_class.dart`: a JS class as a value (Chart.js ADR 0020). A read of a
    static property follows the superclass chain. `jsConstruct` is `new target(...args)`.
    `jsAssign` is `Object.assign` on a class value or a Map.
  - `jsIsFunction` (`typeof value === 'function'`) is true for a class value. `jsCall` throws an
    `ArgumentError` for a class value. A test of `typeof` is a Dart type test.
  - `jsObjectFreeze` is `Object.freeze`, and `Object.isFrozen` is the `isFrozen` getter of a
    `JsFreezable` (Chart.js ADR 0021 §5). Only a `JsFreezable` freezes. A write into frozen options throws a
    `TypeError`.
  - `jsOwnPropertyNames` is `Object.getOwnPropertyNames`. For a resolver, it gives the keys of the
    `ownKeys` trap.
  - `jsSplice` is `Array.prototype.splice`. `start` and `deleteCount` go through
    `ToIntegerOrInfinity`. Dart `null` stands for an absent `deleteCount`.
  - `Date.now()` has no runtime function: it is `clock.now().millisecondsSinceEpoch` of
    package:clock, with `.toDouble()` where the code computes with doubles (Chart.js ADR 0143).
    Inside `testWidgets` and `withClock`, the fake clock moves it. Ported code never calls
    `DateTime.now()`. A `DateTime` is a JS `Date`: `jsToNumber` gives its time value (Chart.js ADR
    0024).
  - `js_promise.dart` has the promise jobs of Chart.js ADR 0019 §7:
    `jsEnqueuePromiseJob`, `jsRunWithMicrotaskCheckpoint` (the checkpoint after an animator frame
    callback) and `jsPromiseAll` (`Promise.all`).
- Rule 2 for the typed layers (Chart.js ADR 0054 §13). A file that ports an upstream module
  keeps its mapped path, its line-1 header and the upstream function names and order, also in
  the config, resolver and data layers. The data representation of these layers is typed:
  option scopes, resolved options, parsed items, element properties, animation keys, contexts
  and plugin objects are Dart classes, not emulations of JS objects, and none is a `Map` (the
  structural rule of `check:typed-reads`). A ported file with a typed representation carries one
  file marker `// DIVERGES(chartjs): <row id>, the typed representation of Chart.js ADR 0054`
  after its header. The files of `lib/src/options/` are port-only; the generated ones come from
  `tool/options_schema.yaml` through `tool/options_gen.dart`. A typed object is read by name only
  through its face (`JsObjectFace`), in a cold path; a by-name form that stays in `lib/src` has a
  reason line in its baseline of `tool/typed_reads/`.
- File names in the upstream spelling and the `_` rules: Chart.js ADR 0012.
  `check:headers` already compares each Dart path with the mapped path.
- Spec names and skip reasons: `porting-flow.md` §1 step 5 (proposed). The skip reasons are
  `'blocked: <module>'`, `'n/a: <reason>'` and `'diverges: <row id>'`. `test:cases` fails on
  other reasons. A chart case that needs only ported modules has a body and passes through the
  harness of Chart.js ADR 0022. The temporary reason `'blocked: harness'` of the phase 5 port step
  is gone.
- The spec paths and the test folders: Chart.js ADR 0012 and `porting-flow.md` §1 step 5
  (proposed). Upstream `test/specs/<base>.tests.js` becomes
  `packages/flutter_chartjs_port/test/specs/<base>_test.dart`. A pure-layer spec imports `package:test`,
  not `flutter_test` ([Tests](#tests)). It calls `setUpSpecs()` of
  `package:chartjs_test_utils/pure.dart` first in `main()`. Tests of behavior without an upstream
  spec go in `test/port/`. `check:headers` already compares each spec path with the mapped path.
- The source list `packages/flutter_chartjs_port/tool/port_sources.yaml`: Chart.js ADR 0035. It has
  one entry for each project that the package ports code from: Chart.js and chartjs-test-utils.
  The `@kurkle/color` entry is in `packages/flutter_kurkle_color_port/tool/port_sources.yaml`. Code from another project also needs an entry, with the license and
  holder of the header. A Chart.js bump (rule 6) also updates the Chart.js `version`, `ref` and
  `commit` in the entry. `check:headers` already fails on a
  mismatch.
- The notice of chartjs-test-utils goes in the `LICENSE` of
  `packages/chartjs_test_utils`, not in `packages/flutter_chartjs_port/LICENSE` (Licensing item 1):
  Chart.js ADR 0035. `check:headers` reads the `LICENSE` of the package that contains
  the file.
- The reference engine: Chart.js ADR 0045. Take JavaScript reference values only from the
  darwin-arm64 build of Node.js v24.22.1 (V8 13.6.233.17-node.58, ICU 78.3). Each test of a data
  file pins the Node.js version and the architecture of its data. Never take reference values
  from a browser. `sin`, `cos`, `atan2` and `log` are `dart:math` as it is, and `log10` gives the
  exponent of an exact power of ten (Chart.js ADR 0122): the last bit can differ from V8, and a
  reference test gives a tolerance there or lists a hit point on an arc border (`hitBorders`).
- The four theming invariants (specs run unthemed, no forui or Material in `lib/`, no
  `Chart.defaults` writes for theming, no `lib/src/theme/` import in ported files): Chart.js ADR
  0050. `check:lib-imports` already fails on the two import invariants.

The D3 port applies the rules above with these changes. The D3 ADRs are proposed. The doc paths
are relative to `packages/flutter_d3_port/doc/`.

- Rule 1: read the upstream file in `third_party/<repo>`. Never port from `d4` or from another
  Dart D3 package (`prior-art/README.md`).
- Rule 2: the header names the repository and its tag, for example
  `// Ported from d3-array v3.2.4 src/ticks.js (ISC, Mike Bostock).` The port-only marker is
  `// Original code, not ported from D3: <reason>.` D3 ADR 0001 item 8 gives the holder strings.
  A file whose name fails the `file_names` lint has `// ignore_for_file: file_names` after its
  header lines (D3 ADR 0002).
- Rules 3 and 4: port the specs by D3 ADR 0004. Update the row of the repository in `parity.md`
  in the same change. From D3 phase 2, tool 6 writes `parity.md`.
- Rule 6: a bump moves one repository. It changes the submodule, the entry in
  `tool/port_sources.yaml` and the headers of the files of that repository (D3 ADR 0001 item 7).
  A bump of `third_party/d3` also changes `d3Version`. `upstream:check` and
  `packages/flutter_d3_port/test/upstream_test.dart` fail on a mismatch.
- `upstream-ledger.md` has one section for each repository. A difference carries
  `// DIVERGES(d3): <row id>, <reason>` and a row in `differences.md`.
- Number strings (D3 ADR 0003): when a string is the result of a module, its JS digits are
  behavior. Examples are d3-format, d3-path, d3-color and d3-time-format. The rules of Chart.js
  ADR 0045 apply to them.
- No port depends on another port (ADR 0008). Thus D3 code never imports
  `package:flutter_chartjs_port`. In D3 phase 1, ADR 0008 copies the generic runtime of `lib/src/js/`
  into the shared package `js_semantics`.

The ECharts port applies the rules above with these changes. The ECharts ADRs are proposed. The
doc paths are relative to `packages/flutter_echarts_port/doc/`.

- Rule 1: read the upstream file in `third_party/echarts` or `third_party/zrender`. Never port
  from a Dart ECharts package or from another port of ECharts (`prior-art/README.md`).
- Rule 2: the header names the project and its tag, for example
  `// Ported from Apache ECharts 6.1.0 src/util/number.ts (Apache-2.0, The Apache Software Foundation).`
  or `// Ported from zrender 6.1.0 src/core/matrix.ts (BSD-3-Clause, Baidu Inc.).` The port-only
  marker is `// Original code, not ported from Apache ECharts: <reason>.` A ported file keeps the
  upstream license comment block verbatim after its header lines (ECharts ADR 0001 item 11). A
  file whose name fails the `file_names` lint has `// ignore_for_file: file_names` after its
  header lines (ECharts ADR 0002).
- Rules 3 and 4: port the specs by ECharts ADR 0005. Update the row of the module in `parity.md`
  in the same change.
- Rule 6: an ECharts bump also moves zrender when the new ECharts `package.json` requires another
  zrender version. It changes the submodules, `echartsVersion`, `zrenderVersion`, the entries in
  `tool/port_sources.yaml` and the headers (ECharts ADR 0001 item 9). `upstream:check` and
  `packages/flutter_echarts_port/test/upstream_test.dart` fail on a mismatch.
- `upstream-ledger.md` has one section for each repository. A difference carries
  `// DIVERGES(echarts): <row id>, <reason>`, also in a zrender file, and a row in
  `differences.md`.
- Numbers and JS values follow ECharts ADRs 0003 and 0004 with the rules of Chart.js ADRs 0045
  and 0034. No port depends on another port (ADR 0008). Thus ECharts code never imports
  `package:flutter_chartjs_port` or `package:flutter_d3_port`.

The chartjs-plugin-zoom port applies the rules of the Chart.js port with these changes. The zoom
ADRs and ADR 0009 are proposed. The doc paths are relative to
`packages/flutter_chartjs_plugin_zoom_port/doc/`.

- Rule 1: read the upstream file in `third_party/chartjs-plugin-zoom` at the pinned commit. Never
  port from the release `v2.2.0` (Hammer.js) or from another zoom package.
- Rule 2: the header is
  `// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 <path> (MIT, chartjs-plugin-zoom contributors).`
  The port-only marker is `// Original code, not ported from chartjs-plugin-zoom: <reason>.`
  `src/<name>.ts` becomes `lib/src/<name>.dart`. A spec `test/specs/<name>.spec.js` and a unit
  test `src/<name>.test.ts` become `test/specs/<name>_test.dart`. `test/index.js` becomes
  `test/flutter_test_config.dart` (Zoom ADR 0002).
- Rules 3 and 4: port the specs. Update the row of the file in `parity.md` in the same change. A
  person writes `parity.md`. A file that waits for a host change has the status
  `blocked: host <seam ids>`.
- Rule 6: a bump moves the submodule, `chartjsPluginZoomVersion`,
  `chartjsPluginZoomPackageVersion`, the entry in `tool/port_sources.yaml` and the headers (Zoom
  ADR 0001 item 7). `upstream:check` and `test/upstream_test.dart` fail on a mismatch.
- The host connection (ADR 0009, Zoom ADR 0003): the zoom port imports only
  `package:flutter_chartjs_port/chartjs.dart`, `package:flutter_chartjs_port/helpers.dart`,
  `package:flutter_chartjs_port/js_semantics.dart` and the app library, never
  `package:flutter_chartjs_port/src/`. Its tests also import
  `package:chartjs_test_utils/flutter.dart` and `pure.dart`. `check:lib-imports` fails on another
  import. A part of the host that the public
  libraries do not give is a host change with a Chart.js ADR, first. `host-seams.md` lists each
  use of the host with its state. A change that closes a seam updates its row.
- A difference carries `// DIVERGES(zoom): <row id>, <reason>` and a row in `differences.md`.
  `check:headers` pairs the markers and the rows.
- The JS numeric rules of Chart.js ADRs 0045 and 0034 apply. The zoom port takes the JS runtime
  from `package:flutter_chartjs_port/js_semantics.dart` (Chart.js ADR 0108, seam H13), and from the
  package `js_semantics` when ADR 0008 makes it. It does not copy `lib/src/js/` of the host.

The chartjs-chart-sankey port applies the rules of the Chart.js port with these changes. The
sankey ADRs are proposed. The doc paths are relative to
`packages/flutter_chartjs_chart_sankey_port/doc/`.

- Rule 1: read the upstream file in `third_party/chartjs-chart-sankey` at the pinned tag. Never
  port from d3-sankey or from another sankey package (`prior-art/README.md`).
- Rule 2: the header is
  `// Ported from chartjs-chart-sankey v0.19.1 <path> (MIT, Jukka Kurkela).` The port-only marker
  is `// Original code, not ported from chartjs-chart-sankey: <reason>.` `src/<path>.ts` becomes
  `lib/src/<path>.dart`. A unit test `src/<path>.test.ts` and a spec `test/specs/<name>.spec.js`
  become `test/specs/<path>_test.dart`. A fixture `test/fixtures/<path>.js` becomes
  `test/fixtures/hand/<path>.dart`. `test/setup.js` becomes `test/flutter_test_config.dart`. A file
  whose name has a hyphen has `// ignore_for_file: file_names` after its header (Sankey ADR 0002).
- Rules 3 and 4: port the specs. Update the row of the file in `parity.md` in the same change. A
  person writes `parity.md`.
- Rule 6: a bump moves the submodule to a later release tag, `chartjsChartSankeyVersion`, the entry
  in `tool/port_sources.yaml` and the headers, and runs `tool/reference/fixtures_reference.mjs`
  again. `upstream:check` and `test/upstream_test.dart` fail on a mismatch.
- The host connection (ADR 0009, Sankey ADR 0003): the port imports only the public libraries of
  the host. A part of the host that they do not give is a host change with a Chart.js ADR. A Dart
  form in the port that stands for a host change is a seam: `host-seams.md` has a row for it. A
  change that closes a seam updates its row.
- A difference carries `// DIVERGES(sankey): <row id>, <reason>` and a row in `differences.md`.
- An option that is a keyword upstream is an enum, and an option that the host holds as a Dart
  object has that object (Sankey ADR 0002 items 7 and 8). The port takes the JS runtime from
  `package:flutter_chartjs_port/js_semantics.dart`: each sort is `jsSort`.

## Tests

- The CI job `test` runs the tests in three shards (`--total-shards=3`). package:test puts a
  continuous part of the tests of each test file in each shard. Thus a test must not need the result
  of an earlier test of its file. A test that uses the state of an earlier test makes that state
  again, or checks it only when that test ran in the same shard. Examples are the group
  `harness-register-builtins` of `packages/flutter_chartjs_port/test/port/flutter_test_config_test.dart`,
  `packages/flutter_chartjs_port/test/port/core/date_format_locale_test.dart` and the group
  `harness-release-at-unmount` of `packages/chartjs_test_utils/test/index_test.dart`.
- A core (historically pure-layer) file may use `dart:ui.Color`, but reaches no
  `package:flutter` framework library through its direct or indirect imports (ADR 0061),
  except `package:flutter/animation.dart` for the curve classes of the option `easing`, and
  `package:flutter/painting.dart` with `show EdgeInsets, TextOverflow, TextStyle` for padding and fonts (Chart.js ADRs
  0123 and 0116). `check:lib-imports` computes the core layers from the roots in
  `packages/flutter_chartjs_port/tool/src/lib_imports.dart`. The roots include `lib/src/js/`,
  `lib/src/types/`, the helpers except `helpers.extras`, the files of
  `lib/src/elements/`, `plugin.decimation` and the files of `plugin.filler/` of `lib/src/plugins/`,
  and `platform.base`, `platform.basic` and `native_event` of `lib/src/platform/`. Of
  `lib/src/core/`, the roots are `core.defaults`, `core.element`, `core.config`, `core.adapters`,
  `core.interaction`, `core.layouts`, `core.animation`, `animation_spec`, `reduced_motion`,
  `tick_font_cache`, `core.typedRegistry` and the port-only `date_*.dart`. Of
  `lib/src/theme/`, the roots are `compile.dart` and `presets.dart`.
  The canvas interface `lib/src/canvas/canvas.dart` is pure, because `helpers.canvas` imports it.
- Write core tests with `package:test`. Execute them through Flutter on the VM
  (`test`) and in Chrome with JavaScript/DDC and WebAssembly (`test:web`).
- A test file that imports `dart:io` or VM-only framework/engine test code needs
  `@TestOn('vm')` after its header line. `test:web` does not compile it. `check:lib-imports` fails
  on a test file without `@TestOn('vm')` that imports more than pure layers, `package:test` and
  `package:chartjs_test_utils/pure.dart`. It does not examine the tests of `chartjs_test_utils`.
  Keep the same rule there by hand.
- `flutter test` runs `packages/flutter_chartjs_port/test/flutter_test_config.dart` around each test
  file of `flutter_chartjs_port`. It sets the test view to DPR 1 and 800 x 600 before each test, also
  after a test calls `tester.view.reset()`. It restores `defaults`, `overrides` and `descriptors`
  after each test (`setUpDefaultsRestore()`, the row `harness-defaults-restore`). Thus a test that
  changes them does not change the next test.
- `flutter_test_config.dart` also runs the oracle O2 (row `harness-foreign-audit`): after the last
  test of each file, a foreign pair of the file that `reviewedForeignPairs` of
  `test/port/options/foreign_audit.dart` does not list fails the file. A test that writes a value
  of another type into a typed option object on purpose sets `foreignAudit` to its own function
  and restores it with `addTearDown`, as `test/port/options/foreign_audit_test.dart` does.
- `flutter_test_config.dart` sets the default date zone to UTC (`setDefaultDateZone('Etc/UTC')`,
  the port of `test/index.js:23`). `setUpSpecs()` does the same. A test that changes the zone or
  calls `DateAdapterBase.override` restores the old state with `addTearDown`.
- `flutter_test_config.dart` registers the built-in components before `main()` of each test file and
  before the snapshot of the restore (`setUpBuiltins()`, the row `harness-register-builtins`,
  Chart.js ADR 0022 §8). After the registration, it sets `defaults.plugins.colors.enabled = false`
  (the port of `test/index.js:25-28`), before the snapshot of the restore. `setUpSpecs()` and
  `removeBuiltins()` remove them again, also the colors plugin and its defaults. Thus a pure-layer
  file has the same state under the VM and browser Flutter test runners.
- The unmount of the harness body calls `releaseCharts` (the row `harness-release-at-unmount`).
  This runs before the end-of-test checks of flutter_test and before the `tearDown` functions. A
  `tearDown(releaseCharts)` is the fallback after a failed test. `releaseCharts` never deletes a
  chart. Thus each test destroys the charts of the earlier tests of its file again, as upstream.
- A spec case that creates a chart is a `testWidgets` test (Chart.js ADR 0022 §2). Its file
  imports `flutter_test` and `package:chartjs_test_utils/flutter.dart`, and has `@TestOn('vm')`.
  `acquireChart` is synchronous. It throws a `StateError` outside the body of a `testWidgets`
  test. Thus a ported `beforeEach` or `afterEach` that acquires or reads a chart is a local
  function. Each test calls it first or last in its body.
- A pure-layer spec file that gets a chart case moves to `@TestOn('vm')` and `flutter_test` as a
  whole. Its pure cases then run on the VM only. A spec file with chart cases does not call
  `setUpSpecs()`, because its charts need the built-in components.
- A nested Map literal of a spec config needs the type `<String, Object?>`. `acquireChart` and
  `Config` write into it. A narrower Map, for example `{'responsive': true}`, throws a
  `TypeError` at the write.
- A dataset Map of a chart that the colors plugin colorizes needs the type `<String, Object?>`. The
  colorizers write `borderColor` and `backgroundColor` into it (row `js-semantics-narrow-datasets`).
- A chart spec ports a Jasmine spy of a function value as a recording function value (`spyOn` of
  `test/support/jasmine.dart`). The spec stores it in place of the spied property, as
  `core.plugin_test.dart` does. A spy of a method is a spy object in the slot that the library
  reads (`spyOnElementDraw` for `meta.data[i]`, `spyOnDataset` for `meta.dataset`,
  `spyOnArrayListener` for the listeners of a data array, a context in `chart.ctx`).
  `test/support/jasmine.dart` holds the shared matchers (`jasmineEquals`, `objectContaining`,
  `anyFunction`, `JasmineOptions`) and spies (Chart.js ADR 0030). A draw spy needs
  `animation: false` (the default of `acquireChart`) or the end of the animations: it throws a
  `StateError` for an element with a running animation. A spy of a plugin hook is `hookSpy()`:
  its `hook` or its `cancelableHook` goes into the hook field of a native plugin (Chart.js ADR
  0144).
- A Jasmine `spyOn(chart, 'update')` is a plugin with a `beforeUpdate` hook (`_spyOnUpdate` of
  `test/specs/global.defaults_test.dart`, Chart.js ADR 0041 §11 item 2).
- A plugin of a test is a native `Plugin<Object?>(id: ..., hooks)`, never a Map. A cancelable
  hook returns `bool`. A test that gets a plugin Map from the reference data makes the native
  plugin with `nativePlugin` of `test/support/native_plugin.dart` (`copyReference` of
  `test/port/scales/scale_chart_harness.dart` does it for the key `plugins`).
- Jasmine `this` in a spec port is a set of `late` variables of the group closure.
- A test scale overrides `getPixelForValue(Object? value, [int? index])` and applies
  `jsToNumber(value)` before its arithmetic. A test controller passes the raw
  `jsGet(parsed, axis)` (Chart.js ADR 0025).
- A scale reference test in `test/port/scales/` builds each chart of its generator with
  `acquireChart` in a `testWidgets` case and compares it through `scale_chart_harness.dart`. Its
  `main()` registers the test controller as a class value. The draw calls have the element draws:
  `drawCalls` puts the recording context in `chart.ctx`, in each `scale.ctx`, in the writable
  `DatasetController.ctx` (Chart.js ADR 0030), in the `ctx` of each `Title` box and in the `ctx` of
  the `Legend` box. A `Path2D` argument records as `{path, calls}`
  (`test/port/canvas/path2d_record.dart`). `expectCalls` removes the reference `clip` of the border
  ring of each bar that the port draws without a `clip` (the row `adapt-bar-clip`). A time-scale
  test runs each chart in `withClock` at the fixed `Date.now()` of its generator (`atNow` of
  `scale_time_harness.dart`).
- The controller reference tests in `test/port/controllers/` build each chart of their generator
  with `acquireChart`, run its steps, and compare the observations, the hit queries and the draw
  calls through `controller_chart_harness.dart` (`testControllerChartCases`). The step `setTooltip`
  calls `setActiveElements` of `chart.tooltip` and then `update` on both sides (Chart.js ADR 0041 §3
  item 6). Each file also runs its cases with the light preset (theming.md §8 test 3): then the
  colors compare in their parsed form, and the options compare only the keys of upstream. A JS
  `TypeError` of a case is a Dart `TypeError`. A step that throws stands in the data as `{do}`
  without observations.
- The tests of the typed API are in `test/port/typed/` (Chart.js ADR 0052 §11). They have
  `@TestOn('vm')`: the typed files import `dart:ui`. The lowering twins (`lowering_test.dart`,
  `expectTwin` of `twin.dart`) compare the Map of each typed field with its raw twin. The docs
  twins (`docs_twins_test.dart`, `expectChartTwin` of `chart_twin.dart`) show a typed config in a
  `ChartView` and its raw twin in a `ChartView.raw`, and compare the observations of the
  controller harness, the hits on a grid and the draw calls, before and during a hover, unthemed
  and under `ChartThemeData.light()`, with the colors in parsed form. A docs twin compares two
  charts through the public API: it holds when the internal model of the chart changes. The raw
  twin of a docs config is a copy of the gallery config: a change of a docs config of the
  gallery changes its copy in the same commit.
- The plugin reference tests in `test/port/plugins/` run the cases of their generator through
  `testPluginChartCases` of `plugin_chart_harness.dart`: the controller harness with `hits: false`,
  the key `boxes` (`observeBoxes`) and a key `plugins.<id>` for each observer of the file. A unit
  case turns off each other plugin (`unitPlugins` of `plugin_chart_common.mjs`), and a full case
  runs the plugins with their defaults (Chart.js ADR 0041 §3 and §4).
- The test files of a controller unit register the controller in `main()`
  (`Chart.register([<Name>Controller.jsClass])`) until the integration agent of its wave adds the
  controller to the namespace `controllers` (Chart.js ADR 0030 §3 item 4). Then
  `flutter_test_config.dart` registers it, and the line goes. A test-only controller subclass
  with its own id (the polar area subclass with option sharing) registers in the `setUp` of its
  group and unregisters in the `tearDown`.
- The JS reference charts get the `BasicPlatform` of Node.js, whose `updateConfig` writes
  `animation: false` (`platform.basic.js:20-22`). The Dart harness gives the platform of
  `platform.flutter.dart`, which keeps the option, as the DOM platform does. Thus a controller
  generator with a case that needs the animation options (the doughnut and polar area `reset`
  cases) puts the no-op `updateConfig` of `BasePlatform` on `BasicPlatform` first.
- The doughnut test file maps the expected JS `null` of `xAxisID` and `yAxisID` to
  `undefined` (`_undefinedAxisIds`): the empty `linkScales` keeps the JS `null`, and the Dart
  field `ChartMeta.xAxisID` (a `String?`) has Dart `null` for both.
- The doughnut and polar area generators have the `legend:` cases of Chart.js ADR 0041 §5: the
  real legend with the label options of the old test legend, and the step `clickLegend`. The probe
  `realLegend` reads `legendItems` through `types.LegendElement` and `legendHitBoxes` through a cast
  to `Legend`. The polar area case `legend: off` calls the override `generateLabels` without a
  legend (`TypeError`). The `legend:` cases run unthemed only.
- The controller generators have no step that writes an option. A pin test of an option change
  takes its expected values from a probe on the pinned build, and the test comment gives the
  probe and its output (`controller.scatter_test.dart`, group `showLine`).
- A spec that changes a data array of a chart (`push`, `pop`, `shift`, `splice`, `unshift`)
  changes the `List` and then calls `notifyArrayListeners`, the body of the hooked method
  (differences.md row `platform-array-events`; the helpers `_push` to `_unshift` of
  `test/specs/core.datasetController_test.dart`). `chart.getActiveElements()` in a Jasmine
  `toEqual` is the list of the objects `{element, datasetIndex, index}`. The event object
  `{type, chart, native: true, x, y}` of `core.interaction.tests.js` is a `types.ChartEvent` with
  `native` null.
- `toEqualOptions` reads the keys of an expected object with `jsObjectKeys`, as the upstream
  `for...in` with `hasOwnProperty` does. Thus it compares only the keys of the first scope of an
  expected resolver. An actual element or tooltip (a `types.ElementPropertyRead`) is an object:
  the matcher reads each expected key by name. An expected element compares with `===` (row
  `harness-expected-element`).
- It also installs the test font (Chart.js ADR 0015, the row `harness-test-font`): Liberation Sans
  under `Helvetica Neue`, `Helvetica`, `Arial`, `Liberation Sans` and `sans-serif`. A text style
  with another family, or with no family, measures with the square FlutterTest font. A test file
  of `chartjs_test_utils` that measures text calls `installTestFont()` itself.
- A custom interaction mode of a test is a subclass of `InteractionMode` in the option `mode`. It
  needs no registration and no restore.
- The defaults restore does not reset the `items` of `registry` (Chart.js ADR 0022 §8). A
  component that several tests of a file need registers in the `main()` of the file, before the
  snapshot of the restore. A component of one test registers in the test and unregisters at its
  end. A pure-layer test file registers its components through a new `TypedRegistry`. A file that
  compares the scopes or the registry with a run of the modules alone calls `setUpSpecs()` or
  `removeBuiltins()` first in `main()`.
- A spec with `setTimeout` or a Jasmine `done` callback is a `testWidgets` case with
  `@TestOn('vm')`. It uses `setTimeout` and `waitForDone` of
  `package:chartjs_test_utils/flutter.dart` (Chart.js ADR 0022 §7). `waitForDone` pumps frames of
  16 ms and fails after the Jasmine timeout of 5000 ms. Do not port a `setTimeout` as one long
  pump.
- The DOM stand-in of `chartjs_test_utils` keeps its element tree between the tests of a file. A
  DOM write outside a `testWidgets` body changes only the element tree. A spec gives the node type
  as a type argument: `document.createElement<HTMLCanvasElement>('canvas')`. The lint
  `omit_local_variable_types` flags a declared variable type.
- A spec file with a fixture group calls `group('auto', fixture.specs('<prefix>'))` at the upstream
  line, with `import '../fixtures/index.dart' as fixture;` (Chart.js ADR 0029). Thus the file has
  `@TestOn('vm')`. Each fixture test has the tag `fixtures`: `test --no-select`, `test:cases` and
  `parity` exclude it, and `test:fixtures` runs it. A hand port is one file at
  `test/fixtures/hand/<path>.dart` with the header of rule 2, the library doc `/// A hand-ported
  fixture config (Chart.js ADR 0029, section 4).` before `library;`, and the function `fixture()`,
  which makes new objects at each call. Its entry in `handFixtures` has the first 12 hex digits of
  the manifest `sha256`. The import prefix is the path without the extension in lower case, with
  each run of other characters than `a-z` and `0-9` as `_`. A fixture skip is an entry of
  `fixtureSkips`. No skip covers a defect. In a hand port, a scriptable option reads `context.tick`
  as a `Tick` (`(jsGet(context, 'tick')! as Tick).value`) and a property of an element with the
  access by name of `Element` (`(jsGet(ctx, 'p0')! as Element)['skip']`), because `jsGet` gives
  `undefined` for these typed objects. A canvas as an image source is `toImageSource()` of
  `UiCanvasElement`. A `moment(...)` value is a `DateTime.utc(...)` of the same time value, with the
  marker of the row `harness-fixture-sources`. `test/fixtures/fixture_events.dart` gives the chart
  event of the raw `mousemove` of the 8 tooltip fixtures (`fixtureMouseMove`, row
  `harness-fixture-sources`). It is outside `hand/`.
- The Node.js generators in `packages/flutter_chartjs_port/tool/reference/` write
  `test/port/js/*_reference.dart`, `test/port/helpers/draw_point_reference.dart`,
  `test/port/elements/*_reference.dart` (point, line, bar and arc),
  `test/port/core/*_reference.dart` (animation, interaction, layouts, scale, scale autoskip, dataset
  controller, registry, controller, date adapter and the resolver trace, D2 of Chart.js ADR 0053,
  kept by Chart.js ADR 0054: `resolver_trace_reference.mjs` runs the dist with a fixed
  `Date.now()` and an animator frame that never runs; `test/port/core/resolver_trace_cases.dart`
  has the user functions and the setups of its cases), `test/port/scales/*_reference.dart` (the six
  scales of `scales/index.dart`), `test/port/controllers/controller_<snake>_reference.dart` (the
  controllers of phase 7 except pie), `test/port/plugins/*_reference.dart` and
  `test/port/plugins/plugin.filler/*_reference.dart` (the plugins of phase 8; the tooltip generator
  writes two files, `plugin_tooltip_reference.dart` and `plugin_tooltip_more_reference.dart`,
  because a data file stays below 2,500,000 bytes),
  `test/port/platform/chart_host_input_reference.dart` (the input path of the legend and the
  tooltip, Chart.js ADR 0037 §17). The other generators run on the reference engine of Chart.js
  ADR 0045.
  `controller_reference.mjs` registers the seven plugins of `src/plugins/index.js` by name (a
  module namespace registers nothing) and sets `defaults.plugins.colors.enabled = false`, as
  `flutter_test_config.dart` does. Each generator on the dist calls `registerBuiltins` of
  `scale_chart_common.mjs` (Chart.js ADR 0041 §1): it registers the four namespaces of
  `src/index.umd.ts:28` and sets `colors.enabled = false`. A future generator without plugins pairs
  with `Chart.unregister([plugins])` in `main()` of its Dart file. The scale generators
  run a build of Chart.js at the pinned commit (`dist/chart.js` of a clone outside the repository,
  the first argument or `CHARTJS_DIST`) through `scale_chart_common.mjs`. Its header gives the build
  steps. It stops unless the clone is at the `commit` of `tool/port_sources.yaml`. It also stops
  unless `third_party/chartjs-test-utils` is at its commit, with no change in `src/`. It measures
  text in Liberation Sans 2.1.5 from the TTF tables. The canvas of `fakeCanvas` has a `style` with
  `getPropertyValue`, `getPropertyPriority` and `setProperty` with the DOM rules, for the canvas
  direction of `textDirection`. `tool/reference/controller_chart_common.mjs` is the shared code of
  the controller generators. It defines a recording `Path2D` before the dist loads. A comment line
  of a data file has at most 80 characters: the generator stops on a longer probe note. `dartArgs`
  of `scale_chart_common.mjs` applies the WebIDL `ToNumber` to the number arguments of the canvas
  and `Path2D` calls (also `bezierCurveTo`, `quadraticCurveTo` and the first five arguments of
  `arc`), as a browser does. A change of `dartArgs` runs each scale and controller generator again,
  and the data of the generators whose arguments are numbers stays byte-identical.
  `tool/reference/plugin_chart_common.mjs` is the shared code of the plugin generators, with
  `unitPlugins`, `observeBoxes` and `runPluginCase` (Chart.js ADR 0041). Its Dart side is
  `test/port/plugins/plugin_chart_harness.dart`. `plugin_filler_reference.mjs` runs on the bundle,
  with `_getTarget` of the source file `filler.target.js`, and also stops unless
  `third_party/kurkle-color` is at its commit. `filler_target_reference.mjs` runs on the source
  files with type stripping and fakes, and stops unless `third_party/Chart.js`,
  `third_party/kurkle-color` and `third_party/chartjs-test-utils` are at their commits.
  `plugin_dispatch_reference.mjs` replaces each hook of the seven plugin objects of the build with a
  recording function and gives each chart an inline plugin `recorder` with every hook name.
  `test/port/plugins/index_test.dart` does the same with recording closures of the same parameter
  count, and restores the hooks with `addTearDown`. `date_adapter_reference.mjs` and the time-scale
  generators also need a `node_modules` folder with moment 2.29.4, moment-timezone 0.5.42 and
  chartjs-adapter-moment 1.0.1, and run with `TZ=UTC`. `date_adapter_reference.mjs` takes the folder
  as its argument. The time-scale generators and `controller_bar_reference.mjs` (for its timeseries
  case) take it as the second argument or from `MOMENT_NODE_MODULES`. The bar test file runs each
  case at the fixed `Date.now()` of the generator. `chart_host_input_reference.mjs` gives the DOM
  events of Chrome for each gesture action of a step (Chart.js ADR 0037, sections 6 to 9) and feeds
  `chart._eventHandler` with one call for each type of `options.events` in the frame, in the order
  of the first event of each type (section 11). `test/port/platform/chart_host_input_test.dart`
  drives the same actions as Flutter pointer events through `ChartHost`, one pump for each step, and
  compares the DOM events of the host too. `tool/reference/text_metrics/` writes
  `test/port/canvas/text_metrics_reference.dart` from headless Chrome. The engine rule of Chart.js ADR 0045
  does not apply to it. Do not edit the generated files by hand.
- The D3 tests use `package:test` (D3 ADR 0004). In phase 0, `test/upstream_test.dart` is the
  only D3 test. It has `@TestOn('vm')`. Thus `test:web` does not run the D3 package yet. The first
  pure D3 test adds the package to `test:web`.
- In a D3 test file with `// ignore_for_file: file_names`, `@TestOn('vm')` comes after the ignore
  line (D3 ADR 0002 section 2). From phase 1, each D3 spec calls `setUpSpecs()` of
  `test/support/spec_setup.dart` first in `main()`. The D3 package has no
  `flutter_test_config.dart`.
- The ECharts tests use `package:test` (ECharts ADR 0005). In phase 0, `test/upstream_test.dart`
  is the only ECharts test. It has `@TestOn('vm')`. Thus `test:web` does not run the ECharts
  package yet. The first pure ECharts test adds the package to `test:web`.
- Each chartjs-chart-sankey test file has `@TestOn('vm')`: `test:web` does not run the package.
  The unit tests of the pure modules use `package:test`. A spec that creates a chart is a
  `testWidgets` case with `acquireChart` of `package:chartjs_test_utils/flutter.dart`. A spec that
  spies on `chart.ctx.fillRect` puts a `RecordingContext` of
  `package:chartjs_test_utils/pure.dart` over the context of the chart in `chart.ctx` and calls
  `chart.draw()` (Chart.js ADR 0133). A test of an option gives the enum value, a `ChartPaint`, or a
  `SankeyNodeGap`, never the upstream keyword or CSS text. A test that names the element next to a
  Flutter import gives the sankey library a prefix.
- Each chartjs-plugin-zoom test file has `@TestOn('vm')`: `test:web` does not run the package.
  The specs that create a chart follow the chart spec rules of the Chart.js port: `testWidgets`,
  `package:chartjs_test_utils/flutter.dart` (without its `triggerMouseEvent`) and the event
  helpers of `test/flutter_test_config.dart`. A test with a wheel zoom and an `onZoomComplete`
  option pumps at least 250 ms before its end: the debounce timer is never cancelled, and
  flutter_test fails on a pending timer. A drag test puts its corners on whole pixels: `getRelativePosition` rounds the
  offsets. A test of real input drives a `ChartView` through `WidgetTester` (`startGesture`,
  `TestPointer` with `sendEventToBinding`, `sendKeyEvent`), not through the synthetic dispatch of
  the specs.

## Licensing

- Chart.js is MIT. `packages/flutter_chartjs_port/LICENSE` lists both copyright holders and
  `REUSE.toml` annotates the paths. CI runs `reuse lint`.
- D3 is ISC. `packages/flutter_d3_port/LICENSE` is the ISC text with
  `Copyright 2010-2026 Mike Bostock` and `Copyright 2026 Vasiliy Ditsyak`. `LICENSES/ISC.txt` has
  the license text. The `packages/flutter_d3_port/**` table of `REUSE.toml` comes after the
  `chartjs_test_utils` table. D3 ADR 0001 items 8 and 10 give the other components and their
  holder strings. Examples are d3-ease (BSD-3-Clause), ColorBrewer in d3-scale-chromatic
  (Apache-2.0), delaunator (`Mapbox`) and robust-predicates (Unlicense). The change that ports
  the first file of a component adds that component by the three steps below.
- Apache ECharts is Apache-2.0. The code of the ECharts port is Apache-2.0 too.
  `packages/flutter_echarts_port/LICENSE` is the plain Apache-2.0 text, and
  `packages/flutter_echarts_port/NOTICE` keeps the notice of Apache ECharts unchanged.
  `LICENSES/Apache-2.0.txt` has the license text. The `packages/flutter_echarts_port/**` table of
  `REUSE.toml` comes after the D3 table. ECharts ADR 0001 item 12 gives the other components:
  zrender (BSD-3-Clause, `Baidu Inc.`), the d3 code in five ECharts files (BSD-3-Clause), and
  node-timsort, jsdiff and tween.js in zrender files. The change that ports the first file of a
  component adds that component by the three steps below.
- chartjs-chart-sankey is MIT. The code of the sankey port is MIT too.
  `packages/flutter_chartjs_chart_sankey_port/LICENSE` is the MIT text with
  `Copyright (c) 2019-2026 Jukka Kurkela` and `Copyright (c) 2026 Vasiliy Ditsyak`. The
  `packages/flutter_chartjs_chart_sankey_port/**` table of `REUSE.toml` comes after the zoom table.
  The last table annotates the gallery samples `apps/chartjs_gallery/lib/docs/sankey/**`. The
  package ports no Chart.js code (Sankey ADR 0001).
- chartjs-plugin-zoom is MIT. The code of the zoom port is MIT too.
  `packages/flutter_chartjs_plugin_zoom_port/LICENSE` is the MIT text with
  `Copyright (c) 2013-2024 chartjs-plugin-zoom contributors` and `Copyright (c) 2026 Vasiliy
  Ditsyak`. The `packages/flutter_chartjs_plugin_zoom_port/**` table of `REUSE.toml` comes after
  the ECharts table. The package ports no Chart.js code (Zoom ADR 0001).
- @kurkle/color is MIT. The code of the color port is MIT too.
  `packages/flutter_kurkle_color_port/LICENSE` is the MIT text with
  `Copyright (c) 2018-2021 Jukka Kurkela` and `Copyright (c) 2026 Vasiliy Ditsyak`. The
  `packages/flutter_kurkle_color_port/**` table of `REUSE.toml` comes after the sankey table. The
  package ports no Chart.js code, and `packages/flutter_chartjs_port/LICENSE` no longer lists
  Jukka Kurkela.
- Code taken from any other project needs three things in the same change:
  1. its notice in the `LICENSE` of the package that contains the code;
  2. a `REUSE.toml` annotation for the files, placed last because the last matching table wins
     and must list every holder;
  3. the file header from rule 2.

  For an MIT source, the notice is its copyright line, added to the existing MIT text. For example,
  `packages/flutter_kurkle_color_port/LICENSE` has `Copyright (c) 2018-2021 Jukka Kurkela`
  (`third_party/kurkle-color/LICENSE.md` at `v0.3.2`). For an Apache-2.0 source, include the full
  license text as a separate component of the package LICENSE, along with its `NOTICE` content,
  and add `LICENSES/Apache-2.0.txt`. For another license, add its notice as a separate component
  of the package LICENSE. Also add `LICENSES/<SPDX-ID>.txt`.
  The test font did this for SIL OFL 1.1: the OFL notice is a separate component of
  `packages/chartjs_test_utils/LICENSE`, `LICENSES/OFL-1.1.txt` has the license text, and the last
  table of `REUSE.toml` annotates `packages/chartjs_test_utils/lib/fonts/**`. The font files and
  their `LICENSE` stay unchanged.
- Never copy code from GPL or otherwise incompatible projects, even for "small" helpers.
  `flutter_web_chartjs` is GPL-3.0; current WebF is GPL-3.0 with an enterprise exception. Ideas
  only. See `packages/flutter_chartjs_port/doc/prior-art/`.

## Conventions

- ADR names: "Chart.js ADR NNNN" is a file of `packages/flutter_chartjs_port/doc/adr/`. "ADR NNNN"
  alone is a `docs/adr/` file. "D3 ADR NNNN" is a file of `packages/flutter_d3_port/doc/adr/`. "ECharts
  ADR NNNN" is a file of `packages/flutter_echarts_port/doc/adr/`. "Zoom ADR NNNN" is a file of
  `packages/flutter_chartjs_plugin_zoom_port/doc/adr/`. "Sankey ADR NNNN" is a file of
  `packages/flutter_chartjs_chart_sankey_port/doc/adr/`. An accepted ADR does not change. A changed
  decision gets a new ADR that states the complete decision and supersedes the old ADR.
- Package names: ADR 0007. The library package of a port has the name `flutter_<library>_port`,
  with the suffix `_port`: `flutter_chartjs_port`, `flutter_d3_port`, `flutter_echarts_port` and
  `flutter_chartjs_plugin_zoom_port`, `flutter_chartjs_chart_sankey_port` and
  `flutter_kurkle_color_port`. A later port uses
  the same form. An add-on port takes the
  npm name of the add-on (ADR 0009 item 5). A harness package is `<library>_test_utils`, or the npm name
  of the upstream harness in snake case (`chartjs_test_utils`). A gallery app is
  `apps/<library>_gallery`. A design-system adapter is `<library package>_<system>`, for example
  `flutter_chartjs_port_forui`. The directory and the commit scope of a package are its name.
  Before a change adds a name, examine `https://pub.dev/api/packages/<name>`: it must give 404.
- Lints: `very_good_analysis` (root `analysis_options.yaml`, which also carries its formatter
  settings, so run Dart tools after `flutter pub get`). The `analysis_options.yaml` of
  `flutter_chartjs_port` includes the same rules (Chart.js ADR 0047). Public APIs are documented.
- Constructors: each class, enum and mixin class uses a primary constructor when its constructors
  allow it, also a class with no declared constructor (ADR 0010). Both `analysis_options.yaml`
  files turn on `use_primary_constructors`, and `dart fix` makes the form. A secondary
  constructor is `new <name>(...)` or `factory <name>(...)`. The generators write the form.
- Commits: Conventional Commits, signed off (`git commit -s`, DCO), for example
  `feat(flutter_chartjs_port): port helpers.math`. The scope of the D3 port is `flutter_d3_port`.
  The scope of the ECharts port is `flutter_echarts_port`. The scope of the zoom port is
  `flutter_chartjs_plugin_zoom_port`. The scope of the sankey port is
  `flutter_chartjs_chart_sankey_port`. The scope of the color port is
  `flutter_kurkle_color_port`. Checks:
  - lefthook ≥ 1.0 `commit-msg` hook (`lefthook install`): `commitlint_cli` checks the type, and
    the scope when one is given, against the list in `commitlint.yaml`; a second command requires a
    `Signed-off-by` trailer;
  - CI `dco` job: checks the sign-off on every pull-request commit.
- CI jobs (`.github/workflows/ci.yaml`): `format`, `analyze`, `test` (ubuntu, macOS, Windows),
  `test-web`, `test-impeller`, `fixtures` (on `ubuntu-24.04`, also the runner of the theme goldens),
  `port-checks`, `upstream-manifest`, `gallery-web`,
  `gallery-android`, `gallery-ios`, `upstream-pin`, `reuse` and `dco`. A `workflow_dispatch` run has the inputs `update_goldens` and
  `flutter_version` (`test:goldens`).
- Releases: `.github/workflows/pages.yaml` publishes `apps/chartjs_docs` at
  <https://artflutter.github.io/flutter_ports/docs/>, on the newest stable Flutter. If the docs do not build,
  their page shows that result, and the other pages deploy. The workflow also publishes
  `apps/chart_benchmark_lab` once for each Flutter
  channel, at <https://artflutter.github.io/flutter_ports/lab-stable/>, `lab-beta/` and `lab-master/`.
  Each run takes the newest release of stable and of beta, and the head of the branch `master`. It does
  not read `.fvmrc`. The action caches no SDK for master, because its cache key for master is fixed. The
  lab resolves alone in these builds (the step deletes `resolution: workspace`), so that a dev dependency
  of the workspace cannot stop a page. The root `pubspec.lock` gives the first choice of versions. If a
  channel does not build, its page shows that result, and the other pages deploy. If no channel builds,
  the deploy stops. The old address `lab/` goes to the root page. The job `version` computes the lab
  version with git-cliff (`cliff.toml`) from the commits after the last `lab/v*` tag. Only the paths of
  its `include_paths` count. The builds take it through `--build-name`, and the run number through
  `--build-number`. The bottom of the page shows both values (the key `lab.version`). The job `deploy`
  pushes the tag of a new version. A deploy replaces the whole Pages site,
  so each page has its own folder in the job `deploy` of that workflow. `web/isolate.js` of the lab adds
  the COOP and COEP headers on `github.io` through a service worker, with one reload key for each page. `web/flutter_bootstrap.js` gives the
  loader no service worker settings: else the worker of Flutter removes that worker. The docs app has the
  same two files, with the same code: without them, skwasm runs on one thread and writes a warning to the
  console. The `web/flutter_bootstrap.js` of the lab, the docs and the gallery sets
  `preferWebParagraph: true` (Flutter issue 172561, from Flutter 3.50): the browser lays out and draws the
  text with the fonts of the system. The engine has that path only in CanvasKit, and only in a browser with
  the Enhanced TextMetrics API (`window.TextCluster`, in Chrome behind the flag "Experimental Web Platform
  features"). A `--wasm` build ignores the setting on skwasm, so the script gives a browser with the API
  `renderer: 'canvaskit'`, the JavaScript build. The three scripts also set
  `wasmAllowList: {gecko: true, webkit: true}`: by default, the loader takes the WebAssembly build only in a
  Chromium browser. The loader of Flutter 3.50 keeps the JavaScript build in Firefox before 147 and in Safari
  before 26.2. `web/isolate.js` also runs in Firefox and Safari. The scripts of the lab and the docs read
  the query parameter `build` of the address: `?build=js` gives the JavaScript build, and `?build=wasm` skips
  the rule of the native text. Each lab card of the root page (`tool/pages/index.html`) has one link for each
  build. The scripts
  `gallery`, `docs` and `benchmark:web` start Chrome with
  `--enable-blink-features=ExtendedTextMetrics`. `test:web` runs without that flag. The header of a
  web run shows its mode (`lib/benchmark/web_mode.dart`; `JAVASCRIPT · NATIVE TEXT` for that path). A note that does not scroll
  (`lib/ui/page_note.dart`) says why that mode applies, or why a scroll or another outside cause stopped a test.
  The note on the mode goes away for good when the first test of the page starts, and `tool/perf_matrix.dart` does
  not show it (`showModeNote: false`).
- Toolchain: Flutter 3.50.0-0.4.pre (beta channel, Dart 3.14.0-315.3.beta), pinned in `.fvmrc`; CI reads the same file, and `.github/actions/setup/action.yaml` names its channel. All
  packages and the gallery have the floor `sdk: ^3.13.0` and `flutter: ">=3.47.0"`
  (`packages/flutter_chartjs_port/doc/porting-flow.md` §2.12).
