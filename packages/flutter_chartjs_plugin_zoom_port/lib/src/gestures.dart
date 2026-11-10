// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/gestures.ts (MIT, chartjs-plugin-zoom contributors).

/// The pointer gestures of the plugin: the pan of one pointer and the pinch
/// of two pointers, from the DOM pointer events of the canvas.
///
/// This file has only the public types of the gestures so far:
/// [GestureEvent] and [ActivePointer]. The gesture manager comes with the
/// port of the input modules (zoom phase 3).
library;

import 'package:flutter_chartjs_plugin_zoom_port/src/types.dart';
import 'package:flutter_chartjs_port/chartjs.dart'
    show HTMLCanvasElement, NativeEvent;

/// gestures.ts:25 `{ clientX: number; clientY: number }`: an active pointer
/// in client coordinates, the logical pixels of the view.
typedef ActivePointer = ({double clientX, double clientY});

/// gestures.ts:13 `GestureEvent`: the normalized gesture event of the pan
/// and pinch callbacks (`onPanStart`, `onPanRejected`).
///
/// It replaces the former Hammer.js event object. It carries only the fields
/// that the plugin reads, all from the native pointer events.
final class GestureEvent {
  /// A gesture event with its fields.
  const GestureEvent({
    required this.center,
    required this.deltaX,
    required this.deltaY,
    required this.distance,
    required this.scale,
    required this.pointers,
    required this.target,
    required this.srcEvent,
    required this.pointerType,
  });

  /// gestures.ts:15 `center`: the gesture centroid in client coordinates,
  /// the midpoint of the active pointers.
  final Point center;

  /// gestures.ts:17 `deltaX`: the cumulative horizontal pan offset in pixels
  /// since the gesture started.
  final double deltaX;

  /// gestures.ts:18 `deltaY`: the cumulative vertical pan offset in pixels
  /// since the gesture started.
  final double deltaY;

  /// gestures.ts:20 `distance`: the straight-line distance in pixels that
  /// the gesture has travelled since it started.
  final double distance;

  /// gestures.ts:22 `scale`: the cumulative pinch scale relative to the
  /// gesture start (1 = unchanged).
  final double scale;

  /// gestures.ts:24 `pointers`: the active pointers, in client coordinates.
  final List<ActivePointer> pointers;

  /// gestures.ts:26 `target`: the canvas that the gesture is bound to.
  final HTMLCanvasElement target;

  /// gestures.ts:28 `srcEvent`: the native pointer event that produced this
  /// gesture event.
  final NativeEvent srcEvent;

  /// gestures.ts:30 `pointerType`: the pointer device type, `mouse`, `touch`
  /// or `pen`.
  final String pointerType;
}
