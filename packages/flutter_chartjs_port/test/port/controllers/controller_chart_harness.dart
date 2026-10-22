// Original code, not ported from Chart.js: controller reference test harness.

/// The harness of the port-only reference tests of the phase 7 controllers
/// (Chart.js ADR 0030): real charts against a build of the pinned Chart.js.
///
/// The method:
///
/// - A generator `tool/reference/controller_<name>_reference.mjs` builds
///   each chart of its cases with a build of Chart.js at the pinned commit in
///   the x64 Node.js v24.12.0 (Chart.js ADR 0032), through
///   `tool/reference/controller_chart_common.mjs`. It runs the steps of each
///   case, and records the observations, the hit queries and the draw calls.
/// - A test file `controller.<name>_test.dart` builds the same charts with
///   `acquireChart` in `testWidgets` cases ([testControllerChartCases]),
///   runs the same steps ([runStep]) and compares the observations
///   ([expectControllerObservations]) and the draw calls (`drawCalls` and
///   `expectCalls` of `scale_chart_harness.dart`, with the element draws).
///
/// One observation has the keys `chartArea`, `scales`, `stacks`,
/// `datasets` and `hits` (Chart.js ADR 0030, section 4). The plugin
/// reference tests (Chart.js ADR 0041, section 3 item 3) leave out `hits`
/// (`hits: false`) and add the keys of `observeExtra`
/// (`test/port/plugins/plugin_chart_harness.dart`). The compare rules:
///
/// - The check reads exactly the keys of the expected Map. An expected key
///   that no check reads fails.
/// - An options object becomes a plain Map through `jsObjectKeys` and
///   `jsGet` ([plainValue]). A resolver never goes to `expect`.
/// - A Map compares as a Map: the key order does not count. A List compares
///   item by item in order.
/// - Numbers: `referenceMatcher`. Hit items: `equals` (exact).
/// - A function value is `'<fn>'` on both sides. An absent property is the
///   `undefined` sentinel on both sides.
///
/// This library is not a test file. It is not a pure layer. A test that
/// imports it needs `@TestOn('vm')`.
library;

import 'dart:convert';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
import 'package:flutter_chartjs_port/src/js/js_array.dart'
    show jsObjectKeys, jsSplice;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/color.dart';
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart';
import '../scales/scale_time_harness.dart' show atNow;

// ---------------------------------------------------------------------------
// The hit queries (Chart.js ADR 0030, section 5).

/// The chart event of the hit queries: `{type: 'mousemove', native: null,
/// x, y}`. getRelativePosition returns it as it is (helpers.dom.ts:109-111).
final class ReferenceEvent implements types.ChartEvent {
  /// The event at the point ([x], [y]).
  const ReferenceEvent(this.x, this.y);

  @override
  String get type => 'mousemove';

  @override
  NativeEvent? get native => null;

  @override
  final double x;

  @override
  final double y;

  /// The event of the generator has no `chart` key.
  @override
  types.Chart? get chart => null;
}

/// The `items` of the `hits` of the generator: one JSON line `items[p]` for
/// each point.
List<Object?> hitItems(Object? text) => [
  for (final line in (text! as String).split('\n'))
    if (line.isNotEmpty) jsonDecode(line),
];

/// The `hits` observation for the points and the queries of [expected]:
/// `getElementsAtEventForMode(e, mode, {intersect, axis, includeInvisible},
/// false)` for each point and each query.
///
/// The points and the queries come from the generator (`hitPoints` and
/// `hitQueries` of controller_chart_common.mjs). `items[p][q]` is the list
/// `[[datasetIndex, index], ...]`. The generator writes `items` as text:
/// one JSON line for each point ([hitItems]).
Map<String, Object?> observeHits(Chart chart, Map<String, Object?> expected) {
  final points = expected['points']! as List<Object?>;
  final queries = expected['queries']! as List<Object?>;
  return <String, Object?>{
    'points': points,
    'queries': queries,
    'items': [
      for (final point in points.cast<List<Object?>>())
        [
          for (final query in queries.cast<List<Object?>>())
            [
              for (final item in chart.getElementsAtEventForMode(
                ReferenceEvent(
                  (point[0]! as num).toDouble(),
                  (point[1]! as num).toDouble(),
                ),
                query[0],
                <String, Object?>{
                  'intersect': query[1],
                  'axis': query[2],
                  'includeInvisible': query[3],
                },
                false,
              ))
                [item.datasetIndex, item.index],
            ],
        ],
    ],
  };
}

// ---------------------------------------------------------------------------
// The observations (Chart.js ADR 0030, section 4).

/// The keys of one observation before the keys of `observeExtra` and
/// `hits`.
const List<String> _observationKeys = [
  'chartArea',
  'scales',
  'stacks',
  'datasets',
];

