// Original code, not ported from Chart.js: segment cases with no spec.
import 'package:flutter_chartjs_port/src/elements/element.point.dart'
    as element_point;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart' show pi;
import 'package:flutter_chartjs_port/src/helpers/helpers.segment.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/color.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:test/test.dart';

// Upstream behaviour that test/specs/helpers.segment.tests.js does not check
// (AGENTS.md rule 3): _computeSegments, _boundSegments, the angle property
// and the segment styles. The expected values come from
// src/helpers/helpers.segment.js at v4.5.1 in Node.js v24.12.0 on x64.

/// A point element `{x, y, skip, stop}`. `null` stands for JS `undefined`,
/// and NaN for the `undefined` of a control point (`SplinePoint`).
final class _Point implements PointElement {
  _Point(this.x, this.y, {this.skip, this.stop});

  @override
  final double x;

  @override
  final double y;

  @override
  final bool? skip;

  @override
  final bool? stop;

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
  double size([Map<String, Object?>? options]) =>
      throw UnsupportedError('size');
}

/// A radar point element `{x: 0, y: 0, angle}`. The control points are NaN,
/// which stands for JS `undefined` (`SplinePoint`).
final class _RadialPoint implements RadialPointElement {
  _RadialPoint(this.angle);

  @override
  final double? angle;

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
  double size([Map<String, Object?>? options]) =>
      throw UnsupportedError('size');
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
final class _Chart implements Chart {
  @override
  Map<String, Object?> getContext() => {'chart': 'c', 'type': 'chart'};

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A JavaScript object `{points, options, _chart, _loop, _fullLoop,
/// _datasetIndex, segments}`, passed as a [LineElement]. The options get
/// `spanGaps: false` first, as in the probe.
final class _Line implements LineElement {
  _Line(
    this.points, {
    Map<String, Object?> options = const {},
    this.chart,
    this.loop,
    this.fullLoop,
    this.datasetIndex,
  }) : options = {'spanGaps': false, ...options};

  @override
  final List<PointElement> points;

  @override
  final Map<String, Object?> options;

  @override
  final Chart? chart;

  @override
  final bool? loop;

  @override
  final bool? fullLoop;

  @override
  final double? datasetIndex;

  @override
  List<Segment> segments = const [];

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A JavaScript object literal `{start, end, loop, style}`, passed as a
/// [Segment].
final class _Segment implements Segment {
  const _Segment(this.start, this.end, {required this.loop, this.style});

  @override
  final double start;

  @override
  final double end;

  @override
  final bool loop;

  @override
  final Object? style;
}

/// A gradient object. Its JS `toString()` tag is `[object CanvasGradient]`.
final class _Gradient implements CanvasGradient {
  @override
  void addColorStop(double offset, String color) {}
}

/// An object of a class, which `JSON.stringify` writes with its own
/// enumerable properties.
final class _Leaf {
  const _Leaf(this.v);

