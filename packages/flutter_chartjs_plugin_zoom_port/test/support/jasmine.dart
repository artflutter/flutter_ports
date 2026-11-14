// Original code, not ported from chartjs-plugin-zoom: the Jasmine helpers.

/// The Jasmine spies and matchers that the zoom specs use, in Dart (Zoom ADR
/// 0002, item 4).
///
/// The upstream specs run on jasmine-core 5.4.0 (`package.json`: jasmine
/// `^5.4.0`). The helpers keep its results: [jasmineEquals] is the `eq` of
/// `toEqual`, [toBe] is `===`, and [toBeCloseTo] has the formula of its
/// `toBeCloseTo` matcher. The host port has its own helpers, with internal
/// forms; the zoom port does not share them.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show ZoomPluginOptions;
import 'package:flutter_chartjs_port/chartjs.dart'
    show JsObjectFace, Plugin, undefined;
import 'package:flutter_chartjs_port/js_semantics.dart'
    show jsGet, jsObjectKeys;
import 'package:flutter_test/flutter_test.dart';

/// The default of an argument that the caller did not pass.
const Object _absent = _Absent();

final class const _Absent();

/// `jasmine.createSpy(name)`: a function value that records its calls.
///
/// [call] is the function: pass its tear-off `spy.call` where upstream
/// passes the spy. It takes zero to three positional arguments and records
/// the arguments that the caller passed. Its type is a subtype of each
/// callback type of the zoom options that returns `void`, so the plugin
/// calls it with a typed call; a callback type with another result type
/// takes the JavaScript call of the plugin.
final class Spy(
  /// The name of the spy, for the messages.
  final String name,
) {
  /// A spy with the [name] of `createSpy(name)`.
  this;

  /// The arguments of each call, in the order of the calls.
  final List<List<Object?>> calls = [];

  /// The `and` of a Jasmine spy: the strategy of the calls.
  late final SpyStrategy and = SpyStrategy._(this);

  Object? _returnValue = undefined;

  /// The number of calls.
  int get count => calls.length;

  /// The spy function: records the passed arguments and returns the value
  /// of `and.returnValue`, or `undefined`.
  Object? call([
    Object? a = _absent,
    Object? b = _absent,
    Object? c = _absent,
  ]) {
    calls.add([
      for (final argument in [a, b, c])
        if (!identical(argument, _absent)) argument,
    ]);
    return _returnValue;
  }

  @override
  String toString() => 'spy $name';
}

/// The `and` of a Jasmine spy.
final class SpyStrategy._(final Spy _spy) {
  /// `spy.and.returnValue(value)`: each call returns [value]. Returns the
  /// spy, as upstream chains `createSpy(name).and.returnValue(value)`.
  Spy returnValue(Object? value) {
    _spy._returnValue = value;
    return _spy;
  }
}

/// `jasmine.createSpy(name)`.
Spy createSpy([String name = 'unknown']) => Spy(name);

/// `spyOn(plugin, 'beforeUpdate')`: replaces the hook `beforeUpdate` of
/// [plugin] with a spy, with no call-through, and puts back the hook at the
/// end of the test.
///
/// The spy is written into the hook field of the native plugin (Chart.js ADR
/// 0126), as a JavaScript spy replaces the property. The hook continues the
/// update, as the `undefined` result of a JavaScript spy does.
Spy spyOnBeforeUpdate(Plugin<ZoomPluginOptions> plugin) {
  final previous = plugin.beforeUpdate;
  final spy = Spy('beforeUpdate');
  plugin.beforeUpdate = (chart, args, options) {
    spy(chart, args, options);
    return true;
  };
  addTearDown(() => plugin.beforeUpdate = previous);
  return spy;
}

/// `toHaveBeenCalled()`: the [Spy] has at least one call.
Matcher toHaveBeenCalled() => const _SpyMatcher(_SpyCheck.called);

/// `toHaveBeenCalledTimes(times)`: the [Spy] has [times] calls.
Matcher toHaveBeenCalledTimes(int times) =>
    _SpyMatcher(_SpyCheck.times, times: times);

/// `toHaveBeenCalledWith(...args)`: one call of the [Spy] has the arguments
/// [args], compared with [jasmineEquals].
Matcher toHaveBeenCalledWith(List<Object?> args) =>
    _SpyMatcher(_SpyCheck.calledWith, args: args);

enum _SpyCheck() {
  called,
  times,
  calledWith,
}

final class const _SpyMatcher(
  final _SpyCheck check, {
  final int times = 0,
  final List<Object?> args = const [],
}) extends Matcher {
  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! Spy) return false;
    return switch (check) {
      _SpyCheck.called => item.count > 0,
      _SpyCheck.times => item.count == times,
      _SpyCheck.calledWith => item.calls.any((call) => _eq(call, args)),
    };
  }

  @override
  Description describe(Description description) => switch (check) {
    _SpyCheck.called => description.add('a spy that has been called'),
    _SpyCheck.times => description.add('a spy called $times times'),
    _SpyCheck.calledWith =>
      description.add('a spy called with ').addDescriptionOf(args),
  };

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) => item is Spy
      ? mismatchDescription.add('has the calls ').addDescriptionOf(item.calls)
      : mismatchDescription.add('is not a spy');
}

