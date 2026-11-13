// Original code, not ported from Chart.js: segment cases with no spec.
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/elements/element.point.dart'
    as element_point;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart' show pi;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableLineSegmentContext;
import 'package:flutter_chartjs_port/src/helpers/helpers.segment.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:flutter_chartjs_port/src/types/line_segment_style.dart';
import 'package:test/test.dart';

// Upstream behaviour that test/specs/helpers.segment.tests.js does not check
// (AGENTS.md rule 3): _computeSegments, _boundSegments, the angle property
// and the segment styles. The expected values come from
// src/helpers/helpers.segment.js at v4.5.1 in Node.js v24.12.0 on x64.

/// A point element `{x, y, skip, stop}`. `null` stands for JS `undefined`,
/// and NaN for the `undefined` of a control point (`SplinePoint`).
final class _Point(
  @override final double x,
  @override final double y, {
  @override final bool? skip,
  @override final bool? stop,
}) implements PointElement {
  @override
  Map<String, Object?>? get options => null;

  @override
  double cp1x = double.nan;

  @override
  double cp1y = double.nan;

  @override
  double cp2x = double.nan;

  @override
  double cp2y = double.nan;

  // The members of Chart.js ADR 0028 that this test does not read.
  @override
  bool get active => false;

  @override
  Object? get hidden => undefined;

  @override
  double size([Object? options]) => throw UnsupportedError('size');
}

/// A radar point element `{x: 0, y: 0, angle}`. The control points are NaN,
/// which stands for JS `undefined` (`SplinePoint`).
final class _RadialPoint(@override final double? angle)
    implements RadialPointElement {
  @override
  double get x => 0;

  @override
  double get y => 0;

  @override
  bool? get skip => null;

  @override
  bool? get stop => null;

  @override
  Map<String, Object?>? get options => null;

  @override
  double cp1x = double.nan;

  @override
  double cp1y = double.nan;

  @override
  double cp2x = double.nan;

  @override
  double cp2y = double.nan;

  // The members of Chart.js ADR 0028 that this test does not read.
  @override
  bool get active => false;

  @override
  Object? get hidden => undefined;

  @override
  double size([Object? options]) => throw UnsupportedError('size');
}

/// The points of a pattern: `o` is a point, `s` a skipped point and `t` a
/// `stop` point. Point `i` is `{x: i * 10, y: i}`.
List<PointElement> _points(String pattern) => [
  for (var i = 0; i < pattern.length; i++)
    _Point(
      i * 10.0,
      i.toDouble(),
      skip: pattern[i] == 's' ? true : null,
      stop: pattern[i] == 't' ? true : null,
    ),
];

