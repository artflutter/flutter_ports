# Fixture smoke runner: draft "fidelity first"

Design panel for the future Chart.js ADR 0029 (tool 7, the fixture smoke runner). Lens: fidelity
first. This draft gives the upstream behavior and the upstream structure the most weight. It
accepts a cost only when a measurement shows that the cost is small.

Scope: `porting-flow.md` §1 step 6, §3 "Fixture selection", §4 item 7, and the phase 7 row of §5.
The runner is the port of `src/fixture.js` of chartjs-test-utils 0.4.0 without the image
comparison ([Chart.js ADR 0009](../../../adr/0009-no-display-only-js-exactness.md) §4).

Evidence folder (below: `<ev>`):
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/fixture-runner-fidelity/`.
All Node.js probes ran on the x64 Node.js v24.12.0 under Rosetta, against the Chart.js build at
the pin `7169e651` (`loadChartJs` of `tool/reference/scale_chart_common.mjs` checks the commit).

## 0. Upstream facts (read at the pin)

chartjs-test-utils 0.4.0 (`third_party/chartjs-test-utils/src/`):

| Site | Fact |
|---|---|
| `fixture.js:15-34` | `loadConfig` reads the file again for each `it`. A `.js` file runs through `new Function('"use strict"; var module = {};' + content + '; return module.exports \|\| fixture;')()` (`:24`). Thus the module body runs at each load and gives a new object. A `.json` file goes through `JSON.parse` (`:27`). |
| `fixture.js:38` | The `it` name is the Karma URL of the config: `/base/test/fixtures/<path>.js`. |
| `fixture.js:40` | `json.description` defaults to the input key (the URL without the extension). It is the text of a failure message only. |
| `fixture.js:42-48` | `config.options` defaults to `{}`. Plugins are disabled (`options.plugins = options.plugins \|\| false`) unless the URL contains `plugin` or `config.plugins !== undefined`. |
| `fixture.js:50` | `_acquireChart(config, json.options)`: the chart is not in the registry `charts` of `index.js`. |
| `fixture.js:51-62` | `_done`: a missing PNG fails (`:52-55`). `readImageData` loads the PNG in a later task (`:57`, `utils.js:10-23`). `toEqualImageData(expected, json)` compares (`:58`). Then `_releaseChart` (`:59`). |
| `fixture.js:63-68` | `run = json.options && json.options.run`. A function runs as `Promise.resolve(run(chart)).finally(_done)`. A rejection still calls `_done`, and the rejection fails the spec as an unhandled rejection. |
| `fixture.js:73-93` | `specsFromFixtures(path)` matches `new RegExp('(^/base/test/fixtures/' + path + '.+)\\.(png\|json\|js)')` against `__karma__.files`. The prefix is a regular expression source: a dot matches any character, and `scale.time` also matches `scale.timeseries`. A `.js` config wins over a `.json` config (`:37`). It returns a function, the body of `describe('auto', ...)`. |
| `utils.js:36-105` | `_acquireChart`: canvas `{height: 512, width: 512}` (`:43`), wrapper `{class: 'chartjs-wrapper'}` (`:44`), `animation: false`, `responsive: false`, `locale: 'en-US'` (`:58-62`), `useOffscreenCanvas` (`:77-86`), `spritingOn(ctx)` for `spriteText` (`:90-92`). |
| `utils.js:107-115` | `_releaseChart`: `spritingOff(chart.ctx)` (`:108`), `chart.destroy()`, wrapper removal. |
| `matchers.js:176-218` | `toEqualImageData(expected, opts)`: `tolerance` default 0.001 (`:181`), `threshold` default 0.1 (`:182`). When the canvas size differs from the PNG size, `count = Math.abs(aw * ah - w * h)` (`:203`), `ratio = count / (w * h)` (`:205`), and the spec fails when `ratio > tolerance` (`:207`). Thus the size of the canvas is part of the comparison. |
| `spriting.js:20-35`, `:45-53`, `:84-101` | `spritingOn` replaces `ctx.measureText` with a fixed width table (16 px font, 224 widths) and `ctx.fillText` with sprite images. `spritingOff` puts both back. |
| `index.js:5` | `export * from './fixture'`. |

Chart.js at the pin: `test/index.js:15-17` sets `jasmine.fixture = {specs: specsFromFixtures}`.
`test/index.js:27` sets `Chart.defaults.plugins.colors.enabled = false`. `karma.conf.cjs:103-105`
serves `test/fixtures/**/*.js`, `**/*.json` and `**/*.png`. Each spec file calls
`describe('auto', jasmine.fixture.specs('<prefix>'))`, for example
`test/specs/controller.bar.tests.js:2`.

### 0.1 Counts (manifest of tool 4 and `<ev>/v2/keys_probe.mjs`)

667 fixtures, 519 pure data (`fixtures.json`), 148 impure. Phase 7 owns every prefix except
`plugin.*`:

| Prefix | Fixtures | Data | Impure | Impure reasons |
|---|---:|---:|---:|---|
| `controller.bar` | 87 | 66 | 21 | function 19, undefined 1, non-finite 1 |
| `controller.bubble` | 8 | 4 | 4 | function 3, non-finite 1, undefined 1 |
| `controller.doughnut` | 57 | 42 | 15 | function 14, non-finite 1 |
| `controller.line` | 68 | 42 | 26 | function 25, non-finite 2 |
| `controller.polarArea` | 54 | 41 | 13 | function 13 |
| `controller.radar` | 45 | 31 | 14 | function 14 |
| `controller.scatter` | 3 | 2 | 1 | function 1 |
| `core.datasetController` | 1 | 1 | 0 | |
| `core.interaction` | 3 | 0 | 3 | function 3 |
| `core.layouts` | 11 | 9 | 2 | function 2 |
| `core.scale` | 62 | 56 | 6 | function 6 |
| `element.line` | 17 | 11 | 6 | non-finite 6 |
| `element.point` | 12 | 10 | 2 | global 1, function 1 |
| `mixed` | 2 | 2 | 0 | |
| `scale.category` | 5 | 4 | 1 | non-finite 1, undefined 1 |
| `scale.linear` | 28 | 27 | 1 | function 1 |
| `scale.logarithmic` | 6 | 6 | 0 | |
| `scale.radialLinear` | 19 | 15 | 4 | function 4 |
| `scale.time` | 29 | 21 | 8 | global 4, function 3, non-finite 1, undefined 1 |
| `scale.timeseries` | 12 | 11 | 1 | function 1 |
| **phase 7** | **529** | **401** | **128** | function 110, non-finite 13, global 5, undefined 4 |
| `plugin.*` (phase 8) | 138 | 118 | 20 | function 18, non-finite 3, global 1 |

Thus phase 7 hand-ports 128 configs, not only the 110 with functions: a non-finite number,
`undefined` or a global value (`moment(...)`, a canvas) does not survive JSON either. The 128
sources have 5,844 lines (median 44, maximum 102).

Phase 7 fixture options (`json.options`): `canvas` 390 (always `width` and `height`), `spriteText:
true` 186, `run` 25 (20 plain, 5 `async`), `useOffscreenCanvas: true` 1, `width` 1 (an upstream
typo that `_acquireChart` ignores), `wrapper` 0. Top level: `threshold` 57, `tolerance` 38,
`description` 46, `debug` 4. `config.options.plugins` is an object in 57 fixtures and `false` in 11.
`config.plugins` (instance plugins) is set in 4. No phase 7 path contains `plugin`.

## 1. Where the runner lives and where the specs call it

### Options

| | Form | Upstream structure | Notes |
|---|---|---|---|
| A (upstream) | `fixture.js` ported to `packages/chartjs_test_utils/lib/src/fixture.dart`; `index.dart` re-exports it (`index.js:5`); each spec file calls `group('auto', specsFromFixtures('<prefix>'))`; the config file wires the file list (`test/index.js:15-17`) | 1:1 | Chart.js ADR 0022 "fixtures of phase 7" already names `fixture.dart` with `utils.dart` as prefix `utils`. |
| B | One port-only test file `test/fixtures_test.dart` that runs all prefixes | none | Tool 5 has no upstream spec for it. The fixture tests leave their spec files. |
| C | A tool (`tool/fixtures.dart`) outside `flutter test` | none | Cannot build a chart: the harness needs `testWidgets`. |

### Choice: A

- Runner: `packages/chartjs_test_utils/lib/src/fixture.dart`, header
  `// Ported from chartjs-test-utils v0.4.0 src/fixture.js (MIT, chartjs-test-utils Contributors).`
  It imports `utils.dart` with the prefix `utils` and calls `utils.acquireChart` and
  `utils.releaseChart` (Chart.js ADR 0022, open item "The fixtures of phase 7").
