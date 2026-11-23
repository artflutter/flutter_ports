// Original code, not ported from Chart.js: the typed config value semantics.
@TestOn('vm')
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart'
    show DiagnosticLevel, Diagnosticable, DiagnosticsNode, ValueKey;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/dataset_copy.dart';

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
ChartPaint _colorFor(ScriptableContext context) => const ChartPaint.solid(_red);

/// Another scriptable color.
ChartPaint _otherFor(ScriptableContext context) =>
    const ChartPaint.solid(_blue);

/// A scriptable point radius.
double _radiusFor(ScriptableContext context) => 3;

/// A scriptable point style.
PointStyle _styleFor(ScriptableContext context) => const RectPointStyle();

/// A tooltip label callback.
List<String>? _tooltipLabel(TooltipModel tooltip, TooltipItem item) => null;

/// A top-level legend handler: its tear-off is equal at each build.
void _legendClick(ChartEvent event, LegendItem item, LegendElement legend) {}

/// A top-level legend filter: its tear-off is equal at each build.
bool _legendFilter(LegendItem item, Object data) => true;

/// A tooltip script that changes nothing.
TooltipOptions? _tooltipScript(
  ScriptableTooltipContext context,
  TooltipOptions options,
) => null;

/// A tick callback.
List<String>? _format(Scale scale, double value, int index, List<Tick> ticks) =>
    null;

/// The parameter names of [Dataset] after `data` and `points`.
const List<String> _style = [
  'hidden',
  'order',
  'clip',
  'backgroundColor',
  'borderColor',
  'borderWidth',
  'hoverBackgroundColor',
  'hoverBorderColor',
  'hoverBorderWidth',
  'shadow',
  'tooltipCallbacks',
];

