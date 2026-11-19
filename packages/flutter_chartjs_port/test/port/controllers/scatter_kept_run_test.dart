// Original code, not ported from Chart.js: scatter twins of the kept run.
@TestOn('vm')
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_test/flutter_test.dart';

import '../canvas/pixel_compare.dart';

const _red = ChartPaint.solid(ui.Color(0xffdd4400));
const _blue = ChartPaint.solid(ui.Color(0x804f6bed));
const _green = ChartPaint.solid(ui.Color(0xff119944));
const _fade = ChartGradient.linear(ui.Offset.zero, ui.Offset(0, 400), [
  ui.Color(0xff4f6bed),
  ui.Color(0x80dd4400),
]);

/// A scatter chart of [count] points with the given styles.
ChartConfig _config(
  int count, {
  ChartValue<ChartPaint> backgroundColor = const ChartValue.constant(_red),
  ChartValue<ChartPaint> borderColor = const ChartValue.constant(_blue),
  double borderWidth = 0,
  ChartValue<ChartPaint>? hoverBackgroundColor,
  List<double>? radii,
}) => ChartConfig(
  type: ChartKind.scatter,
  datasets: [
    ScatterDataset(
      points: [
        for (var i = 0; i < count; i++) DataPoint(i * 37 % 101, i * 53 % 97),
      ],
      pointRadius: radii == null ? 3 : null,
      borderWidth: borderWidth,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      hoverBackgroundColor: hoverBackgroundColor,
      // The typed scalar radius cannot express the indexable radius case.
      extra: {'radius': ?radii},
    ),
  ],
  responsive: false,
  animation: ChartAnimation.none,
  scales: const {
    'x': LinearAxis(display: ScaleDisplay.off, min: 0, max: 100),
    'y': LinearAxis(display: ScaleDisplay.off, min: 0, max: 100),
  },
  extra: const {
    'parsing': false,
    'events': <String>[],
    'plugins': {'legend': false, 'tooltip': false},
  },
);

String _describe(Object? value) => switch (value) {
  final ui.Paint p =>
    'Paint(${p.color}, ${p.style}, ${p.strokeWidth}, ${p.blendMode}, '
        '${p.shader != null})',
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

/// What a draw of the chart of [config] gives with or without the kept
/// colors: the native calls, the styles after the draw, the kept circles and
/// the pixels.
Future<(List<String>, List<Object?>, int, Render)> _draw(
  ChartConfig config, {
  required bool keep,
  List<ActiveElement> active = const [],
}) async {
  final keepBefore = UiCanvasContext.debugKeepRunColors;
  UiCanvasContext.debugKeepRunColors = keep;
  final calls = <String>[];
  final canvas = UiCanvasElement(width: 320, height: 200);
  final chart = Chart(canvas, ChartConfigLowering(config).lower());
  try {
    if (active.isNotEmpty) chart.setActiveElements(active);
    UiCanvasContext.debugRecordingCanvas = (recorder) =>
        _LogCanvas(calls, recorder);
    chart.draw();
    UiCanvasContext.debugRecordingCanvas = null;
    final ctx = chart.ctx! as UiCanvasContext;
    final styles = <Object?>[ctx.fillStyle, ctx.strokeStyle, ctx.lineWidth];
    final kept = ctx.debugKeptRunCircles;
    // A second draw for the pixels: the recording above drew nothing.
    chart.draw();
    final recorder = ui.PictureRecorder();
    ctx.paint(ui.Canvas(recorder), ui.Offset.zero, 1, 1);
    final picture = recorder.endRecording();
    final image = await picture.toImage(320, 200);
    final data = await image.toByteData();
    image.dispose();
    picture.dispose();
    return (calls, styles, kept, Render(data!.buffer.asUint8List(), 320, 200));
  } finally {
    UiCanvasContext.debugRecordingCanvas = null;
    UiCanvasContext.debugKeepRunColors = keepBefore;
    chart.destroy();
  }
}

/// Expects the same native calls, styles and pixels with and without the
/// kept colors, and gives the count of kept circles of the kept form.
Future<int> _expectTwins(
  ChartConfig Function() config, {
  List<ActiveElement> active = const [],
}) async {
  final kept = await _draw(config(), keep: true, active: active);
  final restarted = await _draw(config(), keep: false, active: active);
  expect(restarted.$3, 0);
  if (kept.$3 > 0) {
    expect(kept.$1.where((c) => c.contains('drawRawAtlas')), isNotEmpty);
  }
  expect(kept.$2, restarted.$2);
  expect(kept.$1.length, restarted.$1.length);
  for (var i = 0; i < kept.$1.length; i++) {
    expect(kept.$1[i], restarted.$1[i], reason: 'call $i');
  }
  final diff = comparePixels(kept.$4, restarted.$4);
  expect(diff.differing, 0, reason: '$diff');
  return kept.$3;
}

void main() {
  test('one color: each point has its own options, one run', () async {
    final kept = await _expectTwins(() => _config(2000));
    expect(kept, greaterThan(1900));
  });

  test('two alternating colors with a border', () async {
    final kept = await _expectTwins(
      () => _config(
        2000,
        backgroundColor: const ChartValue.indexed([_red, _green]),
        borderColor: const ChartValue.indexed([_blue, _red]),
        borderWidth: 1,
      ),
    );
    expect(kept, greaterThan(1900));
  });

  test('a scriptable color', () async {
    ChartConfig config() {
      // The calls run in the order of the points in both twins.
      var calls = 0;
      return _config(
        500,
        backgroundColor: ChartValue.resolver(
          (context) => calls++ % 3 == 0 ? _green : _red,
        ),
      );
    }

    final kept = await _expectTwins(config);
    expect(kept, greaterThan(400));
  });

  test('a gradient in the middle ends the run', () async {
    ChartConfig config() {
      var calls = 0;
      return _config(
        300,
        backgroundColor: ChartValue.resolver(
          (context) => switch (calls++) {
            150 => _fade,
            final n => n.isEven ? _red : _green,
          },
        ),
      );
    }

    final kept = await _expectTwins(config);
    expect(kept, greaterThan(100));
  });

  test('a list of radii breaks the run at each change', () async {
    await _expectTwins(
      () => _config(
        300,
        radii: const [2, 3, 3, 4],
        backgroundColor: const ChartValue.indexed([_red, _green]),
      ),
    );
  });

  test('a hovered point draws on top in its hover style', () async {
    final kept = await _expectTwins(
      () => _config(
        800,
        backgroundColor: const ChartValue.indexed([_red, _green]),
        hoverBackgroundColor: const ChartValue.constant(_blue),
      ),
      active: const [
        ActiveElement(datasetIndex: 0, index: 7),
        ActiveElement(datasetIndex: 0, index: 400),
      ],
    );
    expect(kept, greaterThan(700));
  });
}
