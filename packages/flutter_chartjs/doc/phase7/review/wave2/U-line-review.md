# Wave 2, unit U-line: fidelity review

## Scope

The reviewer read `U-line-report.md` and the five files of the unit in full:

- `lib/src/controllers/controller.line.dart`
- `tool/reference/controller_line_reference.mjs`
- `test/port/controllers/controller_line_reference.dart` (generated)
- `test/port/controllers/controller.line_test.dart`
- `test/specs/controller.line_test.dart`

The reviewer compared each ported statement with `src/controllers/controller.line.js` at the pin
`7169e651`. The reviewer compared each spec case with `test/specs/controller.line.tests.js`, and
the decisions with Chart.js ADRs 0027, 0028 and 0030 and with the specs PD and IV.

All paths are relative to `packages/flutter_chartjs/`. The probe folder is
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave2/U-line-review/`
(below: `<review>`). No file of the repository changed, except this review.

## Result

Three findings. Two are behavior differences, and one is a set of wrong citations. Each finding
has a probe. No finding stops the merge of the unit by itself. Finding 1 needs a decision of the
phase lead (open item 1 of the report). Finding 2 is an input to ADR 0027 Open 4.

| # | Severity | Verdict | Subject |
|---|---|---|---|
| 1 | medium (a throw, Chart.js ADR 0009) | confirmed | `draw` throws a `TypeError` at `chart.chartArea!` where upstream does not throw. The doc comment of `draw` states a wrong premise. |
| 2 | low (the `stop` of a point and the line segments) | confirmed | `prevIValue` crosses the user code of `resolveDataElementOptions`. A scriptable option that writes `ctx.parsed` gives other `stop` values. |
| 3 | low (docs) | confirmed | Eight wrong file:line citations in the spec port and one in the generator. |

## Findings

### 1. The draw with no chart area throws in the port only

File: `lib/src/controllers/controller.line.dart:333-342`.

Upstream `controller.line.js:140` gives `this.chart.chartArea` to `updateControlPoints`, also
when it is `undefined`. A plugin that returns `false` from `beforeLayout` at the first update
leaves `chart.chartArea` undefined (`core.controller.js` `_updateLayout`). The chart then draws:
`_layers` is empty, and `_drawDataset` calls `meta.controller.draw()`. Upstream does not throw
for a line without tension. The port throws a `TypeError` at the null check
`chart.chartArea!`.

The doc comment of `draw` (`:334-335`) says: "`chart.chartArea` is set here: the chart draw reads
it before the draw of a dataset." The probe shows that this is not true. Open item 1 of the report
records the same difference. The doc comment in the lib file was not changed to agree.

Probe (`<review>/probe_upstream.mjs`, `<review>/probe_upstream.out`, x64 Node.js v24.12.0 and
the pinned build; `<review>/line_probe_test.dart`, `<review>/line_probe.out`):

| Chart (labels a to c, data 1 to 3, plugin `beforeLayout: () => false`) | Upstream | Port |
|---|---|---|
| line | no throw, `chartArea` undefined | `_TypeError` "Null check operator used on a null value" at `controller.line.dart:340:22` |
| line, `clip: false` | no throw, `chartArea` undefined | the same `_TypeError` at `:340:22` |

Fix (the phase lead decides, as in open item 1): make the area nullable in
`types.LineElement.updateControlPoints`, `LineElement.updateControlPoints`,
`updateBezierControlPoints`, `_capBezierPoints` and the `_LineSpy` of `test/support/jasmine.dart`,
and pass `chart.chartArea` without `!`. Or add a `DIVERGES` row. In both cases, correct the doc
comment at `:334-335` in the same change. Add a pin case (generator: an `error` key or no error)
for the two charts above.

### 2. `prevIValue` crosses user code that can write the parsed item

File: `lib/src/controllers/controller.line.dart:177-186`, `:212-216`, `:252-266`, `:291-293`.

ADR 0027 §8 lets a local replace a later read "only when no statement between the two reads
writes that key of that item". The doc comment of `updateElements` checks the statements between
`:99` and `:104` of one pass. That check is correct. But `prevIValue` replaces the read
`prevParsed[iAxis]` of `:104` at the next pass. Between the two reads, the pass calls
`resolveDataElementOptions` (`:111`). That call runs the scriptable options of the user, and
their context holds the parsed item (`ctx.parsed`, `getContext` of DC). A scriptable option that
writes `ctx.parsed[iAxis]` changes the value that upstream reads at `:104` of the next pass. The
port uses the old value.

Probe (`<review>/probe_upstream.mjs` and `<review>/line_probe_test.dart`): a linear x scale,
data `{x: 0..3, y: 1..4}`, `spanGaps: 1.5`, and `pointRadius: (ctx) => { if (first call with
dataIndex 1) ctx.parsed.x = 10; return 3; }`.

| Value | Upstream | Port |
|---|---|---|
| `stop` of each point | `[false, false, true, false]` | `[false, false, false, false]` |
| `line.segments` | `[[0, 1, false], [2, 3, false]]` | `[[0, 3, false]]` |
| `meta._parsed[1].x` after the update | 10 | 10 |

The parsed item has the same value in both. Only the `stop` of point 2 differs, and thus the
segments: upstream breaks the line between the points 1 and 2.

The case is rare: a scriptable option that writes the parsed item. It is not a pixel-only
difference, because the segment list changes. The 3-read fallback of ADR 0027 Open 4 reads
`jsGetKey(prevParsed, iAxis)` at each pass and gives the upstream result. The two in-pass
locals (`vValue`, `iValue`) are not affected: no user callback runs between `:99` and `:104`
with the built-in scales.

Recommended action: give this probe to the maintainer as an input to Open 4. If the maintainer
keeps `prevIValue`, the doc comment of `updateElements` must state the cross-pass interval
(`:105-118`, with `resolveDataElementOptions` at `:111`), and a `DIVERGES` row or a note in
`differences.md` must record the scriptable case. The same item applies to the scatter unit.

### 3. Wrong file:line citations

The reviewer read each cited range at the pin (`sed -n` of
`third_party/Chart.js/test/specs/controller.line.tests.js` and of
`src/core/core.datasetController.js`).

| File:line | Cited | Correct |
|---|---|---|
| `test/specs/controller.line_test.dart:404` | `:296-326` (the pixels of the first stacked case) | `:304-326` (`:296` is the `y` scale option) |
| `test/specs/controller.line_test.dart:405` | `:352-390` | `:369-391` (`:352` is `scales: {`) |
| `test/specs/controller.line_test.dart:405` | `:447-471` | `:449-471` |
| `test/specs/controller.line_test.dart:405` | `:502-527` | `:505-527` |
| `test/specs/controller.line_test.dart:705` | `:615-637` (the options of `lineOptions`) | `:657-667` and `:695-705` (`:615-637` is in the case "should be overridden by user-supplied values") |
| `test/specs/controller.line_test.dart:705` | `:664-686` (the expectations) | `:675-685` |
| `test/specs/controller.line_test.dart:706` | `:709-724` | `:713-723` |
| `test/specs/controller.line_test.dart:721` | `:674-684` and `:714-724` | `:675-685` and `:713-723` |
| `tool/reference/controller_line_reference.mjs:381` | `core.datasetController.js:686` (`getLabelAndValue`) | `:687` (`:686` is the end of the JSDoc) |

A change of the generator comment changes no generated byte (the comment is not in the output).
Run the generator again after the fix and compare the SHA-256.

## Checks with no finding

- Each statement of `controller.line.js:6-142` has a Dart statement in the same order:
  `initialize`, `update` (`:42-73`), `updateElements` (`:77-119`), `getMaxOverflow`
  (`:126-135`), `draw` (`:139-141`), the statics `id`, `defaults` and `overrides`. No upstream
  statement is missing.
- JS forms: `start > 0 && getParsed(start - 1)` is `false` or the item; `false[iAxis]` gives
  `undefined` through `jsGetKey`; `!!_dataset._decimated`, `!this.options.showLine`,
  `!animationsDisabled`, `_stacked ? ... : ...` and `if (segment)` use `jsTruthy`;
  `sharedOptions || ...` is `??` (shared options are an object or absent);
  `a && a.borderWidth || 0` keeps the raw value; `Math.max` gets the `ToNumber` of the border
  after the two `size` calls, as upstream. `NaN` comparisons of `i < start` and `i >= end` give
  the upstream result.
- The skipped points of an animated update write `skip` into the new object and then
  `continue`, as upstream (the object is discarded).
- `object ?? point as types.PropertyAccess` parses as `object ?? (point as ...)`. The cast runs
  only for a direct update.
- The verdicts of `all.json`: 33 cases of `controller.line.tests.js` are `phase7` and have bodies.
  The case `:1161` is `blocked: plugin.tooltip`, and the spec port skips it with that reason.
- The `describe` and `it` names and their order agree with upstream. The group `auto` is a
  comment at its upstream position.
- The headers of the four Dart files and of the generator are correct for their paths.
- The generator: a run in a mirror folder (`<review>/mirror/`, x64 Node.js v24.12.0, the pinned
  build) gave the SHA-256 `ec7573a936a2ac56e3fb923265ee7f272b3bb37d4f5a0c7dad2801329b095d2c`,
  byte-identical to the committed data.
- The 17 cases agree with the row `line` of ADR 0030 §7. The 11 `parsed:` cases cover the line
  rows of PD §7.3. The 3 `interfaces:` cases and the group `interfaces` cover the line rows of
  IV §7.3. The themed run skips the prefixed cases (`testControllerChartCases`).
- The relation tests pin what their names claim. The report gives mutation evidence for the
  one-read rule and for the writes of `:106-107`.
- No performance form changes the structure. `_setProperty` keeps each write in the upstream
  order. The writes by name are in the step 7 list of ADR 0027 §8.

## Processes

The Dart probe ran with `flutter test` once and ended. No `flutter_tester` process of this review
is left.
