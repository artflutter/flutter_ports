// Ported from Chart.js v4.5.1 src/helpers/helpers.extras.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/helpers.extras.ts`.
///
/// Chart.js ADR 0007 decides the three scheduling helpers:
/// - [requestAnimFrame] registers a Flutter frame callback
///   (`platform-request-anim-frame`, differences.md).
/// - [throttled] calls its function at most one time in each frame, with the
///   latest argument.
/// - [debounce] calls its function after a `dart:async` [Timer]. It gives
///   the latest argument in both branches (`js-semantics-debounce-args`). It
///   returns a [Debounced] with a `cancel()` method
///   (`platform-debounce-cancel`).
///
/// This file imports `package:flutter/scheduler.dart` and `dart:async`. Thus
/// it is not a pure layer (porting-flow.md section 3).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter_chartjs/src/helpers/helpers.collection.dart'
    show lookupByKey;
import 'package:flutter_chartjs/src/helpers/helpers.core.dart'
    show isNullOrUndef;
import 'package:flutter_chartjs/src/helpers/helpers.math.dart' show limitValue;
import 'package:flutter_chartjs/src/js/js_math.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/types/index.dart';

/// helpers.extras.ts:7 `fontString`.
///
/// The `+` operator converts [pixelSize] with `Number::toString`
/// ([jsNumberToString]), so `12` gives `'12px'`, not `'12.0px'`.
String fontString(double pixelSize, String fontStyle, String fontFamily) {
  return '$fontStyle ${jsNumberToString(pixelSize)}px $fontFamily';
}

/// helpers.extras.ts:14 `requestAnimFrame`.
///
/// Request animation polyfill
///
/// Registers [callback] for the next frame through
/// [SchedulerBinding.scheduleFrameCallback], which also schedules a frame
/// (Chart.js ADR 0007, decision 1). Returns the callback id, as
/// `window.requestAnimationFrame` does. The id is the `int` handle of
/// [SchedulerBinding.cancelFrameCallbackWithId]. [callback] gets no frame
/// time stamp, because the upstream callbacks take no argument.
///
/// Without a binding, the call throws. Upstream calls [callback] at once
/// when no `window` exists (`platform-request-anim-frame`, differences.md).
/// The microtasks of a frame run after all its frame callbacks, not after
/// each callback.
int requestAnimFrame(void Function() callback) {
  // DIVERGES(chartjs): platform-request-anim-frame, a frame callback.
  return SchedulerBinding.instance.scheduleFrameCallback((_) => callback());
}

/// helpers.extras.ts:27 `throttled`.
///
/// Throttles calling `fn` once per animation frame
/// Latest arguments are used on the actual call
///
/// The variadic `TArgs` is one type parameter [T]. A caller with more than
/// one argument passes a record or a Flutter value type, for example
/// `Size?` (Chart.js ADR 0007, decision 2). The upstream `thisArg` has no
/// Dart counterpart: a Dart closure takes `this` from the code around it.
/// Each throttled function coalesces its own calls to one call in each
/// frame.
void Function(T args) throttled<T>(void Function(T args) fn) {
  // Upstream starts with an empty argument list. The first call assigns the
  // value before the frame callback reads it.
  late T argsToUse;
  var ticking = false;

  return (args) {
    // Save the args for use later
    argsToUse = args;
    if (!ticking) {
      ticking = true;
      requestAnimFrame(() {
        ticking = false;
        fn(argsToUse);
      });
    }
  };
}

