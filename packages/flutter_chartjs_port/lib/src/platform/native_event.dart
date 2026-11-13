// Original code, not ported from Chart.js: the stand-in for the DOM Event.

/// The native event of the Flutter platform (Chart.js ADRs 0037 and 0108):
/// the stand-in for the DOM `Event`, `MouseEvent`, `PointerEvent`,
/// `TouchEvent`, `WheelEvent` and `KeyboardEvent` that `platform.dom.js` and
/// add-on plugins read.
///
/// `platform.flutter.dart` builds a [NativeEvent] from a Flutter
/// `PointerEvent` and passes it to `fromNativeEvent`, as `platform.dom.js`
/// passes the DOM event (`platform.dom.js:109`). `ChartEvent.native` holds
/// it. Plugins and user callbacks read it as upstream code reads
/// `event.native`.
///
/// The library also has the `EventTarget` part that add-on plugins call
/// ([NativeEventTarget], [NativeEventListener]) and the `DOMRect` of
/// `getBoundingClientRect()` ([DOMRect]).
///
/// This library is a pure layer: it reaches neither `dart:ui` nor
/// `package:flutter`. `NativeEvent.source` keeps the Flutter event as an
/// opaque value.
library;

import 'dart:math' as math;

import 'package:meta/meta.dart';

/// One entry of [NativeEvent.touches]: the DOM `Touch` that
/// `getCanvasPosition` reads (`helpers.dom.ts:81-83`).
///
/// `identifier` is the Flutter pointer id. `x` and `y` are the position of
/// the pointer in the logical pixels of the chart, from its top left corner.
typedef NativeTouch = ({int identifier, double x, double y});

/// A DOM event listener: the callback of `addEventListener`.
///
/// Two listeners are the same listener when they are `==`. A tear-off of one
/// method of one object is `==` to another tear-off of that method, so a
/// method tear-off adds and removes as a JS function value does.
typedef NativeEventListener = void Function(NativeEvent event);

/// The part of the DOM `EventTarget` that add-on plugins call (Chart.js ADR
/// 0108). Port-only.
///
/// A canvas element gives itself as a target through
/// `canvas.eventTarget`, and its document through `canvas.ownerDocument`
/// (the extension `CanvasEventTarget` of `chart_host.dart`).
abstract interface class NativeEventTarget() {
  /// `addEventListener(type, listener, {passive})`.
  ///
  /// A listener that the target already has for [type] is not added again:
  /// the first [passive] value stays. A Dart `null` [passive] is the DOM
  /// default: true for `wheel`, `mousewheel`, `touchstart` and `touchmove`
  /// on the document, else false. A passive listener cannot cancel the
  /// event: [NativeEvent.preventDefault] does nothing while it runs.
  void addEventListener(
    String type,
    NativeEventListener listener, {
    bool? passive,
  });

  /// `removeEventListener(type, listener)`.
  void removeEventListener(String type, NativeEventListener listener);

  /// `dispatchEvent(event)`: sets [NativeEvent.target], calls the listeners
  /// of `event.type` in the order of registration, and returns
  /// `!event.defaultPrevented`.
  ///
  /// A listener that a listener adds or removes takes effect with the next
  /// event.
  bool dispatchEvent(NativeEvent event);
}

/// lib.dom.d.ts `DOMRect`: the result of `getBoundingClientRect()`, in the
/// logical pixels of the view. Port-only.
///
/// As in the DOM, [width] and [height] can be negative. [left], [top],
/// [right] and [bottom] then give the normalized edges.
@immutable
final class const DOMRect(
  /// `x`: the origin on the x axis.
  final double x,

  /// `y`: the origin on the y axis.
  final double y,

  /// `width`. It can be negative.
  final double width,

  /// `height`. It can be negative.
  final double height,
) {
  /// `new DOMRect(x, y, width, height)`.
  this;

  /// The rectangle of an element outside the document: all zeros.
  static const DOMRect zero = DOMRect(0, 0, 0, 0);

  /// `left`: `min(x, x + width)`.
  double get left => math.min(x, x + width);

  /// `top`: `min(y, y + height)`.
  double get top => math.min(y, y + height);

  /// `right`: `max(x, x + width)`.
  double get right => math.max(x, x + width);

  /// `bottom`: `max(y, y + height)`.
  double get bottom => math.max(y, y + height);

  @override
  bool operator ==(Object other) =>
      other is DOMRect &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() => 'DOMRect($x, $y, $width, $height)';
}

