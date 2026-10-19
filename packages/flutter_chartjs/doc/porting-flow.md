# Chart.js porting flow

- Status: proposed
- Date: 2026-10-16
- Related: [Chart.js ADR 0001](adr/0001-theming.md), [theming.md](theming.md),
  [ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md),
  [upstream-tracking.md](upstream-tracking.md)

This document defines how one Chart.js v4.5.1 module becomes Dart code in
`packages/flutter_chartjs`. This document contains the steps, the decisions, the test harness, the
per-module tooling and the phase plan. [upstream-tracking.md](upstream-tracking.md) owns the
upstream tooling (upstream ledger, status script, watch workflow, bump report, bump PR gate, header
restamp). This document owns the phase numbers, the ADR names, the module status vocabulary and
the `differences.md` schema.

## 1. Life cycle of one module port

1. **Choose.** Pick a module whose value dependencies are ported. Use the phase table (section 5)
   until `dart run melos run port:next` exists. Run the module-start check
   ([upstream-tracking.md](upstream-tracking.md) §4.3). From phase 3,
   `dart run melos run upstream:status` does this check. If a newer tag exists, the bump PR comes
   first.
2. **Read the source** at its pin (rule 1, 2.13). From phase 2, also read its manifest entry.
3. **Write the Dart file.**
   - Map the path (2.5). Line 1 is the rule-2 header.
   - Keep the upstream order and names. Use package imports only.
   - Give each public symbol a `///` line that names the upstream symbol and file:line.
   - Call `lib/src/js` for JS builtins (2.3). Import type-only dependencies from `lib/src/types`
     (2.4).
   - Mark each hunk that does not translate upstream lines with
     `// DIVERGES(chartjs): <row id>, <reason>` and a `differences.md` row (section 4).
   - Start a port-only file with `// Original code, not ported from Chart.js: <reason>.` List it
     in the port-only section of `parity.md`.

   ```dart
   // Ported from Chart.js v4.5.1 src/helpers/helpers.math.ts (MIT, Chart.js Contributors).
   import 'dart:math' as math;

   import 'package:flutter_chartjs/src/js/js_math.dart';

   /// helpers.math.ts:9 `PI`.
   const double pi = math.pi;

   /// helpers.math.ts:10 `TAU`.
   const double tau = 2 * pi;

   /// helpers.math.ts:11 `PITAU`.
   const double piTau = tau + pi;

   /// helpers.math.ts:18 `log10 = Math.log10`.
   const double Function(double) log10 = jsLog10;

   /// helpers.math.ts:152 `_angleDiff`. JS `%` is Dart `remainder`.
   double angleDiff(double a, double b) => (a - b + piTau).remainder(tau) - pi;
   ```

   The sample passes `analyze --fatal-infos` and `format:check` (Dart 3.12.2, very_good_analysis
   10.3.0).
4. **Licensing** (AGENTS.md Licensing). The new sources are @kurkle/color 0.3.2 (MIT, Jukka
   Kurkela), fdlibm 5.3 (SunPro, Sun Microsystems, Inc.) and chartjs-test-utils 0.4.0 (MIT,
   chartjs-test-utils Contributors). The port has no pixelmatch code
   ([Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md)).
5. **Port the specs.**
   - The path is `test/specs/<upstream base>_test.dart`. The header names
     `test/specs/<base>.tests.js`.
   - `group()` and `test()` names equal the `describe` and `it` names. The 10 duplicated names get
     ` #2` and ` #3`.
   - The skip reasons are `'blocked: <module>'`, `'n/a: <reason>'` and `'diverges: <row id>'`.
   - A spec file that reaches `dart:ui` has `@TestOn('vm')` directly below its header lines. A
     pure-layer spec file uses `package:test` (section 3).
   - The harness restores `defaults` after each test. Port a `beforeAll` that changes `defaults`
     as `setUp` plus `tearDown`.
   - Put tests of port-only behavior in `test/port/`.
6. **Fixtures.** From phase 7, register the fixture directory with the runner (upstream prefix
   match). Hand-port configs with functions to `test/fixtures/hand/`.
7. **Status.** The values are `not started`, `in progress`, `partial` (with a symbol list),
   `ported`, `replaced`, `distributed` and `n/a` (with a reason). Until tool 6 lands in
   phase 5, edit `parity.md` by hand. After that, `packages/flutter_chartjs/doc/status.yaml` holds the manual
   states. Tool 6 writes `parity.md`. The upstream status script reads the same source. The first
   PR with a new value updates the `parity.md` legend.
8. **Gallery.** When a chart type renders, update `apps/chartjs_gallery/lib/main.dart:9-19`.
9. **Gates.** Run `format:check`, `analyze`, `test --no-select`, `test:web` and `check:port`.
   Also run each other tool of section 4 that exists in that phase, and `upstream:ledger:check`
   when it exists.
10. **PR and merge.** Write a signed-off Conventional Commit. A backport adds a
    `// Upstream backport: chartjs/Chart.js@<sha8> (#<PR>).` line below the header, plus the
    trailers of [upstream-tracking.md](upstream-tracking.md) §4.2. The reviewer compares the Dart
    file with upstream, side by side.

## 2. Decisions

"Gate" is the first phase whose code depends on the ADR. The maintainers accept each ADR before
the first PR that depends on it. Phase 1 accepts the ADRs with gate 1 or 2. Phase 1 also accepts
the four invariants of Chart.js ADR 0001, because tool 1 and AGENTS.md rule 5 enforce them. The
rest of Chart.js ADR 0001 stays proposed until phase 5.

[ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md) is common to all ports.
The other decisions in this section are for Chart.js only. Each of them becomes a file in
[`packages/flutter_chartjs/doc/adr/`](adr/) with the next free number. If a later port needs the same
decision, the decision moves to `docs/adr/`.

The gate 1 and gate 2 decisions are accepted ADR files now (2026-10-18). Their subsections below keep a summary,
the link and the evidence that the ADR does not repeat. Phase 3 wrote the gate 3 decisions (2.2,
2.7 and 2.8) as proposed ADR files (2026-10-19). Phase 3 also wrote Chart.js ADR 0016
(proposed), which changes one decision of the gate 2 part of 2.9. Phase 4 wrote the gate 4 decision (2.14) as the
proposed file of Chart.js ADR 0017 (2026-10-19). The subsections of the gate 3 and gate 4
decisions keep a summary and the link.
The other subsections stay proposals in this document until their ADR files exist.

