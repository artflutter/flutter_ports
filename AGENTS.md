# Agent onboarding

Dart pub workspace + Melos 8 monorepo of native Dart/Flutter ports of JavaScript chart
libraries. First port: Chart.js v4.6.1 →
`packages/flutter_chartjs_port`. Second port: D3 v7.9.0 →
`packages/flutter_d3_port`, in phase 0 (scaffold and design). Each ported D3 module is a package
of its own, as on npm (D3 ADR 0008): d3-color 3.1.0 → `packages/flutter_d3_color_port` (version
0.3.0, on pub.dev), ported in native Dart forms (D3 ADRs 0007, 0009, 0010 and 0013),
d3-interpolate 3.0.1 → `packages/flutter_d3_interpolate_port` (D3 ADRs 0011 and 0013, version
0.3.0, on pub.dev), d3-scale-chromatic 3.1.0 → `packages/flutter_d3_scale_chromatic_port`
(D3 ADRs 0012 and 0013, version 0.3.0, on pub.dev), d3-path 3.1.0 →
`packages/flutter_d3_path_port` (D3 ADR 0014, version 0.1.1, on pub.dev), d3-shape 3.2.0 →
`packages/flutter_d3_shape_port` (D3 ADR 0015, version 0.1.0, on pub.dev), d3-format 3.1.2 →
`packages/flutter_d3_format_port` (D3 ADR 0016, version 0.1.0, on pub.dev), and d3-array 3.2.4 →
`packages/flutter_d3_array_port` (D3 ADR 0017, version 0.1.0, on pub.dev). Third port: Apache
ECharts 6.1.0 with its renderer zrender 6.1.0 → `packages/flutter_echarts_port`, in phase 0
(scaffold and design, no ported code). Fourth port: chartjs-plugin-zoom 2.2.0+fb81d331, an add-on
of the Chart.js port (ADR 0009) → `packages/flutter_chartjs_plugin_zoom_port`, phases 1-4 done
(each file of `src/` ported; the specs, the fixtures and the tests of real input pass), phase 5
next. Fifth port: chartjs-chart-sankey 0.19.1, an add-on of the Chart.js port and the first chart
type of another package → `packages/flutter_chartjs_chart_sankey_port`, phases 0-4 done (each
file of `src/` ported; the unit tests, the specs and the fixtures pass; a gallery page), phase 5
next. Sixth port: @kurkle/color 0.3.2, the color library of the Chart.js port →
`packages/flutter_kurkle_color_port`, a package of its own (version 0.2.0, on pub.dev), with no
import of another port.

## Commands

Run from the repository root. `melos` is a dev dependency: use `dart run melos …`.

Chart.js ADR 0061: the historical "pure layer" names below now mean framework-free
core layers. They may use `dart:ui.Color`, but no `package:flutter` framework APIs.
One exception: a core layer can import `package:flutter/animation.dart` for the curve
classes (`Curve`, `Curves`), the value of the option `easing` (row `adapt-flutter-curves`).
A second exception: a core layer can import `package:flutter/painting.dart`, with no `show` list,
for padding, fonts and corners (`EdgeInsets`, `TextStyle`, `TextOverflow`, `BorderRadius`; Chart.js
ADRs 0116 and 0187).
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
  ubuntu, CI also fetches the three Chart.js submodules, `third_party/d3`, `third_party/d3-color`,
  `third_party/d3-interpolate`, `third_party/d3-scale-chromatic`, `third_party/d3-path`, `third_party/d3-shape`, `third_party/d3-format`, `third_party/d3-array`, the two ECharts submodules, `third_party/chartjs-plugin-zoom` and
  `third_party/chartjs-chart-sankey` by path in each shard, for the `test/upstream_test.dart` of
  `flutter_chartjs_port`, `flutter_d3_port`, `flutter_d3_color_port`,
  `flutter_d3_interpolate_port`, `flutter_d3_scale_chromatic_port`, `flutter_d3_path_port`, `flutter_d3_shape_port`, `flutter_d3_format_port`, `flutter_d3_array_port`, `flutter_echarts_port`, `flutter_chartjs_plugin_zoom_port` and
  `flutter_chartjs_chart_sankey_port`.
- `dart run melos run test:web`: the `flutter_chartjs_port`, `chartjs_test_utils`,
  `flutter_kurkle_color_port`, `flutter_d3_port`, `flutter_d3_color_port`,
  `flutter_d3_interpolate_port`, `flutter_d3_scale_chromatic_port`, `flutter_d3_path_port`, `flutter_d3_shape_port`, `flutter_d3_format_port` and `flutter_d3_array_port` tests without
  `@TestOn('vm')`, in Chrome through Flutter (JavaScript/DDC and WebAssembly). `tool/test_web.dart`
  selects browser-capable files before compilation. A leg fails when it ends by a signal or exits
  with 0 without the summary of a run that passed: `flutter test` exits with 0 when a SIGTERM stops
  it. It needs a local Google Chrome. CI job: `test-web`.
- `dart run melos run check:port`: the port checks of
  `packages/flutter_chartjs_port/doc/porting-flow.md` §4 (tool 2) and tool 9,
  `options:gen:check`, `fixtures:gen:check` and `adr:index:check`, as melos steps. The CI job
  `port-checks` runs the five checks with a shallow checkout of the three Chart.js submodules,
  `third_party/chartjs-plugin-zoom` and `third_party/chartjs-chart-sankey`.
  `check:headers` also examines the add-on ports `flutter_chartjs_plugin_zoom_port` and
  `flutter_chartjs_chart_sankey_port` (ADR 0009 item 6). The other four checks examine only
  `flutter_chartjs_port`. The port has no JS-semantics check (Chart.js ADR 0178).
  Each check can also run alone:
  - `check:headers`: the line-1 header of each Dart file in `lib/`, `test/` and `tool/` of the home
    package and of each package that a `dart` target of its `tool/port_sources.yaml` names. The
    script runs it twelve times: `flutter_chartjs_port` with `chartjs_test_utils`, then
    `packages/flutter_chartjs_plugin_zoom_port` alone, then
    `packages/flutter_chartjs_chart_sankey_port` alone, then `packages/flutter_kurkle_color_port`
    alone, then `packages/flutter_d3_port` alone, then `packages/flutter_d3_color_port` alone, then
    `packages/flutter_d3_interpolate_port` alone, then `packages/flutter_d3_scale_chromatic_port`
    alone, then `packages/flutter_d3_path_port` alone, then `packages/flutter_d3_shape_port`
    alone, then `packages/flutter_d3_format_port` alone, then `packages/flutter_d3_array_port`
    alone. The primary project of the home is the
    entry whose `version_source` is `<constant> in <home>/lib/src/upstream.dart` (Chart.js,
    chartjs-plugin-zoom, chartjs-chart-sankey, @kurkle/color, d3, d3-color, d3-interpolate,
    d3-scale-chromatic, d3-path, d3-shape, d3-format, d3-array). Its `version` is `v<constant value>`, the port-only marker names it, and
    a backport line names the `<owner>/<repo>` of its `url`. The top-level key `marker` of the file
    gives the tag of the `DIVERGES(<tag>)` markers (default `chartjs`). The top-level key `project`
    gives the project name of the port-only marker when it is not the `header` of the primary
    project (`D3` for the primary project `d3`). A directory target maps
    `.tests.js`, `.spec.js` and `-test.js` to `_test.dart`. Only a `differences.md` table with the first
    header cell `ID` has rows; a `Reserved ID` table has none. It compares the project, license
    and holder with the `tool/port_sources.yaml` of the home, the `LICENSE` of the package that
    contains the file and `REUSE.toml`. It also fails on a source path that is not at the pin, or
    on a Dart path that is not the mapped path. A port-only file at the mapped path of a pinned
    source also fails. It compares each submodule gitlink with its `commit` in
    `port_sources.yaml`.
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
  - `fixtures:gen:check`: the check mode of `fixtures:gen` (below).
- `dart run melos run adr:index`: writes the list in the `README.md` of each ADR folder from the
  header lines of the ADRs (`tool/adr_index.dart`). `adr:index:check` fails on a stale list, and on a
  "Supersedes" line without the matching "Superseded by" or "Superseded in part by" line, or the
  reverse. `check:port` and the CI job `port-checks` run it. `docs/adr/README.md` has the ADR rules.
- `dart run melos run options:gen`: writes the typed option scopes of `flutter_chartjs_port`
  (`lib/src/options/option_keys.g.dart`, `scope_kinds.g.dart` and `scopes.g.dart`) and the
  resolved element options (`resolved.g.dart`) from the
  hand-written schema `tool/options_schema.yaml` through `tool/options_gen.dart`, formatted
  (Chart.js ADR 0054 §2). Edit the schema, never a `.g.dart` file. `options:gen:check` generates
  into `.dart_tool/options_gen_check/` and fails when a committed file differs or when
  `lib/src/options/` has a `.g.dart` file that the generator does not write. The analyzer
  excludes `**/*.g.dart`.
- `dart run melos run fixtures:gen`: writes `test/fixtures/data_fixtures.g.dart` of
  `flutter_chartjs_port` from `doc/upstream/fixtures.json` through `tool/fixture_configs_gen.dart`
  (writer `tool/src/fixture_configs.dart`), formatted (Chart.js ADR 0199): `dataFixtures`, the
  typed config of each pure data fixture without a hand port, and `momentTwins`, the ICU twin of
  each data fixture with a moment pattern. Never edit the file. A Chart.js bump runs it after
  `upstream:manifest`. `fixtures:gen:check` generates into `.dart_tool/fixture_configs_check/` and
  fails when the committed file differs.
- `dart run melos run test:cases`: tool 5. It runs `test/specs/` and reports each upstream case of
  `doc/upstream/manifest.json` as passed, failed, skipped or missing. It fails on an unknown test
  name, a bad skip reason and a missing case of a `ported` module. CI runs it in the ubuntu `test`
  leg of shard 0. It passes `--exclude-tags fixtures`. It also fails on a stale
  `blocked: <module>` skip literal in `test/` (each `src/` row of the module `ported`), on an
  unknown module and on a `blocked:` literal in another form than `blocked: <module>` (Chart.js ADR
  0041). The check reads the string literals of `test/` without `test/tool/` and without the
  generated `*_reference*.dart` files. `test:fixtures` runs the same check.
- `dart run melos run test:fixtures`: tool 7, the fixture smoke tests of `flutter_chartjs_port`
  (Chart.js ADR 0029). It is tool 5 with `--fixtures`: it runs the tests with the tag `fixtures` of
  the spec files with a fixture group and of `test/port/fixtures/`. It reports each upstream fixture
  as passed, failed, skipped or missing, and prints the 10 slowest tests. It fails on a failed,
  missing or unknown fixture, on a fixture group that no Dart file calls and on a bad skip reason.
  It also runs the stale-block check of `test:cases` (Chart.js ADR 0041). Each fixture builds its
  chart from a typed `ChartConfig` (Chart.js ADR 0199), except the configs that a `ChartConfig`
  cannot hold (`FixtureConfig.map`). The runner compares the
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
  merges the zoom option `rangeOnlyUpdates: true` into the `ZoomPluginOptions` of
  `Chart.defaults.plugins.zoom`, so each zoom and pan takes `chart.updateRanges` (Chart.js ADR
  0111). The results are those of the run without it; the spec `defaults` expects the field. The CI job `fixtures` runs it with
  `FIXTURES_REQUIRED=1`.
- `dart run melos run test:goldens`: the theme goldens of `flutter_chartjs_port`
  (`test/port/theme/goldens_test.dart`, the tag `golden`, theming.md §8 test 9, Chart.js ADR 0147).
  They skip unless `CHART_GOLDENS=1`. Their pinned runner is the CI job `fixtures` on
  `ubuntu-24.04`, because the font manager of the platform rasterizes the text. A local Mac never
  writes the golden files. Only a `workflow_dispatch` run of CI with the input `update_goldens`
  writes them (`-- --update-goldens`). That run uploads them as the artifact `theme-goldens`. The
  input `flutter_version` writes `.fvmrc` first, for a move to a new Flutter. The golden files are
  `test/port/theme/goldens/bar_light.png` and `bar_dark.png`. On each other run, the job `fixtures`
  compares them after `test:fixtures`. A failed compare uploads the `failures/` images.
