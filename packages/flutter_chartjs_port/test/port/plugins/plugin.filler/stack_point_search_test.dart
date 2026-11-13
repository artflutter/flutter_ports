// Original code, not ported from Chart.js: stack search differential checks.

import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart'
    show FillBoundary;
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.target.stack.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/index.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/stack_point_search.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

final class _Chart() implements types.Chart {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Meta(
  @override final int index,
  @override final types.Element dataset,
) implements types.ChartMeta {
  @override
  bool get hidden => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Scale(final List<types.ChartMeta> metas) implements types.Scale {
  @override
  double get bottom => 100;
  @override
  List<types.ChartMeta> getMatchingVisibleMetas([String? type]) => metas;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PointElement _point(double x, double y) => PointElement()
  ..x = x
  ..y = y
  ..cp1x = x - 0.25
  ..cp2x = x + 0.25
  ..cp1y = y - 1
  ..cp2y = y + 1;

LineElement _line(
  List<PointElement> points, {
  Object? stepped,
  double tension = 0,
}) => LineElement()
  ..points = points
  ..options = LineOptions({
    'spanGaps': false,
    'stepped': stepped,
    'tension': tension,
  });

FillerSource _source(List<LineElement> lines) => FillerSource(
  visible: true,
  index: lines.length - 1,
  fill: FillBoundary.stack,
  chart: _Chart(),
  axis: const XAxis(),
  scale: _Scale([
    for (final (index, line) in lines.indexed) _Meta(index, line),
  ]),
  line: lines.last,
);

void _compare(List<LineElement> lines) {
  final source = _source(lines);
  stackPointSearchEnabled = false;
  final expected = buildStackLine(source).points;
  stackPointSearchEnabled = true;
  final actual = buildStackLine(source).points;
  expect(actual, hasLength(expected.length));
  final originals = Set<types.PointElement>.identity()
    ..addAll(lines.expand((line) => line.points));
  for (var i = 0; i < expected.length; i++) {
    if (originals.contains(expected[i])) expect(actual[i], same(expected[i]));
    expect(actual[i].x, expected[i].x.isNaN ? isNaN : expected[i].x);
    expect(actual[i].y, expected[i].y.isNaN ? isNaN : expected[i].y);
  }
}

class _CustomLine() extends LineElement {
  int calls = 0;
  @override
  Object? interpolate(types.Point point, String property) {
    calls++;
    return super.interpolate(point, property);
  }
}

class _UnreadLine() extends LineElement {
  @override
  List<types.PointElement> get points =>
      throw StateError('unreachable line read');
}

void main() {
  tearDown(() => stackPointSearchEnabled = true);

  test('eligible exact hits reuse points, including backward queries', () {
    final target = _line([
      for (var i = 0; i < 12; i++) _point(i * 1.0, i * 2.0),
    ]);
    final source = _line([_point(0, 1), _point(1, 2)]);
    final search = StackPointSearch.create(
      source,
      source.points,
      source.segments,
      1,
    )!;
    for (final i in [0, 4, 4, 11, 2, 1, 8]) {
      final found = search.find(0, target, _point(i * 1.0, 0))!;
      expect(found.point, same(target.points[i]));
      expect(found.first, i == 0);
      expect(found.last, i == 11);
    }
    expect(search.find(0, target, _point(4.5, 0)), isNull);
    expect(search.find(0, target, _point(double.nan, 0)), isNull);
  });

  test(
    'stack geometry and identity match the original across guarded cases',
    () {
      final random = math.Random(57);
      for (var sample = 0; sample < 150; sample++) {
        final n = 4 + random.nextInt(24);
        final kind = sample % 10;
        final xs = [for (var i = 0; i < n; i++) i * 1.0];
        if (kind == 1) xs[2] = xs[1];
        if (kind == 2) xs[2] = xs[1] + 5e-7;
        if (kind == 3) xs[2] = double.nan;
        if (kind == 4) xs.setAll(0, xs.reversed.toList());
        final lower = _line(
          [
            for (final (i, x) in xs.indexed)
              _point(x, random.nextDouble() * 40)..skip = kind == 5 && i == 2,
          ],
          stepped: kind == 6 ? 'middle' : false,
          tension: kind == 7 ? 0.3 : 0,
        );
        final upper = _line([
          for (var i = 0; i < n; i++)
            _point(kind == 8 ? i + 0.5 : i * 1.0, random.nextDouble() * 20),
        ]);
        if (kind == 9) lower.loop = true;
        _compare([lower, upper]);
      }
    },
  );

  test('a new build observes in-place point changes', () {
    final lower = _line([for (var i = 0; i < 8; i++) _point(i * 1.0, 2)]);
    final upper = _line([for (var i = 0; i < 8; i++) _point(i * 1.0, 1)]);
    _compare([lower, upper]);
    (lower.points[3] as PointElement).y = 20;
    (lower.points[4] as PointElement).x = 3;
    _compare([lower, upper]);
  });

  test('custom interpolation receives the original calls', () {
    final lower = _CustomLine()
      ..points = [for (var i = 0; i < 8; i++) _point(i * 1.0, 2)]
      ..options = LineOptions();
    final upper = _line([for (var i = 0; i < 8; i++) _point(i * 1.0, 1)]);
    final source = _source([lower, upper]);
    stackPointSearchEnabled = false;
    buildStackLine(source);
    final expectedCalls = lower.calls;
    lower.calls = 0;
    stackPointSearchEnabled = true;
    buildStackLine(source);
    expect(lower.calls, expectedCalls);
    expect(lower.calls, greaterThan(0));
  });
  test('an unreached lower line stays unread', () {
    final lower = _line([for (var i = 0; i < 8; i++) _point(i * 1.0, 2)]);
    final upper = _line([_point(2, 1), _point(3, 1), _point(4, 1)]);
    final result = buildStackLine(_source([_UnreadLine(), lower, upper]));
    expect(result.points, [lower.points[2], lower.points[3], lower.points[4]]);
  });

  test('a foreign target disables earlier indexed reuse before fallback', () {
    final lower = _line([for (var i = 0; i < 8; i++) _point(i * 1.0, 2)]);
    final upper = _line([_point(2, 1), _point(3, 1)]);
    final search = StackPointSearch.create(
      upper,
      upper.points,
      upper.segments,
      2,
    )!;
    expect(search.find(0, lower, upper.points[0]), isNotNull);
    expect(search.find(1, _CustomLine(), upper.points[0]), isNull);
    expect(search.find(0, lower, upper.points[1]), isNull);
  });
}
