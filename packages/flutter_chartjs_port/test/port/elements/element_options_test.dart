// Original code, not ported from Chart.js: the typed element options.
import 'dart:math' as math;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show DrawPointOptions;
import 'package:flutter_chartjs_port/src/js/js_array.dart'
    show JsProxyObject, jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_class.dart' show jsAssign;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsToNumber;
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show JsObjectFace, jsGet, jsObjectFreeze, jsObjectIsFrozen, jsSet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:test/test.dart';

// The typed element options of Chart.js ADR 0054 §9 have no upstream source
// and no spec. These tests check:
// - the face of each class (Chart.js ADR 0054 §5: the reads and writes by
//   name with the JS rules) against a plain Map<String, Object?> over the
//   same operations;
// - the known keys of each class against the defaults and the defaultRoutes
//   of its element class (section 2);
// - the typed getters against jsGet, also for an absent key (section 4);
// - PointOptions as the DrawPointOptions of drawPoint against the adapter of
//   element.point.dart over a plain Map (section 4).
// The tests of Chart.js ADR 0021 (section 7) check:
// - createElementOptions for the ids of the element classes and other ids;
// - clone of the five classes, also one test for each known key, and
//   copyOptions for ElementOptions, plain Maps and resolvers;
// - the frozen state of the five classes against Object.freeze in strict
//   mode;
// - the key order of the copy of resolveTargetOptions (the pin of the
//   differences.md row adapt-typed-element-options);
// - GenericElementOptions against a plain Map over the same operations.
// The JavaScript results come from Node.js v24.12.0 on x64 (V8 13.6), in an
// ES module, thus in strict mode.

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

  /// The `defaults` of the element class: a typed scope.
  final JsObjectFace defaults;

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
      'spacingMode': (o) => o.spacingModeValue,
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
/// member of the face (with the JS rules: [undefined] for an absent key),
/// through `jsGet` and through the getters of [kind].
void _expectSame(
  _Kind kind,
  ElementOptions options,
  AnyObject model,
  String reason,
) {
  final keys = _expectedKeys(kind.knownKeys, model);
  expect(
    options.jsKeys(),
    jsObjectKeys({for (final key in keys) key: model[key]}),
    reason: '$reason: jsKeys',
  );
  expect(
    jsObjectKeys(options),
    options.jsKeys(),
    reason: '$reason: jsObjectKeys',
  );
  expect(options.ownKeyCount, model.length, reason: '$reason: ownKeyCount');
  for (final key in [...kind.knownKeys, ..._extraKeys]) {
    final why = '$reason: $key';
    final value = jsGet(model, key);
    expect(options[key], _value(value), reason: '$why: []');
    expect(options.jsRead(key), _value(value), reason: '$why: jsRead');
    expect(options.jsHas(key), model.containsKey(key), reason: '$why: jsHas');
    expect(jsGet(options, key), _value(value), reason: '$why: jsGet');
    if (kind.hasGetter(key)) {
      expect(kind.read(options, key), _value(value), reason: '$why: getter');
    }
  }
}

/// Deletes each own key of [options] through its face.
void _deleteAll(ElementOptions options) {
  options.jsKeys().forEach(options.jsDelete);
}