- `dart run melos run docs` / `docs:build:web`: run the documentation site in Chrome / build it for the web
  with WebAssembly. Each web build (the melos scripts and the workflow `pages`) passes
  `--web-content-hash`: the bundle and asset files get a content hash in their names, so a new build
  misses the browser cache. No app has a deferred import: the flag does not support one.
- `dart run melos run dashboard`: run the live Supabase dashboard sample in Chrome. It needs
  `apps/chartjs_supabase_dashboard/supabase.json` (git ignores it).
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
  equals the `commit` in `packages/flutter_chartjs_chart_sankey_port/tool/port_sources.yaml`. It
  also fails unless `third_party/d3-color` is at the release tag `v<d3ColorVersion>` and equals
  the `commit` in `packages/flutter_d3_color_port/tool/port_sources.yaml`. It also fails unless
  `third_party/d3-interpolate` is at the release tag `v<d3InterpolateVersion>` and equals the
  `commit` in `packages/flutter_d3_interpolate_port/tool/port_sources.yaml`. The
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

- `packages/flutter_chartjs_port`: the Chart.js port (library, version 0.1.0-beta.4, on pub.dev as a beta). Its layout, its internal
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
    `setUpDefaultsRestore()`. It exports each file of `lib/src/` of the pure part (ADR 0011).
  - `lib/src/raw_options.dart` (Chart.js ADR 0201): `raw(object, map)` attaches the raw options of
    a test to an object of a typed config, and `lowerForTest(config)` lowers the config and merges
    each Map into the scope of its object, last; `rawOptionsOf` reads them. `lib/src/scope_from_map.dart`
    has `scopeFromMap`, the Map merge of the tests (`pure.dart`). The fixture runner lowers with
    `lowerForTest`.
  - `lib/flutter.dart`: the part that needs the Flutter engine, for `flutter test` only. It
    exports each other file of `lib/src/`, with `hide acquireChart, releaseChart` on `utils.dart`
    (ADR 0011). It has `installTestFont()`. It also has the DOM stand-in of `lib/src/dom.dart` and the chart helpers
    `acquireChart`, `releaseChart`, `releaseCharts`, `afterEvent`, `waitForResize` and
    `triggerMouseEvent` (Chart.js ADR 0022). `acquireChart` takes the config Map of a spec;
    `acquireChartRoot` takes the typed root scope of a typed config (`ChartConfigLowering`,
    Chart.js ADR 0054 §7). Both take an `AcquireOptions` (Chart.js ADR 0200, row
    `harness-acquire-options`): `canvas` a `HarnessCanvas` (render size, display size, `hidden`),
    `wrapper` a `HarnessBox`, and `useOffscreenCanvas`, `useShadowDOM` and `persistent`; no Map
    form: the fixture configs and the reference generators give an `AcquireOptions`. The harness
    has no CSS: each `HarnessElement` is laid
    out from the typed fields of its `HarnessBox` (`width`, `height`, `maxWidth`, `maxHeight`,
    `padding`, `hidden`, `absolute`, `offset`, `direction`), and a spec writes them as Dart values
    (`wrapper.width = 455`, `canvas.hidden = false`). The DOM stand-in exports are `document`,
    `window`, `HarnessDocument`, `HarnessElement`, `HarnessBox`, `HarnessWindow`, `setTimeout`,
    `afterEachChart`, `pumpFrames`, `pumpFrame`, `waitForDone`, `frameInterval`, `specTimeout`,
    and the extensions `CanvasParentElement` and `HarnessCanvasDisplay`. Only one `pumpFrames` loop pumps at a time: a loop
    that starts while another loop pumps awaits each step of that loop. It also exports the fixture
    runner of `lib/src/fixture.dart`.
  - `lib/src/fixture.dart` ports `src/fixture.js` (Chart.js ADR 0029): `specsFromFixtures`,
    `specFromFixture`, `FixtureConfig` and `fixtureInput` (Chart.js ADR 0199: a loader gives
    `FixtureConfig.typed(ChartConfig, options:, run:, description:)`, which the runner lowers with
    `ChartConfigLowering` and the plugin rule of `fixture.js:45-48`, or `FixtureConfig.map(Map,
    ...)` for a config that a `ChartConfig` cannot hold, which takes `nativeFixtureColors`;
    `options` is the typed `AcquireOptions` of Chart.js ADR 0200 and `run` a `FixtureRun`; `data` of
    `specsFromFixtures` takes the generated configs) and `FixtureSource` (the manifest and
    `fixtures.json` of tool 4, which the runner does not read, the folder
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
    `harness-trigger-mouse-event`). The DOM stand-in places an `absolute` box at its `offset`
    from the padding box of its parent. `lib/src/index.dart` ports `src/index.js`: `acquireChart`, `releaseChart`,
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
    keys of Chart.js ADR 0051. The chart is a `ChartView` with the typed `ChartConfig` that the page
    makes once for each variant (Chart.js ADR 0170), and `onChartCreated` gives the chart to the page. The chart has the
    semantics label `<title> chart: <variant>`. The app follows the platform brightness: its builder puts a `ChartTheme` above each route, with the
    light preset or the dark preset over the surface of the dark color scheme (Chart.js ADR 0147).
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
    `gallery.chart.sankey`). It opens `lib/plugins/sankey_page.dart`, a typed `ChartView` with a
    `SankeyDataset` (Sankey ADR 0004). Its variants are the ports of four samples of the docs of chartjs-chart-sankey
    (`src/content/docs/samples/basic.md`, `vertical.md`, `flow-colors.md` and `node-labels.md`) in
    `lib/docs/sankey/samples/`, with rule-2 headers; `lib/docs/sankey/scripts/utils.dart` ports
    `docs/scripts/utils.js`. Only that page calls `registerSankeyComponents` of
    `lib/demo/gallery_components.dart`, which registers `sankeyRegisterables` once.
    `test/sankey_page_test.dart` pins the page.
  - After the nine entries, the home list has the tile "Zoom and pan" (key `gallery.plugin.zoom`).
    It opens the zoom page `lib/plugins/zoom_page.dart`. Its variants are the ports of four samples
    of the docs of chartjs-plugin-zoom (`docs/samples/basic.md`, `drag/linear.md`,
    `wheel/category.md` and `pan/toggle.md`) in `lib/docs/zoom/samples/`, with rule-2 headers. The
    chart is a typed `ChartView`: each sample gives a `ChartConfig` with its `ZoomPluginOptions`
    in `pluginOptions`. The actions of a sample, for example "Reset zoom", call the zoom API on
    the chart of `onChartCreated`; a toggle writes new zoom options into the options of the chart
    (`setZoomSampleOptions`) and calls `chart.update()`, so the config stays and the zoom range
    stays. `test/zoom_page_test.dart` pins the page (seam H20).
  - The page "Phase 3: canvas and host" has the tabs Canvas, Events, Text, Stress, Elements, Core
    and Axes. The Core tab (`lib/demo/core_demo.dart`) runs a `LineController` chart with the
    typed config of Chart.js ADR 0052 §13, on two hidden linear axes (the typed form of
    `unitScales()`). `build` makes the `ChartConfig` from the control values: a control changes a
    value in `setState`, and the data commands give new data Lists. The duration of the hover transition is a
    `HoverTransition` of `ChartConfig.transitions`. Thus `gallery:build:web` compiles the typed path with dart2wasm. Its controls are
    above the chart: `mode`, `axis`, one line of toggles and commands, `hover` and `update`. The
    Axes tab (`lib/demo/axes_demo.dart`) runs a `LineController` chart on the scales of phase 6,
    with a typed config that `build` makes from the control values, as the Core tab does; the data
    commands change the data Lists in place and call `chart.update()`.
    `x`, `y` and `N` are above the chart, and the other parameters are after the readout
    (Chart.js ADR 0031 §10.7, Open). The plugins of
    `registerables` run with their defaults in both tabs: the legend and the tooltip show. A legend
    click in the Core tab also updates the dataset segments: the inline plugin of the tab gets each
    event in its `afterEvent` hook. Each tab shows its chart in a `ChartView` in a `SizedBox` of
    the height, with `maintainAspectRatio: false`. The keys `core.host` and `axes.host` are on the
    box.
  - The gallery imports the app library `package:flutter_chartjs_port/flutter_chartjs_port.dart`,
    and `helpers.dart` with a `show` list. A file that also needs a name that the app library hides
    (`Animation`, `Element`, `FilterCallback`, `Title`, `Tooltip`) or a name that the gallery
    declares too (`PointOptions`) imports `package:flutter_chartjs_port/chartjs.dart` `as chartjs`,
    with a reason line above the import. No file imports `package:flutter_chartjs_port/src/`
    (ADR 0012).
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
    host: `canvas` (`ChartCanvas`, the default) or `view` (`ChartView` with the typed twin of the
    config: `stressChartTypedConfig`, `stressAxesTypedConfig` and `ChartBenchScene.viewConfig`).
    `BATCHES` (15) splits the
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
  - `lib/main_input_probe.dart` is the input probe of Chart.js ADR 0112: one typed `ChartView` line
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
  port, fl_chart, Graphic, Syncfusion and apexcharts_flutter).
  `ChartLibrary.supports` excludes the Syncfusion radar and the apexcharts_flutter
  polar area: these packages have no such chart, so the lab shows a message and a
  batch skips it. Do not draw a stand-in.
  Only the Chart.js port has the sankey chart, through
  `flutter_chartjs_chart_sankey_port`: `sankeyFlows` of `lib/benchmark/data.dart` gives
  one flow for each item between nodes in three columns, and `_chartJsSankey` of the
  adapter registers `sankeyRegisterables` once and draws a typed `ChartView` with a
  `SankeyDataset` (Chart.js ADR 0189); `updateData` declines it, so each tick is a full update. The
  sankey chart has no visible axes and no shadow (`ChartType.hasShadow`,
  `BenchmarkConfig.shadows`); its zoom and pan act on its hidden x scale, the node columns.
  `ChartLibrary.runs` applies the same rule to the series shadow: fl_chart draws it
  only on a line chart, Graphic only as a blurred Material elevation of a filled
  mark, and Syncfusion and apexcharts_flutter not at all. The settings hide a
  feature that the chart type does not have. A run disables the features that the
  settings show. apexcharts_flutter is the exception: `runs` is true for each setup
  of a type that it has, so it takes part in each batch. `ChartLibrary.fixedFeatures`
  lists the features that are off and that it still draws (the axis labels and the
  grid of a cartesian chart, and the rings, the markers and the fill of a radar).
  `ChartLibrary.missingFeatures` lists the features that are on and that it leaves
  out (the alternating colors of a bar, scatter or bubble chart, the shadow and the
  pinch zoom). Each capture records them as `alwaysDraws` and `leavesOut` in its
  `engineOptions`.
  `ChartLibrary.zoomsWith` gives the zoom and pan of the x axis (line, bar, scatter
  and bubble): the Chart.js port through the zoom port, which the adapter registers
  only for a chart with zoom, fl_chart
  `transformationConfig`, Graphic `RectCoord.horizontalRangeUpdater` and Syncfusion
  `ZoomPanBehavior`, each inside the data and at most `chartMaxZoom` times.
  apexcharts_flutter has no pinch zoom, so `zoomsWith` is false for it: with zoom
  on, it runs with its own wheel zoom and drag selection. The
  adapter claims each wheel over a chart with zoom, so the page does not scroll
  and a test goes on. A desktop trackpad differs by library (the host of the
  Chart.js port maps it to `wheel` events while the toggle "Trackpad gestures",
  `BenchmarkConfig.trackpad`, is on): `zoomsWith` states it.
  The setting "Background CPU load" (`BenchmarkConfig.cpuLoad`, on by default) keeps one
  isolate (a Web Worker on the web) busy from the start of a test to the end of its timing drain
  (`lib/benchmark/cpu_load.dart`), so a light chart runs on performance cores at high clocks. A
  run with it has the key `cpuLoad`. `flutter test` gets no load.
  Run `dart run melos run benchmark:macos` for profile measurements. Dependencies
  are pinned; Syncfusion is included under the owner's confirmed eligible license.
  Shared seeded data and controls live in `lib/benchmark`, adapters in
  `lib/charts`, dashboard in `lib/ui`. One engine is mounted at a time.
  `chart_adapter.dart` imports the adapters of fl_chart, Graphic,
  Syncfusion and apexcharts_flutter (`*_adapter.dart`) as plain libraries.
  The apexcharts_flutter adapter builds the typed `ApexOptions` with its
  constructor, and its bars take a numeric x axis (a category axis draws one
  label for each bar). `web/index.html` preloads Roboto, the fallback font
  that the engine reads before the first frame.
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
  `lib/pages/line_chart_page.dart` has the text and the table of options. `lib/examples/line/` has the code
  of the charts, one file for each code panel. `lib/examples/line_data.dart` has the data that the page
  uses in the configs that it builds. `lib/examples/line_examples.dart` exports them. The app also loads each file of
  `lib/examples/line/` as an asset, and a code panel shows the lines between `// #docregion <name>` and
  `// #enddocregion <name>`. Thus a panel shows the code that draws its chart. Each source file of a code
  panel has one region. A `CodeRegion` names the source file and the region of a panel. Each code panel
  is closed at the start: its **Code** button (`CodeToggle` of `lib/ui/doc_blocks.dart`) opens it.
  `CodeSources` reads the file of a panel at its first open, not at the start of the app.
  `test/code_panels_test.dart` pins this. Each form of a `LiveExample` and the live chart have a
  **Try in DartPad** button (`lib/ui/dartpad.dart`). A code panel with no chart (`DocCode`) has none.
  The sample file of a button is the whole sample: it has the data that it uses, a `main()` after the
  region builds the config of the page and runs it, and it imports no other file of the app. A form of a
  loop (point styles, skipped borders, percentages) opens the sample with the arguments of the first
  form. The export of each sample in `line_examples.dart` or `bar_examples.dart` shows only the names
  that the file declared before its data, so the data and `main` do not collide. Each replica of a
  migration page has the button next to **Original** (`ReplicaBlock`). Its file has a `main()` after the
  region that shows the replica in the frame of its page: the background, the dark chart theme of
  fl_chart, and the card of at most 600 pixels of the fl_chart bar page. A replica keeps its imports of
  the shared kits and data files. The workflow `pages` writes one archive for each file of `lib/examples`
  and `lib/migrate` with a `main()` (`tool/dartpad_archives.dart`): `lib/<path>.dart` becomes
  `dartpad/<path>.tar.gz` of the docs site. The archive has the sample as one file `lib/main.dart` (line 1
  of the header, no region markers), then the declarations of the docs files that it imports and uses,
  with the imports that they need, and a `pubspec.yaml` with each package that it imports, from pub.dev
  at the version of its pubspec in the repository or later (`flutter_chartjs_port`,
  `flutter_chartjs_plugin_zoom_port` and `material_ui`). The tool stops on a top-level extension and on
  two declarations with one name. DartPad has no asset files: a `rootBundle.loadString` of the archive
  reads the asset from the docs site with `package:http`, because `dart:io` does not run on the
  web. It finds the content-hashed file name of the asset key in the `precache_manifest.json` of
  the site. The link opens the archive with the file
  tree collapsed. A sample that needs an API of a later release fails in DartPad until that release is
  on pub.dev. The page tests tap each form and compare the files of the buttons with the samples that
  have a `main()`. `test/migrate_pages_test.dart` finds the button of each replica, and
  `test/dartpad_archives_test.dart` bundles each sample. `test/line_chart_page_test.dart` compares the table with the chart defaults and the parameters of
  `LineDataset`. The workflow `pages` deploys the site.
  - The UI of the site is widget classes, with no function that returns a widget (the Flutter guidance
    "prefer a widget over a helper method"). A docs block takes each text as a widget: a `DocText` for a
    text with the inline forms `` `code` ``, `**bold**` and `[text](#id)`, and a `Text` for a label. The
    block gives the text its style through `DefaultTextStyle`, for example
    `DocParagraph(DocText('Set **stepped** to true.'))` or `DocSection(title: Text('Gaps'), ...)`. A
    `String` field stays only where the code uses the text as a value: the end of a key and the screen
    reader text (`ExampleVariant.name`, `LiveExample.description`), the browser tab title
    (`DocPageContent.tabTitle`), the group of a page and the table data that the tests compare
    (`DocProperty`).
  - The bar chart page has the section structure of `docs/charts/bar.md`: `lib/pages/bar_chart_page.dart`
    has the text and the table. `lib/examples/bar/` has the code of the charts, one file for each code
    panel, and `lib/examples/bar_examples.dart` exports them. Each region name of these files starts with `bar-`, because a region name is unique over all the
    source files.
    `test/bar_chart_page_test.dart` compares the table with the chart defaults and the parameters of
    `BarDataset`.
  - `docPages` of `lib/main.dart` lists the pages with their routes and their groups in the sidebar. Each
    chart type is one group: its docs page (`/charts/<type>`), then its migration pages
    (`/charts/<type>/migrate/<library>`). The browser address `#/<route>` opens a page. `movedRoutes` sends
    the old addresses `/migrate/<library>` to the line chart pages. `test/migrate_pages_test.dart` runs on
    the pages with `/migrate/` in their route.
  - The last group, "Awesome plugins", has one page for each plugin of the port, with no overview page.
    The zoom page (`lib/pages/zoom_plugin_page.dart`, `/plugins/zoom`) ports the pages Getting Started,
    Integration and Usage of the guide of chartjs-plugin-zoom, and links to its options. Its code panels are in
    `lib/examples/zoom/`, and its live chart has the action **Reset zoom** (`ExampleAction` of
    `LiveExample`). The docs app registers no plugin: the page gives the zoom plugin to its chart in
    `ChartConfig.plugins`. `lib/ui/doc_links.dart` has the link buttons and the command panel, and
    `test/plugins_pages_test.dart` pins the zoom page.
  - The line chart migration pages rebuild the line chart demos of fl_chart 1.3.0 (13), Graphic 2.7.0 and
    Syncfusion 35.1.43 with the port. `migrationPage` of `lib/ui/replica_block.dart` gives the intro, a
    table of the names that map and one section for each demo: notes, the live replica and its code on
    a tap. Each replica is one file of `lib/migrate/<library>/` with one region. `pubspec.yaml` lists each
    folder of `snippetFolders` as assets.
  - The bar chart migration pages (`lib/pages/migrate_bar_<library>_page.dart`) rebuild the 8 bar samples
    of fl_chart 1.3.0, the 8 rectangular bar demos of the Graphic 2.7.0 example app and the 14 column and
    bar demos of the Syncfusion gallery. Their replicas are in the same folders: `bar_s01.dart` to
    `bar_s08.dart` and `fl_bar_kit.dart`, `bar_<demo>.dart`, `graphic_bar_kit.dart` and
    `graphic_bar_data.dart`, and `<demo>_column.dart`, `<demo>_bar.dart` and `sf_bar_kit.dart`. Three
    Graphic replicas zoom and pan the x axis through `flutter_chartjs_plugin_zoom_port`, a path dependency
    of the app.
  - The apexcharts_flutter pages (`lib/pages/migrate_apexcharts_page.dart` and
    `migrate_bar_apexcharts_page.dart`, routes `/charts/<type>/migrate/apexcharts`) rebuild the 5 line and
    area demos and the 3 bar demos of the example app of apexcharts_flutter 0.1.2. The sidebar names them
    "From apexcharts_flutter": a long sidebar label wraps (`Flexible` in `doc_page.dart`). The replicas are in
    `lib/migrate/apexcharts/`. `apex_kit.dart` has the shared parts: the axes, the legend, the tooltip
    with its title bar, the hover line and markers, the data labels and `ApexZoomChart`. `ApexZoomChart`
    gives each line and area chart the zoom of `flutter_chartjs_plugin_zoom_port` and the zoom toolbar of
    apexcharts_flutter. The stacked and the horizontal bar replicas show the chart of their options, not
    the axis defects of apexcharts_flutter 0.1.2. Their notes state the difference.
  - The ApexCharts.js pages (`lib/pages/migrate_apexcharts_js_page.dart` and
    `migrate_bar_apexcharts_js_page.dart`, routes `/charts/<type>/migrate/apexcharts_js`, "From
    ApexCharts.js") rebuild 6 line and area demos and 9 column and bar demos of `samples/vanilla-js` of
    ApexCharts.js 4.7.0, the last release under the MIT license (5.x has a license that forbids use in
    competing chart products: never take a demo from it). The **Original** link of a demo is
    `https://apexcharts.com/javascript-chart-demos/<folder>/<sample file name>/`. The replicas are in
    `lib/migrate/apexcharts_js/`, one file and one region `apexjs-<file stem with ->` for each demo.
    `apexjs_kit.dart` imports `apex_kit.dart` and adds the ApexCharts.js defaults: the palette, the
    title, the legend, the axes with the axis line and tick marks, the line and bar series helpers, the
    bar tooltip, the grid bands, the line and bar data labels with the stack totals and the column
    crosshair. A replica whose original shows the zoom tools uses `ApexZoomChart`.
  - The shadcn/ui pages (`lib/pages/migrate_shadcn_page.dart` and `migrate_bar_shadcn_page.dart`, routes
    `/charts/<type>/migrate/shadcn`) rebuild the 10 line and the 10 bar chart blocks of shadcn/ui at commit
    `e62c9435` (Recharts 3.8.0). The replica of the block `chart-<name>` is
    `lib/migrate/shadcn/<name with _>.dart`, and its **Original** link is
    `https://ui.shadcn.com/view/new-york-v4/chart-<name>`. `shadcn_kit.dart` has the shared parts. These are
    the colors of the shadcn/ui site, the card, the axes and the value range of Recharts (`rechartsRange`).
    It also has the curves `NaturalCurve` and `MonotoneXCurve` (subclasses of `CubicInterpolationMode`),
    the `LabelList` plugin and the cursor plugin. `ShadcnChart` puts the tooltip of `ChartTooltipContent` as a
    Flutter widget over a `ChartView`: the chart tooltip has `enabled: false`, and its `external` callback
    gives each change to the widget. A private name of the kit must not be a name of a replica: the DartPad
    archive puts both into one file. `test/shadcn_replicas_test.dart` pins the tooltip widget, the series
    buttons of the interactive line and `rechartsRange`.
  - The replicas are new code. The Syncfusion replicas use no Syncfusion code, the apexcharts_flutter
    replicas use no apexcharts_flutter code, the ApexCharts.js replicas use no ApexCharts.js code, and
    the shadcn/ui replicas use no shadcn/ui or Recharts code.
    The data of the fl_chart
    samples 12 and 13 (`assets/flchart/`), `lib/migrate/graphic/graphic_data.dart`,
    `graphic_bar_data.dart`, `lib/migrate/apexcharts/area_datetime_data.dart` and
    `lib/migrate/shadcn/shadcn_data.dart` and the data of the replicas of `lib/migrate/apexcharts_js/`
    are MIT copies: the
    `LICENSE` of the app and `REUSE.toml` name their holders.
    `test/migrate_pages_test.dart` builds each page, also at phone width, and finds each region.
- `apps/chartjs_ergonomics`: atomic samples of the typed API for a review of its ergonomics (web and
  macOS). One scroll page: each card shows one feature, its chart and the code region `sample` of
  its file in `lib/samples/line/` (an asset). `lib/samples/line/index.dart` lists the samples; an
  accepted sample (`accepted: true`) is a closed panel. `test/samples_test.dart` makes sure that each
  file has its region and its entry, and that each sample draws with no error.
- `apps/chartjs_supabase_dashboard`: a proof of concept of a live dashboard (web and macOS): one
  typed `ChartView` line chart on a time axis, on the Supabase table `metric_points`, with the
  pre-release `supabase_flutter` 3.0.0-dev.17 (an exact pin) and its typed queries: the Supabase
  CLI generates `lib/supabase_schema.g.dart` with the dev dependency `supabase_typegen` (the app
  README, "The typed schema"); never edit it by hand. `lib/src/supabase_metric_source.dart` reads
  the pages and the realtime inserts as partial rows of `id`, `ts` and `value`. Each browser
  signs in as an anonymous Supabase user (`main.dart`; "Allow anonymous sign-ins" is on in the
  Auth settings), and the status bar shows the session.
  `supabase/schema.sql` makes the table with the column `owner` (null for the shared history), the
  read policy `owner is null or owner = auth.uid()` for `authenticated` (Realtime applies it too;
  no client writes the table), the value generator `metric_value` (value noise of several time
  scales, from `hashint8`), the RPC `pump_metric` (the row of `auth.uid()` for the current
  slot of 5 seconds, with the start of the slot as its `ts`; the unique index on `owner` and `ts`
  gives a session one row in a slot, and all sessions get at most 200 rows in a slot), the realtime
  publication, 6 hours of shared history (one row each 5 seconds) and a `pg_cron` job that deletes
  the rows of a session after one day. A table with a `ts` off the slots of 5 seconds (an earlier
  version of the script) loses all its rows when the script runs. The run reads the URL and
  the publishable key from `supabase.json` (`--dart-define-from-file`, git ignores it;
  `supabase.example.json` has the form). `LiveSeries` (`lib/src/live_series.dart`) loads its
  pages by `ts`: a page is the rows of one cell of a grid of `pageSpan` (5000 seconds, 1000 slots,
  the largest response of the API), the cell of the newest row before the oldest page, so a cell
  with no row gives no page. It merges the realtime inserts by id, loads the page before the oldest
  page on demand, and calls `pump_metric` in the middle of each slot of 5 seconds of the device
  clock (`clock.now()`). `LiveChart` moves the view
  in a frame ticker: it writes `min` and `max` of the x and y scales through `scale.setRange` and
  calls `chart.updateRanges` (Chart.js ADR 0111). The right edge is `now` minus the longest recent
  realtime delay, and the y range eases to the values in view. The x axis has `time.minUnit`
  `TimeUnit.second`, and its `afterBuildTicks` hook gives it only the ticks of a fixed grid of
  time, about one for each 100 pixels: the axis makes no tick that its callback removes. A wheel
  or a trackpad scroll pans the x range, and Ctrl and the wheel or a trackpad pinch zooms it
  around the pointer (a canvas `wheel` listener): the next frame of the ticker applies both, so
  such a frame has one chart update. A drag pans the range and a touch pinch zooms it (the zoom
  port with `rangeOnlyUpdates: true`, with no wheel zoom), and a left edge near the oldest row
  loads the next page. The config
  is built once, and each build gives only a new dataset with a new data List: the options stay
  `==`, so the chart keeps the ranges. The line has `MonotoneCubicInterpolationMode`. The solid
  line joins rows at most 1 hour apart (`LiveSeries.gapThreshold`). The inline plugin
  `liveChartGaps` joins two rows that are more than 1 hour and at most 2 hours apart
  (`dashThreshold`) with a dashed line. Rows more than 2 hours apart have no line between them.
  The plugin makes each dash as a line of its own, for the part in view only: a line dash of the
  canvas cuts the whole line, also the part out of view. The inline plugin `liveChartPages` draws
  an amber vertical line with the label `page <n>` at the start of each page on the grid
  (`LiveSeries.pageStarts`, the newest page first), before the datasets: the lines are at uniform
  distances. The points have the time in milliseconds as x, in time
  order, with `parsing: false` and `normalized: true`: an update parses no row. The live view gets
  only the rows of the last two widths of the view, and a zoom keeps that List while it holds the
  view and the view is not below a quarter of its width, so a zoom step is no full update. The
  history view holds its List until a page load. The toolbar above the chart (fixed height) has the note, the button Live and the zoom
  buttons (zoom out, 30s, 2m, 10m and 1h on a chart of 560 px or more, zoom in). Live and the
  zoom buttons start a timed move on `Curves.easeInOutCubic` toward a fixed range or the moving
  live range; the chart gets all rows during a move, and a drag, a wheel or a pinch stops it.
  The chart area keeps one size: an `afterFit` hook sets the label padding of the x
  axis to 0 (the chart padding on the right holds the last label), and another one gives the y
  axis a fixed width (`test/live_chart_test.dart`). A `FrameTiming` readout in the status bar shows
  the frame rate. The tests use `test/support/memory_metric_source.dart`, with no
  network.
- `packages/flutter_d3_port`: the D3 port (library, `publish_to: none` until 0.1.0, ISC), the
  bundle of the D3 modules, as the npm package `d3`. Phase 0 is in progress. Each ported module is
  a package of its own (D3 ADR 0008): the bundle depends on it, and `lib/src/d3/index.dart` (the
  port of `d3/src/index.js`) exports its pure library. `doc/README.md` has the plan and the
  roadmap.
  - `lib/d3.dart` (port-only): the pure library, with no Flutter import. It exports
    `lib/src/d3/index.dart` and `lib/src/upstream.dart` (`d3Version`, `7.9.0`). The index exports
    the pure library of each module package with all of its names (ADR 0011).
    `lib/flutter_d3_port.dart` (port-only) exports it and the main library of each module
    package. `test/port/d3/index_test.dart` reads the names of d3-color and d3-interpolate through
    the bundle.
  - `test/upstream_test.dart` (`@TestOn('vm')`) compares `d3Version` with
    `third_party/d3/package.json`. It also compares each D3 gitlink with its `commit`. It fails
    on a submodule of `.gitmodules` that no entry of a `packages/*/tool/port_sources.yaml` file
    pins.
  - `tool/port_sources.yaml`: 32 pins in the schema of the Chart.js file (D3 ADR 0001), with the
    top-level keys `marker: d3` and `project: D3`. Each entry gives the tag, the commit, the
    license and the holder of one repository. The pin of a ported module moves to the
    `tool/port_sources.yaml` of its package (d3-color, d3-interpolate).
  - Paths (D3 ADR 0008): in the module package `flutter_<repo>_port`, `third_party/<repo>/src/<path>.js`
    becomes `lib/src/<path>.dart`.
    `<repo>` keeps its hyphens. A spec `<repo>/test/<path>-test.js` becomes
    `test/specs/<repo>/<path>_test.dart`. Port-only tests go in `test/port/<repo>/`.
  - `doc/`: all D3 port docs: `README.md` (overview, roadmap, decisions), `porting-flow.md`
    (proposed), `parity.md`, `differences.md`, `upstream-ledger.md` (one section for each
    repository) and the prior-art survey `prior-art/`.
    - `doc/adr/`: the D3 ADRs, all proposed. `doc/adr/README.md` lists them with their status and their supersessions (`adr:index`).
  - `check:headers`, `test:web` and `test --no-select` examine the package. `test:cases` does
    not examine it yet.
- `packages/flutter_d3_color_port`: the d3-color 3.1.0 port (library, version 0.1.2, on pub.dev,
  ISC), the first module package of the D3 port (D3 ADR 0008), as `d3-color` on npm. Its
  `.pubignore` keeps `doc/`, `tool/` and `build/` out of the archive, its `analysis_options.yaml`
  includes the rules of the root file, and `example/main.dart` is the example of the archive. Its
  `README.md` is the README of upstream d3-color with the Dart forms, with no links, and with the
  speed tables of `doc/performance.md`. It depends only on Flutter (`dart:ui`, for its Flutter layer) and
  imports no other port. `flutter_d3_port` depends on it with `^0.1.0`.
  - The port uses no JS runtime (D3 ADR 0007), and its values and factories are native (D3 ADR
    0010): typed `double` channels, NaN for an undefined
    channel as upstream, and Dart constructors for the upstream arity overloads (`Rgb(r, g, b)`,
    `Rgb.from(color)`, `Rgb.parse('steelblue')`; the same for `Hsl`, `Lab`, `Hcl` and
    `Cubehelix`; `color`, `gray` and `lch` stay functions). A string or null channel does not
    compile: the coercion cases skip as `diverges: adapt-color-factories`. The channels are
    mutable fields, as upstream.
  - `lib/d3_color.dart` (port-only): the pure library, with no Flutter import. It exports each
    file of `lib/src/` outside `ui/` (ADR 0011), also `index.dart` and `upstream.dart`
    (`d3ColorVersion`). `lib/flutter_d3_color_port.dart` (port-only) exports it and the Flutter
    layer `lib/src/ui/ui_color.dart` (`toUiColor()` on a d3-color `Color`, `toD3Rgb()` on a
    Flutter `Color`). Each file of the package imports one of the two libraries.
  - `lib/src/`: `color.dart`, `lab.dart`, `cubehelix.dart`, `math.dart` and `index.dart` at the
    mapped paths of `src/`. `src/define.js` has no Dart file: Dart classes take the place of the
    prototype helper. `color()` returns null for a text with U+0085 or U+0130, where Dart `trim()`
    or `toLowerCase()` differs from JavaScript (row `platform-color-trim-lowercase`). `atan2`,
    `sin` and `cos` are `dart:math` (row `platform-color-trig-last-bit`).
  - `test/`: the 8 specs of `test/*-test.js` and `asserts.dart` (`package:test`, no `@TestOn`).
    `test/port/reference_test.dart` compares the port with upstream d3-color in Node.js v24.22.1
    arm64 (`tool/reference/d3_color_reference.mjs` writes `test/port/d3_color_reference.dart`).
    `test/port/ui_color_test.dart` tests the Flutter layer. `test/upstream_test.dart`
    (`@TestOn('vm')`) compares `d3ColorVersion`, the entry and the gitlink.
  - `tool/port_sources.yaml`: the pin of `third_party/d3-color`, with the top-level key
    `marker: d3-color` (the tag of `DIVERGES(d3-color)`) and a `files` list, so `check:headers`
    needs no checkout. `doc/differences.md` has its rows, and `doc/performance.md` its figures.
  - `tool/bench/`: the benchmark (`d3_color_bench.dart`, `d3_color_bench.mjs` with the same cases
    on the upstream source, and `run_bench.sh` for Node.js, AOT, JIT, dart2js and dart2wasm, both
    web targets run in Node.js).
  - `check:headers`, `test:web` and `test --no-select` examine the package.
- `packages/flutter_d3_interpolate_port`: the d3-interpolate 3.0.1 port (library, version 0.1.0,
  on pub.dev, ISC), the second module package of the D3 port (D3 ADR 0008), as `d3-interpolate` on
  npm. Its pubspec has no `publish_to`. Its `.pubignore` keeps `doc/`, `tool/` and `build/` out of the
  archive, its `analysis_options.yaml` includes the rules of the root file, and `example/main.dart`
  is the example of the archive. Its `README.md` is the README of upstream d3-interpolate with the
  Dart forms, with no links, and with the speed table of `doc/performance.md`. It depends on
  Flutter, on `flutter_d3_color_port` (as d3-interpolate depends on d3-color) and on `vector_math`
  (the `Matrix4` of Flutter), and imports no package of another port.
  `flutter_d3_port` depends on it with `^0.1.0`.
  - The port uses no JS runtime (D3 ADR 0007), and its values are native (D3 ADR 0011). A color
    interpolator takes two d3-color `Color` values and returns a new color of its space at each
    call; its `toString()` is the upstream text. `interpolate<T>(a, b)` takes typed values only
    (`double`, `Color`, `DateTime`, a `typed_data` list of numbers, a `List`, `bool`, `null`) and
    throws an `ArgumentError` for another type: `src/string.js` and `src/object.js` have no Dart
    file. `interpolateDate` returns a new `DateTime`, and the array interpolators reuse their
    result list, as upstream. `interpolateRgb`, `interpolateCubehelix`, `interpolateCubehelixLong`
    and `interpolateZoom` are const objects of callable classes with `gamma` or `rho`
    (`interpolateRgb.gamma(2.2)(a, b)`); a function of two colors is the tear-off
    `interpolateRgb.call`. A zoom view is the record `ZoomView`, `(double, double, double)`.
  - `lib/d3_interpolate.dart` (port-only): the pure library, with no Flutter import. It exports
    each file of `lib/src/` outside `ui/` (ADR 0011), also `index.dart` and `upstream.dart`
    (`d3InterpolateVersion`). `lib/flutter_d3_interpolate_port.dart` (port-only) exports it and
    the Flutter layer `lib/src/ui/transform_matrix.dart` (`toTransformParts()` on a `Matrix4`,
    `toMatrix4()` on a `TransformParts`). Each file of the package imports one of the two
    libraries.
  - `lib/src/`: the files of `src/` at their mapped paths, `transform/` too. `src/transform/parse.js`
    has no Dart file: `decompose` returns a `TransformParts`, and `interpolateTransform(a, b)`
    interpolates two of them. A name that `index.js` renames (`hslLong as interpolateHslLong`) is
    a constant of `lib/src/index.dart` (D3 ADR 0008 §6). `exp`, `log`, `pow`, `atan2` and `atan`
    are `dart:math` (row `platform-interpolate-math-last-bit`).
  - `test/`: the 21 specs of `test/*-test.js` and `asserts.dart` (`package:test`, no `@TestOn`).
    `test/transformCss-test.js` has its one case in a comment and no Dart file.
    `test/port/reference_test.dart` compares the port with upstream d3-interpolate in Node.js
    v24.22.1 arm64 (`tool/reference/d3_interpolate_reference.mjs` writes
    `test/port/d3_interpolate_reference.dart`). `test/port/transform_test.dart` and
    `test/port/transform_matrix_test.dart` test the transforms and the Flutter layer.
    `test/port/native_numbers_test.dart` pins the results that differ by platform: on the VM and
    with dart2wasm, `pow(1, y)` of `dart:math` is 1 for a NaN or infinite y, `toInt()` saturates
    at 64 bits and an `int` is not a `double`; with DDC and dart2js each result is the upstream
    one. `test/port/color_values_test.dart` pins a new color at each call, and
    `test/port/rounding_and_dates_test.dart` pins `Math.round` and the date truncation.
    `test/port/faster_forms_test.dart` pins the faster forms of `doc/performance.md` against the
    upstream lines.
    `test/upstream_test.dart` (`@TestOn('vm')`) compares `d3InterpolateVersion`, the entry and the
    gitlink.
  - `tool/port_sources.yaml`: the pin of `third_party/d3-interpolate`, with the top-level key
    `marker: d3-interpolate` (the tag of `DIVERGES(d3-interpolate)`) and a `files` list.
    `doc/differences.md` has its rows, and `doc/performance.md` its figures.
  - `tool/bench/`: the benchmark (`d3_interpolate_bench.dart`, `d3_interpolate_bench.mjs` with the
    same 37 cases on the upstream source, and `run_bench.sh` for Node.js, AOT, JIT, dart2js and
    dart2wasm, both web targets run in Node.js). Typed lists, fields of an object, one class for
    the channels of a color and constants of the creation took the place of closures, records and
    `List<num>` reads. On the VM, the creation of a transform interpolator is 54 times faster, a
    transform call 3 times, a number list 5 times and a color call 35% (rows
    `adapt-interpolate-typed-loops`, `adapt-interpolate-zoom-constants` and
    `adapt-interpolate-channel-objects`).
  - `check:headers`, `test:web` and `test --no-select` examine the package.
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
    - `doc/adr/`: the ECharts ADRs, all proposed. `doc/adr/README.md` lists them with their status and their supersessions (`adr:index`).
  - `check:port`, `test:web` and `test:cases` do not examine the package
    yet. `test --no-select` runs its tests.
- `packages/flutter_chartjs_plugin_zoom_port`: the chartjs-plugin-zoom port (library,
  version 0.1.0-beta.3, on pub.dev as a beta, MIT), the first add-on port (ADR 0009). Zoom phases 1-4 are
  done (2026-11-10): each file of `src/` is ported, and the specs, the fixtures and the tests of
  real input pass. One item stays open: the device check of seam H8 on Android and iOS (Chart.js
  ADR 0108 Open 1). `doc/README.md` has the plan and the roadmap of phases 0-6. Phase 5 has the
  typed options slot (H18, done 2026-11-15 with Chart.js ADR 0148 and Zoom ADR 0005) and the theme
  extension (H19, after its Chart.js ADR).
  - It depends on `flutter_chartjs_port` with `^0.1.0-beta.4`, which the workspace resolves to the package, and imports only its public
    libraries, `js_semantics.dart` among them (Zoom ADR 0003, Chart.js ADR 0108).
  - Its `.pubignore` keeps `doc/`, `test/`, `tool/` and `build/` out of the archive, and
    `example/main.dart` (a line chart that zooms and pans) is the example of the archive.
  - `lib/flutter_chartjs_plugin_zoom_port.dart`: the public library (port-only). It exports each
    file of `lib/src/` and hides `State` of `src/state.dart`, which clashes with the Flutter
    `State` (ADR 0011): the five files that use it import `src/state.dart`. Its names: `zoomPlugin` (an instance of its class `ZoomPlugin`, Chart.js ADR 0181), the
    functions `pan`, `zoom`, `zoomRect`, `zoomScale` and `resetZoom`, the extension `ZoomChart`
    (the ten chart methods of `bindApi`, row `adapt-chart-methods-extension`), `ZoomAmount` and
    `PanAmount` (row `adapt-amount-classes`, `chart.zoom(.all(1.5))`), `ScaleRange`, the option
    classes (`ZoomPluginOptions`, `ZoomOptions`, `PanOptions`, `WheelOptions`, `DragOptions`,
    `PinchOptions`, `ScaleLimits`, `ScaleLimit` and `LimitOptions` (the limits by direction and by
    axis object, Zoom ADR 0007), row
    `adapt-native-zoom-options`), the enums `Mode`, `ModifierKey` and `DrawTime` (row
    `adapt-zoom-option-enums`), `ZoomTrigger`, the callback contexts (records) and typedefs,
    `zoomUpdateMode` (the update mode `zoom`, an `UpdateMode` of the host), `GestureEvent`,
    `ActivePointer`, the three function tables and `lib/src/upstream.dart`.
    `lib/src/upstream.dart` has `chartjsPluginZoomVersion` (`2.2.0+fb81d331`, a commit pin) and
    `chartjsPluginZoomPackageVersion` (`2.2.0`), port-only. An app gives the options as one
    immutable `ZoomPluginOptions` (Chart.js ADR 0148, Zoom ADR 0005): in `ChartConfig.pluginOptions`
    of a typed config, or in `options.plugins.zoom` of a raw config (a Map there stops a debug
    build); it registers the plugin with `Chart.register([zoomPlugin])`, or gives it inline in
    `ChartConfig.plugins` or in the `plugins` of a raw config (seam H18). The port-only zoom option
    `rangeOnlyUpdates: true` (a field, null is false) makes the five update calls of `core.dart`
    (`_updateChart`) call `chart.updateRanges(transition)` of Chart.js ADR 0111 in place of
    `chart.update(transition)`; the app keeps the contract of `updateRanges` (row
    `adapt-range-only-updates`, seam H28). The field `events` is the plugin option `events` of
    Chart.js: the event filter of the host reads it (Chart.js ADR 0150).
  - `lib/src/`: the 12 files of `src/` at their mapped paths: `types`, `options`, `defaults`,
    `state`, `utils`, `scale.types`, `core`, `handlers`, `gestures`, `plugin` and `index`;
    `src/index.umd.ts` has no Dart file (Zoom ADR 0002 item 8, Chart.js ADR 0120). `zoomPlugin` (`plugin.dart`) is a native `ChartPlugin<ZoomPluginOptions>` of the host
    (Chart.js ADRs 0144 and 0148) with the upstream hooks in order, `defaults` (the const
    `ZoomPluginOptions` of `defaults.dart`) and `supportsDataUpdates: true` (row
    `adapt-typed-plugin-object`, seam H25); its hooks take the public `Chart` with no cast and get
    the options of the defaults merged with those of the chart. The upstream keys `version`,
    `panFunctions`, `zoomFunctions` and `zoomRectFunctions` are top-level names of the library. The
    options are immutable final classes with one nullable field for each option of
    `src/options.ts`, `merge` (a nested object merges its fields, `limits` by scale id), `==` and
    `hashCode` (`options.dart`, row `adapt-native-zoom-options`): a null field is not set, a limit
    is a `ScaleLimit` (`ScaleLimit(0)`, `ScaleLimit.original`), a drag color is a `ChartPaint`,
    and the removed option `zoom.enabled` has no field. Getters such as `speedOrDefault` and
    `limitsOrDefault` give the upstream defaults of a read. A callback field (`onZoomStart`,
    `onZoom`, `onPanComplete`, ...) has its typedef type, and the plugin calls it directly; a start
    callback returns `bool` (Zoom ADR 0004). A `mode`, `scaleMode` or `overScaleMode` field is a
    sealed `ModeOption?`: a `Mode`, or a `ModeFromChart` that holds a `ModeFn` (Zoom ADR 0008); each
    reader switches over both. The update mode is an
    `UpdateMode`: the transition parameters of the API are `UpdateMode` with the upstream defaults,
    and the input zooms with `zoomUpdateMode`. The state of a chart
    is an `Expando<State>` (`state.dart`); the gesture managers are an `Expando` too. The listeners
    use `canvas.eventTarget` and `canvas.ownerDocument` of Chart.js ADR 0108 (row
    `adapt-canvas-event-target`): after a drag, the `keydown` listener stays on the document until
    `removeListeners` or the hook `stop`, as upstream. `debounce` runs on a `Timer`; each wheel zoom
    updates the chart, and `beforeUpdate` puts a new debounced handler into the state, so each
    wheel event gives its own `onZoomComplete` 250 ms later, as upstream. A user limit is a
    double; the original option of a scale for `ScaleLimit.original` converts with `jsToNumber`
    (row `js-semantics-numeric-limits`). The default drag colors are `Color` values (row
    `adapt-native-colors`).
  - `test/flutter_test_config.dart` ports `test/index.js`: the set-up of the host tests (DPR 1 and
    800 x 600, the date zone UTC, the built-in components and `Chart.register([zoomPlugin])`, the
    colors plugin off, the defaults restore, the release of the charts and the test font) and the
    event helpers `EventInit`, `triggerWheelEvent`, `dispatchEvent`, `dispatchPointer`,
    `simulatePan`, `simulatePinch` (a named `done`) and a synchronous
    `triggerMouseEvent(chart, type, (x: x, y: y))` (rows `harness-dom-events` and
    `harness-trigger-mouse-event-sync`). Each helper builds a bubbling, cancelable `NativeEvent`
    and calls `canvas.dispatchEvent`. The specs use the native matchers of package:test and
    local recording closures for the spies (Zoom ADR 0006).
  - `test/specs/`: the 8 specs of `test/specs/*.spec.js` (83 cases) and the 2 unit tests of
    `src/*.test.ts` (20 cases; the 4 category pan cases run on a real chart, row
    `harness-category-scale-fake`), with no skip. The configs give the zoom options as
    `ZoomPluginOptions` objects; the spec `defaults` compares the defaults object with `==`. `test/specs/fixtures_test.dart` runs the
    fixtures of `test/fixtures/`: the registry `index.dart`, `manifest.json`, the hand ports
    `hand/pan/*.dart` and `hand/zoom/*.dart` of the 12 fixture configs, and
    `fixtures_reference.dart`, written by `tool/reference/fixtures_reference.mjs` from the upstream
    fixtures (`test:fixtures:zoom`).
  - `test/port/` (port-only): `plugin_test.dart` (the range-only updates of Chart.js ADR 0111:
    twins of each flow with and without the option; the data-only updates of a `ChartView`, also
    with a callback in the options; the warnings of `start`, whose two `zoom.enabled` cases skip
    with `diverges: adapt-native-zoom-options`; the range in the scale options), `public_library_test.dart` (the zoom
    library next to the app library of the host and `material_ui.dart`), `handlers_smoke_test.dart`
    (the listeners with synthetic events) and the tests of real input. `handlers_test.dart`,
    `gestures_test.dart` and `index_test.dart` drive a `ChartView` with the pointer and key events
    of Flutter through the input path of the host: a wheel in a `ListView` zooms and does not
    scroll it, a mouse drag that lifts outside the box zooms, a press on the legend starts no drag,
    Escape cancels a drag with no focus, Enter, Enter on a keyboard target leaves no drag state, a
    one-finger pan and a two-finger pinch with `CanvasTouchAction.none` in a vertical `ListView` do
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
    - `doc/adr/`: the zoom ADRs. `doc/adr/README.md` lists them with their status and their supersessions (`adr:index`).
  - `check:headers` examines the package (ADR 0009 item 6).
    `test:fixtures:zoom` runs its fixtures. `test:web`, `test:cases`, `test:fixtures`
    and `check:typed-reads` do not examine it. `test --no-select` runs its
    tests without the tag `fixtures`.
- `packages/flutter_chartjs_chart_sankey_port`: the chartjs-chart-sankey port (library,
  version 0.1.0-beta.1, on pub.dev as a beta, MIT), the second add-on port (ADR 0009) and the first chart type
  of another package. Sankey phases 0-4 are done (2026-11-13). `doc/README.md` has the plan and the
  roadmap. Phase 5, next, is the work on the public API of the host for its seams.
  - It depends on `flutter_chartjs_port` with `^0.1.0-beta.4`, which the workspace resolves to the
    package, and imports only its public libraries (Sankey ADR 0003). Chart.js ADRs 0132 and 0133
    are the host changes for it.
  - Its `.pubignore` keeps `doc/`, `test/`, `tool/` and `build/` out of the archive, and
    `example/main.dart` (a sankey chart of energy flows) is the example of the archive.
  - `lib/flutter_chartjs_chart_sankey_port.dart`: the public library (port-only). It exports each
    file of `lib/src/` (ADR 0011), also `lib/src/index.esm.dart` (`SankeyController`, `Flow`, `SankeyDataPoint`, `SankeyNode`,
    `FromToElement`, `SankeyNodeGap`, `SankeyNodeCallback`, `SankeyParsedCustom` and the six
    enums) and `lib/src/upstream.dart` (`chartjsChartSankeyVersion`, `0.19.1`), and has the
    port-only List `sankeyRegisterables`. An app calls `Chart.register(sankeyRegisterables)` once
    and gives a typed `ChartView` a `ChartConfig` with a `SankeyDataset`: the class of the first dataset
    gives the chart type (Chart.js ADR 0190). `Flow` is also a Flutter widget name: a library that imports Flutter
    and names the element imports the port with a prefix (seam S21).
  - `lib/src/`: the files of `src/` at their mapped paths: `types`, `lib/helpers`, `lib/core`,
    `lib/layout`, `labels`, `flow`, `controller` and `index.esm`; `src/index.ts`, the entry that
    registers at its import, has no Dart file (Sankey ADR 0002). The port-only
    `sankey_dataset.dart` has the typed `SankeyDataset` and its option types `SankeyColor`,
    `SankeyNodeValue`, `SankeyFlowValue`, `SankeyNodeLabels` and `SankeyFlowLabels` (Sankey ADR
    0004): `lowerOwn` writes the values of a raw sankey dataset Map.
    - A string union of an option is an enum (`SankeyOrientation`, `SankeyLabelPosition`,
      `SankeyColorMode`, `SankeyModeX`, `SankeyNodePaddingMode`, `SankeySize`, row
      `adapt-sankey-option-enums`); a name in a raw config stops a debug build. A color is a
      `ChartPaint` or a `Color` (row `adapt-sankey-native-colors`). The static `defaults`,
      `descriptors` and `overrides` are typed scopes of the host with the sankey keys as extras
      (Chart.js ADR 0204); their values are the Dart objects of the host options (row
      `adapt-sankey-native-defaults`).
    - `SankeyNode` has `inFlow` and `outFlow` for the upstream `in` and `out` (row
      `adapt-sankey-node-fields`). A data item is a `SankeyDataPoint`, or a Map that the keys of
      `parsing` read (row `adapt-sankey-data-point`). A parsed item is a `ParsedItem` of the host
      with a `SankeyParsedCustom` as `custom` (row `adapt-sankey-parsed-item`).
    - The options are objects of the host resolver. Immutable classes with a typed field for each
      option read them (Sankey ADR 0005, row `adapt-sankey-resolved-options`):
      `SankeyControllerDatasetOptions`, `SankeyNodeLabelsOptions`, `SankeyParsingOptions`,
      `FlowOptions` and `FlowLabelsOptions`. Their static `of` reads each key once by name, and no
      other code reads these options by name. The controller reads `of` again after each
      `configure`; `Flow.flowOptions` keeps its result while the options object is the same, and
      the controller calls `Flow.expireFlowOptions` after each update of a flow and before each
      draw (the options of one flow change in place). A Map option (`labels`, `column`,
      `priority`, a node-scoped option by node key) comes from the resolver as a view of the Map,
      not as a `Map` (seam S10): `of` reads each key of all its scopes into a Dart Map. A
      node-scoped option is a `SankeyNodeValue<T>` (a value, a Map by node key or a
      `SankeyNodeCallback<T>`), and `resolveNodeOption<T>` of `labels.dart` gives its value for a
      node (row `adapt-sankey-node-option`).
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
    and `material_ui.dart`, and draws a typed `ChartView` with a `SankeyDataset` of `SankeyDataPoint` items.
    `test/port/sankey_dataset_test.dart` draws each typed case and its raw twin and compares the
    nodes, the flows and the draw calls, also of a hovered flow.
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
    - `doc/adr/`: the sankey ADRs, all proposed. `doc/adr/README.md` lists them with their status and their supersessions (`adr:index`).
  - `check:headers` examines the package (ADR 0009 item 6).
    `test:fixtures:sankey` runs its fixtures. `test:web`, `test:cases`, `test:fixtures`
    and `check:typed-reads` do not examine it. `test --no-select` runs its
    tests without the tag `fixtures`.
- `packages/flutter_kurkle_color_port`: the @kurkle/color 0.3.2 port (library, version 0.2.0,
  MIT, on pub.dev), the color library of the Chart.js port. Its pubspec has no
  `publish_to`. It depends only on Flutter (`dart:ui`: the methods of the upstream class `Color`
  are the extension `KurkleColor` on the Flutter `Color`, Chart.js ADR 0171) and imports no other
  port. `flutter_chartjs_port` depends on it with `^0.2.0`, which
  the workspace resolves to the package; `chartjs_test_utils` and the gallery name it as a path
  dependency. Its `.pubignore` keeps `doc/`, `tool/` and `build/` out of the archive, and
  `example/main.dart` is the example of the archive.
  - `lib/flutter_kurkle_color_port.dart`: the public library (port-only). It exports each file of
    `lib/src/`: `index.esm.dart` (the names of `src/index.esm.js`: the extension `KurkleColor`,
    `RGBA`, `color` and the functions of `byte`, `hex`, `hue`, `names` and `rgb`), the other
    modules and `upstream.dart` (`kurkleColorVersion`). The files of `lib/src/` import the public
    library, not each other (ADR 0011); an import of the package has no `show` list and no prefix, except
    for a name conflict (`color.dart` imports the library again as `kurkle` for the module
    functions that its methods shadow, `hue.dart` keeps `dart:math` as `math` beside the upstream
    locals `max` and `min`, and a file that also imports the `color` of Chart.js hides `color`).
    The app library of `flutter_chartjs_port` exports it with `hide color`.
  - `lib/src/`: the files of `src/` and `packed.js` at their mapped paths, `simple_parse.dart`
    (the guarded comma notation) and `numbers.dart` (port-only): the plain Dart forms of `x | 0`
    (`toInt32`), the number of an input value (`toNumber`), the test `if (x)` of a number
    (`isNonZero`) and the text of a number in a CSS string (`numberText`). The package uses no JS
    runtime. Dart `null` stands for JS `undefined`. Each method of `KurkleColor` reads the bytes
    of the Flutter color, runs the upstream arithmetic and returns a new color (row
    `adapt-kurkle-color-extension`): `alpha(a)` is `withAlphaRatio(a)`, and `clone` and `valid`
    have no port. `KurkleColor.of` (the constructor) and `color()` give Dart `null` for an input
    that is no color. They take no CSS text (row `adapt-direct-colors`); `hexParse`, `nameParse`,
    `rgbParse` and `hueParse` read it, and `KurkleColor.fromRgbaBytes` makes a color of their
    result.
  - `test/index_test.dart` ports `test/index.js`; `test/port/` has the port-only tests;
    `test/support/reference.dart` has `cssColor` (the string branch of the upstream constructor,
    a `Color?`)
    and an independent ToInt32 reference. The tests use `package:test` and run on the VM and in
    `test:web`.
  - `tool/port_sources.yaml`: the pin of `third_party/kurkle-color`, with the top-level key
    `marker: kurkle` (the tag of `DIVERGES(kurkle)`). `doc/differences.md` has its rows.
  - `check:headers` examines the package as its own home. `test:web` and `test --no-select` run
    its tests. `test:cases` and `check:typed-reads` do not examine it. The core layers of
    `flutter_chartjs_port` may import its public library.
- `third_party/`: reference sources only: never imported, built or shipped. Excluded from
  analysis.
  - Shallow git submodules: `Chart.js` at the tag `v4.6.1`
    (`packages/flutter_chartjs_port/doc/upstream-tracking.md` §2.4), and `kurkle-color` (`v0.3.2`) and
    `chartjs-test-utils` (`v0.4.0`) at release tags. The last two come from Chart.js ADR 0035.
  - The 34 D3 submodules, also shallow at release tags (D3 ADR 0001): `d3` (`v7.9.0`), the 30
    `d3-*` modules, `internmap`, `delaunator` (`v5.1.0`) and `robust-predicates` (`v3.0.3`).
    `packages/flutter_d3_port/tool/port_sources.yaml` gives the tag and the commit of each, except
    `d3-color` and `d3-interpolate`, whose pins are in the `tool/port_sources.yaml` of
    `packages/flutter_d3_color_port` and `packages/flutter_d3_interpolate_port`.
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
  - `docs/adr/README.md` has the rules and the template of all ADRs, and the list of the ADRs of
    this folder. An add-on port depends on its host port and imports only the public libraries of
    the host (ADR 0009). ADR 0008 item 1 has the clause for it.

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
rendered forms. The typed API uses `TooltipOptions.callbacks` and `Dataset.tooltipCallbacks`; the old `titleText`,
`labelText` and `footerText` parameters are removed. Reference generators emit native expected values; no callback
Map adapter is present in the runtime.

The tooltip options are one immutable object, `TooltipOptions` (Chart.js ADR 0192, rows
`adapt-native-plugin-options` and `adapt-tooltip-scripted`): a `PluginOptions` with a nullable field for each
option, in `ChartConfig.pluginOptions` of a typed config or in `options.plugins.tooltip` of a raw config, where a
Map stops a debug build. `ChartTooltip`, `ChartConfig.tooltip` and the scope kind `TooltipOptions` are gone. The
scriptable form of the options is the one function `scripted`, `(context, options) => TooltipOptions(...)`. A test
that gives tooltip options gives a typed config; the generated data and the hand fixtures hold the object in their
raw configs, and no helper turns a Map into options.

The legend options are one immutable object, `LegendOptions` (Chart.js ADR 0193, rows
`adapt-native-plugin-options` and `adapt-legend-scripted`): a `PluginOptions` with a nullable field for each
option, with the nested `LegendLabelOptions` (`labels`) and `LegendTitleOptions` (`title`), in
`ChartConfig.pluginOptions` of a typed config or in `options.plugins.legend` of a raw config, where a Map stops a
debug build (`false` turns the legend off). `ChartLegend`, `ChartConfig.legend` and the scope kinds
`LegendOptions`, `LegendLabelOptions` and `LegendTitleOptions` are gone. The label and title `color` that no
options set is the `color` of the chart, which the legend gives in `beforeUpdate`. The scriptable form of the
options is the one function `scripted`, `(context, options) => LegendOptions(...)` with the chart context, once
for each update. A data fixture with legend options has a hand port. The rules of the tooltip options for tests
apply.

The decimation options are one immutable object too, `DecimationOptions` (Chart.js ADR 0194, rows
`adapt-native-plugin-options` and `adapt-decimation-algorithm-objects`): `enabled`, `algorithm` (a
`DecimationAlgorithm`), `samples`, `threshold` and `events`, in `ChartConfig.pluginOptions` or in
`options.plugins.decimation` of a raw config, where a Map stops a debug build. The scope kind
`DecimationOptions`, `DecimationOptions.of` and `DecimationAlgorithm.of` are gone. `ChartConfig` has `parsing`
and `devicePixelRatio`. Each decimation test gives a typed `ChartConfig` with no Map patch, and a
change of an option pumps a `ChartView` with the next config.

The filler and colors options are one immutable object each (Chart.js ADR 0196, row
`adapt-native-plugin-options`): `FillerOptions` (`propagate`, `drawTime`, `events`) and `ColorsPluginOptions`
(`enabled`, `forceOverride`, `events`, and the theme palettes `borderColors` and `backgroundColors` of row
`theme-H4a`), in `ChartConfig.pluginOptions` or in `options.plugins.filler` and `options.plugins.colors` of a raw
config, where a Map stops a debug build. `ChartFiller`, `ChartColors`, `ChartConfig.filler`,
`ChartConfig.colors` and the scope kinds `FillerOptions` and `ColorsOptions` are gone. The theme writes one
`ColorsPluginOptions` with its palettes. A data fixture with colors options has a hand port. The rules of the
tooltip options for tests apply.

The title and the subtitle options are one immutable object each (Chart.js ADR 0197, rows
`adapt-native-plugin-options` and `adapt-title-scripted`): `TitleOptions` and `SubtitleOptions`, the two final
classes of the sealed `TitleBoxOptions<T>` (the fields `align`, `display`, `position`, `color`, `font`,
`fullSize`, `padding`, `text`, `weight`, `scripted` and `events`, written once), in `ChartConfig.pluginOptions`
or in `options.plugins.title` and `options.plugins.subtitle` of a raw config, where a Map stops a debug build.
`ChartTitle`, `ChartConfig.title`, `ChartConfig.subtitle`, `TitleOptions.of` and the scope kind `TitleOptions`
are gone. The `color` that no options set is `Chart.defaults.color`, which the plugin gives in `beforeUpdate`
(`resolvedTitleOptions`). The scriptable form of the options is the one function `scripted`,
`(context, options) => TitleOptions(...)` with the chart context, once for each update. The theme writes one
`TitleOptions` and one `SubtitleOptions`. A data fixture with title options has a hand port. The rules of the
tooltip options for tests apply.

A tooltip item is the native extensible class `TooltipItem` of `lib/src/types/tooltip_item.dart` (row
`adapt-native-tooltip-item`). It is immutable: `datasetIndex` and
`dataIndex` are `int`, `label` is the `List<String>` of the lines of the label, `formattedValue` is a `String`,
`element` is nullable, and `dataset`, `parsed` and `raw` are values of the app. A body item is the final class
`TooltipBodyItem` with the `List<String>` fields `before`, `lines` and `after`. `TooltipModel.dataPoints` is a
`List<TooltipItem>?`, `body` is a `List<TooltipBodyItem>?`, and the four text lists are `List<String>?`.
`getLabelAndValue` of a dataset controller returns `({List<String> label, String value})`: a falsy label is the
empty List (`dataLabelLinesOf`). The tooltip options `filter`, `itemSort` and `external` hold the typed functions
`TooltipItemFilter`, `TooltipItemComparator` and `TooltipExternal` of `tooltip_callbacks.dart`, also in a raw
config, with no `this`; a function of another type stops a debug build. `TooltipOptions` has `filter`,
`itemSort` and `external`. `types.TypedTooltipItem`, `ChartTooltipItem` and the two records of
`plugin.tooltip.dart` are removed. In the tests, `test/support/data_label.dart` gives the native label of a
reference label (`nativeDataLabel`) and the plain forms of the native items.

An active element is the native extensible class `ActiveElement` of `lib/src/types/active_element.dart` (row
`adapt-native-active-element`): `datasetIndex` and `index` are `int`,
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

A tick is the native extensible class `Tick` of `lib/src/types/tick.dart` (row `adapt-native-tick`): `value` is a `double`, `label` is the `List<String>?` of its lines, `major` is a
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
4. **Track parity.** Update the row of the module in `packages/flutter_chartjs_port/doc/parity.md`
   in the same change. A person writes `parity.md` (Chart.js ADR 0179).
5. **No JavaScript at runtime.** No WebView, no JS engine, no `dart:js_interop` in library code
   (ADR 0001). Library code must compile for every Flutter platform and for web WebAssembly.
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
   headers (`packages/flutter_chartjs_port/doc/upstream-tracking.md` §4.8). Update the rows of
   `doc/parity.md`. Backports follow ADR 0006. They never
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
- The JS numeric translation rules: Chart.js ADR 0146. Number formatting: Chart.js ADR 0119
  (package:intl as it is, with no correction of its defects).
  Emulate JavaScript only where the result changes behavior (Chart.js ADR 0034): the ticks, the
  hit element, the item order, the resolved option, a throw, or a value that reaches a layout, a
  scale, an element property, a hit test, a discrete decision or a public return value. Do not
  emulate JavaScript for exact digits or pixels only. No tool checks these forms: the review and the
  tests apply them (Chart.js ADR 0178).
- Deferred plans (`porting-flow.md` §5.1), for example
  `packages/flutter_chartjs_port/doc/canvas-cuts-plan.md`: do not do their work in a phase. A change
  that edits a file that a deferred plan cites updates the plan in the same commit (the
  references, the inventory, the pinning tests, the estimates). It adds no entry when none of
  these changes. A trigger of §5.1 brings the plan
  forward.
- Performance (`porting-flow.md` §1.1, proposed): when two Dart forms give the upstream behavior,
  choose the form with the larger measured gain. The priority is the upstream behavior, then
  performance, then the upstream structure, then less code of our own. A faster form that changes
  the upstream structure gets a `DIVERGES` marker and an `adapt` row. Record the figures in
  `performance.md`.
- The JS runtime in `lib/src/js/`: `jsObjectKeys` (`Object.keys` order), `jsSort` (the stable
  `Array.prototype.sort`), `jsGet` (the
  property read `object[key]`), `jsOrZero` (`value || 0` before arithmetic, Chart.js ADR 0017 §8),
  `jsAdd` (the operator `a + b` on a raw option value: a string operand joins, else the numbers
  add), `jsGetKey` (the read `object[key]` of a parsed item, a data item or a stack object, with the
  `jsGet` result; a read of a resolver stays `jsGet`), `jsGetIndex` (the read `object[index]` with a
  number index: a List gives the item at a whole index in range, else `undefined`) (Chart.js ADR
  0036) and the `undefined` sentinel (Chart.js ADR 0043). `Math.hypot(a, b)` has no runtime function: it is
  `math.sqrt(a * a + b * b)` (Chart.js ADR 0146 §4). `Math.round(x)` is `x.roundToDouble()` (Chart.js
  ADR 0146 §7), and `Math.pow(x, 2)` is `math.pow(x, 2.0)` (Chart.js ADR 0146 §4). `Math.max` and
  `Math.min` have no
  runtime function: they are `dart:math` `max` and `min` with the type argument `double`, explicit
  or inferred (`math.max<double>(x, 0)`; a call in arithmetic infers `num`), never `num` (Chart.js
  ADR 0146 §4). `lib/js_semantics.dart` exports each
  name of `lib/src/js/` for add-on ports (Chart.js ADR 0132). A string `data` throws a `TypeError` in
  `_dataCheck` (Chart.js ADR 0202).
  `jsToString` of a `DateTime` gives the `Date.prototype.toString` text in the platform zone, with
  the V8 zone name on the web and in UTC on the VM (Chart.js ADR 0036, differences.md row
  `platform-date-zone-name`). The functions of `lib/src/canvas/canvas_values.dart` (`canvasStyle`,
  `canvasNumber`, `canvasLineCap`, `canvasLineJoin`, `canvasTextAlign` and `canvasLineDash`) give
  an option value to a Canvas 2D setter or to `setLineDash` with no `ToNumber`: a number option
  holds a `num`, and a value of another type gives Dart `null` or NaN, which the canvas ignores
  (Chart.js ADR 0174).
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
  - The runtime has no class values (Chart.js ADR 0204). A component class of the registry is a
    typed component: a `ControllerType`, a `ScaleType` or an `ElementType` with the statics and
    a typed `create`, the `new` of the class. `IChartComponent` is what a registry reads from a
    component or a plugin.
  - The runtime has no JS function call (Chart.js ADR 0173). An option function has a fixed Dart
    type, with no `this` and no JS arity (`lib/src/types/option_functions.dart`): a scriptable
    option is `(context) => value`, `(context, options) => value` or `() => value`, with an
    `Object?` context; a descriptor `_scriptable` or `_indexable` is `(name) => bool`; a function
    `_fallback` is `(name, value) => fallback`. Another type stops a debug build. `isFunction` of
    `helpers.core` (`typeof value === 'function'`) is true for a Dart function.
    `each<T, K>` takes `(value, key)`, and `callback` calls with the exact arguments. A date adapter
    member and a registry hook take the adapter or the component as their first parameter, in
    place of `this`. A test of `typeof` is a Dart type test. A spec port that gives a function more
    arguments than it declares calls `callDroppingExtraArgs` of `test/support/drop_extra_args.dart`.
  - `jsObjectFreeze` is `Object.freeze`, and `Object.isFrozen` is the `isFrozen` getter of a
    `JsFreezable` (Chart.js ADR 0021 §5). Only a `JsFreezable` freezes. A write into frozen options throws a
    `TypeError`.
  - `jsOwnPropertyNames` is `Object.getOwnPropertyNames`. For a resolver, it gives the keys of the
    `ownKeys` trap.
  - The runtime has no `splice`, index write, `hasOwn`, `delete`, `parseFloat` or `isFinite`
    (Chart.js ADR 0175): ported code uses `removeRange`, `insertAll`, an append at the length and
    `Map.remove`. `isNumber` of `helpers.math` is true for a finite `num` only. A spec port
    changes a data array with `spliceList` of `test/support/list_splice.dart`, and reads own keys
    with `hasOwnKey` and `deleteOwnKey` of `test/support/object_keys.dart`.
  - `Date.now()` has no runtime function: it is `clock.now().millisecondsSinceEpoch` of
    package:clock, with `.toDouble()` where the code computes with doubles (Chart.js ADR 0146 §6).
    Inside `testWidgets` and `withClock`, the fake clock moves it. Ported code never calls
    `DateTime.now()`. A `DateTime` is a JS `Date`: `jsToNumber` gives its time value (Chart.js ADR
    0024).
  - The runtime has no promise code (Chart.js ADR 0172). The animations call a function at their
    end (`Animation.onSettle`, `Animation.whenAllEnd`), and `Animation.runFrame` runs these calls at
    the end of the animator frame callback.
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
- The reference engine: Chart.js ADR 0146. Take JavaScript reference values only from the
  darwin-arm64 build of Node.js v24.22.1 (V8 13.6.233.17-node.58, ICU 78.3). Each test of a data
  file pins the Node.js version and the architecture of its data. Never take reference values
  from a browser. `sin`, `cos`, `atan2` and `log` are `dart:math` as it is, and `log10` gives the
  exponent of an exact power of ten (Chart.js ADR 0146 §3): the last bit can differ from V8, and a
  reference test gives a tolerance there or lists a hit point on an arc border (`hitBorders`).
- The four theming invariants (specs run unthemed, no forui or Material in `lib/`, no
  `Chart.defaults` writes for theming, no name of `lib/src/theme/` in ported files): Chart.js ADR
  0147 §19 and ADR 0012.

The D3 port applies the rules above with these changes. D3 ADRs 0001 to 0006 are proposed, D3
ADRs 0007 to 0011 are accepted. The doc paths
are relative to `packages/flutter_d3_port/doc/`.

- Rule 1: read the upstream file in `third_party/<repo>`. Never port from `d4` or from another
  Dart D3 package (`prior-art/README.md`).
- Rule 2: the header names the repository and its tag, for example
  `// Ported from d3-array v3.2.4 src/ticks.js (ISC, Mike Bostock).` The port-only marker is
  `// Original code, not ported from D3: <reason>.` D3 ADR 0001 item 8 gives the holder strings.
  A file whose name fails the `file_names` lint has `// ignore_for_file: file_names` after its
  header lines (D3 ADR 0002).
- Rules 3 and 4: port the specs by D3 ADR 0009, and by D3 ADR 0004 §6 to §10. Update the row of
  the repository in `parity.md`
  in the same change. A person writes `parity.md`.
- Rule 6: a bump moves one repository. It changes the submodule, the entry in
  `tool/port_sources.yaml` and the headers of the files of that repository (D3 ADR 0001 item 7).
  A bump of `third_party/d3` also changes `d3Version`. `upstream:check` and
  `packages/flutter_d3_port/test/upstream_test.dart` fail on a mismatch.
- `upstream-ledger.md` has one section for each repository. A difference carries
  `// DIVERGES(d3): <row id>, <reason>` and a row in `differences.md`. In a module package, the tag
  is the repository name, for example `// DIVERGES(d3-color): <row id>, <reason>`, and the row is
  in the `doc/differences.md` of the package. The port-only marker of a module package names the
  repository: `// Original code, not ported from d3-color: <reason>.`
- Number strings (D3 ADR 0007 §4): a number in a text of a module is `double.toString` with no
  `.0` for a whole number. A port-only test compares the texts with upstream in Node.js.
- No port depends on another port (ADR 0008). Thus D3 code never imports
  `package:flutter_chartjs_port`. The D3 port uses no JS runtime (D3 ADR 0007): no `undefined`
  sentinel, no `jsCall` and no JS number methods. `Math` is `dart:math` as it is. A number in a
  text of a module is `double.toString` with no `.0` for a whole number.

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
- Numbers and JS values follow ECharts ADRs 0003 and 0004 with the rules of Chart.js ADRs 0146
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
  `package:chartjs_test_utils/flutter.dart` and `pure.dart`. A part of the host that the public
  libraries do not give is a host change with a Chart.js ADR, first. `host-seams.md` lists each
  use of the host with its state. A change that closes a seam updates its row.
- A difference carries `// DIVERGES(zoom): <row id>, <reason>` and a row in `differences.md`.
  `check:headers` pairs the markers and the rows.
- The JS numeric rules of Chart.js ADRs 0146 and 0034 apply. The zoom port takes the JS runtime
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
  `package:flutter/painting.dart` for padding, fonts and corners (Chart.js ADRs 0116 and 0187). The core layers are the files that these roots reach. The roots include `lib/src/js/`,
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
  `@TestOn('vm')` after its header line. `test:web` does not compile it.
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
  writes `adapters.date` restores the old state with `addTearDown`.
- `flutter_test_config.dart` registers the built-in components before `main()` of each test file and
  before the snapshot of the restore (`setUpBuiltins()`, the row `harness-register-builtins`,
  Chart.js ADR 0022 §8). After the registration, it sets `defaults.plugins.colors.enabled = false`
  (the port of `test/index.js:25-28`) with a merge of `ColorsPluginOptions(enabled: false)` over the
  defaults object (Chart.js ADR 0196), before the snapshot of the restore. `setUpSpecs()` and
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
- The spec ports have no Jasmine emulation (Chart.js ADR 0180, Zoom ADR 0006). A spec compares
  with the matchers of package:test: `equals` on native values and objects with `==`
  (`ActiveElement`, records), `same`, `closeTo` and `isA<T>().having(...)` on typed members. A
  spy of a function value or of a plugin hook is a local closure that adds its arguments to a
  local `List`. A spy of a method is a recorder in the slot that the library reads
  (`recordElementDraws` for `meta.data[i]`, `recordLineCalls` for `meta.dataset`,
  `recordArrayCalls` for the listeners of a data array, of `test/support/draw_recorder.dart`; a
  context in `chart.ctx`). A recorder needs `animation: false` (the default of `acquireChart`) or
  the end of the animations: it throws a `StateError` for an element with a running animation.
- A Jasmine `spyOn(chart, 'update')` is a plugin with a `beforeUpdate` hook (`_spyOnUpdate` of
  `test/specs/global.defaults_test.dart`, Chart.js ADR 0041 §11 item 2).
- A plugin of a test is a native `Plugin<Object?>(id: ..., hooks)`, never a Map. A cancelable
  hook returns `bool`. A test that gets a plugin Map from the reference data makes the native
  plugin with `nativePlugin` of `test/support/native_plugin.dart` (`copyReference` of
  `test/port/scales/scale_chart_harness.dart` does it for the key `plugins`).
- Jasmine `this` in a spec port is a set of `late` variables of the group closure.
- A test scale overrides `getPixelForValue(double value, [int? index])`. A test controller
  converts the raw `jsGet(parsed, axis)` with `scaleValueOf(scale, value)`, a label with
  `scaleLabelOf(scale, value)` (Chart.js ADR 0186).
- A scale reference test in `test/port/scales/` builds each chart of its generator with
  `acquireChart` in a `testWidgets` case and compares it through `scale_chart_harness.dart`. Its
  `main()` registers the test controller as a `ControllerType`. The draw calls have the element draws:
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
  `expectTwin` of `twin.dart`) compare the Map of each typed field with its raw twin. `ChartView`
  takes only a typed `ChartConfig` (Chart.js ADR 0198): a test of a change pumps a `ChartView`
  with the next config.
