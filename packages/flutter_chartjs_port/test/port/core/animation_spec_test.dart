// Original code, not ported from Chart.js: tests of animation_spec.dart.
import 'dart:math' as math;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

// The face of AnimationSpec (Chart.js ADR 0054 §5: the reads and writes by
// name with the JS rules) against a plain Map with the same entries
// (Chart.js ADR 0019, section 4, the row adapt-animation-spec).

/// The typed getters of the known keys, by key.
final Map<String, Object? Function(AnimationSpec spec)> _getters = {
  'delay': (spec) => spec.delay,
  'duration': (spec) => spec.duration,
  'easing': (spec) => spec.easing,
  'fn': (spec) => spec.fn,
  'from': (spec) => spec.from,
  'loop': (spec) => spec.loop,
  'to': (spec) => spec.to,
};

/// The values of each key that the spec takes: a number of milliseconds for
/// `delay` and `duration`, a `Curve` for `easing`, an `Interpolator` for
/// `fn`, a `bool` for `loop`, and any value for `from`, `to` and an extra
/// key. Each key also takes `null` and [undefined].
List<Object?> _valuesOf(String key) => [
  undefined,
  null,
  ...switch (key) {
    'delay' || 'duration' => [0.0, 1000.0],
    'easing' => [Curves.linear, Curves.easeOutQuart],
    'fn' => [(Object? from, Object? to, double factor) => to],
    'loop' => [true, false],
    _ => [
      0.0,
      1000.0,
      'linear',
      true,
      <Object?>['x'],
    ],
  },
];

/// The value of the JS object [plain] for [key], as the face gives it: a
/// known key that holds `null` gives [undefined], because Dart `null` is
/// the absent value of a typed field.
Object? _faceValue(AnyObject plain, String key) {
  final value = jsGet(plain, key);
  if (!AnimationSpec.knownKeys.contains(key)) return value;
  return value ?? undefined;
}

/// A matcher of [expected]: equality for a number, else identity.
Matcher _is(Object? expected) =>
    expected is double ? equals(expected) : same(expected);

/// The key order of a spec with the entries of [plain]: the present known
/// keys in their order, then the other keys in the order of [plain].
List<String> _order(AnyObject plain) => [
  for (final key in AnimationSpec.knownKeys)
    if (plain.containsKey(key)) key,
  for (final key in plain.keys)
    if (!AnimationSpec.knownKeys.contains(key)) key,
];

/// Expects that the face of [spec] gives the JS results of [plain]: the keys
/// in the order of `Object.keys`, [undefined] for an absent key, and the
/// typed getters give the value or Dart `null`.
void _expectSame(AnimationSpec spec, AnyObject plain, String reason) {
  final order = _order(plain);
  expect(
    spec.jsKeys(),
    jsObjectKeys({for (final key in order) key: plain[key]}),
    reason: '$reason: jsKeys',
  );
  expect(spec.jsKeys().length, plain.length, reason: '$reason: count');
  for (final key in [...AnimationSpec.knownKeys, 'extra', 'other', '0']) {
    expect(spec.jsHas(key), plain.containsKey(key), reason: key);
    expect(spec[key], _is(_faceValue(plain, key)), reason: '$reason: [$key]');
    expect(
      jsGet(spec, key),
      _is(_faceValue(plain, key)),
      reason: '$reason: $key',
    );
  }
  for (final MapEntry(:key, value: getter) in _getters.entries) {
    final value = plain[key];
    expect(
      getter(spec),
      _is(value is Undefined ? null : value),
      reason: '$reason: $key',
    );
  }
}

void main() {
  setUpSpecs();

  group('adapt-animation-spec', () {
    test('the known keys are the keys of defaults.animation', () {
      expect(jsObjectKeys(defaults['animation']), AnimationSpec.knownKeys);
    });

    test('a new spec has no key, and each getter gives null', () {
      final spec = AnimationSpec();
      _expectSame(spec, <String, Object?>{}, 'new');
      for (final getter in _getters.values) {
        expect(getter(spec), isNull);
      }
    });

    test('a stored undefined and a stored null are present keys', () {
      final spec = AnimationSpec()
        ..['duration'] = undefined
        ..['easing'] = null
        ..['extra'] = undefined;
      final plain = <String, Object?>{
        'duration': undefined,
        'easing': null,
        'extra': undefined,
      };
      _expectSame(spec, plain, 'undefined and null');
      expect(spec.duration, isNull);
      expect(spec.easing, isNull);
    });

    test('the face against a plain Map over random operations', () {
      final random = math.Random(19);
      const keys = [...AnimationSpec.knownKeys, 'extra', 'other', '0'];
      final spec = AnimationSpec();
      final plain = <String, Object?>{};
      for (var i = 0; i < 600; i++) {
        final key = keys[random.nextInt(keys.length)];
        final r = random.nextInt(20);
        if (r < 12) {
          final values = _valuesOf(key);
          final value = values[random.nextInt(values.length)];
          spec[key] = value;
          plain[key] = value;
        } else if (r < 18) {
          expect(spec.jsDelete(key), plain.containsKey(key), reason: 'delete');
          plain.remove(key);
        } else if (r < 19) {
          spec.jsKeys().forEach(spec.jsDelete);
          plain.clear();
        } else {
          spec
            ..['extra'] = i.toDouble()
            ..['loop'] = true;
          plain.addAll({'extra': i.toDouble(), 'loop': true});
        }
        _expectSame(spec, plain, 'operation $i');
      }
    });

    test('jsKeys is a copy: a delete of each key does not throw', () {
      final spec = AnimationSpec()..['duration'] = 1;
      spec['easing'] = Curves.linear;
      expect(spec.jsKeys(), ['duration', 'easing']);
      spec.jsKeys().forEach(spec.jsDelete);
      expect(spec.jsKeys(), isEmpty);
    });

    test('the face gives the known keys in their order, then the extras', () {
      final spec = AnimationSpec()
        ..['to'] = 5
        ..['extra'] = 'x'
        ..['delay'] = 0;
      expect(spec.jsKeys(), ['delay', 'to', 'extra']);
      expect([for (final key in spec.jsKeys()) spec[key]], [0.0, 5, 'x']);
      spec
        ..['from'] = 7
        ..['delay'] = 1000.0;
      expect(spec.from, 7);
      expect(spec.delay, 1000.0);
      expect(spec.jsDelete('extra'), isTrue);
      expect(spec.jsKeys(), ['delay', 'from', 'to']);
    });
  });

  group('adapt-animation-option-types', () {
    test('a value of another type stops a debug build', () {
      for (final (key, value) in <(String, Object?)>[
        ('duration', '1000'),
        ('delay', true),
        ('easing', 'linear'),
        ('fn', 5),
        ('fn', (Object? v) => v),
        ('loop', 1.0),
      ]) {
        expect(
          () => AnimationSpec()[key] = value,
          throwsA(isA<AssertionError>()),
          reason: '$key $value',
        );
      }
    });

    test('a typed setter makes its key present', () {
      final spec = AnimationSpec()
        ..duration = 400.0
        ..loop = null;
      expect(spec.jsKeys(), ['duration', 'loop']);
      expect(spec['duration'], 400.0);
      expect(spec['loop'], same(undefined));
    });

    test('the key type is an extra key', () {
      final spec = AnimationSpec()..['type'] = 'number';
      expect(spec.jsKeys(), ['type']);
      expect(spec['type'], 'number');
    });
  });
}
