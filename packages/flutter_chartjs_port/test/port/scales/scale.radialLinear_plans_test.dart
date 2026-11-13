// Original code, not ported from Chart.js: twins of the radial static plans.
@TestOn('vm')
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// Keep each step of a twin as its own statement.
// ignore_for_file: cascade_invocations

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter/widgets.dart' as widgets show TextDirection;
import 'package:flutter/widgets.dart' show Directionality, SizedBox, TextStyle;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show
        AxisGrid,
        AxisTicks,
        ChartAnimation,
        ChartConfig,
        ChartKind,
        ChartLegend,
        ChartThemeData,
        ChartView,
        RadarDataset,
        RadialLinearAxis;
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableScalePointLabelContext;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_chartjs_port/src/scales/scale.radialLinear.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:flutter_test/flutter_test.dart';

// The twins of Chart.js ADR 0095. Two forms of one chart go through the same
// config:
//
// - A recording context with the capability of the native canvas takes the
//   plan; the same recording context without it takes the ordinary loops. The
//   canvas state is what the plan changes. Thus the comparison is the
//   "effective" log: each operation that paints, with its arguments, the path
//   that it uses and the canvas state at that point. `fillText('')` paints
//   nothing, and a text measure is not an operation. The raw path and paint
//   operations must also stay in order.
// - The exact scale on the native canvas takes the plan, and a trivial subclass
//   takes the ordinary loops: their pixels must be equal.

/// A trivial user subclass of the scale, which keeps each ordinary call.
final class _OrdinaryRadial(super.cfg) extends RadialLinearScale {
  static final value = JsClass(
    'OrdinaryRadial',
    superclass: RadialLinearScale.jsClass,
    statics: {'id': 'ordinaryRadial'},
    construct: (_, args) => _OrdinaryRadial(scaleCfgArg(args)),
  );
}

/// A user subclass that counts the contexts of its point labels.
class _CountedRadial(super.cfg) extends RadialLinearScale {
  static final value = JsClass(
    'CountedRadial',
    superclass: RadialLinearScale.jsClass,
    statics: {'id': 'countedRadial'},
    construct: (_, args) => _CountedRadial(scaleCfgArg(args)),
  );

  int contexts = 0;

  @override
  ScriptableScalePointLabelContext? getPointLabelContext(int index) {
    contexts++;
    return super.getPointLabelContext(index);
  }
}

/// [_CountedRadial] that reports the class of the built-in scale. It stays a
/// user subclass: it keeps each ordinary call.
final class _DisguisedRadial(super.cfg) extends _CountedRadial {
  static final value = JsClass(
    'DisguisedRadial',
    superclass: RadialLinearScale.jsClass,
    statics: {'id': 'disguisedRadial'},
    construct: (_, args) => _DisguisedRadial(scaleCfgArg(args)),
  );

  @override
  Type get runtimeType => RadialLinearScale;
}

/// A chart that counts `getDataVisibility` and records its arguments.
final class _VisibilityChart(super.item, super.userConfig) extends Chart {
  final List<num> visibilityReads = [];

  @override
  bool getDataVisibility(num index) {
    visibilityReads.add(index);
    return super.getDataVisibility(index);
  }
}

/// A color of user code: the plan declines it.
final class const _UserColor(super.value) extends ui.Color;

final class const _Metrics(@override final double width)
    implements TextMetrics {
  @override
  double get actualBoundingBoxAscent => 4;

  @override
  double get actualBoundingBoxDescent => 8;

  @override
  double get actualBoundingBoxLeft => 0;

  @override
  double get actualBoundingBoxRight => width;
}

/// A recording context over the native context of a chart: the font state and
/// the text measures of [target], with no pixels. The plan declines it.
class _Recorder(final CanvasRenderingContext2D target) extends MockContext {
  @override
  HTMLCanvasElement get canvas => target.canvas;

  @override
  TextStyle? get font => target.font;

  @override
  set font(TextStyle? font) {
    super.font = font;
    target.font = font;
  }

  @override
  void save() {
    super.save();
    target.save();
  }

  @override
  void restore() {
    super.restore();
    target.restore();
  }

  @override
  TextMetrics measureText(String text) {
    record('measureText', [text]);
    return _Metrics(target.measureText(text).width);
  }
}

/// [_Recorder] with the capability of the native canvas: the plan accepts it.
final class _PlanRecorder(super.target)
    extends _Recorder
    implements CanvasTextMetricsSource {
  static final Object _generation = Object();

  @override
  Object? get textMetricsGeneration => _generation;
}

RadialLinearScale _scaleOf(Chart chart) =>
    chart.scales['r']! as RadialLinearScale;

/// The text of a double with each bit: the shortest text round-trips.
String _layoutText(RadialLinearScale scale) {
  final items = [
    for (final item in scale.pointLabelItems)
      [
        item.visible,
        item.x,
        item.y,
        item.textAlign,
        item.left,
        item.top,
        item.right,
        item.bottom,
      ].join(' '),
  ];
  return [
    'box ${scale.left} ${scale.top} ${scale.right} ${scale.bottom}',
    'size ${scale.width} ${scale.height}',
    'center ${scale.xCenter} ${scale.yCenter} ${scale.drawingArea}',
    'range ${scale.min} ${scale.max}',
    'ticks ${[for (final tick in scale.ticks!) '${tick.value}:${tick.label}']}',
    'labels ${scale.pointLabels}',
    ...items,
  ].join('\n');
}

