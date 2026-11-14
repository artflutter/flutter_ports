# Chart.js ADR 0145: Native option types with no earlier ADR

- Status: accepted (2026-11-14): it records changes whose code is on main and passes the tests.
- Date: 2026-11-14
- Supersedes: [Chart.js ADR 0127](0127-native-legend-labels.md) (proposed) as a whole, and parts of these ADRs:
  - [Chart.js ADR 0015](0015-text.md) §3 and [Chart.js ADR 0017](0017-element-properties.md) §8: the canvas
    keywords.
  - [Chart.js ADR 0019](0019-animation.md) §3 and [Chart.js ADR 0054](0054-typed-internal-model.md) §10 item 3:
    the easing names.
  - [Chart.js ADR 0024](0024-dates.md) §2 and §4: the `String` time unit and its aliases.
  - [Chart.js ADR 0028](0028-controller-interfaces.md) §1, §2 and §6: the meta members, the `Object?` label and
    the Map legend item.
  - [Chart.js ADR 0038](0038-plugin-modules-class-values-and-interfaces.md) §4 and §6: the `positioners` Map and
    the untyped members.
  - [Chart.js ADR 0039](0039-tooltip-model-and-animation.md) §2, §3, §4, §5, §8 and §12: the `String` aligns,
    the Map items, the positioner table and `this`.
  - [Chart.js ADR 0052](0052-typed-public-api.md) §1, §4, §6, §7 and §8: the name types and the item views.
  - [Chart.js ADR 0054](0054-typed-internal-model.md) §8, §12 and §19: `AxisKey`, the record items and the name
    dictionaries.
  - [Chart.js ADR 0125](0125-native-tooltip-callbacks.md), section "Full types": the view `ChartTooltipItem`.
- Related: [Chart.js ADR 0130](0130-native-callback-options.md)

## Context

Chart.js keeps many options and API values in JS forms: a keyword, a Map, or a function with `this`. Since
2026-11-01, the port moved them to native Dart types. Some moves have their own ADR, for example Chart.js ADR
0140. The moves below exist only as rows of `differences.md`, design drafts and the package `AGENTS.md`.

## Decision

1. Each type below holds in raw and typed configs, and the typed API takes it. An open class takes a new form as
   a subclass, with no registration. No table maps a name to a value. An old keyword, text or Map is a foreign
   value: a debug build stops at its read. A release build takes the upstream result of an unknown value. Some
   items name this result. The `differences.md` row of each item has the details.
2. `mode` of `interaction`, `hover` and the tooltip: an `InteractionMode`, for example `NearestInteractionMode()`.
   A name finds no item (`adapt-interaction-mode-objects`).
3. `axis` of the same scopes: the enum `InteractionAxis`. A keyword takes the fallback axis
   (`adapt-interaction-axis-enum`).
4. The tooltip `position`: a `TooltipPositioner`, for example `NearestTooltipPositioner()`. `positionOf` gives a
   `TooltipPosition` or null (`adapt-tooltip-positioner-objects`).
5. The decimation `algorithm`: a `DecimationAlgorithm`, for example `LttbDecimationAlgorithm()`. A name throws the
   upstream `StateError` (`adapt-decimation-algorithm-objects`).
6. `easing`: a Flutter `Curve`, for example `Curves.easeOutQuart`. A name takes `Curves.linear`
   (`adapt-flutter-curves`).
7. `time.unit`, `time.minUnit`, `time.round` and the units of a date adapter: the enum `TimeUnit`. The ISO week is
   `startOfIsoWeek(time, weekday)`. The adapter has no unit aliases (`adapt-time-unit-enum`).
8. A tick: the class `Tick` (`double value`, `List<String>? label`, `bool major`). `ticks.callback` holds a
   `List<String>? Function(Scale scale, double value, int index, List<Tick> ticks)`. Null removes the tick
   (`adapt-native-tick`).
9. The dataset meta: `ChartMeta<C extends DatasetController>`, with typed fields and no access by name. `stacked`
   is the enum `StackMode` (`adapt-native-chart-meta`).
10. The dataset `clip`: a `ChartClip`, for example `ChartClip.all(5)` or `ChartClip.none`. A number, a bool or a
    Map stops a debug build. `getMaxOverflow` gives a `double?` (`adapt-chart-clip-option`, `adapt-max-overflow`).
11. A legend item: the mutable class `LegendItem`, with `List<String> text`, `ChartPaint` paints, Flutter enums,
    `TRBLCorners?` corners, `int?` indexes, `copyWith` and `merge`. `generateLabels` gives a `List<LegendItem>`. A
    Map is no item (`adapt-native-legend-item`).
