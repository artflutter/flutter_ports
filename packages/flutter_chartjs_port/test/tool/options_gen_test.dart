// Original code, not ported from Chart.js: tests of the schema generator.
@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

import '../../tool/src/options_gen.dart';

const String _schema = r'''
kinds:
  FontSpec:
    doc: the font.
    keys:
      size: number
      weight: number | string
  ChartOptions:
    doc: the chart.
    others: any
    keys:
      font: scope FontSpec
      _fallback: any
      $theme: any
''';

void main() {
  group('readSchema', () {
    test('the kinds, the keys and the shapes', () {
      final schema = readSchema(_schema);
      expect(
        [for (final k in schema.kinds) k.name],
        ['FontSpec', 'ChartOptions'],
      );
      final font = schema.kinds.first.keys;
      expect(font['size']!.dartType, 'double');
      expect(font['weight']!.dartType, 'Object');
      expect(
        font['weight']!.mask,
        shapeAtoms['number']! | shapeAtoms['string']!,
      );
      final chart = schema.kinds.last;
      expect(chart.keys['font']!.scope, 'FontSpec');
      expect(chart.keys['font']!.dartType, 'FontSpecScope');
      expect(chart.others!.mask, shapeAtoms['any']);
      expect(schema.keyNames, [
        r'$theme',
        '_fallback',
        'font',
        'size',
        'weight',
      ]);
    });

    test('errors', () {
      expect(
        () =>
            readSchema('kinds:\n  A:\n    doc: a\n    keys:\n      b: color\n'),
        throwsFormatException,
      );
      expect(
        () => readSchema(
          'kinds:\n  A:\n    doc: a\n    keys:\n      b: scope B\n',
        ),
        throwsFormatException,
      );
      expect(
        () => readSchema('kinds:\n  A:\n    keys: none\n'),
        throwsFormatException,
      );
      expect(() => readSchema('other: 1\n'), throwsFormatException);
    });
  });

  group('keyIdentifier', () {
    test('descriptors, dollar keys and reserved words', () {
      expect(keyIdentifier('_scriptable'), 'descScriptable');
      expect(keyIdentifier(r'$shared'), 'dollarShared');
      expect(keyIdentifier('default'), 'defaultKey');
      expect(keyIdentifier('index'), 'indexKey');
      expect(keyIdentifier('pointRadius'), 'pointRadius');
    });
  });

  group('generate', () {
    test('the four files, with the port-only header', () {
      final files = generate(readSchema(_schema));
      expect(files.keys, [
        'option_keys.g.dart',
        'scope_kinds.g.dart',
        'scopes.g.dart',
        'resolved.g.dart',
      ]);
      for (final text in files.values) {
        expect(text, startsWith('// Original code, not ported from Chart.js:'));
      }
      expect(files['scopes.g.dart'], contains('base class FontSpecScope'));
      expect(
        files['option_keys.g.dart'],
        contains(r"dollarTheme(r'$theme')"),
      );
    });

    test('the committed schema reads', () {
      final schema = readSchema(
        File('tool/options_schema.yaml').readAsStringSync(),
      );
      expect(schema.kinds, isNotEmpty);
      expect(schema.keyNames.toSet().length, schema.keyNames.length);
    });
  });
}
