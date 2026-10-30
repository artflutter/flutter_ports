// Original code, not ported from Chart.js: the keyboard of ChartView.

/// The keyboard of `ChartView` (Chart.js ADR 0051, sections 2 to 7).
///
/// The widget builds one `Focus` around its host. Its `onKeyEvent` and
/// `onFocusChange` call [ChartKeyboard]. The keys move a virtual mouse: each
/// move sends a `mousemove` `NativeEvent` at the target point through
/// `dispatchCanvasEvent`, where `triggerMouseEvent` of the test harness
/// enters the ported input path (section 4). Thus `options.events`, the
/// modes, the callbacks and the replay of `_lastEvent` give the result of a
/// mouse at that point. The keyboard has no hit test and no mode logic. It
/// changes no ported file.
///
/// Not a pure layer: the file imports Flutter. It imports no plugin: it
/// reads the legend hit boxes through `types.LegendElement` (Chart.js ADR
/// 0048, section 3).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_webidl.dart' show canvasStyle;
import 'package:flutter_chartjs_port/src/platform/chart_host.dart'
    show dispatchCanvasEvent, hasCanvasEventListener;
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// The group of the legend targets. A data group has its dataset index.
const int _legendGroup = -1;

/// A target point, in the logical pixels of the chart.
typedef _Point = ({double x, double y});

/// A rectangle of the focus ring.
typedef _Rect = ({double left, double top, double width, double height});

/// The number value of a hit box key, else NaN.
double _num(Object? value) => value is num ? value.toDouble() : double.nan;

/// The keyboard state of the chart of one `ChartView` (Chart.js ADR 0051,
/// sections 2 to 6): the target, the virtual mouse, the key events of
/// `options.events` and the focus ring.
@internal
final class ChartKeyboard {
  /// The keyboard of the canvas `canvas`. `chart` gives the current chart
  /// of the widget, or Dart `null` before the start and after the dispose.
  ChartKeyboard({required this._canvas, required this._chart}) {
    FocusManager.instance.addHighlightModeListener(_onHighlightModeChanged);
  }

  /// The canvas of the chart: the target of the events.
  final HTMLCanvasElement _canvas;

  /// The current chart of the widget.
  final Chart? Function() _chart;

  /// The group of the target: [_legendGroup] or a dataset index. Dart
  /// `null`: no target.
  int? _group;

  /// The index of the target in its group.
  int _item = 0;

  /// Whether the chart has the focus.
  bool _focused = false;

  /// Whether the ring shows: the chart has the focus, and the highlight
  /// mode is traditional (section 6).
  bool get _ringVisible =>
      _focused &&
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  /// The `Focus.onKeyEvent` handler: the key events of `options.events`
  /// (section 5), then the table of section 3.
  KeyEventResult onKeyEvent(FocusNode node, KeyEvent event) {
    _sendKeyEvent(event);
    final chart = _chart();
    if (chart == null || event is KeyUpEvent || _modified()) {
      return KeyEventResult.ignored;
    }
    final ringBefore = _ringRect(chart);
    final result = _act(chart, event);
    if (_ringVisible && _ringRect(chart) != ringBefore) chart.render();
    return result;
  }

  /// The `Focus.onFocusChange` handler: a focus loss sends `mouseout` at the
  /// target and clears it. Each change calls `chart.render()` (section 6).
  // The signature of `Focus.onFocusChange`.
  // ignore: avoid_positional_boolean_parameters
  void onFocusChange(bool focused) {
    _focused = focused;
    final chart = _chart();
    if (chart == null) {
      _group = null;
      return;
    }
    if (!focused) {
      final point = _targetPoint(chart);
      _group = null;
      if (point != null) _dispatch('mouseout', point, null);
    }
    chart.render();
  }

  /// The ring of section 6, from the `afterDraw` hook of the widget plugin:
  /// a 2 px `strokeRect` 2 px outside the hit box of a legend target, or
  /// 1 px inside the canvas box with no target, in the resolved
  /// `chart.options.color`. A data target has no ring.
  void paintRing(types.Chart chart) {
    if (!_ringVisible) return;
    final ctx = chart.ctx;
    final rect = _ringRect(chart);
    if (ctx == null || rect == null) return;
    ctx
      ..save()
      ..strokeStyle = canvasStyle(chart.options['color'])
      ..lineWidth = 2
      ..setLineDash(const <double>[])
      ..strokeRect(rect.left, rect.top, rect.width, rect.height)
      ..restore();
  }

