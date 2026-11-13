// Original code, not ported from Chart.js: the native extensible tick.

/// The native tick contract.
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableScaleContext;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsToString;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:meta/meta.dart';

/// The lines of a label of the app, for example an item of `data.labels`:
/// the label of a tick of a category scale (scale.category.js:25-31).
///
/// A label of the app is a string, a List of lines or another value
/// (index.d.ts:1389). A `List<String>` keeps its identity. A string is one
/// line, and another value is the line of its string form. Null gives null:
/// the scale removes the tick. A null line of a List is not a line, as in
/// the measure of upstream (core.scale.js:842).
@internal
List<String>? labelLinesOf(Object? label) => switch (label) {
  null || Undefined() => null,
  final String line => <String>[line],
  final List<String> lines => lines,
  final List<Object?> lines => <String>[
    for (final line in lines)
      if (line != null && line is! Undefined) jsToString(line),
  ],
  _ => <String>[jsToString(label)],
};

/// A tick of a scale: the typedef `Tick` of core.scale.js:15 and the
/// interface of index.d.ts:1194.
///
/// Upstream makes a tick as an object literal, for example `{value}`
/// (scale.category.js:111) or `{value, major}` (scale.time.js:188-191). The
/// scales construct a [Tick]. `buildTicks` returns a list of them, and the
/// `afterBuildTicks` callback can replace the list.
///
/// Apps and plugins may extend this class. The scale keeps the identity of
/// each tick.
class Tick({
  /// The value of the tick: a number of a linear or a logarithmic scale, the
  /// index of the label of a category scale, or the time value of a time
  /// scale in milliseconds (index.d.ts:1195).
  required var double value,

  /// The lines of the label that `generateTickLabels` writes
  /// (core.scale.js:574): the result of the tick callback.
  ///
  /// A label of one line is a List of one item. Null is the start value. The
  /// scale removes a tick whose callback gives null (core.scale.js:783). An
  /// empty List keeps the tick and draws no line.
  var List<String>? label,

  /// Whether the tick is a major tick. The time and the logarithmic scales
  /// write it (scale.time.js:165, scale.logarithmic.js:55).
  var bool major = false,

  /// The significand of a tick of a logarithmic scale
  /// (scale.logarithmic.js:55). The ticks of the other scales have none.
  var double? significand,
}) {
  /// Creates a tick with no label. `generateTickLabels` writes the [label].
  this;

  /// The scriptable context of the tick that `Scale.getContext` makes
  /// (core.scale.js:966-967). Null is the start value.
  ScriptableScaleContext? get $context {
    final parent = _contextParent;
    if (parent != null) {
      _contextParent = null;
      _context = ScriptableScaleContext.tick(
        parent,
        this,
        _contextIndex.toDouble(),
      );
    }
    return _context;
  }

  set $context(ScriptableScaleContext? value) {
    _contextParent = null;
    _context = value;
  }

  ScriptableScaleContext? _context;
  ScriptableScaleContext? _contextParent;
  int _contextIndex = 0;

  /// Make the same fresh context available on first access after a static
  /// measurement-plan hit. Capture the original parent/index before auto-skip;
  /// a hook-supplied context or an earlier preparation always wins.
  @internal
  void prepareContextForLayout(ScriptableScaleContext parent, int index) {
    // DIVERGES(chartjs): adapt-lazy-tick-context, materialize on observation.
    if (_context != null || _contextParent != null) return;
    _contextIndex = index;
    _contextParent = parent;
  }
}
