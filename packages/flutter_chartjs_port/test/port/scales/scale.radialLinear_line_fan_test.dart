// Original code, not ported from Chart.js: the angle lines in one native call.
@TestOn('vm')
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter/widgets.dart' show Directionality, SizedBox;
import 'package:flutter/widgets.dart' as widgets show TextDirection;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show
        AxisGrid,
        ChartAnimation,
        ChartConfig,
        ChartKind,
        ChartLegend,
        ChartThemeData,
        ChartView,
        RadarDataset,
        RadialLinearAxis;
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_line_fan.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/scales/scale.radialLinear.dart';
import 'package:flutter_test/flutter_test.dart';

// The twins of Chart.js ADR 0103, over the plan of Chart.js ADR 0095:
//
// - A recording context with the capability gets the fan. It writes the calls
//   of the fan as the ordinary sequence, and the same recording context without
//   the capability writes the ordinary sequence: the calls must be equal in
//   order, arguments and bits.
// - The exact scale on the native canvas takes the fan, and a trivial user
//   subclass or a picture observer takes the ordinary strokes: the bytes of the
//   bitmap must be equal.

/// A trivial user subclass of the scale, which keeps each ordinary call.
final class _OrdinaryRadial extends RadialLinearScale {
  _OrdinaryRadial(super.cfg);

  static final value = JsClass(
    'FanOrdinaryRadial',
    superclass: RadialLinearScale.jsClass,
    statics: {'id': 'fanOrdinaryRadial'},
    construct: (_, args) => _OrdinaryRadial(scaleCfgArg(args)),
  );
}

final class _Metrics implements TextMetrics {
  const _Metrics(this.width);

  @override
  final double width;

  @override
  double get actualBoundingBoxAscent => 4;

  @override
  double get actualBoundingBoxDescent => 8;

  @override
  double get actualBoundingBoxLeft => 0;

  @override
  double get actualBoundingBoxRight => width;
}

/// A recording context with the capability of the static plans of the scale:
/// the font state and the text measures of [target], with no pixels.
class _Recorder extends MockContext implements CanvasTextMetricsSource {
  _Recorder(this.target);

  final CanvasRenderingContext2D target;

  static final Object _generation = Object();

  @override
  Object? get textMetricsGeneration => _generation;

  @override
  HTMLCanvasElement get canvas => target.canvas;

  @override
  String? get font => target.font;

  @override
  set font(String? font) {
    super.font = font;
    target.font = font;
  }

  @override
  void save() {
    super.save();
    target.save();
  }

  @override
  void restore() {
    super.restore();
    target.restore();
  }

  @override
  TextMetrics measureText(String text) {
    record('measureText', [text]);
    return _Metrics(target.measureText(text).width);
  }
}

/// [_Recorder] with the capability of the fan. It takes a fan when [takes] is
/// true: then it records the ordinary sequence of its lines.
final class _FanRecorder extends _Recorder implements LineFanCanvas {
  _FanRecorder(super.target, {required this.takes});

  final bool takes;

  /// The count of the lines of each offer.
  final List<int> fans = [];

  @override
  bool tryStrokeLineFan(
    double x,
    double y,
    int count,
    void Function(Float64List ends) writeEnds,
  ) {
    fans.add(count);
    if (!takes) return false;
    final ends = Float64List(count * 2);
    writeEnds(ends);
    for (var i = 0; i < count; i++) {
      beginPath();
      moveTo(x, y);
      lineTo(ends[i * 2], ends[i * 2 + 1]);
      stroke();
    }
    return true;
  }
}

RadialLinearScale _scaleOf(Chart chart) =>
    chart.scales['r']! as RadialLinearScale;

/// A radar or polar area config of [n] labels with the options [r] of the
/// scale. Each call gives new objects.
Map<String, Object?> _config({
  String type = 'radar',
  String? scaleType,
  int n = 40,
  ui.Color color = const ui.Color(0x80336699),
  Map<String, Object?>? angleLines,
  Map<String, Object?>? r,
}) => <String, Object?>{
  'type': type,
  'data': <String, Object?>{
    'labels': <Object?>[for (var i = 0; i < n; i++) 'Label $i'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[
          for (var i = 0; i < n; i++) ((i * 37) % 100).toDouble(),
        ],
      },
    ],
  },
  'options': <String, Object?>{
    'responsive': false,
    'events': <String>[],
    'plugins': <String, Object?>{'legend': false},
    'scales': <String, Object?>{
      'r': <String, Object?>{
        'type': ?scaleType,
        'min': 0.0,
        'max': 100.0,
        'grid': <String, Object?>{'color': const ui.Color(0x33000000)},
        'angleLines': <String, Object?>{
          'display': true,
          'color': color,
          ...?angleLines,
        },
        'ticks': <String, Object?>{'display': false},
        'pointLabels': <String, Object?>{'display': false},
        ...?r,
      },
    },
  },
};

