// Original code, not ported from Chart.js: the twins of Chart.js ADR 0111.
@TestOn('vm')
library;

import 'dart:ui' show Color;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/controllers/controller.line.dart';
import 'package:flutter_chartjs_port/src/core/core.animation.dart';
import 'package:flutter_chartjs_port/src/core/core.animator.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show Config, themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show controllerArgs;
import 'package:flutter_chartjs_port/src/core/core.interaction.dart'
    show
        DatasetInteractionMode,
        IndexInteractionMode,
        InteractionAxis,
        InteractionMode,
        NearestInteractionMode,
        PointInteractionMode,
        XInteractionMode,
        YInteractionMode;
import 'package:flutter_chartjs_port/src/core/date_adapter.dart'
    show defaultDateZone, setDefaultDateZone;
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show OptionView;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.decimation.dart'
    show LttbDecimationAlgorithm;
import 'package:flutter_chartjs_port/src/plugins/plugin.title.dart' show Title;
import 'package:flutter_chartjs_port/src/types/layout.dart' show ChartPosition;
import 'package:flutter_chartjs_port/src/types/plugin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/light_theme.dart';
import '../controllers/controller_chart_harness.dart';
import '../scales/scale_chart_harness.dart' show drawCalls;

// Chart.js ADR 0111, section 9: two charts of one config take the same
// writes of `min` and `max` through the views of the scale options. One
// takes `update(mode)`, the other `updateRanges(mode)`. The observations of
// the controller harness, the hits, the boxes, the hooks, the calls of the
// scriptable options and the draw calls compare after each step, and at the
// end of the animations.

/// The hooks and the calls of the scriptable options of one chart.
final class _Log {
  final List<String> entries = <String>[];

  void add(String entry) => entries.add(entry);

  /// The context [ctx] of a scriptable option [name]: its type and indexes.
  void context(String name, Object? ctx) {
    String read(String key) {
      final value = jsGet(ctx, key);
      return identical(value, undefined) ? '-' : '${plainValue(value)}';
    }

    add(
      '$name type=${read('type')} index=${read('index')} '
      'datasetIndex=${read('datasetIndex')} dataIndex=${read('dataIndex')} '
      'mode=${read('mode')} active=${read('active')}',
    );
  }
}

/// The names of the hooks of [Plugin], without `id`, `events`, `defaults`
/// and the other keys that are no hook.
final List<String> _hookNames = [
  for (final hook in PluginHook.values) hook.jsName,
];

/// The text of a mode for the log: a function is `<fn>`.
String _mode(Object? mode) => mode is Function ? '<fn>' : '$mode';

/// An inline plugin that logs each hook with the mode and the index of its
/// arguments. It opts into the partial lifecycles.
Map<String, Object?> _recorder(_Log log) => <String, Object?>{
  'id': 'rangeRecorder',
  'supportsDataUpdates': true,
  for (final name in _hookNames)
    name: (Object? chart, Object? args, Object? options) {
      final text = switch (args) {
        final UpdateHookArgs a => ' mode=${_mode(a.mode)}',
        final DatasetUpdateHookArgs a =>
          ' index=${a.index} mode=${_mode(a.mode)}',
        final DatasetDrawHookArgs a => ' index=${a.index}',
        final EventHookArgs a => ' ${a.event?.type} replay=${a.replay}',
        _ => '',
      };
      log.add('$name$text');
      return null;
    },
};

/// The scriptable options of the ADR: the title text, `layout.padding`, a
/// dataset `clip`, a scale `ticks.color` and `grid.display`. Each logs its
/// context. The title text shows the range options of the scale [axis] and
/// its last range: the layout fits the title before the scales, so
/// `scale.min` and `scale.max` are those of the last update, in both paths.
Map<String, Object?> _titleOf(_Log log, String axis) => <String, Object?>{
  'display': true,
  'text': (Object? ctx) {
    log.context('title.text', ctx);
    final chart = jsGet(ctx, 'chart')! as Chart;
    final scale = chart.scales[axis];
    if (scale == null) return 'none';
    final options = scale.options;
    return '$axis ${plainValue(jsGet(options, 'min'))} to '
        '${plainValue(jsGet(options, 'max'))}, was ${scale.min} to '
        '${scale.max}';
  },
};

Object? Function(Object?) _padding(_Log log) => (ctx) {
  log.context('layout.padding', ctx);
  return const EdgeInsets.all(4);
};

Object? Function(Object?) _clip(_Log log) => (ctx) {
  log.context('clip', ctx);
  return 2.0;
};

Map<String, Object?> _ticks(_Log log) => <String, Object?>{
  'color': (Object? ctx) {
    log.context('ticks.color', ctx);
    // A read through the scale view has the scale context, with no index.
    final index = jsGet(ctx, 'index');
    return index is num && index % 2 == 0
        ? const Color(0xff336699)
        : const Color(0xff993366);
  },
};

Map<String, Object?> _grid(_Log log) => <String, Object?>{
  'display': (Object? ctx) {
    log.context('grid.display', ctx);
    return true;
  },
};

/// The `animation` option of a run: `false`, or a scriptable option that
/// gives a short animation.
Object? _animation(_Log log, {required bool animated}) => animated
    ? (Object? ctx) {
        log.context('animation', ctx);
        return <String, Object?>{'duration': 120.0};
      }
    : false;

