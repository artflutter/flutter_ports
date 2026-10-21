# Fixture smoke runner: implementation spec

> **Decision D4 of the phase lead (2026-10-21) overrides every line of this spec about the
> submodule.** Chart.js ADR 0029 §3 item 5 and §11 items 4-5 hold: the CI job `fixtures` makes a
> shallow checkout of `third_party/Chart.js` and sets `FIXTURES_REQUIRED=1`. Without the submodule,
> each fixture test skips with `'n/a: the submodule third_party/Chart.js is not checked out'`, and
> with `FIXTURES_REQUIRED=1` it fails. Before a fixture runs, the runner compares the SHA-256 of
> `third_party/Chart.js/test/fixtures/<path>` with the `sha256` of its manifest item. The doc notes
> keep `porting-flow.md` §3 "Fixture selection".


- Decision: [Chart.js ADR 0029](../../../adr/0029-fixture-smoke-runner.md) (proposed). This spec
  gives the work for the agents of the port waves. Where this spec and the ADR differ, the ADR
  wins. Report the difference to the phase lead.
- Roots below: `<pkg>` is `packages/flutter_chartjs/`, `<tu>` is `packages/chartjs_test_utils/`.
  Upstream: `third_party/Chart.js` at `7169e651` and `third_party/chartjs-test-utils` at `v0.4.0`.
- Lists: `<syn>` is
  `/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/design/fixture-runner-synthesis/`.
  `skips.json` (72 skips), `hand.json` (117 hand ports) and `moment_twins.json` (36 twins) are
  there. The appendices of this spec repeat them.
- Rules for each agent: do not change an ADR status line or an accepted ADR. Never edit
  `doc/upstream/` or `doc/parity.md` by hand. Port each hand port from the pinned file, never from
  memory. Kill each `flutter_tester` process that you leave. Prose in ASD-STE100.

## 0. Order of work

| Unit | When | Files (disjoint) |
|---|---|---|
| A1 animator members | any time before H1 and H3, after the integration of a wave | `<pkg>lib/src/core/core.animator.dart`, `<pkg>test/port/core/core.animator_test.dart` (§3) |
| R0 runner | step 4, after the integration of wave 3 is green | `<tu>lib/src/fixture.dart`, `<tu>lib/src/dom.dart`, `<tu>lib/src/index.dart`, `<tu>lib/flutter.dart`, `<tu>dart_test.yaml`, `<tu>test/fixture_test.dart`, `<tu>test/fixture_probe/**`, `<tu>test/dom_test.dart`, `<pkg>dart_test.yaml`, `<pkg>test/fixtures/index.dart`, `<pkg>tool/spec_cases.dart`, `<pkg>tool/src/spec_cases.dart`, `<pkg>tool/parity.dart`, `<pkg>test/tool/spec_cases_test.dart`, `<pkg>tool/port_sources.yaml`, `<pkg>test/tool/check_port_headers_test.dart`, root `pubspec.yaml`, `.github/workflows/ci.yaml` (§2) |
| H1, H2, H3, H4 hand ports | step 4, in parallel with R0 | `<pkg>test/fixtures/hand/<prefixes of the unit>/**` (§4, Appendix B) |
| T1 twins | after R0 | `<pkg>test/port/fixtures/moment_twins_test.dart` (§5) |
| F-int integration | after R0, H1-H4, T1 and the lift agents L1-L3 of the test-strategy spec | `<pkg>test/fixtures/index.dart` (the hand entries), the 20 spec files (the `auto` call), `<pkg>test/specs/mixed_test.dart`, `<pkg>test/port/fixtures/index_test.dart`, the doc notes of §8 (§6) |

- The controller units of the waves keep the comment of the `auto` group at line 2 of their spec
  files (test-strategy spec §5). F-int replaces all 20 comments in one change, because a fixture of
  one prefix can need a controller of a later wave.
- The lift agents L1-L3 edit the spec files too. F-int starts after them, so the files stay
  disjoint.
- `test:fixtures` is a gate from the commit of F-int. R0 lands in the same commit, or in an earlier
  commit without the melos script and the CI job.
- H1 needs A1 for `controller.bar/bar-animation-hide-show.js`. H3 needs A1 for the other 5
  animator fixtures. An H agent can write its other files before A1 lands.
- The `check:headers` gate of an H unit needs the target `test/fixtures/` of
  `tool/port_sources.yaml` (§2.7). R0 lands that change first, before any H unit runs its gates.

## 1. Files

New:
- `<tu>lib/src/fixture.dart`, `<tu>dart_test.yaml`, `<tu>test/fixture_test.dart`,
  `<tu>test/fixture_probe/probe_fixture.dart`, `<tu>test/fixture_probe/manifest.json`,
  `<tu>test/fixture_probe/fixtures.json`
- `<pkg>dart_test.yaml`, `<pkg>test/fixtures/index.dart`, `<pkg>test/fixtures/hand/**` (117 files)
- `<pkg>test/port/fixtures/index_test.dart`, `<pkg>test/port/fixtures/moment_twins_test.dart`
- `<pkg>test/specs/mixed_test.dart`

Changed:
- `<tu>lib/src/dom.dart` (`pumpFrame`), `<tu>lib/src/index.dart`, `<tu>lib/flutter.dart`,
  `<tu>test/dom_test.dart`
- `<pkg>lib/src/core/core.animator.dart`, `<pkg>test/port/core/core.animator_test.dart`
- `<pkg>tool/spec_cases.dart`, `<pkg>tool/src/spec_cases.dart`, `<pkg>tool/parity.dart`,
  `<pkg>test/tool/spec_cases_test.dart`, `<pkg>tool/port_sources.yaml`,
  `<pkg>test/tool/check_port_headers_test.dart`
- `<pkg>test/flutter_test_config.dart` (one comment)
- The 19 existing or wave spec files with a fixture group, and `mixed_test.dart` (§6.2)
- Root `pubspec.yaml`, `.github/workflows/ci.yaml`, `AGENTS.md`, `CONTRIBUTING.md`, the PR
  template
- `<pkg>doc/porting-flow.md`, `<pkg>doc/differences.md`, `<pkg>doc/status.yaml`,
  `<pkg>doc/performance.md`, `<pkg>doc/phase7-progress.md`, then `dart run melos run parity`

## 2. R0: the runner

### 2.1 `<tu>lib/src/fixture.dart`

