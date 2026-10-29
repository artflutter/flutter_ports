# Chart.js porting flow

- Status: proposed
- Date: 2026-10-16
- Related: [Chart.js ADR 0042](adr/0042-theming.md), [theming.md](theming.md),
  [ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md),
  [upstream-tracking.md](upstream-tracking.md)

This document defines how one module of the pinned Chart.js becomes Dart code in
`packages/flutter_chartjs_port`. This document contains the steps, the decisions, the test harness, the
per-module tooling and the phase plan. [upstream-tracking.md](upstream-tracking.md) owns the
upstream tooling (upstream ledger, status script, watch workflow, bump report, bump PR gate, header
restamp). This document owns the phase numbers, the ADR names, the module status vocabulary and
the `differences.md` schema.

## 1. Life cycle of one module port

1. **Choose.** Run `dart run melos run port:next` (tool 8, section 4). Pick a ready module of the
   current phase. Each value import of a ready module is done. Read the interfaces that the module
   needs. Declare each interface that is not declared, and add the members that the module reads
   (2.4). A blocked module waits for the modules that the list names. Run the module-start check
   ([upstream-tracking.md](upstream-tracking.md) §4.3). When the melos script `upstream:status`
   exists, it does this check. If a newer tag exists, the bump PR comes first.
2. **Read the source** at its pin (rule 1, 2.13). From phase 2, also read its manifest entry.
3. **Write the Dart file.**
   - Map the path (2.5). Line 1 is the rule-2 header.
   - Keep the upstream order and names. Use package imports only.
   - Give each public symbol a `///` line that names the upstream symbol and file:line.
   - Call `lib/src/js` for JS builtins (2.3). Import type-only dependencies from `lib/src/types`
     (2.4).
   - Mark each hunk that does not translate upstream lines with
     `// DIVERGES(chartjs): <row id>, <reason>` and a `differences.md` row (section 4).
   - Start a port-only file with `// Original code, not ported from Chart.js: <reason>.` Add its
     row to the `port-only` list of `doc/status.yaml`.
   - When two Dart forms give the upstream behavior, choose the faster form (1.1).

   ```dart
   // Ported from Chart.js v4.6.1 src/helpers/helpers.math.ts (MIT, Chart.js Contributors).
   import 'dart:math' as math;

   import 'package:flutter_chartjs_port/src/js/js_math.dart';

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
   ([Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md)).
5. **Port the specs.**
   - The path is `test/specs/<upstream base>_test.dart`. The header names
     `test/specs/<base>.tests.js`.
   - `group()` and `test()` names equal the `describe` and `it` names. The 10 duplicated names get
     ` #2` and ` #3`.
   - The skip reasons are `'blocked: <module>'`, `'n/a: <reason>'` and `'diverges: <row id>'`.
   - A case that needs a module of a later phase skips as `'blocked: <module>'`, with the missing
     module of the latest phase. A chart case that needs only ported modules passes through the
     harness of [Chart.js ADR 0022](adr/0022-chart-test-harness.md). Since the harness step of
     phase 5, no case skips as `'blocked: harness'`.
   - A spec file that reaches `dart:ui` or creates a chart has `@TestOn('vm')` directly below its
     header lines. A pure-layer spec file without a chart case uses `package:test` (section 3).
   - The harness restores `defaults` after each test. Port a `beforeAll` that changes `defaults`
     as `setUp` plus `tearDown`.
   - A spec that calls `push`, `pop`, `shift`, `splice` or `unshift` on a dataset `data` List calls
     `notifyArrayListeners(list, method, args)` after the change (row `platform-array-events`).
     Without the call, the chart resyncs at the next update and does not animate an insert.
   - Put tests of port-only behavior in `test/port/`.
6. **Fixtures.** From phase 7, each spec file with a fixture group calls
   `group('auto', fixture.specs('<prefix>'))` of `test/fixtures/index.dart` at the upstream line
   (upstream prefix match). Hand-port each impure config to `test/fixtures/hand/<path>.dart`, and
   add its entry to `handFixtures` ([Chart.js ADR 0029](adr/0029-fixture-smoke-runner.md)).
7. **Status.** The values are `not started`, `in progress`, `partial` (with a symbol list),
   `ported`, `replaced`, `distributed` and `n/a` (with a reason). `doc/status.yaml` holds the
   status text of each row. Tool 6 writes `parity.md` from it (section 4). Do not edit `parity.md`.
   A row that `status.yaml` does not list is `not started`. The upstream status script reads the
   same source. The first PR with a new value updates the legend in `status.yaml`. A module row
   goes to `ported` only in the change that lifts its `blocked: <module>` skips: tool 5 fails on a
   `blocked: <module>` skip when each `src/` row of the module is `ported`
   ([Chart.js ADR 0041](adr/0041-plugin-test-strategy.md) §8).
8. **Gallery.** When a chart type renders, update its entry in
   `apps/chartjs_gallery/lib/charts/chart_types.dart` (the status and the note, Chart.js ADR 0031
   §2).
9. **Gates.** Run `format:check`, `analyze`, `test --no-select`, `test:web` and `check:port`.
   Also run each other tool of section 4 that exists in that phase, and `upstream:ledger:check`
   when it exists.
10. **PR and merge.** Write a signed-off Conventional Commit. A backport adds a
    `// Upstream backport: chartjs/Chart.js@<sha8> (#<PR>).` line below the header, plus the
    trailers of [upstream-tracking.md](upstream-tracking.md) §4.2. The reviewer compares the Dart
    file with upstream, side by side.

### 1.1 Performance rule

When two or more Dart forms give the upstream behavior, choose the form with the larger measured
performance gain. The upstream behavior is the part that
[Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md) protects: the ticks, the hit
element, the item order, the resolved option, a throw, and a value that reaches a layout, a scale,
an element property, a hit test, a discrete decision or a public return value. A difference in
exact digits or pixels only does not block a faster form.

The order of priority is:
1. The upstream behavior.
2. Performance: frame rate, draw time and raster time on the three platforms of
   [performance.md](performance.md) (the Pixel 8a, macOS, Chrome with dart2wasm).
3. The upstream structure (AGENTS.md rule 2).
4. Less code of our own, for example the cuts of a deferred plan (§5.1).

Apply the rule in this way:
- Measure before you choose. A form with no measured gain keeps the upstream structure.
- A faster form that keeps the upstream structure needs no more records. An example is the number
  path of `toTRBL` ([performance.md](performance.md) §8.3).
- A `final` local for a repeated read of the same key of the same item in one loop pass keeps the
  structure under the one-read rule of [Chart.js ADR 0036](adr/0036-parsed-data.md) §8.
- A faster form that changes the upstream structure or the canvas calls gets a `DIVERGES` marker
  and an `adapt` row in `differences.md` (section 4). The row names the figure in
  `performance.md`. A port-only test pins the upstream behavior of both forms.
- Record each measured change in `performance.md`: the figures before and after, on each platform
  that it changes.
- A cut of our own code does not land when it makes a measured scenario slower. A faster form can
  add code, also to a file that a deferred plan cites. That change updates the plan in the same
  commit (§5.1).

[Chart.js ADR 0020](adr/0020-registry-and-component-classes.md) §13 gives this reading
of the rule for a gain that only a microbenchmark measures:
- A faster form that keeps the upstream structure can take such a gain. It needs no more records.
- A faster form that changes the upstream structure needs a gain in the frame figures of
  [performance.md](performance.md). These figures have a resolution of 0.1 ms. A smaller gain does
  not count for such a form.
- [Chart.js ADR 0019](adr/0019-animation.md) applies the same threshold to its
  alternative `NumberSlots`. The maintainer decides this reading of the rule.

## 2. Decisions

"Gate" is the first phase whose code depends on the ADR. Since 2026-10-21 the porting lead owns the
ADR statuses: it accepts an ADR when its decision is implemented and its gates are green. Before
that date, the maintainers accepted each ADR before
the first PR that depends on it. Phase 1 accepts the ADRs with gate 1 or 2. Phase 1 also accepted
the four invariants of Chart.js ADR 0001, because tool 1 and AGENTS.md rule 5 enforce them.
Chart.js ADR 0042 restates Chart.js ADR 0001 in full and supersedes it (2026-10-23).

[ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md) is common to all ports.
The other decisions in this section are for Chart.js only. Each of them becomes a file in
[`packages/flutter_chartjs_port/doc/adr/`](adr/) with the next free number. If a later port needs the same
decision, the decision moves to `docs/adr/`.

The gate 1 and gate 2 decisions are accepted ADR files now (2026-10-18). Their subsections below keep a summary,
the link and the evidence that the ADR does not repeat. Phase 3 wrote the gate 3 decisions (2.2,
2.7 and 2.8) as proposed ADR files (2026-10-19). Phase 3 also wrote Chart.js ADR 0016
(proposed), which changes one decision of the gate 2 part of 2.9. Phase 4 wrote the gate 4 decision (2.14) as the
proposed file of Chart.js ADR 0017 (2026-10-19). Phase 4 also wrote the gate 4 decision 2.15 as
the proposed file of Chart.js ADR 0018 (2026-10-19): the typed element options, for the option
reads that [performance.md](performance.md) §8.2 measured (§1.1). The subsections of the gate 3
and gate 4 decisions keep a summary and the link.
Phase 5 wrote the gate 5 decisions as the proposed files of Chart.js ADRs 0019-0022 (2026-10-19).
A design panel of three drafts, a judge and a synthesis wrote each of them. Their subsections are
2.9, 2.16, 2.17 and 2.18. The port of `core.datasetController` wrote Chart.js ADR 0023 (proposed,
2026-10-20): the names of underscore members that collide with a member of their class. 2.5 has
its summary. Chart.js ADRs 0013-0023 are accepted (2026-10-21). Phase 6 wrote Chart.js ADR 0025
(2026-10-20): the value parameters of the scales, the interface members that the scales need, the
names of their underscore members and the parsed read of phase 7. Its subsection is 2.19. Phase 6
also wrote Chart.js ADR 0024 (2026-10-20): the default date adapter, the zone, the calendar, and the
parse and format rules. A design panel of three drafts, a judge and a synthesis wrote it. Its
subsection is 2.10. The fixes of phase 6 wrote Chart.js ADR 0026 (2026-10-20): the number formatting
of Chart.js ADR 0008 with the six guards of `js_intl.dart`. 2.3 has its summary. Chart.js ADRs 0024,
0025 and 0026 are accepted (2026-10-20). Chart.js ADR 0026 supersedes Chart.js ADR 0008.
Phase 7 wrote the gate 7 decisions as the proposed files of Chart.js ADRs 0027-0031 (2026-10-21).
A design panel of three drafts, a judge and a synthesis wrote each of them. Their subsections are
2.20 (Chart.js ADR 0027), 2.21 (Chart.js ADR 0028), 2.22 (Chart.js ADR 0029, written with the
fixture runner in step 4) and 2.23 (Chart.js ADR 0030). Chart.js ADR 0031 (the gallery chart
types) changes no rule of this flow. Thus it has no subsection. Chart.js ADRs 0027, 0028, 0030
and 0031 are accepted (2026-10-21). Chart.js ADR 0029 is accepted too (2026-10-21). Phase 7 also
wrote Chart.js ADR 0033 (2026-10-21): the `undefined` centers of a radial scale before the first
layout. It is accepted, and it supersedes the `xCenter` and `yCenter` bullet of Chart.js ADR 0025
§5. Its subsection is 2.19. Phase 7 also wrote Chart.js ADRs 0032, 0034 and 0035 (2026-10-21).
Chart.js ADR 0032 states the complete numeric rules, with `jsSin` and `jsCos`, and supersedes
Chart.js ADR 0010. Chart.js ADR 0034 supersedes Chart.js ADR 0009, and Chart.js ADR 0035
supersedes Chart.js ADR 0011. The three are accepted (2026-10-21). Their subsections are 2.3
(Chart.js ADR 0032), 2.2, 2.3, 2.6 and 2.10 (Chart.js ADR 0034) and 2.13 (Chart.js ADR 0035). The
review of phase 7 wrote Chart.js ADR 0036 (2026-10-21): the complete decision of Chart.js ADR 0027
with the zone name of `jsToString` and the cast of each parsing key inside the loop. It supersedes
Chart.js ADR 0027 and is accepted (2026-10-21). Its subsection is 2.20. Phase 8 wrote Chart.js
ADRs 0037-0042 (2026-10-22) and Chart.js ADR 0043 (2026-10-23): the input path of the legend and
the tooltip (0037), the plugin modules, class values and interfaces (0038), the tooltip model and
animation (0039), the filler targets and the plain points (0040), the plugin test strategy (0041),
the theming (0042) and the options representation with a `helpers.merge` into an element target
(0043). The porting lead accepted Chart.js ADRs 0038-0043 at the end of step 7 of phase 8
(2026-10-23). Chart.js ADR 0042 supersedes Chart.js ADR 0001, and Chart.js ADR 0043 supersedes
Chart.js ADR 0006. The porting lead accepted Chart.js ADR 0037 after the device check of step 8
(2026-10-29). It supersedes Chart.js ADR 0014. Their subsections are 2.1 (Chart.js ADR 0043), 2.7
(Chart.js ADR 0037), 2.11 (Chart.js ADR 0042) and 2.24 (Chart.js ADRs 0038-0041). The other
subsections stay proposals in this document until their ADR files exist.

| Subsection | ADR | Gate |
|---|---|---|
| 2.1 | [Chart.js ADR 0043: Options representation and resolver](adr/0043-options-representation-and-resolver.md), which supersedes Chart.js ADR 0006 | 2 |
| 2.3 | [Chart.js ADR 0045: Reference engine on arm64](adr/0045-reference-engine-arm64.md), which supersedes Chart.js ADR 0032 | 1 |
| 2.4 | [Chart.js ADR 0003: Type-only dependencies](adr/0003-type-only-dependencies.md) | 1 |
| 2.5 | [Chart.js ADR 0012: Dart file naming](adr/0012-dart-file-naming.md), which supersedes Chart.js ADR 0004 | 1 |
| 2.13 | [Chart.js ADR 0035: Third-party sources](adr/0035-third-party-sources.md), which supersedes Chart.js ADR 0011 | 1 |
| 2.3, number formatting | [Chart.js ADR 0026: Number formatting on package:intl](adr/0026-number-formatting-on-package-intl.md), which supersedes Chart.js ADR 0008 | 2 |
| 2.2, 2.3, 2.6, 2.10 | [Chart.js ADR 0034: No display-only JS exactness](adr/0034-no-display-only-js-exactness.md), which supersedes Chart.js ADR 0009 | 2 |
| 2.2 | [Chart.js ADR 0013: Canvas model](adr/0013-canvas-model.md) | 3 |
| 2.7 | [Chart.js ADR 0037: Legend and tooltip input path](adr/0037-legend-and-tooltip-input-path.md), which supersedes Chart.js ADR 0014 | 3 |
| 2.8 | [Chart.js ADR 0015: Text](adr/0015-text.md) | 3 |
| 2.11 | [Chart.js ADR 0042: Theming](adr/0042-theming.md), which supersedes Chart.js ADR 0001 | 1 for the four invariants, else 5 |
| 2.9, `helpers.extras` and the animator frame source | [Chart.js ADR 0016: Frame scheduling](adr/0016-frame-scheduling.md), which supersedes Chart.js ADR 0007 | 2 |
| 2.14 | [Chart.js ADR 0017: Element properties](adr/0017-element-properties.md) | 4 |
| 2.15 | [Chart.js ADR 0018: Typed element options](adr/0018-typed-element-options.md) | 4 |
| 2.9 | [Chart.js ADR 0019: Animation](adr/0019-animation.md) | 5 |
| 2.16 | [Chart.js ADR 0020: Registry and component classes](adr/0020-registry-and-component-classes.md) | 5 |
| 2.17 | [Chart.js ADR 0021: Typed options in the resolver](adr/0021-typed-options-in-the-resolver.md) | 5 |
| 2.18 | [Chart.js ADR 0022: Chart test harness on Flutter](adr/0022-chart-test-harness.md) | 5 |
| 2.5 | [Chart.js ADR 0023: Underscore members with a colliding name](adr/0023-underscore-member-collisions.md) | 5 |
| 2.10 | [Chart.js ADR 0024: Dates](adr/0024-dates.md) | 6 |
| 2.19 | [Chart.js ADR 0025: Scale value parameters](adr/0025-scale-value-parameters.md) | 6 |
| 2.20 | [Chart.js ADR 0036: Parsed data in the controllers](adr/0036-parsed-data.md), which supersedes Chart.js ADR 0027 | 7 |
| 2.21 | [Chart.js ADR 0028: Controller interfaces and values](adr/0028-controller-interfaces.md) | 7 |
| 2.22 | [Chart.js ADR 0029: Fixture smoke runner](adr/0029-fixture-smoke-runner.md) | 7 |
| 2.23 | [Chart.js ADR 0030: Controller test strategy](adr/0030-controller-test-strategy.md) | 7 |
| 2.19, `xCenter` and `yCenter` | [Chart.js ADR 0033: Radial scale centers before the first layout](adr/0033-radial-scale-centers.md), which supersedes Chart.js ADR 0025 §5 in part | 7 |
| 2.24 | [Chart.js ADR 0038: Plugin modules, class values and interfaces](adr/0038-plugin-modules-class-values-and-interfaces.md) | 8 |
| 2.24 | [Chart.js ADR 0039: Tooltip model and animation](adr/0039-tooltip-model-and-animation.md) | 8 |
| 2.24 | [Chart.js ADR 0040: Filler targets and plain points](adr/0040-filler-targets-and-plain-points.md) | 8 |
| 2.24 | [Chart.js ADR 0041: Plugin test strategy](adr/0041-plugin-test-strategy.md) | 8 |

