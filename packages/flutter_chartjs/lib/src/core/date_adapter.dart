// Original code, not ported from Chart.js: the default date adapter.

/// The default date adapter of the port (Chart.js ADR 0024): the members
/// that `DateAdapterBase.prototype` starts with, and the default zone.
///
/// Chart.js has no date adapter. An adapter package writes its members into
/// `DateAdapterBase.prototype` with `override` when the page loads it
/// (`chartjs-adapter-moment.esm.js:23`, `core.adapters.ts:87-91`). The specs
/// load chartjs-adapter-moment 1.0.1 on moment 2.29.4
/// (`karma.conf.cjs:106-111`). [dateAdapterMembers] gives the results of
/// that adapter, with ICU patterns in place of moment tokens (row
/// `adapt-date-moment-format`).
/// `core.adapters.dart` copies the members into `DateAdapterBase.prototype`
/// (row `adapt-date-default-adapter`).
///
/// Each member is a top-level function that does not read `this`. Thus a
/// method of `DateAdapterBase` calls it directly, and the call gives the
/// result of `jsCall` (Chart.js ADR 0024, decision 1).
///
/// [setDefaultDateZone] is the analog of `moment.tz.setDefault`. The members
/// use the local zone by default, as moment without a default zone.
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'package:flutter_chartjs/src/core/date_calendar.dart';
import 'package:flutter_chartjs/src/core/date_format.dart';
import 'package:flutter_chartjs/src/core/date_parse.dart';
import 'package:flutter_chartjs/src/core/date_zone.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/basic.dart';

/// The default members of `DateAdapterBase.prototype` (Chart.js ADR 0024):
/// the rules of chartjs-adapter-moment 1.0.1 on moment 2.29.4, with ICU
/// patterns. An unmodifiable Map. `core.adapters.dart` copies it into
/// `prototype`.
///
/// The keys are `formats`, `parse`, `format`, `add`, `diff`, `startOf` and
/// `endOf`. The Map has no `init`, because chartjs-adapter-moment has none,
/// and no `_id`, because no upstream code reads it.
final AnyObject dateAdapterMembers = Map<String, Object?>.unmodifiable({
  'formats': _formats,
  'parse': _parse,
  'format': _format,
  'add': _add,
  'diff': _diff,
  'startOf': _startOf,
  'endOf': _endOf,
});

/// The zone of the default members: `null` for UTC, else the local zone.
DateZone? _zone = LocalZone.instance;

/// The name of [_zone].
String? _zoneName;

/// The name of the default zone: `null` (local time), `'UTC'` or
/// `'Etc/UTC'`.
String? get defaultDateZone => _zoneName;

/// `moment.tz.setDefault(name)` for the default members. `null` gives the
/// local zone. `'UTC'` and `'Etc/UTC'` give UTC. Another name throws an
/// [ArgumentError], because the package has no zone data. It clears the
/// local offset cache.
///
/// The spec harness calls `setDefaultDateZone('Etc/UTC')`, the port of
/// `test/index.js:23`. A test that changes the zone restores the old zone.
void setDefaultDateZone(String? name) {
  switch (name) {
    case null:
      _zone = LocalZone.instance;
    case 'UTC' || 'Etc/UTC':
      _zone = null;
    default:
      throw ArgumentError.value(
        name,
        'name',
        'The default date adapter knows only the local zone and UTC',
      );
  }
  _zoneName = name;
  LocalZone.instance.clear();
}

/// `formats()` (`chartjs-adapter-moment.esm.js:26-28`): the shared Map
/// [dateFormats].
///
/// The time scale calls `formats()` once in each update
/// (`scale.time.js:277`), before the parse of that update. Thus the member
/// clears the cache of [LocalZone] there, and the cache holds the offsets of
/// one update (Chart.js ADR 0024, decision 3). It also removes the locales
/// without date data from the locale cache: a locale that gets its data
/// later applies from the next update ([forgetMissingDateLocales]).
Object? _formats() {
  LocalZone.instance.clear();
  forgetMissingDateLocales();
  return dateFormats;
}

