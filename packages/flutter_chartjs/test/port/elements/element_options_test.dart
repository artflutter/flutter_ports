// Original code, not ported from Chart.js: the typed element options.
import 'dart:math' as math;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/elements/element.arc.dart';
import 'package:flutter_chartjs/src/elements/element.bar.dart';
import 'package:flutter_chartjs/src/elements/element.line.dart';
import 'package:flutter_chartjs/src/elements/element.point.dart';
import 'package:flutter_chartjs/src/elements/element_options.dart';
import 'package:flutter_chartjs/src/helpers/helpers.canvas.dart'
    show DrawPointOptions;
import 'package:flutter_chartjs/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs/src/js/js_number.dart' show jsToNumber;
import 'package:flutter_chartjs/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:test/test.dart';

// The typed element options of Chart.js ADR 0018 have no upstream source and
// no spec. These tests check:
// - the Map protocol of each class against a plain Map<String, Object?> over
//   the same operations (section 3);
// - the known keys of each class against the defaults and the defaultRoutes
//   of its element class (section 2);
// - the typed getters against jsGet, also for an absent key (section 4);
// - PointOptions as the DrawPointOptions of drawPoint against the adapter of
//   element.point.dart over a plain Map (section 4).

/// The [undefined] sentinel.
final Matcher _isUndefined = same(undefined);

/// The keys that are not known keys of any class. `'0'` and `'10'` are
/// array indices, which `Object.keys` gives first.
const List<String> _extraKeys = [
  'hoverBackgroundColor',
  'foo',
  '10',
  '0',
  'scales',
];

/// The values that the protocol tests write: numbers, strings, JS `null`,
/// [undefined], a boolean, a list and a Map.
final List<Object?> _values = [
  0,
  1.5,
  double.nan,
  'red',
  '',
  null,
  undefined,
  false,
  true,
  const <double>[4, 2],
  <String, Object?>{'top': true},
];

/// One class of element options with its element statics and getters.
final class _Kind<T extends ElementOptions> {
  _Kind({
    required this.name,
    required this.create,
    required this.knownKeys,
    required this.defaults,
    required this.defaultRoutes,
    required this.writtenKeys,
    required this._getters,
  });

  /// The class name.
  final String name;

  /// The constructor of the class.
  final T Function([AnyObject? source]) create;

  /// The static `knownKeys` of the class.
  final List<String> knownKeys;

  /// The `defaults` of the element class.
  final AnyObject defaults;

  /// The `defaultRoutes` of the element class.
  final AnyObject defaultRoutes;

  /// The known keys that other code writes into the options (Chart.js ADR
  /// 0018, section 2), after the defaults and the routes.
  final List<String> writtenKeys;

  /// The typed getter of each known key.
  ///
  /// Only the members of this class read it: a read through `_Kind` with
  /// another type argument fails the covariance check of the function type.
  final Map<String, Object? Function(T options)> _getters;

  /// The keys that have a typed getter.
  List<String> get getterKeys => _getters.keys.toList();

  /// Whether [key] has a typed getter.
  bool hasGetter(String key) => _getters.containsKey(key);

  /// The value of the getter of [key] on [options].
  Object? read(ElementOptions options, String key) =>
      _getters[key]!(options as T);
}

