// Original code, not ported from Chart.js: scale chart test harness.

/// The harness of the port-only reference tests of the phase 6 scales: real
/// charts against a build of the pinned Chart.js.
///
/// The method (a decision of the phase 6 plan):
///
/// - A test builds real charts with `acquireChart` (Chart.js ADR 0022) in
///   `testWidgets` cases. Its `main()` registers a test controller (and its
///   other classes) through the class value, before the snapshot of the
///   defaults restore (Chart.js ADR 0020, section 8, and Chart.js ADR 0022,
///   section 8).
/// - The expected values come from a generator in
///   `tool/reference/scale_*_reference.mjs`. It runs a build of Chart.js at
///   the pinned commit in the x64 Node.js v24.12.0 (Chart.js ADR 0032), with
///   the same test controllers as `DatasetController` subclasses in
///   JavaScript (`tool/reference/scale_chart_common.mjs`).
/// - Node.js has no canvas. The Node.js side measures text with the advance
///   widths and the `kern` pairs of Liberation Sans 2.1.5, the test font of
///   the harness. Its mock context has a font stack for `save` and
///   `restore`, and its first font is `'10px sans-serif'`. A write of the
///   canvas size resets the font, as on the canvas of the harness. Thus the
///   charts of both sides get the same label sizes, the same layout and the
///   same ticks. The limits: the font form of `toFontString`, ASCII text,
///   integer px sizes, the regular and bold faces and the families of the
///   harness. Outside them, the generator stops with an error.
/// - The Dart side records the calls of one `chart.draw()` after the layout
///   with a [RecordingContext] in place of `chart.ctx`, of each `scale.ctx`,
///   of the writable `ctx` of each dataset controller ([drawCalls],
///   Chart.js ADR 0030) and of the `ctx` of each `Title` box. Thus the calls
///   have the element draws, on both sides. A `Path2D` argument records as
///   `{path, calls}` (`test/port/canvas/path2d_record.dart`).
///
/// The parts:
///
/// - [ScaleTestController], [cartesianTestController] and
///   [scaleTestController]: the cartesian test controller of the generators.
///   [RadialTestController], [radialTestController] and
///   [radialLinearTestController]: the radial test controller.
/// - [RecordingContext] and [drawCalls]: the calls of one draw.
/// - [observeChart]: the observations of `observe` of the generators.
/// - [referenceMatcher], [callMatchers], [copyReference]: the comparison.
/// - [expectScaleObservations], [expectCalls], [expectScaleChart],
///   [testScaleChartCases], [testReferenceOrigin] and
///   [testReferenceWidths]: the checks and the test cases of a reference
///   file. The controller harness
///   (`test/port/controllers/controller_chart_harness.dart`) uses them too.
///   [expectCalls] removes the reference `clip` of the border ring of each
///   bar that the port draws without a `clip` (differences.md
///   `adapt-bar-clip`).
///
/// This library is not a test file: `flutter test` runs only the files that
/// end in `_test.dart`. It is not a pure layer. A test that imports it needs
/// `@TestOn('vm')`.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.title.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/upstream.dart' show chartJsVersion;
import 'package:flutter_test/flutter_test.dart';

import '../canvas/path2d_record.dart';
import '../helpers/rounded_rect_upstream.dart';

// ---------------------------------------------------------------------------
// The test controllers: `cartesianTestController` and
// `radialTestController` of scale_chart_common.mjs.

/// The cartesian test controller of the generators: a point for each value,
/// at the pixels of its index scale and of its value scale
/// (controller.line.js:83-112 without the line, the gaps and the stacks).
final class ScaleTestController extends DatasetController {
  /// The controller of the dataset [datasetIndex] of [chart].
  ScaleTestController(super.chart, super.datasetIndex, [super.newTarget]);

  @override
  void update(String mode) {
    final meta = cachedMeta;
    updateElements(meta.data, 0, meta.data.length.toDouble(), mode);
  }