/// The points `{x, y}` of a line of [count] points.
List<Object?> _points(int count, double shift) => <Object?>[
  for (var i = 0; i < count; i++)
    <String, Object?>{
      'x': i.toDouble(),
      'y': 5 + 4 * ((i * 7 + shift) % 9) / 9,
    },
];

/// A config of a case: the chart options of `options` with the recorder,
/// the title, the padding and the animation of the run.
Map<String, Object?> _config(
  _Log log, {
  required bool animated,
  required String type,
  required Map<String, Object?> data,
  required Map<String, Object?> scales,
  String titleAxis = 'x',
  Map<String, Object?> plugins = const {},
  Map<String, Object?> extra = const {},
}) => <String, Object?>{
  'type': type,
  'plugins': <Object?>[_recorder(log)],
  'data': data,
  'options': <String, Object?>{
    'animation': _animation(log, animated: animated),
    'layout': <String, Object?>{'padding': _padding(log)},
    'scales': scales,
    'plugins': <String, Object?>{
      'title': _titleOf(log, titleAxis),
      ...plugins,
    },
    ...extra,
  },
};

/// A scale option Map with the scriptable ticks and grid.
Map<String, Object?> _scale(
  _Log log,
  String type, [
  Map<String, Object?> more = const {},
]) => <String, Object?>{
  'type': type,
  'ticks': _ticks(log),
  'grid': _grid(log),
  ...more,
};

/// A step: the writes of the ranges, the same on both charts.
typedef _Write = void Function(Chart chart);

/// The options view of the scale [id] of [chart].
JsObjectFace _options(Chart chart, String id) => chart.scales[id]!.options;

/// `scale.options.min = min` and `scale.options.max = max`.
_Write _range(String id, Object? min, Object? max) => (chart) {
  _options(chart, id)
    ..jsWrite('min', min)
    ..jsWrite('max', max);
};

/// `chart.options.scales[id].min = min`: the write through the chart view.
_Write _chartViewRange(String id, Object? min, Object? max) => (chart) {
  final scales = chart.options.jsRead('scales')! as JsObjectFace;
  (scales.jsRead(id)! as JsObjectFace)
    ..jsWrite('min', min)
    ..jsWrite('max', max);
};

/// `delete scale.options.min` and `delete scale.options.max`.
_Write _reset(List<String> ids) => (chart) {
  for (final id in ids) {
    _options(chart, id)
      ..jsDelete('min')
      ..jsDelete('max');
  }
};

/// A new data List for the dataset [index] and, for a category chart, new
/// labels: allowed by the contract.
_Write _newData(int index, List<Object?> Function() values, {int? labels}) =>
    (chart) {
      final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
      (datasets[index]! as Map<String, Object?>)['data'] = values();
      if (labels != null) {
        (chart.data as Map<String, Object?>)['labels'] = <Object?>[
          for (var i = 0; i < labels; i++) 'L$i',
        ];
      }
    };

/// Each step writes, then updates in the next mode of the run.
final class _Case {
  const _Case(this.name, this.build, this.steps, {this.zone});

  final String name;
  final Map<String, Object?> Function(_Log log, {required bool animated}) build;
  final List<_Write> steps;

  /// The default date zone of the case: Dart `null` keeps the zone of the
  /// test configuration, `'local'` is the local zone.
  final String? zone;
}

/// The modes of the steps: `'none'`, `'zoom'`, `'default'` and a function
/// of `{datasetIndex}`.
final List<Object?> _modes = <Object?>[
  'none',
  'zoom',
  'default',
  (Object? ctx) => jsGet(ctx, 'datasetIndex') == 0 ? 'zoom' : 'none',
  undefined,
];

/// The hits on a grid of the canvas, for the modes of the interactions.
Map<String, Object?> _hits(Chart chart) => observeHits(chart, <String, Object?>{
  'points': <Object?>[
    for (var x = 20; x < chart.width; x += 70)
      for (var y = 20; y < chart.height; y += 60) <Object?>[x, y],
  ],
  'queries': <Object?>[
    for (final mode in const <InteractionMode>[
      PointInteractionMode(),
      NearestInteractionMode(),
      IndexInteractionMode(),
      DatasetInteractionMode(),
      XInteractionMode(),
      YInteractionMode(),
    ])
      for (final intersect in [true, false])
        <Object?>[mode, intersect, InteractionAxis.xy, false],
  ],
});

/// The boxes of the layout: their order, positions, weights and boxes.
List<Object?> _boxes(Chart chart) => [
  for (final box in chart.boxes)
    <Object?>[
      box.runtimeType.toString(),
      plainValue(box.position),
      plainValue(box.weight),
      box.fullSize,
      box.left,
      box.top,
      box.width,
      box.height,
    ],
];

/// [value] with NaN as text, as `equals` compares NaN as unequal, and an
/// [Animation] as its fields. The start time of an animation is left out:
/// the hover animations of the twins start one frame apart, because the
/// mouse events of the set-up arrive one frame apart. The animations of a
/// step start in the same frame, and their values compare while they run.
Object? _canon(Object? value) => switch (value) {
  final double d when d.isNaN => 'NaN',
  final Animation a => _canon(<Object?>[
    'animation',
    a.duration,
    a.total,
    a.loop,
    plainValue(a.from),
    plainValue(a.to),
    a.active(),
  ]),
  final Map<Object?, Object?> map => {
    for (final MapEntry(:key, :value) in map.entries) key: _canon(value),
  },
  final List<Object?> list => [for (final item in list) _canon(item)],
  _ => value,
};

