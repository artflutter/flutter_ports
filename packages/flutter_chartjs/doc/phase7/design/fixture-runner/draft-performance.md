# Fixture smoke runner: draft with the lens PERFORMANCE FIRST

- Panel: "Fixture smoke runner" (future Chart.js ADR 0029), phase 7, step 2 (Design).
- Lens: find the fastest forms that keep the behavior that Chart.js ADR 0009 protects, and measure
  them.
- Pin: Chart.js v4.5.1+7169e651, chartjs-test-utils v0.4.0, repository commit `4eda459`.
- Machine of the figures: Apple M3 Max, macOS, Flutter 3.44.9, Dart 3.12.2. The Node.js probe ran
  in the x64 Node.js v24.12.0 under Rosetta (Chart.js ADR 0010), against the build of the pinned
  commit.
- Scripts and raw output: `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/fixture-runner-performance/`
  (below: `<perf>`).

## 0. Summary of the scope and of the performance question

The runner is test code. No choice of this draft changes a file in `lib/`. Thus no choice changes
the frame rate, the draw time or the raster time of a chart (priority 2 of `porting-flow.md`
§1.1). The figures of this draft are wall times of `flutter test` and of the CI jobs. They rank
forms that are equal on priorities 1 and 3. Where a faster form changes the upstream structure,
this draft keeps the upstream structure and records the cost of that choice.

The fixtures at the pin (`doc/upstream/manifest.json`, `summary`):

| Set | Fixtures | Pure data | Impure | Impure with a function |
|---|---|---|---|---|
| All prefixes | 667 | 519 | 148 | 128 |
| Prefixes of phase 7 (not `plugin.*`) | 529 | 401 | 128 | 110 |
| `plugin.*` (phase 8) | 138 | 118 | 20 | 18 |

The other 18 impure configs of phase 7 have no function. Their reasons are `non-finite` (NaN),
`undefined` or `global` (a `moment(...)` value).

Probe P0 (`<perf>/probe_fixtures.mjs`, output `<perf>/all.json`) runs each of the 667 fixtures as
`specFromFixture` does: the loader of `fixture.js:24`, the plugin rule of `fixture.js:46-48`, the
defaults of `_acquireChart` (`utils.js:36-105`) and the `run` hook (`fixture.js:63-68`). It
records the canvas calls instead of an image. In the mode `all` (all registerables, colors off as
`test/index.js:25-28`), the 529 fixtures of phase 7 give no exception. Their total run time in
Node.js is 1,459 ms. The slowest is `controller.line/fill/no-border.js` with 53 ms.

## 1. Where the runner lives, and where the spec files call it

### Options

| Form | Where | Call site in a spec file |
|---|---|---|
| A. Upstream | `src/fixture.js`, re-exported by `src/index.js:5` (`export * from './fixture'`). `test/index.js:15-17` sets `jasmine.fixture = {specs: specsFromFixtures}` | `describe('auto', jasmine.fixture.specs('controller.bar'))` at line 2 of each spec file |
| B. Existing docs | `porting-flow.md:612`, Chart.js ADR 0022 (line 1061): `fixture.dart` imports `utils.dart` with the prefix `utils` and calls `utils.acquireChart` and `utils.releaseChart`. Chart.js ADR 0030 §13 item 3 (proposed): the `auto` group stays at its upstream position, with the tag `fixtures` | `group('auto', ...)` in the spec file |
| C. Faster | One file `test/fixtures/fixtures_test.dart` that runs all groups | none: the spec files keep the comment of a fixture group |

### Evidence

Probe P1 (`<perf>/files_bench.txt`, test files in `<perf>/ws/packages/flutter_chartjs/test/files/`
and `test/single/`). Each test acquires a chart of the scale test controller and pumps one frame.
460 tests in 20 files against the same 460 tests in 1 file. Each run changed every file first.

| Run | 20 files | 1 file |
|---|---|---|
| `flutter test -j 4 --tags fixtures` | 6.58 s, 6.39 s, 6.24 s | 4.24 s, 4.20 s, 4.39 s |
| `flutter test -j 1 --tags fixtures` | 17.91 s, 17.28 s, 16.67 s | 4.68 s, 4.31 s, 4.35 s |

One more test file costs 0.68 s with `-j 1` ((17.28 - 4.35) / 19). With `-j 4`, form C saves
2.1 s for each run of the fixture job. In the default `test` run, form C costs one more file
(0.68 s with `-j 1`) that runs no test, because `--exclude-tags fixtures` skips all its tests.

Form C changes the upstream structure. It also needs a map from the fixture file to the spec files
in tool 5 (Chart.js ADR 0030 §16 item 2), because tool 5 accepts a fixture test only in a fixture
group of its spec file (`tool/src/spec_cases.dart:24-30`, `:141-151`). The gain is CI time only,
not a frame figure. Thus priority 3 decides.

### Choice: form B

- `packages/chartjs_test_utils/lib/src/fixture.dart`, the port of `src/fixture.js`. Header:
  `// Ported from chartjs-test-utils v0.4.0 src/fixture.js (MIT, chartjs-test-utils Contributors).`
  It imports `utils.dart` with the prefix `utils` (Chart.js ADR 0022). It is not a pure layer: it
  imports `flutter_test` and `dart:io`.
