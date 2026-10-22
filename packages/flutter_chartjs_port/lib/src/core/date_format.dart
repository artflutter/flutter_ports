// Original code, not ported from Chart.js: the formats of the date adapter.

/// The formats of the default date adapter (Chart.js ADR 0024, decision 6):
/// the ten ICU patterns of `formats()`, the compiled patterns and their
/// cache, the locale and the ISO default text of moment. The parse with a
/// pattern ([parseDateWall], decision 5) uses the same cache.
///
/// A format string is an ICU pattern of `DateFormat` (Chart.js ADR 0034,
/// section 5). The ten patterns of [dateFormats] give the en_US text of the
/// `FORMATS` of chartjs-adapter-moment 1.0.1. Four of them write the day
/// period in lower case, as moment `a` does.
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'package:flutter_chartjs_port/src/core/date_calendar.dart';
import 'package:flutter_chartjs_port/src/core/date_zone.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:intl/intl.dart';

/// The `FORMATS` of chartjs-adapter-moment 1.0.1 as ICU patterns
/// (`chartjs-adapter-moment.esm.js:10-21`). One shared Map.
///
/// The keys are in the order of `FORMATS`. `yyyy` pads the year to four
/// digits, as moment `YYYY` does. `'Q'Q` is a literal `Q` and the quarter
/// number, as moment `[Q]Q`. The default `formats` member returns this Map
/// at each call, as the moment member returns `FORMATS`.
// DIVERGES(chartjs): adapt-date-moment-format, ICU patterns.
final AnyObject dateFormats = <String, Object?>{
  'datetime': 'MMM d, yyyy, h:mm:ss a',
  'millisecond': 'h:mm:ss.SSS a',
  'second': 'h:mm:ss a',
  'minute': 'h:mm a',
  'hour': 'ha',
  'day': 'MMM d',
  'week': 'MMM d, yyyy',
  'month': 'MMM yyyy',
  'quarter': "'Q'Q - yyyy",
  'year': 'yyyy',
};

/// The patterns of [dateFormats] whose day period is lower case, as moment
/// `a` writes it. ICU `a` gives `AM` and `PM`, and intl has no lower-case
/// token.
///
/// Each pattern has one `a` field, at its end, and no quote.
const Set<String> _lowerCaseDayPeriod = {
  'MMM d, yyyy, h:mm:ss a',
  'h:mm:ss.SSS a',
  'h:mm:ss a',
  'h:mm a',
};

/// The locale that has date data without `initializeDateFormatting`.
const String _fallbackLocale = 'en_US';

/// The verified locale of each locale string of `Intl.getCurrentLocale()`.
final Map<String, String> _locales = {};

/// The locale strings of [_locales] that got `'en_US'` because intl has no
/// date data for them.
final Set<String> _missingLocales = {};

/// The locale of the default members: the verified locale of
/// `Intl.getCurrentLocale()`, or `'en_US'` when intl has no date data for
/// it.
///
/// This is the analog of the global moment locale. The members do not read
/// the chart option `locale`, as chartjs-adapter-moment reads no option.
/// A static Map keeps the result for each locale string, until
/// [forgetMissingDateLocales].
String dateLocale() {
  final current = Intl.getCurrentLocale();
  return _locales[current] ??= _verifiedLocale(current);
}

/// Removes each locale without date data from the cache of [dateLocale].
///
/// The default `formats` member calls it once in each chart update. Thus a
/// locale that gets its data later from `initializeDateFormatting` applies
/// from the next update. moment also applies a locale that the page defines
/// after a failed `moment.locale` call: `defineLocale` sets the global
/// locale (moment.js:2182-2185). A locale without data costs one failed
/// `DateFormat` in each update.
void forgetMissingDateLocales() {
  if (_missingLocales.isEmpty) return;
  _missingLocales
    ..forEach(_locales.remove)
    ..clear();
}

