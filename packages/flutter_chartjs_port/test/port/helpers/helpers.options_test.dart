// Original code, not ported from Chart.js: helpers.options cases with no spec.
import 'dart:ui' show FontStyle, FontWeight;

import 'package:flutter/painting.dart' show TextStyle;

import 'package:flutter_chartjs_port/src/helpers/grace_length.dart'
    show PercentGrace, ValueGrace;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show createResolver;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:test/test.dart';

// Upstream behaviour that test/specs/helpers.options.tests.js does not check
// (AGENTS.md rule 3). The expected values come from the helpers of the
// chart.js 4.5.1 npm package (dist/chart.umd.js) in Node.js v24.12.0 on x64.

/// Whether [actual] is [expected] by `Object.is`: -0 differs from 0, and NaN
/// is NaN.
bool _objectIs(double actual, double expected) =>
    (actual.isNaN && expected.isNaN) ||
    (actual == expected && actual.isNegative == expected.isNegative);

/// A matcher for [_objectIs].
Matcher _isNumber(double expected) => predicate<double>(
  (actual) => _objectIs(actual, expected),
  'Object.is the number',
);

/// The members of a TRBL object, as the keys of the upstream object.
Map<String, double> _trbl(TRBL o) => {
  'top': o.top,
  'right': o.right,
  'bottom': o.bottom,
  'left': o.left,
};

/// Option values that are not objects, for the fast paths of `toTRBL` and
/// `toTRBLCorners`: numbers, strings, booleans, lists, `null` and
/// `undefined`.
const List<Object?> _notObjects = [
  0.0,
  -0.0,
  4.0,
  -2.5,
  double.nan,
  double.infinity,
  double.negativeInfinity,
  3,
  '5',
  ' 0x10 ',
  '',
  'x',
  true,
  false,
  <Object?>[],
  <Object?>[7.0],
  <Object?>[1.0, 2.0],
  null,
  undefined,
];

