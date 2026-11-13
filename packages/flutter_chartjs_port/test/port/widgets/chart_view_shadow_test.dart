// Original code, not ported from Chart.js: the dataset shadow of ChartView.
@TestOn('vm')
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' hide Element;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/typed/datasets.dart' show lowerDataset;
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0107: `Dataset.shadow` lowers to four plain keys of the
// dataset, and the inline plugin of ChartView sets them on the canvas around
// the draw of the dataset.

const Color _black = Color(0xFF000000);
const Color _red = Color(0xFFFF0000);

const ChartShadow _shadow = ChartShadow(
  color: _red,
  blur: 8,
  offset: Offset(0, 20),
);

const Map<String, ChartAxis> _hiddenAxes = {
  'x': CategoryAxis(display: false),
  'y': LinearAxis(min: 0, max: 4, display: false),
};

ChartConfig _line(List<double> data, {ChartShadow? shadow}) => ChartConfig(
  type: ChartKind.line,
  labels: const ['a', 'b', 'c'],
  datasets: [
    LineDataset(
      data: data,
      borderColor: const ChartValue.constant(.solid(_black)),
      pointRadius: 0,
      shadow: shadow,
    ),
  ],
  scales: _hiddenAxes,
  animation: ChartAnimation.none,
  legend: const ChartLegend(display: false),
);

Map<String, Object?> _rawLine({required bool shadow}) => <String, Object?>{
  'type': 'line',
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b', 'c'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[1.0, 3.0, 2.0],
        'borderColor': const ChartPaint.solid(_black),
        'pointRadius': 0.0,
        if (shadow) ...<String, Object?>{
          'shadowColor': _red,
          'shadowBlur': 8,
          'shadowOffsetX': 0,
          'shadowOffsetY': 20,
        },
      },
    ],
  },
  'options': <String, Object?>{
    'animation': false,
    'scales': <String, Object?>{
      'x': <String, Object?>{'display': false},
      'y': <String, Object?>{'min': 0, 'max': 4, 'display': false},
    },
    'plugins': <String, Object?>{'legend': false},
  },
};

Widget _box(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: 300, height: 200, child: child),
  ),
);

Chart _chart(WidgetTester tester) => Chart.getChart(
  tester.renderObject<RenderChartHost>(find.byType(ChartHost)).canvas,
)!;

/// The bytes of the chart canvas over white.
Future<Uint8List> _pixels(WidgetTester tester) async {
  final canvas = _chart(tester).canvas! as UiCanvasElement;
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
    final data = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
    );
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}

/// The pixels that are more red than green: the red shadow under the black
/// line.
int _reddish(Uint8List bytes) {
  var count = 0;
  for (var i = 0; i < bytes.length; i += 4) {
    if (bytes[i] > bytes[i + 1] + 16) count++;
  }
  return count;
}

void main() {
  group('Dataset.shadow', () {
    test('lowers to the four keys of the canvas shadow', () {
      final scope = lowerDataset(
        const LineDataset(data: [1], shadow: _shadow),
        ChartKind.line,
      );
      expect(scope.jsRead('shadowColor'), _red);
      expect(scope.jsRead('shadowBlur'), 8);
      expect(scope.jsRead('shadowOffsetX'), 0);
      expect(scope.jsRead('shadowOffsetY'), 20);
    });

    test('an extra entry wins over the shadow', () {
      final scope = lowerDataset(
        const LineDataset(
          data: [1],
          shadow: _shadow,
          extra: {'shadowBlur': 2.0},
        ),
        ChartKind.line,
      );
      expect(scope.jsRead('shadowBlur'), 2);
    });

    test('no shadow writes no key', () {
      final scope = lowerDataset(const BarDataset(data: [1]), ChartKind.bar);
      expect(scope.jsKeys(), isNot(contains('shadowColor')));
    });

    test('takes part in ==', () {
      const a = LineDataset(shadow: _shadow);
      expect(a, const LineDataset(shadow: _shadow));
      expect(a, isNot(LineDataset(shadow: _shadow.copyWith(blur: 2))));
      expect(a, isNot(const LineDataset()));
      expect(a.copyWith(label: 'x').shadow, _shadow);
    });
  });

  group('ChartView', () {
    testWidgets('draws the shadow and restores the context', (tester) async {
      await tester.pumpWidget(_box(ChartView(config: _line([1, 3, 2]))));
      final plain = _reddish(await _pixels(tester));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        _box(ChartView(config: _line([1, 3, 2], shadow: _shadow))),
      );
      final cast = _reddish(await _pixels(tester));
      expect(plain, 0);
      expect(cast, greaterThan(100));
      final ctx = _chart(tester).ctx!;
      expect(ctx.shadowColor, const Color(0x00000000));
      expect(ctx.shadowBlur, 0);
      expect(ctx.shadowOffsetY, 0);
    });

    testWidgets('a raw dataset with the keys draws the same pixels', (
      tester,
    ) async {
      await tester.pumpWidget(
        _box(ChartView(config: _line([1, 3, 2], shadow: _shadow))),
      );
      final typed = await _pixels(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        _box(ChartView.raw(config: _rawLine(shadow: true))),
      );
      final raw = await _pixels(tester);
      expect(raw, typed);
    });

    testWidgets('the config check rejects a shadowColor that is not a Color', (
      tester,
    ) async {
      final config = _rawLine(shadow: true);
      final dataset =
          ((config['data']! as Map<String, Object?>)['datasets']!
                      as List<Object?>)
                  .single!
              as Map<String, Object?>;
      dataset['shadowColor'] = 'red';
      await tester.pumpWidget(_box(ChartView.raw(config: config)));
      expect(tester.takeException(), isArgumentError);
    });

    testWidgets('a shadow keeps the data-only updates', (tester) async {
      var layouts = 0;
      final spy = <String, Object?>{
        'id': r'$shadowSpy',
        'supportsDataUpdates': true,
        'beforeLayout': (Object? chart, Object? args, Object? options) {
          layouts++;
        },
      };
      Chart.register([spy]);
      addTearDown(() => Chart.unregister([spy]));
      Widget view(List<double> data) => _box(
        ChartView(
          config: _line(data, shadow: _shadow),
          updateMode: 'none',
          dataOnlyUpdates: true,
        ),
      );
      // The first tick after the start is a full update.
      await tester.pumpWidget(view([1, 3, 2]));
      await tester.pump();
      await tester.pumpWidget(view([2, 1, 3]));
      layouts = 0;
      await tester.pumpWidget(view([3, 2, 1]));
      expect(layouts, 0);
      expect(_reddish(await _pixels(tester)), greaterThan(100));
    });
  });
}
