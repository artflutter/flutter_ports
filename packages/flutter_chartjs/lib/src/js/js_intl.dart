// Original code, not ported from Chart.js: Intl.NumberFormat on package:intl.

/// `new Intl.NumberFormat(locale, options)` on the `NumberFormat` of
/// package:intl (Chart.js ADR 0008).
///
/// The strings are the strings of package:intl, not of V8. Chart.js ADR 0008
/// lists the known differences, and `test/port/js/js_intl_test.dart` pins a
/// few of them.
///
/// Locale ([jsNumberFormatLocale]):
/// - A String is a BCP 47 tag or an intl locale name. `Intl.verifiedLocale`
///   finds the intl locale: `'en-US'` gives `'en_US'`, `'de-DE'` gives
///   `'de'`.
/// - A List is a list of tags. The first String tag with intl data wins, as
///   in V8.
/// - [undefined], `null` and any other value give the current intl locale,
///   `Intl.getCurrentLocale()`. An app sets it with `Intl.defaultLocale`. It
///   is `'en_US'` when the app does not set it.
/// - A tag without intl data gives the current intl locale, as V8 gives its
///   default locale. If the current locale also has no data, the result is
///   `'en_US'`.
///
/// Options, read from the JS options object of Chart.js ADR 0006:
/// - `style`: `'decimal'`, `'percent'`, and `'currency'` with `currency`.
///   The currency style writes the simple symbol of package:intl.
/// - `notation`: `'standard'`, `'scientific'` and `'compact'`
///   (`NumberFormat.compact`). `'engineering'` gives scientific notation.
///   The percent style ignores `notation`. The currency style ignores
///   scientific and compact notation.
/// - `minimumIntegerDigits`, `minimumFractionDigits`,
///   `maximumFractionDigits`, `minimumSignificantDigits` and
///   `maximumSignificantDigits`, with the defaults and the precedence of
///   ECMA-402: the significant digits win over the fraction digits.
/// - `useGrouping`: a falsy value turns the grouping off. Every other value
///   keeps the grouping of the locale.
///
/// The function ignores every other option and value, for example
/// `style: 'unit'`, `signDisplay`, `roundingMode`, `compactDisplay`,
/// `currencyDisplay`, and `'currency'` without a `currency`. Thus such an
/// option does not stop a chart.
///
/// A digit option outside the range of ECMA-402, or a minimum above its
/// maximum, throws an [ArgumentError], as V8 throws a `RangeError`.
///
/// Guards against package:intl failures. [JsNumberFormat.format] does not
/// throw for any double:
/// - At most [maxFractionDigits] (15) fraction digits, and two less for
///   percent, on every platform. intl computes `10^digits` times the percent
///   multiplier in an int. On dart2js, an int is a double, which drops the
///   low digits above `2^53`. With significant digits, intl takes the
///   fraction digits from the value: `1.5e-100` asks for 102 of them. Thus a
///   value below about `1e-15` loses its digits: `1.5e-100` gives `'0'`.
/// - Compact notation writes NaN and the infinities as the decimal style
///   does: intl throws for them.
/// - Scientific notation writes a subnormal number as JS
///   `Number.prototype.toString` does, with `E` for `e`: intl divides by
///   `pow(10.0, exponent)`, which is subnormal or 0 there.
library;

import 'dart:math';

import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:intl/intl.dart';

/// The most fraction digits that [jsNumberFormat] gives to package:intl.
///
/// The same cap on every platform. On dart2js, an int is exact up to `2^53`,
/// so `10^15` plus the fraction digits is exact. The percent style has two
/// digits less, for its multiplier 100.
const int maxFractionDigits = 15;

/// The smallest positive normal double, `2^-1022`.
const double _minNormal = 2.2250738585072014e-308;

/// The intl locale for the JS locale argument [locale].
///
/// See the library documentation for the rules.
String jsNumberFormatLocale(Object? locale) {
  final current = Intl.verifiedLocale(
    Intl.getCurrentLocale(),
    NumberFormat.localeExists,
    onFailure: (_) => 'en_US',
  )!;
  final tags = switch (locale) {
    final String tag => [tag],
    final List<Object?> list => list.whereType<String>(),
    _ => const <String>[],
  };
  for (final tag in tags) {
    final verified = Intl.verifiedLocale(
      tag,
      NumberFormat.localeExists,
      onFailure: (_) => null,
    );
    if (verified != null) return verified;
  }
  return current;
}

/// A `NumberFormat` of package:intl with the guards of the library
/// documentation.
final class JsNumberFormat {
  JsNumberFormat._(this.intl, this._compact, this._exponent);

  /// The package:intl formatter.
  final NumberFormat intl;

  final bool _compact;
  final bool _exponent;

