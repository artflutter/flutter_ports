// Ported from chartjs-chart-sankey v0.19.1 src/lib/helpers.test.ts (MIT, Jukka Kurkela).
@TestOn('vm')
library;

import 'package:flutter_chartjs_chart_sankey_port/src/lib/helpers.dart';
import 'package:flutter_chartjs_chart_sankey_port/src/types.dart'
    show SankeySize;
import 'package:test/test.dart';

// helpers.test.ts:3-21 `formatValue`, `formatDescription` and `each`: a
// table of cases, one test for each. Here each table is a list of records
// and a loop. The field `p` is the `%p` text of the input, which upstream
// makes with `JSON.stringify`.

void main() {
  group('lib/helpers', () {
    group('defined', () {
      // Dart `null` stands for the JavaScript `undefined` in the typed
      // fields of the port, and `defined` is a null test.
      const cases = <({bool expected, Object? input, String p, String? skip})>[
        (expected: false, input: null, p: 'undefined', skip: null),
        (
          expected: true,
          input: null,
          p: 'null',
          skip:
              'n/a: Dart null stands for the JS undefined, and the typed '
              'fields have no JS null',
        ),
        (expected: true, input: 0, p: '0', skip: null),
        (expected: true, input: 'abba', p: '"abba"', skip: null),
        (expected: true, input: <Object?>[], p: '[]', skip: null),
        (expected: true, input: <String, Object?>{}, p: '{}', skip: null),
        (expected: true, input: double.nan, p: 'NaN', skip: null),
      ];

      for (final (:expected, :input, :p, :skip) in cases) {
        test('should return $expected for $p', () {
          expect(defined(input), expected);
        }, skip: skip);
      }
    });
    group('toTxtLines', () {
      const cases = <({List<String> expected, Object? input, String p})>[
        (expected: [], input: null, p: 'undefined'),
        (expected: ['123'], input: 123, p: '123'),
        (expected: ['test'], input: 'test', p: '"test"'),
        (expected: ['test'], input: ['test'], p: '["test"]'),
        (expected: ['a', 'b'], input: 'a\nb', p: r'"a\nb"'),
        (expected: ['a', 'b'], input: ['a\nb'], p: r'["a\nb"]'),
        (
          expected: ['a', 'b', 'c', 'd', 'e', 'f', 'g', '1', '2', '3'],
          input: [
            'a\nb',
            ['c', 'd', 'e\nf\ng'],
            1,
            [2, 3],
          ],
          p: r'["a\nb",["c","d","e\nf\ng"],1,[2,3]]',
        ),
      ];

      for (final (:expected, :input, :p) in cases) {
        final expectedText = '[${expected.map((line) => '"$line"').join(',')}]';
        test('should return $expectedText when input is $p', () {
          expect(toTextLines(input), expected);
        });
      }
    });
    group('validateSizeValue', () {
      test('should return "min" when input is "min"', () {
        expect(validateSizeValue(SankeySize.min), SankeySize.min);
      });
      test('should return "max" when input is "max"', () {
        expect(validateSizeValue(SankeySize.max), SankeySize.max);
      });
      test('should return "max" when input is "foo"', () {
        // A size is a SankeySize, and a name is not a value: a debug build
        // stops on the name 'foo'. Another value that is not a size gives
        // the default, as the unknown name does upstream.
        expect(() => validateSizeValue('foo'), throwsA(isA<AssertionError>()));
        expect(validateSizeValue(42), SankeySize.max);
      });
      test('should return "max" when input is undefined', () {
        expect(validateSizeValue(null), SankeySize.max);
      });
    });
  });
}