/// The keys of `controller.options` that `datasetOptions` copies, by the
/// dataset type: `DATASET_OPTION_KEYS` of controller_chart_common.mjs.
/// Another type copies no key.
const Map<String, List<String>> _datasetOptionKeys = {
  'bar': [
    'barThickness',
    'maxBarThickness',
    'categoryPercentage',
    'barPercentage',
    'grouped',
    'skipNull',
    'stacked',
    'minBarLength',
  ],
  'line': ['showLine', 'spanGaps', 'segment', 'drawActiveElementsOnTop'],
  'scatter': ['showLine', 'spanGaps', 'segment', 'drawActiveElementsOnTop'],
  'doughnut': _arcDatasetOptionKeys,
  'pie': _arcDatasetOptionKeys,
  'polarArea': ['spacing', 'spacingMode', 'startAngle'],
  'radar': ['showLine', 'spanGaps'],
  'bubble': ['radius'],
};

/// The dataset option keys of `doughnut` and `pie`.
const List<String> _arcDatasetOptionKeys = [
  'cutout',
  'rotation',
  'circumference',
  'radius',
  'offset',
  'spacing',
  'spacingMode',
  'borderAlign',
  'animateRotate',
  'animateScale',
];

/// A guard against a cycle in a plain copy.
const int _maxDepth = 64;

/// A plain copy of [value] for the compare: `plain` of
/// controller_chart_common.mjs.
///
/// - A Map (also a resolver or typed options) becomes a Map with the keys
///   of `jsObjectKeys` and the plain copies of the `jsGet` values.
/// - A List becomes a List of the plain copies.
/// - A function and a class value become `'<fn>'`.
/// - A `types.ChartMetaClip` becomes the object `{top, right, bottom, left,
///   disabled}` of `toClip` (helpers.options.ts).
/// - Other values stay as they are.
Object? plainValue(Object? value, [int depth = 0]) {
  if (depth > _maxDepth) {
    throw StateError('A plain copy of an object with a cycle');
  }
  return switch (value) {
    Function() || JsClass() => '<fn>',
    final types.ChartMetaClip clip => <String, Object?>{
      'top': clip.top,
      'right': clip.right,
      'bottom': clip.bottom,
      'left': clip.left,
      'disabled': clip.disabled,
    },
    final List<Object?> list => [
      for (final item in list) plainValue(item, depth + 1),
    ],
    final Map<String, Object?> map => <String, Object?>{
      for (final key in jsObjectKeys(map))
        key: plainValue(jsGet(map, key), depth + 1),
    },
    _ => value,
  };
}

/// The `options` of [scale] for `scaleOptions`: the plain copy of `grid`,
/// `border`, `ticks` without `callback` and `title`, and for `radialLinear`
/// also `angleLines` and `pointLabels` (`scaleOptionsOf` of
/// controller_chart_common.mjs).
Map<String, Object?> _scaleOptions(Scale scale) {
  final options = scale.options;
  final keys = [
    'grid',
    'border',
    'ticks',
    'title',
    if (scale.type == 'radialLinear') ...['angleLines', 'pointLabels'],
  ];
  return <String, Object?>{
    for (final key in keys)
      key: switch (plainValue(jsGet(options, key))) {
        final Map<String, Object?> ticks when key == 'ticks' =>
          ticks..remove('callback'),
        final value => value,
      },
  };
}

/// The properties of a data element of its class.
List<String> _elementProperties(types.Element element) => switch (element) {
  PointElement() => const ['x', 'y', 'skip', 'stop'],
  BarElement() => const ['x', 'y', 'base', 'horizontal', 'width', 'height'],
  ArcElement() => const [
    'x',
    'y',
    'startAngle',
    'endAngle',
    'innerRadius',
    'outerRadius',
    'circumference',
    'fullCircles',
    'pixelMargin',
  ],
  _ => throw StateError('No properties for the element $element'),
};

/// `[x, y]` of a point.
List<Object?> _xy(types.Point point) => [point.x, point.y];

/// The plain copy of a parsed item: `_stacks` as its keys only.
Object? _parsedItem(Object? item) => switch (item) {
  final Map<String, Object?> map => <String, Object?>{
    for (final key in jsObjectKeys(map))
      key: key == '_stacks'
          ? jsObjectKeys(jsGet(map, key)! as Map<String, Object?>)
          : plainValue(jsGet(map, key)),
  },
  _ => plainValue(item),
};

