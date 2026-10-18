# Chart.js porting flow

- Status: proposed
- Date: 2026-10-16
- Related: [Chart.js ADR 0001](adr/0001-theming.md), [theming.md](theming.md),
  [ADR 0004](../../../docs/adr/0004-follow-upstream-between-releases.md),
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
   Kurkela), fdlibm 5.3 (SunPro, Sun Microsystems, Inc.), chartjs-test-utils 0.4.0 (MIT,
   chartjs-test-utils Contributors) and pixelmatch 5.3.0 (ISC, Mapbox).
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
   match). Hand-port configs with functions to `test/fixtures/hand/`. Update the ledger rows.
7. **Status.** The values are `not started`, `in progress`, `partial` (with a symbol list),
   `ported`, `verified`, `replaced`, `distributed` and `n/a` (with a reason). Until tool 6 lands in
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

[ADR 0004](../../../docs/adr/0004-follow-upstream-between-releases.md) is common to all ports. The other
decisions in this section are for Chart.js only. Each of them becomes a file in
[`packages/flutter_chartjs/doc/adr/`](adr/) with the next free number. If a later port needs the same
decision, the decision moves to `docs/adr/`.

The gate 1 and gate 2 decisions are proposed ADR files now. Their subsections below keep a summary,
the link and the evidence that the ADR does not repeat. The other subsections stay proposals in
this document until their ADR files exist.

| Subsection | ADR | Gate |
|---|---|---|
| 2.1 | [Chart.js ADR 0006: Options representation and resolver](adr/0006-options-representation-and-resolver.md) | 2 |
| 2.3 | [Chart.js ADR 0002: JS numeric semantics](adr/0002-js-numeric-semantics.md) | 1 |
| 2.4 | [Chart.js ADR 0003: Type-only dependencies](adr/0003-type-only-dependencies.md) | 1 |
| 2.5 | [Chart.js ADR 0004: Dart file naming](adr/0004-dart-file-naming.md) | 1 |
| 2.9, `helpers.extras` and the animator frame source | [Chart.js ADR 0007: Frame scheduling](adr/0007-frame-scheduling.md) | 2 |
| 2.13 | [Chart.js ADR 0005: Third-party sources](adr/0005-third-party-sources.md) | 1 |

ADR 0004 (gate 1) belongs to [upstream-tracking.md](upstream-tracking.md).

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

### 2.2 ADR: Canvas model (gate 3)

**Decision.** A Canvas 2D-compatible layer over `dart:ui` lives in `lib/src/canvas/` (port-only):
- an `abstract interface class CanvasRenderingContext2D` with no `dart:ui` import, with images
  behind an opaque `CanvasImageSource` type
- a `dart:ui` implementation in a file that no helper imports
- a recorder implementation in the harness

The layer owns the Canvas 2D semantics that `dart:ui` lacks. The current path is outside
`save()`/`restore()`. Transforms apply when the code adds a point. `arcTo` and the arc sweep follow
Chromium. Non-finite arguments do nothing. Dashes restart for each contour. Phase 2 ports
`toFontString` and `_isPointInArea` (`helpers.canvas.dart` is `partial`).

`RenderView` already applies the device pixel ratio (DPR) at the root (`rendering/view.dart:70-72`,
`:267-270`). Thus the `dart:ui` context composes each transform on a base
`scale(1 / currentDevicePixelRatio)`. `retinaScale` stays a line-by-line port. The chart does not
apply the DPR two times. With that base, `clearCanvas` and the arc clip rectangle still map
onto the box. The fixture harness applies the root scale and rasterizes at `canvas.width` ×
`canvas.height`, for example with `OffsetLayer.toImage(pixelRatio:)`. A widget test with a
`tester.view.devicePixelRatio` other than 1 pins the base scale.

**Evidence.** Specs port 1:1 only against the mock context API: 24 methods and 9 setters
(chartjs-test-utils `src/context.js:102-146`).

### 2.3 Chart.js ADR 0002: JS numeric semantics (gate 1)

[Chart.js ADR 0002](adr/0002-js-numeric-semantics.md) holds the decision, the translation rules
and the evidence. In short:
- An unexported JS runtime in `lib/src/js/` represents the JS builtins. Ported files call it where
  upstream calls a builtin.
- The reference engine is V8 13.6 as Node.js v24.12.0 for x64 builds it. Reference data never
  come from a browser or from an arm64 Node.js.
