# Line segment style — migration draft

The line option `segment`: style functions for each part of a line, from one point to the next.
Today the typed API has no parameter for it, so an app writes it as a Map in `extra`. Each function
reads the context by name and gives `Object?`, with `undefined` for "keep the line style".

## The classes

```dart
// lib/src/types/line_segment_style.dart: core classes.

// The style functions of the parts of a line. A function that gives null keeps the style of the
// line for that part. A field that is null keeps it for each part.
@immutable
final class const LineSegmentStyle({
  final ChartPaint? Function(ScriptableLineSegmentContext segment)? borderColor,
  final ChartPaint? Function(ScriptableLineSegmentContext segment)? backgroundColor,
  final double? Function(ScriptableLineSegmentContext segment)? borderWidth,
  final List<double>? Function(ScriptableLineSegmentContext segment)? borderDash,
  final double? Function(ScriptableLineSegmentContext segment)? borderDashOffset,
  final StrokeCap? Function(ScriptableLineSegmentContext segment)? borderCapStyle,
  final StrokeJoin? Function(ScriptableLineSegmentContext segment)? borderJoinStyle,
}) {
  // The scopes of a chart combine field by field: a field of other wins.
  LineSegmentStyle merge(LineSegmentStyle? other) => ...;
}

// lib/src/helpers/helpers.options.dart: the context with typed fields, not Object? by name.
final class ScriptableLineSegmentContext extends ContextObject {
  PointElement get p0;      // the point at the start of the part
  PointElement get p1;      // the point at the end of the part
  int get p0DataIndex;
  int get p1DataIndex;
  int get datasetIndex;
}
```

## Before and after

```dart
// Before
LineDataset(data: values, extra: {
  'segment': {'borderColor': segmentColor, 'borderDash': segmentDash},
})
Object? segmentColor(JsObjectFace context) {
  final from = trendAt(context, 'p0DataIndex');
  final to = trendAt(context, 'p1DataIndex');
  ...
  return from > to ? const ChartPaint.solid(red) : undefined;
}

// After
LineDataset(
  data: values,
  segment: LineSegmentStyle(
    // Red where the line goes down.
    borderColor: (s) => values[s.p1DataIndex] < values[s.p0DataIndex] ? red : null,
    // Dashed across a gap.
    borderDash: (s) => s.p0.skip == true || s.p1.skip == true ? [6, 6] : null,
  ),
)

// A raw config holds the same object.
'segment': LineSegmentStyle(borderColor: (s) => ...),
```

## The core

- `LineSegmentStyle` is a typed atom of the schema: the shape of `segment` is `lineSegmentStyle`.
  The scope kind `SegmentOptions` goes.
- The resolver merges the `segment` values of the scopes with `merge`, as it merges fonts.
- `_doSplitByStyles` of `helpers.segment.dart` calls each function with the typed context of each
  part, in the upstream order. A null result takes the value of the line options, as `undefined`
  does upstream. No `setContext` resolver and no `jsCall`.
- `styleChanged` compares two styles with `==` of `SegmentStyle`. The emulation of
  `JSON.stringify` goes. By a reading of the code, that emulation possibly writes `{}` for a
  `StrokeCap` or a `StrokeJoin`, so two styles that differ only there possibly compare as equal
  today. No test confirms it.
- The line and scatter controllers pass the `LineSegmentStyle` to the line with a typed setter.
- `LineDataset`, `ScatterDataset`, `RadarDataset` and `LineElementStyle` get `segment`.
- A constant value for a part goes: a style that is the same for each part is the line option
  itself. A Map `segment` in a raw config stops a debug build.
- Cost: about 32 test files, the 2 docs app uses, the line and filler tests of the segments, the
  O1 texts of the segment contexts.
