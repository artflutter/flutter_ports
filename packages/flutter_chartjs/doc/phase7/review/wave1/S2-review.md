# Wave 1, unit S2 (core layer): adversarial fidelity review

## Result

No blocking finding. The ported lines of S2 keep the upstream behavior. The reads of PD §3 give
the same results as before (S1 review: `jsGetKey` and `jsGetIndex` give the `jsGet` result for
each receiver). The only changed result of `parse` is the `DateTime` order of Chart.js ADR 0027
§7. The early return of `getDataVisibility` gives the upstream result in each state. The
`points` setter and the by-name write have the copy of Chart.js ADR 0028 §3 and keep their
`DIVERGES` markers. There are three findings of low severity: one wrong upstream line citation,
one test that does not pin what it claims, and one doc text that is not correct for the radar
override. No finding changes a behavior that Chart.js ADR 0009 protects.

All paths are relative to `packages/flutter_chartjs/`. The probes are in
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/7a9baa8a-bd9d-417b-a53e-11aebf47f21e/scratchpad/wave1/S2-review/`.
The Node.js probe stops unless the Node.js is x64 v24.12.0. It reads the Chart.js build at the pin
`7169e651`.

## What the review checked

1. The DC diff against PD §3.1 and §3.2: each line of the table of §3.1 has `jsGetKey`. The reads
   that §3.1 keeps (`_parsedValue` at `isFinite`, `_updateStacks` `_stacks`, `_clearStacks`
   `_stacks`, the resolver and option reads) did not change. The 9 callers of `_item` and
   `_getIndex` call `jsGetIndex`. `_setAt`, `_lessThan` and `_toPrimitive` are removed. The sorted
   test is `jsGetKey(cur, iAxis) == null || (jsTruthy(prev) && jsLessThan(...))`: the `=== null`
   and the `prev &&` of dc.js:473. `prev` is `start > 0 ? jsGetIndex(...) : false`, as dc.js:457.
2. `core.controller.dart` against PD §3.3: the 3 callers of `_item` call `jsGetIndex`. The removed
   `_item` tested `index == index.truncateToDouble()`; `jsGetIndex` tests `i == index` after
   `toInt()` below the length. The two tests give the same result for each `double`.
3. `helpers.config.dart` against PD §3.4: `jsGetIndex(data, index)` is `data[index]` of
   `_parseObjectDataRadialScale`. `jsGet` of a non-List receiver gives the same result as the old
   `jsGet(data, jsNumberToString(index))`, because `jsGet` applies `jsToString` to a number key.
4. `getDataVisibility` against ADR 0028 §4 and cc.js:885-887. The early return is the text of
   IV §3.1. No marker, as the ADR says.
5. `ChartMeta.total`, `Chart.legend`, the `@override`s and the interface members against IV §2.1,
   §3.1-§3.5 and ADR 0028 §1. The signatures are the signatures of the spec. Each `///` citation
   of the new interface members was compared with the pinned file (`index.d.ts`, the controllers,
   `plugin.legend.js:602`, `:609`, `filler.target.js:50`, `core.scale.js:237`, `:239`, `:247`,
   `element.point.ts:81`, `core.element.ts:13`, `core.datasetController.js:257`, `:262`, `:713`,
   `:730`). All are correct except the one of F1.
6. `updateElement`: no other `void updateElement(` exists in `lib/`, `test/` or `apps/`. The cast
   `(element as Element)` adds no throw: each data and dataset element is an `Element`.
7. The `points` setter: no reader in `lib/src` adds or removes an item of `line.points` (`grep` of
   the List mutators). Upstream has no mutator of `line.points` either: the pushes of
   `filler.target.stack.js:71`, `:78` and `filler.segment.js:74-78` go to new local arrays. Thus
   `growable: false` is safe.
8. The writable `ctx` against TS §1.1: the field text is the text of the spec. The test draws the
   line and the two points on the recording context, and the next draw after the write back does
   not reach it.
9. The `getDataVisibility` moves case against `core.controller.tests.js:2109-2173`: the expected
   values are the upstream values at each step.
10. The implementers of IV §3.8, `_RadialPoint` and `fake_chart.dart`: the new members only. The
    `FakeChart.update` change keeps the old results for each `String` argument.
11. A run of `flutter test` on `test/port/types/index_test.dart`,
    `test/port/elements/element.line_test.dart`,
    `test/port/core/core.datasetController_chart_test.dart` and
    `test/port/core/core.controller_test.dart`: all passed. This review left no `flutter_tester`
    process.

## Findings

### F1 (low, confirmed): wrong line in the doc of `types.Element.hidden`

