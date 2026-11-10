// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/types.ts (MIT, chartjs-plugin-zoom contributors).

/// The geometry types of the zoom API: [Point], [ZoomAmount], [PanAmount]
/// and [ScaleRange].
///
/// A TypeScript union of a number and an object has no Dart form. The amounts
/// of `zoom` and `pan` are classes with the defaults of `src/core.ts`
/// (differences.md row `adapt-amount-classes`).
library;

/// types.ts:10 `Point`: a position in canvas pixels.
///
/// Chart.js 4.5 widened its own `Point` to `{ x: number | null; y: number |
/// null }` so that it can also describe a gap in a dataset. Everything this
/// plugin measures or moves -- a zoom centre, a drag corner, a pan delta --
/// is a real coordinate, so the geometry here keeps its own non-nullable type
/// rather than null checking values that are never null.
///
/// The public library does not export the name: the host exports another
/// `Point`. A record type is structural, so a caller passes `(x: 10, y: 20)`
/// without the name.
typedef Point = ({double x, double y});

/// types.ts:12 `ZoomAmount`, the union of a number and of
/// `Partial<Point> & { focalPoint?: Point }`: the zoom factor of each axis,
/// and the point that stays in place.
///
/// The defaults are those of `src/core.ts:70`: an axis without a factor keeps
/// its range (1), and a `null` [focalPoint] stands for the center of the
/// chart area. The number form of upstream is [ZoomAmount.all]:
/// `chart.zoom(1.5)` is `chart.zoom(.all(1.5))`.
// DIVERGES(zoom): adapt-amount-classes, a class for number | object.
final class ZoomAmount {
  /// The object form `{x, y, focalPoint}`.
  const ZoomAmount({this.x = 1, this.y = 1, this.focalPoint});

  /// The number form: the same [amount] for both axes.
  const ZoomAmount.all(double amount, {this.focalPoint})
    : x = amount,
      y = amount;

  /// The zoom factor of the x axis. 1 leaves the axis unchanged.
  final double x;

  /// The zoom factor of the y axis. 1 leaves the axis unchanged.
  final double y;

  /// The point in canvas pixels that keeps its value, or `null` for the
  /// center of the chart area.
  final Point? focalPoint;
}

/// types.ts:13 `PanAmount = number | Partial<Point>`: the pan distance of
/// each axis in pixels.
///
/// The defaults are those of `src/core.ts:211`: an axis without a distance
/// does not pan (0). The number form of upstream is [PanAmount.all].
final class PanAmount {
  /// The object form `{x, y}`.
  const PanAmount({this.x = 0, this.y = 0});

  /// The number form: the same [delta] for both axes.
  const PanAmount.all(double delta) : x = delta, y = delta;

  /// The pan distance of the x axis in pixels. 0 does not pan the axis.
  final double x;

  /// The pan distance of the y axis in pixels. 0 does not pan the axis.
  final double y;
}

/// types.ts:14 `ScaleRange`: the `min` and `max` of a scale.
///
/// `src/state.ts:5` declares the same type; `state.dart` exports this one.
typedef ScaleRange = ({double min, double max});

// types.ts:15 `DistributiveArray<T>` has no Dart form: it is a TypeScript
// type helper of the generic `Chart` of `src/index.ts`.
