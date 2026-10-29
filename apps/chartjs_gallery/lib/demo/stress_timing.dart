// Original code, not ported from Chart.js: the timing parts of a chart.

/// The time of four parts of the chart path, from the hooks of an inline
/// plugin ([plugin]), in the ticks of a `Stopwatch` (Chart.js ADR 0031
/// section 6).
///
/// - elements: `beforeElementsUpdate` to `beforeLayout`
///   (core.controller.js:497-510, :611-612): `buildOrUpdateElements` of each
///   dataset (the parse) and the first `getMaxOverflow`.
/// - layout: `beforeLayout` to `afterLayout`, the update and the fit of the
///   scales (`layouts.update`): the data limits, the ticks, the label
///   sizes, the rotation and the auto skip.
/// - datasetsUpdate: `beforeDatasetsUpdate` to `afterDatasetsUpdate`, the
///   update of the elements: `getPixelForValue` for each point, and the
///   second `getMaxOverflow` (core.datasetController.js:704).
/// - datasetsDraw: `beforeDatasetsDraw` to `afterDatasetsDraw`, the draw of
///   the elements. The draw time without this part is the draw of the
///   scales and of the other plugins: in the stress tab, also the labels
///   and the title of the plugin `stressLabels`.
///
/// The hooks run in `chart.update()` and `chart.draw()` (core.controller.js
/// notifies each of them). A call of `draw` alone gives no elements, no
/// layout and no update time.
///
/// The parts add the hooks of all the calls of the chart: also the update at
/// the construction of the chart and the update of a resize. To time one
/// call only, call [StressChartTiming.reset] before the call and read the
/// parts after it, as the stress tab does.
final class StressChartTiming {
  /// The clock of the hooks.
  static final Stopwatch _watch = Stopwatch()..start();

  /// The ticks of a `Stopwatch` in one millisecond.
  static final double ticksPerMs = _watch.frequency / 1000;

  /// The ticks of the element updates since the last [take]:
  /// `beforeElementsUpdate` to `beforeLayout` (core.controller.js:497-510,
  /// :611-612): `buildOrUpdateElements` of each dataset (the parse) and the
  /// first `getMaxOverflow`.
  int elementsTicks = 0;

  /// The ticks of the layouts since the last [take].
  int layoutTicks = 0;

  /// The ticks of the dataset updates since the last [take].
  int datasetsUpdateTicks = 0;

  /// The ticks of the dataset draws since the last [take].
  int datasetsDrawTicks = 0;

  /// The start of the element update of the current update, or -1 when no
  /// `beforeElementsUpdate` came before the next `beforeLayout`.
  int _elementsStart = -1;
  int _layoutStart = 0;
  int _datasetsUpdateStart = 0;
  int _datasetsDrawStart = 0;

  /// The inline plugin `stressChartTiming`. A hook returns Dart `null`
  /// (JS `undefined`): it cancels nothing.
  late final Map<String, Object?> plugin = <String, Object?>{
    'id': 'stressChartTiming',
    'beforeElementsUpdate': (Object? chart, Object? args, Object? options) {
      _elementsStart = _watch.elapsedTicks;
    },
    'beforeLayout': (Object? chart, Object? args, Object? options) {
      final now = _watch.elapsedTicks;
      if (_elementsStart >= 0) {
        elementsTicks += now - _elementsStart;
        _elementsStart = -1;
      }
      _layoutStart = now;
    },
    'afterLayout': (Object? chart, Object? args, Object? options) {
      layoutTicks += _watch.elapsedTicks - _layoutStart;
    },
    'beforeDatasetsUpdate': (Object? chart, Object? args, Object? options) {
      _datasetsUpdateStart = _watch.elapsedTicks;
    },
    'afterDatasetsUpdate': (Object? chart, Object? args, Object? options) {
      datasetsUpdateTicks += _watch.elapsedTicks - _datasetsUpdateStart;
    },
    'beforeDatasetsDraw': (Object? chart, Object? args, Object? options) {
      _datasetsDrawStart = _watch.elapsedTicks;
    },
    'afterDatasetsDraw': (Object? chart, Object? args, Object? options) {
      datasetsDrawTicks += _watch.elapsedTicks - _datasetsDrawStart;
    },
  };

  /// The ticks of each part since the last call, by the name of the part:
  /// `elements`, `layout`, `datasetsUpdate` and `datasetsDraw`. It resets
  /// the parts.
  Map<String, int> take() {
    final parts = {
      'elements': elementsTicks,
      'layout': layoutTicks,
      'datasetsUpdate': datasetsUpdateTicks,
      'datasetsDraw': datasetsDrawTicks,
    };
    reset();
    return parts;
  }

  /// Sets each part to 0.
  void reset() {
    elementsTicks = 0;
    layoutTicks = 0;
    datasetsUpdateTicks = 0;
    datasetsDrawTicks = 0;
  }
}