/// `toEqual(expected)`: the deep equality `eq` of jasmine-core 5.4.0.
///
/// - Numbers compare by value; NaN equals NaN, and `0` does not equal `-0`.
/// - Maps and typed objects with a face (`JsObjectFace`) are objects: they
///   compare by their own keys, in any order, and by the value of each key.
///   A Map and a face can be equal.
/// - Lists compare by length and by each item.
/// - A record of the shapes of the zoom port (`(min:, max:)`, `(x:, y:)` and
///   the callback contexts) compares field by field.
/// - Another value compares with `==`.
Matcher jasmineEquals(Object? expected) => _JasmineEquals(expected);

final class const _JasmineEquals(final Object? expected) extends Matcher {
  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) =>
      _eq(item, expected);

  @override
  Description describe(Description description) =>
      description.add('jasmine-equal to ').addDescriptionOf(expected);
}

bool _isObject(Object? value) => value is Map || value is JsObjectFace;

bool _eq(Object? a, Object? b) {
  if (a is num && b is num) {
    final x = a.toDouble();
    final y = b.toDouble();
    if (x.isNaN || y.isNaN) return x.isNaN && y.isNaN;
    return x == y && (x != 0 || x.isNegative == y.isNegative);
  }
  if (identical(a, b)) return true;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_eq(a[i], b[i])) return false;
    }
    return true;
  }
  if (_isObject(a) && _isObject(b)) {
    final aKeys = jsObjectKeys(a);
    final bKeys = jsObjectKeys(b).toSet();
    if (aKeys.length != bKeys.length) return false;
    for (final key in aKeys) {
      if (!bKeys.contains(key) || !_eq(jsGet(a, key), jsGet(b, key))) {
        return false;
      }
    }
    return true;
  }
  return switch ((a, b)) {
    ((min: final aMin, max: final aMax), (min: final bMin, max: final bMax)) =>
      _eq(aMin, bMin) && _eq(aMax, bMax),
    ((x: final ax, y: final ay), (x: final bx, y: final by)) =>
      _eq(ax, bx) && _eq(ay, by),
    ((chart: final ac), (chart: final bc)) => _eq(ac, bc),
    (
      (chart: final ac, trigger: final at),
      (chart: final bc, trigger: final bt),
    ) =>
      _eq(ac, bc) && _eq(at, bt),
    ((chart: final ac, event: final ae), (chart: final bc, event: final be)) =>
      _eq(ac, bc) && _eq(ae, be),
    (
      (chart: final ac, event: final ae, point: final ap),
      (chart: final bc, event: final be, point: final bp),
    ) =>
      _eq(ac, bc) && _eq(ae, be) && _eq(ap, bp),
    _ => a == b,
  };
}

/// `toBe(expected)`: the JavaScript `===`.
///
/// Numbers compare by value (`0` is `-0`, and NaN is not NaN), and so do
/// strings and booleans. Another value compares by identity.
Matcher toBe(Object? expected) => _ToBe(expected);

final class const _ToBe(final Object? expected) extends Matcher {
  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    final a = item;
    final b = expected;
    if (a is num && b is num) return a.toDouble() == b.toDouble();
    if (a is String && b is String) return a == b;
    if (a is bool && b is bool) return a == b;
    return identical(a, b);
  }

  @override
  Description describe(Description description) =>
      description.add('=== ').addDescriptionOf(expected);
}

/// `toBeCloseTo(expected, precision)` of jasmine-core 5.4.0:
///
/// ```js
/// if (precision !== 0) precision = precision || 2
/// if (expected === Infinity || expected === -Infinity)
///   return { pass: actual === expected }
/// const pow = Math.pow(10, precision + 1)
/// const delta = Math.abs(expected - actual)
/// const maxDelta = Math.pow(10, -precision) / 2
/// return { pass: Math.round(delta * pow) <= maxDelta * pow }
/// ```
///
/// [precision] can be negative: `-1` accepts a difference that rounds to 5
/// or less.
Matcher toBeCloseTo(num expected, [int precision = 2]) =>
    _ToBeCloseTo(expected.toDouble(), precision);

final class const _ToBeCloseTo(final double expected, final int precision)
    extends Matcher {
  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! num) return false;
    final actual = item.toDouble();
    // Infinity is close to Infinity and -Infinity is close to -Infinity,
    // regardless of the precision.
    if (expected.isInfinite) return actual == expected;
    final pow = math.pow(10.0, precision + 1);
    final delta = (expected - actual).abs();
    final maxDelta = math.pow(10.0, -precision) / 2;
    return (delta * pow).roundToDouble() <= maxDelta * pow;
  }

  @override
  Description describe(Description description) =>
      description.add('a number close to $expected with precision $precision');
}
