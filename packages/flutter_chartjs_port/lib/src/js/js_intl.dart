// Original code, not ported from Chart.js: Intl.NumberFormat on package:intl.

/// `new Intl.NumberFormat(locale, options)` on the `NumberFormat` of
/// package:intl (Chart.js ADR 0026).
///
/// The strings are the strings of package:intl, not of V8. Chart.js ADR 0026
/// lists the known differences, and `test/port/js/js_intl_test.dart` pins a
/// few of them.
///
/// Locale ([jsNumberFormatLocale]). The tags come from the locale argument
/// as in `CanonicalizeLocaleList` of ECMA-402:
/// - [undefined] gives no tags. A String is one tag. A List is a list of
///   tags. A Map (a JS object) is an array-like list: the keys `'0'`, `'1'`
///   and so on below its `length`. A bool, a number and a function give no
///   tags.
/// - JS `null` (Dart `null`) throws a [TypeError], as in V8.
/// - An item of a list that is `null`, [undefined], a bool or a number
///   throws a [TypeError], as in V8. Another item that is not a String gives
///   its `ToString` ([jsToString]).
/// - A tag that is not a structurally valid language tag of ECMA-402 throws
///   an [ArgumentError], as V8 throws a `RangeError`. Examples are `''`,
///   `'x'`, `'root'` and the intl locale names `'en_US'` and `'de_DE'`:
///   BCP 47 uses `-`, not `_`. The function examines all the tags before it
///   selects one, as V8 does. V8 (ICU) also throws for some very long tags:
///   variants of 180 or more characters with their `-`, or more than 25
///   different keys in the `u` extension. The port does not.
/// - `Intl.verifiedLocale` finds the intl locale of a tag: `'en-US'` gives
///   `'en_US'`, `'de-DE'` gives `'de'`. The first tag with intl data wins,
///   as in V8.
/// - Without a tag with intl data, the result is the current intl locale,
///   `Intl.getCurrentLocale()`, as V8 gives its default locale. An app sets
///   the current locale with `Intl.defaultLocale`. It is `'en_US'` when the
///   app does not set it. If the current locale has no intl data, the
///   result is `'en_US'`.
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
/// Guards against package:intl failures (Chart.js ADR 0026).
/// [JsNumberFormat.format] does not throw for any double:
/// - intl gets at most [maxFractionDigits] (15) fraction digits, and two
///   less for percent, on every platform. intl computes `10^digits` times
///   the percent multiplier in an int. On dart2js, an int is a double, which
///   drops the low digits above `2^53`. With significant digits, intl takes
///   the fraction digits from the value: `1.5e-100` asks for 102 of them.
///   Thus a value below about `1e-15` loses its digits: `1.5e-100` gives
///   `'0'`. V8 writes up to 20 fraction digits. The cap applies where intl
///   writes the digits: the standard notation below `2^53` with significant
///   digits, and compact notation.
/// - Below `2^53`, the standard notation with more maximum fraction digits
///   than the cap writes the shortest decimal digits of the double, rounded
///   half away from zero to the maximum fraction digits, as V8 does.
///   `formatters.numeric` asks for up to 20 fraction digits: two ticks
///   `0.3` and `0.1 + 0.2` get 17. V8 gives `'0.30000000000000000'` and
///   `'0.30000000000000004'`. intl with the cap gives `'0.300000000000000'`
///   for both.
/// - NaN and the infinities get the prefix and the suffix of the pattern, as
///   in V8: `'NaN%'`, `'$NaN'` and `'-\u{221E}\u{A0}\u{20AC}'`. intl
///   writes NaN without them, and an infinity without the suffix. Compact
///   notation writes them as the decimal style does: intl throws for them.
/// - From `2^53`, the standard notation writes the shortest decimal digits
///   of the double (the digits of `Number::toString`) and zeros, as V8
///   does. Significant digits round these digits half away from zero. The
///   pattern of the style gives the groups. intl writes other digits there.
///   On the VM and dart2wasm, it writes the binary value, and a 64-bit int
///   overflows from `2^63`: `1e21` gives `'922,337,203,685,477,580,700'`.
///   On dart2js, it writes 16 digits and zeros.
/// - Compact notation does the same from `2^53` units. The unit is the unit
///   that intl writes for `1e18`. With many significant or fraction digits,
///   intl on the VM and dart2wasm selects a smaller unit than V8. The
///   significant digits round the count of units, and the minimum digits
///   give the zeros of its fraction, as in V8. The guard does not group the
///   digits, as intl does not group compact numbers. There, intl overflows
///   on the VM and dart2wasm, and can throw on dart2js.
/// - Scientific notation takes the exponent and the digits from the
///   shortest decimal digits, and rounds them half away from zero, as V8
///   does. It writes them with the symbols of the decimal pattern of the
///   locale. The scientific pattern of intl takes the exponent from a
///   logarithm: it gives `'10E14'` for `1e15`. A mantissa that rounds up to
///   10 also keeps its exponent: `9.5e14` with no fraction digits gives
///   `'10E14'`. V8 gives `'1E15'` for both. In some locales, the scientific
///   pattern of intl has brackets (`hi`) or no exponent (`lo`), and V8 does
///   not.
library;

