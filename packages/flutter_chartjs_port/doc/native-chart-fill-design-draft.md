# Fill target — migration draft

The line option `fill`. The row is [`adapt-fill-target-objects`](differences.md#adapt-fill-target-objects).

`FillTarget` is the type of the `fill` option of a line. A value says where the colored area under
the line ends.

- Today it is a sealed type with two forms only: `FillBoundary` (`origin`, `start`, `end`, `stack`,
  `shape`) and `RelativeFill`. The other forms of `fill` (a number, a bool, a Map) are not
  `FillTarget` values.
- In this draft, every value of `fill` is a `FillTarget`. The app writes it, and the filler gets the
  same object.
- The name does not fit all values: `.none` and `.shape` have no target, and a split adds colors. A
  name such as `LineFill` fits better: `LineDataset(fill: LineFill.toOrigin)`.

## The class

```dart
// lib/src/plugins/fill_target.dart
sealed class const FillTarget() {
  static const FillTarget none = NoFill();
  static const FillTarget toOrigin = OriginFill();
  static const FillTarget toStart = StartFill();
  static const FillTarget toEnd = EndFill();
  static const FillTarget toStacked = StackFill();
  static const FillTarget toPrevious = RelativeFill(-1);
  static const FillTarget toNext = RelativeFill(1);
  static const FillTarget shape = ShapeFill();
  const factory FillTarget.toValue(double value) = ValueFill;
  const factory FillTarget.toDataset(int index) = DatasetFill;
  const factory FillTarget.toRelative(int offset) = RelativeFill;

  // This target with its own colors above and below it.
  FillTarget split({ChartPaint? above, ChartPaint? below}) => SplitFill._(this, above, below);
}

final class const NoFill() extends FillTarget;
final class const OriginFill() extends FillTarget;
final class const StartFill() extends FillTarget;
final class const EndFill() extends FillTarget;
final class const StackFill() extends FillTarget;
final class const ShapeFill() extends FillTarget;
final class const ValueFill(final double value) extends FillTarget;
final class const DatasetFill(final int index) extends FillTarget;
final class const RelativeFill(final int offset) extends FillTarget;

final class SplitFill._(final FillTarget target, final ChartPaint? above, final ChartPaint? below)
    extends FillTarget {
  @override
  FillTarget split({ChartPaint? above, ChartPaint? below}) => SplitFill._(target, above, below);
}
```

## Before and after

```dart
// Before
LineDataset(fill: .origin)
LineDataset(fill: .relative(-1))
LineDataset(fill: const .value(50))
LineDataset(extra: {'fill': {'target': 'origin', 'above': green, 'below': red}})

// After
LineDataset(fill: .toOrigin)
LineDataset(fill: .toPrevious)
LineDataset(fill: .toValue(50))
LineDataset(fill: .toOrigin.split(above: green, below: red))
```

## Notes

- `fill` is the only fill parameter. The app writes `FillTarget` members only. The filler matches
  the subclasses, and the compiler proves that each switch covers each form.
- A raw config holds the same objects. `true`, `false`, a number, a Map and a text stop a debug
  build.
- Only `split()` makes a `SplitFill`, and `SplitFill.split()` keeps the same target. Thus a split
  never wraps a split. A split fill is not `const`.
- The filler gets a `FillTarget`, not `Object`. Its reads by name, `jsParseFloat`, `isFinite`,
  `as num` and the text `'+'` go. An absent fill still takes the truthiness of `backgroundColor`.
- `ChartFill`, `FillBoundary`, `FillTargetOptions` and the scope kind `FillTarget` go.
- Cost: about 930 test lines in 131 files (`false`, numbers, `true`), the reference generators,
  and hand ports of the data fixtures with a bool, a number or an object `fill` (162 values).
