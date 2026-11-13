// Original code, not ported from Chart.js: the run of point markers.
@TestOn('vm')
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show CirclePointStyle, RectPointStyle;
// Canvas observations are deliberately separate from mutations.
// ignore_for_file: cascade_invocations

import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../canvas/pixel_compare.dart';

/// A point of a user class: the run stops at it.
class _UserPoint extends PointElement;

/// A point of a user class that gives the type of the built-in class.
class _DisguisedPoint extends PointElement {
  @override
  Type get runtimeType => PointElement;
}

final class _Area implements ChartArea {
  @override
  double get left => 10;
  @override
  double get top => 8;
  @override
  double get right => 130;
  @override
  double get bottom => 120;
  @override
  double get width => right - left;
  @override
  double get height => bottom - top;
}

const _colors = [
  ui.Color(0xff4f6bed),
  ui.Color(0x80dd4400),
  ui.Color(0xff119944),
];

Object _options(math.Random r) {
  final kind = r.nextInt(24);
  final radius = switch (r.nextInt(8)) {
    0 => 0.05,
    1 => 0.0,
    2 => 1.5,
    3 => double.nan,
    _ => 2.0 + r.nextInt(3),
  };
  final values = <String, Object?>{
    'radius': radius,
    'hoverRadius': r.nextBool() ? 4.0 : 0.0,
    'borderWidth': r.nextInt(3) == 0 ? 1.5 : 0.0,
    'rotation': 0.0,
    'pointStyle': kind == 0 ? const RectPointStyle() : const CirclePointStyle(),
    'backgroundColor': ChartPaint.solid(_colors[r.nextInt(_colors.length)]),
    'borderColor': ChartPaint.solid(_colors[r.nextInt(_colors.length)]),
  };
  // An option that is absent, of another type or a plain Map.
  if (kind == 1) values.remove('borderColor');
  if (kind == 2) values['borderWidth'] = '2';
  if (kind == 3) values.remove('backgroundColor');
  return kind == 4 ? values : PointOptions(values);
}

List<types.Element> _elements(int seed) {
  final r = math.Random(seed);
  final options = [for (var i = 0; i <= r.nextInt(3); i++) _options(r)];
  final mixed = r.nextInt(3) == 0;
  return [
    for (var i = 0; i < 1 + r.nextInt(70); i++)
      () {
        final point =
            mixed && r.nextInt(40) == 0 ? _UserPoint() : PointElement()
              ..x = switch (r.nextInt(30)) {
                0 => double.nan,
                1 => -40,
                2 => double.infinity,
                _ => r.nextDouble() * 140,
              }
              ..y = r.nextInt(25) == 0 ? 400 : r.nextDouble() * 130
              ..options = options[mixed ? r.nextInt(options.length) : 0]
              ..active = r.nextInt(12) == 0;
        if (r.nextInt(12) == 0) point.skip = true;
        if (r.nextInt(14) == 0) point.hidden = r.nextBool() ? true : 0;
        return point;
      }(),
  ];
}

void _state(UiCanvasContext ctx, int kind) {
  switch (kind) {
    case 1:
      ctx.setTransform(2, 0, 0, 2, 0, 0);
    case 2:
      ctx.setTransform(1, 0, 0, 1, 3.5, 2.25);
    case 3:
      ctx.setTransform(.8, .6, -.6, .8, 30, 0);
    case 4:
      ctx.setTransform(2, 0, 0, 1, 0, 0);
    case 5:
      ctx.globalAlpha = .5;
    case 6:
      ctx.setLineDash(const [2, 1]);
    case 7:
      ctx.globalCompositeOperation = CanvasCompositeOperation.multiply;
    case 8:
      ctx.setTransform(-1, 0, 0, 1, 150, 0);
    case 9:
      ctx.setTransform(1, 0, 0, 1, 100000000, 0);
  }
}

/// The loop of `DatasetController.draw`, from the element [from].
void _loop(
  UiCanvasContext ctx,
  List<types.Element> elements,
  int from,
  List<types.Element> active, {
  required bool activeOnTop,
}) {
  final area = _Area();
  for (var i = from; i < elements.length; i++) {
    final element = elements[i] as PointElement;
    final hidden = element.hidden;
    if (hidden == true || (hidden is num && hidden != 0)) continue;
    if (element.active && activeOnTop) {
      active.add(element);
    } else {
      element.draw(ctx, area);
    }
  }
  for (final element in active) {
    (element as PointElement).draw(ctx, area);
  }
}

/// What the current path and the styles leave for the next draw: a stroke and
/// a fill of the current path, in new colors.
List<Object?> _rest(UiCanvasContext ctx) {
  final state = <Object?>[
    ctx.fillStyle,
    ctx.strokeStyle,
    ctx.lineWidth,
    ctx.debugPath.hasSingleCircle,
    if (ctx.debugPath.hasSingleCircle) ...[
      ctx.debugPath.circleX,
      ctx.debugPath.circleY,
      ctx.debugPath.circleRadius,
    ],
  ];
  ctx.strokeStyle = const ui.Color(0xff000000);
  ctx.lineWidth = 1;
  ctx.stroke();
  return state;
}

