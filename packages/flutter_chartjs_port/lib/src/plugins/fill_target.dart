// Original code, not ported from Chart.js: the fill targets of the filler.

/// The values of the option `fill` (row `adapt-fill-target-objects`,
/// Chart.js ADR 0140).
///
/// Upstream `fill` (`FillTarget` of index.d.ts:2300 and `ComplexFillTarget`
/// of index.d.ts:2302) is a number (the index of a dataset), a boolean, an
/// object `{value}`, a keyword (`'origin'`, `'start'`, `'end'`, `'stack'`,
/// `'shape'`), a relative index as text (`'+1'`, `'-2'`) or an object
/// `{target, above, below}`. In the port, each value is a [FillTarget], also
/// in a raw config. The filler gets the same object.
///
/// ```dart
/// LineDataset(data: values, fill: .toOrigin);
/// LineDataset(data: values, fill: .toPrevious);
/// LineDataset(data: values, fill: .toValue(50));
/// LineDataset(
///   data: values,
///   fill: FillTarget.toOrigin.split(
///     above: const ChartPaint.solid(Color(0xFF4CAF50)),
///     below: const ChartPaint.solid(Color(0xFFF44336)),
///   ),
/// );
/// ```
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show Undefined;
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:meta/meta.dart' show immutable;

/// Where the colored area under a line ends: the value of the option `fill`.
///
/// The members give each form. Only [split] makes a fill with its own colors
/// above and below the target.
@immutable
sealed class const FillTarget() {
  /// The fill to the line at [value] of the value axis: `{value: value}`.
  const factory toValue(double value) = ValueFill;

  /// The fill to the dataset at [index]: the number `index`.
  const factory toDataset(int index) = DatasetFill;

  /// The fill to the dataset at [offset] from this dataset: `'+1'` for 1
  /// and `'-1'` for -1.
  const factory toRelative(int offset) = RelativeFill;

  /// No fill: the `false` of Chart.js.
  static const FillTarget none = NoFill();

  /// The fill to the origin of the value axis: `'origin'` and `true`.
  static const FillTarget toOrigin = OriginFill();

  /// The fill to the start of the value axis: `'start'`.
  static const FillTarget toStart = StartFill();

  /// The fill to the end of the value axis: `'end'`.
  static const FillTarget toEnd = EndFill();

  /// The fill to the dataset below in the stack: `'stack'`.
  static const FillTarget toStacked = StackFill();

  /// The fill to the previous dataset: `'-1'`.
  static const FillTarget toPrevious = RelativeFill(-1);

  /// The fill to the next dataset: `'+1'`.
  static const FillTarget toNext = RelativeFill(1);

  /// The fill of the closed shape of the line, for a radar dataset:
  /// `'shape'`.
  static const FillTarget shape = ShapeFill();

  /// This target with its own colors above and below it: `{target, above,
  /// below}`. A Dart `null` color takes the `backgroundColor` of the line.
  FillTarget split({ChartPaint? above, ChartPaint? below}) =>
      SplitFill._(this, above, below);

  /// The target of [value], the value of the option `fill`, or Dart `null`
  /// for `undefined` and `null`. Another value (a boolean, a number, a Map,
  /// a text of Chart.js) is no target: a debug build stops on it, and a
  /// release build takes no fill.
  static FillTarget? of(Object? value) {
    assert(
      value == null || value is FillTarget || value is Undefined,
      'The option fill takes a FillTarget, not $value.',
    );
    return value is FillTarget ? value : null;
  }
}

/// No fill: [FillTarget.none].
final class const NoFill() extends FillTarget {
  /// No fill.
  this;

  @override
  bool operator ==(Object other) => other is NoFill;

  @override
  int get hashCode => (NoFill).hashCode;

  @override
  String toString() => 'FillTarget.none';
}

/// The fill to the origin of the value axis: [FillTarget.toOrigin].
final class const OriginFill() extends FillTarget {
  /// The fill to the origin.
  this;

  @override
  bool operator ==(Object other) => other is OriginFill;

  @override
  int get hashCode => (OriginFill).hashCode;

  @override
  String toString() => 'FillTarget.toOrigin';
}

