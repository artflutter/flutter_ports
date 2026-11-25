# Chart.js ADR 0205: Typed parsed values

- Status: accepted (2026-11-25): its code is on main, and the gates of AGENTS.md pass.
- Date: 2026-11-25
- Supersedes: of [Chart.js ADR 0054](0054-typed-internal-model.md) §8, the type `Object?` of the axis
  fields `x`, `y` and `r`; of [Chart.js ADR 0036](0036-parsed-data.md), `jsLessThan` in §7 and §8; of
  [Chart.js ADR 0052](0052-typed-public-api.md), in the section "Data", `DataPoint.label` and the
  `DateTime` `x` of `DataPoint.time`
- Related: [Chart.js ADR 0202](0202-no-string-data.md), [Chart.js ADR 0204](0204-typed-chart-components.md)

## Context

A parsed item held `x`, `y` and `r` as `Object?`. The parse of each scale already gave a `double?`. The other
values came from `parsing: false`, where the data items of the app are the parsed items: a `DataPoint` held a
`DateTime` or a label `String` as `x`, and a test could write any value. Thus the 42 reads of a parsed value
converted with `jsToNumber`, compared with `jsLessThan`, tested with `jsIsNaN`, added with `jsAdd` and mapped
to a pixel with `scaleValueOf`, and an app read `point.x as double`.

## Decision

1. `x`, `y` and `r` of `ParsedItem` are `double?`. Dart `null` stands for the JS `null` and for an absent key.
   A write by name of another value stops a debug build, and a release build stores `null`.

   ```dart
   // Before
   Object? get x => hasSlot(0) ? _x : undefined;
   // After
   double? get x => _x;
   ```

2. `DataPoint.time` stores the time value in milliseconds. `DataPoint.label` is gone: a data item with a
   text `x` is a `LabelPoint`, which is no parsed item. The typed API gives a list of them with
   `DatasetData.labelPoints`.

   ```dart
   // Before
   LineDataset(data: .points([DataPoint.label('Mon', 20), DataPoint.label('Tue', 10)]))
   // After
   LineDataset(data: .labelPoints([LabelPoint('Mon', 20), LabelPoint('Tue', 10)]))
   ```

3. The readers use plain `double` arithmetic. Where a JS operator reads a `null` value as 0 (`<`, `-`, `+`,
   `isNaN`), the reader writes `value ?? 0.0`. `scaleNumberOf` and `scaleLabelOf` take a `double?`.
   `jsLessThan` is gone from the runtime.

## Consequences

- With `parsing: false`, a parsed value is a number or null. A string, a `Date` or an object of the app has no
  form: upstream compares two strings by code units, and the decimation joins them as text.
- An absent key and a `null` value give the same result. Upstream keeps `undefined` apart in a few places: an
  item without `x` on a logarithmic axis, the label `NaN` of a doughnut item without `r`, and the stack value
  of an item without a value. The bubble parse still reads an absent `r` of a parsed item as `undefined`,
  so the item takes the default radius.
- A label point is never a parsed item. Thus `parsing: false` does not take it, and a data-only update does
  not take a list of label points.
- A custom time `parser` function gets the time value of a `DataPoint.time`, not the `DateTime`.
- The reference cases of `parsing: false` with a string or an absent value skip as
  `diverges: adapt-typed-parsed-values`.

## Tests

`test/port/options/parsed_test.dart`, `test/port/typed/datasets_test.dart`,
`test/port/controllers/controller.polarArea_test.dart` (group `parsed data`),
`test/specs/core.datasetController_test.dart` (group `labels array synchronization`).
