// Original code, not ported from Chart.js: the key check of the typed API.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show EdgeInsets, TextStyle;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show JsObjectFace, jsGet;
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
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
// in its Map. A font Map and a padding Map are values, not groups.
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
  'options.plugins.legend.labels.boxHeight': 2479,
  'options.plugins.legend.labels.font': 2489,
  'options.plugins.legend.labels.usePointStyle': 2528,
  'options.plugins.tooltip.mode': 1610,
  'options.plugins.tooltip.intersect': 1615,
  'options.animation.onProgress': 1802,
  'options.animation.onComplete': 1806,
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
const TextStyle _font = TextStyle(fontSize: 12);
const EdgeInsets _padding = EdgeInsets.all(4);

String? _text(List<ChartTooltipItem> items) => null;
String? _label(ChartTooltipItem item) => null;
String? _format(AxisTickInfo tick) => null;
Color _colorFor(ChartContext context) => _red;
void _onEvent(ChartEventDetails details) {}
void _onLegend(ChartLegendEventDetails details) {}
void _onAnimation(ChartAnimationDetails details) {}

const AxisTicks _ticks = AxisTicks(
  display: true,
  color: _red,
  font: _font,
  padding: 3,
  stepSize: 1,
  maxRotation: 0,
  autoSkip: true,
  format: _format,
);
const AxisGrid _grid = AxisGrid(
  display: true,
  color: _red,
  lineWidth: 1,
  drawOnChartArea: true,
  drawTicks: true,
  offset: false,
);
const AxisTitle _axisTitle = AxisTitle(
  display: true,
  text: 'T',
  color: _red,
  font: _font,
  align: .center,
  padding: _padding,
);

/// The line style parameters, for [LineDataset], [ScatterDataset] and
/// [RadarDataset].
const ChartFill _fill = .origin;