/// The observation of [chart] after an update.
Object? _observe(Chart chart) => _canon(<String, Object?>{
  'controllers': observeControllers(
    chart,
    expectedHits: null,
    scaleOptions: true,
  ),
  'hits': _hits(chart),
  'boxes': _boxes(chart),
  'active': [
    for (final item in chart.getActiveElements())
      [item.datasetIndex, item.index],
  ],
  'tooltip': chart.tooltip == null
      ? null
      : <Object?>[
          chart.tooltip!.opacity,
          plainValue(jsGet(chart.tooltip, 'title')),
          chart.tooltip!.caretX,
          chart.tooltip!.caretY,
        ],
  'calls': drawCalls(chart),
});

/// The logs and the observations of both charts are equal.
void _expectTwins(
  Chart full,
  _Log fullLog,
  Chart ranges,
  _Log rangeLog,
  String reason,
) {
  expect(rangeLog.entries, fullLog.entries, reason: '$reason: the log');
  fullLog.entries.clear();
  rangeLog.entries.clear();
  expect(_observe(ranges), _observe(full), reason: reason);
}

/// Runs the steps of [c] on twins, with or without animations.
Future<void> _runCase(_Case c, {required bool animated}) async {
  final previousZone = defaultDateZone;
  if (c.zone == 'local') {
    setDefaultDateZone(null);
    addTearDown(() => setDefaultDateZone(previousZone));
  }
  final fullLog = _Log();
  final rangeLog = _Log();
  final full = acquireChart(c.build(fullLog, animated: animated));
  final ranges = acquireChart(c.build(rangeLog, animated: animated));
  if (animated) {
    await pumpFrames(() => !animator.has(full) && !animator.has(ranges));
  }
  // A move onto the chart: each update replays it.
  for (final chart in [full, ranges]) {
    await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
      'x': chart.chartArea!.left + chart.chartArea!.width * 0.4,
      'y': chart.chartArea!.top + chart.chartArea!.height * 0.5,
    });
  }
  if (animated) {
    await pumpFrames(() => !animator.has(full) && !animator.has(ranges));
  }
  _expectTwins(full, fullLog, ranges, rangeLog, '${c.name}: start');
  for (var i = 0; i < c.steps.length; i++) {
    final mode = _modes[i % _modes.length];
    final reason = '${c.name}: step $i, mode ${_mode(mode)}';
    c.steps[i](full);
    c.steps[i](ranges);
    full.update(mode);
    expect(ranges.updateRanges(mode), isTrue, reason: reason);
    _expectTwins(full, fullLog, ranges, rangeLog, reason);
    if (animated) {
      // Half the animation, then its end.
      await pumpFrames(() => true);
      for (var f = 0; f < 3; f++) {
        await pumpFrames(() => true);
      }
      _expectTwins(full, fullLog, ranges, rangeLog, '$reason: running');
      await pumpFrames(() => !animator.has(full) && !animator.has(ranges));
      _expectTwins(full, fullLog, ranges, rangeLog, '$reason: done');
    }
  }
}

/// The line chart on linear axes.
Map<String, Object?> _line(_Log log, {required bool animated}) => _config(
  log,
  animated: animated,
  type: 'line',
  data: <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'a',
        'data': _points(16, 0),
        'clip': _clip(log),
        'pointRadius': 3.0,
      },
    ],
  },
  scales: <String, Object?>{
    'x': _scale(log, 'linear'),
    'y': _scale(log, 'linear'),
  },
);

/// The scatter chart.
Map<String, Object?> _scatter(_Log log, {required bool animated}) => _config(
  log,
  animated: animated,
  type: 'scatter',
  data: <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{'label': 'a', 'data': _points(20, 3)},
      <String, Object?>{'label': 'b', 'data': _points(12, 5)},
    ],
  },
  scales: <String, Object?>{
    'x': _scale(log, 'linear'),
    'y': _scale(log, 'linear'),
  },
);

/// The bar chart on a category axis.
Map<String, Object?> _bar(_Log log, {required bool animated}) => _config(
  log,
  animated: animated,
  type: 'bar',
  data: <String, Object?>{
    'labels': <Object?>[for (var i = 0; i < 10; i++) 'L$i'],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'a',
        'data': <Object?>[for (var i = 0; i < 10; i++) 1.0 + (i * 3) % 7],
        'clip': _clip(log),
      },
    ],
  },
  scales: <String, Object?>{
    'x': _scale(log, 'category'),
    'y': _scale(log, 'linear'),
  },
);

/// The time of day [i] of November 2026, in milliseconds.
double _day(int i) =>
    DateTime.utc(2026, 11, 1 + i).millisecondsSinceEpoch.toDouble();

/// The line chart on a time axis.
Map<String, Object?> _time(_Log log, {required bool animated}) => _config(
  log,
  animated: animated,
  type: 'line',
  data: <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'a',
        'data': <Object?>[
          for (var i = 0; i < 20; i++)
            <String, Object?>{'x': _day(i), 'y': 1.0 + (i * 5) % 7},
        ],
      },
    ],
  },
  scales: <String, Object?>{
    'x': _scale(log, 'time'),
    'y': _scale(log, 'linear'),
  },
);