/// One update of [chart] with the context [ctx] in its scale: the layout text.
String _layoutWith(Chart chart, CanvasRenderingContext2D ctx) {
  final scale = _scaleOf(chart);
  final old = scale.ctx;
  scale.ctx = ctx;
  try {
    chart.update('none');
    return _layoutText(scale);
  } finally {
    scale.ctx = old;
  }
}

/// One fit of the scale of [chart] on [recorder], as `update` makes it: the
/// recorded calls.
List<ContextCall> _fitWith(Chart chart, _Recorder recorder) {
  final scale = _scaleOf(chart);
  final old = scale.ctx;
  scale.ctx = recorder;
  try {
    scale
      ..setDimensions()
      ..fit();
    return recorder.getCalls();
  } finally {
    scale.ctx = old;
  }
}

/// One draw of the scale of [chart] on [recorder]: the recorded calls.
List<ContextCall> _drawWith(Chart chart, _Recorder recorder) {
  final scale = _scaleOf(chart);
  final old = scale.ctx;
  scale.ctx = recorder;
  try {
    scale.draw(chart.chartArea);
    return recorder.getCalls();
  } finally {
    scale.ctx = old;
  }
}

const Set<String> _pathOperations = {
  'arc',
  'beginPath',
  'closePath',
  'fill',
  'fillRect',
  'lineTo',
  'moveTo',
  'rect',
  'roundRect',
  'stroke',
  'strokeText',
};

/// The raw path and paint operations, in order. `fillText('')` paints nothing.
List<String> _rawOperations(List<ContextCall> calls) => [
  for (final call in calls)
    if (_pathOperations.contains(call['name']) ||
        (call['name'] == 'fillText' && (call['args']! as List)[0] != ''))
      '${call['name']} ${call['args']}',
];

/// Each paint operation with its path and the canvas state at that point. A
/// setter that repeats a value and a `save` with its `restore` leave this text.
List<String> _effectiveLog(List<ContextCall> calls) {
  var state = <String, String>{};
  final stack = <Map<String, String>>[];
  final path = <String>[];
  final log = <String>[];
  for (final call in calls) {
    final name = call['name']! as String;
    final args = call['args']! as List<Object?>;
    switch (name) {
      case 'save':
        stack.add({...state});
      case 'restore':
        state = stack.removeLast();
      case 'measureText':
        break;
      case 'beginPath':
        path.clear();
      case 'moveTo' || 'lineTo' || 'arc' || 'closePath':
        path.add('$name $args');
      case 'fillText' when args[0] == '':
        break;
      default:
        if (name.startsWith('set')) {
          state[name] = '$args';
        } else {
          log.add('$name $args | path $path | state ${_sorted(state)}');
        }
    }
  }
  return log..add('final ${_sorted(state)}');
}

String _sorted(Map<String, String> state) =>
    (state.entries.map((e) => '${e.key}=${e.value}').toList()..sort()).join(
      ' ',
    );

int _count(List<ContextCall> calls, String name) =>
    calls.where((call) => call['name'] == name).length;

int _emptyTexts(List<ContextCall> calls) => calls
    .where(
      (call) =>
          call['name'] == 'fillText' &&
          (call['args']! as List<Object?>)[0] == '',
    )
    .length;

/// The label of every fourth index, else `''`: most labels have no text, as in
/// a dense radar.
Object? _everyFourth(Object? label, num index) => index % 4 == 0 ? label : '';

/// A radar or polar area config of [n] labels. [r] gives the options of the
/// scale `r`, over labels with a [callback]. Each call gives new objects.
AnyObject _config({
  String type = 'radar',
  String? scaleType,
  int n = 40,
  List<Object?>? labels,
  AnyObject Function()? r,
  AnyObject Function()? pointLabels,
  Object? callback = _everyFourth,
}) => <String, Object?>{
  'type': type,
  'data': <String, Object?>{
    'labels': labels ?? <Object?>[for (var i = 0; i < n; i++) 'Label $i'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[
          for (var i = 0; i < (labels?.length ?? n); i++)
            ((i * 37) % 100).toDouble(),
        ],
      },
    ],
  },
  'options': <String, Object?>{
    'responsive': false,
    'events': <String>[],
    'plugins': <String, Object?>{'legend': false},
    'scales': <String, Object?>{
      'r': <String, Object?>{
        'type': ?scaleType,
        'min': 0.0,
        'max': 100.0,
        'grid': <String, Object?>{
          'color': const ChartPaint.solid(ui.Color(0x33000000)),
        },
        'angleLines': <String, Object?>{
          'display': true,
          'color': const ChartPaint.solid(ui.Color(0xFF336699)),
        },
        'ticks': <String, Object?>{'display': false},
        ...?r?.call(),
        'pointLabels': <String, Object?>{
          'display': true,
          'callback': ?callback,
          ...?pointLabels?.call(),
        },
      },
    },
  },
};

/// What the plan must do in a case: `true` for a plan, on the recording
/// context with the capability.
final class const _Expect({
  final bool fit = true,
  final bool labels = true,

  /// Null when the ordinary loop strokes no angle line.
  final bool? lines = true,
});

