// Ported from d3-time-format v4.1.0 test/locale-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_time_format_port/d3_time_format.dart';
import 'package:test/test.dart';

void main() {
  test('locale data is valid', () {
    expect(timeFormatLocales, hasLength(34));
    for (final entry in timeFormatLocales.entries) {
      final def = entry.value;
      expect(def.dateTime, isNotEmpty, reason: '${entry.key}.dateTime');
      expect(def.date, isNotEmpty, reason: '${entry.key}.date');
      expect(def.time, isNotEmpty, reason: '${entry.key}.time');
      expect(def.periods, hasLength(2), reason: '${entry.key}.periods');
      expect(def.days, hasLength(7), reason: '${entry.key}.days');
      expect(def.shortDays, hasLength(7), reason: '${entry.key}.shortDays');
      expect(def.months, hasLength(12), reason: '${entry.key}.months');
      expect(
        def.shortMonths,
        hasLength(12),
        reason: '${entry.key}.shortMonths',
      );
      timeFormatLocale(def);
    }
  });
}