ADR 0006 (gate 1) belongs to [upstream-tracking.md](upstream-tracking.md).

### 2.1 Chart.js ADR 0043: Options representation and resolver (gate 2)

[Chart.js ADR 0043](adr/0043-options-representation-and-resolver.md) holds the decision and its
evidence. It restates Chart.js ADR 0006 with `helpers.merge` into an element target, and
supersedes it. In short:
- Scopes are `Map<String, Object?>`. An absent key, a stored const `undefined` sentinel and Dart
  `null` (JS `null`) stay three separate states.
- `Resolver` and `ContextResolver` replace the Proxy traps. They are line-by-line ports of
  `helpers.config.ts` and the scope part of `core.config.js`.
- Release 0.1.0 accepts raw Map configs. A typed options API comes after 0.1.0, with its own ADR
  ("ADR: Typed options API").

The ADR corrects one line reference of the earlier evidence. `Object.keys` enumerates the
declared-key marker at `core.datasetController.js:817`, not at `:818`.

### 2.2 Chart.js ADR 0013: Canvas model (gate 3)

[Chart.js ADR 0013](adr/0013-canvas-model.md) holds the decision and its evidence. In
short:
- `lib/src/canvas/canvas.dart` is the pure Canvas 2D interface, with `Path2D` and the port-only
  `CanvasNode` and `CanvasContainer`. The `dart:ui` implementation is `canvas_ui.dart` and four
  parts. No helper imports it. The harness has `MockContext`.
- `UiCanvasContext` keeps a retained bitmap as a list of pictures. A full `clearRect` drops the
  list. A partial clear paints inside a layer. More than 8 pictures flatten into one image.
- The pictures are in bitmap (device-pixel) space. `paint` maps the bitmap pixels with the scale
  of the host. `retinaScale` stays a line-by-line port. This replaces the base scale of the first
  proposal.
- The layer keeps only the Canvas 2D semantics that change behavior, with no Chromium-exact arc
  math ([Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md)).

### 2.3 Chart.js ADR 0045: Reference engine on arm64 (gate 1)

[Chart.js ADR 0045](adr/0045-reference-engine-arm64.md) holds the complete decision, the
translation rules and the evidence. It supersedes Chart.js ADR 0032. Chart.js ADR 0032
superseded Chart.js ADR 0010. Chart.js ADR 0010 superseded Chart.js ADR 0002.
[Chart.js ADR 0026](adr/0026-number-formatting-on-package-intl.md) holds the number formatting
decision, with six guards against package:intl failures. It supersedes
[Chart.js ADR 0008](adr/0008-number-formatting-on-package-intl.md).
[Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md) holds the principle of no
display-only JS exactness. In short:
- An unexported JS runtime in `lib/src/js/` represents the JS builtins. Ported files call it where
  upstream calls a builtin.
- The reference engine is V8 13.6 as Node.js v24.22.1 for darwin-arm64 builds it. The fdlibm
  data stay the data of the x64 Node.js v24.12.0. Reference data never come from a browser.
- `Math.log10`, `Math.atan2`, and `Math.sin` and `Math.cos` at a protected site, are pure-Dart
  netlib fdlibm ports, because their last bit changes log-scale ticks and hit tests. A protected
  site is a site whose result reaches a layout, a scale, an element property, a hit test, a value
  that a public member returns or a discrete decision. The other `Math.sin` and `Math.cos` calls
  and `Math.pow` use `dart:math` with `double` operands.
- `Math.max` and `Math.min` with `double` operands are `jsMax` and `jsMin` of
  `lib/src/js/js_math.dart`. On dart2wasm, these functions compare the operands in their own
  code, because the generic `dart:math` `max` and `min` box `double` operands there. On the VM
  and dart2js, they call `dart:math` `max` and `min`. With `int` operands, ported code calls
  `dart:math` `max` and `min`.
- `Math.pow(x, 2)` is `jsSquare(x)` of `lib/src/js/js_math.dart`, which returns `x * x`. The
  product is correctly rounded. On the x64 engine, `Math.pow(x, 2)` gave the bits of `x * x`
  for all of 23 million probe inputs. Thus the result is the JS result on every target.
  `ToNumber` of a `double?` value whose `null` is JS `null`, such as `Point.x` and `Point.y`, is
  `(e ?? 0)`, not `jsToNumber(e)`.
- Where the Dart SDK or a package that Flutter 3.47.7 depends on gives the JS result, the port
  uses it. The port-only `jsSort` calls `mergeSort` of `package:collection`. `jsDateNow()` reads
  `clock.now()` of `package:clock`. The `FakeAsync` zone of `testWidgets` fakes that clock.
- `Intl.NumberFormat` is the `NumberFormat` of `package:intl`. The port-only adapter
  `lib/src/js/js_intl.dart` maps the JS locale and options onto it
  ([Chart.js ADR 0026](adr/0026-number-formatting-on-package-intl.md)). Its guards write the V8
  digits where package:intl fails: from `2^53`, in scientific notation, with more than 15
  fraction digits, and the affixes of NaN and the infinities. A string that differs from
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
[Chart.js ADR 0023](adr/0023-underscore-member-collisions.md) adds one rule. When the
class or a superclass already has a member with the name without the underscore, the Dart name
gets a trailing underscore: `_update` is `update_`, and `_getSharedOptions` is
`getSharedOptions_`. The `_dataset` of the meta is `ChartMeta.dataset_`.
Chart.js ADR 0025 applies the rule to the `_` members that only a spec reads, as
`Chart.metasets` does: `unit`, `adapter`, `pointLabels` and `pointLabelItems` drop the underscore
and carry `@internal`.

### 2.6 Chart.js ADR 0034: No display-only JS exactness, image comparison part (gate 2)

[Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md) holds the decision. In short, the
port does not compare its renders with the upstream PNGs. It has no pixelmatch port, no
Canvas-call replay suite and no fixture ledger. The fixture configs run as smoke tests (tool 7).
Flutter goldens of the port test only Flutter behavior.

### 2.7 Chart.js ADR 0037: Legend and tooltip input path (gate 3)

[Chart.js ADR 0037](adr/0037-legend-and-tooltip-input-path.md) (accepted 2026-10-29) holds the
decision, its evidence and the items that stay open. In short:
- `platform.flutter.dart` replaces `platform.dom.js` with the upstream names. The port-only
  `NativeEvent` stands in for the DOM event. `detectPlatform` tests for a chart host.
- The internal chart host (`ChartHost`, `RenderChartHost`) sizes the chart in its first layout,
  before the first paint. Later size and DPR changes go through one `throttled<Size?>` function.
  Unbounded constraints give the canvas default of 300 x 150. Paint clips a larger chart.
- `PointerDeviceKind` selects the DOM event names of Chrome. The host reads raw pointer events and
  claims nothing in the gesture arena: its own click rule gives `click`. Parent scrollables keep
  their drags, and tappable ancestors also get the tap. A touch tap gives the compatibility mouse
  events, and a tap outside gives `mouseout` to the chart of the last tap.
- `getRelativePosition` keeps `Math.round` and drops the CSS math and the DPR factor (row
  `platform-relative-position`).
- The canvas has the `width` and `height` attributes of the DOM. `initCanvas` and
  `releaseContext` read and restore them line by line. Thus the default spec canvas of
  `acquireChart` is 512 x 512. Paint maps the bitmap to the display size with one scale for each
  axis.

### 2.8 Chart.js ADR 0015: Text (gate 3)

[Chart.js ADR 0015](adr/0015-text.md) holds the decision and its evidence. In short:
- `parseCanvasFont` parses the CSS shorthand of `toFontString`. Generic families stay family
  names. `measureText` and `fillText` use one `ui.Paragraph` for each font and text, in LRU caches.
- The harness installs Liberation Sans 2.1.5 (SIL OFL 1.1) under the families of the Chart.js
  default font and `sans-serif`.
- The text-metric probe ([text-metrics.md](text-metrics.md)) found all 80 widths equal to the
  Chrome widths. Baseline offsets differ by less than 1 px. These differences are display-only.

### 2.9 Chart.js ADR 0019: Animation (gate 5), with Chart.js ADR 0016 for `helpers.extras` and the animator frame source (gate 2)

[Chart.js ADR 0016: Frame scheduling](adr/0016-frame-scheduling.md) holds the gate 2 part:
`requestAnimFrame`, `throttled` and `debounce` in `helpers.extras` (`helpers.extras.ts:14-61`),
and the frame source of the animator. `requestAnimFrame` calls
`SchedulerBinding.scheduleFrameCallback`. `throttled` coalesces calls to one in each frame.
`debounce` uses a `dart:async` `Timer`. `Chart.destroy()` cancels that `Timer`. `core.animator.js` stays
one module-level animator on `requestAnimFrame`. `TickerMode(enabled: false)` mutes a chart
(the last bullet of this section). Thus `core.animator.js` has two small `DIVERGES` hunks for the
mute: the mute and the skip of a muted chart. Its third row is the promise checkpoint (see below).
[Chart.js ADR 0045](adr/0045-reference-engine-arm64.md) gives the clock: `jsDateNow()` on
`clock.now()`.

Chart.js ADR 0016 (accepted 2026-10-21) supersedes Chart.js ADR 0007. It states the complete
scheduling decision again and changes decision 9 of Chart.js ADR 0007. The first layout of the
chart host reports the attach at once, inside `performLayout`
([Chart.js ADR 0037](adr/0037-legend-and-tooltip-input-path.md), section 3). A canvas swap reports
the detach of the old canvas at once, during the build. Chart.js ADR 0016 keeps the other eleven
decisions with their numbers.

[Chart.js ADR 0019: Animation](adr/0019-animation.md) (phase 5) holds the gate 5
decision, its evidence and the items that stay open. In short:
- `core.animation`, `core.animations` and `core.animator` are line-by-line ports on the
  module-level animator of Chart.js ADR 0016, with `jsDateNow()` on `clock.now()`.
- An animation reads and writes its target by name, and keeps the `undefined` state.
- A promise checkpoint (`lib/src/js/js_promise.dart`) runs the promise jobs of an animator frame
  callback at the end of that callback, as a browser does. Without it, a re-hover in the frame
  that ends a 400 ms un-hover gives a wrong resolved option.
- Three `adapt` hunks make the frame cheaper: a typed animation config, a number path on
  `double` values and a color cache for each animation. The checkpoint is a `platform` hunk for
  the behavior: the resolved option.
- Reduced motion has no code in the core. The phase 9 widget decides it. The theme modes need no
  code. Until phase 9, a theme removal under reduced motion animates for 1000 ms
  ([theming.md](theming.md) §11).
- 15 of the 16 cases of the three animation specs pass. One case of `core.animator` needs a bar
  chart. It skips as `'blocked: controller.bar'`.
- The specs with a `done` callback are `testWidgets` cases. They wait with `setTimeout` and
  `waitForDone` of the harness (section 3, "Frames in tests").
- The chart host owns no chart (Chart.js ADR 0037 §2). It reports the ticker state through
  `ChartHost.onTickerModeChanged`. The owner of a chart connects it to `animator.mute` and
  `animator.unmute`. The owner also mutes a chart that it creates under
  `TickerMode(enabled: false)`. The gallery `ChartCanvas` does this. The phase 9 widget does it
  for the public API.

### 2.10 Chart.js ADR 0024: Dates (gate 6)

[Chart.js ADR 0024](adr/0024-dates.md) holds the decision and its evidence. In short:
- `DateAdapterBase.prototype` starts with the default members of the port-only
  `date_adapter.dart`. `_date` stays the base class `DateAdapterBase`. A member of the exact Dart
  type of its method gets a typed direct call. Five port-only pure files
  `lib/src/core/date_*.dart` hold the adapter. The time scale keeps its adapter in the
  `@internal` field `adapter` (`_adapter`, Chart.js ADR 0025 §6).
- The members follow chartjs-adapter-moment 1.0.1 on moment 2.29.4: the `isoWeekday` clamp and
  the forward rule, `add` with `absRound`, `diff` with `absFloor` and `monthDiff`, and the week
  start of the locale.
- The default zone is local time. The harness ports `test/index.js:23` as
  `setDefaultDateZone('Etc/UTC')`.
- `format` takes ICU patterns. The default formats give the moment en_US text, also the lower-case
  day period, because it changes the ticks. A spec case with a moment format string skips as
  `'diverges: adapt-date-moment-format'`. A port-only twin with ICU patterns tests the same
  behavior.
- `parse` reads ISO 8601 with the moment grammar, RFC 2822, the ASP.NET form, and a format string
  through intl with the current-date fill. Other strings, Lists and Maps are invalid (row
  `adapt-date-parse-fallback`).
- "Now" is `jsDateNow()` ([Chart.js ADR 0045](adr/0045-reference-engine-arm64.md)), because
  `scale.time.js:342-343` calls `Date.now()`. A step of `_generate` that does not advance throws a
  `StateError` (row `adapt-time-generate-no-advance`).

**Later zone package.** `flutter_chartjs_port` has no named time zones. A later optional package can
add them on `timezone` `^0.11.2` (BSD-2-Clause, labs.dart.dev, pure Dart). That package imports
only `package:timezone/timezone.dart`. It takes the zone from `adapters.date.zone`, as the luxon
adapter does, and it uses the moment-timezone offset rule. `timezone` has no DST transitions
after 2037. The ADR of the package decides named zones, the rules after 2037 and a zone option for
each scale (Chart.js ADR 0024, Open 4).

**`temporal`.** Do not use `temporal` (0.1.3). Its web backend calls the browser `Temporal` global
through `dart:js_interop` (ADR 0001). Safari has no `Temporal`. Its native build compiles Rust from
source with cargo. Its native time-zone code gives wrong local midnights on some DST days: on
native it gave 29 wrong local midnights in 9,130, against Python `zoneinfo`. The bug is in
temporal_rs 0.2.6. It costs 0.23-0.44 µs per operation (AOT), 7-18× the cost of UTC `DateTime`.
Its license is not detected, its repository returns 404, and it has no verified publisher.
`temporal` becomes a candidate for the optional zone package only after six changes:
1. a web backend without JS interop
2. prebuilt, checksummed binaries, or a build for each target architecture
3. the DST fix
4. a license file that pana detects, with notices for the bundled crates
5. support for `code_assets` 2.x
6. a verified publisher, a public repository and a stable 1.0

### 2.11 Chart.js ADR 0042: Theming (gate 1 for its four invariants, else 5)

[Chart.js ADR 0042](adr/0042-theming.md) and [theming.md](theming.md) own this decision. Chart.js
ADR 0042 restates Chart.js ADR 0001 with the palette of the theme map, and supersedes it. The flow
has three conditions. The theme hooks H0-H3 in `core.config` and H4a-H4c and H5 in
`plugin.colors` are `DIVERGES` hunks. The harness runs with no theme and with the colors plugin
disabled. `lib/` imports neither forui nor Material.