/// The locale of the date data of intl for [locale], else `'en_US'`.
///
/// The result is a key of the date data of intl, before and after
/// `initializeDateFormatting`. Thus a `DateFormat` of the cache keeps its
/// data when the app loads the data of all locales later.
///
/// - The function canonicalizes [locale] first (`'en-US'` gives `'en_US'`).
///   Without `initializeDateFormatting`, intl accepts each alias of en_US,
///   and a `DateFormat` keeps the alias. After `initializeDateFormatting`,
///   the date data has no key for the alias, and that `DateFormat` throws
///   at each format.
/// - Without `initializeDateFormatting`, only en_US has date data. For
///   another locale, intl throws a `LocaleDataException`, which
///   `package:intl/intl.dart` does not export. Thus the function catches
///   each [Exception] (Chart.js ADR 0024, fact 9).
/// - After `initializeDateFormatting`, intl has the data of each locale that
///   it knows. For a locale that it does not know, the `DateFormat`
///   constructor throws an [ArgumentError]. Thus the function gives an
///   `onFailure` to `Intl.verifiedLocale`, and the result is `'en_US'`, as
///   moment keeps `en` for a locale without data.
///
/// A locale that gets `'en_US'` for lack of data goes into
/// [_missingLocales].
String _verifiedLocale(String locale) {
  try {
    final verified = Intl.verifiedLocale(
      Intl.canonicalizedLocale(locale),
      DateFormat.localeExists,
      onFailure: (_) => null,
    );
    if (verified != null) return verified;
  } on Exception {
    // No date data for the locale.
  }
  _missingLocales.add(locale);
  return _fallbackLocale;
}

/// The first day of the week of each locale.
final Map<String, int> _weekStarts = {};

/// The moment `dow` of [locale]: `(FIRSTDAYOFWEEK + 1) % 7` (0 is Sunday).
///
/// intl numbers the days from Monday (0) to Sunday (6). en_US gives 0, as
/// the moment locale `en` (moment.js:1420-1426).
int weekStartOf(String locale) => _weekStarts[locale] ??=
    (_patternOf('a', locale).whole.dateSymbols.FIRSTDAYOFWEEK + 1) % 7;

/// The largest number of cached patterns of one locale.
const int _cacheLimit = 256;

/// The compiled patterns of each locale, by pattern.
final Map<String, Map<String, _Pattern>> _patterns = {};

/// The pattern of the last [_patternOf] call.
_Pattern? _last;

/// The compiled pattern of [pattern] and [locale], from the cache.
///
/// At [_cacheLimit] patterns of one locale, the cache of that locale is
/// cleared.
_Pattern _patternOf(String pattern, String locale) {
  final last = _last;
  if (last != null && last.pattern == pattern && last.locale == locale) {
    return last;
  }
  final byPattern = _patterns[locale] ??= <String, _Pattern>{};
  var compiled = byPattern[pattern];
  if (compiled == null) {
    if (byPattern.length >= _cacheLimit) byPattern.clear();
    compiled = byPattern[pattern] = _Pattern(pattern, locale);
  }
  return _last = compiled;
}

/// The wall time of [value] with the ICU pattern [pattern] in [locale] (the
/// wall fields as UTC ms), or `null` when intl does not read [value]. The
/// parse with a format of `date_parse.dart` uses it.
///
/// The parse is `tryParse(text, true)` of a cached `DateFormat`. intl builds
/// a UTC `DateTime` from the fields, in 1970-01-01 for the fields that the
/// pattern does not have. moment fills these fields from the current date
/// first, then it builds the date (`create/from-array.js:79-81`). [today]
/// gives the day number of the current date.
///
/// - A pattern with a year field: the time of the `DateTime`.
/// - A pattern with a month field and no year field: `text` starts with the
///   current year and a space, and the `DateFormat` reads it before
///   [pattern]. Thus intl builds the date in the current year: a February 29
///   of a leap year is valid, as in moment.
/// - A pattern with a day field and no month and year field: the time of the
///   `DateTime` plus the first day of the current month, minus 1970-01-01.
/// - A pattern with no date field: the time of the `DateTime` plus the
///   current date, minus 1970-01-01.
///
/// In the last two cases, the day of 1970 and the carry of the time (24:00
/// gives the next day) are a number of days after the first day of the
/// month, as in the JS `Date` of moment.
///
/// When intl does not read `text`, the parse tries again with each name of a
/// text field of [pattern] in the case of the locale. These are the day
/// periods and the names of the months and the weekdays. moment reads them
/// in any case (moment.js:1209-1220, :1847-1862, :1987-1993), and intl reads
/// them only in the case of the locale.
///
/// intl builds the `DateTime` with the `DateTime` constructor, which throws
/// an [ArgumentError] for a year outside its range.
int? parseDateWall(
  String value,
  String pattern,
  String locale,
  int Function() today,
) => _patternOf(pattern, locale).parse(value, today);

