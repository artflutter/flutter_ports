// Original code, not ported from Chart.js: the default date adapter.

/// The default date adapter of the port (Chart.js ADR 0024),
/// [DefaultDateAdapter], and the default zone.
///
/// Chart.js has no date adapter. An adapter package writes its members into
/// `DateAdapterBase.prototype` with `override` when the page loads it
/// (`chartjs-adapter-moment.esm.js:23`, `core.adapters.ts:87-91`). The specs
/// load chartjs-adapter-moment 1.0.1 on moment 2.29.4
/// (`karma.conf.cjs:106-111`). [DefaultDateAdapter] gives the results of
/// that adapter, with ICU patterns in place of moment tokens (row
/// `adapt-date-moment-format`). [ChartAdapters.date] starts with its
/// constructor (row `adapt-date-default-adapter`).
///
/// [setDefaultDateZone] is the analog of `moment.tz.setDefault`. The adapter
/// uses the local zone by default, as moment without a default zone.
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// The zone of [DefaultDateAdapter]: `null` for UTC, else the local zone.
DateZone? _zone = LocalZone.instance;

/// The name of [_zone].
String? _zoneName;

/// The name of the default zone: `null` (local time), `'UTC'` or
/// `'Etc/UTC'`.
String? get defaultDateZone => _zoneName;

/// `moment.tz.setDefault(name)` for [DefaultDateAdapter]. `null` gives the
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

/// The default date adapter of the port (Chart.js ADR 0024): the rules of
/// chartjs-adapter-moment 1.0.1 on moment 2.29.4, with ICU patterns.
///
/// It reads no [options]: chartjs-adapter-moment reads none. It has no
/// `init`, because chartjs-adapter-moment has none.
// DIVERGES(chartjs): adapt-date-default-adapter, the default adapter.
class DefaultDateAdapter([super.options]) extends DateAdapterBase {
  /// `new adapters._date(options)` (`scale.time.js:269`).
  this;

  /// `formats()` (`chartjs-adapter-moment.esm.js:26-28`): the shared Map
  /// [dateFormats].
  ///
  /// The time scale calls `formats()` once in each update
  /// (`scale.time.js:277`), before the parse of that update. Thus the member
  /// clears the cache of [LocalZone] there, and the cache holds the offsets
  /// of one update (Chart.js ADR 0024, decision 3). It also removes the
  /// locales without date data from the locale cache: a locale that gets its
  /// data later applies from the next update ([forgetMissingDateLocales]).
  @override
  Map<String, String> formats() {
    LocalZone.instance.clear();
    forgetMissingDateLocales();
    return dateFormats;
  }

  /// `parse(value, format)` (`chartjs-adapter-moment.esm.js:30-37`).
  ///
  /// A `String` [value] with a [format] goes to [parseWithFormat]. An empty
  /// [format] uses the input rule, because moment tests `if (format)`
  /// (moment.js:2973). Any other value goes to [dateInput]. An invalid date
  /// gives `null`.
  @override
  double? parse(Object? value, [String? format]) {
    final time = value is String && format != null && format.isNotEmpty
        ? parseWithFormat(value, format, _zone, dateLocale())
        : dateInput(value, _zone);
    return time.isNaN ? null : time;
  }

  /// `format(time, format)` (`chartjs-adapter-moment.esm.js:39-41`):
  /// [formatDate] of [timestamp].
  @override
  String format(double timestamp, String? format) =>
      formatDate(timeClip(timestamp), format, _zone, dateLocale());

  /// `add(time, amount, unit)` (`chartjs-adapter-moment.esm.js:43-45`):
  /// moment `add` (moment.js:3580-3597, :3463-3533, :3157-3190). NaN adds
  /// 0, as the `|| 0` of the moment `Duration`.
  @override
  double add(double timestamp, double amount, TimeUnit unit) =>
      addUnit(timeClip(timestamp), amount.isNaN ? 0 : amount, unit, _zone);

  /// `diff(max, min, unit)` (`chartjs-adapter-moment.esm.js:47-49`):
  /// [diffUnit] of the two times.
  @override
  double diff(double a, double b, TimeUnit unit) =>
      diffUnit(timeClip(a), timeClip(b), unit, _zone);

  /// `startOf(time, unit)` (`chartjs-adapter-moment.esm.js:51-58`):
  /// [startOfUnit] with the week start of the locale.
  @override
  double startOf(double timestamp, TimeUnit unit) =>
      startOfUnit(timeClip(timestamp), unit, _zone, _weekStart(unit));

  /// `startOf(time, 'isoWeek', weekday)`
  /// (`chartjs-adapter-moment.esm.js:53-56`): [startOfIsoWeekday].
  @override
  double startOfIsoWeek(double timestamp, int weekday) =>
      startOfIsoWeekday(timeClip(timestamp), weekday, _zone);

  /// `endOf(time, unit)` (`chartjs-adapter-moment.esm.js:60-62`):
  /// [endOfUnit] with the week start of the locale.
  @override
  double endOf(double timestamp, TimeUnit unit) =>
      endOfUnit(timeClip(timestamp), unit, _zone, _weekStart(unit));
}

/// The week start of the locale for the unit [name]. Only `week` reads it,
/// so the other units skip the locale.
int _weekStart(TimeUnit? name) =>
    name == TimeUnit.week ? weekStartOf(dateLocale()) : 0;