Line 1: `// Ported from chartjs-test-utils v0.4.0 src/fixture.js (MIT, chartjs-test-utils Contributors).`
Then a library doc that maps the upstream functions to the port (the style of `index.dart`), and
`library;`.

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chartjs_test_utils/src/dom.dart' show pumpFrame, pumpFrames;
import 'package:chartjs_test_utils/src/utils.dart' as utils;
// ignore: implementation_imports
import 'package:flutter_chartjs/src/core/core.controller.dart';
// ignore: implementation_imports
import 'package:flutter_chartjs/src/js/js_function.dart';
// ignore: implementation_imports
import 'package:flutter_chartjs/src/js/js_number.dart';
// ignore: implementation_imports
import 'package:flutter_chartjs/src/js/js_object.dart';
// ignore: implementation_imports
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tag of each fixture test (Chart.js ADR 0029, section 10).
const String fixturesTag = 'fixtures';

/// A config loader: each call gives a new `json` object (fixture.js:24
/// runs the module body at each load).
typedef FixtureLoad = Map<String, Object?> Function();

/// A hand-ported config: its loader and the first 12 hex digits of the
/// `sha256` of the upstream file in the manifest.
typedef HandFixture = ({FixtureLoad load, String sha256});

/// One item of `fixtures.items` of the manifest of tool 4.
typedef FixtureItem = ({String path, String sha256, String? png, bool data});

/// fixture.js:36 `inputs`: the loader of the config and the PNG path.
typedef FixtureInputs = ({FixtureLoad? load, String? png});

/// The files of tool 4 that stand for the Karma files (fixture.js:77).
///
/// The paths are relative to the working directory of `flutter test`, the
/// package root.
final class FixtureSource {
  const FixtureSource({
    this.manifest = 'doc/upstream/manifest.json',
    this.data = 'doc/upstream/fixtures.json',
  });

  final String manifest;
  final String data;

  /// The items of the manifest, in its order. Read once for each isolate.
  List<FixtureItem> get items;

  /// The pure data config of [path]. The data file is decoded once for each
  /// isolate, at the first call. Each subtree feeds one test.
  Map<String, Object?> dataConfig(String path);
}

/// fixture.js:73 `specsFromFixtures(path)`: the body of `group('auto', ...)`.
void Function() specsFromFixtures(
  String path, {
  Map<String, HandFixture> hand = const {},
  Map<String, String> skips = const {},
  FixtureSource source = const FixtureSource(),
});

/// fixture.js:36 `specFromFixture(description, inputs)`. [description] is
/// the path without its extension, the input key of fixture.js:83.
void specFromFixture(String description, String input, FixtureInputs inputs);
```

Note: upstream `specFromFixture` takes `inputs` with the URLs, and it reads `input` from
`inputs.js || inputs.json` (`:37`). The port gives `input` (the test name, the path with its
extension) as its own parameter, because the loader replaces the URL.

`FixtureSource` caches the decoded files in a private top-level `Map<String, Object?>` keyed by the
file path. `items` reads `fixtures.items` and maps each entry to a `FixtureItem` (`png` can be
absent).

`specsFromFixtures`:

```dart
  // DIVERGES(chartjs): harness-fixture-sources, the manifest and the registry.
  final items = source.items;
  final known = {for (final item in items) item.path};
  for (final key in [...hand.keys, ...skips.keys]) {
    if (!known.contains(key)) {
      throw StateError('$key is not a fixture of doc/upstream/manifest.json.');
    }
  }
  // fixture.js:74: the prefix is a regular expression source, not escaped.
  final regex = RegExp('^$path.+\\.(json|js)\$');
  final inputs = [for (final item in items) if (regex.hasMatch(item.path)) item];
  return () {
    for (final item in inputs) {
      _declare(item, hand[item.path], skips[item.path], source);
    }
  };
```

`_declare` (port-only, under the same marker):
1. A skip reason: when the reason is `'blocked: plugin.<id>'` and
   `Chart.registry.plugins.get(id) != null`, declare
   `test(item.path, () => fail('stale skip: plugin.<id> is registered. Remove the skip of ${item.path}.'), tags: fixturesTag)`.
   Else declare `test(item.path, () {}, skip: reason, tags: fixturesTag)`.
2. A hand entry: when `hand.sha256` is not the first 12 hex digits of `item.sha256`, declare
   `test(item.path, () => fail('the hand port of ${item.path} is stale: port the diff of the bump and update its sha256.'), tags: fixturesTag)`.
   Else `specFromFixture(<path without extension>, item.path, (load: hand.load, png: item.png))`.
3. A data item: `specFromFixture(..., (load: () => source.dataConfig(item.path), png: item.png))`.
4. Else: `specFromFixture(..., (load: null, png: item.png))`. The body fails with
   `'hand-port ${item.path} to test/fixtures/hand/, or skip it with a reason.'`.

`specFromFixture` (the steps of ADR §7):

```dart
void specFromFixture(String description, String input, FixtureInputs inputs) {
  testWidgets(input, (tester) async {
    final load = inputs.load;
    if (load == null) fail('hand-port $input to test/fixtures/hand/, or skip it with a reason.');
    final json = load(); // :39
    final descr = jsTruthy(json['description'])
        ? json['description']
        : (json['description'] = description); // :40

    final config = json['config']! as Map<String, Object?>;
    final options = (jsTruthy(config['options'])
        ? config['options']
        : (config['options'] = <String, Object?>{}))! as Map<String, Object?>; // :43

    // plugins are disabled by default, except if the path contains 'plugin' or there are instance plugins
    if (!input.contains('plugin') && identical(jsGet(config, 'plugins'), undefined)) {
      options['plugins'] = jsTruthy(options['plugins']) ? options['plugins'] : false;
    }

    final fixtureOptions = json['options'] as Map<String, Object?>?;
    final chart = utils.acquireChart(config, fixtureOptions); // :50
    try {
      final run = fixtureOptions == null ? undefined : jsGet(fixtureOptions, 'run'); // :63
      if (jsIsFunction(run)) {
        final result = jsCall(run, [chart]);
        if (result is Future<Object?>) await _settle(result); // :65
      }
      if (inputs.png == null) {
        fail('$descr\r\nMissing PNG comparison file for $input'); // :52-55
      }
      // DIVERGES(chartjs): harness-fixture-frame, one frame for the image load task.
      await pumpFrame(); // :57
      // :58 toEqualImageData: n/a (Chart.js ADR 0009 section 4).
    } finally {
      // DIVERGES(chartjs): harness-fixture-frame, the release also after a failure.
      utils.releaseChart(chart); // :59
    }
  }, tags: fixturesTag);
}
```

`_settle(Future<Object?> future)`: record the result or the error with `then`, call
`pumpFrames(() => settled)`, and then throw the error with its stack trace
(`Error.throwWithStackTrace`). `pumpFrames` fails with the Jasmine timeout message after 5000 ms.

Notes:
- `json['options']` of a data config is a `Map<String, dynamic>`. The cast to
  `Map<String, Object?>?` holds.
- Do not catch the errors of `acquireChart`: they fail the test, as upstream.

### 2.2 `<tu>lib/src/dom.dart`

```dart
/// One frame for the image load task of the fixture runner (Chart.js ADR
/// 0029, section 7): runs the due harness tasks, and then one pump of
/// [frameInterval] with the frame callbacks, the build, the layout and the
/// paint.
Future<void> pumpFrame() async {
  await _runDueTasks();
  await _harness.binding.pump(frameInterval);
}
```

### 2.3 Exports

- `<tu>lib/src/index.dart`: replace `// index.js:5 \`export * from './fixture'\`: phase 7.` with
  `export 'fixture.dart';`. Update the library doc bullet of `index.js:5`.