void main() {
  for (var seed = 0; seed < 600; seed++) {
    test('the run draws what the elements draw, seed $seed', () async {
      final kind = seed % 12;
      final activeOnTop = seed.isEven;
      List<Object?>? before;
      List<Object?>? after;
      final ordinary = await renderContext((ctx) {
        _state(ctx, kind);
        _loop(ctx, _elements(seed), 0, [], activeOnTop: activeOnTop);
        before = _rest(ctx);
      });
      final run = await renderContext((ctx) {
        _state(ctx, kind);
        final elements = _elements(seed);
        final active = <types.Element>[];
        final next = (elements.first as PointElement).drawCircleRun(
          ctx,
          _Area(),
          elements,
          0,
          elements.length,
          active,
          activeOnTop: activeOnTop,
        );
        _loop(ctx, elements, next, active, activeOnTop: activeOnTop);
        after = _rest(ctx);
      });
      expect(after, before);
      final diff = comparePixels(ordinary, run);
      expect(diff.differing, 0, reason: '$diff');
    });
  }

  test('a plain run handles each element and builds no path', () {
    final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
    addTearDown(ctx.dispose);
    final options = PointOptions(<String, Object?>{
      'radius': 3.0,
      'hoverRadius': 4.0,
      'borderWidth': 1.0,
      'pointStyle': const CirclePointStyle(),
      'backgroundColor': ChartPaint.solid(_colors[0]),
      'borderColor': ChartPaint.solid(_colors[1]),
    });
    final elements = <types.Element>[
      for (var i = 0; i < 2000; i++)
        PointElement()
          ..x = 10.0 + i % 100
          ..y = 10.0 + i % 90
          ..options = options,
    ];
    final next = (elements.first as PointElement).drawCircleRun(
      ctx,
      _Area(),
      elements,
      0,
      elements.length,
      [],
      activeOnTop: true,
    );
    expect(next, elements.length);
    expect(ctx.debugPath.debugBuilt, isFalse);
    expect(ctx.debugPath.hasSingleCircle, isTrue);
    expect(ctx.debugPath.circleX, (elements.last as PointElement).x);
    expect(ctx.fillStyle, _colors[0]);
    expect(ctx.strokeStyle, _colors[1]);
    expect(ctx.lineWidth, 1);
  });

  test('a point with no options goes to the ordinary loop', () {
    final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
    addTearDown(ctx.dispose);
    final elements = <types.Element>[
      PointElement()
        ..x = 40
        ..y = 40,
    ];
    final next = (elements.first as PointElement).drawCircleRun(
      ctx,
      _Area(),
      elements,
      0,
      1,
      [],
      activeOnTop: true,
    );
    // The ordinary loop gets the element, and its draw throws.
    expect(next, 0);
    expect(
      () => (elements.first as PointElement).draw(ctx, _Area()),
      throwsA(isA<TypeError>()),
    );
  });

  test('a class that overrides runtimeType ends the run', () {
    final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
    addTearDown(ctx.dispose);
    final elements = <types.Element>[
      _DisguisedPoint()
        ..x = 40
        ..y = 40
        ..options = PointOptions(<String, Object?>{
          'radius': 3.0,
          'pointStyle': const CirclePointStyle(),
          'hoverRadius': 0.0,
          'borderWidth': 0.0,
          'backgroundColor': ChartPaint.solid(_colors[0]),
        }),
    ];
    expect(
      (elements.first as PointElement).drawCircleRun(
        ctx,
        _Area(),
        elements,
        0,
        1,
        [],
        activeOnTop: true,
      ),
      0,
    );
  });

  test('no draw leaves the styles and the path', () {
    final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
    addTearDown(ctx.dispose);
    ctx.fillStyle = _colors[2];
    final elements = <types.Element>[
      PointElement()
        ..x = 500
        ..y = 500
        ..options = PointOptions(<String, Object?>{
          'radius': 3.0,
          'pointStyle': const CirclePointStyle(),
          'hoverRadius': 0.0,
          'borderWidth': 0.0,
          'backgroundColor': ChartPaint.solid(_colors[0]),
        }),
    ];
    final next = (elements.first as PointElement).drawCircleRun(
      ctx,
      _Area(),
      elements,
      0,
      1,
      [],
      activeOnTop: true,
    );
    expect(next, 1);
    expect(ctx.fillStyle, _colors[2]);
    expect(ctx.debugPath.isEmpty, isTrue);
  });

  test('a throwing color keeps the path of the last drawn circle', () {
    final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
    addTearDown(ctx.dispose);
    PointOptions options(Object? color) => PointOptions(<String, Object?>{
      'radius': 3.0,
      'pointStyle': const CirclePointStyle(),
      'hoverRadius': 0.0,
      'borderWidth': 0.0,
      'backgroundColor': color,
    });
    final elements = <types.Element>[
      PointElement()
        ..x = 40
        ..y = 40
        ..options = options(_colors[0]),
      PointElement()
        ..x = 50
        ..y = 50
        ..options = options('red'),
    ];
    expect(
      () => (elements.first as PointElement).drawCircleRun(
        ctx,
        _Area(),
        elements,
        0,
        2,
        [],
        activeOnTop: true,
      ),
      throwsArgumentError,
    );
    expect(ctx.debugPath.circleX, 40);
  });
}
