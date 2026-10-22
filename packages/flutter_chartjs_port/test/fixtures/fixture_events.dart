// Original code, not ported from Chart.js: the raw DOM event of the tooltip fixtures as a chart event.
// The header line is longer than 80 columns and has no URI.
// ignore_for_file: lines_longer_than_80_chars

/// The chart event of the raw `mousemove` of the tooltip fixtures
/// (Chart.js ADR 0041, section 10 item 2).
///
/// The 8 fixtures of `test/fixtures/plugin.tooltip/` make the raw event
/// `{type: 'mousemove', target: canvas, clientX, clientY}` at a data point
/// and give it to `chart._handleEvent`, `chart.tooltip.handleEvent` and
/// `chart.tooltip.draw`. The port gives the chart event that
/// `getRelativePosition` (helpers.dom.ts:105-130) gives for that event. The
/// hand ports in `hand/plugin.tooltip/` call [fixtureMouseMove].
///
/// This file is not a hand port and not a test entry: it is outside
/// `hand/`, as `index.dart` is.
library;

import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsRound;
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// The chart event that getRelativePosition (helpers.dom.ts:105-130) gives
/// for the raw `mousemove` of a tooltip fixture at [point]: at DPR 1 and
/// with the canvas at the origin of its host, Math.round of the point
/// (:128-129). Its `native` is null: the raw event has no `native` key.
/// Row harness-fixture-sources.
///
/// One value differs: upstream `tooltip._eventPosition` is `{x: undefined,
/// y: undefined}` for the raw event, and here it has the numbers. Only the
/// positioner `nearest` reads it, and the 8 fixtures use `average`.
types.ChartEvent fixtureMouseMove(Point point) =>
    _FixtureEvent(jsRound(point.x ?? 0), jsRound(point.y ?? 0));

/// The chart event of [fixtureMouseMove]: the type `mousemove` and the
/// relative position. The form of `_PointEvent` of
/// `test/specs/controller.line_test.dart`.
final class _FixtureEvent implements types.ChartEvent {
  _FixtureEvent(this.x, this.y);

  @override
  String get type => 'mousemove';

  @override
  NativeEvent? get native => null;

  @override
  final double? x;

  @override
  final double? y;

  @override
  types.Chart? get chart => null;
}
