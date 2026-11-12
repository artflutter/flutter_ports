// Ported from Chart.js v4.6.1 src/helpers/helpers.intl.ts (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-intl-number-format, a NumberFormat of package:intl.

/// Port of `src/helpers/helpers.intl.ts`.
///
/// `Intl.NumberFormat` is the `NumberFormat` of package:intl (Chart.js ADR
/// 0119). The chart option `locale` holds a Flutter `Locale`, and the tick
/// option `format` holds a `NumberFormat`. The strings are the strings of
/// package:intl, with its defects: the port does not correct them.
library;

import 'dart:ui' show Locale;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:intl/intl.dart';

/// helpers.intl.ts:2 `intlCache`.
///
/// A key is the record of the intl locale name, the scientific notation and
/// the fraction digits (Dart `null` for the defaults of the decimal
/// pattern).
final Map<(String, bool, int?), NumberFormat> _intlCache =
    <(String, bool, int?), NumberFormat>{};

/// helpers.intl.ts:4 `getNumberFormat`.
///
/// The formatter of the decimal pattern of [locale], or of the scientific
/// pattern when [scientific] is true. [fractionDigits] sets the minimum and
/// the maximum fraction digits. Dart `null` keeps the defaults of the
/// pattern. A [locale] without intl data, and Dart `null`, give the current
/// locale of package:intl (`Intl.defaultLocale`, `'en_US'` when the app does
/// not set it). The resolved locale is in the cache key, so a change of
/// `Intl.defaultLocale` reaches the next call.
NumberFormat _getNumberFormat(
  Locale? locale, {
  bool scientific = false,
  int? fractionDigits,
}) {
  final name = _localeName(locale) ?? Intl.getCurrentLocale();
  final cacheKey = (name, scientific, fractionDigits);
  var formatter = _intlCache[cacheKey];
  if (formatter == null) {
    formatter = scientific
        ? NumberFormat.scientificPattern(name)
        : NumberFormat.decimalPattern(name);
    if (fractionDigits != null) {
      formatter
        ..maximumFractionDigits = fractionDigits
        ..minimumFractionDigits = fractionDigits;
    }
    _intlCache[cacheKey] = formatter;
  }
  return formatter;
}

/// The intl locale of [locale], or Dart `null` when [locale] is Dart `null`
/// or has no intl data.
String? _localeName(Locale? locale) => locale == null
    ? null
    : Intl.verifiedLocale(
        locale.toLanguageTag(),
        NumberFormat.localeExists,
        onFailure: (_) => null,
      );

/// helpers.intl.ts:15 `formatNumber`.
///
/// Upstream names the first parameter `num`, a Dart type name. [locale] is
/// `chart.options.locale`. [format] is the tick option `format`: it formats
/// [number] as it is. Without it, the decimal pattern of [locale] formats
/// [number], as `new Intl.NumberFormat(locale)` does.
String formatNumber(double number, Locale? locale, [NumberFormat? format]) {
  return (format ?? _getNumberFormat(locale)).format(number);
}

/// [formatNumber] with the options of `formatters.numeric`
/// (core.ticks.js:56): the scientific notation when [scientific] is true,
/// and [fractionDigits] as the minimum and the maximum fraction digits.
String formatNumberDigits(
  double number,
  Locale? locale, {
  required bool scientific,
  required int fractionDigits,
}) => _getNumberFormat(
  locale,
  scientific: scientific,
  fractionDigits: fractionDigits,
).format(number);

/// The chart option `locale` of the resolved option value [value]: a
/// [Locale], or Dart `null` when the option is absent. Another value stops
/// a debug build, for example a language tag as text (Chart.js ADR 0119).
/// A release build takes Dart `null`, the current locale.
Locale? localeOf(Object? value) {
  assert(
    value == null || value is Locale || value is Undefined,
    'The option locale holds a Locale (Chart.js ADR 0119), not $value.',
  );
  return value is Locale ? value : null;
}

/// The tick option `format` of the resolved option value [value]: a
/// [NumberFormat], or Dart `null` when the option is absent. Another value
/// stops a debug build, for example an object of number format options
/// (Chart.js ADR 0119). A release build takes Dart `null`, the formatter of
/// the chart.
NumberFormat? numberFormatOf(Object? value) {
  assert(
    value == null || value is NumberFormat || value is Undefined,
    'The tick option format holds a NumberFormat (Chart.js ADR 0119), '
    'not $value.',
  );
  return value is NumberFormat ? value : null;
}
