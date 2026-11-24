// Original code, not ported from Chart.js: the key check of the typed API.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart' show EdgeInsets, TextStyle;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0052, section 13: the key check. A typed key that lowers to
// a path that Chart.js does not read has no effect, so each lowered path of
// a config with every typed parameter is a path of the defaults inventory
// of tool 4 (`defaults.values.defaults` and `.overrides` of
// doc/upstream/manifest.json), or a row of the allowlist below: the keys
// with no default, each with the line of `src/types/index.d.ts` that
// declares it.
//
// The mapping of a lowered path to the defaults paths follows the scopes
// of the resolver:
// - `options.<path>` is `<path>`, also below the chart type of an override
//   (`doughnut.aspectRatio`);
// - an axis `options.scales.<id>.<path>` is `scale.<path>`,
//   `scales.<scale type>.<path>`, or `scales.<id>.<path>`,
//   `scales._index_.<path>` and `scales._value_.<path>` of an override;
// - a dataset key `<key>` of a dataset of the type `<type>` is
//   `datasets.<type>.<key>`, the root `<key>` or `elements.<element>.<key>`
//   for an element of the controller, also without the prefix `hover` and,
//   for the point options, without the prefix `point`
//   (`core.datasetController.js`, `resolveDataElementOptions`).
// A path that is the start of a defaults path is a group: the check goes on
// in its Map. A font Map and a padding Map are values, not groups. An options
// object of `ChartConfig.pluginOptions` (the `LegendOptions` at
// `options.plugins.legend`, the `TooltipOptions` at `options.plugins.tooltip`
// and the `FillerOptions` at `options.plugins.filler`, Chart.js ADRs 0192,
// 0193 and 0196) is a value too: it has one field for each option of its
// plugin, so it lowers no key of its own.
//
// When the submodule third_party/Chart.js is checked out, a test reads
// `src/types/index.d.ts` and checks that each allowlist line declares its
// key. The test prints the share of the defaults inventory that the typed
// set covers.
//
// VM only: the test reads files and the typed files import dart:ui.

/// The keys with no default, as lowered paths (`*` for a dataset index or
/// an axis id), each with the line of `src/types/index.d.ts` at the pin that
/// declares the key.
const Map<String, int> _allowlist = {
  'type': 3919,
  'plugins': 3922,
  'data.labels': 3897,
  'data.datasets.*.type': 3860,
  'data.datasets.*.data': 3861,
  'data.datasets.*.label': 79,
  'data.datasets.*.order': 83,
  'data.datasets.*.stack': 88,
  'data.datasets.*.hidden': 93,
  'data.datasets.*.xAxisID': 104,
  'data.datasets.*.yAxisID': 108,
  'options.scales.*.axis': 3286,
  'data.datasets.*.barThickness': 124,
  'data.datasets.*.maxBarThickness': 129,
  'data.datasets.*.minBarLength': 134,
  'data.datasets.*.weight': 274,
  'options.scales.*.position': 3270,
  'options.scales.*.min': 3291,
  'options.scales.*.max': 3296,
  'options.scales.*.stacked': 3339,
  'options.scales.*.labels': 3347,
  'options.scales.*.suggestedMin': 3366,
  'options.scales.*.suggestedMax': 3370,
  'options.scales.*.ticks.font': 3144,
  'options.scales.*.ticks.stepSize': 3390,
  'options.scales.*.title.align': 3313,
  'options.scales.*.title.font': 3323,
  'options.scales.*.time.tooltipFormat': 3453,
  'options.scales.*.offsetAfterAutoskip': 3503,
  'options.scales.*.ticks.z': 3168,
  'options.scales.*.ticks.sampleSize': 3184,
  'options.scales.*.ticks.includeBounds': 3212,
  'options.scales.*.ticks.maxTicksLimit': 3244,
  'options.scales.*.ticks.precision': 3385,
  'options.scales.*.ticks.count': 3395,
  'options.scales.*.grid.circular': 3068,
  'options.scales.*.grid.tickBorderDash': 3088,
  'options.scales.*.grid.tickBorderDashOffset': 3092,
  'options.scales.*.grid.z': 3112,
  'options.scales.*.title.strokeColor': 3319,
  'options.scales.*.title.strokeWidth': 3321,
  'options.scales.*.stack': 3275,
  'options.scales.*.stackWeight': 3281,
  'options.scales.*.alignToPixels': 1209,
  'options.scales.*.backgroundColor': 1213,
  'options.scales.*.weight': 1228,
  'options.scales.*.beforeUpdate': 1248,
  'options.scales.*.beforeSetDimensions': 1252,
  'options.scales.*.afterSetDimensions': 1256,
  'options.scales.*.beforeDataLimits': 1260,
  'options.scales.*.afterDataLimits': 1264,
  'options.scales.*.beforeBuildTicks': 1268,
  'options.scales.*.afterBuildTicks': 1272,
  'options.scales.*.beforeTickToLabelConversion': 1276,
  'options.scales.*.afterTickToLabelConversion': 1280,
  'options.scales.*.beforeCalculateLabelRotation': 1284,
  'options.scales.*.afterCalculateLabelRotation': 1288,
  'options.scales.*.beforeFit': 1292,
  'options.scales.*.afterFit': 1296,
  'options.scales.*.afterUpdate': 1300,
  'options.elements.point.hoverBackgroundColor': 1864,
  'options.elements.point.hoverBorderColor': 1863,
  'options.elements.point.drawActiveElementsOnTop': 2080,
  'data.datasets.*.base': 2152,
  'data.datasets.*.skipNull': 153,
  'options.normalized': 63,
  'options.animation.onProgress': 1802,
  'options.animation.onComplete': 1806,
  'options.animation.animateRotate': 298,
  'options.animation.animateScale': 304,
};