12. A legend hit box: the mutable class `LegendHitBox`, with `double` geometry, an `int?` row or column, `contains`
    and `center` (`adapt-native-legend-hit-box`).
13. A tooltip item: the immutable class `TooltipItem`, with `int` indexes and `List<String> label`, and the body
    item `TooltipBodyItem`. `getLabelAndValue` gives `({List<String> label, String value})`. `filter`,
    `itemSort` and `external` hold typed functions with no `this` (`adapt-native-tooltip-item`).
14. An active element: the class `ActiveElement` (`int datasetIndex`, `int index`, `Element? element`).
    `setActiveElements` takes a `List<ActiveElement>`. A Map is no item (`adapt-native-active-element`).
15. The `align` of the legend, the titles and an axis title, and the legend title `position`: the enum `ChartAlign`
    (`adapt-chart-align-enum`).
16. The tooltip `xAlign` and `yAlign`: the enums `TooltipXAlign` and `TooltipYAlign` (`adapt-tooltip-align-enums`).
17. An axis: `XAxis`, `YAxis` or `RAxis`. `indexAxis` takes a `CartesianAxis`, for example `const YAxis()`. The
    scale `axis` takes a `ScaleAxis` (`adapt-axis-objects`).
18. `cutout` and `radius`: a `RadiusLength`, for example `PercentRadius(50)`. The scale `grace`: a `GraceLength`,
    for example `ValueGrace(1)`. The text `'50%'` stops a debug build (`adapt-length-objects`).
19. `pointStyle`: a `PointStyle`, for example `CirclePointStyle()`, or `false` (`adapt-point-style-objects`).
20. `cubicInterpolationMode`: a `CubicInterpolationMode`, for example `MonotoneCubicInterpolationMode()`. A keyword
    takes the default mode (`adapt-cubic-interpolation-mode-objects`).
21. The line `stepped`: a `bool` or the enum `SteppedLine` (`adapt-stepped-line-enum`).
22. The bar `borderSkipped`: a `bool` or the enum `BorderSkippedEdge` (`adapt-border-skipped-enum`).
23. The scale `bounds`, `ticks.source`, `ticks.align` and `ticks.crossAlign`: the enums `ScaleBounds`,
    `TickSource`, `TickAlign` and `TickCrossAlign` (`adapt-scale-option-enums`).
24. The arc `borderAlign` and `spacingMode`: the enums `ArcBorderAlign` and `ArcSpacingMode`
    (`adapt-arc-option-enums`).
25. `borderCapStyle`, `borderJoinStyle` and the canvas `lineCap` and `lineJoin`: the Flutter `StrokeCap` and
    `StrokeJoin`. A keyword has no effect, as in the DOM setter (`adapt-flutter-stroke-enums`).
26. Each text align, for example the canvas `textAlign` and the legend `labels.textAlign`: the Flutter `TextAlign`.
    `TextAlign.justify` draws as `start` (`adapt-flutter-text-align`).
27. The canvas `textBaseline`: the enum `CanvasTextBaseline`. A keyword does not compile
    (`adapt-canvas-text-baseline-enum`).
28. The filler `drawTime`: the enum `FillerDrawTime`. A keyword fills in no hook (`adapt-filler-draw-time-enum`).
29. The position of a box: a `LayoutPosition`, the enum `ChartPosition` or `ScaleValuePosition('x', 0)` for the
    object `{x: 0}` (`adapt-chart-position-enum`).
30. `ChartConfig.animations` holds `PropertyAnimation` items, for example `RadiusAnimation(duration: d)`, and
    `ChartConfig.transitions` holds `ChartTransition` items. Two items of one class stop a debug build
    (`adapt-property-animations`).

## Rejected

- A name table, or an extension type over the keyword (Chart.js ADR 0052 §7): the core still compares text.
- One ADR for each change: each ADR repeats item 1.

## Consequences

- An enum closes its set: the core code handles each value.
- The reference generators write the native values. A compare with upstream JSON text prints the name or a marker.
- The data fixtures with such a keyword have hand ports (Chart.js ADR 0115).

## Tests

- `test/port/core/core.interaction_test.dart`
- `test/port/plugins/plugin.tooltip_test.dart`
- `test/port/options/curve_option_test.dart`
- `test/port/plugins/legend_item_test.dart`
- `test/port/typed/animations_test.dart`
- `test/port/typed/lowering_test.dart`
