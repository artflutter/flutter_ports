// Ported from Chart.js v4.6.1 src/core/core.adapters.ts (MIT, Chart.js Contributors).

/// Port of `src/core/core.adapters.ts`: the date adapter of the time scale.
///
/// @namespace Chart._adapters
/// @since 2.8.0
/// @private
///
/// The members of a date adapter take and give Dart values (Chart.js ADR
/// 0203): a timestamp is a `double`, a format is a `String` and a unit is a
/// [TimeUnit]. Only [DateAdapter.parse] takes a raw data value.
///
/// `Object.assign(DateAdapterBase.prototype, members)` has no Dart form: a
/// Dart class has no prototype object. An app gives its adapter as a
/// subclass of [DateAdapterBase], for example of [DefaultDateAdapter], and
/// writes its constructor into [ChartAdapters.date] of [adapters] (row
/// `adapt-date-adapter-class` of differences.md).
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// core.adapters.ts:10 `TimeUnit`: `'millisecond' | 'second' | 'minute' |
/// 'hour' | 'day' | 'week' | 'month' | 'quarter' | 'year'`.
///
/// The step of a time axis and the unit of the calendar work of a date
/// adapter (row `adapt-time-unit-enum`). The options `time.unit`,
/// `time.minUnit` and `time.round` hold a value of this enum, also in a raw
/// config. The time scale closes the set: its table of intervals has these
/// nine units. A date adapter of a plugin gets the enum value in
/// [DateAdapter.add], [DateAdapter.diff], [DateAdapter.startOf] and
/// [DateAdapter.endOf]. The
/// name of each value is the keyword of Chart.js. Dart has no type for these
/// units: a `Duration` has no month, quarter or year.
// DIVERGES(chartjs): adapt-time-unit-enum, an enum of the units.
enum TimeUnit() {
  /// `'millisecond'`.
  millisecond,

  /// `'second'`.
  second,

  /// `'minute'`.
  minute,

  /// `'hour'`.
  hour,

  /// `'day'`.
  day,

  /// `'week'`: the week of the locale of the adapter.
  week,

  /// `'month'`.
  month,

  /// `'quarter'`.
  quarter,

  /// `'year'`.
  year;

  /// The value of [value], the value of an option `time.unit`,
  /// `time.minUnit` or `time.round`, or Dart `null` for a value that is not
  /// a [TimeUnit] (`false` for the automatic unit). A keyword of Chart.js is
  /// not a value: a debug build stops on it.
  static TimeUnit? of(Object? value) {
    assert(
      value is! String,
      'A time unit option takes a TimeUnit, not the name "$value".',
    );
    return value is TimeUnit ? value : null;
  }
}

/// core.adapters.ts:12 `DateAdapter`.
///
/// The members take and give Dart values (see the library documentation).
// DIVERGES(chartjs): adapt-date-adapter-class, the typed members.
abstract interface class DateAdapter() {
  /// core.adapters.ts:13 `readonly options: T`.
  ///
  /// The constructor of [DateAdapterBase] keeps any truthy value. Thus it is
  /// an `Object?`, not an [AnyObject].
  Object? get options;

  /// core.adapters.ts:17 `init(chartOptions: ChartOptions): void`.
  ///
  /// Will called with chart options after adapter creation.
  void init(Object? chartOptions);

  /// core.adapters.ts:22 `formats(): Record<TimeUnit | 'datetime',
  /// string>`.
  ///
  /// Returns a map of time formats for the supported formatting units
  /// defined in Unit as well as 'datetime' representing a detailed date/time
  /// string.
  Map<String, String> formats();

  /// core.adapters.ts:28 `parse(value: unknown, format?: string): number |
  /// null`.
  ///
  /// Parses the given `value` and return the associated timestamp.
  /// @param value - the value to parse (usually comes from the data)
  /// @param [format] - the expected data format
  double? parse(Object? value, [String? format]);

  /// core.adapters.ts:34 `format(timestamp: number, format: string):
  /// string`.
  ///
  /// Returns the formatted date in the specified `format` for a given
  /// `timestamp`.
  /// @param timestamp - the timestamp to format
  /// @param format - the date/time token
  ///
  /// The time scale gives Dart `null` for an absent display format, and NaN
  /// for the JS `null` value of a tick.
  String format(double timestamp, String? format);

