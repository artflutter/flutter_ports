// Original code, not ported from Chart.js: the truthiness of `alignToPixels`.
@TestOn('vm')
library;

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show alignPixel;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show int16Range;
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_test/flutter_test.dart';

/// A line chart at the pixel ratio 2 with two linear scales, `alignToPixels`
/// [value] on both, or no key for [undefined].
Map<String, Object?> _config(Object? value) {
  Map<String, Object?> scale() => <String, Object?>{
    'type': 'linear',
    'min': 0.0,
    'max': 7.0,
    if (!identical(value, undefined)) 'alignToPixels': value,
  };
  return <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            for (var i = 0; i < 8; i++)
              <String, Object?>{'x': i * 1.0, 'y': (i * 5 % 7) * 1.0},
          ],
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'animation': false,
      'devicePixelRatio': 2.0,
      'events': <String>[],
      'plugins': <String, Object?>{'legend': false, 'tooltip': false},
      'scales': <String, Object?>{'x': scale(), 'y': scale()},
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // core.scale.js:497 stores the raw option, and :926 tests its truthiness.
  // The port stores the `ToBoolean` at :497 (row
  // adapt-loop-invariant-truthiness): each value gives the pixels of its
  // truthiness.
  final cases = <(String, Object?, bool)>[
    ('absent', undefined, false),
    ('true', true, true),
    ('false', false, false),
    ('1', 1, true),
    ('0', 0, false),
    ('NaN', double.nan, false),
    ("'a'", 'a', true),
    ("''", '', false),
    ('null', null, false),
    ('an object', <String, Object?>{}, true),
  ];
  for (final (name, value, truthy) in cases) {
    test('alignToPixels $name gives the pixels of its truthiness', () {
      // A value outside the type `boolean` of the key is a foreign value
      // (oracle O2): this test writes them on purpose.
      final saved = foreignAudit;
      foreignAudit = (owner, key, raw) {};
      addTearDown(() => foreignAudit = saved);
      final canvas = UiCanvasElement(width: 641, height: 401);
      final chart = Chart(canvas, _config(value));
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
