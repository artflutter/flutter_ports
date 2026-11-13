# Chart.js ADR 0129: An index is an int

- Status: accepted (2026-11-13): the tests of each package, the fixtures and the port checks pass.
- Date: 2026-11-13
- Related: Chart.js ADR 0045 (the JS numeric rules), Chart.js ADR 0052 (the typed public API), Chart.js ADR 0054
  (the typed internal model).
- Difference: `adapt-int-indexes`, `adapt-native-active-element`.

## Context

JavaScript has one number type. The port held each index as a `double` (Chart.js ADR 0045, section 7), and six
methods of `Chart` took a `num` at the public boundary (Chart.js ADR 0052, section 10). A Dart List takes an `int`
index, so the library and the apps converted with `toDouble()`, `toInt()` and `* 1.0` at many calls. The typed view
`ChartHit` existed only to give `int` indexes to an app.

Chart.js writes whole numbers at each place where it makes an index: a loop counter, a List length, the result of
a binary search, and the two fields of an interaction item.

## Decision

1. A dataset index, a data index, and the start and the count of a range of data elements are `int` values in the
   whole library: parameters, fields, records and loop variables.

   ```dart
   final meta = chart.getDatasetMeta(active.datasetIndex);
   final parsed = meta.controller!.getParsed(active.index);
   chart.hide(0);
   chart.toggleDataVisibility(2);
   ```

2. An absent index is Dart `null`, where upstream gives `undefined`: `getStyle`, `getContext`, `updateElement`,
   `setHoverStyle` and `removeHoverStyle`.
3. The context keys `index`, `dataIndex` and `datasetIndex`, `ChartMeta.index`, the `index` of the dataset hook
   arguments and the index of `each` hold an `int`. A scriptable option that reads a context index gets an `int`.

   ```dart
   backgroundColor: ChartValue.resolver(
     (context) => palette[context.dataIndex! % palette.length],
   ),
   ```

4. The four angle methods of the radial linear scale take a `num` index: `getIndexAngle`, `getPointPosition`,
   `getPointPositionForValue` and `getBasePosition`. They compute an angle and read no List.
5. The two decimation algorithms and the segment code of a line keep their inner numbers. They compute bucket
   limits and loop positions with fractions. Their public methods take `int` ranges.
6. Ported code writes no conversion between `int` and `double` for an index.

## Superseded parts

- Chart.js ADR 0045, section 7: the rule that an index is a `double`. The rule stays for each other JS number.
- Chart.js ADR 0052, section 10: the `num` index parameters of `Chart`.

## Consequences

- A value that is not a whole number is no longer an index. Chart.js accepts a fraction, NaN or a string and finds
  no item. In the port it is a compile error.
- `'$index'` of a context index prints `2`, not `2.0`.
- A scale subclass of an app overrides `getPixelForValue(Object? value, [int? index])`, and a controller subclass
  overrides its methods with `int` indexes.