/// helpers.extras.ts:50 `debounce`.
///
/// Debounces calling `fn` for `delay` ms
///
/// The variadic `TArgs` is one type parameter [T], as for [throttled]. The
/// result is a [Debounced]: [Debounced.call] is the upstream function, and
/// [Debounced.cancel] cancels the pending [Timer]
/// (`platform-debounce-cancel`, differences.md).
///
/// The branch tests [delay] with the JS ToBoolean. Thus a delay of `0.5`,
/// `-5` or infinity takes the delayed branch. The [Timer] duration is
/// `ToInt32(delay)` milliseconds, as the HTML `setTimeout` converts the
/// delay. [Timer] treats a negative duration as zero.
///
/// Upstream passes the argument array to `setTimeout`, so the delayed call
/// gets one array argument, and the immediate call gets the arguments
/// spread. Here both calls get the latest argument
/// (`js-semantics-debounce-args`, differences.md).
Debounced<T> debounce<T>(void Function(T args) fn, double delay) {
  Timer? timeout;
  // DIVERGES(chartjs): platform-debounce-cancel, a Debounced with cancel().
  return Debounced<T>._(
    (args) {
      if (delay != 0 && !delay.isNaN) {
        timeout?.cancel();
        timeout = Timer(
          Duration(milliseconds: jsToInt32(delay).toInt()),
          // DIVERGES(chartjs): js-semantics-debounce-args, args not [args].
          () => fn(args),
        );
      } else {
        fn(args);
      }
      return delay;
    },
    () => timeout?.cancel(),
  );
}

/// The result of [debounce]: the upstream debounced function, plus
/// [cancel] (Chart.js ADR 0007, decision 4).
///
/// `platform-debounce-cancel` (differences.md): upstream returns a plain
/// function and never clears its timeout. `Chart.destroy()` calls
/// [cancel], so that no `update()` reaches a destroyed chart and no [Timer]
/// stays pending after the widget tree unmounts.
final class Debounced<T> {
  // DIVERGES(chartjs): platform-debounce-cancel, a port-only class.
  Debounced._(this._call, this._cancel);

  final double Function(T args) _call;

  final void Function() _cancel;

  /// helpers.extras.ts:52, the function that `debounce` returns.
  ///
  /// Calls `fn` with [args] at once, or after `delay` ms. A new call in the
  /// delay cancels the pending call. Returns `delay`.
  double call(T args) => _call(args);

  /// Cancels the pending call, as `clearTimeout(timeout)` does. Does nothing
  /// when no call is pending.
  void cancel() => _cancel();
}

/// helpers.extras.ts:67 `_toLeftRightCenter`.
///
/// Converts 'start' to 'left', 'end' to 'right' and others to 'center'
/// @private
String toLeftRightCenter(String align) => align == 'start'
    ? 'left'
    : align == 'end'
    ? 'right'
    : 'center';

/// helpers.extras.ts:73 `_alignStartEnd`.
///
/// Returns `start`, `end` or `(start + end) / 2` depending on `align`.
/// Defaults to `center`
/// @private
double alignStartEnd(String align, double start, double end) => align == 'start'
    ? start
    : align == 'end'
    ? end
    : (start + end) / 2;

/// helpers.extras.ts:79 `_textX`.
///
/// Returns `left`, `right` or `(left + right) / 2` depending on `align`.
/// Defaults to `left`
/// @private
double textX(
  String align,
  double left,
  double right,
  // The upstream signature has a positional `rtl`.
  // ignore: avoid_positional_boolean_parameters
  bool rtl,
) {
  final check = rtl ? 'left' : 'right';
  return align == check
      ? right
      : align == 'center'
      ? (left + right) / 2
      : left;
}