- `<tu>lib/flutter.dart`: add `pumpFrame` to the `show` list of `src/dom.dart`, and
  `FixtureInputs`, `FixtureItem`, `FixtureLoad`, `FixtureSource`, `HandFixture`, `fixturesTag`,
  `specFromFixture` and `specsFromFixtures` to the `show` list of `src/index.dart`. Update the
  library doc.
- `<pkg>test/flutter_test_config.dart`: the comment "`specsFromFixtures` comes in phase 7" becomes
  "`jasmine.fixture` (:15-17) is `specs` of `test/fixtures/index.dart`, which the spec files
  import with the prefix `fixture` (Chart.js ADR 0029)". No import.

### 2.4 Tag files

`<pkg>dart_test.yaml` and `<tu>dart_test.yaml`:

```yaml
# The fixture smoke tests of tool 7 (Chart.js ADR 0029). The melos script
# `test` excludes them. `test:fixtures` runs them.
tags:
  fixtures:
```

### 2.5 `<pkg>test/fixtures/index.dart` (first form)

```dart
// Original code, not ported from Chart.js: the registry of the hand-ported fixture configs and the fixture skips.
library;

import 'package:chartjs_test_utils/flutter.dart';

/// `jasmine.fixture.specs(path)` of Chart.js `test/index.js:15-17`.
void Function() specs(String path) =>
    specsFromFixtures(path, hand: handFixtures, skips: fixtureSkips);

/// The hand-ported configs by fixture path (Chart.js ADR 0029, section 5).
final Map<String, HandFixture> handFixtures = {};

/// The fixtures that skip, by fixture path (Chart.js ADR 0029, section 9).
const Map<String, String> fixtureSkips = {
  // the 72 entries of Appendix A, sorted by path
};
```

The file is not a test entry (no `_test.dart` suffix), so it has no `@TestOn`. Only VM test files
import it. F-int adds the hand imports and entries (§6.1).

### 2.6 Tools 5 and 6

`<pkg>tool/spec_cases.dart` and `<pkg>tool/src/spec_cases.dart`:
1. The case mode adds `--exclude-tags fixtures` to its command (`tool/spec_cases.dart:149-150`):
   `['test', '--exclude-tags', 'fixtures', '--reporter', 'json', 'test/specs']`.
2. A new option `--fixtures` (also with `--results <file>`). The mode:
   - selects the Dart spec files whose manifest spec has a fixture group with `fixtures > 0`, and
     `test/port/fixtures/` when it exists;
   - runs `flutter test --tags fixtures --reporter json <files>`;
   - for each selected spec file and each fixture of each group: passed, failed, skipped (reason)
     or missing; a test outside `test/specs/`: passed or failed;
   - fails on: a failed test or a failed `setUpAll`; a missing fixture; a fixture group without a
     Dart test ("fixture group not called"); a test in a fixture group that is not a fixture of
     its prefix; a repeated full name; a skip reason outside the three forms of porting-flow.md §1
     step 5;
   - prints a summary for each spec file (passed, failed, skipped by reason, missing), the totals,
     and the 10 slowest fixture tests from the `time` of the `testStart` and `testDone` events
     (not a gate);
   - exits with 0 when no finding fails.
3. The usage text and the library doc describe the mode.

`<pkg>tool/parity.dart:259-261`: add `--exclude-tags fixtures`. The usage text at `:20` follows.

### 2.7 Port sources

`<pkg>tool/port_sources.yaml`, Chart.js entry, `targets`, after `test/specs/`:

```yaml
      - source: test/fixtures/
        dart: packages/flutter_chartjs/test/fixtures/hand/
```

`tool/src/port_headers.dart` does not change. `check:headers` needs the submodule to check the
source paths of the hand ports. The CI job `port-checks` has it.

### 2.8 Scripts and CI

Root `pubspec.yaml`, melos:

```yaml
    test:
      exec:
        command: flutter test --exclude-tags fixtures
    test:fixtures:
      run: dart run packages/flutter_chartjs/tool/spec_cases.dart --fixtures
      description: Run the fixture smoke tests of flutter_chartjs (tool 7) and report each fixture as passed, failed, skipped or missing. Fail on a failed, missing or unknown fixture and on a bad skip reason.
```

Keep the other keys of `test` (the `packageFilters`). `.github/workflows/ci.yaml`, a new job after
`test-web`:

```yaml
  fixtures:
    # Tool 7 of packages/flutter_chartjs/doc/porting-flow.md section 4
    # (Chart.js ADR 0029). The runner reads only committed files:
    # doc/upstream/manifest.json, doc/upstream/fixtures.json and
    # test/fixtures/. Thus the job checks out no submodule.
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: ./.github/actions/setup
      - run: dart run melos run test:fixtures
```

If R0 lands before F-int, add the script and the job in the commit of F-int.

### 2.9 Tests of R0

**`<tu>test/fixture_test.dart`** (`@TestOn('vm')`, not tagged). The tag `fixtures` of the runner
keeps its tests out of the melos `test` run. Thus this file runs one subprocess in `setUpAll`:

```
flutter test --tags fixtures --reporter json test/fixture_probe/probe_fixture.dart
```

in the package root (`runInShell: Platform.isWindows`). The probe file has no `_test.dart`
suffix, so a run of the folder never picks it (probe E10 of the ADR). Each test of
`fixture_test.dart` reads the parsed events and asserts one fact.

`<tu>test/fixture_probe/probe_fixture.dart` (port-only header, `@TestOn('vm')`) registers the bar
and line controllers, the category and linear scales and the point, line and bar elements through
`Chart.register`, and calls `specsFromFixtures` with
`FixtureSource(manifest: 'test/fixture_probe/manifest.json', data: 'test/fixture_probe/fixtures.json')`.
The two JSON files have the form of tool 4 with a few items. The run hooks of the probe hand
entries assert with `expect` inside the hook, so a wrong value fails that probe test.

