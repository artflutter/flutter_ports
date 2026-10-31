// Original code, not ported from Chart.js: tests of animation_spec.dart.
import 'dart:math' as math;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/animation_spec.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart' show jsAssign;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:test/test.dart';

// The face of AnimationSpec (Chart.js ADR 0054 §5: the reads and writes by
// name with the JS rules) against a plain Map with the same entries
// (Chart.js ADR 0019, section 4, the row adapt-animation-spec).

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

/// Expects that the face of [spec] gives the JS results of [plain]: the keys
/// in the order of `Object.keys`, [undefined] for an absent key.
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
    expect(spec[key], same(jsGet(plain, key)), reason: '$reason: [$key]');
    expect(jsGet(spec, key), same(jsGet(plain, key)), reason: '$reason: $key');
  }
  for (final MapEntry(:key, value: getter) in _getters.entries) {
    expect(getter(spec), same(jsGet(plain, key)), reason: '$reason: $key');
  }
}

void main() {
  setUpSpecs();

  group('adapt-animation-spec', () {
    test('the known keys are the keys of defaults.animation', () {
      expect(jsObjectKeys(defaults['animation']), AnimationSpec.knownKeys);
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

    test('the face against a plain Map over random operations', () {
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
          expect(spec.jsDelete(key), plain.containsKey(key), reason: 'delete');
          plain.remove(key);
        } else if (r < 19) {
          spec.jsKeys().forEach(spec.jsDelete);
          plain.clear();
        } else {
          jsAssign(spec, <String, Object?>{
            'extra': i.toDouble(),
            'loop': true,
          });
          plain.addAll({'extra': i.toDouble(), 'loop': true});
        }
        _expectSame(spec, plain, 'operation $i');
      }
    });

    test('jsKeys is a copy: a delete of each key does not throw', () {
      final spec = AnimationSpec()..['duration'] = 1;
      spec['easing'] = 'linear';
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
      expect([for (final key in spec.jsKeys()) spec[key]], [0, 5, 'x']);
      spec
        ..['from'] = 7
        ..['delay'] = 9;
      expect(spec.fromValue, 7);
      expect(spec.delayValue, 9);
      expect(spec.jsDelete('extra'), isTrue);
      expect(spec.jsKeys(), ['delay', 'from', 'to']);
    });
  });
}
