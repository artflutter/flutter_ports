// Ported from Chart.js v4.5.1+7169e651 test/specs/element.line.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;

// The spec constructs Chart.elements.LineElement. Here it is the LineElement
// of element.line.dart (Chart.js ADR 0017). The case of :14 acquires a line
// chart with a Jasmine `done` callback. It is a `testWidgets` case with
// `waitForDone` (Chart.js ADR 0022, section 7), and the file runs on the VM
// (Chart.js ADR 0030, section 12 item 5). It does not call `setUpSpecs()`:
// its charts need the built-in components.

void main() {
  // Tests for the line element
  group('Chart.elements.LineElement', () {
    group('auto', fixture.specs('element.line'));

    test('should be constructed', () {
      // `points: [1, 2, 3, 4]`: a `List<PointElement>` does not take
      // numbers, so the spec passes four point elements.
      final points = <types.PointElement>[
        for (var i = 1; i <= 4; i++) PointElement({'x': i, 'y': i}),
      ];
      final line = LineElement({'points': points});

      expect(line, isNotNull);
      expect(line.points, equals([points[0], points[1], points[2], points[3]]));
    });

    testWidgets('should not cache path when animations are enabled', (
      tester,
    ) async {
      await waitForDone((done) {
        late final Chart chart;
        chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[0, -1, 0],
                'label': 'dataset1',
              },
            ],
            'labels': <Object?>['label1', 'label2', 'label3'],
          },
          'options': <String, Object?>{
            'animation': <String, Object?>{
              'duration': 50,
              'onComplete': () {
                // The dataset element reads `_path` by name, which gives
                // the `undefined` sentinel.
                final line = chart.getDatasetMeta(0).dataset! as LineElement;
                expect(line['_path'], same(undefined));
                done();
              },
            },
          },
        });
      });
    });
  });
}