Facts to assert:
- the prefix: `scale.time` matches `scale.timeseries/a.json`; `a.b` matches `aXb/c.json`; a path
  equal to the prefix with no rest does not match;
- the names: each test name is the relative path with its extension, in the calling group;
- the tag: all declared tests ran under `--tags fixtures`;
- the plugin rule: no `plugins` gives `false`; a path with `plugin` keeps it absent; a set
  `config.plugins` keeps it; an object `options.plugins` stays the object;
- the run hook: a sync hook; a hook that returns a `Future` that frames complete; a hook that
  never completes fails with the Jasmine timeout message; a hook that throws fails, and the chart
  is destroyed (a second probe test reads the registry of the canvas, or the hook records the
  chart and a later test checks `chart.attached`);
- the PNG: an item without `png` fails with the upstream message;
- the sources: a hand entry wins over a data config; an impure item without a hand entry fails with
  the hand-port message; a stale `sha256` fails with the stale message; a skip gives a skipped test
  with its reason; a `blocked: plugin.<id>` skip of a registered plugin fails as stale;
- the `StateError`: a call with a hand key or a skip key that is not in the manifest throws (an
  in-process test of `specsFromFixtures` inside a `group`, no subprocess needed).

**`<tu>test/dom_test.dart`**: `pumpFrame` advances the fake clock by 16 ms, runs a due harness task
before the pump, and runs a frame callback.

**`<pkg>test/tool/spec_cases_test.dart`**: the case mode passes `--exclude-tags fixtures`; the mode
`--fixtures` passes `--tags fixtures` and only the selected files; with a `--results` file it
reports passed, failed, skipped and missing; it fails on a failed, a missing and an unknown
fixture, on a group not called, on a repeated name and on a bad skip reason; it counts a test of
`test/port/fixtures/` as port-only.

**`<pkg>test/tool/check_port_headers_test.dart`**: the new target maps
`test/fixtures/controller.bar/baseLine/mid-x.js` to
`packages/flutter_chartjs/test/fixtures/hand/controller.bar/baseLine/mid-x.dart`, and `sourcesOf`
gives it back.

## 3. A1: the animator members

`<pkg>lib/src/core/core.animator.dart`, import `package:meta/meta.dart` if the file does not have
it:

1. `final class _Anims` becomes `@internal final class Anims`. Keep the field docs. Update each
   use.
2. `_Anims _getAnims(types.Chart chart)` becomes `@internal Anims getAnims(types.Chart chart)`.
   Its doc keeps `core.animator.js:112 \`_getAnims(chart)\``.
3. `void _update([double? date])` becomes `@internal void update([double? date])`. Its doc keeps
   `core.animator.js:57`.
4. `_refresh`:

   ```dart
   /// core.animator.js:38 `_refresh()`: registers one frame callback.
   ///
   /// A field that holds a function: a fixture replaces it on the singleton
   /// (`doughnut-animation.js:59-60`), and each call reads the field, as
   /// `this._refresh()` reads the property upstream (:49, :171).
   // DIVERGES(chartjs): harness-method-fields, a fixture replaces it.
   @internal
   late void Function() refresh = _refreshMethod;

   void _refreshMethod() {
     // the body of the current `_refresh`, with `refresh()` at the place of
     // the recursive `_refresh()` call
   }
   ```

   `start` (`:171`) and `unmute` call `refresh()`. Keep the marker
   `platform-animation-promise-checkpoint` in the body.
5. Update the library doc and the comments that name `_update`, `_refresh` or `_getAnims` (for
   example the `jsMapForEach` note).

Tests, `<pkg>test/port/core/core.animator_test.dart`, a new group `harness-method-fields`:
- a chart with a running animation; `animator.refresh = () {}` after `start`: the next frame
  callback runs `update` and then calls the replaced field, so no further frame callback is
  registered (the count of pumps that tick stays 1); restoring the field and calling `start`
  resumes;
- `animator.update(date)` ticks the animations of `getAnims(chart).items` at `date`: the
  `currentStep` of a progress listener equals `date - start`, clamped as upstream (`:31`);
- `getAnims` of a new chart gives a record with `running == false`, `initial == true` and empty
  `items`.

The rename touches no other file in `lib/`. Run `analyze`, `test --no-select` and `test:web`.

## 4. H1-H4: the hand ports

### 4.1 The form of a file

```dart
// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.line/radius/scriptable-to-value.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
library;

import 'package:flutter_chartjs/src/core/core.controller.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    // ...
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
    'run': (Chart chart) {
      // the hook body, line by line
    },
  },
};
```

Rules:
1. Path: `<pkg>test/fixtures/hand/<path>.dart` for `test/fixtures/<path>.js`. Keep the upstream
   spelling of each directory and file name.
2. Line 1 is the header. Add `// ignore_for_file: file_names` as line 2 when the base name is not
   lower_case_with_underscores (Appendix B marks them). Then `library;`.
3. Port the whole file with its comments, in source key order. Module statements (`var`, `const`,
   `function`, the canvas set-up) go into `fixture()` before the `return`. Use a block body when
   the module has statements.
4. Literals: `<String, Object?>{...}` for each object (also when it is empty), `<Object?>[...]` for
   each array, `int` for an integer literal, the upstream digits for a decimal literal,
   `double.nan`, `double.infinity` and `-double.infinity`, and `undefined` of `js_undefined.dart`
   for `undefined`. A shorthand property `{data}` is `'data': data`.
5. Functions: a closure with the upstream parameters as `Object?` (`(Object? ctx) => ...`). A
   scriptable option reads the context with `jsGet` and the JS runtime of AGENTS.md (`jsTruthy`,
   `jsOrZero`, `jsToNumber`). Number forms follow Chart.js ADR 0010 and `check:js-semantics`.
6. The `run` hook: `(Chart chart) { ... }`, or `(Chart chart) async { ... }` for `async run`. A hook
   that returns a `new Promise(...)` returns the `Future` of a `Completer<void>`.
7. Browser and Jasmine names:
   - `window.requestAnimationFrame(cb)`: `requestAnimFrame(cb)` of `helpers.extras.dart`.
   - `jasmine.triggerMouseEvent(chart, type, point)`: `await triggerMouseEvent(chart, type, point)`
     of `package:chartjs_test_utils/flutter.dart`.
   - `document.createElement('canvas')`: `document.createElement<HTMLCanvasElement>('canvas')`.
   - `Chart.helpers.clearCanvas(c)`: `clearCanvas(c)` of `helpers.canvas.dart`.
   - `ctx.drawImage(canvas, ...)` and a canvas as a point style: the image source of the canvas
     layer (`toImageSource()` of `UiCanvasElement`), taken at the place of the upstream read.
   - `Chart.animator`: the singleton `animator` of `core.animator.dart` (§3 names).
   - A splice of `chart.data.datasets` or of a data array: `jsSplice`, then
     `notifyArrayListeners` (row `platform-array-events`).
