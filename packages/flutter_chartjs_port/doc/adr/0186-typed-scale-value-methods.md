# Chart.js ADR 0186: Typed scale value methods

- Status: accepted (2026-11-20): the typed value methods are on main, and the tests pass.
- Date: 2026-11-20
- Supersedes: [Chart.js ADR 0025](0025-scale-value-parameters.md) §1 to §3, for `parse`, `getLabelForValue`, `getPixelForValue` and `getDecimalForValue`
- Related: [Chart.js ADR 0183](0183-typed-scale-option-classes.md), [Chart.js ADR 0054](0054-typed-internal-model.md)

## Context

The value methods of a scale took and gave `Object?`, as the JS functions do: each scale tested the JS
type of its value, and a fast path took a `double` first. `index.d.ts` types the value as a number and
the label as a string. The maintainer asked for typed value methods (2026-11-20). A parsed item, a data
item of `parsing: false`, a stack value and the `{x: value}` position of a scale can still hold another
value of the user.

## Decision

### 1. The value methods take and give numbers

```dart
double? parse(Object? raw, [int? index]);
String getLabelForValue(double value);
double getPixelForValue(double value, [int? index]);
double getDecimalForValue(double value); // TimeScale, TimeSeriesScale
```

- `parse` keeps an `Object?` input: the data of the user. The base `Scale.parse` gives a number, Dart
  `null` for `null` and `undefined`, and the `ToNumber` of another value.
- The logarithmic parse of a 0 gives NaN, where upstream gives `undefined`. NaN is not finite and
  compares false, as `undefined`: the limits, the sorted test and the stacks do not change. The
  logarithmic `getPixelForValue` and `getLabelForValue` read NaN as 0.
- `getLabelForValue` gives the text of the label, the `'' + label` of the callers.
- `getLabels` stays `List<Object?>`: a label of some lines, a `DateTime` label of a time scale and the
  live List that the category parse writes stay.
- The other value methods of [Chart.js ADR 0025](0025-scale-value-parameters.md) keep their types.

### 2. A caller converts a value of the user

```dart
// Before
iScale.getPixelForValue(parsedValueOf(parsed, iAxis), index);
xScale.getLabelForValue(parsedValueOf(parsed, const XAxis()));
// After
iScale.getPixelForValue(scaleValueOf(iScale, parsedValueOf(parsed, iAxis)), index);
scaleLabelOf(xScale, parsedValueOf(parsed, const XAxis()));
```

`scaleValueOf` and `scaleLabelOf` of `lib/src/core/scale_value.dart` give a number as it is. For
another value they apply the rule of the upstream method: the category scale (`LabelIndexScale`) parses
a label, the time and logarithmic scales (`NullValueScale`) give their `nullValue` and `nanValue`, and
another scale applies `ToNumber`. A caller with a number calls the method directly.

### 3. The bodies have no type tests

Each body is the arithmetic of upstream on its `double`. The `value is double` fast paths go. A time
scale gives the JS `null` timestamp of a label that does not parse as its `nullValue`: NaN, and 0 for the
timeseries scale.

## Rejected

- `getLabels` as `List<String>`: it loses the labels of some lines, the dates and the List that the
  category parse writes.
- `-Infinity` for the logarithmic 0: it compares as a number, so the sorted test and the stack signs
  change.

## Consequences

- A test scale overrides `getPixelForValue(double value, [int? index])` with no `jsToNumber`.
- A NaN value on a logarithmic scale draws at the minimum, where upstream gives NaN. So does the sum of
  a stacked 0, where upstream gives NaN.
- The label of a value that is not a number on the base scale is the text of its `ToNumber`.

## Tests

`test/port/scales/`, `test/specs/scale.*_test.dart`, `test/port/core/core.datasetController_test.dart`,
`test/port/core/core.scale_test.dart`, `test/port/options/observation_test.dart`.
