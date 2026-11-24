// Original code, not ported from Chart.js: tests of the fixture generator.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/fixture_configs_gen.dart';
import '../../tool/src/fixture_configs.dart';

/// Each text at a color key of [json], at any depth.
Set<String> _colorTexts(Object? json) {
  final texts = <String>{};
  void walk(Object? node) {
    switch (node) {
      case final Map<String, Object?> map:
        for (final MapEntry(:key, :value) in map.entries) {
          if (isColorKey(key)) {
            for (final item in value is List ? value : [value]) {
              if (item is String && item.isNotEmpty) texts.add(item);
            }
          }
          walk(value);
        }
      case final List<Object?> list:
        list.forEach(walk);
    }
  }

  walk(json);
  return texts;
}

/// The `Color` of the source [expression] of [cssColorExpression].
Color _colorOf(String expression) {
  final hex = RegExp(r'^Color\(0x([0-9A-F]{8})\)$').firstMatch(expression);
  if (hex != null) return Color(int.parse(hex[1]!, radix: 16));
  final rgbo = RegExp(r'^Color\.fromRGBO\((\d+), (\d+), (\d+), ([0-9.e-]+)\)$')
      .firstMatch(expression)!;
  return Color.fromRGBO(
    int.parse(rgbo[1]!),
    int.parse(rgbo[2]!),
    int.parse(rgbo[3]!),
    double.parse(rgbo[4]!),
  );
}

void main() {
  test('the Color of each CSS color of fixtures.json is the color of '
      'paintOfCss', () {
    final json = jsonDecode(
      File('doc/upstream/fixtures.json').readAsStringSync(),
    );
    final texts = {
      ..._colorTexts(json),
      ...cssColorNames.keys,
      'transparent',
      'rgba(255, 0, 0, 0.5)',
      'rgba(0,0,0,0.1)',
      '#f008',
      '#ff000080',
    };
    final wrong = <String>[];
    for (final text in texts) {
      final expression = cssColorExpression(text);
      final paint = paintOfCss(text);
      if (expression == null || paint is! SolidChartPaint) {
        wrong.add('$text: $expression, $paint');
      } else if (_colorOf(expression) != paint.color) {
        wrong.add('$text: $expression is not ${paint.color}');
      }
    }
    expect(wrong, isEmpty);
  });

  test('hasMomentPattern finds a parser text and a displayFormats text', () {
    expect(hasMomentPattern({'parser': 'YYYY'}), isTrue);
    expect(
      hasMomentPattern({
        'a': [
          {
            'displayFormats': {'year': 'YYYY'},
          },
        ],
      }),
      isTrue,
    );
    expect(hasMomentPattern({'type': 'line', 'parser': 1}), isFalse);
  });

  test('toIcu changes each moment pattern', () {
    expect(
      toIcu({
        'options': {
          'scales': {
            'x': {
              'time': {
                'parser': 'YYYY-MM',
                'displayFormats': {'year': 'YYYY'},
              },
            },
          },
        },
        'data': {
          'datasets': [
            {
              'parser': 'YYYY',
              'data': ['2017'],
            },
          ],
        },
      }, 'p'),
      {
        'options': {
          'scales': {
            'x': {
              'time': {
                'parser': 'yyyy-MM',
                'displayFormats': {'year': 'yyyy'},
              },
            },
          },
        },
        'data': {
          'datasets': [
            {
              'parser': 'yyyy',
              'data': ['2017'],
            },
          ],
        },
      },
    );
    expect(() => toIcu({'parser': 'MMM D'}, 'p'), throwsFormatException);
  });

  group('FixtureEmitter', () {
    String emit(Map<String, Object?> json, [String path = 'a/b.json']) =>
        FixtureEmitter(path).emit(fixtureValueOf(json) as FixtureMap);

    test('a config with no dataset keeps its Map', () {
      final emitter = FixtureEmitter('a/b.json');
      final source = emitter.emit(
        fixtureValueOf({
          'config': {'type': 'line'},
        }) as FixtureMap,
      );
      expect(source, startsWith('FixtureConfig.map('));
      expect(emitter.mapReason, contains('no data'));
    });

    test('a typed option is a parameter, another one an extra entry', () {
      final emitter = FixtureEmitter('a/b.json');
      final source = emitter.emit(
        fixtureValueOf({
          'config': {
            'type': 'bar',
            'data': {
              'labels': ['a'],
              'datasets': [
                {
                  'data': [1],
                  'borderColor': 'red',
                  'legendHidden': true,
                },
              ],
            },
            'options': {
              'scales': {
                'x': {'display': false},
              },
              'locale': 'de-DE',
            },
          },
        }) as FixtureMap,
      );
      expect(source, contains('BarDataset('));
      expect(
        source,
        contains('borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000)))'),
      );
      expect(source, contains("'legendHidden': true"));
      expect(source, contains('CategoryAxis(CartesianAxis.x,'));
      expect(source, contains('display: ScaleDisplay.off'));
      expect(source, contains("'locale': 'de-DE'"));
      expect(emitter.extras, [
        'Dataset.extra[legendHidden]',
        'ChartConfig.extra[locale]',
      ]);
    });

    test('the axes go to extra when a typed id is not the upstream id', () {
      final source = emit({
        'config': {
          'type': 'line',
          'data': {
            'datasets': [
              {
                'data': [1],
                'yAxisID': 'y2',
              },
            ],
          },
          'options': {
            'scales': {
              'y2': {'position': 'right'},
            },
          },
        },
      });
      expect(source, isNot(contains('LinearAxis')));
      expect(source, contains("'yAxisID': 'y2'"));
      expect(source, contains("'scales': <String, Object?>{"));
    });
  });
}