/// The line element of a dataset, or Dart `null`.
Map<String, Object?>? _datasetElement(types.Element? element) {
  if (element == null) {
    return null;
  }
  final line = element as LineElement;
  return <String, Object?>{
    '_loop': line['_loop'],
    '_fullLoop': line['_fullLoop'],
    'pointCount': line.points.length.toDouble(),
    'segments': [
      for (final s in line.segments) [s.start, s.end, s.loop],
    ],
    'options': plainValue(line.options),
  };
}

/// The `datasets` observation of the dataset [index] of [chart].
Map<String, Object?> _observeDataset(Chart chart, int index) {
  final i = index.toDouble();
  final meta = chart.getDatasetMeta(i);
  final controller = meta.controller!;
  final type = meta['type'];
  final total = meta.total;
  final drawStart = controller.drawStart;
  final drawCount = controller.drawCount;
  final data = meta.data;
  return <String, Object?>{
    'type': type,
    'indexAxis': meta['indexAxis'],
    // linkScales gives a scale id or JS `undefined`
    // (core.datasetController.js:306-308). The Dart field gives Dart `null`
    // for `undefined`.
    'xAxisID': meta.xAxisID ?? undefined,
    'yAxisID': meta.yAxisID ?? undefined,
    'rAxisID': meta['rAxisID'],
    'stack': meta['stack'],
    'order': meta.order,
    'visible': chart.isDatasetVisible(i),
    'hidden': meta.hidden,
    '_clip': plainValue(meta['_clip']),
    'total': ?total,
    '_drawStart': ?drawStart,
    '_drawCount': ?drawCount,
    'maxOverflow': controller.getMaxOverflow(),
    'datasetOptions': <String, Object?>{
      for (final key in _datasetOptionKeys[type] ?? const <String>[])
        if (jsGet(controller.options, key) case final value
            when !identical(value, undefined))
          key: plainValue(value),
    },
    'parsed': [for (final item in meta.parsed) _parsedItem(item)],
    'dataset': _datasetElement(meta.dataset),
    'data': [
      for (final element in data)
        <String, Object?>{
          for (final key in _elementProperties(element))
            key: (element as types.ElementPropertyRead)[key],
          'active': element.active,
          'hidden': element.hidden,
          'center': _xy((element as types.VisualElement).getCenterPoint(false)),
          'tooltipPosition': _xy((element as Element).tooltipPosition(false)),
        },
    ],
    'options': [
      for (final element in data) plainValue((element as Element).options),
    ],
    'active': [
      for (var k = 0; k < data.length; k++)
        plainValue(
          controller.resolveDataElementOptions(k.toDouble(), 'active'),
        ),
    ],
    'labelAndValue': [
      for (var k = 0; k < data.length; k++)
        switch (controller.getLabelAndValue(k.toDouble())) {
          (:final label, :final value) => <String, Object?>{
            'label': plainValue(label),
            'value': value,
          },
        },
    ],
  };
}

/// The observation of [chart] with the keys of `observeControllers` of
/// controller_chart_common.mjs. [scaleOptions] adds `scales.<id>.options`.
/// [expectedHits] gives the points and the queries of `hits`
/// ([observeHits]). Dart `null` for [expectedHits] leaves out `hits` (the
/// option `hits: false` of the generator). [observeExtra] adds its keys
/// after `datasets`, as plain copies ([plainValue]).
Map<String, Object?> observeControllers(
  Chart chart, {
  required Map<String, Object?>? expectedHits,
  bool scaleOptions = false,
  Map<String, Object?> Function(Chart chart)? observeExtra,
}) {
  final base = observeChart(
    chart,
    extra: scaleOptions
        ? (scale, chart) => <String, Object?>{'options': _scaleOptions(scale)}
        : null,
  );
  final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
  final stacks = chart.stacks;
  return <String, Object?>{
    'chartArea': base['chartArea'],
    'scales': base['scales'],
    'stacks': stacks == null ? undefined : plainValue(stacks),
    'datasets': [
      for (var i = 0; i < datasets.length; i++) _observeDataset(chart, i),
    ],
    if (observeExtra != null)
      for (final MapEntry(:key, :value) in observeExtra(chart).entries)
        key: plainValue(value),
    if (expectedHits != null) 'hits': observeHits(chart, expectedHits),
  };
}

// ---------------------------------------------------------------------------
// The colors of the themed run (theming.md section 8 test 3).

/// Whether [key] names a color option: `color` or a key that ends in
/// `Color`.
bool _isColorKey(String key) => key == 'color' || key.endsWith('Color');

/// [value] with each color in its parsed form: `Color(value).rgbString()`.
/// A value that does not parse stays as it is. A List gets the parse of
/// each item.
Object? _parseColor(Object? value) => switch (value) {
  final String s => Color(s).rgbString() ?? s,
  final List<Object?> list => [for (final item in list) _parseColor(item)],
  _ => value,
};

