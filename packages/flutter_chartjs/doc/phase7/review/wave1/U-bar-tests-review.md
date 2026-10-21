# Wave 1, unit U-bar-tests: fidelity review

## Result

The review found 1 defect (low) and 1 observation. The defect is in a test name: the test does
not pin all of its claim. No defect changes behavior that Chart.js ADR 0009 protects. The spec
port, the generator, the reference data and the rename L1 agree with the pinned upstream, the
ADRs and the specs.

The paths are relative to `packages/flutter_chartjs/`. `<scratch>` is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad`.

## Findings

### F1 (confirmed, low): the test "the 23 cases first" does not pin the order

- File: `test/port/controllers/controller.bar_test.dart:137-146`.
- The test name says that the 23 cases of Chart.js ADR 0030 §7 come first. The test checks only
  that the first name is `default` and that 23 names do not start with `parsed:` or
  `interfaces:`. A list where a plain case comes after a `parsed:` case also passes.
- Probe: `<scratch>/wave1/U-bar-tests-review/stale_probe_test.dart`, test P2. It moves case 23
  to position 31 (after the first `parsed:` case). The predicate of the test passes
  (`P2: the predicate passed for the reordered list`).
- Effect: small. The generator stops when its first list does not have 23 cases
  (`controller_bar_reference.mjs`, `cases.length !== 23`), and the themed run skips by name
  prefix. Thus the order has no effect on a result now.
- Fix: also expect that each name of `names.take(23)` has no prefix, and that each name of
  `names.skip(23)` has one of the two prefixes. Or change the name to "the reference has the 23
  cases of Chart.js ADR 0030".

## Observation (no defect)

### O1: the stale-key test cannot fail for a key that the theme emits in the four subtrees

- File: `test/port/controllers/controller.bar_test.dart:162-174` with
  `expectNoStaleScaleKeys` of `controller_chart_harness.dart`.
- The check looks for each emitted path in the options of the scales of the port chart. The
  theme scope gives each emitted key to the resolver. Thus a key that the theme emits under
  `grid`, `border`, `ticks` or `title` is always there.
- Probe: `stale_probe_test.dart`, test P1. A theme with `raw.scale.ticks.staleKeyX` and a
  snapshot with the path `scale.ticks.staleKeyX` pass `expectNoStaleScaleKeys`. The upstream
  observations of `default` do not have the key.
- This agrees with Chart.js ADR 0030 §8 and TS §1.6: the signature takes the port chart. A
  check against the upstream observations would fail on the light preset, because the upstream
  `ticks` observation has no `font` key and the preset emits `scale.ticks.font.*`. The check
  finds a dead slot (an emitted path that the resolver of the scale does not read, or a path
  outside the four observed subtrees). Test 4 (`coverage_test.dart`, REMOVED) finds an emitted
  path that upstream does not have. The themed draw calls compare the tick fonts. No change for
  this unit. The phase lead can record the limit in the doc of `expectNoStaleScaleKeys` (U0).

## What the review examined

### The spec port `test/specs/controller.bar_test.dart`

- The 55 `it` cases of `controller.bar.tests.js` at `7169e651`, in the upstream order, with the
  exact names. The `forEach` of `:1463` is a Dart `for` over `[undefined, 20]` with
  `jsToString`.
- Each body against its upstream lines: the configs, the expected values, the `forEach` blocks
  (`_expectBars`), the hooks (`setUp` for `:1313-1322` and `:1387-1397`, local `afterEach()`
  for `:1325` and `:1399`, local `beforeEach()` for `:1465`), the spies, `objectContaining`,
  `getMinMax()` as `getMinMax(false)`, and `toEqual` of a number as an exact `expect`.
- `removeHoverStyle(bar)` with NaN: upstream `getStyle` (`core.datasetController.js:752-757`)
  reads `index || 0`, and `getContext` (`:762`) tests `index >= 0`. NaN and `undefined` give the
  same results. `defined(index)` at `:809` is true for NaN, but `enableOptionSharing` is false
  for the bar controller.
- The 4 placeholders: `:70`, `:310`, `:671` (`blocked: controller.line`) and `:1808`
  (`blocked: plugin.tooltip`), each with its upstream line in a comment. The D1 cases `:1426`,
  `:1442` and `:1538` have bodies.
- The citations `:85`, `:307`, `:325`, `:575`, `:797-807`, `:1325`, `:1399`, `:1465`,
  `:1677-1678`, `:1803` and `index.umd.ts:35` are correct.
- The header line and the imports agree with Chart.js ADR 0030 §13 item 1. The `auto` group is a
  comment. F-int adds the call (work plan, row F-int).

### The reference tests and the generator

- The 23 cases cover each branch of the bar row of Chart.js ADR 0030 §7. `default` has
  `scaleOptions: true` and the steps `push` and `splice`. The timeseries case runs in `atNow`.
- The 25 `parsed:` cases cover the bar rows of PD §7.3. The 2 `interfaces:` cases and the group
  `interfaces` cover the bar row of IV §7.3.
- The probes `barEdges` and `stackKeys` have the same bodies on both sides.
  `Number(inflateAmount)` agrees with Chart.js ADR 0027 §6 (no `DIVERGES` row).
- Upstream probes in the x64 Node.js v24.12.0 with the pinned build
  (`<scratch>/wave1/U-bar-tests-review/probe_labels.mjs`, `probe_widths.mjs`,
  `probe_base.mjs`):
  - a bad `yAxisKey` on a category index axis: `TypeError` (`key.split is not a function`), and
    `data.labels` is `["q"]`. The relation test of the port agrees.
  - `base: true` gives the bars of `base: 1`.
  - `barThickness: 'flex'` with `grouped: false`: width NaN. `maxBarThickness: null`: width 0.
    `'30'`: width 30.
  - `base: 5` against `'5'`: the same bars without `minBarLength`. With `minBarLength: 20` and
    `[5, 6, 0]`, the bases differ at bar 0 (`bar.js:603`) and at bar 1 (the `===` of
    `getLineWidthForValue`, tick 5). The generated case pins both forms.
- A rerun of the generator in a mirror folder
  (`<scratch>/wave1/U-bar-tests-review/mirror/`) gives SHA-256
  `5ac89ab80dda534c45c6cfaa331cdc3c5d6ac809bcb240c111cdab2dec450c51`, the same as the
  committed data.

### The rename L1 in `lib/src/controllers/controller.bar.dart`

- `getStackCount` and `getStackIndex` drop the underscore and carry `@internal`, because the spec
  reads them (Chart.js ADR 0012, underscore members). The `///` lines keep the upstream names.
  The citations `controller.bar.js:485` and `:518` are correct. `_getStacks` keeps its
  underscore (only its own file reads it). No other file uses the old names.

### Checks of the reviewer

| Command | Result |
|---|---|
| `flutter test test/port/controllers/controller.bar_test.dart test/specs/controller.bar_test.dart` | +136 ~4, all passed |
| `dart analyze --fatal-infos lib/src/controllers test/port/controllers test/specs/controller.bar_test.dart` | No issues |
| `flutter test <scratch>/wave1/U-bar-tests-review/stale_probe_test.dart` | P1 and P2 pass (they show F1 and O1) |

No `flutter_tester` process of this review is left. The process 67820 belongs to another session.