import 'dart:math';

import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:intl/intl.dart';

/// The most fraction digits that [jsNumberFormat] gives to package:intl.
///
/// The same cap on every platform. On dart2js, an int is exact up to `2^53`,
/// so `10^15` plus the fraction digits is exact. The percent style has two
/// digits less, for its multiplier 100.
const int maxFractionDigits = 15;

/// `2^53`. From this value, every double is an integer, and package:intl
/// writes other digits than V8.
const double _twoTo53 = 9007199254740992;

/// The digits and the comma of the integer part of a number pattern.
final RegExp _integerPattern = RegExp('[#0,]+');

/// The intl locale for the JS locale argument [locale].
///
/// See the library documentation for the rules. Throws a [TypeError] and
/// an [ArgumentError] where V8 throws a `TypeError` and a `RangeError`.
String jsNumberFormatLocale(Object? locale) {
  final current = Intl.verifiedLocale(
    Intl.getCurrentLocale(),
    NumberFormat.localeExists,
    onFailure: (_) => 'en_US',
  )!;
  for (final tag in _localeList(locale)) {
    final verified = Intl.verifiedLocale(
      tag,
      NumberFormat.localeExists,
      onFailure: (_) => null,
    );
    if (verified != null) return verified;
  }
  return current;
}

/// `CanonicalizeLocaleList(locales)` of ECMA-402, without the
/// canonicalization: the tags of the JS locale argument [locale].
///
/// The list is complete before the caller selects a tag. Thus a tag that is
/// not valid throws also after a tag with intl data, as in V8.
List<String> _localeList(Object? locale) {
  final Iterable<Object?> items;
  switch (locale) {
    case Undefined():
      return const [];
    case null:
      // A JavaScript TypeError: ToObject of null.
      throw TypeError();
    case final String tag:
      return [_validTag(tag)];
    case final List<Object?> list:
      items = list;
    case final Map<Object?, Object?> object:
      // ToLength(object.length): the index keys below the length.
      final length = jsToNumber(jsGet(object, 'length'));
      final indices = [
        for (final key in object.keys)
          if (_arrayIndex(key) case final index? when index + 1 <= length)
            index,
      ]..sort();
      items = [for (final index in indices) jsGet(object, '$index')];
    default:
      // ToObject of a bool, a number or a function has no index keys.
      return const [];
  }
  return [
    for (final item in items)
      switch (item) {
        final String tag => _validTag(tag),
        // A JavaScript TypeError: an item that is not a String or an object.
        null || Undefined() || bool() || num() => throw TypeError(),
        _ => _validTag(jsToString(item)),
      },
  ];
}

