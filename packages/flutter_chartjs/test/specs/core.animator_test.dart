// Ported from Chart.js v4.5.1+7169e651 test/specs/core.animator.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs/src/core/core.animator.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

// `Chart.animator` is `animator` of core.animator.dart. The first case makes
// a bar chart. It is a `testWidgets` case with `acquireChart` and
// `waitForDone` (Chart.js ADR 0019, section 12, Chart.js ADR 0022, section
// 7). `animation.currentStep <= 250` reads the `double?` field: the
// listener of `progress` always gets a number.

/// The chart object `{}` of the spec. Its members throw.
final class _Chart implements types.Chart {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Chart.animator', () {
    testWidgets('should fire onProgress for each draw', (tester) async {
      await waitForDone((done) {
        var count = 0;
        var drawCount = 0;
        void progress(AnimationEvent animation) {
          count++;
          expect(animation.numSteps, 250);
          expect(animation.currentStep! <= 250, isTrue);
        }

        acquireChart(
          <String, Object?>{
            'type': 'bar',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[10, 5, 0, 25, 78, -10],
                },
              ],
              'labels': <Object?>[
                'tick1',
                'tick2',
                'tick3',
                'tick4',
                'tick5',
                'tick6',
              ],
            },
            'options': <String, Object?>{
              'animation': <String, Object?>{
                'duration': 250,
                'onProgress': progress,
                'onComplete': () {
                  expect(count, drawCount);
                  done();
                },
              },
            },
            'plugins': <Object?>[
              <String, Object?>{
                'afterDraw': () {
                  drawCount++;
                },
              },
            ],
          },
          <String, Object?>{
            'canvas': <String, Object?>{'height': 150, 'width': 250},
          },
        );
      });
    });

    test('should not fail when adding no items', () {
      final chart = _Chart();
      animator
        ..add(chart, null)
        ..add(chart, [])
        ..start(chart);
      expect(animator.running(chart), isFalse);
    });
  });
}