- Each transcendental `Math` builtin that ported code calls is a pure-Dart netlib fdlibm port.
  Phase 2 adds `sin`, `cos` and `pow` for `helpers.easing`.
- Where the Dart SDK or a package that Flutter 3.44.9 pins gives the JS result, the port uses it.
  Ported code calls `dart:math` `max` and `min`. The port-only `jsSort` calls `mergeSort` of
  `package:collection`. `jsDateNow()` reads `clock.now()` of `package:clock`. The `FakeAsync` zone
  of `testWidgets` fakes that clock.
- Tool 3 enforces the translation rules. A site that keeps a flagged form for a stated reason
  carries `// js-ok: <reason>` at the end of its line, or alone on the line before it.

### 2.4 Chart.js ADR 0003: Type-only dependencies (gate 1)

[Chart.js ADR 0003](adr/0003-type-only-dependencies.md) holds the decision and its evidence. In
short, each declaration file becomes a library of `abstract interface class` declarations in
`lib/src/types/`. A member arrives when a ported caller needs it. A file that also needs a concrete
class of the same name imports the types library with the prefix `types`. A union waits for its
first ported caller. The `src/types/*.d.ts` rows become `distributed`.

### 2.5 Chart.js ADR 0004: Dart file naming (gate 1)

[Chart.js ADR 0004](adr/0004-dart-file-naming.md) holds the decision and its evidence. In short,
"Dart-cased" applies to identifiers. File and directory names keep the upstream spelling, for
example `lib/src/controllers/controller.polarArea.dart`. `simpleArc.dart` is the one file that
needs `// ignore_for_file: file_names`. Upstream `_`-prefixed exports drop the underscore. A
`_`-prefixed member that other modules read also drops the underscore. It carries `@internal`.

### 2.6 ADR: Visual verification (gate 3)

**Decision.** Reuse the upstream PNGs. Do not re-render references. Compare with pixelmatch 5.3.0
semantics (white alpha blend) and each fixture's top-level `threshold` (default 0.1) and
`tolerance` (default 0.001). Key the fixture ledger by fixture path plus PNG sha256. Run on Linux
with the default Skia software path of flutter_tester. Use Flutter-only goldens only for Flutter
behavior.

**Evidence.** A 596-line state machine replayed the Canvas calls of chart.js 4.5.1. 381/384
geometry and 208/208 sprite fixtures pass at upstream thresholds. The 3 failures pass at 0.05,
because DisplayList changes rectangle paths into `DrawRect`. pixelmatch 7.2.0 changes 33 results.

### 2.7 ADR: Input events and interaction state (gate 3)

**Decision.** Flutter input produces the DOM-named events that a browser fires. `PointerDeviceKind`
selects them, not the platform. `EVENT_TYPES` (`platform.dom.js:21-31`) and the `options.events`
filter stay unchanged. The chart claims only one `TapGestureRecognizer` (for `click`) in the
gesture arena. Thus parent scrollables keep their gestures. Events coalesce for each frame.
`platform.flutter.dart` replaces `platform.dom.js`. Keyboard and semantics are port-only.
- Phase 3 adds an internal chart host. The host is a port-only, unexported `RenderBox` plus
  `LeafRenderObjectWidget`. It owns the canvas layer and the `platform.flutter` listeners. Its
  contract names `computeDryLayout`. Phase 9 puts the public widget on top of it.
- [Chart.js ADR 0007](adr/0007-frame-scheduling.md) decides the scheduling. The host makes one
  throttled function for each `options.events` entry. One `throttled<Size?>` function takes the
  size and DPR changes. One post-frame callback takes attach and detach.
- The host takes the chart size from its layout, not from a `ResizeObserver`.
- The host reads the DPR with `MediaQuery.devicePixelRatioOf` and the ticker state with
  `TickerMode.valuesOf` in `createRenderObject` and `updateRenderObject`. `View.of` does not rebuild on a DPR change. The window `resize` listener
  and its global map (`platform.dom.js:161-189`) have no port.
- The scrollbar step of `platform.dom.js:198-209` has no port. A Flutter `Scrollbar` paints over
  its child and takes no layout width.