### 2.12 ADR: Toolchain pin and library floor (gate: the change that moves `.fvmrc` to 3.47.7)

**Decision** (the porting lead, on the request of the maintainer, 2026-10-21).
- Pin `.fvmrc` at Flutter 3.47.7 (Dart 3.13.5). CI reads the same file.
- All packages of the workspace and the gallery have the floor `sdk: ^3.13.0` and
  `flutter: ">=3.47.0"`. The root `pubspec.yaml` has `sdk: ^3.13.0`. Phase 9 sets the published
  floor.
- No CI `floor` job. A job on 3.44.9 cannot resolve a `^3.13.0` floor.
- The gallery takes the deployment targets of the 3.47.7 app templates: iOS 15.0 and macOS 12.0.
- A test constraint (a dependency or a dev_dependency) that matches a pin of the Flutter SDK
  follows the pin. Thus `test` is `^1.31.1`, the version with the `test_api` pin 0.7.12 of
  `flutter_test` in 3.47.7. `chartjs_test_utils` has `test` as a dependency, and the other
  packages have it as a dev_dependency.
- The change that moves the pin updates the toolchain lines of AGENTS.md Conventions,
  CONTRIBUTING.md Setup and README.md. A probe line that names an older version stays as evidence.
- This change keeps very_good_analysis at ^10.3.0. A move to 11.0.0 (`sdk: ^3.13.0`) is its own
  change.
- Do not move to 3.50 before two changes: a fix of cli_launcher #28 and a gallery on `material_ui`.

**Evidence.** The sdkfloor probe of 2026-10-16 gave the evidence for a CI `floor` job, and this
decision rejects that job. In that probe, all gates passed on 3.47.7 (`sdkfloor/logs/q2-*`). The
floor job of the probe found a 3.47-only API that the workspace analyzer missed. With only
`resolution:`, a harness dev_dependency did not resolve. On the 3.50 beta, `flutter/material.dart` is deprecated. `dart run melos` crashes on Dart
3.14. On 2026-10-21, `dart pub get` of Dart 3.12.2 (Flutter 3.44.9) failed on a package with
`sdk: ^3.13.0`. On Dart 3.13.5, a package with `sdk: ^3.13.0` compiles primary constructors and
`const new()`. With `sdk: ^3.12.0`, the analyzer rejects both (`primary-constructors`).

On 2026-10-21, the sort probe and the cycle probe ran again on 3.47.7. The results are the same
as on 3.44.9:
- `List.sort` is not stable above 32 elements on the VM JIT, the VM AOT, dart2wasm and DDC. 2360
  of 3000 lists are not stable, and the shortest of them has 34 elements. On dart2js,
  `List.sort` is stable.
- `mergeSort` of `package:collection` 1.19.1 is stable on every target.
- The dev_dependency cycle of the workspace resolves on 3.47.7. `pub get`, `analyze` and a
  `testWidgets` test pass. `--enforce-lockfile` keeps the lock file.
- Flutter 3.47.7 depends on `collection: ^1.19.1`. This is a constraint, not an exact pin.

### 2.13 Chart.js ADR 0035: Third-party sources (gate 1)

[Chart.js ADR 0035](adr/0035-third-party-sources.md) holds the complete decision and its
evidence. It supersedes Chart.js ADR 0011. Chart.js ADR 0011 superseded Chart.js ADR 0005. In
short:
- `third_party/kurkle-color` (`v0.3.2`) and `third_party/chartjs-test-utils` (`v0.4.0`) are
  reference-only shallow submodules. The phase 2 cleanup removed `third_party/pixelmatch`
  ([Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md)).
- `third_party/fdlibm/` holds unchanged netlib copies, because fdlibm has no git repository.
- `packages/flutter_chartjs_port/tool/port_sources.yaml` has one entry for each project. Tool 2 reads
  it.
- [ADR 0005](../../../docs/adr/0005-pin-upstream-sources.md) gives the reference-only rules.
  Dev-time tools can read and evaluate reference sources. Dart code never imports them. No tool
  builds them inside `third_party/`. No package ships them.

**Evidence** (2026-10-16). `.gitmodules` listed only Chart.js.

### 2.14 Chart.js ADR 0017: Element properties (gate 4)

[Chart.js ADR 0017](adr/0017-element-properties.md) holds the decision, its evidence
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
- A numeric field whose `undefined` start value a reader writes into an element or another
  observed object is `double?`, with Dart `null` for `undefined`. NaN for `undefined` is correct
  only when each reader uses the value in arithmetic. Example: `RadialLinearScale.xCenter` and
  `yCenter` (phase 7, Chart.js ADR 0033): the reset of a new radar or polar area point writes
  `undefined`, and the animation starts at its target.
- `operator []` and `operator []=` give the access by name of phase 5. A Map of extra properties
  keeps the names that the class does not declare. The constructors write their `cfg` argument
  through `operator []=`, as `Object.assign` does.
- `getProps` returns the element itself or an `ElementProps` over a new Map. `tooltipPosition`
  and `getCenterPoint` return an `ElementPoint`.
- The JS form `value || 0` before arithmetic is `jsOrZero` of `lib/src/js/js_number.dart`. The
  port-only file `lib/src/js/js_webidl.dart` converts an option value for a Canvas 2D setter, as
  the WebIDL type of the DOM setter does (`canvasStyle`, `canvasNumber`, `canvasKeyword` and
  `canvasLineDash`). The controllers and the plugins use the same functions.
- `core.element.dart`, `lib/src/elements/` and `lib/src/js/js_webidl.dart` are pure layers. Their
  specs and tests run on the VM, with dart2js and with dart2wasm.
- [Chart.js ADR 0020](adr/0020-registry-and-component-classes.md) §3 answers the Open item on how
  the registry reads the static members. `Element` and each element class have a static `jsClass`,
  the class as a value (2.16).

### 2.15 Chart.js ADR 0018: Typed element options (gate 4)

[Chart.js ADR 0018](adr/0018-typed-element-options.md) holds the decision, its evidence
and the items that stay open. In short:
- The port-only file `lib/src/elements/element_options.dart` declares `ElementOptions`, a
  `MapBase<String, Object?>`, and its four final subclasses `PointOptions`, `LineOptions`,
  `BarOptions` and `ArcOptions`. An instance is a Map. Thus Chart.js ADR 0043 stays valid, and
  `jsGet`, the resolver and user code read it as a Map.
- Each subclass has a fixed list of known keys: `$shared`, the keys of the `defaults` and of the
  `defaultRoutes` of its element class, and the keys that other code writes into the options
  (`segment` of the line, `$animations`). Each known key has a field. A private sentinel marks an
  absent key. The other keys go to a Map of extra keys.
- The Map protocol gives the results of a plain Map with the same entries. Only the key order can
  differ: the present known keys come in the order of the list.
- The getter of a known key gives the raw value, or `undefined` for an absent key, with no Map
  lookup. The element code reads each option through one small function, which also takes a
  plain Map. `PointOptions` implements `DrawPointOptions`.
- Phase 4 makes typed options in the gallery.
  [Chart.js ADR 0021](adr/0021-typed-options-in-the-resolver.md) (2.17) decides the phase 5 part.
  `createElementOptions` picks the typed class by the element type id, not by the `names` of
  `resolveNamedOptions`. Another id gets `GenericElementOptions`. `resolveNamedOptions` fills the
  object that its caller gives. `copyOptions` keeps the class in a copy, through `clone`. The
  options have a frozen state.
- Each element test that compares with reference data runs with plain Map options and with typed
  options.

### 2.16 Chart.js ADR 0020: Registry and component classes (gate 5)

[Chart.js ADR 0020](adr/0020-registry-and-component-classes.md) holds the decision, its
evidence and the items that stay open. It answers the two Open items of Chart.js ADR 0017. In
short:
- The port-only, pure `JsClass` of `lib/src/js/js_class.dart` stands for a JS class value: its
  name, its superclass and its static members, with `jsConstruct`, `jsAssign` and
  `jsObjectClass`. Each class that the registry takes gets `static final JsClass jsClass`.
- `TypedRegistry` and `Registry` are line-by-line ports. `isForType` tests the superclass chain
  of the class value. `Chart.register` takes one `List`, and the static `Chart.registry` stays.
- A plugin is a Map or a class value. `_notify` reads each hook by name at each call.
- `getRange` is in the port-only interface `VisualElementRange`.
- Section 13 of the ADR reads the performance rule of §1.1 for a form that changes the upstream
  structure: its gain must show in the frame figures, which have a resolution of 0.1 ms.
- Phase 5 ported `core.typedRegistry`, `core.registry` and `core.plugins`. `core.typedRegistry`
  is a pure layer. `core.registry` imports `core.datasetController` and `core.scale`, as
  upstream does. The spec `core.registry.tests.js` passes its 15 cases through `Chart.register`.
- The typed hook slots (CT, the Alternatives of the ADR) wait for the frame figures of phase 8.
  Phase 8 registers the seven built-in plugins (wave 4), and its step 8 measures their dispatch in
  the gallery ([Chart.js ADR 0038](adr/0038-plugin-modules-class-values-and-interfaces.md) §10). A
  new ADR adopts CT when the dispatch shows in the frame figures.

### 2.17 Chart.js ADR 0021: Typed options in the resolver (gate 5)

[Chart.js ADR 0021](adr/0021-typed-options-in-the-resolver.md) holds the decision, its
evidence and the items that stay open. It answers the two Open items of Chart.js ADR 0018. In
short:
- `createElementOptions` picks the typed class by the element type id. Another id gets
  `GenericElementOptions`. `resolveNamedOptions` takes the new object as an optional argument.
- The four `Object.assign` copies of options use `copyOptions`, which keeps the class.
- `ElementOptions` implements `JsFreezable`. A write into frozen options throws a `TypeError`, as
  JavaScript strict mode does. `jsObjectFreeze` and `jsObjectIsFrozen` stand for the builtins.
- A gallery stress mode `chart` measures the element draw cost through the real chart path.

### 2.18 Chart.js ADR 0022: Chart test harness on Flutter (gate 5)

[Chart.js ADR 0022](adr/0022-chart-test-harness.md) holds the decision, its evidence
and the items that stay open. In short:
- `acquireChart` is synchronous and works only inside a `testWidgets` body. A port-only DOM
  stand-in and a forced layout attach the chart at its construction, as upstream does.
- `resize` and `eventHandler` are function fields of `Chart`. Thus `waitForResize` and
  `afterEvent` are line-by-line ports with the upstream timing.
- `triggerMouseEvent` dispatches a `NativeEvent` to the canvas listeners and pumps frames.
  `setTimeout` is a harness task on `clock.now()`.
- `releaseCharts` runs when the test body unmounts. The harness registers the built-in components
  before the snapshot of the defaults.
- The ADR changes the chart host: the first resize notification comes at the next layout, and an
  append or a removal reports the attach state in a microtask checkpoint.

### 2.19 Chart.js ADR 0025: Scale value parameters (gate 6)

[Chart.js ADR 0025](adr/0025-scale-value-parameters.md) holds the decision and its evidence. In
short:
- `getPixelForValue`, `getDecimalForValue`, `getDistanceFromCenterForValue`,
  `getPointPositionForValue` and `getLineWidthForValue` take `Object?`. Dart `null` is JS
  `null`, and the `undefined` sentinel is JS `undefined`. The callers pass the raw value. The
  row `adapt-scale-position-value` goes.
- The category, linear and logarithmic `getPixelForValue` and the time `getDecimalForValue`
  start with a port-only `value is double` branch, then the literal lines. A port-only test
  pins both paths.
- Phase 6 adds `types.Chart.getDataVisibility` and
  `types.DatasetController.getAllParsedValues`. Phase 7 adds the other `types.Scale` members
  and `types.RadialLinearScale` with their first readers, with the signatures of the ADR. Phase
  7 makes `xCenter` and `yCenter` `double?` (Dart `null` for `undefined`,
  [Chart.js ADR 0033](adr/0033-radial-scale-centers.md)). Chart.js ADR 0033 supersedes the
  `xCenter` and `yCenter` bullet of §5 of Chart.js ADR 0025.
- The `_` members that another file or a spec reads drop the underscore with `@internal`:
  `startValue`, `endValue`, `valueRange`, `offsets`, `generate`, `unit`, `adapter`,
  `pointLabels` and `pointLabelItems`.
- `Scale` implements `MinMax`. `setMinAndMaxByKey` reads a tick by its `value`.
- A phase 7 reader that passes `parsed[axis]` to a scale keeps `undefined` for an absent key.

### 2.20 Chart.js ADR 0036: Parsed data in the controllers (gate 7)

[Chart.js ADR 0036](adr/0036-parsed-data.md) holds the complete decision, its evidence and the
items that stay open. It supersedes Chart.js ADR 0027. In short:
- A parsed item, a data item and a stack object are any value. `jsGetKey` of `js_object.dart` is
  the read `object[key]` with a String key: it gives the `jsGet` result, with a Map case first. A
  read of a resolver or of an option object stays `jsGet`.
- `jsGetIndex` is the read `object[index]` with a number index, `jsSetIndex` is the write
  `list[index] = value` (a write at the length appends), and `jsLessThan` is the operator `a < b`
  on raw values (two strings by their code units, a `DateTime` by its time value). They replace
  the private index helpers of `core.datasetController` and `core.controller`.
- `core.datasetController` reads parsed items and stack objects with `jsGetKey`. The reads that
  test with `isFinite` or the truthiness keep `_parsedValue`. `stacksOf` (`@internal`) reads
  `item._stacks`: a List, a `DateTime` or a function item keeps it in an `Expando`, and a
  primitive item throws a `TypeError`, as upstream.
- A controller casts no data item, parsed item or data value. A parsing key is cast to `String` at
  its `resolveObjectKey` call inside the loop, in the controllers and in
  `core.datasetController`. Thus the throw of a bad key comes at the upstream call. A raw option
  value stays `Object?` until its upstream operator, which then has its runtime form
  (`jsToNumber`, `jsTruthy`, `jsAdd`, `==` or a `===` by identity for two possible `Date`
  operands).
- Each hot loop is ported literally first. The one-read rule (a `final` local for a repeated read
  of the same key of the same item in one loop pass) applies to the line and scatter loops. The
  structure changes of the bar, bubble, polar area and radar loops wait for step 7.
- `jsToString` of a `DateTime` gives the V8 text with the zone name, because a category scale
  measures a `Date` label through it. dart2js and dart2wasm take the name of the engine. The VM
  gives it only in UTC: the row `platform-date-zone-name` has the other zones.
- One `DIVERGES` marker and one new row (`platform-date-zone-name`). The rows
  `js-semantics-resolver-objects` and `platform-array-events` get new text.

### 2.21 Chart.js ADR 0028: Controller interfaces and values (gate 7)

[Chart.js ADR 0028](adr/0028-controller-interfaces.md) holds the decision, its evidence
and the items that stay open. In short:
- A controller reads the members of other modules through `lib/src/types/`. It imports no
  concrete chart, meta, scale or element module, and it casts only to a `types` interface or to a
  class of its own library, at the upstream read. Three other kinds of casts stay: a `List` cast
  of a value that upstream reads as an array (the `labels` of the legend functions, the data of
  the doughnut `parse`, the result of `parseObjectDataRadialScale` in the polar area and radar
  `parseObjectData`), the `String` cast of a parsing key
  ([Chart.js ADR 0036](adr/0036-parsed-data.md) §4), and the `AnyObject` cast of an options object
  or a stack object that the controller made. The `List` and `AnyObject` casts cannot throw where
  upstream does not throw. `lib/src/types/index.dart` gets the members that the controllers read
  first, `RadialLinearScale` and a minimal `LegendElement`.
- `getLabelAndValue` gives `({Object? label, String value})`: the label keeps its JS type.
- The `points` setter of `LineElement` takes a `List<types.Element>` and copies a list that is
  not a `List<types.PointElement>` (the row `adapt-line-points-elements`).
- `getDataVisibility` returns `true` at once for an empty `_hiddenIndices`: a fast path with the
  upstream result. `toggleDataVisibility` takes any JS value (`Object?`) and writes the key
  `ToString(index)`. The legend `onClick` passes the raw index of the item. `ChartMeta.total` is a typed field, and `Chart.legend` a field that the legend
  plugin writes.