  @override
  void updateElements(
    List<types.Element> points,
    double start,
    double count,
    String mode,
  ) {
    final meta = cachedMeta;
    final iScale = meta.iScale!;
    final vScale = meta.vScale!;
    final iAxis = iScale.axis;
    final vAxis = vScale.axis;
    final (:sharedOptions, :includeOptions) = getSharedOptions_(start, mode);
    for (var i = start; i < start + count; ++i) {
      final point = points[i.toInt()] as Element;
      final parsed = getParsed(i);
      final properties = <String, Object?>{
        iAxis: iScale.getPixelForValue(jsGet(parsed, iAxis), i),
        vAxis: vScale.getPixelForValue(jsGet(parsed, vAxis), i),
      };
      if (includeOptions) {
        properties['options'] =
            sharedOptions ??
            resolveDataElementOptions(i, point.active ? 'active' : mode);
      }
      updateElement(point, i, properties, mode);
    }
  }
}

/// The class value of a [ScaleTestController] with the id [id] and the
/// overrides [overrides]: `cartesianTestController(id, overrides)` of the
/// generators.
JsClass cartesianTestController(String id, AnyObject overrides) => JsClass(
  'ScaleTestController',
  superclass: DatasetController.jsClass,
  statics: {
    'id': id,
    'defaults': <String, Object?>{
      'datasetElementType': false,
      'dataElementType': 'point',
    },
    'overrides': overrides,
  },
  construct: (newTarget, args) {
    final (:chart, :datasetIndex) = controllerArgs(args);
    return ScaleTestController(chart, datasetIndex, newTarget);
  },
);

/// The test controller `scaleTest` of the generators: category on the index
/// axis and linear on the value axis.
final JsClass scaleTestController = cartesianTestController('scaleTest', {
  'scales': <String, Object?>{
    '_index_': <String, Object?>{'type': 'category'},
    '_value_': <String, Object?>{'type': 'linear'},
  },
});

/// The result of `getPointPositionForValue(index, value)` of a radial scale.
typedef RadialPointPosition = ({double x, double y, double angle});

/// A call of `getPointPositionForValue(index, value)` on [scale].
///
/// The interface `types.Scale` has no `getPointPositionForValue`. Thus the
/// test of a radial scale gives the call, for example:
///
/// ```dart
/// (scale, index, value) =>
///     (scale as RadialLinearScale).getPointPositionForValue(index, value)
/// ```
///
/// [value] is the parsed value r, unchanged: any JS value (Chart.js ADR
/// 0025, section 9).
typedef RadialPointPositionOf = RadialPointPosition Function(
  types.Scale scale,
  double index,
  Object? value,
);

/// The radial test controller of the generators: a point for each value, at
/// the position of `getPointPositionForValue` of the scale r
/// (controller.radar.js:81-103 without the line). The index axis is r. Thus
/// a primitive value parses to `{r: value}`.
///
/// The controller gives the parsed value r unchanged, as
/// controller.radar.js:88 and the generators do (Chart.js ADR 0025, section
/// 9). The parse of null, undefined and NaN is null. Thus the scale gets
/// null, and the radial linear scale gives a point at NaN.
final class RadialTestController extends DatasetController {
  /// The controller of the dataset [datasetIndex] of [chart].
  RadialTestController(
    super.chart,
    super.datasetIndex,
    this.pointPosition, [
    super.newTarget,
  ]);

  /// The call of `getPointPositionForValue` on the scale r.
  final RadialPointPositionOf pointPosition;

  @override
  void update(String mode) {
    final meta = cachedMeta;
    updateElements(meta.data, 0, meta.data.length.toDouble(), mode);
  }

  @override
  void updateElements(
    List<types.Element> points,
    double start,
    double count,
    String mode,
  ) {
    final scale = cachedMeta.rScale!;
    for (var i = start; i < start + count; i++) {
      final position = pointPosition(scale, i, jsGet(getParsed(i), 'r'));
      updateElement(points[i.toInt()] as Element, i, {
        'x': position.x,
        'y': position.y,
        'angle': position.angle,
        'options': resolveDataElementOptions(i, mode),
      }, mode);
    }
  }
}

/// The class value of a [RadialTestController] with the id [id] and the
/// overrides [overrides]: `radialTestController(id, overrides)` of the
/// generators. [pointPosition] calls `getPointPositionForValue` on the
/// scale r.
JsClass radialTestController(
  String id,
  AnyObject overrides,
  RadialPointPositionOf pointPosition,
) => JsClass(
  'RadialTestController',
  superclass: DatasetController.jsClass,
  statics: {
    'id': id,
    'defaults': <String, Object?>{
      'datasetElementType': false,
      'dataElementType': 'point',
      'indexAxis': 'r',
    },
    'overrides': overrides,
  },
  construct: (newTarget, args) {
    final (:chart, :datasetIndex) = controllerArgs(args);
    return RadialTestController(chart, datasetIndex, pointPosition, newTarget);
  },
);

