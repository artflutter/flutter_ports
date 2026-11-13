# Chart.js ADR 0140: The option `fill` holds a `FillTarget`

- Status: accepted (2026-11-13, by the porting lead). The code and the tests of section Tests pass.
- Date: 2026-11-13
- Related: Chart.js ADRs [0054](0054-typed-internal-model.md) (the typed internal model),
  [0115](0115-hand-ports-of-typed-data-fixtures.md) (the hand ports of the data fixtures with a class value),
  [0139](0139-typed-dataset-shadow.md) (a native value in the native option plans). The row
  `adapt-fill-target-objects`. The draft `doc/native-chart-fill-design-draft.md`.
- Supersedes: parts of [Chart.js ADR 0052](0052-typed-public-api.md): the type `ChartFill` of the parameter `fill`
  in §1 and the name `ChartFill` in the file table of §1 (`values.dart`). Parts of
  [Chart.js ADR 0040](0040-filler-targets-and-plain-points.md) §6: the type `Object` of `FillerSource.fill` with
  its values `false`, a `double` index, a `String` mode or the object `{value}`, and the test
  `source.fill != false` of `_shouldApplyFill`.

## Context

Upstream `fill` (`FillTarget` and `ComplexFillTarget` of `index.d.ts:2300-2306`) has many forms: `false`, `true`, a
number (the index of a dataset), a keyword (`'origin'`, `'start'`, `'end'`, `'stack'`, `'shape'`), a relative index
as text (`'+1'`, `'-2'`), an object `{value}` and an object `{target, above, below}`. `parseFillOption` and
`_decodeFill` (`src/plugins/plugin.filler/filler.options.js:46-137`) turn them into the decoded fill of a source:
`false`, a dataset index, a keyword or the object `{value}`.

Before this ADR, the port held a part of these forms as native values: a keyword was the enum `FillBoundary`, and a
relative index was a `RelativeFill`, both under a sealed `FillTarget`. The number, the boolean and the two objects
stayed JS values. The filler read the objects by name through a facade, called `parseFloat`, tested `isFinite` and
cast to `num`. The typed API had a second type, the extension type `ChartFill` over `Object`, whose `optionValue`
gave the raw form.

The maintainer allows no JS shape where a native type fits, and no table from a name to a value.

## Decision

1. Each value of `fill` is a `FillTarget` of `lib/src/plugins/fill_target.dart`, in the typed API and in a raw
   config. The filler gets the same object.

   ```dart
   sealed class const FillTarget() {
     const factory toValue(double value) = ValueFill;
     const factory toDataset(int index) = DatasetFill;
     const factory toRelative(int offset) = RelativeFill;
     static const FillTarget none = NoFill();
     static const FillTarget toOrigin = OriginFill();
     static const FillTarget toStart = StartFill();
     static const FillTarget toEnd = EndFill();
     static const FillTarget toStacked = StackFill();
     static const FillTarget toPrevious = RelativeFill(-1);
     static const FillTarget toNext = RelativeFill(1);
     static const FillTarget shape = ShapeFill();
     FillTarget split({ChartPaint? above, ChartPaint? below});
   }
   ```

   `false` is `none`, `true` and `'origin'` are `toOrigin`, a number is `toDataset`, `'+n'` and `'-n'` are
   `toRelative`, `{value}` is `toValue`, and `{target, above, below}` is `target.split(above:, below:)`. Only
   `split` makes the class `SplitFill`, and `SplitFill.split` keeps its target: a split never holds a split. A Dart
   `null` color of a split takes the `backgroundColor` of the line, as the default of upstream. Each subclass has
   `==` and `hashCode`. The name stays `FillTarget`; the draft notes `LineFill` as a possible later name.
2. A value that is no `FillTarget` (a boolean, a number, a Map, a text) stops a debug build (`FillTarget.of`), and
   a release build takes no fill. Dart `null` stays the JS `null`: no fill. An absent fill takes the truthiness of
   `backgroundColor`, as upstream.