/// The keys of a value Map: the check does not go into it.
const Set<String> _valueMaps = {
  'font',
  'titleFont',
  'bodyFont',
  'footerFont',
  'padding',
};

/// The element types of each controller (`dataElementType` and
/// `datasetElementType`).
const Map<String, List<String>> _elementsOf = {
  'bar': ['bar'],
  'line': ['line', 'point'],
  'scatter': ['line', 'point'],
  'radar': ['line', 'point'],
  'bubble': ['point'],
  'pie': ['arc'],
  'doughnut': ['arc'],
  'polarArea': ['arc'],
};

const Color _red = Color(0xFFFF0000);

/// A scale hook of the configs (Chart.js ADR 0130).
void _scaleHook(Scale scale) {}
const TextStyle _font = TextStyle(fontSize: 12);
const EdgeInsets _padding = EdgeInsets.all(4);

String? _text(List<TooltipItem> items) => null;
String? _label(TooltipItem item) => null;
List<String>? _format(Scale scale, double value, int index, List<Tick> ticks) =>
    null;
ChartPaint _colorFor(ScriptableContext context) => const ChartPaint.solid(_red);
void _onEvent(ChartEvent event, List<ActiveElement> hits, Chart chart) {}
void _onLegend(ChartEvent event, LegendItem item, LegendElement legend) {}
void _onAnimation(IAnimationEvent event) {}

const AxisTicks _ticks = AxisTicks(
  display: true,
  color: .constant(ChartPaint.solid(_red)),
  font: .constant(_font),
  padding: 3,
  stepSize: 1,
  maxRotation: 0,
  autoSkip: true,
  callback: _format,
  backdropColor: .constant(ChartPaint.solid(_red)),
  backdropPadding: _padding,
  showLabelBackdrop: true,
  textStrokeColor: .constant(ChartPaint.solid(_red)),
  textStrokeWidth: 1,
  z: 1,
  sampleSize: 4,
  autoSkipPadding: 3,
  includeBounds: true,
  labelOffset: 1,
  minRotation: 0,
  mirror: false,
  maxTicksLimit: 11,
  precision: 0,
  count: 5,
);
const AxisGrid _grid = AxisGrid(
  display: true,
  color: .constant(ChartPaint.solid(_red)),
  lineWidth: .constant(1),
  drawOnChartArea: true,
  drawTicks: true,
  offset: false,
  tickLength: 8,
  circular: false,
  tickBorderDash: [2, 2],
  tickBorderDashOffset: 0,
  tickColor: .constant(ChartPaint.solid(_red)),
  tickWidth: .constant(1),
  z: 0,
);
const AxisTitle _axisTitle = AxisTitle(
  display: true,
  text: ['T'],
  color: ChartPaint.solid(_red),
  font: _font,
  align: .center,
  padding: _padding,
  strokeColor: ChartPaint.solid(_red),
  strokeWidth: 1,
);