/// The line chart on a logarithmic y axis.
Map<String, Object?> _logarithmic(_Log log, {required bool animated}) =>
    _config(
      log,
      animated: animated,
      type: 'line',
      titleAxis: 'y',
      data: <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'label': 'a',
            'data': <Object?>[
              for (var i = 0; i < 12; i++)
                <String, Object?>{'x': i.toDouble(), 'y': 1.0 + i * i * 9},
            ],
          },
        ],
      },
      scales: <String, Object?>{
        'x': _scale(log, 'linear'),
        'y': _scale(log, 'logarithmic'),
      },
    );

/// A radial chart: `radar` or `polarArea` on the scale `r`.
Map<String, Object?> Function(_Log log, {required bool animated}) _radial(
  String type,
) =>
    (log, {required animated}) => _config(
      log,
      animated: animated,
      type: type,
      titleAxis: 'r',
      data: <String, Object?>{
        'labels': <Object?>[for (var i = 0; i < 6; i++) 'L$i'],
        'datasets': <Object?>[
          <String, Object?>{
            'label': 'a',
            'data': <Object?>[for (var i = 0; i < 6; i++) 2.0 + (i * 3) % 7],
          },
        ],
      },
      scales: <String, Object?>{
        'r': <String, Object?>{'type': 'radialLinear', 'ticks': _ticks(log)},
      },
    );

/// Two datasets on two y axes.
Map<String, Object?> _twoAxes(_Log log, {required bool animated}) => _config(
  log,
  animated: animated,
  type: 'line',
  titleAxis: 'y2',
  data: <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{'label': 'a', 'data': _points(12, 1), 'yAxisID': 'y'},
      <String, Object?>{
        'label': 'b',
        'data': <Object?>[
          for (var i = 0; i < 12; i++)
            <String, Object?>{'x': i.toDouble(), 'y': 100.0 + i * 13},
        ],
        'yAxisID': 'y2',
      },
    ],
  },
  scales: <String, Object?>{
    'x': _scale(log, 'linear'),
    'y': _scale(log, 'linear'),
    'y2': _scale(log, 'linear', <String, Object?>{
      'position': ChartPosition.right,
    }),
  },
);

/// A line of 400 points with enabled decimation.
Map<String, Object?> _decimation(_Log log, {required bool animated}) => _config(
  log,
  animated: animated,
  type: 'line',
  data: <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'a',
        'data': <Object?>[
          for (var i = 0; i < 400; i++)
            <String, Object?>{
              'x': i.toDouble(),
              'y': ((i * 37) % 101).toDouble(),
            },
        ],
        'pointRadius': 0.0,
      },
    ],
  },
  scales: <String, Object?>{
    'x': _scale(log, 'linear'),
    'y': _scale(log, 'linear'),
  },
  plugins: <String, Object?>{
    'decimation': <String, Object?>{
      'enabled': true,
      'algorithm': const LttbDecimationAlgorithm(),
      'samples': 40.0,
    },
  },
  extra: <String, Object?>{'parsing': false},
);

/// The line chart under the light theme.
Map<String, Object?> _themed(_Log log, {required bool animated}) =>
    _line(log, animated: animated)..[themeConfigKey] = compileLightTheme();

/// The steps of a chart on the linear axes `x` and `y`.
final List<_Write> _xySteps = [
  _range('x', 2.0, 9.0),
  _range('x', 3.0, 10.0),
  _chartViewRange('y', 4.0, 8.0),
  _reset(['x', 'y']),
  _range('x', 1.0, 6.0),
  _newData(0, () => _points(18, 4)),
  _range('y', 5.5, 7.5),
  _reset(['x', 'y']),
];

final List<_Case> _cases = [
  _Case('line', _line, _xySteps),
  _Case('scatter', _scatter, _xySteps),
  _Case('bar', _bar, [
    _range('x', 'L2', 'L7'),
    _range('x', 3.0, 8.0),
    _chartViewRange('y', 0.0, 5.0),
    _reset(['x', 'y']),
    _newData(
      0,
      () => <Object?>[for (var i = 0; i < 12; i++) 2.0 + i % 5],
      labels: 12,
    ),
    _range('x', 'L5', 'L11'),
    _reset(['x']),
  ]),
  _Case('time UTC', _time, [
    _range('x', _day(3), _day(12)),
    _range('x', _day(5), _day(6)),
    _chartViewRange('y', 2.0, 6.0),
    _reset(['x', 'y']),
    _range('x', '2026-11-04', '2026-11-09'),
    _reset(['x']),
  ]),
  _Case(
    'time local',
    _time,
    [
      _range('x', _day(3), _day(12)),
      _range('x', _day(5), _day(6)),
      _reset(['x']),
    ],
    zone: 'local',
  ),
  _Case('logarithmic', _logarithmic, [
    _range('y', 2.0, 500.0),
    _range('y', 10.0, 100.0),
    _reset(['y']),
    _range('x', 2.0, 8.0),
  ]),
  _Case('radar', _radial('radar'), [
    _range('r', 1.0, 6.0),
    _range('r', 3.0, 9.0),
    _reset(['r']),
  ]),
  _Case('polar area', _radial('polarArea'), [
    _range('r', 1.0, 6.0),
    _chartViewRange('r', 0.0, 12.0),
    _reset(['r']),
  ]),
  _Case('two y axes', _twoAxes, [
    _range('y2', 120.0, 200.0),
    _range('x', 2.0, 9.0),
    _chartViewRange('y', 5.0, 8.0),
    _reset(['x', 'y', 'y2']),
  ]),
  _Case('decimation', _decimation, [
    _range('x', 20.0, 300.0),
    _range('x', 100.0, 140.0),
    _range('x', 150.0, 250.0),
    _reset(['x']),
  ]),
  _Case('theme', _themed, _xySteps),
];

