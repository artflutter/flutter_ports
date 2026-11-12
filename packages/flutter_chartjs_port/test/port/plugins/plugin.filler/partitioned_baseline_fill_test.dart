// Original code, not ported from Chart.js: partitioned fill regressions.
@TestOn('vm')
library;

// Canvas observations are deliberately separate from mutations.
// ignore_for_file: cascade_invocations

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_path.dart'
    show deferredPathCommands;
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart'
    show DefaultCubicInterpolationMode;
import 'package:flutter_chartjs_port/src/helpers/helpers.segment.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/partitioned_baseline_fill.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../../canvas/pixel_compare.dart';

class _CustomPoint extends PointElement {
  @override
  double get x => throw StateError('custom coordinate must not be probed');
}

LineElement _line() => LineElement()
  ..options = LineOptions({
    'tension': .35,
    'stepped': false,
    'cubicInterpolationMode': const DefaultCubicInterpolationMode(),
  })
  ..points = <types.PointElement>[
    for (var i = 0; i < 1057; i++)
      PointElement()
        ..x = 10 + i * .12
        ..y = 50 + 12 * math.sin(i * .31)
        ..cp1x = 10 + i * .12 - .04
        ..cp1y = 48 + 12 * math.sin(i * .31)
        ..cp2x = 10 + i * .12 + .04
        ..cp2y = 52 + 12 * math.sin(i * .31),
  ];

LineElement _boundary(LineElement line) =>
    LineElement()
      ..points = <types.PointElement>[
        PointElement()
          ..x = line.points.first.x
          ..y = 125,
        PointElement()
          ..x = line.points.last.x
          ..y = 125,
      ];

bool _try(UiCanvasContext ctx, LineElement line, LineElement boundary) =>
    tryPartitionedBaselineFill(
      ctx,
      line: line,
      target: boundary,
      source: createBoundarySegment(0, line.points.length - 1),
      start: PointElement()..x = 10,
      end: PointElement()..x = 10 + 1056 * .12,
    );

void _original(UiCanvasContext ctx, LineElement line) {
  ctx.beginPath();
  line.pathSegment(ctx, createBoundarySegment(0, line.points.length - 1));
  ctx.lineTo(line.points.last.x, 125);
  ctx.lineTo(line.points.first.x, 125);
  ctx.closePath();
}

