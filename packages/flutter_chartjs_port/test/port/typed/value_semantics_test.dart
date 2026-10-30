// Original code, not ported from Chart.js: the typed config value semantics.
@TestOn('vm')
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart'
    show DiagnosticLevel, DiagnosticsNode, ValueKey;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0052, sections 1 and 9: each config class is immutable, with
// a `const` constructor, `==`, `hashCode`, `copyWith` and the diagnostics
// from one property list. `==` compares the Lists of the app by identity
// (`data`, `points`), the small style Lists by their items, a function with
// Dart `==` and the `extra` Maps by their entries.
//
// VM only: the typed files import dart:ui and the painting library.

const Color _red = Color(0xFFFF6384);
const Color _blue = Color(0xFF36A2EB);

/// A scriptable color.
Color _colorFor(ChartContext context) => _red;

/// Another scriptable color.
Color _otherFor(ChartContext context) => _blue;

/// The parameter names of [Dataset] after `data` and `points`.
const List<String> _style = [
  'hidden',
  'order',
  'backgroundColor',
  'backgroundColors',
  'backgroundColorFor',
  'borderColor',
  'borderColors',
  'borderColorFor',
  'borderWidth',
  'hoverBackgroundColor',
  'hoverBorderColor',
  'hoverBorderWidth',
];

/// The parameter names of the line style.
const List<String> _lineStyle = [
  'fill',
  'tension',
  'borderDash',
  'spanGaps',
  'showLine',
  'stepped',
  'pointRadius',
  'pointHoverRadius',
  'pointStyle',
  'pointBackgroundColor',
  'pointBorderColor',
  'pointBorderWidth',
];

/// The parameter names of the pie and the doughnut arcs.
const List<String> _arcs = [
  'offset',
  'hoverOffset',
  'spacing',
  'weight',
  'circumference',
  'rotation',
  'cutout',
  'radius',
];

/// Each dataset class without parameters, with the names of its
/// parameters in parameter order.
const List<(Dataset, List<String>)> _datasets = [
  (
    BarDataset(),
    [
      'key',
      'label',
      'data',
      'points',
      ..._style,
      'xAxisID',
      'yAxisID',
      'stack',
      'indexAxis',
      'borderRadius',
      'barPercentage',
      'categoryPercentage',
      'barThickness',
      'maxBarThickness',
      'minBarLength',
      'grouped',
      'extra',
    ],
  ),
  (
    LineDataset(),
    [
      'key',
      'label',
      'data',
      'points',
      ..._style,
      'xAxisID',
      'yAxisID',
      'stack',
      'indexAxis',
      ..._lineStyle,
      'extra',
    ],
  ),
  (
    ScatterDataset(),
    [
      'key',
      'label',
      'data',
      'points',
      ..._style,
      'xAxisID',
      'yAxisID',
      'stack',
      ..._lineStyle,
      'extra',
    ],
  ),
  (
    BubbleDataset(),
    [
      'key',
      'label',
      'points',
      ..._style,
      'xAxisID',
      'yAxisID',
      'radius',
      'hoverRadius',
      'pointStyle',
      'extra',
    ],
  ),
  (PieDataset(), ['key', 'label', 'data', ..._style, ..._arcs, 'extra']),
  (DoughnutDataset(), ['key', 'label', 'data', ..._style, ..._arcs, 'extra']),
  (
    PolarAreaDataset(),
    [
      'key',
      'label',
      'data',
      ..._style,
      'offset',
      'hoverOffset',
      'spacing',
      'extra',
    ],
  ),
  (RadarDataset(), ['key', 'label', 'data', ..._style, ..._lineStyle, 'extra']),
];

/// The diagnostics properties of [object].
List<DiagnosticsNode> _properties(Dataset object) =>
    object.toDiagnosticsNode().getProperties();

/// [value], as a value that is not a constant.
T _runtime<T>(T value) => value;

/// Expects [a] and [b] to be `==` with the same hash code.
void _expectEqual(Object a, Object b) {
  expect(a, b);
  expect(a.hashCode, b.hashCode);
}

