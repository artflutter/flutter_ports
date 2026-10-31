// Ported from chartjs-test-utils v0.4.0 src/index.js (MIT, chartjs-test-utils Contributors).

/// Port of `src/index.js`, the entry point of chartjs-test-utils.
///
/// The members of `src/index.js` go to these places (porting-flow.md
/// section 3, Chart.js ADR 0022):
/// - The imports of `src/utils.js` (index.js:3): `utils.dart` with the
///   prefix `utils`. The Dart names of `_acquireChart` and `_releaseChart`
///   are `acquireChart` and `releaseChart`, the names of this file (Chart.js
///   ADR 0012, Collisions).
/// - The re-exports of `src/utils.js` (index.js:6): `afterEvent`,
///   `waitForResize` and `triggerMouseEvent`.
///   `package:chartjs_test_utils/flutter.dart` exports them.
/// - [acquireChart] (index.js:22), [releaseChart] (index.js:28),
///   [releaseCharts] (index.js:54) and the registry [charts] (index.js:9).
///   They need the chart and its host. Thus this file is not a pure layer.
/// - `createMockContext` (index.js:33): in `context.dart`, so that
///   `package:chartjs_test_utils/pure.dart` keeps it
///   (`harness-index-pure-split`).
/// - The re-export of `src/fixture.js` (index.js:5): `fixture.dart`, the
///   smoke runner of Chart.js ADR 0029 (`specsFromFixtures`,
///   `specFromFixture`, `FixtureSource` and its types).
///   `package:chartjs_test_utils/flutter.dart` exports them.
/// - `injectWrapperCSS` (index.js:37): `n/a`. Flutter has no CSS. The DOM
///   stand-in (`dom.dart`) gives the class `chartjs-wrapper` the effect of
///   the rule.
/// - `addMatchers` (index.js:50): `n/a`. A matcher is a function that
///   returns a `Matcher` (`matchers.dart`). A spec imports it.
library;

import 'package:chartjs_test_utils/src/utils.dart' as utils;
// The harness keeps the charts of flutter_chartjs_port, which does not export
// lib/src.
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
// The JS property read and ToBoolean of `(chart.$test || {}).persistent`.
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/js/js_number.dart';
// The JS property read.
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/js/js_object.dart';

export 'fixture.dart';
export 'utils.dart' show afterEvent, triggerMouseEvent, waitForResize;

/// index.js:9 `charts`: keep track of all acquired charts to automatically
/// release them after each specs.
///
/// The key is the [Chart.id] of each chart. Upstream keys the object by the
/// `ToString` of the id. The ids grow. Thus the insertion order of the Map
/// is the order of `Object.keys` for the integer keys. [releaseCharts]
/// never deletes a chart: only [releaseChart] does.
final Map<Object, Chart> charts = {};

/// index.js:22 `acquireChart(config, options)`.
///
/// Injects a new canvas (and div wrapper) and creates the associated Chart
/// instance using the given config. Additional options allow tweaking
/// elements generation. See `utils.acquireChart` for [config] and
/// [options]: `canvas`, `wrapper`, `useOffscreenCanvas`, `useShadowDOM`
/// and `persistent`.
///
/// It is synchronous, and it works only in the body of a `testWidgets` test
/// (Chart.js ADR 0022, section 4). The chart is attached at its
/// construction.
///
/// [config] is a JS object literal of a spec: a Map. A nested Map literal
/// gets the type `<String, Object?>` from the parameter type.
Chart acquireChart([
  Map<String, Object?>? config,
  Map<String, Object?>? options,
]) {
  final chart = utils.acquireChart(config, options);
  charts[chart.id] = chart;
  return chart;
}

/// [acquireChart] for a config that is not a Map: the typed root scope of a
/// typed config (`ChartConfigLowering`, Chart.js ADR 0054 §7). Port-only.
Chart acquireChartRoot(Object config, [Map<String, Object?>? options]) {
  final chart = utils.acquireChart(config, options);
  charts[chart.id] = chart;
  return chart;
}

/// index.js:28 `releaseChart(chart)`.
void releaseChart(Chart chart) {
  utils.releaseChart(chart);
  charts.remove(chart.id);
}

// index.js:33-35 `createMockContext` is in context.dart
// (harness-index-pure-split).

// index.js:37 `injectWrapperCSS()`: n/a. The class `chartjs-wrapper` of
// dom.dart gives the effect of the rule.

// index.js:50 `addMatchers()`: n/a. A spec imports the matchers.

/// index.js:54 `releaseCharts()`.
///
/// Releases each chart of [charts] that is not persistent. It never deletes
/// a chart from [charts]. Thus each later call destroys the earlier charts
/// again, as upstream does after each spec. `destroy()` on a destroyed chart
/// does not throw.
///
/// `test/flutter_test_config.dart` calls it at the unmount of the harness
/// body, and in a `tearDown` as the fallback (`harness-release-at-unmount`,
/// Chart.js ADR 0022, section 8).
void releaseCharts() {
  for (final id in List.of(charts.keys)) {
    final chart = charts[id]!;
    if (!jsTruthy(
      jsGet(utils.$test[chart] ?? <String, Object?>{}, 'persistent'),
    )) {
      utils.releaseChart(chart);
    }
  }
}
