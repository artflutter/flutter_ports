// Ported from Chart.js v4.6.1 src/plugins/plugin.filler/index.js (MIT, Chart.js Contributors).

/// Port of `src/plugins/plugin.filler/index.js`.
///
/// Plugin based on discussion from the following Chart.js issues:
/// @see https://github.com/chartjs/Chart.js/issues/2380#issuecomment-279961569
/// @see https://github.com/chartjs/Chart.js/issues/2440#issuecomment-256461897
///
/// [filler] is the plugin object, the default export of the upstream file
/// and `Filler` of `src/plugins/index.js:3` (Chart.js ADR 0038, section 1).
/// It is a mutable Map with the upstream keys in the upstream order. The
/// hooks are closures with the upstream parameter count (Chart.js ADR 0038,
/// section 3).
///
/// [FillerSource] is the source object of `index.js:26-34`. The other
/// filler files import it with `show FillerSource`: the Dart form of the
/// JSDoc type of their `source` parameters (Chart.js ADR 0040, section 6).
/// `meta.$filler` is an extra property of the meta, through the access by
/// name of `types.PropertyAccess`.
///
/// This library is a pure layer (Chart.js ADR 0038, section 9).
library;

import 'package:flutter_chartjs_port/src/elements/element.line.dart'
    show LineElement;
import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsToNumber, jsToString, jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.drawing.dart'
    show drawfill;
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.helper.dart'
    show shouldApplyFill;
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.options.dart'
    show decodeFill, resolveTarget;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// index.js:26-34, the source object of a dataset. The fields keep the
/// upstream key order. `index.js:47` writes [fill].
///
/// `jsGet` of a source gives `undefined` for each key, as for the typed
/// elements. No reader at the pin reads a source by a dynamic key (Chart.js
/// ADR 0040, section 6).
final class FillerSource {
  /// index.js:26 the object literal.
  FillerSource({
    required this.visible,
    required this.index,
    required this.fill,
    required this.chart,
    required this.axis,
    required this.scale,
    required this.line,
  });

  /// index.js:27 `visible: chart.isDatasetVisible(i)`.
  final bool visible;

  /// index.js:28 `index: i`, the dataset index.
  final double index;

  /// index.js:29 `fill: _decodeFill(line, i, count)`: `false`, a `double`
  /// dataset index, a `String` mode or the option object `{value}`
  /// (filler.options.js:46-73). `_resolveTarget` writes it (index.js:47).
  Object fill;

  /// index.js:30 `chart`.
  final types.Chart chart;

  /// index.js:31 `axis: meta.controller.options.indexAxis`: any option
  /// value.
  final Object? axis;

  /// index.js:32 `scale: meta.vScale`. Dart `null` is JS `undefined`.
  final types.Scale? scale;

  /// index.js:33 `line`, a `LineElement` (index.js:25).
  final types.LineElement line;
}

/// The axis argument of `source.line.updateControlPoints(area, source.axis)`
/// (index.js:61): Dart `null` for the `undefined` of an absent option, else
/// the String, or the `ToString` of another option value.
String? _axisArgument(Object? axis) => switch (axis) {
  final String value => value,
  null || Undefined() => null,
  _ => jsToString(axis),
};

/// index.js:12 the default export, `Filler` of `src/plugins/index.js:3`
/// (Chart.js ADR 0038, section 1).
final AnyObject filler = <String, Object?>{
  'id': 'filler',

  // index.js:15 `afterDatasetsUpdate(chart, _args, options)`.
  'afterDatasetsUpdate': (types.Chart chart, AnyObject _, AnyObject options) {
    final datasets = jsGet(chart.data, 'datasets');
    final count = jsTruthy(datasets)
        ? jsToNumber(jsGet(datasets, 'length'))
        : 0.0;
    final sources = <FillerSource?>[];

    for (var i = 0; i < count; ++i) {
      final index = i.toDouble();
      final meta = chart.getDatasetMeta(index);
      final line = meta.dataset;
      FillerSource? source;

      if (line != null && jsTruthy(line.options) && line is LineElement) {
        source = FillerSource(
          visible: chart.isDatasetVisible(index),
          index: index,
          fill: decodeFill(line, index, count),
          chart: chart,
          axis: jsGet(meta.controller!.options, 'indexAxis'),
          scale: meta.vScale,
          line: line,
        );
      }

      (meta as types.PropertyAccess)[r'$filler'] = source;
      sources.add(source);
    }

    for (var i = 0; i < count; ++i) {
      final source = sources[i];
      if (source == null || source.fill == false) {
        continue;
      }

      source.fill = resolveTarget(
        sources,
        i,
        jsTruthy(jsGet(options, 'propagate')),
      );
    }
  },

  // index.js:51 `beforeDraw(chart, _args, options)`. `if (!source)` is the
  // type test: the port writes only Dart `null` and a [FillerSource], and an
  // absent property reads `undefined` (Chart.js ADR 0040, section 6).
  'beforeDraw': (types.Chart chart, AnyObject _, AnyObject options) {
    final draw = jsGet(options, 'drawTime') == 'beforeDraw';
    final metasets = chart.getSortedVisibleDatasetMetas();
    final area = chart.chartArea;
    for (var i = metasets.length - 1; i >= 0; --i) {
      final source = (metasets[i] as types.PropertyAccess)[r'$filler'];
      if (source is! FillerSource) {
        continue;
      }

      source.line.updateControlPoints(area, _axisArgument(source.axis));
      if (draw && jsTruthy(source.fill)) {
        drawfill(chart.ctx!, source, area);
      }
    }
  },

  // index.js:68 `beforeDatasetsDraw(chart, _args, options)`.
  'beforeDatasetsDraw': (types.Chart chart, AnyObject _, AnyObject options) {
    if (jsGet(options, 'drawTime') != 'beforeDatasetsDraw') {
      return;
    }

    final metasets = chart.getSortedVisibleDatasetMetas();
    for (var i = metasets.length - 1; i >= 0; --i) {
      final source = (metasets[i] as types.PropertyAccess)[r'$filler'];

      if (shouldApplyFill(source)) {
        drawfill(chart.ctx!, source! as FillerSource, chart.chartArea);
      }
    }
  },

  // index.js:83 `beforeDatasetDraw(chart, args, options)`. `args.meta` is
  // the meta of the dataset (core.controller.js:785-789).
  'beforeDatasetDraw': (types.Chart chart, AnyObject args, AnyObject options) {
    final source = (jsGet(args, 'meta')! as types.PropertyAccess)[r'$filler'];

    if (!shouldApplyFill(source) ||
        jsGet(options, 'drawTime') != 'beforeDatasetDraw') {
      return;
    }

    drawfill(chart.ctx!, source! as FillerSource, chart.chartArea);
  },

  // index.js:93-96.
  'defaults': <String, Object?>{
    'propagate': true,
    'drawTime': 'beforeDatasetDraw',
  },
};