/// [options] with the parsed form of each color option at any depth.
Object? _parseOptionColors(Object? options) => switch (options) {
  final Map<String, Object?> map => <String, Object?>{
    for (final MapEntry(:key, :value) in map.entries)
      key: _isColorKey(key) ? _parseColor(value) : _parseOptionColors(value),
  },
  final List<Object?> list => [
    for (final item in list) _parseOptionColors(item),
  ],
  _ => options,
};

/// [observation] with the parsed form of each color in the options:
/// `options`, `active`, `datasetOptions` and `dataset.options` of each
/// dataset, and `scales.<id>.options`.
Map<String, Object?> _parseObservationColors(
  Map<String, Object?> observation,
) => <String, Object?>{
  ...observation,
  'scales': <String, Object?>{
    for (final MapEntry(:key, :value)
        in (observation['scales']! as Map<String, Object?>).entries)
      key: switch (value) {
        final Map<String, Object?> scale when scale.containsKey('options') =>
          <String, Object?>{
            ...scale,
            'options': _parseOptionColors(scale['options']),
          },
        _ => value,
      },
  },
  'datasets': [
    for (final dataset
        in (observation['datasets']! as List<Object?>)
            .cast<Map<String, Object?>>())
      <String, Object?>{
        ...dataset,
        for (final key in const ['options', 'active', 'datasetOptions'])
          if (dataset.containsKey(key)) key: _parseOptionColors(dataset[key]),
        if (dataset['dataset'] case final Map<String, Object?> line)
          'dataset': <String, Object?>{
            ...line,
            if (line.containsKey('options'))
              'options': _parseOptionColors(line['options']),
          },
      },
  ],
};

/// [observed] with only the keys of [expected] in each Map, at any depth.
/// A key of [expected] that [observed] does not have stays absent, so that
/// the compare fails.
Object? _expectedKeysOnly(Object? observed, Object? expected) =>
    switch ((observed, expected)) {
      (
        final Map<String, Object?> o,
        final Map<String, Object?> e,
      ) =>
        <String, Object?>{
          for (final key in e.keys)
            if (o.containsKey(key)) key: _expectedKeysOnly(o[key], e[key]),
        },
      (final List<Object?> o, final List<Object?> e)
          when o.length == e.length =>
        [for (var i = 0; i < o.length; i++) _expectedKeysOnly(o[i], e[i])],
      _ => observed,
    };

/// [observed] with only the keys of [expected] in the options: the options
/// of the scales and of the datasets of [_parseObservationColors]. The
/// theme of a themed run adds own keys to the options, for example
/// `scales.<id>.options.ticks.font`: upstream has no such key, and
/// [expectNoStaleScaleKeys] checks the emitted keys.
Map<String, Object?> _themedOptions(
  Map<String, Object?> observed,
  Map<String, Object?> expected,
) {
  final scales = observed['scales']! as Map<String, Object?>;
  final expectedScales = expected['scales']! as Map<String, Object?>;
  final datasets = observed['datasets']! as List<Object?>;
  final expectedDatasets = expected['datasets']! as List<Object?>;
  return <String, Object?>{
    ...observed,
    'scales': <String, Object?>{
      for (final MapEntry(:key, :value) in scales.entries)
        key: switch ((value, expectedScales[key])) {
          (
            final Map<String, Object?> scale,
            final Map<String, Object?> expectedScale,
          )
              when scale.containsKey('options') =>
            <String, Object?>{
              ...scale,
              'options': _expectedKeysOnly(
                scale['options'],
                expectedScale['options'],
              ),
            },
          _ => value,
        },
    },
    'datasets': [
      for (var i = 0; i < datasets.length; i++)
        switch ((
          datasets[i],
          i < expectedDatasets.length ? expectedDatasets[i] : null,
        )) {
          (
            final Map<String, Object?> dataset,
            final Map<String, Object?> expectedDataset,
          ) =>
            <String, Object?>{
              ...dataset,
              for (final key in const ['options', 'active', 'datasetOptions'])
                if (dataset.containsKey(key))
                  key: _expectedKeysOnly(dataset[key], expectedDataset[key]),
              if ((dataset['dataset'], expectedDataset['dataset']) case (
                final Map<String, Object?> line,
                final Map<String, Object?> expectedLine,
              ))
                'dataset': <String, Object?>{
                  ...line,
                  'options': _expectedKeysOnly(
                    line['options'],
                    expectedLine['options'],
                  ),
                },
            },
          (final dataset, _) => dataset,
        },
    ],
  };
}

/// The calls with a parsed color argument.
const Set<String> _colorCalls = {'setFillStyle', 'setStrokeStyle'};