  /// Clears the target with no event: a new chart.
  void reset() => _group = null;

  /// Removes the highlight mode listener.
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightModeChanged);
  }

  /// A change of the highlight mode changes the ring (section 6).
  void _onHighlightModeChanged(FocusHighlightMode mode) {
    if (_focused) _chart()?.render();
  }

  /// Whether a modifier key is down. The table of section 3 has no key with
  /// a modifier: such a key goes on to the ancestors, for example a
  /// shortcut of the app or of the browser.
  static bool _modified() {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isShiftPressed ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed;
  }

  /// The table of section 3 for a `KeyDownEvent` or a `KeyRepeatEvent`.
  KeyEventResult _act(Chart chart, KeyEvent event) {
    // The current target. A group that is gone clears it.
    final group = _group;
    final points = group == null ? null : _points(chart, group);
    if (points == null || points.isEmpty) {
      _group = null;
    } else {
      _item = math.min(_item, points.length - 1);
    }
    final hasTarget = _group != null;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        if (!hasTarget) return _moveToFirst(chart, event);
        return _moveTo(group!, _item + 1, points!, event);
      case LogicalKeyboardKey.arrowLeft:
        if (!hasTarget) return KeyEventResult.ignored;
        return _moveTo(group!, _item - 1, points!, event);
      case LogicalKeyboardKey.arrowDown:
        if (!hasTarget) return _moveToFirst(chart, event);
        return _moveToGroup(chart, group!, 1, event);
      case LogicalKeyboardKey.arrowUp:
        if (!hasTarget) return KeyEventResult.ignored;
        return _moveToGroup(chart, group!, -1, event);
      case LogicalKeyboardKey.home:
        if (!hasTarget) return KeyEventResult.ignored;
        return _moveTo(group!, 0, points!, event);
      case LogicalKeyboardKey.end:
        if (!hasTarget) return KeyEventResult.ignored;
        return _moveTo(group!, points!.length - 1, points, event);
      case LogicalKeyboardKey.enter ||
          LogicalKeyboardKey.numpadEnter ||
          LogicalKeyboardKey.space:
        if (!hasTarget) return KeyEventResult.ignored;
        // A repeat gives no second click.
        if (event is KeyDownEvent) {
          final point = points![_item];
          _dispatch('mousedown', point, event);
          _dispatch('mouseup', point, event);
          _dispatch('click', point, event);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        if (!hasTarget) return KeyEventResult.ignored;
        if (event is KeyDownEvent) {
          _group = null;
          _dispatch('mouseout', points![_item], event);
        }
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Moves to the first target of the first group with a target.
  KeyEventResult _moveToFirst(Chart chart, KeyEvent event) {
    for (final group in _groups(chart)) {
      final points = _points(chart, group);
      if (points != null && points.isNotEmpty) {
        return _moveTo(group, 0, points, event);
      }
    }
    return KeyEventResult.ignored;
  }

  /// Moves to the same index in the next group with a target in the
  /// direction [step], or to its last target when the group is shorter.
  KeyEventResult _moveToGroup(
    Chart chart,
    int group,
    int step,
    KeyEvent event,
  ) {
    final groups = _groups(chart);
    for (
      var i = groups.indexOf(group) + step;
      i >= 0 && i < groups.length;
      i += step
    ) {
      final points = _points(chart, groups[i]);
      if (points != null && points.isNotEmpty) {
        return _moveTo(
          groups[i],
          math.min(_item, points.length - 1),
          points,
          event,
        );
      }
    }
    return KeyEventResult.ignored;
  }

  /// Moves the virtual mouse to the target [item] of [group], whose target
  /// points are [points]: a `mousemove` at its point (section 4). An index
  /// outside the group gives `ignored`. The current target gives no event.
  KeyEventResult _moveTo(
    int group,
    int item,
    List<_Point> points,
    KeyEvent event,
  ) {
    if (item < 0 || item >= points.length) return KeyEventResult.ignored;
    if (group == _group && item == _item) return KeyEventResult.handled;
    _group = group;
    _item = item;
    _dispatch('mousemove', points[item], event);
    return KeyEventResult.handled;
  }

  /// The groups of section 2: the legend group when the legend shows hit
  /// boxes, then each visible dataset in index order.
  static List<int> _groups(Chart chart) {
    final datasets = chart.data['datasets'];
    final count = datasets is List ? datasets.length : 0;
    return [
      if (_legendBoxes(chart) != null) _legendGroup,
      for (var i = 0; i < count; i++)
        if (chart.isDatasetVisible(i.toDouble())) i,
    ];
  }

  /// The target points of [group], or Dart `null` when the group is gone.
  ///
  /// A legend target is the center of a hit box. A data target is the final
  /// center (`getCenterPoint(true)`) of an element with a finite center and
  /// a visible data index.
  static List<_Point>? _points(Chart chart, int group) {
    if (group == _legendGroup) {
      final boxes = _legendBoxes(chart);
      if (boxes == null) return null;
      return [
        for (final box in boxes)
          (
            x: _num(box['left']) + _num(box['width']) / 2,
            y: _num(box['top']) + _num(box['height']) / 2,
          ),
      ];
    }
    final datasets = chart.data['datasets'];
    if (datasets is! List ||
        group >= datasets.length ||
        !chart.isDatasetVisible(group.toDouble())) {
      return null;
    }
    final elements = chart.getDatasetMeta(group.toDouble()).data;
    final points = <_Point>[];
    for (var j = 0; j < elements.length; j++) {
      if (elements[j] case final types.VisualElement element
          when chart.getDataVisibility(j.toDouble())) {
        final center = element.getCenterPoint(true);
        final x = center.x;
        final y = center.y;
        if (x != null && y != null && x.isFinite && y.isFinite) {
          points.add((x: x, y: y));
        }
      }
    }
    return points;
  }

  /// The hit boxes of the legend (plugin.legend.js:52), or Dart `null`
  /// when the chart has no legend, the legend does not show, or it has no
  /// hit box. A hidden legend keeps the hit boxes of its last fit.
  static List<AnyObject>? _legendBoxes(types.Chart chart) {
    final legend = chart.legend;
    if (legend == null || !jsTruthy(jsGet(legend.options, 'display'))) {
      return null;
    }
    final boxes = legend.legendHitBoxes;
    return boxes.isEmpty ? null : boxes;
  }

  /// The point of the target, or Dart `null` with no target.
  _Point? _targetPoint(Chart chart) {
    final group = _group;
    if (group == null) return null;
    final points = _points(chart, group);
    if (points == null || points.isEmpty) return null;
    return points[math.min(_item, points.length - 1)];
  }

  /// The ring rectangle of section 6, or Dart `null` for no ring.
  _Rect? _ringRect(types.Chart chart) {
    final group = _group;
    if (group == null) {
      return (
        left: 1,
        top: 1,
        width: chart.width - 2,
        height: chart.height - 2,
      );
    }
    if (group != _legendGroup) return null;
    final boxes = _legendBoxes(chart);
    if (boxes == null) return null;
    final box = boxes[math.min(_item, boxes.length - 1)];
    return (
      left: _num(box['left']) - 3,
      top: _num(box['top']) - 3,
      width: _num(box['width']) + 6,
      height: _num(box['height']) + 6,
    );
  }

  /// Sends the mouse event [type] at [point], with the key event [source],
  /// to the canvas listeners (section 4).
  void _dispatch(String type, _Point point, KeyEvent? source) =>
      dispatchCanvasEvent(
        _canvas,
        NativeEvent(
          type: type,
          offsetX: point.x,
          offsetY: point.y,
          target: _canvas,
          source: source,
        ),
      );

  /// The key events of `options.events` (section 5): `keydown`, and then
  /// `keypress` for an event with a character, or `keyup`.
  void _sendKeyEvent(KeyEvent event) {
    if (event is KeyUpEvent) {
      _sendKey('keyup', event);
      return;
    }
    _sendKey('keydown', event);
    if (event.character != null) _sendKey('keypress', event);
  }

  /// Sends the key event [type] with NaN offsets, only when the canvas has
  /// a listener for it: when `options.events` lists it.
  void _sendKey(String type, KeyEvent event) {
    if (!hasCanvasEventListener(_canvas, type)) return;
    dispatchCanvasEvent(
      _canvas,
      NativeEvent(
        type: type,
        offsetX: double.nan,
        offsetY: double.nan,
        target: _canvas,
        source: event,
      ),
    );
  }
}
