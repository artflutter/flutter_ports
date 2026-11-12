// Original code, not ported from Chart.js: the two axis reads of the core.

/// The reads of a [ScaleAxis] that several core files share (row
/// `adapt-axis-objects`).
///
/// Upstream compares two axis letters with `===` and reads a plain object
/// of the user by the letter (`item[axis]`). An axis of the port is a class
/// with no members, so the core matches its class: [sameAxis] for the
/// compare, and [axisDataKey] for the key of a plain object of the user
/// (a data item of `parsing: false`, or a `_stacks` object that user code
/// gave).
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/types/chart_axis.dart';

/// `a === b` of two axes: both [XAxis], both [YAxis] or both [RAxis]. An
/// axis of another class is the same only as itself.
bool sameAxis(ScaleAxis? a, ScaleAxis? b) => switch ((a, b)) {
  (XAxis(), XAxis()) || (YAxis(), YAxis()) || (RAxis(), RAxis()) => true,
  _ => identical(a, b),
};

/// The key of [axis] in a plain object of the user, for example the data
/// item `{x: 1, y: 2}`: `'x'`, `'y'` or `'r'`. An axis of another class has
/// no key: Dart `null`.
String? axisDataKey(ScaleAxis? axis) => switch (axis) {
  XAxis() => 'x',
  YAxis() => 'y',
  RAxis() => 'r',
  _ => null,
};