/// One draw of the scale of [chart] on [ctx]: the recorded calls.
List<ContextCall> _drawWith(Chart chart, _Recorder ctx) {
  final scale = _scaleOf(chart);
  final old = scale.ctx;
  scale.ctx = ctx;
  try {
    scale.draw(chart.chartArea);
    return ctx.getCalls();
  } finally {
    scale.ctx = old;
  }
}

const Set<String> _paths = {'beginPath', 'moveTo', 'lineTo', 'stroke'};

/// The path and paint calls of [calls], with their arguments and each bit.
List<String> _pathCalls(List<ContextCall> calls) => [
  for (final call in calls)
    if (_paths.contains(call['name'])) '${call['name']} ${call['args']}',
];

int _strokes(List<ContextCall> calls) =>
    calls.where((call) => call['name'] == 'stroke').length;

/// The RGBA bytes of the bitmap of [chart], over an opaque white rectangle.
Future<Uint8List> _pixels(WidgetTester tester, Chart chart) async {
  final canvas = chart.canvas! as UiCanvasElement;
  final w = canvas.width;
  final h = canvas.height;
  final recorder = ui.PictureRecorder();
  final c = ui.Canvas(recorder)
    ..drawRect(
      ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
  canvas.getContext2d().paint(c, ui.Offset.zero, 1, 1);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(w, h);
  try {
    final data = (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
    ))!;
    return data.buffer.asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}

int _pictures(Chart chart) =>
    (chart.canvas! as UiCanvasElement).getContext2d().debugPictureCount;

void main() {
  Chart.register([_OrdinaryRadial.value]);

  setUp(() {
    UiCanvasContext.debugLineFanWithoutImpeller = true;
    addTearDown(() => UiCanvasContext.debugLineFanWithoutImpeller = false);
  });

  group('a recording context', () {
    for (final type in const ['radar', 'polarArea']) {
      testWidgets('$type: a fan has the calls of the ordinary lines', (
        tester,
      ) async {
        final chart = acquireChart(_config(type: type));
        final target = chart.ctx!;
        final ordinary = _drawWith(chart, _Recorder(target));
        final taken = _FanRecorder(target, takes: true);
        final fan = _drawWith(chart, taken);
        expect(taken.fans, [39]);
        expect(_strokes(ordinary), greaterThanOrEqualTo(40));
        expect(_pathCalls(fan), _pathCalls(ordinary));

        // A decline leaves the ordinary loop, also with no write of an end.
        final declined = _FanRecorder(target, takes: false);
        final loop = _drawWith(chart, declined);
        expect(declined.fans, [39]);
        expect(_pathCalls(loop), _pathCalls(ordinary));
      });

      testWidgets('$type: reverse, a start angle and a circular grid', (
        tester,
      ) async {
        final chart = acquireChart(
          _config(
            type: type,
            r: {
              'reverse': true,
              'startAngle': 33.0,
              'grid': <String, Object?>{
                'circular': true,
                'color': const ui.Color(0x33000000),
              },
            },
          ),
        );
        final target = chart.ctx!;
        final ordinary = _drawWith(chart, _Recorder(target));
        final taken = _FanRecorder(target, takes: true);
        final fan = _drawWith(chart, taken);
        expect(taken.fans, [39]);
        expect(_pathCalls(fan), _pathCalls(ordinary));
      });
    }

    testWidgets('a scale subclass gets no fan', (tester) async {
      final chart = acquireChart(_config(scaleType: 'fanOrdinaryRadial'));
      expect(_scaleOf(chart), isA<_OrdinaryRadial>());
      final ctx = _FanRecorder(chart.ctx!, takes: true);
      final calls = _drawWith(chart, ctx);
      expect(ctx.fans, isEmpty);
      expect(_strokes(calls), greaterThanOrEqualTo(40));
    });

    testWidgets('a scriptable color gets no fan, and each call', (
      tester,
    ) async {
      var reads = 0;
      Object? color(Object? context) {
        reads++;
        return const ui.Color(0x80336699);
      }

      final chart = acquireChart(_config(angleLines: {'color': color}));
      final target = chart.ctx!;
      reads = 0;
      final ordinary = _drawWith(chart, _Recorder(target));
      final ordinaryReads = reads;
      expect(ordinaryReads, 40);
      reads = 0;
      final ctx = _FanRecorder(target, takes: true);
      final calls = _drawWith(chart, ctx);
      expect(reads, ordinaryReads);
      expect(ctx.fans, isEmpty);
      expect(_pathCalls(calls), _pathCalls(ordinary));
    });

    testWidgets('an indexed color gets no fan', (tester) async {
      final chart = acquireChart(
        _config(
          angleLines: {
            'color': <Object?>[
              const ui.Color(0x80336699),
              const ui.Color(0x80996633),
            ],
          },
        ),
      );
      final ctx = _FanRecorder(chart.ctx!, takes: true);
      final calls = _drawWith(chart, ctx);
      expect(ctx.fans, isEmpty);
      expect(_strokes(calls), greaterThanOrEqualTo(40));
    });

    testWidgets('a dash gets no fan', (tester) async {
      final chart = acquireChart(
        _config(
          angleLines: {
            'borderDash': <Object?>[3.0, 2.0],
          },
        ),
      );
      final ctx = _FanRecorder(chart.ctx!, takes: true);
      final calls = _drawWith(chart, ctx);
      expect(ctx.fans, isEmpty);
      expect(_strokes(calls), greaterThanOrEqualTo(40));
    });

    testWidgets('a scriptable dash offset gets no fan', (tester) async {
      final chart = acquireChart(
        _config(angleLines: {'borderDashOffset': (Object? _) => 1.0}),
      );
      final ctx = _FanRecorder(chart.ctx!, takes: true);
      _drawWith(chart, ctx);
      expect(ctx.fans, isEmpty);
    });

    testWidgets('display false, a color and a width with no line get no fan', (
      tester,
    ) async {
      for (final angleLines in <Map<String, Object?>>[
        {'display': false},
        {'lineWidth': 0.0},
        {'color': ''},
      ]) {
        final chart = acquireChart(_config(angleLines: angleLines));
        final target = chart.ctx!;
        final ordinary = _drawWith(chart, _Recorder(target));
        final ctx = _FanRecorder(target, takes: true);
        final calls = _drawWith(chart, ctx);
        expect(ctx.fans, isEmpty, reason: '$angleLines');
        expect(_pathCalls(calls), _pathCalls(ordinary), reason: '$angleLines');
        final grid = _strokes(calls);
        expect(grid, lessThan(40), reason: '$angleLines');
      }
    });

    testWidgets('below three labels, the loop has no run', (tester) async {
      for (final n in const [0, 1, 2]) {
        final chart = acquireChart(_config(n: n));
        final target = chart.ctx!;
        final ordinary = _drawWith(chart, _Recorder(target));
        final ctx = _FanRecorder(target, takes: true);
        final calls = _drawWith(chart, ctx);
        expect(ctx.fans, isEmpty, reason: '$n');
        expect(_pathCalls(calls), _pathCalls(ordinary), reason: '$n');
      }
      final three = acquireChart(_config(n: 3));
      final ctx = _FanRecorder(three.ctx!, takes: true);
      _drawWith(three, ctx);
      expect(ctx.fans, [2]);
    });
  });

  group('the pixels of the bitmap', () {
    for (final type in const ['radar', 'polarArea']) {
      for (final n in const [3, 12, 40, 700]) {
        for (final color in const [
          ui.Color(0x33000000),
          ui.Color(0xFF336699),
        ]) {
          testWidgets('$type: $n lines of $color', (tester) async {
            final fan = acquireChart(_config(type: type, n: n, color: color));
            final ordinary = acquireChart(
              _config(
                type: type,
                n: n,
                color: color,
                scaleType: 'fanOrdinaryRadial',
              ),
            );
            expect(_scaleOf(fan).runtimeType, RadialLinearScale);
            expect(_scaleOf(ordinary).runtimeType, _OrdinaryRadial);
            if (n == 700) {
              // The native canvas took the fan: its 699 lines are one draw of
              // the recording, where the ordinary strokes split it.
              expect(_pictures(fan), lessThan(_pictures(ordinary)));
            }
            expect(
              await _pixels(tester, fan),
              await _pixels(tester, ordinary),
            );
          });
        }
      }
    }

    for (final (name, options) in <(String, Map<String, Object?>)>[
      ('a wide line', {'lineWidth': 3.5}),
      ('a thin line', {'lineWidth': 0.25}),
      (
        'a dashed line',
        {
          'borderDash': <Object?>[3.0, 2.0],
        },
      ),
      (
        'a scriptable color',
        {'color': (Object? _) => const ui.Color(0x80996633)},
      ),
      (
        'an indexed color',
        {
          'color': <Object?>[
            const ui.Color(0x80336699),
            const ui.Color(0x80996633),
          ],
        },
      ),
      ('no display', {'display': false}),
    ]) {
      testWidgets(name, (tester) async {
        final fan = acquireChart(_config(angleLines: options));
        final ordinary = acquireChart(
          _config(angleLines: options, scaleType: 'fanOrdinaryRadial'),
        );
        expect(await _pixels(tester, fan), await _pixels(tester, ordinary));
      });
    }

    testWidgets('reverse, a start angle, a circular grid and ticks', (
      tester,
    ) async {
      Map<String, Object?> r() => {
        'reverse': true,
        'startAngle': 33.0,
        'grid': <String, Object?>{
          'circular': true,
          'color': const ui.Color(0x33000000),
        },
        'ticks': <String, Object?>{'display': true},
        'pointLabels': <String, Object?>{'display': true},
      };
      final fan = acquireChart(_config(r: r()));
      final ordinary = acquireChart(
        _config(r: r(), scaleType: 'fanOrdinaryRadial'),
      );
      expect(await _pixels(tester, fan), await _pixels(tester, ordinary));
    });

    testWidgets('a canvas with no radius: the lines have no length', (
      tester,
    ) async {
      Map<String, Object?> options() => <String, Object?>{
        'canvas': <String, Object?>{'width': 8, 'height': 8},
      };
      final fan = acquireChart(_config(), options());
      final ordinary = acquireChart(
        _config(scaleType: 'fanOrdinaryRadial'),
        options(),
      );
      expect(_scaleOf(fan).drawingArea, _scaleOf(ordinary).drawingArea);
      expect(await _pixels(tester, fan), await _pixels(tester, ordinary));
    });

    testWidgets('a picture observer takes the ordinary strokes', (
      tester,
    ) async {
      final fan = acquireChart(_config(n: 700));
      final fanPictures = _pictures(fan);
      final fanPixels = await _pixels(tester, fan);
      addTearDown(() => ui.Picture.onCreate = null);
      ui.Picture.onCreate = (_) {};
      final ordinary = acquireChart(_config(n: 700));
      final ordinaryPictures = _pictures(ordinary);
      ui.Picture.onCreate = null;
      expect(fanPictures, lessThan(ordinaryPictures));
      expect(fanPixels, await _pixels(tester, ordinary));
    });
  });

  group('the current path after the scale', () {
    testWidgets('is the path of the last angle line', (tester) async {
      final fan = acquireChart(_config());
      final ordinary = acquireChart(_config(scaleType: 'fanOrdinaryRadial'));
      final scale = _scaleOf(fan);
      final ordinaryScale = _scaleOf(ordinary);
      scale.draw(fan.chartArea);
      ordinaryScale.draw(ordinary.chartArea);
      final path = (fan.ctx! as UiCanvasContext).debugPath;
      final ordinaryPath = (ordinary.ctx! as UiCanvasContext).debugPath;
      expect(path.hasSingleLine, isTrue);
      expect(ordinaryPath.hasSingleLine, isTrue);
      expect(path.lineX0, ordinaryPath.lineX0);
      expect(path.lineY0, ordinaryPath.lineY0);
      expect(path.lineX1, ordinaryPath.lineX1);
      expect(path.lineY1, ordinaryPath.lineY1);
    });
  });

  group('the typed config of a dense radar', () {
    testWidgets('takes the fan, with the pixels of the ordinary strokes', (
      tester,
    ) async {
      Future<Chart> pump(int size) async {
        late Chart chart;
        await tester.pumpWidget(
          Directionality(
            textDirection: widgets.TextDirection.ltr,
            child: SizedBox(
              width: 400,
              height: size.toDouble(),
              child: ChartView(
                config: ChartConfig(
                  type: ChartKind.radar,
                  datasets: [
                    RadarDataset(
                      label: 'Values',
                      data: [
                        for (var i = 0; i < 700; i++) (i % 100).toDouble(),
                      ],
                      pointRadius: 0,
                    ),
                  ],
                  labels: [for (var i = 0; i < 700; i++) ''],
                  scales: const {
                    'r': RadialLinearAxis(
                      min: 0,
                      max: 100,
                      angleLinesColor: ui.Color(0x33888888),
                      angleLinesLineWidth: 1,
                      grid: AxisGrid(
                        color: ui.Color(0x33888888),
                        drawTicks: false,
                      ),
                    ),
                  },
                  animation: ChartAnimation.none,
                  legend: const ChartLegend(display: false),
                  maintainAspectRatio: false,
                  extra: const {'events': <String>[]},
                ),
                updateMode: 'none',
                theme: const ChartThemeData(),
                excludeFromSemantics: true,
                onChartCreated: (created) => chart = created,
              ),
            ),
          ),
        );
        await tester.pump();
        return chart;
      }

      final fan = await pump(400);
      final fanPictures = _pictures(fan);
      final fanPixels = await _pixels(tester, fan);

      await tester.pumpWidget(const SizedBox());
      addTearDown(() => ui.Picture.onCreate = null);
      ui.Picture.onCreate = (_) {};
      final ordinary = await pump(400);
      final ordinaryPictures = _pictures(ordinary);
      ui.Picture.onCreate = null;

      expect(fanPictures, lessThan(ordinaryPictures));
      expect(fanPixels, await _pixels(tester, ordinary));
    });
  });
}