  /// `Intl.NumberFormat.prototype.format(value)`.
  String format(double value) {
    if (_compact && !value.isFinite) {
      final symbols = intl.symbols;
      if (value.isNaN) return symbols.NAN;
      return '${value < 0 ? symbols.MINUS_SIGN : ''}${symbols.INFINITY}';
    }
    if (_exponent && value != 0 && value.abs() < _minNormal) {
      return jsNumberToString(value).toUpperCase();
    }
    return intl.format(value);
  }
}

/// `new Intl.NumberFormat(locale, options)`: a [JsNumberFormat] on a
/// `NumberFormat` of package:intl.
///
/// [locale] is the JS locale argument ([jsNumberFormatLocale]). [options] is
/// the JS options object. `null` stands for `undefined`. In the map, an
/// absent key and [undefined] mean `undefined`.
///
/// See the library documentation for the options.
JsNumberFormat jsNumberFormat(
  Object? locale, [
  Map<String, Object?>? options,
]) {
  final o = options ?? const <String, Object?>{};
  final tag = jsNumberFormatLocale(locale);

  String? text(String key) => switch (o[key]) {
    final String s => s,
    _ => null,
  };
  int? digits(String key, int min, int max) {
    final value = o[key];
    if (!o.containsKey(key) || value is Undefined) return null;
    final n = jsToNumber(value);
    if (n.isNaN || n < min || n > max) {
      throw ArgumentError.value(value, key, 'Out of range $min-$max');
    }
    return n.floor();
  }

  final notation = text('notation') ?? 'standard';
  final style = text('style');
  // ECMA-402 upper-cases the currency code.
  final currency = style == 'currency' ? text('currency')?.toUpperCase() : null;
  final plain = style != 'percent' && currency == null;
  final compact = notation == 'compact' && plain;
  // Engineering notation falls back to scientific notation.
  final scientific =
      (notation == 'scientific' || notation == 'engineering') && plain;
  final format = switch (currency) {
    final String name => NumberFormat.simpleCurrency(locale: tag, name: name),
    _ when style == 'percent' => NumberFormat.percentPattern(tag),
    _ when compact => NumberFormat.compact(locale: tag),
    _ when scientific =>
      NumberFormat.scientificPattern(tag)
        // One integer digit.
        ..minimumIntegerDigits = 1
        ..maximumIntegerDigits = 1,
    _ => NumberFormat.decimalPattern(tag),
  };
  final cap = maxFractionDigits + 1 - '${format.multiplier}'.length;

  final minimumInteger = digits('minimumIntegerDigits', 1, 21);
  final minimumFraction = digits('minimumFractionDigits', 0, 100);
  final maximumFraction = digits('maximumFractionDigits', 0, 100);
  final minimumSignificant = digits('minimumSignificantDigits', 1, 21);
  final maximumSignificant = digits('maximumSignificantDigits', 1, 21);

  if (minimumInteger != null) format.minimumIntegerDigits = minimumInteger;
  if (minimumSignificant != null || maximumSignificant != null) {
    final minimum = minimumSignificant ?? 1;
    final maximum = maximumSignificant ?? 21;
    if (minimum > maximum) {
      throw ArgumentError.value(maximum, 'maximumSignificantDigits');
    }
    // The fraction digits that intl takes from the significant digits stop
    // at the cap. The setter turns the significant digits off, so it comes
    // first.
    format.maximumFractionDigits = cap;
    if (maximumSignificant != null) format.maximumSignificantDigits = maximum;
    if (minimumSignificant != null) format.minimumSignificantDigits = minimum;
  } else if (minimumFraction != null || maximumFraction != null || scientific) {
    // ECMA-402 SetNumberFormatDigitOptions: the default of the style fills
    // in a missing bound. For scientific notation, the defaults of a decimal
    // number (0 and 3) replace the 0 and 0 of the intl pattern.
    final defaultMaximum = scientific ? 3 : format.maximumFractionDigits;
    final minimum =
        minimumFraction ??
        min(format.minimumFractionDigits, maximumFraction ?? defaultMaximum);
    final maximum = maximumFraction ?? max(defaultMaximum, minimum);
    if (minimum > maximum) {
      throw ArgumentError.value(maximum, 'maximumFractionDigits');
    }
    format
      ..maximumFractionDigits = min(maximum, cap)
      ..minimumFractionDigits = min(minimum, cap);
  } else if (compact) {
    // Compact notation has three significant digits: cap them as above.
    format
      ..maximumFractionDigits = cap
      ..significantDigitsInUse = true;
  }

  final useGrouping = o.containsKey('useGrouping')
      ? o['useGrouping']
      : undefined;
  if (useGrouping is! Undefined && !jsTruthy(useGrouping)) {
    format.turnOffGrouping();
  }
  return JsNumberFormat._(format, compact, scientific);
}