final List<_Kind> _kinds = [
  _Kind<PointOptions>(
    name: 'PointOptions',
    create: PointOptions.new,
    knownKeys: PointOptions.knownKeys,
    defaults: PointElement.defaults,
    defaultRoutes: PointElement.defaultRoutes,
    writtenKeys: const [r'$animations'],
    getters: {
      r'$shared': (o) => o.$sharedValue,
      'borderWidth': (o) => o.borderWidthValue,
      'hitRadius': (o) => o.hitRadiusValue,
      'hoverBorderWidth': (o) => o.hoverBorderWidthValue,
      'hoverRadius': (o) => o.hoverRadiusValue,
      'pointStyle': (o) => o.pointStyleValue,
      'radius': (o) => o.radiusValue,
      'rotation': (o) => o.rotationValue,
      'backgroundColor': (o) => o.backgroundColorValue,
      'borderColor': (o) => o.borderColorValue,
      r'$animations': (o) => o.$animationsValue,
    },
  ),
  _Kind<LineOptions>(
    name: 'LineOptions',
    create: LineOptions.new,
    knownKeys: LineOptions.knownKeys,
    defaults: LineElement.defaults,
    defaultRoutes: LineElement.defaultRoutes,
    writtenKeys: const ['segment', r'$animations'],
    getters: {
      r'$shared': (o) => o.$sharedValue,
      'borderCapStyle': (o) => o.borderCapStyleValue,
      'borderDash': (o) => o.borderDashValue,
      'borderDashOffset': (o) => o.borderDashOffsetValue,
      'borderJoinStyle': (o) => o.borderJoinStyleValue,
      'borderWidth': (o) => o.borderWidthValue,
      'capBezierPoints': (o) => o.capBezierPointsValue,
      'cubicInterpolationMode': (o) => o.cubicInterpolationModeValue,
      'fill': (o) => o.fillValue,
      'spanGaps': (o) => o.spanGapsValue,
      'stepped': (o) => o.steppedValue,
      'tension': (o) => o.tensionValue,
      'backgroundColor': (o) => o.backgroundColorValue,
      'borderColor': (o) => o.borderColorValue,
      'segment': (o) => o.segmentValue,
      r'$animations': (o) => o.$animationsValue,
    },
  ),
  _Kind<BarOptions>(
    name: 'BarOptions',
    create: BarOptions.new,
    knownKeys: BarOptions.knownKeys,
    defaults: BarElement.defaults,
    defaultRoutes: BarElement.defaultRoutes,
    writtenKeys: const [r'$animations'],
    getters: {
      r'$shared': (o) => o.$sharedValue,
      'borderSkipped': (o) => o.borderSkippedValue,
      'borderWidth': (o) => o.borderWidthValue,
      'borderRadius': (o) => o.borderRadiusValue,
      'inflateAmount': (o) => o.inflateAmountValue,
      'pointStyle': (o) => o.pointStyleValue,
      'backgroundColor': (o) => o.backgroundColorValue,
      'borderColor': (o) => o.borderColorValue,
      r'$animations': (o) => o.$animationsValue,
    },
  ),
  _Kind<ArcOptions>(
    name: 'ArcOptions',
    create: ArcOptions.new,
    knownKeys: ArcOptions.knownKeys,
    defaults: ArcElement.defaults,
    defaultRoutes: ArcElement.defaultRoutes,
    writtenKeys: const [r'$animations'],
    getters: {
      r'$shared': (o) => o.$sharedValue,
      'borderAlign': (o) => o.borderAlignValue,
      'borderColor': (o) => o.borderColorValue,
      'borderDash': (o) => o.borderDashValue,
      'borderDashOffset': (o) => o.borderDashOffsetValue,
      'borderJoinStyle': (o) => o.borderJoinStyleValue,
      'borderRadius': (o) => o.borderRadiusValue,
      'borderWidth': (o) => o.borderWidthValue,
      'offset': (o) => o.offsetValue,
      'spacing': (o) => o.spacingValue,
      'angle': (o) => o.angleValue,
      'circular': (o) => o.circularValue,
      'selfJoin': (o) => o.selfJoinValue,
      'backgroundColor': (o) => o.backgroundColorValue,
      r'$animations': (o) => o.$animationsValue,
    },
  ),
];

/// A matcher of [value]: [isNaN] for NaN, [same] for [undefined], else
/// equality.
Matcher _value(Object? value) => switch (value) {
  final double d when d.isNaN => isNaN,
  Undefined() => _isUndefined,
  _ => equals(value),
};

/// The key order of options with the entries of [model]: the present known
/// keys in the order of [knownKeys], then the extra keys of [model] in its
/// order (Chart.js ADR 0018, section 3).
List<String> _expectedKeys(List<String> knownKeys, AnyObject model) => [
  for (final key in knownKeys)
    if (model.containsKey(key)) key,
  for (final key in model.keys)
    if (!knownKeys.contains(key)) key,
];

/// Expects that [options] holds the entries of [model], read through each
/// member of the Map protocol, through `jsGet` and through the getters of
/// [kind].
void _expectSame(
  _Kind kind,
  ElementOptions options,
  AnyObject model,
  String reason,
) {
  final keys = _expectedKeys(kind.knownKeys, model);
  expect(options.keys.toList(), keys, reason: '$reason: keys');
  expect(options.length, model.length, reason: '$reason: length');
  expect(options.isEmpty, model.isEmpty, reason: '$reason: isEmpty');
  expect(options.isNotEmpty, model.isNotEmpty, reason: '$reason: isNotEmpty');
  expect(
    jsObjectKeys(options),
    jsObjectKeys({for (final key in keys) key: model[key]}),
    reason: '$reason: jsObjectKeys',
  );
  for (final key in [...kind.knownKeys, ..._extraKeys]) {
    final why = '$reason: $key';
    expect(options[key], _value(model[key]), reason: '$why: []');
    expect(
      options.containsKey(key),
      model.containsKey(key),
      reason: '$why: containsKey',
    );
    final value = jsGet(model, key);
    expect(jsGet(options, key), _value(value), reason: '$why: jsGet');
    if (kind.hasGetter(key)) {
      expect(kind.read(options, key), _value(value), reason: '$why: getter');
    }
  }
  // A Map<String, Object?> gives null and false for a key that is not a
  // String.
  expect(options[_notAString], isNull, reason: '$reason: [1]');
  expect(
    options.containsKey(_notAString),
    isFalse,
    reason: '$reason: containsKey(1)',
  );
}