/// The line style parameters, for [LineDataset], [ScatterDataset] and
/// [RadarDataset].
const FillTarget _fill = .toOrigin;

/// Configs with each typed parameter: the chart types bar (with a line, a
/// scatter and a bubble dataset), doughnut (with a pie dataset), polar
/// area and radar.
List<ChartConfig> _configs() {
  final data = <num?>[1, 2];
  final points = [DataPoint(1, 2)];
  return [
    ChartConfig(
      labels: const ['a', 'b'],
      datasets: [
        BarDataset(
          label: 'A',
          data: .values(data),
          hidden: false,
          order: 1,
          backgroundColor: const ChartValue.constant(.solid(_red)),
          borderColor: const ChartValue.constant(.solid(_red)),
          borderWidth: 1,
          hoverBackgroundColor: const .constant(.solid(_red)),
          hoverBorderColor: const .constant(.solid(_red)),
          hoverBorderWidth: 1,
          xAxis: _xAxis,
          yAxis: _yAxis,
          stack: 's',
          indexAxis: const XAxis(),
          borderRadius: 2,
          barPercentage: 0.9,
          categoryPercentage: 0.8,
          barThickness: const BarThickness.pixels(10),
          maxBarThickness: 12,
          minBarLength: 1,
          grouped: true,
          borderSkipped: BorderSkip.start,
          base: 0,
          inflateAmount: 0,
          skipNull: false,
          hoverBorderRadius: 0,
          pointStyle: const CirclePointStyle(),
        ),
        LineDataset(
          data: .points(points),
          backgroundColor: const ChartValue.indexed([ChartPaint.solid(_red)]),
          borderColor: const ChartValue.resolver(_colorFor),
          xAxis: _xAxis,
          yAxis: _yAxis,
          stack: 's',
          indexAxis: const XAxis(),
          fill: _fill,
          tension: 0.4,
          borderDash: const [2, 2],
          spanGaps: true,
          showLine: true,
          stepped: SteppedLine.before,
          pointRadius: const .constant(3),
          pointHoverRadius: const .constant(4),
          pointStyle: const .constant(CirclePointStyle()),
          pointBackgroundColor: const .constant(.solid(_red)),
          pointBorderColor: const .constant(.solid(_red)),
          pointBorderWidth: 1,
          pointHoverBackgroundColor: const .constant(.solid(_red)),
          pointHoverBorderColor: const .constant(.solid(_red)),
          borderDashOffset: 0,
          capBezierPoints: true,
          drawActiveElementsOnTop: true,
          pointHitRadius: const .constant(1),
          pointHoverBorderWidth: const .constant(1),
          pointRotation: const .constant(0),
        ),
        ScatterDataset(
          data: .points(points),
          xAxis: _xAxis,
          yAxis: _yAxis,
          stack: 's',
          fill: _fill,
          tension: 0.4,
          borderDash: const [2, 2],
          spanGaps: true,
          showLine: true,
          stepped: SteppedLine.before,
          pointRadius: const .constant(3),
          pointHoverRadius: const .constant(4),
          pointStyle: const .constant(CirclePointStyle()),
          pointBackgroundColor: const .constant(.solid(_red)),
          pointBorderColor: const .constant(.solid(_red)),
          pointBorderWidth: 1,
          pointHoverBackgroundColor: const .constant(.solid(_red)),
          pointHoverBorderColor: const .constant(.solid(_red)),
        ),
        BubbleDataset(
          data: [DataPoint.bubble(1, 2, 3)],
          xAxis: _xAxis,
          yAxis: _yAxis,
          radius: 3,
          hoverRadius: 4,
          pointStyle: const CirclePointStyle(),
          drawActiveElementsOnTop: true,
        ),
      ],
      scales: [
        _xAxis,
        _yAxis,
        const LogarithmicAxis(
          .y,
          min: 1,
          max: 10,
          suggestedMin: 1,
          suggestedMax: 10,
        ),
        TimeAxis(
          .x,
          min: DateTime.utc(2020),
          max: DateTime.utc(2021),
          unit: .month,
          tooltipFormat: 'yyyy',
          displayFormats: const TimeDisplayFormats(month: 'MMM yyyy'),
          offsetAfterAutoskip: true,
          parser: 'yyyy',
          round: .day,
          minUnit: .second,
          isoWeekday: 1,
        ),
        TimeSeriesAxis(
          .x,
          min: DateTime.utc(2020),
          max: DateTime.utc(2021),
          unit: .month,
          tooltipFormat: 'yyyy',
          displayFormats: const TimeDisplayFormats(month: 'MMM yyyy'),
          offsetAfterAutoskip: true,
          parser: 'yyyy',
          round: .day,
          minUnit: .second,
          isoWeekday: 1,
        ),
      ],
      indexAxis: const XAxis(),
      responsive: true,
      maintainAspectRatio: true,
      normalized: false,
      datasetDefaults: const [BarDataset(categoryPercentage: 0.8)],
      color: const ChartPaint.solid(_red),
      aspectRatio: 2,
      padding: _padding,
      pluginOptions: [
        const TitleOptions(
          display: true,
          text: ['T'],
          color: ChartPaint.solid(_red),
          font: _font,
          align: .center,
          position: .top,
          padding: _padding,
          fullSize: true,
        ),
        const SubtitleOptions(
          display: true,
          text: ['S'],
          color: ChartPaint.solid(_red),
          font: _font,
          align: .center,
          position: .top,
          padding: _padding,
          fullSize: true,
        ),
        const LegendOptions(
          textDirection: .rtl,
          display: true,
          position: ChartPosition.top,
          align: .center,
          reverse: false,
          labels: LegendLabelOptions(
            color: ChartPaint.solid(_red),
            font: _font,
            boxWidth: 40,
            boxHeight: 12,
            padding: 10,
            usePointStyle: false,
          ),
          onClick: _onLegend,
          onHover: _onLegend,
          onLeave: _onLegend,
        ),
        TooltipOptions(
          textDirection: .rtl,
          enabled: true,
          mode: const IndexInteractionMode(),
          intersect: false,
          backgroundColor: const ChartPaint.solid(_red),
          titleColor: const ChartPaint.solid(_red),
          titleFont: _font,
          bodyColor: const ChartPaint.solid(_red),
          bodyFont: _font,
          footerColor: const ChartPaint.solid(_red),
          footerFont: _font,
          padding: _padding,
          displayColors: true,
          caretSize: 0,
          caretPadding: 16,
          bodyAlign: .center,
          callbacks: TooltipCallbacks(
            title: (tooltip, arg) {
              final text = _text(arg);
              return text == null
                  ? null
                  : text.isEmpty
                  ? <String>[]
                  : [text];
            },
            label: (tooltip, arg) {
              final text = _label(arg);
              return text == null
                  ? null
                  : text.isEmpty
                  ? <String>[]
                  : [text];
            },
            footer: (tooltip, arg) {
              final text = _text(arg);
              return text == null
                  ? null
                  : text.isEmpty
                  ? <String>[]
                  : [text];
            },
          ),
        ),
        const FillerOptions(propagate: true),
      ],
      interaction: const ChartInteraction(
        mode: NearestInteractionMode(),
        intersect: true,
        includeInvisible: false,
      ),
      animation: const ChartAnimation(
        duration: Duration(seconds: 1),
        delay: Duration.zero,
        easing: Curves.easeOutQuart,
        loop: false,
        animateScale: false,
        animateRotate: true,
        onProgress: _onAnimation,
        onComplete: _onAnimation,
      ),
      elements: const ChartElements(
        point: PointElementStyle(
          radius: 3,
          pointStyle: CirclePointStyle(),
          backgroundColor: ChartPaint.solid(_red),
          borderColor: ChartPaint.solid(_red),
          borderWidth: 1,
          hitRadius: 1,
          hoverRadius: 4,
          rotation: 0,
          hoverBackgroundColor: ChartPaint.solid(_red),
          hoverBorderColor: ChartPaint.solid(_red),
          hoverBorderWidth: 1,
          drawActiveElementsOnTop: true,
        ),
        line: LineElementStyle(
          tension: 0,
          backgroundColor: ChartPaint.solid(_red),
          borderColor: ChartPaint.solid(_red),
          borderWidth: 3,
          borderDash: [2, 2],
          fill: _fill,
          stepped: SteppedLine.before,
          borderDashOffset: 0,
          capBezierPoints: true,
        ),
        bar: BarElementStyle(
          backgroundColor: ChartPaint.solid(_red),
          borderColor: ChartPaint.solid(_red),
          borderWidth: 0,
          borderRadius: 0,
          borderSkipped: BorderSkip.all,
          inflateAmount: 0,
        ),
        arc: ArcElementStyle(
          backgroundColor: ChartPaint.solid(_red),
          borderColor: ChartPaint.solid(_red),
          borderWidth: 2,
          offset: 0,
          spacing: 0,
          borderDash: [2, 2],
          borderDashOffset: 0,
          borderJoinStyle: .round,
          selfJoin: false,
          circular: true,
          angle: 0,
        ),
      ),
      onClick: _onEvent,
      onHover: _onEvent,
      events: const ['click'],
      plugins: const [],
    ),
    ChartConfig(
      labels: const ['a', 'b'],
      datasets: [
        for (final dataset in [
          PieDataset(
            data: data,
            offset: 1,
            hoverOffset: 2,
            spacing: 1,
            weight: 1,
            circumference: 360,
            rotation: 0,
            cutout: const PercentRadius(50),
            radius: const PixelRadius(100),
          ),
          DoughnutDataset(
            data: data,
            offset: 1,
            hoverOffset: 2,
            spacing: 1,
            weight: 1,
            circumference: 360,
            rotation: 0,
            cutout: const PercentRadius(50),
            radius: const PixelRadius(100),
            borderAlign: ArcBorderAlign.center,
            borderJoinStyle: .round,
            borderRadius: 0,
            selfJoin: false,
            spacingMode: ArcSpacingMode.angular,
          ),
        ])
          dataset,
      ],
    ),
    ChartConfig(
      labels: const ['a', 'b'],
      datasets: [
        PolarAreaDataset(
          data: data,
          offset: 1,
          hoverOffset: 2,
          spacing: 1,
          borderAlign: ArcBorderAlign.center,
          borderJoinStyle: .round,
          borderRadius: 0,
          selfJoin: false,
          spacingMode: ArcSpacingMode.angular,
          angle: 90,
        ),
      ],
      scales: const [
        RadialLinearAxis(
          display: ScaleDisplay.on,
          position: .chartArea,
          min: 0,
          max: 10,
          suggestedMin: 0,
          suggestedMax: 10,
          beginAtZero: true,
          startAngle: 0,
          pointLabelsDisplay: ScaleDisplay.on,
          pointLabelsColor: ChartPaint.solid(_red),
          pointLabelsFont: _font,
          pointLabelsPadding: 5,
          angleLinesDisplay: true,
          angleLinesColor: ChartPaint.solid(_red),
          angleLinesLineWidth: 1,
        ),
      ],
    ),
    ChartConfig(
      labels: const ['a', 'b'],
      datasets: [
        RadarDataset(
          data: data,
          fill: _fill,
          tension: 0.4,
          borderDash: const [2, 2],
          spanGaps: true,
          showLine: true,
          stepped: SteppedLine.before,
          pointRadius: const .constant(3),
          pointHoverRadius: const .constant(4),
          pointStyle: const .constant(CirclePointStyle()),
          pointBackgroundColor: const .constant(.solid(_red)),
          pointBorderColor: const .constant(.solid(_red)),
          pointBorderWidth: 1,
          pointHoverBackgroundColor: const .constant(.solid(_red)),
          pointHoverBorderColor: const .constant(.solid(_red)),
        ),
      ],
      animation: ChartAnimation.none,
    ),
  ];
}