8. `moment(...)` (5 files of H4): a `DateTime.utc(...)` of the same time value. The default zone of
   the specs is UTC (`test/index.js:23`). `moment(s, fmt).add(d, 'd').toDate()` is
   `DateTime.utc(y, m, day + d, h, min)`. Mark each site with
   `// DIVERGES(chartjs): harness-fixture-sources, a moment value is a DateTime of the same time value.`
9. No skip and no `DIVERGES` marker for any other reason. A hunk that cannot translate is a finding
   for the phase lead.
10. Compute the 12 hex digits for F-int: the first 12 characters of the manifest `sha256` of the
    path. Put them in the final report of the unit, one line for each file:
    `'<path>': (load: <prefix>.fixture, sha256: '<12 hex>'),`.

### 4.2 Checks of an H unit

- `dart run melos run analyze`, `format:check`, `check:headers` (with the submodule),
  `check:js-semantics`.
- A temporary local test (not committed) that imports the unit's files, calls each `fixture()`
  twice, and checks that the two results are not identical objects. Delete it before the end.
- Read each hand port against the upstream file once more: key order, literals, hooks.

## 5. T1: the twins

`<pkg>test/port/fixtures/moment_twins_test.dart`:

```dart
// Original code, not ported from Chart.js: the ICU twins of the fixtures that parse with a moment format string (row adapt-date-moment-format).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The 36 pure data configs of Appendix C.
const List<String> _twins = [/* ... */];

/// The ICU pattern of each moment pattern of the twins.
const Map<String, String> _icu = {'YYYY': 'yyyy', 'YYYY-MM': 'yyyy-MM'};

void main() {
  const source = FixtureSource();
  group('adapt-date-moment-format', () {
    final items = {for (final item in source.items) item.path: item};
    for (final path in _twins) {
      specFromFixture(
        path.substring(0, path.lastIndexOf('.')),
        path,
        (load: () => _toIcu(source.dataConfig(path)), png: items[path]!.png),
      );
    }
  });
}
```

`_toIcu` walks the config. It replaces the string at each `parser` key and each string value of a
`displayFormats` Map through `_icu`. Another string at these places throws a `StateError`. It
returns the same Map. Each twin test passes like a fixture test (no exception). A twin that fails
is a defect of the date adapter or a new difference: report it to the phase lead.

## 6. F-int: the integration

### 6.1 The registry

Add to `<pkg>test/fixtures/index.dart` one import for each of the 117 hand ports, sorted by path:
`import 'hand/<path>.dart' as <prefix>;`. The prefix is the path without the extension, in lower
case, with each run of other characters than `a-z` and `0-9` as `_`
(`controller.bar/baseLine/mid-x.js` gives `controller_bar_baseline_mid_x`). Add the 117 entries of
the H reports to `handFixtures`, sorted by path.

### 6.2 The calls

In each of these spec files, replace the comment of the fixture group with the call, at the same
line, and add `import '../fixtures/index.dart' as fixture;`:

| Dart spec file | Call |
|---|---|
| `controller.bar_test.dart` | `group('auto', fixture.specs('controller.bar'));` |
| `controller.bubble_test.dart` | `group('auto', fixture.specs('controller.bubble'));` |
| `controller.doughnut_test.dart` | `group('auto', fixture.specs('controller.doughnut'));` |
| `controller.line_test.dart` | `group('auto', fixture.specs('controller.line'));` |
| `controller.polarArea_test.dart` | `group('auto', fixture.specs('controller.polarArea'));` |
| `controller.radar_test.dart` | `group('auto', fixture.specs('controller.radar'));` |
| `controller.scatter_test.dart` | `group('auto', fixture.specs('controller.scatter'));` |
| `core.datasetController_test.dart` | `group('auto', fixture.specs('core.datasetController'));` |
| `core.interaction_test.dart` | `group('auto', fixture.specs('core.interaction'));` |
| `core.layouts_test.dart` | `group('auto', fixture.specs('core.layouts'));` |
| `core.scale_test.dart` | `group('auto', fixture.specs('core.scale'));` |
| `element.line_test.dart` | `group('auto', fixture.specs('element.line'));` |
| `element.point_test.dart` | `group('auto', fixture.specs('element.point'));` |
| `helpers.canvas_test.dart` | `group('auto', fixture.specs('helpers'));` |
| `mixed_test.dart` (new) | `group('auto', fixture.specs('mixed'));` |
| `scale.category_test.dart` | `group('auto', fixture.specs('scale.category'));` |
| `scale.linear_test.dart` | `group('auto', fixture.specs('scale.linear'));` |
| `scale.logarithmic_test.dart` | `group('auto', fixture.specs('scale.logarithmic'));` |
| `scale.radialLinear_test.dart` | `group('auto', fixture.specs('scale.radialLinear'));` |
| `scale.time_test.dart` | `group('auto', fixture.specs('scale.time'));` |

The group name of each call is the second item of the manifest `describe` path; the outer group
name stays the one of the file. A file that is still a pure-layer file moves to `@TestOn('vm')`,
`flutter_test` and `package:chartjs_test_utils/flutter.dart` in the same change, and drops
`setUpSpecs()` (AGENTS.md, Tests). At the pin, only `element.point_test.dart` is such a file after
the lift.