3. The decoded fill of a source (`FillerSource.fill`) is a `FillTarget` too: `none`, a `DatasetFill`, a boundary or
   a `ValueFill`. The ported functions keep their upstream names and order. `_decodeFill` takes `index + offset` for a
   `RelativeFill` and drops a target that is the dataset itself, negative or past the count; a NaN value gives no
   fill. `_resolveTarget` with `propagate` follows the hidden datasets of `DatasetFill` targets. The filler matches
   the subclasses. The reads by name, `parseFloat`, `isFinite`, the cast to `num` and the text `'+'` of the fill go.
4. The JS truthiness of a fill (the warning of `core.datasetController.js:287` and the `source.fill` test of
   `index.js:56`) is `fillTargetTruthy`: `none` and `toDataset(0)` are falsy, as `false` and `0` are upstream.
5. The schema shape of `fill` is the typed atom `fillTarget` only. The scope kind `FillTarget` and the keys `target`,
   `above`, `below` and `value` go, and with them the facade `FillTargetOptions`. The defaults of the line element
   and of the scatter dataset are `FillTarget.none`, and the radar default is `FillTarget.toStart`.
6. The typed API takes `FillTarget` in `LineDataset.fill`, `ScatterDataset.fill`, `RadarDataset.fill` and
   `LineElementStyle.fill`, and the lowering writes the object with no copy. `ChartFill` and `values.dart` go.
   `lib/chartjs.dart` exports `FillTarget` and its subclasses, so a plugin can match them.
7. The native option plans (`_indexedScalar` of `helpers.config.dart`) count a `FillTarget` as a scalar, a split
   only with plain paints. The static settings check of the data-only update (`staticDataUpdateOptions` of
   `data_update.dart`) accepts a `FillTarget`, a split only with solid colors of the exact class.

## Consequences

- One type holds the option from the app to the filler, and the compiler proves that each switch covers each form.
- A nested scriptable value in a fill object (`{value: (ctx) => ...}`) has no form: a scriptable fill returns its
  `FillTarget`. The two spec cases of `core.datasetController.tests.js` for it skip with
  `diverges: adapt-fill-target-objects`. The spec case of the invalid fill values keeps NaN (as a value fill) and
  `null`; the other values are no `FillTarget`.
- The data fixtures with a fill value are hand ports (Chart.js ADR 0115): 71 new ones. The 18 data fixtures of the
  moment skips hold only `fill: false`; the observation oracle and the moment twins give it `FillTarget.none`
  (`nativeFixtureFalseFills` of `test/support/fill_json.dart`). The fixture adapter has no rule for `fill`.
- The reference generators write the `FillTarget` of each fill (`tool/reference/fill_target.mjs`). The filler target
  generator drops its cases of values with no `FillTarget`. A split fill holds native paints
  (`nativeFixturePaint` of `chartjs_test_utils`), so a data file with one is a `final` list.
- A JSON text compare puts a marker on both sides for the fill (`withFillMarkers`).

## Alternatives considered

- **Keep the JS forms next to the native ones.** The filler then keeps its reads by name and its text parse.
  Rejected: it is the JS shape that the typed model removes.
- **Rename to `LineFill`.** The name fits `none`, `shape` and a split better. Not now: the draft keeps the name, and a
  rename is its own change.
- **Convert the fixture values in the adapter.** A map from a keyword to a member is a table. Rejected by Chart.js
  ADR 0115.

## Tests

- `test/port/plugins/plugin.filler/filler.options_test.dart` and `filler.target_test.dart` (the generator data).
- `test/specs/plugin.filler_test.dart`, `test/port/typed/values_test.dart`, `lowering_test.dart`,
  `docs_twins_test.dart`.
- `test/port/options/schema_test.dart` and `observation_test.dart`.
- `dart run melos run test:fixtures`: each hand port of a fill fixture runs and passes.