- The polar area hunk of #12238 is the upstream lines. The option functions of `defaults` and
  `overrides` are tear-offs of top-level functions.
- `lib/src/controllers/index.dart` exports the controllers, and the `controllers` namespace of
  `lib/src/index.dart` registers the eight controllers in the order of the bundle.

### 2.22 Chart.js ADR 0029: Fixture smoke runner (gate 7)

[Chart.js ADR 0029](adr/0029-fixture-smoke-runner.md) holds the decision, its evidence
and the items that stay open. In short:
- `packages/chartjs_test_utils/lib/src/fixture.dart` ports `src/fixture.js` of chartjs-test-utils
  0.4.0: `specsFromFixtures`, `specFromFixture` and `FixtureSource`. `dom.dart` gets `pumpFrame`.
  `flutter.dart` exports them.
- `test/fixtures/index.dart` stands for `jasmine.fixture`. A spec file with a fixture group calls
  `group('auto', fixture.specs('<prefix>'))` at the upstream line. 27 Dart spec files do this:
  the 20 of phase 7 and the 7 `plugin.*` spec files of phase 8. Thus each of them is a VM file.
  `element.point_test.dart` moved for its 12 fixtures.
- The list of the fixtures and the pure data configs come from tool 4 (`manifest.json` and
  `fixtures.json`). Before a fixture runs, the runner compares the SHA-256 of the upstream file
  in `third_party/Chart.js/test/fixtures/` with the manifest.
- Each impure config has a hand port `test/fixtures/hand/<path>.dart` with a function `fixture()`,
  and an entry with the first 12 hex digits of its manifest `sha256`. A stale hand port, a stale
  `blocked: plugin.<id>` skip and an impure fixture without a hand port fail.
- The animator has `getAnims`, `update` and the field `refresh`: six hand ports replace `refresh`.
- One fixture test: the load, the plugin rule, `acquireChart`, the `run` hook, one frame and the
  release in a `finally`. No image comparison
  ([Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md) §4). The test passes when no step
  throws.
- Phase 7 runs 529 fixtures: 457 pass and 72 skip (33 `blocked: plugin.*`, 39
  `diverges: adapt-date-moment-format`). Wave 4 of phase 8 runs 667 fixtures with the `plugin.*`
  fixtures: 628 pass and 39 skip, all `diverges: adapt-date-moment-format`. No `blocked: plugin.*`
  skip stays. The 36 pure data configs of the moment skips run as ICU
  twins in `test/port/fixtures/moment_twins_test.dart`.
- Each fixture test has the tag `fixtures`. `test`, `test:cases` and tool 6 exclude it.
  `test:fixtures` (tool 5 `--fixtures`, tool 7) runs it. The CI job `fixtures` makes a shallow
  checkout of `third_party/Chart.js` and sets `FIXTURES_REQUIRED=1`.
- Rows `harness-fixture-sources` and `harness-fixture-frame`. The row `harness-method-fields`
  names `Animator.refresh`.

### 2.23 Chart.js ADR 0030: Controller test strategy (gate 7)

[Chart.js ADR 0030](adr/0030-controller-test-strategy.md) holds the decision, its
evidence and the items that stay open. In short:
- `DatasetController.ctx` is writable, as the JS property `_ctx`. One `drawCalls` on both sides
  records the element draws. The 8 phase 6 reference files were generated again with the element
  draws.
- A `Path2D` argument records as `{path, calls}`. The controller generators define a recording
  `Path2D` before the dist loads.
- One generator and one reference test file for each controller, on the shared
  `tool/reference/controller_chart_common.mjs` and `test/port/controllers/controller_chart_harness.dart`.
  A case has the observations after `acquireChart` and after each step, the hit queries and the
  draw calls of one draw. The pin cases `parsed:` and `interfaces:` serve Chart.js ADRs 0036 and
  0028.
- Each controller test file runs its cases again with the light preset (theme test 3). Theme test
  5, the hover tests and the blue screen come with the theme unit of step 4.
- The lift of the `blocked: controller.*` skips follows a check of all 536 records of the
  classification by `lift_check.py`, a temporary script of phase 7, not kept.
- The 7 controller spec files follow the conventions of §13 and share the Jasmine matchers and
  spies of `test/support/jasmine.dart`.

### 2.24 Chart.js ADRs 0038-0041: Plugins (gate 8)

[Chart.js ADR 0038](adr/0038-plugin-modules-class-values-and-interfaces.md) holds the plugin
modules:
- Each plugin object of `src/plugins/` is a mutable Map with the upstream keys in the upstream
  order. Each hook takes the upstream parameter count. `Title`, `Legend` and `Tooltip` have class
  values ([Chart.js ADR 0020](adr/0020-registry-and-component-classes.md) §3).
- The namespace `plugins` of `lib/src/index.dart` holds the seven plugin objects in the order of
  `src/plugins/index.js:1-7`, which is the hook order. `registerables` registers them.
- A plugin reads the members of other modules through `lib/src/types/`. `Chart.titleBlock`,
  `Chart.legend` and `Chart.tooltip` are fields that the plugins write.
- `plugin.decimation` and the files of `plugin.filler/` are pure layers.

[Chart.js ADR 0039](adr/0039-tooltip-model-and-animation.md) holds the tooltip model: `Tooltip`
implements `types.TooltipModel`, its animation targets and the merge of `helpers.merge` into an
element target. [Chart.js ADR 0040](adr/0040-filler-targets-and-plain-points.md) holds the filler
targets: each plain point of upstream is a `PointElement` with only the properties of the plain
object (row `adapt-line-points-elements`), and the draw dispatches on `types.LineElement` and
`types.SimpleArc`.

[Chart.js ADR 0041](adr/0041-plugin-test-strategy.md) holds the tests of the plugins:
- `flutter_test_config.dart` registers the seven plugins with the other built-in components and
  sets `defaults.plugins.colors.enabled = false`, as `test/index.js:25-28` does.
- Each reference generator registers the same components (`registerBuiltins` of
  `scale_chart_common.mjs`). The two source generators register the seven plugins by name.
- The plugin reference tests have unit cases (the other plugins off) and full cases (the plugins
  with their defaults).
- Tool 5 fails on a stale `blocked: <module>` skip (section 4, tool 5). The fixture runner fails a
  stale `blocked: plugin.<id>` skip.

## 3. Test harness

**Package.** `packages/chartjs_test_utils` (`publish_to: none`) mirrors the npm package module by
module. It is a dev_dependency of `flutter_chartjs_port`. It also depends on `flutter_chartjs_port`. Probes
showed that the workspace resolves this cycle. The harness, its notices and the test font stay
outside the published archive. Port exactly 0.4.0 (`package.json:90`). `dom.dart` pumps frames
with the test binding and runs its tasks on `clock.now()`. Thus `flutter_test` and `clock` are
regular dependencies of the package ([Chart.js ADR 0022](adr/0022-chart-test-harness.md) §1).

| Upstream (0.4.0) | Dart | Phase |
|---|---|---|
| — | `pure.dart` (spec set-up for `dart test`) | 2, done |
| `src/context.js`, `src/index.js` | `MockContext implements CanvasRenderingContext2D`, `createMockContext` (in `context.dart`, row `harness-index-pure-split`, so that `pure.dart` stays pure) | 3, done |
| `src/matchers.js`, `src/matchers.options.js` | matchers: `toBeCloseToPixel`, `toBeCloseToPoint`, `toEqualOneOf`, `toEqualOptions` (it reads the keys of the expected object with `jsObjectKeys`, as `for...in` with `hasOwnProperty` does. For a resolver, these are the keys of the first scope, `helpers.config.ts:73-75`) | 3, done |
| — | test font (`installTestFont` of `flutter.dart`, [Chart.js ADR 0015](adr/0015-text.md)) | 3, done |
| `src/matchers.js` | `toBeValidChart`, `toBeChartOfSize` (the display size from the inline px style and the render size of the canvas, with the CSS rule for one style and `auto` for a canvas with `display: none`, [Chart.js ADR 0022](adr/0022-chart-test-harness.md) §9), in a pure layer | 5, done |
| `src/utils.js` | `acquireChart`, `releaseChart`, `afterEvent` and `waitForResize` (over the function fields of `Chart`), and `triggerMouseEvent` (a `NativeEvent` to the listeners of the canvas, frames of 16 ms). `acquireChart` is synchronous and works only in the body of a `testWidgets` test. It gives 512×512 as attributes of the `UiCanvasElement` of `document.createElement`, and the `canvas.style` option as the inline style. The wrapper has the class `chartjs-wrapper` in the DOM stand-in, with the CSS subset of `dom.dart`. The default wrapper is a box of the canvas display size. A forced layout attaches the chart at its construction. The defaults are `animation: false`, `responsive: false` and `locale: 'en-US'`. `useOffscreenCanvas` gives a canvas that no host shows | 5, done |
| `src/index.js` | `acquireChart`, `releaseChart`, `releaseCharts` and the registry `charts`. `releaseCharts` never deletes a chart. `index.dart` imports `utils.dart` with the prefix `utils` ([Chart.js ADR 0012](adr/0012-dart-file-naming.md), Collisions). `export 'fixture.dart';` is the re-export of `src/fixture.js` (`:5`) | 5, done; the re-export 7, done |
| — | `dom.dart`, exported by `flutter.dart` ([Chart.js ADR 0022](adr/0022-chart-test-harness.md) §3, §7 and §8): the DOM stand-in (`document`, `window`, `div` and `canvas` nodes, a subset of CSS), the harness body, the mutation checkpoint, the harness tasks of `setTimeout`, `pumpFrames` (frames of 16 ms, the Jasmine timeout after 5000 ms; one loop pumps at a time, and a loop that starts during another loop awaits its steps), `waitForDone`, `afterEachChart`, and `pumpFrame` (one frame of the fixture runner) | 5, done; `pumpFrame` 7, done |
| `src/fixture.js` | `fixture.dart`: `specsFromFixtures` and `specFromFixture` as a smoke runner (prefix match, plugin rule, `run` hook, one frame), no image comparison. `FixtureSource` reads the manifest, `fixtures.json` and the upstream files of the SHA-256 check. Rows `harness-fixture-sources` and `harness-fixture-frame` ([Chart.js ADR 0029](adr/0029-fixture-smoke-runner.md)) | 7, done |
| `src/spriting.js`; pixelmatch `index.js`; Canvas-call recordings | not ported (`n/a`): no image comparison ([Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md)) | — |
| `injectWrapperCSS`, `useShadowDOM` | not ported (`n/a`). The class `chartjs-wrapper` of `dom.dart` gives the effect of the `injectWrapperCSS` rule. `useShadowDOM` throws an `UnsupportedError`. The `useShadowDOM` cases of `helpers.dom` skip as `'n/a: Flutter has no shadow DOM'` | — |

**Licensing.** The harness has no pixelmatch code. Thus its `LICENSE` has no ISC notice. Its
`LICENSE` has the SIL OFL 1.1 notice of the test font as a separate component
([Chart.js ADR 0015](adr/0015-text.md)).

**`test/index.js` equivalent.** From phase 3, `packages/flutter_chartjs_port/test/flutter_test_config.dart`
ports `test/index.js`. It translates DPR 1 (`:5`). It translates the UTC zone line (`:23`) as
`setDefaultDateZone('Etc/UTC')` ([Chart.js ADR 0024](adr/0024-dates.md)). `setUpSpecs()` of
`pure.dart` makes the same call. After the registration of the built-in components, it ports the
disabled colors plugin (`:25-28`): `defaults.plugins.colors.enabled = false`, before the snapshot of
the restore. Four port-only hunks carry `DIVERGES` markers and `harness-*` rows.
Phase 3 added the file with DPR 1 and the first two rows. Phase 5 added the last two rows:
- `harness-defaults-restore`: the restore of `defaults`, `overrides` and `descriptors` in
  `tearDown`, from a snapshot after the harness setup. It calls `setUpDefaultsRestore()` of
  `pure.dart`.
- `harness-test-font`: the test font install.
- `harness-register-builtins`: the call of `src/index.umd.ts:28` before `main()` and before the
  snapshot of the restore ([Chart.js ADR 0022](adr/0022-chart-test-harness.md) §8). `setUpSpecs()`
  of `pure.dart` removes the built-in components again.
- `harness-release-at-unmount`: `releaseCharts()` (`:34-36`) at the unmount of the harness body,
  with a `tearDown` as the fallback.

The harness installs no theme ([Chart.js ADR 0042](adr/0042-theming.md)). Thus no ported spec
depends on the platform that flutter_test reports (`TargetPlatform.android`).

`dart test` does not read `flutter_test_config.dart`. Thus each pure-layer spec file calls the
same set-up from `package:chartjs_test_utils/pure.dart`. Phase 2 added `pure.dart`. It restores
`defaults`, `overrides` and `descriptors` after each test. Its `setUpSpecs()` also removes the built-in
components. Thus a pure-layer file has the same state under `flutter test` and `dart test`. A spec
file with chart cases does not call `setUpSpecs()`. `pure.dart` is a port-only file. Thus its
restore has no `DIVERGES` marker and no row.

**Frames in tests.** The scheduling of [Chart.js ADR 0016](adr/0016-frame-scheduling.md) runs only
when the test pumps.
- A spec that reaches `requestAnimFrame` or `throttled` is a `testWidgets` test. In a plain
  `test()`, no frame runs.
- `setUp` runs outside the `FakeAsync` zone of `testWidgets`. Its timers are real. `clock.now()`
  there gives real time. Thus a ported `beforeEach` that acquires a chart runs at the
  start of each `testWidgets` body. 29 `beforeEach` blocks in 10 spec files acquire a chart.
- `acquireChart` is synchronous and runs no frame. It throws a `StateError` outside the body of a
  `testWidgets` test.
- A ported `afterEach` that reads or acquires a chart is a local function. Each test calls it last
  in its body ([Chart.js ADR 0022](adr/0022-chart-test-harness.md) §2).
- A ported `beforeEach` that writes the DOM for a case with `Chart(...)` is a local function too.
  Each case calls it first. A `setUp` writes only the element tree, and the canvas stays on its
  standby host. An `afterEach` that reads no chart stays a `tearDown`. An example is the group
  `context acquisition` of `test/specs/platform.dom_test.dart`.
- `triggerMouseEvent` pumps. It resolves after the throttled event callback. A type with a
  listener needs one frame of 16 ms. A type without a listener fails with the Jasmine timeout
  message. Specs call it 104 times in 13 files. `waitForResize` does not pump. It replaces the
  `resize` field of the chart, and its callback runs after the next resize. The pumps of
  `waitForDone` run that resize. Specs call it 32 times in 2 files.
- A spec with `resizeDelay` pumps past the delay. `pumpAndSettle` does not wait for a `Timer`.
- A spec with `setTimeout` or a Jasmine `done` callback is a `testWidgets` test. It calls
  `setTimeout` and `waitForDone` of `dom.dart` ([Chart.js ADR 0022](adr/0022-chart-test-harness.md)
  §7). `setTimeout` adds a harness task that is due at `clock.now()` plus the delay. A harness task
  is not a `Timer`.
- `pumpFrames` and `waitForDone` pump frames of 16 ms. Between the pumps, they run the due harness
  tasks in the zone of the test body. Thus an `expect` in a task works. After 5000 ms of fake time,
  they fail with the Jasmine timeout message.
- A port of a `setTimeout` with one long pump fails ([Chart.js ADR 0019](adr/0019-animation.md),
  Consequences).
- A resize observer of the chart host gets its first notification at the next layout of the host.
  Its throttled resize comes in the frame after that layout (Chart.js ADR 0022 §10).
- An append or a removal in `dom.dart` schedules one microtask, the mutation checkpoint. It lays
  out the harness body and calls `flushCanvasMutations`. Thus the attach and detach listeners of the
  platform run in the task of the write.