final class const _Case(
  final String name, {
  final _Expect expected = const _Expect(),
  final List<Object?>? labels,
  final AnyObject Function()? r,
  final AnyObject Function()? pointLabels,
  final Object? callback = _everyFourth,
  final List<int> hidden = const [],
  final int n = 40,
}) {
  AnyObject config(String type, {String? scaleType}) => _config(
    type: type,
    scaleType: scaleType,
    n: n,
    labels: labels,
    r: r,
    pointLabels: pointLabels,
    callback: callback,
  );
}

/// The user calls of the scriptable options of a run, with their contexts.
final List<String> _userCalls = [];

Object? _record(String name, Object? context, Object? value) {
  final index = jsGet(context, 'index');
  final label = jsGet(context, 'label');
  final type = jsGet(context, 'type');
  _userCalls.add('$name $index $label $type');
  return value;
}

final List<_Case> _cases = [
  const _Case('labels with text', callback: null),
  const _Case('a few labels with text'),
  _Case('all labels empty', callback: (Object? _, num _) => ''),
  _Case('a falsy callback result', callback: (Object? _, num _) => null),
  const _Case(
    'a multi-line label in the middle',
    labels: [
      'one',
      'two',
      'three',
      'four',
      'five',
      <Object?>['six a', 'six b'],
      'seven',
      'eight',
    ],
    callback: null,
  ),
  const _Case(
    'a multi-line first label',
    labels: [
      <Object?>['one a', 'one b'],
      'two',
      'three',
      'four',
    ],
    callback: null,
  ),
  const _Case(
    'a multi-line last label',
    labels: [
      'one',
      'two',
      'three',
      <Object?>['four a', 'four b'],
    ],
    callback: null,
  ),
  const _Case(
    'a number label',
    labels: ['one', 'two', 'three', 7, 'five', 'six', 0, 'eight'],
    callback: null,
  ),
  _Case(
    'a backdrop',
    expected: const _Expect(labels: false),
    pointLabels: () => {
      'backdropColor': const ChartPaint.solid(ui.Color(0xFFFFCC00)),
      'backdropPadding': const EdgeInsets.all(3),
      'borderRadius': 0.0,
    },
  ),
  _Case(
    'a rounded backdrop',
    expected: const _Expect(labels: false),
    pointLabels: () => {
      'backdropColor': const ChartPaint.solid(ui.Color(0x80FF00FF)),
      'borderRadius': 4.0,
    },
  ),
  _Case(
    'a scriptable font',
    expected: const _Expect(fit: false, labels: false),
    pointLabels: () => {
      'font': (Object? ctx) => _record(
        'font',
        ctx,
        ChartTextStyle(fontSize: 10.0 + (jsGet(ctx, 'index')! as double) % 3),
      ),
    },
  ),
  _Case(
    'an indexed font',
    expected: const _Expect(fit: false, labels: false),
    pointLabels: () => {
      'font': const <Object?>[
        ChartTextStyle(fontSize: 10),
        ChartTextStyle(fontSize: 12),
      ],
    },
  ),
  _Case(
    'a static font',
    pointLabels: () => {
      'font': const ChartTextStyle(
        fontSize: 13,
        fontStyle: ui.FontStyle.italic,
        fontWeight: ui.FontWeight.bold,
        height: 1.5,
        fontFamily: 'Arial',
        fontFamilyFallback: [],
      ),
    },
  ),
  _Case(
    'a scriptable color',
    expected: const _Expect(labels: false),
    pointLabels: () => {
      'color': (Object? ctx) =>
          _record('color', ctx, const ChartPaint.solid(ui.Color(0xFF123456))),
    },
  ),
  _Case(
    'an indexed color',
    expected: const _Expect(labels: false),
    pointLabels: () => {
      'color': <Object?>[
        const ChartPaint.solid(ui.Color(0xFFFF0000)),
        const ChartPaint.solid(ui.Color(0xFF00FF00)),
        const ChartPaint.solid(ui.Color(0xFF0000FF)),
      ],
    },
  ),
  _Case(
    'a native color',
    pointLabels: () => {'color': const ChartPaint.solid(ui.Color(0xFF00FF00))},
  ),
  _Case(
    'a color of user code',
    expected: const _Expect(labels: false),
    pointLabels: () => {
      'color': const ChartPaint.solid(_UserColor(0xFF112233)),
    },
  ),
  _Case(
    'a scriptable padding',
    expected: const _Expect(fit: false),
    pointLabels: () => {
      'padding': (Object? ctx) =>
          _record('padding', ctx, (jsGet(ctx, 'index')! as double) % 4),
    },
  ),
  _Case(
    'an indexed padding',
    expected: const _Expect(fit: false),
    pointLabels: () => {
      'padding': <Object?>[1.0, 2.0, 3.0],
    },
  ),
  _Case(
    'a string padding',
    expected: const _Expect(fit: false),
    pointLabels: () => {'padding': '5'},
  ),
  _Case('an integer padding', pointLabels: () => {'padding': 7}),
  _Case(
    'a scriptable angle line color',
    expected: const _Expect(lines: false),
    r: () => {
      'angleLines': <String, Object?>{
        'display': true,
        'color': (Object? ctx) =>
            _record('line color', ctx, const ui.Color(0xFF445566)),
      },
    },
  ),
  _Case(
    'a scriptable grid color, with the routed color of the angle lines',
    r: () => {
      'angleLines': <String, Object?>{'display': true},
      'grid': <String, Object?>{
        'color': (Object? ctx) =>
            _record('grid color', ctx, const ui.Color(0xFF667788)),
      },
    },
  ),
  _Case(
    'an indexed line width',
    expected: const _Expect(lines: false),
    r: () => {
      'angleLines': <String, Object?>{
        'display': true,
        'lineWidth': <Object?>[1.0, 2.0],
      },
    },
  ),
  _Case(
    'a scriptable line width',
    expected: const _Expect(lines: false),
    r: () => {
      'angleLines': <String, Object?>{
        'display': true,
        'lineWidth': (Object? ctx) => _record('line width', ctx, 2.0),
      },
    },
  ),
  _Case(
    'a line dash',
    expected: const _Expect(lines: false),
    r: () => {
      'angleLines': <String, Object?>{
        'display': true,
        'borderDash': <Object?>[4.0, 2.0],
        'borderDashOffset': 1.0,
      },
    },
  ),
  _Case(
    'translucent lines',
    r: () => {
      'angleLines': <String, Object?>{
        'display': true,
        'color': const ChartPaint.solid(ui.Color(0x4D0A141E)),
        'lineWidth': 2.0,
      },
    },
  ),
  _Case(
    'a line width of 0',
    expected: const _Expect(lines: null),
    r: () => {
      'angleLines': <String, Object?>{'display': true, 'lineWidth': 0.0},
    },
  ),
  _Case(
    'a null line color',
    expected: const _Expect(lines: null),
    r: () => {
      'angleLines': <String, Object?>{'display': true, 'color': null},
    },
  ),
  _Case(
    'no line and a scriptable line color',
    expected: const _Expect(lines: false),
    r: () => {
      'angleLines': <String, Object?>{
        'display': true,
        'lineWidth': 0.0,
        'color': (Object? ctx) =>
            _record('zero line color', ctx, const ui.Color(0xFF778899)),
      },
    },
  ),
  const _Case('hidden data points', hidden: [2, 5, 6, 39]),
  _Case(
    'display auto, with overlapping labels',
    callback: null,
    n: 300,
    pointLabels: () => {'display': 'auto'},
  ),
  _Case(
    'center point labels',
    callback: null,
    pointLabels: () => {'centerPointLabels': true},
  ),
  _Case(
    'a start angle and reverse',
    callback: null,
    r: () => {'startAngle': 33.0, 'reverse': true},
  ),
  _Case(
    'ticks and a circular grid',
    r: () => {
      'ticks': <String, Object?>{'display': true},
      'grid': <String, Object?>{
        'circular': true,
        'color': const ChartPaint.solid(ui.Color(0xFFAABBCC)),
      },
    },
  ),
  _Case(
    'no angle lines',
    expected: const _Expect(lines: null),
    r: () => {
      'angleLines': <String, Object?>{'display': false},
    },
  ),
  const _Case('a single label', n: 1),
  const _Case('two labels', n: 2),
  const _Case('no labels', n: 0),
];

