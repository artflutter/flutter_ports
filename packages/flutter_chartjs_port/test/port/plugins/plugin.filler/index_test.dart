// Original code, not ported from Chart.js: filler plugin reference tests.
@TestOn('vm')
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsLessThan;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.target.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/index.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/simpleArc.dart';
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../../controllers/controller_chart_harness.dart' show plainValue;
import '../../scales/scale_chart_harness.dart';
import '../plugin_chart_harness.dart';
import 'plugin_filler_reference.dart';

// The port-only reference tests of lib/src/plugins/plugin.filler/ (Chart.js
// ADR 0041, section 3, and Chart.js ADR 0040). The spec port is
// test/specs/plugin.filler_test.dart.
//
// The reference group compares real charts with the charts of
// tool/reference/plugin_filler_reference.mjs: a build of the pinned
// Chart.js in Node.js v24.22.1 on arm64 (Chart.js ADR 0045), with the seven
// plugins registered and `colors.enabled: false` in the defaults. Each case
// is a unit case (the other plugins are `false`, Chart.js ADR 0041, section
// 4), except the full cases (the names that start with `full:`), which have
// the default plugin options (section 4 item 2). The observation has `boxes`
// and `plugins.filler` (`meta.$filler` of each dataset), and the draw calls.
// The probe `targets` compares the target of `getTarget` of each source after
// the draw with the target of the pinned `_getTarget`: the five wraps and the
// bare point of the list result of Chart.js ADR 0040 give the upstream points
// (the difference `adapt-line-points-elements`).
//
// The cases run two times: unthemed, and with the light preset (theming.md
// section 8 test 3). In the themed run, the colors compare in their parsed
// form, and the options compare only the keys of upstream.

/// The named functions of the configs of the generator, with the same
/// bodies.
final Map<String, Object?> _functions = {
  // (ctx) => (ctx.p0DataIndex < 2 ? 'red' : 'blue')
  'segStyle': (Object? ctx) =>
      jsLessThan(jsGet(ctx, 'p0DataIndex'), 2) ? 'red' : 'blue',
  // () => false
  'noLayout': () => false,
};

/// The observer `plugins.filler` of the generator (`observeFiller`): for
/// each dataset, `meta.$filler` as Dart `null`, or `{visible, index, fill,
/// axis, scale}` with the plain resolved `fill` and the id of the scale.
Object? _observeFiller(Chart chart) {
  final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
  return [
    for (var i = 0; i < datasets.length; i++)
      _observeSource(chart.getDatasetMeta(i)),
  ];
}

/// The entry of [_observeFiller] for one meta.
Object? _observeSource(types.ChartMeta meta) {
  final source = (meta as types.PropertyAccess)[r'$filler'];
  if (source is! FillerSource) {
    return source;
  }
  return <String, Object?>{
    'visible': source.visible,
    'index': source.index,
    'fill': plainValue(source.fill),
    'axis': source.axis,
    'scale': source.scale?.id ?? undefined,
  };
}

/// The most points of a target line in the data (`MAX_POINTS`).
const int _maxPoints = 60;

/// `describeTarget` of the generator: the target [target] of `getTarget`.
/// The properties of a line and of its points are the reads by name.
Object? _describeTarget(Object? target) {
  if (target == true) return 'shape';
  if (target == null) return null;
  if (target is SimpleArc) {
    return <String, Object?>{
      'kind': 'simpleArc',
      'x': target.x,
      'y': target.y,
      'radius': target.radius,
    };
  }
  if (target is! types.LineElement) {
    return <String, Object?>{'kind': 'element'};
  }
  final line = target as Element;
  final points = target.points;
  return <String, Object?>{
    'kind': 'line',
    'loop': line['_loop'],
    'fullLoop': line['_fullLoop'],
    'count': points.length.toDouble(),
    'points': points.length > _maxPoints
        ? undefined
        : [
            for (final point in points.cast<Element>())
              [point['x'], point['y'], point['angle']],
          ],
  };
}

/// The probe `targets` of the generator: the target of each source after
/// the draw.
Object? _targets(Chart chart) {
  final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
  return [
    for (var i = 0; i < datasets.length; i++)
      switch ((chart.getDatasetMeta(i) as types.PropertyAccess)[r'$filler']) {
        final FillerSource source => _describeTarget(getTarget(source)),
        _ => null,
      },
  ];
}

/// The keys of the default export of index.js:12-97, in their order.
const List<String> _upstreamKeys = [
  'id',
  'afterDatasetsUpdate',
  'beforeDraw',
  'beforeDatasetsDraw',
  'beforeDatasetDraw',
  'defaults',
];

void main() {
  testReferenceOrigin(
    node: pluginFillerReferenceNode,
    arch: pluginFillerReferenceArch,
    dist: pluginFillerReferenceDist,
    commit: pluginFillerReferenceCommit,
  );
  testReferenceWidths(pluginFillerReferenceWidths);

  test('the reference has the cases of filler spec section 4.2', () {
    expect(
      [for (final c in pluginFillerReference) c.name],
      [
        'fill origin',
        'fill start',
        'fill end',
        'fill value',
        'fill true',
        'fill false',
        'fill -1',
        'fill +1',
        'fill as a dataset index',
        'fill stack',
        'fill shape',
        'a gap without spanGaps',
        'a gap with spanGaps',
        'stepped',
        'a tension with fill -1',
        'monotone',
        'indexAxis y with fill origin',
        'indexAxis y with fill -1',
        'above and below on x',
        'above and below on y',
        'above and below between two lines',
        'clip false',
        'drawTime beforeDraw',
        'drawTime beforeDatasetsDraw',
        'propagate false with a hidden target',
        'propagate true with a hidden target',
        'stack above a line with segment styles',
        'stack above a line whose x goes back',
        'stack above a line without segment styles',
        'stack on a scatter chart',
        'an empty target on x',
        'an empty target on y',
        'offset with min and max on a category scale',
        '120 points without parsing',
        'radar origin',
        'radar start',
        'radar end',
        'radar value',
        'radar with a gap',
        'radar fill 1',
        'radar reverse',
        'radar with a negative minimum',
        'radar with r min and max',
        'radar with a positive r min',
        'radar circular',
        'radar circular with a gap',
        'throws: shape with two colors',
        'throws: radar without a layout',
        'full: radar with colors on',
        'full: lttb with fill origin',
        'full: min-max with fill stack',
      ],
    );
  });

  testPluginChartCases(
    pluginFillerReference,
    observers: {'filler': _observeFiller},
    functions: _functions,
    extras: {'targets': _targets},
  );

  group('theming.md §8 test 3: the light preset', () {
    testPluginChartCases(
      pluginFillerReference,
      observers: {'filler': _observeFiller},
      functions: _functions,
      extras: {'targets': _targets},
      theme: compileChartTheme(ChartThemes.light),
    );
  });

  group('plugin object', () {
    test('the keys of the plugin object are the upstream keys', () {
      expect(jsObjectKeys(filler), _upstreamKeys);
    });

    test('the defaults are the upstream defaults (index.js:93-96)', () {
      final defaults = filler['defaults']! as JsObjectFace;
      expect(jsObjectKeys(defaults), ['propagate', 'drawTime']);
      expect(defaults['propagate'], isTrue);
      expect(defaults['drawTime'], 'beforeDatasetDraw');
    });
  });
}