/// helpers.extras.ts:88 `_getStartAndCountOfVisiblePoints`.
///
/// Return start and count of visible points.
/// @private
///
/// `start` and `count` are JS numbers, thus `double` values (Chart.js ADR
/// 0010). They are always integers: list positions and lengths. The `lo`
/// and `hi` of [lookupByKey] are `int` values, which the port converts.
/// `_parsed.slice(…)` is [_slice].
({double start, double count}) getStartAndCountOfVisiblePoints(
  ChartMeta meta,
  List<PointElement> points,
  // The upstream signature has a positional `animationsDisabled`.
  // ignore: avoid_positional_boolean_parameters
  bool animationsDisabled,
) {
  final pointCount = points.length.toDouble();

  var start = 0.0;
  var count = pointCount;

  if (meta.sorted) {
    final iScale = meta.iScale!;
    // Upstream reads `vScale.axis` only in the spanGaps callbacks.
    final vScale = meta.vScale;
    final parsed = meta.parsed;
    final dataset = meta.dataset;
    final spanGaps = dataset != null
        ? dataset.options != null
              ? dataset.options!['spanGaps']
              : null
        : null;
    final axis = iScale.axis;
    final (:min, :max, :minDefined, :maxDefined) = iScale.getUserBounds();

    if (minDefined) {
      start = jsMin(
        lookupByKey(parsed, axis, min).lo.toDouble(),
        animationsDisabled
            ? pointCount
            : lookupByKey(
                points,
                axis,
                iScale.getPixelForValue(min),
              ).lo.toDouble(),
      );
      if (jsTruthy(spanGaps)) {
        final distanceToDefinedLo = _slice(parsed, 0, start + 1).reversed
            .toList()
            .indexWhere((point) => !isNullOrUndef(point[vScale!.axis]));
        start -= math.max<int>(0, distanceToDefinedLo);
      }
      start = limitValue(start, 0, pointCount - 1);
    }
    if (maxDefined) {
      var end = jsMax(
        lookupByKey(parsed, iScale.axis, max, true).hi + 1.0,
        animationsDisabled
            ? 0.0
            : lookupByKey(
                    points,
                    axis,
                    iScale.getPixelForValue(max),
                    true,
                  ).hi +
                  1.0,
      );
      if (jsTruthy(spanGaps)) {
        final distanceToDefinedHi = _slice(
          parsed,
          end - 1,
        ).indexWhere((point) => !isNullOrUndef(point[vScale!.axis]));
        end += math.max<int>(0, distanceToDefinedHi);
      }
      count = limitValue(end, start, pointCount) - start;
    } else {
      count = pointCount - start;
    }
  }

  return (start: start, count: count);
}

/// `array.slice(begin, end)` (ECMAScript 23.1.3.28) for integer arguments:
/// a negative bound counts from the end, and both bounds stay in the list.
/// A null [end] is `undefined`: the length of [list].
List<T> _slice<T>(List<T> list, double begin, [double? end]) {
  final length = list.length;
  int bound(double value) => value < 0
      ? math.max(length + value.toInt(), 0)
      : math.min(value.toInt(), length);
  final from = bound(begin);
  final to = end == null ? length : bound(end);
  return from < to ? list.sublist(from, to) : <T>[];
}

/// helpers.extras.ts:146 `newRanges`, the object literal
/// `{xmin, xmax, ymin, ymax}` of `_scaleRangesChanged`.
final class _ScaleRanges implements ScaleRanges {
  _ScaleRanges({
    required this.xmin,
    required this.xmax,
    required this.ymin,
    required this.ymax,
  });

  @override
  double xmin;

  @override
  double xmax;

  @override
  double ymin;

  @override
  double ymax;
}

/// helpers.extras.ts:144 `_scaleRangesChanged`.
///
/// Checks if the scale ranges have changed.
/// @param {object} meta - dataset meta.
/// @returns {boolean}
/// @private
///
/// The `!==` tests are `!=` on `double` values. Both give true for NaN and
/// false for `0` and `-0`.
bool scaleRangesChanged(ChartMeta meta) {
  final xScale = meta.xScale!;
  final yScale = meta.yScale!;
  final scaleRanges = meta.scaleRanges;
  final newRanges = _ScaleRanges(
    xmin: xScale.min,
    xmax: xScale.max,
    ymin: yScale.min,
    ymax: yScale.max,
  );
  if (scaleRanges == null) {
    meta.scaleRanges = newRanges;
    return true;
  }
  final changed =
      scaleRanges.xmin != xScale.min ||
      scaleRanges.xmax != xScale.max ||
      scaleRanges.ymin != yScale.min ||
      scaleRanges.ymax != yScale.max;

  // Object.assign(_scaleRanges, newRanges)
  scaleRanges
    ..xmin = newRanges.xmin
    ..xmax = newRanges.xmax
    ..ymin = newRanges.ymin
    ..ymax = newRanges.ymax;
  return changed;
}