- `lib/src/index.dart` replaces the comment `index.js:5 ... phase 7` with
  `export 'fixture.dart' show FixtureRun, HandFixture, fixturesTag, specsFromFixtures;`.
  `lib/flutter.dart` adds the same names to its `show` list of `src/index.dart`. `lib/pure.dart`
  does not export it.
- The spec files call it through `test/fixtures/index.dart` (section 2), imported with the prefix
  `fixture`. Thus the call has the upstream form:

```dart
import '../fixtures/index.dart' as fixture;

void main() {
  group('Chart.controllers.bar', () {
    group('auto', fixture.specs('controller.bar'));
    // the cases of the spec file
  });
}
```

`fixture.specs` stands for `jasmine.fixture.specs` (`test/index.js:15-17`). The call goes to line 2
of the `describe` body, as upstream. It replaces the comment of a fixture group in the 12 earlier
spec files (`core.datasetController`, `core.interaction`, `core.layouts`, `core.scale`,
`element.line`, `element.point`, `helpers.canvas`, `scale.category`, `scale.linear`,
`scale.logarithmic`, `scale.radialLinear`, `scale.time`). The 7 controller spec files and the new
`mixed_test.dart` get it at line 2. `helpers.canvas` matches 0 fixtures and gets the call for the
structure.

Cost of form B: 2.1 s for each run of the fixture job with `-j 4` (P1). `element.point_test.dart`
moves to `@TestOn('vm')` and `flutter_test` (AGENTS.md, Tests). Its 4 pure cases leave the web
legs. `test/port/elements/element.point_test.dart` stays pure and keeps the web legs of the module
(Chart.js ADR 0030 §13 item 3). The other 4 pure spec files (`core.datasetController`,
`core.interaction`, `core.layouts`, `element.line`) move in phase 7 anyway: their chart cases that
skip as `'blocked: controller.*'` (71 in the 4 files) get bodies.

## 2. The source of the configs, the hand-ported configs and their headers

### Options

| Form | Data configs | Configs with functions |
|---|---|---|
| A. Upstream | `readFile` of the Karma URL (`fixture.js:3-13`), then `new Function('"use strict"; var module = {};' + content + '; return module.exports || fixture;')()` or `JSON.parse` (`fixture.js:15-34`) | the same: JavaScript runs |
| B. Existing docs | `porting-flow.md:868-872`: the configs that tool 4 writes (`doc/upstream/fixtures.json`) and the hand-ported configs in `test/fixtures/hand/`. `porting-flow.md:729-733`: a shallow submodule checkout | hand ports, form open |
| C1. Faster? | a Dart file that a generator writes from `fixtures.json`: one builder closure for each config | the same as B |
| C2. Faster? | one registry Map of closures for each prefix, no file for each fixture | the same Map |

### Evidence

Probe P2, the load of the configs (`<perf>/jsonbench/bin/bench.dart`; AOT binary
`<perf>/jsonbench/bench_aot`; JIT with `dart run`). The median of 7 samples.

| Step | AOT | JIT |
|---|---|---|
| J0 read `fixtures.json` (292 KB) | 0.66 ms | 0.68 ms |
| J1 `jsonDecode` of all 519 configs | 2.37 ms | 2.35 ms |
| J1m `jsonDecode` of `manifest.json` (549 KB) | 1.62 ms | 2.13 ms |
| J3 `jsonDecode` of each config line, 519 configs | 1.51 ms | 1.79 ms |
| J4 deep copy of 519 decoded configs | 1.04 ms | 0.98 ms |
| J5 generated Dart builder of each config, 519 configs | 0.44 ms | 0.86 ms |

J3 and J5 give equal trees for 519 of 519 configs. The decoded Map is a `_Map<String, dynamic>`.
It is a `LinkedHashMap<String, Object?>` at run time, and its key order is the source order. Thus
`acquireChart` and `Config` can write into it.

Probe P3, the compile cost of form C1 (`<perf>/compile_bench.txt`). The generated file of 519
configs has 467 KB of Dart.

| Run | Generated Dart | JSON |
|---|---|---|
| `flutter test` of one file, only the test file changed | 1.63 s, 1.61 s | 1.53 s, 1.52 s |
| `flutter test`, the generated file changed too | 1.62 s, 1.73 s, 1.69 s | 1.58 s, 1.59 s, 1.58 s |
| `dart compile kernel` | 0.25 s, 9.17 MB | 0.21 s, 8.22 MB |

Form C1 saves at most 3 µs for each fixture at run time. It costs 50-150 ms of compile in each test
file that imports it, in each run, also in the default run where the fixture tests do not run. Thus
the JSON form is faster in total. Form C1 also adds a generator.

Probe P4, the compile cost of the hand registry (`<perf>/hand_compile_bench.txt`, files in
`<perf>/ws/packages/flutter_chartjs/test/hand_probe/`). 118 stand-in hand libraries of 1.2 KB each,
the size of the real ones (5,844 lines for 128 configs at the pin):

| Run | Import of 118 libraries | Import of 6 libraries |
|---|---|---|
| `flutter test`, all hand files changed | 1.63 s, 1.71 s, 1.63 s | 1.53 s, 1.66 s, 1.55 s |