/// The fill to the start of the value axis: [FillTarget.toStart].
final class const StartFill() extends FillTarget {
  /// The fill to the start.
  this;

  @override
  bool operator ==(Object other) => other is StartFill;

  @override
  int get hashCode => (StartFill).hashCode;

  @override
  String toString() => 'FillTarget.toStart';
}

/// The fill to the end of the value axis: [FillTarget.toEnd].
final class const EndFill() extends FillTarget {
  /// The fill to the end.
  this;

  @override
  bool operator ==(Object other) => other is EndFill;

  @override
  int get hashCode => (EndFill).hashCode;

  @override
  String toString() => 'FillTarget.toEnd';
}

/// The fill to the dataset below in the stack: [FillTarget.toStacked].
final class const StackFill() extends FillTarget {
  /// The fill to the stack.
  this;

  @override
  bool operator ==(Object other) => other is StackFill;

  @override
  int get hashCode => (StackFill).hashCode;

  @override
  String toString() => 'FillTarget.toStacked';
}

/// The fill of the closed shape of the line: [FillTarget.shape].
final class const ShapeFill() extends FillTarget {
  /// The fill of the shape.
  this;

  @override
  bool operator ==(Object other) => other is ShapeFill;

  @override
  int get hashCode => (ShapeFill).hashCode;

  @override
  String toString() => 'FillTarget.shape';
}

/// The fill to the line at [value] of the value axis:
/// [FillTarget.toValue].
final class const ValueFill(
  /// The value on the value axis. NaN gives no fill.
  final double value,
) extends FillTarget {
  /// The fill to the line at [value].
  this;

  @override
  bool operator ==(Object other) => other is ValueFill && other.value == value;

  @override
  int get hashCode => Object.hash(ValueFill, value);

  @override
  String toString() => 'FillTarget.toValue($value)';
}

/// The fill to the dataset at [index]: [FillTarget.toDataset].
final class const DatasetFill(
  /// The index of the target dataset.
  final int index,
) extends FillTarget {
  /// The fill to the dataset at [index].
  this;

  @override
  bool operator ==(Object other) =>
      other is DatasetFill && other.index == index;

  @override
  int get hashCode => Object.hash(DatasetFill, index);

  @override
  String toString() => 'FillTarget.toDataset($index)';
}

/// The fill to the dataset at [offset] from this dataset:
/// [FillTarget.toRelative], [FillTarget.toPrevious] and
/// [FillTarget.toNext].
final class const RelativeFill(
  /// The offset of the target dataset from this dataset.
  final int offset,
) extends FillTarget {
  /// The fill to the dataset at [offset] from this one.
  this;

  @override
  bool operator ==(Object other) =>
      other is RelativeFill && other.offset == offset;

  @override
  int get hashCode => Object.hash(RelativeFill, offset);

  @override
  String toString() => 'FillTarget.toRelative($offset)';
}

/// A [target] with its own colors [above] and below it: [FillTarget.split].
///
/// Only [FillTarget.split] makes it, and its own [split] keeps the same
/// [target]: a split never holds a split.
final class const SplitFill._(
  /// The target of the fill. It is never a [SplitFill].
  final FillTarget target,

  /// The color of the fill above the target, or Dart `null` for the
  /// `backgroundColor` of the line.
  final ChartPaint? above,

  /// The color of the fill below the target, or Dart `null` for the
  /// `backgroundColor` of the line.
  final ChartPaint? below,
) extends FillTarget {
  @override
  FillTarget split({ChartPaint? above, ChartPaint? below}) =>
      SplitFill._(target, above, below);

  @override
  bool operator ==(Object other) =>
      other is SplitFill &&
      other.target == target &&
      other.above == above &&
      other.below == below;

  @override
  int get hashCode => Object.hash(SplitFill, target, above, below);

  @override
  String toString() => '$target.split(above: $above, below: $below)';
}

/// The JS truthiness of the fill [fill]: `false` and the number `0` are
/// falsy, and each other value of `fill` (a keyword, a relative index as
/// text, an object) is truthy. The warning of core.datasetController.js:287
/// and the `source.fill` test of the filler (index.js:56) read it.
bool fillTargetTruthy(FillTarget fill) =>
    fill is! NoFill && fill != const DatasetFill(0);