| Subsection | ADR | Gate |
|---|---|---|
| 2.1 | [Chart.js ADR 0006: Options representation and resolver](adr/0006-options-representation-and-resolver.md) | 2 |
| 2.3 | [Chart.js ADR 0010: JS numeric semantics](adr/0010-js-numeric-semantics.md), which supersedes Chart.js ADR 0002 | 1 |
| 2.4 | [Chart.js ADR 0003: Type-only dependencies](adr/0003-type-only-dependencies.md) | 1 |
| 2.5 | [Chart.js ADR 0012: Dart file naming](adr/0012-dart-file-naming.md), which supersedes Chart.js ADR 0004 | 1 |
| 2.9, `helpers.extras` and the animator frame source | [Chart.js ADR 0007: Frame scheduling](adr/0007-frame-scheduling.md) | 2 |
| 2.13 | [Chart.js ADR 0011: Third-party sources](adr/0011-third-party-sources.md), which supersedes Chart.js ADR 0005 | 1 |
| 2.3, number formatting | [Chart.js ADR 0008: Number formatting on package:intl](adr/0008-number-formatting-on-package-intl.md) | 2 |
| 2.2, 2.3, 2.6, 2.10 | [Chart.js ADR 0009: No display-only JS exactness](adr/0009-no-display-only-js-exactness.md) | 2 |
| 2.2 | [Chart.js ADR 0013: Canvas model](adr/0013-canvas-model.md) (proposed) | 3 |
| 2.7 | [Chart.js ADR 0014: Input events and the chart host](adr/0014-input-events-and-chart-host.md) (proposed) | 3 |
| 2.8 | [Chart.js ADR 0015: Text](adr/0015-text.md) (proposed) | 3 |
| 2.9, `helpers.extras` and the animator frame source | [Chart.js ADR 0016: Frame scheduling](adr/0016-frame-scheduling.md) (proposed), which supersedes Chart.js ADR 0007 on acceptance | 2 |
| 2.14 | [Chart.js ADR 0017: Element properties](adr/0017-element-properties.md) (proposed) | 4 |

ADR 0006 (gate 1) belongs to [upstream-tracking.md](upstream-tracking.md).

### 2.1 Chart.js ADR 0006: Options representation and resolver (gate 2)

[Chart.js ADR 0006](adr/0006-options-representation-and-resolver.md) holds the decision and its
evidence. In short:
- Scopes are `Map<String, Object?>`. An absent key, a stored const `undefined` sentinel and Dart
  `null` (JS `null`) stay three separate states.
- `Resolver` and `ContextResolver` replace the Proxy traps. They are line-by-line ports of
  `helpers.config.ts` and the scope part of `core.config.js`.
- Release 0.1.0 accepts raw Map configs. A typed options API comes after 0.1.0, with its own ADR
  ("ADR: Typed options API").

The ADR corrects one line reference of the earlier evidence. `Object.keys` enumerates the
declared-key marker at `core.datasetController.js:817`, not at `:818`.

### 2.2 Chart.js ADR 0013: Canvas model (gate 3)

[Chart.js ADR 0013](adr/0013-canvas-model.md) (proposed) holds the decision and its evidence. In
short:
- `lib/src/canvas/canvas.dart` is the pure Canvas 2D interface, with `Path2D` and the port-only
  `CanvasNode` and `CanvasContainer`. The `dart:ui` implementation is `canvas_ui.dart` and four
  parts. No helper imports it. The harness has `MockContext`.
- `UiCanvasContext` keeps a retained bitmap as a list of pictures. A full `clearRect` drops the
  list. A partial clear paints inside a layer. More than 8 pictures flatten into one image.
- The pictures are in bitmap (device-pixel) space. `paint` applies `scale(1 / devicePixelRatio)`.
  `retinaScale` stays a line-by-line port. This replaces the base scale of the first proposal.
- The layer keeps only the Canvas 2D semantics that change behavior, with no Chromium-exact arc
  math ([Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md)).

### 2.3 Chart.js ADR 0010: JS numeric semantics (gate 1)

[Chart.js ADR 0010](adr/0010-js-numeric-semantics.md) holds the complete decision, the
translation rules and the evidence. It supersedes Chart.js ADR 0002.
[Chart.js ADR 0008](adr/0008-number-formatting-on-package-intl.md) holds the number formatting
decision. [Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md) holds the principle of no
display-only JS exactness. In short:
- An unexported JS runtime in `lib/src/js/` represents the JS builtins. Ported files call it where
  upstream calls a builtin.
- The reference engine is V8 13.6 as Node.js v24.12.0 for x64 builds it. Reference data never
  come from a browser or from an arm64 Node.js.
- `Math.log10` and `Math.atan2` are pure-Dart netlib fdlibm ports, because their last bit changes
  log-scale ticks and arc hit tests. `Math.sin`, `Math.cos` and `Math.pow` use `dart:math` `sin`,
  `cos` and `pow` with `double` operands, because no pixel depends on their last bit.
- `Math.max` and `Math.min` with `double` operands are `jsMax` and `jsMin` of
  `lib/src/js/js_math.dart`. On dart2wasm, these functions compare the operands in their own
  code, because the generic `dart:math` `max` and `min` box `double` operands there. On the VM
  and dart2js, they call `dart:math` `max` and `min`. With `int` operands, ported code calls
  `dart:math` `max` and `min`.
- `Math.pow(x, 2)` is `jsSquare(x)` of `lib/src/js/js_math.dart`, which returns `x * x`. The
  product is correctly rounded. On the reference engine, `Math.pow(x, 2)` gave the bits of
  `x * x` for all of 23 million probe inputs. Thus the result is the JS result on every target.
  `ToNumber` of a `double?` value whose `null` is JS `null`, such as `Point.x` and `Point.y`, is
  `(e ?? 0)`, not `jsToNumber(e)`.
- Where the Dart SDK or a package that Flutter 3.44.9 pins gives the JS result, the port uses it.
  The port-only `jsSort` calls `mergeSort` of
  `package:collection`. `jsDateNow()` reads `clock.now()` of `package:clock`. The `FakeAsync` zone
  of `testWidgets` fakes that clock.
- `Intl.NumberFormat` is the `NumberFormat` of `package:intl`. The port-only adapter
  `lib/src/js/js_intl.dart` maps the JS locale and options onto it
  ([Chart.js ADR 0008](adr/0008-number-formatting-on-package-intl.md)). A string that differs from
  the V8 string is the `differences.md` row `adapt-intl-number-format`.
- Tool 3 enforces the translation rules. A site that keeps a flagged form for a stated reason
  carries `// js-ok: <reason>` at the end of its line, or alone on the line before it.

### 2.4 Chart.js ADR 0003: Type-only dependencies (gate 1)

[Chart.js ADR 0003](adr/0003-type-only-dependencies.md) holds the decision and its evidence. In
short, each declaration file becomes a library of `abstract interface class` declarations in
`lib/src/types/`. A member arrives when a ported caller needs it. A file that also needs a concrete
class of the same name imports the types library with the prefix `types`. A union waits for its
first ported caller. The `src/types/*.d.ts` rows become `distributed`.

