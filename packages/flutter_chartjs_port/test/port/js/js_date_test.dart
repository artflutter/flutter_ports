// Original code, not ported from Chart.js: tests of lib/src/js/js_date.dart.
@TestOn('vm')
library;

import 'package:clock/clock.dart';
import 'package:flutter_chartjs_port/src/js/js_date.dart';
import 'package:flutter_test/flutter_test.dart';

// jsDateNow reads clock.now() of package:clock (Chart.js ADR 0045, section
// 6). withClock and the FakeAsync zone of testWidgets replace that clock.

void main() {
  group('jsDateNow', () {
    test('gives whole milliseconds since the epoch of the real clock', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final now = jsDateNow();
      final after = DateTime.now().millisecondsSinceEpoch;
      expect(now, isA<double>());
      expect(now, now.floorToDouble());
      expect(now, inInclusiveRange(before, after));
    });

    test('reads the clock of withClock', () {
      final fixed = DateTime.utc(2026, 10, 19, 12, 0, 0, 7, 999);
      withClock(Clock.fixed(fixed), () {
        expect(jsDateNow(), fixed.millisecondsSinceEpoch.toDouble());
        expect(jsDateNow(), 1792411200007);
      });
    });

    testWidgets('moves with the pumps of testWidgets', (tester) async {
      final start = jsDateNow();
      await tester.pump(const Duration(milliseconds: 16));
      expect(jsDateNow() - start, 16);
      await tester.pump(const Duration(milliseconds: 300));
      expect(jsDateNow() - start, 316);
    });
  });
}