- The plugin reference tests in `test/port/plugins/` run the cases of their generator through
  `testPluginChartCases` of `plugin_chart_harness.dart`: the controller harness with `hits: false`,
  the key `boxes` (`observeBoxes`) and a key `plugins.<id>` for each observer of the file. A unit
  case turns off each other plugin (`unitPlugins` of `plugin_chart_common.mjs`), and a full case
  runs the plugins with their defaults (Chart.js ADR 0041 §3 and §4).
- The test files of a controller unit register the controller in `main()`
  (`Chart.register([<Name>Controller.component])`) until the integration agent of its wave adds the
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
  `@TestOn('vm')`. Each fixture test has the tag `fixtures`: `test --no-select` and `test:cases`
  exclude it, and `test:fixtures` runs it. A hand port is one file at
  `test/fixtures/hand/<path>.dart` with the header of rule 2, the library doc `/// A hand-ported
  fixture config (Chart.js ADR 0029, section 4).` before `library;`, and the function
  `FixtureConfig fixture()`, which makes new objects at each call (Chart.js ADR 0199). It returns
  `FixtureConfig.typed` with a typed `ChartConfig`: an option with no typed parameter goes to the
  raw options of the nearest typed object (`raw(object, map)` of `chartjs_test_utils`, Chart.js ADR
  0201), with its native value (a `ChartPaint.solid(Color(...))` for a color, the enum value for a
  keyword), and a function of a color option returns a
  `ChartPaint`. Only a config that a `ChartConfig` cannot hold (no dataset, no chart type, a first
  dataset of another type than the chart, `xLabels` or another key with no parameter) returns
  `FixtureConfig.map`, with the reason in its doc. A typed hand port ignores the lints
  `prefer_const_constructors` and `prefer_const_literals_to_create_immutables`: the chart keeps the
  Lists of its config and writes into some of them. A run hook writes into a typed dataset scope by
  name (`jsSet`). Its entry in `handFixtures` has the first 12 hex digits of
  the manifest `sha256`. The import prefix is the path without the extension in lower case, with
  each run of other characters than `a-z` and `0-9` as `_`. A fixture skip is an entry of
  `fixtureSkips`. No skip covers a defect. In a hand port, a scriptable option takes the typed
  context class of its option (`(ScriptableScaleContext context) => context.tick!.value`), and a
  segment function reads a property of an element with the access by name of `Element`
  (`(ctx.p0 as Element)['skip']`). A canvas as an image source is `toImageSource()` of
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
  ADR 0146.
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
  `test/port/canvas/text_metrics_reference.dart` from headless Chrome. The engine rule of Chart.js ADR 0146
  does not apply to it. Do not edit the generated files by hand.