/// One day in ms.
const int _dayMs = 86400000;

/// The number of fields of the current date that moment fills for
/// [pattern] (`create/from-array.js:79-81`): 0 when the pattern has a year
/// field (`y`); 1 (the year) when it has a month field (`M`, `L`) or a day
/// of the year (`D`); 2 (the year and the month) when it has a day field
/// (`d`); else 3. A letter in single quotes is not a field.
///
/// moment sets the month and the day from a day of the year before it fills
/// the fields (moment.js:2610-2624).
int _fillOf(String pattern) {
  var year = false;
  var month = false;
  var day = false;
  var quoted = false;
  for (var i = 0; i < pattern.length; i++) {
    switch (pattern.codeUnitAt(i)) {
      case 0x27:
        quoted = !quoted;
      case 0x79 when !quoted:
        year = true;
      case 0x4D || 0x4C || 0x44 when !quoted:
        month = true;
      case 0x64 when !quoted:
        day = true;
    }
  }
  return year ? 0 : (month ? 1 : (day ? 2 : 3));
}

/// The names that intl reads for the text fields of [pattern] with the date
/// symbols of [format], longest first, each with its lower case: the day
/// periods (`a`), and the names of the months (`MMM`, `MMMM`, `LLL`,
/// `LLLL`) and of the weekdays (`E` and longer, `ccc`, `cccc`). The narrow
/// names (one letter) and a name that changes its length in lower case are
/// not in the list.
List<(String, String)> _namesOf(String pattern, DateFormat format) {
  final symbols = format.dateSymbols;
  final names = <String>{};
  var quoted = false;
  var i = 0;
  while (i < pattern.length) {
    final unit = pattern.codeUnitAt(i);
    var end = i + 1;
    if (unit == 0x27) {
      quoted = !quoted;
      i = end;
      continue;
    }
    while (end < pattern.length && pattern.codeUnitAt(end) == unit) {
      end++;
    }
    final width = end - i;
    i = end;
    if (quoted) continue;
    switch (unit) {
      case 0x61: // a
        names.addAll(symbols.AMPMS);
      case 0x4D when width == 3: // MMM
        names.addAll(symbols.SHORTMONTHS);
      case 0x4D when width == 4: // MMMM
        names.addAll(symbols.MONTHS);
      case 0x4C when width == 3: // LLL
        names.addAll(symbols.STANDALONESHORTMONTHS);
      case 0x4C when width == 4: // LLLL
        names.addAll(symbols.STANDALONEMONTHS);
      case 0x45 when width <= 3: // E to EEE
        names.addAll(symbols.SHORTWEEKDAYS);
      case 0x45: // EEEE
        names.addAll(symbols.WEEKDAYS);
      case 0x63 when width == 3: // ccc
        names.addAll(symbols.STANDALONESHORTWEEKDAYS);
      case 0x63 when width == 4: // cccc
        names.addAll(symbols.STANDALONEWEEKDAYS);
    }
  }
  return [
    for (final name in names)
      if (name.toLowerCase() case final lower when lower.length == name.length)
        (name, lower),
  ]..sort((a, b) => b.$1.length - a.$1.length);
}