One import of the full registry costs about 0.1 s of compile for each test file. In the 20 spec
files that call the runner, this is about 2 s for each run with `-j 1`. In
`flutter_test_config.dart`, which `flutter test` compiles into each of the 144 test files of the
package, it is about 14 s. Form C2 (a registry for each prefix) saves the 2 s. It needs one more
index file for each prefix, and `scale.time` needs two (`scale.time` matches `scale.timeseries`).

### Choice

1. **Data configs:** `doc/upstream/fixtures.json` of tool 4, read at run time. The runner decodes the
   file once for each test file, at the first fixture body (a `late final` field), not at the
   declaration. The default `test` run thus never reads it.
2. **The list of fixtures:** `doc/upstream/manifest.json`, `fixtures.items`. The runner reads it
   once for each test file at the declaration (J0 + J1m: 2.3-2.8 ms for each spec file, 50 ms for
   the 20 files). The manifest gives each path, its `sha256`, its `png` and `data`. It replaces the
   Karma file list of `fixture.js:77-86`.
3. **No submodule.** Both files are committed. The CI job `upstream-manifest` keeps them equal to
   the pin. Thus the runner never reads `third_party/` (section 4).
4. **Hand ports: one Dart file for each fixture** (form B), at the mapped path:

   | Upstream | Dart |
   |---|---|
   | `test/fixtures/<path>.js` or `.json` | `test/fixtures/hand/<path>.dart` |

   Example: `test/fixtures/controller.bar/baseLine/mid-x.js` becomes
   `packages/flutter_chartjs/test/fixtures/hand/controller.bar/baseLine/mid-x.dart`. File and
   directory names keep the upstream spelling (Chart.js ADR 0012). 62 of the 118 names fail the
   `file_names` lint (a hyphen or a capital before the first dot). These files carry
   `// ignore_for_file: file_names` below the header lines (the `simpleArc` rule of Chart.js ADR
   0012). No two fixture paths have the same base name at the pin, so no two map to one Dart path.
5. **The header:** `// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.bar/baseLine/mid-x.js (MIT, Chart.js Contributors).`
   `tool/port_sources.yaml` gets one more target of the Chart.js entry:

   ```yaml
       - source: test/fixtures/
         dart: packages/flutter_chartjs/test/fixtures/hand/
   ```

   `PortTarget.map` (`tool/src/port_headers.dart:106-129`) then gives the Dart path without a
   change. `PortTarget.sourcesOf` (`:131-151`) gets `.json` in its candidate extensions, for a
   hand port of a `.json` config. REUSE.toml needs no change: `packages/flutter_chartjs/**` already
   lists the Chart.js holder.
6. **The registry:** `packages/flutter_chartjs/test/fixtures/index.dart`, a port-only file outside
   the mapped folder `hand/`. It imports each hand file and has the skip reasons of section 5:

```dart
// Original code, not ported from Chart.js: the registry of the fixture configs with functions, and the fixture skips.
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hand/controller.bar/baseLine/mid-x.dart' as controller_bar_baseLine_mid_x;
// ... one import for each of the 118 hand files

/// `jasmine.fixture.specs(path)` of Chart.js `test/index.js:15-17`.
void Function() specs(String path) =>
    specsFromFixtures(path, hand: handFixtures, skips: fixtureSkips);

/// The hand-ported configs by fixture path: the loader and the first 12 hex
/// digits of the sha256 of the upstream file (the `sha256` of the manifest).
final Map<String, HandFixture> handFixtures = {
  'controller.bar/baseLine/mid-x.js': (
    load: controller_bar_baseLine_mid_x.fixture,
    sha256: '0123456789ab',
  ),
  // ...
};

/// The fixtures that skip, by fixture path (section 5).
const Map<String, String> fixtureSkips = {
  'controller.line/fill/value.js': 'blocked: plugin.filler',
  // ...
};
```

   Only the spec files with a fixture group import the registry. `flutter_test_config.dart` never
   imports it (P4: 14 s). The single registry costs about 2 s of compile for each run with `-j 1`
   (P4). This draft keeps one registry (less code). If the hand count of phase 8 (138 configs in
   total) makes the cost larger than 4 s, a registry for each spec file is the faster form.
7. **The form of a hand file:** one top-level function `fixture()` that gives a new config for each
   call. `fixture.js:24` evaluates the module again for each load, so module-level state (the
   canvas of `doughnut-animation.js:1-4`) is new for each call too. The literals follow the forms
   of the ported specs: `<String, Object?>{...}` for each nested Map, closures for scriptable
   options, Maps of closures for inline plugins (`core.plugin_test.dart:136-138`), `double.nan` for
   `NaN`, `undefined` for `undefined`, and a `DateTime` of the same time value in UTC for a
   `moment(...)` value. The `run` hook is the entry `'run'` of the `options` Map.

