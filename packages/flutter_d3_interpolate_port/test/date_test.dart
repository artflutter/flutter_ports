// Ported from d3-interpolate v3.0.1 test/date-test.js (ISC, Mike Bostock).
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

void main() {
  test('interpolateDate(a, b) interpolates between two dates a and b', () {
    final i = interpolateDate(DateTime(2000), DateTime(2000, 1, 2));
    expect(i(0), isA<DateTime>());
    expect(i(0.5), isA<DateTime>());
    expect(i(1), isA<DateTime>());
    expect(i(0.2), DateTime(2000, 1, 1, 4, 48));
    expect(i(0.4), DateTime(2000, 1, 1, 9, 36));
  });

  test('interpolateDate(a, b) reuses the output datea', () {
    // const i = interpolateDate(new Date(2000, 0, 1), new Date(2000, 0, 2));
    // assert.strictEqual(i(0.2), i(0.4));
    //
    // A DateTime is immutable: each call returns a new DateTime.
  }, skip: 'diverges: adapt-interpolate-date-value');

  test('interpolateDate(a, b) gives exact ends for t=0 and t=1', () {
    final a = DateTime.fromMillisecondsSinceEpoch(100000000 * 24 * 60 * 60000);
    final b = DateTime.fromMillisecondsSinceEpoch(
      -100000000 * 24 * 60 * 60000 + 1,
    );
    expect(interpolateDate(a, b)(1), b);
    expect(interpolateDate(a, b)(0), a);
  });
}