/// The parameter names of the line style.
const List<String> _lineStyle = [
  'fill',
  'tension',
  'borderDash',
  'borderCapStyle',
  'borderJoinStyle',
  'spanGaps',
  'showLine',
  'stepped',
  'cubicInterpolationMode',
  'segment',
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
      ..._style,
      'xAxis',
      'yAxis',
      'stack',
      'indexAxis',
      'borderRadius',
      'barPercentage',
      'categoryPercentage',
      'barThickness',
      'maxBarThickness',
      'minBarLength',
      'grouped',
      'borderSkipped',
      'extra',
    ],
  ),
  (
    LineDataset(),
    [
      'key',
      'label',
      'data',
      ..._style,
      'xAxis',
      'yAxis',
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
      ..._style,
      'xAxis',
      'yAxis',
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
      'data',
      ..._style,
      'xAxis',
      'yAxis',
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
      const a = BarDataset(label: 'A', data: .values([1, 2]));
      const b = BarDataset(label: 'A', data: .values([1, 2]));
      expect(identical(a, b), isTrue);
    });

    test('equal parameters give == datasets with one hash code', () {
      final data = <num?>[1, 2];
      final points = [DataPoint(1, 2)];
      _expectEqual(
        BarDataset(
          key: const ValueKey('a'),
          label: 'A',
          data: .values(data),
          backgroundColor: const ChartValue.constant(.solid(_red)),
          borderColor: const ChartValue.resolver(_colorFor),
          extra: const {'clip': ChartClip.all(5)},
        ),
        BarDataset(
          key: const ValueKey('a'),
          label: 'A',
          data: .values(data),
          backgroundColor: const ChartValue.constant(.solid(_red)),
          borderColor: const ChartValue.resolver(_colorFor),
          extra: const {'clip': ChartClip.all(5)},
        ),
      );
      _expectEqual(
        LineDataset(data: .points(points), fill: const .toValue(2)),
        LineDataset(data: .points(points), fill: const .toValue(2)),
      );
    });

    test('a data List compares by identity', () {
      expect(
        BarDataset(data: .values(_runtime([1, 2]))),
        isNot(BarDataset(data: .values(_runtime([1, 2])))),
      );
      expect(
        LineDataset(data: .points([DataPoint(1, 2)])),
        isNot(LineDataset(data: .points([DataPoint(1, 2)]))),
      );
    });

    test('a style List compares by its items', () {
      _expectEqual(
        BarDataset(
          backgroundColor: ChartValue.indexed(
            _runtime([
              const ChartPaint.solid(_red),
              const ChartPaint.solid(_blue),
            ]),
          ),
        ),
        BarDataset(
          backgroundColor: ChartValue.indexed(
            _runtime([
              const ChartPaint.solid(_red),
              const ChartPaint.solid(_blue),
            ]),
          ),
        ),
      );
      _expectEqual(
        LineDataset(
          borderColor: ChartValue.indexed(
            _runtime([const ChartPaint.solid(_red)]),
          ),
          borderDash: _runtime([4, 2]),
        ),
        LineDataset(
          borderColor: ChartValue.indexed(
            _runtime([const ChartPaint.solid(_red)]),
          ),
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
        const BarDataset(backgroundColor: ChartValue.resolver(_colorFor)),
        const BarDataset(backgroundColor: ChartValue.resolver(_colorFor)),
      );
      expect(
        const BarDataset(backgroundColor: ChartValue.resolver(_colorFor)),
        isNot(
          const BarDataset(backgroundColor: ChartValue.resolver(_otherFor)),
        ),
      );
      expect(
        BarDataset(
          backgroundColor: ChartValue.resolver(
            (context) => const ChartPaint.solid(_red),
          ),
        ),
        isNot(
          BarDataset(
            backgroundColor: ChartValue.resolver(
              (context) => const ChartPaint.solid(_red),
            ),
          ),
        ),
      );
    });

    test('a point radius and a point style compare by their values', () {
      for (final make
          in <Dataset Function(ChartValue<double>?, ChartValue<PointStyle>?)>[
            (r, s) =>
                LineDataset(pointRadius: r, pointHoverRadius: r, pointStyle: s),
            (r, s) => ScatterDataset(
              pointRadius: r,
              pointHoverRadius: r,
              pointStyle: s,
            ),
            (r, s) => RadarDataset(
              pointRadius: r,
              pointHoverRadius: r,
              pointStyle: s,
            ),
          ]) {
        _expectEqual(
          make(
            .constant(_runtime(3)),
            .constant(_runtime(const RectPointStyle())),
          ),
          make(
            .constant(_runtime(3)),
            .constant(_runtime(const RectPointStyle())),
          ),
        );
        expect(
          make(const .constant(3), null),
          isNot(make(const .constant(4), null)),
        );
        expect(
          make(null, const .constant(RectPointStyle())),
          isNot(make(null, const .constant(CirclePointStyle()))),
        );
        _expectEqual(
          make(
            .indexed(_runtime([0, 4, 0])),
            .indexed(
              _runtime([const CirclePointStyle(), const RectPointStyle()]),
            ),
          ),
          make(
            .indexed(_runtime([0, 4, 0])),
            .indexed(
              _runtime([const CirclePointStyle(), const RectPointStyle()]),
            ),
          ),
        );
        expect(
          make(.indexed(_runtime([0, 4])), null),
          isNot(make(.indexed(_runtime([4, 0])), null)),
        );
        expect(
          make(const .constant(3), null),
          isNot(make(const .indexed([3]), null)),
          reason: 'the variant takes part',
        );
        _expectEqual(
          make(const .resolver(_radiusFor), const .resolver(_styleFor)),
          make(const .resolver(_radiusFor), const .resolver(_styleFor)),
        );
        expect(
          make(.resolver((context) => 3), null),
          isNot(make(.resolver((context) => 3), null)),
        );
      }
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

    test('borderSkipped compares by its value', () {
      _expectEqual(
        BarDataset(borderSkipped: _runtime(BorderSkip.none)),
        const BarDataset(borderSkipped: BorderSkip.none),
      );
      expect(
        const BarDataset(borderSkipped: BorderSkip.none),
        isNot(const BarDataset(borderSkipped: BorderSkip.all)),
      );
      expect(
        const BarDataset(borderSkipped: BorderSkip.start),
        isNot(const BarDataset()),
      );
      _expectEqual(
        BarElementStyle(borderSkipped: _runtime(BorderSkip.left)),
        const BarElementStyle(borderSkipped: BorderSkip.left),
      );
      expect(
        const BarElementStyle(borderSkipped: BorderSkip.left),
        isNot(const BarElementStyle(borderSkipped: BorderSkip.right)),
      );
      expect(
        const BarElementStyle().copyWith(borderSkipped: BorderSkip.all),
        const BarElementStyle(borderSkipped: BorderSkip.all),
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
      final bar = BarDataset(data: .values(data), borderRadius: 4, stack: 's');
      final copy = bar.copyWith(grouped: false);
      expect((copy.data! as DatasetValues).values, same(data));
      expect([copy.borderRadius, copy.stack, copy.grouped], [4, 's', false]);
      final skipped = copy.copyWith(borderSkipped: BorderSkip.none);
      expect(
        [skipped.grouped, skipped.borderSkipped],
        [false, BorderSkip.none],
      );
      final doughnut = const DoughnutDataset(cutout: PercentRadius(70))
          .copyWith(rotation: 90);
      expect(
        [doughnut.cutout, doughnut.rotation],
        [const PercentRadius(70), 90],
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
        backgroundColor: ChartValue.indexed([ChartPaint.solid(_red)]),
        borderColor: ChartValue.resolver(_colorFor),
      );
      final shown = [
        for (final property in _properties(dataset))
          if (property.level != DiagnosticLevel.fine) property.name,
      ];
      expect(shown, ['label', 'backgroundColor', 'borderColor']);
      expect(dataset.toString(), startsWith('BarDataset#'));
      const paintStart = 'ChartPaint.solid(Color(';
      expect(
        dataset.toString(),
        contains('(label: A, backgroundColor: ChartValue.indexed([$paintStart'),
      );
    });

    test('a DatasetData compares its List by identity', () {
      final values = <num?>[1, 2];
      _expectEqual(DatasetData.values(values), DatasetData.values(values));
      expect(
        DatasetData.values(values),
        isNot(DatasetData.values(_runtime(<num?>[1, 2]))),
      );
      final points = [DataPoint(1, 2)];
      _expectEqual(DatasetData.points(points), DatasetData.points(points));
      expect(
        DatasetData.points(points),
        isNot(DatasetData.points([DataPoint(1, 2)])),
      );
      // The two forms differ also around one List.
      final empty = <Never>[];
      expect(DatasetData.values(empty), isNot(DatasetData.points(empty)));
    });

    test('a new DatasetData around the same List gives == datasets', () {
      final values = <num?>[1, 2];
      _expectEqual(
        LineDataset(data: .values(values)),
        LineDataset(data: .values(values)),
      );
      final points = [DataPoint(1, 2)];
      _expectEqual(
        ScatterDataset(data: .points(points)),
        ScatterDataset(data: .points(points)),
      );
    });

    test('chartData gives the List of either form by reference', () {
      final values = <num?>[1, null];
      final points = [DataPoint(1, 2)];
      expect(
        lowerDataset(
          BarDataset(data: .values(values)),
          ChartKind.bar,
        ).ownCell(OptionKey.data)!.raw,
        same(values),
      );
      expect(
        lowerDataset(
          LineDataset(data: .points(points)),
          ChartKind.line,
        ).ownCell(OptionKey.data)!.raw,
        same(points),
      );
    });

    test('a DatasetData shows its form and its List', () {
      expect(
        const DatasetData.values([1, null]).toString(),
        'DatasetData.values([1, null])',
      );
      expect(const DatasetData.points([]).toString(), 'DatasetData.points([])');
    });
  });

  group('the config, the axes and the groups', () {
    test('a const config is canonical', () {
      const a = ChartConfig(
        datasets: [
          BarDataset(data: .values([1])),
        ],
        scales: [LinearAxis(.y, beginAtZero: true)],
        pluginOptions: [LegendOptions(display: false)],
      );
      const b = ChartConfig(
        datasets: [
          BarDataset(data: .values([1])),
        ],
        scales: [LinearAxis(.y, beginAtZero: true)],
        pluginOptions: [LegendOptions(display: false)],
      );
      expect(identical(a, b), isTrue);
    });

    test('a config built twice is ==, with new Lists of datasets', () {
      final data = <num?>[1, 2];
      final labels = <Object>['a', 'b'];
      ChartConfig build() => ChartConfig(
        labels: labels,
        datasets: [
          BarDataset(
            data: .values(data),
            backgroundColor: ChartValue.indexed(
              _runtime([const ChartPaint.solid(_red)]),
            ),
          ),
        ],
        scales: [
          _runtime(const CategoryAxis(.x)),
          LinearAxis(.y, min: _runtime(0)),
        ],
        animation: ChartAnimation(onComplete: (details) {}),
        onClick: (_, _, _) {},
        // A top-level tear-off: the options object compares it with `==`.
        pluginOptions: [
          LegendOptions(onClick: _runtime(_legendClick)),
          TooltipOptions(
            callbacks: TooltipCallbacks(label: _runtime(_tooltipLabel)),
          ),
        ],
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
        ChartConfig(datasets: const [BarDataset()], labels: _runtime(['a'])),
        isNot(
          ChartConfig(datasets: const [BarDataset()], labels: _runtime(['a'])),
        ),
      );
      expect(
        ChartConfig(
          datasets: const [BarDataset()],
          plugins: _runtime([Plugin<Object?>(id: 'p')]),
        ),
        isNot(
          ChartConfig(
            datasets: const [BarDataset()],
            plugins: _runtime([Plugin<Object?>(id: 'p')]),
          ),
        ),
      );
    });

    test('the plugins compare by the identity of their items', () {
      final plugin = Plugin<Object?>(id: 'p');
      ChartConfig config(List<Plugin<Object?>> plugins) =>
          ChartConfig(datasets: const [BarDataset()], plugins: plugins);
      _expectEqual(config(_runtime([plugin])), config(_runtime([plugin])));
      expect(
        config(_runtime([plugin])),
        isNot(config(_runtime([Plugin<Object?>(id: 'p')]))),
      );
      expect(
        config(_runtime([plugin])),
        isNot(config(_runtime([plugin, plugin]))),
      );
      expect(
        config(_runtime([plugin])),
        isNot(const ChartConfig(datasets: [BarDataset()])),
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

    test('the events compare by their items', () {
      ChartConfig config(List<String> events) =>
          ChartConfig(datasets: const [BarDataset()], events: events);
      _expectEqual(
        config(_runtime(['click', 'mousemove'])),
        config(_runtime(['click', 'mousemove'])),
      );
      expect(
        config(_runtime(['click'])),
        isNot(config(_runtime(['mousemove']))),
      );
      expect(
        config(_runtime([])),
        isNot(const ChartConfig(datasets: [BarDataset()])),
      );
      expect(
        const ChartConfig(datasets: [BarDataset()]).copyWith(events: ['click']),
        config(_runtime(['click'])),
      );
    });

    test('the disabled plugins compare by their items', () {
      ChartConfig config(List<PluginOff<Plugin<Object?>>> off) =>
          ChartConfig(datasets: const [BarDataset()], disabledPlugins: off);
      _expectEqual(
        config(_runtime([const PluginOff<LegendPlugin>()])),
        config(_runtime([const PluginOff<LegendPlugin>()])),
      );
      expect(
        config(_runtime([const PluginOff<LegendPlugin>()])),
        isNot(config(_runtime([const PluginOff<TitlePlugin>()]))),
      );
      expect(
        config(_runtime([])),
        isNot(const ChartConfig(datasets: [BarDataset()])),
      );
      expect(
        const ChartConfig(datasets: [BarDataset()])
            .copyWith(disabledPlugins: const [PluginOff<LegendPlugin>()]),
        config(_runtime([const PluginOff<LegendPlugin>()])),
      );
    });

    test('offsetAfterAutoskip of a time axis compares with ==', () {
      _expectEqual(
        const TimeAxis(.x).copyWith(offsetAfterAutoskip: true),
        const TimeAxis(.x, offsetAfterAutoskip: true),
      );
      _expectEqual(
        const TimeSeriesAxis(.x).copyWith(offsetAfterAutoskip: true),
        const TimeSeriesAxis(.x, offsetAfterAutoskip: true),
      );
      for (final (on, off, unset) in const <(ChartAxis, ChartAxis, ChartAxis)>[
        (
          TimeAxis(.x, offsetAfterAutoskip: true),
          TimeAxis(.x, offsetAfterAutoskip: false),
          TimeAxis(.x),
        ),
        (
          TimeSeriesAxis(.x, offsetAfterAutoskip: true),
          TimeSeriesAxis(.x, offsetAfterAutoskip: false),
          TimeSeriesAxis(.x),
        ),
      ]) {
        _expectEqual(on.copyWith(), on);
        expect(on, isNot(off));
        expect(off, isNot(unset));
      }
    });

    test('the grid tick length compares by its value', () {
      _expectEqual(
        const AxisGrid(tickLength: 6),
        AxisGrid(tickLength: _runtime(6)),
      );
      expect(
        const AxisGrid(tickLength: 6),
        isNot(const AxisGrid(tickLength: 5)),
      );
      expect(const AxisGrid(tickLength: 6), isNot(const AxisGrid()));
      expect(
        const AxisGrid().copyWith(tickLength: 6),
        const AxisGrid(tickLength: 6),
      );
      expect(
        const AxisGrid(tickLength: 6).copyWith(offset: true).tickLength,
        6,
      );
    });

    test('the scales compare by their entries, in key order', () {
      expect(
        const ChartConfig(
          datasets: [BarDataset()],
          scales: [CategoryAxis(.x), LinearAxis(.y)],
        ),
        isNot(
          const ChartConfig(
            datasets: [BarDataset()],
            scales: [LinearAxis(.y), CategoryAxis(.x)],
          ),
        ),
      );
    });

    test('a callback behind a trampoline compares by its presence', () {
      _expectEqual(
        ChartConfig(datasets: const [BarDataset()], onClick: (_, _, _) {}),
        ChartConfig(datasets: const [BarDataset()], onClick: (_, _, _) {}),
      );
      expect(
        ChartConfig(datasets: const [BarDataset()], onHover: (_, _, _) {}),
        isNot(const ChartConfig(datasets: [BarDataset()])),
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

    group('LegendOptions in pluginOptions', () {
      ChartConfig config(LegendOptions legend) =>
          ChartConfig(datasets: const [BarDataset()], pluginOptions: [legend]);

      test('compare by value', () {
        _expectEqual(
          config(
            LegendOptions(
              textDirection: .rtl,
              reverse: true,
              maxWidth: _runtime(60),
              labels: LegendLabelOptions(
                boxWidth: _runtime(12),
                textAlign: .center,
              ),
              title: LegendTitleOptions(text: _runtime(['T'])),
            ),
          ),
          config(
            const LegendOptions(
              textDirection: .rtl,
              reverse: true,
              maxWidth: 60,
              labels: LegendLabelOptions(boxWidth: 12, textAlign: .center),
              title: LegendTitleOptions(text: ['T']),
            ),
          ),
        );
        for (final changed in [
          const LegendOptions(display: false),
          const LegendOptions(textDirection: .ltr),
          const LegendOptions(reverse: true),
          const LegendOptions(labels: LegendLabelOptions(padding: 8)),
          const LegendOptions(title: LegendTitleOptions(display: true)),
        ]) {
          expect(config(changed), isNot(config(const LegendOptions())));
        }
        expect(
          const ChartConfig(datasets: [BarDataset()]),
          isNot(config(const LegendOptions())),
        );
      });

      test('a new closure is a new value', () {
        expect(
          config(LegendOptions(onLeave: (_, _, _) {})),
          isNot(config(LegendOptions(onLeave: (_, _, _) {}))),
        );
        expect(
          config(LegendOptions(scripted: (context, options) => null)),
          isNot(config(LegendOptions(scripted: (context, options) => null))),
        );
      });

      test('a top-level tear-off is equal', () {
        _expectEqual(
          config(
            const LegendOptions(
              onClick: _legendClick,
              labels: LegendLabelOptions(filter: _legendFilter),
            ),
          ),
          config(
            LegendOptions(
              onClick: _runtime(_legendClick),
              labels: LegendLabelOptions(filter: _runtime(_legendFilter)),
            ),
          ),
        );
      });
    });

    group('TooltipOptions in pluginOptions', () {
      ChartConfig config(TooltipOptions tooltip) =>
          ChartConfig(datasets: const [BarDataset()], pluginOptions: [tooltip]);

      test('compare by value', () {
        _expectEqual(
          config(
            TooltipOptions(
              textDirection: .rtl,
              caretSize: 0,
              caretPadding: _runtime(16),
              bodyAlign: .center,
              animation: const TooltipAnimation(
                duration: Duration(milliseconds: 150),
              ),
            ),
          ),
          config(
            const TooltipOptions(
              textDirection: .rtl,
              caretSize: 0,
              caretPadding: 16,
              bodyAlign: .center,
              animation: TooltipAnimation(
                duration: Duration(milliseconds: 150),
              ),
            ),
          ),
        );
        for (final changed in [
          const TooltipOptions(enabled: false),
          const TooltipOptions(textDirection: .ltr),
          const TooltipOptions(caretPadding: 8),
          const TooltipOptions(bodyAlign: .right),
          const TooltipOptions(animation: TooltipAnimation.off),
        ]) {
          expect(config(changed), isNot(config(const TooltipOptions())));
        }
        expect(
          const ChartConfig(datasets: [BarDataset()]),
          isNot(config(const TooltipOptions())),
        );
      });

      test('a new closure is a new value', () {
        expect(
          config(
            TooltipOptions(
              callbacks: TooltipCallbacks(footer: (tooltip, items) => ['a']),
            ),
          ),
          isNot(
            config(
              TooltipOptions(
                callbacks: TooltipCallbacks(footer: (tooltip, items) => ['a']),
              ),
            ),
          ),
        );
        expect(
          config(TooltipOptions(scripted: (context, options) => null)),
          isNot(config(TooltipOptions(scripted: (context, options) => null))),
        );
      });

      test('a top-level tear-off is equal', () {
        _expectEqual(
          config(
            const TooltipOptions(
              callbacks: TooltipCallbacks(label: _tooltipLabel),
              scripted: _tooltipScript,
            ),
          ),
          config(
            TooltipOptions(
              callbacks: TooltipCallbacks(label: _runtime(_tooltipLabel)),
              scripted: _runtime(_tooltipScript),
            ),
          ),
        );
      });
    });

    test('a tick format compares with ==', () {
      _expectEqual(
        const AxisTicks(callback: _format),
        const AxisTicks(callback: _format),
      );
      expect(
        AxisTicks(callback: (scale, value, index, ticks) => null),
        isNot(AxisTicks(callback: (scale, value, index, ticks) => null)),
      );
    });

    test('animateScale and animateRotate compare by value', () {
      _expectEqual(
        const ChartAnimation(animateScale: true, animateRotate: false),
        ChartAnimation(animateScale: _runtime(true), animateRotate: false),
      );
      expect(
        const ChartAnimation(animateScale: true),
        isNot(const ChartAnimation(animateScale: false)),
      );
      expect(
        const ChartAnimation(animateRotate: true),
        isNot(const ChartAnimation()),
      );
      expect(
        const ChartAnimation().copyWith(
          animateScale: true,
          animateRotate: true,
        ),
        const ChartAnimation(animateScale: true, animateRotate: true),
      );
      expect(
        ChartAnimation.none.copyWith(animateScale: true),
        same(ChartAnimation.none),
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
        CategoryAxis(.x),
        LinearAxis(.y),
        LogarithmicAxis(.y),
        TimeAxis(.x),
        TimeSeriesAxis(.x),
        RadialLinearAxis(),
      ]) {
        _expectEqual(axis.copyWith(), axis);
        final changed = axis.copyWith(reverse: true);
        expect(changed.runtimeType, axis.runtimeType);
        expect(changed.reverse, isTrue);
        expect(changed, isNot(axis));
      }
      // The border (Chart.js ADR 0141): an AxisBorder for a cartesian axis, a
      // RadialAxisBorder for the radial axis, compared with ==.
      const line = LinearAxis(.y, border: AxisBorder(width: 2, dash: [4, 4]));
      _expectEqual(line.copyWith(), line);
      _expectEqual(
        line,
        const LinearAxis(.y, border: AxisBorder(width: 2, dash: [4, 4])),
      );
      expect(
        line.copyWith(border: const AxisBorder(width: 3)).border,
        const AxisBorder(width: 3),
      );
      expect(line, isNot(const LinearAxis(.y, border: AxisBorder(width: 3))));
      const radial = RadialLinearAxis(border: RadialAxisBorder(dash: [2, 2]));
      _expectEqual(radial.copyWith(), radial);
      expect(
        radial.copyWith(border: const RadialAxisBorder(dashOffset: 1)).border,
        const RadialAxisBorder(dashOffset: 1),
      );
      // The display formats of a time axis, compared with ==.
      const time = TimeAxis(
        .x,
        displayFormats: TimeDisplayFormats(day: 'dd MMM'),
      );
      _expectEqual(time.copyWith(), time);
      _expectEqual(
        time,
        const TimeAxis(.x, displayFormats: TimeDisplayFormats(day: 'dd MMM')),
      );
      expect(
        time
            .copyWith(displayFormats: const TimeDisplayFormats(day: 'd'))
            .displayFormats,
        const TimeDisplayFormats(day: 'd'),
      );
      expect(
        time,
        isNot(const TimeAxis(.x, displayFormats: TimeDisplayFormats(day: 'd'))),
      );
      const config = ChartConfig(datasets: [BarDataset()]);
      _expectEqual(config.copyWith(), config);
      expect(config.type, ChartKind.bar);
      expect(
        config.copyWith(datasets: const [LineDataset()]).type,
        ChartKind.line,
      );
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
          const AxisTitle().copyWith(text: ['T']),
        ),
        (
          const TimeDisplayFormats(day: 'dd MMM'),
          const TimeDisplayFormats(day: 'dd MMM').copyWith(),
          const TimeDisplayFormats(day: 'dd MMM').copyWith(hour: 'HH:mm'),
        ),
        (
          const ChartTitle(),
          const ChartTitle().copyWith(),
          const ChartTitle().copyWith(text: ['T']),
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
      expect(names(const ChartConfig(datasets: [BarDataset()])), [
        'datasets',
        'labels',
        'scales',
        'indexAxis',
        'responsive',
        'maintainAspectRatio',
        'aspectRatio',
        'padding',
        'title',
        'subtitle',
        'filler',
        'interaction',
        'animation',
        'animations',
        'transitions',
        'elements',
        'onClick',
        'onHover',
        'events',
        'pluginOptions',
        'plugins',
        'disabledPlugins',
        'extra',
      ]);
      expect(names(const RadialLinearAxis()), [
        'axis',
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
        'pointLabelsCallback',
        'angleLinesDisplay',
        'angleLinesColor',
        'angleLinesLineWidth',
        'ticks',
        'grid',
        'border',
        'title',
        'extra',
      ]);
      for (final axis in const <ChartAxis>[TimeAxis(.x), TimeSeriesAxis(.x)]) {
        expect(names(axis), [
          'axis',
          'display',
          'position',
          'reverse',
          'stacked',
          'min',
          'max',
          'unit',
          'tooltipFormat',
          'displayFormats',
          'offsetAfterAutoskip',
          'bounds',
          'ticks',
          'grid',
          'border',
          'title',
          'extra',
        ]);
      }
      expect(names(ChartAnimation.none).first, 'none');
      expect(
        ChartConfig(
          datasets: const [BarDataset()],
          onClick: (_, _, _) {},
        ).toString(),
        contains('onClick: set'),
      );
    });
  });
}
