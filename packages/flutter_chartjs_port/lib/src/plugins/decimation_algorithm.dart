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

import 'package:flutter_chartjs_port/chartjs_core.dart';
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
///   List<ParsedItem?> decimate(
///     List<ParsedItem?> data,
///     int start,
///     int count,
///     double availableWidth,
///     DecimationOptions options,
///   ) => [
///     for (var i = start; i < start + count; i += n) data[i],
///   ];
/// }
/// ```
@immutable
abstract class const DecimationAlgorithm() {
  /// An algorithm.
  this;

  /// The decimated items of the [count] items of [data] from the index
  /// [start], for a chart area of [availableWidth] pixels. The items are the
  /// data items of the app (the plugin needs `parsing: false`): each one is a
  /// [ParsedItem], for example a `DataPoint`. [options]
  /// are the merged options of the plugin: a built-in algorithm reads
  /// `samples` from them. An algorithm of a program keeps its own settings in
  /// its fields.
  List<ParsedItem?> decimate(
    List<ParsedItem?> data,
    int start,
    int count,
    double availableWidth,
    DecimationOptions options,
  );
}