### 2.5 Chart.js ADR 0012: Dart file naming (gate 1)

[Chart.js ADR 0012](adr/0012-dart-file-naming.md) holds the decision and its evidence. It
supersedes Chart.js ADR 0004. In short,
"Dart-cased" applies to identifiers. File and directory names keep the upstream spelling, for
example `lib/src/controllers/controller.polarArea.dart`. `simpleArc.dart` is the one file that
needs `// ignore_for_file: file_names`. Upstream `_`-prefixed exports drop the underscore. A
`_`-prefixed member that other modules read also drops the underscore. It carries `@internal`.
A member of an interface in `lib/src/types/` does not carry it, because a type library imports
only other type libraries.

### 2.6 Chart.js ADR 0009: No display-only JS exactness, image comparison part (gate 2)

[Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md) holds the decision. In short, the
port does not compare its renders with the upstream PNGs. It has no pixelmatch port, no
Canvas-call replay suite and no fixture ledger. The fixture configs run as smoke tests (tool 7).
Flutter goldens of the port test only Flutter behavior.

### 2.7 Chart.js ADR 0014: Input events and the chart host (gate 3)

[Chart.js ADR 0014](adr/0014-input-events-and-chart-host.md) (proposed) holds the decision, its
evidence and the items that stay open. In short:
- `platform.flutter.dart` replaces `platform.dom.js` with the upstream names. The port-only
  `NativeEvent` stands in for the DOM event. `detectPlatform` tests for a chart host.
- The internal chart host (`ChartHost`, `RenderChartHost`) sizes the chart in its first layout,
  before the first paint. Later size and DPR changes go through one `throttled<Size?>` function.
  Unbounded constraints give the canvas default of 300 x 150. Paint clips a larger chart.
- `PointerDeviceKind` selects the DOM event names. The host reads raw pointer events and claims
  only one `TapGestureRecognizer`, for `click`. Parent scrollables keep their drags.
- `getRelativePosition` keeps `Math.round` and drops the CSS math and the DPR factor (row
  `platform-relative-position`).

### 2.8 Chart.js ADR 0015: Text (gate 3)

[Chart.js ADR 0015](adr/0015-text.md) (proposed) holds the decision and its evidence. In short:
- `parseCanvasFont` parses the CSS shorthand of `toFontString`. Generic families stay family
  names. `measureText` and `fillText` use one `ui.Paragraph` for each font and text, in LRU caches.
- The harness installs Liberation Sans 2.1.5 (SIL OFL 1.1) under the families of the Chart.js
  default font and `sans-serif`.
- The text-metric probe ([text-metrics.md](text-metrics.md)) found all 80 widths equal to the
  Chrome widths. Baseline offsets differ by less than 1 px. These differences are display-only.

### 2.9 ADR: Animation (gate 5), with Chart.js ADR 0007 for `helpers.extras` and the animator frame source (gate 2)

[Chart.js ADR 0007: Frame scheduling](adr/0007-frame-scheduling.md) holds the gate 2 part:
`requestAnimFrame`, `throttled` and `debounce` in `helpers.extras` (`helpers.extras.ts:14-61`),
and the frame source of the animator. `requestAnimFrame` calls
`SchedulerBinding.scheduleFrameCallback`. `throttled` coalesces calls to one in each frame.
`debounce` uses a `dart:async` `Timer`. `Chart.destroy()` cancels that `Timer`. `core.animator.js` stays
one module-level animator on `requestAnimFrame`. The chart host mutes a chart under
`TickerMode(enabled: false)`. Thus `core.animator.js` has two small `DIVERGES` hunks.
[Chart.js ADR 0010](adr/0010-js-numeric-semantics.md) gives the clock: `jsDateNow()` on
`clock.now()`. The rest of this subsection stays a proposal for ADR: Animation (gate 5).

[Chart.js ADR 0016: Frame scheduling](adr/0016-frame-scheduling.md) (proposed, phase 3) states
the complete scheduling decision again. It changes decision 9 of Chart.js ADR 0007. The first
layout of the chart host reports the attach at once, inside `performLayout`
([Chart.js ADR 0014](adr/0014-input-events-and-chart-host.md), section 3). A canvas swap reports
the detach of the old canvas at once, during the build. Chart.js ADR 0016 keeps the other eleven
decisions. On acceptance, it supersedes Chart.js ADR 0007.

**Decision.** None yet. [Chart.js ADR 0007](adr/0007-frame-scheduling.md) decisions 6 and 7
already make the chart host of 2.7 destroy its chart in `dispose` and follow `TickerMode`. Tests use `tester.pump` with
`animation: false`, as `acquireChart` does.

**Evidence.** Thin. The ADR must cover `core.animator.tests.js` and the 400 ms hover transitions.

**Open.** Chart animations under reduced motion, through `MediaQuery.maybeDisableAnimationsOf`. A
theme switch uses the zero-duration `'themeFrame'` mode. Theme removal uses `'default'`. Thus it
animates until this ADR decides ([theming.md](theming.md) §3.7, §11).

### 2.10 ADR: Dates (gate 6)

**Decision.**
- Port `core.adapters.ts`. Ship a default adapter on `DateTime`, in local time or UTC. Make
  calendar steps with the `DateTime` constructor, not with `Duration`. Clamp month ends. Truncate
  `diff` toward zero. Return null for invalid input, also for NaN and ±Infinity. Stop an `add`
  loop that does not advance.
- Format with `DateFormat` of `intl`, with ICU pattern tokens
  ([Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md)). The port has no
  moment-compatible formatter or parser.
- Read "now" through `jsDateNow()` ([Chart.js ADR 0010](adr/0010-js-numeric-semantics.md)),
  because `scale.time.js:342-343` calls `Date.now()`. A spec sets the time with `withClock` of
  `package:clock`. The fake time of `testWidgets` starts at the wall-clock time of the test start.
  It moves only by the pumped durations.
- The specs use the default adapter in UTC. The harness has no moment emulation. A spec case that
  asserts moment-token output or parses a moment format string skips with
  `'diverges: <row id>'`.
- `flutter_chartjs` has no named time zones. A later optional package can add them on `timezone`
  `^0.11.2` (BSD-2-Clause, labs.dart.dev, pure Dart). That package imports only
  `package:timezone/timezone.dart`. It takes the zone from `adapters.date.zone`, as the luxon
  adapter does, and it uses the moment-timezone offset rule.
- Do not use `temporal` (0.1.3). Its web backend calls the browser `Temporal` global through
  `dart:js_interop` (ADR 0001). Safari has no `Temporal`. Its native build compiles Rust from
  source with cargo. Its native time-zone code gives wrong local midnights on some DST days. Its
  license is not detected, its repository returns 404, and it has no verified publisher.