/// The canonical array index [key] (`'0'`, `'1'` and so on), or null.
int? _arrayIndex(Object? key) {
  if (key is! String) return null;
  final index = int.tryParse(key);
  return index != null && index >= 0 && '$index' == key ? index : null;
}

/// The last tag that [_validTag] accepted. A chart formats each tick label
/// with the same tag. This check costs less than the examination of the
/// tag.
String? _lastValidTag;

/// [tag], when it is a structurally valid language tag of ECMA-402
/// (`IsStructurallyValidLanguageTag`).
///
/// Throws an [ArgumentError] for another String, as V8 throws a
/// `RangeError`.
String _validTag(String tag) {
  if (tag == _lastValidTag) return tag;
  if (_isStructurallyValid(tag)) return _lastValidTag = tag;
  throw ArgumentError.value(
    tag,
    'locale',
    'Incorrect locale information provided',
  );
}

/// Whether [tag] is a `unicode_locale_id` of UTS 35 in the BCP 47 syntax,
/// without a duplicate variant or a duplicate singleton
/// (`IsStructurallyValidLanguageTag` of ECMA-402). The letters of the two
/// cases are the same. Only ASCII letters and digits are letters and
/// digits.
///
/// The grammar (UTS 35, section 3.2):
/// - The language id: a language (2-3 or 5-8 letters), then maybe a script
///   (4 letters), a region (2 letters or 3 digits) and variants (5-8 letters
///   and digits, or a digit and 3 letters and digits).
/// - Then the extensions. Each extension starts with a singleton: one
///   letter or digit. `u` has attributes (3-8 letters and digits), then
///   keywords: a key (a letter or digit, then a letter) and its types (3-8
///   letters and digits). `t` has a language id without the extensions,
///   then fields: a key (a letter, then a digit) and its values (3-8 letters
///   and digits). Another singleton has subtags of 2-8 letters and digits.
/// - Then maybe the private use: `x` and subtags of 1-8 letters and digits.
///
/// The BCP 47 syntax has no `root`, no `_` and no language id that starts
/// with a script.
bool _isStructurallyValid(String tag) {
  final subtags = tag.split('-');
  final n = subtags.length;
  var i = _languageId(subtags, 0);
  if (i < 0) return false;
  final singletons = <String>{};
  while (i < n) {
    final singleton = subtags[i].toLowerCase();
    if (!_run(singleton, 1, 1, _isAlnum)) return false;
    final start = ++i;
    if (singleton == 'x') {
      while (i < n && _run(subtags[i], 1, 8, _isAlnum)) {
        i++;
      }
      return i == n && i > start;
    }
    if (!singletons.add(singleton)) return false;
    switch (singleton) {
      case 'u':
        while (i < n && _run(subtags[i], 3, 8, _isAlnum)) {
          i++;
        }
        while (i < n && _isUnicodeKey(subtags[i])) {
          i++;
          while (i < n && _run(subtags[i], 3, 8, _isAlnum)) {
            i++;
          }
        }
      case 't':
        if (i < n && _isLanguage(subtags[i])) {
          i = _languageId(subtags, i);
          if (i < 0) return false;
        }
        while (i < n && _isTransformedKey(subtags[i])) {
          final values = ++i;
          while (i < n && _run(subtags[i], 3, 8, _isAlnum)) {
            i++;
          }
          if (i == values) return false;
        }
      default:
        while (i < n && _run(subtags[i], 2, 8, _isAlnum)) {
          i++;
        }
    }
    if (i == start) return false;
  }
  return true;
}

