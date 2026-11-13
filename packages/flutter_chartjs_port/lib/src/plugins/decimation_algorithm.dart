// Original code, not ported from Chart.js: the decimation algorithm.

/// The algorithm of the decimation plugin (row
/// `adapt-decimation-algorithm-objects`).
///
/// The option `algorithm` of the decimation plugin holds a
/// [DecimationAlgorithm]. The two algorithms of upstream are classes of
/// `plugin.decimation.dart` (`LttbDecimationAlgorithm`,
/// `MinMaxDecimationAlgorithm`). The base class is here, because the option
/// cell of `opt.dart` reads the type of the option, and the option model
/// imports no plugin.
///
/// This library is a pure layer.
library;

import 'package:meta/meta.dart';

/// An algorithm of the decimation plugin: the value of the option
/// `algorithm`. It gives fewer data items that draw the same line.
///
/// Upstream holds the name of an algorithm in the option and selects the
/// function with a `switch` (plugin.decimation.js:269-278). The port holds
/// the algorithm itself: the plugin calls [decimate] of the value of the
/// option, and has no `switch`. A program gives its own algorithm as a
/// subclass, with no registration:
///
/// ```dart
/// final class EveryNthDecimation extends DecimationAlgorithm {
///   const EveryNthDecimation(this.n);
///
///   final int n;
///
///   @override
///   List<Object?> decimate(
///     List<Object?> data,
///     double start,
///     double count,
///     double availableWidth,
///     Object options,
///   ) => [
///     for (var i = start.toInt(); i < start + count; i += n) data[i],
///   ];
/// }
/// ```
@immutable
abstract class const DecimationAlgorithm() {
  /// An algorithm.
  this;

  /// The decimated items of the [count] items of [data] from the index
  /// [start], for a chart area of [availableWidth] pixels. The items are the
  /// data items of the app (the plugin needs `parsing: false`). [options]
  /// are the options of the plugin: a built-in algorithm reads `samples`
  /// from them, and an algorithm of a program can have its own fields.
  List<Object?> decimate(
    List<Object?> data,
    int start,
    int count,
    double availableWidth,
    Object options,
  );

  /// The algorithm of [value], the value of the option `algorithm`, or Dart
  /// `null` for a value that is not an algorithm: the plugin then throws, as
  /// upstream throws for a name that is not a case of its `switch`. An
  /// algorithm name of Chart.js is not an algorithm: a debug build stops on
  /// it.
  static DecimationAlgorithm? of(Object? value) {
    assert(
      value is! String,
      'The option algorithm of the decimation takes a DecimationAlgorithm, '
      'not the name "$value".',
    );
    return value is DecimationAlgorithm ? value : null;
  }
}