**Evidence.**
- `scale.time.tests.js` mentions `moment` 85 times. Of 145 classified time-scale cases, 97 parse
  with moment format strings, 58 check moment-token text and 0 depend on DST.
- A `DateTime` prototype matched moment local mode on the VM, dart2js and dart2wasm for
  1970-2037.
- `temporal` on native gave 29 wrong local midnights in 9,130, against Python `zoneinfo`. The bug
  is in temporal_rs 0.2.6. It costs 0.23-0.44 µs per operation (AOT), 7-18× the cost of UTC
  `DateTime`.

**Open.**
- The `isoWeekday` rule: moment can move a date forward, but luxon and date-fns move it back.
- Whether `diff` returns fractions or truncates.
- Outside 1970-2037, the VM and dart2wasm compute local offsets from a substitute year. Thus only
  UTC gives the same ticks on every target.
- `timezone` has no DST transitions after 2037.
- `temporal` becomes a candidate for the optional zone package only after six changes:
  1. a web backend without JS interop
  2. prebuilt, checksummed binaries, or a build for each target architecture
  3. the DST fix
  4. a license file that pana detects, with notices for the bundled crates
  5. support for `code_assets` 2.x
  6. a verified publisher, a public repository and a stable 1.0

### 2.11 Chart.js ADR 0001: Theming (gate 1 for its four invariants, else 5)

[Chart.js ADR 0001](adr/0001-theming.md) and [theming.md](theming.md) own this decision. The flow
has three conditions. The theme hooks H0-H3 in `core.config` and H4a-H4c and H5 in
`plugin.colors` are `DIVERGES` hunks. The harness runs with no theme and with the colors plugin disabled. `lib/`
imports neither forui nor Material.

### 2.12 ADR: Toolchain pin and library floor (gate: the PR that moves `.fvmrc`)

**Decision.**
- Keep `.fvmrc` at 3.44.9. The evidence in this document comes from 3.44.9.
- Move the pin in its own PR when a measurement or the forui adapter (after 0.1.0,
  [theming.md](theming.md) §5.3) needs 3.47. That PR
  moves to 3.47.7 with the iOS deployment-target migration. It updates the toolchain lines of
  AGENTS.md Conventions and CONTRIBUTING.md Setup.
- That PR also adds a CI `floor` job on 3.44.9. It re-runs the sort probe and the cycle probe on
  3.47.7.
- Keep `flutter_chartjs` at `sdk: ^3.12.0`, `flutter: ">=3.44.0"`. Phase 9 sets the published floor.
- The floor job does not use `.github/actions/setup` (a root `flutter pub get`). It writes this
  `pubspec_overrides.yaml` in `packages/flutter_chartjs`, in CI only:

  ```yaml
  resolution:
  dependency_overrides:
    chartjs_test_utils:
      path: ../chartjs_test_utils
  ```

  It runs `dart analyze` (no lints), `flutter test` with a harness-based spec, and
  `flutter pub downgrade && flutter test`.
- Keep very_good_analysis at ^10.3.0 until the floor job exists.
- Do not move to 3.50 before two changes: a fix of cli_launcher #28 and a gallery on `material_ui`.

**Evidence.** On 3.47.7, all gates pass (`sdkfloor/logs/q2-*`). The floor job found a 3.47-only API
that the workspace analyzer missed. With only `resolution:`, a harness dev_dependency does not
resolve. On the 3.50 beta, `flutter/material.dart` is deprecated. `dart run melos` crashes on Dart
3.14.

### 2.13 Chart.js ADR 0011: Third-party sources (gate 1)

[Chart.js ADR 0011](adr/0011-third-party-sources.md) holds the complete decision and its
evidence. It supersedes Chart.js ADR 0005. In short:
- `third_party/kurkle-color` (`v0.3.2`) and `third_party/chartjs-test-utils` (`v0.4.0`) are
  reference-only shallow submodules. The phase 2 cleanup removed `third_party/pixelmatch`
  ([Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md)).
- `third_party/fdlibm/` holds unchanged netlib copies, because fdlibm has no git repository.
- `packages/flutter_chartjs/tool/port_sources.yaml` has one entry for each project. Tool 2 reads
  it.
- [ADR 0005](../../../docs/adr/0005-pin-upstream-sources.md) gives the reference-only rules.
  Dev-time tools can read and evaluate reference sources. Dart code never imports them. No tool
  builds them inside `third_party/`. No package ships them.

**Evidence** (2026-10-16). `.gitmodules` listed only Chart.js.

### 2.14 Chart.js ADR 0017: Element properties (gate 4)

[Chart.js ADR 0017](adr/0017-element-properties.md) (proposed) holds the decision, its evidence
and the items that stay open. In short:
- `Element` of `core.element.dart` is a concrete class. Each element class extends it and
  implements `types.VisualElement`. The static members `id`, `defaults`, `defaultRoutes` and
  `descriptors` keep the upstream contents and key order.
- An element class implements each method of `types.VisualElement`, also a method that its
  upstream class does not have. When the upstream caller tests for the method, the method gives
  the result of that test: `ArcElement.inXRange` and `ArcElement.inYRange` give false. Else the
  method throws a `NoSuchMethodError`.
- `types.PointElement` implements `SplinePoint`. Thus `element.line.dart` passes its point
  elements to `helpers.curve` without a cast.
- Each upstream property is a typed Dart member with the upstream name. A property that starts
  `undefined` has a nullable field. Its numeric getter gives NaN for `undefined`.
- `operator []` and `operator []=` give the access by name of phase 5. A Map of extra properties
  keeps the names that the class does not declare. The constructors write their `cfg` argument
  through `operator []=`, as `Object.assign` does.
- `getProps` returns the element itself or an `ElementProps` over a new Map. `tooltipPosition`
  and `getCenterPoint` return an `ElementPoint`.
- The JS form `value || 0` before arithmetic is `jsOrZero` of `lib/src/js/js_number.dart`. The
  port-only file `lib/src/js/js_webidl.dart` converts an option value for a Canvas 2D setter, as
  the WebIDL type of the DOM setter does (`canvasStyle`, `canvasNumber`, `canvasKeyword` and
  `canvasLineDash`). The controllers of phase 5 and the plugins of phase 8 use the same
  functions.
- `core.element.dart`, `lib/src/elements/` and `lib/src/js/js_webidl.dart` are pure layers. Their
  specs and tests run on the VM, with dart2js and with dart2wasm.

## 3. Test harness

**Package.** `packages/chartjs_test_utils` (`publish_to: none`) mirrors the npm package module by
module. It is a dev_dependency of `flutter_chartjs`. It also depends on `flutter_chartjs`. Probes
showed that the workspace resolves this cycle. The harness, its notices and the test font stay
outside the published archive. Port exactly 0.4.0 (`package.json:90`).