/// The result of the key check.
final class _Check() {
  /// The lowered paths that are neither known nor on the allowlist.
  final List<String> unknown = [];

  /// The allowlist rows that a lowered path uses.
  final Set<String> allowed = {};

  /// The defaults paths that a lowered path covers.
  final Set<String> covered = {};

  /// The number of lowered key paths, without the dataset index and the
  /// axis id.
  final Set<String> paths = {};
}

late Set<String> _defaults;
late Set<String> _overrides;

/// The defaults paths and the override paths below their chart type.
Set<String> get _known => {..._defaults, ..._overrides};

bool _isPrefix(String path) =>
    _known.any((known) => known.startsWith('$path.'));

/// [key] with its first letter in lower case.
String _lowerFirst(String key) =>
    key.isEmpty ? key : key[0].toLowerCase() + key.substring(1);

/// The defaults paths of the dataset key [key] of a dataset of [type].
List<String> _datasetCandidates(String type, String key) {
  final elements = _elementsOf[type] ?? const <String>[];
  final names = {
    key,
    if (key.startsWith('hover') && key.length > 5)
      _lowerFirst(key.substring(5)),
    if (key.startsWith('point') && key.length > 5 && elements.contains('point'))
      _lowerFirst(key.substring(5)),
  };
  return [
    for (final name in names) ...[
      'datasets.$type.$name',
      name,
      for (final element in elements) 'elements.$element.$name',
    ],
  ];
}