/// An ICU pattern, compiled for the format and the parse.
///
/// A pattern of [_lowerCaseDayPeriod] is split at its `a` field. The text
/// before the field is a `DateFormat`, and the field writes the day period
/// of the locale in lower case. Any other pattern is one `DateFormat`.
final class _Pattern {
  _Pattern(this.pattern, this.locale);

  /// The ICU pattern.
  final String pattern;

  /// The locale of the patterns.
  final String locale;

  /// The `DateFormat` of the whole pattern.
  late final DateFormat whole = DateFormat(pattern, locale);

  /// The number of fields of the current date that a parse fills
  /// ([_fillOf]).
  late final int _fill = _fillOf(pattern);

  /// The `DateFormat` of the parse: [whole], or the current year and a
  /// space before the pattern when [_fill] is 1.
  late final DateFormat _parser = _fill == 1
      ? DateFormat('yyyy $pattern', locale)
      : whole;

  /// The day number of [_fillText] and [_fillDays]. The first value is no
  /// day number of a `DateTime`, whose day numbers are in ±100,000,000.
  int _today = -1000000000;

  /// The current year and a space, when [_fill] is 1. The digits are the
  /// digits of the locale, as [_parser] reads them.
  String _fillText = '';

  /// The day number of the date that 1970-01-01 of intl stands for, when
  /// [_fill] is 2 or 3.
  int _fillDays = 0;

  /// The names of the text fields of the pattern ([_namesOf]).
  late final List<(String, String)> _names = _namesOf(pattern, whole);

  /// [parseDateWall] of [value].
  int? parse(String value, int Function() today) {
    final fill = _fill;
    var text = value;
    if (fill != 0) {
      final days = today();
      if (days != _today) {
        final date = civilFromDays(days);
        if (fill == 1) {
          final year = DateFormat(
            'yyyy',
            locale,
          ).format(DateTime.utc(date.year));
          _fillText = '$year ';
        } else {
          _fillDays = fill == 2
              ? daysFromCivil(date.year, date.month, 1)
              : days;
        }
        _today = days;
      }
      if (fill == 1) text = _fillText + value;
    }
    final parser = _parser;
    var parsed = parser.tryParse(text, true);
    if (parsed == null) {
      final folded = _foldCase(text);
      if (folded == null) return null;
      parsed = parser.tryParse(folded, true);
      if (parsed == null) return null;
    }
    final wall = parsed.millisecondsSinceEpoch;
    return fill < 2 ? wall : _fillDays * _dayMs + wall;
  }

  /// [text] with each name of [_names] in the case of the locale, or `null`
  /// when no name of [text] has another case. The scan takes the longest
  /// name at each position.
  String? _foldCase(String text) {
    final names = _names;
    if (names.isEmpty) return null;
    final lower = text.toLowerCase();
    if (lower.length != text.length) return null;
    StringBuffer? folded;
    var copied = 0;
    var i = 0;
    while (i < text.length) {
      String? match;
      for (final (name, lowerName) in names) {
        if (lower.startsWith(lowerName, i)) {
          match = name;
          break;
        }
      }
      if (match == null) {
        i++;
        continue;
      }
      if (!text.startsWith(match, i)) {
        (folded ??= StringBuffer())
          ..write(text.substring(copied, i))
          ..write(match);
        copied = i + match.length;
      }
      i += match.length;
    }
    if (folded == null) return null;
    return (folded..write(text.substring(copied))).toString();
  }

  /// The parts of the pattern: a `DateFormat`, or `null` for a day period
  /// in lower case.
  ///
  /// A pattern of [_lowerCaseDayPeriod] gives two parts: the `DateFormat` of
  /// the text before its `a` field, and `null`.
  late final List<DateFormat?> _parts = _lowerCaseDayPeriod.contains(pattern)
      ? [DateFormat(pattern.substring(0, pattern.length - 1), locale), null]
      : [whole];

  /// The day periods of the locale in lower case: before noon, after noon.
  late final List<String> _dayPeriods = [
    for (final period in whole.dateSymbols.AMPMS) period.toLowerCase(),
  ];