/// The test controller `radialTest` of the generators: radialLinear on the
/// axis r, and the aspect ratio 1 (controller.radar.js:45-52).
JsClass radialLinearTestController(RadialPointPositionOf pointPosition) =>
    radialTestController('radialTest', {
      'aspectRatio': 1.0,
      'scales': <String, Object?>{
        'r': <String, Object?>{'type': 'radialLinear'},
      },
    }, pointPosition);

// ---------------------------------------------------------------------------
// The draw calls.

/// A [MockContext] that records every call and forwards the text state to
/// a real context [target].
///
/// It forwards `font`, `save`, `restore`, `measureText`, `canvas` and
/// `resetTransform`. Thus a measure gets the font of the real canvas, as
/// the layout did. It draws nothing on [target]. It records a `roundRect`
/// call as the upstream arcs and lines of `addRoundedRectPath`
/// (differences.md `adapt-rounded-rect-path`), so that the records compare
/// with the upstream calls.
final class RecordingContext extends MockContext {
  /// A recording context over [target].
  RecordingContext(this.target);

  /// The real context: the context of the chart.
  final CanvasRenderingContext2D target;

  @override
  HTMLCanvasElement get canvas => target.canvas;

  @override
  String? get font => target.font;

  @override
  set font(String? font) {
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
    return target.measureText(text);
  }

  @override
  void resetTransform() {
    record('resetTransform', const []);
    target.resetTransform();
  }

  @override
  void roundRect(double x, double y, double w, double h, [Object? radii]) =>
      replayRoundRectAsUpstream(this, x, y, w, h, radii);
}

/// The calls of one `chart.draw()`: `drawCalls(chart)` of the generators,
/// with the element draws.
///
/// The function puts a [RecordingContext] over `chart.ctx` in place of
/// `chart.ctx`, of the `ctx` of each scale (core.controller.js:357-362), of
/// the `ctx` of each dataset controller whose context is the context of the
/// chart (core.datasetController.js:257 `_ctx`), and of the `ctx` of each
/// `Title` box whose context is the context of the chart (plugin.title.js:16,
/// :110). Then it draws once and puts back the old contexts. The layout is
/// done already: the label widths come from the caches of the scales. Each
/// `Path2D` argument becomes `{path, calls}` (path2d_record.dart).
List<Object?> drawCalls(Chart chart) {
  final target = chart.ctx!;
  final recording = RecordingContext(target);
  final scales = chart.scales.values.toList();
  final scaleContexts = [for (final scale in scales) scale.ctx];
  final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
  final controllers = <DatasetController>[
    for (var i = 0; i < datasets.length; i++)
      if (chart.getDatasetMeta(i.toDouble()).controller
          case final DatasetController c when identical(c.ctx, target))
        c,
  ];
  // The title boxes keep the context of the chart in their own `ctx`
  // (plugin.title.js:16, :110).
  final titles = <Title>[
    for (final box in chart.boxes)
      if (box case final Title title when identical(title.ctx, target)) title,
  ];
  chart.ctx = recording;
  for (final scale in scales) {
    scale.ctx = recording;
  }
  for (final controller in controllers) {
    controller.ctx = recording;
  }
  for (final title in titles) {
    title.ctx = recording;
  }
  try {
    chart.draw();
  } finally {
    chart.ctx = target;
    for (var i = 0; i < scales.length; i++) {
      scales[i].ctx = scaleContexts[i];
    }
    for (final controller in controllers) {
      controller.ctx = target;
    }
    for (final title in titles) {
      title.ctx = target;
    }
  }
  return recordedCalls(recording.getCalls());
}

// ---------------------------------------------------------------------------
// The observations: `observe` of scale_chart_common.mjs.

/// The keys that a test adds to the observations of a scale: the `extra`
/// function of `observe` of the generator, with the same keys.
typedef ScaleObservations = Map<String, Object?> Function(
  Scale scale,
  Chart chart,
);