  final double v;
}

/// SameValue on a number: `-0` does not equal `0`.
Matcher _sameValue(double expected) => predicate<double>(
  (actual) => actual == expected && actual.isNegative == expected.isNegative,
  'SameValue ${jsNumberToString(expected)}',
);

/// A segment `{start, end, loop, style}`. The default [style] is `isNull`,
/// the JS `undefined` of [Segment.style].
Matcher _segment(double start, double end, bool loop, [Object? style]) =>
    isA<Segment>()
        .having((s) => s.start, 'start', _sameValue(start))
        .having((s) => s.end, 'end', _sameValue(end))
        .having((s) => s.loop, 'loop', loop)
        .having((s) => s.style, 'style', style ?? isNull);

/// The base options of the style cases.
const AnyObject _base = {'borderColor': 'blue', 'borderWidth': 3.0};

/// The `readStyle` object (helpers.segment.js:337) of [_base] with the given
/// values.
Matcher _style({
  Object? backgroundColor = undefined,
  Object? borderDash = undefined,
  Object? borderWidth = 3.0,
  Object? borderColor = 'blue',
}) => equals(<String, Object?>{
  'backgroundColor': backgroundColor,
  'borderCapStyle': undefined,
  'borderDash': borderDash,
  'borderDashOffset': undefined,
  'borderJoinStyle': undefined,
  'borderWidth': borderWidth,
  'borderColor': borderColor,
});

/// The point of a segment context: `ctx.p0`.
PointElement _p0(Object? ctx) => (ctx! as AnyObject)['p0']! as PointElement;

/// The data index of a segment context: `ctx.p0DataIndex`.
Object? _p0DataIndex(Object? ctx) => (ctx! as AnyObject)['p0DataIndex'];

void main() {
  group('computeSegments', () {
    test('gives no segment for no points', () {
      expect(computeSegments(_Line([])), <Matcher>[]);
    });

    test('gives one segment for points without gaps', () {
      expect(computeSegments(_Line(_points('ooooo'))), [
        _segment(0, 4, false),
      ]);
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
      expect(computeSegments(_Line(_points('sooos'))), [
        _segment(1, 3, false),
      ]);
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

    test('splits the line where the style changes', () {
      final contexts = <AnyObject>[];
      final segmentOptions = <String, Object?>{
        'setContext': (AnyObject ctx) {
          contexts.add(ctx);
          return {
            ..._base,
            'borderColor': _p0(ctx).y >= 2 ? 'red' : 'blue',
          };
        },
      };
      final line = _Line(
        _points('oooooo'),
        options: _base,
        chart: chart,
        datasetIndex: 1,
      );
      expect(computeSegments(line, segmentOptions), [
        _segment(0, 2, false, _style()),
        _segment(2, 5, false, _style(borderColor: 'red')),
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
      expect(ctx['p0'], same(line.points[0]));
      expect(ctx['p1'], same(line.points[1]));
      expect(ctx['p0DataIndex'], 0);
      expect(ctx['p1DataIndex'], 1);
      expect(ctx['datasetIndex'], 1);
    });

    test('gives undefined as the datasetIndex of a line without one', () {
      final contexts = <AnyObject>[];
      final segmentOptions = <String, Object?>{
        'setContext': (AnyObject ctx) {
          contexts.add(ctx);
          return _base;
        },
      };
      computeSegments(
        _Line(_points('ooo'), options: _base, chart: chart),
        segmentOptions,
      );
      expect(contexts[0].containsKey('datasetIndex'), isTrue);
      expect(contexts[0]['datasetIndex'], same(undefined));
    });

    test('calls setContext with the segment options as this', () {
      Object? self;
      late final AnyObject segmentOptions;
      segmentOptions = {
        'setContext': JsFunction((Object? thisArg, Object? ctx) {
          self = thisArg;
          return _base;
        }),
      };
      computeSegments(
        _Line(_points('ooo'), options: _base, chart: chart),
        segmentOptions,
      );
      expect(self, same(segmentOptions));
    });

    test('moves the style ends off skipped points', () {
      final redAt2 = <String, Object?>{
        'setContext': (Object? ctx) => {
          ..._base,
          'borderColor': _p0DataIndex(ctx) == 2 ? 'red' : 'blue',
        },
      };
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
          _segment(0, 1, false, _style()),
          _segment(1, 3, false, _style(borderColor: 'red')),
          _segment(3, 5, false, _style()),
        ],
      );
      expect(
        computeSegments(
          _Line(_points('oosooo'), options: _base, chart: chart),
          redAt2,
        ),
        [_segment(0, 1, false, _style()), _segment(3, 5, false, _style())],
      );
      final redTo3 = <String, Object?>{
        'setContext': (Object? ctx) => {
          ..._base,
          'borderColor': (ctx! as AnyObject)['p1DataIndex'] == 3
              ? 'red'
              : 'blue',
        },
      };
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
          _segment(0, 1, false, _style()),
          _segment(1, 3, false, _style(borderColor: 'red')),
          _segment(3, 5, false, _style()),
        ],
      );
    });

    test('keeps the loop flag of a loop', () {
      final redAt2 = <String, Object?>{
        'setContext': (Object? ctx) => {
          ..._base,
          'borderColor': _p0DataIndex(ctx) == 2 ? 'red' : 'blue',
        },
      };
      expect(
        computeSegments(
          _Line(
            _points('oooo'),
            options: _base,
            chart: chart,
            loop: true,
            fullLoop: true,
          ),
          redAt2,
        ),
        [
          _segment(0, 2, true, _style()),
          _segment(2, 3, true, _style(borderColor: 'red')),
        ],
      );
    });

    test('tells null from undefined', () {
      final nullAt1 = <String, Object?>{
        'setContext': (Object? ctx) => {
          ..._base,
          if (_p0DataIndex(ctx) == 1) 'borderDash': null,
        },
      };
      expect(
        computeSegments(
          _Line(_points('oooo'), options: _base, chart: chart),
          nullAt1,
        ),
        [
          _segment(0, 1, false, _style()),
          _segment(1, 2, false, _style(borderDash: null)),
          _segment(2, 3, false, _style()),
        ],
      );
    });

    test('compares the JSON text of the styles', () {
      // JSON.stringify writes NaN as null.
      final nanAt1 = <String, Object?>{
        'setContext': (Object? ctx) => {
          ..._base,
          'borderWidth': _p0DataIndex(ctx) == 1 ? double.nan : null,
        },
      };
      expect(
        computeSegments(
          _Line(
            _points('oooo'),
            options: {..._base, 'borderWidth': null},
            chart: chart,
          ),
          nanAt1,
        ),
        [_segment(0, 3, false, _style(borderWidth: null))],
      );
      final dash = <String, Object?>{
        'setContext': (Object? ctx) => {
          ..._base,
          'borderDash': [2.0, 3.0],
        },
      };
      expect(
        computeSegments(
          _Line(
            _points('oooo'),
            options: {
              ..._base,
              'borderDash': [2.0, 3.0],
            },
            chart: chart,
          ),
          dash,
        ),
        [
          _segment(0, 3, false, _style(borderDash: [2.0, 3.0])),
        ],
      );
    });

    test('compares gradients by identity', () {
      final g1 = _Gradient();
      final g2 = _Gradient();
      final gradients = <String, Object?>{
        'setContext': (Object? ctx) => {
          ..._base,
          'backgroundColor': _p0DataIndex(ctx) == 1 ? g2 : g1,
        },
      };
      final line = _Line(
        _points('oooo'),
        options: {..._base, 'backgroundColor': g1},
        chart: chart,
      );
      expect(computeSegments(line, gradients), [
        _segment(0, 1, false, _style(backgroundColor: same(g1))),
        _segment(1, 2, false, _style(backgroundColor: same(g2))),
        _segment(2, 3, false, _style(backgroundColor: same(g1))),
      ]);
      final sameGradient = <String, Object?>{
        'setContext': (Object? ctx) => {..._base, 'backgroundColor': g1},
      };
      expect(computeSegments(line, sameGradient), hasLength(1));
      // The replacer writes the first gradient as its cache index 0.
      final zero = <String, Object?>{
        'setContext': (Object? ctx) => {
          ..._base,
          'backgroundColor': _p0DataIndex(ctx) == 1 ? 0.0 : g1,
        },
      };
      expect(computeSegments(line, zero), hasLength(1));
    });

    test('compares the JSON text of strings with escapes', () {
      // The style at point 1 is [at1], the style at the other points is
      // [other]. The result is the start, end and loop of each segment.
      List<List<Object>> split(
        AnyObject options,
        AnyObject at1,
        AnyObject other,
      ) {
        final segmentOptions = <String, Object?>{
          'setContext': (Object? ctx) => {
            ..._base,
            ...(_p0DataIndex(ctx) == 1 ? at1 : other),
          },
        };
        return [
          for (final s in computeSegments(
            _Line(
              _points('oooo'),
              options: {..._base, ...options},
              chart: chart,
            ),
            segmentOptions,
          ))
            [s.start, s.end, s.loop],
        ];
      }

      const three = [
        [0.0, 1.0, false],
        [1.0, 2.0, false],
        [2.0, 3.0, false],
      ];
      // Without the escape of '"', both styles would give the text
      // "borderCapStyle":"x","borderDash":"y".
      expect(
        split(
          {'borderCapStyle': 'x', 'borderDash': 'y'},
          {'borderCapStyle': 'x","borderDash":"y'},
          {'borderCapStyle': 'x', 'borderDash': 'y'},
        ),
        three,
      );
      // Without the escape of '\', both styles would give "\u0000".
      expect(
        split(
          {'borderCapStyle': '\u0000'},
          {'borderCapStyle': r'\u0000'},
          {'borderCapStyle': '\u0000'},
        ),
        three,
      );
      // JSON.stringify writes a lone surrogate as \ud800, not as U+FFFD.
      expect(
        split(
          {'borderCapStyle': '\uD800'},
          {'borderCapStyle': '�'},
          {'borderCapStyle': '\uD800'},
        ),
        three,
      );
      // Equal strings that are not the same object give the same text.
      for (final value in [
        'a"b',
        r'a\b',
        '\u0000\b\t\n\f\r\u001f\u007f',
        '\uD800',
        'x\uDC00',
        '😀',
        'é€',
      ]) {
        AnyObject copy() => {
          'borderCapStyle': String.fromCharCodes(value.codeUnits),
        };
        expect(split(copy(), copy(), copy()), [
          [0.0, 3.0, false],
        ], reason: value);
      }
    });

    test('does not split without setContext', () {
      expect(
        computeSegments(
          _Line(_points('oooo'), options: _base, chart: chart),
          const <String, Object?>{},
        ),
        [_segment(0, 3, false)],
      );
    });
  });

  group('js-semantics-segment-style-json', () {
    // In JavaScript, JSON.stringify writes {"v":1} and {"v":2}, and the line
    // gets three segments. The port writes {} for both leaf objects.
    test('writes a leaf object as {}', () {
      final leaves = <String, Object?>{
        'setContext': (Object? ctx) => {
          ..._base,
          'borderColor': _Leaf(_p0DataIndex(ctx) == 1 ? 1 : 2),
        },
      };
      expect(
        computeSegments(
          _Line(
            _points('oooo'),
            options: {..._base, 'borderColor': const _Leaf(2)},
            chart: _Chart(),
          ),
          leaves,
        ),
        hasLength(1),
      );
    });
  });
}