/// `parse(value, format)` (`chartjs-adapter-moment.esm.js:30-37`).
///
/// A `String` [value] with a `String` [format] goes to [parseWithFormat]. An
/// empty [format] uses the input rule, because moment tests `if (format)`
/// (moment.js:2973). Any other value goes to [dateInput]. An invalid date
/// gives `null`.
Object? _parse(Object? value, [Object? format = undefined]) {
  final time = value is String && format is String && format.isNotEmpty
      ? parseWithFormat(value, format, _zone, dateLocale())
      : dateInput(value, _zone);
  return time.isNaN ? null : time;
}

/// `format(time, format)` (`chartjs-adapter-moment.esm.js:39-41`):
/// [formatDate] of the time of [time].
Object? _format(Object? time, Object? format) =>
    formatDate(dateInput(time, _zone), format, _zone, dateLocale());

/// `add(time, amount, unit)` (`chartjs-adapter-moment.esm.js:43-45`):
/// moment `add` (moment.js:3580-3597, :3463-3533, :3157-3190).
///
/// When [unit] is not `null` and its `ToNumber` is not NaN, moment
/// exchanges [amount] and [unit] (`createAdder`). A numeric amount with a
/// truthy unit adds the amount of that unit. A numeric amount with a falsy
/// unit adds milliseconds. NaN gives 0, as the `|| 0` of the moment
/// `Duration`. An amount that is not numeric adds nothing.
Object? _add(Object? time, Object? amount, Object? unit) {
  var value = amount;
  var key = unit;
  if (key != null && _isNumeric(key)) {
    value = unit;
    key = amount;
  }
  final t = dateInput(time, _zone);
  final number = jsToNumber(value);
  if (number.isNaN && value is! num) {
    // moment reads a duration string (`'P1D'`, `'1.02:03:04'`) and a
    // duration object (`{days: 2}`) as an amount.
    // DIVERGES(chartjs): adapt-date-parse-fallback, no duration amount.
    return t;
  }
  final String? name;
  if (jsTruthy(key)) {
    // The key of the duration object: `ToPropertyKey(key)`.
    name = normalizeDateUnit(key is String ? key : jsToString(key));
  } else {
    name = 'millisecond';
  }
  return addUnit(t, number.isNaN ? 0 : number, name, _zone);
}

/// Whether `ToNumber(value)` is not NaN.
///
/// A unit name starts with a letter. A numeric string starts with white
/// space, a sign, a digit, a point or the `I` of `Infinity`. Thus a string
/// that starts with another ASCII letter is not numeric, and the test skips
/// the `RegExp` of [jsToNumber] for it.
bool _isNumeric(Object? value) {
  if (value is String && value.isNotEmpty) {
    final lower = value.codeUnitAt(0) | 0x20;
    if (lower >= 0x61 && lower <= 0x7A && lower != 0x69) return false;
  }
  return !jsToNumber(value).isNaN;
}

/// `diff(max, min, unit)` (`chartjs-adapter-moment.esm.js:47-49`):
/// [diffUnit] of the two times.
Object? _diff(Object? max, Object? min, Object? unit) => diffUnit(
  dateInput(max, _zone),
  dateInput(min, _zone),
  normalizeDateUnit(unit),
  _zone,
);

/// `startOf(time, unit, weekday)` (`chartjs-adapter-moment.esm.js:51-58`).
///
/// The unit `'isoWeek'` (an exact compare, as `unit === 'isoWeek'`) gives
/// [startOfIsoWeekday]. Any other unit gives [startOfUnit] with the week
/// start of the locale.
Object? _startOf(Object? time, Object? unit, [Object? weekday = undefined]) {
  final t = dateInput(time, _zone);
  if (unit == 'isoWeek') return startOfIsoWeekday(t, weekday, _zone);
  final name = normalizeDateUnit(unit);
  return startOfUnit(t, name, _zone, _weekStart(name));
}

/// `endOf(time, unit)` (`chartjs-adapter-moment.esm.js:60-62`): [endOfUnit]
/// with the week start of the locale.
Object? _endOf(Object? time, Object? unit) {
  final name = normalizeDateUnit(unit);
  return endOfUnit(dateInput(time, _zone), name, _zone, _weekStart(name));
}

/// The week start of the locale for the unit [name]. Only `week` reads it,
/// so the other units skip the locale.
int _weekStart(String? name) => name == 'week' ? weekStartOf(dateLocale()) : 0;