/// The observations of [chart] after its layout, with the keys of `observe`
/// of the generators.
///
/// - `chartArea`: `[left, top, right, bottom]`.
/// - `scales`: for each scale id, in the order of `chart.scales`: `type`,
///   `axis`, `position`, `min`, `max`, `ticks` (`[value, label, major]`),
///   `box`, `labelRotation`, `paddings`, `tickPixels`, `valuePixels` (min,
///   the middle, max), `valueForPixel` (the start, the middle and the end
///   of the box along the axis) and `basePixel`. [extra] adds its keys.
/// - `points`: for each dataset, `[x, y]` of each data element.
///
/// A number field gives NaN for JS `undefined`, and the generator writes
/// NaN for it too. `getValueForPixel` of the base class gives Dart `null`
/// for JS `undefined`.
Map<String, Object?> observeChart(Chart chart, {ScaleObservations? extra}) {
  final scales = <String, Object?>{};
  for (final MapEntry(key: id, value: s) in chart.scales.entries) {
    final ticks = s.ticks!;
    final horizontal = s.isHorizontal();
    final start = horizontal ? s.left : s.top;
    final end = horizontal ? s.right : s.bottom;
    scales[id] = <String, Object?>{
      'type': s.type,
      'axis': s.axis,
      // An object position is a resolver. `JSON.stringify` of the generator
      // writes its own keys, so the observation is a plain Map of them.
      'position': switch (s.position) {
        final Map<String, Object?> position => <String, Object?>{
          for (final k in jsObjectKeys(position)) k: jsGet(position, k),
        },
        final position => position,
      },
      'min': s.min,
      'max': s.max,
      'ticks': [
        for (final t in ticks) [t.value, t.label, t.major ?? false],
      ],
      'box': [s.left, s.top, s.right, s.bottom],
      'labelRotation': s.labelRotation,
      'paddings': [
        s.paddingLeft,
        s.paddingTop,
        s.paddingRight,
        s.paddingBottom,
      ],
      'tickPixels': [
        for (var i = 0; i < ticks.length; i++) s.getPixelForTick(i),
      ],
      'valuePixels': [
        for (final v in [s.min, (s.min + s.max) / 2, s.max])
          s.getPixelForValue(v),
      ],
      'valueForPixel': [
        for (final p in [start, (start + end) / 2, end]) s.getValueForPixel(p),
      ],
      'basePixel': s.getBasePixel(),
      ...?extra?.call(s, chart),
    };
  }
  final area = chart.chartArea!;
  final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
  return <String, Object?>{
    'chartArea': [area.left, area.top, area.right, area.bottom],
    'scales': scales,
    'points': [
      for (var i = 0; i < datasets.length; i++)
        [
          for (final p in chart.getDatasetMeta(i.toDouble()).data) [p.x, p.y],
        ],
    ],
  };
}

// ---------------------------------------------------------------------------
// The comparison.

/// A matcher of a reference value.
///
/// - A number: [closeTo] with 1e-9, or with `n.abs() * 1e-12` above 1e3.
///   `dart:math` can differ from V8 in the last bit (Chart.js ADR 0034,
///   `js-semantics-dart-math`).
/// - NaN: [isNaN]. An infinity: [equals].
/// - `{'num': s}`, a number that JSON cannot hold: `'NaN'`, `'Infinity'`,
///   `'-Infinity'` or `'-0'`. `'-0'` matches both zeros: no behavior
///   depends on the sign of a zero pixel (Chart.js ADR 0034).
/// - Lists and maps: item by item. Other values: `==`.
Object? referenceMatcher(Object? expected) => switch (expected) {
  final num n when n.isNaN => isNaN,
  final num n when n.isInfinite => equals(n),
  final num n => closeTo(n, n.abs() > 1e3 ? n.abs() * 1e-12 : 1e-9),
  final Map<String, Object?> map when map.length == 1 && map['num'] is String =>
    switch (map['num']) {
      'NaN' => isNaN,
      '-0' => closeTo(0, 0),
      'Infinity' => equals(double.infinity),
      '-Infinity' => equals(double.negativeInfinity),
      final s => throw ArgumentError.value(s, 'num', 'Not a reference number'),
    },
  final List<Object?> list => [for (final item in list) referenceMatcher(item)],
  final Map<String, Object?> map => {
    for (final MapEntry(:key, :value) in map.entries)
      key: referenceMatcher(value),
  },
  _ => expected,
};

