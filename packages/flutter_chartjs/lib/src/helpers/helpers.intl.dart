// Ported from Chart.js v4.5.1 src/helpers/helpers.intl.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/helpers.intl.ts`.
///
/// `Intl.NumberFormat` is the `NumberFormat` of package:intl (Chart.js ADR
/// 0026). [jsNumberFormat] in `lib/src/js/js_intl.dart` maps the
/// locale and the options. The strings are the strings of package:intl, not
/// of V8. The guards of the adapter write the digits of V8 for numbers from
/// `2^53`, in scientific notation and for more than 15 fraction digits, and
/// the affixes of the pattern for NaN and the infinities.
library;

import 'package:flutter_chartjs/src/js/js_intl.dart';

/// helpers.intl.ts:2 `intlCache`.
final Map<String, JsNumberFormat> _intlCache = <String, JsNumberFormat>{};

/// helpers.intl.ts:4 `getNumberFormat`.
///
/// [locale] is a resolved option value (Chart.js ADR 0006): `undefined`,
/// JS `null` (Dart `null`), a String or a List of Strings. The cache key is
/// [_cacheKey], not `locale + JSON.stringify(options)`.
JsNumberFormat _getNumberFormat(
  Object? locale, [
  Map<String, Object?>? options,
]) {
  // Upstream reassigns its parameter.
  // ignore: parameter_assignments
  options = options ?? <String, Object?>{};
  // DIVERGES(chartjs): adapt-intl-number-format, locale and entries key.
  final cacheKey = _cacheKey(locale, options);
  var formatter = _intlCache[cacheKey];
  if (formatter == null) {
    // DIVERGES(chartjs): adapt-intl-number-format, package:intl NumberFormat.
    formatter = jsNumberFormat(locale, options);
    _intlCache[cacheKey] = formatter;
  }
  return formatter;
}

/// The key of [_intlCache]: the intl locale of [jsNumberFormatLocale], then
/// each entry of [options] as `key: value`.
///
/// It reads the entries, as `JSON.stringify` reads the values of a
/// resolver. The `toString` of a `Resolver` lists only its cache. A String
/// value is in quotes, as in JSON. Thus `false` and `'false'` give two keys.
String _cacheKey(Object? locale, Map<String, Object?> options) => [
  jsNumberFormatLocale(locale),
  for (final MapEntry(:key, :value) in options.entries)
    '$key: ${value is String ? "'$value'" : value}',
].join(', ');

/// helpers.intl.ts:15 `formatNumber`.
///
/// Upstream names the first parameter `num`, a Dart type name. [locale] is
/// `chart.options.locale`, a resolved option value (Chart.js ADR 0006). A
/// String is a BCP 47 tag, and a List is a list of tags. `undefined` gives
/// the current locale of package:intl (`Intl.defaultLocale`, `'en_US'` when
/// the app does not set it). In [options], an absent key and `undefined` are
/// `undefined`.
///
/// The cache key holds the resolved intl locale. Thus a change of
/// `Intl.defaultLocale` also changes a chart without a `locale` option.
///
/// Throws a [TypeError] for Dart `null` (JS `null`), as V8 does. Throws an
/// [ArgumentError] for a tag that is not valid, for example `'en_US'`, and
/// for a digit option out of range, as V8 throws a `RangeError`
/// ([jsNumberFormatLocale] and [jsNumberFormat]). [jsNumberFormat] ignores
/// the options that it does not support.
String formatNumber(
  double number,
  Object? locale, [
  Map<String, Object?>? options,
]) {
  return _getNumberFormat(locale, options).format(number);
}
