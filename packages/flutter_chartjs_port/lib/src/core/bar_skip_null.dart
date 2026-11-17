// Original code, not ported from Chart.js: the index of the skipNull search.

import 'package:flutter_chartjs_port/src/core/bar_index_layout.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// The `find` of `skipNull` in `_getStacks` (controller.bar.js:443-450) as
/// one pass for each parsed list and each update, then one read for each
/// search (row `adapt-bar-skip-null-index`).
///
/// One object lives for one `BarController.update` call. The first search in
/// a parsed list walks the list one time and proves that it is positional:
/// each item is a [ParsedItem] whose index value is the number of its own
/// position, or `null`, or `undefined`. In such a list the first item with
/// the index value `v` can only be the item at the position `v`. Each later
/// search reads that one item and tests its index value again. Each other
/// case gives [scan]: the caller then runs the upstream search from the
/// start of the list.
///
/// A proof holds only while no code of the app runs. Port code writes no
/// parsed list and no index value between two bars. Code of the app can run
/// there only in these ways:
///
/// - a function value that the JS runtime calls ([jsCall], [jsCall1]): a
///   scriptable option of any scope, a `_fallback` or `_scriptable`
///   descriptor. [JsFunction.calls] counts each such call. A new count ends
///   the proofs.
/// - the options of one bar ([optionRead]): the resolve of the options of a
///   bar can read a custom scope. It ends the proofs before the resolve.
/// - a read of a parsed list or of its items: the data List of the app
///   (`parsing: false`), a List of another class, an item that is not a
///   [ParsedItem] (the `operator []` of a Map of the app), or a value that is
///   not a number, `null` or `undefined` (`jsIsNaN` of an object calls its
///   `toString`). A proof pass ([proveAll], or the first search in a list)
///   finds each such list, and the object answers [scan] for the rest of its
///   update. The caller proves each list that the search can read in
///   [qualify], so after [qualify] no read of a list runs code of the app.
/// - a subclass method, a custom Map or List, or a route of a scope. The
///   caller tests these one time, at the first proof ([qualify]): before
///   that point no code of the app ran since the test, and after it each
///   first entry into code of the app is one of the two first kinds above.
///
/// After each such event the object answers [scan] for the rest of its
/// update. The live tests of the list length and of the item at the position
/// stay as a second line of defense.
final class BarSkipNullIndex(
  /// The test of the chart, its containers, its classes and its option
  /// scopes, and the proof of each parsed list that the search can read
  /// ([proveAll]). It runs no code of the app. The first search with a number
  /// calls it one time.
  final bool Function() qualify,
) {
  /// An index with no proof.
  this;

  /// The result of [find] that sends the caller to the upstream search.
  static const Object scan = Object();

  /// Whether an update with the mode [mode] on the scales [iScale] and
  /// [vScale] can take the index: a direct mode makes no animation for a bar
  /// (core.datasetController.js:229, :901), and the exact category or
  /// linear scale runs no code of another class in a pixel read.
  static bool applies(String mode, types.Scale? iScale, types.Scale? vScale) =>
      (mode == 'none' || mode == 'reset') &&
      exactScale(iScale) &&
      exactScale(vScale);

  /// Whether [scale] is the exact category or linear scale.
  static bool exactScale(Object? scale) =>
      scale is NativeBarIndexReads && scale.supportsNativeBarIndexReads;

  /// The class of the List that `_dataCheck` gives `meta._parsed`: a List of
  /// the SDK. A read of such a List runs no code of the app.
  static final Type _plainList = <Object?>[].runtimeType;

  /// The count of the visits of a parsed item by the `find` of `skipNull`:
  /// the items of each proof pass, each read of this object and each item
  /// that the upstream search tests. Only a debug build counts, for the
  /// tests.
  @visibleForTesting
  static int debugVisits = 0;

  /// Counts one visit of the upstream search. It gives true, for an
  /// `assert`.
  static bool debugCountVisit() {
    debugVisits++;
    return true;
  }

  /// The proven length of each parsed list of this update, or -1 for a list
  /// that is not positional. The keys compare by identity.
  final Map<List<Object?>, int> _proven = Map.identity();

  /// The result of [_prove] for a list whose read can run code of the app.
  static const int _unsafe = -2;

  /// The index axis of the proofs.
  ScaleAxis? _axis;

  /// Whether the first search with a number ran [qualify].
  bool _started = false;

  /// [JsFunction.calls] at the first proof.
  int _calls = 0;

  /// Whether an event ended the proofs of this update, or [qualify] failed.
  bool _dropped = false;

  /// Whether this object made a proof pass.
  bool get proved => _proven.isNotEmpty;

  /// Whether an event ended the proofs, or [qualify] failed.
  bool get dropped => _dropped;

  /// The resolve of the options of a bar can run code of the app. A proof
  /// that this object made before it does not hold: the upstream search
  /// takes the rest of the update.
  void optionRead() {
    if (_started) _dropped = true;
  }

  /// Proves the parsed list of each of [metas] for the index axis [axis]
  /// before the first answer. It gives false when the read of one of the
  /// lists can run code of the app: then the caller declines the index. The
  /// caller gives each meta whose list the search, or the read of the
  /// current item, can reach in this update.
  bool proveAll(Iterable<types.ChartMeta> metas, ScaleAxis axis) {
    for (final meta in metas) {
      final parsed = meta.parsed;
      if (_proven.containsKey(parsed)) continue;
      final length = _prove(meta, parsed, axis);
      if (length == _unsafe) return false;
      _proven[parsed] = length;
    }
    return true;
  }

  /// The first item of the parsed list of [meta] whose value of [axis] is
  /// `===` [value], or `undefined` when a proven list has no such item, or
  /// [scan] when this object cannot prove the answer.
  Object? find(types.ChartMeta meta, ScaleAxis axis, Object? value) {
    // `===` of a value that is not a number: the upstream search decides.
    if (_dropped || value is! num) return scan;
    if (!_started) {
      _started = true;
      if (!qualify()) {
        _dropped = true;
        return scan;
      }
      _calls = JsFunction.calls;
      _axis = axis;
    } else if (JsFunction.calls != _calls || !identical(axis, _axis)) {
      // A function of the app ran since the first proof.
      _dropped = true;
      return scan;
    }
    final parsed = meta.parsed;
    var length = _proven[parsed];
    if (length == null) {
      length = _prove(meta, parsed, axis);
      if (length == _unsafe) {
        // The search of this list can run code of the app, which can write
        // a list of an earlier proof: no later answer relies on a proof.
        _dropped = true;
        return scan;
      }
      _proven[parsed] = length;
    }
    // A list that is not positional.
    if (length < 0) return scan;
    // The length changed since the pass: some code wrote the list.
    if (length != parsed.length) {
      _dropped = true;
      return scan;
    }
    // NaN is `===` to no value. A fraction and a position out of the range
    // match no item of a positional list.
    if (value != value ||
        value < 0 ||
        value >= length ||
        value != value.truncateToDouble()) {
      return undefined;
    }
    final item = parsed[value.toInt()];
    assert(debugCountVisit(), 'counts the read');
    if (item is ParsedItem) {
      final live = item.valueOf(axis);
      if (live is num) {
        // The item at the position still has the index value: it is the
        // first match.
        if (live == value) return item;
      } else if (live == null || identical(live, undefined)) {
        // The one item that can match has no index value.
        return undefined;
      }
    }
    // Some code wrote this slot of the list since the pass.
    _dropped = true;
    return scan;
  }

  /// The length of [parsed] when it is positional, -1 when it is not, or
  /// [_unsafe] when a read of the list, of an item or of a value of an item
  /// can run code of the app.
  int _prove(types.ChartMeta meta, List<Object?> parsed, ScaleAxis axis) {
    // With `parsing: false` the list is the data List of the app
    // (core.datasetController.js:461). Another List class can run code of
    // the app in a read.
    if (meta.controller?.parsing == false || parsed.runtimeType != _plainList) {
      return _unsafe;
    }
    // `_axisValueOf(parsed, meta.vScale)` and `jsIsNaN` of the search read
    // the value of the value axis of each found item.
    final vAxis = meta.vScale?.axis;
    if (vAxis == null) return _unsafe;
    final length = parsed.length;
    var positional = true;
    for (var i = 0; i < length; i++) {
      final item = parsed[i];
      assert(debugCountVisit(), 'counts the read');
      // A Map or another object of the app: its read runs code of the app.
      // A foreign value of a field can reach the code of the app too.
      if (item is! ParsedItem || item.hasForeign) return _unsafe;
      if (!_plain(item.valueOf(vAxis))) return _unsafe;
      final value = item.valueOf(axis);
      if (value is num) {
        if (value != i) positional = false;
      } else if (value != null && !identical(value, undefined)) {
        // `===` of an object is identity, but the value can reach other
        // reads of the loop: the index declines it.
        return _unsafe;
      }
    }
    return positional ? length : -1;
  }

  /// Whether [value] is a number, `null` or `undefined`: a value whose
  /// `jsIsNaN` and `===` run no code of the app.
  static bool _plain(Object? value) =>
      value is num || value == null || identical(value, undefined);
}
