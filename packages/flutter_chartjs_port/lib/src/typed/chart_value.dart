// Original code, not ported from Chart.js: explicit typed option values.

/// Public constant, indexed and callback values for Dataset.backgroundColor.
/// Other typed options retain their existing API in this prototype.
library;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_chartjs_port/src/options/opt.dart';
import 'package:flutter_chartjs_port/src/typed/callbacks.dart'
    show ChartContext, ChartScript;
import 'package:meta/meta.dart' show immutable, internal;

/// One of the supported forms of a typed chart option.
///
/// Dataset.backgroundColor accepts `ChartValue<Color>`. Omitting that parameter
/// inherits the default. Use [ChartValue.constant] for a shared value,
/// [ChartValue.indexed] for a repeating list, or [ChartValue.resolver] for a
/// callback. The variants retain their kind when lowered into internal cells.
///
/// Values compare by variant and contents. Treat indexed lists as immutable
/// configuration inputs; lowering makes a mutable copy for the chart. Callback
/// equality uses Dart function equality, so stable method tear-offs avoid
/// unnecessary configuration updates.
@immutable
sealed class ChartValue<T> {
  const ChartValue._();

  /// One value for the dataset.
  const factory ChartValue.constant(T value) = ChartConstant<T>;

  /// Values selected by item index, repeating when the list is shorter.
  ///
  /// Empty lists retain the existing raw option behavior. The input list is
  /// copied into a mutable engine list each time the dataset is lowered.
  const factory ChartValue.indexed(List<T> values) = ChartIndexed<T>;

  /// A callback evaluated with the chart's typed context during resolution.
  const factory ChartValue.resolver(ChartScript<T> callback) = ChartResolver<T>;

  /// Preserves this variant directly in an internal option cell.
  /// No callback is executed during lowering.
  @internal
  Opt<T> toOptionCell();
}

/// A constant [ChartValue].
final class ChartConstant<T> extends ChartValue<T> {
  /// A value shared by the dataset.
  const ChartConstant(this.value) : super._();

  /// The constant value.
  final T value;

  @internal
  @override
  Opt<T> toOptionCell() => OptValue<T>(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChartConstant && value == other.value;

  @override
  int get hashCode => Object.hash(ChartConstant, value);

  @override
  String toString() => 'ChartValue.constant($value)';
}

/// An indexed [ChartValue].
final class ChartIndexed<T> extends ChartValue<T> {
  /// A repeating list of option values.
  const ChartIndexed(this.values) : super._();

  /// The style values. Treat the source list as immutable configuration.
  final List<T> values;

  @internal
  @override
  Opt<T> toOptionCell() => OptList<T>(<Object?>[...values]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartIndexed && listEquals<Object?>(values, other.values);

  @override
  int get hashCode => Object.hash(ChartIndexed, Object.hashAll(values));

  @override
  String toString() => 'ChartValue.indexed($values)';
}

/// A callback-backed [ChartValue].
final class ChartResolver<T> extends ChartValue<T> {
  /// A function of each option resolution's typed context.
  const ChartResolver(this.callback) : super._();

  /// The callback. Reuse a function or method tear-off across rebuilds.
  final ChartScript<T> callback;

  @internal
  @override
  Opt<T> toOptionCell() {
    // A fresh two-argument bridge, preserving the previous typed callback
    // adaptation and function-identity behavior of each lowering.
    final callback = this.callback;
    Object? resolve(Object? context, Object? _) =>
        callback(context! as ChartContext);
    return OptFunction<T>(resolve);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartResolver && callback == other.callback;

  @override
  int get hashCode => Object.hash(ChartResolver, callback);

  @override
  String toString() => 'ChartValue.resolver($callback)';
}