/// The recorded calls [calls] with the parsed form of the argument of
/// `setFillStyle` and `setStrokeStyle`.
List<Object?> _parseCallColors(List<Object?> calls) => [
  for (final call in calls.cast<Map<String, Object?>>())
    if (_colorCalls.contains(call['name']))
      <String, Object?>{
        'name': call['name'],
        'args': [
          for (final arg in call['args']! as List<Object?>) _parseColor(arg),
        ],
      }
    else
      call,
];

/// The reference text [text] of the calls with the parsed form of the
/// argument of `setFillStyle` and `setStrokeStyle`.
String _parseCallTextColors(String text) => [
  for (final line in text.split('\n'))
    if (line.isEmpty)
      line
    else
      switch (jsonDecode(line) as List<Object?>) {
        [final String name, ...final args] when _colorCalls.contains(name) =>
          jsonEncode([name, for (final arg in args) _parseColor(arg)]),
        _ => line,
      },
].join('\n');

// ---------------------------------------------------------------------------
// The checks.

/// Expects [chart] to give [expected], an observation of the generator.
/// [label] names the observation in each reason: `initial` or `step <k>`.
/// [parseColors] is for the themed run (theming.md section 8 test 3): each
/// color (the color options and the arguments of `setFillStyle` and
/// `setStrokeStyle`) compares in its parsed form on both sides, and an
/// options Map compares only the keys of the expected Map
/// ([_themedOptions]). Without [parseColors], each Map must have exactly
/// the keys of the expected Map.
///
/// [hits] and [observeExtra] are the options of the plugin reference tests
/// (Chart.js ADR 0041, section 3 item 3). Without [hits], the observation
/// has no `hits`. Each key of [observeExtra] compares with
/// [referenceMatcher]. With [parseColors], the colors of a key of
/// [observeExtra] compare parsed, and its Maps compare only the keys of the
/// expected Map, as the options do.
void expectControllerObservations(
  Chart chart,
  Object? expected,
  String label, {
  bool parseColors = false,
  bool hits = true,
  Map<String, Object?> Function(Chart chart)? observeExtra,
}) {
  var expectedMap = expected! as Map<String, Object?>;
  final scaleOptions = (expectedMap['scales']! as Map<String, Object?>).values
      .any((scale) => (scale! as Map<String, Object?>).containsKey('options'));
  var observed = observeControllers(
    chart,
    expectedHits: hits ? expectedMap['hits']! as Map<String, Object?> : null,
    scaleOptions: scaleOptions,
    observeExtra: observeExtra,
  );
  final extraKeys = [
    for (final key in observed.keys)
      if (!_observationKeys.contains(key) && key != 'hits') key,
  ];
  expect(
    expectedMap.keys,
    unorderedEquals([..._observationKeys, ...extraKeys, if (hits) 'hits']),
    reason: '$label: the keys of the observation',
  );
  if (parseColors) {
    observed = _parseObservationColors(observed);
    expectedMap = _parseObservationColors(expectedMap);
    observed = _themedOptions(observed, expectedMap);
    for (final key in extraKeys) {
      expectedMap = {...expectedMap, key: _parseOptionColors(expectedMap[key])};
      observed = {
        ...observed,
        key: _expectedKeysOnly(
          _parseOptionColors(observed[key]),
          expectedMap[key],
        ),
      };
    }
  }

  expectScaleObservations(
    {'chartArea': observed['chartArea'], 'scales': observed['scales']},
    {'chartArea': expectedMap['chartArea'], 'scales': expectedMap['scales']},
    label: label,
  );

  expect(
    observed['stacks'],
    referenceMatcher(expectedMap['stacks']),
    reason: '$label: stacks',
  );
  _expectKeyOrder(observed['stacks'], expectedMap['stacks'], '$label: stacks');

  final datasets = observed['datasets']! as List<Object?>;
  final expectedDatasets = expectedMap['datasets']! as List<Object?>;
  expect(
    datasets.length,
    expectedDatasets.length,
    reason: '$label: the dataset count',
  );
  for (var i = 0; i < expectedDatasets.length; i++) {
    final dataset = datasets[i]! as Map<String, Object?>;
    final expectedDataset = expectedDatasets[i]! as Map<String, Object?>;
    expect(
      dataset.keys,
      unorderedEquals(expectedDataset.keys),
      reason: '$label: the keys of datasets.$i',
    );
    for (final key in expectedDataset.keys) {
      expect(
        dataset[key],
        referenceMatcher(expectedDataset[key]),
        reason: '$label: datasets.$i.$key',
      );
    }
  }

  for (final key in extraKeys) {
    expect(
      observed[key],
      referenceMatcher(expectedMap[key]),
      reason: '$label: $key',
    );
  }

  if (!hits) {
    return;
  }
  final observedHits = observed['hits']! as Map<String, Object?>;
  final expectedHits = expectedMap['hits']! as Map<String, Object?>;
  expect(
    expectedHits.keys,
    unorderedEquals(['points', 'queries', 'items']),
    reason: '$label: the keys of hits',
  );
  expect(
    observedHits['items'],
    equals(hitItems(expectedHits['items'])),
    reason:
        '$label: hits (items[point][query], see hits.points and '
        'hits.queries)',
  );
}