/// The DOM event that `platform.dom.js` passes to `fromNativeEvent`, and that
/// the host gives to the listeners of a canvas and of its document.
///
/// One class stands for each DOM event interface: a listener has one type,
/// [NativeEventListener], for each event name, as the DOM registry keys the
/// listeners by a string. A field that the DOM interface of an event does
/// not have keeps its init default.
///
/// - [type] is the DOM event name that Chrome fires (Chart.js ADR 0037,
///   section 6): a `pointer*` name (`pointerover`, `pointerenter`,
///   `pointerdown`, `pointermove`, `pointerup`, `pointercancel`,
///   `pointerout`, `pointerleave`), a `touch*` name (`touchstart`,
///   `touchmove`, `touchend`, `touchcancel`), a `mouse*` name (`mouseover`,
///   `mouseenter`, `mousemove`, `mousedown`, `mouseup`, `mouseout`,
///   `mouseleave`), `click` or `wheel`. The keyboard of `ChartView` and the
///   document also give `keydown`, `keypress` and `keyup` (Chart.js ADRs
///   0051 and 0108). `fromNativeEvent` maps it with `EVENT_TYPES`.
/// - [offsetX] and [offsetY] are the DOM `offsetX` and `offsetY`: the
///   position in the logical pixels of the chart, from its top left corner.
///   A `touch*` event has NaN for both, as the upstream `TouchEvent` has no
///   offset. Its position comes from [touches]. Thus a `touchend` after the
///   last finger lifts has NaN coordinates (`helpers.dom.ts:81-93`). A key
///   event has NaN for both, as the upstream `KeyboardEvent` gives a NaN
///   position (`helpers.dom.ts:65-95`).
/// - [clientX] and [clientY] are the DOM `clientX` and `clientY`: the
///   position in the logical pixels of the view (Chart.js ADR 0108).
/// - [touches] stands for the DOM `TouchEvent.touches`, but holds only the
///   touch pointers that went down on the chart host (the DOM
///   `targetTouches`), sorted by pointer id, for a `touch*` event (Chart.js
///   ADR 0037, Open 11). Other events have an empty list.
/// - [target] is the DOM `event.target`: the canvas element, or the
///   document of `canvas.ownerDocument`. A dispatch sets it.
/// - [source] is the Flutter `PointerEvent`, the Flutter `KeyEvent` of a key,
///   or `null` (in tests, and for the `mouseout` of a focus loss).
final class NativeEvent({
  /// The DOM event name, for example `'mousemove'`.
  required final String type,

  /// The DOM `offsetX`, in logical pixels. NaN for a `touch*` event and for
  /// a key event.
  required final double offsetX,

  /// The DOM `offsetY`, in logical pixels. NaN for a `touch*` event and for
  /// a key event.
  required final double offsetY,

  /// The touch pointers that went down on the chart host, sorted by pointer
  /// id (the DOM `targetTouches`). Empty for an event of another device and
  /// for a `touchend` after the last finger lifts.
  final List<NativeTouch> touches = const [],
  var Object? _target,

  /// The Flutter event that this event stands for, an opaque value.
  final Object? source,

  /// `bubbles`: whether a dispatch on a canvas also calls the listeners of
  /// its document. The DOM default is false.
  final bool bubbles = false,

  /// `cancelable`: whether [preventDefault] sets [defaultPrevented]. The DOM
  /// default is false.
  final bool cancelable = false,

  /// `clientX`: the position on the x axis in the logical pixels of the
  /// view. NaN for a `touch*` event and for a key event of the host.
  final double clientX = 0,

  /// `clientY`: the position on the y axis in the logical pixels of the
  /// view. NaN for a `touch*` event and for a key event of the host.
  final double clientY = 0,

  /// `MouseEvent.button`: the button that changed. 0 is the main button, 1
  /// the auxiliary (middle) button, 2 the secondary button, 3 back and 4
  /// forward. A `pointer*` event with no change of the buttons has -1.
  final int button = 0,

  /// `MouseEvent.buttons`: the bit set of the pressed buttons. 1 is the main
  /// button or the contact of a touch or a pen, 2 the secondary button or
  /// the pen barrel, 4 the auxiliary button, 8 back, 16 forward and 32 the
  /// eraser.
  final int buttons = 0,

  /// `PointerEvent.pointerId`. 1 is the mouse. 0 for an event that is not a
  /// `PointerEvent`.
  final int pointerId = 0,

  /// `PointerEvent.pointerType`: `'mouse'`, `'pen'`, `'touch'`, or `''`.
  final String pointerType = '',

  /// `WheelEvent.deltaX`, in [deltaMode] units.
  final double deltaX = 0,

  /// `WheelEvent.deltaY`, in [deltaMode] units. Positive scrolls down.
  final double deltaY = 0,

  /// `WheelEvent.deltaMode`: 0 is pixels, 1 lines, 2 pages.
  final int deltaMode = 0,

  /// `KeyboardEvent.key`: the UI Events key value, for example `'Escape'`,
  /// `'ArrowLeft'` or `'a'`.
  final String key = '',

  /// `ctrlKey`: whether a Control key was down.
  final bool ctrlKey = false,

  /// `altKey`: whether an Alt key was down.
  final bool altKey = false,

  /// `shiftKey`: whether a Shift key was down.
  final bool shiftKey = false,

  /// `metaKey`: whether a Meta key was down.
  final bool metaKey = false,
}) {
  /// Creates a native event of the DOM event name [type].
  ///
  /// Each optional field has the default of its DOM init dictionary
  /// (`EventInit`, `MouseEventInit`, `PointerEventInit`, `WheelEventInit`,
  /// `KeyboardEventInit`). [target] serves an event that a caller passes to
  /// a listener directly: a dispatch replaces it.
  this;

  /// The DOM `event.target`: the canvas element of the chart, or the
  /// document of `canvas.ownerDocument`. A dispatch sets it. Before a
  /// dispatch, it is the value of the constructor.
  Object? get target => _target;

  /// `defaultPrevented`: whether a listener canceled the event.
  bool get defaultPrevented => _canceled;
  bool _canceled = false;

  /// Whether a passive listener runs.
  bool _inPassiveListener = false;

  /// Whether a listener stopped the propagation.
  bool _stopped = false;

  /// `preventDefault()`: sets [defaultPrevented] when the event is
  /// [cancelable]. In a passive listener, it does nothing.
  void preventDefault() {
    if (cancelable && !_inPassiveListener) {
      _canceled = true;
    }
  }

  /// `stopPropagation()`: the dispatch ends after the listeners of the
  /// current target. A bubbling event of a canvas then does not reach the
  /// document.
  void stopPropagation() {
    _stopped = true;
  }

  @override
  String toString() =>
      'NativeEvent($type, $offsetX, $offsetY, '
      'client: ($clientX, $clientY), touches: $touches)';
}

/// Calls [listener] with [event] as a listener with the `passive` flag
/// [passive]: [NativeEvent.preventDefault] does nothing while a passive
/// listener runs. The dispatch of a target calls it.
@internal
void invokeNativeEventListener(
  NativeEventListener listener,
  NativeEvent event, {
  required bool passive,
}) {
  final outer = event._inPassiveListener;
  event._inPassiveListener = passive;
  try {
    listener(event);
  } finally {
    event._inPassiveListener = outer;
  }
}

/// Starts the dispatch of [event] on [target]: sets [NativeEvent.target]
/// and clears the stop flag of an earlier dispatch, as the DOM clears it at
/// the end of each dispatch.
@internal
void setNativeEventTarget(NativeEvent event, Object? target) {
  event
    .._target = target
    .._stopped = false;
}

/// Whether a listener called [NativeEvent.stopPropagation] in the current
/// dispatch of [event].
@internal
bool nativeEventStopped(NativeEvent event) => event._stopped;