void main() {
  // Row adapt-text-style-fonts: the line height is a field of the font.
  group('ChartTextStyle.lineHeight', () {
    test('is fontSize * height, or null without one of them', () {
      expect(
        const ChartTextStyle(fontSize: 12, height: 1.2).lineHeight,
        12 * 1.2,
      );
      expect(const ChartTextStyle(fontSize: 12).lineHeight, isNull);
      expect(const ChartTextStyle(height: 1.2).lineHeight, isNull);
    });

    test('follows the merged size and height', () {
      const base = ChartTextStyle(fontSize: 12, height: 1.2);
      final merged = base.merge(const ChartTextStyle(fontSize: 20));
      expect(merged.lineHeight, 20 * 1.2);
      expect(base.merge(const TextStyle(height: 2)).lineHeight, 24);
      expect(base.copyWith(fontSize: 10).lineHeight, 10 * 1.2);
    });
  });

  group('_readValueToProps', () {
    test('reads the keys of a list from an object', () {
      expect(
        readValueToProps(
          <String, Object?>{
            'a': 1.0,
            'b': '2',
            'c': null,
            'd': 'x',
          },
          ['a', 'b', 'c', 'd', 'e'],
        ),
        {'a': 1, 'b': 2, 'c': 0, 'd': 0, 'e': 0},
      );
    });
    test('gives a number to each key, in the order of the keys', () {
      final props = readValueToProps(3.0, ['b', 'a']);
      expect(props, {'b': 3, 'a': 3});
      expect(props.keys, ['b', 'a']);
    });
    test('reads the shorthand keys of an object of props', () {
      final props = readValueToProps(
        <String, Object?>{'x': 1.0, 'y': 2.0, 'top': 7.0},
        <String, Object?>{'top': 'y', 'right': 'x', 'bottom': 'y', 'left': 'x'},
      );
      expect(props, {'top': 7, 'right': 1, 'bottom': 2, 'left': 1});
      expect(props.keys, ['top', 'right', 'bottom', 'left']);
    });
    test('falls back only for an undefined value', () {
      expect(
        readValueToProps(
          <String, Object?>{
            'top': undefined,
            'y': 3.0,
          },
          <String, Object?>{'top': 'y'},
        ),
        {'top': 3},
      );
      expect(
        readValueToProps(
          <String, Object?>{
            'top': null,
            'y': 3.0,
          },
          <String, Object?>{'top': 'y'},
        ),
        {'top': 0},
      );
    });
    test('converts the values with ToNumber, and -0 to 0', () {
      expect(
        readValueToProps(<String, Object?>{'a': -0.0}, ['a'])['a'],
        _isNumber(0),
      );
      expect(readValueToProps(' 0x10 ', ['a']), {'a': 16});
      expect(readValueToProps(<Object?>[5.0], ['a']), {'a': 5});
      expect(readValueToProps(true, ['a']), {'a': 1});
    });
  });

  group('toTRBL', () {
    test('supports the x / y shorthands', () {
      expect(_trbl(toTRBL(<String, Object?>{'x': 1.0, 'y': 2.0})), {
        'top': 2,
        'right': 1,
        'bottom': 2,
        'left': 1,
      });
    });
    test('gives 0 for -0', () {
      expect(toTRBL(-0.0).top, _isNumber(0));
    });
    test('the fast path gives the result of _readValueToProps', () {
      for (final value in _notObjects) {
        final props = readValueToProps(value, const <String, Object?>{
          'top': 'y',
          'right': 'x',
          'bottom': 'y',
          'left': 'x',
        });
        final o = _trbl(toTRBL(value));
        for (final key in props.keys) {
          expect(o[key], _isNumber(props[key]!), reason: '$value $key');
        }
      }
    });
  });

  group('toTRBLCorners', () {
    test('the fast path gives the result of _readValueToProps', () {
      for (final value in _notObjects) {
        final props = readValueToProps(value, const [
          'topLeft',
          'topRight',
          'bottomLeft',
          'bottomRight',
        ]);
        final o = toTRBLCorners(value);
        final corners = {
          'topLeft': o.topLeft,
          'topRight': o.topRight,
          'bottomLeft': o.bottomLeft,
          'bottomRight': o.bottomRight,
        };
        for (final key in props.keys) {
          expect(corners[key], _isNumber(props[key]!), reason: '$value $key');
        }
      }
    });
    test('gives 0 for the missing corners', () {
      final o = toTRBLCorners(<String, Object?>{
        'topLeft': 2.0,
        'bottomRight': '3',
      });
      expect(
        [o.topLeft, o.topRight, o.bottomLeft, o.bottomRight],
        [2, 0, 0, 3],
      );
    });
  });

  group('toPadding', () {
    test('adds width and height', () {
      final o = toPadding(<String, Object?>{
        'top': -1.0,
        'right': '2',
        'bottom': double.infinity,
        'left': 1.0,
      });
      expect(
        [o.top, o.right, o.bottom, o.left, o.width, o.height],
        [-1, 2, double.infinity, 1, 3, double.infinity],
      );
    });
    test('takes no argument', () {
      final o = toPadding();
      expect([o.top, o.width, o.height], [0, 0, 0]);
    });
  });

  // Row adapt-text-style-fonts: toFont merges a TextStyle over the fallback.
  group('toFont', () {
    test('merges the font over defaults.font', () {
      final font = toFont(const ChartTextStyle(fontWeight: FontWeight.bold));
      expect(font.fontFamily, 'Helvetica Neue');
      expect(font.fontFamilyFallback, ['Helvetica', 'Arial', 'sans-serif']);
      expect(font.fontSize, 12);
      expect(font.fontWeight, FontWeight.bold);
      expect(font.fontStyle, FontStyle.normal);
      expect(font.lineHeight, 12 * 1.2);
    });

    test('merges the font over the fallback', () {
      const fallback = ChartTextStyle(fontSize: 10, height: 2);
      final font = toFont(const ChartTextStyle(fontSize: 20), fallback);
      expect(font.fontSize, 20);
      expect(font.height, 2);
      expect(font.lineHeight, 40);
      expect(font.fontFamily, isNull);
    });

    test('a plain TextStyle gives a ChartTextStyle', () {
      final font = toFont(const TextStyle(fontSize: 30));
      expect(font, isA<ChartTextStyle>());
      expect(font.lineHeight, 30 * 1.2);
    });

    test('a value that is not a font gives the fallback', () {
      expect(toFont(undefined), toFont(const ChartTextStyle()));
      expect(toFont(null).fontSize, 12);
      expect(toFont(5.0).fontSize, 12);
    });

    test('a font object of Chart.js stops a debug build', () {
      expect(
        () => toFont(<String, Object?>{'size': 12}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('reads a resolver font, merged through its scopes', () {
      final resolver = createResolver([
        <String, Object?>{'font': const ChartTextStyle(fontSize: 20)},
        <String, Object?>{
          'font': const ChartTextStyle(fontWeight: FontWeight.bold),
        },
      ]);
      final font = toFont(resolver['font']);
      expect(font.fontSize, 20);
      expect(font.fontWeight, FontWeight.bold);
      expect(font.lineHeight, 24);
    });
  });

  group('resolve', () {
    test('sets info.cacheable only for a scriptable or indexable value', () {
      var info = <String, Object?>{'cacheable': true};
      expect(resolve([undefined, 1.0], <String, Object?>{}, 0, info), 1);
      expect(info, {'cacheable': true});

      info = <String, Object?>{'cacheable': true};
      expect(resolve([() => 5.0], <String, Object?>{}, null, info), 5);
      expect(info, {'cacheable': false});

      info = <String, Object?>{'cacheable': true};
      expect(
        resolve(
          [
            <Object?>[1.0, 2.0],
          ],
          undefined,
          1,
          info,
        ),
        2,
      );
      expect(info, {'cacheable': false});

      info = <String, Object?>{'cacheable': true};
      expect(
        resolve([() => undefined, 7.0], <String, Object?>{}, null, info),
        7,
      );
      expect(info, {'cacheable': false});
    });
    test('calls a function for a null context', () {
      expect(
        resolve([(Object? c) => c == null ? 'null-ctx' : 'other'], null),
        'null-ctx',
      );
    });
    test('gives undefined for an index that is not an array index', () {
      final array = <Object?>[1.0, 2.0, 3.0];
      expect(resolve([array, 'f'], undefined, -1), 'f');
      expect(resolve([array, 'f'], undefined, 0.5), 'f');
      expect(resolve([<Object?>[], 'f'], undefined, 0), 'f');
      expect(
        resolve(
          [
            <Object?>[1.0],
            'f',
          ],
          undefined,
          double.nan,
        ),
        'f',
      );
      expect(resolve([array, 'f'], undefined, -0), 1);
    });
    test('returns null elements and undefined for no input', () {
      expect(
        resolve(
          [
            <Object?>[null, 1.0],
            'f',
          ],
          undefined,
          0,
        ),
        isNull,
      );
      expect(resolve([]), same(undefined));
    });
  });

  group('_addGrace', () {
    test('adds the grace to both ends', () {
      // The grace is a GraceLength (row adapt-length-objects).
      expect(
        addGrace((min: 0, max: 10), const PercentGrace(10), false),
        (min: -0.5, max: 10.5),
      );
      expect(
        addGrace((min: 0, max: 10), const PercentGrace(-10), false),
        (min: -0.5, max: 9.5),
      );
      expect(
        addGrace((min: -5, max: 5), const ValueGrace(2), true),
        (min: -7.0, max: 7.0),
      );
      expect(
        addGrace((min: 1, max: 3), const ValueGrace(0.5), false),
        (min: 0.5, max: 3.5),
      );
      expect(
        addGrace((min: 5, max: 6), const ValueGrace(0), false),
        (min: 5.0, max: 6.0),
      );
    });
    test('keeps a zero end at 0 with beginAtZero', () {
      expect(
        addGrace((min: 0, max: 10), const PercentGrace(10), true),
        (min: 0.0, max: 10.5),
      );
      final range = addGrace((min: -0.0, max: 6), const ValueGrace(1), true);
      expect(range.min, _isNumber(0));
      expect(range.max, 7);
    });
    test('gives NaN for a NaN grace', () {
      final range = addGrace(
        (min: 1, max: 2),
        const ValueGrace(double.nan),
        false,
      );
      expect(range.min, isNaN);
      expect(range.max, isNaN);
    });
  });

  // createContext: the Map form of the prototype chain.
  group('adapt-create-context-prototype', () {
    late Map<String, Object?> parent;
    late ContextObject context;

    setUp(() {
      parent = <String, Object?>{'chart': 'c', 'type': 'chart', 'n': null};
      context = createContext(parent, <String, Object?>{
        'type': 'dataset',
        'index': 1.0,
        '2': 'two',
        'u': undefined,
      });
    });

    test('reads the own keys, then the prototype', () {
      expect(context['chart'], 'c');
      expect(context['type'], 'dataset');
      expect(context['index'], 1);
      expect(context['n'], isNull);
      expect(context['u'], same(undefined));
      expect(context['missing'], same(undefined));
      expect(context.prototype, same(parent));
    });
    test('gives the own keys in the order of Object.keys', () {
      expect(jsObjectKeys(context), ['2', 'type', 'index', 'u']);
      expect(context.ownKeyCount, 4);
    });
    test('containsKey is the in operator', () {
      expect(
        ['chart', 'n', 'u', 'missing'].map(context.hasProperty),
        [true, true, true, false],
      );
      expect(
        ['chart', 'type', 'u'].map(context.hasOwnProperty),
        [false, true, true],
      );
    });
    test('sees later changes of the prototype, and writes own keys', () {
      parent['later'] = 'L';
      context['chart'] = 'own';
      expect(
        [context['later'], context['chart'], parent['chart']],
        [
          'L',
          'own',
          'c',
        ],
      );

      final child = createContext(context, <String, Object?>{
        'dataIndex': 0.0,
      });
      expect(
        [child['chart'], child['type'], child['later'], child['dataIndex']],
        ['own', 'dataset', 'L', 0],
      );
      expect(jsObjectKeys(child), ['dataIndex']);
    });
    test('an own undefined shadows the prototype', () {
      final shadow = createContext(parent, <String, Object?>{
        'chart': undefined,
      });
      expect(shadow['chart'], same(undefined));
      expect(shadow.hasProperty('chart'), isTrue);
    });
    test('has a null prototype for a null parent', () {
      final root = createContext(null, <String, Object?>{'chart': 1.0});
      expect(root.prototype, isNull);
      expect(jsObjectKeys(root), ['chart']);
    });
    test('copies only the own keys of the context', () {
      final source = createContext(parent, <String, Object?>{'a': 1.0});
      // `Object.assign` reads the own keys of the context object: the plain
      // object of its face (Chart.js ADR 0054 §5).
      final copy = createContext(null, <String, Object?>{
        for (final key in jsObjectKeys(source)) key: source[key],
      });
      expect(jsObjectKeys(copy), ['a']);
      expect(copy.hasProperty('chart'), isFalse);
    });
  });

  // createContext: the typed class of the type (Chart.js ADR 0054 §11).
  group('adapt-typed-contexts', () {
    test('gives the class of the type', () {
      ContextObject make(String type) =>
          createContext(null, <String, Object?>{'type': type});
      expect(make('chart'), isA<ScriptableChartContext>());
      expect(make('dataset'), isA<ScriptableContext>());
      expect(make('data'), isA<ScriptableContext>());
      expect(make('scale'), isA<ScriptableScaleContext>());
      expect(make('tick'), isA<ScriptableScaleContext>());
      expect(make('pointLabel'), isA<ScriptableScalePointLabelContext>());
      expect(make('tooltip'), isA<ScriptableTooltipContext>());
      expect(make('segment'), isA<ScriptableLineSegmentContext>());
      final other = make('custom');
      expect(other.runtimeType, ContextObject);
      final none = createContext(null, <String, Object?>{'a': 1.0});
      expect(none.runtimeType, ContextObject);
    });
    test('keeps the order of the literal, with fields and extras', () {
      // core.datasetController.js:196-205, then an extra and a field write.
      final chart = createContext(null, <String, Object?>{
        'chart': 'c',
        'type': 'chart',
      });
      final dataset = createContext(chart, <String, Object?>{
        'active': false,
        'dataset': undefined,
        'datasetIndex': 0.0,
        'index': 0.0,
        'mode': 'default',
        'type': 'dataset',
      });
      final data =
          (createContext(dataset, <String, Object?>{
              'active': false,
              'dataIndex': 2.0,
              'parsed': undefined,
              'raw': undefined,
              'element': 'e',
              'index': 2.0,
              'mode': 'default',
              'type': 'data',
            }) as ScriptableContext)
            ..['extra'] = 'x'
            ..['raw'] = 7.0;
      expect(jsObjectKeys(data), [
        'active',
        'dataIndex',
        'parsed',
        'raw',
        'element',
        'index',
        'mode',
        'type',
        'extra',
      ]);
      expect(
        [data.raw, data.dataIndex, data.parsed, data['extra']],
        [7.0, 2.0, same(undefined), 'x'],
      );
      // The members of the parents: the dataset and the chart context.
      expect(data.datasetIndex, 0.0);
      expect(data['chart'], 'c');
      expect((chart as ScriptableChartContext).chart, 'c');
      expect(data.hasOwnProperty('datasetIndex'), isFalse);
    });
    test('a delete of a field reads the parent again', () {
      final parent = createContext(null, <String, Object?>{
        'index': 1.0,
        'type': 'scale',
      });
      final tick = createContext(parent, <String, Object?>{
        'tick': 't',
        'index': 2.0,
        'type': 'tick',
      }) as ScriptableScaleContext;
      expect([tick.index, tick.tick, tick.type], [2.0, 't', 'tick']);
      expect(tick.jsDelete('index'), isTrue);
      expect(tick.index, 1.0);
      expect(jsObjectKeys(tick), ['tick', 'type']);
      tick['index'] = 3.0;
      expect(jsObjectKeys(tick), ['tick', 'type', 'index']);
      expect(tick.index, 3.0);
    });
    test('the face reads with JS rules', () {
      final context = createContext(
        createContext(null, <String, Object?>{'n': null, 'type': 'chart'}),
        <String, Object?>{'p0': 'a', 'type': 'segment', '1': 'one'},
      );
      expect(context.jsRead('p0'), 'a');
      expect(context.jsRead('n'), isNull);
      expect(context.jsRead('missing'), same(undefined));
      expect(context.jsKeys(), ['1', 'p0', 'type']);
      expect(context.jsHas('n'), isFalse);
      expect(context.jsDelete('p0'), isTrue);
      expect(context.jsDelete('p0'), isFalse);
      expect(context.jsRead('p0'), same(undefined));
    });
  });

  // The typed results of toTRBL and toPadding.
  group('adapt-options-typed-results', () {
    test('the TRBL object has no width before toPadding sets it', () {
      final trbl = toTRBL(1.0);
      expect(trbl, isA<ChartArea>());
      expect(() => (trbl as ChartArea).width, throwsA(isA<Error>()));
    });
  });
}