/// The index after the language id that starts at [start] in [subtags], or
/// -1 when there is no language id or it has a duplicate variant.
int _languageId(List<String> subtags, int start) {
  final n = subtags.length;
  if (start >= n || !_isLanguage(subtags[start])) return -1;
  var i = start + 1;
  if (i < n && _run(subtags[i], 4, 4, _isAlpha)) i++;
  if (i < n &&
      (_run(subtags[i], 2, 2, _isAlpha) || _run(subtags[i], 3, 3, _isDigit))) {
    i++;
  }
  final variants = <String>{};
  while (i < n && _isVariant(subtags[i])) {
    if (!variants.add(subtags[i].toLowerCase())) return -1;
    i++;
  }
  return i;
}

/// A language subtag: 2-3 or 5-8 letters.
bool _isLanguage(String s) => s.length != 4 && _run(s, 2, 8, _isAlpha);

/// A variant subtag: 5-8 letters and digits, or a digit and 3 letters and
/// digits.
bool _isVariant(String s) =>
    _run(s, 5, 8, _isAlnum) ||
    (s.length == 4 && _isDigit(s.codeUnitAt(0)) && _run(s, 4, 4, _isAlnum));

/// A key of the `u` extension: a letter or a digit, then a letter.
bool _isUnicodeKey(String s) =>
    s.length == 2 && _isAlnum(s.codeUnitAt(0)) && _isAlpha(s.codeUnitAt(1));

/// A key of the `t` extension: a letter, then a digit.
bool _isTransformedKey(String s) =>
    s.length == 2 && _isAlpha(s.codeUnitAt(0)) && _isDigit(s.codeUnitAt(1));

/// Whether [s] has [min] to [max] code units, and [test] accepts each.
bool _run(String s, int min, int max, bool Function(int) test) {
  if (s.length < min || s.length > max) return false;
  for (var i = 0; i < s.length; i++) {
    if (!test(s.codeUnitAt(i))) return false;
  }
  return true;
}

/// An ASCII letter of one of the two cases.
bool _isAlpha(int c) => (c | 0x20) >= 0x61 && (c | 0x20) <= 0x7A;

/// An ASCII digit.
bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

/// An ASCII letter or digit.
bool _isAlnum(int c) => _isAlpha(c) || _isDigit(c);

/// A `NumberFormat` of package:intl with the guards of the library
/// documentation.
final class JsNumberFormat {
  JsNumberFormat._(
    this.intl,
    this._compact,
    this._scientific,
    this._pattern,
    this._fraction,
    this._significant,
    this._manyFraction,
  );

  /// The package:intl formatter. It gives the symbols and the affixes to the
  /// guards.
  final NumberFormat intl;

  final bool _compact;
  final bool _scientific;

  /// The pattern of the style, or null for no grouping.
  final String? _pattern;

  /// The minimum and the maximum fraction digits of ECMA-402, without the
  /// cap of [maxFractionDigits].
  final (int, int) _fraction;

  /// The minimum and the maximum significant digits, or null when the
  /// fraction digits apply.
  final (int, int)? _significant;

  /// Whether the standard notation applies the fraction digits, and their
  /// maximum is above the cap of [maxFractionDigits].
  final bool _manyFraction;

  /// The groups of the integer digits, from [_pattern] as in intl: the size
  /// of the last group, 0 for no grouping, and the size of the other groups.
  /// These are the digits after the last comma, and between the last two
  /// commas.
  late final (int, int) _groups = () {
    final pattern = _pattern;
    final groups = pattern == null
        ? const <String>[]
        : _integerPattern.firstMatch(pattern)![0]!.split(',');
    final last = groups.length > 1 ? groups.last.length : 0;
    return (last, groups.length > 2 ? groups[groups.length - 2].length : last);
  }();

  /// `Intl.NumberFormat.prototype.format(value)`.
  String format(double value) {
    if (!value.isFinite) return _nonFinite(value);
    if (_scientific) return _exponential(value);
    if (value.abs() < _twoTo53) {
      return _manyFraction ? _manyFractionDigits(value) : intl.format(value);
    }
    return _compact ? _compactLarge(value) : _large(value);
  }