`<pkg>test/specs/mixed_test.dart`: the port of `mixed.tests.js` with the header of the spec, the
`auto` group at line 2, and the 2 chart cases (`:4`, `:25`) as `testWidgets` cases with
`acquireChart`. The names keep the upstream spelling ("shoud be constructed with doughnuts
chart"). The classification (`all.json`) does not have these 2 cases, so `lift_check.py` does not
see them. Run each in the probe first (`doc/phase7/probe/run_spec.mjs <dist> mixed.tests.js
--mode none`). `test:cases` must report them as passed. Add the row `test/specs/mixed.tests.js`
to `doc/status.yaml` (§8.4).

### 6.3 `<pkg>test/port/fixtures/index_test.dart`

Port-only header, `@TestOn('vm')`, not tagged. It reads the manifest with `FixtureSource()` and the
manifest spec list. Cases:
- each key of `handFixtures` and of `fixtureSkips` is a manifest fixture;
- no key of `handFixtures` is a pure data fixture;
- each impure fixture that a fixture group of an existing Dart spec file matches (with the regex
  of `fixture.js:74`) has a hand port or a skip;
- each `.dart` file under `test/fixtures/hand/` maps to a key of `handFixtures`
  (`hand/<path>.dart` to `<path>.js`), and each key has its file;
- each `sha256` of `handFixtures` is the first 12 hex digits of the manifest `sha256`;
- each skip reason has the form `blocked: <module>`, `n/a: <reason>` or `diverges: <row id>`, and
  each `diverges` row id has an anchor in `doc/differences.md`.

### 6.4 The run

1. `dart run melos run test:fixtures`. Expected: 457 fixture tests pass, 72 skip with the reasons
   of Appendix A, 36 twin tests pass, 0 missing, 0 unknown.
2. A failed fixture is a defect of a hand port or of the port. Find the cause with the x64 Node.js
   and the build at the pin (`doc/phase7/probe/README.md`). Fix a hand port in place. Give a defect
   of `lib/` to the phase lead with the probe. No skip covers a defect.
3. Kill each `flutter_tester` process that the run leaves.
4. Then all gates: `format:check`, `analyze`, `test --no-select`, `test:web`, `test:cases`,
   `test:fixtures`, `check:port`.

## 7. `DIVERGES` rows

Add to `<pkg>doc/differences.md`, in the harness block:

| ID | Dart file and symbol | Upstream file@version:lines | Category | Reason | Pinning test | Re-check on bump |
|---|---|---|---|---|---|---|
| `harness-fixture-sources` | `packages/chartjs_test_utils/lib/src/fixture.dart` `specsFromFixtures`, `FixtureSource`; `packages/flutter_chartjs/test/fixtures/hand/scale.time/*.dart` (the `moment` values) | chartjs-test-utils `src/fixture.js`@v0.4.0:3-34, 73-93 | harness | Upstream loads each config from the Karma files: `JSON.parse` for a `.json` file and `new Function` for a `.js` module, at each `it`. Dart runs no JavaScript. The runner reads the list from the manifest of tool 4, a pure data config from `doc/upstream/fixtures.json`, and an impure config from a hand port of `test/fixtures/hand/` ([Chart.js ADR 0029](adr/0029-fixture-smoke-runner.md) §3-§5). The test name is the path relative to `test/fixtures/`, not the Karma URL. Port-only checks: a hand port with another `sha256` than the manifest fails as stale; a `blocked: plugin.<id>` skip of a registered plugin fails as stale; an impure fixture without a hand port fails; a hand or skip key that is not a fixture throws a `StateError`. A `moment(...)` value of a hand port is a `DateTime` of the same time value in UTC (`test/index.js`@v4.5.1+7169e651:23). | `packages/chartjs_test_utils/test/fixture_test.dart`; `test/port/fixtures/index_test.dart` | Compare `src/fixture.js` when chartjs-test-utils moves. Run `test:fixtures` after each Chart.js bump. |
| `harness-fixture-frame` | `packages/chartjs_test_utils/lib/src/fixture.dart` `specFromFixture`; `packages/chartjs_test_utils/lib/src/dom.dart` `pumpFrame` | chartjs-test-utils `src/fixture.js`@v0.4.0:36-71 | harness | The port compares no image ([Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md) §4). One frame of `pumpFrame` stands for the image load task of `readImageData` (`:57`): it runs the build, the layout and the paint of the chart host. `releaseChart` runs in a `finally`, also after a failure, where upstream releases after the comparison (`:59`). A skipped fixture is a plain `test()` with the reason, because `testWidgets` takes only `skip: true`. | `packages/chartjs_test_utils/test/fixture_test.dart` | Compare `src/fixture.js` when chartjs-test-utils moves. |

Change the row `harness-method-fields`: add `` `lib/src/core/core.animator.dart` `Animator.refresh` ``
to the Dart column, `src/core/core.animator.js`@v4.5.1+7169e651:38-52, 171 to the upstream column,
and this sentence to the reason: "The fixtures of `controller.bar`, `controller.doughnut` and
`controller.polarArea` replace `Chart.animator._refresh` (Chart.js ADR 0029 §6). Thus `refresh` is
a field too, and `start`, the frame callback and `unmute` call the field." Add the group
`harness-method-fields` of `test/port/core/core.animator_test.dart` to the pinning test column.

Change the Dart column of `platform-animation-promise-checkpoint` (`Animator._refresh` to
`Animator.refresh`) and of `platform-animator-skip-muted` (`Animator._update` to
`Animator.update`).

## 8. Doc notes for the integration agent

### 8.1 `AGENTS.md`

- Commands: add `dart run melos run test:fixtures` (tool 7: the fixture smoke tests of
  `flutter_chartjs`, tool 5 `--fixtures`; it reports each fixture as passed, failed, skipped or
  missing; CI job `fixtures`; no submodule). Say that `test` passes `--exclude-tags fixtures`, and
  that `test:cases` and `parity` exclude the tag. Add `test:fixtures` to the pre-push list.
- Layout, `flutter_chartjs`: `test/fixtures/hand/`, the hand-ported configs at the upstream paths
  (Chart.js ADR 0029); `test/fixtures/index.dart`, the registry and the skips;
  `test/port/fixtures/`. `tool/port_sources.yaml` has the target `test/fixtures/`.
- Layout, `core.animator`: `getAnims`, `update` and the field `refresh` (Chart.js ADR 0029 §6).
- Layout, `chartjs_test_utils`: `lib/src/fixture.dart` ports `src/fixture.js`
  (`specsFromFixtures`, `specFromFixture`, `FixtureSource`); `lib/flutter.dart` exports them and
  `pumpFrame`.
- Chart.js ADRs list: Chart.js ADR 0029 (fixture smoke runner) is proposed.
- CI jobs list: add `fixtures`.
- Tests: add a bullet: "A spec file with a fixture group calls
  `group('auto', fixture.specs('<prefix>'))` at the upstream line, with
  `import '../fixtures/index.dart' as fixture;` (Chart.js ADR 0029). Each fixture test has the tag
  `fixtures`. A hand port is one file at `test/fixtures/hand/<path>.dart` with the function
  `fixture()`, and an entry with the 12 hex digits of its manifest `sha256` in
  `test/fixtures/index.dart`. A fixture skip is an entry of `fixtureSkips`."

### 8.2 `doc/porting-flow.md`

- §1 step 6: "From phase 7, each spec file with a fixture group calls `fixture.specs(<prefix>)` of
  `test/fixtures/index.dart` (upstream prefix match). Hand-port each impure config to
  `test/fixtures/hand/<path>.dart` (Chart.js ADR 0029)."
- §2: a row for Chart.js ADR 0029 in the table of decisions, and the subsection "§2.22 Chart.js
  ADR 0029: Fixture smoke runner (gate 7)" with a short summary of sections 1-11 of the ADR (the
  numbers of `../work-plan.md`, "Doc numbering").
