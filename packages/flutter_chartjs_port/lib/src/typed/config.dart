// Original code, not ported from Chart.js: the root of the typed config.

/// The root of the typed config (Chart.js ADR 0052, sections 1 and 7): the
/// chart type [ChartKind] and the index axis [IndexAxis].
library;

/// The type of a chart or of a dataset: the id of a registered controller,
/// the `type` of a Chart.js config (`core.config.js:93-95`).
///
/// The constants name the 8 controllers of Chart.js. The constructor names
/// a custom controller that the app registers (`Chart.register`). For a
/// type with no registered controller, the chart throws the upstream error
/// `"line" is not a registered controller.`, with the name of the type.
extension type const ChartKind(String name) {
  /// `'bar'`, `BarController`.
  static const ChartKind bar = ChartKind('bar');

  /// `'line'`, `LineController`.
  static const ChartKind line = ChartKind('line');

  /// `'scatter'`, `ScatterController`.
  static const ChartKind scatter = ChartKind('scatter');

  /// `'bubble'`, `BubbleController`.
  static const ChartKind bubble = ChartKind('bubble');

  /// `'pie'`, `PieController`.
  static const ChartKind pie = ChartKind('pie');

  /// `'doughnut'`, `DoughnutController`.
  static const ChartKind doughnut = ChartKind('doughnut');

  /// `'polarArea'`, `PolarAreaController`.
  static const ChartKind polarArea = ChartKind('polarArea');

  /// `'radar'`, `RadarController`.
  static const ChartKind radar = ChartKind('radar');
}

/// The index axis of a chart or of a dataset: the `indexAxis` option. The
/// option value is the [name].
///
/// The index axis holds the labels, and the value axis the data. Thus [x]
/// gives vertical bars, and [y] gives horizontal bars
/// (`docs/charts/bar.md`, "Horizontal Bar Chart").
enum IndexAxis {
  /// `'x'`: the labels on the x axis.
  x,

  /// `'y'`: the labels on the y axis.
  y,
}
