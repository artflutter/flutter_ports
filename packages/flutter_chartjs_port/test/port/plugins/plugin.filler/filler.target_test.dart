// Original code, not ported from Chart.js: filler target reference tests.

// The tests of the target functions of lib/src/plugins/plugin.filler/
// against tool/reference/filler_target_reference.mjs (Chart.js ADR 0041,
// section 3 item 8; Chart.js ADR 0040): `decodeFill`, `resolveTarget`,
// `getTargetPixel`, `getTargetValue`, `getTarget` with `segments`, and
// `drawfill` on the mock context. The generator runs the pinned source
// files in Node.js v24.22.1 on arm64 with fakes of the chart, the metas and
// the scales. The fakes of this file give the same values: they use only
// `+`, `-`, `*` and `/`.
//
// The files are pure layers (Chart.js ADR 0038, section 9). Thus this file
// uses package:test, and test:web runs it too. It builds no chart, so it
// registers no plugin (Chart.js ADR 0041, section 7).

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.drawing.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.options.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.segment.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.target.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/index.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/simpleArc.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

import 'filler_target_reference.dart';

// ---------------------------------------------------------------------------
// The fakes of the generator.

/// The chart area of the description `d`.
final class _Area implements types.ChartArea {
  _Area(Map<String, Object?> d)
    : left = _n(d['left']),
      top = _n(d['top']),
      right = _n(d['right']),
      bottom = _n(d['bottom']);

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

/// A number of the data.
double _n(Object? value) => (value! as num).toDouble();

/// The fake chart: `getDatasetMeta`, `isDatasetVisible` and `chartArea`.
final class _FakeChart implements types.Chart {
  _FakeChart(this._visible, this.chartArea);

  final List<bool> _visible;
  List<_FakeMeta> metas = const [];

  @override
  final types.ChartArea? chartArea;

  @override
  types.ChartMeta getDatasetMeta(num datasetIndex) =>
      metas[datasetIndex.toInt()];

  @override
  bool isDatasetVisible(num datasetIndex) => _visible[datasetIndex.toInt()];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The clip of a fake meta: `{disabled: true}`.
final class _DisabledClip implements types.ChartMetaClip {
  @override
  bool get disabled => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The fake meta `{index, type, hidden, dataset, iScale, _clip}`.
final class _FakeMeta implements types.ChartMeta {
  _FakeMeta({
    required this.index,
    required this.type,
    required this.hidden,
    required this.dataset,
    required this.iScale,
  });

  @override
  final double index;
  @override
  final String type;
  @override
  final bool? hidden;
  @override
  types.Element? dataset;
  @override
  types.Scale? iScale;
  @override
  types.ChartMetaClip clip = _DisabledClip();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The fake linear scale of the generator.
final class _FakeLinearScale implements types.Scale {
  _FakeLinearScale(Map<String, Object?> d, this._chart)
    : _horizontal = d['horizontal']! as bool,
      top = _n(d['top']),
      bottom = _n(d['bottom']),
      left = _n(d['left']),
      right = _n(d['right']),
      min = _n(d['min']),
      max = _n(d['max']),
      _baseValue = _n(d['baseValue']),
      options = <String, Object?>{'reverse': d['reverse']};

  final _FakeChart _chart;
  final bool _horizontal;
  final double _baseValue;

