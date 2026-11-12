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

import 'package:flutter_chartjs_port/src/core/core.adapters.dart' show TimeUnit;
import 'package:flutter_chartjs_port/src/core/date_calendar.dart';
import 'package:flutter_chartjs_port/src/core/date_format.dart';
import 'package:flutter_chartjs_port/src/core/date_parse.dart';
import 'package:flutter_chartjs_port/src/core/date_zone.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';

/// The default members of `DateAdapterBase.prototype` (Chart.js ADR 0024):
/// the rules of chartjs-adapter-moment 1.0.1 on moment 2.29.4, with ICU
/// patterns. An unmodifiable Map. `core.adapters.dart` copies it into
/// `prototype`.
///
/// The keys are `formats`, `parse`, `format`, `add`, `diff`, `startOf`,
/// `startOfIsoWeek` and `endOf`. The Map has no `init`, because
/// chartjs-adapter-moment has none, and no `_id`, because no upstream code
/// reads it.
final AnyObject dateAdapterMembers = Map<String, Object?>.unmodifiable({
  'formats': _formats,
  'parse': _parse,
  'format': _format,
  'add': _add,
  'diff': _diff,
  'startOf': _startOf,
  'startOfIsoWeek': _startOfIsoWeek,
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
/// [unit] is a [TimeUnit] (row `adapt-time-unit-enum`): moment does not
/// read a unit name, so its aliases (`'ms'`, `'days'`) and its exchange of
/// a numeric unit with the amount (`createAdder`) do not apply. Another
/// value of [unit] adds nothing. NaN gives 0, as the `|| 0` of the moment
/// `Duration`. An amount that is not numeric adds nothing.
Object? _add(Object? time, Object? amount, Object? unit) {
  final t = dateInput(time, _zone);
  final number = jsToNumber(amount);
  if (number.isNaN && amount is! num) {
    // moment reads a duration string (`'P1D'`, `'1.02:03:04'`) and a
    // duration object (`{days: 2}`) as an amount.
    // DIVERGES(chartjs): adapt-date-parse-fallback, no duration amount.
    return t;
  }
  final name = TimeUnit.of(unit);
  if (name == null) return t;
  return addUnit(t, number.isNaN ? 0 : number, name, _zone);
}

/// `diff(max, min, unit)` (`chartjs-adapter-moment.esm.js:47-49`):
/// [diffUnit] of the two times. A [unit] that is not a [TimeUnit] gives
/// the difference in ms, as moment gives it for an unknown unit.
Object? _diff(Object? max, Object? min, Object? unit) => diffUnit(
  dateInput(max, _zone),
  dateInput(min, _zone),
  TimeUnit.of(unit),
  _zone,
);

/// `startOf(time, unit)` (`chartjs-adapter-moment.esm.js:51-58`):
/// [startOfUnit] with the week start of the locale. A [unit] that is not a
/// [TimeUnit] gives the time, as moment gives it for an unknown unit.
Object? _startOf(Object? time, Object? unit) {
  final name = TimeUnit.of(unit);
  return startOfUnit(dateInput(time, _zone), name, _zone, _weekStart(name));
}

/// `startOf(time, 'isoWeek', weekday)` (`chartjs-adapter-moment.esm.js:53-56`):
/// [startOfIsoWeekday].
Object? _startOfIsoWeek(Object? time, Object? weekday) =>
    startOfIsoWeekday(dateInput(time, _zone), weekday, _zone);

/// `endOf(time, unit)` (`chartjs-adapter-moment.esm.js:60-62`): [endOfUnit]
/// with the week start of the locale.
Object? _endOf(Object? time, Object? unit) {
  final name = TimeUnit.of(unit);
  return endOfUnit(dateInput(time, _zone), name, _zone, _weekStart(name));
}

/// The week start of the locale for the unit [name]. Only `week` reads it,
/// so the other units skip the locale.
int _weekStart(TimeUnit? name) =>
    name == TimeUnit.week ? weekStartOf(dateLocale()) : 0;
