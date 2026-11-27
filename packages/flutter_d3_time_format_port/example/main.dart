// Original code, not ported from d3-time-format: package usage example.

// Example prints formatted dates to stdout.
// ignore_for_file: avoid_print

import 'package:flutter_d3_time_format_port/d3_time_format.dart';

void main() {
  final sample = DateTime.utc(2024, 6, 15, 14, 37, 22, 432);

  // 1. Format and parse in UTC or local time
  final formatDate = utcFormat('%B %-d, %Y at %H:%M:%S.%L UTC');
  final formatted = formatDate(sample);
  print(formatted); // June 15, 2024 at 14:37:22.432 UTC

  final parsed = utcParse('%Y-%m-%d %H:%M:%S')('2024-06-15 14:37:22');
  print(parsed); // 2024-06-15 14:37:22.000Z

  // 2. ISO 8601 round-trip
  final iso = isoFormat(sample);
  print('$iso -> ${isoParse(iso)}');

  // 3. Built-in const locales (34 locales, zero I/O)
  final fr = timeFormatLocale(timeLocaleFrFR);
  final ja = timeFormatLocale(timeLocaleJaJP);
  print('fr-FR: ${fr.utcFormat('%c')(sample)}');
  print('ja-JP: ${ja.utcFormat('%c')(sample)}');
}
