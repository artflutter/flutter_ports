// Original code, not ported from Chart.js: LineElement cases with no spec.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/elements/element.line.dart';
import 'package:flutter_chartjs/src/elements/element.point.dart';
import 'package:flutter_chartjs/src/elements/element_options.dart';
import 'package:flutter_chartjs/src/helpers/helpers.interpolation.dart'
    show InterpolatedPoint;
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:test/test.dart';

import 'line_reference.dart';

// Upstream behavior that test/specs/element.line.tests.js does not check
// (AGENTS.md rule 3): the Path2D cache, the fast path and pathSegment, the
// steps, the control points, interpolate, the segments, first and last,
// loops and spanGaps, the draw arguments, the statics and the access by
// name. The group 'reference' runs the cases of line_reference.dart, which
// tool/reference/line_reference.mjs writes from the pinned element.line.js
// and the mock context of chartjs-test-utils in Node.js v24.12.0 on x64. The
// other expected values come from a probe of the same sources in the same
// Node.js. The numbers compare with closeTo (Chart.js ADR 0009).
//
// Each reference case runs twice (Chart.js ADR 0018, section 6): with the
// plain Map options of the reference, and with a LineOptions with the same
// entries. Both compare with the same reference data.

/// A chart area `{left, top, right, bottom, width, height}`.
final class _Area implements ChartArea {
  const _Area(this.left, this.top, this.right, this.bottom);

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;

  @override
  double get width => right - left;

  @override
  double get height => bottom - top;
}

/// The chart `{getContext}` of a line with segment styles: the `_chart` of
/// helpers.segment.js:280.
final class _Chart implements types.Chart {
  @override
  Map<String, Object?> getContext() => {'chart': 'chart', 'type': 'chart'};

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The option `segment` of a reference case: `'empty'` is `{}`, `'style'`
/// has the `setContext` of the generator.
AnyObject _segmentOption(String kind) => switch (kind) {
  'empty' => <String, Object?>{},
  _ => <String, Object?>{
    'setContext': (Object? ctx) {
      final late = jsToNumber(jsGet(ctx, 'p0DataIndex')) >= 2;
      return <String, Object?>{
        'borderColor': late ? 'blue' : 'red',
        'borderWidth': late ? 4.0 : 2.0,
      };
    },
  },
};

/// The point element `{x, y, skip, stop}` of [point]. A null `skip` or
/// `stop` is an absent key.
PointElement _point(LineReferencePointInput point) {
  final (x, y, skip, stop) = point;
  return PointElement({
    'x': x,
    'y': y,
    'skip': ?skip,
    'stop': ?stop,
  });
}

/// [options] as they are: the plain Map form of the options.
AnyObject _plainOptions(AnyObject options) => options;

/// The two forms of the options of a line (Chart.js ADR 0018, section 6): the
/// plain Map, and a [LineOptions] with the same entries in the same key
/// order.
const Map<String, AnyObject Function(AnyObject options)> _optionsForms = {
  'Map options': _plainOptions,
  'LineOptions': LineOptions.new,
};

/// The line of a reference case, made as the generator makes it:
/// `new LineElement({points, options, ...props})`, with the options in the
/// form [form].
LineElement _line(
  LineReferenceCase c,
  List<types.PointElement> points,
  AnyObject Function(AnyObject) form,
) {
  final options = c.options;
  final segment = c.segment;
  return LineElement({
    'points': points,
    if (options != null)
      'options': form(
        segment == null
            ? options
            : {...options, 'segment': _segmentOption(segment)},
      ),
    for (final MapEntry(:key, :value) in c.props.entries)
      key: value == 'chart' ? _Chart() : value,
  });
}

/// A matcher of the number [n]: [isNaN] for NaN, else [closeTo].
Matcher _number(num n) => n.isNaN ? isNaN : closeTo(n, 1e-9);

/// The expected value [value] of a reference call as a matcher structure.
Object? _expected(Object? value) => switch (value) {
  final num n => _number(n),
  final LineReferencePath path => {
    'path': path.id,
    'calls': _expectedCalls(path.calls),
  },
  final List<Object?> list => [for (final item in list) _expected(item)],
  _ => value,
};

/// The expected calls [calls] as a matcher structure.
List<Object?> _expectedCalls(List<LineReferenceCall> calls) => [
  for (final (name, args) in calls)
    {
      'name': name,
      'args': [for (final arg in args) _expected(arg)],
    },
];

/// The ids of the Path2D objects of one case, in the order of the first
/// sight, as the generator numbers them.
final class _PathIds {
  final Map<Path2D, int> _ids = {};

