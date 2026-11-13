# ChartShadow option — migration draft

The dataset option `shadow` of Chart.js ADR 0107. Chart.js has no such option: the port adds it.

## The class

```dart
// lib/src/types/chart_shadow.dart: a core file, the value of the option.
@immutable
class const ChartShadow({
  // The canvas shadowColor. A transparent color draws no shadow.
  required final Color color,
  // The canvas shadowBlur: the Gaussian sigma is blur / 2.
  final double blur = 0,
  // The canvas shadowOffsetX and shadowOffsetY, in logical pixels.
  final Offset offset = Offset.zero,
}) {
  this : assert(blur >= 0, 'The blur is not negative.');
  // copyWith, == and hashCode as today.
}
```

## Before and after

```dart
// Before: the typed API splits it into four keys by name.
'shadowColor': const Color(0x40000000), 'shadowBlur': 8.0,

// After: typed API and raw config hold the same object.
LineDataset(data: points, shadow: const ChartShadow(color: Color(0x40000000), blur: 8));
'shadow': const ChartShadow(color: Color(0x40000000), blur: 8),
```

## The reader

```dart
// _beginShadow of chart_view_plugin.dart.
final shadow = readOption(args.meta?.controller?.getDataset(), OptionKey.shadow);
if (shadow is! ChartShadow) return false;
ctx
  ..save()
  ..shadowColor = shadow.color
  ..shadowBlur = shadow.blur
  ..shadowOffsetX = shadow.offset.dx
  ..shadowOffsetY = shadow.offset.dy;
```

- The class moves from `lib/src/typed/datasets.dart` to a core file. It loses `Diagnosticable`,
  because a core file imports no Flutter framework library. It keeps `Color` and `Offset` of
  `dart:ui`.
- The class is open, as `ChartClip`, `ActiveElement` and `TooltipItem` are. Today it is `final`
  only by the rule of the typed config classes (Chart.js ADR 0052), which no longer applies in a
  core file.
- The schema gets `shadow: chartShadow`, a typed atom, in the 8 dataset kinds that have
  `clip: chartClip`. Another value stops a debug build.
- The lowering writes `shadow` with the typed setter. The split into four keys goes.
- `_indexedScalar` of `helpers.config.dart` accepts a `ChartShadow`, as it accepts a `ChartClip`.
  Thus a dataset with a shadow keeps the data-only update.
- The `shadowColor` case of `validateChartColors` goes: the class types the color.
- The four `jsGet` reads go, and with them `tool/typed_reads/widgets/chart_view_plugin.dart.txt`.
- The four canvas setters and the draw code of `canvas_ui.dart` stay: they are the Canvas 2D
  members of Chart.js ADR 0106.
- The app library keeps the export. `lib/chartjs.dart` adds it for raw configs, as for
  `ChartClip`.
- Tests: `chart_view_shadow_test.dart`, the lowering twin of `shadow`, the schema test.