/// Expects the keys of each Map in [observed] to have the order of the keys
/// of the same Map in [expected] (the stacks keys, Chart.js ADR 0030,
/// section 4).
void _expectKeyOrder(Object? observed, Object? expected, String reason) {
  if (observed is Map<String, Object?> && expected is Map<String, Object?>) {
    expect(
      observed.keys,
      orderedEquals(expected.keys),
      reason: '$reason: the key order',
    );
    for (final MapEntry(:key, :value) in expected.entries) {
      _expectKeyOrder(observed[key], value, '$reason.$key');
    }
  }
}

/// Applies one step of a case ([step] is the `do` list of the generator,
/// `applyStep` of controller_chart_common.mjs).
///
/// `push` and `splice` change the data List first and then call
/// [notifyArrayListeners], as the hooked array methods do (differences.md
/// `platform-array-events`). `hover`, `mouseout` and `click` dispatch a
/// native event through [triggerMouseEvent] (Chart.js ADR 0022, section 6).
/// The generator gives `mouseout` the point of the last `hover` or `click`.
/// It writes the steps `clickLegend` and `hoverLegend` as `click` and
/// `hover` at the rounded center of the legend hit box. Thus they never
/// reach this function (Chart.js ADR 0041, section 3 item 6). `setOption`
/// writes the value at the path (`plugins.title.display`) through
/// `operator []=` of the option resolver, the `set` trap of upstream, and
/// then updates the chart (Chart.js ADR 0041, section 3 item 6).
/// `setTooltip` calls `setActiveElements` of `chart.tooltip` through
/// `types.TooltipModel` with the Maps `{datasetIndex, index}` and the event
/// position `{x, y}`, and then updates the chart (Chart.js ADR 0039,
/// section 14). Without the tooltip plugin, `chart.tooltip` is `null`, and
/// the null check throws a [TypeError], as the JS read of `undefined` does.
Future<void> runStep(
  WidgetTester tester,
  Chart chart,
  List<Object?> step,
) async {
  switch (step) {
    case ['update']:
      chart.update();
    case ['update', final String mode]:
      chart.update(mode);
    case ['setDatasetVisibility', final num d, final bool v]:
      chart
        ..setDatasetVisibility(d.toDouble(), v)
        ..update();
    case ['toggleDataVisibility', final num i]:
      chart
        ..toggleDataVisibility(i.toDouble())
        ..update();
    case ['setActive', final List<Object?> items]:
      chart
        ..setActiveElements([
          for (final [d, i] in items.cast<List<Object?>>())
            <String, Object?>{'datasetIndex': d, 'index': i},
        ])
        ..update();
    case ['push', final num d, ...final values]:
      final data = _data(chart, d)..addAll(values);
      notifyArrayListeners(data, 'push', values);
      chart.update();
    case [
      'splice',
      final num d,
      final num start,
      final num count,
      ...final items,
    ]:
      final data = _data(chart, d);
      jsSplice(data, start.toDouble(), count.toDouble(), items);
      notifyArrayListeners(data, 'splice', [start, count, ...items]);
      chart.update();
    case ['reset']:
      chart.reset();
    case ['hover', final num x, final num y]:
      await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
        'x': x,
        'y': y,
      });
    case ['mouseout', final num x, final num y]:
      await triggerMouseEvent(chart, 'mouseout', <String, Object?>{
        'x': x,
        'y': y,
      });
    case ['click', final num x, final num y]:
      await triggerMouseEvent(chart, 'click', <String, Object?>{
        'x': x,
        'y': y,
      });
    case ['setTooltip', final List<Object?> items, final num x, final num y]:
      chart.tooltip!.setActiveElements(
        [
          for (final [d, i] in items.cast<List<Object?>>())
            <String, Object?>{'datasetIndex': d, 'index': i},
        ],
        <String, Object?>{'x': x, 'y': y},
      );
      chart.update();
    case ['setOption', final String path, final Object? value]:
      final keys = path.split('.');
      Object? target = chart.options;
      for (final key in keys.take(keys.length - 1)) {
        target = jsGet(target, key);
      }
      (target! as Map<String, Object?>)[keys.last] = copyReference(value);
      chart.update();
    default:
      throw ArgumentError.value(step, 'step', 'Not a reference step');
  }
}

