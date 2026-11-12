// Original code, not ported from Chart.js: the axis of a scale as a class.

/// The axis of a scale and the index axis of a chart (row
/// `adapt-axis-objects`).
///
/// Upstream holds the axis as a letter: `'x'`, `'y'` or `'r'`
/// (`indexAxis`, index.d.ts:71, and the scale option `axis`). In the port,
/// the axis is a class with no members. A cartesian slot (the option
/// `indexAxis` of a chart or of a cartesian dataset, and the `axis` of a
/// cartesian scale) has the type [CartesianAxis]: it takes [XAxis] or
/// [YAxis], and the compiler refuses [RAxis]. A radial slot (the index axis
/// of a radial controller, and the `axis` of the radial scale) has the type
/// [RAxis]. The core keeps an axis of either kind as a [ScaleAxis] and reads
/// it with pattern matching:
///
/// ```dart
/// final value = switch (scale.axis) {
///   XAxis() => parsed.x,
///   YAxis() => parsed.y,
///   RAxis() => parsed.r,
///   _ => undefined,
/// };
/// ```
///
/// An app writes the axis with a `const` constructor:
///
/// ```dart
/// ChartConfig(
///   type: ChartKind.bar,
///   indexAxis: const YAxis(), // a horizontal bar chart
///   datasets: [BarDataset(data: [1, 2, 3])],
/// );
/// ```
///
/// This library is a pure layer.
library;

/// The axis of a scale: [XAxis], [YAxis] or [RAxis]. The core keeps an axis
/// of either kind in this type; no option has it.
abstract class ScaleAxis {}

/// The axis of a cartesian chart or scale: [XAxis] or [YAxis] only.
abstract class CartesianAxis implements ScaleAxis {}

/// The horizontal axis: `'x'` upstream.
final class XAxis implements CartesianAxis {
  /// The horizontal axis.
  const XAxis();
}

/// The vertical axis: `'y'` upstream.
final class YAxis implements CartesianAxis {
  /// The vertical axis.
  const YAxis();
}

/// The radial axis: `'r'` upstream. Only the radial controllers and the
/// radial scale take it.
final class RAxis implements ScaleAxis {
  /// The radial axis.
  const RAxis();
}
