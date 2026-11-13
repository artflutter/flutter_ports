// Original code, not ported from Chart.js: native tick labels in the tests.

/// The tick label forms of the tests (differences.md row `adapt-native-tick`).
library;

import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsNumberToString;
import 'package:flutter_chartjs_port/src/types/index.dart' show Scale, Tick;
import 'package:flutter_chartjs_port/src/types/tick.dart' show labelLinesOf;

/// The label of [tick] in the form of an upstream expectation: the line of a
/// label of one line, else the List of lines. Null is no label.
///
/// A ported spec compares it with the string literal of the upstream spec
/// (`scale.ticks.map(t => t.label)`).
Object? upstreamTickLabel(Tick tick) => switch (tick.label) {
  null => null,
  [final line] => line,
  final lines => lines,
};

/// The native label of the label [upstream] of generated reference data: a
/// string is one line, a List is its lines, and a number is the line of its
/// string form.
List<String>? nativeTickLabel(Object? upstream) => labelLinesOf(upstream);

/// The tick callback `value => '' + value` of the upstream specs
/// (`value.toString()`).
List<String>? valueTickLabel(
  Scale scale,
  double value,
  int index,
  List<Tick> ticks,
) => <String>[jsNumberToString(value)];

/// The tick callback `(value, index) => '' + index` of the upstream specs
/// (`index.toString()`).
List<String>? indexTickLabel(
  Scale scale,
  double value,
  int index,
  List<Tick> ticks,
) => <String>['$index'];
