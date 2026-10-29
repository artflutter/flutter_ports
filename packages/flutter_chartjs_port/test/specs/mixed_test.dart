// Ported from Chart.js v4.6.1 test/specs/mixed.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;

// The spec runs on the VM: a chart reaches the chart host and dart:ui. Each
// chart case is a `testWidgets` case with the harness of Chart.js ADR 0022,
// section 2. The conventions are those of Chart.js ADR 0030, section 13.
//
// flutter_test_config.dart registers the eight controllers of phase 7 with
// the built-in components before main(). The config of each case has no
// chart `type`: each dataset gives its own type.
//
// The case names keep the upstream spelling ("shoud").

void main() {
  group('Mixed charts', () {
    group('auto', fixture.specs('mixed'));

    testWidgets('shoud be constructed with doughnuts chart', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'type': 'line',
              'data': <Object?>[10, 20, 30, 40],
            },
            <String, Object?>{
              'type': 'doughnut',
              'data': <Object?>[10, 20, 30, 50],
            },
          ],
          'labels': <Object?>[],
        },
      });

      final meta0 = chart.getDatasetMeta(0);
      expect(meta0.type, 'line');
      final meta1 = chart.getDatasetMeta(1);
      expect(meta1.type, 'doughnut');
    });

    testWidgets('shoud be constructed with pie chart', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'type': 'bar',
              'data': <Object?>[10, 20, 30, 40],
            },
            <String, Object?>{
              'type': 'pie',
              'data': <Object?>[10, 20, 30, 50],
            },
          ],
          'labels': <Object?>[],
        },
      });

      final meta0 = chart.getDatasetMeta(0);
      expect(meta0.type, 'bar');
      final meta1 = chart.getDatasetMeta(1);
      expect(meta1.type, 'pie');
    });
  });
}