- The zero-size skip of `platform.dom.js:217-222` stays as a guard in the host. `Offstage` calls
  `layout` on its child with its own constraints (`proxy_box.dart:3918-3923`). Thus the child does
  not get the zero size of `display: none`. The harness emulates `display: none` with
  `SizedBox.shrink`.
- The event position comes from `PointerEvent.localPosition`. One `DIVERGES` hunk in
  `getRelativePosition` of `helpers.dom.dart` reads it. The port does not emulate the CSS math of
  `helpers.dom.ts:73-130`. The DOM-only spec cases skip as `n/a`.
- Flutter sends one event for each pointer. `platform.flutter.dart` builds a `touches` list,
  sorted by pointer id.
- `platform.flutter.dart` makes the destroyed-chart guard of `platform.dom.js:246` again.

**Evidence.** The pan recognizer of fl_chart breaks `PageView` (#202).

**Open.**
- Touch sizes (hit radius, hover radius, font size) and the tooltip after a touch lift (#7738).
  An amendment of Chart.js ADR 0001 decides the touch sizes in phase 9
  ([theming.md](theming.md) §11).
- The first size. Upstream sizes the chart at construction (spec
  `core.controller.tests.js:651`). The first observer notification uses `throttled`
  (spec `:712`). The host can size the chart only after its first layout. Thus the port paints
  one blank first frame. This ADR records it as a divergence or prevents it.
- `getMaximumSize` stays a port in `helpers.dom.dart`, with `DIVERGES` hunks for the DOM reads.
  `AspectRatio` has no `round1`, no `floor` and no `width / 2` fallback.
- Unbounded constraints: infinity to 0, or infinity to the current chart size? A chart larger
  than its box: paint outside the box, or clip?
- The factor `/ chart.width * canvas.width / currentDevicePixelRatio` of `getRelativePosition`:
  keep it for exact values at fractional sizes, or drop it?
- A harness detach without an unmount, for the specs that keep a detached chart across a task
  (`core.controller.tests.js:1065`, `:1147`, `:1179`). Without it, these specs skip as `n/a`.
- Touch scope: only the pointers that hit the chart, or all pointers through
  `GestureBinding.instance.pointerRouter.addGlobalRoute`? Upstream gives NaN coordinates on a
  `touchend` after the last finger lifts (`helpers.dom.ts:81-93`).

### 2.8 ADR: Text (gate 3)

**Decision.** `font` takes the CSS shorthand from `toFontString` and parses it into
`ui.TextStyle`. `measureText` builds a `ui.Paragraph` and returns `width` plus
`actualBoundingBox*`. The layer caches results for each font and text. The harness can replace
`fillText` and `measureText`.

**Open.** `toBeCloseToPixel` (0.5% or less than 2 px) occurs 374 times in 16 spec files. These
specs measure real fonts. The proposal is a metric-compatible OFL font in `chartjs_test_utils`.
Phase 3 measures the result.

### 2.9 ADR: Animation (gate 5), with Chart.js ADR 0007 for `helpers.extras` and the animator frame source (gate 2)

[Chart.js ADR 0007: Frame scheduling](adr/0007-frame-scheduling.md) holds the gate 2 part:
`requestAnimFrame`, `throttled` and `debounce` in `helpers.extras` (`helpers.extras.ts:14-61`),
and the frame source of the animator. `requestAnimFrame` calls
`SchedulerBinding.scheduleFrameCallback`. `throttled` coalesces calls to one in each frame.
`debounce` uses a `dart:async` `Timer`. `Chart.destroy()` cancels that `Timer`. `core.animator.js` stays
one module-level animator on `requestAnimFrame`. The chart host mutes a chart under
`TickerMode(enabled: false)`. Thus `core.animator.js` has two small `DIVERGES` hunks.
[Chart.js ADR 0002](adr/0002-js-numeric-semantics.md) gives the clock: `jsDateNow()` on
`clock.now()`. The rest of this subsection stays a proposal for ADR: Animation (gate 5).

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
- Format through `intl` (`^0.20.2`). This ADR selects the token dialect of the default adapter:
  moment tokens or ICU tokens.
- Read "now" through `jsDateNow()` ([Chart.js ADR 0002](adr/0002-js-numeric-semantics.md)),
  because `scale.time.js:342-343` calls `Date.now()`. A spec sets the time with `withClock` of
  `package:clock`. The fake time of `testWidgets` starts at the wall-clock time of the test start.
  It moves only by the pumped durations.
- The specs use a test adapter in `chartjs_test_utils`. It runs in UTC only. It matches
  chartjs-adapter-moment 1.0.1 with moment 2.29.4 and moment-timezone 0.5.42 in `Etc/UTC`. It has a
  small formatter and a lenient parser for the moment tokens that the specs use. Write it from the
  moment documentation as ideas only. A dev-time Node script can run the pinned moment to give
  expected values.
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
- The token dialect.
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
- That PR also adds a CI `floor` job on 3.44.9. It re-runs the replay suite, the renderer default,
  the sort probe and the cycle probe on 3.47.7.
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

### 2.13 Chart.js ADR 0005: Third-party sources (gate 1)

[Chart.js ADR 0005](adr/0005-third-party-sources.md) holds the decision and its evidence. In
short:
- `third_party/kurkle-color` (`v0.3.2`), `third_party/chartjs-test-utils` (`v0.4.0`) and
  `third_party/pixelmatch` (`v5.3.0`) are reference-only shallow submodules.
- `third_party/fdlibm/` holds unchanged netlib copies, because fdlibm has no git repository.
- `packages/flutter_chartjs/tool/port_sources.yaml` has one entry for each project. Tool 2 reads
  it.
- The ADR clarifies ADR 0002. Dev-time tools can read and evaluate reference sources. Dart code
  never imports them. No tool builds them inside `third_party/`. No package ships them.

**Evidence** (2026-10-16). `.gitmodules` listed only Chart.js.

## 3. Test harness

**Package.** `packages/chartjs_test_utils` (`publish_to: none`) mirrors the npm package module by
module. It is a dev_dependency of `flutter_chartjs`. It also depends on `flutter_chartjs`. Probes
showed that the workspace resolves this cycle. The harness, its notices, the test font and the
recordings stay outside the published archive. Port exactly 0.4.0 (`package.json:90`).

| Upstream (0.4.0) | Dart | Phase |
|---|---|---|
| — | `pure.dart` (spec set-up for `dart test`) | 2 |
| `src/context.js` | `MockContext implements CanvasRenderingContext2D` | 3 |
| `src/matchers.js`, `src/matchers.options.js` | matchers | 3 |
| `src/spriting.js`; pixelmatch `index.js` | `spriting.dart` plus sheet; `pixelmatch.dart` | 3 |
| — | test font, recordings | 3 |
| `src/utils.js` | `acquireChart` (512×512, `animation: false`, `locale: 'en-US'`), `afterEvent`, `triggerMouseEvent`, `waitForResize` | 5 |
| `src/fixture.js` | `specsFromFixtures` (prefix match, plugin rule, `run` hook) | 7 |
| `injectWrapperCSS`, `useShadowDOM`, `useOffscreenCanvas` | not ported (`n/a`) | — |

**Licensing.** pixelmatch is ISC ("Copyright (c) 2019, Mapbox"). Its code needs the notice in the
harness `LICENSE`, `LICENSES/ISC.txt`, a last-placed `REUSE.toml` annotation and the header
`// Ported from pixelmatch v5.3.0 index.js (ISC, Mapbox).`

**`test/index.js` equivalent.** `packages/flutter_chartjs/test/flutter_test_config.dart` ports
`test/index.js`. It translates DPR 1 (`:5`), the UTC zone (`:23`), the disabled colors plugin
(`:25-28`) and `releaseCharts()` (`:34-36`). Two port-only hunks carry `DIVERGES` markers and
rows:
- the restore of `defaults` and `overrides` in `tearDown`, from a snapshot after the harness setup
- the test font install.

The harness installs no theme ([Chart.js ADR 0001](adr/0001-theming.md)). Thus no ported spec
depends on the platform that flutter_test reports (`TargetPlatform.android`).

`dart test` does not read `flutter_test_config.dart`. Thus each pure-layer spec file calls the
same set-up from `package:chartjs_test_utils/pure.dart`.

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
| Fixtures and replay (`@Tags(['fixtures'])`) | ubuntu `fixtures` job | no | no |
| Flutter-only goldens | one pinned runner | no | no |

A pure-layer file is a file whose transitive imports reach neither `dart:ui` nor
`package:flutter`. The pure layers are `lib/src/js`, `lib/src/types`, `lib/src/kurkle_color`, the
canvas interface, the `core.defaults` closure and all helpers except `helpers.dom` and
`helpers.extras`. `helpers.options` and `helpers.curve` import `helpers.canvas`. Thus the canvas
interface must stay free of `dart:ui` (2.2). Tool 1 computes the closure.

On 3.44.9, `dart test -p chrome` runs in a Flutter package with a `test` dev_dependency (probe).
`--tags` does not stop the compile of other files. `@TestOn('vm')` stops it. `flutter test` still
runs `@TestOn('vm')` files.

The matrix does not use `flutter test --platform chrome`. That flag is deprecated in 3.44.9. Its
JS leg compiles with DDC (`web_test_compiler.dart:113-176`), not with dart2js. `flutter build web`
uses dart2js.

**Fixture selection.** The melos `test` script passes `--exclude-tags fixtures`. The `fixtures`
job runs `flutter test --tags fixtures` with a shallow submodule checkout. A fixture test skips
when the submodule is absent. It fails instead when `FIXTURES_REQUIRED=1`. Only that job sets
this variable. A `CI=true` rule cannot do this, because GitHub sets `CI=true` in every job.

**Renderer.** Never pass `--enable-impeller` to the fixture job. Re-run the full ledger on every
`.fvmrc` change.

## 4. Tooling owned by this flow

**1. Library import guard** (`tool/check_lib_imports.dart`, `check:lib-imports`, phase 1). The
melos script `check:port` and the CI job `port-checks` run tools 1-3. Tool 1 uses allowlists:
- `lib/`: `dart:async`, `collection`, `convert`, `core`, `math`, `typed_data` and `ui`, the
  `package:flutter/` libraries `foundation`, `gestures`, `painting`, `rendering`, `scheduler`,
  `semantics`, `services` and `widgets`, `package:meta/meta.dart`, `package:intl/intl.dart` with
  its `number_symbols` files, and the package's own files. From phase 2, also
  `package:collection/collection.dart`. From phase 5, also `package:clock/clock.dart`
  ([Chart.js ADR 0002](adr/0002-js-numeric-semantics.md)).
- Pure layers: the same list without `dart:ui` and `package:flutter`, over the transitive closure.
- Test files without `@TestOn('vm')`: pure layers, `package:test` and `pure.dart` only.
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

**`differences.md` schema.** Each row is one `DIVERGES` hunk. Port-only files are not rows. The
columns are ID, Dart file and symbol, Upstream file@version:lines, Category, Reason, Upstream
reference, Pinning test and Re-check on bump. The ID is a hyphenated name that starts with the
lowercase category, for example `theme-H1`. It has an HTML anchor. The marker text after
`DIVERGES(chartjs): ` starts with the ID. A skip reason is `'diverges: <ID>'`. The categories are
`adapt`, `platform`, `theme`, `js-semantics`, `harness` and `not-followed`. The file comes with the first `DIVERGES` hunk.

**3. JS-semantics check** (`tool/check_js_semantics.dart`, `check:js-semantics`, phase 1). It
examines the `lib/` and `test/` files whose header block names a `js` project of
`tool/port_sources.yaml`. It flags these forms:
- `.round()`, `.roundToDouble()`, `.floor()`, `.ceil()`, `.truncate()`, `.clamp(`, `%`, `pow(`
  with any base, every `.toString()` call, `is int` and `.sort(`
- the `dart:math` functions `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`, `exp` and `log`
- the interpolation of a value with the static type `double` or `num`
- from phase 2, the sorts of `package:collection`: `mergeSort(`, `insertionSort(`, `.sorted(`,
  `.sortedBy(`, `.sortedByCompare(`, `.sortBy(`, `.sortByCompare(` and `.sortRange(`
- from phase 5, `DateTime.now(`

A site passes with `// js-ok: <reason>` at the end of its line, or alone on the line before it.
The lexical rules read the code without comments and strings. The interpolation rule resolves
types with `package:analyzer`, a dev_dependency of `flutter_chartjs`.
[Chart.js ADR 0002](adr/0002-js-numeric-semantics.md) lists the forms that tool 3 does not find.

**4. Upstream manifest** (`tool/upstream_manifest/`, Node, `upstream:manifest`, job
`upstream-manifest`, mid phase 2). With `--src <checkout> --out <file>`, it writes
`packages/flutter_chartjs/doc/upstream/manifest.json` plus the fixture configs as JSON. A `vm` run of the
`describe` bodies finds the 31 loop-generated cases. Its fixture count becomes authoritative. It
also records the defaults inventory and the JS builtin sites. Only this tool and the Node
reference recorder of tool 7 need Node. They run on the porter's machine. In CI, only the
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

**7. Fixture runner and fixture ledger** (`test:fixtures`, `fixtures:update`, job `fixtures`).
Phase 3 brings the comparator, the replay suite and the ledger seed. Phase 7 brings the runner.
- `test/fixtures/ledger.csv` has one row for each fixture. The columns are fixture, png_sha256,
  kind, sprite, tolerance, threshold, replay, port, flutter and note. `flutter` is the SDK that
  last confirmed the row.
- The statuses are `pass`, `pass-relaxed: <threshold>`, `needs-real-font`, `needs-events`,
  `hand-config`, `blocked: <module>`, `not-started` and `fail: <issue>`.
- CI fails when a result differs from the ledger, or when a PNG hash is stale.
- The harness keeps all 592 Canvas-call recordings (about 0.5 MB compressed) as a replay suite.
- The Node reference recorder is a pinned part of tool 7. It pins `@kurkle/color` 0.3.2, because
  npm resolves `^0.3.0` to 0.3.4.

**8. Port-order helper** (`tool/port_order.dart`, `port:next`, phase 5). It lists the ready
modules and the interfaces that each module needs.

**Node and ADR 0001.** A dev-time Node tool is not runtime. Nothing in `lib/` or `test/` loads it.
A clarification in ADR 0001 records this.

## 5. Revised phases

The roadmap in `packages/flutter_chartjs/doc/README.md` changes for these reasons:
- `helpers.options.ts:3` and `helpers.curve.ts:2` import `toFontString` and `_isPointInArea`.
- `core.ticks.js:2` calls `formatNumber`. The log10 spec loop needs fdlibm.
- Elements import only `core.element` from core. 20 of 21 element cases need no chart.
- 14 of the 23 core, element and scale spec files call `acquireChart`. Thus phase exits count cases.
- Master (unreleased, milestone 4.6.0) fixes `retinaScale` (#12142). It also changes doughnut
  spacing (#12238). ADR 0004 decides both.

| Phase | Scope | Exit criteria |
|---|---|---|
| 0. Scaffold | done; the design documents | CI green |
| 1. Decisions, minimum tooling, pilot | gate 1-2 ADRs; pins (2.13); tools 1-3; pilot by hand: `helpers.math`, `lib/src/js`, `geometric.dart`, `isFinite` from `helpers.core` | 12 `helpers.math` cases pass on VM, dart2js and dart2wasm; log10 comparison passes on the netlib port; AGENTS.md revised from the pilot; tools 1-3 green; gate 1-2 ADRs accepted |
| 2. JS runtime, helpers, defaults | rest of `lib/src/js` and `lib/src/types`; helpers except `helpers.canvas` and `helpers.dom`, plus `toFontString` and `_isPointInArea`; `core.defaults` closure; @kurkle/color; null-vs-undefined resolver tests; `pure.dart`; tools 4-5 | 181 non-chart helper cases and 5 `core.defaults`/`core.ticks` cases pass on VM, pure-layer cases also on dart2js and dart2wasm; `test:cases` reports none missing |
| 3. Canvas, text, platform, harness | `lib/src/canvas`; rest of `helpers.canvas`; `helpers.dom`; `platform.*`; internal chart host; phase-3 harness rows; replay suite; ledger seed | non-chart canvas and DOM cases pass; replay reaches 381/384 geometry and 208/208 sprite; text-metric probe recorded |
| 4. Elements | `core.element`, point, line, bar, arc | 20 of 21 element cases pass |
| 5. Core | `core.config` with hunks H0-H3 and their tests; registry to controller; phase-5 harness rows; tools 6 and 8 | non-chart core cases pass; others skipped `blocked: <module>` |
| 6. Scales | seven scales; date adapters | non-chart scale cases pass |
| 7. Controllers | bar first, then the other seven; fixture runner | controller and earlier chart-blocked cases pass or have rows; replay-passing fixtures pass with the port; gallery shows every type |
| 8. Plugins | seven plugins; hunks H4a-H4c and H5 and their tests; input adapter for legend and tooltip | plugin cases pass; `plugin.*` ledger rows resolved |
| 9. Flutter API and release | public widget on the host; theme API; keyboard and semantics; docs; published floor (2.12); pana | `flutter_chartjs` 0.1.0 on pub.dev |

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
- Licensing: ISC, SunPro, OFL. Item 1 becomes "its notice in the `LICENSE` of the package that
  contains the code" (the harness for pixelmatch, the adapter for forui code). Commands and
  Layout: new scripts, packages, pins, `tool/` files.

**Repository files.**
- Root `pubspec.yaml`: `packages/chartjs_test_utils` in `workspace:`, new melos scripts,
  `--exclude-tags fixtures` in `test`, and every `third_party` submodule in `upstream`.
- `packages/flutter_chartjs`: `meta`, `intl: ^0.20.2`, `collection: ^1.19.1` (phase 2),
  `clock: ^1.1.2` (phase 5), the dev_dependencies `chartjs_test_utils`
  and `test`, and `dart_test.yaml` with the `fixtures` tag. The PR that adds tool 2 adds the
  port-only marker to `lib/src/upstream.dart` and `test/upstream_test.dart`. Phase 1 added the
  dev_dependencies `test` and `analyzer` (for tool 3) and the two port-only markers.
- `ci.yaml`: phase 1 added a shallow `submodules: true` checkout in the ubuntu `test` leg (for
  `upstream_test.dart`) and in the job `port-checks` (tools 1-3). It also added the job `test-web`
  (dart2js and dart2wasm). Add the `fixtures` and `upstream-manifest` jobs.
- `.gitmodules`, `commitlint.yaml` (the `chartjs_test_utils` scope), CONTRIBUTING.md
  (pre-push list), the PR template, and `REUSE.toml` (harness, fdlibm, sprite sheet, font,
  recordings). Phase 1 changed `.gitmodules`, the pre-push lists of CONTRIBUTING.md and the PR
  template, and the fdlibm tables of `REUSE.toml`.

**ADRs and docs.**
- ADR 0001 gets the Node clarification.
- [Chart.js ADR 0005](adr/0005-third-party-sources.md) (2.13) amends ADR 0002. The status line of
  ADR 0002 names it. The body of ADR 0002 stays as it is.
- ADR 0003 records `chartjs_test_utils`. The forui adapter change (after 0.1.0,
  [theming.md](theming.md) §5.3) records `flutter_chartjs_forui` and its `commitlint.yaml` scope.
- When the maintainers accept this plan, `packages/flutter_chartjs/doc/README.md` takes the phase table of
  section 5. `parity.md` takes the new phase numbers.

Phase 0 already made the index edits. `docs/README.md` links the six new documents.
`packages/flutter_chartjs/doc/prior-art/README.md` lists the forui survey.

## 7. Risks and open questions

**Risks**
1. **Text metrics.** 374 `toBeCloseToPixel` assertions depend on Chrome's font metrics. Failures
   become `differences.md` rows, not looser matchers.
2. **Skia leaves flutter_tester.** Impeller costs 26 geometry and 3 sprite passes. Use
   `pass-relaxed` rows with stated causes.
3. **Map resolver speed on dart2js.** It is about 1.6× slower than V8 on the scriptable path.
   Typed resolvers come only after parity, behind the same specs.
4. **Reference drift.** The recordings came from npm chart.js 4.5.1. In phase 3, build v4.5.1 in a
   throwaway clone outside the repository. Compare it with the npm dist and record the result.
5. **File-name lint gap.** If `file_names` starts to examine the whole name, 2.5 needs a new form.
6. **Hot modules.** element.arc, core.datasetController, plugin.tooltip, plugin.filler,
   helpers.dom, helpers.canvas, core.scale, core.controller, scale.time, scale.radialLinear,
   plugin.colors and controller.bar change most often. Keep them at the strictest fidelity.
7. **Unpublished dev_dependency.** It is possible that pana rejects a dev_dependency on an
   unpublished package. Phase 9 runs pana first.

**Open questions**
- Fixture PNGs: read from the submodule (about 21 MB) or vendored (about 15 MB)?
- The 31 real-font fixtures: re-render references or use Flutter-only goldens?
- fdlibm or correctly rounded libm? log10 differs in the last bit on 7/5,909 inputs.
  [Chart.js ADR 0002](adr/0002-js-numeric-semantics.md) proposes fdlibm for now. V8 `main` moved
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
