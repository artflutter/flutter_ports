// Original code, not ported from Chart.js: realistic inputs for the benchmarks.

/// Inputs that mirror what Chart.js builds for a bar chart: the registered
/// bar defaults, the option scopes of a bar element, a chart config with
/// three datasets of 100 points, and the data contexts.
///
/// The configs are typed `ChartConfig` objects, lowered to their option
/// scopes by `ChartConfigLowering` as a `ChartView` lowers them (Chart.js
/// ADRs 0052 and 0054). The plugin options are the option objects of
/// `pluginOptions` (Chart.js ADRs 0192, 0193 and 0197).
///
/// The scope list is the one that `Config.getOptionScopes` builds for
/// `datasetElementScopeKeys('bar', 'bar')` (`core.config.js:252`, `:296`):
/// the dataset, the chart options, `overrides.bar`, `defaults.datasets.bar`,
/// `defaults.elements.bar`, `defaults` and `descriptors`.
library;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

bool _registered = false;

/// Registers the bar controller and the bar element once:
/// `registry.add(BarController, BarElement)` writes their `defaults`, the
/// element `defaultRoutes` and the controller `overrides` into the defaults
/// (`core.registry.js`, `core.typedRegistry.js:69-93`).
void registerBarDefaults() {
  if (_registered) return;
  _registered = true;
  Chart.register([BarController.jsClass, BarElement.jsClass]);
}

/// The data of a bar dataset: 100 values.
DatasetData _barData() =>
    DatasetData.values([for (var i = 0; i < 100; i++) (i * 7 % 50).toDouble()]);

/// A dataset with static options.
BarDataset staticBarDataset(int index) => BarDataset(
  label: 'Dataset $index',
  data: _barData(),
  backgroundColor: const ChartValue.constant(
    ChartPaint.solid(Color.fromRGBO(255, 99, 132, 0.5)),
  ),
  borderColor: const ChartValue.constant(
    ChartPaint.solid(Color.fromRGBO(255, 99, 132, 1)),
  ),
  borderWidth: 1,
);

/// A dataset with scriptable and indexable options, as Chart.js samples
/// write them: a function of the context for `backgroundColor`, a function
/// of the context and the options for `borderWidth`, and an array for
/// `borderColor`.
BarDataset scriptableBarDataset(int index) => BarDataset(
  label: 'Dataset $index',
  data: _barData(),
  backgroundColor: ChartValue.resolver(
    (ctx) => (ctx.dataIndex ?? 1).isEven
        ? const ChartPaint.solid(Color.fromRGBO(255, 99, 132, 0.5))
        : const ChartPaint.solid(Color.fromRGBO(54, 162, 235, 0.5)),
  ),
  borderColor: const ChartValue.indexed([
    ChartPaint.solid(Color(0xffff6384)),
    ChartPaint.solid(Color(0xff36a2eb)),
    ChartPaint.solid(Color(0xffffce56)),
  ]),
  // The typed API has no function form of `borderWidth`: the function of
  // the context and the options goes through `extra`.
  extra: {
    'borderWidth': (ScriptableContext ctx, Object? options) =>
        ctx.active ? 2.0 : 1.0,
  },
);

/// A bar chart config with three [datasets] (by default the static ones),
/// 100 labels, scales and plugin options.
ChartConfig barChart([List<BarDataset>? datasets]) => ChartConfig(
  datasets: datasets ?? [for (var d = 0; d < 3; d++) staticBarDataset(d)],
  labels: [for (var i = 0; i < 100; i++) 'Label $i'],
  responsive: true,
  maintainAspectRatio: false,
  indexAxis: .x,
  scales: const [
    CategoryAxis(
      .x,
      grid: AxisGrid(display: false),
      ticks: AxisTicks(maxRotation: 0, autoSkip: true),
    ),
    LinearAxis(
      .y,
      beginAtZero: true,
      ticks: AxisTicks(
        stepSize: 10,
        font: .constant(TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
      title: AxisTitle(display: true, text: ['Value']),
    ),
  ],
  pluginOptions: const [
    LegendOptions(
      position: ChartPosition.top,
      labels: LegendLabelOptions(usePointStyle: true, boxWidth: 12),
    ),
    TitleOptions(display: true, text: ['Bar chart']),
    TooltipOptions(
      mode: IndexInteractionMode(),
      intersect: false,
      padding: EdgeInsets.symmetric(vertical: 6),
    ),
  ],
  animation: const ChartAnimation(
    duration: Duration(milliseconds: 400),
    easing: Curves.easeOutQuart,
  ),
);

/// The root scope of [config], as a `ChartView` lowers it.
ChartConfigurationScope lowerConfig(ChartConfig config) =>
    ChartConfigLowering(config).lower();

/// The root scope of the bar chart config with three datasets of 100
/// points.
ChartConfigurationScope barChartConfig() => lowerConfig(barChart());

/// The `options` scope of the bar chart config.
ChartOptionsScope barChartOptions() =>
    barChartConfig().optionsCell!.raw! as ChartOptionsScope;

/// The scope of the first dataset of [config].
Object datasetScopeOf(ChartConfigurationScope config) {
  final data = config.dataCell!.raw! as ChartDataScope;
  final datasets = data.datasetsCell!.raw! as List<Object?>;
  return datasets.first!;
}

/// The scope of a dataset with static options and the `options` scope of
/// its bar chart.
({Object dataset, ChartOptionsScope options}) staticBarScopes() =>
    _scopes(staticBarDataset(0));

/// The scope of a dataset with scriptable and indexable options and the
/// `options` scope of its bar chart.
({Object dataset, ChartOptionsScope options}) scriptableBarScopes() =>
    _scopes(scriptableBarDataset(0));

({Object dataset, ChartOptionsScope options}) _scopes(BarDataset dataset) {
  final config = lowerConfig(barChart([dataset]));
  return (
    dataset: datasetScopeOf(config),
    options: config.optionsCell!.raw! as ChartOptionsScope,
  );
}

/// The option scopes of a bar element of [scopes] (`core.config.js:296`,
/// `getOptionScopes`).
List<Object?> barElementScopes(
  ({Object dataset, ChartOptionsScope options}) scopes,
) {
  registerBarDefaults();
  return <Object?>[
    scopes.dataset,
    scopes.options,
    overrides['bar'],
    jsGet(defaults['datasets'], 'bar'),
    jsGet(defaults['elements'], 'bar'),
    defaults,
    descriptors,
  ];
}

/// The option names of a bar element: `Object.keys(defaults.elements.bar)`
/// (`core.datasetController.js:817`) and the three dataset options of the
/// bar ruler.
List<String> barOptionNames() {
  registerBarDefaults();
  return <String>[
    ...jsObjectKeys(jsGet(defaults['elements'], 'bar')),
    'barPercentage',
    'categoryPercentage',
    'grouped',
  ];
}

/// The chart context, the dataset context and the data contexts of
/// [count] elements (`core.controller.js` `getContext`,
/// `core.datasetController.js:96-121`).
List<ScriptableContext> dataContexts(int count) {
  final chartContext = ScriptableChartContext(BenchChart());
  final datasetContext = ScriptableContext.dataset(chartContext, 0)
    ..dataset = 'dataset';
  return <ScriptableContext>[
    for (var i = 0; i < count; i++)
      ScriptableContext.data(datasetContext, i, null)
        ..parsed = <String, Object?>{'x': i.toDouble(), 'y': 1.0}
        ..raw = 1.0,
  ];
}

/// A chart with no members: the `chart` of a context of a benchmark.
final class BenchChart() implements IChart {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