/// Configs with each typed parameter: the chart types bar (with a line, a
/// scatter and a bubble dataset), doughnut (with a pie dataset), polar
/// area and radar.
List<ChartConfig> _configs() {
  final data = <num?>[1, 2];
  final points = [DataPoint(1, 2)];
  return [
    ChartConfig(
      type: .bar,
      labels: const ['a', 'b'],
      datasets: [
        BarDataset(
          label: 'A',
          data: data,
          hidden: false,
          order: 1,
          backgroundColor: _red,
          borderColor: _red,
          borderWidth: 1,
          hoverBackgroundColor: _red,
          hoverBorderColor: _red,
          hoverBorderWidth: 1,
          xAxisID: 'x',
          yAxisID: 'y',
          stack: 's',
          indexAxis: .x,
          borderRadius: 2,
          barPercentage: 0.9,
          categoryPercentage: 0.8,
          barThickness: 10,
          maxBarThickness: 12,
          minBarLength: 1,
          grouped: true,
        ),
        LineDataset(
          points: points,
          backgroundColors: const [_red],
          borderColorFor: _colorFor,
          xAxisID: 'x',
          yAxisID: 'y',
          stack: 's',
          indexAxis: .x,
          fill: _fill,
          tension: 0.4,
          borderDash: const [2, 2],
          spanGaps: true,
          showLine: true,
          stepped: false,
          pointRadius: 3,
          pointHoverRadius: 4,
          pointStyle: .circle,
          pointBackgroundColor: _red,
          pointBorderColor: _red,
          pointBorderWidth: 1,
          pointHoverBackgroundColor: _red,
          pointHoverBorderColor: _red,
        ),
        ScatterDataset(
          points: points,
          xAxisID: 'x',
          yAxisID: 'y',
          stack: 's',
          fill: _fill,
          tension: 0.4,
          borderDash: const [2, 2],
          spanGaps: true,
          showLine: true,
          stepped: false,
          pointRadius: 3,
          pointHoverRadius: 4,
          pointStyle: .circle,
          pointBackgroundColor: _red,
          pointBorderColor: _red,
          pointBorderWidth: 1,
          pointHoverBackgroundColor: _red,
          pointHoverBorderColor: _red,
        ),
        BubbleDataset(
          points: [DataPoint.bubble(1, 2, 3)],
          xAxisID: 'x',
          yAxisID: 'y',
          radius: 3,
          hoverRadius: 4,
          pointStyle: .circle,
        ),
      ],
      scales: {
        'x': const CategoryAxis(
          display: true,
          position: .bottom,
          reverse: false,
          stacked: true,
          labels: ['a', 'b'],
          min: 'a',
          max: 'b',
          ticks: _ticks,
          grid: _grid,
          title: _axisTitle,
        ),
        'y': const LinearAxis(
          min: 0,
          max: 10,
          suggestedMin: 0,
          suggestedMax: 10,
          beginAtZero: true,
        ),
        'y2': const LogarithmicAxis(
          min: 1,
          max: 10,
          suggestedMin: 1,
          suggestedMax: 10,
        ),
        't': TimeAxis(
          min: DateTime.utc(2020),
          max: DateTime.utc(2021),
          unit: .month,
          tooltipFormat: 'yyyy',
        ),
        'ts': TimeSeriesAxis(
          min: DateTime.utc(2020),
          max: DateTime.utc(2021),
          unit: .month,
          tooltipFormat: 'yyyy',
        ),
      },
      indexAxis: .x,
      responsive: true,
      maintainAspectRatio: true,
      aspectRatio: 2,
      padding: _padding,
      legend: const ChartLegend(
        display: true,
        position: .top,
        align: .center,
        reverse: false,
        labelColor: _red,
        labelFont: _font,
        boxWidth: 40,
        boxHeight: 12,
        labelPadding: 10,
        usePointStyle: false,
        onClick: _onLegend,
        onHover: _onLegend,
        onLeave: _onLegend,
      ),
      title: const ChartTitle(
        display: true,
        text: 'T',
        color: _red,
        font: _font,
        align: .center,
        position: .top,
        padding: _padding,
        fullSize: true,
      ),
      subtitle: const ChartTitle(
        display: true,
        text: 'S',
        color: _red,
        font: _font,
        align: .center,
        position: .top,
        padding: _padding,
        fullSize: true,
      ),
      tooltip: const ChartTooltip(
        enabled: true,
        mode: .index,
        intersect: false,
        backgroundColor: _red,
        titleColor: _red,
        titleFont: _font,
        bodyColor: _red,
        bodyFont: _font,
        footerColor: _red,
        footerFont: _font,
        padding: _padding,
        cornerRadius: 6,
        displayColors: true,
        titleText: _text,
        labelText: _label,
        footerText: _text,
      ),
      filler: const ChartFiller(propagate: true),
      interaction: const ChartInteraction(
        mode: .nearest,
        intersect: true,
        includeInvisible: false,
      ),
      animation: const ChartAnimation(
        duration: Duration(seconds: 1),
        delay: Duration.zero,
        easing: .easeOutQuart,
        loop: false,
        onProgress: _onAnimation,
        onComplete: _onAnimation,
      ),
      elements: const ChartElements(
        point: PointElementStyle(
          radius: 3,
          pointStyle: .circle,
          backgroundColor: _red,
          borderColor: _red,
          borderWidth: 1,
          hitRadius: 1,
          hoverRadius: 4,
        ),
        line: LineElementStyle(
          tension: 0,
          backgroundColor: _red,
          borderColor: _red,
          borderWidth: 3,
          borderDash: [2, 2],
          fill: _fill,
          stepped: false,
        ),
        bar: BarElementStyle(
          backgroundColor: _red,
          borderColor: _red,
          borderWidth: 0,
          borderRadius: 0,
        ),
        arc: ArcElementStyle(
          backgroundColor: _red,
          borderColor: _red,
          borderWidth: 2,
          offset: 0,
          spacing: 0,
        ),
      ),
      onClick: _onEvent,
      onHover: _onEvent,
      plugins: const [],
    ),
    ChartConfig(
      type: .doughnut,
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
            cutout: const .percent(50),
            radius: const .pixels(100),
          ),
          DoughnutDataset(
            data: data,
            offset: 1,
            hoverOffset: 2,
            spacing: 1,
            weight: 1,
            circumference: 360,
            rotation: 0,
            cutout: const .percent(50),
            radius: const .pixels(100),
          ),
        ])
          dataset,
      ],
    ),
    ChartConfig(
      type: .polarArea,
      labels: const ['a', 'b'],
      datasets: [
        PolarAreaDataset(data: data, offset: 1, hoverOffset: 2, spacing: 1),
      ],
      scales: const {
        'r': RadialLinearAxis(
          display: true,
          position: .chartArea,
          min: 0,
          max: 10,
          suggestedMin: 0,
          suggestedMax: 10,
          beginAtZero: true,
          startAngle: 0,
          pointLabelsDisplay: true,
          pointLabelsColor: _red,
          pointLabelsFont: _font,
          pointLabelsPadding: 5,
          angleLinesDisplay: true,
          angleLinesColor: _red,
          angleLinesLineWidth: 1,
        ),
      },
    ),
    ChartConfig(
      type: .radar,
      labels: const ['a', 'b'],
      datasets: [
        RadarDataset(
          data: data,
          fill: _fill,
          tension: 0.4,
          borderDash: const [2, 2],
          spanGaps: true,
          showLine: true,
          stepped: false,
          pointRadius: 3,
          pointHoverRadius: 4,
          pointStyle: .circle,
          pointBackgroundColor: _red,
          pointBorderColor: _red,
          pointBorderWidth: 1,
          pointHoverBackgroundColor: _red,
          pointHoverBorderColor: _red,
        ),
      ],
      animation: ChartAnimation.none,
    ),
  ];
}

/// The result of the key check.
final class _Check {
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
    final share = (100 * defaults.length / _defaults.length).toStringAsFixed(
      1,
    );
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
          matches(RegExp('^\\s*$key\\??:')),
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
