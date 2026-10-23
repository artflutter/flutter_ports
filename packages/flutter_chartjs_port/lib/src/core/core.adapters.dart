// Ported from Chart.js v4.5.1+7169e651 src/core/core.adapters.ts (MIT, Chart.js Contributors).

/// Port of `src/core/core.adapters.ts`: the date adapter of the time scale.
///
/// @namespace Chart._adapters
/// @since 2.8.0
/// @private
///
/// The members of a date adapter take and give JavaScript values (Chart.js
/// ADR 0043): a date library replaces them with function values
/// ([DateAdapterBase.override]), and the time scale reads their results with
/// `+value` (`scale.time.js:76`, `:158`, `:342`). Thus each parameter and
/// each result is an `Object?`. The `///` line of each member gives the type
/// of `core.adapters.ts`.
///
/// `Object.assign(DateAdapterBase.prototype, members)` has no Dart form: a
/// Dart class has no prototype object. [DateAdapterBase.prototype] holds the
/// members that [DateAdapterBase.override] assigned. A method of
/// [DateAdapterBase] calls its member there, with the adapter as `this`.
/// Without a member, it runs its own body, as the method of the class body
/// runs upstream. Thus an override reaches every adapter, also an adapter
/// that exists before the override (row `adapt-date-adapter-prototype` of
/// differences.md).
///
/// [DateAdapterBase.prototype] starts with the default members of
/// `date_adapter.dart` (Chart.js ADR 0024, row `adapt-date-default-adapter`).
/// A method calls a member of the exact Dart function type of the method
/// directly. It calls any other value through `jsCall`, with the adapter as
/// `this`.
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'dart:core';
import 'dart:core' as core show override;

import 'package:flutter_chartjs_port/src/core/date_adapter.dart'
    show dateAdapterMembers;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';

/// core.adapters.ts:10 `TimeUnit`: `'millisecond' | 'second' | 'minute' |
/// 'hour' | 'day' | 'week' | 'month' | 'quarter' | 'year'`.
///
/// Dart has no union of string literals. A time unit is one of these
/// strings.
typedef TimeUnit = String;

/// core.adapters.ts:12 `DateAdapter`.
///
/// The members take and give JavaScript values (see the library
/// documentation).
abstract interface class DateAdapter {
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
  Object? formats();

  /// core.adapters.ts:28 `parse(value: unknown, format?: string): number |
  /// null`.
  ///
  /// Parses the given `value` and return the associated timestamp.
  /// @param value - the value to parse (usually comes from the data)
  /// @param [format] - the expected data format
  Object? parse(Object? value, [Object? format]);

  /// core.adapters.ts:34 `format(timestamp: number, format: string):
  /// string`.
  ///
  /// Returns the formatted date in the specified `format` for a given
  /// `timestamp`.
  /// @param timestamp - the timestamp to format
  /// @param format - the date/time token
  Object? format(Object? timestamp, Object? format);

  /// core.adapters.ts:41 `add(timestamp: number, amount: number, unit:
  /// TimeUnit): number`.
  ///
  /// Adds the specified `amount` of `unit` to the given `timestamp`.
  /// @param timestamp - the input timestamp
  /// @param amount - the amount to add
  /// @param unit - the unit as string
  Object? add(Object? timestamp, Object? amount, Object? unit);

  /// core.adapters.ts:48 `diff(a: number, b: number, unit: TimeUnit):
  /// number`.
  ///
  /// Returns the number of `unit` between the given timestamps.
  /// @param a - the input timestamp (reference)
  /// @param b - the timestamp to subtract
  /// @param unit - the unit as string
  Object? diff(Object? a, Object? b, Object? unit);

  /// core.adapters.ts:56 `startOf(timestamp: number, unit: TimeUnit |
  /// 'isoWeek', weekday?: number | boolean): number`.
  ///
  /// Returns start of `unit` for the given `timestamp`.
  /// @param timestamp - the input timestamp
  /// @param unit - the unit as string
  /// @param [weekday] - the ISO day of the week with 1 being Monday
  /// and 7 being Sunday (only needed if param *unit* is `isoWeek`).
  Object? startOf(Object? timestamp, Object? unit, [Object? weekday]);