```dart
// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.line/radius/scriptable-to-value.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
library;

import 'package:flutter_chartjs/src/core/core.controller.dart';

Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['A', 'B', 'C'],
      'datasets': <Object?>[
        <String, Object?>{'data': <Object?>[12, 19, 3]},
      ],
    },
    'options': <String, Object?>{
      'animation': <String, Object?>{'duration': 0},
      'backgroundColor': 'red',
      'radius': ([Object? _]) => 20,
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
    'run': (Chart chart) {
      (chart.options as Map<String, Object?>)['radius'] = 5;
      chart.update();
    },
  },
};
```

   The 6 animation fixtures (`controller.bar/bar-animation-hide-show.js`,
   `controller.doughnut/doughnut-animation.js`, `doughnut-animation-hide-last.js`,
   `controller.polarArea/last-slice-animate.js`, `polar-area-animation-rotate.js`,
   `polar-area-animation-scale.js`) read `Chart.animator._getAnims`, `_refresh` and `_update`.
   These members stay private in the port: only `core.animator.dart` reads them. The hand port
   advances the fake clock instead. `animator._update(start + i * 500)` becomes
   `await pumpFrame(const Duration(milliseconds: 500))`, one frame after 500 ms. The animator of the
   port updates in that frame at that time. `animator._update(Date.now() * 2)` becomes one frame
   after one day. `animator._refresh = function() {}` has no port: a frame runs only when the
   harness pumps. A `pumpFrames` loop is not the form here: 16 steps of 500 ms are 8,000 ms of fake
   time, after the Jasmine timeout of 5,000 ms of `pumpFrames` (`dom.dart:1251-1270`). The
   `drawImage` calls into a second canvas and `Chart.helpers.clearCanvas` only build the image of
   the PNG comparison. They are `n/a` (Chart.js ADR 0009 §4), with a comment at each site. Thus no
   choice changes `lib/`.

## 3. Test names and tool 5

### Options

| Form | Name of a fixture test |
|---|---|
| A. Upstream | `it(input, ...)` (`fixture.js:38`): the Karma URL `/base/test/fixtures/controller.bar/aligned-pixels.js` |
| B. Existing tool 5 | the config path relative to `test/fixtures/`, or the Karma URL, in the fixture group of the manifest (`tool/src/spec_cases.dart:24-30`, `:141-156`). `doc/upstream/README.md` "Dart test names for tool 5" names the relative path |

Tool 5 runs `flutter test --reporter json test/specs` (`tool/spec_cases.dart:148-150`). Tool 6
(`parity:check`) runs the same function. Without a change, both run all fixture tests (458 chart
tests) in each `test:cases` and each `parity:check`. The harness bench P5 below gives about 5.5 ms
for each such test, so at least 2.5 s for each run, plus the time of the real controllers.

### Choice

- The group path is the `describe` path of the spec file plus `auto`. The test name is the config
  path relative to `test/fixtures/` (`controller.bar/aligned-pixels.js`), with the extension. Tool
  5 accepts it without a change.
- A fixture that runs is a `testWidgets` test. A fixture that skips is a plain `test()` with a
  `skip:` string, as for a spec case (`testWidgets` takes only `skip: true`, and the JSON reporter
  then has no reason). Probe P6 (`<perf>/ws/packages/flutter_chartjs/test/bench/tags_probe_test.dart`)
  showed that the JSON reporter gives the `skipReason` and the tag selection for both forms.
- The order of the tests is the order of `fixtures.items` of the manifest. Upstream runs the
  insertion order of the Karma file list (`karma.conf.cjs:102-105`: the `.js` files, then the
  `.json` files). Each fixture makes its own chart, and the harness restores the defaults after
  each test. Thus the order does not change a result.
- The normal mode of tool 5 adds `--exclude-tags fixtures` to its `flutter test` command. Then
  `test:cases` and `parity:check` do not run the fixture tests, and tool 5 sees no fixture names.
- Tool 5 gets a fixture mode, `--fixtures`. It runs
  `flutter test --tags fixtures --reporter json <files>`, where `<files>` are only the spec files
  in `test/specs/` whose manifest entry has a fixture group with at least one fixture. P1 gives
  0.68 s of compile for each file that a run can leave out (`-j 1`). The other spec files and the
  other test files of the package (about 100) do not compile. The mode reports each fixture as passed,
  failed, skipped with its reason, or missing. It fails on a failed fixture, on a missing fixture
  of a spec file that calls `fixture.specs`, on an unknown fixture name, and on a skip reason that
  is not `'blocked: <module>'`, `'n/a: <reason>'` or `'diverges: <row id>'`. It also prints the
  10 slowest fixture tests from the `time` fields of the reporter, at no extra cost. That list is
  not a gate and not a figure for `performance.md`.
- The Fixtures column of `parity.md` keeps the manifest count. Tool 6 needs no change.

## 4. Tags, scripts, CI job and the submodule

### Options

| Form | Inputs of the job | Absent inputs |
|---|---|---|
| A. Upstream | Karma serves `test/fixtures/**` | n/a |
| B. Existing docs (`porting-flow.md:729-733`) | a shallow submodule checkout | the test skips, or fails with `FIXTURES_REQUIRED=1`, which only the `fixtures` job sets |
| C. Faster | only committed files: `doc/upstream/manifest.json`, `doc/upstream/fixtures.json`, `test/fixtures/` | they cannot be absent |

### Evidence

- Form B exists because the runner was to read the submodule. With section 2, the runner reads no
  file of `third_party/`. Thus the skip rule and `FIXTURES_REQUIRED` have no case to cover.
- The shallow fetch of the pinned Chart.js commit took 1.86 s and 33 MB on this machine
  (`<perf>/clone`, `git fetch --depth 1 origin 7169e651...`). Form C removes it and one failure
  mode of the job (a network fetch).
