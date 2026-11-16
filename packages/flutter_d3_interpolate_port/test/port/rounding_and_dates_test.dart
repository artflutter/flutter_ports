// Original code, not ported from d3-interpolate: the rounding and date pins.

/// Pins the `Math.round` of `round.js` and `color.js` (a negative half
/// rounds up) and the truncation of `interpolateDate` toward zero. Each
/// upstream value comes from the source of `third_party/d3-interpolate` in
/// Node.js v24.22.1 on arm64.
library;

import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

void main() {
  test('interpolateRound rounds a negative half up, as Math.round', () {
    expect(interpolateRound(-3, -2)(0.5), -2);
    expect(interpolateRound(-1, -2)(0.5), -1);
    expect(interpolateRound(2, 3)(0.5), 3);
    final z = interpolateRound(0, -1)(0.5);
    expect(z, 0);
    expect(z.isNegative, isTrue, reason: 'Math.round(-0.5) is -0');
  });

  test('interpolateHue takes the upstream path for a difference of -540 or '
      '540', () {
    // d - 360 * Math.round(d / 360) with d / 360 = -1.5 gives -180.
    expect(interpolateHue(540, 0)(0.5), 90);
    expect(interpolateHue(-540, 0)(0.5), 90);
    expect(interpolateHue(0, 540)(0.5), 270);
  });

  group('interpolateDate', () {
    DateTime ms(int value) =>
        DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    DateTime us(int value) =>
        DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true);

    test('truncates the time toward zero', () {
      // Upstream: 0 for both (0.0005 and -0.0005 milliseconds).
      expect(interpolateDate(ms(0), ms(1))(0.0005), ms(0));
      expect(interpolateDate(ms(0), ms(-1))(0.0005), ms(0));
    });

    test('keeps the microseconds of the result', () {
      // Upstream truncates to the millisecond: -1 for -1.5 ms.
      expect(interpolateDate(ms(0), ms(-3))(0.5), us(-1500));
      expect(interpolateDate(ms(0), ms(1))(0.25), us(250));
      expect(interpolateDate(us(1), us(3))(0.5), us(2));
    });

    test('returns a new date in the zone of b', () {
      final i = interpolateDate(DateTime(2000), DateTime.utc(2000, 1, 2));
      expect(i(0.5).isUtc, isTrue);
      expect(identical(i(0.5), i(0.5)), isFalse);
    });
  });
}
