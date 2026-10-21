# Fixture smoke runner: draft "simplicity first"

Design panel for tool 7 (future Chart.js ADR 0029). Lens: the form with the least code of our own
and the fewest new concepts that keeps the behavior that Chart.js ADR 0009 protects.

Probe scripts and raw output are in
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/fixture-runner-simplicity/`:

| File | What it gives |
|---|---|
| `runner_probe_test.dart` | A working prototype of `specsFromFixtures` over `doc/upstream/fixtures.json` and `manifest.json`, run with `flutter test` from `packages/flutter_chartjs`. The chart types change to the phase 6 test controller `scaleTest` (the controllers are not ported yet). |
| `probe1.json` | The JSON reporter output of the prototype: 261 tests, 204 run, 0 failures. |
| `full_suite.json` | The JSON reporter output of `flutter test` for all of `flutter_chartjs` today. |
| `durations.py` | The summary of a JSON reporter output (count, sum, median, p90). |
| `plugins_probe.mjs`, `plugins_probe.out` | x64 Node.js v24.12.0 against the build at the pin: the phase 8 plugins that each data fixture of a ported prefix reaches after the plugin rule. |

## 0. Facts at the pin

Sources checked:
- chartjs-test-utils 0.4.0 `src/fixture.js:36-71` (`specFromFixture`), `:73-93`
  (`specsFromFixtures`), `src/index.js:5` (`export * from './fixture'`), `src/utils.js:36-105`
  (`_acquireChart` reads `canvas`, `wrapper`, `useOffscreenCanvas`, `spriteText`, `persistent`),
  `src/matchers.js:181-182` (the defaults of `tolerance` and `threshold`).
- Chart.js `test/index.js:15-17` (`jasmine.fixture = {specs: specsFromFixtures}`), `:25-28`
  (colors plugin off), `karma.conf.cjs:102-105` (the `test/fixtures/**` file patterns).
- Chart.js `src/core/core.plugins.js:104-106` and `:146-176`: `plugins: false` gives no
  descriptor. `src/core/core.datasetController.js:288`: a `fill` option without the filler plugin
  gives a `console.warn`, not a throw.
- `doc/upstream/README.md` "Fixtures" and "Dart test names for tool 5", and
  `tool/src/spec_cases.dart:24-30`, `:141-156`, `:654-660`.

Counts from `doc/upstream/manifest.json` (667 fixtures, 519 pure data):

| Prefix | Fixtures | Data (`fixtures.json`) | Hand port |
|---|---|---|---|
| `controller.bar` | 87 | 66 | 21 |
| `controller.bubble` | 8 | 4 | 4 |
| `controller.doughnut` | 57 | 42 | 15 |
| `controller.line` | 68 | 42 | 26 |
| `controller.polarArea` | 54 | 41 | 13 |
| `controller.radar` | 45 | 31 | 14 |
| `controller.scatter` | 3 | 2 | 1 |
| `core.datasetController` | 1 | 1 | 0 |
| `core.interaction` | 3 | 0 | 3 |
| `core.layouts` | 11 | 9 | 2 |
| `core.scale` | 62 | 56 | 6 |
| `element.line` | 17 | 11 | 6 |
| `element.point` | 12 | 10 | 2 |
| `mixed` | 2 | 2 | 0 |
| `scale.category` | 5 | 4 | 1 |
| `scale.linear` | 28 | 27 | 1 |
| `scale.logarithmic` | 6 | 6 | 0 |
| `scale.radialLinear` | 19 | 15 | 4 |
| `scale.time` (with `scale.timeseries`) | 41 | 32 | 9 |
| **Ported prefixes (phase 7)** | **529** | **401** | **128** |
| `plugin.*` (phase 8) | 138 | 118 | 20 |

- The 128 hand ports of phase 7 have 5,844 upstream lines. Their `impure` reasons: `function` 109,
  `non-finite` 9, `non-finite` + `undefined` 3, `undefined` 1, `function` + `non-finite` 1,
  `global` 5 (`moment(...)` in `scale.time`, a canvas in `element.point/point-style-image.js`).
- 29 of them have a `run` hook. 6 replace private members of the animator
  (`Chart.animator._refresh`, `_update`, `_getAnims`): `controller.bar/bar-animation-hide-show.js`,
  `controller.doughnut/doughnut-animation.js`, `doughnut-animation-hide-last.js`,
  `controller.polarArea/last-slice-animate.js`, `polar-area-animation-rotate.js`,
  `polar-area-animation-scale.js`. 4 call `jasmine.triggerMouseEvent` (the 3 `core.interaction`
  fixtures and `controller.doughnut/event-replay.js`). 8 draw the chart canvas into a second
  canvas with `drawImage` (image composition only): the 6 animator hooks, `event-replay.js` and
  `controller.doughnut/doughnut-rotation-circumference-8x8.js`. The other 18 hooks call only
  public chart members. No hook of a ported prefix reads
  `chart.tooltip`, `chart.legend` or another phase 8 member.
- `json.options` keys over the 519 data configs: `canvas` 379, `spriteText` 188,
  `useOffscreenCanvas` 1 (`controller.line/point-style-offscreen-canvas.json`). No fixture sets
  `wrapper`. Top-level keys: `threshold` 49, `description` 43, `tolerance` 30, `debug` 4.
- The fixture groups at the pin (`manifest.json` `fixtureGroups`): one
  `describe('auto', jasmine.fixture.specs(<prefix>))` in 27 spec files. `helpers.canvas` (prefix
  `helpers`) and `plugin.decimation` match 0 fixtures. The regex is not escaped: `scale.time` also
  runs the 12 `scale.timeseries` fixtures.

## 1. Where the runner lives and where the spec files call it

### Options

| | Form | Code of our own | Structure |
|---|---|---|---|
| A (upstream) | `src/fixture.js` in the harness; `test/index.js:15-17` puts it on `jasmine.fixture`; each spec file has `describe('auto', jasmine.fixture.specs('<prefix>'))` | — | — |
| B (existing docs) | `packages/chartjs_test_utils/lib/src/fixture.dart` with `specsFromFixtures`; `src/index.dart` re-exports it (`index.js:5`); `flutter.dart` exports it. Each spec file calls `group('auto', specsFromFixtures('<prefix>', ...))` at the upstream line. ADR 0022 (open questions, `fixture.dart` imports `utils.dart` with the prefix `utils`) and porting-flow.md §3 table | 1 file, about 90 lines | same split as upstream |
| C | One port-only file `test/specs/fixtures_test.dart` that runs all prefixes | 1 file | breaks the upstream split |
| D | A runner in `packages/flutter_chartjs/test/` (not in the harness) | 1 file | moves `src/fixture.js` out of the harness port |

C fails tool 5: `compareCases` maps each Dart file to one upstream spec file
(`tool/src/spec_cases.dart:632-642`). `fixtures_test.dart` has no upstream spec file, so tool 5
reports "no upstream spec file". A fixture test is known only in the `auto` group of its own spec
file (`spec_cases.dart:144-150`). D breaks the `src/` target of chartjs-test-utils in
`tool/port_sources.yaml` and the porting-flow.md §3 table.

### Choice: B

- `packages/chartjs_test_utils/lib/src/fixture.dart`, header
  `// Ported from chartjs-test-utils v0.4.0 src/fixture.js (MIT, chartjs-test-utils Contributors).`
  The mapped path of the existing `src/` target. No tool change.
- `lib/src/index.dart` replaces the comment `// index.js:5 ... phase 7.` with
  `export 'fixture.dart' show specsFromFixtures;`. `lib/flutter.dart` adds `specsFromFixtures` to
  its `show` list of `src/index.dart`.
- `fixture.dart` imports `utils.dart` with the prefix `utils` and calls `utils.acquireChart` and
  `utils.releaseChart`, as `fixture.js:1` imports `_acquireChart` and `_releaseChart` (Chart.js ADR
  0022, open questions). A fixture chart thus does not enter the registry `charts`.
- The `test/index.js:15-17` line has no Dart form: Dart has no `jasmine` global. The spec file
  imports the function from `package:chartjs_test_utils/flutter.dart`. The comment at
  `test/flutter_test_config.dart` ("index.js:15-19 ... the specs import them") already says this.

Spec call, at the upstream line of each spec file:

```dart
group('Chart.controllers.bar', () {
  // controller.bar.tests.js:2 describe('auto', jasmine.fixture.specs('controller.bar')).
  group('auto', specsFromFixtures('controller.bar', hand: handFixtures));
  // ...
});
```

The `hand` argument is the one addition to the upstream call (section 2). It keeps the 128 hand
files out of the compile of the about 125 test files without a fixture group: 144 test files
exist in `flutter_chartjs` today, and 20 spec files get a fixture group in phase 7.

Consequences for the spec files of phase 7:
- 19 spec files get the line: the 7 controller files, `core.datasetController`,
  `core.interaction`, `core.layouts`, `core.scale`, `element.line`, `element.point`, `mixed`,
  `scale.category`, `scale.linear`, `scale.logarithmic`, `scale.radialLinear` and `scale.time`.
  `helpers.canvas_test.dart` also gets the line for the structure. It is `@TestOn('vm')` already,
  and the prefix `helpers` matches 0 fixtures, so it makes no test.
- `test/specs/mixed_test.dart` is new: `mixed.tests.js` has the fixture group and 2 chart cases
  (`mixed.tests.js:4`, `:25`). The classification of the Scout does not list these 2 cases.
- A pure-layer spec file with a fixture group moves to `@TestOn('vm')` and `flutter_test`
  (AGENTS.md Tests). `core.datasetController`, `core.interaction`, `core.layouts` and
  `element.line` move in phase 7 anyway (their chart cases get `phase7`). `element.point_test.dart`
  moves only because of its 12 fixtures. Its 4 pure cases then leave the two web legs. The
  element tests of `test/port/elements/` keep the web coverage of `element.point`.

## 2. The source of the configs, the hand-port form and the header rule

### Options for the source

| | Form | Evidence |
|---|---|---|
| A (upstream) | Load each `.js` or `.json` file at run time (`fixture.js:3-33`, `new Function(...)` for `.js`) | Dart cannot evaluate JavaScript. Only the 140 `.json` files could load this way. |
| B (tool 4, porting-flow.md §4 item 7) | The 401 data configs from the committed `doc/upstream/fixtures.json`, the list from `doc/upstream/manifest.json`, and the 128 hand ports in `test/fixtures/hand/` | The prototype runs 204 data configs with this form (`probe1.json`, 0 failures). |
| C (faster to load) | Generate Dart `const` Maps of the 401 data configs | 292 KB of literals in each spec file compile, plus a tool 4 change. The JSON decode that it saves is small: 6 calls that each decode both files take 76 ms in all (`PROBE decode ms 76`), about 13 ms for each spec file. |
| D (fewer hand ports) | Tool 4 writes tagged JSON for `NaN`, `Infinity` and `undefined` (for example `{"$js": "NaN"}`) | Saves 13 hand files (about 370 upstream lines). Costs a tag format in tool 4 (Node.js) and a decoder in the runner: one more concept. |

### Choice: B, no generated code, no tag format

The runner reads both JSON files once for each call (one call for each spec file), relative to
the working directory of `flutter test` (the package root). The manifest gives the complete list
and the `data` flag. Thus a fixture with `data: false` and no hand port fails loudly. A fixture
cannot silently disappear. The submodule is not read at run time.

### Options for the hand-port form

| | Form | Rule 2 header |
|---|---|---|
| A | One Dart file for each upstream fixture file, at the mapped path, with a top-level function `fixture()` that returns the `json` object. One port-only index file with a `const` Map from the path to the tear-off | Each file names its one source. `check:headers` maps it with a new data target. |
| B | One registry file for each prefix (21 configs in `controller.bar.dart`) | A header names one source. 21 sources in one file break rule 2 and the mechanical map. |
| C | JSON for the data part plus a Dart patch of the functions only | Two places to compare with one upstream file, and a merge that must keep the key order (`doc/upstream/README.md`: "The key order of a config can change the result of Chart.js"). |

### Choice: A

- Path: `test/fixtures/<path>.js` maps to
  `packages/flutter_chartjs/test/fixtures/hand/<path>.dart`. The folder name `hand/` is the name
  of porting-flow.md §1 step 6. All `.json` fixtures are pure data, so no `.json` source needs a
  map.
- `check:headers` needs no code. `PortTarget.map` (`tool/src/port_headers.dart:116-133`) changes
  the last extension to `.dart`, and `sourcesOf` (`:141-155`) gives the `.js` candidate. Add one
  target to the Chart.js entry of `tool/port_sources.yaml`:

  ```yaml
      - source: test/fixtures/
        dart: packages/flutter_chartjs/test/fixtures/hand/
  ```

  Without the submodule, `check:headers` reports the fixture headers as "not in the files ... and
  third_party/Chart.js is not checked out" (`port_headers.dart:985-993`). The CI job
  `port-checks` checks out the submodule. `check:port` already needs it for `parity:check`.
- 68 of the 128 file names fail the `file_names` lint (hyphens or capitals, for example
  `issue-9105`, `drawActiveElementsOnTop-false`). These files carry
  `// ignore_for_file: file_names` below the header, the form of Chart.js ADR 0012 (`simpleArc`)
  and D3 ADR 0002.
- The index `test/fixtures/hand/index.dart` is port-only
  (`// Original code, not ported from Chart.js: the index of the hand-ported fixture configs.`).
  No upstream file maps to it.
- `check:js-semantics` examines these files, because their header names a `js` project. The
  `% 4`, `Math.floor` and similar forms of the run hooks follow tool 3 (`jsFloor`, or
  `// js-ok: <reason>` for an image grid index).
- Each file ports the whole upstream file, with its comments, in source key order. The top-level
  statements of the module (for example `const canvas = document.createElement('canvas')` in
  `event-replay.js:9-12`) go into `fixture()`, because `fixture.js:24` runs the module again for
  each test.

Hand file sketch (`controller.bar/backgroundColor/scriptable.js:1-51`):

```dart
// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.bar/backgroundColor/scriptable.js (MIT, Chart.js Contributors).
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';

/// The fixture config: `module.exports` of the upstream file.
Map<String, Object?> fixture() => {
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'labels': [0, 1, 2, 3, 4, 5],
      'datasets': [
        <String, Object?>{
          // option in dataset
          'data': [0, 5, 10, null, -10, -5],
          'backgroundColor': (Object? ctx) {
            final value = _or(
              jsGet(jsGet(jsGet(ctx, 'dataset'), 'data'), jsGet(ctx, 'dataIndex')),
              0,
            );
            // ...
          },
        },
        // ...
      ],
    },
    // ...
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
};
```

Index sketch:

```dart
// Original code, not ported from Chart.js: the index of the hand-ported fixture configs.
import 'controller.bar/backgroundColor/scriptable.dart' as bar_background_color_scriptable;
// ... one import for each hand file

/// The hand-ported fixture configs, by the path relative to `test/fixtures/`.
const Map<String, Map<String, Object?> Function()> handFixtures = {
  'controller.bar/backgroundColor/scriptable.js': bar_background_color_scriptable.fixture,
  // ...
};

/// The fixtures that skip, by path, with a skip reason of porting-flow.md §1 step 5.
const Map<String, String> fixtureSkips = {};
```

## 3. Test names and tool 5

### Options

| | Name | Tool 5 |
|---|---|---|
| A (upstream) | The Karma URL, `/base/test/fixtures/controller.bar/aligned-pixels.js` (`fixture.js:37-38`) | accepted (`spec_cases.dart:153-156`) |
| B (tool 4 README) | The path relative to `test/fixtures/`, `controller.bar/aligned-pixels.js` | accepted (`spec_cases.dart:144-150`) |

### Choice: B

The relative path is the key of `fixtures.json`, of the manifest `path` and of `handFixtures`. One
string names the fixture everywhere. The test is directly in the `auto` group, with no extra
group: the group path must equal the `describe` path of the manifest fixture group
(`spec_cases.dart:150`). Tool 5 then counts the test as a fixture test ("+N fixture tests",
`spec_cases.dart:795`) and never reports an unknown name.

A skipped fixture is a plain `test(path, () {}, skip: reason)`, as for a skipped case
(`doc/upstream/README.md`, "Dart test names for tool 5"). Tool 5 does not validate the reason of a
fixture test. The runner keeps the three reason forms anyway.

Known limit, no change in this draft: tool 5 does not report a failed fixture test
(`spec_cases.dart:657-660` only counts it). `flutter test` and thus `test --no-select` fail on it
(section 4).

## 4. Tag, melos scripts, CI job, submodule skip

### Options

| | Form | Code and config | Run cost |
|---|---|---|---|
| A (porting-flow.md §3 "Fixture selection", kickstart scope) | `@Tags(['fixtures'])`, `dart_test.yaml` with the tag, `--exclude-tags fixtures` in the melos `test` script, `test:fixtures`, CI job `fixtures` with a submodule checkout, a skip without the submodule, `FIXTURES_REQUIRED=1` to fail instead | tag, `dart_test.yaml`, melos edit, new melos script, new CI job, a submodule probe and an environment rule in the runner | fixtures run once, on ubuntu |
| B (simplicity) | Fixtures run in every `flutter test` of the package. The tag stays only to select them (`test:fixtures`). No exclusion, no new CI job, no submodule probe, no `FIXTURES_REQUIRED` | the `tags:` argument, `dart_test.yaml` (2 lines), one melos script | fixtures run on 3 OS legs, and again in `test:cases` and `parity` |
| C (no tag) | As B, and `test:fixtures` selects with `--name` | no `dart_test.yaml` | as B, but the name filter is fragile: the full name "... auto ..." also matches `autoSkip` cases |

The reason for the skip rule of A is gone. Porting-flow.md §3 lets a fixture test skip "when the
submodule is absent", because the runner was to read the submodule. With the committed
`fixtures.json` and `manifest.json` (section 2), no fixture test reads the submodule. The
`upstream-manifest` job already fails when these files differ from the pin.

A also leaves a gap: tool 5 runs `flutter test --reporter json test/specs` with no tag filter
(`tool/spec_cases.dart:69-74`). It thus runs the fixtures in the ubuntu `test` leg anyway, but it
does not fail on a failed fixture (section 3). The A job is then a second run of the same tests on
the same OS.

Run cost, measured on this Mac (macOS, `flutter test`, Flutter 3.44.9):
- The whole `flutter_chartjs` suite today: 5,796 tests, 30.3 s wall, 51.4 s of test time
  (`full_suite.json`).
- The prototype: 204 data fixtures (with the `scaleTest` proxy controller), 1.53 s of test time,
  median 6 ms, p90 9 ms, one outlier of 225 ms (the first chart of the file). 3.6 s wall for the
  file with its compile (`probe1.json`).
- Estimate for the 529 fixtures of phase 7 at the proxy cost: about 4 s of test time, 8% of the
  suite. The real controllers draw more than the proxy. The phase 7 step 4 measures the real
  figure.

### Choice: B, with a fallback rule

- `packages/flutter_chartjs/dart_test.yaml`:

  ```yaml
  tags:
    fixtures:
  ```

- The runner gives each fixture test `tags: 'fixtures'`.
- Melos: `test:fixtures` runs
  `cd packages/flutter_chartjs && flutter test --tags fixtures test/specs`. The `test` script does
  not change.
- CI: no change. The 3 `test` legs run the fixtures through `test --no-select`. The ubuntu leg
  runs them again through `test:cases`.
- The runner has no submodule probe and reads no environment variable.
- Fallback rule (for the judge): when the real fixtures of phase 7 add more than 20% to the test
  time of the slowest `test` leg, add `--exclude-tags fixtures` to the melos `test` script and run
  `test:fixtures` in the ubuntu `test` leg. That is one line in each place and still no submodule
  rule.

Deviation from the kickstart: its scope names the CI job `fixtures` and `FIXTURES_REQUIRED=1`, and
its exit criteria say "also in the CI job `fixtures`". With B, the `test` job is the CI gate of
the fixtures. The ADR records the change, and porting-flow.md §3 "Fixture selection", §3 "Where
tests run" (the row "Fixture smoke tests") and §5.2 (`--exclude-tags fixtures`, the `fixtures`
job) change with it.

## 5. Which fixtures pass in phase 7, the phase 8 rule, "one frame"

### Scope

The fixtures that the 20 spec-file calls of section 1 match: 529 (table of section 0). They must
pass. The 138 `plugin.*` fixtures wait for the plugin spec files of phase 8, which make the calls.

### A fixture of a ported prefix and the plugins of phase 8

The plugin rule (`fixture.js:45-48`) gives `options.plugins = false` unless the path contains
`plugin` or `config.plugins` is set. `plugins: false` gives no plugin descriptor
(`core.plugins.js:104-106`). The probe (`plugins_probe.out`) gives these results for the data
configs of the ported prefixes:
- 313 built configs keep no plugin. 34 keep plugins on, because `options.plugins` is an object
  (38 in `fixtures.json`; the probe could not build 4 of them, see below).
- Of the 34, 25 draw a phase 8 plugin upstream: the filler 13 (for example
  `controller.line/fill/value.js`), the title 11 (the `controller.polarArea/pointLabels/withTitle/*`
  fixtures) and the legend 1 (`core.layouts/refit-vertical-boxes.js`).
- 54 configs did not build in the probe: 50 need the moment adapter, which the probe did not load,
  and 4 have non-ASCII text, which the Liberation Sans mock of `scale_chart_common.mjs` does not
  measure. These are limits of the probe, not of the fixtures.
- In the hand configs, 22 files contain the word `plugins`. No run hook reads a phase 8 member.

Options:

| | Rule | Code |
|---|---|---|
| A | Skip every fixture that reaches a phase 8 plugin upstream, as `'blocked: plugin.<id>'` | a list of 25+ paths that a probe computes, and a new list at each bump |
| B | Run each fixture with the components that the registry has. Skip only a fixture that throws because a phase 8 module is absent | an empty `fixtureSkips` Map |

Choice: B. Without the plugin, the chart has no title, legend or fill area. The upstream code
does not throw in that case: `core.datasetController.js:288` only warns for `fill`. The smoke
test asserts only "no exception". When phase 8 registers the plugins, the same 25 fixtures
exercise them with no change to the runner or to the configs. A fixture that throws because of an
absent phase 8 module gets an entry in `fixtureSkips`, for example
`'controller.x/y.js': 'blocked: plugin.tooltip'`. The prediction for phase 7 is 0 entries.

### "One frame" in the harness

Upstream: `_acquireChart` builds the chart, and with `animation: false` the chart draws in its
constructor. Then the `run` hook, then `_done` compares the image and releases the chart, also
when `run` rejects (`Promise.resolve(run(chart)).finally(_done)`, `fixture.js:63-68`).

Port, in the body of one `testWidgets` test:
1. `utils.acquireChart(config, json['options'])`. The chart is attached and has drawn into the
   recording canvas (Chart.js ADR 0022 §4).
2. `await run(chart)` when `run` is a `FutureOr<void> Function(Chart)`.
3. `finally`: `await tester.pump()`, one frame with no time step. `RenderChartHost.paint`
   (`lib/src/platform/chart_host.dart:675`) replays the pictures of `UiCanvasElement.paint`
   (`lib/src/canvas/canvas_ui.dart:562-580`). Thus the frame runs the `dart:ui` paint path. An
   exception in the frame fails the test through flutter_test. Then `utils.releaseChart(chart)`.

The `finally` keeps `fixture.js:65` (`.finally(_done)`): the release also runs when the hook
throws. A frame of 16 ms is not needed: the frame paints at the current fake time. A hook that
needs time pumps it itself (section 6).

## 6. Fixture options

| Key | Upstream use | Port |
|---|---|---|
| `json.options.canvas` | `_acquireChart` sets the canvas attributes (`utils.js:41-49`) | passed through to `acquireChart` (it exists) |
| `json.options.wrapper` | wrapper attributes (`utils.js:42`) | passed through; no fixture sets it |
| `json.options.spriteText` | `spritingOn(ctx)` (`utils.js:90-92`) | ignored by `acquireChart`: no image (row `harness-acquire-chart`) |
| `json.options.useOffscreenCanvas` | `utils.js:77` | passed through; `acquireChart` gives a canvas that no host shows (1 fixture) |
| `json.options.run` | `fixture.js:63-68` | called and awaited; only hand configs have it |
| `json.options.persistent` | `utils.js:100` | passed through; no fixture sets it |
| `json.threshold`, `json.tolerance` | `toEqualImageData` (`matchers.js:181-182`) | ignored: no image comparison (Chart.js ADR 0009 §4) |
| `json.description`, `json.debug` | the failure message, the image dump | ignored |

The run hooks in the hand ports:
- 18 hooks call only public chart members (`update`, `hide`, `show`, `toggleDataVisibility`,
  `setActiveElements`, `draw`, a write of `chart.data`). They port line by line.
- 4 hooks call `jasmine.triggerMouseEvent`. They call `triggerMouseEvent` of the harness, which
  pumps until the event callback ran.
- 8 hooks copy the canvas into a second canvas with `drawImage`, and one draws a grid on it. The
  port omits these lines: they make only the image. The chart calls between them stay, for
  example the 64 `chart.update()` calls of `doughnut-rotation-circumference-8x8.js:39-49`.
- 6 hooks stop the animator loop (`animator._refresh = function() {}`) and call
  `animator._update(start + i * step)` for each image. The Dart animator keeps these members
  private (`lib/src/core/core.animator.dart:161`, `:186`). The port runs the same animation on the
  fake clock: `await pumpFrames(() => !Chart.animator.running(chart))`. The animator then calls
  its own update at each frame of 16 ms. Each animation step of the hook (`hide`, `show`,
  `toggleDataVisibility`) keeps its place.

These omissions and replacements need one row in `differences.md`, `fixture-run-hooks`
(category `harness`), and one `// DIVERGES(chartjs): fixture-run-hooks, <reason>` marker at each
changed hook. The row states: no image composition (Chart.js ADR 0009 §4), and the animator steps
come from frames on the fake clock, not from calls of the private members.

## 7. Code form of the runner

```dart
// Ported from chartjs-test-utils v0.4.0 src/fixture.js (MIT, chartjs-test-utils Contributors).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chartjs_test_utils/src/utils.dart' as utils;
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fixture config: the `json` object of `fixture.js:39`.
typedef FixtureConfig = Map<String, Object?>;

/// fixture.js:73 `specsFromFixtures(path)`.
///
/// The fixture list is the manifest of tool 4 (`doc/upstream/manifest.json`,
/// the `__karma__.files` of fixture.js:77). A data config comes from
/// `doc/upstream/fixtures.json`. [hand] gives the configs that JSON cannot
/// hold. [skip] gives the skip reason of a fixture. [upstream] is the folder
/// of the two files, relative to the working directory.
void Function() specsFromFixtures(
  String path, {
  Map<String, FixtureConfig Function()> hand = const {},
  Map<String, String> skip = const {},
  String upstream = 'doc/upstream',
}) {
  // fixture.js:74: the prefix is a regular expression, not escaped.
  final regex = RegExp('^$path.+\\.(json|js)');
  final manifest = _readJson('$upstream/manifest.json');
  final data = _readJson('$upstream/fixtures.json');
  final items = [
    for (final item in (manifest['fixtures']! as Map)['items']! as List)
      item as Map<String, Object?>,
  ];
  final known = {for (final item in items) item['path']};
  for (final key in [...hand.keys, ...skip.keys]) {
    if (!known.contains(key)) throw StateError('$key is not a fixture of the pin.');
  }
  return () {
    for (final item in items) {
      final input = item['path']! as String;
      if (!regex.hasMatch(input)) continue;
      final reason = skip[input];
      if (reason != null) {
        test(input, () {}, skip: reason);
        continue;
      }
      final load = hand[input] ??
          (item['data'] == true ? () => _copy(data[input]) : null);
      specFromFixture(input, load);
    }
  };
}

/// fixture.js:36 `specFromFixture(description, inputs)`.
void specFromFixture(String input, FixtureConfig Function()? load) {
  testWidgets(input, (tester) async {
    if (load == null) {
      fail('$input is not pure data, and test/fixtures/hand/ has no port of it.');
    }
    final json = load();
    final config = json['config']! as Map<String, Object?>;
    final options = (jsTruthy(config['options'])
        ? config['options']
        : config['options'] = <String, Object?>{})! as Map<String, Object?>;

    // plugins are disabled by default, except if the path contains 'plugin'
    // or there are instance plugins
    if (!input.contains('plugin') && identical(jsGet(config, 'plugins'), undefined)) {
      options['plugins'] = jsTruthy(options['plugins']) ? options['plugins'] : false;
    }

    final fixtureOptions = json['options'] as Map<String, Object?>?;
    final chart = utils.acquireChart(config, fixtureOptions);
    try {
      final run = fixtureOptions?['run'];
      if (run is FutureOr<void> Function(Chart)) await run(chart);
    } finally {
      // fixture.js:51-62 `_done`: no image comparison (Chart.js ADR 0009). One
      // frame paints the recorded canvas.
      await tester.pump();
      utils.releaseChart(chart);
    }
  }, tags: 'fixtures');
}
```

`_readJson` is `jsonDecode(File(path).readAsStringSync())`. `_copy` is
`jsonDecode(jsonEncode(value))`, a new tree for each test, because the chart writes into its
config. `jsonDecode` keeps the key order and gives `int` for an integral number, the same form as
the literals of the ported specs. The prototype ran 204 configs from `jsonDecode` through
`acquireChart` with no error.

## 8. Files that the implementation changes

New:
- `packages/chartjs_test_utils/lib/src/fixture.dart` (the runner, section 7).
- `packages/chartjs_test_utils/test/fixture_test.dart` (`@TestOn('vm')`, port-only tests below).
- `packages/flutter_chartjs/test/fixtures/hand/<path>.dart`: 128 files (section 2).
- `packages/flutter_chartjs/test/fixtures/hand/index.dart`: `handFixtures`, `fixtureSkips`.
- `packages/flutter_chartjs/test/specs/mixed_test.dart`: the port of `mixed.tests.js`.
- `packages/flutter_chartjs/dart_test.yaml`: the tag `fixtures`.
- `packages/flutter_chartjs/doc/adr/0029-fixture-smoke-runner.md` (proposed).

Changed:
- `packages/chartjs_test_utils/lib/src/index.dart`: `export 'fixture.dart' show specsFromFixtures;`
  in place of the phase 7 comment.
- `packages/chartjs_test_utils/lib/flutter.dart`: export `specsFromFixtures`, and its doc.
- The 19 spec files of section 1 (and `helpers.canvas_test.dart`): the `group('auto', ...)` line.
  `element.point_test.dart` moves to `@TestOn('vm')` and `flutter_test`.
- `packages/flutter_chartjs/tool/port_sources.yaml`: the target `test/fixtures/` to
  `packages/flutter_chartjs/test/fixtures/hand/`.
- `pubspec.yaml` (root): the melos script `test:fixtures`.
- `packages/flutter_chartjs/doc/differences.md`: the row `fixture-run-hooks`.
- `packages/flutter_chartjs/doc/status.yaml`: the row of `src/fixture.js` (chartjs-test-utils), the
  rows of the spec files, `mixed.tests.js`. Then `dart run melos run parity`.
- `packages/flutter_chartjs/doc/porting-flow.md`: §1 step 6, §3 table row of `src/fixture.js`,
  "Where tests run", "Fixture selection", §4 item 7, §5.2.
- `AGENTS.md`: Commands (`test:fixtures`), Layout (`test/fixtures/hand/`), Tests (the `auto`
  group, the hand-port header map).
- `packages/flutter_chartjs/test/flutter_test_config.dart`: the comment at `index.js:15-19`
  names `specsFromFixtures` as done.

No change: `.github/workflows/ci.yaml`, the melos `test` script, tool 4, tool 5, tool 2 code.

## 9. Tests that pin the decision

In `packages/chartjs_test_utils/test/fixture_test.dart`, with a small `manifest.json` and
`fixtures.json` in a temporary folder (the `upstream` argument), and the test controller of a
registered type:
- **prefix match:** `specsFromFixtures('scale.time')` makes the tests of `scale.time/...` and
  `scale.timeseries/...`. The prefix `a.b` also matches `aXb/...` (the regex of `fixture.js:74`
  is not escaped). A path equal to the prefix with no rest does not match (`.+`).
- **names:** each test name is the path relative to `test/fixtures/`, directly in the calling
  group, with the tag `fixtures`.
- **plugin rule:** a config with no `plugins` gets `options.plugins == false`; a path with
  `plugin` keeps `options.plugins` absent; `config.plugins` set keeps it; an object
  `options.plugins` stays the object (`fixture.js:46-47`).
- **run hook:** an async `run` completes before the frame; a throwing `run` fails the test, and
  the chart is still destroyed and its wrapper leaves the body (`.finally`, `fixture.js:65`).
- **sources:** a `hand` entry wins over a data config; a `data: false` fixture with no hand port
  fails with the message of section 7; a `skip` entry gives a skipped `test` with its reason; a
  `hand` or `skip` key that is not in the manifest throws a `StateError` at the call.
- **options:** `canvas` sets the canvas size; `useOffscreenCanvas` gives a chart that no host
  shows; `spriteText`, `threshold` and `tolerance` change nothing.

In `packages/flutter_chartjs`:
- The 529 fixture tests themselves, in the `auto` groups of the 20 spec files, through
  `test --no-select` and `test:cases` (tool 5 prints "+529 fixture tests" over the spec files).
- `check:headers` over `test/fixtures/hand/` (the mapped paths and the pin).
- `test/tool/` (existing tests of tool 2): one case that `PortTarget.map` of the new target maps
  `test/fixtures/controller.bar/stacking/issue-9105.js` to
  `packages/flutter_chartjs/test/fixtures/hand/controller.bar/stacking/issue-9105.dart`, and that
  `sourcesOf` gives it back.