- The check that form B gave, a stale config after a bump, moves to two places: the job
  `upstream-manifest` for `fixtures.json` and `manifest.json`, and the `sha256` of each hand port
  in the registry against the manifest (section 2 item 6). A changed upstream config thus fails the
  fixture test of its hand port: "the hand port of <path> is stale".

### Choice: form C

- `packages/flutter_chartjs/dart_test.yaml`:

  ```yaml
  tags:
    fixtures:
  ```

- Root `pubspec.yaml`, melos scripts:

  ```yaml
      test:
        exec:
          command: flutter test --exclude-tags fixtures
      test:fixtures:
        run: dart run packages/flutter_chartjs/tool/spec_cases.dart --fixtures
        description: Run the fixture smoke tests of flutter_chartjs (tool 7) and report each fixture as passed, failed, skipped or missing. Fail on a failed, missing or unknown fixture.
  ```

  `--exclude-tags fixtures` in a package without the tag excludes nothing and prints no warning
  (probe in `ws/packages/chartjs_test_utils`).
- `.github/workflows/ci.yaml`, a new job that runs in parallel with the others:

  ```yaml
    fixtures:
      # Tool 7 of packages/flutter_chartjs/doc/porting-flow.md section 4. The
      # runner reads only committed files (doc/upstream/manifest.json,
      # doc/upstream/fixtures.json, test/fixtures/). Thus the job checks out no
      # submodule.
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v7
        - uses: ./.github/actions/setup
        - run: dart run melos run test:fixtures
  ```

- No `FIXTURES_REQUIRED` and no skip without the submodule. The pre-push list of AGENTS.md,
  CONTRIBUTING.md and the PR template gets `test:fixtures` (the gates of the kickstart prompt
  already name it).

## 5. Which fixtures pass in phase 7, the phase 8 skips, and one frame

### The prefixes of phase 7

All prefixes except `plugin.*`: the 7 controller prefixes, `core.datasetController`,
`core.interaction`, `core.layouts`, `core.scale`, `element.line`, `element.point`, `mixed` and the
5 scale prefixes (`scale.time` also runs `scale.timeseries`). `controller.pie` has no fixture
folder: its fixtures are in `controller.doughnut`. The 138 `plugin.*` fixtures wait for the spec
files of phase 8.

### Which fixtures need a module of phase 8

Probe P0 runs each fixture in four kinds of mode in the x64 Node.js: `all`, `none` (no plugin),
and `without:<id>` for each plugin id. It compares a sha256 of the canvas calls after the `run`
hook, and of the calls of one more `draw()`. A second run of `all` (`<perf>/all2.json`) finds the
fixtures whose calls depend on the clock. A fixture needs a plugin when `all` and `none` differ
and the removal of that plugin alone changes the calls (`<perf>/blockers.py`,
`<perf>/blockers.json`).