/// The drawPoint calls of a point at (50, 40) with [options].
List<ContextCall> _drawCalls(AnyObject options) {
  final ctx = createMockContext();
  PointElement({'options': options, 'x': 50, 'y': 40}).draw(ctx);
  return ctx.getCalls();
}

void main() {
  setUpSpecs();

  for (final kind in _kinds) {
    group(kind.name, () {
      test(r'the known keys are $shared, the defaults, the routes and the '
          'written keys', () {
        expect(kind.knownKeys, [
          r'$shared',
          ...jsObjectKeys(kind.defaults),
          ...jsObjectKeys(kind.defaultRoutes),
          ...kind.writtenKeys,
        ]);
        expect(kind.knownKeys.toSet(), hasLength(kind.knownKeys.length));
      });

      test('each known key has a getter', () {
        expect(kind.getterKeys, kind.knownKeys);
      });

      test('new options have no key', () {
        final options = kind.create();
        _expectSame(kind, options, {}, 'new');
        for (final key in kind.knownKeys) {
          expect(kind.read(options, key), _isUndefined, reason: key);
        }
      });

      test('the getters give the raw value, and undefined when absent', () {
        final options = kind.create();
        for (final key in kind.knownKeys) {
          for (final value in _values) {
            options[key] = value;
            expect(kind.read(options, key), _value(value), reason: key);
            expect(jsGet(options, key), _value(value), reason: key);
          }
          options.remove(key);
          expect(kind.read(options, key), _isUndefined, reason: key);
          expect(jsGet(options, key), _isUndefined, reason: key);
          expect(options[key], isNull, reason: key);
        }
      });

      test('a stored undefined is a present key', () {
        final options = kind.create();
        final key = kind.knownKeys[1];
        options[key] = undefined;
        expect(options.containsKey(key), isTrue);
        expect(options[key], _isUndefined);
        expect(options.keys, [key]);
        expect(kind.read(options, key), _isUndefined);
      });

      test('a stored null is a present key that reads null', () {
        final options = kind.create();
        final key = kind.knownKeys[1];
        options[key] = null;
        expect(options.containsKey(key), isTrue);
        expect(options[key], isNull);
        expect(kind.read(options, key), isNull);
        expect(jsGet(options, key), isNull);
      });

      test('keys is a view, as the keys of a Map are', () {
        final model = <String, Object?>{};
        final options = kind.create();
        final modelKeys = model.keys;
        final keys = options.keys;
        for (final key in [kind.knownKeys[2], 'foo', kind.knownKeys[1]]) {
          model[key] = 1;
          options[key] = 1;
          expect(keys.length, modelKeys.length, reason: key);
          expect(keys.contains(key), isTrue, reason: key);
          expect(keys, _expectedKeys(kind.knownKeys, model), reason: key);
        }
        model.remove('foo');
        options.remove('foo');
        expect(keys.contains('foo'), isFalse);
        expect(keys.length, modelKeys.length);
        model.clear();
        options.clear();
        expect(keys.isEmpty, isTrue);
        expect(keys, isEmpty);
      });

      test('the writes in the order of the list give the order of a Map', () {
        final model = <String, Object?>{};
        final options = kind.create();
        for (final key in [...kind.knownKeys, ..._extraKeys]) {
          model[key] = key.length;
          options[key] = key.length;
        }
        expect(options.keys.toList(), model.keys.toList());
        expect(options.values.toList(), model.values.toList());
        expect(options.toString(), model.toString());
      });

      test('the constructor copies a Map in its key order', () {
        final source = <String, Object?>{
          'foo': 1,
          kind.knownKeys[2]: 2,
          r'$shared': true,
          kind.knownKeys[1]: null,
          'bar': undefined,
        };
        final options = kind.create(source);
        _expectSame(kind, options, source, 'copy');
        expect(options.keys, [
          r'$shared',
          kind.knownKeys[1],
          kind.knownKeys[2],
          'foo',
          'bar',
        ]);
        final copy = kind.create(options);
        _expectSame(kind, copy, source, 'copy of the copy');
        expect(identical(copy, options), isFalse);
      });

      test('a random sequence of operations gives the results of a Map', () {
        final random = math.Random(18);
        final keys = [...kind.knownKeys, ..._extraKeys];
        final model = <String, Object?>{};
        final options = kind.create();
        for (var step = 0; step < 600; step++) {
          final key = keys[random.nextInt(keys.length)];
          final op = random.nextInt(10);
          final reason = 'step $step';
          switch (op) {
            case < 6:
              final value = _values[random.nextInt(_values.length)];
              model[key] = value;
              options[key] = value;
            case < 9:
              expect(
                options.remove(key),
                _value(model.remove(key)),
                reason: '$reason: remove($key)',
              );
            default:
              if (random.nextInt(4) == 0) {
                model.clear();
                options.clear();
              }
          }
          _expectSame(kind, options, model, reason);
        }
      });

      test('the members of MapBase give the results of a Map', () {
        final model = <String, Object?>{};
        final options = kind.create();
        void both(void Function(AnyObject map) op) {
          op(model);
          op(options);
        }

        both((m) => m.addAll({kind.knownKeys[3]: 3, 'foo': 'x'}));
        both((m) => m.putIfAbsent(kind.knownKeys[1], () => 1));
        both((m) => m.putIfAbsent(kind.knownKeys[1], () => 9));
        both((m) => m.update(kind.knownKeys[3], (v) => '$v!'));
        both((m) => m.update('bar', (v) => v, ifAbsent: () => 'y'));
        _expectSame(kind, options, model, 'after the updates');
        expect(
          [for (final e in options.entries) (e.key, e.value)],
          [for (final key in options.keys) (key, model[key])],
        );
        final visited = <String>[];
        options.forEach((key, value) {
          visited.add(key);
          expect(value, model[key]);
        });
        expect(visited, options.keys);
        both((m) => m.removeWhere((key, value) => key == 'foo'));
        _expectSame(kind, options, model, 'after removeWhere');
        expect(options.remove(_notAString), isNull);
        expect(Map.of(options), model);
      });
    });
  }

  group('PointOptions as DrawPointOptions', () {
    // The adapter of element.point.dart reads the plain Map with
    // `options[key]`: Dart null for an absent key, then ToNumber.
    final cases = <String, Object?>{
      'absent': _absentMarker,
      'null': null,
      'undefined': undefined,
      'zero': 0,
      'number': 4.5,
      'NaN': double.nan,
      'numeric string': '6',
      'string': 'star',
      'true': true,
      'list': const [3],
    };

    for (final MapEntry(key: name, :value) in cases.entries) {
      test('$name gives the values of the adapter', () {
        final map = <String, Object?>{
          if (!identical(value, _absentMarker)) ...{
            'pointStyle': value,
            'rotation': value,
            'radius': value,
            'borderWidth': value,
          },
        };
        final DrawPointOptions options = PointOptions(map);
        expect(options.pointStyle, _value(map['pointStyle']));
        expect(options.rotation, _value(jsToNumber(map['rotation'])));
        expect(options.radius, _value(jsToNumber(map['radius'])));
        expect(options.borderWidth, _value(jsToNumber(map['borderWidth'])));
      });
    }

    test('draws the calls of the adapter for each point style', () {
      for (final style in [
        'circle',
        'cross',
        'crossRot',
        'dash',
        'line',
        'rect',
        'rectRounded',
        'rectRot',
        'star',
        'triangle',
        false,
        null,
        undefined,
      ]) {
        for (final rotation in [null, 0, 30, '45', undefined]) {
          final map = <String, Object?>{
            'radius': 5,
            'borderWidth': 2,
            'borderColor': 'red',
            'backgroundColor': 'blue',
            'pointStyle': style,
            'rotation': ?rotation,
          };
          expect(
            _drawCalls(PointOptions(map)),
            _drawCalls(map),
            reason: '$style $rotation',
          );
        }
      }
    });

    test('a write in place reaches the next draw', () {
      final options = PointOptions({
        'radius': 5,
        'borderWidth': 1,
        'pointStyle': 'circle',
      });
      final point = PointElement({'options': options, 'x': 50, 'y': 40});
      options['radius'] = 7;
      final ctx = createMockContext();
      point.draw(ctx);
      expect(
        [
          for (final call in ctx.getCalls())
            if (call['name'] == 'arc') (call['args']! as List<Object?>)[2],
        ],
        [7],
      );
    });
  });
}

/// The marker of an absent key in the cases of the DrawPointOptions group.
const Object _absentMarker = #absent;

/// A key that is not a `String`.
const Object _notAString = 1;