/// The matchers of the calls of a reference text: one JSON array
/// `[name, ...args]` for each line, as the records `{name, args}` of
/// [MockContext]. A `Path2D` argument `{path, calls}` of the generators
/// matches the form of `recordedCalls` (path2d_record.dart): the id
/// exactly, and its calls with the same rules.
List<Object?> callMatchers(Object? text) => [
  for (final line in (text! as String).split('\n'))
    if (line.isNotEmpty) _callMatcher(jsonDecode(line) as List<Object?>),
];

/// The matcher of one reference call `[name, ...args]`.
Map<String, Object?> _callMatcher(List<Object?> call) => {
  'name': call[0],
  'args': [for (final arg in call.skip(1)) _argMatcher(arg)],
};

/// The matcher of one argument of a reference call: a `Path2D` record
/// `{path, calls}`, a List item by item, or [referenceMatcher].
Object? _argMatcher(Object? arg) => switch (arg) {
  {'path': final int id, 'calls': final List<Object?> calls}
      when arg.length == 2 =>
    <String, Object?>{
      'path': id,
      'calls': [
        for (final call in calls) _callMatcher(call! as List<Object?>),
      ],
    },
  final List<Object?> list => [for (final item in list) _argMatcher(item)],
  _ => referenceMatcher(arg),
};

/// The calls of the rectangle paths of a bar: `addNormalRectPath`
/// (element.bar.js:123-125) and `addRoundedRectPath`
/// (helpers.canvas.ts:498-527). The `roundRect` of the port records as the
/// upstream calls ([RecordingContext]).
const Set<String> _barPathCalls = {
  'rect',
  'moveTo',
  'lineTo',
  'arc',
  'closePath',
};

/// The `fill('evenodd')` calls of the calls with the names [names] and the
/// first arguments [firstArgs], in order. For each: `ring` is true when the
/// calls since its `beginPath` have the form of the border ring of a bar
/// (element.bar.js:186-192): path calls, at most one `clip`, then one
/// `setFillStyle`. `clip` is the index of that `clip`, or Dart `null`.
List<({bool ring, int? clip})> _evenOddFills(
  List<Object?> names,
  List<Object?> firstArgs,
) {
  final fills = <({bool ring, int? clip})>[];
  for (var f = 0; f < names.length; f++) {
    if (names[f] != 'fill' || firstArgs[f] != 'evenodd') continue;
    var ring = false;
    int? clip;
    if (f > 0 && names[f - 1] == 'setFillStyle') {
      for (var k = f - 2; k >= 0; k--) {
        final name = names[k];
        if (name == 'beginPath') {
          ring = true;
          break;
        }
        if (name == 'clip' && clip == null) {
          clip = k;
        } else if (!_barPathCalls.contains(name)) {
          break;
        }
      }
    }
    fills.add((ring: ring, clip: ring ? clip : null));
  }
  return fills;
}

/// The indexes of the reference calls [matchers] that the row
/// `adapt-bar-clip` of differences.md removes for the recorded calls
/// [actual].
///
/// Upstream clips to the outer rectangle before it fills the border ring
/// of a bar (element.bar.js:186-189). The port does not call `clip` when
/// `inflateAmount` is 0 (element.bar.dart `draw`). The row says: "the tests
/// remove `clip` from the reference calls of such a bar". The k-th
/// `fill('evenodd')` of [matchers] pairs with the k-th of [actual]. When
/// the reference fill is a ring with a `clip` and the recorded fill is a
/// ring without a `clip`, that `clip` goes. When the two counts differ,
/// nothing goes: the compare then fails.
///
/// The path arguments still compare. A reference bar with an amount that
/// is not 0 has an outer path that `inflateRect` moves by the amount
/// (element.bar.js:127-139): the ring is there only when an edge of the
/// outer rectangle differs from the inner one. Thus a port bar with the
/// amount 0 in its place fails at a path argument.
Set<int> _barClipsToRemove(List<Object?> actual, List<Object?> matchers) {
  Object? nameOf(Object? call) => (call! as Map<String, Object?>)['name'];
  Object? firstArgOf(Object? call) => switch ((call! as Map)['args']) {
    [final first, ...] => first,
    _ => null,
  };
  final expectedFills = _evenOddFills(
    [for (final m in matchers) nameOf(m)],
    [for (final m in matchers) firstArgOf(m)],
  );
  final actualFills = _evenOddFills(
    [for (final c in actual) nameOf(c)],
    [for (final c in actual) firstArgOf(c)],
  );
  if (expectedFills.length != actualFills.length) return const {};
  return {
    for (var k = 0; k < expectedFills.length; k++)
      if (expectedFills[k]
          case (
            ring: true,
            :final int clip,
          )
          when actualFills[k].ring && actualFills[k].clip == null)
        clip,
  };
}

