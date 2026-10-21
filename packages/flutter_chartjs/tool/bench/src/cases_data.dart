// Original code, not ported from Chart.js: the data-size benchmarks.

/// The cases that scale with the data: `helpers.curve`
/// (`_updateBezierControlPoints`), `helpers.segment` (`_computeSegments`,
/// `_boundSegments`) and `helpers.collection` (`_lookupByKey`,
/// `_rlookupByKey`).
library;

import 'dart:math' as math;

import 'package:flutter_chartjs/src/helpers/helpers.collection.dart';
import 'package:flutter_chartjs/src/helpers/helpers.curve.dart';
import 'package:flutter_chartjs/src/helpers/helpers.segment.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:flutter_chartjs/src/types/index.dart';

import 'harness.dart';

/// A spline point `{x, y, skip}` with its control points.
final class _SplinePoint implements SplinePoint {
  _SplinePoint(this.x, this.y);

  @override
  final double x;

  @override
  final double y;

  @override
  bool? get skip => null;

  @override
  double cp1x = double.nan;

  @override
  double cp1y = double.nan;

  @override
  double cp2x = double.nan;

  @override
  double cp2y = double.nan;
}

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

/// A point element `{x, y, skip, stop}`. The control points are NaN, which
/// stands for JS `undefined` (`SplinePoint`).
final class _PointElement implements PointElement {
  _PointElement(this.x, this.y, {this.skip});

  @override
  final double x;

  @override
  final double y;

  @override
  final bool? skip;

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

/// A chart `{getContext}`.
final class _Chart implements Chart {
  final Map<String, Object?> _context = {'chart': 'chart', 'type': 'chart'};

  @override
  Map<String, Object?> getContext() => _context;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A line element `{points, options, _chart, _loop, _fullLoop, segments}`.
final class _Line implements LineElement {
  _Line(this.points, this.options, {this.chart});

  @override
  final List<PointElement> points;

  @override
  final Map<String, Object?> options;

  @override
  final Chart? chart;

  @override
  bool? get loop => false;

  @override
  bool? get fullLoop => false;

  @override
  double? get datasetIndex => 0;

  @override
  List<Segment> segments = const [];

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// [count] spline points along a noisy sine, 1 px apart on x.
List<SplinePoint> _splinePoints(int count) => [
  for (var i = 0; i < count; i++)
    _SplinePoint(
      i.toDouble(),
      300 + 200 * math.sin(i * 0.05) + 37 * ((i * 7919) % 13 - 6) / 6,
    ),
];

/// [count] point elements with a skipped point every 50 points.
List<PointElement> _linePoints(int count) => [
  for (var i = 0; i < count; i++)
    _PointElement(
      i * 10.0,
      (i % 97).toDouble(),
      skip: i % 50 == 49 ? true : null,
    ),
];

/// The line style options of `element.line.js` defaults.
Map<String, Object?> _lineStyle() => <String, Object?>{
  'spanGaps': false,
  'backgroundColor': 'rgba(0,0,0,0.1)',
  'borderCapStyle': 'butt',
  'borderDash': <Object?>[],
  'borderDashOffset': 0.0,
  'borderJoinStyle': 'miter',
  'borderWidth': 3.0,
  'borderColor': 'rgb(75, 192, 192)',
};

BenchCase _curve(int count, String mode) => BenchCase(
  'data',
  'curve/${mode}_$count',
  () {
    final points = _splinePoints(count);
    final options = <String, Object?>{
      'tension': 0.4,
      'cubicInterpolationMode': mode,
      'capBezierPoints': true,
      'spanGaps': false,
    };
    const area = _Area(0, 0, 10000, 600);
    return (n) {
      var acc = 0;
      for (var i = 0; i < n; i++) {
        updateBezierControlPoints(points, options, area, false, 'x');
        acc += points[count ~/ 2].cp1x.toInt();
      }
      return acc;
    };
  },
  items: count,
  per: '_updateBezierControlPoints, $mode, $count points, capped',
);

/// The data cases.
List<BenchCase> dataCases() => [
  _curve(1000, 'default'),
  _curve(10000, 'default'),
  _curve(1000, 'monotone'),
  _curve(10000, 'monotone'),
  BenchCase(
    'data',
    'segment/compute_10k_gaps',
    () {
      final line = _Line(_linePoints(10000), _lineStyle());
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          acc += computeSegments(line).length;
        }
        return acc;
      };
    },
    items: 10000,
    per: '_computeSegments, 10k points, a gap every 50 (200 segments)',
  ),
  BenchCase(
    'data',
    'segment/compute_1k_styled',
    () {
      final style = _lineStyle();
      final red = <String, Object?>{...style, 'borderColor': 'red'};
      final segmentOptions = <String, Object?>{
        'setContext': (Object? ctx) {
          final p0 = (ctx! as Map<String, Object?>)['p0']! as PointElement;
          return p0.y >= 48 ? red : style;
        },
      };
      final line = _Line(_linePoints(1000), style, chart: _Chart());
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          acc += computeSegments(line, segmentOptions).length;
        }
        return acc;
      };
    },
    items: 1000,
    per: '_computeSegments with segment styles, 1k points',
  ),
  BenchCase(
    'data',
    'segment/bound_10k_gaps',
    () {
      final line = _Line(_linePoints(10000), _lineStyle());
      line.segments = computeSegments(line);
      const bounds = (property: 'x', start: 25000.0, end: 75000.0);
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          acc += boundSegments(line, bounds).length;
        }
        return acc;
      };
    },
    items: 10000,
    per: '_boundSegments on x, 10k points, 200 segments',
  ),
  BenchCase(
    'data',
    'collection/lookupByKey_100k_maps',
    () {
      final table = <Object?>[
        for (var i = 0; i < 100000; i++)
          <String, Object?>{'x': i.toDouble(), 'y': (i % 31).toDouble()},
      ];
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          final value = ((i * 7919) % 100000).toDouble() + 0.5;
          acc += lookupByKey(table, 'x', value).lo;
          acc += lookupByKey(table, 'x', value, true).hi;
        }
        return acc;
      };
    },
    items: 2,
    per: '_lookupByKey first + last on 100k parsed Maps',
  ),
  BenchCase(
    'data',
    'collection/lookupByKey_100k_elements',
    () {
      final table = <Object?>[
        for (var i = 0; i < 100000; i++)
          _PointElement(i * 3.0, (i % 31).toDouble()),
      ];
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          final value = ((i * 7919) % 100000) * 3.0 + 1;
          acc += lookupByKey(table, 'x', value).lo;
        }
        return acc;
      };
    },
    per: '_lookupByKey on 100k point elements',
  ),
  BenchCase(
    'data',
    'collection/rlookupByKey_100k_maps',
    () {
      final table = <Object?>[
        for (var i = 0; i < 100000; i++)
          <String, Object?>{'x': (100000 - i).toDouble()},
      ];
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          final value = ((i * 7919) % 100000).toDouble() + 0.5;
          acc += rlookupByKey(table, 'x', value).lo;
        }
        return acc;
      };
    },
    per: '_rlookupByKey on 100k Maps sorted descending',
  ),
];
