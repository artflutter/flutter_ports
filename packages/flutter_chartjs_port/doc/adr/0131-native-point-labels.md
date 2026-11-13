# Chart.js ADR 0131: Native point labels

- Status: accepted (2026-11-13): its code passes the tests, the specs, the fixtures and the port checks.
- Date: 2026-11-13
- Related: Chart.js ADR 0130 (native callback options), Chart.js ADR 0095 (the radial static plans), the
  [design draft](../native-point-label-design-draft.md).
- Difference: `adapt-native-point-labels`.
- Supersedes: of Chart.js ADR 0130, the type `PointLabelCallback` (`Object? Function(Object? label, int index)`).

## Decision

1. `RadialLinearScale.pointLabels` is a `List<List<String>>`: one entry for each visible label, the lines of
   its point label. It replaces `List<Object?>`.
2. The option `pointLabels.callback` holds a `PointLabelCallback`, also in a raw config:

   ```dart
   typedef PointLabelCallback =
       List<String> Function(Scale scale, List<String> label, int index);
   ```

   The scale is the first argument, as in `TickCallback`. `label` is the lines of the item of `data.labels`.
   The result is the lines to draw: `['']` is one empty line, and `[]` is no line, with the height 0. The
   typedef is in `core.scale.dart`, because the typed API cannot import a scale module.
3. Before the callback, the scale turns each item of `data.labels` into lines (`labelLinesOf`). An item that
   Chart.js draws as `''` is `['']`. The default callback gives `label` as it is.
4. The point-label context holds the lines under `label`. Its getter stays `Object?` until the contexts are
   typed.
5. `RadialLinearAxis.pointLabelsCallback` of the typed API writes the option.
6. The static plans of Chart.js ADR 0095 read the lines: a label of more than one line takes the ordinary
   loop, and `[]` measures and draws as no line.

## Tests

`test/port/scales/scale.radialLinear_plans_test.dart`, `scale.radialLinear_test.dart` (the reference data maps
each upstream point label to its lines), `test/specs/scale.radialLinear_test.dart`, the radar and polar area
tests.
