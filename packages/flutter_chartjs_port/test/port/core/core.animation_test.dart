// Original code, not ported from Chart.js: core.animation cases with no spec.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/animation_spec.dart';
import 'package:flutter_chartjs_port/src/core/core.animation.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:test/test.dart';

import 'animation_reference.dart';

// The behavior of Chart.js ADR 0019 that test/specs/core.animation.tests.js
// does not check (AGENTS.md rule 3). The expected values come from
// src/core/core.animation.js at v4.5.1, run with type stripping in Node.js
// v24.12.0 on x64. animation_reference.dart has the scenarios and the color
// data, which tool/reference/animation_reference.mjs writes (Chart.js ADR
// 0032). The explicit cases below come from the same engine.
//
// Each tick uses a date relative to `start` in whole milliseconds. Thus the
// results do not depend on the clock. The interpolations are IEEE arithmetic
// and the mix of @kurkle/color. Thus the tests compare the values exactly:
// NaN equals NaN, and -0 differs from 0.

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

/// The plain Map form of the cfg of one replay.
AnyObject _plain(Map<String, Object?> cfg) => cfg;

/// An [AnimationSpec] with the entries of [cfg], in its key order.
AnyObject _spec(Map<String, Object?> cfg) => AnimationSpec()..addAll(cfg);

/// [cfg] with a user `fn` that gives the result of the `number`
/// interpolator. The animation then takes the generic path.
AnyObject _withFn(Map<String, Object?> cfg) => {
  ...cfg,
  'fn': (Object? from, Object? to, double factor) =>
      jsToNumber(from) + (jsToNumber(to) - jsToNumber(from)) * factor,
};

/// Replays [scenario] on the property [prop] of [target] with the cfg form
/// [cfgOf]: [_plain], [_spec] or [_withFn]. It compares each step with the
/// reference.
void _replay(
  AnimationScenario scenario, {
  required Object target,
  required String prop,
  required AnyObject Function(Map<String, Object?> cfg) cfgOf,
  required String label,
}) {
  if (!identical(scenario.current, animationAbsent)) {
    writeProperty(target, prop, scenario.current);
  }
  final anim = Animation(
    cfgOf(scenario.cfg),
    target,
    prop,
    identical(scenario.to, animationAbsent) ? undefined : scenario.to,
  );
  final startBase = anim.start;
  for (final (i, (step, expected)) in scenario.steps.indexed) {
    final reason = '$label, ${scenario.name}, step $i (${step.$1})';
    String? error;
    try {
      switch (step.$1) {
        case 'tick':
          anim.tick(anim.start + step.$2);
        case 'from':
          anim.from = step.$3;
        case 'to':
          anim.to = step.$3;
        case 'update':
          anim.update(cfgOf(step.$4!), step.$3, anim.start + step.$2);
      }
      // The steps compare the error of the port with the error of upstream.
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      error = _errorName(e);
    }
    expect(error, expected.$3, reason: '$reason: error');
    expect(anim.active(), expected.$1, reason: '$reason: active');
    expect(readProperty(target, prop), _isValue(expected.$2), reason: reason);
    final fields = expected.$4;
    if (fields != null) {
      expect(anim.from, _isValue(fields.from), reason: '$reason: from');
      expect(anim.to, _isValue(fields.to), reason: '$reason: to');
      expect(anim.duration, _isValue(fields.duration), reason: '$reason: dur');
      expect(anim.total, _isValue(fields.total), reason: '$reason: total');
      expect(
        anim.start - startBase,
        _isValue(fields.start),
        reason: '$reason: start',
      );
    }
  }
}

/// Runs the color animation of [animationColorReference] from [from] to
/// [to], and returns the value after each tick at the 11 factors.
List<Object?> _colorResults(Object? from, Object? to) {
  final target = <String, Object?>{'color': 'black'};
  final anim =
      Animation(
          {'duration': 1000, 'loop': true, 'type': 'color'},
          target,
          'color',
          'red',
        )
        ..from = from
        ..to = to;
  return [
    for (var k = 0; k <= 10; k++)
      (() {
        anim.tick(anim.start + 100 * k);
        return target['color'];
      })(),
  ];
}