/// Expects the recorded calls [actual] to match the reference text
/// [expected], call by call. [actual] has the form of `recordedCalls`
/// (path2d_record.dart), as [drawCalls] gives it. The [reason] of a failure
/// names the index of the call.
///
/// Before the compare, the `clip` of the border ring of each bar that the
/// port draws without a `clip` goes from the reference calls (the row
/// `adapt-bar-clip` of differences.md, [_barClipsToRemove]).
void expectCalls(
  List<Object?> actual,
  Object? expected, {
  String reason = 'calls',
}) {
  final all = callMatchers(expected);
  final removed = _barClipsToRemove(actual, all);
  final matchers = [
    for (var i = 0; i < all.length; i++)
      if (!removed.contains(i)) all[i],
  ];
  final count = math.min(actual.length, matchers.length);
  for (var i = 0; i < count; i++) {
    expect(actual[i], matchers[i], reason: '$reason: call $i');
  }
  expect(actual.length, matchers.length, reason: '$reason: the call count');
}

/// A mutable copy of a reference value, with each `'fn:<name>'` replaced by
/// the function [functions] gives for the name. The chart and
/// `acquireChart` write into the config and the options.
Object? copyReference(
  Object? value, [
  Map<String, Object?> functions = const {},
]) => switch (value) {
  final String s when s.startsWith('fn:') =>
    functions.containsKey(s.substring(3))
        ? functions[s.substring(3)]
        : throw ArgumentError.value(s, 'value', 'No function of this name'),
  final Map<String, Object?> map => <String, Object?>{
    for (final MapEntry(:key, :value) in map.entries)
      key: copyReference(value, functions),
  },
  final List<Object?> list => <Object?>[
    for (final item in list) copyReference(item, functions),
  ],
  _ => value,
};

/// The keys of the observations that [expectScaleObservations] compares.
const List<String> _scaleObservationKeys = ['chartArea', 'scales', 'points'];

/// Expects the observations [observed] (the Map of [observeChart], or a Map
/// with the same keys) to match [expected], for each key of [expected]:
/// `chartArea`, `scales` and `points`. A failure names the key:
/// `chartArea`, `scales.<id>.<key>` or `points`. [expected] must have no
/// other key: a key that no check reads cannot fail.
///
/// The controller harness calls it for the keys `chartArea` and `scales`,
/// with the name of the observation in [label]: each reason starts with
/// it.
void expectScaleObservations(
  Map<String, Object?> observed,
  Map<String, Object?> expected, {
  String label = '',
}) {
  final prefix = label.isEmpty ? '' : '$label: ';
  expect(
    expected.keys.where((key) => !_scaleObservationKeys.contains(key)),
    isEmpty,
    reason: '${prefix}the keys of the scale observations',
  );
  if (expected.containsKey('chartArea')) {
    expect(
      observed['chartArea'],
      referenceMatcher(expected['chartArea']),
      reason: '${prefix}chartArea',
    );
  }
  if (expected.containsKey('scales')) {
    final scales = observed['scales']! as Map<String, Object?>;
    final expectedScales = expected['scales']! as Map<String, Object?>;
    expect(
      scales.keys,
      orderedEquals(expectedScales.keys),
      reason: '${prefix}scale ids',
    );
    for (final MapEntry(key: id, :value) in expectedScales.entries) {
      final scale = scales[id]! as Map<String, Object?>;
      final expectedScale = value! as Map<String, Object?>;
      expect(
        scale.keys,
        orderedEquals(expectedScale.keys),
        reason: '${prefix}keys of scale $id',
      );
      for (final key in expectedScale.keys) {
        expect(
          scale[key],
          referenceMatcher(expectedScale[key]),
          reason: '${prefix}scales.$id.$key',
        );
      }
    }
  }
  if (expected.containsKey('points')) {
    expect(
      observed['points'],
      referenceMatcher(expected['points']),
      reason: '${prefix}points',
    );
  }
}