| Upstream (0.4.0) | Dart | Phase |
|---|---|---|
| — | `pure.dart` (spec set-up for `dart test`) | 2, done |
| `src/context.js`, `src/index.js` | `MockContext implements CanvasRenderingContext2D`, `createMockContext` | 3, done |
| `src/matchers.js`, `src/matchers.options.js` | matchers: `toBeCloseToPixel`, `toBeCloseToPoint`, `toEqualOneOf`, `toEqualOptions` | 3, done |
| — | test font (`installTestFont` of `flutter.dart`, [Chart.js ADR 0015](adr/0015-text.md)) | 3, done |
| `src/matchers.js` | `toBeValidChart`, `toBeChartOfSize` | 5 |
| `src/utils.js` | `acquireChart` (512×512, `animation: false`, `locale: 'en-US'`), `afterEvent`, `triggerMouseEvent`, `waitForResize` | 5 |
| `src/fixture.js` | `specsFromFixtures` as a smoke runner (prefix match, plugin rule, `run` hook), no image comparison | 7 |
| `src/spriting.js`; pixelmatch `index.js`; Canvas-call recordings | not ported (`n/a`): no image comparison ([Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md)) | — |
| `injectWrapperCSS`, `useShadowDOM`, `useOffscreenCanvas` | not ported (`n/a`) | — |

**Licensing.** The harness has no pixelmatch code. Thus its `LICENSE` has no ISC notice. Its
`LICENSE` has the SIL OFL 1.1 notice of the test font as a separate component
([Chart.js ADR 0015](adr/0015-text.md)).

**`test/index.js` equivalent.** From phase 3, `packages/flutter_chartjs/test/flutter_test_config.dart`
ports `test/index.js`. It translates DPR 1 (`:5`). The UTC zone line (`:23`) has no Dart
counterpart: the specs use the default date adapter in UTC (phase 6). The disabled colors plugin
(`:25-28`, phase 8) and `releaseCharts()` (`:34-36`, phase 5) come later. Two port-only hunks carry
`DIVERGES` markers and `harness-*` rows. Phase 3 added the file with DPR 1 and the two rows:
- `harness-defaults-restore`: the restore of `defaults` and `overrides` in `tearDown`, from a
  snapshot after the harness setup. It calls `setUpDefaultsRestore()` of `pure.dart`.
- `harness-test-font`: the test font install.

The colors plugin line comes in phase 8. `releaseCharts()` comes in phase 5.

The harness installs no theme ([Chart.js ADR 0001](adr/0001-theming.md)). Thus no ported spec
depends on the platform that flutter_test reports (`TargetPlatform.android`).

`dart test` does not read `flutter_test_config.dart`. Thus each pure-layer spec file calls the
same set-up from `package:chartjs_test_utils/pure.dart`. Phase 2 added `pure.dart`. It restores
`defaults` and `overrides` after each test. `pure.dart` is a port-only file. Thus its restore has no
`DIVERGES` marker and no row.

**Frames in tests.** The scheduling of [Chart.js ADR 0007](adr/0007-frame-scheduling.md) runs only
when the test pumps.
- A spec that reaches `requestAnimFrame` or `throttled` is a `testWidgets` test. In a plain
  `test()`, no frame runs.
- `setUp` runs outside the `FakeAsync` zone of `testWidgets`. Its timers are real. `clock.now()`
  there gives real time. Thus a ported `beforeEach` that acquires a chart runs at the
  start of each `testWidgets` body. 29 `beforeEach` blocks in 10 spec files acquire a chart.
- The harness helpers pump. `triggerMouseEvent` resolves after the throttled event callback. Specs
  call it 104 times in 13 files. `waitForResize` resolves after the next resize. Specs call it
  32 times in 2 files.
- A spec with `resizeDelay` pumps past the delay. `pumpAndSettle` does not wait for a `Timer`.

**Where tests run.**

| Suite | VM: `flutter test`, 3 OS | `dart test -p chrome -c dart2js` | `-c dart2wasm` |
|---|---|---|---|
| Pure-layer specs | yes | yes | yes |
| Other specs (`@TestOn('vm')`) | yes | no | no |
| Fixture smoke tests (`@Tags(['fixtures'])`) | ubuntu `fixtures` job | no | no |
| Flutter-only goldens | one pinned runner | no | no |

The tests of `packages/chartjs_test_utils` without `@TestOn('vm')` follow the pure-layer row. The
melos script `test:web` runs them in Chrome too (phase 3).

A pure-layer file is a file whose transitive imports reach neither `dart:ui` nor
`package:flutter`. The pure layers are `lib/src/js`, `lib/src/types`, `lib/src/kurkle_color`, the
canvas interface, the `core.defaults` closure, all helpers except `helpers.extras`, `core.element`
and the files of `lib/src/elements/` ([Chart.js ADR 0017](adr/0017-element-properties.md), section
10), and `platform.base`, `platform.basic` and `native_event` of `lib/src/platform/`.
`helpers.options` and `helpers.curve` import `helpers.canvas`. Thus the canvas interface must stay
free of `dart:ui` (2.2). Tool 1 computes the closure.

On 3.44.9, `dart test -p chrome` runs in a Flutter package with a `test` dev_dependency (probe).
`--tags` does not stop the compile of other files. `@TestOn('vm')` stops it. `flutter test` still
runs `@TestOn('vm')` files.

The matrix does not use `flutter test --platform chrome`. That flag is deprecated in 3.44.9. Its
JS leg compiles with DDC (`web_test_compiler.dart:113-176`), not with dart2js. `flutter build web`
uses dart2js.

**Fixture selection.** From phase 7 (tool 7), the melos `test` script passes
`--exclude-tags fixtures`. The `fixtures`
job runs `flutter test --tags fixtures` with a shallow submodule checkout. A fixture test skips
when the submodule is absent. It fails instead when `FIXTURES_REQUIRED=1`. Only that job sets
this variable. A `CI=true` rule cannot do this, because GitHub sets `CI=true` in every job.

## 4. Tooling owned by this flow

**1. Library import guard** (`tool/check_lib_imports.dart`, `check:lib-imports`, phase 1). The
melos script `check:port` and the CI job `port-checks` run tools 1-3. Tool 1 uses allowlists:
- `lib/`: `dart:async`, `collection`, `convert`, `core`, `math`, `typed_data` and `ui`, the
  `package:flutter/` libraries `foundation`, `gestures`, `painting`, `rendering`, `scheduler`,
  `semantics`, `services` and `widgets`, `package:meta/meta.dart`, `package:intl/intl.dart` with
  its `number_symbols` files, and the package's own files. From phase 2, also
  `package:collection/collection.dart` with `show mergeSort`. From phase 5, also
  `package:clock/clock.dart` ([Chart.js ADR 0010](adr/0010-js-numeric-semantics.md)).
