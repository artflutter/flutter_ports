// Original code, not ported from Chart.js: core.animation cancel() cases.
@TestOn('vm')
library;

import 'dart:async';

import 'package:chartjs_test_utils/pure.dart';
import 'package:clock/clock.dart';
import 'package:flutter_chartjs_port/src/core/core.animation.dart';
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_promise.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:test/test.dart';

import 'animation_reference.dart';

// The behavior of Animation.cancel() that test/specs/core.animation.tests.js
// does not check (AGENTS.md rule 3). cancel() ticks at Date.now() before it
// stops (core.animation.js:67-74). Thus it writes the value at that time,
// and then it rejects the promises of wait(). When that tick ends the
// animation, the tick resolves the promises first, and the rejection does
// nothing.
//
// The expected values come from src/core/core.animation.js at v4.5.1, run
// with type stripping in Node.js v24.22.1 on arm64 with a fake Date.now.
// tool/reference/animation_reference.mjs writes them to
// animation_reference.dart (Chart.js ADR 0045). Here withClock gives the
// same dates to jsDateNow: the constructor reads animationCancelNow, and a
// cancel step reads `start + offset`. jsRunWithMicrotaskCheckpoint runs the
// promise jobs of each step before the next step, as the script waits for a
// macrotask. The handler of wait() records the value and the active state
// that it sees. Thus the data also gives the order of the write and of the
// settlement.
//
// The web legs do not compile this file: package:clock is not in the import
// list of a web test (check:lib-imports).

/// Whether [actual] is the reference value [expected]: the same type and
/// value, NaN for NaN, and the sign of a zero.
bool _same(Object? actual, Object? expected) {
  if (expected is double) {
    if (actual is! num) return false;
    final value = actual.toDouble();
    if (expected.isNaN) return value.isNaN;
    return value == expected && value.isNegative == expected.isNegative;
  }
  return identical(actual, expected) || actual == expected;
}

/// A matcher for the reference value [expected] ([_same]).
Matcher _isValue(Object? expected) => predicate<Object?>(
  (actual) => _same(actual, expected),
  'is ${expected is String ? "'$expected'" : expected} of the reference',
);

/// The JavaScript name of the class of [error], as `e.constructor.name`.
String _errorName(Object error) =>
    error is TypeError ? 'TypeError' : error.runtimeType.toString();

/// A clock that gives the date [ms], in milliseconds since the epoch.
Clock _at(double ms) =>
    Clock.fixed(DateTime.fromMillisecondsSinceEpoch(ms.toInt()));

/// The plain Map form of the cfg of one replay.
AnyObject _plain(Map<String, Object?> cfg) => cfg;

/// [cfg] with a user `fn` that gives the result of the `number`
/// interpolator. The animation then takes the generic path.
AnyObject _withFn(Map<String, Object?> cfg) => {
  ...cfg,
  'fn': (Object? from, Object? to, double factor) =>
      jsToNumber(from) + (jsToNumber(to) - jsToNumber(from)) * factor,
};

/// Replays [cancelCase] on the property [prop] of [target] with the cfg
/// form [cfgOf]. It compares each step with the reference.
void _replay(
  AnimationCancelCase cancelCase, {
  required Object target,
  required String prop,
  required AnyObject Function(Map<String, Object?> cfg) cfgOf,
  required String label,
}) {
  if (!identical(cancelCase.current, animationAbsent)) {
    writeProperty(target, prop, cancelCase.current);
  }
  final anim = withClock(
    _at(animationCancelNow),
    () => Animation(cfgOf(cancelCase.cfg), target, prop, cancelCase.to),
  );
  AnimationSettled? settled;
  unawaited(
    anim.wait().then<void>(
      (_) => settled = ('resolved', readProperty(target, prop), anim.active()),
      onError: (Object _) =>
          settled = ('rejected', readProperty(target, prop), anim.active()),
    ),
  );
  for (final (i, (step, expected)) in cancelCase.steps.indexed) {
    final reason = '$label, ${cancelCase.name}, step $i (${step.$1})';
    String? error;
    try {
      jsRunWithMicrotaskCheckpoint(() {
        switch (step.$1) {
          case 'tick':
            anim.tick(anim.start + step.$2);
          case 'cancel':
            withClock(_at(anim.start + step.$2), anim.cancel);
          case 'to':
            anim.to = step.$3;
        }
      });
      // The steps compare the error of the port with the error of upstream.
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      error = _errorName(e);
    }
    expect(error, expected.$3, reason: '$reason: error');
    expect(anim.active(), expected.$1, reason: '$reason: active');
    expect(readProperty(target, prop), _isValue(expected.$2), reason: reason);
    final expectedSettled = expected.$4;
    final actualSettled = settled;
    if (expectedSettled == null) {
      expect(actualSettled, isNull, reason: '$reason: settled');
    } else {
      expect(actualSettled, isNotNull, reason: '$reason: settled');
      expect(actualSettled!.$1, expectedSettled.$1, reason: '$reason: kind');
      expect(
        actualSettled.$2,
        _isValue(expectedSettled.$2),
        reason: '$reason: value in the handler',
      );
      expect(
        actualSettled.$3,
        expectedSettled.$3,
        reason: '$reason: active in the handler',
      );
    }
  }
}

void main() {
  setUpSpecs();

  group('Animation.cancel', () {
    test('the cases on a plain Map give the upstream steps', () {
      // A cfg without fn takes the number path for two doubles, and the
      // generic path for the other values.
      for (final cancelCase in animationCancelReference) {
        _replay(
          cancelCase,
          target: <String, Object?>{},
          prop: 'prop',
          cfgOf: _plain,
          label: 'Map',
        );
      }
    });

    test('the numeric cases give the upstream steps on each path', () {
      final numeric = animationCancelReference.where((c) => c.numeric);
      expect(numeric, isNotEmpty);
      for (final cancelCase in numeric) {
        for (final (label, target, prop, cfgOf) in [
          ('Map, fn', <String, Object?>{}, 'prop', _withFn),
          ('PointElement x', PointElement(), 'x', _plain),
          ('PointElement x, fn', PointElement(), 'x', _withFn),
          ('BarElement y', BarElement(), 'y', _plain),
        ]) {
          _replay(
            cancelCase,
            target: target,
            prop: prop,
            cfgOf: cfgOf,
            label: label,
          );
        }
      }
    });
  });
}
