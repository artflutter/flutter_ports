// Original code, not ported from Chart.js: Scale cases without a chart.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:ui' as native_ui;
import 'dart:ui' show FontStyle;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show ContextResolver, attachContext, createResolver;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show setMinAndMaxByKey;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ContextObject, createContext;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/layout.dart'
    show ChartPosition, ScaleValuePosition;
import 'package:flutter_chartjs_port/src/types/plugin.dart' show PluginHook;
import 'package:flutter_test/flutter_test.dart';

import '../../support/color_json.dart';
import '../../support/font_record.dart';
import '../../support/tick_label.dart';
import 'scale_reference.dart';

// The chart cases of core.scale.tests.js need a chart controller (phase 7).
// These tests cover the Scale pipeline without a chart (AGENTS.md rule 3):
// `init`, `update` with the order of the hooks and plugin notifications, the
// ticks and the tick callback, the label sizes and their cache
// (`_computeLabelSizes`), the rotation and the fit, `getPixelForTick` and
// the other pixel methods, `getLabelItems` (`_computeLabelItems`),
// `_layers`, and the draw calls of the background, the grid
// (`_computeGridLineItems`), the border, the title with its stroke and the
// labels.
//
// The expected values are in scale_reference.dart, which
// tool/reference/scale_reference.mjs writes from src/core/core.scale.js at
// the pin in Node.js v24.22.1 on arm64 (Chart.js ADR 0045), with the mock
// context of chartjs-test-utils. Both sides use a test subclass of Scale with
// fixed ticks and a linear mapping, a fake chart, and options that resolve
// through the user options, `defaults.scale` and `descriptors.scale`. Names
// and strings compare exactly, numbers with closeTo (Chart.js ADR 0034):
// `Math.asin` and the `Math.sin` and `Math.cos` of a display-only site can
// differ in the last bit.
//
// The other groups test the parts of the Dart form: the test of an
// overridden `draw` in `_layers`, the class value and the throws.

/// The log of the hooks of the current case.
List<String> _log = [];

/// A rectangle `{left, top, right, bottom, width, height}`.
final class _Area(
  @override final double left,
  @override final double top,
  @override final double right,
  @override final double bottom,
) implements types.ChartArea {
  @override
  double get width => right - left;

  @override
  double get height => bottom - top;
}

