// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/gestures.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart' show acquireChart;
import 'package:flutter_chartjs_port/chartjs.dart' show CssStyleProperties;
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';

void main() {
  group('gesture manager', () {
    final data = <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 1, 'y': 3},
            <String, Object?>{'x': 2, 'y': 2},
            <String, Object?>{'x': 3, 'y': 1},
          ],
        },
      ],
    };

    testWidgets(
      'should disable text selection and browser touch actions while '
      'gestures are enabled',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': data,
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'pan': <String, Object?>{'enabled': true},
              },
            },
          },
        });

        expect(chart.canvas!.style.touchAction, toBe('none'));
        expect(chart.canvas!.style.userSelect, toBe('none'));
      },
    );

    testWidgets(
      'should leave canvas styles untouched when neither pan nor pinch is '
      'enabled',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': data,
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'zoom': <String, Object?>{
                'zoom': <String, Object?>{
                  'wheel': <String, Object?>{'enabled': true},
                },
              },
            },
          },
        });

        expect(chart.canvas!.style.userSelect, toBe(''));
        expect(chart.canvas!.style.touchAction, toBe(''));
      },
    );
  });
}