/// The drawPoint calls of a point at (50, 40) with [options].
List<ContextCall> _drawCalls(Object options) {
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
          expect(options.jsDelete(key), isTrue, reason: key);
          expect(kind.read(options, key), _isUndefined, reason: key);
          expect(jsGet(options, key), _isUndefined, reason: key);
          expect(options[key], _isUndefined, reason: key);
        }
      });

      test('a stored undefined is a present key', () {
        final options = kind.create();
        final key = kind.knownKeys[1];
        options[key] = undefined;
        expect(options.jsHas(key), isTrue);
        expect(options[key], _isUndefined);
        expect(options.jsKeys(), [key]);
        expect(kind.read(options, key), _isUndefined);
      });

      test('a stored null is a present key that reads null', () {
        final options = kind.create();
        final key = kind.knownKeys[1];
        options[key] = null;
        expect(options.jsHas(key), isTrue);
        expect(options[key], isNull);
        expect(kind.read(options, key), isNull);
        expect(jsGet(options, key), isNull);
      });

      test('jsKeys follows the writes and the deletes', () {
        final model = <String, Object?>{};
        final options = kind.create();
        for (final key in [kind.knownKeys[2], 'foo', kind.knownKeys[1]]) {
          model[key] = 1;
          options[key] = 1;
          expect(options.ownKeyCount, model.length, reason: key);
          expect(options.jsHas(key), isTrue, reason: key);
          expect(
            options.jsKeys(),
            _expectedKeys(kind.knownKeys, model),
            reason: key,
          );
        }
        model.remove('foo');
        expect(options.jsDelete('foo'), isTrue);
        expect(options.jsHas('foo'), isFalse);
        expect(options.ownKeyCount, model.length);
        expect(options.jsKeys(), _expectedKeys(kind.knownKeys, model));
      });

      test('the writes in the order of the list give the order of a Map', () {
        final model = <String, Object?>{};
        final options = kind.create();
        for (final key in [...kind.knownKeys, ..._extraKeys]) {
          model[key] = key.length;
          options[key] = key.length;
        }
        expect(options.jsKeys(), jsObjectKeys(model));
        expect(
          [for (final key in options.jsKeys()) options[key]],
          [for (final key in jsObjectKeys(model)) model[key]],
        );
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
        expect(options.jsKeys(), [
          r'$shared',
          kind.knownKeys[1],
          kind.knownKeys[2],
          'foo',
          'bar',
        ]);
        final copy = options.clone();
        _expectSame(kind, copy, source, 'clone of the copy');
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
                options.jsDelete(key),
                model.containsKey(key),
                reason: '$reason: jsDelete($key)',
              );
              model.remove(key);
            default:
              if (random.nextInt(4) == 0) {
                model.clear();
                _deleteAll(options);
              }
          }
          _expectSame(kind, options, model, reason);
        }
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

  _adr0021Tests();
}

/// One options class of the tests of Chart.js ADR 0021.
final class _Class {
  const _Class(this.name, this.create, this.knownKeys, this.keyA, this.keyB);

  /// The class name.
  final String name;

  /// The constructor of the class.
  final ElementOptions Function([AnyObject? source]) create;

  /// The static `knownKeys` of the class. [GenericElementOptions] has none.
  final List<String> knownKeys;

  /// Two keys that the options of the element type have: known keys of a
  /// typed class.
  final String keyA;
  final String keyB;
}

const List<_Class> _classes = [
  _Class(
    'PointOptions',
    PointOptions.new,
    PointOptions.knownKeys,
    'radius',
    'borderWidth',
  ),
  _Class(
    'LineOptions',
    LineOptions.new,
    LineOptions.knownKeys,
    'tension',
    'borderWidth',
  ),
  _Class(
    'BarOptions',
    BarOptions.new,
    BarOptions.knownKeys,
    'borderSkipped',
    'borderWidth',
  ),
  _Class(
    'ArcOptions',
    ArcOptions.new,
    ArcOptions.knownKeys,
    'offset',
    'borderWidth',
  ),
  _Class(
    'GenericElementOptions',
    GenericElementOptions.new,
    [],
    'radius',
    'borderWidth',
  ),
];

/// The TypeError of a write into a frozen object in strict mode.
final Matcher _throwsTypeError = throwsA(isA<TypeError>());

/// A resolver: its `get` trap gives the value of [_values] with a `!`
/// suffix, and [objectKeys] gives the keys in the order of [_order].
final class _Proxy implements JsProxyObject {
  _Proxy(this._values, this._order);

  final Map<String, Object?> _values;
  final List<String> _order;

  @override
  Object? jsRead(String name) => '${_values[name]}!';

  @override
  Object? operator [](String name) => jsRead(name);

  @override
  void jsWrite(String name, Object? value) {}