/// A JavaScript object `{getContext}`, passed as a [Chart].
final class _Chart() implements Chart {
  @override
  Map<String, Object?> getContext() => {'chart': 'c', 'type': 'chart'};

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A JavaScript object `{points, options, _chart, _loop, _fullLoop,
/// _datasetIndex, segments}`, passed as a [LineElement]. The options get
/// `spanGaps: false` first, as in the probe.
final class _Line(
  @override final List<PointElement> points, {
  Map<String, Object?> options = const {},
  @override final Chart? chart,
  @override final bool? loop,
  @override final bool? fullLoop,
  @override final int? datasetIndex,
}) implements LineElement {
  @override
  final Map<String, Object?> options = {'spanGaps': false, ...options};

  @override
  List<Segment> segments = const [];

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A JavaScript object literal `{start, end, loop, style}`, passed as a
/// [Segment].
final class const _Segment(
  @override final double start,
  @override final double end, {
  @override required final bool loop,
  @override final Object? style,
}) implements Segment;

/// A gradient object. Its JS `toString()` tag is `[object CanvasGradient]`.
ChartGradient _gradient() => ChartGradient.linear(
  ui.Offset.zero,
  const ui.Offset(1, 1),
  List<ui.Color>.empty(growable: true),
);

/// SameValue on a number: `-0` does not equal `0`.
Matcher _sameValue(double expected) => predicate<double>(
  (actual) => actual == expected && actual.isNegative == expected.isNegative,
  'SameValue ${jsNumberToString(expected)}',
);

/// A segment `{start, end, loop, style}`. The default [style] is `isNull`,
/// the JS `undefined` of [Segment.style]. A [SegmentStyle] compares with
/// its `==`.
Matcher _segment(double start, double end, bool loop, [Object? style]) =>
    isA<Segment>()
        .having((s) => s.start, 'start', _sameValue(start))
        .having((s) => s.end, 'end', _sameValue(end))
        .having((s) => s.loop, 'loop', loop)
        .having((s) => s.style, 'style', style ?? isNull);

/// The base options of the style cases.
const AnyObject _base = {
  'borderColor': ChartPaint.solid(ui.Color.fromRGBO(0, 0, 255, 1)),
  'borderWidth': 3.0,
};

void main() {
  group('computeSegments', () {
    test('gives no segment for no points', () {
      expect(computeSegments(_Line([])), <Matcher>[]);
    });

    test('gives one segment for points without gaps', () {
      expect(computeSegments(_Line(_points('ooooo'))), [_segment(0, 4, false)]);
    });

    test('splits at a skipped point', () {
      expect(computeSegments(_Line(_points('oosoo'))), [
        _segment(0, 1, false),
        _segment(3, 4, false),
      ]);
    });

    test('spans a skipped point with spanGaps true', () {
      expect(
        computeSegments(
          _Line(_points('oosoo'), options: const {'spanGaps': true}),
        ),
        [_segment(0, 4, false)],
      );
    });

    test('leaves out the skipped points at the ends', () {
      expect(
        computeSegments(
          _Line(_points('sooos'), options: const {'spanGaps': true}),
        ),
        [_segment(1, 3, false)],
      );
      expect(computeSegments(_Line(_points('sooos'))), [_segment(1, 3, false)]);
    });

    test('gives a loop only for a full loop', () {
      expect(
        computeSegments(_Line(_points('ooooo'), loop: true, fullLoop: true)),
        [_segment(0, 4, true)],
      );
      expect(computeSegments(_Line(_points('ooooo'), loop: true)), [
        _segment(0, 4, false),
      ]);
    });

    test('starts a loop after its first gap', () {
      expect(
        computeSegments(_Line(_points('oosoo'), loop: true, fullLoop: true)),
        [_segment(3, 1, false)],
      );
      expect(
        computeSegments(
          _Line(
            _points('oosoo'),
            options: const {'spanGaps': true},
            loop: true,
            fullLoop: true,
          ),
        ),
        [_segment(0, 4, true)],
      );
    });

    test('splits at a stop point', () {
      expect(computeSegments(_Line(_points('ootoo'))), [
        _segment(0, 1, false),
        _segment(2, 4, false),
      ]);
    });

    test('starts at 0 after a skipped point and a stop point', () {
      // solidSegments sets start to null, and null % count is 0.
      expect(computeSegments(_Line(_points('ostoso'))), [
        _segment(0, 0, false),
        _segment(0, 3, false),
        _segment(5, 5, false),
      ]);
      expect(computeSegments(_Line(_points('ostoo'))), [
        _segment(0, 0, false),
        _segment(0, 4, false),
      ]);
    });

    test('treats a number spanGaps as truthy, and not as true', () {
      expect(
        computeSegments(
          _Line(_points('oosoo'), options: const {'spanGaps': 2.0}, loop: true),
        ),
        [_segment(0, 1, false), _segment(3, 4, false)],
      );
    });

    test('gives one segment when all points are skipped', () {
      expect(computeSegments(_Line(_points('sss'))), [_segment(0, 0, false)]);
    });
  });

  group('boundSegments', () {
    final line = _Line(_points('oosoooo'));
    line.segments = computeSegments(line);

    test('bounds each segment of the line', () {
      expect(boundSegments(line, (property: 'x', start: 5, end: 45)), [
        _segment(0, 1, false),
        _segment(3, 5, false),
      ]);
      expect(boundSegments(line, (property: 'y', start: 3.5, end: 9)), [
        _segment(3, 6, false),
      ]);
    });

    test('gives the segments of the line without bounds', () {
      expect(boundSegments(line), [
        _segment(0, 1, false),
        _segment(3, 6, false),
      ]);
    });
  });

  group('boundSegment', () {
    final radial = [
      for (var i = 0; i < 6; i++) _RadialPoint(-pi / 2 + i * 2 * pi / 6),
    ];

    test('bounds the angle of a loop', () {
      const loop = _Segment(0, 5, loop: true);
      expect(
        boundSegment(loop, radial, (property: 'angle', start: 0.5, end: 2.5)),
        [_segment(1, 4, false)],
      );
      expect(
        boundSegment(loop, radial, (property: 'angle', start: 5, end: 1)),
        [_segment(0, 3, false)],
      );
    });

    test('bounds the angle of a segment that is not a loop', () {
      expect(
        boundSegment(const _Segment(0, 5, loop: false), radial, (
          property: 'angle',
          start: 3,
          end: 6,
        )),
        [_segment(0, 2, false), _segment(4, 5, false)],
      );
    });

    test('finds no angle on a point without one', () {
      expect(
        boundSegment(
          const _Segment(0, 2, loop: false),
          [_Point(1, 1), _Point(2, 2), _Point(3, 3), _RadialPoint(null)],
          (property: 'angle', start: 0, end: 7),
        ),
        <Matcher>[],
      );
    });

    test('bounds x on a loop', () {
      expect(
        boundSegment(const _Segment(3, 2, loop: true), _points('ooooo'), (
          property: 'x',
          start: 15,
          end: 35,
        )),
        [_segment(1, 4, false), _segment(4, 0, false)],
      );
      expect(
        boundSegment(const _Segment(0, 4, loop: true), _points('ooooo'), (
          property: 'x',
          start: 0,
          end: 40,
        )),
        [_segment(0, 4, true)],
      );
    });

    test('keeps the style of the segment', () {
      final style = <String, Object?>{'a': 1.0};
      expect(
        boundSegment(
          _Segment(0, 4, loop: false, style: style),
          _points('ooooo'),
          (property: 'x', start: 10, end: 20),
        ),
        [_segment(1, 2, false, same(style))],
      );
    });

    test('ignores skipped points', () {
      expect(
        boundSegment(const _Segment(0, 4, loop: false), _points('oosoo'), (
          property: 'x',
          start: 0,
          end: 40,
        )),
        [_segment(0, 4, false)],
      );
    });

    test('takes -0 and 0 as the same value', () {
      expect(
        boundSegment(
          const _Segment(0, 2, loop: false),
          // The double literal keeps the sign of -0.
          // ignore: prefer_int_literals
          [_Point(-0.0, 0), _Point(0, 0), _Point(1, 0)],
          (property: 'x', start: 0, end: 0),
        ),
        [_segment(0, 0, false)],
      );
    });

    test('skips the points of an undefined x, as upstream', () {
      // Upstream normalize keeps `undefined` for 'x' (helpers.segment.js:22),
      // and `undefined === undefined` is true, also for the first
      // prevValue. The x getter of an element gives NaN for `undefined`.
      // Upstream gives [{start: 0, end: 3}] and [{start: 1, end: 4}] (the
      // pinned helpers.segment.js and element.point.ts, x64 Node.js
      // v24.12.0).
      expect(
        boundSegment(
          const _Segment(0, 3, loop: false),
          [
            element_point.PointElement({'y': 0}),
            element_point.PointElement({'y': 1}),
            element_point.PointElement({'x': 5, 'y': 2}),
            element_point.PointElement({'x': 20, 'y': 3}),
          ],
          (property: 'x', start: 0, end: 10),
        ),
        [_segment(0, 3, false)],
      );
      expect(
        boundSegment(
          const _Segment(0, 4, loop: false),
          [
            element_point.PointElement({'x': 0, 'y': 0}),
            element_point.PointElement({'y': 1}),
            element_point.PointElement({'y': 2}),
            element_point.PointElement({'x': 5, 'y': 3}),
            element_point.PointElement({'x': 20, 'y': 4}),
          ],
          (property: 'x', start: 4, end: 10),
        ),
        [_segment(1, 4, false)],
      );
    });

    test('takes a NaN x apart from an undefined x', () {
      // `NaN === NaN` and `NaN === undefined` are false. Upstream gives
      // [{start: 1, end: 3}] for both lists (x64 Node.js v24.12.0).
      expect(
        boundSegment(
          const _Segment(0, 3, loop: false),
          [
            element_point.PointElement({'x': double.nan, 'y': 0}),
            element_point.PointElement({'x': double.nan, 'y': 1}),
            element_point.PointElement({'x': 5, 'y': 2}),
            element_point.PointElement({'x': 20, 'y': 3}),
          ],
          (property: 'x', start: 0, end: 10),
        ),
        [_segment(1, 3, false)],
      );
      expect(
        boundSegment(
          const _Segment(0, 3, loop: false),
          [
            element_point.PointElement({'y': 0}),
            element_point.PointElement({'x': double.nan, 'y': 1}),
            element_point.PointElement({'x': 5, 'y': 2}),
            element_point.PointElement({'x': 20, 'y': 3}),
          ],
          (property: 'x', start: 0, end: 10),
        ),
        [_segment(1, 3, false)],
      );
    });

    test('gives no segment for a property other than x, y and angle', () {
      // JS reads `undefined` for the absent property, and the upstream gives
      // [] with and without loop (x64 Node.js v24.12.0).
      for (final loop in [false, true]) {
        expect(
          boundSegment(_Segment(0, 2, loop: loop), _points('ooo'), (
            property: 'r',
            start: 0,
            end: 1,
          )),
          isEmpty,
        );
      }
    });
  });

  group('segment styles', () {
    final chart = _Chart();
    const blue = ChartPaint.solid(ui.Color.fromRGBO(0, 0, 255, 1));
    const red = ChartPaint.solid(ui.Color.fromRGBO(255, 0, 0, 1));

    test('splits the line where the style changes', () {
      final contexts = <ScriptableLineSegmentContext>[];
      final segmentOptions = LineSegmentStyle(
        borderColor: (s) {
          contexts.add(s);
          return s.p0.y >= 2 ? red : blue;
        },
      );
      final line = _Line(
        _points('oooooo'),
        options: _base,
        chart: chart,
        datasetIndex: 1,
      );
      expect(computeSegments(line, segmentOptions), [
        _segment(0, 2, false, const SegmentStyle(borderColor: blue)),
        _segment(2, 5, false, const SegmentStyle(borderColor: red)),
      ]);
      final ctx = contexts[0];
      expect(jsObjectKeys(ctx), [
        'type',
        'p0',
        'p1',
        'p0DataIndex',
        'p1DataIndex',
        'datasetIndex',
      ]);
      expect(ctx['chart'], 'c');
      expect(ctx['type'], 'segment');
      expect(ctx.p0, same(line.points[0]));
      expect(ctx.p1, same(line.points[1]));
      expect(ctx.p0DataIndex, 0);
      expect(ctx.p1DataIndex, 1);
      expect(ctx.datasetIndex, 1);
      expect(ctx['p0'], same(line.points[0]));
      expect(ctx['p1DataIndex'], 1);
      expect(contexts.map((s) => s.p1DataIndex), [1, 2, 3, 4, 5]);
    });

    test('gives undefined as the datasetIndex of a line without one', () {
      final contexts = <ScriptableLineSegmentContext>[];
      computeSegments(
        _Line(_points('ooo'), options: _base, chart: chart),
        LineSegmentStyle(
          borderWidth: (s) {
            contexts.add(s);
            return null;
          },
        ),
      );
      expect(jsObjectKeys(contexts[0]), contains('datasetIndex'));
      expect(contexts[0]['datasetIndex'], same(undefined));
    });

    test('calls the functions in the key order of readStyle', () {
      // helpers.segment.js:337-347: the order of the keys of the literal.
      final calls = <String>[];
      T? Function(ScriptableLineSegmentContext) record<T>(String name) => (s) {
        calls.add('$name ${s.p0DataIndex}');
        return null;
      };
      computeSegments(
        _Line(_points('ooo'), options: _base, chart: chart),
        LineSegmentStyle(
          borderColor: record('borderColor'),
          backgroundColor: record('backgroundColor'),
          borderWidth: record('borderWidth'),
          borderDash: record('borderDash'),
          borderDashOffset: record('borderDashOffset'),
          borderCapStyle: record('borderCapStyle'),
          borderJoinStyle: record('borderJoinStyle'),
        ),
      );
      expect(calls, [
        for (final i in [0, 1]) ...[
          'backgroundColor $i',
          'borderCapStyle $i',
          'borderDash $i',
          'borderDashOffset $i',
          'borderJoinStyle $i',
          'borderWidth $i',
          'borderColor $i',
        ],
      ]);
    });

    test('moves the style ends off skipped points', () {
      final redAt2 = LineSegmentStyle(
        borderColor: (s) => s.p0DataIndex == 2 ? red : blue,
      );
      expect(
        computeSegments(
          _Line(
            _points('oosooo'),
            options: {..._base, 'spanGaps': true},
            chart: chart,
          ),
          redAt2,
        ),
        [
          _segment(0, 1, false, const SegmentStyle(borderColor: blue)),
          _segment(1, 3, false, const SegmentStyle(borderColor: red)),
          _segment(3, 5, false, const SegmentStyle(borderColor: blue)),
        ],
      );
      expect(
        computeSegments(
          _Line(_points('oosooo'), options: _base, chart: chart),
          redAt2,
        ),
        [
          _segment(0, 1, false, const SegmentStyle(borderColor: blue)),
          _segment(3, 5, false, const SegmentStyle(borderColor: blue)),
        ],
      );
      final redTo3 = LineSegmentStyle(
        borderColor: (s) => s.p1DataIndex == 3 ? red : blue,
      );
      expect(
        computeSegments(
          _Line(
            _points('oosooo'),
            options: {..._base, 'spanGaps': true},
            chart: chart,
          ),
          redTo3,
        ),
        [
          _segment(0, 1, false, const SegmentStyle(borderColor: blue)),
          _segment(1, 3, false, const SegmentStyle(borderColor: red)),
          _segment(3, 5, false, const SegmentStyle(borderColor: blue)),
        ],
      );
    });

    test('keeps the loop flag of a loop', () {
      expect(
        computeSegments(
          _Line(
            _points('oooo'),
            options: _base,
            chart: chart,
            loop: true,
            fullLoop: true,
          ),
          LineSegmentStyle(borderColor: (s) => s.p0DataIndex == 2 ? red : blue),
        ),
        [
          _segment(0, 2, true, const SegmentStyle(borderColor: blue)),
          _segment(2, 3, true, const SegmentStyle(borderColor: red)),
        ],
      );
    });

    test('a null result keeps the line style, as undefined does', () {
      // A null result is the `undefined` of a key that the segment options
      // do not resolve: the style holds `undefined`, and the draw takes the
      // value of the line options.
      expect(
        computeSegments(
          _Line(_points('oooo'), options: _base, chart: chart),
          LineSegmentStyle(
            borderDash: (s) => s.p0DataIndex == 1 ? null : [2.0, 3.0],
          ),
        ),
        [
          _segment(0, 1, false, const SegmentStyle(borderDash: [2.0, 3.0])),
          _segment(1, 2, false, const SegmentStyle()),
          _segment(2, 3, false, const SegmentStyle(borderDash: [2.0, 3.0])),
        ],
      );
    });

    test('compares lists item by item, and NaN as NaN', () {
      // JSON.stringify writes two equal arrays the same, and each NaN as
      // null.
      expect(
        computeSegments(
          _Line(_points('oooo'), options: _base, chart: chart),
          LineSegmentStyle(
            borderDash: (s) => [2.0, 3.0],
            borderWidth: (s) => double.nan,
          ),
        ),
        [
          _segment(
            0,
            3,
            false,
            const SegmentStyle(borderDash: [2.0, 3.0], borderWidth: double.nan),
          ),
        ],
      );
    });

    for (final (name, style) in [
      (
        'borderCapStyle',
        LineSegmentStyle(
          borderCapStyle: (s) =>
              s.p0DataIndex == 1 ? ui.StrokeCap.round : ui.StrokeCap.butt,
        ),
      ),
      (
        'borderJoinStyle',
        LineSegmentStyle(
          borderJoinStyle: (s) =>
              s.p0DataIndex == 1 ? ui.StrokeJoin.round : ui.StrokeJoin.bevel,
        ),
      ),
    ]) {
      test('splits where only $name changes', () {
        // JSON.stringify writes the two keywords of upstream apart. The old
        // JSON emulation of the port wrote `{}` for each enum value, and
        // gave one segment here.
        expect(
          [
            for (final s in computeSegments(
              _Line(_points('oooo'), options: _base, chart: chart),
              style,
            ))
              [s.start, s.end, s.loop],
          ],
          [
            [0.0, 1.0, false],
            [1.0, 2.0, false],
            [2.0, 3.0, false],
          ],
        );
      });
    }

    Matcher background(Object paint) => isA<SegmentStyle>().having(
      (s) => s.backgroundColor,
      'backgroundColor',
      same(paint),
    );

    test('compares gradients by identity', () {
      final g1 = _gradient();
      final g2 = _gradient();
      final line = _Line(
        _points('oooo'),
        options: {..._base, 'backgroundColor': g1},
        chart: chart,
      );
      expect(
        computeSegments(
          line,
          LineSegmentStyle(
            backgroundColor: (s) => s.p0DataIndex == 1 ? g2 : g1,
          ),
        ),
        [
          _segment(0, 1, false, background(g1)),
          _segment(1, 2, false, background(g2)),
          _segment(2, 3, false, background(g1)),
        ],
      );
      expect(
        computeSegments(line, LineSegmentStyle(backgroundColor: (s) => g1)),
        hasLength(1),
      );
    });

    test('a color of the line options that is not a paint throws', () {
      expect(
        () => computeSegments(
          _Line(
            _points('oooo'),
            options: {..._base, 'backgroundColor': 0.0},
            chart: chart,
          ),
          LineSegmentStyle(borderWidth: (s) => 1),
        ),
        throwsArgumentError,
      );
    });

    test('does not split without a segment style', () {
      expect(
        computeSegments(_Line(_points('oooo'), options: _base, chart: chart)),
        [_segment(0, 3, false)],
      );
      expect(
        computeSegments(
          _Line(_points('oooo'), options: _base, chart: chart),
          const LineSegmentStyle(),
        ),
        [_segment(0, 3, false)],
      );
    });
  });

  group('SegmentStyle ==', () {
    test('compares a gradient by identity and a solid paint by color', () {
      final g = _gradient();
      expect(SegmentStyle(borderColor: g), SegmentStyle(borderColor: g));
      expect(
        SegmentStyle(borderColor: g),
        isNot(SegmentStyle(borderColor: _gradient())),
      );
      expect(
        const SegmentStyle(
          borderColor: ChartPaint.solid(ui.Color.fromRGBO(1, 2, 3, 1)),
        ),
        const SegmentStyle(
          borderColor: ChartPaint.solid(ui.Color.fromRGBO(1, 2, 3, 1)),
        ),
      );
    });

    test('tells undefined from null', () {
      expect(const SegmentStyle(), isNot(const SegmentStyle(borderDash: null)));
    });

    test('gives equal hash codes for equal styles', () {
      const a = SegmentStyle(borderDash: [1.0, 2.0], borderWidth: double.nan);
      const b = SegmentStyle(borderDash: [1.0, 2.0], borderWidth: double.nan);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