- `lib/src/index.dart` replaces its comment `// index.js:5 export * from './fixture': phase 7.`
  with `export 'fixture.dart' show specsFromFixtures;`. `lib/flutter.dart` adds
  `specsFromFixtures`, `setUpFixtures`, `FixtureFiles`, `HandFixture` and `FixtureModule` to its
  `show` list. The runner is not a pure layer: it needs `testWidgets` and `dart:io`.
- `test/flutter_test_config.dart` (the port of `test/index.js`) replaces its comment at
  `index.js:15-19` with `setUpFixtures(fixtureFiles)`. `fixtureFiles` is the stand-in of
  `__karma__.files` (section 2).
- Each Dart spec file calls the runner at the line of the upstream call, in the outer group:

```dart
void main() {
  group('Chart.controllers.bar', () {
    // controller.bar.tests.js:2
    group('auto', specsFromFixtures('controller.bar'));
    // ...
  });
}
```

- The existing comments `// describe('auto', jasmine.fixture.specs(...)): a fixture group of phase
  7, not a case.` become the call in these files: `core.datasetController`, `core.interaction`,
  `core.layouts`, `core.scale`, `element.line`, `element.point`, `scale.category`, `scale.linear`,
  `scale.logarithmic`, `scale.radialLinear`, `scale.time` and `helpers.canvas` (prefix `helpers`,
  0 fixtures: the group is empty, as upstream). The new files are the seven `controller.*` specs
  and `mixed_test.dart`.
- A fixture is a chart case. By the rule of AGENTS.md (Tests), a pure-layer spec file with a chart
  case moves to `@TestOn('vm')` and `flutter_test` as a whole. `core.datasetController`,
  `core.interaction`, `core.layouts` and `element.line` move in phase 7 anyway, because their
  chart cases lift their `blocked: controller.*` skips. `element.point` moves only for its 12
  fixtures. Its 4 non-chart cases then run on the VM only. This draft accepts that loss: the
  structure of the spec file stays 1:1, and the 4 cases still run.

### Code form

```dart
// Ported from chartjs-test-utils v0.4.0 src/fixture.js (MIT, chartjs-test-utils Contributors).
library;

import 'package:chartjs_test_utils/src/utils.dart' as utils;

/// A hand-ported fixture module. Each call runs the module body and returns
/// `module.exports` (fixture.js:24 runs the body at each load).
typedef FixtureModule = Map<String, Object?> Function();

/// One hand port: the sha256 of its source at the pin (the `sha256` of the
/// manifest) and its module.
typedef HandFixture = ({String sha256, FixtureModule module});

/// The stand-in of `__karma__.files` (karma.conf.cjs:103-105) and of the
/// files that `loadConfig` reads.
final class FixtureFiles {
  FixtureFiles({
    required this.manifestPath, // doc/upstream/manifest.json
    required this.dataPath, // doc/upstream/fixtures.json
    required this.hand, // test/fixture_index.dart
    required this.skips,
  });
  // The manifest and the data lines load at the first use (section 2).
}

/// test/index.js:15-17 `jasmine.fixture = {specs: specsFromFixtures}`.
void setUpFixtures(FixtureFiles files);

/// fixture.js:73 `specsFromFixtures(path)`: the body of `group('auto', ...)`.
void Function() specsFromFixtures(String path);
```