void main() {
  Chart.register([
    _OrdinaryRadial.value,
    _CountedRadial.value,
    _DisguisedRadial.value,
  ]);

  group('twins', () {
    for (final type in const ['radar', 'polarArea']) {
      for (final c in _cases) {
        testWidgets('$type: ${c.name} draws and fits as the ordinary loops', (
          tester,
        ) async {
          _userCalls.clear();
          final chart = acquireChart(c.config(type));
          if (c.hidden.isNotEmpty) {
            c.hidden.forEach(chart.toggleDataVisibility);
          }
          final target = chart.ctx!;

          // Fit: the same chart, one update on each context.
          _userCalls.clear();
          final ordinaryLayout = _layoutWith(chart, _Recorder(target));
          final ordinaryFitCalls = [..._userCalls];
          _userCalls.clear();
          final planLayout = _layoutWith(chart, _PlanRecorder(target));
          expect(planLayout, ordinaryLayout);
          expect(_userCalls, ordinaryFitCalls);

          // One fit alone: the calls of each form.
          final ordinaryFit = _fitWith(chart, _Recorder(target));
          final planFit = _fitWith(chart, _PlanRecorder(target));
          expect(_layoutText(_scaleOf(chart)), planLayout);
          final labels = _scaleOf(chart).pointLabels.length;
          if (!c.expected.fit) {
            expect(_count(planFit, 'save'), _count(ordinaryFit, 'save'));
          } else if (labels > 2) {
            expect(
              _count(planFit, 'save'),
              lessThan(_count(ordinaryFit, 'save')),
            );
          }

          // Draw: one scale draw on each context. A plan never adds a call.
          _userCalls.clear();
          final ordinary = _drawWith(chart, _Recorder(target));
          final ordinaryDrawCalls = [..._userCalls];
          _userCalls.clear();
          final plan = _drawWith(chart, _PlanRecorder(target));
          expect(_userCalls, ordinaryDrawCalls);
          expect(_rawOperations(plan), _rawOperations(ordinary));
          expect(_effectiveLog(plan), _effectiveLog(ordinary));
          expect(plan.length, lessThanOrEqualTo(ordinary.length));
          if (labels > 1) {
            final emptyOrdinary = _emptyTexts(ordinary);
            if (emptyOrdinary > 1) {
              if (c.expected.labels) {
                // Only the first ordinary label can have an empty string.
                expect(_emptyTexts(plan), lessThanOrEqualTo(1));
              } else {
                expect(_emptyTexts(plan), emptyOrdinary);
              }
            }
            final strokesOrdinary = _count(ordinary, 'setStrokeStyle');
            final strokesPlan = _count(plan, 'setStrokeStyle');
            switch (c.expected.lines) {
              case true when labels > 2:
                expect(strokesPlan, lessThan(strokesOrdinary));
              case false:
                expect(strokesPlan, strokesOrdinary);
              case _:
                break;
            }
          }
        });

        testWidgets('$type: ${c.name} paints the pixels of a user subclass', (
          tester,
        ) async {
          final planned = acquireChart(c.config(type));
          final ordinary = acquireChart(
            c.config(type, scaleType: 'ordinaryRadial'),
          );
          expect(_scaleOf(planned).runtimeType, RadialLinearScale);
          expect(_scaleOf(ordinary).runtimeType, _OrdinaryRadial);
          // The exact scale takes its plans on this native canvas.
          expect(
            (planned.ctx! as CanvasTextMetricsSource).textMetricsGeneration,
            isNotNull,
          );
          if (c.hidden.isNotEmpty) {
            c.hidden.forEach(planned.toggleDataVisibility);
            c.hidden.forEach(ordinary.toggleDataVisibility);
            planned.update('none');
            ordinary.update('none');
          }
          expect(
            _layoutText(_scaleOf(planned)),
            _layoutText(_scaleOf(ordinary)),
          );
          final plannedPixels = await _pixels(tester, planned);
          final ordinaryPixels = await _pixels(tester, ordinary);
          expect(
            plannedPixels.buffer.asUint8List(),
            ordinaryPixels.buffer.asUint8List(),
          );
        });
      }
    }
  });

  group('guards', () {
    testWidgets('a subclass with a recording context of the capability keeps '
        'each ordinary call', (tester) async {
      final planned = acquireChart(_config());
      final ordinary = acquireChart(_config(scaleType: 'ordinaryRadial'));
      final plan = _drawWith(planned, _PlanRecorder(planned.ctx!));
      final subclass = _drawWith(ordinary, _PlanRecorder(ordinary.ctx!));
      expect(_emptyTexts(plan), lessThanOrEqualTo(1));
      expect(_emptyTexts(subclass), 30);
      expect(_count(plan, 'setStrokeStyle'), lessThan(40));
      expect(_count(subclass, 'setStrokeStyle'), greaterThanOrEqualTo(40));
    });

    testWidgets('a subclass that reports the built-in class keeps each '
        'ordinary call', (tester) async {
      // In one draw, each label and each angle line read their own context, 24
      // in all. In one fit, each label reads its own context.
      ({int fit, int draw, List<ContextCall> calls}) run(String scaleType) {
        final chart = acquireChart(_config(scaleType: scaleType, n: 12));
        final scale = _scaleOf(chart) as _CountedRadial;
        scale.contexts = 0;
        _fitWith(chart, _PlanRecorder(chart.ctx!));
        final fit = scale.contexts;
        scale.contexts = 0;
        scale.draw(chart.chartArea);
        final draw = scale.contexts;
        return (
          fit: fit,
          draw: draw,
          calls: _drawWith(chart, _PlanRecorder(chart.ctx!)),
        );
      }

      final disguised = run('disguisedRadial');
      final counted = run('countedRadial');
      expect(disguised.draw, 24);
      expect(counted.draw, 24);
      expect(disguised.fit, 12);
      expect(counted.fit, 12);
      // The labels with no text and the state of each angle line stay.
      expect(_emptyTexts(disguised.calls), 9);
      expect(
        _count(disguised.calls, 'setStrokeStyle'),
        greaterThanOrEqualTo(12),
      );
      expect(_rawOperations(disguised.calls), _rawOperations(counted.calls));
      expect(
        [for (final call in disguised.calls) call['name']],
        [for (final call in counted.calls) call['name']],
      );
    });

    testWidgets('the plan writes the state once and each line its path', (
      tester,
    ) async {
      final chart = acquireChart(_config(n: 12));
      final calls = _drawWith(chart, _PlanRecorder(chart.ctx!));
      final names = [
        for (final call in calls)
          if (const {
            'beginPath',
            'moveTo',
            'lineTo',
            'stroke',
            'setLineDash',
            'setLineDashOffset',
          }.contains(call['name']))
            call['name'],
      ];
      // The grid lines come first: the last 12 lines are the angle lines, with
      // the state of the first line once.
      final last = names.sublist(names.lastIndexOf('setLineDash'));
      expect(last, [
        'setLineDash',
        'setLineDashOffset',
        for (var i = 0; i < 12; i++) ...[
          'beginPath',
          'moveTo',
          'lineTo',
          'stroke',
        ],
      ]);
    });

    testWidgets('a write into the resolver after the first update takes a new '
        'probe', (tester) async {
      final chart = acquireChart(_config());
      final scale = _scaleOf(chart);
      final target = chart.ctx!;
      // The set trap of the view: the next reads give the new color.
      final labels = scale.options.pointLabels.raw! as JsObjectFace
        ..jsWrite('color', const ChartPaint.solid(ui.Color(0xFF010203)));
      expect(
        labels.jsRead('color'),
        const ChartPaint.solid(ui.Color(0xFF010203)),
      );
      final ordinary = _drawWith(chart, _Recorder(target));
      final plan = _drawWith(chart, _PlanRecorder(target));
      expect(_effectiveLog(plan), _effectiveLog(ordinary));
      expect(_effectiveLog(plan).join(), contains('0.0039'));
    });

    testWidgets('a deleted option leaves the plan to the ordinary reads', (
      tester,
    ) async {
      final chart = acquireChart(_config());
      final target = chart.ctx!;
      final scale = _scaleOf(chart);
      (scale.options.angleLines.raw! as JsObjectFace).jsDelete('lineWidth');
      final ordinary = _drawWith(chart, _Recorder(target));
      final plan = _drawWith(chart, _PlanRecorder(target));
      expect(_effectiveLog(plan), _effectiveLog(ordinary));
    });
  });

  group('the point label context', () {
    testWidgets('has the fields, the key order and the parent of the literal', (
      tester,
    ) async {
      final chart = acquireChart(_config(n: 4));
      final scale = _scaleOf(chart);
      final context = scale.getPointLabelContext(2)!;
      expect(context.jsKeys(), ['label', 'index', 'type']);
      expect(context.label, scale.pointLabels[2]);
      expect(context.index, 2.0);
      expect(context.jsRead('type'), 'pointLabel');
      // The parent is the scale context.
      // ignore: invalid_use_of_protected_member
      expect(identical(context.prototype, scale.getContext()), isTrue);
      expect(identical(scale.getPointLabelContext(2), context), isFalse);
      expect(jsGet(context, 'chart'), same(chart));
      context.jsWrite('extra', 1.0);
      expect(context.jsKeys(), ['label', 'index', 'type', 'extra']);
      expect(context.jsDelete('index'), isTrue);
      context.jsWrite('index', 3.0);
      expect(context.jsKeys(), ['label', 'type', 'extra', 'index']);
      expect(scale.getPointLabelContext(4), isNull);
      expect(scale.getPointLabelContext(-1), isNull);
    });
  });

  group('generateTickLabels', () {
    /// The labels and the callback calls of [callback] on the exact scale and
    /// on the user subclass.
    void expectSameLabels(
      Object? Function(List<String> calls) callback, {
      int n = 8,
    }) {
      List<String> run(String? scaleType) {
        final calls = <String>[];
        final chart = acquireChart(
          _config(scaleType: scaleType, n: n, callback: callback(calls)),
        );
        calls.add('update');
        chart.update('none');
        return [...calls, '${_scaleOf(chart).pointLabels}'];
      }

      expect(run(null), run('ordinaryRadial'));
    }

    testWidgets('a typed closure runs for each label, in order', (
      tester,
    ) async {
      expectSameLabels(
        (calls) => (Object? label, double index) {
          calls.add('$label $index');
          return index % 2 == 0 ? label : '';
        },
      );
    });

    testWidgets('a closure with a num index, the lab shape', (tester) async {
      expectSameLabels(
        (calls) => (Object? label, num index) {
          calls.add('$label $index ${index.runtimeType}');
          return label;
        },
      );
    });

    testWidgets('a closure with one parameter', (tester) async {
      expectSameLabels(
        (calls) => (Object? label) {
          calls.add('$label');
          return label;
        },
      );
    });

    testWidgets('a closure with no parameter', (tester) async {
      expectSameLabels(
        (calls) => () {
          calls.add('call');
          return 'x';
        },
      );
    });

    testWidgets('a closure with a third required parameter gets undefined', (
      tester,
    ) async {
      expectSameLabels(
        (calls) => (Object? label, double index, Object? third) {
          calls.add('$label $index $third');
          return label;
        },
      );
    });

    testWidgets('a closure with an optional third parameter gets two', (
      tester,
    ) async {
      expectSameLabels(
        (calls) => (Object? label, double index, [Object? third = 'absent']) {
          calls.add('$label $index $third');
          return label;
        },
      );
    });

    testWidgets('a closure with a narrow parameter takes the generic call', (
      tester,
    ) async {
      expectSameLabels(
        (calls) => (String label, double index) {
          calls.add('$label $index');
          return '$label!';
        },
      );
    });

    testWidgets('a JsFunction gets this', (tester) async {
      expectSameLabels(
        (calls) => JsFunction((Object? self, Object? label, double index) {
          calls.add('${self is RadialLinearScale} $label $index');
          return label;
        }),
      );
    });

    testWidgets('a callback that is no function gives empty labels', (
      tester,
    ) async {
      // The value is outside the type of the key, on purpose.
      final saved = foreignAudit;
      foreignAudit = (_, _, _) {};
      addTearDown(() => foreignAudit = saved);
      expectSameLabels((calls) => 'no function');
    });

    testWidgets('falsy results and 0 keep the rule of the upstream line', (
      tester,
    ) async {
      final results = <Object?>[0.0, 0, false, null, '', double.nan, 1.5, 'a'];
      expectSameLabels(
        (calls) =>
            (Object? label, double index) => results[index.toInt()],
      );
      final chart = acquireChart(
        _config(
          n: 8,
          callback: (Object? label, double index) => results[index.toInt()],
        ),
      );
      expect(_scaleOf(chart).pointLabels, <Object?>[
        0.0,
        0,
        '',
        '',
        '',
        '',
        1.5,
        'a',
      ]);
    });

    testWidgets('a throw of a closure leaves the same way', (tester) async {
      Object? run(String? scaleType) {
        var calls = 0;
        try {
          acquireChart(
            _config(
              scaleType: scaleType,
              callback: (Object? label, double index) {
                if (++calls == 3) throw StateError('three');
                return label;
              },
            ),
          );
          // The twin compares the error that leaves the update.
          // ignore: avoid_catching_errors
        } on StateError catch (error) {
          return '$error $calls';
        }
        return null;
      }

      expect(run(null), run('ordinaryRadial'));
      expect(run(null), isNotNull);
    });

    testWidgets('a closure can replace the option between two labels', (
      tester,
    ) async {
      List<String> run(String? scaleType) {
        final calls = <String>[];
        Object? second(Object? label, double index) {
          calls.add('second $label $index');
          return 'second';
        }

        late Chart chart;
        Object? first(Object? label, double index) {
          calls.add('first $label $index');
          if (index == 2) {
            (_scaleOf(chart).options.pointLabels.raw! as JsObjectFace).jsWrite(
              'callback',
              second,
            );
          }
          return 'first';
        }

        chart = acquireChart(_config(scaleType: scaleType, n: 5));
        (jsGet(
                  jsGet(jsGet(chart.config.options, 'scales'), 'r'),
                  'pointLabels',
                )!
                as JsObjectFace)
            .jsWrite('callback', first);
        chart.update('none');
        return [...calls, '${_scaleOf(chart).pointLabels}'];
      }

      final exact = run(null);
      expect(exact, run('ordinaryRadial'));
      expect(exact, contains('second Label 3 3.0'));
    });

    testWidgets('a closure can hide a label: the filter reads after all '
        'callbacks', (tester) async {
      List<String> run(String? scaleType) {
        late Chart chart;
        chart = acquireChart(
          _config(scaleType: scaleType, n: 6, callback: null),
        );
        (jsGet(
                  jsGet(jsGet(chart.config.options, 'scales'), 'r'),
                  'pointLabels',
                )!
                as JsObjectFace)
            .jsWrite('callback', (Object? label, double index) {
              if (index == 4) chart.toggleDataVisibility(1);
              return label;
            });
        chart.update('none');
        return ['${_scaleOf(chart).pointLabels}'];
      }

      final exact = run(null);
      expect(exact, run('ordinaryRadial'));
      expect(exact.single, isNot(contains('Label 1')));
    });

    testWidgets('a user chart gets each visibility read, with a double', (
      tester,
    ) async {
      final canvas = UiCanvasElement(width: 300, height: 300);
      final chart = _VisibilityChart(canvas, _config(n: 3));
      addTearDown(chart.destroy);
      chart.visibilityReads.clear();
      _scaleOf(chart).generateTickLabels(_scaleOf(chart).ticks!);
      expect(chart.visibilityReads, <double>[0, 1, 2]);
      expect(chart.visibilityReads.every((v) => v is double), isTrue);
    });

    testWidgets('the built-in callback copies a native label list', (
      tester,
    ) async {
      final labels = <Object?>[
        'a',
        '',
        0,
        0.5,
        null,
        false,
        <Object?>['l'],
      ];
      final chart = acquireChart(_config(labels: labels, callback: null));
      expect(_scaleOf(chart).pointLabels, <Object?>[
        'a',
        '',
        0,
        0.5,
        '',
        '',
        <Object?>['l'],
      ]);
      final twin = acquireChart(
        _config(labels: labels, callback: null, scaleType: 'ordinaryRadial'),
      );
      expect(_scaleOf(twin).pointLabels, _scaleOf(chart).pointLabels);
    });

    testWidgets('no hidden index gives a growable list of the labels', (
      tester,
    ) async {
      final chart = acquireChart(_config(n: 3));
      final labels = _scaleOf(chart).pointLabels;
      expect(labels, hasLength(3));
      labels.add('more');
      expect(labels, hasLength(4));
    });
  });

  group('the position inputs', () {
    String bits(double value) {
      final data = ByteData(8)..setFloat64(0, value);
      return data.getUint64(0).toRadixString(16);
    }

    void expectSameBits(Chart chart) {
      final scale = _scaleOf(chart);
      // An ordinary read resolves the start angle of a chart with no label.
      scale.getIndexAngle(0);
      final positions = scale.prepareRadialPositions()!;
      const additions = [0.0, 0.1, 3.14159, -2.5];
      const distances = [0.0, -0.0, 1.0, 123.456, double.nan, double.infinity];
      for (final index in const [0, 1, 2, 7, 39, 40, 41, 1000]) {
        expect(
          bits(positions.indexAngleAt(index)),
          bits(scale.getIndexAngle(index.toDouble())),
        );
        for (final distance in distances) {
          for (final addition in additions) {
            final ordinary = scale.getPointPosition(
              index.toDouble(),
              distance,
              addition,
            );
            final plan = positions.positionAt(index, distance, addition);
            expect(bits(plan.x), bits(ordinary.x));
            expect(bits(plan.y), bits(ordinary.y));
            expect(bits(plan.angle), bits(ordinary.angle));
          }
        }
      }
      for (final value in const [
        0.0,
        -0.0,
        5.0,
        100.0,
        -3.5,
        1e300,
        double.nan,
        double.infinity,
      ]) {
        expect(
          bits(positions.distanceOf(value)),
          bits(scale.getDistanceFromCenterForValue(value)),
        );
      }
    }

    testWidgets('give the bits of the methods', (tester) async {
      expectSameBits(acquireChart(_config()));
    });

    testWidgets('give the bits of the methods with a start angle and reverse', (
      tester,
    ) async {
      expectSameBits(
        acquireChart(_config(r: () => {'startAngle': 33.0, 'reverse': true})),
      );
    });

    testWidgets('give the bits of the methods with no point labels', (
      tester,
    ) async {
      expectSameBits(
        acquireChart(
          _config(
            n: 0,
            r: () => {'startAngle': -725.5, 'min': -10.0, 'max': 10.0},
          ),
        ),
      );
    });

    testWidgets('are not for a user subclass', (tester) async {
      final chart = acquireChart(_config(scaleType: 'ordinaryRadial'));
      expect(_scaleOf(chart).prepareRadialPositions(), isNull);
    });

    testWidgets('run no scriptable option that no read resolved yet', (
      tester,
    ) async {
      var reads = 0;
      final chart = acquireChart(
        _config(
          r: () => {
            'startAngle': (Object? ctx) {
              reads++;
              return 0.0;
            },
          },
        ),
      );
      final scale = _scaleOf(chart);
      final before = reads;
      expect(scale.prepareRadialPositions(), isNotNull);
      expect(reads, before);
      // A new view has no cached value: no plan, and no call.
      // The scale context stays the context of the new view.
      // ignore: invalid_use_of_protected_member
      scale.options = scale.options.setContext(scale.getContext());
      expect(scale.prepareRadialPositions(), isNull);
      expect(reads, before);
    });
  });

  group('the typed config of a dense radar', () {
    testWidgets('takes each plan', (tester) async {
      late Chart chart;
      const grid = ui.Color(0x33888888);
      await tester.pumpWidget(
        Directionality(
          textDirection: widgets.TextDirection.ltr,
          child: SizedBox(
            width: 400,
            height: 400,
            child: ChartView(
              config: ChartConfig(
                type: ChartKind.radar,
                datasets: [
                  RadarDataset(
                    label: 'Values',
                    data: [for (var i = 0; i < 64; i++) (i % 100).toDouble()],
                    pointRadius: 0,
                  ),
                ],
                labels: [for (var i = 0; i < 64; i++) '$i'],
                scales: const {
                  'r': RadialLinearAxis(
                    min: 0,
                    max: 100,
                    pointLabelsFont: TextStyle(fontSize: 10),
                    angleLinesColor: ChartPaint.solid(grid),
                    angleLinesLineWidth: 1,
                    grid: AxisGrid(
                      color: ChartPaint.solid(grid),
                      drawTicks: false,
                      extra: {'circular': true},
                    ),
                    ticks: AxisTicks(
                      stepSize: 25,
                      font: TextStyle(fontSize: 10),
                    ),
                    extra: {
                      'pointLabels': {'callback': _everyFourth},
                    },
                  ),
                },
                animation: ChartAnimation.none,
                legend: const ChartLegend(display: false),
                maintainAspectRatio: false,
                extra: const {'events': <String>[]},
              ),
              updateMode: 'none',
              theme: const ChartThemeData(),
              excludeFromSemantics: true,
              onChartCreated: (created) => chart = created,
            ),
          ),
        ),
      );
      await tester.pump();
      final target = chart.ctx!;
      final ordinaryFit = _Recorder(target);
      final ordinaryLayout = _layoutWith(chart, ordinaryFit);
      final planFit = _PlanRecorder(target);
      expect(_layoutWith(chart, planFit), ordinaryLayout);
      expect(
        _count(planFit.getCalls(), 'save'),
        lessThan(_count(ordinaryFit.getCalls(), 'save') - 50),
      );
      final ordinary = _drawWith(chart, _Recorder(target));
      final plan = _drawWith(chart, _PlanRecorder(target));
      expect(_effectiveLog(plan), _effectiveLog(ordinary));
      expect(_emptyTexts(ordinary), 48);
      expect(_emptyTexts(plan), lessThanOrEqualTo(1));
      expect(
        _count(plan, 'setStrokeStyle'),
        lessThan(_count(ordinary, 'setStrokeStyle') - 50),
      );
    });
  });
}

/// The RGBA bytes of the bitmap of [chart], over an opaque white rectangle.
Future<ByteData> _pixels(WidgetTester tester, Chart chart) async {
  final canvas = chart.canvas! as UiCanvasElement;
  final w = canvas.width;
  final h = canvas.height;
  final recorder = ui.PictureRecorder();
  final c = ui.Canvas(recorder)
    ..drawRect(
      ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
  canvas.getContext2d().paint(c, ui.Offset.zero, 1, 1);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(w, h);
  try {
    return (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
    ))!;
  } finally {
    image.dispose();
    picture.dispose();
  }
}