void main() {
  group('the datasets', () {
    test('a const dataset is canonical', () {
      const a = BarDataset(label: 'A', data: [1, 2]);
      const b = BarDataset(label: 'A', data: [1, 2]);
      expect(identical(a, b), isTrue);
    });

    test('equal parameters give == datasets with one hash code', () {
      final data = <num?>[1, 2];
      final points = [DataPoint(1, 2)];
      _expectEqual(
        BarDataset(
          key: const ValueKey('a'),
          label: 'A',
          data: data,
          backgroundColor: _red,
          borderColorFor: _colorFor,
          extra: const {'clip': 5},
        ),
        BarDataset(
          key: const ValueKey('a'),
          label: 'A',
          data: data,
          backgroundColor: _red,
          borderColorFor: _colorFor,
          extra: const {'clip': 5},
        ),
      );
      _expectEqual(
        LineDataset(points: points, fill: const .value(2)),
        LineDataset(points: points, fill: const .value(2)),
      );
    });

    test('a data List compares by identity', () {
      expect(
        BarDataset(data: _runtime([1, 2])),
        isNot(BarDataset(data: _runtime([1, 2]))),
      );
      expect(
        LineDataset(points: [DataPoint(1, 2)]),
        isNot(LineDataset(points: [DataPoint(1, 2)])),
      );
    });

    test('a style List compares by its items', () {
      _expectEqual(
        BarDataset(backgroundColors: _runtime([_red, _blue])),
        BarDataset(backgroundColors: _runtime([_red, _blue])),
      );
      _expectEqual(
        LineDataset(
          borderColors: _runtime([_red]),
          borderDash: _runtime([4, 2]),
        ),
        LineDataset(
          borderColors: _runtime([_red]),
          borderDash: _runtime([4, 2]),
        ),
      );
      expect(
        LineDataset(borderDash: _runtime([4, 2])),
        isNot(LineDataset(borderDash: _runtime([2, 4]))),
      );
    });

    test('a function compares with ==', () {
      _expectEqual(
        const BarDataset(backgroundColorFor: _colorFor),
        const BarDataset(backgroundColorFor: _colorFor),
      );
      expect(
        const BarDataset(backgroundColorFor: _colorFor),
        isNot(const BarDataset(backgroundColorFor: _otherFor)),
      );
      expect(
        BarDataset(backgroundColorFor: (context) => _red),
        isNot(BarDataset(backgroundColorFor: (context) => _red)),
      );
    });

    test('extra compares by its entries, in key order', () {
      final list = <Object?>[1];
      _expectEqual(
        BarDataset(
          extra: {
            'a': 1,
            'b': {'c': list},
          },
        ),
        BarDataset(
          extra: {
            'a': 1,
            'b': {'c': list},
          },
        ),
      );
      expect(
        const BarDataset(extra: {'a': 1, 'b': 2}),
        isNot(const BarDataset(extra: {'b': 2, 'a': 1})),
      );
      expect(
        BarDataset(
          extra: {
            'a': _runtime([1]),
          },
        ),
        isNot(
          BarDataset(
            extra: {
              'a': _runtime([1]),
            },
          ),
        ),
        reason: 'a List in extra goes by reference',
      );
    });

    test('the key and the class take part', () {
      expect(
        const BarDataset(key: ValueKey('a')),
        isNot(const BarDataset(key: ValueKey('b'))),
      );
      expect(const PieDataset(), isNot(const DoughnutDataset()));
      expect(const LineDataset(), isNot(const ScatterDataset()));
    });

    test('copyWith() gives an == dataset, and each parameter changes', () {
      for (final (dataset, _) in _datasets) {
        _expectEqual(dataset.copyWith(), dataset);
        final labeled = dataset.copyWith(label: 'B', hidden: true);
        expect(labeled.runtimeType, dataset.runtimeType);
        expect([labeled.label, labeled.hidden], ['B', true]);
        expect(labeled, isNot(dataset));
        expect(labeled.copyWith(order: 2).label, 'B');
      }
    });

    test('copyWith of a class keeps its own parameters', () {
      final data = <num?>[1];
      final bar = BarDataset(data: data, borderRadius: 4, stack: 's');
      final copy = bar.copyWith(grouped: false);
      expect(copy.data, same(data));
      expect([copy.borderRadius, copy.stack, copy.grouped], [4, 's', false]);
      final doughnut = const DoughnutDataset(
        cutout: .percent(70),
      ).copyWith(rotation: 90);
      expect(
        [doughnut.cutout, doughnut.rotation],
        [
          const ChartLength.percent(70),
          90,
        ],
      );
    });

    test('the diagnostics name each parameter in parameter order', () {
      for (final (dataset, names) in _datasets) {
        expect(
          [for (final property in _properties(dataset)) property.name],
          names,
          reason: '${dataset.runtimeType}',
        );
      }
    });

    test('the diagnostics show the parameters that are set', () {
      const dataset = BarDataset(
        label: 'A',
        backgroundColors: [_red],
        borderColorFor: _colorFor,
      );
      final shown = [
        for (final property in _properties(dataset))
          if (property.level != DiagnosticLevel.fine) property.name,
      ];
      expect(shown, ['label', 'backgroundColors', 'borderColorFor']);
      expect(dataset.toString(), startsWith('BarDataset#'));
      expect(
        dataset.toString(),
        contains('(label: A, backgroundColors: [Color('),
      );
    });

    test('the constructor asserts one form of each color', () {
      expect(
        () => BarDataset(backgroundColor: _red, backgroundColors: const [_red]),
        throwsAssertionError,
      );
      expect(
        () => LineDataset(
          backgroundColors: const [_red],
          backgroundColorFor: _colorFor,
        ),
        throwsAssertionError,
      );
      expect(
        () => PieDataset(borderColor: _red, borderColorFor: _colorFor),
        throwsAssertionError,
      );
      expect(
        () => RadarDataset(
          borderColors: const [_red],
          borderColorFor: _colorFor,
        ),
        throwsAssertionError,
      );
    });

    test('the constructor asserts data or points', () {
      expect(
        () => BarDataset(data: const [1], points: [DataPoint(1, 2)]),
        throwsAssertionError,
      );
      expect(
        () => ScatterDataset(data: const [1], points: [DataPoint(1, 2)]),
        throwsAssertionError,
      );
    });
  });
}
