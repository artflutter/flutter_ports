// Original code, not ported from Chart.js: helpers.extras has no spec.
@TestOn('vm')
library;

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_chartjs/src/helpers/helpers.extras.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/index.dart';
import 'package:flutter_test/flutter_test.dart';

// test/specs has no helpers.extras.tests.js. These tests cover the nine
// exports of src/helpers/helpers.extras.ts (AGENTS.md rule 3). The expected
// values of the six pure exports come from the helpers of the chart.js 4.5.1
// npm package (dist/chart.umd.cjs) in Node.js v24.12.0 on x64. The groups
// platform-request-anim-frame, js-semantics-debounce-args and
// platform-debounce-cancel pin the differences.md rows of the same names
// (Chart.js ADR 0007, decision 11). helpers.extras is not a pure layer. Thus
// this file runs on the VM only (Chart.js ADR 0007, decision 10).

/// A scale object literal `{axis, getUserBounds, getPixelForValue}` (or
/// `{min, max}`), passed as a [Scale]. The other members are absent.
final class _Scale implements Scale {
  _Scale({
    this.axis = 'x',
    this.min = 0,
    this.max = 0,
    this.bounds = (
      min: double.negativeInfinity,
      max: double.infinity,
      minDefined: false,
      maxDefined: false,
    ),
    this.pixel = _times10,
  });

  static double _times10(double value) => value * 10;

  @override
  final String axis;

  @override
  double min;

  @override
  double max;

  final ({double min, double max, bool minDefined, bool maxDefined}) bounds;

  final double Function(double value) pixel;

  @override
  ({double min, double max, bool minDefined, bool maxDefined})
  getUserBounds() => bounds;

  @override
  double getPixelForValue(double value, [double? index]) => pixel(value);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A dataset element with an `options` object, passed as an [Element].
final class _Dataset implements Element {
  _Dataset(this.options);

  @override
  final Map<String, Object?>? options;

  @override
  double get x => 0;

  @override
  double get y => 0;
}

/// A point element `{x, y}`, passed as a [PointElement]. The control points
/// are NaN, which stands for JS `undefined` (`SplinePoint`).
final class _Point implements PointElement {
  _Point(this.x, this.y);

  @override
  final double x;

  @override
  final double y;

  @override
  Map<String, Object?>? get options => null;

  @override
  bool? get skip => null;

  @override
  bool? get stop => null;

  @override
  double cp1x = double.nan;

  @override
  double cp1y = double.nan;

  @override
  double cp2x = double.nan;

  @override
  double cp2y = double.nan;
}

/// A dataset meta object literal, passed as a [ChartMeta].
final class _Meta implements ChartMeta {
  _Meta({
    this.sorted = true,
    this.iScale,
    this.vScale,
    this.parsed = const [],
    this.dataset,
    this.xScale,
    this.yScale,
  });

  @override
  final bool sorted;

  @override
  final Scale? iScale;

  @override
  final Scale? vScale;

  @override
  final List<Map<String, Object?>> parsed;

  @override
  final Element? dataset;

  @override
  final Scale? xScale;

  @override
  final Scale? yScale;

