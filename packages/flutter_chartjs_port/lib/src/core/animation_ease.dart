// Original code, not ported from Chart.js: one curve solve for equal inputs.

/// The eased factors of one `Animator.update` call (Chart.js ADR 0149, row
/// `adapt-animation-ease-table`).
///
/// The animations of one chart update share the curve and the duration, and
/// most of them share the start. So most ticks of one frame ask the curve
/// for the same input. The default curve `Curves.easeOutQuart` is a
/// [Cubic], which Flutter solves by bisection. The table of this library
/// keeps the inputs and the results of the curve calls of one
/// `Animator.update` call. A tick with an input of the table takes its
/// result, with no second solve.
///
/// Each result is the result of `curve.transform(factor)`, bit for bit. The
/// guards:
/// - The curve is an object of the class [Cubic] itself. That class is
///   immutable, it runs no code of the app, and its result depends only on
///   its four fields and on the input. A curve of another class, also a
///   subclass of [Cubic], keeps each call.
/// - Each entry has its curve object. An entry of another curve object is a
///   miss.
/// - Only an input above 0 and below 1 takes the table. `Curve.transform`
///   gives 0 and 1 back with no solve, and it takes no value outside that
///   range.
/// - The table lives while an `Animator.update` call runs. Its last call
///   that ends removes each entry. A tick outside `Animator.update`, for
///   example of `Animation.cancel`, calls the curve.
///
/// The table has one entry for each slot. Two inputs of one slot replace
/// each other, and each of them still gets the result of its own curve
/// call.
///
/// This library is a pure layer: `core.animation.dart` imports it.
library;

import 'dart:typed_data';

import 'package:flutter/animation.dart' show Cubic, Curve;
import 'package:meta/meta.dart';

/// The count of the slots of the table, a power of two.
const int _size = 256;

/// The slot of an input is the low bits of the input times this scale. The
/// scale is no power of two and no whole number, so the inputs `k / d` of
/// the whole milliseconds `k` of one duration `d` spread over the slots,
/// also for a duration of 256, 512 or 1024 ms.
const double _slotScale = 1696835.7;

final Float64List _inputs = Float64List(_size);
final Float64List _results = Float64List(_size);

/// The curve object of each entry, or Dart `null` for an empty slot.
final List<Curve?> _curves = List<Curve?>.filled(_size, null);

/// The count of the `Animator.update` calls that run now. An `update` call
/// can run inside another one: a listener or a draw can call it.
int _depth = 0;

/// Whether [_curves] has an entry.
bool _filled = false;

/// The last curve that is an object of the class [Cubic] itself, or Dart
/// `null`.
Curve? _cubic;

/// The last curve of another class than [Cubic], or Dart `null`: it keeps
/// each call, with no second read of its class.
Curve? _other;

int _hits = 0;
int _misses = 0;

/// Whether an `Animator.update` call runs now, so that a tick can take
/// [easeTableAt].
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
bool get easeTableActive => _depth != 0;

/// Starts the table for one `Animator.update` call. Each call needs one
/// [easeTableEnd] call, in a `finally` block.
void easeTableBegin() {
  _depth++;
}

/// Ends the table of one `Animator.update` call. The end of the last call
/// that runs removes each entry, so the table keeps no curve object and no
/// result for a later frame.
void easeTableEnd() {
  assert(_depth > 0, 'easeTableEnd without easeTableBegin.');
  if (--_depth != 0) return;
  if (_filled) {
    _curves.fillRange(0, _size, null);
    _filled = false;
  }
  _cubic = null;
  _other = null;
}

/// `curve.transform(factor)`, with one curve call for each input of the
/// `Animator.update` calls that run now.
///
/// The caller reads [easeTableActive] first. [factor] is a value that
/// `curve.transform` takes: the result and each error are those of that
/// call.
double easeTableAt(Curve curve, double factor) {
  // The second and the third test are false for 0, 1 and NaN.
  if (!identical(curve, _other) && factor > 0.0 && factor < 1.0) {
    final slot = (factor * _slotScale).toInt() & (_size - 1);
    // An entry holds only a curve that passed the class test below.
    if (identical(_curves[slot], curve) && _inputs[slot] == factor) {
      assert(_count(hit: true), 'Unreachable: the count is always true.');
      return _results[slot];
    }
    if (identical(curve, _cubic) || _isCubic(curve)) {
      final result = curve.transform(factor);
      _curves[slot] = curve;
      _inputs[slot] = factor;
      _results[slot] = result;
      _filled = true;
      assert(_count(hit: false), 'Unreachable: the count is always true.');
      return result;
    }
  }
  return curve.transform(factor);
}

/// Whether [curve] is an object of the class [Cubic] itself. It stores the
/// answer in [_cubic] or [_other].
bool _isCubic(Curve curve) {
  if (curve.runtimeType == Cubic) {
    _cubic = curve;
    return true;
  }
  _other = curve;
  return false;
}

/// Counts one hit or one miss of the table. Only an `assert` calls it, so a
/// profile build and a release build count nothing.
bool _count({required bool hit}) {
  if (hit) {
    _hits++;
  } else {
    _misses++;
  }
  return true;
}

/// The count of the eased factors that came from the table, in a build with
/// asserts.
@visibleForTesting
int get debugEaseTableHits => _hits;

/// The count of the curve calls that made an entry of the table, in a build
/// with asserts.
@visibleForTesting
int get debugEaseTableMisses => _misses;

/// The count of the entries of the table.
@visibleForTesting
int get debugEaseTableEntries {
  var count = 0;
  for (final curve in _curves) {
    if (curve != null) count++;
  }
  return count;
}
