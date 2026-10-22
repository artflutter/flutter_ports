# Chart.js ADR 0029: Fixture smoke runner

- Status: accepted (2026-10-21)
- Date: 2026-10-21
- Related: [Chart.js ADR 0006](0006-options-representation-and-resolver.md) (raw Map configs,
  `jsonDecode` output, the `undefined` sentinel),
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) §4 and §5 (no image comparison, the
  smoke test, the moment format strings),
  [Chart.js ADR 0032](0032-js-numeric-semantics.md) (the reference engine),
  [Chart.js ADR 0035](0035-third-party-sources.md) (`tool/port_sources.yaml`),
  [Chart.js ADR 0012](0012-dart-file-naming.md) (the upstream spelling, `file_names`, the
  underscore members),
  [Chart.js ADR 0016](0016-frame-scheduling.md) (`requestAnimFrame`),
  [Chart.js ADR 0019](0019-animation.md) Open (the six fixtures that drive the animator),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) §13 (a gain that only a
  microbenchmark measures),
  [Chart.js ADR 0022](0022-chart-test-harness.md) §4, §5, §7 and Open ("The fixtures of phase 7"),
  [Chart.js ADR 0023](0023-underscore-member-collisions.md) (names that collide),
  [Chart.js ADR 0024](0024-dates.md) §8 (the twins of the moment cases),
  [Chart.js ADR 0030](0030-controller-test-strategy.md) §13 item 3 and Open item 2 (the position
  of the `auto` group),
  [porting-flow.md](../porting-flow.md) §1 step 6, §1.1, §3 ("Where tests run", "Fixture
  selection"), §4 tools 5, 6 and 7, §5,
  [doc/upstream/README.md](../upstream/README.md) ("Fixtures", "Dart test names for tool 5"),
  [differences.md](../differences.md) rows `adapt-date-moment-format`, `harness-acquire-chart` and
  `harness-method-fields`

## Context

Phase 7 adds tool 7, the fixture smoke runner (`porting-flow.md` §4 item 7). The kickstart prompt
of phase 7 (`kickstart-prompt.md:143-148`, a working file of phase 7, not committed) names its
parts: the port of `src/fixture.js` of chartjs-test-utils 0.4.0 without the image comparison,
the tag `fixtures`, the melos script `test:fixtures`, the CI job `fixtures`, and the hand ports of
the configs with functions in `test/fixtures/hand/`. The exit criterion (`:178`) is: "The fixture
smoke tests pass for the ported chart types, also in the CI job `fixtures`." Chart.js ADR 0034 §4
fixes the test: "A smoke test builds the chart and renders one frame. It passes when no exception
occurs."

Three questions stay open in other ADRs. Chart.js ADR 0019 (Open) leaves two forms for the six
fixtures that drive the animator. Chart.js ADR 0022 (Open, "The fixtures of phase 7") fixes only
the import of `utils.dart` with the prefix `utils` and says "Phase 7 decides the rest". Chart.js
ADR 0030 (Open item 2) waits for the position of the fixture tests.

A design panel wrote three drafts (fidelity, performance and simplicity). A judge scored them. This
ADR takes the performance draft as its base and adds the parts of the other drafts that the judge
named.

### Upstream facts

The lines below are at the pins: chartjs-test-utils `v0.4.0` (`third_party/chartjs-test-utils`)
and Chart.js `7169e651` (`third_party/Chart.js`).

| Site | Fact |
|---|---|
| `fixture.js:1` | It imports `readImageData`, `_acquireChart` and `_releaseChart` of `utils.js`. |
| `fixture.js:15-34` | `loadConfig` reads the file at each `it`. A `.js` file runs through `new Function('"use strict"; var module = {};' + content + '; return module.exports \|\| fixture;')()` (`:24`). Thus the module body runs again at each load and gives new objects. A `.json` file goes through `JSON.parse` (`:27`). |
| `fixture.js:37-38` | A `.js` config wins over a `.json` config. The `it` name is the config URL. |
| `fixture.js:40` | `json.description` defaults to the input key. Only a failure message reads it. |
| `fixture.js:43` | `config.options` defaults to `{}`. |
| `fixture.js:45-48` | The plugin rule: `options.plugins = options.plugins \|\| false`, unless the URL contains `plugin` or `config.plugins !== undefined`. |
| `fixture.js:50` | `_acquireChart(config, json.options)`. The chart does not enter the registry `charts` of `index.js`. |
| `fixture.js:51-62` | `_done`: a missing PNG fails (`:52-55`). `readImageData` loads the PNG in a later task (`:57`). `toEqualImageData` compares (`:58`). `_releaseChart` runs after the comparison (`:59`). |
| `fixture.js:63-68` | A `run` function runs as `Promise.resolve(run(chart)).finally(_done)`. A rejection still calls `_done`. |
| `fixture.js:73-93` | `specsFromFixtures(path)` matches `new RegExp('(^/base/test/fixtures/' + path + '.+)\\.(png\|json\|js)')` against the Karma files. The prefix is a regular expression source: a dot matches any character, and `scale.time` also matches `scale.timeseries`. It returns the body of `describe('auto', ...)`. |
| `index.js:5` | `export * from './fixture'`. |
| `utils.js:36-105` | `_acquireChart` reads `canvas`, `wrapper`, `useShadowDOM` (`:64`), `useOffscreenCanvas` (`:77`), `spriteText` (`:90-92`) and `persistent` (`:100`). |
| `utils.js:107-115` | `_releaseChart` calls `spritingOff` (`:108`), `chart.destroy()` and removes the wrapper. |
| Chart.js `test/index.js:15-17` | `jasmine.fixture = {specs: specsFromFixtures}`. |
| Chart.js `test/index.js:23` | `moment.tz.setDefault('Etc/UTC')`. |
| Chart.js `test/index.js:25-28` | The colors plugin is off for all tests. |
| Chart.js `karma.conf.cjs:102-105` | Karma serves `test/fixtures/**/*.js`, `**/*.json` and `**/*.png`. |
| Chart.js `src/core/core.animator.js:38-52` | `_refresh` registers one frame callback. The callback calls `this._update()` (`:45`) and then `this._refresh()` (`:49`): a read of the property, which a fixture can replace. `start` calls `this._refresh()` (`:171`). |
| Chart.js `src/core/core.animator.js:57`, `:112` | `_update(date = Date.now())` and `_getAnims(chart)`. |
| Chart.js `src/core/core.plugins.js:103-106` | `options.plugins === false` gives no plugin descriptor. |
| Chart.js `src/core/core.datasetController.js:287-289` | A `fill` option without the filler plugin gives a `console.warn`, not a throw. |
| Chart.js `src/plugins/index.js:1-7` | The plugin order: colors, decimation, filler, legend, subtitle, title, tooltip. |
| `test/fixtures/scale.time/invalid-data.js:14`, `:36` | The data `'25:15:00'` with `parser: 'HH:mm:ss'`. |
| `test/fixtures/core.interaction/drawActiveElementsOnTop-false.js:25-28`, `:36-39` | `plugins` is an object that turns off only `tooltip` and `legend`. An `async run` calls `jasmine.triggerMouseEvent`. |
| `test/fixtures/controller.doughnut/doughnut-animation.js:1-4`, `:55-79` | A module-level canvas. The `run` hook reads `Chart.animator._getAnims`, replaces `_refresh`, calls `_update(start + i * 500)` 16 times and draws each state into the module canvas. |

### Counts at the pin

Tool 4 gives 667 fixtures (`doc/upstream/manifest.json`, `fixtures.items`). 519 configs are pure
data (`doc/upstream/fixtures.json`). The fixture groups of the manifest are in 27 spec files.

| Set | Fixtures | Pure data | Impure | Impure with a function |
|---|---:|---:|---:|---:|
| Prefixes of phase 7 (all except `plugin.*`) | 529 | 401 | 128 | 110 |
| `plugin.*` (phase 8) | 138 | 118 | 20 | 18 |

The other 18 impure configs of phase 7 have no function: a non-finite number, `undefined`, or a
global value (`moment(...)`, a canvas). JSON cannot hold them either. 25 fixtures of phase 7 have a
`run` hook. 6 of them read `_getAnims`, `_refresh` and `_update`. `controller.pie` has no fixture
folder: its fixtures are in `controller.doughnut`. The prefix `helpers` of `helpers.canvas.tests.js`
matches 0 fixtures.

### Port facts

- `packages/chartjs_test_utils/lib/src/index.dart` has the comment of `index.js:5` in place of the
  export. `utils.dart` has `acquireChart` and `releaseChart` (Chart.js ADR 0022 §4). `dom.dart` has
  `pumpFrames` (frames of 16 ms, the Jasmine timeout of 5000 ms).
- Chart.js ADR 0022 §4 item 5 (proposed): `spritingOn` and `spritingOff` have no port.
- 12 Dart spec files have the comment of a fixture group of phase 7 in place of the `auto` group.
- Tool 5 accepts a fixture test in a fixture group of the manifest. Its name is the config path
  relative to `test/fixtures/` or the Karma URL (`tool/src/spec_cases.dart:24-30`, `:141-156`).
  Tool 5 only counts these tests (`:654-661`). It does not report a failed fixture, a bad skip
  reason or a missing fixture.
- `porting-flow.md` §3 "Fixture selection" asks for a shallow submodule checkout in the job
  `fixtures`, a skip without the submodule, and `FIXTURES_REQUIRED=1`. The phase 7 prompt names
  the same job in its scope.
- `lib/src/core/core.animator.dart` keeps `_Anims`, `_getAnims`, `_refresh` and `_update` private.
  `Animator` has no public `update`, `refresh` or `getAnims`. Thus the names without the underscore
  do not collide (Chart.js ADR 0023).
- `Chart.resize` and `Chart.eventHandler` are fields that hold a function, because a test replaces
  them for one chart (Chart.js ADR 0022 §5, row `harness-method-fields`).

## Decision

### 1. The runner and its exports

1. `packages/chartjs_test_utils/lib/src/fixture.dart` is the port of `src/fixture.js`. Its header
   is `// Ported from chartjs-test-utils v0.4.0 src/fixture.js (MIT, chartjs-test-utils Contributors).`
   It imports `utils.dart` with the prefix `utils` and calls `utils.acquireChart` and
   `utils.releaseChart` (Chart.js ADR 0022 Open). It is not a pure layer: it imports
   `flutter_test` and `dart:io`.
2. `lib/src/index.dart` replaces its comment of `index.js:5` with `export 'fixture.dart';`, the
   form of `export *`. `lib/flutter.dart` adds the public names of `fixture.dart` to its `show`
   list of `src/index.dart`. `lib/pure.dart` does not export them.
3. The public names are `specsFromFixtures` (`:73`), `specFromFixture` (`:36`), `FixtureSource`,
   `FixtureItem`, `FixtureInputs`, `FixtureLoad`, `HandFixture` and `fixturesTag`. Upstream
   `specFromFixture` is a module function. The port makes it public, because the twins of §9 call
   it.
4. `dom.dart` gets `pumpFrame()`: it runs the due harness tasks and then one `binding.pump` of
   `frameInterval` (the frame callbacks, the build, the layout and the paint). `flutter.dart`
   exports it.

### 2. The call in the spec files

1. The port-only file `packages/flutter_chartjs_port/test/fixtures/index.dart` stands for
   `jasmine.fixture` of `test/index.js:15-17`. It has the function
   `void Function() specs(String path)`, which calls `specsFromFixtures` with the hand ports and
   the skips of §5.
2. A spec file imports it with the prefix `fixture`. The call has the upstream form, at the
   upstream line of the `describe` body:

   ```dart
   import '../fixtures/index.dart' as fixture;

   void main() {
     group('Chart.controllers.bar', () {
       group('auto', fixture.specs('controller.bar'));
       // the cases of the spec file
     });
   }
   ```

3. The fixture tests stay in their spec files. This closes Open item 2 of Chart.js ADR 0030
   without its trigger. 20 Dart spec files call the runner in phase 7: the 7 controller files, the
   12 files with the comment of a fixture group (`core.datasetController`, `core.interaction`,
   `core.layouts`, `core.scale`, `element.line`, `element.point`, `helpers.canvas`,
   `scale.category`, `scale.linear`, `scale.logarithmic`, `scale.radialLinear`, `scale.time`), and
   the new `mixed_test.dart`. `helpers.canvas` gets the call for the structure: it makes no test.
   `mixed_test.dart` also ports the 2 chart cases of `mixed.tests.js:4` and `:25`. They need the
   bar, line, doughnut and pie controllers. The classification of phase 7 (`all.json`) does not
   have them. Thus `test:cases` checks them, not the lift check of Chart.js ADR 0030 §12.
4. A spec file with a fixture group is a VM file (`@TestOn('vm')`, `flutter_test`), as AGENTS.md
   (Tests) asks for a chart case. `element.point_test.dart` moves for its 12 fixtures. Its 4 pure
   cases then run on the VM only (Chart.js ADR 0030 §13 item 3).
5. `flutter_test_config.dart` does not import the registry. Only the spec files with a fixture
   group and the port-only fixture tests import it. Thus the form needs no global set-up and no
   global state. The cost of an import in the config is small: 0.24-0.37 s for 20 test files
   (E4). Less code decides.

### 3. The sources of the configs

1. The list of the fixtures is `fixtures.items` of `doc/upstream/manifest.json`, in its order. It
   stands for the Karma files of `fixture.js:77-86`. Each item gives the path, the `sha256` of the
   upstream file, the `png` and the `data` flag.
2. A pure data config comes from `doc/upstream/fixtures.json`. Tool 4 wrote it in V8 with the
   source key order. The CI job `upstream-manifest` fails when the two files differ from the pin.
   `jsonDecode` output goes to the chart unchanged: an integer literal stays an `int` (Chart.js
   ADR 0006).
3. `FixtureSource` gives the two paths. The defaults are the paths relative to the package root,
   the working directory of `flutter test`. A test of the runner gives other paths.
4. The runner reads the manifest once for each test file, at the first declaration. It decodes
   `fixtures.json` once for each test file, at the first data config that a test body loads. The
   default `test` run thus never reads `fixtures.json`. Each subtree of the decoded file feeds
   exactly one test, so the runner makes no copy.
5. The runner reads the configs only from the committed files. It reads one more thing from
   `third_party/Chart.js/test/fixtures/`: the bytes of the upstream file of each fixture. It
   compares their SHA-256 with the `sha256` of the manifest item before the fixture runs. A
   difference fails the test with the path of the stale config. Thus the job `fixtures` finds a
   committed config that does not match the pin, also without the job `upstream-manifest`.

### 4. The hand ports

1. Each impure fixture that runs gets one Dart file. `test/fixtures/<path>.js` becomes
   `packages/flutter_chartjs_port/test/fixtures/hand/<path>.dart`. File and directory names keep the
   upstream spelling (Chart.js ADR 0012). No two fixture paths of the pin map to one Dart path.
2. The header is `// Ported from Chart.js v4.5.1+7169e651 test/fixtures/<path>.js (MIT, Chart.js Contributors).`
   A file whose base name fails the `file_names` lint (61 of 117 at the pin) has
   `// ignore_for_file: file_names` below the header line, the form of `simpleArc` (Chart.js ADR
   0012). `tool/port_sources.yaml` gets the target `test/fixtures/` to
   `packages/flutter_chartjs_port/test/fixtures/hand/` in the Chart.js entry. `PortTarget.map` gives
   the Dart path without a change. `PortTarget.sourcesOf` does not change: no `.json` config is
   impure.
3. The file has one top-level function `Map<String, Object?> fixture()`. Each call runs the module
   body again and returns `module.exports` (`fixture.js:24`). Module statements, for example the
   canvas of `doughnut-animation.js:1-4`, go into the function.
4. The literals follow the ported specs: `<String, Object?>{...}` for each object, `<Object?>[...]`
   for each array, the source key order, an `int` for an integer literal, `double.nan` and
   `double.infinity` for the non-finite numbers, the `undefined` sentinel for `undefined`, and a
   closure for a function. The `run` hook is the entry `'run'` of the `options` Map.
5. The run hooks port line by line. `window.requestAnimationFrame` is `requestAnimFrame` of
   `helpers.extras.dart` (Chart.js ADR 0016). `jasmine.triggerMouseEvent` is `triggerMouseEvent`
   of the harness. `Chart.helpers.clearCanvas` is `clearCanvas`. `drawImage` of a canvas takes
   the image source of the canvas layer. A splice of a data array calls `notifyArrayListeners`
   after the change (row `platform-array-events`).
6. A `moment(...)` value is a `DateTime` of the same time value in UTC, the zone of
   `test/index.js:23` (Chart.js ADR 0024: a `DateTime` is a JS `Date`). It carries the marker of
   the row `harness-fixture-sources`. 5 hand ports have such a value at the pin.
7. `check:headers` and `check:js-semantics` examine the hand ports, because their header names a
   `js` project.

### 5. The registry of the hand ports and the skips

1. `test/fixtures/index.dart` is port-only
   (`// Original code, not ported from Chart.js: the registry of the hand-ported fixture configs and the fixture skips.`).
   It is outside the mapped folder `hand/`.
2. It imports each hand port with a prefix: the path without the extension, in lower case, with
   each run of other characters than `a-z` and `0-9` as `_`. The 117 prefixes are unique at the
   pin.
3. `handFixtures` is a `Map<String, HandFixture>` from the fixture path to the loader and the first
   12 hex digits of the manifest `sha256` of the upstream file. `fixtureSkips` is a
   `Map<String, String>` from the fixture path to a skip reason of §9.
4. `specsFromFixtures` throws a `StateError` at its call when a key of `hand` or of `skips` is not
   a fixture of the manifest.
5. A hand port whose 12 hex digits differ from the manifest gives a failing test: "the hand port of
   `<path>` is stale". A Chart.js bump that changes a fixture thus fails until the porter ports the
   diff.
6. An impure fixture without a hand port and without a skip gives a failing test: "hand-port
   `<path>` to `test/fixtures/hand/`". No skip reason covers a missing hand port.
7. A hand port wins over a data config of the same path. The test of §10 item 6 keeps the case
   away.

### 6. The animator members of six hand ports

This section decides the Open item of Chart.js ADR 0019. `lib/src/core/core.animator.dart` gets
these changes:

1. `_getAnims` becomes `getAnims`, and `_update` becomes `update`. Both carry `@internal`. They
   drop the underscore because a file outside `core.animator.dart` reads them (Chart.js ADR 0012).
2. `_Anims` becomes the `@internal` class `Anims`, because `getAnims` returns it.
3. `_refresh` becomes the `@internal` field `late void Function() refresh = _refreshMethod;`. The
   private method `_refreshMethod` has the upstream body. Each call of `this._refresh()` (`:49`,
   `:171`) and the call in `unmute` call the field. Thus a replaced `refresh` sees each call, as
   the replaced property does upstream. This is the form of `Chart.resize` (Chart.js ADR 0022 §5).
   The field carries the marker of the row `harness-method-fields`.
4. The six hand ports keep their control flow: `animator.getAnims(chart)`, the backup and the
   replacement of `animator.refresh`, the 16 calls of `animator.update(start + i * 500)`, the
   `drawImage` calls and the restore. `anims.items[0]._start` is `anims.items[0].start`.
5. Cost: one field read for each animator frame. AOT gives 0.82-0.89 ns for the field call and
   0.82-0.85 ns for the method call, dart2wasm 0.337 against 0.336 ns (E6). The form keeps the
   upstream structure. Thus microbenchmark figures are sufficient evidence (Chart.js ADR 0020 §13).

### 7. The steps of one fixture test

A fixture that runs is one `testWidgets` test. `specFromFixture` ports `fixture.js:36-71` in this
order:

1. Load the config (`:39`). A missing loader fails the test (§5 item 6).
2. The description default (`:40`), the `config.options` default (`:43`) and the plugin rule
   (`:45-48`) port line by line, with `jsTruthy`, `jsGet` and `identical(..., undefined)`.
3. `utils.acquireChart(config, json.options)` (`:50`). The forced layout attaches the chart, and
   the constructor draws (Chart.js ADR 0022 §4).
4. In a `try`: when `json.options.run` is a function (`jsIsFunction`), the runner calls it with
   `jsCall`. A `Future` result settles through `pumpFrames` (frames of 16 ms, the Jasmine timeout
   of 5000 ms). An error of the hook fails the test after the settle.
5. A fixture without a PNG fails (`:52-55`). All 667 fixtures have one at the pin.
6. `await pumpFrame()`: the image load task of `readImageData` (`:57`). This is the frame of
   Chart.js ADR 0034 §4. It puts the paint path of `canvas_ui.dart` into each smoke test.
7. `toEqualImageData` (`:58`) is `n/a` (Chart.js ADR 0034 §4).
8. In the `finally`: `utils.releaseChart(chart)` (`:59`). Upstream releases only after the image
   comparison. The release after a failure stops the frame callbacks of the failed chart and
   changes no result.

The test passes when no step throws and flutter_test reports no `FlutterError`. The runner adds no
other assertion (Chart.js ADR 0034 §4).

### 8. The fixture options

| Key | Fixtures of phase 7 | Port |
|---|---:|---|
| `json.options.canvas` | 390 | `acquireChart` sets the attributes (Chart.js ADR 0022 §4) |
| `json.options.wrapper` | 0 | `acquireChart` sets the attributes |
| `json.options.useOffscreenCanvas` | 1 | `acquireChart` gives the context of a second canvas that no host shows |
| `json.options.persistent`, `useShadowDOM` | 0 | as `acquireChart` |
| `json.options.spriteText` | 186 | `n/a`: `spritingOn` has no port (Chart.js ADR 0022 §4 item 5) |
| `json.options.run` | 25 | §7 item 4 |
| `json.options.width` | 1 | ignored, as upstream: `_acquireChart` does not read it |
| `json.threshold`, `json.tolerance`, `json.debug` | 66 with `threshold` or `tolerance`, 4 with `debug` | `n/a`: only `toEqualImageData` reads them |
| `json.description` | 46 | the text of a failure message (`fixture.js:40`, `:53`) |

### 9. The set of phase 7 and the skips

1. Phase 7 runs the groups of all prefixes except `plugin.*`: 529 fixtures. The 138 `plugin.*`
   fixtures wait for the spec files of phase 8.
2. **Phase 8 modules.** A fixture of phase 7 skips as `'blocked: plugin.<id>'` when its upstream
   observations differ between a run with all registerables and a run without the plugins. The
   observations are the chart area, the layout boxes, the scale boxes, the scale min and max, the
   ticks, the element geometry and the counts of the draw calls, after the `run` hook. The id is
   the first plugin, in the order of `src/plugins/index.js:1-7`, whose removal alone changes the
   observations. When no single removal changes them, it is the first plugin whose presence alone
   restores them. The probe of E7 gives 33 skips: filler 19, title 10, tooltip 2, legend 1 and
   subtitle 1. `core.interaction/drawActiveElementsOnTop-false.js` is the subtitle case: its hidden
   y scale has 4 ticks with the plugins and 7 ticks without them, and `title` or `subtitle` alone
   gives the 4 ticks.
3. **Moment format strings.** A fixture that parses with a moment format string skips as
   `'diverges: adapt-date-moment-format'`, as the row and Chart.js ADR 0034 §5 ask for a spec case.
   39 fixtures do this: 17 `controller.bar/bar-thickness-*.json`, 12 `scale.time` and 10
   `scale.timeseries`. `scale.time/invalid-data.js` is one of them: `'25:15:00'` with
   `'HH:mm:ss'` is an invalid date in moment and the next day in the `tryParse` of intl, so the
   min, the max and the ticks change.
4. **Twins.** Each of the 36 pure data configs of item 3 gets a port-only twin, as the row
   `adapt-date-moment-format` asks. The twin replaces the moment pattern with its ICU pattern
   (`'YYYY'` to `'yyyy'`, `'YYYY-MM'` to `'yyyy-MM'`) at each `parser` key and in each
   `displayFormats` Map, and runs through `specFromFixture`. The twins are in
   `test/port/fixtures/moment_twins_test.dart`, with the tag `fixtures`. The 3 impure moment
   fixtures keep only the skip.
5. **Totals.** 72 skips (33 `blocked`, 39 `diverges`, no overlap) and 457 fixtures that run: 340
   data configs and 117 hand ports (128 impure minus 11 impure skips).
6. **Stale skips.** At the declaration, a `'blocked: plugin.<id>'` skip whose plugin is in
   `Chart.registry.plugins` gives a failing test "stale skip" in place of the skip. Phase 8 thus
   lifts each skip when it registers the plugin. The 11 impure skipped fixtures get their hand
   ports in that lift.
7. A skipped fixture is a plain `test()` with the `skip` reason and the tag, as for a spec case.
   `testWidgets` takes only `skip: true`, and the JSON reporter then gives no reason.

### 10. Test names and tool 5

1. The test name is the config path relative to `test/fixtures/`, with its extension
   (`controller.bar/aligned-pixels.js`). It is the key of the manifest, of `fixtures.json` and of
   the registry. The tool 4 README names it, and tool 5 accepts it. The group path is the
   `describe` path of the spec file plus `auto`. The test order is the manifest order. Each fixture
   makes its own chart, and the harness restores the defaults after each test. Thus the order
   changes no result.
2. Each fixture test and each skip carries the tag `fixtures` (`fixturesTag`).
3. The case mode of tool 5 (`test:cases`) and tool 6 (`parity`, `parity:check`) add
   `--exclude-tags fixtures` to their `flutter test` command.
4. Tool 5 gets the mode `--fixtures`. It runs `flutter test --tags fixtures --reporter json` on the
   Dart spec files whose manifest entry has a fixture group with at least one fixture, and on
   `test/port/fixtures/`. It reports each fixture as passed, failed, skipped with its reason, or
   missing. It fails on a failed test, on a missing fixture, on a fixture group of a selected spec
   file without a test, on an unknown name in an `auto` group, on a repeated name, and on a skip
   reason that is not `'blocked: <module>'`, `'n/a: <reason>'` or `'diverges: <row id>'`. A test
   outside `test/specs/` counts as a port-only test: only its result counts. The mode prints the 10
   slowest fixture tests. That list is not a gate.
5. The Fixtures column of `parity.md` keeps the manifest count. Tool 6 needs no other change.
6. `test/port/fixtures/index_test.dart` (VM, not tagged) checks the registry against the manifest
   and the folder `test/fixtures/hand/` (the spec gives the list).

### 11. Tag, scripts, CI job and the submodule

1. `packages/flutter_chartjs_port/dart_test.yaml` and `packages/chartjs_test_utils/dart_test.yaml`
   declare the tag `fixtures`.
2. The melos script `test` runs `flutter test --exclude-tags fixtures`. In a package without
   fixture tests, the exclusion excludes nothing and prints no warning (E9).
3. The melos script `test:fixtures` runs
   `dart run packages/flutter_chartjs_port/tool/spec_cases.dart --fixtures`.
4. The CI job `fixtures` runs on ubuntu with the setup action, a shallow checkout of the
   submodule `third_party/Chart.js`, `FIXTURES_REQUIRED=1` and `dart run melos run
   test:fixtures`.
5. The rule of `porting-flow.md` §3 "Fixture selection" applies. Without the submodule, each
   fixture test skips with the reason `'n/a: the submodule third_party/Chart.js is not checked
   out'`. With `FIXTURES_REQUIRED=1`, the same case fails. Only the job `fixtures` sets the
   variable. A stale config fails in this job (the SHA-256 check of §3 item 5), in the job
   `upstream-manifest` (the JSON files) or in the hand-port test (§5 item 5).
6. `test:fixtures` is a gate from the commit that adds the runner. AGENTS.md, CONTRIBUTING.md and
   the PR template add it to the pre-push list.

### 12. Rows and markers

1. New row `harness-fixture-sources` (harness): `fixture.dart` `specsFromFixtures`,
   `FixtureSource`, and the hand ports with a `moment(...)` value. Upstream
   `src/fixture.js`@v0.4.0:3-34, 73-93. Reason: the manifest, `fixtures.json` and the registry of
   hand ports stand for the Karma files and `new Function`. The test name is the relative path, not
   the Karma URL. The stale `sha256` check, the stale-skip check, the missing hand port and the
   `StateError` for an unknown key are port-only. A `moment(...)` value of a hand port is a
   `DateTime` of the same time value.
2. New row `harness-fixture-frame` (harness): `fixture.dart` `specFromFixture`, `pumpFrame` of
   `dom.dart`. Upstream `src/fixture.js`@v0.4.0:36-71. Reason: no image comparison (Chart.js ADR
   0009 §4), one frame for the image load task, the release in a `finally`, and a skip as a plain
   `test()`.
3. The row `harness-method-fields` gets `lib/src/core/core.animator.dart` `Animator.refresh`, with
   `src/core/core.animator.js`@v4.5.1+7169e651:38-52, 171.
4. No other row. The six animator hand ports translate their upstream lines.

### 13. The questions of the panel

| Question | Decision | Open |
|---|---|---|
| Q1. Where the runner lives and where the spec files call it | §1, §2 | — |
| Q2. The source of the configs, the hand-port form and the header rule | §3, §4, §5 | Items 1, 2 |
| Q2a. The six fixtures that drive the animator | §6 | — |
| Q3. Test names and tool 5 | §10 | — |
| Q4. Tag, scripts, CI job and the submodule | §11 | — |
| Q5. The set of phase 7, the phase 8 skips and "one frame" | §7, §9 | — |
| Q6. The fixture options | §8 | Item 3 |

## Alternatives considered

The order of the scores is that of `porting-flow.md` §1.1: behavior, performance, structure, less
code. The runner is test code. Only §6 changes `lib/`. Test wall time breaks a tie only after
priority 4.

**The three drafts.** The judge ranked the drafts on each question. Performance won Q1, Q2, Q3,
Q4 and Q6. Fidelity won Q2a and Q5. Simplicity won no question. It breaks the exit criterion of the
CI job `fixtures` and reports fixtures that need a phase 8 plugin as passed.

| Alternative | Draft | Why rejected |
|---|---|---|
| One test file for all fixture groups | P (form C) | 2.1 s less for each run of the job with `-j 4` (E3). It changes the upstream structure, and tool 5 then needs a map from that file to the spec files. |
| The registry in `flutter_test_config.dart` and a global `setUpFixtures` | F | Equal on behavior and structure. It adds a global set-up and the class `FixtureFiles`. The compile cost is 0.24-0.37 s for 20 files (E4), not 14 s. |
| `specsFromFixtures(prefix, hand: handFixtures)` in each spec file | S | The upstream call has one argument. |
| Generated Dart configs in place of `fixtures.json` | P (C1) | 3 µs less for each fixture. 50-150 ms more compile in each importing file (E2), and a generator. |
| Hand ports in `test/fixtures/<path>.dart` | F | It leaves the folder that the kickstart prompt and `porting-flow.md` §1 step 6 name, for no gain. |
| Hand ports of all 128 impure configs | F | The 11 impure skips need no port in phase 7. Phase 8 ports them when it lifts the skips. |
| A JSON copy for each test | S | Each subtree feeds one test. |
| Restore of the shared object identity | F | The probe of E8 gives equal observations and draw calls for all 9 configs with a shared object. It adds code for a future case only (Open item 1). |
| A tagged JSON form for `NaN`, `Infinity` and `undefined` | S (D) | It saves 13 hand ports and adds a tag format to tool 4 and a decoder to the runner. |
| `.json` in `PortTarget.sourcesOf` | P | No `.json` config is impure. |
| Pumps of 500 ms in place of `update(date)` | P | It changes the bodies of six hooks and needs a marker at each site. §6 keeps them 1:1 for 0.06 ns or less for each frame. |
| `pumpFrames(() => !running)` and no image loop | S | Same as above. |
| The Karma URL as the test name | F | The `/base/` prefix comes from the Karma server (`karma.conf.cjs:102-105`), not from the test structure. The relative path is the key of all files. |
| Tool 5 without a fixture mode | S | Tool 5 then reports no failed fixture, no bad skip reason and no missing fixture. |
| Fixtures in every `test` run, no CI job | S | It breaks the exit criterion "also in the CI job `fixtures`". It runs each fixture on three OS legs and again in `test:cases` and `parity`. |
| No submodule checkout and no `FIXTURES_REQUIRED` | Panel draft | The phase 7 scope and `porting-flow.md` §3 name both. The fetch costs 1.86 s and 33 MB (E9). The SHA-256 check of §3 item 5 gives the checkout a use: the job finds a stale config at the pin. Decision D4 of the phase lead (2026-10-21). |
| A skip when one plugin removal changes the canvas calls (32 skips) | P | It runs `drawActiveElementsOnTop-false.js` with other ticks than upstream (E7). |
| No skip unless a fixture throws | S | 33 fixtures then pass with another behavior than upstream, and tool 5 and `parity.md` report them as passed. |
| A static rule: skip when a phase 8 plugin is active | P | It skips 25 fixtures that need no plugin. |
| `invalid-data.js` runs, because `HH:mm:ss` has one meaning in moment and ICU | F | The parse differs (§9 item 3). |
| One `testWidgets` for each group | P (form D) | 3.3 ms less for each fixture. It loses the name, the skip reason and the isolation of each fixture. |
| No frame after the `run` hook | P | 0.6 ms less for each fixture (E5). The paint path then gets no smoke test, and Chart.js ADR 0034 §4 asks for one frame. |
| The frame in the `finally`, also after a failed hook | S | The frame can add a second error to the report. |
| A port of `spriting.js` with a text hook in `canvas_ui.dart` | F | The sprite widths change the ticks of 4 fixtures and the layout of 121 more, but the smoke test asserts neither, and the library behavior does not change. It contradicts Chart.js ADR 0022 §4 item 5 and touches a file of the deferred `canvas-cuts-plan.md`. |
| The canvas size part of `toEqualImageData` | F | Chart.js ADR 0034 §4 says that a smoke test passes when no exception occurs. It also needs a tool 4 change for 3 DPR fixtures (Open item 3). |

## Consequences

- 457 fixtures of phase 7 run as smoke tests in the CI job `fixtures`. 72 skip with a reason that
  tool 5 checks. 36 twins keep the coverage of the moment configs.
- 117 hand ports (5,338 upstream lines) and one registry come into `test/fixtures/`. A Chart.js
  bump that changes a fixture fails its test until the porter ports the diff.
- `lib/src/core/core.animator.dart` gets three `@internal` members and one public `@internal`
  class. The `differences.md` rows that name `Animator._refresh` and `Animator._update` get the new
  names.
- `element.point_test.dart` moves to the VM. Its 4 pure cases leave the web legs.
  `test/port/elements/element.point_test.dart` keeps the web legs of the module.
- The default `test` run and `test:cases` do not run the fixtures. `test:fixtures` is a new gate.
- `porting-flow.md` §3 "Fixture selection" keeps its rule. Its row "Fixture smoke tests" of
  "Where tests run", §4 item 7 and §5 get the runner facts of this ADR.
- Phase 8 lifts 33 `blocked: plugin.*` skips and hand-ports the 11 impure skipped configs. The
  stale-skip check fails when it registers a plugin and forgets a skip.
- Chart.js ADR 0019, 0022 and 0030 do not change. This ADR decides their open items on the
  fixtures.

## Open

1. **The identity of shared objects.** Owner: the porter of each Chart.js bump (AGENTS.md rule 6).
   Trigger 1: a bump adds or changes a data fixture with an object at two places (the probe
   `shared_refs.mjs` of E8). Trigger 2: a fixture test of a data config fails, and the same config
   with its shared objects passes in Node.js. Then tool 4 records the shared paths, and the runner
   restores the identity after the decode (the form of the fidelity draft).
2. **One registry for each spec file.** Owner: the phase 8 lead. Trigger: after the hand ports of
   phase 8, the import of `test/fixtures/index.dart` costs more than 4 s for each run of
   `test:fixtures` with `-j 1` (the method of E4). Then each spec file imports a registry of its
   own prefix.
3. **The canvas size check.** Owner: the maintainer. Trigger: a defect in the device size of a DPR
   chart that the smoke tests did not find. Then a new ADR restates and supersedes Chart.js ADR
   0034, tool 4 writes the PNG size, and the runner compares it with the canvas size
   (`matchers.js:197-207`).

## Evidence

All files are in the session scratchpad folder
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/`
(below: `<design>`). The drafts are `design/fixture-runner/draft-*.md`, and the judgment is
`judge.md` in the same folder (working files of phase 7, not committed). The Node.js probes ran
on an x64 build of Node.js v24.12.0 under Rosetta, against the Chart.js build at `7169e651`
(Chart.js ADR 0032). The Dart figures come from an Apple M3 Max, Flutter 3.44.9 and Dart 3.12.2.

- **E1, upstream source.** chartjs-test-utils v0.4.0 `src/fixture.js:1-93`, `src/index.js:5`,
  `src/utils.js:36-115`, `src/matchers.js:176-218`. Chart.js `7169e651` `test/index.js:1-36`,
  `karma.conf.cjs:102-108`, `src/core/core.animator.js:38-57`, `:112`, `:171`,
  `src/core/core.plugins.js:101-107`, `src/core/core.datasetController.js:284-290`,
  `src/plugins/index.js:1-7`, `test/specs/mixed.tests.js:1-46`,
  `test/fixtures/scale.time/invalid-data.js:1-40`,
  `test/fixtures/core.interaction/drawActiveElementsOnTop-false.js:1-41`,
  `test/fixtures/controller.doughnut/doughnut-animation.js:1-6`, `:49-81`.
- **E2, the config load** (`<design>/fixture-runner-performance/jsonbench/`, `compile_bench.txt`).
  `jsonDecode` of all 519 data configs: 2.37 ms AOT. The manifest: 1.62 ms AOT. A generated Dart
  builder saves 3 µs for each fixture and costs 50-150 ms of compile for each importing file.
- **E3, one file against 20 files** (`<design>/fixture-runner-performance/files_bench.txt`). 460
  tests: 6.24-6.58 s in 20 files and 4.20-4.39 s in 1 file with `-j 4`.
- **E4, the compile of the registry.** The judge re-ran the 20-file probe of the fidelity draft
  (`<design>/fixture-runner-judge/cfgprobe_rerun.txt`): 12.93 against 13.17 s and 13.02 against
  13.39 s without and with an import of 128 hand-port libraries. The performance draft measured a
  delta of about 0.1 s for one file (`<design>/fixture-runner-performance/hand_compile_bench.txt`).
  Most of it is a one-time compile, so the 14 s of that draft for 144 files is wrong.
- **E5, the cost of one fixture** (`<design>/fixture-runner-performance/harness_bench.txt`). 300
  tests: an empty `testWidgets` 2.2 ms, with `acquireChart` 4.9 ms, with one more frame 5.5 ms, a
  skipped `test()` 0.04 ms.
- **E6, the `refresh` field** (`<design>/fixture-runner-judge/hooks_bench.dart`, AOT binary
  `hooks_bench`; dart2wasm in `<design>/fixture-runner-fidelity/v2/bench/`). One call for each
  frame. Fidelity: AOT 0.881 against 0.845 ns, dart2wasm 0.337 against 0.336 ns. Judge: AOT 0.886
  against 0.829 ns. Synthesis, two runs (`<design>/fixture-runner-synthesis/hooks_bench_rerun.txt`
  and the console): AOT 0.822 against 0.819 ns and 0.859 against 0.819 ns.
- **E7, the phase 8 skips.** Fidelity: `<design>/fixture-runner-fidelity/probe/run_spec.mjs`,
  `compare.mjs`, `cmp2/`, `cmp3/`, `analyze.py`, `v2/dae/` (the 4 and 7 ticks), `v2/anim/` (the
  clock of the animation fixtures). Performance: `<design>/fixture-runner-performance/probe_fixtures.mjs`,
  `all.json`, `none.json`, `without_*.json`, `blockers.py`. The merged list of the 72 skips is
  `<design>/fixture-runner-synthesis/skips.json` (`merge_skips.py`). The twin list is
  `moment_twins.json`, and the 117 hand ports are `hand.json`, in the same folder.
- **E8, shared objects** (`<design>/fixture-runner-fidelity/v2/shared_refs.mjs`,
  `identity_probe.mjs`). 9 data configs share an object, 5 of them in phase 7. The source config
  and its JSON copy give equal observations and draw calls for all 9.
- **E9, the CI form** (`<design>/fixture-runner-performance/clone`). The shallow fetch of the pin
  took 1.86 s and 33 MB. `--exclude-tags fixtures` in `packages/chartjs_test_utils` of the probe
  workspace excluded nothing and printed no warning.
- **E10, the forms of the harness.** `flutter test --reporter json --tags fixtures` runs a file
  without the `_test.dart` suffix when the command names it
  (`<design>/fixture-runner-synthesis/probe_explicit.json`). A Dart library at
  `controller.bar/baseLine/mid-x.dart` with `// ignore_for_file: file_names` imports and analyzes
  with no issue (`<design>/fixture-runner-synthesis/hyphen/`).
- **E11, the sprite metrics** (rejected form, `<design>/fixture-runner-fidelity/v2/sprite_probe.mjs`).
  The sprite widths change the ticks of 4 phase 7 fixtures and the layout of 121 more.