## 2. The source of the configs and the form of a hand port

### Options for the data configs

| | Source | Values | Needs the submodule |
|---|---|---|---|
| A (upstream) | read `third_party/Chart.js/test/fixtures/<path>` at test time | `.json`: exact. `.js`: cannot run without a JS engine | yes |
| B (porting-flow §4 tool 7) | `doc/upstream/fixtures.json` of tool 4 for every pure config | V8 evaluated the `.js` module (tool 4 `loadConfig`, `fixtures.mjs:116-133`); the shortest round-trip number text gives the same doubles | no |
| C | B, plus the `.json` files read from the submodule | same values as B for `.json` | yes, for 140 files |

Choice: B. Tool 4 is the one evaluator of the upstream modules, in V8, with the source key order.
The CI job `upstream-manifest` already fails when `fixtures.json` differs from the submodule. C
adds a second loader and a submodule dependency and gives the same values. Chart.js ADR 0006
(accepted) gives the decode form: `jsonDecode` output goes to the resolver unchanged, and an
integer literal stays an `int` that ported code reads through `jsToNumber`.

**Fresh object for each test.** `loadConfig` parses the file at each `it`. The runner splits
`fixtures.json` into one line per path at the first use, and calls `jsonDecode` on the line of the
fixture in each test. Cost (`<ev>/v2/bench/decode_bench.dart`, JIT, 519 configs): the split takes
1.0-3.3 ms and all 519 line decodes take 2.6 ms. A whole-file decode plus deep copies takes
3.9-4.6 ms (22.6 ms cold). Both are small against one chart test (median 9 ms, section 4).

**Shared objects.** JSON loses the identity of an object that a config shares at two places.
`<ev>/v2/shared_refs.mjs` finds 9 data fixtures with a shared object: 5 in phase 7
(`controller.bar/data/parsing.js` shares one `data` array between 3 datasets; `core.scale/
backgroundColor.js`, `tick-backdrop.js` and `tick-backdrop-rotation.js` share `ticks`, `grid` and
`title` objects between scales; `scale.time/labels.js` shares one `time` object between 4 scales)
and 4 in `plugin.filler/line/dataset/clip-bounds-*.js`. `<ev>/v2/identity_probe.mjs` builds each
chart from the source config and from its JSON copy: the observations (`observe`) and the draw
calls (`drawCalls`) are equal for all 9. Thus the loss changes no result at the pin. Fidelity
choice: tool 4 records the shared paths, and the runner restores the identity after the decode.
The cost is about 20 lines of Node.js and 20 lines of Dart. A later fixture whose result depends
on the identity (for example a data array that two controllers listen to) then stays exact.

```json
{"path": "controller.bar/data/parsing.js", "data": true,
 "shared": [["/config/data/datasets/0/data", "/config/data/datasets/1/data"],
            ["/config/data/datasets/0/data", "/config/data/datasets/2/data"]]}
```

The first pointer of a pair is the first place in source key order. The runner sets the value at
the second pointer to the object at the first pointer.

### Options for the impure configs (hand ports)

| | Form | Upstream structure | Bump replay |
|---|---|---|---|
| A (upstream) | one Dart file for each fixture, at the mirrored path, with a function that runs the module body and returns `module.exports` | 1:1 | the diff of one `.js` file maps to one Dart file |
| B | one Dart file for each prefix with a Map of closures | no | a diff touches a shared file |
| C | one registry Map with all 128 configs | no | same as B |

Choice: A. A module body (for example `var gradient;` at `element.point/rotation.js:1`, or the
canvas of `controller.doughnut/doughnut-animation.js:1-4`) runs again at each call, as
`new Function(...)()` does at each load. The upstream key order stays the literal order of the
Dart Map.

**Path and header.** A new target in `tool/port_sources.yaml`, Chart.js entry:

```yaml
      - source: test/fixtures/
        dart: packages/flutter_chartjs/test/fixtures/
```

`PortTarget.map` (`tool/src/port_headers.dart:117-134`) then maps
`test/fixtures/controller.bar/bar-base-value.js` to
`test/fixtures/controller.bar/bar-base-value.dart`, and check:headers compares each header path
with the mapped path, as for `src/` and `test/specs/`. The header is
`// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.bar/bar-base-value.js (MIT, Chart.js Contributors).`
This draft does not use the `hand/` folder of porting-flow §1 step 6: the mirrored path needs no
extra rule in `PortTarget`, and no data config gets a Dart file. 68 of the 128 names fail the
`file_names` lint (a hyphen or a capital before the first dot). These files carry
`// ignore_for_file: file_names` below the header, by Chart.js ADR 0012. No `.json` source and
no name with `+` or `%` is impure at the pin. Thus every hand port has a valid Dart file name.
check:js-semantics examines the hand ports, because their header names a `js` project.

**Hand port form.**

```dart
// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.doughnut/doughnut-animation.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
library;

/// The module of `doughnut-animation.js`. Each call runs the module body
/// (`:1-4` makes a new canvas) and returns `module.exports` (`:6-80`).
Map<String, Object?> fixture() {
  final canvas = document.createElement<HTMLCanvasElement>('canvas')
    ..width = 512
    ..height = 512;
  final ctx = canvas.getContext('2d')!;

  return <String, Object?>{
    'config': <String, Object?>{ /* the literal of :7-48, in source key order */ },
    'options': <String, Object?>{
      'canvas': <String, Object?>{'height': 512, 'width': 512},
      'run': (Chart chart) {
        final anims = animator.getAnims(chart);
        // disable animator
        final backup = animator.refresh;
        animator.refresh = () {};
        final done = Completer<void>();
        requestAnimFrame(() {
          final start = anims.items[0].start;
          for (var i = 0; i < 16; i++) {
            animator.update(start + i * 500);
            final x = i % 4 * 128;
            final y = (i / 4).floorToDouble() * 128;
            ctx.drawImage(chart.canvas!, x.toDouble(), y, 128, 128);
          }
          clearCanvas(chart.canvas);
          chart.ctx.drawImage(canvas, 0, 0);
          animator.refresh = backup;
          done.complete();
        });
        return done.future;
      },
    },
  };
}
```