- §3 "Where tests run", the row "Fixture smoke tests": `fixtures` tag, the ubuntu job `fixtures`.
- §3 "Fixture selection": replace the paragraph: the melos `test` script, `test:cases` and tool 6
  pass `--exclude-tags fixtures`; `test:fixtures` runs tool 5 `--fixtures`; the runner reads only
  committed files, so the job checks out no submodule and no test skips for a missing submodule;
  `FIXTURES_REQUIRED` is gone (Chart.js ADR 0029 §11).
- §3, the table row of `src/fixture.js`: the port, `fixture.dart`, `specsFromFixtures` and
  `specFromFixture`, rows `harness-fixture-sources` and `harness-fixture-frame`.
- §4 item 5: the mode `--fixtures` and the tag exclusion. §4 item 7: the sources, the hand ports,
  the registry, tool 5 `--fixtures`, the job without a submodule.
- §5, the phase 7 row and "Repository files": the counts (457 run, 72 skip, 117 hand ports, 36
  twins), the job `fixtures` without a submodule, `dart_test.yaml` in both packages.

### 8.3 `doc/performance.md`

In the phase 7 section, the subsection "13.3 The fixture runner (Chart.js ADR 0029)":
- the `refresh` field of the animator: one field call for each frame; AOT 0.82-0.89 ns against
  0.82-0.85 ns, dart2wasm 0.337 against 0.336 ns (ADR Evidence E6); no frame effect;
- the cost of one fixture test (E5) and the wall time of the first `test:fixtures` run with its 10
  slowest fixtures (from the tool 5 output of §6.4);
- Open item 2 of the ADR (the registry split at 4 s).

### 8.4 `doc/status.yaml`

- chartjs-test-utils `src/fixture.js`: "ported: `specsFromFixtures` and `specFromFixture` as a
  smoke runner (Chart.js ADR 0029): the prefix match, the plugin rule, the `run` hook, one frame,
  no image comparison. The list and the data configs come from tool 4, the impure configs from the
  hand ports of `flutter_chartjs`. `FixtureSource` gives the files. Not a pure layer.
  `test/fixture_test.dart` tests it through a probe run ({{differences}})".
- chartjs-test-utils `src/index.js`: the re-export of `src/fixture.js` (:5) is done.
- Chart.js `test/index.js`: `jasmine.fixture` (:15-17) is `specs` of `test/fixtures/index.dart`.
- `src/core/core.animator.js`: `getAnims`, `update` and the field `refresh` (Chart.js ADR 0029
  §6).
- The rows of the 20 spec files with a fixture group: remove "The fixture group `auto` waits for
  phase 7"; add the fixture counts where the text gives counts.
- New row `test/specs/mixed.tests.js`.
- Port-only rows: `test/fixtures/index.dart`, `test/fixtures/hand/` (one row for the folder),
  `test/port/fixtures/index_test.dart`, `test/port/fixtures/moment_twins_test.dart`,
  `chartjs_test_utils/test/fixture_test.dart`, `chartjs_test_utils/test/fixture_probe/`.
- Then `dart run melos run parity`.

### 8.5 Other files

- `CONTRIBUTING.md` and the PR template: `test:fixtures` in the pre-push list.
- `doc/phase7-progress.md`: the decision line "Chart.js ADR 0029: fixture smoke runner" and the
  result of §6.4.