/// The data List of the dataset [d] of [chart]:
/// `chart.data.datasets[d].data`. An absent dataset throws the
/// [TypeError] of the JS property read of `undefined`.
List<Object?> _data(Chart chart, num d) {
  final datasets = jsGet(chart.data, 'datasets');
  return jsGet(jsGetIndex(datasets, d.toDouble()), 'data')! as List<Object?>;
}

/// The keys of the expected Map of a case.
const Set<String> _caseKeys = {
  'initial',
  'steps',
  'drawCalls',
  'extra',
  'error',
};

/// The Dart matchers of the JS error names of the `error` key. A JS
/// `TypeError` is a Dart [TypeError] (Chart.js ADR 0030, section 4).
final Map<String, Matcher> _defaultErrorTypes = {
  'TypeError': isA<TypeError>(),
};

/// The matcher of the throw of the error [error] `{at, name}` of a case.
Matcher _throwsError(
  Map<String, Object?> error,
  Map<String, Matcher> errorTypes,
) {
  final name = error['name']! as String;
  final matcher = errorTypes[name] ?? _defaultErrorTypes[name];
  if (matcher == null) {
    fail(
      'The JS error $name of the case has no Dart type: map it in the test '
      'file, with the differences.md row that gives the Dart type.',
    );
  }
  return throwsA(matcher);
}

/// A deep copy of [value] for the compare of `defaults` before and after a
/// themed case: Maps and Lists are copies, other values stay as they are.
Object? _snapshot(Object? value, [int depth = 0]) {
  if (depth > _maxDepth) {
    throw StateError('A snapshot of an object with a cycle');
  }
  return switch (value) {
    final List<Object?> list => [
      for (final item in list) _snapshot(item, depth + 1),
    ],
    final Map<String, Object?> map => <String, Object?>{
      for (final key in jsObjectKeys(map))
        key: _snapshot(jsGet(map, key), depth + 1),
    },
    _ => value,
  };
}

/// A `testWidgets` case for each of [cases]: `acquireChart` with the config
/// and the options of the case ([copyReference] with [functions]), the
/// observations of `initial`, each step and its observations, then the
/// draw calls, then the probes of `extra` through [extras]. An `error` of
/// the case expects a throw at its place (Chart.js ADR 0030, section 4):
/// a JS `TypeError` is a Dart [TypeError], and [errorTypes] maps other JS
/// names to Dart matchers. With [theme], the config gets
/// `themeConfigKey: theme`, the colors compare parsed, `defaults` must be
/// the same after the case, and the cases whose names start with
/// `parsed:` or `interfaces:` do not run. With [now], each case runs in
/// `atNow(now, ...)`. [hits] and [observeExtra] go to each
/// [expectControllerObservations] call (Chart.js ADR 0041, section 3 item
/// 3): `testPluginChartCases` of `test/port/plugins/plugin_chart_harness.dart`
/// sets them.
///
/// A step that throws stands in `steps` with its `do` and without
/// `observations`, and the `error` of the case has its `at`.
void testControllerChartCases(
  List<ScaleChartCase> cases, {
  Map<String, Object?> functions = const {},
  Map<String, Object? Function(Chart chart)> extras = const {},
  AnyObject? theme,
  double? now,
  Map<String, Matcher> errorTypes = const {},
  bool hits = true,
  Map<String, Object?> Function(Chart chart)? observeExtra,
}) {
  for (final c in cases) {
    if (theme != null &&
        (c.name.startsWith('parsed:') || c.name.startsWith('interfaces:'))) {
      continue;
    }
    testWidgets(c.name, (tester) async {
      Future<void> body() => _runControllerCase(
        tester,
        c,
        functions: functions,
        extras: extras,
        theme: theme,
        errorTypes: errorTypes,
        hits: hits,
        observeExtra: observeExtra,
      );
      if (now == null) {
        await body();
      } else {
        await atNow(now, body);
      }
    });
  }
}

/// The body of one case of [testControllerChartCases]. A themed case
/// compares `defaults` with its state before the case after each end of
/// [_runCaseSteps], also after an expected error (Chart.js ADR 0030,
/// section 8).
Future<void> _runControllerCase(
  WidgetTester tester,
  ScaleChartCase c, {
  required Map<String, Object?> functions,
  required Map<String, Object? Function(Chart chart)> extras,
  required AnyObject? theme,
  required Map<String, Matcher> errorTypes,
  required bool hits,
  required Map<String, Object?> Function(Chart chart)? observeExtra,
}) async {
  final defaultsBefore = theme == null ? null : _snapshot(defaults);
  await _runCaseSteps(
    tester,
    c,
    functions: functions,
    extras: extras,
    theme: theme,
    errorTypes: errorTypes,
    hits: hits,
    observeExtra: observeExtra,
  );
  if (defaultsBefore != null) {
    expect(
      _snapshot(defaults),
      equals(defaultsBefore),
      reason: 'defaults after the themed case',
    );
  }
}