// ---------------------------------------------------------------------------
// The other cases.

/// A small line chart with the recorder, on the axes x and y.
Map<String, Object?> _small(
  _Log log, {
  List<Object?> plugins = const [],
  Map<String, Object?> pluginOptions = const {},
  Map<String, Object?> extra = const {},
}) => <String, Object?>{
  'type': 'line',
  'plugins': <Object?>[_recorder(log), ...plugins],
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{'label': 'a', 'data': _points(8, 0)},
    ],
  },
  'options': <String, Object?>{
    'animation': false,
    'scales': <String, Object?>{
      'x': <String, Object?>{'type': 'linear'},
      'y': <String, Object?>{'type': 'linear'},
    },
    'plugins': <String, Object?>{
      'title': _titleOf(log, 'x'),
      ...pluginOptions,
    },
    ...extra,
  },
};

/// Twins after a change on both: the range chart calls
/// `updateRanges` and gets [expected], and the other chart `update`.
void _expectFallbackTwins(
  Chart full,
  _Log fullLog,
  Chart ranges,
  _Log rangeLog, {
  required bool expected,
  Object? mode = 'none',
  String reason = '',
}) {
  _range('x', 2.0, 5.0)(full);
  _range('x', 2.0, 5.0)(ranges);
  full.update(mode);
  expect(ranges.updateRanges(mode), expected, reason: reason);
  _expectTwins(full, fullLog, ranges, rangeLog, reason);
}

/// A user subclass of the line controller.
final class _UserLine extends LineController {
  _UserLine(super.chart, super.datasetIndex, [super.newTarget]);

  static final value = JsClass(
    'RangeUserLine',
    superclass: LineController.jsClass,
    statics: {'id': 'rangeUserLine'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _UserLine(chart, datasetIndex, target);
    },
  );
}

/// A user subclass of the chart.
final class _UserChart extends Chart {
  _UserChart(super.item, super.userConfig);
}

/// A user subclass of the config.
final class _UserConfig extends Config {
  _UserConfig(super.config);
}

/// A chart that gives a config of its own: an exact Chart always makes an
/// exact Config.
final class _ConfigChart extends Chart {
  _ConfigChart(Object item, this.supplied) : super(item, <String, Object?>{});
  final Config supplied;
  @override
  Config get config => supplied;
}

/// A chart of [cfg] on a canvas of its own: a [_UserChart] for [user], a
/// [_ConfigChart] for a [Config].
Chart _canvasChart(Object cfg, {bool user = false}) {
  final canvas = UiCanvasElement(width: 512, height: 384);
  final chart = cfg is Config
      ? (_ConfigChart(canvas, cfg)..update())
      : user
      ? _UserChart(canvas, cfg)
      : Chart(canvas, cfg);
  addTearDown(() {
    chart.destroy();
    canvas.getContext2d().dispose();
  });
  return chart;
}

/// The resolver of the descriptor of the plugin [id] of [chart].
Object? _pluginResolver(Chart chart, String id) =>
    (chart.plugins.cache!.firstWhere((d) => jsGet(d.plugin, 'id') == id).options
            as OptionView)
        .resolver;