void main() {
  setUp(() => partitionedBaselineFillEnabled = true);
  tearDown(() => partitionedBaselineFillEnabled = true);

  for (final transform in [false, true]) {
    test(
      'equivalent fill and original current-path stroke ($transform)',
      () async {
        final line = _line();
        final boundary = _boundary(line);
        Future<Render> draw({required bool optimized}) => renderContext((ctx) {
          if (transform) ctx.setTransform(.9, 0, 0, .9, .25, .5);
          ctx.beginPath();
          ctx.rect(5, 5, 145, 140);
          ctx.clip();
          ctx.fillStyle = const ui.Color(0x804f6bed);
          ctx.globalAlpha = .7;
          _original(ctx, line);
          if (optimized) {
            expect(_try(ctx, line, boundary), isTrue);
          } else {
            ctx.fill();
          }
          // A changed current path would stroke every interior partition edge.
          ctx.strokeStyle = const ui.Color(0xffdd4400);
          ctx.lineWidth = .6;
          ctx.stroke();
        });
        final original = await draw(optimized: false);
        final optimized = await draw(optimized: true);
        final difference = comparePixels(original, optimized);
        // Software Skia may round AA at internal contour boundaries slightly
        // differently; reject any material color, coverage or stroke change.
        expect(difference.maxChannel, lessThanOrEqualTo(3));
        expect(difference.differing, lessThan(200));
        expect(difference.solidDiffering, 0);
        expect(difference.inkRatio, lessThan(.0002));
      },
    );
  }

  test('a partitioned fill builds no engine path of the original', () {
    final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
    addTearDown(ctx.dispose);
    final line = _line();
    ctx.fillStyle = const ui.Color(0x804f6bed);
    ctx.beginPath();
    deferPathOfPartitionedFill(ctx, line);
    line.pathSegment(ctx, createBoundarySegment(0, line.points.length - 1));
    ctx.lineTo(line.points.last.x, 125);
    ctx.lineTo(line.points.first.x, 125);
    ctx.closePath();
    expect(_try(ctx, line, _boundary(line)), isTrue);
    expect(ctx.debugPath.debugBuilt, isFalse);
    // The next path takes the buffers of a short path again.
    ctx.beginPath();
    expect(ctx.debugPath.debugBuilt, isFalse);
    for (var i = 0; i <= deferredPathCommands; i++) {
      ctx.lineTo(i.toDouble(), 3);
    }
    expect(ctx.debugPath.debugBuilt, isTrue);
  });

  test('a read of the deferred original gets the same path', () async {
    final line = _line();
    final boundary = _boundary(line);
    Future<Render> draw({required bool defer, required bool partition}) =>
        renderContext((ctx) {
          ctx.setTransform(.9, 0, 0, .9, .25, .5);
          ctx.fillStyle = const ui.Color(0x804f6bed);
          ctx.beginPath();
          if (defer) deferPathOfPartitionedFill(ctx, line);
          line.pathSegment(
            ctx,
            createBoundarySegment(0, line.points.length - 1),
          );
          ctx.lineTo(line.points.last.x, 125);
          ctx.lineTo(line.points.first.x, 125);
          ctx.closePath();
          if (partition) {
            expect(_try(ctx, line, boundary), isTrue);
          } else {
            ctx.fill();
          }
          ctx.strokeStyle = const ui.Color(0xffdd4400);
          ctx.lineWidth = .6;
          ctx.stroke();
        });
    expect(
      comparePixels(
        await draw(defer: false, partition: false),
        await draw(defer: true, partition: false),
      ).differing,
      0,
    );
    expect(
      comparePixels(
        await draw(defer: false, partition: true),
        await draw(defer: true, partition: true),
      ).differing,
      0,
    );
  });

  test('the context of long paths in pieces takes no compound path', () {
    final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
    addTearDown(ctx.dispose);
    addTearDown(() => UiCanvasContext.debugDrawLongPathsInPieces = false);
    UiCanvasContext.debugDrawLongPathsInPieces = true;
    final line = _line();
    final before = partitionedBaselineFillDraws;
    ctx.fillStyle = const ui.Color(0x804f6bed);
    expect(_try(ctx, line, _boundary(line)), isFalse);
    expect(partitionedBaselineFillDraws, before);
    // The fill path stays out of the engine from a lower count of points.
    final short = LineElement()
      ..options = LineOptions(<String, Object?>{'tension': .4})
      ..points = <types.PointElement>[
        for (var i = 0; i < 300; i++)
          PointElement()
            ..x = i * .5
            ..y = 40.0 + i % 7
            ..cp1x = i * .5 - .1
            ..cp1y = 40.0 + i % 7
            ..cp2x = i * .5 + .1
            ..cp2y = 40.0 + i % 7,
      ];
    ctx.beginPath();
    deferPathOfPartitionedFill(ctx, short);
    short.pathSegment(ctx, createBoundarySegment(0, 299));
    expect(ctx.debugPath.debugBuilt, isFalse);
  });

  test('a short line or a user class keeps the eager path', () {
    final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
    addTearDown(ctx.dispose);
    final short = LineElement()
      ..options = LineOptions(<String, Object?>{'tension': .4})
      ..points = <types.PointElement>[
        for (var i = 0; i < 100; i++)
          PointElement()
            ..x = i.toDouble()
            ..y = i % 7
            ..cp1x = i - .2
            ..cp1y = i % 7
            ..cp2x = i + .2
            ..cp2y = i % 7,
      ];
    ctx.beginPath();
    deferPathOfPartitionedFill(ctx, short);
    short.pathSegment(ctx, createBoundarySegment(0, 99));
    expect(ctx.debugPath.debugBuilt, isTrue);
  });

  test('unsupported geometry and options decline before drawing', () {
    final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
    addTearDown(ctx.dispose);
    final line = _line();
    final boundary = _boundary(line);
    final point = line.points[300] as PointElement;
    point.skip = true;
    expect(_try(ctx, line, boundary), isFalse);
    point.skip = false;
    point.stop = true;
    expect(_try(ctx, line, boundary), isFalse);
    point.stop = false;
    final x = point.x;
    point.x = 0;
    expect(_try(ctx, line, boundary), isFalse);
    point.x = x;
    point.cp1y = double.nan;
    expect(_try(ctx, line, boundary), isFalse);
    point.cp1y = 50;
    point.cp1y = 150;
    expect(_try(ctx, line, boundary), isFalse);
    point.cp1y = 50;
    (line.options! as LineOptions)['stepped'] = true;
    expect(_try(ctx, line, boundary), isFalse);
    (line.options! as LineOptions)['stepped'] = false;
    (boundary.points.last as PointElement).y = 124;
    expect(_try(ctx, line, boundary), isFalse);
  });

  test('flat curves keep the inexpensive original fill', () {
    final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
    addTearDown(ctx.dispose);
    final line = _line();
    final boundary = _boundary(line);
    for (final point in line.points.cast<PointElement>()) {
      point.y = 50;
      point.cp1y = 50;
      point.cp2y = 50;
    }
    expect(_try(ctx, line, boundary), isFalse);
  });

  test('custom point getters are not preflighted', () {
    final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
    addTearDown(ctx.dispose);
    final line = _line();
    final boundary = _boundary(line);
    line.points[300] = _CustomPoint();
    expect(_try(ctx, line, boundary), isFalse);
  });

  test('gradients, rotation and compositing keep the original path', () {
    final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
    addTearDown(ctx.dispose);
    final line = _line();
    final boundary = _boundary(line);
    final gradient = ctx.createLinearGradient(0, 0, 160, 0)
      ..addColorStop(0, const ui.Color(0xff000000))
      ..addColorStop(1, const ui.Color(0xffffffff));
    ctx.fillStyle = gradient;
    expect(_try(ctx, line, boundary), isFalse);
    ctx.fillStyle = const ui.Color(0xff000000);
    ctx.rotate(.1);
    expect(_try(ctx, line, boundary), isFalse);
    ctx.resetTransform();
    ctx.globalCompositeOperation = CanvasCompositeOperation.copy;
    expect(_try(ctx, line, boundary), isFalse);
    var called = false;
    expect(ctx.tryFillPartitionedPath((_) => called = true), isFalse);
    expect(called, isFalse);
  });
}