  @override
  void operator []=(String name, Object? value) {}

  @override
  List<String> jsKeys() => objectKeys();

  @override
  bool jsHas(String name) => _order.contains(name);

  @override
  bool jsDelete(String name) => false;

  @override
  List<String> objectKeys() => _order;

  @override
  List<String> ownKeys() => _values.keys.toList();

  @override
  bool hasProperty(String name) => _values.containsKey(name);
}

void _adr0021Tests() {
  group('createElementOptions', () {
    test('the ids of the element classes give their typed classes', () {
      expect(createElementOptions(PointElement.id), isA<PointOptions>());
      expect(createElementOptions(LineElement.id), isA<LineOptions>());
      expect(createElementOptions(BarElement.id), isA<BarOptions>());
      expect(createElementOptions(ArcElement.id), isA<ArcOptions>());
    });

    test('another id gives GenericElementOptions', () {
      for (final id in <Object?>[
        'custom',
        'myPoint',
        'Point',
        '',
        null,
        undefined,
        5.0,
        true,
      ]) {
        expect(
          createElementOptions(id),
          isA<GenericElementOptions>(),
          reason: '$id',
        );
      }
    });

    test('each call gives a new, empty object that is not frozen', () {
      for (final id in ['point', 'line', 'bar', 'arc', 'custom']) {
        final first = createElementOptions(id);
        final second = createElementOptions(id);
        expect(identical(first, second), isFalse, reason: id);
        expect(first.ownKeyCount, 0, reason: id);
        expect(first.isFrozen, isFalse, reason: id);
        expect(jsObjectIsFrozen(first), isFalse, reason: id);
      }
    });
  });

  for (final c in _classes) {
    group('clone of ${c.name}', () {
      /// Options with a known key, extra keys, an array-index key, the
      /// undefined sentinel and JS null.
      ElementOptions source() => c.create()
        ..['foo'] = 1.0
        ..[c.keyB] = undefined
        ..[r'$shared'] = true
        ..[c.keyA] = null
        ..['10'] = <String, Object?>{'top': true}
        ..['bar'] = undefined;

      test('gives the same class with the same entries in the same order', () {
        final options = source();
        final copy = options.clone();
        expect(copy.runtimeType, options.runtimeType);
        expect(identical(copy, options), isFalse);
        expect(copy.jsKeys(), options.jsKeys());
        expect(jsObjectKeys(copy), jsObjectKeys(options));
        expect(copy.ownKeyCount, options.ownKeyCount);
        for (final key in options.jsKeys()) {
          expect(copy.jsHas(key), isTrue, reason: key);
          // The copy is shallow, as Object.assign is: the same objects.
          expect(copy[key], same(options[key]), reason: key);
          expect(jsGet(copy, key), same(jsGet(options, key)), reason: key);
        }
        expect(copy.isFrozen, isFalse);
      });

      test('a write into the copy does not change the source', () {
        final options = source();
        final keys = options.jsKeys();
        options.clone()
          ..[c.keyA] = 7.0
          ..['foo'] = 'changed'
          ..['baz'] = 2.0
          ..[r'$animations'] = <String, Object?>{}
          ..jsDelete(c.keyB)
          ..jsDelete('bar');
        expect(options.jsKeys(), keys);
        expect(options[c.keyA], isNull);
        expect(options['foo'], 1.0);
        expect(options.jsHas('baz'), isFalse);
        expect(options.jsHas(r'$animations'), isFalse);
        expect(options[c.keyB], _isUndefined);
        expect(options['bar'], _isUndefined);
      });

      test('a write into the source does not change the copy', () {
        final options = source();
        final copy = options.clone();
        final keys = copy.jsKeys();
        options
          ..['foo'] = 'changed'
          ..['qux'] = 3.0;
        _deleteAll(options);
        expect(copy.jsKeys(), keys);
        expect(copy['foo'], 1.0);
        expect(copy.jsHas('qux'), isFalse);
      });

      test('the copy of frozen options is not frozen', () {
        // Object.isFrozen(Object.assign({}, Object.freeze(o))) is false.
        final options = source()..freeze();
        final copy = options.clone();
        expect(copy.isFrozen, isFalse);
        expect(jsObjectIsFrozen(copy), isFalse);
        copy[c.keyA] = 5.0;
        expect(copy[c.keyA], 5.0);
        expect(options[c.keyA], isNull);
      });

      test('the copy of empty options is empty', () {
        final copy = c.create().clone();
        expect(copy.ownKeyCount, 0);
        expect(copy.runtimeType, c.create().runtimeType);
      });

      test('copyOptions gives the clone', () {
        final options = source();
        final copy = copyOptions(options);
        expect(copy.runtimeType, options.runtimeType);
        expect(identical(copy, options), isFalse);
        expect((copy as ElementOptions).jsKeys(), options.jsKeys());
        expect(copy.isFrozen, isFalse);
      });
    });

    // A source with only one known key gives a copy with the identical
    // value. Thus a test fails when clone does not copy a field.
    for (final key in c.knownKeys) {
      test('clone of ${c.name} copies $key', () {
        final value = <String, Object?>{'key': key};
        final copy = (c.create()..[key] = value).clone();
        expect(copy[key], same(value));
        expect(copy.jsKeys(), [key]);
        expect(copy.ownKeyCount, 1);
      });
    }
  }

  group('copyOptions', () {
    test('a plain Map gives a plain Map in the Object.keys order', () {
      // Object.keys(Object.assign({}, {b: 1, '10': 2})) is ['10', 'b'].
      final copy = copyOptions({'b': 1.0, '10': 2.0}) as Map<String, Object?>;
      expect(copy, isNot(isA<ElementOptions>()));
      expect(copy.keys, ['10', 'b']);
      expect(copy, {'10': 2.0, 'b': 1.0});
    });

    test('a plain Map keeps JS null and undefined as own keys', () {
      // Object.assign({}, {$shared: true, radius: 3, n: null, u: undefined,
      // extra: 'x', 7: 'seven'}) has the keys ['7', '$shared', 'radius',
      // 'n', 'u', 'extra']. n is null, u is undefined, and 'u' in copy is
      // true.
      final source = <String, Object?>{
        r'$shared': true,
        'radius': 3.0,
        'n': null,
        'u': undefined,
        'extra': 'x',
        '7': 'seven',
      };
      final copy = copyOptions(source) as Map<String, Object?>;
      expect(copy.keys, ['7', r'$shared', 'radius', 'n', 'u', 'extra']);
      expect(copy['n'], isNull);
      expect(copy.containsKey('n'), isTrue);
      expect(copy['u'], _isUndefined);
      expect(identical(copy, source), isFalse);
    });

    test('a resolver gives the values of its get trap in the order of '
        'objectKeys', () {
      final copy = copyOptions(
        _Proxy({'a': 1, 'b': 2, 'c': 3}, ['c', 'a']),
      ) as Map<String, Object?>;
      expect(copy, isNot(isA<JsProxyObject>()));
      expect(copy.keys, ['c', 'a']);
      expect(copy.values, ['3!', '1!']);
    });
  });

  for (final c in _classes) {
    group('frozen state of ${c.name}', () {
      /// Options with two keys of the element type, an extra key and a Map
      /// value.
      ElementOptions options() => c.create()
        ..[r'$shared'] = true
        ..[c.keyA] = 3.0
        ..['foo'] = 'x'
        ..[r'$animations'] = <String, Object?>{};

      test('freeze sets the frozen state', () {
        final o = options();
        expect(o.isFrozen, isFalse);
        expect(jsObjectIsFrozen(o), isFalse);
        expect(jsObjectFreeze(o), same(o));
        expect(o.isFrozen, isTrue);
        expect(jsObjectIsFrozen(o), isTrue);
      });

      test('a write throws a TypeError, also of the same value', () {
        // In strict mode, a write of a known key, of the same value, of a new
        // key and of $animations into a frozen object throws a TypeError.
        final o = options()..freeze();
        expect(() => o[c.keyA] = 9.0, _throwsTypeError);
        expect(() => o[c.keyA] = o[c.keyA], _throwsTypeError);
        expect(() => o[c.keyB] = 1.0, _throwsTypeError);
        expect(() => o['foo'] = 'y', _throwsTypeError);
        expect(() => o['newKey'] = 1.0, _throwsTypeError);
        expect(() => o[r'$animations'] = <String, Object?>{}, _throwsTypeError);
        expect(() => o[r'$shared'] = false, _throwsTypeError);
        expect(() => o['n'] = null, _throwsTypeError);
        expect(() => o['u'] = undefined, _throwsTypeError);
      });

      test('a removal of a present key throws a TypeError', () {
        // `delete o.radius` of a frozen object throws a TypeError.
        final o = options()..freeze();
        expect(() => o.jsDelete(c.keyA), _throwsTypeError);
        expect(() => o.jsDelete('foo'), _throwsTypeError);
        expect(() => o.jsDelete(r'$shared'), _throwsTypeError);
      });

      test('Object.assign into frozen options throws a TypeError', () {
        // Object.assign(o, {radius: 3}) of a frozen object throws a
        // TypeError.
        final o = options()..freeze();
        expect(
          () => jsAssign(o, <String, Object?>{c.keyA: 3.0}),
          _throwsTypeError,
        );
        expect(
          () => jsAssign(o, <String, Object?>{'absent': 1.0}),
          _throwsTypeError,
        );
      });

      test('the operations that write nothing do not throw', () {
        // `delete o.absentKey` of a frozen object returns true, and
        // Object.assign(o, {}) returns o.
        final o = options()..freeze();
        final keys = o.jsKeys();
        expect(o.jsDelete('absentKey'), isFalse);
        expect(o.jsDelete(c.keyB), isFalse);
        expect(jsAssign(o, const <String, Object?>{}), same(o));
        expect(o.jsKeys(), keys);
        final empty = c.create()..freeze();
        expect(jsAssign(empty, const <String, Object?>{}), same(empty));
        expect(empty.ownKeyCount, 0);
      });

      test('the reads give the values from before the freeze', () {
        final o = options();
        final animations = o[r'$animations'];
        final keys = o.jsKeys();
        o.freeze();
        expect(o.jsKeys(), keys);
        expect(o.ownKeyCount, 4);
        expect(o[r'$shared'], isTrue);
        expect(o[c.keyA], 3.0);
        expect(o['foo'], 'x');
        expect(o[r'$animations'], same(animations));
        expect(o.jsHas(c.keyA), isTrue);
        expect(o.jsHas(c.keyB), isFalse);
        expect(jsGet(o, c.keyA), 3.0);
        expect(jsGet(o, c.keyB), _isUndefined);
        expect(o.$sharedValue, isTrue);
        expect(o.$animationsValue, same(animations));
      });

      test('the freeze is shallow: a Map value stays writable', () {
        // Object.freeze(o); o.extra.a = 1 does not throw.
        final o = options()..freeze();
        (o[r'$animations']! as Map<String, Object?>)['radius'] = 1.0;
        expect(o[r'$animations'], {'radius': 1.0});
      });
    });
  }

  test('the typed getters of frozen options give the values', () {
    for (final kind in _kinds) {
      final options = kind.create();
      for (final key in kind.knownKeys) {
        options[key] = '$key value';
      }
      options.freeze();
      for (final key in kind.knownKeys) {
        expect(kind.read(options, key), '$key value', reason: key);
      }
    }
  });

  group('adapt-typed-element-options', () {
    // core.animations.js:159 copies shared options with
    // Object.assign({}, options, {$shared: false, $animations: {}}).
    // Object.keys of the copy of {$shared: true, borderWidth: 1, radius: 3,
    // backgroundColor: 'red', myKey: 1} is ['$shared', 'borderWidth',
    // 'radius', 'backgroundColor', 'myKey', '$animations'].
    const jsOrder = [
      r'$shared',
      'borderWidth',
      'radius',
      'backgroundColor',
      'myKey',
      r'$animations',
    ];
    final source = <String, Object?>{
      r'$shared': true,
      'borderWidth': 1.0,
      'radius': 3.0,
      'backgroundColor': 'red',
      'myKey': 1.0,
    };

    Object targetCopy(Object options) {
      final copy = copyOptions(options);
      jsSet(copy, r'$shared', false);
      jsSet(copy, r'$animations', <String, Object?>{});
      return copy;
    }

    test(r'a typed copy puts $animations before the extra keys', () {
      final copy = targetCopy(PointOptions(source));
      expect(copy, isA<PointOptions>());
      expect(jsObjectKeys(copy), [
        r'$shared',
        'borderWidth',
        'radius',
        'backgroundColor',
        r'$animations',
        'myKey',
      ]);
      // The entries are the entries of JavaScript.
      expect(jsObjectKeys(copy).toSet(), jsOrder.toSet());
      expect(jsGet(copy, r'$shared'), isFalse);
    });

    test(
      'GenericElementOptions and a plain Map give the JavaScript order',
      () {
        expect(
          jsObjectKeys(targetCopy(GenericElementOptions(source))),
          jsOrder,
        );
        expect(jsObjectKeys(targetCopy(source)), jsOrder);
      },
    );

    test('a typed copy without extra keys gives the JavaScript order', () {
      final noExtra = {...source}..remove('myKey');
      expect(
        jsObjectKeys(targetCopy(PointOptions(noExtra))),
        [...jsOrder]..remove('myKey'),
      );
    });
  });

  group('GenericElementOptions', () {
    const keys = [
      r'$shared',
      r'$animations',
      'radius',
      'borderWidth',
      ..._extraKeys,
    ];

    /// Expects that [options] holds the entries of [model] in its order,
    /// read through its face with the JS rules.
    void expectSame(
      GenericElementOptions options,
      AnyObject model,
      String reason,
    ) {
      expect(options.jsKeys(), jsObjectKeys(model), reason: reason);
      expect(options.ownKeyCount, model.length, reason: reason);
      expect(jsObjectKeys(options), jsObjectKeys(model), reason: reason);
      for (final key in keys) {
        expect(
          options[key],
          _value(jsGet(model, key)),
          reason: '$reason: $key',
        );
        expect(
          options.jsHas(key),
          model.containsKey(key),
          reason: '$reason: jsHas($key)',
        );
        expect(
          jsGet(options, key),
          _value(jsGet(model, key)),
          reason: '$reason: jsGet($key)',
        );
      }
      expect(
        options.$sharedValue,
        _value(jsGet(model, r'$shared')),
        reason: reason,
      );
      expect(
        options.$animationsValue,
        _value(jsGet(model, r'$animations')),
        reason: reason,
      );
    }

    test('a random sequence of operations gives the results of a Map', () {
      final random = math.Random(21);
      final model = <String, Object?>{};
      final options = GenericElementOptions();
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
              options.jsDelete(key),
              model.containsKey(key),
              reason: '$reason: jsDelete($key)',
            );
            model.remove(key);
          default:
            if (random.nextInt(4) == 0) {
              model.clear();
              _deleteAll(options);
            }
        }
        expectSame(options, model, reason);
        if (step % 50 == 0) {
          expectSame(options.clone(), model, '$reason: clone');
        }
      }
    });

    test('the constructor copies a Map in its key order', () {
      final source = <String, Object?>{
        'foo': 1.0,
        'radius': 2.0,
        r'$animations': null,
        r'$shared': true,
        'bar': undefined,
      };
      final options = GenericElementOptions(source);
      expectSame(options, source, 'copy');
      expect(options.jsKeys(), [
        'foo',
        'radius',
        r'$animations',
        r'$shared',
        'bar',
      ]);
    });
  });
}

/// The marker of an absent key in the cases of the DrawPointOptions group.
const Object _absentMarker = #absent;
