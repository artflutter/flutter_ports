// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/utils.test.ts (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:flutter_chartjs_plugin_zoom_port/src/options.dart'
    show Mode, ZoomChartContext;
import 'package:flutter_chartjs_plugin_zoom_port/src/utils.dart';
import 'package:flutter_chartjs_port/chartjs.dart' show Chart;
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';

/// `{} as Chart`: a chart that `directionEnabled` only passes on.
final class _FakeChart extends Fake implements Chart {}

void main() {
  group('utils', () {
    group('directionEnabled', () {
      final Chart chart = _FakeChart();
      const testCases = <({Mode mode, String dir, bool expected})>[
        (mode: Mode.xy, dir: 'x', expected: true),
        (mode: Mode.x, dir: 'x', expected: true),
        (mode: Mode.y, dir: 'x', expected: false),

        (mode: Mode.xy, dir: 'y', expected: true),
        (mode: Mode.x, dir: 'y', expected: false),
        (mode: Mode.y, dir: 'y', expected: true),
      ];

      for (final (:mode, :dir, :expected) in testCases) {
        test(
          'returns $expected when mode is ${mode.name} and required direction '
          'is $dir',
          () {
            expect(directionEnabled(mode, dir, chart), jasmineEquals(expected));

            final modeFn = createSpy('mode').and.returnValue(mode);

            expect(
              directionEnabled(
                (ZoomChartContext context) => modeFn.call(context)! as Mode,
                dir,
                chart,
              ),
              jasmineEquals(expected),
            );
            expect(modeFn, toHaveBeenCalledWith([(chart: chart)]));
          },
        );
      }
    });
  });
}
