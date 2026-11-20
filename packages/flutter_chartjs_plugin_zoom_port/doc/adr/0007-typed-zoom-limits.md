# Zoom ADR 0007: Typed zoom limits

- Status: accepted (2026-11-20): the zoom tests, the fixtures and the range-only suite pass.
- Date: 2026-11-20
- Supersedes: [Zoom ADR 0005](0005-typed-zoom-options.md) item 2, the sentence "`LimitOptions` is
  `Map<String, ScaleLimits>`" and "`limits` merges by scale id"
- Related: [Chart.js ADR 0191](../../../flutter_chartjs_port/doc/adr/0191-typed-axes.md)
- Difference: `adapt-native-zoom-options`, `adapt-axis-classes`.

## Context

`LimitOptions` was a `Map<String, ScaleLimits>`. Upstream reads `limits[scale.id] || limits[scale.axis]`: a
key is a scale id or a direction. A typed config has no scale ids since Chart.js ADR 0191, so the limits of
one axis need the axis object, and the limits of a direction need no string.

## Decision

1. `LimitOptions` is an immutable final class with three fields: `x` and `y` (`ScaleLimits?`, the upstream
   keys `x` and `y` as a direction) and `axes` (`Map<ChartAxis, ScaleLimits>?`, the upstream key of a scale
   id).

   ```dart
   ZoomPluginOptions(limits: const LimitOptions(
     x: ScaleLimits(min: ScaleLimit(-200), max: ScaleLimit(200), minRange: 50),
     y: ScaleLimits(minRange: 50),
   ));
   ZoomPluginOptions(limits: LimitOptions(axes: {right: ScaleLimits(max: ScaleLimit(500))}));
   ```

2. The limits of a scale are the `axes` entry whose axis has the id of the scale (`chart.scaleIdOf`, Chart.js
   ADR 0191), else the field of the direction of the scale, else `ScaleLimits()`. This is the upstream order.
3. `merge` merges `x` and `y` with `ScaleLimits.merge`, and the `axes` entries by their axis (`==`). `==` and
   `hashCode` compare the three fields; `axes` compares its entries in any order.
4. A raw config (`ChartView.raw`) has no axis objects: its limits are `x` and `y` only.
5. The zoom API keeps the scale ids of the run time: `zoomScale(id, range)`, `getZoomedScaleBounds()` and
   `getInitialScaleBounds()`. `chart.scaleIdOf(axis)` gives the id of an axis.

## Rejected

- A Map with the keys `XAxis()` and `YAxis()`: a direction is a fixed set of two, so it is two fields.
- A key by scale id for raw configs: a raw config with a custom id is not a use of the typed API.

## Consequences

- Each `limits: {'x': ...}` becomes `limits: LimitOptions(x: ...)`.
- The function tables `zoomFunctions`, `zoomRectFunctions` and `panFunctions` take the class.

## Tests

- `packages/flutter_chartjs_plugin_zoom_port/test/port/limit_options_test.dart`
- `packages/flutter_chartjs_plugin_zoom_port/test/specs/scale.types_test.dart`
