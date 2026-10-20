// Ported from Chart.js v4.5.1+7169e651 test/specs/platform.basic.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
// The spec builds charts of flutter_chartjs, which does not export lib/src
// yet.
import 'package:flutter_chartjs/src/platform/platform.basic.dart';
import 'package:flutter_test/flutter_test.dart';

// Each case creates a chart with `acquireChart`. Thus each one is a
// `testWidgets` case, and the file runs on the VM (Chart.js ADR 0022,
// sections 1 and 2). `useOffscreenCanvas: true` gives the chart the context
// of a canvas that no chart host shows. `detectPlatform` then gives
// BasicPlatform, as `platform/index.js:7` does for an `OffscreenCanvas`
// (row `harness-acquire-chart`). `toBeInstanceOf(Chart.platforms.
// BasicPlatform)` is `isA<BasicPlatform>()`. test/port/platform/ tests
// BasicPlatform without a chart.

void main() {
  group('Platform.basic', () {
    testWidgets(
      'should automatically choose the BasicPlatform for offscreen canvas',
      (tester) async {
        final chart = acquireChart(
          {'type': 'line'},
          {'useOffscreenCanvas': true},
        );

        expect(chart.platform, isA<BasicPlatform>());

        chart.destroy();
      },
    );

    testWidgets('should disable animations', (tester) async {
      final chart = acquireChart(
        {
          'type': 'line',
          'options': <String, Object?>{'animation': <String, Object?>{}},
        },
        {'useOffscreenCanvas': true},
      );

      expect(chart.options['animation'], false);

      chart.destroy();
    });

    test(
      'supports choosing the BasicPlatform in a web worker',
      () {},
      skip: 'n/a: Flutter has no web worker and no transferControlToOffscreen',
    );

    group('with offscreenCanvas', () {
      test(
        'supports laying out a simple chart',
        () {},
        skip: 'blocked: plugin.legend',
      );

      test(
        'supports resizing a chart',
        () {},
        skip: 'blocked: plugin.legend',
      );
    });
  });
}
