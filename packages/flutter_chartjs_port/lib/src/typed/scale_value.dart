// Original code, not ported from Chart.js: the scriptable options of an axis.

/// Constant, indexed and callback values for the scriptable options of an
/// axis: the grid and tick colors, the grid line widths and the tick font
/// (`docs/axes/styling.md`, scriptable with `ScriptableScaleContext`).
library;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:meta/meta.dart' show immutable;

/// A scriptable option of an axis: a function of the tick context that gives
/// the value.
///
/// Chart.js calls it for each tick in each draw. The value has no fallback.
///
/// ```dart
/// ChartPaint gridColor(ScriptableScaleContext context) =>
///     context.tick?.value == 0 ? zeroPaint : linePaint;
/// ```
typedef ScaleScript<T> = T Function(ScriptableScaleContext context);

/// One of the forms of a scriptable option of an axis.
///
/// Use [ScaleValue.constant] for one value, [ScaleValue.indexed] for a value
/// for each tick, which repeats when the List is shorter, or
/// [ScaleValue.resolver] for a function of the tick context. A parameter that
/// is `null` takes the default.
///
/// Values compare by form and contents, and a function by Dart function
/// equality: a method tear-off or a function in a field gives no new value in
/// each build.
@immutable
sealed class const ScaleValue<T>._() {
  /// One value for each tick.
  const factory constant(T value) = ScaleConstant<T>;

  /// A value for each tick by its index, repeated when the List is shorter.
  /// The lowering copies the List.
  const factory indexed(List<T> values) = ScaleIndexed<T>;

  /// A function of the tick context, called in each resolution.
  const factory resolver(ScaleScript<T> callback) = ScaleResolver<T>;

  /// The option cell of this value. The lowering calls no function.
  Opt<T> toOptionCell();
}

/// A constant [ScaleValue].
final class const ScaleConstant<T>(
  /// The value.
  final T value,
) extends ScaleValue<T> {
  /// One value for each tick.
  this : super._();

  @override
  Opt<T> toOptionCell() => OptValue<T>(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScaleConstant && value == other.value;

  @override
  int get hashCode => Object.hash(ScaleConstant, value);

  @override
  String toString() => 'ScaleValue.constant($value)';
}

/// An indexed [ScaleValue].
final class const ScaleIndexed<T>(
  /// The values by tick index. Treat the List as immutable.
  final List<T> values,
) extends ScaleValue<T> {
  /// A value for each tick by its index.
  this : super._();

  @override
  Opt<T> toOptionCell() => OptList<T>(<Object?>[...values]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScaleIndexed && listEquals<Object?>(values, other.values);

  @override
  int get hashCode => Object.hash(ScaleIndexed, Object.hashAll(values));

  @override
  String toString() => 'ScaleValue.indexed($values)';
}

/// A [ScaleValue] of a function.
final class const ScaleResolver<T>(
  /// The function. Reuse a function or a method tear-off across builds.
  final ScaleScript<T> callback,
) extends ScaleValue<T> {
  /// A function of the tick context.
  this : super._();

  @override
  Opt<T> toOptionCell() {
    // A two-argument bridge, as ChartResolver of chart_value.dart.
    final callback = this.callback;
    Object? resolve(ScriptableScaleContext context, Object? _) =>
        callback(context);
    return OptFunction<T>(resolve);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScaleResolver && callback == other.callback;

  @override
  int get hashCode => Object.hash(ScaleResolver, callback);

  @override
  String toString() => 'ScaleValue.resolver($callback)';
}