void main() {
  Chart.register([_UserLine.value]);

  group('twins (Chart.js ADR 0111, section 9)', () {
    for (final c in _cases) {
      testWidgets('${c.name}: no animation', (tester) async {
        await _runCase(c, animated: false);
      });
      testWidgets('${c.name}: the animations of each mode', (tester) async {
        await _runCase(c, animated: true);
      });
    }
  });

  group('the range lifecycle', () {
    testWidgets('keeps the resolvers and makes new views', (tester) async {
      final log = _Log();
      final chart = acquireChart(_small(log));
      final options = chart.options;
      final scale = chart.scales['x']!.options;
      final dataset = chart.getDatasetMeta(0).controller!.options;
      final title = _pluginResolver(chart, 'title');
      expect(chart.updateRanges(), isTrue);
      expect(chart.options, isNot(same(options)));
      expect(chart.options.resolver, same(options.resolver));
      expect(chart.scales['x']!.options, isNot(same(scale)));
      expect(
        (chart.scales['x']!.options as OptionView).resolver,
        same((scale as OptionView).resolver),
      );
      final next = chart.getDatasetMeta(0).controller!.options;
      expect(next, isNot(same(dataset)));
      expect(next.resolver, same(dataset.resolver));
      expect(_pluginResolver(chart, 'title'), same(title));
      chart.update();
      expect(chart.options.resolver, isNot(same(options.resolver)));
      expect(_pluginResolver(chart, 'title'), isNot(same(title)));
    });

    testWidgets('a scriptable title shows each new range', (tester) async {
      final log = _Log();
      final chart = acquireChart(_small(log));
      final title = chart.titleBlock! as Title;
      // The first update laid out the title before any scale had a range.
      expect(jsGet(title.options, 'text'), startsWith('x undefined to'));
      for (final (min, max, was) in [
        (1.0, 4.0, '0.0 to 7.0'),
        (2.0, 6.0, '1.0 to 4.0'),
      ]) {
        _range('x', min, max)(chart);
        expect(chart.updateRanges(), isTrue);
        expect(jsGet(title.options, 'text'), 'x $min to $max, was $was');
      }
      _reset(['x'])(chart);
      expect(chart.updateRanges(), isTrue);
      expect(
        jsGet(title.options, 'text'),
        'x undefined to undefined, was 2.0 to 6.0',
      );
    });

    testWidgets('100 range updates add no cache entry and no scope', (
      tester,
    ) async {
      final log = _Log();
      final chart = acquireChart(
        _small(
          log,
          plugins: <Object?>[
            <String, Object?>{
              'id': 'withDefaults',
              'supportsDataUpdates': true,
              'defaults': <String, Object?>{'size': 3.0},
              'beforeDraw': (Object? chart, Object? args, Object? options) =>
                  log.add('size ${jsGet(options, 'size')}'),
            },
          ],
          pluginOptions: <String, Object?>{'withDefaults': <String, Object?>{}},
        ),
      );
      final config = chart.config;
      final sizes = config.debugCacheSizes;
      final scopes =
          jsGet(_pluginResolver(chart, 'withDefaults'), '_scopes')!
              as List<Object?>;
      final length = scopes.length;
      for (var i = 0; i < 100; i++) {
        _range('x', i % 5 + 0.0, i % 5 + 3.0)(chart);
        expect(chart.updateRanges('none'), isTrue);
      }
      expect(config.debugCacheSizes, sizes);
      expect(
        jsGet(_pluginResolver(chart, 'withDefaults'), '_scopes'),
        same(scopes),
      );
      expect(scopes, hasLength(length));
      expect(log.entries.where((e) => e.startsWith('size 3')), hasLength(101));
    });
  });

  group('the checks of section 3: update(mode) and its result', () {
    testWidgets('1. a call from a hook of update and of updateRanges', (
      tester,
    ) async {
      final results = <bool>[];
      var enabled = false;
      final nested = <String, Object?>{
        'id': 'nested',
        'supportsDataUpdates': true,
        'afterUpdate': (Object? chart, Object? args, Object? options) {
          if (enabled) {
            enabled = false;
            results.add((chart! as Chart).updateRanges('none'));
          }
        },
      };
      final fullLog = _Log();
      final rangeLog = _Log();
      final full = acquireChart(_small(fullLog, plugins: [nested]));
      final ranges = acquireChart(_small(rangeLog, plugins: [nested]));
      _range('x', 2.0, 5.0)(full);
      _range('x', 2.0, 5.0)(ranges);
      enabled = true;
      full.update('none');
      enabled = true;
      expect(ranges.updateRanges('none'), isTrue);
      // Both nested calls are `update('none')`.
      expect(results, [false, false]);
      _expectTwins(full, fullLog, ranges, rangeLog, 'nested');
      // The nested update armed the range state.
      _expectFallbackTwins(full, fullLog, ranges, rangeLog, expected: true);
    });

    testWidgets('2. no range state after a cancelled or thrown update', (
      tester,
    ) async {
      for (final hook in [
        'beforeUpdate',
        'beforeLayout',
        'beforeDatasetsUpdate',
      ]) {
        var cancel = false;
        Map<String, Object?> canceller() => <String, Object?>{
          'id': 'canceller',
          'supportsDataUpdates': true,
          hook: (Object? chart, Object? args, Object? options) =>
              cancel ? false : null,
        };
        final fullLog = _Log();
        final rangeLog = _Log();
        final full = acquireChart(_small(fullLog, plugins: [canceller()]));
        final ranges = acquireChart(_small(rangeLog, plugins: [canceller()]));
        cancel = true;
        full.update('none');
        expect(ranges.updateRanges('none'), isTrue, reason: hook);
        cancel = false;
        _expectFallbackTwins(
          full,
          fullLog,
          ranges,
          rangeLog,
          expected: false,
          reason: hook,
        );
        _expectFallbackTwins(
          full,
          fullLog,
          ranges,
          rangeLog,
          expected: true,
          reason: '$hook, then',
        );
      }
      var thrown = false;
      final thrower = <String, Object?>{
        'id': 'thrower',
        'supportsDataUpdates': true,
        'afterLayout': (Object? chart, Object? args, Object? options) {
          if (thrown) {
            thrown = false;
            throw StateError('hook');
          }
        },
      };
      final log = _Log();
      final chart = acquireChart(_small(log, plugins: [thrower]));
      thrown = true;
      expect(chart.updateRanges, throwsStateError);
      expect(chart.updateRanges(), isFalse);
      expect(chart.updateRanges(), isTrue);
    });

    // Check 2 already refuses these charts: only the exact classes record
    // the range state. The case pins the result, not check 3 alone.
    test('3. a chart or a config of another class', () {
      final log = _Log();
      final user = _canvasChart(_small(log), user: true);
      expect(user.updateRanges(), isFalse);
      expect(Config(_small(log)).supportsDataUpdates, isTrue);
      expect(_UserConfig(_small(log)).supportsDataUpdates, isFalse);
      final other = _canvasChart(_UserConfig(_small(log)));
      expect(other.updateRanges(), isFalse);
      final plain = _canvasChart(_small(log));
      expect(plain.updateRanges(), isTrue);
    });

    testWidgets('4. a plugin that does not opt in, a register, the colors '
        'plugin with forceOverride', (tester) async {
      Map<String, Object?> plain() => <String, Object?>{
        'id': 'plain',
        'beforeUpdate': (Object? chart, Object? args, Object? options) {},
      };
      var fullLog = _Log();
      var rangeLog = _Log();
      var full = acquireChart(_small(fullLog, plugins: [plain()]));
      var ranges = acquireChart(_small(rangeLog, plugins: [plain()]));
      _expectFallbackTwins(full, fullLog, ranges, rangeLog, expected: false);

      fullLog = _Log();
      rangeLog = _Log();
      full = acquireChart(_small(fullLog));
      ranges = acquireChart(_small(rangeLog));
      final registered = Plugin(supportsDataUpdates: true)..id = 'registered';
      Chart.register([registered]);
      addTearDown(() => Chart.unregister([registered]));
      _expectFallbackTwins(full, fullLog, ranges, rangeLog, expected: false);
      _expectFallbackTwins(full, fullLog, ranges, rangeLog, expected: true);

      for (final (force, expected) in [(true, false), (false, true)]) {
        fullLog = _Log();
        rangeLog = _Log();
        Map<String, Object?> colors(_Log log) => _small(
          log,
          pluginOptions: <String, Object?>{
            'colors': <String, Object?>{
              'enabled': true,
              'forceOverride': force,
            },
          },
        );
        full = acquireChart(colors(fullLog));
        ranges = acquireChart(colors(rangeLog));
        _expectFallbackTwins(
          full,
          fullLog,
          ranges,
          rangeLog,
          expected: expected,
          reason: 'forceOverride: $force',
        );
      }
    });

    testWidgets('4. the guard of the data-only lifecycle is not called: '
        'decimation takes the range update', (tester) async {
      final log = _Log();
      final chart = acquireChart(_decimation(log, animated: false));
      expect(chart.updateData(), isFalse);
      _range('x', 10.0, 200.0)(chart);
      expect(chart.updateRanges(), isTrue);
    });

    testWidgets('5. a notified change of a data array', (tester) async {
      final fullLog = _Log();
      final rangeLog = _Log();
      final full = acquireChart(_small(fullLog));
      final ranges = acquireChart(_small(rangeLog));
      for (final chart in [full, ranges]) {
        // The upstream push, then the notification of the array listener.
        final values =
            jsGet(
                    (jsGet(chart.data, 'datasets')! as List<Object?>)[0],
                    'data',
                  )!
                  as List<Object?>
              ..add(<String, Object?>{'x': 8.0, 'y': 6.0});
        notifyArrayListeners(values, 'push', [values.last]);
      }
      expect(ranges.dataChanges, isNotEmpty);
      _expectFallbackTwins(full, fullLog, ranges, rangeLog, expected: false);
    });

    testWidgets('6. another data or options object, another dataset, '
        'another chart type, another inline plugin List', (
      tester,
    ) async {
      final changes = <String, void Function(Chart chart)>{
        'config.data': (chart) {
          final config = chart.config;
          final data = config.data as Map<String, Object?>;
          config.data = <String, Object?>{...data};
        },
        'config.options': (chart) {
          final config = chart.config;
          final options = config.options as Map<String, Object?>;
          config.options = <String, Object?>{...options};
        },
        'a dataset at an index': (chart) {
          final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
          datasets[0] = <String, Object?>{
            ...datasets[0]! as Map<String, Object?>,
          };
        },
        'one more dataset': (chart) {
          (jsGet(chart.data, 'datasets')! as List<Object?>).add(
            <String, Object?>{'label': 'b', 'data': _points(5, 2)},
          );
        },
        'config.type': (chart) => chart.config.type = 'scatter',
        'an inline plugin added in place': (chart) {
          (chart.config.plugins! as List<Object?>).add(<String, Object?>{
            'id': 'added',
            'supportsDataUpdates': true,
          });
        },
      };
      for (final MapEntry(key: name, value: change) in changes.entries) {
        final fullLog = _Log();
        final rangeLog = _Log();
        final full = acquireChart(_small(fullLog));
        final ranges = acquireChart(_small(rangeLog));
        change(full);
        change(ranges);
        _expectFallbackTwins(
          full,
          fullLog,
          ranges,
          rangeLog,
          expected: false,
          reason: name,
        );
      }
    });

    testWidgets('7. a controller that is not of its exact class', (
      tester,
    ) async {
      Map<String, Object?> user(_Log log) =>
          _small(log)..['type'] = 'rangeUserLine';
      final fullLog = _Log();
      final rangeLog = _Log();
      final full = acquireChart(user(fullLog));
      final ranges = acquireChart(user(rangeLog));
      _expectFallbackTwins(full, fullLog, ranges, rangeLog, expected: false);
    });
  });

  group('re-entry (section 6)', () {
    testWidgets('updateData from a hook throws the StateError of a full '
        'update', (tester) async {
      var enabled = false;
      Object? error;
      Chart? target;
      final plugin = <String, Object?>{
        'id': 'reentry',
        'supportsDataUpdates': true,
        'beforeDatasetsUpdate': (Object? chart, Object? args, Object? opts) {
          if (!enabled) return;
          enabled = false;
          try {
            target!.updateData();
            // The error of the nested call is the result of the test.
            // ignore: avoid_catching_errors
          } on StateError catch (e) {
            error = e;
          }
        },
      };
      final log = _Log();
      final chart = target = acquireChart(_small(log, plugins: [plugin]));
      enabled = true;
      expect(chart.updateRanges(), isTrue);
      expect(error, isA<StateError>());
    });

    testWidgets('update from a hook runs, and the next call takes the range '
        'path', (tester) async {
      var enabled = false;
      Chart? target;
      final plugin = <String, Object?>{
        'id': 'reentry',
        'supportsDataUpdates': true,
        'beforeDatasetsUpdate': (Object? chart, Object? args, Object? opts) {
          if (!enabled) return;
          enabled = false;
          target!.update('none');
        },
      };
      final fullLog = _Log();
      final rangeLog = _Log();
      final full = acquireChart(_small(fullLog, plugins: [plugin]));
      final ranges = acquireChart(_small(rangeLog, plugins: [plugin]));
      target = full;
      enabled = true;
      _range('x', 2.0, 5.0)(full);
      full.update('none');
      target = ranges;
      enabled = true;
      _range('x', 2.0, 5.0)(ranges);
      expect(ranges.updateRanges('none'), isTrue);
      _expectTwins(full, fullLog, ranges, rangeLog, 'nested update');
      expect(ranges.updateRanges('none'), isTrue);
    });

    testWidgets('updateRanges from onHover of the replay delegates', (
      tester,
    ) async {
      final results = <bool>[];
      var enabled = false;
      final log = _Log();
      late Chart chart;
      chart = acquireChart(
        _small(
          log,
          extra: <String, Object?>{
            'onHover': (Object? event, Object? active, Object? c) {
              if (enabled) {
                enabled = false;
                results.add(chart.updateRanges('none'));
              }
            },
          },
        ),
      );
      await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
        'x': chart.chartArea!.left + 20,
        'y': chart.chartArea!.top + 20,
      });
      enabled = true;
      expect(chart.updateRanges('none'), isTrue);
      expect(results, [false]);
      expect(chart.updateRanges('none'), isTrue);
    });
  });

  group('invalidation (section 6)', () {
    final points = <String, void Function(Chart chart)>{
      'chart.data =': (chart) {
        final data = chart.data;
        chart.data = data;
      },
      'chart.options =': (chart) => chart.options = chart.config.options,
      // A resize to the same size: no update of its own.
      'resize': (chart) => chart.resize(),
      'reset': (chart) => chart.reset(),
      'setDatasetVisibility': (chart) => chart.setDatasetVisibility(0, true),
      'toggleDataVisibility': (chart) => chart
        ..toggleDataVisibility(1)
        ..toggleDataVisibility(1),
    };
    for (final MapEntry(key: name, value: invalidate) in points.entries) {
      testWidgets(name, (tester) async {
        final fullLog = _Log();
        final rangeLog = _Log();
        final full = acquireChart(_small(fullLog));
        final ranges = acquireChart(_small(rangeLog));
        invalidate(full);
        invalidate(ranges);
        fullLog.entries.clear();
        rangeLog.entries.clear();
        _expectFallbackTwins(full, fullLog, ranges, rangeLog, expected: false);
        _expectFallbackTwins(full, fullLog, ranges, rangeLog, expected: true);
      });
    }

    testWidgets('hide and show run their own update', (tester) async {
      final log = _Log();
      final chart = acquireChart(_small(log))..hide(0);
      expect(chart.updateRanges(), isTrue);
      chart.show(0);
      expect(chart.updateRanges(), isTrue);
    });

    testWidgets('destroy', (tester) async {
      final log = _Log();
      final chart = acquireChart(_small(log));
      expect(chart.updateRanges(), isTrue);
      releaseChart(chart);
      // `destroy` drops the range state: the call is `update`, which throws
      // on a destroyed chart, and the range steps do not run.
      StackTrace? stack;
      try {
        chart.updateRanges();
      } on Object catch (_, trace) {
        stack = trace;
      }
      expect(stack, isNotNull);
      expect(stack.toString(), contains('Chart.update '));
      expect(stack.toString(), isNot(contains('Chart._updateRanges')));
    });

    testWidgets('a direct write of meta.hidden', (tester) async {
      final fullLog = _Log();
      final rangeLog = _Log();
      final full = acquireChart(_small(fullLog));
      final ranges = acquireChart(_small(rangeLog));
      full.getDatasetMeta(0).hidden = true;
      ranges.getDatasetMeta(0).hidden = true;
      _expectFallbackTwins(full, fullLog, ranges, rangeLog, expected: true);
    });
  });

  group('data in a range update (section 2)', () {
    testWidgets('a new data List and new labels equal update', (tester) async {
      final fullLog = _Log();
      final rangeLog = _Log();
      final full = acquireChart(_bar(fullLog, animated: false));
      final ranges = acquireChart(_bar(rangeLog, animated: false));
      for (final count in [14, 6, 9]) {
        for (final chart in [full, ranges]) {
          _newData(
            0,
            () => <Object?>[for (var i = 0; i < count; i++) 1.0 + i % 4],
            labels: count,
          )(chart);
          _range('x', 'L1', 'L${count - 2}')(chart);
        }
        full.update('none');
        expect(ranges.updateRanges('none'), isTrue);
        _expectTwins(full, fullLog, ranges, rangeLog, 'count $count');
      }
    });
  });
}
