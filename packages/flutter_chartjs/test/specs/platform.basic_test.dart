// Ported from Chart.js v4.5.1 test/specs/platform.basic.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:test/test.dart';

// Each case creates a chart. The port gives BasicPlatform for a canvas that
// no chart host shows, the counterpart of `useOffscreenCanvas: true`
// (Chart.js ADR 0014). test/port/platform/ tests BasicPlatform without a
// chart.

void main() {
  setUpSpecs();
  group('Platform.basic', () {
    test(
      'should automatically choose the BasicPlatform for offscreen canvas',
      () {},
      skip: 'blocked: core.controller',
    );

    test(
      'should disable animations',
      () {},
      skip: 'blocked: core.controller',
    );

    test(
      'supports choosing the BasicPlatform in a web worker',
      () {},
      skip: 'n/a: Flutter has no web worker and no transferControlToOffscreen',
    );

    group('with offscreenCanvas', () {
      test(
        'supports laying out a simple chart',
        () {},
        skip: 'blocked: core.controller',
      );

      test(
        'supports resizing a chart',
        () {},
        skip: 'blocked: core.controller',
      );
    });
  });
}
