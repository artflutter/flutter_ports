// Original code, not ported from Chart.js: the bool option `alignToPixels`.
@TestOn('vm')
library;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_test/flutter_test.dart';

/// A line chart at the pixel ratio 2 with two linear scales, `alignToPixels`
/// [value] on both, or no key for [undefined].
ChartConfig _config(Object? value) {
  LinearAxis scale() => LinearAxis(
    min: 0,
    max: 7,
    // Keep explicit null distinct from an absent option in these cases.
    extra: {if (!identical(value, undefined)) 'alignToPixels': value},
  );
  return ChartConfig(
    type: ChartKind.line,
    datasets: [
      LineDataset(
        points: [for (var i = 0; i < 8; i++) DataPoint(i, i * 5 % 7)],
      ),
    ],
    responsive: false,
    animation: ChartAnimation.none,
    scales: {'x': scale(), 'y': scale()},
    extra: const {
      'devicePixelRatio': 2.0,
      'events': <String>[],
      'plugins': {'legend': false, 'tooltip': false},
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // core.scale.js:497 stores the option, and :926 tests it. The option holds
  // a bool (row adapt-bool-options): absent and null are false.
  final cases = <(String, Object?, bool)>[
    ('absent', undefined, false),
    ('true', true, true),
    ('false', false, false),
    ('null', null, false),
  ];
  for (final (name, value, truthy) in cases) {
    test('alignToPixels $name gives its pixels', () {
      final canvas = UiCanvasElement(width: 641, height: 401);
      final chart = Chart(canvas, ChartConfigLowering(_config(value)).lower());
      addTearDown(chart.destroy);
      expect(chart.currentDevicePixelRatio, 2.0);
      for (final scaleId in ['x', 'y']) {
        final scale = chart.scales[scaleId]!;
        for (var i = 0; i <= 16; i++) {
          final decimal = i / 16 + 1 / 3;
          final d = scale.reversePixels ? 1 - decimal : decimal;
          final pixel = scale.startPixel + d * scale.length;
          final expected = int16Range(
            truthy ? alignPixel(chart, pixel, 0) : pixel,
          );
          expect(scale.getPixelForDecimal(decimal), expected);
        }
        // The unaligned and aligned pixels differ for these decimals.
        final pixel = scale.startPixel + (1 / 3) * scale.length;
        expect(alignPixel(chart, pixel, 0), isNot(pixel));
      }
    });
  }
}
