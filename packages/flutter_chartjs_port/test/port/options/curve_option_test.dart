// Original code, not ported from Chart.js: tests of the curve of `easing`.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter/animation.dart' show Curve, Curves;
import 'package:flutter_chartjs_port/src/core/animation_spec.dart';
import 'package:flutter_chartjs_port/src/core/core.animation.dart';
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_chartjs_port/src/options/opt.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:test/test.dart';

// The option `easing` holds a Flutter `Curve` (row adapt-flutter-curves).
// The library has no easing names: a name is a value of the wrong type. A
// curve class of an app or of a plugin needs no registration.

/// A curve of our own: [steps] equal steps, with the value of the last
/// reached step. No constant of `Curves` has this form.
final class const StepsCurve(
  /// The number of steps.
  final int steps,
) extends Curve {
  /// A curve of [steps] steps.
  this;

  @override
  double transformInternal(double t) => (t * steps).floorToDouble() / steps;
}

/// The value of `x` after a tick at [elapsed] ms of an animation of 1000 ms
/// from 0 to 100 with the config [cfg].
double _at(Object cfg, double elapsed) {
  final target = <String, Object?>{'x': 0.0};
  final animation = Animation(cfg, target, 'x', 100.0);
  animation.tick(animation.start + elapsed);
  return target['x']! as double;
}

void main() {
  setUpSpecs();

  group('the option cell', () {
    test('the typed setter stores the curve', () {
      final scope = AnimationOptionsScope()..easing = Curves.easeInOutCubic;
      final cell = scope.easingCell;
      expect(cell, isA<OptValue<Curve>>());
      expect((cell! as OptValue<Curve>).value, same(Curves.easeInOutCubic));
      expect(scope.readKey(OptionKey.easing), same(Curves.easeInOutCubic));
    });

    test('a curve of a raw config stays the same object', () {
      const steps = StepsCurve(4);
      final scope = AnimationOptionsScope()..['easing'] = steps;
      expect(scope['easing'], same(steps));
    });

    test('a function stays a scriptable option', () {
      Object? script(Object? context, Object? options) => Curves.linear;
      expect(classifyTyped<Curve>(script), isA<OptFunction<Curve>>());
    });

    test('an easing name is a value of the wrong type', () {
      expect(classifyTyped<Curve>('easeOutQuart'), isA<OptForeign<Curve>>());
      expect(classifyTyped<Curve>(12.0), isA<OptForeign<Curve>>());
    });

    test('the audit of the typed model reports a name in a scope', () {
      final pairs = <String>[];
      final previous = foreignAudit;
      addTearDown(() => foreignAudit = previous);
      foreignAudit = (owner, key, value) =>
          pairs.add('$key ${value.runtimeType}');
      AnimationOptionsScope()['easing'] = 'easeOutQuart';
      expect(pairs, ['easing String']);
    });
  });

  group('an animation', () {
    test('with no easing is linear', () {
      // core.animation.js:36 `effects[cfg.easing] || effects.linear`.
      expect(_at({'duration': 1000}, 250), 25);
    });

    test('follows a constant of Curves', () {
      final cfg = {'duration': 1000, 'easing': Curves.easeOutQuart};
      for (final elapsed in [100.0, 250.0, 500.0, 900.0]) {
        expect(
          _at(cfg, elapsed),
          100 * Curves.easeOutQuart.transform(elapsed / 1000),
        );
      }
    });

    test('stops in a debug build on an easing name', () {
      expect(
        () => Animation(
          {'duration': 1000, 'easing': 'easeOutQuart'},
          <String, Object?>{'x': 0.0},
          'x',
          100.0,
        ),
        throwsA(
          isA<AssertionError>().having(
            (e) => '${e.message}',
            'message',
            contains('takes a Flutter Curve'),
          ),
        ),
      );
    });
  });

  group('a curve of our own', () {
    const steps = StepsCurve(4);

    test('an animation of a raw config follows it', () {
      final cfg = <String, Object?>{'duration': 1000, 'easing': steps};
      expect(_at(cfg, 0), 0);
      expect(_at(cfg, 240), 0);
      expect(_at(cfg, 260), 25);
      expect(_at(cfg, 510), 50);
      expect(_at(cfg, 990), 75);
      expect(_at(cfg, 1000), 100);
    });

    test('an animation of a typed config follows it', () {
      final cfg = AnimationSpec()
        ..storeKey(OptionKey.duration, 1000.0)
        ..storeKey(OptionKey.easing, steps);
      expect(_at(cfg, 260), 25);
      expect(_at(cfg, 760), 75);
      final animation = Animation(cfg, <String, Object?>{'x': 0.0}, 'x', 1.0);
      expect(animation.easing, same(steps));
    });
  });
}