/// Checks [value] at the lowered path [lowered], with the defaults paths
/// [candidates].
void _check(
  Object? value,
  String lowered,
  List<String> candidates,
  _Check check,
) {
  check.paths.add(lowered);
  if (_allowlist.containsKey(lowered)) {
    check.allowed.add(lowered);
    return;
  }
  final exact = [
    for (final c in candidates)
      if (_known.contains(c)) c,
  ];
  if (exact.isNotEmpty) {
    check.covered.addAll(exact);
    return;
  }
  final groups = [
    for (final c in candidates)
      if (_isPrefix(c)) c,
  ];
  if (groups.isEmpty) {
    check.unknown.add(lowered);
    return;
  }
  final key = lowered.substring(lowered.lastIndexOf('.') + 1);
  if (_isObject(value) && !_valueMaps.contains(key)) {
    for (final (child, childValue) in _entries(value)) {
      _check(childValue, '$lowered.$child', [
        for (final group in groups) '$group.$child',
      ], check);
    }
    return;
  }
  // A value at a group path: `animation: false` or a value Map.
  check.covered.addAll([
    for (final group in groups)
      for (final known in _known)
        if (known.startsWith('$group.')) known,
  ]);
}

/// Whether [value] is an object of a lowered config: a typed scope (a typed
/// object with a face, Chart.js ADR 0054 §7) or a Map.
bool _isObject(Object? value) =>
    value is Map<String, Object?> || value is JsObjectFace;