/// Expects [chart] to give the observations and the draw calls of
/// [expected], the `expected` of a reference case. A failure names the key:
/// `chartArea`, `scales.<id>.<key>`, `points` or the index of the call.
/// [expected] must have no other key: a key that no check reads cannot
/// fail.
void expectScaleChart(
  Chart chart,
  Map<String, Object?> expected, {
  ScaleObservations? extra,
}) {
  expect(
    expected.keys,
    unorderedEquals(['chartArea', 'scales', 'points', 'drawCalls']),
    reason: 'the keys of the reference case',
  );
  expectScaleObservations(observeChart(chart, extra: extra), {
    for (final key in _scaleObservationKeys) key: expected[key],
  });
  expectCalls(drawCalls(chart), expected['drawCalls'], reason: 'draw');
}

// ---------------------------------------------------------------------------
// The test cases of a reference file.

/// One case of a reference file: the `ReferenceCase` typedef of the
/// generated file has this record type.
typedef ScaleChartCase = ({
  String name,
  Map<String, Object?> config,
  Map<String, Object?> options,
  Map<String, Object?> expected,
});

/// One width of a reference file: the `ReferenceWidth` typedef of the
/// generated file has this record type.
typedef ScaleChartWidth = ({String font, String text, double width});

/// A test that the reference comes from Node.js v24.12.0 on x64 (Chart.js
/// ADR 0032) and from a build of the pinned Chart.js: [dist] is
/// [chartJsVersion], and [commit] is a full commit. For a commit pin, the
/// commit starts with the sha8 of [chartJsVersion].
void testReferenceOrigin({
  required String node,
  required String arch,
  required String dist,
  required String commit,
}) {
  test('the reference comes from Node.js v24.12.0 on x64 and a build of the '
      'pinned Chart.js', () {
    expect(node, 'v24.12.0');
    expect(arch, 'x64');
    expect(dist, chartJsVersion);
    expect(commit, matches(RegExp(r'^[0-9a-f]{40}$')));
    final plus = chartJsVersion.indexOf('+');
    if (plus >= 0) {
      expect(commit, startsWith(chartJsVersion.substring(plus + 1)));
    }
  });
}

/// A `testWidgets` case for each of [cases]: the chart of `acquireChart`
/// with the config and the options of the case ([copyReference] with
/// [functions]), then [expectScaleChart] with [extra].
void testScaleChartCases(
  List<ScaleChartCase> cases, {
  Map<String, Object?> functions = const {},
  ScaleObservations? extra,
}) {
  for (final c in cases) {
    testWidgets(c.name, (tester) async {
      final chart = acquireChart(
        copyReference(c.config, functions)! as AnyObject,
        copyReference(c.options)! as AnyObject,
      );
      expectScaleChart(chart, c.expected, extra: extra);
    });
  }
}

/// The first font of a canvas (HTML), and of the mock of the generators.
const String _firstFont = '10px sans-serif';

/// A test for each font of [widths]: each text in that font on the canvas
/// of the harness has the width of the generator.
///
/// A test writes its font on a new canvas. For the first font of a canvas,
/// `'10px sans-serif'`, it writes no font: the first font of the canvas of
/// the harness must be the first font of the mock of the generator.
///
/// The generator adds the advances and the `kern` pairs of Liberation Sans
/// 2.1.5 in float64. Flutter adds float32 advances. For integer px sizes
/// each advance is `units * size / 2048`, a dyadic number, and both sums
/// are exact. Thus the widths are equal to 1e-9.
void testReferenceWidths(List<ScaleChartWidth> widths) {
  final fonts = <String, List<ScaleChartWidth>>{};
  for (final width in widths) {
    (fonts[width.font] ??= []).add(width);
  }
  for (final MapEntry(key: font, value: texts) in fonts.entries) {
    test('${texts.length} texts in $font', () {
      final ctx = UiCanvasElement().getContext2d();
      if (font != _firstFont) ctx.font = font;
      expect(ctx.font, font, reason: 'the canvas takes the font');
      for (final (font: _, :text, :width) in texts) {
        expect(
          ctx.measureText(text).width,
          closeTo(width, 1e-9),
          reason: text,
        );
      }
    });
  }
}
