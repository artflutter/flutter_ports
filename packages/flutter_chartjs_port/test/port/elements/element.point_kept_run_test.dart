// Original code, not ported from Chart.js: the kept run of point markers.
@TestOn('vm')
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show CirclePointStyle, RectPointStyle;
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart' show immutable;

import '../canvas/pixel_compare.dart';

// Canvas observations are deliberately separate from mutations.
// ignore_for_file: cascade_invocations

final class _Area() implements ChartArea {
  @override
  double get left => 10;
  @override
  double get top => 8;
  @override
  double get right => 150;
  @override
  double get bottom => 140;
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

const _wide = ui.Color.from(
  alpha: 1,
  red: 0.8,
  green: 0.2,
  blue: 0.2,
  colorSpace: ui.ColorSpace.displayP3,
);

const _gradient = ChartGradient.linear(ui.Offset.zero, ui.Offset(0, 140), [
  ui.Color(0xff4f6bed),
  ui.Color(0x80dd4400),
]);

/// A paint of [color], or of an equal color that is another object.
ChartPaint _solid(math.Random r, ui.Color color) =>
    ChartPaint.solid(r.nextInt(4) == 0 ? ui.Color(color.toARGB32()) : color);

/// Points with options of their own, as a scatter chart gives them: equal
/// values, a color for each point, and now and then another size, another
/// style, a paint that is not solid or a color that the batch does not keep.
List<types.Element> _elements(int seed) {
  final r = math.Random(seed);
  final radius = const [2.0, 3.0, 4.5][r.nextInt(3)];
  final border = r.nextInt(3) == 0 ? 0.0 : 1.5;
  final base = <String, Object?>{
    'radius': radius,
    'hoverRadius': 4.0,
    'borderWidth': border,
    'rotation': 0.0,
    'pointStyle': const CirclePointStyle(),
    'backgroundColor': ChartPaint.solid(_colors[0]),
    'borderColor': ChartPaint.solid(_colors[1]),
  };
  final mode = r.nextInt(3);
  final rare = 8 + r.nextInt(60);
  final elements = <types.Element>[];
  PointOptions? last;
  for (var i = 0; i < 1 + r.nextInt(150); i++) {
    final values = Map<String, Object?>.of(base);
    switch (mode) {
      case 1:
        values['backgroundColor'] = _solid(r, _colors[i % 2]);
        values['borderColor'] = _solid(r, _colors[(i + 1) % 2]);
      case 2:
        values['backgroundColor'] = _solid(r, _colors[r.nextInt(3)]);
        if (r.nextBool()) {
          values['borderColor'] = _solid(r, _colors[r.nextInt(3)]);
        }
    }
    var x = 4 + r.nextDouble() * 152;
    final y = 2 + r.nextDouble() * 144;
    var share = false;
    var skip = false;
    if (r.nextInt(rare) == 0) {
      switch (r.nextInt(12)) {
        case 0:
          values['backgroundColor'] = _gradient;
        case 1:
          values['borderColor'] = _gradient;
        case 2:
          values.remove('borderColor');
        case 3:
          values['backgroundColor'] = const ChartPaint.unchanged();
        case 4:
          values['radius'] = radius + 1;
        case 5:
          values['hoverRadius'] = 9.0;
        case 6:
          values['borderWidth'] = border + 1;
        case 7:
          values['pointStyle'] = const RectPointStyle();
        case 8:
          values['backgroundColor'] = const ChartPaint.solid(_wide);
        case 9:
          share = last != null;
        case 10:
          skip = true;
        case 11:
          x = 400;
      }
    }
    final options = share ? last! : PointOptions(values);
    last = options;
    final point = PointElement()
      ..x = x
      ..y = y
      ..options = options
      ..active = r.nextInt(40) == 0;
    if (skip) point.skip = true;
    elements.add(point);
  }
  return elements;
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
      ctx.globalAlpha = .5;
    case 5:
      ctx.fillStyle = _colors[2];
      ctx.strokeStyle = _colors[2];
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

/// The loop with the runs, as `DatasetController.draw` offers each element
/// that the ordinary loop does not take to a new run.
void _runLoop(
  UiCanvasContext ctx,
  List<types.Element> elements, {
  required bool activeOnTop,
}) {
  final area = _Area();
  final active = <types.Element>[];
  var i = 0;
  while (i < elements.length) {
    final next = (elements[i] as PointElement).drawCircleRun(
      ctx,
      area,
      elements,
      i,
      elements.length,
      active,
      activeOnTop: activeOnTop,
    );
    if (next < elements.length) {
      final element = elements[next] as PointElement;
      if (element.active && activeOnTop) {
        active.add(element);
      } else {
        element.draw(ctx, area);
      }
    }
    i = next + 1;
  }
  for (final element in active) {
    (element as PointElement).draw(ctx, area);
  }
}

/// What the styles and the current path leave for the next draw. The styles
/// compare by identity: the next draw reads these objects.
List<Object?> _rest(UiCanvasContext ctx) => [
  _Same(ctx.fillStyle),
  _Same(ctx.strokeStyle),
  ctx.lineWidth,
  ctx.debugPath.hasSingleCircle,
  if (ctx.debugPath.hasSingleCircle) ...[
    ctx.debugPath.circleX,
    ctx.debugPath.circleY,
    ctx.debugPath.circleRadius,
  ],
];

/// A value that equals another only when both hold the identical object.
@immutable
final class const _Same(final Object? value) {
  @override
  bool operator ==(Object other) =>
      other is _Same && identical(other.value, value);

  @override
  int get hashCode => identityHashCode(value);

  @override
  String toString() => 'same($value)';
}

/// A copy of an argument of a native draw call, at the call.
String _describe(Object? value) => switch (value) {
  final ui.Paint p =>
    'Paint(${p.color}, ${p.style}, ${p.strokeWidth}, ${p.blendMode}, '
        '${p.filterQuality}, ${p.isAntiAlias}, ${p.shader != null})',
  final Float32List list => '${List<double>.of(list)}',
  final Int32List list => '${List<int>.of(list)}',
  final ui.Image image => 'Image(${image.width} x ${image.height})',
  final ui.Path path => 'Path(${path.getBounds()})',
  _ => '$value',
};

/// A canvas that logs each native call with its arguments and draws nothing.
final class _LogCanvas(final List<String> _log, ui.PictureRecorder recorder)
    implements ui.Canvas {
  this {
    ui.Canvas(recorder);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final arguments = [
      for (final argument in invocation.positionalArguments)
        _describe(argument),
      for (final MapEntry(:key, :value) in invocation.namedArguments.entries)
        '$key: ${_describe(value)}',
    ];
    _log.add('${invocation.memberName}(${arguments.join(', ')})');
    return null;
  }
}

/// The native calls, the pending circles and the styles after a run loop of
/// [elements], with or without the kept colors.
(List<String>, int, List<Object?>, int) _observe(
  List<types.Element> elements,
  int kind, {
  required bool keep,
  required bool activeOnTop,
}) {
  final calls = <String>[];
  final keepBefore = UiCanvasContext.debugKeepRunColors;
  UiCanvasContext.debugKeepRunColors = keep;
  UiCanvasContext.debugRecordingCanvas = (recorder) =>
      _LogCanvas(calls, recorder);
  final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
  try {
    _state(ctx, kind);
    _runLoop(ctx, elements, activeOnTop: activeOnTop);
    final pending = ctx.debugPendingCircles;
    final rest = _rest(ctx);
    final recorder = ui.PictureRecorder();
    ctx.paint(ui.Canvas(recorder), ui.Offset.zero, 1, 1);
    recorder.endRecording().dispose();
    return (calls, pending, rest, ctx.debugKeptRunCircles);
  } finally {
    ctx.dispose();
    UiCanvasContext.debugRecordingCanvas = null;
    UiCanvasContext.debugKeepRunColors = keepBefore;
  }
}

/// The fill color of the options of [point].
ui.Color _fillOf(PointElement point) =>
    (point.options! as PointOptions).backgroundColor!.color;

extension on ChartPaint {
  ui.Color get color => (this as SolidChartPaint).color;
}

/// A color of a program whose value changes between two draws. The class
/// `ui.Color` is immutable, a subclass need not be. Its channels read [argb].
final class _ChangingColor() extends ui.Color {
  this : super(0);

  int argb = 0;

  @override
  double get a => (argb >> 24 & 0xff) / 255;
  @override
  double get r => (argb >> 16 & 0xff) / 255;
  @override
  double get g => (argb >> 8 & 0xff) / 255;
  @override
  double get b => (argb & 0xff) / 255;
}

PointElement _point(double x, double y, PointOptions options) => PointElement()
  ..x = x
  ..y = y
  ..options = options;

PointOptions _options(
  ChartPaint fill, {
  ChartPaint? stroke,
  double borderWidth = 0,
  Object pointStyle = const CirclePointStyle(),
}) => PointOptions(<String, Object?>{
  'radius': 3.0,
  'hoverRadius': 4.0,
  'borderWidth': borderWidth,
  'pointStyle': pointStyle,
  'backgroundColor': fill,
  'borderColor': stroke ?? ChartPaint.solid(_colors[1]),
});

void main() {
  for (var seed = 0; seed < 300; seed++) {
    test('the kept run draws what the elements draw, seed $seed', () async {
      final kind = seed % 6;
      final activeOnTop = seed % 4 < 2;
      // One list for each form: the styles compare by identity.
      final elements = _elements(seed);
      // The kept colors against the setters and a new start for each
      // options object: the same native calls and the same styles.
      final kept = _observe(
        elements,
        kind,
        keep: true,
        activeOnTop: activeOnTop,
      );
      final restarted = _observe(
        elements,
        kind,
        keep: false,
        activeOnTop: activeOnTop,
      );
      expect(restarted.$4, 0);
      expect(kept.$2, restarted.$2);
      expect(kept.$3, restarted.$3);
      expect(kept.$1.length, restarted.$1.length);
      for (var i = 0; i < kept.$1.length; i++) {
        expect(kept.$1[i], restarted.$1[i], reason: 'call $i');
      }
      // The kept run against the draw of each element: the same pixels
      // and styles.
      List<Object?>? before;
      List<Object?>? after;
      final ordinary = await renderContext((ctx) {
        _state(ctx, kind);
        _loop(ctx, elements, 0, [], activeOnTop: activeOnTop);
        before = _rest(ctx);
      });
      final run = await renderContext((ctx) {
        _state(ctx, kind);
        _runLoop(ctx, elements, activeOnTop: activeOnTop);
        after = _rest(ctx);
      });
      expect(after, before);
      final diff = comparePixels(ordinary, run);
      expect(diff.differing, 0, reason: '$diff');
    });
  }

  test('the seeds take the kept colors', () {
    var kept = 0;
    for (var seed = 0; seed < 300; seed++) {
      kept += _observe(
        _elements(seed),
        seed % 6,
        keep: true,
        activeOnTop: seed % 4 < 2,
      ).$4;
    }
    expect(kept, greaterThan(3000));
  });

  group('the kept run', () {
    test('holds one run over options of equal values', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      final elements = <types.Element>[
        for (var i = 0; i < 400; i++)
          _point(
            12.0 + i % 120,
            12.0 + i % 110,
            _options(
              ChartPaint.solid(_colors[0]),
              stroke: ChartPaint.solid(_colors[1]),
              borderWidth: 1,
            ),
          ),
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
      expect(ctx.debugCircleRunHeld, isTrue);
      expect(ctx.debugPendingCircles, 800);
      expect(ctx.debugKeptRunCircles, 399);
      // The styles of the last point, as after its draw.
      final last = elements.last as PointElement;
      expect(ctx.fillStyle, same(_fillOf(last)));
      expect(
        ctx.strokeStyle,
        same((last.options! as PointOptions).borderColor!.color),
      );
      expect(ctx.lineWidth, 1);
      expect(ctx.debugPath.circleX, last.x);
    });

    test('keeps the run when only the colors change', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      final elements = <types.Element>[
        for (var i = 0; i < 300; i++)
          _point(
            12.0 + i % 120,
            12.0 + i % 110,
            _options(ChartPaint.solid(_colors[i % 2])),
          ),
      ];
      (elements.first as PointElement).drawCircleRun(
        ctx,
        _Area(),
        elements,
        0,
        elements.length,
        [],
        activeOnTop: true,
      );
      expect(ctx.debugCircleRunHeld, isTrue);
      expect(ctx.debugPendingCircles, 300);
      // The second circle gives the batch a color for each instance
      // through the setters and a new start.
      expect(ctx.debugKeptRunCircles, 298);
      expect(ctx.fillStyle, same(_colors[1]));
    });

    test('a gradient in the middle takes the setters and ends the run', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      final elements = <types.Element>[
        _point(20, 20, _options(ChartPaint.solid(_colors[0]))),
        _point(30, 30, _options(ChartPaint.solid(_colors[1]))),
        _point(40, 40, _options(_gradient)),
        _point(50, 50, _options(ChartPaint.solid(_colors[0]))),
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
      // The shader fill declines the run at the third point, after the
      // setters of that point.
      expect(next, 2);
      expect(ctx.fillStyle, same(_gradient));
      expect(ctx.debugPath.circleX, 30);
    });

    test('a break by another style leaves the styles of the last circle', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      final elements = <types.Element>[
        _point(20, 20, _options(ChartPaint.solid(_colors[0]))),
        _point(30, 30, _options(ChartPaint.solid(_colors[1]))),
        _point(40, 40, _options(ChartPaint.solid(_colors[2]))),
        _point(
          50,
          50,
          _options(
            ChartPaint.solid(_colors[0]),
            pointStyle: const RectPointStyle(),
          ),
        ),
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
      expect(next, 3);
      expect(ctx.fillStyle, same(_colors[2]));
      expect(ctx.debugPath.circleX, 40);
    });

    test('an unchanged paint takes the setters after the owed ones', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      final elements = <types.Element>[
        _point(20, 20, _options(ChartPaint.solid(_colors[0]))),
        _point(30, 30, _options(ChartPaint.solid(_colors[1]))),
        _point(35, 35, _options(ChartPaint.solid(_colors[0]))),
        // The setter ignores the paint: the fill stays the color of the
        // third point, which the run owed.
        _point(40, 40, _options(const ChartPaint.unchanged())),
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
      expect(next, 4);
      expect(ctx.fillStyle, same(_colors[0]));
      expect(ctx.debugPendingCircles, 4);
      expect(ctx.debugKeptRunCircles, 1);
    });

    test('keeps no color value from an earlier run', () async {
      // Two runs on one canvas, with a change of the color between them:
      // the second run draws the color as it is then, as each element
      // draw does.
      final changing = _ChangingColor()..argb = 0xff4f6bed;
      final elements = <types.Element>[
        for (var i = 0; i < 40; i++)
          _point(
            12.0 + i * 3,
            12.0 + i * 3,
            _options(
              ChartPaint.solid(i.isEven ? changing : _colors[2]),
              stroke: ChartPaint.solid(_colors[1]),
              borderWidth: 1,
            ),
          ),
      ];
      Future<Render> render({required bool keep}) async {
        final keepBefore = UiCanvasContext.debugKeepRunColors;
        UiCanvasContext.debugKeepRunColors = keep;
        try {
          changing.argb = 0xff4f6bed;
          return await renderContext((ctx) {
            _runLoop(ctx, elements, activeOnTop: true);
            changing.argb = 0xffdd4400;
            _runLoop(ctx, elements, activeOnTop: true);
          });
        } finally {
          UiCanvasContext.debugKeepRunColors = keepBefore;
        }
      }

      final restarted = await render(keep: false);
      final kept = await render(keep: true);
      final diff = comparePixels(restarted, kept);
      expect(diff.differing, 0, reason: '$diff');
    });

    test('a color that the batch does not keep ends the run', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      final elements = <types.Element>[
        _point(20, 20, _options(ChartPaint.solid(_colors[0]))),
        _point(30, 30, _options(const ChartPaint.solid(_wide))),
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
      expect(next, 1);
      expect(ctx.fillStyle, same(_wide));
      expect(ctx.debugPath.circleX, 20);
    });
  });
}