  /// The text of the wall time [wall], a UTC `DateTime` with the wall
  /// fields.
  String format(DateTime wall) {
    final parts = _parts;
    if (parts.length == 1) return _text(parts[0], wall);
    return _text(parts[0], wall) + _text(parts[1], wall);
  }

  /// The text of one part.
  String _text(DateFormat? part, DateTime wall) =>
      part?.format(wall) ?? _dayPeriods[wall.hour < 12 ? 0 : 1];
}

/// The largest time value of a JS `Date` in ms. A `DateTime` has the same
/// range.
const int _maxTime = 8640000000000000;

/// `moment(t).format(format)` of the default adapter
/// (`chartjs-adapter-moment.esm.js:39-41`, moment.js:3923-3996).
///
/// - A NaN [t] gives `'Invalid date'` (moment.js:589), for any [format].
/// - A falsy [format] (`undefined`, `null`, `''`, `false`, `0`, NaN) gives
///   the ISO default text of moment: `YYYY-MM-DDTHH:mm:ss` and a literal `Z`
///   in UTC, and the same fields of the wall time and the offset `±HH:mm`
///   in a [zone]. The offset has whole minutes ([wholeMinuteOffset]).
/// - A `String` [format] is an ICU pattern. The text is the text of the
///   compiled pattern for the wall time of [t].
/// - Any other [format] throws a [TypeError], as moment does when its cache
///   has no format function for the text of [format] (row
///   `adapt-date-moment-format`).
String formatDate(double t, Object? format, DateZone? zone, String locale) {
  if (t.isNaN) return 'Invalid date';
  final instant = t.toInt();
  if (!jsTruthy(format)) return _isoText(instant, zone);
  // moment calls `format.match`, which a number, an object or an array do
  // not have. moment keys its format functions by the text of the format:
  // after a call with 'YYYY', the format ['YYYY'] gives the year.
  // DIVERGES(chartjs): adapt-date-moment-format, no format cache.
  if (format is! String) throw TypeError();
  var wall = zone == null ? instant : instant + zone.offsetAt(instant);
  if (wall > _maxTime || wall < -_maxTime) {
    // DIVERGES(chartjs): platform-date-local-offset, the DateTime range.
    wall = instant;
  }
  return _patternOf(
    format,
    locale,
  ).format(DateTime.fromMillisecondsSinceEpoch(wall, isUtc: true));
}

/// The text of [value] with at least [width] digits: moment `zeroFill`
/// without a forced sign. A negative value gets a `-`.
String _zeroFill(int value, int width) {
  final digits = value.abs().toString().padLeft(width, '0');
  return value < 0 ? '-$digits' : digits;
}

/// The moment default text of the instant [instant]: `YYYY-MM-DDTHH:mm:ss`
/// and `Z` in UTC, or the offset `±HH:mm` in a [zone] (moment.js:3923-3924,
/// :3988-3996).
String _isoText(int instant, DateZone? zone) {
  final wall = zone == null ? instant : instant + zone.offsetAt(instant);
  final timeOfDay = wall % 86400000;
  final date = civilFromDays((wall - timeOfDay) ~/ 86400000);
  final text =
      '${_zeroFill(date.year, 4)}-${_zeroFill(date.month, 2)}-'
      '${_zeroFill(date.day, 2)}T${_zeroFill(timeOfDay ~/ 3600000, 2)}:'
      '${_zeroFill(timeOfDay ~/ 60000 % 60, 2)}:'
      '${_zeroFill(timeOfDay ~/ 1000 % 60, 2)}';
  if (zone == null) return '${text}Z';
  final minutes = wholeMinuteOffset(zone, instant) ~/ 60000;
  final sign = minutes < 0 ? '-' : '+';
  return '$text$sign${_zeroFill(minutes.abs() ~/ 60, 2)}:'
      '${_zeroFill(minutes.abs() % 60, 2)}';
}