  /// core.adapters.ts:41 `add(timestamp: number, amount: number, unit:
  /// TimeUnit): number`.
  ///
  /// Adds the specified `amount` of `unit` to the given `timestamp`.
  /// @param timestamp - the input timestamp
  /// @param amount - the amount to add
  /// @param unit - the unit
  double add(double timestamp, double amount, TimeUnit unit);

  /// core.adapters.ts:48 `diff(a: number, b: number, unit: TimeUnit):
  /// number`.
  ///
  /// Returns the number of `unit` between the given timestamps.
  /// @param a - the input timestamp (reference)
  /// @param b - the timestamp to subtract
  /// @param unit - the unit
  double diff(double a, double b, TimeUnit unit);

  /// core.adapters.ts:56 `startOf(timestamp: number, unit: TimeUnit |
  /// 'isoWeek', weekday?: number | boolean): number`.
  ///
  /// Returns start of `unit` for the given `timestamp`.
  /// @param timestamp - the input timestamp
  /// @param unit - the unit
  ///
  /// The unit `'isoWeek'` of upstream, which is not a [TimeUnit], is the
  /// member [startOfIsoWeek].
  // DIVERGES(chartjs): adapt-time-unit-enum, the ISO week is its own member.
  double startOf(double timestamp, TimeUnit unit);

  /// core.adapters.ts:56 `startOf(timestamp, 'isoWeek', weekday)`: the
  /// start of the day [weekday] of the ISO week of [timestamp].
  ///
  /// @param timestamp - the input timestamp
  /// @param weekday - the ISO day of the week with 1 being Monday and 7
  /// being Sunday. The time scale gives 1 for the option `time.isoWeekday`
  /// `true`, and the whole part of a number.
  // DIVERGES(chartjs): adapt-time-unit-enum, the ISO week is its own member.
  double startOfIsoWeek(double timestamp, int weekday);

  /// core.adapters.ts:62 `endOf(timestamp: number, unit: TimeUnit): number`.
  ///
  /// Returns end of `unit` for the given `timestamp`.
  /// @param timestamp - the input timestamp
  /// @param unit - the unit
  double endOf(double timestamp, TimeUnit unit);
}

/// core.adapters.ts:75 `class DateAdapterBase implements DateAdapter`.
///
/// Date adapter (current used by the time scale)
/// @namespace Chart._adapters._date
/// @memberof Chart._adapters
/// @private
///
/// Upstream, each method of the class body throws an `Error` until an
/// adapter package assigns its members. Here each method is abstract: a
/// subclass that leaves one out does not compile. [DefaultDateAdapter] is
/// the adapter of the port.
// DIVERGES(chartjs): adapt-date-adapter-class, a subclass for each adapter.
abstract class DateAdapterBase([Object? options = undefined])
    implements DateAdapter {
  /// core.adapters.ts:95 `constructor(options?: AnyObject)`.
  ///
  /// A falsy [options] gives a new Map. Another value stays as it is.
  this;

  /// core.adapters.ts:93 `readonly options: AnyObject`.
  @override
  final Object? options = jsTruthy(options) ? options : <String, Object?>{};

  /// core.adapters.ts:100 `init() {}`.
  @override
  void init(Object? chartOptions) {
    // eslint-disable-next-line @typescript-eslint/no-empty-function
  }
}

/// The constructor of a date adapter: `new adapters._date(options)`
/// (`scale.time.js:269`).
typedef DateAdapterFactory = DateAdapter Function(Object? options);

/// The type of [adapters], the default export of core.adapters.ts:131.
///
/// Upstream `_date` is the class `DateAdapterBase`, whose prototype an
/// adapter package changes. Here [date] is the constructor of the adapter
/// class. An app writes its own constructor into it.
///
/// ```dart
/// final class MyDateAdapter([super.options]) extends DefaultDateAdapter {
///   @override
///   double? parse(Object? value, [String? format]) => ...;
/// }
///
/// adapters.date = MyDateAdapter.new;
/// ```
// DIVERGES(chartjs): adapt-date-adapter-class, the adapter constructor.
final class ChartAdapters() {
  /// The adapters with [DefaultDateAdapter] as [date].
  this;

  /// core.adapters.ts:132 `_date`: the constructor of the adapter of each
  /// time scale.
  DateAdapterFactory date = DefaultDateAdapter.new;
}

/// core.adapters.ts:131 the default export, `Chart._adapters`.
final ChartAdapters adapters = ChartAdapters();