- `doc/canvas-cuts-plan.md`: no change (no file of the plan changes).
- `doc/upstream-ledger.md`: row `cb02e1d2` (#12155), the fixture
  `controller.line/stacking/stack-cache.js` runs (hand port of H2); row `714b48cd` (#12328), the
  fixture `controller.polarArea/pointLabels/overlapping.js` runs (hand port of H3); row `ab79c3bf`
  (#12238), the fixtures of the row run. Remove "waits for controller.line" and "is not started"
  where the text says it.

## 9. Checks before the end of each unit

- `dart run melos run format:check`, `analyze`, `test --no-select`, `test:web`, `test:cases`,
  `check:port`; from F-int on, also `test:fixtures`.
- No `flutter_tester` process left.

## Appendix A. The 72 skips

`'diverges: adapt-date-moment-format'` (39):
- `controller.bar/`: `bar-thickness-absolute.json`, `bar-thickness-flex-offset.json`,
  `bar-thickness-flex-single-reverse.json`, `bar-thickness-flex-single.json`,
  `bar-thickness-flex.json`, `bar-thickness-max.json`, `bar-thickness-min-interval-multi.json`,
  `bar-thickness-min-interval.json`, `bar-thickness-multiple.json`,
  `bar-thickness-no-overlap.json`, `bar-thickness-offset.json`,
  `bar-thickness-per-dataset-stacked.json`, `bar-thickness-per-dataset.json`,
  `bar-thickness-reverse.json`, `bar-thickness-single-xy.json`, `bar-thickness-single.json`,
  `bar-thickness-stacked.json`
- `scale.time/`: `invalid-data.js`, `labels.js`, `skip-null-gridlines.js`,
  `skip-undefined-gridlines.js`, `source-auto-linear.js`, `source-data-linear.js`,
  `source-labels-linear-offset-min-max.js`, `source-labels-linear.js`,
  `ticks-reverse-linear-min-max.js`, `ticks-reverse-linear.js`, `ticks-reverse-offset.js`,
  `ticks-reverse.js`
- `scale.timeseries/`: `normalize.js`, `source-auto.js`, `source-data-offset-min-max.js`,
  `source-data.js`, `source-labels-offset-min-max.js`, `source-labels.js`,
  `ticks-reverse-max.js`, `ticks-reverse-min-max.js`, `ticks-reverse-min.js`, `ticks-reverse.js`

`'blocked: plugin.filler'` (19):
- `controller.line/`: `backgroundColor/scriptable.js`, `backgroundColor/value.js`,
  `fill/no-border.js`, `fill/order-default.js`, `fill/order.js`, `fill/scriptable.js`,
  `fill/value.js`, `showLine/false.js`, `stacking/order-default.js`,
  `stacking/order-specified.js`, `stacking/single.js`
- `controller.radar/`: `backgroundColor/scriptable.js`, `backgroundColor/value.js`,
  `fill/scriptable.js`, `fill/value.js`, `showLine/value.js`
- `scale.radialLinear/gridlines-no-z.json`, `scale.radialLinear/gridlines-z.json`,
  `scale.time/negative-times.js`

`'blocked: plugin.title'` (10): `controller.polarArea/pointLabels/withTitle/` `bottom-centered-45.js`,
`bottom-centered.js`, `left-centered-45.js`, `left-centered.js`, `right-centered-45.js`,
`right-centered.js`, `top-centered-45.js`, `top-centered.js`, `top-default-45.js`,
`top-default.js`.

`'blocked: plugin.tooltip'` (2): `core.interaction/nearest-partial-bar.js`,
`core.interaction/nearest-point-behind-scale.js`.

`'blocked: plugin.legend'` (1): `core.layouts/refit-vertical-boxes.js`.

`'blocked: plugin.subtitle'` (1): `core.interaction/drawActiveElementsOnTop-false.js`.

## Appendix B. The 117 hand ports by unit

Marks: `i` the file needs `// ignore_for_file: file_names`; `r` a `run` hook; `a` the animator
members of §3; `e` `triggerMouseEvent`; `m` a module statement; `s` a splice; `t` a `moment` value.

**H1** (26): `controller.bar/` `backgroundColor/scriptable.js`, `bar-animation-hide-show.js` (i r a
m), `baseLine/bottom.js`, `baseLine/left.js`, `baseLine/mid-x.js` (i), `baseLine/mid-y.js` (i),
`baseLine/right.js`, `baseLine/top.js`, `baseLine/value-x.js` (i), `baseLine/value-y.js` (i),
`borderColor/scriptable.js`, `borderSkipped/scriptable.js`, `borderWidth/scriptable.js`,
`borderWidth/scriptable-object.js` (i), `minBarLength/horizontal.js`, `minBarLength/vertical.js`,
`skipNull/bar-skip-null.js` (i), `skipNull/bar-skip-null-object-data.js` (i),
`stacking/issue-9105.js` (i r), `stacking/remove-dataset.js` (i r m s), `stacking/replace-data.js`
(i r m); `controller.bubble/` `hover-radius-zero.js` (i r), `padding-update.js` (i r),
`radius-data.js` (i), `radius-scriptable.js` (i); `controller.scatter/showLine/changed.js` (r).

**H2** (31): `controller.line/` `borderCapStyle/scriptable.js`, `borderColor/scriptable.js`,
`borderDash/scriptable.js`, `borderDashOffset/scriptable.js`, `borderJoinStyle/scriptable.js`,
`borderWidth/scriptable.js`, `clip/false.js` (m), `cubicInterpolationMode/scriptable.js`,
`issue-8902.js` (i), `pointBackgroundColor/scriptable.js`, `pointBorderColor/scriptable.js`,
`pointBorderWidth/scriptable.js`, `pointStyle/scriptable.js`, `radius/scriptable.js`,
`radius/scriptable-to-value.js` (i r), `rotation/scriptable.js`, `segments/gap.js`,
`segments/gradient.js` (m), `segments/range.js` (m), `segments/slope.js` (m),
`segments/spanGaps.js` (i), `stacking/stack-cache.js` (i r m), `stacking/updates.js` (r s);
`element.line/skip/` `all.js`, `first.js`, `first-span.js` (i), `last.js`, `last-span.js` (i),
`middle.js`; `element.point/` `point-style-image.js` (i m), `rotation.js` (m).

**H3** (40): `controller.doughnut/` `backgroundColor/scriptable.js`, `borderAlign/scriptable.js`,
`borderColor/scriptable.js`, `borderDash/scriptable.js`, `borderRadius/scriptable.js`,
`borderWidth/scriptable.js`, `doughnut-NaN.js` (i), `doughnut-animation.js` (i r a m),
`doughnut-animation-hide-last.js` (i r a m), `doughnut-full-to-semi.js` (i r),
`doughnut-hidden.js` (i), `doughnut-hidden-single.js` (i r),
`doughnut-rotation-circumference-8x8.js` (i r m), `doughnut-set-active-elements.js` (i r),
`event-replay.js` (i r e m); `controller.polarArea/` `backgroundColor/scriptable-dataset.js` (i),
`backgroundColor/scriptable-element-options.js` (i), `borderAlign/scriptable-dataset.js` (i),
`borderAlign/scriptable-element-options.js` (i), `borderColor/scriptable-dataset.js` (i),
`borderColor/scriptable-element-options.js` (i), `borderDash/scriptable.js`,
`borderWidth/scriptable-dataset.js` (i), `borderWidth/scriptable-element-options.js` (i),
`last-slice-animate.js` (i r a m), `pointLabels/overlapping.js` (r),
`polar-area-animation-rotate.js` (i r a m), `polar-area-animation-scale.js` (i r a m);
`controller.radar/` `borderCapStyle/scriptable.js`, `borderColor/scriptable.js`,
`borderDash/scriptable.js`, `borderDashOffset/scriptable.js`, `borderJoinStyle/scriptable.js`,
`borderWidth/scriptable.js`, `pointBackgroundColor/scriptable.js`,
`pointBorderColor/scriptable.js`, `pointBorderWidth/scriptable.js`, `pointStyle/scriptable.js`,
`radius/scriptable.js`, `rotation/scriptable.js`.

**H4** (20): `core.layouts/` `hidden-vertical-boxes.js` (i), `scriptable.js`; `core.scale/`
`crossAlignment/cross-align-left-far-clipped.js` (i),
`crossAlignment/cross-align-right-far-clipped.js` (i), `grid/scriptable-borderDash.js` (i),
`ticks/rotated-long.js` (i), `ticks/rotated-multi-line.js` (i), `ticks/skip-by-callback.js` (i);
`scale.category/invalid-data.js` (i); `scale.linear/tick-count-data-limits.js` (i);
`scale.radialLinear/` `anglelines-scriptable.js` (i), `gridlines-scriptable.js` (i),
`pointLabels/scriptable-color-small.js` (i), `ticks-below-zero.js` (i); `scale.time/`
`bar-large-gap-between-data.js` (i m t), `custom-parser.js` (i t), `data-ty.js` (i m t),
`data-xy.js` (i m t), `labels-date.js` (i m t); `scale.timeseries/financial-daily.js` (i m).

## Appendix C. The 36 twins

`controller.bar/`: the 17 `bar-thickness-*.json` of Appendix A. `scale.time/`: `labels.js`,
`source-auto-linear.js`, `source-data-linear.js`, `source-labels-linear-offset-min-max.js`,
`source-labels-linear.js`, `ticks-reverse-linear-min-max.js`, `ticks-reverse-linear.js`,
`ticks-reverse-offset.js`, `ticks-reverse.js`. `scale.timeseries/`: the 10 files of Appendix A.
The moment patterns in these configs are `'YYYY'` (38 places), `'YYYY-MM'` (1) and
`displayFormats: {year: 'YYYY'}` (4).