  /// NaN or an infinity, with the prefix and the suffix of the pattern.
  String _nonFinite(double value) {
    final symbols = intl.symbols;
    final text = value.isNaN ? symbols.NAN : symbols.INFINITY;
    final negative = value == double.negativeInfinity;
    // A compact intl format has its prefixes only in a call of format.
    if (_compact) return '${negative ? symbols.MINUS_SIGN : ''}$text';
    return negative
        ? '${intl.negativePrefix}$text${intl.negativeSuffix}'
        : '${intl.positivePrefix}$text${intl.positiveSuffix}';
  }

  /// [value] in scientific notation.
  String _exponential(double value) {
    var (digits, exponent) = value == 0 ? ('0', 0) : _decimal(value.abs());
    // The mantissa has one integer digit. Thus its significant digits are
    // the fraction digits and 1.
    final (minimum, maximum) =
        _significant ?? (_fraction.$1 + 1, _fraction.$2 + 1);
    (digits, exponent) = _round(digits, exponent, maximum);
    final symbols = intl.symbols;
    return _write(
      value.isNegative,
      digits.substring(0, 1),
      digits.substring(1).padRight(minimum - 1, '0'),
      '${symbols.EXP_SYMBOL}${exponent < 0 ? symbols.MINUS_SIGN : ''}'
      '${_local('${exponent.abs()}')}',
    );
  }

  /// Finite [value] below `2^53` in the standard notation, with more
  /// maximum fraction digits than the cap: the shortest decimal digits,
  /// rounded half away from zero to the maximum fraction digits.
  String _manyFractionDigits(double value) {
    var (digits, exponent) = ('0', 0);
    if (value != 0) {
      (digits, exponent) = _decimal(value.abs());
      // The multiplier of the percent style moves the digits.
      exponent += '${intl.multiplier}'.length - 1;
    }
    final (minimum, maximum) = _fraction;
    final count = exponent + 1 + maximum;
    if (count > 0) {
      (digits, exponent) = _round(digits, exponent, count);
    } else {
      // All the digits are after the last fraction digit. They round to 1
      // in the last place or to 0.
      (digits, exponent) = count == 0 && digits.codeUnitAt(0) >= 0x35
          ? ('1', -maximum)
          : ('0', 0);
    }
    final integer = exponent + 1;
    final String fraction;
    if (integer <= 0) {
      fraction = '${'0' * -integer}$digits';
    } else {
      fraction = digits.length > integer ? digits.substring(integer) : '';
      digits = digits.padRight(integer, '0').substring(0, integer);
    }
    return _write(
      value.isNegative,
      integer <= 0 ? '0' : digits,
      fraction.padRight(minimum, '0'),
    );
  }

  /// Finite [value] from `2^53` in the standard notation.
  String _large(double value) {
    final (digits, exponent) = _decimal(value.abs());
    // The multiplier of the percent style moves the digits.
    final (integer, fraction) = _fixed(
      digits,
      exponent + '${intl.multiplier}'.length - 1,
    );
    return _write(value < 0, integer, fraction);
  }

  /// The prefix, the suffix and the exponent of the unit of compact notation
  /// for a positive and for a negative number.
  late final (String, String, int) _compactPositive = _compactUnit(
    1000000000000000000,
  );
  late final (String, String, int) _compactNegative = _compactUnit(
    -1000000000000000000,
  );