- Pure layers: the same list without `dart:ui` and `package:flutter`, over the transitive closure.
- Test files without `@TestOn('vm')`: pure layers, `package:test` and `pure.dart` only.
- The harness: the closure of `packages/chartjs_test_utils/lib/pure.dart` is a pure layer. It
  imports only pure libraries, `package:test` and the pure layers of `flutter_chartjs`.
- Ported files: no import of `lib/src/theme/` ([Chart.js ADR 0001](adr/0001-theming.md)). `lib/`
  never imports `material`, `cupertino`, `material_ui` or `forui`.

**2. Header check** (`tool/check_port_headers.dart`, `check:headers`, phase 1). It examines
`packages/flutter_chartjs/{lib,test,tool}/**`. When `packages/chartjs_test_utils` exists, the
check also examines that package. It fails unless all of these conditions are true:
- Line 1 matches `^// Ported from (\S+) (v?\d+(?:\.\d+)*) (\S+) \(([^,]+), (.+)\)\.$` or the
  port-only marker. Files under `test/port/` and `tool/` have the port-only marker. A file at the
  mapped path of a source that exists at a pin does not have the port-only marker.
- Each next header line is a `// Ported from` line or matches
  `^// Upstream backport: chartjs/Chart\.js@[0-9a-f]{8} \(#\d+\)\.$`. `upstream_status.dart
  --check` pairs these lines with ledger rows.
- Project, license and holder match `tool/port_sources.yaml`, the package `LICENSE` and
  `REUSE.toml`.
- The source path exists at the pin. When a submodule is not checked out, the paths come from the
  `parity.md` links and the file lists in `port_sources.yaml`. The CI job `port-checks` checks out
  the submodules. Thus CI compares the paths with the pinned trees.
- The Dart path equals the mapped path. For Chart.js `src`, 2.5 gives the path. A spec for
  `test/specs/<base>.tests.js` is `test/specs/<base>_test.dart` (section 1, step 5).
  `test/index.js` maps to `test/flutter_test_config.dart`. For other projects,
  `tool/port_sources.yaml` gives the target.
- Each `DIVERGES` marker names a `differences.md` row. Each row has a marker. Marker lines fit 80
  columns, because the line-length exemption needs a path. A marker is a line comment. A
  `DIVERGES` block comment fails.

A Chart.js version older than `chartJsVersion` is stale. The header restamp belongs to
upstream-tracking.

**`differences.md` schema.** Each row is one difference. One or more `DIVERGES` hunks name it. Port-only files are not rows. The
columns are ID, Dart file and symbol, Upstream file@version:lines, Category, Reason, Upstream
reference, Pinning test and Re-check on bump. The ID is a hyphenated name that starts with the
lowercase category, for example `theme-H1`. It has an HTML anchor. The marker text after
`DIVERGES(chartjs): ` starts with the ID. A skip reason is `'diverges: <ID>'`. The categories are
`adapt`, `platform`, `theme`, `js-semantics`, `harness` and `not-followed`. The file comes with the first `DIVERGES` hunk.

**3. JS-semantics check** (`tool/check_js_semantics.dart`, `check:js-semantics`, phase 1). It
examines the `lib/` and `test/` files whose header block names a `js` project of
`tool/port_sources.yaml`. When `packages/chartjs_test_utils` exists, the check also examines that
package. It flags these forms:
- `.round()`, `.roundToDouble()`, `.floor()`, `.ceil()`, `.truncate()`, `.clamp(`, `%`, `pow(`
  with any base, every `.toString()` call, `is int` and `.sort(`. A `pow` call with `double`
  operands carries `// js-ok`.
- the `dart:math` functions `tan`, `asin`, `acos`, `atan`, `atan2`, `exp` and `log`. `sin` and
  `cos` are not flagged ([Chart.js ADR 0010](adr/0010-js-numeric-semantics.md)).
- the interpolation of a value with the static type `double` or `num`
- the calls and tear-offs of `dart:math` `max` and `min` with the type argument `double` or `num`.
  Use `jsMax` and `jsMin` ([Chart.js ADR 0010](adr/0010-js-numeric-semantics.md)).
- from phase 2, the sorts of `package:collection`: `mergeSort(`, `insertionSort(`, `.sorted(`,
  `.sortedBy(`, `.sortedByCompare(`, `.sortBy(`, `.sortByCompare(` and `.sortRange(`
- from phase 5, `DateTime.now(`

A site passes with `// js-ok: <reason>` at the end of its line, or alone on the line before it.
The lexical rules read the code without comments and strings. The interpolation rule and the
`max`/`min` rule resolve types with `package:analyzer`, a dev_dependency of `flutter_chartjs`.
[Chart.js ADR 0010](adr/0010-js-numeric-semantics.md) lists the forms that tool 3 does not find.

**4. Upstream manifest** (`tool/upstream_manifest/`, Node, `upstream:manifest`, job
`upstream-manifest`, mid phase 2). With `--src <checkout> --out <file>`, it writes
`packages/flutter_chartjs/doc/upstream/manifest.json` plus the fixture configs as JSON. A `vm` run of the
`describe` bodies finds the loop-generated cases: 163 cases from 26 `it` call sites in 8 spec files
at v4.5.1. 31 of them are in `helpers.easing`. Its fixture count becomes authoritative. It
also records the defaults inventory and the JS builtin sites. Only this tool and the reference
generators in `tool/reference/` need Node. They run on the porter's machine. In CI, only the
`upstream-manifest` job runs Node. The bump report and the watch preview read the committed
manifests or git.

**5. Spec-case tracking** (`tool/spec_cases.dart`, `test:cases` in the ubuntu test leg, mid phase
2). Each upstream case is `passed`, `failed`, `skipped(<reason>)` or `missing`. The tool fails on
unknown names. It also fails on `missing` cases in `ported` modules.

**6. Parity generator** (`tool/parity.dart`, `parity` and `parity:check`, phase 5). It derives the
Dart target from the headers. It adds case and fixture columns, plus sections for port-only files,
the Flutter input mapping and `test/types`. It also writes the `differences.md` row count by
category into the `parity.md` row of each file with `DIVERGES` hunks ([theming.md](theming.md)
§7).

**7. Fixture smoke runner** (`test:fixtures`, job `fixtures`, phase 7). It builds a chart from
each fixture config of a ported module and renders one frame. A test passes when no exception
occurs. The runner compares no pixels and keeps no ledger
([Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md)). It reads the configs that tool 4
writes and the hand-ported configs in `test/fixtures/hand/`.

**8. Port-order helper** (`tool/port_order.dart`, `port:next`, phase 5). It lists the ready
modules and the interfaces that each module needs.

