// Original code, not ported from Chart.js: the typed config value semantics.
@TestOn('vm')
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart'
    show DiagnosticLevel, Diagnosticable, DiagnosticsNode, ValueKey;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0052, sections 1 and 9: each config class is immutable, with
// a `const` constructor, `==`, `hashCode`, `copyWith` and the diagnostics
// from one property list. `==` compares the Lists of the app by identity
// (`data`, `points`, `labels`, `plugins`), the small style Lists and the
// datasets by their items, the `scales` and the `extra` Maps by their
// entries, a function with Dart `==`, and a callback behind a trampoline
// by its presence.
//
// VM only: the typed files import dart:ui and the painting library.

const Color _red = Color(0xFFFF6384);
const Color _blue = Color(0xFF36A2EB);

/// A scriptable color.
Color _colorFor(ChartContext context) => _red;

/// Another scriptable color.
Color _otherFor(ChartContext context) => _blue;

/// A tick format.
String? _format(AxisTickInfo tick) => null;

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
  'pointHoverBackgroundColor',
  'pointHoverBorderColor',
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

  group('the config, the axes and the groups', () {
    test('a const config is canonical', () {
      const a = ChartConfig(
        type: .bar,
        datasets: [
          BarDataset(data: [1]),
        ],
        scales: {'y': LinearAxis(beginAtZero: true)},
        legend: ChartLegend(display: false),
      );
      const b = ChartConfig(
        type: .bar,
        datasets: [
          BarDataset(data: [1]),
        ],
        scales: {'y': LinearAxis(beginAtZero: true)},
        legend: ChartLegend(display: false),
      );
      expect(identical(a, b), isTrue);
    });

    test('a config built twice is ==, with new Lists of datasets', () {
      final data = <num?>[1, 2];
      final labels = <Object>['a', 'b'];
      ChartConfig build() => ChartConfig(
        type: .bar,
        labels: labels,
        datasets: [
          BarDataset(data: data, backgroundColors: _runtime([_red])),
        ],
        scales: {
          'x': _runtime(const CategoryAxis()),
          'y': LinearAxis(min: _runtime(0)),
        },
        legend: ChartLegend(onClick: (details) {}),
        tooltip: ChartTooltip(labelText: (item) => null),
        animation: ChartAnimation(onComplete: (details) {}),
        onClick: (details) {},
        extra: {
          'plugins': {
            'decimation': {'enabled': _runtime(true)},
          },
        },
      );
      _expectEqual(build(), build());
    });

    test('the Lists of the app compare by identity', () {
      expect(
        ChartConfig(type: .bar, datasets: const [], labels: _runtime(['a'])),
        isNot(
          ChartConfig(type: .bar, datasets: const [], labels: _runtime(['a'])),
        ),
      );
      expect(
        ChartConfig(
          type: .bar,
          datasets: const [],
          plugins: _runtime([<String, Object?>{}]),
        ),
        isNot(
          ChartConfig(
            type: .bar,
            datasets: const [],
            plugins: _runtime([<String, Object?>{}]),
          ),
        ),
      );
    });

    test('the plugins compare by the identity of their items', () {
      final plugin = <String, Object?>{'id': 'p'};
      ChartConfig config(List<Map<String, Object?>> plugins) =>
          ChartConfig(type: .bar, datasets: const [], plugins: plugins);
      _expectEqual(config(_runtime([plugin])), config(_runtime([plugin])));
      expect(
        config(_runtime([plugin])),
        isNot(
          config(
            _runtime([
              <String, Object?>{'id': 'p'},
            ]),
          ),
        ),
      );
      expect(
        config(_runtime([plugin])),
        isNot(config(_runtime([plugin, plugin]))),
      );
      expect(
        config(_runtime([plugin])),
        isNot(const ChartConfig(type: .bar, datasets: [])),
      );
    });

    test('the element styles compare by value, a borderDash by its items', () {
      _expectEqual(
        ChartElements(
          line: LineElementStyle(borderDash: _runtime([4.0, 2.0])),
          point: PointElementStyle(radius: _runtime(0)),
        ),
        ChartElements(
          line: LineElementStyle(borderDash: _runtime([4.0, 2.0])),
          point: PointElementStyle(radius: _runtime(0)),
        ),
      );
      expect(
        const ChartElements(bar: BarElementStyle(borderWidth: 1)),
        isNot(const ChartElements(arc: ArcElementStyle(borderWidth: 1))),
      );
    });

    test('the scales compare by their entries, in key order', () {
      expect(
        const ChartConfig(
          type: .bar,
          datasets: [],
          scales: {'x': CategoryAxis(), 'y': LinearAxis()},
        ),
        isNot(
          const ChartConfig(
            type: .bar,
            datasets: [],
            scales: {'y': LinearAxis(), 'x': CategoryAxis()},
          ),
        ),
      );
    });

    test('a callback behind a trampoline compares by its presence', () {
      _expectEqual(
        ChartConfig(type: .bar, datasets: const [], onClick: (details) {}),
        ChartConfig(type: .bar, datasets: const [], onClick: (details) {}),
      );
      expect(
        ChartConfig(type: .bar, datasets: const [], onHover: (details) {}),
        isNot(const ChartConfig(type: .bar, datasets: [])),
      );
      _expectEqual(
        ChartLegend(onLeave: (details) {}),
        ChartLegend(onLeave: (details) {}),
      );
      _expectEqual(
        ChartTooltip(footerText: (items) => 'a'),
        ChartTooltip(footerText: (items) => 'b'),
      );
      _expectEqual(
        ChartAnimation(onProgress: (details) {}),
        ChartAnimation(onProgress: (details) {}),
      );
      expect(
        ChartAnimation(onProgress: (details) {}),
        isNot(const ChartAnimation()),
      );
    });

    test('a tick format compares with ==', () {
      _expectEqual(
        const AxisTicks(format: _format),
        const AxisTicks(format: _format),
      );
      expect(
        AxisTicks(format: (tick) => null),
        isNot(AxisTicks(format: (tick) => null)),
      );
    });

    test('ChartAnimation.none is not an empty animation', () {
      expect(ChartAnimation.none, isNot(const ChartAnimation()));
      expect(ChartAnimation.none.copyWith(), same(ChartAnimation.none));
      expect(
        ChartAnimation.none.copyWith(duration: Duration.zero),
        same(ChartAnimation.none),
      );
    });

    test('copyWith() gives an == object, and a parameter changes', () {
      for (final axis in const <ChartAxis>[
        CategoryAxis(),
        LinearAxis(),
        LogarithmicAxis(),
        TimeAxis(),
        TimeSeriesAxis(),
        RadialLinearAxis(),
      ]) {
        _expectEqual(axis.copyWith(), axis);
        final changed = axis.copyWith(reverse: true);
        expect(changed.runtimeType, axis.runtimeType);
        expect(changed.reverse, isTrue);
        expect(changed, isNot(axis));
      }
      const config = ChartConfig(type: .bar, datasets: []);
      _expectEqual(config.copyWith(), config);
      expect(config.copyWith(type: .line).type, ChartKind.line);
      for (final (object, copy, changed) in <(Object, Object, Object)>[
        (
          const AxisTicks(),
          const AxisTicks().copyWith(),
          const AxisTicks().copyWith(display: false),
        ),
        (
          const AxisGrid(),
          const AxisGrid().copyWith(),
          const AxisGrid().copyWith(offset: true),
        ),
        (
          const AxisTitle(),
          const AxisTitle().copyWith(),
          const AxisTitle().copyWith(text: 'T'),
        ),
        (
          const ChartLegend(),
          const ChartLegend().copyWith(),
          const ChartLegend().copyWith(reverse: true),
        ),
        (
          const ChartTitle(),
          const ChartTitle().copyWith(),
          const ChartTitle().copyWith(text: 'T'),
        ),
        (
          const ChartTooltip(),
          const ChartTooltip().copyWith(),
          const ChartTooltip().copyWith(enabled: false),
        ),
        (
          const ChartInteraction(),
          const ChartInteraction().copyWith(),
          const ChartInteraction().copyWith(intersect: false),
        ),
        (
          const ChartAnimation(),
          const ChartAnimation().copyWith(),
          const ChartAnimation().copyWith(loop: true),
        ),
        (
          const ChartFiller(),
          const ChartFiller().copyWith(),
          const ChartFiller().copyWith(propagate: false),
        ),
        (
          const ChartElements(),
          const ChartElements().copyWith(),
          const ChartElements().copyWith(line: const LineElementStyle()),
        ),
        (
          const PointElementStyle(),
          const PointElementStyle().copyWith(),
          const PointElementStyle().copyWith(radius: 0),
        ),
        (
          const LineElementStyle(),
          const LineElementStyle().copyWith(),
          const LineElementStyle().copyWith(borderWidth: 3),
        ),
        (
          const BarElementStyle(),
          const BarElementStyle().copyWith(),
          const BarElementStyle().copyWith(borderRadius: 4),
        ),
        (
          const ArcElementStyle(),
          const ArcElementStyle().copyWith(),
          const ArcElementStyle().copyWith(spacing: 2),
        ),
      ]) {
        _expectEqual(copy, object);
        expect(changed, isNot(object));
      }
    });

    test('the diagnostics name each parameter in parameter order', () {
      List<String> names(Diagnosticable object) => [
        for (final property in object.toDiagnosticsNode().getProperties())
          property.name!,
      ];
      expect(names(const ChartConfig(type: .bar, datasets: [])), [
        'type',
        'datasets',
        'labels',
        'scales',
        'indexAxis',
        'responsive',
        'maintainAspectRatio',
        'aspectRatio',
        'padding',
        'legend',
        'title',
        'subtitle',
        'tooltip',
        'filler',
        'interaction',
        'animation',
        'elements',
        'onClick',
        'onHover',
        'plugins',
        'extra',
      ]);
      expect(names(const RadialLinearAxis()), [
        'display',
        'position',
        'reverse',
        'stacked',
        'min',
        'max',
        'suggestedMin',
        'suggestedMax',
        'beginAtZero',
        'startAngle',
        'pointLabelsDisplay',
        'pointLabelsColor',
        'pointLabelsFont',
        'pointLabelsPadding',
        'angleLinesDisplay',
        'angleLinesColor',
        'angleLinesLineWidth',
        'ticks',
        'grid',
        'title',
        'extra',
      ]);
      expect(names(const ChartLegend()), [
        'display',
        'position',
        'align',
        'reverse',
        'labelColor',
        'labelFont',
        'boxWidth',
        'boxHeight',
        'labelPadding',
        'usePointStyle',
        'onClick',
        'onHover',
        'onLeave',
        'extra',
      ]);
      expect(names(ChartAnimation.none).first, 'none');
      expect(
        ChartConfig(
          type: .bar,
          datasets: const [],
          onClick: (details) {},
        ).toString(),
        contains('onClick: set'),
      );
    });
  });
}