  /// [probe] in compact notation, without its digits: the text before them,
  /// the text after them and the exponent of the unit.
  ///
  /// 1e18 is above the largest unit of each intl locale. intl writes it as
  /// `1` and zeros, maybe with zeros for the minimum integer digits before
  /// the `1` and fraction digits after the zeros. The count of the digits
  /// from the `1` to the end of the integer gives the exponent of the unit.
  (String, String, int) _compactUnit(double probe) {
    final text = intl.format(probe);
    final zero = intl.localeZero;
    bool isDigit(int index) {
      if (index >= text.length) return false;
      final unit = text.codeUnitAt(index);
      return unit >= zero && unit <= zero + 9;
    }

    var start = 0;
    while (!isDigit(start)) {
      start++;
    }
    var one = start;
    while (text.codeUnitAt(one) == zero) {
      one++;
    }
    var end = one;
    while (isDigit(end)) {
      end++;
    }
    final unit = 19 - (end - one);
    final separator = intl.symbols.DECIMAL_SEP;
    if (text.startsWith(separator, end) && isDigit(end + separator.length)) {
      end += separator.length;
      while (isDigit(end)) {
        end++;
      }
    }
    return (text.substring(0, start), text.substring(end), unit);
  }

  /// Finite [value] from `2^53` in compact notation.
  String _compactLarge(double value) {
    final (prefix, suffix, unit) = value < 0
        ? _compactNegative
        : _compactPositive;
    // Below 2^53 units, intl writes the digits of V8.
    if (value.abs() < _twoTo53 * pow(10, unit)) return intl.format(value);
    final (digits, exponent) = _decimal(value.abs());
    final (integer, fraction) = _fixed(digits, exponent - unit);
    return '$prefix${_local(integer.padLeft(intl.minimumIntegerDigits, '0'))}'
        '${fraction.isEmpty ? '' : intl.symbols.DECIMAL_SEP + _local(fraction)}'
        '$suffix';
  }

  /// The ASCII integer digits and fraction digits of the integer with the
  /// shortest decimal digits [shortest] and the exponent [first] >= 15 of
  /// the first digit. The significant digits round the digits half away from
  /// zero. The minimum significant digits, or else the minimum fraction
  /// digits, give the zeros of the fraction.
  ///
  /// From `2^53`, each double is an integer. From `2^53` units, the doubles
  /// are more than one unit apart. Thus the shortest digits have no fraction
  /// digits there, and the fraction digits do not round them.
  (String, String) _fixed(String shortest, int first) {
    if (_significant case (final minimum, final maximum)) {
      final (digits, exponent) = _round(shortest, first, maximum);
      return (
        digits.padRight(exponent + 1, '0'),
        '0' * max(0, minimum - exponent - 1),
      );
    }
    return (shortest.padRight(first + 1, '0'), '0' * _fraction.$1);
  }

  /// The ASCII digits [integer] and [fraction] with the symbols, the groups
  /// and the minimum integer digits of the locale, and the prefix and the
  /// suffix of the sign. [exponent] comes before the suffix.
  String _write(
    bool negative,
    String integer,
    String fraction, [
    String exponent = '',
  ]) {
    final digits = _local(integer.padLeft(intl.minimumIntegerDigits, '0'));
    final (last, other) = _groups;
    final groups = <String>[];
    var end = digits.length;
    for (var size = last; size > 0 && end > size; size = other) {
      groups.add(digits.substring(end - size, end));
      end -= size;
    }
    groups.add(digits.substring(0, end));
    final symbols = intl.symbols;
    return '${negative ? intl.negativePrefix : intl.positivePrefix}'
        '${groups.reversed.join(symbols.GROUP_SEP)}'
        '${fraction.isEmpty ? '' : symbols.DECIMAL_SEP + _local(fraction)}'
        '$exponent'
        '${negative ? intl.negativeSuffix : intl.positiveSuffix}';
  }

  /// The ASCII [digits] as digits of the locale.
  String _local(String digits) {
    final offset = intl.localeZero - 0x30;
    if (offset == 0) return digits;
    return String.fromCharCodes([
      for (final unit in digits.codeUnits) unit + offset,
    ]);
  }
}