/// The steps of one case of [_runControllerCase]: the chart, the
/// observations, the draw calls and the probes. An expected error ends the
/// steps.
Future<void> _runCaseSteps(
  WidgetTester tester,
  ScaleChartCase c, {
  required Map<String, Object?> functions,
  required Map<String, Object? Function(Chart chart)> extras,
  required AnyObject? theme,
  required Map<String, Matcher> errorTypes,
  required bool hits,
  required Map<String, Object?> Function(Chart chart)? observeExtra,
}) async {
  final expected = c.expected;
  expect(
    expected.keys.where((key) => !_caseKeys.contains(key)),
    isEmpty,
    reason: 'the keys of the reference case',
  );
  final error = expected['error'] as Map<String, Object?>?;
  final at = error?['at'];
  final parseColors = theme != null;
  final config = copyReference(c.config, functions)! as AnyObject;
  if (theme != null) {
    config[themeConfigKey] = theme;
  }
  final options = copyReference(c.options)! as AnyObject;

  if (at == 'initial') {
    expect(
      () => acquireChart(config, options),
      _throwsError(error!, errorTypes),
      reason: 'initial: the error of the generator',
    );
    return;
  }
  final chart = acquireChart(config, options);
  expectControllerObservations(
    chart,
    expected['initial'],
    'initial',
    parseColors: parseColors,
    hits: hits,
    observeExtra: observeExtra,
  );

  final steps = expected['steps']! as List<Object?>;
  for (var k = 0; k < steps.length; k++) {
    final step = steps[k]! as Map<String, Object?>;
    final action = step['do']! as List<Object?>;
    if (!step.containsKey('observations')) {
      expect(at, 'step $k', reason: 'step $k: a step without observations');
      expect(
        step.keys,
        ['do'],
        reason: 'step $k: the keys of the step that throws',
      );
      await expectLater(
        () => runStep(tester, chart, action),
        _throwsError(error!, errorTypes),
        reason: 'step $k: the error of the generator',
      );
      return;
    }
    expect(
      step.keys,
      unorderedEquals(['do', 'observations']),
      reason: 'step $k: the keys of the step',
    );
    await runStep(tester, chart, action);
    expectControllerObservations(
      chart,
      step['observations'],
      'step $k',
      parseColors: parseColors,
      hits: hits,
      observeExtra: observeExtra,
    );
  }

  if (at == 'draw') {
    expect(
      () => drawCalls(chart),
      _throwsError(error!, errorTypes),
      reason: 'draw: the error of the generator',
    );
    return;
  }
  expect(error, isNull, reason: 'an error of the generator at $at');
  final calls = drawCalls(chart);
  final expectedCalls = expected['drawCalls']! as String;
  expectCalls(
    parseColors ? _parseCallColors(calls) : calls,
    parseColors ? _parseCallTextColors(expectedCalls) : expectedCalls,
    reason: 'draw',
  );

  if (expected['extra'] case final Map<String, Object?> extra) {
    for (final MapEntry(:key, :value) in extra.entries) {
      final probe = extras[key];
      if (probe == null) {
        fail('The probe $key of the generator has no Dart function');
      }
      expect(
        plainValue(probe(chart)),
        referenceMatcher(value),
        reason: 'extra: $key',
      );
    }
  }
}

/// Expects no stale key of the light snapshot in the scale options of
/// [chart] (theming.md section 8 test 3).
///
/// Each emitted path of [lightSnapshot] under `scale.` must be in the
/// observed `scales.<id>.options` of each scale, and each path under
/// `scales.<type>.` in the options of each scale of that type. A path that
/// is not there fails as a stale key.
void expectNoStaleScaleKeys(Chart chart, Map<String, Object?> lightSnapshot) {
  for (final MapEntry(key: id, value: scale) in chart.scales.entries) {
    final options = _scaleOptions(scale);
    final prefixes = ['scale.', 'scales.${scale.type}.'];
    for (final path in lightSnapshot.keys) {
      final prefix = prefixes.where(path.startsWith).firstOrNull;
      if (prefix == null) {
        continue;
      }
      Object? node = options;
      for (final key in path.substring(prefix.length).split('.')) {
        node = node is Map<String, Object?> && node.containsKey(key)
            ? node[key]
            : undefined;
      }
      expect(
        identical(node, undefined),
        isFalse,
        reason: 'the stale key $path in scales.$id.options',
      );
    }
  }
}
