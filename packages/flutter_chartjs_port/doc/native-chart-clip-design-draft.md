# ChartClip option — migration draft

The dataset option `clip` (`index.d.ts:75`, `clip: number | ChartArea | false`). The rows are
[`adapt-chart-clip-option`](differences.md#adapt-chart-clip-option) and
[`adapt-max-overflow`](differences.md#adapt-max-overflow).

## The class

```dart
// lib/src/types/chart_meta.dart: the class of meta.clip, also the option value.
@immutable
class const ChartClip({
  // The pixels outside the area of the dataset. Null: no clip on that side.
  final double? left,
  final double? top,
  final double? right,
  final double? bottom,
  final bool disabled = false,
}) {
  // `clip: 5`: each side.
  const new all(double pixels)
    : this(left: pixels, top: pixels, right: pixels, bottom: pixels);

  // `clip: false`: no clip area at all.
  static const ChartClip none = ChartClip(disabled: true);
}
```

## Before and after

```dart
// Before: a number, false or a Map, through extra.
LineDataset(data: points, extra: {'clip': 5});
'clip': <String, Object?>{'top': 8, 'left': false, 'right': -20, 'bottom': -20},

// After: typed API and raw config.
LineDataset(data: points, clip: const ChartClip.all(5));
'clip': const ChartClip(top: 8, right: -20, bottom: -20),
'clip': ChartClip.none,
```

## The core

```dart
// DatasetController: null is the JS false, that is, no overflow.
double? getMaxOverflow() => null;

// update_: the default runs at each update, as upstream.
final clip = options.readKey(OptionKey.clip);
final orElse = _defaultClip(meta.xScale, meta.yScale, getMaxOverflow());
meta.clip = clip is ChartClip ? clip : orElse;
```

- `update_` takes the `ChartClip` of the option, or the default. An old form stops a debug build.
- `_defaultClip` gives `ChartClip.none` for no overflow, else the overflow or 0 on each side.
- The schema has `clip: chartClip`, a typed atom. The scope kind `ChartArea` is gone.
- A side that the app omits is null and has no clip. Upstream gives `undefined` there, and the
  clip area is NaN.
- The native option plans count a `ChartClip` as a scalar.
- The layout padding reads `getMaxOverflow() ?? 0`.
- The scale option `clip` (a bool) does not change.