- The D3 tests use the matchers of `package:test` (D3 ADR 0009 §2), with no Node `assert`
  stand-in. The d3-color and d3-interpolate specs are pure, and `test:web` runs them. DDC makes a
  constant `-0.0` a 0: a web test that needs -0 makes it at run time, with `double.parse('-0')`.
- In a D3 test file with `// ignore_for_file: file_names`, `@TestOn('vm')` comes after the ignore
  line (D3 ADR 0002 section 2). A D3 module whose specs change module-level state restores it
  through a set-up function in the `test/support/` folder of its package (D3 ADR 0009 §4). The D3
  package has no
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
- d3-color is ISC. `packages/flutter_d3_color_port/LICENSE` is the ISC text with
  `Copyright 2010-2022 Mike Bostock` (the `LICENSE` of `third_party/d3-color` at `v3.1.0`) and
  `Copyright 2026 Vasiliy Ditsyak`. The `packages/flutter_d3_color_port/**` table of `REUSE.toml`
  comes after the kurkle table.
- d3-interpolate is ISC. `packages/flutter_d3_interpolate_port/LICENSE` is the ISC text with
  `Copyright 2010-2021 Mike Bostock` (the `LICENSE` of `third_party/d3-interpolate` at `v3.0.1`)
  and `Copyright 2026 Vasiliy Ditsyak`. The `packages/flutter_d3_interpolate_port/**` table of
  `REUSE.toml` comes after the d3-color table.
