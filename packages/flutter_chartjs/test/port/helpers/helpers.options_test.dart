// Original code, not ported from Chart.js: helpers.options cases with no spec.
import 'dart:async';

import 'package:flutter_chartjs/src/core/core.defaults.dart';
import 'package:flutter_chartjs/src/helpers/helpers.config.dart'
    show createResolver;
import 'package:flutter_chartjs/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
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

/// Runs [body] and returns the lines that it prints (`console.warn`).
List<String> _warnings(void Function() body) {
  final lines = <String>[];
  runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );
  return lines;
}

void main() {
  group('toLineHeight', () {
    test('reads ToString of the value with the anchored pattern', () {
      for (final value in <Object?>[
        '1.5PX',
        '-1px',
        ' 2',
        '2 ',
        '2.',
        '.5',
        '2px\n',
        1e21,
        1e-7,
        '1.5e1',
        true,
        'normal',
      ]) {
        expect(toLineHeight(value, 16), 16 * 1.2, reason: '$value');
      }
      expect(toLineHeight(<Object?>['2'], 16), 32);
      expect(toLineHeight(0.0, 16), _isNumber(0));
      expect(toLineHeight(-0.0, 16), _isNumber(0));
      expect(toLineHeight('200%', 16), 32);
      expect(toLineHeight('3em', 16), 48);
      expect(toLineHeight('0.5', 16), 8);
      expect(toLineHeight(2.0, double.nan), isNaN);
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
  });

  group('toTRBLCorners', () {
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

  group('toFont', () {
    test('warns about an invalid style and drops it', () {
      late ParsedFont font;
      final warnings = _warnings(() {
        font = toFont(<String, Object?>{
          'style': 'bold',
          'size': 12.0,
          'family': 'a',
        });
      });
      expect(warnings, ['Invalid font style specified: "bold"']);
      expect(font.style, isNull);
      expect(font.string, '12px a');
      expect(font.lineHeight, 14.399999999999999);

      expect(
        _warnings(() {
          font = toFont(<String, Object?>{
            'style': 'oblique 100deg',
            'size': 12.0,
            'family': 'a',
          });
        }),
        ['Invalid font style specified: "oblique 100deg"'],
      );
      expect(font.string, '12px a');
    });
    test('accepts an oblique angle of two digits', () {
      final font = toFont(<String, Object?>{
        'style': 'oblique 90deg',
        'size': 12.0,
        'family': 'a',
      });
      expect(font.string, 'oblique 90deg 12px a');
    });
    test('keeps an empty style without a warning', () {
      late ParsedFont font;
      expect(
        _warnings(() {
          font = toFont(<String, Object?>{
            'style': '',
            'size': 10.0,
            'family': 'f',
          });
        }),
        isEmpty,
      );
      expect(font.style, '');
      expect(font.string, '10px f');
    });
    test('reads a string size with parseInt', () {
      var font = toFont(<String, Object?>{'size': '21px', 'family': 'a'});
      expect(
        [font.size, font.lineHeight, font.string],
        [
          21,
          25.2,
          'normal 21px a',
        ],
      );

      font = toFont(<String, Object?>{'size': '  12.9', 'family': 'a'});
      expect([font.size, font.string], [12, 'normal 12px a']);

      font = toFont(<String, Object?>{'size': 'abc', 'family': 'a'});
      expect(font.size, isNaN);
      expect(font.lineHeight, isNaN);
      expect(font.string, 'normal NaNpx a');

      font = toFont(<String, Object?>{'size': '-0', 'family': 'a'});
      expect(font.size, _isNumber(-0));
      expect(font.lineHeight, _isNumber(-0));
      expect(font.string, 'normal 0px a');
    });
    test('gives a null string for a null size', () {
      final font = toFont(<String, Object?>{'size': null, 'family': 'a'});
      expect(font.size, isNull);
      expect(font.lineHeight, _isNumber(0));
      expect(font.string, isNull);
    });
    test('puts the weight into the string', () {
      expect(
        toFont(<String, Object?>{
          'weight': 'bold',
          'size': 12.0,
          'family': 'a',
        }).string,
        'normal bold 12px a',
      );
      final font = toFont(<String, Object?>{
        'weight': 600.0,
        'size': 12.5,
        'family': 'a',
      });
      expect(font.weight, 600);
      expect(font.lineHeight, 15);
      expect(font.string, 'normal 600 12.5px a');
    });
    test('reads the fallback object', () {
      var font = toFont(<String, Object?>{}, <String, Object?>{
        'family': 'x',
        'size': 10.0,
        'lineHeight': '20px',
      });
      expect(font.lineHeight, 20);
      expect(font.style, isNull);
      expect(font.weight, same(undefined));
      expect(font.string, '10px x');

      font = toFont(
        <String, Object?>{'size': 8.0},
        <String, Object?>{
          'family': 'x',
          'size': 10.0,
          'lineHeight': '150%',
          'style': 'italic',
          'weight': 'bold',
        },
      );
      expect(font.lineHeight, 12);
      expect(font.string, 'italic bold 8px x');
    });
    test('reads a resolver through its get trap', () {
      // The has trap of a prefixed resolver does not know 'size'. The get
      // trap gives the null of 'hoverSize'.
      final resolver = createResolver(
        [
          <String, Object?>{'hoverSize': null, 'family': 'a'},
        ],
        ['hover', ''],
      );
      final font = toFont(resolver, <String, Object?>{
        'size': 12.0,
        'family': 'b',
      });
      expect(font.size, isNull);
      expect(font.string, isNull);
      expect(font.family, 'a');

      final trbl = createResolver(
        [
          <String, Object?>{'hoverTop': null, 'y': 5.0},
        ],
        ['hover', ''],
      );
      expect(_trbl(toTRBL(trbl)), {
        'top': 0,
        'right': 0,
        'bottom': 5,
        'left': 0,
      });
    });
    test('reads defaults.font for empty options', () {
      for (final options in <Object?>[null, undefined]) {
        final font = toFont(options);
        expect(
          font.family,
          "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        );
        expect(font.lineHeight, 14.399999999999999);
        expect(font.size, 12);
        expect(font.style, 'normal');
        expect(font.weight, isNull);
        expect(
          font.string,
          "normal 12px 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        );
      }
      expect(defaults['font'], isA<Map<String, Object?>>());
    });
    test('converts a lineHeight string', () {
      expect(
        toFont(<String, Object?>{
          'lineHeight': '2em',
          'size': 10.0,
          'family': 'f',
        }).lineHeight,
        20,
      );
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
      expect(addGrace((min: 0, max: 10), '10%', false), (min: -0.5, max: 10.5));
      expect(addGrace((min: 0, max: 10), '-10%', false), (min: -0.5, max: 9.5));
      expect(addGrace((min: -5, max: 5), 2.0, true), (min: -7.0, max: 7.0));
      expect(addGrace((min: 1, max: 3), '0.5', false), (min: 0.5, max: 3.5));
      expect(addGrace((min: 5, max: 6), null, false), (min: 5.0, max: 6.0));
    });
    test('keeps a zero end at 0 with beginAtZero', () {
      expect(addGrace((min: 0, max: 10), '10%', true), (min: 0.0, max: 10.5));
      final range = addGrace((min: -0.0, max: 6), 1.0, true);
      expect(range.min, _isNumber(0));
      expect(range.max, 7);
    });
    test('gives NaN for an undefined grace', () {
      final range = addGrace((min: 1, max: 2), undefined, false);
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
      expect(context['missing'], isNull);
      expect(context.prototype, same(parent));
    });
    test('gives the own keys in the order of Object.keys', () {
      expect(jsObjectKeys(context), ['2', 'type', 'index', 'u']);
      expect(context.length, 4);
    });
    test('containsKey is the in operator', () {
      expect(
        ['chart', 'n', 'u', 'missing'].map(context.containsKey),
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
      expect(shadow.containsKey('chart'), isTrue);
    });
    test('has a null prototype for a null parent', () {
      final root = createContext(null, <String, Object?>{'chart': 1.0});
      expect(root.prototype, isNull);
      expect(jsObjectKeys(root), ['chart']);
    });
    test('copies only the own keys of the context', () {
      final source = createContext(parent, <String, Object?>{'a': 1.0});
      final copy = createContext(null, source);
      expect(jsObjectKeys(copy), ['a']);
      expect(copy.containsKey('chart'), isFalse);
    });
  });

  // The typed results of toTRBL, toPadding and toFont.
  group('adapt-options-typed-results', () {
    test('converts the font members to the types of CanvasFontSpec', () {
      // Upstream keeps the values: {family: 5, size: true, style:
      // ['italic']}, and the string 'italic truepx 5'.
      var font = toFont(<String, Object?>{
        'family': 5.0,
        'size': true,
        'style': <Object?>['italic'],
      });
      expect([font.family, font.size, font.style], ['5', 1, 'italic']);
      expect(font.lineHeight, 1.2);
      expect(font.string, 'italic 1px 5');

      // Upstream keeps the array [14]. The string is the same.
      font = toFont(<String, Object?>{
        'family': 'f',
        'size': <Object?>[14.0],
      });
      expect(font.size, 14);
      expect(font.lineHeight, 16.8);
      expect(font.string, 'normal 14px f');
    });
    test('a falsy style that is not a string becomes null', () {
      // Upstream keeps the value, and the string is '12px a' for each.
      for (final style in <Object?>[0.0, -0.0, double.nan, false]) {
        final font = toFont(<String, Object?>{
          'style': style,
          'size': 12.0,
          'family': 'a',
        });
        expect(font.style, isNull, reason: '$style');
        expect(font.string, '12px a', reason: '$style');
      }
    });
    test('the TRBL object has no width before toPadding sets it', () {
      final trbl = toTRBL(1.0);
      expect(trbl, isA<ChartArea>());
      expect(() => (trbl as ChartArea).width, throwsA(isA<Error>()));
    });
  });
}