  @override
  String get id => _horizontal ? 'x' : 'y';
  @override
  final double top;
  @override
  final double bottom;
  @override
  final double left;
  @override
  final double right;
  @override
  final double min;
  @override
  final double max;
  @override
  final Map<String, Object?> options;
  @override
  types.Chart get chart => _chart;
  @override
  bool isHorizontal() => _horizontal;
  @override
  double getPixelForValue(Object? value, [double? index]) =>
      _horizontal ? 50 + 40 * jsToNumber(value) : 400 - 40 * jsToNumber(value);
  @override
  double getBasePixel() => getPixelForValue(_baseValue);
  @override
  double getBaseValue() => _baseValue;
  @override
  List<types.ChartMeta> getMatchingVisibleMetas([String? type]) => [
    for (final meta in _chart.metas)
      if (meta.type == type && _chart.isDatasetVisible(meta.index)) meta,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The fake radial linear scale of the generator.
final class _FakeRadialScale implements types.RadialLinearScale {
  _FakeRadialScale(Map<String, Object?> d, this._chart)
    : _n5 = _n(d['n']).toInt(),
      min = _n(d['min']),
      max = _n(d['max']),
      _reverse = d['reverse']! as bool,
      _baseValue = _n(d['baseValue']),
      options = <String, Object?>{
        'reverse': d['reverse'],
        'grid': <String, Object?>{'circular': d['circular']},
      };

  final _FakeChart _chart;
  final int _n5;
  final bool _reverse;
  final double _baseValue;

  @override
  String get id => 'r';
  @override
  final double min;
  @override
  final double max;
  @override
  final Map<String, Object?> options;
  @override
  types.Chart get chart => _chart;
  @override
  List<Object?> getLabels() => [for (var i = 0; i < _n5; i++) 'l$i'];
  @override
  double getBaseValue() => _baseValue;

  double _dist(Object? value) => _reverse
      ? (max - jsToNumber(value)) * 20
      : (jsToNumber(value) - min) * 20;

  @override
  double getDistanceFromCenterForValue(Object? value) => _dist(value);

  @override
  ({double x, double y, double angle}) getPointPositionForValue(
    double index,
    Object? value,
  ) {
    final r = _dist(value);
    return (
      x: 256 + (r * (index - 2)) / 2,
      y: 280 - (r * (3 - index)) / 3,
      angle: index * 1.25 - 1.5,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The fake scale of the description [d], or Dart `null` for `null`.
types.Scale? _makeScale(Object? d, _FakeChart chart) => switch (d) {
  null => null,
  final Map<String, Object?> map when map['kind'] == 'radial' =>
    _FakeRadialScale(map, chart),
  final Map<String, Object?> map => _FakeLinearScale(map, chart),
  _ => throw ArgumentError.value(d, 'd'),
};

/// The element of the line description [d] (`makeLine` of the generator).
types.Element _makeLine(Map<String, Object?> d) {
  if (d['element'] == 'point') {
    return PointElement()
      ..x = 1
      ..y = 2;
  }
  final points = [
    for (final p in (d['points']! as List<Object?>).cast<AnyObject>())
      PointElement()..assign(p),
  ];
  final loop = d['loop'];
  return LineElement(<String, Object?>{
    'points': points,
    'options': Map<String, Object?>.of(d['options']! as Map<String, Object?>),
    if (!identical(loop, undefined)) '_loop': loop,
    if (!identical(loop, undefined)) '_fullLoop': loop,
  });
}

/// The fake chart and the source of a `target` or `drawfill` case.
({_FakeChart chart, FillerSource source}) _makeChart(AnyObject input) {
  final c = input['chart']! as Map<String, Object?>;
  final lines = (c['lines']! as List<Object?>).cast<Map<String, Object?>>();
  final area = c['area'];
  final chart = _FakeChart(
    [for (final line in lines) line['visible']! as bool],
    area == null ? null : _Area(area as Map<String, Object?>),
  );
  final scale = _makeScale(c['scale'], chart);
  final iScale = _makeScale(c['iScale'], chart);
  chart.metas = [
    for (var i = 0; i < lines.length; i++)
      _FakeMeta(
        index: i.toDouble(),
        type: lines[i]['type']! as String,
        hidden: lines[i]['hidden'] as bool?,
        dataset: _makeLine(lines[i]),
        iScale: iScale,
      ),
  ];
  final source = input['source']! as Map<String, Object?>;
  final index = _n(source['index']);
  return (
    chart: chart,
    source: FillerSource(
      visible: chart.isDatasetVisible(index),
      index: index,
      fill: source['fill']!,
      chart: chart,
      axis: source['axis'],
      scale: scale,
      line: chart.metas[index.toInt()].dataset! as types.LineElement,
    ),
  );
}

// ---------------------------------------------------------------------------
// The results of the generator.

/// A point read by name: `[x, y, angle]`.
List<Object?> _byName(types.PointElement point) {
  final element = point as Element;
  return [element['x'], element['y'], element['angle']];
}

/// A segment: `[start, end, loop]`.
List<Object?> _seg(types.Segment segment) => [
  segment.start,
  segment.end,
  segment.loop,
];

/// `describeTarget` of the generator.
Object? _describeTarget(Object? target) {
  if (target == true) return 'shape';
  if (target == null) return null;
  if (target is SimpleArc) {
    return <String, Object?>{
      'kind': 'simpleArc',
      'x': target.x,
      'y': target.y,
      'radius': target.radius,
    };
  }
  if (target is! types.LineElement) {
    return <String, Object?>{'kind': 'element'};
  }
  final line = target as Element;
  return <String, Object?>{
    'kind': 'line',
    'loop': line['_loop'],
    'fullLoop': line['_fullLoop'],
    'points': [for (final point in target.points) _byName(point)],
    'segments': [for (final segment in target.segments) _seg(segment)],
  };
}

/// `describeParts` of the generator.
List<Object?> _describeParts(List<FillPart> parts) => [
  for (final (:source, :target, :start, :end) in parts)
    <String, Object?>{
      'source': _seg(source),
      'target': switch (target) {
        null => undefined,
        final ({String property, double start, double end}) bounds =>
          <String, Object?>{
            'property': bounds.property,
            'start': bounds.start,
            'end': bounds.end,
          },
        final types.Segment segment => _seg(segment),
        _ => throw StateError('A target of ${target.runtimeType}'),
      },
      'start': _byName(start),
      'end': _byName(end),
    },
];

/// The name of the class of the thrown value [error]: a Dart [TypeError]
/// is a JS `TypeError` (Chart.js ADR 0030, section 4).
String _errorName(Object error) => switch (error) {
  TypeError() => 'TypeError',
  RangeError() => 'RangeError',
  _ => error.runtimeType.toString(),
};

/// The result of [fn], or `{error}` with the name of its error.
Object? _attempt(Object? Function() fn) {
  try {
    return fn();
    // The test maps each error to its JS name.
    // ignore: avoid_catches_without_on_clauses
  } catch (error) {
    return <String, Object?>{'error': _errorName(error)};
  }
}

/// The calls of the mock context as `[name, ...args]`. The Dart mock
/// records the optional arguments of `clip` and `fill` as `null`, the JS
/// mock records only the given arguments.
List<Object?> _calls(MockContext ctx) => [
  for (final call in ctx.getCalls())
    [
      call['name'],
      ...switch (call['name']) {
        'clip' || 'fill' => (call['args']! as List<Object?>).where(
          (arg) => arg != null,
        ),
        _ => call['args']! as List<Object?>,
      },
    ],
];

/// The Dart result of the case [c].
Object? _run(FillerTargetReferenceCase c) {
  final input = c.input;
  switch (c.kind) {
    case 'decodeFill':
      final line = LineElement(<String, Object?>{
        'options': Map<String, Object?>.of(
          input['options']! as Map<String, Object?>,
        ),
      });
      return _attempt(
        () => decodeFill(line, _n(input['index']), _n(input['count'])),
      );
    case 'resolveTarget':
      final chart = _FakeChart(const [], null);
      final sources = [
        for (final (i, s) in (input['sources']! as List<Object?>).indexed)
          if (s case final Map<String, Object?> source)
            FillerSource(
              visible: source['visible']! as bool,
              index: i.toDouble(),
              fill: source['fill']!,
              chart: chart,
              axis: null,
              scale: null,
              line: LineElement(),
            )
          else
            null,
      ];
      return _attempt(
        () => resolveTarget(
          sources,
          _n(input['index']).toInt(),
          input['propagate']! as bool,
        ),
      );
    case 'targetPixel':
      final scale = _makeScale(input['scale'], _FakeChart(const [], null));
      return _attempt(() => getTargetPixel(input['fill']!, scale));
    case 'targetValue':
      final scale = _makeScale(input['scale'], _FakeChart(const [], null));
      return _attempt(
        () => getTargetValue(input['fill']!, scale!, _n(input['startValue'])),
      );
    case 'target':
      final (chart: _, :source) = _makeChart(input);
      return _attempt(() {
        final target = getTarget(source);
        return <String, Object?>{
          'target': _describeTarget(target),
          'parts': target != null
              ? _attempt(
                  () => _describeParts(
                    segments(source.line, target, input['property']! as String),
                  ),
                )
              : const <Object?>[],
        };
      });
    case 'drawfill':
      final (:chart, :source) = _makeChart(input);
      final ctx = createMockContext();
      String? error;
      try {
        drawfill(ctx, source, chart.chartArea);
        // The test maps each error to its JS name.
        // ignore: avoid_catches_without_on_clauses
      } catch (e) {
        error = _errorName(e);
      }
      return <String, Object?>{'calls': _calls(ctx), 'error': error};
  }
  throw ArgumentError.value(c.kind, 'kind');
}

/// The expected results of the port where they differ from the data, with
/// the reason.
final Map<String, Object? Function(Object? expected)> _portResults = {
  // Chart.js ADR 0040, section 8, the difference
  // `adapt-filler-target-classes`: the port throws before `clipArea`, so it
  // records `save` and `beginPath` less.
  'drawfill radar without a layout': (expected) {
    final map = expected! as Map<String, Object?>;
    final calls = map['calls']! as List<Object?>;
    expect(calls.take(2), [
      ['save'],
      ['beginPath'],
    ]);
    return <String, Object?>{...map, 'calls': calls.sublist(2)};
  },
};

/// [expected] with Dart `null` for the JS `undefined` of
/// `{}.bottom` and `{}.top` (the doc of `getTargetPixel`).
Object? _pixel(Object? expected) =>
    identical(expected, undefined) ? null : expected;

// ---------------------------------------------------------------------------
// The compare.

/// Expects [actual] to equal [expected]: numbers to 1e-9 (NaN equals NaN),
/// the `undefined` sentinel by identity, Lists item by item and Maps by
/// their keys.
void _expectValue(Object? actual, Object? expected, String path) {
  switch (expected) {
    case final num e:
      expect(actual, isA<num>(), reason: path);
      final a = (actual! as num).toDouble();
      if (e.isNaN) {
        expect(a.isNaN, isTrue, reason: '$path: NaN');
      } else if (e.isInfinite) {
        expect(a, e, reason: path);
      } else {
        expect(a, closeTo(e, 1e-9), reason: path);
      }
    case final List<Object?> e:
      expect(actual, isA<List<Object?>>(), reason: path);
      final a = actual! as List<Object?>;
      expect(a.length, e.length, reason: '$path: the length');
      for (var i = 0; i < e.length; i++) {
        _expectValue(a[i], e[i], '$path[$i]');
      }
    case final Map<String, Object?> e:
      expect(actual, isA<Map<String, Object?>>(), reason: path);
      final a = actual! as Map<String, Object?>;
      expect(a.keys.toSet(), e.keys.toSet(), reason: '$path: the keys');
      for (final key in e.keys) {
        _expectValue(a[key], e[key], '$path.$key');
      }
    case Undefined():
      expect(actual, same(undefined), reason: path);
    default:
      expect(actual, expected, reason: path);
  }
}

void main() {
  test('the reference comes from Node.js v24.22.1 on arm64', () {
    expect(fillerTargetReferenceNode, 'v24.22.1');
    expect(fillerTargetReferenceArch, 'arm64');
  });

  for (final kind in [
    'decodeFill',
    'resolveTarget',
    'targetPixel',
    'targetValue',
    'target',
    'drawfill',
  ]) {
    group(kind, () {
      for (final c in fillerTargetReference.where((c) => c.kind == kind)) {
        test(c.name, () {
          var expected = c.result;
          if (kind == 'targetPixel') expected = _pixel(expected);
          expected = _portResults[c.name]?.call(expected) ?? expected;
          _expectValue(_run(c), expected, c.name);
        });
      }
    });
  }
}
