// Original code, not ported from Chart.js: scatter twins of the kept run.
@TestOn('vm')
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../canvas/pixel_compare.dart';

const _red = ChartPaint.solid(ui.Color(0xffdd4400));
const _blue = ChartPaint.solid(ui.Color(0x804f6bed));
const _green = ChartPaint.solid(ui.Color(0xff119944));
const _fade = ChartGradient.linear(ui.Offset.zero, ui.Offset(0, 400), [
  ui.Color(0xff4f6bed),
  ui.Color(0x80dd4400),
]);

/// A scatter chart of [count] points with the dataset options [dataset].
Map<String, Object?> _config(int count, Map<String, Object?> dataset) => {
  'type': 'scatter',
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[
          for (var i = 0; i < count; i++)
            <String, Object?>{
              'x': (i * 37 % 101).toDouble(),
              'y': (i * 53 % 97).toDouble(),
            },
        ],
        'radius': 3.0,
        'borderWidth': 0.0,
        'backgroundColor': _red,
        'borderColor': _blue,
        ...dataset,
      },
    ],
  },
  'options': <String, Object?>{
    'responsive': false,
    'animation': false,
    'parsing': false,
    'events': <String>[],
    'plugins': <String, Object?>{'legend': false, 'tooltip': false},
    'scales': <String, Object?>{
      'x': <String, Object?>{
        'type': 'linear',
        'display': ScaleDisplay.off,
        'min': 0.0,
        'max': 100.0,
      },
      'y': <String, Object?>{
        'type': 'linear',
        'display': ScaleDisplay.off,
        'min': 0.0,
        'max': 100.0,
      },
    },
  },
};

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
  Map<String, Object?> config, {
  required bool keep,
  List<ActiveElement> active = const [],
}) async {
  final keepBefore = UiCanvasContext.debugKeepRunColors;
  UiCanvasContext.debugKeepRunColors = keep;
  final calls = <String>[];
  final canvas = UiCanvasElement(width: 320, height: 200);
  final chart = Chart(canvas, config);
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
  Map<String, Object?> Function() config, {
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
    final kept = await _expectTwins(() => _config(2000, {}));
    expect(kept, greaterThan(1900));
  });

  test('two alternating colors with a border', () async {
    final kept = await _expectTwins(
      () => _config(2000, {
        'backgroundColor': <ChartPaint>[_red, _green],
        'borderColor': <ChartPaint>[_blue, _red],
        'borderWidth': 1.0,
      }),
    );
    expect(kept, greaterThan(1900));
  });

  test('a scriptable color', () async {
    Map<String, Object?> config() {
      // The calls run in the order of the points in both twins.
      var calls = 0;
      return _config(500, {
        'backgroundColor': (Object? context) =>
            calls++ % 3 == 0 ? _green : _red,
      });
    }

    final kept = await _expectTwins(config);
    expect(kept, greaterThan(400));
  });

  test('a gradient in the middle ends the run', () async {
    Map<String, Object?> config() {
      var calls = 0;
      return _config(300, {
        'backgroundColor': (Object? context) => switch (calls++) {
          150 => _fade,
          final n => n.isEven ? _red : _green,
        },
      });
    }

    final kept = await _expectTwins(config);
    expect(kept, greaterThan(100));
  });

  test('a list of radii breaks the run at each change', () async {
    await _expectTwins(
      () => _config(300, {
        'radius': <double>[2, 3, 3, 4],
        'backgroundColor': <ChartPaint>[_red, _green],
      }),
    );
  });

  test('a hovered point draws on top in its hover style', () async {
    final kept = await _expectTwins(
      () => _config(800, {
        'backgroundColor': <ChartPaint>[_red, _green],
        'hoverBackgroundColor': _blue,
      }),
      active: const [
        ActiveElement(datasetIndex: 0, index: 7),
        ActiveElement(datasetIndex: 0, index: 400),
      ],
    );
    expect(kept, greaterThan(700));
  });
}
