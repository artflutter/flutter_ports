// Original code, not ported from Chart.js: helpers.options cases with no spec.

import 'package:flutter/painting.dart';

import 'package:flutter_chartjs_port/chartjs_core.dart';
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
          <String, Object?>{'a': 1.0, 'b': '2', 'c': null, 'd': 'x'},
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
          <String, Object?>{'top': undefined, 'y': 3.0},
          <String, Object?>{'top': 'y'},
        ),
        {'top': 3},
      );
      expect(
        readValueToProps(
          <String, Object?>{'top': null, 'y': 3.0},
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
          'topLeft': o.topLeft.x,
          'topRight': o.topRight.x,
          'bottomLeft': o.bottomLeft.x,
          'bottomRight': o.bottomRight.x,
        };
        for (final key in props.keys) {
          expect(corners[key], _isNumber(props[key]!), reason: '$value $key');
        }
      }
    });
    test('gives a BorderRadius as it is (row adapt-flutter-border-radius)', () {
      const corners = BorderRadius.only(
        topLeft: Radius.circular(2),
        bottomRight: Radius.circular(3),
      );
      final o = toTRBLCorners(corners);
      expect(o, same(corners));
      expect(
        [o.topLeft.x, o.topRight.x, o.bottomLeft.x, o.bottomRight.x],
        [2, 0, 0, 3],
      );
    });
    test('stops a debug build on a Map', () {
      expect(
        () => toTRBLCorners(<String, Object?>{'topLeft': 2.0}),
        throwsA(isA<AssertionError>()),
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
      expect(resolve([<Object?>[], 'f'], undefined, 0), 'f');
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
      expect(addGrace((min: 0, max: 10), const PercentGrace(10), false), (
        min: -0.5,
        max: 10.5,
      ));
      expect(addGrace((min: 0, max: 10), const PercentGrace(-10), false), (
        min: -0.5,
        max: 9.5,
      ));
      expect(addGrace((min: -5, max: 5), const ValueGrace(2), true), (
        min: -7.0,
        max: 7.0,
      ));
      expect(addGrace((min: 1, max: 3), const ValueGrace(0.5), false), (
        min: 0.5,
        max: 3.5,
      ));
      expect(addGrace((min: 5, max: 6), const ValueGrace(0), false), (
        min: 5.0,
        max: 6.0,
      ));
    });
    test('keeps a zero end at 0 with beginAtZero', () {
      expect(addGrace((min: 0, max: 10), const PercentGrace(10), true), (
        min: 0.0,
        max: 10.5,
      ));
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

  // The typed contexts of Chart.js ADR 0054 §11 (row `adapt-typed-contexts`).
  group('adapt-typed-contexts', () {
    test('each class gives the type of upstream', () {
      final chart = ScriptableChartContext(_FakeChart());
      final scale = ScriptableScaleContext.scale(chart, _FakeScale());
      final tick = ScriptableScaleContext.tick(scale, Tick(value: 1), 0);
      expect(
        [
          chart.type,
          ScriptableContext.dataset(chart, 0).type,
          ScriptableContext.data(chart, 0, null).type,
          scale.type,
          tick.type,
          ScriptableScalePointLabelContext.pointLabel(scale, ['a'], 0).type,
          ScriptableTooltipContext(
            chart,
            tooltip: null,
            tooltipItems: null,
          ).type,
        ],
        ['chart', 'dataset', 'data', 'scale', 'tick', 'pointLabel', 'tooltip'],
      );
    });
    test('a child reads the members of its parents', () {
      final fake = _FakeChart();
      final chart = ScriptableChartContext(fake);
      final dataset = ScriptableContext.dataset(chart, 3)..dataset = 'd';
      final data = ScriptableContext.data(dataset, 2, null);
      expect(data.chart, same(fake));
      expect(data.datasetIndex, 3);
      expect(data.dataset, 'd');
      expect(data.dataIndex, 2);
      expect(data.index, 2);
      expect(dataset.dataIndex, isNull);
      // The dataset context of a later update gives its new values.
      dataset
        ..dataset = 'e'
        ..datasetIndex = 4;
      expect([data.dataset, data.datasetIndex], ['e', 4]);

      final scaleObject = _FakeScale();
      final scale = ScriptableScaleContext.scale(chart, scaleObject);
      final tick = ScriptableScaleContext.tick(scale, Tick(value: 1), 5);
      expect(tick.scale, same(scaleObject));
      expect([tick.index, scale.index, scale.tick], [5, null, null]);
      final label = ScriptableScalePointLabelContext.pointLabel(scale, [
        'a',
      ], 1);
      expect(label.scale, same(scaleObject));
      expect(label.chart, same(fake));
    });
    test('a context with no chart context throws at chart', () {
      expect(
        () => ScriptableContext.data(null, 0, null).chart,
        throwsA(isA<TypeError>()),
      );
    });
    test('callScriptable gives the typed context to a typed function', () {
      final data = ScriptableContext.data(null, 4, null);
      expect(callScriptable((ScriptableContext c) => c.dataIndex, data), 4);
      expect(
        callScriptable(
          (ScriptableContext c, Object? options) => [c.index, options],
          data,
          'o',
        ),
        [4, 'o'],
      );
      expect(callScriptable((Object? c) => c, data), same(data));
      expect(callScriptable(() => 1, data), 1);
      // A spec gives a Map of its own as the context.
      expect(
        callScriptable((Object? c) => jsGet(c, 'index'), <String, Object?>{
          'index': 1.0,
        }),
        1.0,
      );
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

/// A chart with no members: the `chart` of a context of a test.
final class _FakeChart() implements IChart {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A scale with no members: the `scale` of a context of a test.
final class _FakeScale() implements IScale {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