- d3-scale-chromatic is ISC with an Apache-2.0 ColorBrewer component (D3 ADR 0001 items 10 and 12).
  `packages/flutter_d3_scale_chromatic_port/LICENSE` carries both notices, and `REUSE.toml` has
  both the package `ISC` table and the 35-file ColorBrewer `ISC AND Apache-2.0` table.
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
  `flutter_chartjs_plugin_zoom_port`, `flutter_chartjs_chart_sankey_port`,
  `flutter_kurkle_color_port`, `flutter_d3_color_port`, `flutter_d3_interpolate_port`,
  `flutter_d3_scale_chromatic_port`, `flutter_d3_path_port`, `flutter_d3_shape_port`,
  `flutter_d3_format_port` and `flutter_d3_array_port`. A D3
  module package is
  `flutter_<repo>_port` (D3 ADR 0008). A later port uses
  the same form. An add-on port takes the
  npm name of the add-on (ADR 0009 item 5). A harness package is `<library>_test_utils`, or the npm name
  of the upstream harness in snake case (`chartjs_test_utils`). A gallery app is
  `apps/<library>_gallery`. A design-system adapter is `<library package>_<system>`, for example
  `flutter_chartjs_port_forui`. The directory and the commit scope of a package are its name.
  Before a change adds a name, examine `https://pub.dev/api/packages/<name>`: it must give 404.