void main() {
  setUpSpecs();

  test('the reference comes from Node.js v24.12.0 on x64', () {
    expect(animationReferenceNode, 'v24.12.0');
    expect(animationReferenceArch, 'x64');
  });

  group('adapt-animation-number-path', () {
    test('each scenario on a plain Map gives the upstream steps', () {
      for (final scenario in animationScenarioReference) {
        _replay(
          scenario,
          target: <String, Object?>{},
          prop: 'prop',
          cfgOf: _plain,
          label: 'Map',
        );
      }
    });

    test('each numeric scenario on an element and on PointOptions', () {
      final numeric = animationScenarioReference.where((s) => s.numeric);
      expect(numeric, isNotEmpty);
      for (final scenario in numeric) {
        for (final (label, target, prop) in [
          ('PointElement x', PointElement(), 'x'),
          ('PointElement y', PointElement(), 'y'),
          ('LineElement x', LineElement(), 'x'),
          ('LineElement y', LineElement(), 'y'),
          ('BarElement x', BarElement(), 'x'),
          ('BarElement y', BarElement(), 'y'),
          ('ArcElement x', ArcElement(), 'x'),
          ('ArcElement y', ArcElement(), 'y'),
          ('ArcElement startAngle', ArcElement(), 'startAngle'),
          ('PointOptions radius', PointOptions(), 'radius'),
        ]) {
          _replay(
            scenario,
            target: target,
            prop: prop,
            cfgOf: _plain,
            label: label,
          );
        }
      }
    });

    test('a user fn with the number formula takes the generic path', () {
      // The number path needs the built-in interpolator. A user fn with the
      // same formula takes the generic path and gives the same steps.
      final numberScenarios = animationScenarioReference.where(
        (s) => s.cfg['type'] == 'number',
      );
      expect(numberScenarios, isNotEmpty);
      for (final scenario in numberScenarios) {
        _replay(
          scenario,
          target: <String, Object?>{},
          prop: 'prop',
          cfgOf: _withFn,
          label: 'Map, fn',
        );
        if (scenario.numeric) {
          _replay(
            scenario,
            target: PointElement(),
            prop: 'x',
            cfgOf: _withFn,
            label: 'PointElement x, fn',
          );
        }
      }
    });

    test('a write by name and the setter store the same state', () {
      // The number path writes x and y through the setters. A write by name
      // of a double stores the same state (Chart.js ADR 0017, section 5).
      // Chart.js ADR 0019 asks for this test on each element class.
      for (final (name, create) in <(String, Element Function())>[
        ('PointElement', PointElement.new),
        ('LineElement', LineElement.new),
        ('BarElement', BarElement.new),
        ('ArcElement', ArcElement.new),
      ]) {
        for (final value in [
          1.5,
          double.nan,
          -0.0,
          3.0,
          double.infinity,
          double.negativeInfinity,
        ]) {
          final viaSetter = create()
            ..x = value
            ..y = value;
          final viaName = create();
          viaName['x'] = value;
          viaName['y'] = value;
          for (final prop in ['x', 'y']) {
            final reason = '$name $prop $value';
            expect(viaName[prop], _isValue(value), reason: reason);
            expect(viaSetter[prop], _isValue(viaName[prop]), reason: reason);
          }
          expect(viaSetter.x, _isValue(viaName.x), reason: '$name x $value');
          expect(viaSetter.y, _isValue(viaName.y), reason: '$name y $value');
        }
      }
    });
  });

  group('adapt-animation-spec', () {
    test('an AnimationSpec cfg gives the steps of a plain Map cfg', () {
      for (final scenario in animationScenarioReference) {
        _replay(
          scenario,
          target: <String, Object?>{},
          prop: 'prop',
          cfgOf: _spec,
          label: 'AnimationSpec',
        );
      }
    });
  });

  group('adapt-animation-color-cache', () {
    test('each color pair at 11 factors gives the upstream colors', () {
      for (final (from, to, results) in animationColorReference) {
        expect(
          _colorResults(from, to),
          pairwiseCompare<Object?, Object?>(results, _same, 'reference'),
          reason: '$from to $to',
        );
      }
    });

    test('a change of from and to between the calls parses again', () {
      final target = <String, Object?>{'color': 'black'};
      final anim = Animation(
        {'duration': 1000, 'loop': true, 'type': 'color'},
        target,
        'color',
        'red',
      );
      for (final (i, step) in animationColorSequence.indexed) {
        if (!identical(step.from, animationAbsent)) anim.from = step.from;
        if (!identical(step.to, animationAbsent)) anim.to = step.to;
        anim.tick(anim.start + step.offset);
        expect(target['color'], _isValue(step.result), reason: 'step $i');
      }
    });

    test('repeated ticks of the same pair give the same colors', () {
      // The cache mixes a clone of the cached target color. Thus a second
      // round of ticks gives the colors of the first round.
      final first = _colorResults('#36A2EB80', 'rgb(255, 99, 132)');
      final target = <String, Object?>{'color': 'black'};
      final anim = Animation(
        {'duration': 1000, 'loop': true, 'type': 'color'},
        target,
        'color',
        'rgb(255, 99, 132)',
      )..from = '#36A2EB80';
      for (var round = 0; round < 3; round++) {
        for (var k = 0; k <= 10; k++) {
          anim.tick(anim.start + 100 * k);
          expect(target['color'], first[k], reason: 'round $round, $k');
        }
      }
    });
  });

  group('Animation', () {
    test('from != to is the JS !== for NaN and -0', () {
      // NaN !== NaN is true: the animation runs until its end.
      final nan = <String, Object?>{'v': double.nan};
      final a = Animation({'duration': 1000}, nan, 'v', double.nan);
      a.tick(a.start + 10);
      expect(a.active(), isTrue);
      expect(nan['v'], _isValue(double.nan));
      a.tick(a.start + 1000);
      expect(a.active(), isFalse);

      // 0 !== -0 is false: the first tick writes the target value.
      final zero = <String, Object?>{'v': 0.0};
      final b = Animation({'duration': 1000}, zero, 'v', -0.0);
      b.tick(b.start + 10);
      expect(b.active(), isFalse);
      expect(zero['v'], _isValue(-0.0));

      final negativeZero = <String, Object?>{'v': -0.0};
      final c = Animation({'duration': 1000}, negativeZero, 'v', 0.0);
      c.tick(c.start + 10);
      expect(c.active(), isFalse);
      expect(negativeZero['v'], _isValue(0.0));
    });

    test('a typeof without an interpolator throws at the interpolation', () {
      // typeof 'a' is 'string', and interpolators has no 'string' key.
      final target = <String, Object?>{'v': 'a'};
      final anim = Animation({'duration': 1000}, target, 'v', 'b');
      anim.tick(anim.start - 10);
      expect(anim.active(), isTrue);
      expect(target['v'], 'a');
      expect(() => anim.tick(anim.start + 10), throwsA(isA<TypeError>()));
      anim.tick(anim.start + 1000);
      expect(anim.active(), isFalse);
      expect(target['v'], 'b');
    });

    test('a user fn with one parameter gets from only', () {
      final calls = <Object?>[];
      final target = <String, Object?>{'v': true};
      final anim = Animation(
        {
          'duration': 1000,
          'fn': (Object? v) {
            calls.add(v);
            return jsTruthy(v) ? 1.0 : 0.0;
          },
        },
        target,
        'v',
        false,
      );
      anim.tick(anim.start + 250);
      expect(calls, [true]);
      expect(target['v'], 1.0);
    });

    test('a JsFunction fn gets the animation as this', () {
      final calls = <List<Object?>>[];
      late final Animation anim;
      final target = <String, Object?>{'v': true};
      anim = Animation(
        {
          'duration': 1000,
          'fn': JsFunction((
            Object? self,
            Object? from,
            Object? to,
            Object? factor,
          ) {
            calls.add([from, to, factor]);
            return identical(self, anim);
          }),
        },
        target,
        'v',
        false,
      );
      anim.tick(anim.start + 250);
      expect(target['v'], isTrue);
      expect(calls, [
        [true, false, 0.25],
      ]);
    });

    test('a truthy fn that is not a function throws at the interpolation', () {
      final target = <String, Object?>{'v': 0.0};
      final anim = Animation({'duration': 1000, 'fn': 5}, target, 'v', 10.0);
      expect(() => anim.tick(anim.start + 250), throwsArgumentError);
    });

    test('the number interpolator with null, undefined and booleans', () {
      for (final (from, to, active, value)
          in const <
            (
              Object?,
              Object?,
              bool,
              Object?,
            )
          >[
            (null, 10.0, true, 2.5),
            (undefined, 10.0, true, double.nan),
            (true, false, true, 0.75),
            (false, 2.0, true, 0.5),
            (null, null, false, null),
            (10.0, null, true, 7.5),
            (10.0, undefined, true, double.nan),
            (true, true, false, true),
          ]) {
        final target = <String, Object?>{'v': 'x'};
        final anim =
            Animation({'duration': 1000, 'type': 'number'}, target, 'v', 'y')
              ..from = from
              ..to = to;
        anim.tick(anim.start + 250);
        expect(anim.active(), active, reason: '$from to $to');
        expect(target['v'], _isValue(value), reason: '$from to $to');
      }
    });

    test('wait completes at the end and fails at update and cancel', () async {
      final target = <String, Object?>{'v': 0.0};
      final ended = Animation({'duration': 100}, target, 'v', 10.0);
      final done = ended.wait();
      ended.tick(ended.start + 100);
      await expectLater(done, completes);

      final updated = Animation({'duration': 100}, target, 'v', 10.0);
      final rejected = updated.wait();
      updated.update({'duration': 100}, 20.0, updated.start + 10);
      await expectLater(rejected, throwsA(same(undefined)));
      // The end of the updated animation resolves the list again. The first
      // future stays failed, and a new future completes.
      final next = updated.wait();
      updated.tick(updated.start + 200);
      await expectLater(next, completes);

      final cancelled = Animation({'duration': 100000}, target, 'v', 10.0);
      final failed = cancelled.wait();
      cancelled.cancel();
      expect(cancelled.active(), isFalse);
      await expectLater(failed, throwsA(same(undefined)));
    });

    test('readProperty and writeProperty need an object target', () {
      expect(() => readProperty(5, 'x'), throwsArgumentError);
      expect(() => writeProperty('s', 'x', 1), throwsArgumentError);
      final point = PointElement();
      expect(readProperty(point, 'x'), same(undefined));
      writeProperty(point, 'x', 2);
      expect(point.x, 2.0);
      final map = <String, Object?>{};
      expect(readProperty(map, 'x'), same(undefined));
      writeProperty(map, 'x', null);
      expect(readProperty(map, 'x'), isNull);
    });
  });
}