**Reference tests of the controllers.** From phase 7, the port-only reference tests of the dataset
controllers follow [Chart.js ADR 0030](adr/0030-controller-test-strategy.md) §1-§7:
- One generator for each controller, `tool/reference/controller_<name>_reference.mjs`, on the
  shared `controller_chart_common.mjs`. It runs a build of the pinned Chart.js on the reference
  engine, with the checks of `scale_chart_common.mjs`, and defines a recording `Path2D` before
  the dist loads. It writes `test/port/controllers/controller_<name>_reference.dart`: Dart `const`
  literals, one JSON-lines string of the draw calls for each case, and one JSON line of hit items
  for each query point. A data file has at most 2.5 MB. A probe line of a comment note has at most
  75 characters, because the generator stops on a comment line of more than 80 characters.
- One test file for each controller, `test/port/controllers/controller.<name>_test.dart`
  (`@TestOn('vm')`), on the harness `controller_chart_harness.dart`. Each case is one
  `testWidgets` case: `acquireChart`, the steps (`update`, `setDatasetVisibility`,
  `toggleDataVisibility`, `setActive`, `push`, `splice`, `reset`, `hover`, `mouseout`), and after
  each step the observations of the chart area, the scales, the stacks, the datasets and the hit
  queries. The draw calls of one `chart.draw()` come last. A step that throws stands in `steps` as
  `{do}` without observations, and the case expects the throw at the same place: a JS `TypeError`
  is a Dart `TypeError`.