- 57 fixtures of phase 7 have a phase 8 plugin in their active set (`options.plugins` is an object,
  or `config.plugins` is set). Only 32 of them change their calls. A static rule ("skip when a
  plugin of phase 8 is active") thus skips 25 fixtures that need no plugin. This draft takes the
  measured list.
- The 6 animation fixtures give other calls in a second run of the same mode (5 in `all`
  against `all2`, and `polar-area-animation-rotate.js` in a second run of `none`). They read the
  clock. All 6 set
  `legend`, `title`, `tooltip` and `filler` to `false`. They run in phase 7.
- `test/index.js:25-28` disables the colors plugin, so `colors` never changes a fixture.

Moment parser strings: 39 fixtures set a moment `parser` string (`parser: 'YYYY'`, for example).
The port parses with an ICU pattern (row `adapt-date-moment-format`, Chart.js ADR 0024). Spec cases
of this kind skip with this row. The fixtures follow the same rule.

| Prefix | All | Data, run | Hand, run | Skip |
|---|---|---|---|---|
| `controller.bar` | 87 | 49 | 21 | 17 |
| `controller.bubble` | 8 | 4 | 4 | 0 |
| `controller.doughnut` | 57 | 42 | 15 | 0 |
| `controller.line` | 68 | 34 | 23 | 11 |
| `controller.polarArea` | 54 | 31 | 13 | 10 |
| `controller.radar` | 45 | 28 | 12 | 5 |
| `controller.scatter` | 3 | 2 | 1 | 0 |
| `core.datasetController` | 1 | 1 | 0 | 0 |
| `core.interaction` | 3 | 0 | 1 | 2 |
| `core.layouts` | 11 | 8 | 2 | 1 |
| `core.scale` | 62 | 56 | 6 | 0 |
| `element.line` | 17 | 11 | 6 | 0 |
| `element.point` | 12 | 10 | 2 | 0 |
| `mixed` | 2 | 2 | 0 | 0 |
| `scale.category` | 5 | 4 | 1 | 0 |
| `scale.linear` | 28 | 27 | 1 | 0 |
| `scale.logarithmic` | 6 | 6 | 0 | 0 |
| `scale.radialLinear` | 19 | 13 | 4 | 2 |
| `scale.time` | 29 | 11 | 5 | 13 |
| `scale.timeseries` | 12 | 1 | 1 | 10 |
| **Total** | **529** | **340** | **118** | **71** |

458 fixtures run. 118 configs need a hand port (128 impure minus 10 impure ones that skip). The
71 skips (`<perf>/skips.json`):

- `'diverges: adapt-date-moment-format'` (39): `controller.bar/bar-thickness-*.json` (17),
  `scale.time` (12: `invalid-data`, `labels`, `skip-null-gridlines`, `skip-undefined-gridlines`,
  `source-auto-linear`, `source-data-linear`, `source-labels-linear-offset-min-max`,
  `source-labels-linear`, `ticks-reverse-linear-min-max`, `ticks-reverse-linear`,
  `ticks-reverse-offset`, `ticks-reverse`), `scale.timeseries` (10: `normalize`, `source-auto`,
  `source-data-offset-min-max`, `source-data`, `source-labels-offset-min-max`, `source-labels`,
  `ticks-reverse-max`, `ticks-reverse-min-max`, `ticks-reverse-min`, `ticks-reverse`).
- `'blocked: plugin.filler'` (19): `controller.line` (`backgroundColor/scriptable`,
  `backgroundColor/value`, `fill/no-border`, `fill/order-default`, `fill/order`,
  `fill/scriptable`, `fill/value`, `showLine/false`, `stacking/order-default`,
  `stacking/order-specified`, `stacking/single`), `controller.radar` (`backgroundColor/scriptable`,
  `backgroundColor/value`, `fill/scriptable`, `fill/value`, `showLine/value`),
  `scale.radialLinear` (`gridlines-no-z.json`, `gridlines-z.json`), `scale.time/negative-times`.
- `'blocked: plugin.title'` (10): `controller.polarArea/pointLabels/withTitle/*`.
- `'blocked: plugin.tooltip'` (2): `core.interaction/nearest-partial-bar`,
  `core.interaction/nearest-point-behind-scale`.
- `'blocked: plugin.legend'` (1): `core.layouts/refit-vertical-boxes` (legend and title; the reason
  names the first id in the order legend, filler, title, tooltip).

A `'blocked: plugin.<id>'` skip whose plugin is in `registry.plugins` at the declaration does not
skip. The runner declares a failing test "stale skip" in its place. Thus phase 8 must lift each
skip when it registers the plugin. The check is one Map read for each skip at the declaration.

A fixture of a ported prefix that has functions and no hand port fails with the message "hand-port
<path> to test/fixtures/hand/". No skip reason covers a missing hand port.

### One frame

Upstream reads the canvas right after `Promise.resolve(run(chart)).finally(_done)`
(`fixture.js:51-68`). With `animation: false` (`utils.js`, the defaults of `_acquireChart`), the
construction draws synchronously. The Dart steps of one fixture:

1. `utils.acquireChart(config, json.options)`. The forced layout attaches the chart at its
   construction (Chart.js ADR 0022 §4). The first `update()` draws into the canvas of the
   `UiCanvasElement`.
2. The `run` hook, when `json.options.run` is a `FixtureRun`. A `Future` result settles through
   `pumpFrames`: frames of 16 ms until the `Future` completes, and the Jasmine timeout after
   5,000 ms (`dom.dart:1251-1270`). `triggerMouseEvent` (5 hooks) pumps its own frames.
3. `await tester.pump()`: one frame. It runs the build, the layout and the paint of the chart host.
   A responsive chart gets its first resize notification at this layout. This is port-only: it
   puts the paint path of `canvas_ui.dart` into each smoke test.
4. The png check of `fixture.js:52-55` (the manifest `png`; all 667 fixtures have one).
   `readImageData` and `toEqualImageData` (`fixture.js:57-58`) are `n/a` (Chart.js ADR 0009 §4).
5. `utils.releaseChart(chart)` in a `finally` block. `fixture.js:59` releases only after the image
   comparison. The fixture charts are not in the `charts` registry of `index.dart`, so the unmount
   of the harness body does not release them.

A test passes when no step throws and flutter_test reports no `FlutterError`.

Probe P5 (`<perf>/harness_bench.txt`, `<perf>/ws/packages/flutter_chartjs/test/bench/harness_bench_test.dart`):
300 tests for each form, 6 runs in 4 orders, a chart of the scale test controller with 2 datasets
of 10 points, a category and a linear scale.

| Form | Median for 300 | For each test |
|---|---|---|
| A. empty `testWidgets` | 666 ms | 2.2 ms |
| B. `testWidgets` with `acquireChart` | 1,455 ms | 4.9 ms |
| C. B and `tester.pump()` | 1,636 ms | 5.5 ms |
| D. one `testWidgets` with 300 charts (acquire, pump, release) | 650 ms | 2.2 ms |
| E. plain `test()` with a skip reason | 11 ms | 0.04 ms |

- The frame of step 3 costs 0.6 ms for each fixture (C - B), 0.3 s for the 458 fixtures. The draft
  keeps it.
- Form D (one `testWidgets` for each fixture group) saves 3.3 ms for each fixture, 1.5 s for each
  run of the job. It loses the name, the skip reason and the isolation of each fixture, and tool 5
  cannot count it. Rejected.
- A skip costs 0.04 ms. The 71 skips cost 3 ms.

## 6. Fixture options

| Key | Use in phase 7 | Port |
|---|---|---|
| `json.options.canvas` | 390 | `acquireChart` sets the attributes (Chart.js ADR 0022 §4) |
| `json.options.wrapper` | 0 | `acquireChart` sets the attributes |
| `json.options.spriteText` | 186 | ignored: `acquireChart` has no `spritingOn` (`utils.js:90-92`, n/a, Chart.js ADR 0009) |
| `json.options.useOffscreenCanvas` | 1 (`controller.line/point-style-offscreen-canvas.json`) | `acquireChart` gives the context of a second `UiCanvasElement`; the frame of step 3 paints no chart |
| `json.options.run` | 25 (12 sync, 8 sync that return a Promise, 5 async) | step 2 |
| `json.options.width` | 1 (`scale.radialLinear/pointLabels/scriptable-color-small.js`) | ignored, as upstream (`_acquireChart` does not read it) |
| `json.threshold`, `json.tolerance` | 66 fixtures | `n/a`: only `toEqualImageData` reads them |
| `json.description` | some `.js` configs | the text of the png failure (`fixture.js:40`, `:53`) |
| `json.options.persistent`, `useShadowDOM` | 0 | as `acquireChart` |

The plugin rule (`fixture.js:45-48`) is a line-by-line port:

```dart
// plugins are disabled by default, except if the path contains 'plugin' or
// there are instance plugins
if (!input.contains('plugin') &&
    identical(jsGet(config, 'plugins'), undefined)) {
  options['plugins'] = _or(jsGet(options, 'plugins'), false);
}
```

At the pin, 472 of the 529 fixtures of phase 7 end with `options.plugins === false`. 57 keep an
object, and 4 set `config.plugins` (P0).

## 7. The runner in Dart

```dart
// Ported from chartjs-test-utils v0.4.0 src/fixture.js (MIT, chartjs-test-utils Contributors).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chartjs_test_utils/src/dom.dart' show pumpFrames;
import 'package:chartjs_test_utils/src/utils.dart' as utils;
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.registry.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tag of each fixture test. `flutter test --exclude-tags fixtures`
/// leaves them out.
const String fixturesTag = 'fixtures';

/// `json.options.run`: it can return a `Future` (a JS Promise).
typedef FixtureRun = FutureOr<Object?> Function(Chart chart);

/// A hand-ported config: a new config for each call, and the first 12 hex
/// digits of the sha256 of the upstream file.
typedef HandFixture = ({Map<String, Object?> Function() load, String sha256});

/// fixture.js:73 `specsFromFixtures(path)`.
///
/// DIVERGES(chartjs): harness-fixture-sources, the manifest and the registry
/// in place of the Karma files and `new Function`.
void Function() specsFromFixtures(
  String path, {
  Map<String, HandFixture> hand = const {},
  Map<String, String> skips = const {},
}) {
  // fixture.js:74: the prefix is a regular expression, as upstream.
  final regex = RegExp('^$path.+');
  final inputs = [
    for (final item in _manifest.items)
      if (regex.hasMatch(item.path)) item,
  ];
  return () {
    for (final input in inputs) {
      _specFromFixture(input, hand[input.path], skips[input.path]);
    }
  };
}
```

`_specFromFixture` declares a skipped `test()` for a skip (or a failing test for a stale
`blocked: plugin.<id>` skip), else one `testWidgets` with the steps of section 5. `_manifest` is a
`late final` field that reads `doc/upstream/manifest.json` once. `_dataConfigs` is a `late final`
field that reads `doc/upstream/fixtures.json` at the first fixture body. The paths are relative to
the package root, the working directory of `flutter test`. The tests of the runner give other paths
through a `FixtureSource` parameter with these defaults.

One harness function is new, in `dom.dart`, exported by `flutter.dart`:

```dart
/// One frame after [duration] of fake time: the frame callbacks, the build,
/// the layout and the paint. A hand-ported `run` hook calls it in place of
/// `animator._update(time)`.
Future<void> pumpFrame([Duration duration = frameInterval]);
```

`differences.md` gets two harness rows: `harness-fixture-sources` (the manifest, `fixtures.json`
and the registry in place of the Karma files and `new Function`, the stale sha256 check, the skip
registry) and `harness-fixture-frame` (no image comparison, the frame of step 3, the release in a
`finally` block, the animator steps as frames).

## 8. Rejected faster forms

| Form | Gain | Why rejected |
|---|---|---|
| One fixture file for all groups (1 C) | 2.1 s for each job run with `-j 4` (P1) | changes the upstream structure; tool 5 needs a file map; the gain is CI time only |
| Generated Dart configs (2 C1) | 3 µs for each fixture at run time (P2) | 50-150 ms more compile for each importing file in each run (P3); a generator |
| Registry in `flutter_test_config.dart` | no import line in the spec files | about 14 s of compile for each run with `-j 1` (P4) |
| One `testWidgets` for each group (5 D) | 1.5 s for each job run (P5) | no name, no skip reason and no isolation for each fixture |
| No frame after the run hook | 0.3 s for each job run (P5) | the paint path of `canvas_ui.dart` gets no smoke test |
| A static plugin-skip rule | no probe list to keep | skips 25 fixtures that need no plugin (P0) |
| Public `_update` and `_getAnims`, and `_refresh` as a function field | the exact upstream times in 6 hand ports | changes `lib/src/core/core.animator.dart` for test code; the frame form gives the same smoke |

## 9. Files that the implementation changes

New:
- `packages/chartjs_test_utils/lib/src/fixture.dart`
- `packages/chartjs_test_utils/test/fixture_test.dart`
- `packages/flutter_chartjs/dart_test.yaml`
- `packages/flutter_chartjs/test/fixtures/index.dart`
- `packages/flutter_chartjs/test/fixtures/index_test.dart`
- `packages/flutter_chartjs/test/fixtures/hand/**` (118 files)
- `packages/flutter_chartjs/test/specs/mixed_test.dart` and the 7 controller spec files (with
  their `auto` group)

Changed:
- `packages/chartjs_test_utils/lib/src/index.dart`, `lib/flutter.dart`, `lib/src/dom.dart`
  (`pumpFrame`)
- The 12 earlier spec files of section 1 (the comment becomes the call; `core.datasetController`,
  `core.interaction`, `core.layouts`, `element.line` and `element.point` move to `@TestOn('vm')`
  and `flutter_test` when their chart cases do not move them first)
- `packages/flutter_chartjs/tool/spec_cases.dart`, `tool/src/spec_cases.dart`
  (`--exclude-tags fixtures`, the mode `--fixtures`)
- `packages/flutter_chartjs/tool/port_sources.yaml` (the target `test/fixtures/`)
- `packages/flutter_chartjs/tool/src/port_headers.dart` (`.json` in `sourcesOf`)
- Root `pubspec.yaml` (`test`, `test:fixtures`), `.github/workflows/ci.yaml` (job `fixtures`)
- `AGENTS.md` (Commands, Layout, pre-push list), `CONTRIBUTING.md`, the PR template
- `packages/flutter_chartjs/doc/porting-flow.md` (§1 step 6, §3 "Where tests run" and "Fixture
  selection", §4 tool 7, the `src/fixture.js` row of §3), `doc/differences.md` (the two harness
  rows), `doc/status.yaml` (the `src/fixture.js` row of chartjs-test-utils), then
  `dart run melos run parity`

## 10. Tests that pin the decision

1. `packages/chartjs_test_utils/test/fixture_test.dart` (`@TestOn('vm')`, a temporary manifest
   through `FixtureSource`):
   - the prefix match: `scale.time` matches `scale.timeseries`; the `.` of a prefix matches any
     character, as `fixture.js:74`
   - the plugin rule: a path with `plugin`, a set `config.plugins`, an `options.plugins` object
     and an absent `options.plugins`
   - a sync `run`, a `run` that returns a `Future` that frames complete, and a `run` that never
     completes (the Jasmine timeout message)
   - the release in `finally` after a `run` that throws
   - the png failure, the stale sha256 failure, the missing hand port failure
   - a skip gives a plain `test()` with the reason and the tag; a stale `blocked: plugin.<id>`
     skip fails
   - a hand port wins over a data config of the same path
   - the test names and the group path
2. `packages/flutter_chartjs/test/fixtures/index_test.dart` (`@TestOn('vm')`):
   - each key of `handFixtures` and `fixtureSkips` is a fixture path of the manifest
   - each impure fixture of a spec file that calls `fixture.specs` has a hand port or a skip
   - each file in `test/fixtures/hand/` is in `handFixtures`, and each entry has a file
   - each sha256 equals the first 12 hex digits of the manifest `sha256`
   - each skip reason has a valid form
3. `packages/flutter_chartjs/test/tool/spec_cases_test.dart`: the normal mode passes
   `--exclude-tags fixtures`; the mode `--fixtures` passes `--tags fixtures` and only the spec
   files with fixtures; it fails on a failed, a missing and an unknown fixture and on a bad skip
   reason.
4. `packages/flutter_chartjs/test/tool/check_port_headers_test.dart`: the target `test/fixtures/`
   maps `controller.bar/baseLine/mid-x.js` to `test/fixtures/hand/controller.bar/baseLine/mid-x.dart`,
   and a `.json` source maps back.
5. The CI job `fixtures`: 458 fixture tests pass and 71 skip with the reasons of section 5.

## 11. Probe commands

```sh
S=/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad
P=$S/design/fixture-runner-performance
NODE="/usr/bin/arch -x86_64 $S/env/node-v24.12.0-darwin-x64/bin/node"
cd $P
$NODE probe_fixtures.mjs $S/env/chartjs-build/dist/chart.js $S/env/moment/node_modules --mode all --out all.json
$NODE probe_fixtures.mjs ... --mode all --out all2.json        # the clock check
$NODE probe_fixtures.mjs ... --mode none --out none.json
$NODE probe_fixtures.mjs ... --mode without:filler --out without_filler.json   # and legend, title, tooltip, subtitle, decimation
python3 analyze.py; python3 blockers.py; python3 classify.py
$P/jsonbench/bench_aot; (cd $P/jsonbench && dart run bin/bench.dart)
cd $P/ws/packages/flutter_chartjs
BENCH_ORDER=ABCDE flutter test test/bench/harness_bench_test.dart
flutter test -j 4 --tags fixtures test/files; flutter test -j 4 --tags fixtures test/single
flutter test test/hand_probe/all_test.dart; flutter test test/hand_probe/six_test.dart
```

A rerun of the mode `none` gave the same hashes for all fixtures of phase 7 except the 4
animation fixtures that read the clock.