  /// The id of [path], or null for no path.
  int? of(Path2D? path) =>
      path == null ? null : _ids.putIfAbsent(path, () => _ids.length + 1);
}

/// A recorded argument [value] with a Path2D as its id and its commands.
Object? _actual(Object? value, _PathIds ids) => switch (value) {
  final Path2D path => {
    'path': ids.of(path),
    'calls': _actualCalls(_replay(path), ids),
  },
  final List<Object?> list => [for (final item in list) _actual(item, ids)],
  _ => value,
};

/// The recorded calls [calls] with each Path2D argument as its id and its
/// commands.
List<Object?> _actualCalls(List<ContextCall> calls, _PathIds ids) => [
  for (final call in calls)
    {
      'name': call['name'],
      'args': [
        for (final arg in call['args']! as List<Object?>) _actual(arg, ids),
      ],
    },
];

/// The calls of the commands of [path] on a new mock context.
List<ContextCall> _replay(Path2D path) {
  final ctx = createMockContext();
  path.replay(ctx);
  return ctx.getCalls();
}

/// The double of the reference argument [args] at [index], or null for an
/// absent argument.
double? _arg(List<Object?> args, int index) =>
    index < args.length ? (args[index]! as num).toDouble() : null;

/// The encoded point of an interpolate result: the index of a point of
/// [points], or its `x` and `y`.
LineReferencePoint _encode(Point point, List<types.PointElement> points) {
  final index = points.indexWhere((p) => identical(p, point));
  return index >= 0
      ? (index: index, x: null, y: null)
      : (index: null, x: point.x, y: point.y);
}

/// The matcher of the expected interpolate point [point].
Matcher _expectedPoint(LineReferencePoint point) => isA<LineReferencePoint>()
    .having((p) => p.index, 'index', point.index)
    .having(
      (p) => p.x,
      'x',
      point.x == null ? isNull : _number(point.x!),
    )
    .having(
      (p) => p.y,
      'y',
      point.y == null ? isNull : _number(point.y!),
    );

/// Runs the steps of the reference case [c], with the options in the form
/// [form], and compares each record.
void _run(LineReferenceCase c, AnyObject Function(AnyObject) form) {
  final points = <types.PointElement>[for (final p in c.points) _point(p)];
  final line = _line(c, points, form);
  final ids = _PathIds();

  for (var i = 0; i < c.steps.length; i++) {
    final step = c.steps[i];
    final args = step.args;
    final reason = 'step $i: ${step.action} $args';
    final ctx = createMockContext();
    Object? result;

    switch (step.action) {
      case 'draw':
        line.draw(ctx, null, _arg(args, 0), _arg(args, 1));
      case 'updateControlPoints':
        line.updateControlPoints(
          _Area(_arg(args, 0)!, _arg(args, 1)!, _arg(args, 2)!, _arg(args, 3)!),
          args.length > 4 ? args[4]! as String : null,
        );
        result = [
          for (final p in points.cast<SplinePoint>())
            [p.cp1x, p.cp1y, p.cp2x, p.cp2y],
        ];
      case 'setPoints':
        // `line.points = line.points`.
        final current = line.points;
        line.points = current;
      case 'path':
        result = line.path(ctx, _arg(args, 0), _arg(args, 1));
      case 'pathSegment':
        result = line.pathSegment(
          ctx,
          line.segments[(args[0]! as num).toInt()],
          args.length > 1 ? args[1]! as AnyObject : null,
        );
      case 'interpolate':
        final value = _arg(args, 0)!;
        final property = args[1]! as String;
        final point = PointElement(
          property == 'x' ? {'x': value, 'y': 0} : {'x': 0, 'y': value},
        );
        result = switch (line.interpolate(point, property)) {
          null => null,
          final List<Point> list => [
            for (final p in list) _encode(p, points),
          ],
          final Point p => _encode(p, points),
          final other => other,
        };
      case 'segments':
        result = [
          for (final s in line.segments)
            (s.start, s.end, s.loop, s.style != null),
        ];
      case 'first':
        result = _indexOf(line.first(), points);
      case 'last':
        result = _indexOf(line.last(), points);
      default:
        fail('Unknown step ${step.action}');
    }

    expect(
      _actualCalls(ctx.getCalls(), ids),
      _expectedCalls(step.calls),
      reason: '$reason: calls',
    );
    expect(result, _expectedResult(step), reason: '$reason: result');
    expect(
      ids.of(_pathOf(line)),
      step.path,
      reason: '$reason: the id of _path',
    );
    expect(
      line['_pointsUpdated'],
      step.pointsUpdated,
      reason: '$reason: _pointsUpdated',
    );
  }
}

/// The cached path of [line], read by name. The [undefined] sentinel gives
/// null.
Path2D? _pathOf(LineElement line) => switch (line['_path']) {
  final Path2D path => path,
  _ => null,
};

/// The index of [point] in [points], or null for no point.
int? _indexOf(types.PointElement? point, List<types.PointElement> points) =>
    point == null ? null : points.indexWhere((p) => identical(p, point));

/// The matcher of the result of [step].
Object? _expectedResult(LineReferenceStep step) {
  final result = step.result;
  return switch (step.action) {
    'updateControlPoints' => [
      for (final cps in result! as List<List<double>>)
        [for (final v in cps) _number(v)],
    ],
    'segments' => [
      for (final (start, end, loop, styled)
          in result! as List<LineReferenceSegment>)
        (start, end, loop, styled),
    ],
    'interpolate' => switch (result) {
      null => isNull,
      final List<LineReferencePoint> list => [
        for (final p in list) _expectedPoint(p),
      ],
      final LineReferencePoint p => _expectedPoint(p),
      _ => result,
    },
    _ => result,
  };
}

/// A line of the points `(0, 10)`, `(10, 20)` and `(20, 15)` with the
/// options [options].
LineElement _simpleLine([AnyObject? options]) => LineElement({
  'points': <types.PointElement>[
    PointElement({'x': 0, 'y': 10}),
    PointElement({'x': 10, 'y': 20}),
    PointElement({'x': 20, 'y': 15}),
  ],
  'options': ?options,
});

/// The resolved options of a line: the defaults and a border color.
AnyObject _options([AnyObject extra = const {}]) => {
  ...LineElement.defaults,
  'borderColor': 'black',
  ...extra,
};

void main() {
  group('reference', () {
    test('has the reference of Node.js v24.12.0 on x64', () {
      expect(lineReferenceNode, 'v24.12.0');
      expect(lineReferenceArch, 'x64');
      expect(lineReference, hasLength(40));
    });

    for (final MapEntry(key: name, value: form) in _optionsForms.entries) {
      group(name, () {
        for (final c in lineReference) {
          test(c.name, () => _run(c, form));
        }
      });
    }
  });

  group('statics', () {
    test('has the id, defaults, defaultRoutes and descriptors', () {
      expect(LineElement.id, 'line');
      expect(LineElement.defaults, {
        'borderCapStyle': 'butt',
        'borderDash': <Object?>[],
        'borderDashOffset': 0,
        'borderJoinStyle': 'miter',
        'borderWidth': 3,
        'capBezierPoints': true,
        'cubicInterpolationMode': 'default',
        'fill': false,
        'spanGaps': false,
        'stepped': false,
        'tension': 0,
      });
      expect(LineElement.defaults.keys, [
        'borderCapStyle',
        'borderDash',
        'borderDashOffset',
        'borderJoinStyle',
        'borderWidth',
        'capBezierPoints',
        'cubicInterpolationMode',
        'fill',
        'spanGaps',
        'stepped',
        'tension',
      ]);
      expect(LineElement.defaultRoutes, {
        'backgroundColor': 'backgroundColor',
        'borderColor': 'borderColor',
      });
      expect(LineElement.descriptors.keys, ['_scriptable', '_indexable']);
      expect(LineElement.descriptors['_scriptable'], isTrue);
    });

    test('indexes every option but borderDash and fill', () {
      final indexable =
          LineElement.descriptors['_indexable']! as bool Function(String);
      expect(indexable('borderDash'), isFalse);
      expect(indexable('fill'), isFalse);
      expect(indexable('borderColor'), isTrue);
      expect(indexable('tension'), isTrue);
    });
  });

  group('the undefined state', () {
    test('starts animated and in the undefined state', () {
      final line = LineElement();
      expect(line.animated, isTrue);
      expect(line.decimated, isFalse);
      expect(line.options, isNull);
      expect(line.chart, isNull);
      expect(line.loop, isNull);
      expect(line.fullLoop, isNull);
      expect(line.datasetIndex, isNull);
      for (final name in [
        'options',
        '_chart',
        '_loop',
        '_fullLoop',
        '_path',
        '_points',
        'points',
        '_segments',
        '_datasetIndex',
      ]) {
        expect(line[name], same(undefined), reason: name);
      }
      expect(line['animated'], isTrue);
      expect(line['_decimated'], isFalse);
      expect(line['_pointsUpdated'], isFalse);
      expect(line.hasValue(), isFalse);
    });

    test('throws a TypeError for the points of the undefined state', () {
      // Upstream returns undefined, and each reader throws a TypeError.
      expect(() => LineElement().points, throwsA(isA<TypeError>()));
      expect(
        () => LineElement({'options': _options()}).segments,
        throwsA(isA<TypeError>()),
      );
    });

    test('throws a TypeError for the options of the undefined state', () {
      // Upstream: Cannot read properties of undefined (reading 'segment').
      expect(() => _simpleLine().segments, throwsA(isA<TypeError>()));
      expect(() => _simpleLine().first(), throwsA(isA<TypeError>()));
      expect(() => _simpleLine().last(), throwsA(isA<TypeError>()));
      expect(
        () => _simpleLine().updateControlPoints(const _Area(0, 0, 1, 1)),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => _simpleLine().path(createMockContext()),
        throwsA(isA<TypeError>()),
      );
    });

    test('throws a TypeError for control points without points', () {
      // Upstream: Cannot read properties of undefined (reading '0').
      final line = LineElement({
        'options': <String, Object?>{'tension': 0.4},
      });
      expect(
        () => line.updateControlPoints(const _Area(0, 0, 1, 1)),
        throwsA(isA<TypeError>()),
      );
    });

    test('draws nothing without options and drops the path', () {
      final ctx = createMockContext();
      final line = _simpleLine()
        ..['_path'] = Path2D()
        ..draw(ctx);
      expect(ctx.getCalls(), isEmpty);
      expect(line['_path'], same(undefined));
    });

    test('throws a TypeError for a borderDash that is not a list', () {
      // The DOM setLineDash throws a TypeError for a value that is not a
      // sequence.
      final line = _simpleLine(_options({'borderDash': undefined}));
      expect(
        () => line.draw(createMockContext()),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('access by name', () {
    test('writes the declared properties', () {
      final chart = _Chart();
      final path = Path2D();
      final segments = <types.Segment>[];
      final line = LineElement()
        ..['animated'] = false
        ..['_chart'] = chart
        ..['_loop'] = true
        ..['_fullLoop'] = false
        ..['_path'] = path
        ..['_segments'] = segments
        ..['_decimated'] = true
        ..['_pointsUpdated'] = true
        ..['_datasetIndex'] = 2;
      expect(line.animated, isFalse);
      expect(line.chart, same(chart));
      expect(line.loop, isTrue);
      expect(line.fullLoop, isFalse);
      expect(line['_path'], same(path));
      expect(line['_segments'], same(segments));
      expect(line.decimated, isTrue);
      expect(line['_pointsUpdated'], isTrue);
      expect(line.datasetIndex, 2.0);
      expect(line['_datasetIndex'], isA<double>());
    });

    test('writes undefined to the properties of the undefined state', () {
      final line = LineElement({
        '_chart': _Chart(),
        '_loop': true,
        '_fullLoop': true,
        '_datasetIndex': 1,
      });
      for (final name in ['_chart', '_loop', '_fullLoop', '_datasetIndex']) {
        line[name] = undefined;
        expect(line[name], same(undefined), reason: name);
      }
    });

    test('drops the cache with the points setter, not with _points', () {
      // Upstream: `line._points = …` keeps `_segments`; `line.points = …`
      // drops them.
      final line = _simpleLine(_options());
      final segments = line.segments;
      final path = Path2D();
      line
        ..['_path'] = path
        ..['_pointsUpdated'] = true
        ..['_points'] = <types.PointElement>[
          PointElement({'x': 0, 'y': 0}),
        ];
      expect(line.segments, same(segments));
      expect(line['_path'], same(path));
      expect(line['_pointsUpdated'], isTrue);

      line['points'] = line.points;
      expect(line['_segments'], same(undefined));
      expect(line['_path'], same(undefined));
      expect(line['_pointsUpdated'], isFalse);
      expect(line.segments, isNot(same(segments)));

      line['points'] = undefined;
      expect(line['points'], same(undefined));
    });

    test('computes the segments at a read of segments', () {
      final line = _simpleLine(_options());
      expect(line['_segments'], same(undefined));
      final segments = line['segments'];
      expect(segments, isA<List<types.Segment>>());
      expect(line['_segments'], same(segments));
      expect(line.segments, same(segments));
    });

    test('throws an ArgumentError for a write of segments', () {
      // Upstream: Cannot set property segments of #<LineElement> which has
      // only a getter. Object.assign throws the same TypeError.
      expect(
        () => LineElement()['segments'] = <types.Segment>[],
        throwsArgumentError,
      );
      expect(
        () => LineElement({'segments': <types.Segment>[]}),
        throwsArgumentError,
      );
    });

    test('throws an ArgumentError for a value outside the type', () {
      final line = LineElement();
      for (final (name, value) in <(String, Object?)>[
        ('animated', undefined),
        ('animated', 1),
        ('_decimated', null),
        ('_pointsUpdated', 'true'),
        ('_chart', <String, Object?>{}),
        ('_loop', 1),
        ('_fullLoop', null),
        ('_path', <Object?>[]),
        ('points', <Object?>[1, 2]),
        ('_points', <int>[1]),
        ('_segments', <Object?>[]),
        ('_datasetIndex', '1'),
        ('options', <Object?>[]),
      ]) {
        expect(
          () => line[name] = value,
          throwsArgumentError,
          reason: '$name = $value',
        );
      }
    });

    test('passes other names to Element', () {
      final line = LineElement({'x': 1, r'$context': 'context'});
      expect(line.x, 1.0);
      expect(line[r'$context'], 'context');
      expect(line['unknown'], same(undefined));
    });
  });

  group('types', () {
    test('is a types.LineElement and a types.VisualElement', () {
      final line = LineElement();
      expect(line, isA<Element>());
      expect(line, isA<types.LineElement>());
      expect(line, isA<types.VisualElement>());
      expect(line, isA<types.Element>());
    });

    test('has no hit test and no center point, as upstream', () {
      // Upstream: `typeof line.inRange` is 'undefined'. A call throws a
      // TypeError.
      final line = _simpleLine(_options());
      expect(() => line.inRange(0, 0), throwsNoSuchMethodError);
      expect(() => line.inXRange(0), throwsNoSuchMethodError);
      expect(() => line.inYRange(0), throwsNoSuchMethodError);
      expect(line.getCenterPoint, throwsNoSuchMethodError);
    });
  });

  group('path', () {
    test('gives _loop when the line has no segments', () {
      // Upstream: true for `_loop: true` and no points, false without it.
      expect(
        LineElement({
          'points': <types.PointElement>[],
          'options': <String, Object?>{},
          '_loop': true,
        }).path(createMockContext()),
        isTrue,
      );
      expect(
        LineElement({
          'points': <types.PointElement>[],
          'options': <String, Object?>{},
        }).path(createMockContext()),
        isFalse,
      );
    });

    test('gives undefined from pathSegment on the fast path', () {
      final line = _simpleLine(_options());
      expect(
        line.pathSegment(createMockContext(), line.segments[0]),
        isNull,
      );
    });

    test('reads the params of pathSegment with ToNumber and ToBoolean', () {
      final line = _simpleLine(_options({'stepped': true}));
      final plain = createMockContext();
      final coerced = createMockContext();
      line
        ..pathSegment(plain, line.segments[0], {
          'start': 1,
          'end': 2,
          'move': false,
          'reverse': true,
        })
        ..pathSegment(coerced, line.segments[0], {
          'start': '1',
          'end': true,
          'move': 0,
          'reverse': 'yes',
        });
      // `end: true` is ToNumber 1.
      final reference = createMockContext();
      line.pathSegment(reference, line.segments[0], {
        'start': 1,
        'end': 1,
        'move': false,
        'reverse': true,
      });
      expect(coerced.getCalls(), reference.getCalls());
      expect(plain.getCalls(), isNotEmpty);
    });
  });

  group('fast path with an undefined y', () {
    // Upstream keeps `minY = maxY = undefined` for a group whose first y is
    // undefined, and `undefined !== undefined` is false, so drawX draws
    // nothing for the group. The y getter gives NaN, and `NaN !== NaN` is
    // true, so an explicit NaN draws the group. Probe of the pinned
    // element.line.js and the mock context in Node.js v24.12.0 on x64.

    /// The names and the arguments of the calls of pathSegment over the
    /// first segment of a line of [points] with the default options.
    (List<Object?>, List<List<Object?>>) fastPath(
      List<types.PointElement> points,
    ) {
      final line = LineElement({
        'points': points,
        'options': <String, Object?>{...LineElement.defaults},
      });
      final ctx = createMockContext();
      expect(line.pathSegment(ctx, line.segments[0]), isNull);
      final calls = ctx.getCalls();
      return (
        [for (final call in calls) call['name']],
        [for (final call in calls) call['args']! as List<Object?>],
      );
    }

    test('does not draw the group of an undefined first y', () {
      // Upstream: moveTo(0,0) lineTo(0,0) lineTo(10,undefined)
      // lineTo(20,20).
      final (names, args) = fastPath([
        PointElement({'x': 0, 'y': 0}),
        PointElement({'x': 10}),
        PointElement({'x': 10.5, 'y': 5}),
        PointElement({'x': 20, 'y': 20}),
      ]);
      expect(names, ['moveTo', 'lineTo', 'lineTo', 'lineTo']);
      expect(args[0], [0, 0]);
      expect(args[1], [0, 0]);
      // Upstream records undefined. The y getter gives NaN.
      expect(args[2][0], 10);
      expect(args[2][1], isNaN);
      expect(args[3], [20, 20]);
    });

    test('keeps the undefined y over the other points of the group', () {
      // Upstream: moveTo(0,0) lineTo(0,0) lineTo(10,undefined)
      // lineTo(20,20). `y < undefined` and `y > undefined` are false.
      final (names, args) = fastPath([
        PointElement({'x': 0, 'y': 0}),
        PointElement({'x': 10}),
        PointElement({'x': 10.2, 'y': 5}),
        PointElement({'x': 10.5, 'y': 8}),
        PointElement({'x': 20, 'y': 20}),
      ]);
      expect(names, ['moveTo', 'lineTo', 'lineTo', 'lineTo']);
      expect(args[2][0], 10);
      expect(args[2][1], isNaN);
      expect(args[3], [20, 20]);
    });

    test('draws the group of a NaN first y', () {
      // Upstream: moveTo(0,0) lineTo(0,0) lineTo(10,NaN) lineTo(10.5,NaN)
      // lineTo(10.5,NaN) lineTo(10.5,5) lineTo(20,20).
      final (names, args) = fastPath([
        PointElement({'x': 0, 'y': 0}),
        PointElement({'x': 10, 'y': double.nan}),
        PointElement({'x': 10.5, 'y': 5}),
        PointElement({'x': 20, 'y': 20}),
      ]);
      expect(names, [
        'moveTo',
        'lineTo',
        'lineTo',
        'lineTo',
        'lineTo',
        'lineTo',
        'lineTo',
      ]);
      expect(args[2][0], 10);
      expect(args[2][1], isNaN);
      for (final i in [3, 4]) {
        expect(args[i][0], 10.5);
        expect(args[i][1], isNaN);
      }
      expect(args[5], [10.5, 5]);
      expect(args[6], [20, 20]);
    });
  });

  group('adapt-line-points-elements', () {
    test('a write of plain points throws an ArgumentError', () {
      // Upstream stores any array: `points: Point[]` (index.d.ts:1981).
      expect(
        () => LineElement({
          'points': <Point>[InterpolatedPoint(1, 2), InterpolatedPoint(3, 4)],
          'options': {'tension': 0},
        }),
        throwsArgumentError,
      );
      final line = LineElement();
      expect(
        () => line['_points'] = <Point>[InterpolatedPoint(1, 2)],
        throwsArgumentError,
      );
    });

    test('point elements with the same x and y give the upstream line', () {
      // Upstream, with the plain points {x: 1, y: 2} and {x: 3, y: 4}:
      // first() is {x: 1, y: 2}, and path draws moveTo(1,2) lineTo(1,2)
      // lineTo(3,4).
      final line = LineElement({
        'points': <types.PointElement>[
          PointElement({'x': 1, 'y': 2}),
          PointElement({'x': 3, 'y': 4}),
        ],
        'options': {'tension': 0},
      });
      expect(line.first()!.x, 1);
      expect(line.first()!.y, 2);
      expect(line.last()!.y, 4);
      final ctx = createMockContext();
      line.path(ctx);
      expect(ctx.getCalls(), [
        {
          'name': 'moveTo',
          'args': [1, 2],
        },
        {
          'name': 'lineTo',
          'args': [1, 2],
        },
        {
          'name': 'lineTo',
          'args': [3, 4],
        },
      ]);
    });
  });
}