- `drawCalls` puts the recording context in `chart.ctx`, in each `scale.ctx` and in the writable
  `DatasetController.ctx`. Thus the draw calls have the element draws. A `Path2D` argument records
  as `{path, calls}` (`test/port/canvas/path2d_record.dart`). `expectCalls` removes the reference
  `clip` of the border ring of each bar that the port draws without a `clip` (row
  [`adapt-bar-clip`](differences.md#adapt-bar-clip)).
- Each file runs its cases again with the light preset ([theming.md](theming.md) §8 test 3). The
  colors then compare in their parsed form, the options compare only the keys of upstream, and the
  test compares `defaults` with its state before the run. The pin cases `parsed:` and
  `interfaces:` run unthemed only.
- `flutter_test_config.dart` registers the controllers of each finished wave with the built-in
  components. A unit tests its controller before that: its test files register the controller
  class in `main()` until the integration agent of the wave removes the line. A test-only
  controller subclass with its own id registers in the `setUp` of its group and unregisters in the
  `tearDown`.
- `dartArgs` of `scale_chart_common.mjs` applies the WebIDL `ToNumber` to the number arguments of
  the canvas and `Path2D` calls, also of `bezierCurveTo`, `quadraticCurveTo` and the first five
  arguments of `arc`, as a browser does. The Dart canvas takes a `double`.
- The JS charts get the `BasicPlatform` of Node.js, whose `updateConfig` writes `animation: false`
  (`platform.basic.js:20-22`). The Dart harness gives the platform of `platform.flutter.dart`,
  which keeps the option. A generator with a case that needs the animation options (the doughnut
  and polar area `reset` cases) puts the no-op `updateConfig` of `BasePlatform` on
  `BasicPlatform` first.
- The Dart field `ChartMeta.xAxisID` is a `String?` and cannot keep the JS `null` of a controller
  without `linkScales` (the doughnut and the pie) apart from the `undefined` of a controller with
  it. The doughnut and pie test files compare an expected `null` of the two axis ids as
  `undefined`.
- A hit query between two symmetric arcs can tie at the last bit. `jsSin` and `jsCos` give the V8
  bits on every target ([Chart.js ADR 0045](adr/0045-reference-engine-arm64.md)), so the tie keeps
  the V8 item. The pie generator uses the data `[5, 15, 10, 20]`, which has the
  tie of `Math.sin(3.665191429188092)` at step 2 of `the step toggleDataVisibility`. The doughnut
  case `parsed: object items with the default key` has the tie of
  `Math.sin(-0.7853981633974483)` (CI run 39544591156). The generators keep the border queries.
- The controller generators have no step that writes an option. A pin test of an option change
  takes its expected values from a probe on the pinned build. The test comment gives the probe
  and its output (wave 3: the group `showLine` of `controller.scatter_test.dart`).
- A scatter line with `tension` draws its Bézier curves with NaN control points upstream: scatter
  has no `draw` override, so no `updateControlPoints` call. The canvas of the port skips a
  `bezierCurveTo` with an argument that is not finite, as a Canvas 2D does.
- The spec ports share the Jasmine matchers and spies of `test/support/jasmine.dart`: a spy of a
  function value is a recording function value, and a spy of a method is a spy object in the slot
  that the library reads (`meta.data[i]`, `meta.dataset`, the listeners of a data array,
  `chart.ctx`). A draw spy of an element with a running animation throws a `StateError`. Jasmine
  `this` is a set of `late` variables of the group closure.

**Where tests run.**

| Suite | VM: `flutter test`, 3 OS | `dart test -p chrome -c dart2js` | `-c dart2wasm` |
|---|---|---|---|
| Pure-layer specs | yes | yes | yes |
| Other specs (`@TestOn('vm')`) | yes | no | no |
| Fixture smoke tests (the tag `fixtures` of `specFromFixture`) | ubuntu `fixtures` job (`test:fixtures`, with the submodule `third_party/Chart.js`) | no | no |
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

These phase 5 files are pure layers too:
- `core.config` ([Chart.js ADR 0021](adr/0021-typed-options-in-the-resolver.md), section 7) and
  `core.adapters` (the `pureRoots` of `tool/src/lib_imports.dart`)
- `core.interaction` and `core.layouts`
- `core.animation` and the port-only `animation_spec` ([Chart.js ADR 0019](adr/0019-animation.md),
  section 1)
- `core.typedRegistry` ([Chart.js ADR 0020](adr/0020-registry-and-component-classes.md), section
  10)
- the theme compiler and the internal presets of `lib/src/theme/` (`compile.dart` and
  `presets.dart`, [theming.md](theming.md) §7)

`core.animations`, `core.animator`, `core.scale` and `core.scale.autoskip` are not pure layers.
`core.animator` and `core.scale` import `helpers.extras`. `core.datasetController`,
`core.registry`, `core.plugins` and `core.controller` are not pure layers either.
`core.datasetController` imports `core.animations`, and `core.registry` imports `core.scale`.
`core.plugins` imports `core.registry`, and `core.controller` imports the platform layer.

On 3.44.9, `dart test -p chrome` runs in a Flutter package with a `test` dev_dependency (probe).
`--tags` does not stop the compile of other files. `@TestOn('vm')` stops it. `flutter test` still
runs `@TestOn('vm')` files. On 3.47.7 (2026-10-21),
`dart test -p chrome -c dart2js test/specs/helpers.math_test.dart` in `packages/flutter_chartjs_port`
passed its 12 tests.

The matrix does not use `flutter test --platform chrome`. That flag is deprecated in 3.47.7, as in
3.44.9. Its JS leg compiles with DDC (`lib/src/test/web_test_compiler.dart:113-176` of
`flutter_tools`), not with dart2js. `flutter build web` uses dart2js.

**Fixture selection.** From phase 7 (tool 7), the melos `test` script, `test:cases` and tool 6
pass `--exclude-tags fixtures`. `test:fixtures` runs tool 5 with `--fixtures`, which runs
`flutter test --tags fixtures`. The `fixtures` job runs it with a shallow checkout of
`third_party/Chart.js`. Before a fixture runs, the runner compares the SHA-256 of
`third_party/Chart.js/test/fixtures/<path>` with the `sha256` of the manifest item (it also
accepts the bytes with each CRLF changed to LF). A fixture test skips with the reason
`'n/a: the submodule third_party/Chart.js is not checked out'` when the submodule is absent. It
fails instead when `FIXTURES_REQUIRED=1`. Only that job sets this variable. A `CI=true` rule
cannot do this, because GitHub sets `CI=true` in every job ([Chart.js ADR
0029](adr/0029-fixture-smoke-runner.md) §11).

## 4. Tooling owned by this flow

**1. Library import guard** (`tool/check_lib_imports.dart`, `check:lib-imports`, phase 1). The
melos script `check:port` and the CI job `port-checks` run tools 1-3 and the checks of tools 6
and 8. Tool 1 uses allowlists:
- `lib/`: `dart:async`, `collection`, `convert`, `core`, `math`, `typed_data` and `ui`, the
  `package:flutter/` libraries `foundation`, `gestures`, `painting`, `rendering`, `scheduler`,
  `semantics`, `services` and `widgets`, `package:meta/meta.dart`, `package:intl/intl.dart` with
  its `number_symbols` files, and the package's own files. From phase 2, also
  `package:collection/collection.dart` with `show mergeSort`. From phase 5, also
  `package:clock/clock.dart` ([Chart.js ADR 0045](adr/0045-reference-engine-arm64.md)).
- Pure layers: the same list without `dart:ui` and `package:flutter`, over the transitive closure.
  The roots of the closure are the list `pureRoots` of `tool/src/lib_imports.dart`:
  - `lib/src/js/`, `lib/src/types/`, `lib/src/kurkle_color/` and the helpers except
    `helpers.extras`
  - `core.defaults`, `core.element`, `core.config`, `core.adapters`, `core.interaction`,
    `core.layouts`, `core.animation`, `animation_spec` and `core.typedRegistry`
  - the files of `lib/src/elements/`
  - `platform.base`, `platform.basic` and `native_event`
  - `compile.dart` and `presets.dart` of `lib/src/theme/`
- Test files without `@TestOn('vm')`: pure layers, `package:test` and `pure.dart` only.
- The harness: the closure of `packages/chartjs_test_utils/lib/pure.dart` is a pure layer. It
  imports only pure libraries, `package:test` and the pure layers of `flutter_chartjs_port`.
- Ported files: no import of `lib/src/theme/` ([Chart.js ADR 0042](adr/0042-theming.md)). `lib/`
  never imports `material`, `cupertino`, `material_ui` or `forui`.

**2. Header check** (`tool/check_port_headers.dart`, `check:headers`, phase 1). It examines
`packages/flutter_chartjs_port/{lib,test,tool}/**`. When `packages/chartjs_test_utils` exists, the
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
  the submodules. Thus CI compares the paths with the pinned trees. A checked-out submodule at
  another commit than its pin fails the check. Under a commit pin, the `parity.md` links name the
  full pin commit.
- The Dart path equals the mapped path. For Chart.js `src`, 2.5 gives the path. A spec for
  `test/specs/<base>.tests.js` is `test/specs/<base>_test.dart` (section 1, step 5).
  `test/index.js` maps to `test/flutter_test_config.dart`. For other projects,
  `tool/port_sources.yaml` gives the target.
- Each `DIVERGES` marker names a `differences.md` row. Each row has a marker. Marker lines fit 80
  columns, because the line-length exemption needs a path. A marker is a line comment. A
  `DIVERGES` block comment fails.

A Chart.js version older than `chartJsVersion` is stale. Under a commit pin, the version is
`<release>+<sha8>`, and a header of the release alone is stale. The header restamp belongs to
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
- the `dart:math` functions `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`, `exp` and
  `log`. A display-only `sin` or `cos` carries `// js-ok: display only (Chart.js ADR 0045)`
  ([Chart.js ADR 0045](adr/0045-reference-engine-arm64.md)).
- the interpolation of a value with the static type `double` or `num`
- the calls and tear-offs of `dart:math` `max` and `min` with the type argument `double` or `num`.
  Use `jsMax` and `jsMin` ([Chart.js ADR 0045](adr/0045-reference-engine-arm64.md)).
- from phase 2, the sorts of `package:collection`: `mergeSort(`, `insertionSort(`, `.sorted(`,
  `.sortedBy(`, `.sortedByCompare(`, `.sortBy(`, `.sortByCompare(` and `.sortRange(`
- from phase 5, `DateTime.now(`. Ported code reads the time through `jsDateNow`, because only
  `clock.now()` follows the fake clock of `testWidgets` and `withClock`.

A site passes with `// js-ok: <reason>` at the end of its line, or alone on the line before it.
The lexical rules read the code without comments and strings. The interpolation rule and the
`max`/`min` rule resolve types with `package:analyzer`, a dev_dependency of `flutter_chartjs_port`.
[Chart.js ADR 0045](adr/0045-reference-engine-arm64.md) lists the forms that tool 3 does not find.

**4. Upstream manifest** (`tool/upstream_manifest/`, Node, `upstream:manifest`, job
`upstream-manifest`, mid phase 2). With `--src <checkout> --out <file>`, it writes
`packages/flutter_chartjs_port/doc/upstream/manifest.json` plus the fixture configs as JSON. A `vm` run of the
`describe` bodies finds the loop-generated cases: 163 cases from 26 `it` call sites in 8 spec files
at v4.5.1. 31 of them are in `helpers.easing`. Its fixture count becomes authoritative. It
also records the defaults inventory and the JS builtin sites. Only this tool and the reference
generators in `tool/reference/` need Node. They run on the porter's machine. In CI, only the
`upstream-manifest` job runs Node. The bump report and the watch preview read the committed
manifests or git.

**5. Spec-case tracking** (`tool/spec_cases.dart`, `test:cases` in the ubuntu test leg, mid phase
2). Each upstream case is `passed`, `failed`, `skipped(<reason>)` or `missing`. The tool fails on
unknown names. It also fails on `missing` cases in `ported` modules. The case mode runs
`flutter test --exclude-tags fixtures` (`caseTestArguments`), and tool 6 runs the same command.
The mode `--fixtures` is tool 7. Both modes also run the stale-block check (Chart.js ADR 0041,
section 8). The check reads the string literals of the Dart files of `test/` through `DartSource`,
without `test/tool/` (its literals are test input) and without the generated `*_reference*.dart`
files. A comment, a literal inside an interpolation and a literal with an interpolation do not
count. A literal whose whole text is `blocked: <module>` fails when each `src/` row of `<module>`
in `parity.md` is `ported` (the rows of `moduleRows`: the file name without its extension is
`<module>`, or the row is in a `<module>/` folder). It also fails when `<module>` has no `src/`
row, and on a literal that starts with `blocked:` and is not of the whole form
`blocked: <module>`. Thus a module row goes to `ported` only in the change that lifts its skips.
The check covers the spec files, `test/port/` and `fixtureSkips`. The runtime check of the
fixture runner (Chart.js ADR 0029 §9 item 6) stays.

**6. Parity generator** (`tool/parity.dart`, `parity` and `parity:check`, phase 5). It writes
`doc/parity.md` from these inputs:
1. The files of the pinned copies in `third_party/` and their `wc -l` line counts. Each file gets
   one row.
2. The rule-2 headers of the Dart files of both packages. They give the Dart target of a row. A
   `dart` entry of `status.yaml` gives the target of a row without a header, for example
   `platform.flutter.dart` for `platform.dom.js`.
3. `doc/status.yaml`: the text outside the tables, the status text of each row and the port-only
   rows.
4. The case results of tool 5, and the case and fixture counts of `doc/upstream/manifest.json`.
5. The `DIVERGES` markers and the rows of `differences.md`.

The spec table has the columns Cases and Fixtures. Placeholders in the texts of `status.yaml` give
the derived values:
- `{{differences}}` gives the `differences.md` row count by category and the links of the hunks
  of the row ([theming.md](theming.md) §7). For a spec row, the rows of its `diverges:` skip
  reasons also count.
- `{{passed}}`, `{{failed}}`, `{{skipped}}`, `{{missing}}`, `{{cases}}` and
  `{{skipped:<reason>}}` give the case counts of tool 5.
- `{{platforms}}` gives the test legs from `@TestOn('vm')`. `{{files:<glob>}}` counts files.
  `{{rows:<area>:<status>}}` counts the rows of a Summary area.

These findings are errors:
- a `status.yaml` entry of a file that no table lists
- a status that does not start with a value of section 1 step 7
- an unknown placeholder, or a placeholder without a value
- a row with hunks and no `{{differences}}`
- a `dart` entry of a row with a header

These findings are warnings: a row with a Dart file and the status `not started`, a port-only Dart
file that no port-only row names, and a port-only path that does not exist. `parity:check` fails
when `parity.md` differs from the output, or on an error. `check:port` and the CI job
`port-checks` run it. `--import` reads the cells of `parity.md` back into `status.yaml`.
`--import --base <file>` keeps the entries of the cells that did not change after `<file>`. The
sections for the Flutter input mapping and for `test/types` do not exist yet.

**7. Fixture smoke runner** (`test:fixtures`, job `fixtures`, phase 7). It builds a chart from
each fixture config of a ported module and renders one frame. A test passes when no exception
occurs. The runner compares no pixels and keeps no ledger
([Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md)). It reads the list and the pure
data configs that tool 4 writes (`manifest.json`, `fixtures.json`) and the hand-ported configs in
`test/fixtures/hand/`, through the registry `test/fixtures/index.dart`. Before a fixture runs, it
compares the SHA-256 of the upstream file in `third_party/Chart.js/test/fixtures/` with the
manifest. `test:fixtures` is tool 5 with `--fixtures`: it runs the tests with the tag `fixtures`
of the spec files with a fixture group and of `test/port/fixtures/`, and reports each fixture as
passed, failed, skipped or missing. The job `fixtures` makes a shallow checkout of
`third_party/Chart.js` and sets `FIXTURES_REQUIRED=1` ([Chart.js ADR
0029](adr/0029-fixture-smoke-runner.md)).

**8. Port-order helper** (`tool/port_order.dart`, `port:next`, phase 5). It reads each `.js` and
`.ts` file of `third_party/Chart.js/src`, with its imports, re-exports and JSDoc `import()` types.
It also reads the port state of each module:
- A Dart file in `lib/` at the mapped path (2.5), whose rule-2 header names the module, starts the
  module. The status `in progress` or `partial` also starts it.
- The `parity.md` status `ported`, `replaced`, `distributed` or `n/a` makes the module done.

A module that is not started is ready when each value import is done. A `partial` module satisfies
the imports of the symbols that its status lists in backticks. These rules apply:
- An imported name that a module re-exports (an `index` file) is an import of the module that
  declares the name. Thus `plugin.colors.ts:1` needs `controller.doughnut.js`,
  `controller.polarArea.js` and `core.defaults.js`, not `src/index.ts`.
- A type-only import does not block a module (2.4). The type-only imports are `import type`,
  `export type`, a `type` specifier, an import of a `.d.ts` file, each import in a `.d.ts` file
  and a JSDoc `import()` type. The helper lists these types as the interfaces that the module
  needs. For each type, it names the Dart file that declares it: a file of `lib/src/types`, or the
  Dart file of the done module.
- An import of a JSON file of the pin is data, not a module. `core.controller.js:12` imports
  `version` from `package.json`. The port has `chartJsPackageVersion` for it.
- A package import is done when `tool/port_sources.yaml` has an entry for the package, for example
  `@kurkle/color`.
- Modules that import each other are ready together when no other import blocks them.
- The phase table does not name a phase for `src/index.ts`, `src/index.umd.ts` and `src/types.ts`.
  The helper gives them phase 9.

The list gives the ready modules in the phase order of section 5, with the upstream line count and
the number of modules that need each module. It also gives the modules in progress and the blocked
modules with their missing imports. `--json` prints the same data. `--check` fails in three
cases. The helper cannot read a module or a header line of `lib/`. A `parity.md` status is not a
value of section 1 step 7. An import does not resolve. The melos script `port:next:check` runs this
mode in `check:port` and in the CI job `port-checks`, which checks out the submodules. Without the
submodule, each mode exits with 2. Thus a gate without the checkout fails.

**Node and ADR 0001.** A dev-time Node tool is not runtime. Nothing in `lib/` or `test/` loads it.
[ADR 0001](../../../docs/adr/0001-native-ports-not-wrappers.md) records this in its Decision.

## 5. Revised phases

The roadmap in `packages/flutter_chartjs_port/doc/README.md` changes for these reasons:
- `helpers.options.ts:3` and `helpers.curve.ts:2` import `toFontString` and `_isPointInArea`.
- `core.ticks.js:2` calls `formatNumber`. The log10 spec loop needs fdlibm.
- Elements import only `core.element` from core. 20 of 21 element cases need no chart.
- 14 of the 23 core, element and scale spec files call `acquireChart`. Thus phase exits count cases.
- Master (unreleased, milestone 4.6.0) fixes `retinaScale` (#12142). It also changes doughnut
  spacing (#12238). ADR 0006 decides both. The commit pin `4.5.1+7169e651` of 2026-10-20
  ([upstream-tracking.md](upstream-tracking.md) §2.4) brings both.

| Phase | Scope | Exit criteria |
|---|---|---|
| 0. Scaffold | done; the design documents | CI green |
| 1. Decisions, minimum tooling, pilot | done; gate 1-2 ADRs; pins (2.13); tools 1-3; pilot by hand: `helpers.math`, `lib/src/js`, `geometric.dart`, `isFinite` from `helpers.core` | 12 `helpers.math` cases pass on VM, dart2js and dart2wasm; log10 comparison passes on the netlib port; AGENTS.md revised from the pilot; tools 1-3 green; gate 1-2 ADRs accepted |
| 2. JS runtime, helpers, defaults | done; rest of `lib/src/js` and `lib/src/types`; helpers except `helpers.canvas` and `helpers.dom`, plus `toFontString` and `_isPointInArea`; `core.defaults` closure; @kurkle/color; null-vs-undefined resolver tests; `pure.dart`; tools 4-5 | 181 non-chart helper cases and 5 `core.defaults`/`core.ticks` cases pass on VM, pure-layer cases also on dart2js and dart2wasm; `test:cases` reports none missing. Result: 179 of the 181 helper cases pass. The 2 `helpers.color` cases that need a canvas pattern and gradient skip as `blocked: helpers.canvas`. `test/port/helpers/helpers.color_test.dart` tests the same behavior with test classes. `helpers.rtl` is in progress: `overrideTextDirection` and `restoreTextDirection` need the canvas layer. `src/helpers/index.ts` re-exports `helpers.dom`. Both wait for phase 3 |
| 3. Canvas, text, platform, harness | done; `lib/src/canvas`; rest of `helpers.canvas`; rest of `helpers.rtl`; `helpers.dom`; `src/helpers/index.ts`; `platform.*`; internal chart host; phase-3 harness rows | non-chart canvas and DOM cases pass; the 2 `helpers.color` canvas cases pass; text-metric probe recorded. Result: the five phase 3 spec files have 66 cases. 21 pass, 0 fail and 45 skip. The 12 non-chart `helpers.canvas` cases, the 4 `helpers.color` cases and the 5 `helpers.dom` cases with a Flutter equivalent pass. 28 cases skip as `blocked: core.controller`, 15 as `n/a` (CSS, the shadow DOM, DOM ids, iframes, a web worker) and 2 as `diverges: platform-relative-position`. `test:cases` reports 205 passed, 0 failed, 47 skipped and 0 missing cases in the 17 ported spec files. The text-metric probe ([text-metrics.md](text-metrics.md)) found all 80 widths equal to Chrome. Chart.js ADRs 0013-0015 record the gate 3 decisions |
| 4. Elements | done; `core.element`, point, line, bar, arc, `elements/index`; the type members; `jsOrZero` and `js_webidl.dart` of `lib/src/js`; tool 1 roots | 20 of 21 element cases pass. Result: the five phase 4 spec files have 22 cases. 21 pass, 0 fail and 1 skips as `blocked: core.controller` (`element.line`, "should not cache path when animations are enabled"). 20 of the 21 element cases pass. `test:cases` reports 226 passed, 0 failed, 48 skipped and 0 missing cases in the 22 ported spec files. The port-only tests `test/port/core/core.element_test.dart` and `test/port/elements/` (the four elements and `index`) test the behavior that the specs do not test. Four generators of `tool/reference/` (point, line, bar and arc) write the reference data of the four element tests from an x64 build of Node.js v24.12.0. Chart.js ADR 0017 records the gate 4 decision. [performance.md](performance.md) §8 has the element draw cost on the Pixel 8a, on macOS and in Chrome with dart2wasm, and a number path in `toTRBL` and `toTRBLCorners` that cuts the bar draw time on macOS by about 12 % |
| 5. Core | done; `core.config` with hunks H0-H3 and their tests; registry to controller; phase-5 harness rows; tools 6 and 8 | non-chart core cases pass; others skipped `blocked: <module>`. Result of the port step and the harness step (2026-10-20): all 21 core modules have the status `ported`. The 14 core spec files have 286 cases. 98 pass, 0 fail and 188 skip. The 36 non-chart cases of the new core spec files pass: `core.animation` 6, `core.animations` 8, `core.animator` 1, `core.controller` 4, `core.layouts` 1, `core.registry` 15 and `core.scale` 1. The harness rows of phase 5 are done: `acquireChart`, `releaseChart`, `releaseCharts`, `triggerMouseEvent`, the release at the unmount and the built-in registration. Through the harness, 32 more `core.controller` cases pass (36/85), 19 `core.plugin` cases (19/19) and 3 `core.scale` cases (4/41). 188 core cases skip. Of these, 13 wait for a scale of phase 6, 164 for a controller of phase 7 and 10 for a plugin of phase 8. 1 case is `n/a` (DOM element ids). Of the 76 cases of the port step that waited for the harness, 74 pass. 1 skips as `diverges: platform-canvas-no-shadow`, and 1 as `blocked: scale.linear`. The review of phase 5 made two changes. The `data: []` case of `core.controller` passes: an array data gives a new Map (`adapt-config-objects`). The `core.scale` case "should throw error on scale with custom name without axis type" skips as `blocked: scale.linear`: its throw needs `defaults.scales.linear`. `core.controller.tests.js:918` passes too. It was `n/a` before. Outside core, `helpers.canvas` has 14/14, `helpers.dom` 7/22, `platform.basic` 2/5 and `platform.dom` 15/21. `test:cases` reports 337 passed, 0 failed, 213 skipped and 0 missing cases in the 32 ported spec files. No case skips as `blocked: harness`. Tools 6 and 8 run in `check:port`. The gallery has the Core tab and the stress mode `chart`. The adversarial review and the figures of the typed options on a real chart path come next |
| 6. Scales | done; seven scales; default date adapter on `DateFormat` (ICU tokens) | non-chart scale cases pass; moment-token cases skip as `diverges`. Result of the port, the specs and the fixes (2026-10-20): the seven scale modules and `src/scales/index.js` have the status `ported`, and `lib/src/index.dart` registers the six scales. The default date adapter is the five port-only files `lib/src/core/date_*.dart` (Chart.js ADR 0024). The five scale spec files have 233 cases. 22 pass, 0 fail and 211 skip: `scale.category` 2/19, `scale.linear` 7/45, `scale.logarithmic` 2/60, `scale.radialLinear` 2/23 and `scale.time` 9/86. 11 cases without a chart pass: the registration and the default config of each scale, and the date library of `scale.time`. 11 chart cases pass: 5 of `scale.linear` and 6 of `scale.time`. Of the 211 skips, 59 are `diverges: adapt-date-moment-format`. 140 wait for a controller of phase 7 and 12 for `plugin.legend` of phase 8. The 13 core cases that waited for a scale pass: `core.controller` 43/85 and `core.scale` 10/41. `test:cases` reports 372 passed, 0 failed, 411 skipped and 0 missing cases in the 37 ported spec files. The port-only tests compare 445 charts of the seven scale files and 8 charts of the harness with the chart.js 4.5.1 npm dist. They use the Liberation Sans widths, and the time charts use chartjs-adapter-moment 1.0.1 on moment 2.29.4. The date adapter gives the moment result for each reference call, also for the corpus of 357,576 calls. The 59 `diverges` cases of `scale.time` have port-only twins with ICU patterns: 2 pass and 57 wait for `controller.line`. Chart.js ADRs 0024 and 0025 record the gate 6 decisions (accepted 2026-10-20). The fixes wrote Chart.js ADR 0026 (accepted 2026-10-20) for the number formatting guards. The gallery has the Axes tab, the stress mode `axes` and the frameless benchmark `lib/main_bench.dart`. [performance.md](performance.md) §10.10-§10.11, §11 and §12 have the figures. On the Pixel 8a, the scale path runs at 53-58 FPS with 5000 points for the linear, logarithmic and time axes (§11.6). A category axis with 5000 labels ran at 7 FPS: the canvas metrics cache missed on each label. A larger cache with an eviction in one pass gives 29 FPS (§11.7). The iPhone, macOS and Chrome series wait (§11.8) |
| 7. Controllers | done; bar first, then the other seven; fixture smoke runner | controller and earlier chart-blocked cases pass or have rows; fixture smoke tests pass for the ported types; gallery shows every type. The commit pin landed before phase 7 (2026-10-20): Chart.js `4.5.1+7169e651`, the `master` commit after v4.5.1 ([upstream-tracking.md](upstream-tracking.md) §2.4). It ported #12130, #12142, #12155 and #12238 into the started modules. Phase 7 ports from the pin: `controller.doughnut` and `controller.polarArea` with the `spacingMode` of #12238 and its 3 new spec cases, and the fixture `controller.line/stacking/stack-cache` of #12155. The scale generators of phase 6 now read a build of the pinned commit, and their data did not change. Result of wave 1 (2026-10-21): the shared layer of Chart.js ADRs 0027, 0028 and 0030 and `controller.bar` have landed. `lib/src/js/` has `jsGetKey`, `jsGetIndex`, `jsSetIndex` and `jsLessThan`. `core.datasetController` reads parsed items through them and `stacksOf`, and its `ctx` is writable. `lib/src/types/index.dart` has the members of Chart.js ADR 0028. `lib/src/controllers/index.dart` exports `BarController`, and the namespace `controllers` registers it. The 8 phase 6 reference files were generated again with the element draws (8,455,931 to 9,069,771 bytes). `test/port/controllers/controller.bar_test.dart` compares 23 bar charts with upstream, again with the light preset, and 27 pin cases. The spec `controller.bar` has 51/55 cases that pass; 3 skip as `blocked: controller.line` and 1 as `blocked: plugin.tooltip`. `test:cases` reports 434 passed, 0 failed, 415 skipped and 187 missing cases in the 38 ported spec files (before phase 7: 383, 0, 411 and 242 in 37 files). The lift check (`lift_check.py`, a temporary script of phase 7, not kept) finds 62 of the 122 records of wave 1 and earlier that pass. The other 60 skip as `blocked: controller.bar` in 8 spec files outside the controller spec files, and the lift of wave 1 (L1) takes them. Result of wave 2 (2026-10-21): `controller.line`, `controller.bubble`, `controller.doughnut`, `controller.polarArea` and `controller.radar` have landed, and the namespace `controllers` registers them. The reference tests compare 17 line charts, 7 bubble charts, 15 doughnut charts, 9 polar area charts and 8 radar charts of Chart.js ADR 0030 §7 with upstream, each again with the light preset, with 81 pin cases `parsed:` and `interfaces:`. The specs: `controller.line` 33/34 (1 `blocked: plugin.tooltip`), `controller.bubble` 10/11 (1 `blocked: plugin.tooltip`), `controller.doughnut` 11/13 (1 `blocked: controller.pie`, 1 `blocked: plugin.tooltip`), `controller.polarArea` 13/14 (1 `blocked: plugin.tooltip`) and `controller.radar` 11/13 (1 `blocked: plugin.filler`, 1 `blocked: plugin.tooltip`). L1 lifted the 60 records of wave 1 outside `controller.bar_test.dart`: `core.animator` 1, `core.datasetController` 3, `core.layouts` 5, `helpers.dom` 2, `scale.category` 2, `scale.linear` 25, `scale.logarithmic` 21 and `scale.time` 1. Each passed in the first run, with no change in `lib/`. `core.datasetController_test.dart` and `core.layouts_test.dart` moved to the VM: 1 pure case lost the web legs (`core.layouts` "should be exposed through Chart.layouts"). A1 made the animator members of Chart.js ADR 0029 §6. The integration fixed five shared defects that the units found: the old parsed item of `_insertElements`, the JS `+` of string options in `PointElement` (the hit tests, `getRange` and `size`) and `ArcElement`, the `undefined` chart area of `updateControlPoints`, and the `ToNumber` of the `arc` and curve arguments in the generators. `test:cases` reports 572 passed, 0 failed, 362 skipped and 102 missing cases in the 43 ported spec files. The lift check is green for wave 1: 122 of 122 records pass or skip with their verdict. The 293 records of the wave 2 lift list (L2) skip as `blocked: controller.*`. Result of wave 3 (2026-10-21): `controller.scatter` and `controller.pie` have landed, and the namespace `controllers` registers the eight controllers. The reference tests compare 17 scatter charts (the 6 cases of Chart.js ADR 0030 §7 and 11 pin cases, the 6 cases again with the light preset) and 8 pie charts (the 4 cases of §7 and 4 `interfaces:` cases, the 4 cases again with the light preset). The specs: `controller.scatter` 4/6 (2 `blocked: plugin.tooltip`), and `controller.doughnut` 12/13 since its case of :4 reads the registered pie controller. Pie has no spec file. L2 lifted the 293 records of wave 2 outside the controller spec files: `core.controller` 30, `core.datasetController` 38, `core.interaction` 43, `core.scale` 26, `core.ticks` 2, `element.line` 1, `platform.dom` 2, `scale.category` 11, `scale.linear` 11, `scale.logarithmic` 37, `scale.radialLinear` 18, `scale.time` 14, the 3 placeholders of `controller.bar_test.dart` and the 57 twins of `test/port/scales/scale.time_test.dart`. Each passes, with no change in `lib/`. The 2 records that read `_chartjs` and `Object.getPrototypeOf` check the effect of the array listener and the resolver type. `core.interaction_test.dart`, `core.ticks_test.dart` and `element.line_test.dart` moved to the VM: 3 pure cases lost the web legs (`core.ticks` 2, `element.line` 1). X-fix made `RadialLinearScale.xCenter` and `yCenter` `double?` (the `undefined` reset position of a new radar or polar area point), kept a string `data` as a `JsStringList` with no listener, and gave `toggleDataVisibility` the raw legend index with the key `ToString(index)`. `test:cases` reports 813 passed, 0 failed, 127 skipped and 96 missing cases in the 44 ported spec files. The lift check is green for waves 1 and 2: 508 of 508 records pass or skip with their verdict. The 16 records of the wave 3 lift list (L3) skipped as `blocked: controller.pie` (7) and `blocked: controller.scatter` (9). Result of step 4 (2026-10-21): L3 lifted the 16 records of wave 3: `core.controller` 7, `core.datasetController` 2, `core.interaction` 2 and `core.scale` 5. Each passed in the first run, with no change in `lib/`. The lift check is green for wave 3: 536 of 536 records pass or skip with their verdict. The fixture smoke runner (Chart.js ADR 0029) runs 529 fixtures of 20 spec files: 457 pass and 72 skip (33 `blocked: plugin.*`, 39 `diverges: adapt-date-moment-format`). `test/fixtures/hand/` has 119 hand ports: tool 4 classifies a string that holds the text of a sandbox stub as `global`, so `scale.time/autoskip-major.js` and `scale.time/offset-with-no-ticks.js` have hand ports. The 36 ICU twins of `test/port/fixtures/moment_twins_test.dart` pass. `element.point_test.dart` moved to the VM for its fixture group: its 4 cases without a chart lost the web legs (8 pure cases in phase 7). `dart_test.yaml` declares the tag `fixtures` in both packages. The CI job `fixtures` checks out `third_party/Chart.js` at depth 1 and sets `FIXTURES_REQUIRED=1`. `test:cases` reports 831 passed, 0 failed, 111 skipped and 94 missing cases in the 45 ported spec files. Result of step 5, the gallery (2026-10-21, Chart.js ADR 0031): the home list opens a page for each of the nine chart types, with 12 variants: the 11 `chart-editor` blocks of `docs/charts/*.md` and the Area sample. Area draws only its line until the filler of phase 8. The gallery controller `StressPointController` is gone. The Core tab, the Axes tab and the stress mode `axes` run a `LineController` chart. The stress mode `chart` and the frameless benchmark run each of the eight controllers (the define `TYPE`, 12 new benchmark cases). Line and scatter keep the scene, the chart area and the draw split of phase 5 on two hidden unit scales. Each control of the changed pages is a full-width segmented button, and each chart is in view at 412 x 915 (the type pages also at 360 x 640). [performance.md](performance.md) §6 and §13.5 have the defines and the figures of the decision. Step 7 measures the sides A, A' and B (§13.6). Result of step 6, the adversarial review (2026-10-21): a finder for each of 17 file groups (each controller, the shared layer, the elements and scales, the fixture runner, the hand ports, JS semantics and the ADRs, the tests and reference data, the gallery and the docs), and a judge for each finding. The judges confirmed 21 findings (6 medium, 15 low, none high) and refuted 1. The fixes: a dataset axis id that is a number no longer throws, because `linkScales` keeps the raw id and the `ChartMeta` axis ids are `Object?`. `parseObjectData` casts each parsing key at its read in the loop. `PointElement.size` tests the raw radius. `jsToString` of a `DateTime` gives the V8 zone name (row `platform-date-zone-name`). Tool 4 marks a config with a stub string as impure, so two `scale.time` fixtures got hand ports (119 in all). Tool 3 flags a `dart:math` tear-off. The tab bar of the page "Phase 3: canvas and host" fits at 412 x 915 and 360 x 640, and a change of the stress mode keeps a valid count. Chart.js ADR 0036 restates Chart.js ADR 0027 with these rules and supersedes it. With the fdlibm `sin` and `cos` of Chart.js ADR 0032, the Windows leg of CI run 39569626698 passed the doughnut and pie hits on the border of two arcs (ADR 0032 Open 1). Thus the border hit queries stay in the controller data, and the pie data is `[5, 15, 10, 20]`. CI run 39581171519 of the step 6 commits passed its 14 jobs. Result of step 7, the performance (2026-10-21 to 2026-10-22, [performance.md](performance.md) §13.6-§13.8): the move to Flutter 3.47.7 (`c0a6576`) came first, so step 7 measured the tree before phase 7 (`0e0ab93`) again on that toolchain. The figures are G-U6 (the A/B of §6) on the Pixel 8a and macOS, the frameless benchmark before and after on the Pixel 8a, the iPhone 17 Pro, macOS and Chrome, the stress frames of the eight chart types, and CPU profiles against upstream Chart.js on the same phone. Of five candidate fixes, each with an ABBA series by a rule written before its runs and an independent recompute, one landed: `bar-ring-zero-inner`, a bar border ring with an empty inner shape fills as a rect (the `chart.bar` draw -21 to -26 % on the Pixel 8a, -13 to -14 % on macOS and -28 to -31 % in the VS Code browser with dart2wasm). The rule rejected the other four (§13.7 item 10). The hot spots of §13.7 item 11, for example the arc draw, have no fix. The radar and polar area frames answer Chart.js ADR 0032 Open 2 (§13.8). End of the phase (2026-10-22): the exit criteria hold at `86ca63c` (CI run 39777502932: 20 jobs passed, `dco` skipped). `test:cases` reports 831 passed, 0 failed, 111 skipped and 94 missing cases. The 94 missing cases are in the 9 plugin spec files with no Dart tests, so the 45 ported spec files have 0 missing cases. Each skip has a valid reason (`blocked: plugin.*`, `n/a` or `diverges`). The seven controller spec files have 146 cases: 137 pass, with the 11 non-chart cases, and 9 skip (8 `blocked: plugin.tooltip`, 1 `blocked: plugin.filler`). `test:fixtures` runs 529 fixtures: 457 pass and 72 skip, also in the CI job `fixtures`. The eight controllers have reference tests through real charts on the VM. The gallery shows the nine chart types. The design step wrote Chart.js ADRs 0027-0031 from five panels. Two later panels wrote Chart.js ADRs 0032 and 0033. A parallel ADR session restated Chart.js ADR 0032 and wrote Chart.js ADRs 0034 and 0035. The review wrote Chart.js ADR 0036. Chart.js ADRs 0028-0036 are accepted, and Chart.js ADR 0036 supersedes Chart.js ADR 0027. Other records of the phase: the module-start check of 2026-10-20 found no tag after v4.5.1 and no commit after the pin ([upstream-tracking.md](upstream-tracking.md) §4.3). U0 ran the 8 phase 6 generators once with `registerPhase7`. Their data was byte-identical, so they keep `registerPhase6` (Chart.js ADR 0030 §3 item 5). The probe harness (`run_spec.mjs`, `compare.mjs`), the classification of the 536 records (Chart.js ADR 0030 §12) and `lift_check.py` were working files of phase 7. They are not kept. The lift check was green after each wave: 536 of 536 records at the end. Accepted Chart.js ADR 0033 keeps some `lib/` and `test/` line citations from before its implementation, and its §9 and Open item 3 call Chart.js ADR 0032 proposed. Chart.js ADR 0032 is accepted (2026-10-21). Accepted Chart.js ADR 0030 cites old line numbers of `tool/reference/scale_chart_common.mjs` (`:759` for `observe`, `:910-940` for `drawCalls`). An accepted ADR does not change, so the code is the reference. The environment script `env-setup.sh` of Chart.js ADR 0030 (Evidence) was a working file of phase 7 too. The header of `tool/reference/scale_chart_common.mjs` gives the build steps of the reference engine and the checksums of the phase 7 build, and AGENTS.md (Tests) gives the moment packages. The accepted Chart.js ADRs 0027-0033 cite decisions of the phase lead by their ids in the progress file of phase 7, a working file that is not committed. The decisions and the docs that hold them: D1, the bar cases `controller.bar.tests.js:1426`, `:1442` and `:1538` get bodies, because they pass without the legend (Chart.js ADR 0030 §12 item 6); D3, the layout rule of the user for the gallery (Chart.js ADR 0031 §10, AGENTS.md); D4, the CI job `fixtures` keeps the submodule checkout and `FIXTURES_REQUIRED=1` (Chart.js ADR 0029 §3 and §11); D7, `jsToString` of a `DateTime` without the zone name, replaced by the V8 zone name of Chart.js ADR 0036 (row `platform-date-zone-name`); D8, the hit items of the controller data are JSON text lines (Chart.js ADR 0030 §3 item 6); D10, line and scatter read the parsed values inside one pass of `updateElements` (the 3-read form of Chart.js ADR 0036 §8); D11, the unit X-fix of wave 3: the `double?` radial centers (Chart.js ADR 0033), the `JsStringList` of a string `data` and the raw legend index of `toggleDataVisibility` (Chart.js ADR 0036, Chart.js ADR 0028); D13, the controller generators drop each ill-conditioned hit query, replaced before it landed: the queries stay (Chart.js ADR 0032, Alternatives and §10); D14, the design panels of Chart.js ADRs 0032 and 0033. |
| 8. Plugins | done; seven plugins; hunks H4a-H4c and H5 and their tests; input path of the legend and the tooltip (Chart.js ADR 0037) | plugin cases pass; `plugin.*` fixture smoke tests pass. Result of the port step (waves 1-4, 2026-10-22 to 2026-10-23, Chart.js ADRs 0037-0043, proposed): wave 1 ported `plugin.title` and `plugin.colors` with the hunks H4a-H4c and H5, the theme tokens of the palette, the input path of the chart host and the stale-block check of tool 5. Wave 2 ported `plugin.subtitle`, `plugin.legend`, the 8 files of `plugin.filler/` and `plugin.decimation`. Wave 3 ported `plugin.tooltip` and the merge of `helpers.merge` into an element target. Wave 4 is one change (Chart.js ADR 0041 §7 item 6): the namespace `plugins` and `registerables` have the seven plugins, and `flutter_test_config.dart` sets `defaults.plugins.colors.enabled = false`. The 16 dist generators and the 2 source generators register the plugins and ran again. The reference tests take 8.8 % more time ([performance.md](performance.md) §14.2). The doughnut, pie and polar area generators have the `legend:` cases with the real legend. New reference tests compare the hook dispatch of the seven plugins (`test/port/plugins/index_test.dart`) and the input path of the chart host (18 cases, `test/port/platform/chart_host_input_test.dart`) with upstream. The stress and benchmark charts turn off the legend with `plugins.legend: false` ([performance.md](performance.md) §14.3). The Core and Axes tabs keep the legend and the tooltip. Wave 4 lifted the 33 spec skips (`core.controller` 4, the seven controller spec files 9, `core.layouts` 6, `platform.basic` 2, `scale.category` 4, `scale.linear` 2, `scale.radialLinear` 3, `scale.time` 3) and the 33 fixture skips, with 8 new hand ports (147 in all). Each lift passed with no change in `lib/`. `test:cases` reports 955 passed, 0 failed, 81 skipped and 0 missing cases in the 53 spec files (end of phase 7: 831, 0, 111 and 94). The skips are `n/a`, `diverges` and the 3 `blocked: index.umd` cases of `global.namespace`. No `blocked: plugin.*` skip stays. `test:fixtures` runs 667 fixtures: 628 pass and 39 skip (all `diverges: adapt-date-moment-format`). The lift check of phase 8 is green: 131 of 131 records. Result of steps 4-6 (2026-10-23): the audit of step 4 found no `lib/` defect: each assertion value of the `plugin.legend`, `plugin.tooltip` and `global.defaults` spec ports equals the value of the pinned build, and no test result changed. Step 4 measured the import of the fixture registry again: far below the trigger of 4 s ([performance.md](performance.md) §14.4). Step 5 closed the theming of phase 8: test 3 with the plugin keys and the palette, the full blue screen, and no "phase 8" entry in `notThemed` ([theming.md](theming.md) §10). Step 6: the type pages of the gallery show the legend, the title and the tooltip, and the Area page fills, with the four fill actions of `docs/samples/area/line-boundaries.md` (`origin`, `start`, `end` and `false`) as its variants. The counts of `test:cases` and `test:fixtures` did not change. Step 7 (2026-10-23) was the review. At its end, the porting lead accepted Chart.js ADRs 0038-0043: Chart.js ADR 0042 supersedes Chart.js ADR 0001, and Chart.js ADR 0043 supersedes Chart.js ADR 0006. Chart.js ADR 0037 waits for the device check of step 8. Phase 8 closed these Open items of accepted ADRs: Chart.js ADR 0030 Open 5 (the full blue screen and test 3 with the colors plugin; the active element case waits for `IdentityChartHover`, Chart.js ADR 0042 Open 4), and the two phase 8 items of Chart.js ADR 0031 Open: the stress and benchmark charts turn off the legend with `plugins.legend: false` ([performance.md](performance.md) §14.3), and the Area page has the four fill modes as variants. Result of step 8, the performance (2026-10-23 to 2026-10-29, [performance.md](performance.md) §14.6-§14.9): the frameless benchmark measured the plugin cells of the hook dispatch, the tooltip, the legend, the title and the filler on the Pixel 8a (the dispatch and the tooltip), the iPhone 17 Pro, macOS and the VS Code browser (Chromium, dart2wasm). The maintainer stopped the Pixel 8a series at the battery gate, and no iPhone run occurred from 2026-10-23 21:00 to the stage 1 series of the night A/B tests on 2026-10-29 ([performance.md](performance.md) §14.9). Thus the Pixel 8a has no fill, legend, title or upstream figure. The stress entry gave the before/after record of the line and radar charts on the Pixel 8a (the radar draws its default fill now: 1.80x draw at 20000 points), and the plugin scenes on the iPhone 17 Pro, macOS and the VS Code browser. An independent recompute agrees with each figure and decision. CT rule 1 (Chart.js ADR 0038 §10) failed on each platform (R4, and R2 and R3 on the Pixel 8a). Its stage 2 (P5) ran on macOS and in the VS Code browser in the night of 2026-10-28 to 2026-10-29: rule 2 is false on both platforms (the gain of CT in R2 and R3 is below 0.1 ms on each platform), so CT stays closed, and Chart.js ADR 0020 Open 1 and Chart.js ADR 0038 Open 1 close with the figures. Tooltip rule T1 fired on the Pixel 8a and in the VS Code browser. Its design panel kept Chart.js ADR 0039 §7: the cost is the paragraph build of new tooltip lines in the canvas layer, not the option reads. Rule F started P6, with two variants of the fill text of the canvas layer (V1, a quantized alpha; V2, an opaque paragraph in a layer): the rule rejected both variants on macOS (slower text draws in the guard and control cells) and accepted both in the VS Code browser, and V2 failed the raster check on macOS (0.16 ms more raster time for each frame). Thus no variant is accepted, the present paragraph cache stays, and Chart.js ADR 0039 Open 2 closes with the figures. The `stack` fill drew 1.85 times the upstream time in the VS Code browser, so Chart.js ADR 0040 Open 3 went to a design panel. The panel wrote Chart.js ADR 0044 (the stack fill search): the loop of `_boundSegment` with direct calls and an `int` index (row `adapt-bound-segment-loop`), and a window search of the lines below in the stack line (row `adapt-stack-line-window`). The bound segments, the results of `interpolate` and the stack points are the upstream ones (6000 random stack charts against the pinned build). Its code A/B gave ACCEPT on macOS and REJECT in the VS Code browser: with the change, the stack draw was 0.056 times the upstream time in the VS Code browser, but the draw of the radar fill (a guard cell) was 5.5 % slower, and 9 control cells were slower. Thus the change went out of the tree, the stack fill stays quadratic, as upstream, and Chart.js ADR 0040 Open 3 stays open. The registry import on a quiet Mac stays below the trigger of Chart.js ADR 0029 Open 2. The upstream comparison of the plugin cells (P3) ran in the VS Code browser on 2026-10-29: the largest excess of a plugin cell is `fill.stack` update at N 1000, 19.598 ms for each frame (1.90 times upstream), and 86 of the 100 cells have an excess of 0.1 ms or more. The phones have no upstream figure. No variant of a performance rule landed: CT, P6, the T1 memo and Chart.js ADR 0044 have no accepted figure. The input check of Chart.js ADR 0037 on the Pixel 8a (no timing; Chrome 155 on the same phone) found five differences in its first rounds, which `78129b8` fixed, and one in the re-check: Chrome puts the compatibility events and `click` of a stylus tap at the up position (STN10), which `102634b` fixed. Round g1 ran STN10 and its regression rows again with the fixed host on 2026-10-29: all 9 rows pass, and the three optional stylus rows (a long press, a tap outside and a lift outside the host) pass too. Thus the device gate of Chart.js ADR 0037 is met. End of the phase (2026-10-29): the exit criteria hold at `357428c` (CI run 40818984994: 20 jobs passed, `dco` skipped). `test:cases` reports 955 passed, 0 failed, 81 skipped and 0 missing cases in the 53 spec files. The nine spec files of phase 8 have 94 cases: 91 pass, with the 13 non-chart plugin cases. The 3 `global.namespace` cases at :6, :26 and :35 skip as `blocked: index.umd` (phase 9), because their statics come from `index.umd.ts:30-43`. No `blocked: plugin.*` skip stays. `test:fixtures` runs 667 fixtures: 628 pass and 39 skip (all `diverges: adapt-date-moment-format`), also in the CI job `fixtures`. The 138 `plugin.*` fixtures pass. Each plugin has reference tests through real charts on the VM, and `test/port/plugins/index_test.dart` compares the hook dispatch of the seven plugins with upstream. The theming hunks H4a-H5 and their tests pass. The exit criterion "Chart.js ADR 0001 is accepted in full" changed with the theme panel: Chart.js ADR 0042 is accepted, and it supersedes Chart.js ADR 0001. The gallery shows the legend, the title, the tooltip and the Area fill. [performance.md](performance.md) §14.7 and §14.9 have the figures of the plugin paths on the iPhone 17 Pro, macOS and the VS Code browser, and the dispatch and the tooltip on the Pixel 8a. The design step wrote Chart.js ADRs 0037-0042 from six panels. Wave 3 wrote Chart.js ADR 0043, and step 8 wrote Chart.js ADR 0044. Chart.js ADRs 0038-0043 are accepted (2026-10-23): Chart.js ADR 0042 supersedes Chart.js ADR 0001, and Chart.js ADR 0043 supersedes Chart.js ADR 0006. Chart.js ADR 0037 is accepted (2026-10-29) after the device round g1 of STN10 (2026-10-29); it supersedes Chart.js ADR 0014, and the live citations moved from Chart.js ADR 0014 to Chart.js ADR 0037. Chart.js ADR 0044 is rejected: its code A/B rejected the change in the VS Code browser (2026-10-29), the change went out of the tree, and [Chart.js ADR 0046](adr/0046-stack-fill-search-result.md) records the result. Phase 8 closed these Open items of accepted ADRs: Chart.js ADR 0030 Open 5, the two phase 8 items of Chart.js ADR 0031 Open, Chart.js ADR 0039 Open 4 (the four private rounded rectangle classes stay: `_Rect` of `element.bar.dart` and `_RoundedRect` of `scale.radialLinear.dart`, `plugin.legend.dart` and `plugin.tooltip.dart`; the same behavior, no measured gain, and one literal at each site, as upstream) and Chart.js ADR 0039 Open 1 (T1 fired, and the design panel kept §7). Chart.js ADR 0029 Open 2 does not fire: the import of the fixture registry costs 0.45 s on a busy Mac and +0.703 s (upper end +1.882 s) on a quiet Mac, below the trigger of 4 s, so one registry stays. The night series closed Chart.js ADR 0020 Open 1 and Chart.js ADR 0038 Open 1 (P5: CT is not adopted) and Chart.js ADR 0039 Open 2 (P6: the present paragraph cache stays). Chart.js ADR 0040 Open 3 stays open. The commits of the phase on `main`: wave 1 `64ad3c9`, `22180ec` and `963bc66`; wave 2 `6dc24fd` and `3d0ff08`; wave 3 `45e9b66`, `2605c27`, `b40dbd5` and `5c446c0`; wave 4 `20a59f9`, `bbd2c52` and `2db0ddb`; steps 4-6 `1fdca0a`, `2e6a2ab` and `aadc3f3`; step 7 `4153c91`, `43b0747` and `92ead8c`, and the acceptance `cc10c73` and `20d5ed9`; step 8 `4e332a5` (the benchmark cells), `ce340ca` (the stress scenes, and the stress entry on dart2wasm), `78129b8` and `363f28d` (the touch path after the device check), `102634b` (the stylus tap point), `a5a3ce6` (the record), `1d271cd` (the generators on arm64 Node.js) and `357428c` (the acceptance of Chart.js ADR 0037, Chart.js ADR 0046 and the night record of performance.md). Other records of the phase: the module-start check of 2026-10-22 found no tag after v4.5.1 and no commit after the pin ([upstream-tracking.md](upstream-tracking.md) §4.3). Chart.js ADR 0029 says that phase 8 hand-ports "the 11 impure skipped configs". Only 8 of them were `blocked: plugin.*`, and phase 8 hand-ported these 8: `controller.line/backgroundColor/scriptable.js`, `controller.line/fill/no-border.js`, `controller.line/fill/scriptable.js`, `controller.radar/backgroundColor/scriptable.js`, `controller.radar/fill/scriptable.js`, `core.interaction/drawActiveElementsOnTop-false.js`, `core.interaction/nearest-partial-bar.js` and `core.interaction/nearest-point-behind-scale.js` (147 hand ports in all). The other 3 (`scale.time/invalid-data.js`, `skip-null-gridlines.js` and `skip-undefined-gridlines.js`) keep the skip `diverges: adapt-date-moment-format`. Chart.js ADR 0029 is accepted and does not change. The stress and benchmark charts turn off the legend with `plugins.legend: false`, not with `legend.display: false`: the same chart area, and 3.3 times faster updates of `chart.doughnut` at 5000 arcs on macOS ([performance.md](performance.md) §14.3). The Area page has the four fill actions of `docs/samples/area/line-boundaries.md` as its variants. Thus the two phase 8 items of Chart.js ADR 0031 Open close, and the accepted ADR does not change. The device series of step 8 ran only the rows and series that need no person at the phone: the touch rows with a finger (H01-H03) and the mouse rows (M01, M02) of the input check did not run, and Open 1 of Chart.js ADR 0037 names them as not checked. The Mac now runs macOS 27 with no Rosetta 2, so the x64 Node.js of the reference engine of Chart.js ADR 0032 cannot run. `1d271cd` removes the x64 checks of the generators. On arm64 Node.js v24.22.1 the generators give the same data, but `log10_reference.mjs` and `trig_reference.mjs` must not run on arm64: their fdlibm data then differ in the last bits and in the NaN signs (AGENTS.md). Chart.js ADR 0045 (proposed, 2026-10-28) states the engine move: Node.js v24.22.1 on darwin-arm64, with the x64 data of log10, atan2 and trig frozen. Until its acceptance, Chart.js ADR 0032 and the AGENTS.md rule "The reference engine" still name the x64 build. Its acceptance moves the citations of Chart.js ADR 0032 and gives the three fdlibm generators their x64 check back.. The probe harness, the classification of the 131 records, the lift check (green after each wave: 131 of 131 records at the end), the design drafts, and the protocols, raw data, scripts and recomputes of step 8 were working files of phase 8. They are not kept. |
| 9. Flutter API and release | public widget on the host; theme API; keyboard and semantics; docs; published floor (2.12); pana | `flutter_chartjs_port` 0.1.0 on pub.dev |

### 5.1 Deferred plans

A deferred plan records work that the port does not do now, so that the phases above keep their
focus. The phases do not wait for a deferred plan. Each deferred plan names its revisit point and
its triggers.

| Plan | Revisit point | Triggers that bring it forward |
|---|---|---|
| [canvas-cuts-plan.md](canvas-cuts-plan.md): cuts of own code in the canvas layer and the chart host, the web matrix fix (work package W), and the removal of the circle batch and of the text rotation snap | After phase 8, before phase 9. At that point (2026-10-29) the maintainer kept the open work packages deferred: the plan waits for a trigger ([Deferral](canvas-cuts-plan.md#deferral)). | Phase 5 starts the `acquireChart` harness: the default spec canvas is 512 x 256 until cut 2 lands (plan §3.3). This trigger occurred in phase 5: cut 2 landed ([Deferral](canvas-cuts-plan.md#deferral)). Ported code strokes or clips a path under a skew or a non-uniform scale on the web (plan §2.3). The toolchain pin moves to a stable Flutter release with the skwasm fixes (plan §4.2). Flutter batches `drawCircle` calls (plan §4.1). |

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
  invariants of Chart.js ADR 0042.
- New rule: JS numeric semantics.
- Licensing: SunPro, OFL. Item 1 becomes "its notice in the `LICENSE` of the package that
  contains the code" (the harness for chartjs-test-utils, the adapter for forui code). Commands and
  Layout: new scripts, packages, pins, `tool/` files.
- Phase 2 applied the Commands and Layout revisions, the JS numeric rule, the spec skip reasons
  and `setUpSpecs`. The other revisions wait for their phases.

**Repository files.**
- Root `pubspec.yaml`: `packages/chartjs_test_utils` in `workspace:`, new melos scripts,
  `--exclude-tags fixtures` in `test` (phase 7), and every `third_party` submodule in `upstream`.
- `packages/flutter_chartjs_port`: `meta`, `intl: ^0.20.2`, `collection: ^1.19.1` (phase 2),
  `clock: ^1.1.2` (phase 5), the dev_dependencies `chartjs_test_utils`
  and `test`, and `dart_test.yaml` with the `fixtures` tag (phase 7, also in
  `packages/chartjs_test_utils`). The PR that adds tool 2 adds the
  port-only marker to `lib/src/upstream.dart` and `test/upstream_test.dart`. Phase 1 added the
  dev_dependencies `test` and `analyzer` (for tool 3) and the two port-only markers.
- `ci.yaml`: phase 1 added a shallow `submodules: true` checkout in the ubuntu `test` leg (for
  `upstream_test.dart`) and in the job `port-checks` (tools 1-3). It also added the job `test-web`
  (dart2js and dart2wasm). Phase 2 added the job `upstream-manifest` (tool 4) and the `test:cases`
  step in the ubuntu `test` leg. Phase 7 added the `fixtures` job (a shallow checkout of
  `third_party/Chart.js`, `FIXTURES_REQUIRED=1`).
- `.gitmodules`, `commitlint.yaml` (the `chartjs_test_utils` scope), CONTRIBUTING.md
  (pre-push list), the PR template, and `REUSE.toml` (harness, fdlibm, font). Phase 1 changed
  `.gitmodules`, the pre-push lists of CONTRIBUTING.md and the PR
  template, and the fdlibm tables of `REUSE.toml`. Phase 2 added the harness table of `REUSE.toml`
  and `test:cases` to the pre-push lists. It removed the pixelmatch entry of `.gitmodules`. Phase 7
  added `test:fixtures` to the pre-push lists.

**ADRs and docs.**
- An accepted ADR does not change. A changed decision gets a new ADR that states the complete
  decision and supersedes the old ADR. The old ADR gets only the line "Superseded by".
- [ADR 0005](../../../docs/adr/0005-pin-upstream-sources.md) supersedes ADR 0002. It states the
  complete pin rules and the reference-only rules for dev-time tools.
  [ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md) supersedes ADR 0004. It
  states the backport rules without the status `verified`.
- Chart.js ADR 0010 superseded Chart.js ADR 0002, and Chart.js ADR 0011 superseded Chart.js ADR
  0005. [Chart.js ADR 0032](adr/0032-js-numeric-semantics.md) (2.3) supersedes
  Chart.js ADR 0010, [Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md) (2.2, 2.3,
  2.6, 2.10) supersedes Chart.js ADR 0009, and
  [Chart.js ADR 0035](adr/0035-third-party-sources.md) (2.13) supersedes Chart.js ADR 0011.
  [Chart.js ADR 0045](adr/0045-reference-engine-arm64.md) (2.3) supersedes Chart.js ADR 0032
  (2026-10-29): the reference engine moves to Node.js v24.22.1 on arm64.
  [Chart.js ADR 0012](adr/0012-dart-file-naming.md) (2.5) supersedes Chart.js ADR 0004. It adds
  the rule for the members of the type libraries.
- The phase 2 cleanup removed `third_party/pixelmatch` and its references. The Consequences of
  [Chart.js ADR 0009](adr/0009-no-display-only-js-exactness.md) have the list.
- [ADR 0007](../../../docs/adr/0007-package-names.md) supersedes ADR 0003. It records
  `chartjs_test_utils` and the adapter name `flutter_chartjs_port_forui`. The forui adapter change
  (after 0.1.0, [theming.md](theming.md) §5.3) adds its `commitlint.yaml` scope.
- When the maintainers accept this plan, `packages/flutter_chartjs_port/doc/README.md` takes the phase table of
  section 5. `parity.md` takes the new phase numbers.

Phase 0 already made the index edits. `docs/README.md` links the six new documents.
`packages/flutter_chartjs_port/doc/prior-art/README.md` lists the forui survey.

## 7. Risks and open questions

**Risks**

The numbers of the risks do not change, because ADRs cite them. A risk that no longer applies
stays in the list as closed.
1. **Text metrics.** 374 `toBeCloseToPixel` assertions depend on Chrome's font metrics. Failures
   become `differences.md` rows, not looser matchers.
2. **Skia leaves flutter_tester.** Closed. The port compares no pixels
   ([Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md)).
3. **Map resolver speed on dart2js.** It is about 1.6× slower than V8 on the scriptable path.
   Typed resolvers come only after parity, behind the same specs.
4. **Reference drift.** Closed. The port has no Canvas-call recordings
   ([Chart.js ADR 0034](adr/0034-no-display-only-js-exactness.md)).
5. **File-name lint gap.** If `file_names` starts to examine the whole name, 2.5 needs a new form.
6. **Hot modules.** element.arc, core.datasetController, plugin.tooltip, plugin.filler,
   helpers.dom, helpers.canvas, core.scale, core.controller, scale.time, scale.radialLinear,
   plugin.colors and controller.bar change most often. Keep them at the strictest fidelity.
7. **Unpublished dev_dependency.** Closed. pana resolves the package only without its
   dev_dependencies, and it formats `lib/` without the options of the workspace. A package
   `analysis_options.yaml`, a dev_dependency on `very_good_analysis` and a path dev_dependency on
   the harness fix it ([Chart.js ADR 0047](adr/0047-published-archive.md)).

**Open questions**
- fdlibm or correctly rounded libm for `log10` and `atan2`? log10 differs in the last bit on
  7/5,909 inputs.
  [Chart.js ADR 0045](adr/0045-reference-engine-arm64.md) keeps fdlibm for now. V8 `main` moved
  `Math.log10` to a correctly rounded libm on 2026-05-11.
- Tooltip after touch lift: Chart.js ADR 0037 (accepted 2026-10-29) keeps the Chrome result
  (#7738). The device check of its Open 1 closed the question on Android (its Evidence E8 to E11).
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
