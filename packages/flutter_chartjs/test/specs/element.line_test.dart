// Ported from Chart.js v4.5.1 test/specs/element.line.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/elements/element.line.dart';
import 'package:flutter_chartjs/src/elements/element.point.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:test/test.dart';

// The spec constructs Chart.elements.LineElement. Here it is the LineElement
// of element.line.dart (Chart.js ADR 0017).

void main() {
  setUpSpecs();

  // Tests for the line element
  group('Chart.elements.LineElement', () {
    // describe('auto', jasmine.fixture.specs('element.line')): a fixture
    // group of phase 7, not a case.

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

    test(
      'should not cache path when animations are enabled',
      () {
        // var chart = window.acquireChart({
        //   type: 'line',
        //   data: {
        //     datasets: [{
        //       data: [0, -1, 0],
        //       label: 'dataset1',
        //     }],
        //     labels: ['label1', 'label2', 'label3']
        //   },
        //   options: {
        //     animation: {
        //       duration: 50,
        //       onComplete: () => {
        //         expect(chart.getDatasetMeta(0).dataset._path)
        //             .toBeUndefined();
        //         done();
        //       }
        //     }
        //   }
        // });
        //
        // The dataset element reads `_path` by name:
        // `chart.getDatasetMeta(0).dataset['_path']`, which gives the
        // `undefined` sentinel.
      },
      skip: 'blocked: controller.line',
    );
  });
}