  /// core.adapters.ts:62 `endOf(timestamp: number, unit: TimeUnit): number`.
  ///
  /// Returns end of `unit` for the given `timestamp`.
  /// @param timestamp - the input timestamp
  /// @param unit - the unit as string
  Object? endOf(Object? timestamp, Object? unit);
}

/// core.adapters.ts:65 `abstract`.
///
/// Upstream throws an `Error`. The port throws a [StateError] with the same
/// message (Chart.js ADR 0020, section 5).
Never _abstract() {
  throw StateError(
    'This method is not implemented: Check that a complete date adapter is '
    'provided.',
  );
}

/// The Dart function type of a member with two arguments that a method of
/// [DateAdapterBase] calls directly (Chart.js ADR 0024, decision 1). The
/// members `formats` and `init` have the types `Object? Function()` and
/// `Object? Function(Object?)`. A Dart closure cannot read `this`. Thus a
/// direct call gives the result of `jsCall`.
typedef _Member2 = Object? Function(Object?, Object?);

/// The Dart function type of a member with three arguments (see
/// [_Member2]).
typedef _Member3 = Object? Function(Object?, Object?, Object?);

/// core.adapters.ts:75 `class DateAdapterBase implements DateAdapter`.
///
/// Date adapter (current used by the time scale)
/// @namespace Chart._adapters._date
/// @memberof Chart._adapters
/// @private
class DateAdapterBase implements DateAdapter {
  /// core.adapters.ts:95 `constructor(options?: AnyObject)`.
  ///
  /// A falsy [options] gives a new Map. Another value stays as it is.
  DateAdapterBase([Object? options = undefined])
    : options = jsTruthy(options) ? options : <String, Object?>{};

  /// core.adapters.ts:87 `static override(members)`.
  ///
  /// Override default date adapter methods.
  /// Accepts type parameter to define options type.
  /// @example
  /// Chart._adapters._date.override<{myAdapterOption: string}>({
  ///   init() {
  ///     console.log(this.options.myAdapterOption);
  ///   }
  /// })
  ///
  /// `Object.assign(DateAdapterBase.prototype, members)` writes each key of
  /// [members] into [prototype], in the `jsObjectKeys` order. A member that
  /// reads `this` is a `JsFunction`.
  static void override(AnyObject members) {
    // DIVERGES(chartjs): adapt-date-adapter-prototype, a Map of the members.
    jsAssign(prototype, members);
  }

  /// The own properties that [override] assigned to
  /// `DateAdapterBase.prototype` (see the library documentation).
  ///
  /// It starts with the default members of the port (`dateAdapterMembers`,
  /// Chart.js ADR 0024). Upstream, an adapter package writes them with
  /// `override` at load.
  ///
  /// The methods of the class body are not entries. Each method of
  /// [DateAdapterBase] calls its entry when the entry exists, else it runs
  /// its body. An entry that is not a function value throws an
  /// [ArgumentError] at the call, where JavaScript throws a `TypeError`
  /// (`jsCall`).
  // DIVERGES(chartjs): adapt-date-adapter-prototype, a Map of the members.
  static final AnyObject prototype = <String, Object?>{
    // DIVERGES(chartjs): adapt-date-default-adapter, the default members.
    ...dateAdapterMembers,
  };

  /// core.adapters.ts:75 `class DateAdapterBase` as a value (Chart.js ADR
  /// 0020, section 3): the `_date` of [adapters].
  ///
  /// It has the static `override`. Its `construct` calls
  /// `DateAdapterBase(options)` with the first argument.
  static final JsClass jsClass = JsClass(
    'DateAdapterBase',
    statics: {'override': override},
    construct: (newTarget, args) =>
        DateAdapterBase(args.isEmpty ? undefined : args[0]),
  );

  /// core.adapters.ts:93 `readonly options: AnyObject`.
  @core.override
  final Object? options;