**Node and ADR 0001.** A dev-time Node tool is not runtime. Nothing in `lib/` or `test/` loads it.
[ADR 0001](../../../docs/adr/0001-native-ports-not-wrappers.md) records this in its Decision.

## 5. Revised phases

The roadmap in `packages/flutter_chartjs/doc/README.md` changes for these reasons:
- `helpers.options.ts:3` and `helpers.curve.ts:2` import `toFontString` and `_isPointInArea`.
- `core.ticks.js:2` calls `formatNumber`. The log10 spec loop needs fdlibm.
- Elements import only `core.element` from core. 20 of 21 element cases need no chart.
- 14 of the 23 core, element and scale spec files call `acquireChart`. Thus phase exits count cases.
- Master (unreleased, milestone 4.6.0) fixes `retinaScale` (#12142). It also changes doughnut
  spacing (#12238). ADR 0006 decides both.

| Phase | Scope | Exit criteria |
|---|---|---|
| 0. Scaffold | done; the design documents | CI green |
| 1. Decisions, minimum tooling, pilot | done; gate 1-2 ADRs; pins (2.13); tools 1-3; pilot by hand: `helpers.math`, `lib/src/js`, `geometric.dart`, `isFinite` from `helpers.core` | 12 `helpers.math` cases pass on VM, dart2js and dart2wasm; log10 comparison passes on the netlib port; AGENTS.md revised from the pilot; tools 1-3 green; gate 1-2 ADRs accepted |
| 2. JS runtime, helpers, defaults | done; rest of `lib/src/js` and `lib/src/types`; helpers except `helpers.canvas` and `helpers.dom`, plus `toFontString` and `_isPointInArea`; `core.defaults` closure; @kurkle/color; null-vs-undefined resolver tests; `pure.dart`; tools 4-5 | 181 non-chart helper cases and 5 `core.defaults`/`core.ticks` cases pass on VM, pure-layer cases also on dart2js and dart2wasm; `test:cases` reports none missing. Result: 179 of the 181 helper cases pass. The 2 `helpers.color` cases that need a canvas pattern and gradient skip as `blocked: helpers.canvas`. `test/port/helpers/helpers.color_test.dart` tests the same behavior with test classes. `helpers.rtl` is in progress: `overrideTextDirection` and `restoreTextDirection` need the canvas layer. `src/helpers/index.ts` re-exports `helpers.dom`. Both wait for phase 3 |
| 3. Canvas, text, platform, harness | done; `lib/src/canvas`; rest of `helpers.canvas`; rest of `helpers.rtl`; `helpers.dom`; `src/helpers/index.ts`; `platform.*`; internal chart host; phase-3 harness rows | non-chart canvas and DOM cases pass; the 2 `helpers.color` canvas cases pass; text-metric probe recorded. Result: the five phase 3 spec files have 66 cases. 21 pass, 0 fail and 45 skip. The 12 non-chart `helpers.canvas` cases, the 4 `helpers.color` cases and the 5 `helpers.dom` cases with a Flutter equivalent pass. 28 cases skip as `blocked: core.controller`, 15 as `n/a` (CSS, the shadow DOM, DOM ids, iframes, a web worker) and 2 as `diverges: platform-relative-position`. `test:cases` reports 205 passed, 0 failed, 47 skipped and 0 missing cases in the 17 ported spec files. The text-metric probe ([text-metrics.md](text-metrics.md)) found all 80 widths equal to Chrome. Chart.js ADRs 0013-0015 record the gate 3 decisions (proposed) |
| 4. Elements | done; `core.element`, point, line, bar, arc, `elements/index`; the type members; `jsOrZero` and `js_webidl.dart` of `lib/src/js`; tool 1 roots | 20 of 21 element cases pass. Result: the five phase 4 spec files have 22 cases. 21 pass, 0 fail and 1 skips as `blocked: core.controller` (`element.line`, "should not cache path when animations are enabled"). 20 of the 21 element cases pass. `test:cases` reports 226 passed, 0 failed, 48 skipped and 0 missing cases in the 22 ported spec files. The port-only tests `test/port/core/core.element_test.dart` and `test/port/elements/` (the four elements and `index`) test the behavior that the specs do not test. Four generators of `tool/reference/` (point, line, bar and arc) write the reference data of the four element tests from an x64 build of Node.js v24.12.0. Chart.js ADR 0017 records the gate 4 decision (proposed). [performance.md](performance.md) §8 has the element draw cost on the Pixel 8a, on macOS and in Chrome with dart2wasm, and a number path in `toTRBL` and `toTRBLCorners` that cuts the bar draw time on macOS by about 12 % |
| 5. Core | `core.config` with hunks H0-H3 and their tests; registry to controller; phase-5 harness rows; tools 6 and 8 | non-chart core cases pass; others skipped `blocked: <module>` |
| 6. Scales | seven scales; default date adapter on `DateFormat` (ICU tokens) | non-chart scale cases pass; moment-token cases skip as `diverges` |
| 7. Controllers | bar first, then the other seven; fixture smoke runner | controller and earlier chart-blocked cases pass or have rows; fixture smoke tests pass for the ported types; gallery shows every type |
| 8. Plugins | seven plugins; hunks H4a-H4c and H5 and their tests; input adapter for legend and tooltip | plugin cases pass; `plugin.*` fixture smoke tests pass |
| 9. Flutter API and release | public widget on the host; theme API; keyboard and semantics; docs; published floor (2.12); pana | `flutter_chartjs` 0.1.0 on pub.dev |

### 5.1 Deferred plans

A deferred plan records work that the port does not do now, so that the phases above keep their
focus. The phases do not wait for a deferred plan. Each deferred plan names its revisit point and
its triggers.

| Plan | Revisit point | Triggers that bring it forward |
|---|---|---|
| [canvas-cuts-plan.md](canvas-cuts-plan.md): cuts of own code in the canvas layer and the chart host, the web matrix fix (work package W), and the removal of the circle batch and of the text rotation snap | After phase 8, before phase 9 | Phase 5 starts the `acquireChart` harness: the default spec canvas is 512 x 256 until cut 2 lands (plan §3.3). Ported code strokes or clips a path under a skew or a non-uniform scale on the web (plan §2.3). The toolchain pin moves to a stable Flutter release with the skwasm fixes (plan §4.2). Flutter batches `drawCircle` calls (plan §4.1). |

Keep each deferred plan current while the phases go on:
- A change that edits a file that a deferred plan cites updates the plan in the same commit: the
  file and line references, the code inventory, the tests that pin the behavior, and the
  estimates.
- A change that makes a step of the plan unnecessary, or adds a new reason for it, says so in the
  plan.
- A trigger that occurs brings the plan forward. Record the decision in the plan and in this
  table.
- At the revisit point, the maintainer decides which work packages to do, to change or to drop.

## 6. Changes to other files

**AGENTS.md.**
- Rules 1 and 6: [upstream-tracking.md](upstream-tracking.md) §2.5 has the final text.
- Rule 2: path mapping, file-name exception, underscore rules, `///` lines, package imports, the
  tool 2 header block and the `DIVERGES` marker. The backport line uses the text of
  upstream-tracking.md §2.5.
- Rule 3: spec names, skip reasons, `@TestOn('vm')`, `package:test` for pure layers, fixtures,
  `test/port/`.
- Rule 4: status vocabulary, tool 6. Rule 5: the tool 1 allowlist, the library floor and the four
  invariants of Chart.js ADR 0001.
- New rule: JS numeric semantics.
- Licensing: SunPro, OFL. Item 1 becomes "its notice in the `LICENSE` of the package that
  contains the code" (the harness for chartjs-test-utils, the adapter for forui code). Commands and
  Layout: new scripts, packages, pins, `tool/` files.
- Phase 2 applied the Commands and Layout revisions, the JS numeric rule, the spec skip reasons
  and `setUpSpecs`. The other revisions wait for their phases.

**Repository files.**
- Root `pubspec.yaml`: `packages/chartjs_test_utils` in `workspace:`, new melos scripts,
  `--exclude-tags fixtures` in `test` (phase 7), and every `third_party` submodule in `upstream`.
- `packages/flutter_chartjs`: `meta`, `intl: ^0.20.2`, `collection: ^1.19.1` (phase 2),
  `clock: ^1.1.2` (phase 5), the dev_dependencies `chartjs_test_utils`
  and `test`, and `dart_test.yaml` with the `fixtures` tag (phase 7). The PR that adds tool 2 adds the
  port-only marker to `lib/src/upstream.dart` and `test/upstream_test.dart`. Phase 1 added the
  dev_dependencies `test` and `analyzer` (for tool 3) and the two port-only markers.
- `ci.yaml`: phase 1 added a shallow `submodules: true` checkout in the ubuntu `test` leg (for
  `upstream_test.dart`) and in the job `port-checks` (tools 1-3). It also added the job `test-web`
  (dart2js and dart2wasm). Phase 2 added the job `upstream-manifest` (tool 4) and the `test:cases`
  step in the ubuntu `test` leg. Phase 7 adds the `fixtures` job.
- `.gitmodules`, `commitlint.yaml` (the `chartjs_test_utils` scope), CONTRIBUTING.md
  (pre-push list), the PR template, and `REUSE.toml` (harness, fdlibm, font). Phase 1 changed
  `.gitmodules`, the pre-push lists of CONTRIBUTING.md and the PR
  template, and the fdlibm tables of `REUSE.toml`. Phase 2 added the harness table of `REUSE.toml`
  and `test:cases` to the pre-push lists. It removed the pixelmatch entry of `.gitmodules`.

**ADRs and docs.**
- An accepted ADR does not change. A changed decision gets a new ADR that states the complete
  decision and supersedes the old ADR. The old ADR gets only the line "Superseded by".
- [ADR 0005](../../../docs/adr/0005-pin-upstream-sources.md) supersedes ADR 0002. It states the
  complete pin rules and the reference-only rules for dev-time tools.
  [ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md) supersedes ADR 0004. It
  states the backport rules without the status `verified`.
- [Chart.js ADR 0010](adr/0010-js-numeric-semantics.md) (2.3) supersedes Chart.js ADR 0002.
  [Chart.js ADR 0011](adr/0011-third-party-sources.md) (2.13) supersedes Chart.js ADR 0005.
  [Chart.js ADR 0012](adr/0012-dart-file-naming.md) (2.5) supersedes Chart.js ADR 0004. It adds
  the rule for the members of the type libraries.
- The phase 2 cleanup removed `third_party/pixelmatch` and its references. The Consequences of
  [Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md) have the list.
- A new ADR that supersedes ADR 0003 records `chartjs_test_utils`. The forui adapter change
  (after 0.1.0, [theming.md](theming.md) §5.3) records `flutter_chartjs_forui` and its
  `commitlint.yaml` scope.
- When the maintainers accept this plan, `packages/flutter_chartjs/doc/README.md` takes the phase table of
  section 5. `parity.md` takes the new phase numbers.

Phase 0 already made the index edits. `docs/README.md` links the six new documents.
`packages/flutter_chartjs/doc/prior-art/README.md` lists the forui survey.

## 7. Risks and open questions

**Risks**

The numbers of the risks do not change, because ADRs cite them. A risk that no longer applies
stays in the list as closed.
1. **Text metrics.** 374 `toBeCloseToPixel` assertions depend on Chrome's font metrics. Failures
   become `differences.md` rows, not looser matchers.
2. **Skia leaves flutter_tester.** Closed. The port compares no pixels
   ([Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md)).
3. **Map resolver speed on dart2js.** It is about 1.6× slower than V8 on the scriptable path.
   Typed resolvers come only after parity, behind the same specs.
4. **Reference drift.** Closed. The port has no Canvas-call recordings
   ([Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md)).
5. **File-name lint gap.** If `file_names` starts to examine the whole name, 2.5 needs a new form.
6. **Hot modules.** element.arc, core.datasetController, plugin.tooltip, plugin.filler,
   helpers.dom, helpers.canvas, core.scale, core.controller, scale.time, scale.radialLinear,
   plugin.colors and controller.bar change most often. Keep them at the strictest fidelity.
7. **Unpublished dev_dependency.** It is possible that pana rejects a dev_dependency on an
   unpublished package. Phase 9 runs pana first.

**Open questions**
- fdlibm or correctly rounded libm for `log10` and `atan2`? log10 differs in the last bit on
  7/5,909 inputs.
  [Chart.js ADR 0010](adr/0010-js-numeric-semantics.md) keeps fdlibm for now. V8 `main` moved
  `Math.log10` to a correctly rounded libm on 2026-05-11.
- Tooltip after touch lift: keep upstream parity (#7738), hide on tap-up, or fade?
- Research evidence: commit the archive of the 2026-10-16 probes under `tool/research/`, or keep it
  outside the repository?

## Appendix: evidence

The numbers in this document come from the research of 2026-10-16. Its scripts, probes,
prototypes and measurements are not in the repository. They are in one archive outside the
repository:
- `digest/`: findings with the verifier corrections
- `scripts-repo-flow/`, `out-repo-flow/`: the tool 4 prototypes and their output
- `golden-feas/`: `ledger-draft.csv`, `canvas2d.dart`, `pixelmatch.dart` (ISC header), recorder,
  recordings
- `jssem/`, `optrep/proto/`, `sdkfloor/logs/`: probes and the resolver prototype

If the maintainers commit the archive, its `REUSE.toml` annotation must name the ISC code in
`pixelmatch.dart`.