`window.requestAnimationFrame` (6 hooks) is `requestAnimFrame` of `helpers.extras.dart`, which
wraps the same browser call upstream. `jasmine.triggerMouseEvent` (5 hooks) is
`triggerMouseEvent` of the harness. `setTimeout` (`controller.line/fill/no-border.js`) is the
harness `setTimeout`. A splice of `chart.data.datasets` (2 hooks) calls `notifyArrayListeners`
after the change (AGENTS.md, Tests).

**The animator members of 6 fixtures.** `controller.bar/bar-animation-hide-show.js`,
`controller.doughnut/doughnut-animation.js`, `doughnut-animation-hide-last.js`,
`controller.polarArea/last-slice-animate.js`, `polar-area-animation-rotate.js` and
`polar-area-animation-scale.js` call `animator._getAnims`, replace `animator._refresh` and call
`animator._update(date)`. Chart.js ADR 0019 left the choice open ("Their hand ports either read
`getAnims` and `update` as `@internal` members, with a test switch for `_refresh`, or drive the
frames with pumps").

| | Form | Fixture structure | Cost |
|---|---|---|---|
| A (fidelity) | Chart.js ADR 0012 names: `getAnims`, `update`, and `refresh` as a field that holds a function (the form of `Chart.resize`, `core.controller.dart:945`, Chart.js ADR 0022). `_Anims` becomes the `@internal` class `Anims`. `start()` and the frame callback call the field, as `this._refresh()` reads the patched property upstream (`core.animator.js:38-52`) | 1:1 | AOT 0.881 against 0.845 ns for each frame call; dart2wasm 0.337 against 0.336 ns (`<ev>/v2/bench/hooks_bench.dart`). One call for each frame. |
| B | The hand port drives the frames with pumps of 500 ms or 2000 ms | the loop changes into pumps | no change in `lib/` |

Choice: A. The port keeps the exact control flow of the fixture. The cost is below 0.04 ns for
each frame.

**The registry.** The port-only file `test/fixture_index.dart` holds `fixtureFiles`: the two JSON
paths, the Map of the 128 hand ports with the sha256 of each source, and the skip Map
(section 5). It imports each hand port with a prefix. `flutter_test_config.dart` imports it.
`<ev>/v2/cfgprobe/` measured the cost of that import: 20 test files with a config that imports
128 generated hand-port libraries ran in 13.3, 13.3 and 13.4 s, and without the import in 13.3,
13.2 and 13.0 s (`flutter test --concurrency=1`, three rounds). The import costs 0.1-0.4 s for
20 files.

```dart
// Original code, not ported from Chart.js: the fixture files of tool 7, the stand-in of the Karma file list.
library;

import 'fixtures/controller.bar/bar-base-value.dart' as controller_bar_bar_base_value;
// ...

final FixtureFiles fixtureFiles = FixtureFiles(
  manifestPath: 'doc/upstream/manifest.json',
  dataPath: 'doc/upstream/fixtures.json',
  hand: {
    'controller.bar/bar-base-value.js': (
      sha256: '<the sha256 of the manifest>',
      module: controller_bar_bar_base_value.fixture,
    ),
    // ...
  },
  skips: { /* section 5 */ },
);
```

The sha256 makes a bump mechanical: when a Chart.js bump changes a fixture source, the manifest
gets a new sha256, and the registry test fails until the porter ports the diff.

## 3. Test names and tool 5

### Options

| | Test name | Tool 5 today |
|---|---|---|
| A (upstream) | the `it` name, the Karma URL `/base/test/fixtures/controller.bar/aligned-pixels.js` (`fixture.js:38`) | accepted (`tool/src/spec_cases.dart:24-30`, `:144-156`) |
| B (doc/upstream/README.md) | the config path `controller.bar/aligned-pixels.js` | accepted |

Choice: A. Rule 3 of AGENTS.md gives each test the upstream `it` name. Tool 5 already accepts the
URL form and strips `fixtureUrlPrefix` (`spec_cases.dart:156`). The group path is the upstream
`describe` path, for example `['Chart.controllers.bar', 'auto']`, which `FixtureGroup` of the
manifest gives.

### Counting

Today tool 5 counts a fixture test (`fixtureTests++`, `tool/src/spec_cases.dart:654-661`) and checks
nothing else: no result, no skip reason, no missing fixture. The fidelity choice gives the
fixtures the same checks as the cases, in a separate mode:

- `test:cases` and tool 6 run `flutter test --exclude-tags fixtures --reporter json test/specs`
  (`tool/spec_cases.dart:148-150`, `tool/parity.dart:259-261`). The cases stay fast.
- `test:fixtures` runs `dart run packages/flutter_chartjs/tool/spec_cases.dart --fixtures`. That
  mode runs `flutter test --tags fixtures --reporter json test/specs test/port/fixtures` and
  reports each fixture of each Dart spec file as passed, failed, skipped(reason) or missing. It
  fails on a failed fixture, on a skip reason outside the three forms, on an unknown fixture name,
  on a repeated name, and on a missing fixture of a spec file whose row is `ported` (the rule of
  the cases). Test files outside `test/specs/` count as port-only tests.
- `parity.md` keeps the Fixtures column of the manifest count (`tool/src/parity.dart:775-776`).

## 4. Tag, scripts, CI job and the submodule

### Options

| | Selection | Submodule | Skip rule |
|---|---|---|---|
| A (porting-flow §3) | tag `fixtures`; `test` excludes it; `test:fixtures`; job `fixtures` | shallow checkout | skip without the submodule; fail with `FIXTURES_REQUIRED=1` |
| B (this draft) | same tag, exclusion, script and job | none | none |
| C (upstream) | no tag: the fixtures run in every `test` run, as in Karma | none | none |

Choice: B. The submodule rule of porting-flow §3 comes from the plan with image comparison, which
read the PNGs. With the sources of section 2, the runner reads only committed files:
`fixtures.json`, the manifest (with the PNG size, section 6) and the Dart hand ports. Thus no
fixture test can skip for a missing submodule, and `FIXTURES_REQUIRED` has nothing to guard.
C is the upstream form, but `test` runs in three OS legs and in each local gate. The fixtures add
about 458 chart tests (section 5) of about 9 ms each (median of 20 `testWidgets` chart cases of
`core.scale_test.dart` and `scale.linear_test.dart`, `<ev>/v2/spec_run.jsonl`), plus the hooks
that pump frames. A separate job keeps the fixture results apart and keeps check:port fast.

Files:

- `packages/flutter_chartjs/dart_test.yaml` (new):

```yaml
# Fixture smoke tests of tool 7 (Chart.js ADR 0029). The melos script `test`
# excludes them. `test:fixtures` runs them.
tags:
  fixtures:
```

- The runner gives each fixture test `tags: ['fixtures']` (`testWidgets` and `test` take
  `tags`; the `group` of flutter_test does not).
- Root `pubspec.yaml`, melos: `test.exec.command: flutter test --exclude-tags fixtures` (the
  packages without the tag ignore the exclusion), and a new script:

```yaml
    test:fixtures:
      run: dart run packages/flutter_chartjs/tool/spec_cases.dart --fixtures
      description: Run the fixture smoke tests of flutter_chartjs (tool 7) and report each fixture of the ported spec files as passed, failed, skipped or missing.
```

- `.github/workflows/ci.yaml`: a job `fixtures` on ubuntu with the Flutter version of `.fvmrc`,
  `flutter pub get` and `dart run melos run test:fixtures`. No submodule checkout.
- porting-flow §3 "Fixture selection" and §4 item 7, the phase 7 row of §5, AGENTS.md
  (Commands, the pre-push list) and CONTRIBUTING.md change to this form.

## 5. Which fixtures pass in phase 7, and "one frame"

### The set

Phase 7 runs the groups of every non-plugin prefix: 529 fixtures. The `plugin.*` spec files come
in phase 8. Each fixture of a ported prefix gets one test. It passes, or it skips with a valid
reason from the skip Map of `test/fixture_index.dart`.

### Fixtures that need a phase 8 module

| | Rule | Result |
|---|---|---|
| A | Run every fixture without the plugins | 526 of 529 run without an exception in Node.js too (`<ev>/cmp2`), but 33 do not show their upstream behavior |
| B | Skip by a static rule (`options.plugins` is an object) | 57 + 4 fixtures keep the plugins on; most of them show no plugin effect |
| C (fidelity) | Skip when the upstream observations change without the phase 8 plugins | 33 skips |

Choice: C. The probe (`<ev>/probe/run_spec.mjs` and `compare.mjs`, the phase 7 probe harness with
a port of `specFromFixture` that records a digest after the run hook: chart area, layout boxes,
scale boxes, min, max, tick labels, element geometry and draw call counts) runs each phase 7
fixture with `registerables` (`all`) and without plugins (`none`). Results (`<ev>/analyze.py`
over `<ev>/cmp2`; a new run of `core.layouts`, `core.interaction` and `controller.radar` in
`<ev>/cmp3` gave the same fixture results):

- 526 pass in both modes. 3 need features that the probe does not have (OffscreenCanvas,
  `createLinearGradient`); the port harness has both.
- 37 differ between `all` and `none`:
  - 32 change when one plugin goes: filler 19, title 10, tooltip 2, legend and title 1.
  - 4 animation fixtures differ by the clock only. With a fixed `Date.now()`
    (`<ev>/v2/freeze.mjs`, `<ev>/v2/anim/`), only the geometry of the animated elements differs,
    in the same fields as between two `all` runs. Their configs turn off legend, title, tooltip
    and filler, or have no plugins at all. They run.
  - 1, `core.interaction/drawActiveElementsOnTop-false.js`: the ticks of the hidden y scale
    change (4 ticks with plugins, 7 without). No single removal changes them. `only:title` and
    `only:subtitle` each give the ticks of `all` (`<ev>/v2/dae/`). Ticks are a protected result
    (Chart.js ADR 0009). It skips.
- The skip names the first plugin of `src/plugins/index.js` order whose removal changes the
  result, or, when no single removal does, the first plugin whose presence alone restores it.

38 more fixtures parse with a moment format string (`parser: 'YYYY'` or `'YYYY-MM'`): 17
`controller.bar/bar-thickness-*.json`, 11 `scale.time` and 10 `scale.timeseries`
(`<ev>/moment_format.json`; all 38 contain `YYYY`). The port reads a format string as an ICU
pattern (Chart.js ADR 0024, row `adapt-date-moment-format`). The rule of that row applies: the
fixture skips with `'diverges: adapt-date-moment-format'`. Its port-only twin replaces each
moment pattern with its ICU pattern (`YYYY` to `yyyy`, `YYYY-MM` to `yyyy-MM`) and runs through
the same runner in `test/port/fixtures/moment_twins_test.dart` (tag `fixtures`). Thus the 17
bar-thickness configs keep their coverage of `controller.bar`. `scale.time/invalid-data.js`
parses with `'HH:mm:ss'`, which has the same meaning in moment and ICU: it runs.

Totals of phase 7: 529 fixtures, 458 run, 33 `blocked: plugin.*`, 38
`diverges: adapt-date-moment-format`, plus 38 twins. The 128 hand ports include the 8 impure
blocked fixtures and the 2 impure diverging ones, so that phase 8 only removes skips. Appendix A
lists the 33 blocked fixtures.

A skipped fixture is a `test()` with the skip text (tool 5 rule: `testWidgets` takes only
`skip: true`):

```dart
test(input, () {}, skip: 'blocked: plugin.filler', tags: fixtureTags);
```

### "One frame"

Upstream sequence: the chart draws in its constructor (`animation: false`), the run hook runs,
`Promise.resolve(...).finally(_done)` waits at least one microtask, `readImageData` waits for the
image load task, and the matcher reads the pixels. The port maps each step:

1. `utils.acquireChart(config, json['options'])` (`fixture.js:50`): synchronous. The forced
   layout attaches the chart, and the constructor draws.
2. The run hook (`:63-68`): a `Future` result completes through `pumpFrames` (frames of 16 ms,
   the harness tasks of `setTimeout`, the Jasmine timeout of 5000 ms). An error of the hook, sync
   or async, fails the test, as the unhandled rejection does upstream.
3. The microtask turn of `Promise.resolve`: `pumpFrames` lets the microtasks run first.
4. The image load task of `readImageData` (`:57`): one pump of `frameInterval`. It runs the frame
   callbacks (the animator), the build, the layout and the paint of the chart host. This is the
   frame of Chart.js ADR 0009 §4. A new harness function `pumpFrame()` in `dom.dart` runs the due
   harness tasks and one pump.
5. The size part of `toEqualImageData` (section 6), then `utils.releaseChart(chart)` (`:59`) in a
   `finally`. Upstream does not release a chart after a failure. The release after a failure
   changes no result, and it stops the frame callbacks of the failed chart.

```dart
void _specFromFixture(String description, _Inputs inputs) {
  final input = inputs.js ?? inputs.json!; // fixture.js:37
  final skip = _files.skips[_relative(input)];
  if (skip != null) {
    test(input, () {}, skip: skip, tags: fixtureTags);
    return;
  }
  testWidgets(input, (tester) async {
    final json = _loadConfig(input); // :39
    final descr = jsTruthy(json['description'])
        ? json['description']
        : (json['description'] = description); // :40
    final config = json['config']! as Map<String, Object?>;
    var options = config['options'];
    if (!jsTruthy(options)) config['options'] = options = <String, Object?>{};
    // plugins are disabled by default, except if the path contains 'plugin'
    // or there are instance plugins
    if (!input.contains('plugin') &&
        identical(jsGet(config, 'plugins'), undefined)) {
      final map = options! as Map<String, Object?>;
      map['plugins'] = jsTruthy(map['plugins']) ? map['plugins'] : false;
    }
    final acquire = json['options'] as Map<String, Object?>?;
    final chart = utils.acquireChart(config, acquire); // :50
    try {
      final run = acquire?['run']; // :63
      await _settle(jsIsFunction(run) ? jsCall(run, [chart]) : null); // :65
      if (inputs.png == null) {
        fail('$descr\r\nMissing PNG comparison file for $input'); // :52-55
      }
      await pumpFrame(); // :57, the image load task
      expect(chart, toEqualImageData(inputs.pngSize!, json)); // :58
    } finally {
      utils.releaseChart(chart); // :59
    }
  }, tags: fixtureTags);
}
```

The order of the tests is the order of the manifest: the configs sorted by path. Karma serves
the `.js` pattern before the `.json` pattern (`karma.conf.cjs:103-104`). This draft did not run
Karma to pin its order inside a pattern. The order changes no result: each test makes a new chart,
and the harness restores the defaults after each test.

## 6. The fixture options

| Option | Fixtures (phase 7) | Upstream | Port |
|---|---:|---|---|
| `canvas` | 390 | canvas attributes (`utils.js:43-50`) | `utils.acquireChart` already writes them (phase 5) |
| `wrapper` | 0 | wrapper attributes (`:44`, `:52-56`) | `utils.acquireChart` already writes them |
| `useOffscreenCanvas` | 1 | `transferControlToOffscreen` (`:77-86`) | the harness canvas that no host shows (`harness-acquire-chart`) |
| `spriteText` | 186 | `spritingOn(ctx)`: sprite `measureText` and `fillText` (`:90-92`) | port of `spriting.js`, see below |
| `run` | 25 | the hook (`fixture.js:63-68`) | section 5 |
| `threshold` | 57 | pixelmatch threshold (`matchers.js:182`) | `n/a`: no pixel comparison (Chart.js ADR 0009) |
| `tolerance` | 38 | the mismatch ratio (`:181`, `:207`) | used by the size part of `toEqualImageData` |
| `debug` | 4 | the diff preview (`:180`, `:207`) | `n/a` |
| `description` | 46 | the failure text (`fixture.js:40`) | the failure text |
| `width` (typo) | 1 | ignored by `_acquireChart` | ignored |

### The size part of `toEqualImageData`

`matchers.js:197-207` fails a fixture whose canvas size differs from the PNG size beyond the
tolerance. The size is a result of the chart: `retinaScale` gives
`Math.floor(height * pixelRatio)`. `<ev>/v2/png_size.mjs` reads the IHDR of each PNG: 664 PNGs
have the size of the canvas attributes, and 3 have the device size of a `devicePixelRatio`
option (`controller.bar/aligned-pixels.js` 100x500 to 125x625, `borderColor/border+dpr.js`
501x256 to 751x384, `borderRadius/no-spacing.js` 512x256 to 640x320). Fidelity choice: port the
size part with the upstream arithmetic, and keep `count = 0` for equal sizes, where pixelmatch
would count (`n/a`). This is not an image comparison: it reads only `canvas.width` and
`canvas.height`. Tool 4 adds `pngWidth` and `pngHeight` (bytes 16-23 of the PNG) to each manifest
item, so the runner needs no PNG file.

```dart
/// matchers.js:176 `toEqualImageData`, the size part. The pixel part
/// (pixelmatch, `threshold`, `debug`) is n/a (Chart.js ADR 0009).
Matcher toEqualImageData(({int width, int height}) expected, Map<String, Object?> opts);
```

This is a check that Chart.js ADR 0009 §4 does not name ("It passes when no exception occurs").
It is a refinement: a failed expectation is an exception of the test. If the judge reads §4 as a
limit, the rest of this design does not depend on the size check.

### `spriteText`

`spritingOn` replaces `measureText` with the width table of the sprite font
(`spriting.js:45-53`). Text widths change the layout and the ticks. `<ev>/v2/sprite_probe.mjs`
builds each of the 186 phase 7 sprite fixtures twice in Node.js, with the Liberation Sans widths
of the port's test font and with the sprite widths: the ticks differ in 4
(`core.layouts/hidden-vertical-boxes.js`, `scale.linear/min-max-skip/edge-case-3.js`,
`rotated-case-1.js`, `rotated-case-3.js`), the layout differs in 121 more, 58 are equal, and 3
have non-ASCII text that the Liberation mock does not measure. Thus without the sprite metrics,
the port runs 125 fixtures on another layout than upstream.

| | Form | Upstream behavior | Cost |
|---|---|---|---|
| A (porting-flow §3 table) | `n/a`: no image comparison | 125 fixtures on another layout, 4 with other ticks | none |
| B (fidelity) | port `spriting.js` to `packages/chartjs_test_utils/lib/src/spriting.dart`: the width table, `measureText`, the position arithmetic of `spriteWrite`, `spritingOn` and `spritingOff`. `UiCanvasContext` gets the `@visibleForTesting` field `debugTextOverride` (the instance patch of `spritingOn`). `spriteWrite` draws nothing: the sprite image is display-only | upstream layout and ticks | one null test in `measureText` and `fillText`: AOT 9.751 against 9.739 ns for each call (+0.1 %), dart2wasm 13.648 against 13.616 ns (+0.2 %), `<ev>/v2/bench/hooks_bench.dart` |

Choice: B. The sprite `measureText` gives `{width}` only. The port returns NaN for the other
fields of `TextMetrics`, the JS result of `undefined` in arithmetic. `utils.acquireChart` calls
`spritingOn(ctx)` for `options.spriteText`, and `utils.releaseChart` calls `spritingOff`
(`utils.js:90-92`, `:108`). The context of the canvas is one object (`UiCanvasElement` keeps
`_context`), so the chart reads the patched context, as upstream. The change touches
`canvas_ui.dart`, which `canvas-cuts-plan.md` cites: the same commit updates the plan.

## Files that the implementation changes

New:
- `packages/chartjs_test_utils/lib/src/fixture.dart` (port of `src/fixture.js`).
- `packages/chartjs_test_utils/lib/src/spriting.dart` (port of `src/spriting.js`, metrics only).
- `packages/flutter_chartjs/test/fixture_index.dart` (port-only registry and skip Map).
- `packages/flutter_chartjs/test/fixtures/<prefix>/<path>.dart`: 128 hand ports.
- `packages/flutter_chartjs/test/specs/controller.{bar,bubble,doughnut,line,polarArea,radar,scatter}_test.dart`
  and `mixed_test.dart` (with their `auto` groups).
- `packages/flutter_chartjs/test/port/fixtures/fixture_index_test.dart`,
  `packages/flutter_chartjs/test/port/fixtures/moment_twins_test.dart`.
- `packages/chartjs_test_utils/test/fixture_test.dart`, `spriting_test.dart`.
- `packages/flutter_chartjs/dart_test.yaml`.
- `packages/flutter_chartjs/doc/adr/0029-fixture-smoke-runner.md` (proposed).

Changed:
- `packages/chartjs_test_utils/lib/src/index.dart` (re-export), `lib/flutter.dart` (show list),
  `lib/src/utils.dart` (`spritingOn`, `spritingOff`), `lib/src/matchers.dart`
  (`toEqualImageData`, size part), `lib/src/dom.dart` (`pumpFrame`).
- `packages/flutter_chartjs/lib/src/core/core.animator.dart` (`getAnims`, `update`, `refresh`
  field, `Anims`), `lib/src/canvas/canvas_ui.dart` (`debugTextOverride`).
- `packages/flutter_chartjs/test/flutter_test_config.dart` (`setUpFixtures`).
- The 12 existing spec files of section 1 (the `auto` call; `core.datasetController`,
  `core.interaction`, `core.layouts`, `element.line` and `element.point` move to
  `@TestOn('vm')`).
- `packages/flutter_chartjs/tool/port_sources.yaml` (target `test/fixtures/`).
- `packages/flutter_chartjs/tool/spec_cases.dart`, `tool/src/spec_cases.dart` (`--fixtures`
  mode, `--exclude-tags fixtures`), `tool/parity.dart` (`--exclude-tags fixtures`).
- `packages/flutter_chartjs/tool/upstream_manifest/src/fixtures.mjs` (`pngWidth`, `pngHeight`,
  `shared`), its test, and the regenerated `doc/upstream/manifest.json` and `README.md`.
- Root `pubspec.yaml` (melos `test`, `test:fixtures`), `.github/workflows/ci.yaml` (job
  `fixtures`), AGENTS.md, CONTRIBUTING.md, the PR template.
- `packages/flutter_chartjs/doc/porting-flow.md` §1 step 6, §3, §4 item 7, §5;
  `doc/canvas-cuts-plan.md`; `doc/status.yaml` (rows of `src/fixture.js` and `src/spriting.js`
  of the harness).

## Tests that pin the decision

- `test/port/fixtures/fixture_index_test.dart` (VM): the hand port keys equal the impure manifest
  fixtures of the prefixes that a Dart spec file runs; each sha256 equals the manifest; each Dart
  file under `test/fixtures/` is in the registry; no data fixture has a hand port; each skip key
  is a manifest fixture of a phase 7 prefix and each reason has a valid form; the prefix
  `helpers` and each upstream group without a Dart call match 0 fixtures at the pin.
- `packages/chartjs_test_utils/test/fixture_test.dart`: the prefix regex (a dot matches any
  character; `scale.time` matches `scale.timeseries`); `.js` wins over `.json`; the plugin rule
  (a path with `plugin`, `config.plugins` set, `null`, absent; `options.plugins` truthy kept,
  falsy to `false`); the description default; a sync, an async, a throwing and a never-ending run
  hook (the Jasmine timeout); a missing PNG fails; the size part (equal, a DPR size inside and
  outside `tolerance`); the release after a failure; a fresh config for each test; the restore of
  the `shared` identity; the `fixtures` tag on each test and the skip form.
- `packages/chartjs_test_utils/test/spriting_test.dart`: the widths of `spriting.js:20-35`, the
  shifts of `spriteWrite` for each `textAlign` and `textBaseline`, `spritingOff` restores the
  context.
- `test/port/core/core.animator_test.dart`: a replaced `refresh` stops the self-scheduling, and
  `update(date)` ticks at the given date.
- `test/port/fixtures/moment_twins_test.dart`: the 38 twins pass.
- `test/tool/spec_cases_test.dart`: the `--fixtures` mode (statuses, invalid skip reason, unknown
  and repeated names, missing fixture of a `ported` spec row), and the `--exclude-tags fixtures`
  argument of the case mode.
- `tool/upstream_manifest/test/upstream_manifest.test.mjs`: `pngWidth`, `pngHeight` and `shared`.
- The CI job `fixtures`: 458 passed, 71 skipped, 0 failed for the ported prefixes.

## Appendix A. The 33 `blocked` fixtures of phase 7

| Fixture | Skip |
|---|---|
| `controller.line/backgroundColor/scriptable.js` | `blocked: plugin.filler` |
| `controller.line/backgroundColor/value.js` | `blocked: plugin.filler` |
| `controller.line/fill/no-border.js` | `blocked: plugin.filler` |
| `controller.line/fill/order-default.js` | `blocked: plugin.filler` |
| `controller.line/fill/order.js` | `blocked: plugin.filler` |
| `controller.line/fill/scriptable.js` | `blocked: plugin.filler` |
| `controller.line/fill/value.js` | `blocked: plugin.filler` |
| `controller.line/showLine/false.js` | `blocked: plugin.filler` |
| `controller.line/stacking/order-default.js` | `blocked: plugin.filler` |
| `controller.line/stacking/order-specified.js` | `blocked: plugin.filler` |
| `controller.line/stacking/single.js` | `blocked: plugin.filler` |
| `controller.polarArea/pointLabels/withTitle/bottom-centered-45.js` | `blocked: plugin.title` |
| `controller.polarArea/pointLabels/withTitle/bottom-centered.js` | `blocked: plugin.title` |
| `controller.polarArea/pointLabels/withTitle/left-centered-45.js` | `blocked: plugin.title` |
| `controller.polarArea/pointLabels/withTitle/left-centered.js` | `blocked: plugin.title` |
| `controller.polarArea/pointLabels/withTitle/right-centered-45.js` | `blocked: plugin.title` |
| `controller.polarArea/pointLabels/withTitle/right-centered.js` | `blocked: plugin.title` |
| `controller.polarArea/pointLabels/withTitle/top-centered-45.js` | `blocked: plugin.title` |
| `controller.polarArea/pointLabels/withTitle/top-centered.js` | `blocked: plugin.title` |
| `controller.polarArea/pointLabels/withTitle/top-default-45.js` | `blocked: plugin.title` |
| `controller.polarArea/pointLabels/withTitle/top-default.js` | `blocked: plugin.title` |
| `controller.radar/backgroundColor/scriptable.js` | `blocked: plugin.filler` |
| `controller.radar/backgroundColor/value.js` | `blocked: plugin.filler` |
| `controller.radar/fill/scriptable.js` | `blocked: plugin.filler` |
| `controller.radar/fill/value.js` | `blocked: plugin.filler` |
| `controller.radar/showLine/value.js` | `blocked: plugin.filler` |
| `core.interaction/drawActiveElementsOnTop-false.js` | `blocked: plugin.subtitle` |
| `core.interaction/nearest-partial-bar.js` | `blocked: plugin.tooltip` |
| `core.interaction/nearest-point-behind-scale.js` | `blocked: plugin.tooltip` |
| `core.layouts/refit-vertical-boxes.js` | `blocked: plugin.legend` |
| `scale.radialLinear/gridlines-no-z.json` | `blocked: plugin.filler` |
| `scale.radialLinear/gridlines-z.json` | `blocked: plugin.filler` |
| `scale.time/negative-times.js` | `blocked: plugin.filler` |

By module: filler 19, title 10, tooltip 2, legend 1, subtitle 1. The machine-readable list with
the 38 `diverges` fixtures is `<ev>/v2/skips.json`.

## Appendix B. Evidence scripts

| Evidence | Script or data in `<ev>` |
|---|---|
| counts of options and impurities | `v2/keys_probe.mjs` |
| all against none for 529 fixtures | `probe/run_spec.mjs` (fixture port at its end), `probe/compare.mjs`, `cmp2/`, `cmp3/`, `analyze.py`, `blocked.json` |
| the hidden ticks of `drawActiveElementsOnTop-false.js` | `v2/dae/` |
| the animation fixtures with a fixed clock | `v2/freeze.mjs`, `v2/anim/` |
| shared objects and their effect | `v2/shared_refs.mjs`, `v2/identity_probe.mjs` |
| PNG sizes | `v2/png_size.mjs` |
| sprite metrics | `v2/sprite_probe.mjs` |
| moment patterns | `moment_format.json` |
| hook costs, AOT and dart2wasm | `v2/bench/hooks_bench.dart`, `v2/bench/run_wasm.mjs` |
| JSON decode cost | `v2/bench/decode_bench.dart` |
| config import cost | `v2/cfgprobe/` (`README.txt`) |
| chart test time | `v2/spec_run.jsonl` |