/// The own keys of the object [object] with their values, in the order of
/// `Object.keys`, read by name.
List<(String, Object?)> _entries(Object? object) => [
  for (final key in jsObjectKeys(object)) (key, jsGet(object, key)),
];

/// Checks the root scope [root] of a lowered config.
void _checkRoot(Object root, _Check check) {
  final chartType = jsGet(root, 'type')! as String;
  for (final (key, value) in _entries(root)) {
    switch (key) {
      case 'data':
        for (final (dataKey, dataValue) in _entries(value)) {
          if (dataKey != 'datasets') {
            _check(dataValue, 'data.$dataKey', const [], check);
            continue;
          }
          for (final dataset in dataValue! as List<Object?>) {
            final datasetType = jsGet(dataset, 'type');
            final type = datasetType is String ? datasetType : chartType;
            for (final (name, option) in _entries(dataset)) {
              _check(
                option,
                'data.datasets.*.$name',
                _datasetCandidates(type, name),
                check,
              );
            }
          }
        }
      case 'options':
        for (final (name, option) in _entries(value)) {
          if (name != 'scales') {
            _check(option, 'options.$name', [name], check);
            continue;
          }
          for (final (id, axis) in _entries(option)) {
            final scaleType = jsGet(axis, 'type')! as String;
            for (final (axisKey, axisValue) in _entries(axis)) {
              _check(axisValue, 'options.scales.*.$axisKey', [
                for (final scope in [
                  'scale',
                  'scales.$scaleType',
                  'scales.$id',
                  'scales._index_',
                  'scales._value_',
                ])
                  '$scope.$axisKey',
              ], check);
            }
          }
        }
      default:
        _check(value, key, const [], check);
    }
  }
}