- File: `lib/src/types/index.dart:1119`.
- Claim: the doc says "core.controller.js:899 writes it". Line 899 is `this.update();`. The write
  `meta.data[dataIndex].hidden = !visible;` is at line 898. `core.element.dart:230` gives the
  correct line (898). ADR 0028 §1 gives the range `cc.js:892-899`. The error comes from the code
  block of IV §2.1 (spec line 184), which S2 copied.
- Probe (`citation.sh`): `sed -n 897,899p` of `third_party/Chart.js/src/core/core.controller.js`
  at `7169e651` prints `if (defined(dataIndex)) {`, `meta.data[dataIndex].hidden = !visible;`,
  `this.update();`.
- Recommendation: change `:899` to `:898` in `lib/src/types/index.dart`. The integration agent
  also corrects IV §2.1, or records the difference.

### F2 (low, confirmed): the record-type test of `getLabelAndValue` does not pin the type

- File: `test/port/types/index_test.dart`, group `DatasetController.getLabelAndValue`, the line
  `expect(result, isA<({Object? label, String value})>());`.
- Claim: the comment says that the line checks "the record type of Chart.js ADR 0028, section 2".
  The runtime type of a record comes from the runtime types of its field values, and record types
  are covariant. Thus the old return type `({String label, String value})` also passes the line.
  The test does not fail if the change goes back.
- Probe (`record_type.dart`, `dart run`): both the old and the new function give `true` for
  `is ({Object? label, String value})`. Both results have the runtime type
  `({String label, String value})`. The torn-off function keeps the declared return type: the old
  tear-off gives `true` for `is ({String label, String value}) Function()`, and the new one gives
  `false`.
- Recommendation: replace the line with
  `expect(controller.getLabelAndValue is ({String label, String value}) Function(double), isFalse);`
  This fails for the old signature. A test controller that overrides `getLabelAndValue` with a
  non-`String` label is a compile-time pin too.

### F3 (low, confirmed): the doc of `getLabelAndValue` is not correct for radar

- File: `lib/src/core/core.datasetController.dart`, the doc of `getLabelAndValue` (the text of
  IV §3.3).
- Claim: the doc says that the overrides of scatter, bubble, doughnut, pie, polar area and radar
  "return the raw label of `chart.data.labels`". Radar returns `vScale.getLabels()[index]`
  (`controller.radar.js:44`). `Scale.getLabels` reads the scale option `labels` first, then
  `xLabels` or `yLabels`, and `chart.data.labels` only after them (`core.scale.js:358-361`). The
  other five overrides return `labels[index] || ''` (ADR 0028 §2): a falsy label gives `''`, so
  their label is not the raw label either. Only radar can give the `undefined` sentinel.
- Probe (`radar_label.mjs`, x64 Node.js v24.12.0, `dist/chart.js` at the pin):
  `RadarController.prototype.getLabelAndValue` on a scale with the option
  `labels: ['option label 0']` and `chart.data.labels: ['data label 0']` gives
  `{"label":"option label 0","value":"1"}`.
- Effect: the doc only. The record type `Object?` is correct for all the overrides.
- Recommendation: "The overrides of scatter, bubble, doughnut, pie and polar area return
  `labels[index] || ''` of `chart.data.labels`, any truthy value. Radar returns
  `vScale.getLabels()[index]`: any value, Dart `null` for JS `null`, or the [undefined]
  sentinel." The integration agent also corrects IV §3.3.

## Not findings

- `ChartMeta.total`: a by-name write of JS `null` (Dart `null`) gives `undefined` at the next
  read. In JavaScript, the read gives `null`. No upstream code writes `null`, and `total > 0` is
  false for both. The other nullable typed fields of `ChartMeta` (`xScale`, `_scaleRanges`) have
  the same form. ADR 0028 §1 accepts it.
- The header of `test/port/types/index_test.dart` says "type members of Chart.js ADR 0028". IV
  §7.1 gives "the type members of Chart.js ADR 0028". `check:headers` accepts both. The text has
  no effect.
- The comparisons of `index_test.dart` through the interface and through the concrete class call
  the same method. They pin the signatures at compile time only, as IV §7.1 says. The runtime
  values (`legend` null, `total` null, `hidden` `undefined`, `getParsed(2)` `undefined`,
  `getPixelForTick(99)` null, `is types.RadialLinearScale` false for a cartesian scale) are
  pinned.
- The early return of `getDataVisibility` gives the same result as the upstream line. Thus no
  test can see it. The tests pin the slow path after toggles and after the moves of
  `_updateHiddenIndices`, as IV §7.1 asks.
- The copy of `line.points` loses the identity `line.points === meta.data` of upstream. ADR 0028
  §3 decides it, and the row `adapt-line-points-elements` covers it. The tests pin the identical
  items in the same order and the `TypeError` before the write.
- `fake_chart.dart` is not in the S2 row (S2 report, open item 1). Without the change the package
  does not compile. The change is the smallest valid override.
