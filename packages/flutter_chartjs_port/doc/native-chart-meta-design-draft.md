# ChartMeta — class design draft

```dart
class ChartMeta<C extends DatasetController>({
  required var int index,

  // The dataset of the app: a Map, or the dataset scope of a typed config.
  required final Object? datasetConfig,

  // A new type makes a new meta (core.controller.js:427-430).
  required final String type,

  // getDatasetMeta computes them, and each update writes them again.
  required var String label,
  required var ScaleAxis indexAxis,
  var double order = 0,
}) {
  // The first update writes it. An earlier read throws, as in Chart.js.
  late ChartClip clip;

  // The chart gives ChartMeta<DatasetController> of the app.
  C? controller;

  final List<Element> data = [];
  Element? dataset;

  bool? hidden;
  bool visible = false;

  String? stack;
  StackMode stacked = StackMode.off;

  String? xAxisID;
  String? yAxisID;
  String? rAxisID;
  String? iAxisID;
  String? vAxisID;

  Scale? xScale;
  Scale? yScale;
  Scale? rScale;
  Scale? iScale;
  Scale? vScale;

  List<Object?> parsed = [];
  bool sorted = false;
}

enum StackMode { off, on, single }

class const ChartClip({
  // Null: no clip on that side.
  final double? left,
  final double? top,
  final double? right,
  final double? bottom,
  final bool disabled = false,
});
```

`ChartMeta` is in `lib/src/types/chart_meta.dart`. It replaces the interface `types.ChartMeta`, `types.ChartMetaClip`,
`types.ChartMetaFiller` and the class of `core.controller.dart`.

The meta has only the fields that the core reads. The state of one chart type goes to its controller: a controller
belongs to one meta (`meta.controller`). Chart.js makes the meta before the controller (`core.controller.js:424-448`),
so a controller cannot give a meta subclass without a change to that order.

```dart
// controller.doughnut.js:235 `meta.total`, index.d.ts:374 DoughnutMetaExtensions.
class DoughnutController extends DatasetController {
  double? total;
}

// An app.
final points = chart.getDatasetMeta(0).data;
final total = (chart.getDatasetMeta(0).controller! as DoughnutController).total!;

// An add-on controller: its own state in its own fields, the parse state in the meta.
class FinancialController extends DatasetController {
  double barWidth = 0;

  @override
  void parse(int start, int count) {
    cachedMeta.parsed = parseOhlc(start, count);
    cachedMeta.sorted = true;
  }
}

// A plugin: its state for each dataset in its own Expando.
final _sources = Expando<FillerSource>('filler');
_sources[meta] = source;
```

Removed: `meta['...']`, `meta[...] = ...`, the extras Map, `$filler`, `dataset_` and `meta.total`.