/// The controller of a fake meta: `getMinMax` gives a fixed range.
final class _Controller(final double min, final double max)
    implements types.DatasetController {
  @override
  ({double min, double max}) getMinMax(types.Scale scale, [bool? canStack]) {
    _log.add('getMinMax:${(scale as Scale).id}:$canStack');
    return (min: min, max: max);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A fake meta `{type, xAxisID, yAxisID, controller}`.
final class _Meta(Map<String, Object?> spec) implements types.ChartMeta {
  @override
  final String type = spec['type']! as String;

  @override
  final String? xAxisID = spec['xAxisID'] as String?;

  @override
  final String? yAxisID = spec['yAxisID'] as String?;

  @override
  String? get rAxisID => null;

  @override
  final types.DatasetController controller = _Controller(
    (spec['min']! as num).toDouble(),
    (spec['max']! as num).toDouble(),
  );

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A scale of `chart.scales` for an object position:
/// `getPixelForValue(v) = offset + ToNumber(v)`.
final class _OtherScale(final double offset) implements types.Scale {
  @override
  double getPixelForValue(Object? value, [int? index]) =>
      offset + jsToNumber(value);

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The fake chart of a case.
final class _Chart(Map<String, Object?> spec) implements types.Chart {
  this : options = <String, Object?>{'font': defaults['font']};

  @override
  double width = _number(spec['width']);

  @override
  double height = _number(spec['height']);

  @override
  types.ChartArea chartArea = _areaOf(spec['chartArea']! as List<Object?>);

  @override
  double currentDevicePixelRatio = spec.containsKey('dpr')
      ? _number(spec['dpr'])
      : 1;

  @override
  final AnyObject data =
      _copy(spec['data'] ?? <String, Object?>{})! as AnyObject;

  @override
  final AnyObject options;

  @override
  final Map<String, types.Scale> scales = {
    for (final MapEntry(:key, :value)
        in ((spec['otherScales'] ?? <String, Object?>{}) as AnyObject).entries)
      key: _OtherScale(_number(value)),
  };

  final List<types.ChartMeta> _metas = [
    for (final meta in (spec['metas'] ?? <Object?>[]) as List<Object?>)
      _Meta(meta! as AnyObject),
  ];

  ContextObject? _context;

  @override
  bool notifyPlugins<A extends Object>(PluginHook<A> hook, [A? args]) {
    _log.add('notify:${hook.jsName}:${jsGet(args, 'type')}');
    return true;
  }

  @override
  ContextObject getContext() =>
      _context ??= createContext(null, {'chart': this, 'type': 'chart'});

  @override
  List<types.ChartMeta> getSortedVisibleDatasetMetas() => _metas;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The test subclass of Scale: ticks from the spec, data limits and a
/// linear mapping.
final class _TestScale(super.cfg, final AnyObject spec) extends Scale {
  @override
  void determineDataLimits() {
    _log.add('determineDataLimits');
    min = _number(spec['min']);
    max = _number(spec['max']);
  }

  @override
  List<Tick>? buildTicks() {
    _log.add('buildTicks');
    return [
      for (final tick
          in (spec['ticks']! as List<Object?>).cast<List<Object?>>())
        Tick(
          value: _number(tick[0]),
          major: tick.length > 1 && tick[1]! as bool,
        ),
    ];
  }

  @override
  double getPixelForValue(Object? value, [int? index]) {
    return getPixelForDecimal((jsToNumber(value) - min) / (max - min));
  }

  /// `scale.configure()`.
  void configureForTest() => configure();
}

/// The `ToNumber` of a reference number.
double _number(Object? value) => (value! as num).toDouble();

/// The rectangle of `[left, top, right, bottom]`.
_Area _areaOf(List<Object?> edges) => _Area(
  _number(edges[0]),
  _number(edges[1]),
  _number(edges[2]),
  _number(edges[3]),
);

/// The state of the ticks at a hook: their count, or 'null'.
String _tickState(Scale scale) {
  final ticks = scale.ticks;
  return ticks == null ? 'null' : '${ticks.length}';
}

/// The named functions of the reference options.
final Map<String, Object> _functions = {
  for (final name in [
    'beforeUpdate',
    'beforeSetDimensions',
    'afterSetDimensions',
    'beforeDataLimits',
    'afterDataLimits',
    'beforeBuildTicks',
    'afterBuildTicks',
    'beforeTickToLabelConversion',
    'afterTickToLabelConversion',
    'beforeCalculateLabelRotation',
    'afterCalculateLabelRotation',
    'beforeFit',
    'afterFit',
    'afterUpdate',
  ])
    'hook:$name': (Object? scale) {
      _log.add('cb:$name:${_tickState(scale! as Scale)}');
    },
  // The tick callbacks are `TickCallback`s (row `adapt-native-tick`): the
  // result is the lines of the label, and null for the `null` and the
  // `undefined` of the generator.
  'nullOdd': (Scale scale, double value, int index, List<Tick> ticks) =>
      index.isOdd ? null : ['L${jsNumberToString(value)}'],
  'undefinedLast': (Scale scale, double value, int index, List<Tick> ticks) =>
      index == ticks.length - 1 ? null : ['v${jsNumberToString(value)}'],
  'arrayLabel': (Scale scale, double value, int index, List<Tick> ticks) => [
    'a${jsNumberToString(value)}',
    'second line',
  ],
  'longLabel': (Scale scale, double value, int index, List<Tick> ticks) => [
    'Label number ${jsNumberToString(value)}',
  ],
  'numberLabel': (Scale scale, double value, int index, List<Tick> ticks) => [
    jsNumberToString(value * 10),
  ],
  'thisType': (Scale scale, double value, int index, List<Tick> ticks) => [
    '${scale.type}${jsNumberToString(value)}',
  ],
  'colorByIndex': (Object? ctx) =>
      jsTruthy(jsToNumber(jsGet(ctx, 'index')).remainder(2))
      ? const ChartPaint.solid(native_ui.Color.fromRGBO(255, 0, 0, 1))
      : const ChartPaint.solid(native_ui.Color.fromRGBO(0, 0, 255, 1)),
  'widthByIndex': (Object? ctx) =>
      jsGet(ctx, 'type') == 'tick' ? jsToNumber(jsGet(ctx, 'index')) + 1 : 5.0,
  'undefinedOddWidth': (Object? ctx) =>
      jsTruthy(jsToNumber(jsGet(ctx, 'index')).remainder(2)) ? undefined : 2.0,
  'fontByIndex': (Object? ctx) => ChartTextStyle(
    fontSize: jsGet(ctx, 'type') == 'tick'
        ? 10 + 2 * jsToNumber(jsGet(ctx, 'index'))
        : 12.0,
  ),
  'colorByMajor': (Object? ctx) {
    final tick = jsGet(ctx, 'tick');
    return tick is Tick && tick.major
        ? const ChartPaint.solid(native_ui.Color.fromRGBO(255, 0, 0, 1))
        : const ChartPaint.solid(native_ui.Color.fromRGBO(128, 128, 128, 1));
  },
  'dropFirst': (Object? scale) {
    final s = scale! as Scale;
    s.ticks = s.ticks!.sublist(1);
  },
};

/// A mutable copy of a reference value, with each `'fn:<name>'` replaced by
/// the named function.
Object? _copy(Object? value) => switch (value) {
  final String s when s.startsWith('fn:') => _functions[s.substring(3)]!,
  final Map<String, Object?> map => <String, Object?>{
    for (final MapEntry(:key, :value) in map.entries)
      key: key == 'strokeWidth' && map['strokeColor'] == ''
          ? 0.0
          : key == 'strokeColor' && value == ''
          ? const ChartPaint.unchanged()
          : (key == 'color' || key.endsWith('Color')) &&
                value is String &&
                !value.startsWith('fn:')
          ? referenceColorInput(value)
          : _copy(value),
  },
  final List<Object?> list => <Object?>[for (final item in list) _copy(item)],
  _ => value,
};

/// A matcher of a reference value: numbers with [closeTo], NaN with
/// [isNaN], lists and maps item by item, other values with `==`.
Object? _matcher(Object? expected) => switch (expected) {
  final String text when isReferenceColor(text) => referenceColorOrString(text),
  final num n when n.isNaN => isNaN,
  final num n when n.isInfinite => equals(n),
  final num n => closeTo(n, 1e-9),
  {'num': final String s} => switch (s) {
    'NaN' => isNaN,
    '-0' => closeTo(0, 0),
    _ => equals(double.parse(s)),
  },
  final List<Object?> list => [for (final item in list) _matcher(item)],
  // The record of a font (row adapt-text-style-fonts, font_record.dart).
  {'font': final Map<String, Object?> _} when expected.length == 1 =>
    fontRecordMatcher(expected),
  final Map<String, Object?> map => {
    for (final MapEntry(:key, :value) in map.entries) key: _matcher(value),
  },
  _ => expected,
};

/// The calls of a reference text: one JSON array `[name, ...args]` for
/// each line, as the records `{name, args}` of MockContext.
List<Object?> _calls(Object? text) {
  final lines = (text! as String).split('\n').where((l) => l.isNotEmpty);
  return [
    for (final line in lines)
      () {
        final call = jsonDecode(line) as List<Object?>;
        // alignPixel rounds with roundToDouble() (row adapt-dart-round): a
        // line at the canvas edge, where Chart.js draws at 0 or 0.5, draws at
        // -1 or -0.5 in the port.
        final edge = call[0] == 'moveTo' || call[0] == 'lineTo';
        return {
          'name': call[0],
          'args': [
            for (final arg in call.sublist(1))
              if (edge && (arg == 0 || arg == 0.5))
                anyOf(_matcher(arg), equals((arg! as num) - 1))
              else
                _matcher(arg),
          ],
        };
      }(),
  ];
}

/// The JSON values of a reference text, one for each line.
List<Object?> _jsonLines(Object? text) => [
  for (final line in (text! as String).split('\n'))
    if (line.isNotEmpty) jsonDecode(line),
];

/// A label item as the plain object of the reference.
Map<String, Object?> _labelItem(types.LabelItem item) {
  final o = item.options;
  final backdrop = o.backdrop;
  return {
    'label': item.label,
    // The font compares by its record (font_record.dart).
    'font': item.font,
    'lineHeight': item.font.lineHeight,
    'textOffset': item.textOffset,
    'rotation': o.rotation,
    'color': referencePaintValue(o.color),
    'strokeColor': referencePaintValue(o.strokeColor),
    'strokeWidth': o.strokeWidth,
    // The upstream keyword: the name of the enum value.
    'textAlign': o.textAlign?.name,
    // The upstream keyword: the name of the enum value.
    'textBaseline': o.textBaseline?.name,
    'translation': [o.translation!.$1, o.translation!.$2],
    'backdrop': backdrop == null
        ? null
        : {
            'left': backdrop.left,
            'top': backdrop.top,
            'width': backdrop.width,
            'height': backdrop.height,
            'color': referencePaintValue(backdrop.color),
          },
  };
}

/// The ticks as `[value, label]` pairs.
List<Object?> _ticksOf(Scale scale) => [
  for (final tick in scale.ticks!) [tick.value, tick.label],
];

/// The `[value, label]` pairs of the reference with native labels (row
/// `adapt-native-tick`).
List<Object?> _nativeTicks(Object? ticks) => [
  for (final tick in (ticks! as List<Object?>).cast<List<Object?>>())
    [tick[0], nativeTickLabel(tick[1])],
];

/// The label items of the reference with native labels.
List<Object?> _nativeLabelItems(List<Object?> items) => [
  for (final item in items.cast<Map<String, Object?>>())
    {...item, 'label': nativeTickLabel(item['label'])},
];

/// The resolver of the scale options of a case: the user options,
/// `defaults.scale` and `descriptors.scale`, with the chart context.
ContextResolver _scaleOptions(AnyObject options, _Chart chart) => attachContext(
  createResolver([options, defaults['scale'], descriptors['scale']]),
  chart.getContext(),
);

/// Runs [c] as the generator does, and compares each result.
void _run(ScaleReferenceCase c) {
  _log = [];
  final chart = _Chart(c.chart);
  final ctx = MockContext();
  final options = _copy(c.options)! as AnyObject;
  final spec = _copy(c.scale)! as AnyObject;
  final scale = _TestScale({
    'id': options['id'] ?? 'x',
    'type': 'test',
    'ctx': ctx,
    'chart': chart,
  }, spec);
  final expected = c.expected;
  final margins = spec['margins'] as AnyObject?;
  final marginsArea = margins == null
      ? null
      : _Area(
          _number(margins['left']),
          _number(margins['top']),
          _number(margins['right']),
          _number(margins['bottom']),
        );
  final maxWidth = _number(spec['maxWidth']);
  final maxHeight = _number(spec['maxHeight']);

  scale
    ..init(_scaleOptions(options, chart), {})
    ..update(maxWidth, maxHeight, marginsArea);
  expect(_log, expected['hooks'], reason: 'hooks');
  _log = [];
  expect(ctx.getCalls(), _calls(expected['updateCalls']), reason: 'update');
  ctx.resetCalls();

  expect(
    _ticksOf(scale),
    _matcher(_nativeTicks(expected['ticks'])),
    reason: 'ticks',
  );
  for (final (name, value) in [
    ('labelRotation', scale.labelRotation),
    ('width', scale.width),
    ('height', scale.height),
    ('paddingLeft', scale.paddingLeft),
    ('paddingTop', scale.paddingTop),
    ('paddingRight', scale.paddingRight),
    ('paddingBottom', scale.paddingBottom),
    ('length', scale.length),
    ('maxLength', scale.maxLength),
    ('startPixel', scale.startPixel),
    ('endPixel', scale.endPixel),
  ]) {
    expect(value, _matcher(expected[name]), reason: name);
  }
  expect(scale.reversePixels, expected['reversePixels'], reason: 'reverse');

  // The place of the box, as setBoxDims writes it (core.layouts.js:209-215).
  final box = spec['box']! as List<Object?>;
  final boxLeft = _number(box[0]);
  final boxTop = _number(box[1]);
  scale
    ..left = boxLeft
    ..top = boxTop
    ..right = boxLeft + scale.width
    ..bottom = boxTop + scale.height
    ..configureForTest();

  final userBounds = scale.getUserBounds();
  final minMax = scale.getMinMax(false);
  final padding = scale.getPadding();
  final tickCount = scale.ticks!.length;
  final results = <String, Object?>{
    'isHorizontal': scale.isHorizontal(),
    'isFullSize': jsTruthy(scale.isFullSize()),
    'userBounds': [
      userBounds.min,
      userBounds.max,
      userBounds.minDefined,
      userBounds.maxDefined,
    ],
    'minMax': [minMax.min, minMax.max],
    'padding': [padding.left, padding.top, padding.right, padding.bottom],
    'baseValue': scale.getBaseValue(),
    'basePixel': scale.getBasePixel(),
    'pixels': [
      for (var i = 0; i < tickCount; i++) scale.getPixelForTick(i),
      scale.getPixelForTick(tickCount),
    ],
    'decimals': [
      for (final d in [0.0, 0.25, 1.0]) scale.getPixelForDecimal(d),
    ],
    'decimalForPixel': scale.getDecimalForPixel(boxLeft + 37),
    'lineWidthForFirst': tickCount != 0
        ? scale.getLineWidthForValue(scale.ticks![0].value)
        : 0,
    'lineWidthForMissing': scale.getLineWidthForValue(-12345),
    'labels': scale.getLabels(),
    'tickSize': tickCount != 0 ? scale.tickSize() : 0,
    'maxDigits': scale.maxDigits(),
    'layers': [for (final layer in scale.layers!()) layer.z],
  };
  for (final MapEntry(:key, :value) in results.entries) {
    expect(value, _matcher(expected[key]), reason: key);
  }
  expect(
    [for (final item in scale.getLabelItems()) _labelItem(item)],
    _matcher(_nativeLabelItems(_jsonLines(expected['labelItems']))),
    reason: 'labelItems',
  );
  expect(_log, expected['queryLog'], reason: 'queryLog');
  _log = [];
  ctx.resetCalls();

  scale.draw(chart.chartArea);
  expect(ctx.getCalls(), _calls(expected['drawCalls']), reason: 'draw');
  expect(_log, expected['drawLog'], reason: 'drawLog');

  final second = expected['secondUpdate'] as AnyObject?;
  if (second != null) {
    _log = [];
    ctx.resetCalls();
    spec['ticks'] = spec['ticks2'];
    scale.update(maxWidth, maxHeight, marginsArea);
    expect(_log, second['hooks'], reason: 'second hooks');
    expect(ctx.getCalls(), _calls(second['calls']), reason: 'second update');
    expect(
      _ticksOf(scale),
      _matcher(_nativeTicks(second['ticks'])),
      reason: 'second',
    );
  }
}

/// The scale configuration `{id, type, ctx, chart}` with a new chart.
AnyObject _cfg(_Chart chart, [CanvasContextHolder? holder]) => {
  'id': 'x',
  'type': 'test',
  'ctx': holder?.ctx ?? MockContext(),
  'chart': chart,
};

/// Holds a context for [_cfg].
final class CanvasContextHolder(final MockContext ctx);

/// A chart of 500 x 400 without metas.
_Chart _plainChart() => _Chart(<String, Object?>{
  'width': 500,
  'height': 400,
  'chartArea': <Object?>[40, 30, 480, 350],
});

/// A scale of `chart.scales` that records the values of
/// `getPixelForValue`.
final class _RecordingScale() implements types.Scale {
  /// The values of the calls, in order, unchanged.
  final List<Object?> values = [];

  @override
  double getPixelForValue(Object? value, [int? index]) {
    values.add(value);
    return 50;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A scale subclass that overrides `draw` and calls `super.draw`.
final class _DrawingScale(super.cfg) extends Scale {
  int draws = 0;

  @override
  void draw([types.ChartArea? chartArea]) {
    draws++;
    super.draw(chartArea);
  }
}

/// A scale subclass that inherits `draw` through another subclass.
final class _SubScale(super.cfg, super.spec) extends _TestScale;

void main() {
  setUpDefaultsRestore();

  test('font reuse still creates each tick context and sees option writes', () {
    final chart = _plainChart();
    final scale = _TestScale(_cfg(chart), {})
      ..init(
        _scaleOptions({
          'axis': const XAxis(),
          'position': ChartPosition.bottom,
          'ticks': {
            'font': const ChartTextStyle(
              fontSize: 12,
              fontFamily: 'Arial',
              fontFamilyFallback: [],
              fontStyle: FontStyle.normal,
              height: 1.2,
            ),
          },
        }, chart),
      )
      ..ticks = [Tick(value: 0), Tick(value: 1)];
    final first = scale.resolveTickFontOptions(0);
    expect(scale.ticks![1].$context, isNull);
    final second = scale.resolveTickFontOptions(1);
    // A font is immutable (Chart.js ADR 0116): the reuse gives the same
    // object.
    expect(second, same(first));
    expect(scale.ticks![1].$context!.index, 1.0);
    expect(scale.ticks![1].$context!.tick, same(scale.ticks![1]));
    final tickOptions = scale.options.ticks.raw! as ContextResolver;
    tickOptions['font'] = const ChartTextStyle(fontSize: 22);
    expect(scale.resolveTickFontOptions(1).fontSize, 22);
  });

  test('direct tick contexts preserve identity, parent and own-key order', () {
    final chart = _plainChart();
    final scale =
        _TestScale(_cfg(chart), {
            'ticks': <Object?>[
              <Object?>[0],
              <Object?>[1],
            ],
            'min': 0,
            'max': 1,
          })
          ..init(
            _scaleOptions({
              'axis': const XAxis(),
              'position': ChartPosition.bottom,
            }, chart),
          )
          ..update(300, 200)
          ..resolveTickFontOptions(0);
    final tick = scale.ticks!.first;
    final context = tick.$context!;
    expect(context.jsKeys(), ['tick', 'index', 'type']);
    expect(context.tick, same(tick));
    expect(context.index, isA<int>());
    expect(context.index, 0.0);
    expect(context.type, 'tick');
    expect(context.scale, same(scale));
    expect(context.jsHas('scale'), isFalse);
    expect(context.jsRead('chart'), same(chart));
    scale.resolveTickFontOptions(0);
    expect(tick.$context, same(context));
    scale
      ..update(300, 200)
      ..resolveTickFontOptions(0);
    expect(scale.ticks!.first.$context, isNot(same(context)));
    expect(scale.ticks!.first.$context!.prototype, same(context.prototype));
  });

  test('the reference comes from Node.js v24.22.1 on arm64', () {
    expect(scaleReferenceNode, 'v24.22.1');
    expect(scaleReferenceArch, 'arm64');
  });

  group('the scale pipeline', () {
    for (final c in scaleReference) {
      test(c.name, () => _run(c));
    }
  });

  group('_layers', () {
    /// The options of a horizontal scale with the given user options.
    ContextResolver options(_Chart chart, [AnyObject? user]) => _scaleOptions({
      'axis': const XAxis(),
      'position': ChartPosition.bottom,
      ...?user,
    }, chart);

    test('gives three layers for a scale that keeps draw', () {
      final chart = _plainChart();
      final scale = _TestScale(_cfg(chart), {
        'ticks': <Object?>[],
        'min': 0,
        'max': 1,
      })..init(options(chart));
      expect(scale.layers!(), hasLength(3));
      final sub = _SubScale(_cfg(chart), {
        'ticks': <Object?>[],
        'min': 0,
        'max': 1,
      })..init(options(chart));
      expect(sub.layers!(), hasLength(3));
    });

    test('gives one layer with the ticks z for an overridden draw', () {
      // core.scale.tests.js:513-544: a custom scale with its own draw.
      final chart = _plainChart();
      final scale = _DrawingScale(_cfg(chart))
        ..init(
          options(chart, {
            'grid': <String, Object?>{'z': 10},
            'ticks': <String, Object?>{'z': 20},
          }),
        );
      final layers = scale.layers!();
      expect(layers, hasLength(1));
      expect(layers[0].z, 20);
      layers[0].draw(chart.chartArea);
      expect(scale.draws, 1);
    });

    test('gives one layer with z 0 for a hidden scale', () {
      final chart = _plainChart();
      final scale = _TestScale(_cfg(chart), {
        'ticks': <Object?>[],
        'min': 0,
        'max': 1,
      })..init(options(chart, {'display': false}));
      final layers = scale.layers!();
      expect(layers, hasLength(1));
      expect(layers[0].z, 0);
      expect(layers[0].idx, isNaN);
    });

    test('a layer of an overridden draw calls the override', () {
      final chart = _plainChart();
      final holder = CanvasContextHolder(MockContext());
      final scale = _DrawingScale(_cfg(chart, holder))
        ..init(options(chart, {'display': false}));
      scale.layers!()[0].draw(chart.chartArea);
      expect(scale.draws, 1);
      // A hidden scale draws nothing.
      expect(holder.ctx.getCalls(), isEmpty);
    });
  });

  group('the class value', () {
    test('Scale.jsClass extends Element.jsClass without statics', () {
      expect(Scale.jsClass.name, 'Scale');
      expect(identical(Scale.jsClass.superclass, Element.jsClass), isTrue);
      expect(Scale.jsClass.isSubclassOf(Element.jsClass), isTrue);
      expect(Scale.jsClass.id, same(undefined));
      // The inherited statics of Element (core.element.ts:8-9).
      expect(Scale.jsClass['defaults'], same(Element.defaults));
      expect(Scale.jsClass.has('defaultRoutes'), isTrue);
    });

    test('jsConstruct makes a Scale from the cfg object', () {
      final chart = _plainChart();
      final scale = jsConstruct(Scale.jsClass, [_cfg(chart)]);
      expect(scale, isA<Scale>());
      expect((scale as Scale).id, 'x');
      expect(scale.type, 'test');
      expect(identical(scale.chart, chart), isTrue);
    });

    test('jsConstruct of a subclass value without construct makes a Scale', () {
      final chart = _plainChart();
      final custom = JsClass('CustomScale', superclass: Scale.jsClass)
        ..['id'] = 'customScale'
        ..['defaults'] = <String, Object?>{};
      expect(jsConstruct(custom, [_cfg(chart)]), isA<Scale>());
    });

    test('jsConstruct without a cfg object throws a TypeError', () {
      expect(
        () => jsConstruct(Scale.jsClass, const []),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => jsConstruct(Scale.jsClass, [undefined]),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('the start values', () {
    test('match the constructor of upstream', () {
      final chart = _plainChart();
      final scale = Scale(_cfg(chart));
      // core.scale.js:187-249: undefined numbers are NaN.
      for (final value in [
        scale.top,
        scale.bottom,
        scale.left,
        scale.right,
        scale.width,
        scale.height,
        scale.maxWidth,
        scale.maxHeight,
        scale.paddingTop,
        scale.paddingBottom,
        scale.paddingLeft,
        scale.min,
        scale.max,
        scale.startPixel,
        scale.endPixel,
      ]) {
        expect(value, isNaN);
      }
      // core.scale.js:221: the field holds any JS value (the raw
      // `minRotation`), so it starts as the sentinel.
      expect(scale.labelRotation, same(undefined));
      expect(scale.ticks, isEmpty);
      expect(scale.length, 0);
      expect(scale.maxLength, 0);
      expect(scale.reversePixels, isFalse);
      expect(scale.range, isNull);
      // The typed cache of Chart.js ADR 0054 §4: each key absent.
      expect(scale.cache.data, isNull);
      expect(scale.cache.labels, isNull);
      expect(scale.cache.all, isNull);
      expect(scale.cache.bar, isNull);
      expect(scale.userMin, same(undefined));
      expect(scale.userMax, same(undefined));
      expect(scale.suggestedMin, same(undefined));
    });

    test('options before init throw a TypeError', () {
      final scale = Scale(_cfg(_plainChart()));
      expect(() => scale.options, throwsA(isA<TypeError>()));
    });

    test('the base class has no ticks, no pixel and no value', () {
      final chart = _plainChart();
      final scale = Scale(_cfg(chart))
        ..init(
          _scaleOptions(<String, Object?>{
            'axis': const XAxis(),
            'position': ChartPosition.bottom,
          }, chart),
        );
      expect(scale.buildTicks(), isEmpty);
      expect(scale.getPixelForValue(1), isNaN);
      expect(scale.getValueForPixel(1), isNull);
      expect(scale.getLabelForValue('a'), 'a');
      expect(scale.parse(12), 12);
      expect(scale.getPixelForTick(0), isNull);
      expect(scale.getTicks(), same(scale.ticks));
    });

    test('beforeLayout resets the data limits cache', () {
      final chart = _plainChart();
      final scale =
          _TestScale(_cfg(chart), {'ticks': <Object?>[], 'min': 0, 'max': 1})
            ..init(
              _scaleOptions({
                'axis': const XAxis(),
                'position': ChartPosition.bottom,
              }, chart),
            );
      _log = [];
      scale.update(100, 100);
      expect(_log.where((e) => e == 'determineDataLimits'), hasLength(1));
      final cache = scale.cache..bar = [1];
      _log = [];
      scale.update(100, 100);
      expect(_log, isNot(contains('determineDataLimits')));
      scale.beforeLayout();
      expect(scale.cache, isNot(same(cache)));
      expect(scale.cache.bar, isNull);
      _log = [];
      scale.update(100, 100);
      expect(_log, contains('determineDataLimits'));
    });
  });

  group('the throws', () {
    test('an object position of an absent scale throws a TypeError', () {
      // `scales[Object.keys(position)[0]]` is undefined, and the call of
      // getPixelForValue on it throws. Upstream also gives it for an object
      // without keys; the ScaleValuePosition of the port always names a
      // scale (row adapt-chart-position-enum).
      final chart = _plainChart();
      final scale =
          _TestScale(_cfg(chart), {
              'ticks': <Object?>[
                <Object?>[0],
              ],
              'min': 0,
              'max': 1,
            })
            ..init(
              _scaleOptions({
                'axis': const XAxis(),
                'position': const ScaleValuePosition('absent', 0),
              }, chart),
            )
            ..update(440, 200);
      expect(() => scale.draw(chart.chartArea), throwsA(isA<TypeError>()));
    });

    test('a scale without a context throws a TypeError at the draw', () {
      final chart = _plainChart();
      final scale =
          _TestScale(
              {'id': 'x', 'type': 'test', 'ctx': null, 'chart': chart},
              {'ticks': <Object?>[], 'min': 0, 'max': 1},
            )
            ..init(
              _scaleOptions({
                'axis': const XAxis(),
                'position': ChartPosition.bottom,
              }, chart),
            )
            ..update(440, 200);
      expect(() => scale.draw(chart.chartArea), throwsA(isA<TypeError>()));
    });
  });

  group('adapt-scale-option-types', () {
    // Upstream `this.axis = options.axis` (core.scale.js:259) keeps any
    // value, and `getLabels` (:358-361) returns the first truthy value.
    // `types.Scale.axis` is an axis class (row adapt-axis-objects) and
    // `getLabels` returns a List.
    test('an axis option that is not an axis class throws a TypeError', () {
      final chart = _plainChart();
      for (final axis in <Object?>[true, 1]) {
        final scale = Scale(_cfg(chart));
        expect(
          () => scale.init(
            _scaleOptions({
              'axis': axis,
              'position': ChartPosition.bottom,
            }, chart),
          ),
          throwsA(isA<TypeError>()),
          reason: '$axis',
        );
      }
      final scale = Scale(_cfg(chart))
        ..init(
          _scaleOptions({
            'axis': const XAxis(),
            'position': ChartPosition.bottom,
          }, chart),
        );
      expect(scale.axis, isA<XAxis>());
    });

    test('labels that are not a List throw a TypeError', () {
      final chart = _plainChart();
      final scale = Scale(_cfg(chart))
        ..init(
          _scaleOptions({
            'axis': const XAxis(),
            'position': ChartPosition.bottom,
            'labels': 'abc',
          }, chart),
        );
      expect(scale.getLabels, throwsA(isA<TypeError>()));

      chart.data['xLabels'] = 5;
      final other = Scale(_cfg(chart))
        ..init(
          _scaleOptions({
            'axis': const XAxis(),
            'position': ChartPosition.bottom,
          }, chart),
        );
      expect(other.getLabels, throwsA(isA<TypeError>()));

      final labels = <Object?>['a', 'b'];
      chart.data['xLabels'] = labels;
      expect(other.getLabels(), same(labels));
    });

    test('a size or a translation that a string option joins is its '
        'ToNumber', () {
      // Upstream (Node.js v24.12.0 on x64) keeps the joined strings:
      // `height` '80' (core.scale.js:649, :682) and the translations '405'
      // and '5245' (:1210, :1322). The port fields are `double`.
      final spec = <String, Object?>{
        'ticks': <Object?>[
          <Object?>[0],
          <Object?>[1],
        ],
        'min': 0,
        'max': 1,
      };
      final chart = _plainChart();
      final hidden = _TestScale(_cfg(chart), spec)
        ..init(
          _scaleOptions({
            'axis': const XAxis(),
            'position': ChartPosition.bottom,
            'ticks': <String, Object?>{'display': false},
            'grid': <String, Object?>{'tickLength': '8'},
          }, chart),
        )
        ..update(440, 200);
      expect(hidden.height, 80);

      final bottom = _TestScale(_cfg(chart), spec)
        ..init(
          _scaleOptions({
            'axis': const XAxis(),
            'position': ChartPosition.bottom,
            'ticks': <String, Object?>{'labelOffset': '5'},
          }, chart),
        )
        ..update(440, 200);
      bottom
        ..left = 40
        ..top = 350
        ..right = 40 + bottom.width
        ..bottom = 350 + bottom.height
        ..configureForTest();
      expect(
        [for (final item in bottom.getLabelItems()) item.options.translation],
        [(405, 361), (5245, 361)],
      );
    });
  });

  group('paddingTop and paddingBottom keep the joined padding', () {
    // core.scale.js:734-735 write `paddingTop + padding`. getPadding returns
    // `this.paddingTop || 0` (:340), and core.layouts.js:111-113 apply
    // `Math.max`. The values come from Node.js v24.12.0 on x64.

    /// A left scale with two ticks and the `ticks.padding` [padding].
    _TestScale left(Object? padding) {
      final chart = _plainChart();
      return _TestScale(_cfg(chart), {
          'ticks': <Object?>[
            <Object?>[0],
            <Object?>[1],
          ],
          'min': 0,
          'max': 1,
        })
        ..init(
          _scaleOptions({
            'axis': const YAxis(),
            'position': ChartPosition.left,
            'ticks': <String, Object?>{'padding': padding},
          }, chart),
        )
        ..update(250, 320);
    }

    test('a string padding joins the number', () {
      final scale = left('3');
      expect(scale.paddingTop, '7.1999999999999993');
      expect(scale.paddingBottom, '7.1999999999999993');
      expect(scale.getPadding().top, 7.199999999999999);
      expect(scale.getPadding().bottom, 7.199999999999999);
    });

    test('a joined string that is not a number gives the padding NaN', () {
      // The string is truthy: `'7.199999999999999x' || 0` is the string,
      // and Math.max makes NaN of it. A `double` field gave 0.
      final scale = left('x');
      expect(scale.paddingTop, '7.199999999999999x');
      expect(scale.getPadding().top, isNaN);
      expect(scale.getPadding().bottom, isNaN);
    });

    test('a NaN number gives the padding 0', () {
      // `NaN || 0` is 0.
      final scale = left(double.nan);
      expect(scale.paddingTop, isNaN);
      expect(scale.getPadding().top, 0);
      expect(scale.getPadding().bottom, 0);
    });
  });

  group('labelRotation keeps the raw minRotation', () {
    // core.scale.js:590-596 and :622 write the raw `minRotation || 0`
    // without a calculated rotation. :691 tests `labelRotation !== 0`. The
    // reference cases 'bottom, minRotation string 0' and 'bottom, string
    // minRotation 5 and maxRotation 30, long labels' compare the layout.

    /// A bottom scale with ten long labels: the labels need a rotation.
    _TestScale longLabels(Map<String, Object?> ticks) {
      final chart = _plainChart();
      return _TestScale(_cfg(chart), {
          'ticks': <Object?>[
            for (var i = 0; i < 10; i++) <Object?>[i],
          ],
          'min': 0,
          'max': 9,
        })
        ..init(
          _scaleOptions({
            'axis': const XAxis(),
            'position': ChartPosition.bottom,
            'ticks': {'callback': _functions['longLabel'], ...ticks},
          }, chart),
        )
        ..update(260, 150);
    }

    test('the string 0 stays a string', () {
      final chart = _plainChart();
      Object? rotation(Object? minRotation) =>
          (_TestScale(_cfg(chart), {
                  'ticks': <Object?>[
                    <Object?>[0],
                    <Object?>[1],
                  ],
                  'min': 0,
                  'max': 1,
                })
                ..init(
                  _scaleOptions({
                    'axis': const XAxis(),
                    'position': ChartPosition.bottom,
                    'ticks': <String, Object?>{'minRotation': minRotation},
                  }, chart),
                )
                ..update(440, 200))
              .labelRotation;
      expect(rotation('0'), '0');
      expect(rotation(0), 0);
      expect(rotation(''), 0);
    });

    test('two strings compare by their code units', () {
      // '5' >= '30' is true: the early return keeps '5'. The numbers 5
      // and 30 calculate a rotation, and Math.max and Math.min limit it
      // to 30. The values come from the reference cases.
      expect(
        longLabels({'minRotation': '5', 'maxRotation': '30'}).labelRotation,
        '5',
      );
      expect(
        longLabels({'minRotation': 5, 'maxRotation': 30}).labelRotation,
        30,
      );
      // A string and a number compare as numbers: 30 >= 5.
      expect(
        longLabels({'minRotation': '30', 'maxRotation': 5}).labelRotation,
        '30',
      );
    });
  });

  group('object position value (core.scale.js:145, :156, :1064, :1077, '
      ':1182, :1191)', () {
    // Upstream passes the raw `position[positionAxisID]` to
    // getPixelForValue. So does the port (Chart.js ADR 0025). Each scale
    // with a title makes three calls: the label items (:1182, :1191), the
    // grid line items (:1064, :1077) and the title (:145, :156).
    for (final (axis, axisClass, otherAxis) in const [
      ('x', XAxis(), 'y'),
      ('y', YAxis(), 'x'),
    ]) {
      group('$axis scale', () {
        for (final (value, expected) in <(Object?, Matcher)>[
          ('B', equals('B')),
          (null, isNull),
          ('7', equals('7')),
          (3, equals(3)),
        ]) {
          test('passes $value unchanged', () {
            final chart = _plainChart();
            final other = _RecordingScale();
            chart.scales[otherAxis] = other;
            _TestScale(_cfg(chart), {
                'ticks': <Object?>[
                  <Object?>[0],
                ],
                'min': 0,
                'max': 1,
              })
              ..init(
                _scaleOptions({
                  'axis': axisClass,
                  'position': ScaleValuePosition(otherAxis, value),
                  'title': <String, Object?>{'display': true, 'text': 'T'},
                }, chart),
              )
              ..update(250, 320)
              ..getLabelItems()
              ..draw(chart.chartArea);
            expect(other.values, [expected, expected, expected]);
          });
        }
      });
    }
  });

  test('Scale is a MinMax', () {
    // scale.linearbase.js:274 and scale.logarithmic.js:172 call
    // `_setMinAndMaxByKey(ticks, this, 'value')` (Chart.js ADR 0025, section
    // 7).
    final scale = Scale(_cfg(_plainChart()))
      ..min = 0
      ..max = 5;
    setMinAndMaxByKey([Tick(value: -1), Tick(value: 9)], scale, 'value');
    expect(scale.min, -1);
    expect(scale.max, 9);
  });
}
