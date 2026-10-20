// Ported from Chart.js v4.5.1+7169e651 test/specs/core.animator.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:flutter_chartjs/src/core/core.animator.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

// `Chart.animator` is `animator` of core.animator.dart. The first case makes
// a bar chart: `controller.bar` is a phase 7 module. Its body comes with
// that module, as a `testWidgets` case with `acquireChart` and
// `waitForDone` (Chart.js ADR 0019, section 12, Chart.js ADR 0022).

/// The chart object `{}` of the spec. Its members throw.
final class _Chart implements types.Chart {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Chart.animator', () {
    test(
      'should fire onProgress for each draw',
      () {},
      skip: 'blocked: controller.bar',
    );

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