/// The shortest decimal digits of finite [x] > 0, without zeros at the
/// start and the end, and the exponent of the first digit: `('15', -7)` for
/// `1.5e-7`. These are the digits of `Number::toString`, which V8 rounds.
/// `toStringAsExponential()` gives the same digits, but a format with it is
/// 6 to 22 % slower on the VM.
(String, int) _decimal(double x) {
  final text = jsNumberToString(x);
  final e = text.indexOf('e');
  final end = e < 0 ? text.length : e;
  final point = text.indexOf('.');
  final pointAt = point < 0 ? end : point;
  bool isZeroOrPoint(int index) {
    final unit = text.codeUnitAt(index);
    return unit == 0x30 || unit == 0x2E;
  }

  var start = 0;
  while (isZeroOrPoint(start)) {
    start++;
  }
  var stop = end;
  while (isZeroOrPoint(stop - 1)) {
    stop--;
  }
  return (
    text.substring(start, stop).replaceFirst('.', ''),
    (e < 0 ? 0 : int.parse(text.substring(e + 1))) +
        pointAt -
        start -
        (pointAt > start ? 1 : 0),
  );
}

/// [digits] and [exponent] rounded half away from zero to [count] >= 1
/// digits, the `halfExpand` rounding of ECMA-402. The result has no zeros
/// at the end.
(String, int) _round(String digits, int exponent, int count) {
  if (digits.length <= count) return (digits, exponent);
  // The digit after the kept digits is below 5: drop the rest.
  if (digits.codeUnitAt(count) < 0x35) {
    var stop = count;
    while (stop > 1 && digits.codeUnitAt(stop - 1) == 0x30) {
      stop--;
    }
    return (digits.substring(0, stop), exponent);
  }
  // Add 1 to the last digit: the nines at the end become zeros, which the
  // result does not keep.
  var last = count - 1;
  while (last >= 0 && digits.codeUnitAt(last) == 0x39) {
    last--;
  }
  if (last < 0) return ('1', exponent + 1);
  final up = String.fromCharCode(digits.codeUnitAt(last) + 1);
  return ('${digits.substring(0, last)}$up', exponent);
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
    // Scientific notation takes the symbols of the decimal pattern, as V8
    // does.
    _ => NumberFormat.decimalPattern(tag),
  };
  final cap = maxFractionDigits + 1 - '${format.multiplier}'.length;

  final minimumInteger = digits('minimumIntegerDigits', 1, 21);
  final minimumFraction = digits('minimumFractionDigits', 0, 100);
  final maximumFraction = digits('maximumFractionDigits', 0, 100);
  final minimumSignificant = digits('minimumSignificantDigits', 1, 21);
  final maximumSignificant = digits('maximumSignificantDigits', 1, 21);

  if (minimumInteger != null) format.minimumIntegerDigits = minimumInteger;
  // The digit options after the defaults of ECMA-402, for the guards.
  (int, int)? significant;
  var fraction = (format.minimumFractionDigits, format.maximumFractionDigits);
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
    significant = (minimum, maximum);
  } else if (minimumFraction != null || maximumFraction != null) {
    // ECMA-402 SetNumberFormatDigitOptions: the default of the style fills
    // in a missing bound.
    final defaultMaximum = format.maximumFractionDigits;
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
    fraction = (minimum, maximum);
  } else if (compact) {
    // Compact notation has three significant digits: cap them as above.
    format
      ..maximumFractionDigits = cap
      ..significantDigitsInUse = true;
  }

  final useGrouping = o.containsKey('useGrouping')
      ? o['useGrouping']
      : undefined;
  final grouping = useGrouping is Undefined || jsTruthy(useGrouping);
  if (!grouping) format.turnOffGrouping();
  final symbols = format.symbols;
  return JsNumberFormat._(
    format,
    compact,
    scientific,
    !grouping
        ? null
        : currency != null
        ? symbols.CURRENCY_PATTERN
        : style == 'percent'
        ? symbols.PERCENT_PATTERN
        : symbols.DECIMAL_PATTERN,
    fraction,
    significant,
    !compact && significant == null && fraction.$2 > cap,
  );
}