  @override
  ScaleRanges? scaleRanges;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const List<double> _xs = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

/// The meta and the points of the probe `mk(xs, ys, bounds, opts)`: the
/// parsed values are `{x, y}`, and each point is at the pixel `x * 10`.
(ChartMeta, List<PointElement>) _visible(
  List<Object?> ys,
  ({double min, double max, bool minDefined, bool maxDefined}) bounds, {
  List<double> xs = _xs,
  bool sorted = true,
  Element? dataset,
  double Function(double value) pixel = _Scale._times10,
}) {
  final meta = _Meta(
    sorted: sorted,
    iScale: _Scale(bounds: bounds, pixel: pixel),
    vScale: _Scale(axis: 'y'),
    parsed: [
      for (var i = 0; i < xs.length; i++) {'x': xs[i], 'y': ys[i]},
    ],
    dataset: dataset,
  );
  final points = [
    for (final x in xs) _Point(x * 10, x),
  ];
  return (meta, points);
}

({double min, double max, bool minDefined, bool maxDefined}) _bounds(
  double min,
  double max, {
  required bool minDefined,
  required bool maxDefined,
}) => (min: min, max: max, minDefined: minDefined, maxDefined: maxDefined);

void main() {
  group('fontString', () {
    test('converts the size with Number::toString', () {
      expect(fontString(12, 'italic', 'Arial'), 'italic 12px Arial');
      expect(
        fontString(12.5, 'normal', 'Helvetica Neue'),
        'normal 12.5px Helvetica Neue',
      );
      expect(
        fontString(0.1 + 0.2, 'bold', 'serif'),
        'bold 0.30000000000000004px serif',
      );
      expect(fontString(1e21, '', 'x'), ' 1e+21px x');
      expect(fontString(1e-7, 'normal', 'x'), 'normal 1e-7px x');
      // A double literal keeps the sign of the zero.
      // ignore: prefer_int_literals
      expect(fontString(-0.0, 'normal', 'x'), 'normal 0px x');
      expect(fontString(double.nan, 'normal', 'x'), 'normal NaNpx x');
      expect(
        fontString(double.infinity, 'normal', 'x'),
        'normal Infinitypx x',
      );
      expect(
        fontString(123456789012, 'normal', 'x'),
        'normal 123456789012px x',
      );
    });
  });

  group('_toLeftRightCenter', () {
    test('converts start and end, and others to center', () {
      expect(toLeftRightCenter('start'), 'left');
      expect(toLeftRightCenter('end'), 'right');
      expect(toLeftRightCenter('center'), 'center');
      expect(toLeftRightCenter('left'), 'center');
      expect(toLeftRightCenter('right'), 'center');
      expect(toLeftRightCenter(''), 'center');
    });
  });

  group('_alignStartEnd', () {
    test('returns start, end or the middle', () {
      expect(alignStartEnd('start', 1, 4), 1);
      expect(alignStartEnd('end', 1, 4), 4);
      expect(alignStartEnd('center', 1, 4), 2.5);
      expect(alignStartEnd('left', 1, 4), 2.5);
      expect(alignStartEnd('', 1, 4), 2.5);
      expect(alignStartEnd('center', double.nan, 4), isNaN);
    });
  });

  group('_textX', () {
    test('returns left, right or the middle', () {
      expect(textX('left', 10, 25, false), 10);
      expect(textX('right', 10, 25, false), 25);
      expect(textX('center', 10, 25, false), 17.5);
      expect(textX('start', 10, 25, false), 10);
    });

    test('swaps left and right for rtl', () {
      expect(textX('left', 10, 25, true), 25);
      expect(textX('right', 10, 25, true), 10);
      expect(textX('center', 10, 25, true), 17.5);
      expect(textX('start', 10, 25, true), 10);
    });
  });

  group('_getStartAndCountOfVisiblePoints', () {
    final both = _bounds(2.5, 6.5, minDefined: true, maxDefined: true);
    final gaps = <Object?>[0, null, null, undefined, 4, 5, null, null, 8, 9];
    final gapBounds = _bounds(3.5, 5.5, minDefined: true, maxDefined: true);

    test('returns all points for unsorted data', () {
      final (meta, points) = _visible(_xs, both, sorted: false);
      expect(getStartAndCountOfVisiblePoints(meta, points, false), (
        start: 0,
        count: 10,
      ));
    });

    test('returns all points without user bounds', () {
      final (meta, points) = _visible(
        _xs,
        _bounds(
          double.negativeInfinity,
          double.infinity,
          minDefined: false,
          maxDefined: false,
        ),
      );
      expect(getStartAndCountOfVisiblePoints(meta, points, false), (
        start: 0,
        count: 10,
      ));
    });

    test('limits the points to min and max', () {
      final (meta, points) = _visible(_xs, both);
      expect(getStartAndCountOfVisiblePoints(meta, points, true), (
        start: 2,
        count: 6,
      ));
      expect(getStartAndCountOfVisiblePoints(meta, points, false), (
        start: 2,
        count: 6,
      ));
    });

    test('takes the smaller range of the parsed values and the pixels', () {
      final (meta, points) = _visible(_xs, both, pixel: (value) => value * 5);
      expect(getStartAndCountOfVisiblePoints(meta, points, false), (
        start: 1,
        count: 7,
      ));
    });

    test('limits the points to min or max only', () {
      final (minMeta, minPoints) = _visible(
        _xs,
        _bounds(3, 0, minDefined: true, maxDefined: false),
      );
      expect(getStartAndCountOfVisiblePoints(minMeta, minPoints, true), (
        start: 2,
        count: 8,
      ));
      final (maxMeta, maxPoints) = _visible(
        _xs,
        _bounds(0, 3, minDefined: false, maxDefined: true),
      );
      expect(getStartAndCountOfVisiblePoints(maxMeta, maxPoints, true), (
        start: 0,
        count: 4,
      ));
    });

    test('keeps the last points for bounds after the data', () {
      final (meta, points) = _visible(
        _xs,
        _bounds(20, 30, minDefined: true, maxDefined: true),
      );
      expect(getStartAndCountOfVisiblePoints(meta, points, true), (
        start: 8,
        count: 2,
      ));
    });

    test('returns no points for empty data', () {
      final (meta, points) = _visible(const [], both, xs: const []);
      expect(getStartAndCountOfVisiblePoints(meta, points, true), (
        start: 0,
        count: 0,
      ));
    });

    test('extends the range to the next defined values for spanGaps', () {
      final (meta, points) = _visible(
        gaps,
        gapBounds,
        dataset: _Dataset({'spanGaps': true}),
      );
      expect(getStartAndCountOfVisiblePoints(meta, points, true), (
        start: 0,
        count: 9,
      ));
    });

    test('does not extend the range for a falsy or missing spanGaps', () {
      for (final dataset in [
        _Dataset({'spanGaps': false}),
        _Dataset({}),
        _Dataset(null),
        null,
      ]) {
        final (meta, points) = _visible(gaps, gapBounds, dataset: dataset);
        expect(getStartAndCountOfVisiblePoints(meta, points, true), (
          start: 3,
          count: 4,
        ));
      }
    });

    test('reads vScale only for spanGaps', () {
      // Upstream destructures `vScale` and reads `vScale.axis` only in the
      // spanGaps callbacks. Thus a meta without a vScale gives a result.
      final meta = _Meta(
        iScale: _Scale(bounds: both),
        parsed: [
          for (final x in _xs) {'x': x, 'y': x},
        ],
      );
      final points = [
        for (final x in _xs) _Point(x * 10, x),
      ];
      expect(getStartAndCountOfVisiblePoints(meta, points, true), (
        start: 2,
        count: 6,
      ));
    });

    test('does not extend the range when no value is defined', () {
      final (meta, points) = _visible(
        [for (final _ in _xs) null],
        gapBounds,
        dataset: _Dataset({'spanGaps': 1}),
      );
      expect(getStartAndCountOfVisiblePoints(meta, points, true), (
        start: 3,
        count: 4,
      ));
    });
  });

  group('_scaleRangesChanged', () {
    test('stores the ranges and reports a change', () {
      final xScale = _Scale(max: 10);
      final yScale = _Scale(min: -1, max: 1);
      final meta = _Meta(xScale: xScale, yScale: yScale);
      ScaleRanges ranges() => meta.scaleRanges!;
      List<double> values() => [
        ranges().xmin,
        ranges().xmax,
        ranges().ymin,
        ranges().ymax,
      ];

      expect(scaleRangesChanged(meta), isTrue);
      expect(values(), [0, 10, -1, 1]);
      final stored = ranges();

      expect(scaleRangesChanged(meta), isFalse);
      expect(values(), [0, 10, -1, 1]);

      xScale.min = 2;
      expect(scaleRangesChanged(meta), isTrue);
      expect(values(), [2, 10, -1, 1]);

      yScale.max = 5;
      expect(scaleRangesChanged(meta), isTrue);
      expect(values(), [2, 10, -1, 5]);

      // Object.assign keeps the stored object.
      expect(identical(ranges(), stored), isTrue);
    });

    test('compares with !==: 0 equals -0, NaN differs from NaN', () {
      final xScale = _Scale(max: 10);
      final meta = _Meta(xScale: xScale, yScale: _Scale(min: -1, max: 5));
      expect(scaleRangesChanged(meta), isTrue);

      xScale.min = -0.0;
      expect(scaleRangesChanged(meta), isFalse);
      expect(meta.scaleRanges!.xmin.isNegative, isTrue);

      xScale.min = double.nan;
      expect(scaleRangesChanged(meta), isTrue);
      expect(meta.scaleRanges!.xmin, isNaN);
      expect(scaleRangesChanged(meta), isTrue);
    });
  });

  group('platform-request-anim-frame', () {
    testWidgets('runs the callback in the next frame', (tester) async {
      final calls = <String>[];
      final id = requestAnimFrame(() => calls.add('a'));
      expect(id, isPositive);
      expect(calls, isEmpty);
      await tester.pump();
      expect(calls, ['a']);
      await tester.pump();
      expect(calls, ['a']);
    });

    testWidgets('runs the callbacks in registration order', (tester) async {
      final calls = <String>[];
      requestAnimFrame(() {
        calls.add('a');
        requestAnimFrame(() => calls.add('c'));
      });
      requestAnimFrame(() => calls.add('b'));
      await tester.pump();
      expect(calls, ['a', 'b']);
      await tester.pump();
      expect(calls, ['a', 'b', 'c']);
    });

    testWidgets('runs the microtasks after all the frame callbacks', (
      tester,
    ) async {
      final calls = <String>[];
      requestAnimFrame(() {
        calls.add('a');
        scheduleMicrotask(() => calls.add('micro'));
      });
      requestAnimFrame(() => calls.add('b'));
      await tester.pump();
      // A browser runs the microtask after each requestAnimationFrame
      // callback and gives ['a', 'micro', 'b'].
      expect(calls, ['a', 'b', 'micro']);
    });

    testWidgets('returns the id of the frame callback', (tester) async {
      final calls = <String>[];
      final id = requestAnimFrame(() => calls.add('a'));
      SchedulerBinding.instance.cancelFrameCallbackWithId(id);
      await tester.pump();
      expect(calls, isEmpty);
    });
  });

  group('throttled', () {
    testWidgets('calls fn once per frame with the latest args', (
      tester,
    ) async {
      final calls = <Object?>[];
      final throttledFn = throttled<Object?>(calls.add)
        ..call('a')
        ..call('b')
        ..call(null);
      expect(calls, isEmpty);
      await tester.pump();
      expect(calls, [null]);

      throttledFn(('c', 1));
      await tester.pump();
      expect(calls, [null, ('c', 1)]);
      await tester.pump();
      expect(calls, [null, ('c', 1)]);
    });

    testWidgets('throttles each function on its own', (tester) async {
      final calls = <String>[];
      final first = throttled<String>((args) => calls.add('first $args'));
      final second = throttled<String>((args) => calls.add('second $args'));
      second('a');
      first('b');
      second('c');
      first('d');
      await tester.pump();
      expect(calls, ['second c', 'first d']);
    });
  });

  group('js-semantics-debounce-args', () {
    testWidgets('gives fn the latest argument after the delay', (
      tester,
    ) async {
      final calls = <Object?>[];
      final debounced = debounce<Object?>(calls.add, 50);
      expect(debounced('a'), 50);
      await tester.pump(const Duration(milliseconds: 20));
      expect(debounced('b'), 50);
      await tester.pump(const Duration(milliseconds: 49));
      expect(calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      // Upstream gives fn the argument array ['b'].
      expect(calls, ['b']);
    });

    testWidgets('calls fn at once for a delay of 0, -0 and NaN', (
      tester,
    ) async {
      final calls = <Object?>[];
      expect(debounce<Object?>(calls.add, 0)('resize'), 0);
      expect(calls, ['resize']);
      // A double literal keeps the sign of the zero.
      // ignore: prefer_int_literals
      expect(debounce<Object?>(calls.add, -0.0)('zero').isNegative, isTrue);
      expect(calls, ['resize', 'zero']);
      expect(debounce<Object?>(calls.add, double.nan)('attach'), isNaN);
      expect(calls, ['resize', 'zero', 'attach']);
    });

    testWidgets('delays fn for a delay of 0.5, -5 and infinity', (
      tester,
    ) async {
      final calls = <Object?>[];
      expect(debounce<Object?>(calls.add, 0.5)('a'), 0.5);
      expect(debounce<Object?>(calls.add, -5)('b'), -5);
      expect(
        debounce<Object?>(calls.add, double.infinity)('c'),
        double.infinity,
      );
      expect(calls, isEmpty);
      // ToInt32 gives 0, -5 and 0 ms. Timer treats a negative duration as
      // zero, as setTimeout does. Thus all three calls wait for the next turn
      // of the event loop.
      await tester.pump(Duration.zero);
      expect(calls, ['a', 'b', 'c']);
    });

    testWidgets('converts a large delay with ToInt32', (tester) async {
      final calls = <Object?>[];
      // ToInt32(2^32 + 50) is 50.
      expect(debounce<Object?>(calls.add, 4294967346)('x'), 4294967346);
      await tester.pump(const Duration(milliseconds: 49));
      expect(calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(calls, ['x']);

      // ToInt32(2^31) is -2^31, a negative duration: a zero wait.
      expect(debounce<Object?>(calls.add, 2147483648)('y'), 2147483648);
      expect(calls, ['x']);
      await tester.pump(Duration.zero);
      expect(calls, ['x', 'y']);
    });
  });

  group('platform-debounce-cancel', () {
    testWidgets('cancel() drops the pending call', (tester) async {
      final calls = <Object?>[];
      final debounced = debounce<Object?>(calls.add, 50)..call('a');
      await tester.pump(const Duration(milliseconds: 10));
      debounced.cancel();
      await tester.pump(const Duration(milliseconds: 60));
      expect(calls, isEmpty);

      // The function stays usable after cancel().
      debounced('b');
      await tester.pump(const Duration(milliseconds: 50));
      expect(calls, ['b']);
    });

    testWidgets('cancel() does nothing without a pending call', (
      tester,
    ) async {
      final calls = <Object?>[];
      final debounced = debounce<Object?>(calls.add, 0)..cancel();
      debounced('a');
      debounced.cancel();
      expect(calls, ['a']);
    });
  });
}