/// The repository root above the package, or `null`.
Directory? _repositoryRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync() &&
        Directory('${dir.path}/third_party').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

/// The x axis and the y axis of the datasets (Chart.js ADR 0191).
const _xAxis = CategoryAxis(
  .x,
  display: ScaleDisplay.on,
  position: .bottom,
  reverse: false,
  stacked: StackMode.on,
  labels: ['a', 'b'],
  min: 'a',
  max: 'b',
  ticks: _ticks,
  grid: _grid,
  title: _axisTitle,
  offset: true,
  stack: 'a',
  stackWeight: 1,
  alignToPixels: false,
  backgroundColor: ChartPaint.solid(_red),
  clip: true,
  weight: 0,
  beforeUpdate: _scaleHook,
  beforeSetDimensions: _scaleHook,
  afterSetDimensions: _scaleHook,
  beforeDataLimits: _scaleHook,
  afterDataLimits: _scaleHook,
  beforeBuildTicks: _scaleHook,
  afterBuildTicks: _scaleHook,
  beforeTickToLabelConversion: _scaleHook,
  afterTickToLabelConversion: _scaleHook,
  beforeCalculateLabelRotation: _scaleHook,
  afterCalculateLabelRotation: _scaleHook,
  beforeFit: _scaleHook,
  afterFit: _scaleHook,
  afterUpdate: _scaleHook,
);
const _yAxis = LinearAxis(
  .y,
  min: 0,
  max: 10,
  suggestedMin: 0,
  suggestedMax: 10,
  beginAtZero: true,
  grace: PercentGrace(5),
);

void main() {
  late _Check check;

  setUpAll(() {
    final manifest = jsonDecode(
      File('doc/upstream/manifest.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final values =
        (manifest['defaults']! as Map<String, Object?>)['values']!
            as Map<String, Object?>;
    _defaults = (values['defaults']! as Map<String, Object?>).keys.toSet();
    _overrides = {
      for (final key in (values['overrides']! as Map<String, Object?>).keys)
        key.substring(key.indexOf('.') + 1),
    };
    check = _Check();
    for (final config in _configs()) {
      _checkRoot(ChartConfigLowering(config).lower(), check);
    }
  });

  test('each lowered path is a defaults path or an allowlist row', () {
    expect(check.unknown, isEmpty);
    expect(_defaults, contains('scale.ticks.callback'));
  });

  test('each allowlist row names a lowered path', () {
    expect(_allowlist.keys.toSet().difference(check.allowed), isEmpty);
  });

  test('the typed set covers a share of the defaults inventory', () {
    final defaults = check.covered.intersection(_defaults);
    final share = (100 * defaults.length / _defaults.length).toStringAsFixed(1);
    // The share is a report of the test (ADR 0052, section 13).
    // ignore: avoid_print
    print(
      'key check: ${check.paths.length} typed key paths, '
      '${_allowlist.length} allowlist rows; they cover ${defaults.length} '
      'of ${_defaults.length} defaults paths ($share %).',
    );
    expect(defaults.length, greaterThan(100));
  });

  final root = _repositoryRoot();
  final dts = root == null
      ? null
      : File('${root.path}/third_party/Chart.js/src/types/index.d.ts');
  test(
    'each allowlist line of index.d.ts declares its key',
    () {
      final lines = dts!.readAsLinesSync();
      for (final MapEntry(key: path, value: line) in _allowlist.entries) {
        final key = path.substring(path.lastIndexOf('.') + 1);
        expect(
          lines[line - 1],
          matches(RegExp('^\\s*$key\\??[:(]')),
          reason: '$path at index.d.ts:$line',
        );
      }
    },
    skip: dts == null
        ? 'n/a: not inside the flutter_ports repository'
        : dts.existsSync()
        ? false
        : 'n/a: the submodule third_party/Chart.js is not checked out',
  );
}
