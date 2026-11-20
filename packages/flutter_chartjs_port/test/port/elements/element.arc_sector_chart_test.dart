// Original code, not ported from Chart.js: the fused arc sector on real charts.
@TestOn('vm')
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// A picture observer makes the native canvas decline its fused draws, so one
// chart config gives the two paths. Each slice has a color of its own, so no
// two sectors join.

const _colors = <ChartPaint>[
  ChartPaint.solid(ui.Color(0xFF3366CC)),
  ChartPaint.solid(ui.Color(0xFFDC3912)),
  ChartPaint.solid(ui.Color(0xFFFF9900)),
  ChartPaint.solid(ui.Color(0xFF109618)),
  ChartPaint.solid(ui.Color(0xFF990099)),
  ChartPaint.solid(ui.Color(0xFF0099C6)),
  ChartPaint.solid(ui.Color(0xFFDD4477)),
  ChartPaint.solid(ui.Color(0xFF66AA00)),
];

Dataset _dataset(
  ChartKind type, {
  required List<num> data,
  required ChartValue<ChartPaint> backgroundColor,
  required double borderWidth,
}) => switch (type) {
  ChartKind.pie => PieDataset(
    data: data,
    backgroundColor: backgroundColor,
    borderWidth: borderWidth,
  ),
  ChartKind.doughnut => DoughnutDataset(
    data: data,
    backgroundColor: backgroundColor,
    borderWidth: borderWidth,
  ),
  ChartKind.polarArea => PolarAreaDataset(
    data: data,
    backgroundColor: backgroundColor,
    borderWidth: borderWidth,
  ),
  _ => throw ArgumentError.value(type, 'type'),
};

ChartConfig _config(ChartKind type, {required double borderWidth}) =>
    ChartConfig(
      labels: [for (var i = 0; i < 8; i++) 'L$i'],
      datasets: [
        _dataset(
          type,
          data: [for (var i = 0; i < 8; i++) 3.0 + i],
          backgroundColor: const ChartValue.indexed(_colors),
          borderWidth: borderWidth,
        ),
      ],
      animation: ChartAnimation.none,
      extra: const {
        'plugins': {'legend': false, 'title': false, 'tooltip': false},
      },
    );

Future<Uint8List> _pixels(
  WidgetTester tester,
  ChartConfig config, {
  required bool ordinary,
}) async {
  if (ordinary) ui.Picture.onCreate = (_) {};
  addTearDown(() => ui.Picture.onCreate = null);
  final chart = acquireChartRoot(ChartConfigLowering(config).lower());
  await tester.pump();
  final canvas = chart.canvas! as UiCanvasElement;
  final (w, h) = (canvas.width, canvas.height);
  final context = canvas.getContext2d();
  // A draw with the fused route waits in its run: the paint draws it.
  final recorder = ui.PictureRecorder();
  context.paint(ui.Canvas(recorder), ui.Offset.zero, 1, 1);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(w, h);
  final data = await tester.runAsync(image.toByteData);
  image.dispose();
  picture.dispose();
  ui.Picture.onCreate = null;
  return data!.buffer.asUint8List();
}

void main() {
  for (final type in const [ChartKind.pie, ChartKind.doughnut]) {
    testWidgets('$type of one color: the slices of a real chart join', (
      tester,
    ) async {
      const n = 2000;
      final config = ChartConfig(
        labels: [for (var i = 0; i < n; i++) i],
        datasets: [
          _dataset(
            type,
            data: [for (var i = 0; i < n; i++) 1.0 + i % 37],
            backgroundColor: ChartValue.constant(_colors.first),
            borderWidth: 0,
          ),
        ],
        animation: ChartAnimation.none,
        extra: const {
          'plugins': {'legend': false, 'tooltip': false},
        },
      );
      final chart = acquireChartRoot(ChartConfigLowering(config).lower());
      await tester.pump();
      chart.draw();
      final context = (chart.canvas! as UiCanvasElement).getContext2d();
      // One run ends just below a full turn, so a few slices start a second
      // one. The rounding of the angles of `pathArc` splits nothing.
      expect(context.debugPendingSectors, lessThan(n));
      expect(context.debugPictureCount, 1);
      final recorder = ui.PictureRecorder();
      context.paint(ui.Canvas(recorder), ui.Offset.zero, 1, 1);
      recorder.endRecording().dispose();
      expect(context.debugPendingSectors, 0);
    });
  }

  for (final type in const [
    ChartKind.pie,
    ChartKind.doughnut,
    ChartKind.polarArea,
  ]) {
    testWidgets('$type with no border takes the fused route', (tester) async {
      final chart = acquireChartRoot(
        ChartConfigLowering(_config(type, borderWidth: 0)).lower(),
      );
      await tester.pump();
      chart.draw();
      final canvas = chart.canvas! as UiCanvasElement;
      expect(canvas.getContext2d().debugPendingSectors, 1);
    });

    for (final borderWidth in const [0.0, 2.0]) {
      testWidgets('$type with a border of $borderWidth: the same bytes', (
        tester,
      ) async {
        final fused = await _pixels(
          tester,
          _config(type, borderWidth: borderWidth),
          ordinary: false,
        );
        releaseCharts();
        final ordinary = await _pixels(
          tester,
          _config(type, borderWidth: borderWidth),
          ordinary: true,
        );
        expect(fused.length, ordinary.length);
        var differing = 0;
        for (var i = 0; i < fused.length; i++) {
          if (fused[i] != ordinary[i]) differing++;
        }
        expect(differing, 0);
        expect(fused.any((b) => b != 0), isTrue);
      });
    }
  }
}
