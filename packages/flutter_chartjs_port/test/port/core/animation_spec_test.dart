// Original code, not ported from Chart.js: tests of animation_spec.dart.
import 'dart:math' as math;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/animation_spec.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:test/test.dart';

// The Map protocol of AnimationSpec against a plain Map with the same
// entries (Chart.js ADR 0019, section 4, the row adapt-animation-spec).

/// The getters of the known keys, by key.
final Map<String, Object? Function(AnimationSpec spec)> _getters = {
  'delay': (spec) => spec.delayValue,
  'duration': (spec) => spec.durationValue,
  'easing': (spec) => spec.easingValue,
  'fn': (spec) => spec.fnValue,
  'from': (spec) => spec.fromValue,
  'loop': (spec) => spec.loopValue,
  'to': (spec) => spec.toValue,
  'type': (spec) => spec.typeValue,
};

/// The key order of a spec with the entries of [plain]: the present known
/// keys in their order, then the other keys in the order of [plain].
List<String> _order(AnyObject plain) => [
  for (final key in AnimationSpec.knownKeys)
    if (plain.containsKey(key)) key,
  for (final key in plain.keys)
    if (!AnimationSpec.knownKeys.contains(key)) key,
];

/// Expects that [spec] gives the Map results of [plain].
void _expectSame(AnimationSpec spec, AnyObject plain, String reason) {
  expect(spec.length, plain.length, reason: '$reason: length');
  expect(spec.isEmpty, plain.isEmpty, reason: '$reason: isEmpty');
  expect(spec.keys.toList(), _order(plain), reason: '$reason: keys');
  expect(spec.keys.length, plain.length, reason: '$reason: keys.length');
  for (final key in [...AnimationSpec.knownKeys, 'extra', 'other', '0']) {
    expect(spec.containsKey(key), plain.containsKey(key), reason: key);
    expect(spec.keys.contains(key), plain.containsKey(key), reason: key);
    expect(spec[key], same(plain[key]), reason: '$reason: [$key]');
    expect(jsGet(spec, key), same(jsGet(plain, key)), reason: '$reason: $key');
  }
  for (final MapEntry(:key, value: getter) in _getters.entries) {
    expect(getter(spec), same(jsGet(plain, key)), reason: '$reason: $key');
  }
  final AnyObject map = spec;
  const Object key = 5;
  expect(map[key], isNull);
  expect(map.containsKey(key), isFalse);
}

void main() {
  setUpSpecs();

  group('adapt-animation-spec', () {
    test('the known keys are the keys of defaults.animation', () {
      expect(
        jsObjectKeys(defaults['animation']! as AnyObject),
        AnimationSpec.knownKeys,
      );
    });

    test('a new spec has no key, and each getter gives undefined', () {
      final spec = AnimationSpec();
      _expectSame(spec, <String, Object?>{}, 'new');
      for (final getter in _getters.values) {
        expect(getter(spec), same(undefined));
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
      expect(spec.durationValue, same(undefined));
      expect(spec.easingValue, isNull);
    });

    test('the Map protocol against a plain Map over random operations', () {
      final random = math.Random(19);
      const keys = [...AnimationSpec.knownKeys, 'extra', 'other', '0'];
      final values = <Object?>[
        undefined,
        null,
        0.0,
        1000.0,
        'linear',
        true,
        <Object?>['x'],
        (Object? v) => v,
      ];
      final spec = AnimationSpec();
      final plain = <String, Object?>{};
      for (var i = 0; i < 600; i++) {
        final key = keys[random.nextInt(keys.length)];
        final r = random.nextInt(20);
        if (r < 12) {
          final value = values[random.nextInt(values.length)];
          spec[key] = value;
          plain[key] = value;
        } else if (r < 18) {
          expect(spec.remove(key), same(plain.remove(key)), reason: 'remove');
        } else if (r < 19) {
          spec.clear();
          plain.clear();
        } else {
          spec.addAll({'extra': i.toDouble(), 'loop': true});
          plain.addAll({'extra': i.toDouble(), 'loop': true});
        }
        _expectSame(spec, plain, 'operation $i');
      }
    });

    test('keys is a view, and a change during an iteration does not throw', () {
      final spec = AnimationSpec()..['duration'] = 1;
      final keys = spec.keys;
      spec['easing'] = 'linear';
      expect(keys.toList(), ['duration', 'easing']);
      spec.keys.forEach(spec.remove);
      expect(spec, isEmpty);
    });

    test('the members of MapBase give the results of a plain Map', () {
      final spec = AnimationSpec()
        ..['to'] = 5
        ..['extra'] = 'x'
        ..['delay'] = 0;
      expect(Map<String, Object?>.of(spec), {
        'delay': 0,
        'to': 5,
        'extra': 'x',
      });
      expect(spec.entries.map((e) => e.key), ['delay', 'to', 'extra']);
      expect(spec.values, [0, 5, 'x']);
      expect(spec.putIfAbsent('to', () => 6), 5);
      expect(spec.putIfAbsent('from', () => 7), 7);
      expect(spec.update('delay', (v) => 9), 9);
      expect(spec.fromValue, 7);
      expect(spec.delayValue, 9);
      spec.removeWhere((key, value) => key == 'extra');
      expect(spec.keys, ['delay', 'from', 'to']);
    });
  });
}