  /// The call of [member], a member of [prototype], with [args], with this
  /// adapter as `this`: `adapter[name](...args)`.
  Object? _callMember(Object? member, List<Object?> args) =>
      jsCall(member, args, thisArg: this);

  /// core.adapters.ts:100 `init() {}`.
  @core.override
  void init(Object? chartOptions) {
    // DIVERGES(chartjs): adapt-date-adapter-prototype, the assigned member.
    final member = prototype['init'];
    if (member is Object? Function(Object?)) {
      member(chartOptions);
      return;
    }
    if (prototype.containsKey('init')) {
      _callMember(member, [chartOptions]);
      return;
    }
    // eslint-disable-next-line @typescript-eslint/no-empty-function
  }

  /// core.adapters.ts:102 `formats()`.
  @core.override
  Object? formats() {
    // DIVERGES(chartjs): adapt-date-adapter-prototype, the assigned member.
    final member = prototype['formats'];
    if (member is Object? Function()) return member();
    if (prototype.containsKey('formats')) {
      return _callMember(member, const []);
    }
    return _abstract();
  }

  /// core.adapters.ts:106 `parse()`.
  @core.override
  Object? parse(Object? value, [Object? format = undefined]) {
    // DIVERGES(chartjs): adapt-date-adapter-prototype, the assigned member.
    final member = prototype['parse'];
    if (member is _Member2) return member(value, format);
    if (prototype.containsKey('parse')) {
      return _callMember(member, [value, format]);
    }
    return _abstract();
  }

  /// core.adapters.ts:110 `format()`.
  @core.override
  Object? format(Object? timestamp, Object? format) {
    // DIVERGES(chartjs): adapt-date-adapter-prototype, the assigned member.
    final member = prototype['format'];
    if (member is _Member2) return member(timestamp, format);
    if (prototype.containsKey('format')) {
      return _callMember(member, [timestamp, format]);
    }
    return _abstract();
  }

  /// core.adapters.ts:114 `add()`.
  @core.override
  Object? add(Object? timestamp, Object? amount, Object? unit) {
    // DIVERGES(chartjs): adapt-date-adapter-prototype, the assigned member.
    final member = prototype['add'];
    if (member is _Member3) return member(timestamp, amount, unit);
    if (prototype.containsKey('add')) {
      return _callMember(member, [timestamp, amount, unit]);
    }
    return _abstract();
  }

  /// core.adapters.ts:118 `diff()`.
  @core.override
  Object? diff(Object? a, Object? b, Object? unit) {
    // DIVERGES(chartjs): adapt-date-adapter-prototype, the assigned member.
    final member = prototype['diff'];
    if (member is _Member3) return member(a, b, unit);
    if (prototype.containsKey('diff')) {
      return _callMember(member, [a, b, unit]);
    }
    return _abstract();
  }

  /// core.adapters.ts:122 `startOf()`.
  @core.override
  Object? startOf(
    Object? timestamp,
    Object? unit, [
    Object? weekday = undefined,
  ]) {
    // DIVERGES(chartjs): adapt-date-adapter-prototype, the assigned member.
    final member = prototype['startOf'];
    if (member is _Member3) return member(timestamp, unit, weekday);
    if (prototype.containsKey('startOf')) {
      return _callMember(member, [timestamp, unit, weekday]);
    }
    return _abstract();
  }

  /// core.adapters.ts:126 `endOf()`.
  @core.override
  Object? endOf(Object? timestamp, Object? unit) {
    // DIVERGES(chartjs): adapt-date-adapter-prototype, the assigned member.
    final member = prototype['endOf'];
    if (member is _Member2) return member(timestamp, unit);
    if (prototype.containsKey('endOf')) {
      return _callMember(member, [timestamp, unit]);
    }
    return _abstract();
  }
}

/// core.adapters.ts:131 the default export, `Chart._adapters`.
///
/// `_date` is the class value [DateAdapterBase.jsClass]. The time scale
/// constructs it with `new adapters._date(options)` (`scale.time.js:269`).
final AnyObject adapters = <String, Object?>{'_date': DateAdapterBase.jsClass};