- Imports (ADR 0012): the public library of each package of `packages/` exports each file of
  `lib/src/`, and each file of the package imports that library, not a file of `lib/src/`.
  `flutter_chartjs_port` has three libraries: `chartjs_core.dart` (each core file, Chart.js ADR
  0061), `chartjs.dart` (each file, no `hide`) and the app library `flutter_chartjs_port.dart`
  (`chartjs.dart` without `Animation`, `Element`, `FilterCallback`, `Title` and `Tooltip`). A core
  file and a browser test import `chartjs_core.dart`; another file imports the app library, or
  `chartjs.dart` when it uses a hidden name. Each public top-level name of `lib/src/` is unique: an
  interface of `lib/src/types/` with the name of a class has the prefix `I` (`IChart`, `IScale`,
  row `adapt-public-library-names`). An import has no `show` list, no `hide` list and no prefix,
  except for a clash of two names (`show NumberFormat` on `package:intl/intl.dart`, whose
  `TextDirection` clashes with the one of `dart:ui`) or a local name that hides an imported name. A
  core layer imports `package:flutter/painting.dart` with no list (Chart.js ADR 0187). A package import
  hides a `dart:` name with no error: a file that reads `pi` of `dart:math` next to the host
  helpers has `hide pi` on the helpers. A public library hides an internal name that clashes with
  `package:flutter/widgets.dart` (the zoom `State`).
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
  `flutter_kurkle_color_port`. The scope of the d3-color port is `flutter_d3_color_port`. The
  scope of the d3-interpolate port is `flutter_d3_interpolate_port`. The scope of the
  d3-scale-chromatic port is `flutter_d3_scale_chromatic_port`. The scope of the d3-path port is
  `flutter_d3_path_port`. The scope of the d3-shape port is `flutter_d3_shape_port`. The scope of
  the d3-format port is `flutter_d3_format_port`. The scope of the d3-array port is
  `flutter_d3_array_port`. Checks:
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
  <https://artflutter.github.io/flutter_ports/docs/>, on the newest stable Flutter. It also publishes `apps/chartjs_ergonomics` at
  <https://artflutter.github.io/flutter_ports/ergonomics/>, on the newest stable Flutter. If the docs do not build,
  their page shows that result, and the other pages deploy. The workflow also publishes
  `apps/chart_benchmark_lab` once for each Flutter
  channel, at <https://artflutter.github.io/flutter_ports/lab-stable/>, `lab-beta/` and `lab-master/`.
  Each run takes the newest release of stable and of beta, and the head of the branch `master`. It does
  not read `.fvmrc`. The action caches no SDK for master, because its cache key for master is fixed. The
  lab resolves alone in these builds (the step deletes `resolution: workspace`), so that a dev dependency
  of the workspace cannot stop a page. The root `pubspec.lock` gives the first choice of versions. If a
  channel does not build, its page shows that result, and the other pages deploy. If no channel builds,
  the deploy stops. The old address `lab/` goes to the root page. The workflow also publishes
  `apps/chartjs_supabase_dashboard` once for each channel, at `dashboard/stable/`,
  `dashboard/beta/` and `dashboard/master/`, with its own page `dashboard/`
  (`tool/pages/dashboard.html`, one WebAssembly and one JavaScript link for each channel), apart
  from the root page. Its builds resolve the app alone, as the lab does, and read the Supabase URL
  and the publishable key from the repository variables `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY`. A dashboard build that fails does not stop the deploy: its channel
  page says so. The build has `--web-content-hash`: the
  bundle and asset file names get a content hash, so a new build misses the browser cache. The app has the `web/isolate.js` and `web/flutter_bootstrap.js` of the lab; its
  worker leaves the CORS requests to other origins (Supabase) alone. The job `version` computes the lab
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
