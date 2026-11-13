// Original code, not ported from Chart.js: a recording context over a real one.

/// A recording context that a chart can draw on (Chart.js ADR 0133).
///
/// This library is a pure layer, as `context.dart` is.
library;

import 'package:chartjs_test_utils/src/context.dart';
import 'package:flutter/painting.dart' show TextStyle;
// flutter_chartjs_port does not export lib/src.
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';

/// A [MockContext] that records each call and forwards the text state to
/// the real context [target]: `font`, `save`, `restore`, `measureText`,
/// `canvas` and `resetTransform`.
///
/// The mock context alone has no `canvas` and no `resetTransform`, which
/// `chart.draw()` reads, and it measures each text as 10 pixels for each
/// character. This context measures in the font of the real canvas, as the
/// layout of the chart did. It draws nothing on [target].
///
/// It is the Dart form of a spy that calls through, for example
/// `vi.spyOn(chart.ctx, 'fillRect')`:
///
/// ```dart
/// final target = chart.ctx!;
/// final recording = RecordingContext(target);
/// chart.ctx = recording;
/// chart.draw();
/// chart.ctx = target;
/// final rects = recording.getCalls().where((c) => c['name'] == 'fillRect');
/// ```
class RecordingContext(
  /// The real context: the context of the chart.
  final CanvasRenderingContext2D target,
) extends MockContext {
  /// A recording context over [target].
  this;

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
    return target.measureText(text);
  }

  @override
  void resetTransform() {
    record('resetTransform', const []);
    target.resetTransform();
  }
}
