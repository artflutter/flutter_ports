// Original code, not ported from Chart.js: the stand-in for the DOM Event.

/// The native event of the Flutter platform (Chart.js ADR 0037): the
/// stand-in for the DOM `Event`, `MouseEvent`, `PointerEvent`, `TouchEvent`
/// and `WheelEvent` that `platform.dom.js` reads.
///
/// `platform.flutter.dart` builds a [NativeEvent] from a Flutter
/// `PointerEvent` and passes it to `fromNativeEvent`, as `platform.dom.js`
/// passes the DOM event (`platform.dom.js:109`). `ChartEvent.native` holds
/// it. Plugins and user callbacks read it as upstream code reads
/// `event.native`.
///
/// This library is a pure layer: it reaches neither `dart:ui` nor
/// `package:flutter`. `NativeEvent.source` keeps the Flutter event as an
/// opaque value.
library;

/// One entry of [NativeEvent.touches]: the DOM `Touch` that
/// `getCanvasPosition` reads (`helpers.dom.ts:81-83`).
///
/// `identifier` is the Flutter pointer id. `x` and `y` are the position of
/// the pointer in the logical pixels of the chart, from its top left corner.
typedef NativeTouch = ({int identifier, double x, double y});

/// The DOM event that `platform.dom.js` passes to `fromNativeEvent`.
///
/// - [type] is the DOM event name that Chrome fires (Chart.js ADR 0037,
///   section 6): a `pointer*` name (`pointerover`, `pointerenter`,
///   `pointerdown`, `pointermove`, `pointerup`, `pointercancel`,
///   `pointerout`, `pointerleave`), a `touch*` name (`touchstart`,
///   `touchmove`, `touchend`, `touchcancel`), a `mouse*` name (`mouseover`,
///   `mouseenter`, `mousemove`, `mousedown`, `mouseup`, `mouseout`,
///   `mouseleave`), `click` or `wheel`. `fromNativeEvent` maps it with
///   `EVENT_TYPES`.
/// - [offsetX] and [offsetY] are the DOM `offsetX` and `offsetY`: the
///   position in the logical pixels of the chart, from its top left corner.
///   A `touch*` event has NaN for both, as the upstream `TouchEvent` has no
///   offset. Its position comes from [touches]. Thus a `touchend` after the
///   last finger lifts has NaN coordinates (`helpers.dom.ts:81-93`).
/// - [touches] stands for the DOM `TouchEvent.touches`, but holds only the
///   touch pointers that went down on the chart host (the DOM
///   `targetTouches`), sorted by pointer id, for a `touch*` event (Chart.js
///   ADR 0037, Open 11). Other events have an empty list.
/// - [target] is the DOM `event.target`: the canvas element.
/// - [source] is the Flutter `PointerEvent` (or `null` in tests).
final class NativeEvent {
  /// Creates a native event of the DOM event name [type].
  NativeEvent({
    required this.type,
    required this.offsetX,
    required this.offsetY,
    this.touches = const [],
    this.target,
    this.source,
  });

  /// The DOM event name, for example `'mousemove'`.
  final String type;

  /// The DOM `offsetX`, in logical pixels. NaN for a `touch*` event.
  final double offsetX;

  /// The DOM `offsetY`, in logical pixels. NaN for a `touch*` event.
  final double offsetY;

  /// The touch pointers that went down on the chart host, sorted by pointer
  /// id (the DOM `targetTouches`). Empty for an event of another device and
  /// for a `touchend` after the last finger lifts.
  final List<NativeTouch> touches;

  /// The DOM `event.target`: the canvas element of the chart.
  final Object? target;

  /// The Flutter event that this event stands for, an opaque value.
  final Object? source;

  @override
  String toString() =>
      'NativeEvent($type, $offsetX, $offsetY, touches: $touches)';
}
