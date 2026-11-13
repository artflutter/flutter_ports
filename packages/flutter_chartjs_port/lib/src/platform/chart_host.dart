// Original code, not ported from Chart.js: the internal chart host.

/// The internal chart host (Chart.js ADR 0037, porting-flow.md 2.7): the
/// render object that shows a canvas element of the canvas layer, and the
/// DOM parts of `platform.dom.js` that the host stands in for.
///
/// - [ChartHost] is a `LeafRenderObjectWidget`, and [RenderChartHost] its
///   `RenderBox`. The library is not exported. The public widget `ChartView`
///   builds on it: it starts its chart in [ChartHost.onFirstLayout]
///   (Chart.js ADR 0049, section 2).
/// - The host is the parent node of its canvas (`CanvasNode.parentNode`)
///   and its container ([CanvasContainer]): the container size is the max
///   size of its incoming constraints.
/// - The event listeners of a canvas ([addCanvasEventListener], and the
///   extension [CanvasEventTarget] for add-on plugins) stand in for the
///   `EventTarget` of the DOM canvas. The host makes [NativeEvent]s from
///   Flutter pointer events and sends them to these listeners. A bubbling
///   event then reaches the listeners of the one document of the isolate
///   ([CanvasDocument], `canvas.ownerDocument`, Chart.js ADR 0108).
/// - [CanvasMutationObserver] stands in for the `MutationObserver` of
///   `createAttachObserver` and `createDetachObserver`, and
///   [ContainerResizeObserver] for the `ResizeObserver` of
///   `createResizeObserver` and the window `resize` listener.
///
/// Sizing (Chart.js ADR 0037, sections 2 to 5):
/// - The first layout of the host reports the attach at once. Thus the
///   chart takes its size from the container before the first paint, as
///   upstream sizes a chart at construction (`core.controller.tests.js:651`).
///   A canvas swap reports the detach of the old canvas during the build.
///   Later attach and detach changes go through one post-frame callback,
///   which reports only a net change (Chart.js ADR 0016, decision 9). The
///   test harness reports them earlier, at its mutation checkpoint
///   ([flushCanvasMutations], Chart.js ADR 0022).
/// - A [ContainerResizeObserver] that starts on a laid-out host gets its
///   first notification at the next layout of the host, as a DOM
///   `ResizeObserver` gets it at the next rendering step (Chart.js ADR
///   0022).
/// - A later change of the constraints or of the device pixel ratio reaches
///   the [ContainerResizeObserver]s. `createResizeObserver` throttles them
///   to one resize in the next frame, as upstream.
/// - The size of the host is the display size of the canvas, constrained to
///   the incoming constraints: its `width` and `height` styles when both are
///   pixel values, as `retinaScale` writes them, else its render size.
///   Paint maps the bitmap to the display size with one scale, as the DOM
///   stretches a canvas bitmap to its CSS size, and clips a larger canvas to
///   the host box.
/// - Unbounded constraints give an infinite container side. Then
///   `FlutterPlatform.getMaximumSize` gives the chart a size.
///
/// A new host can take over the canvas of an old host in one frame: a
/// wrapper widget is toggled, the host moves to another slot without a
/// `GlobalKey`, or an `AnimatedSwitcher` swaps it. The new host then takes
/// over the reported attached state and the [ContainerResizeObserver]s of
/// the old host. Thus the chart stays attached and follows the new
/// container. An old host that no longer shows the canvas reports nothing.
///
/// Input (Chart.js ADR 0037, sections 6 to 11): `hitTestSelf` is true.
/// [RenderChartHost] reads raw pointer events in `handleEvent` and maps them
/// to the DOM event names of Chrome by `PointerDeviceKind`: mouse and
/// trackpad are mouse-like, all other kinds in contact are touch-like, as
/// in Chrome on Android (device check P4, row ST1). With the default
/// `touch-action` of the canvas, it claims nothing in the gesture arena.
/// Thus parent scrollables keep their drags, and tappable ancestors keep
/// their taps, as a DOM click also reaches them by bubbling. A canvas with
/// `touch-action: none` and a prevented `wheel` change this (Chart.js ADR
/// 0108, below).
/// - The click rule (section 7): a mouse-like down with the primary button
///   on the host, then the up of that pointer inside the box, gives `click`
///   after `mouseup`. The distance between the down and the up has no limit.
/// - The touch sequence (section 8, the Chromium rules of P4): a move with
///   no change of the point gives no event. The tap candidate gives only
///   `pointermove` inside its slop limit. The first move past a slop limit
///   begins the pan: `pointercancel`, `pointerout` and `pointerleave` at the
///   view origin for each touch-like pointer, then only `touch*` events
///   until all touch-like pointers of the host lift. A sequence with
///   `touch-action: none` has no pan (below).
/// - The tap rule (section 8): one touch-like pointer on the host, no pan, no
///   cancel, and the up before `kLongPressTimeout`. A tap gives `mouseover` and
///   `mouseenter` (when the compatibility mouse is not over the host),
///   `mousemove`, `mousedown`, `mouseup` and `click` at its tap point: the down
///   position, the up position for a stylus and an inverted stylus (P4 STN10).
///   A pointer held past `kLongPressTimeout` gives `mouseover`, `mouseenter`
///   and `mousemove` at the down position, and no `click`.
/// - The compatibility mouse (section 9): one for each isolate, as a browser
///   has one. A tap or a long press on a host makes that host the owner.
///   While an owner exists, one global pointer route watches the touch-like
///   pointers of the app. A tap or a long press that does not hit a host
///   gives the owner `mouseout` and `mouseleave`. Then the owner ends, and
///   the route goes. The detach or the dispose of the owner ends it.
///
/// A mouse has no implicit capture: a mouse move, up or cancel outside the
/// box gives the canvas no event. The host tracks the hover of the kinds
/// other than the mouse itself and gives their enter and exit events.
///
/// The document and the event fields (Chart.js ADR 0108):
/// - A mouse-like pointer that went down on the host gives the document its
///   `pointermove` and `mousemove`, its `pointerup` and `mouseup`, the
///   `click` of the click rule and its `pointercancel` while it is outside
///   the box, with the document as the target. A detach, a dispose or a
///   canvas swap ends it.
/// - Each event has the fields of the DOM event that Chrome gives: the
///   client point (`PointerEvent.position`), `button`, `buttons`,
///   `pointerId` (the mouse 1, a touch-like pointer an id from 2),
///   `pointerType`, the wheel deltas, the modifier keys of
///   `HardwareKeyboard`, `bubbles` and `cancelable`.
/// - `canvas.getBoundingClientRect()` gives the box of the canvas in the
///   logical pixels of the view ([RenderChartHost.boundingClientRect]).
///
/// `touch-action` and the wheel (Chart.js ADR 0108):
/// - The host reads the `touch-action` of the inline style of the canvas at
///   the first touch-like down of a sequence, as Chrome fixes the touch
///   action at the start of a touch. A change in a sequence acts at the next
///   one. With `none`, no move begins the pan: no `pointercancel`, and the
///   `pointer*` and `touch*` events go on. The tap candidate ends at its
///   first move past its slop limit. The host adds each touch-like pointer
///   of the sequence to the gesture arena. It accepts the arena of a pointer
///   at its first move farther than the hit slop (`computeHitSlop`) from its
///   down, and the arenas of all its pointers at a second touch-like down.
///   Thus a parent scrollable, a `PageView` and an `InteractiveViewer` do
///   not pan or zoom, as the browser does not pan or zoom the canvas. It
///   gives up the arena of a pointer that it did not accept at its up or
///   its cancel. Thus a tappable ancestor still gets a tap. Each other value
///   keeps the rules of Chart.js ADR 0037.
/// - A `wheel` whose dispatch gives false (a listener prevented its
///   default) takes the pointer signal: the host registers with the
///   `pointerSignalResolver` before any ancestor, and responds with
///   `allowPlatformDefault: false`. Thus no parent scrollable scrolls, and
///   on the web the page does not scroll. An unprevented `wheel` changes
///   nothing.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/platform/native_event.dart';

// The EventTarget of the canvas.

/// One entry of a listener list: the listener and its `passive` flag.
typedef _Listener = ({NativeEventListener listener, bool passive});

/// The listeners of each canvas, by DOM event type: the `EventTarget` part of
/// the DOM canvas element.
final Expando<Map<String, List<_Listener>>> _eventListeners = Expando(
  'canvas event listeners',
);

/// Adds [listener] to the list of [type] in [byType], once, as the DOM
/// `addEventListener` does.
void _addListener(
  Map<String, List<_Listener>> byType,
  String type,
  NativeEventListener listener, {
  required bool passive,
}) {
  final listeners = byType.putIfAbsent(type, () => []);
  for (final entry in listeners) {
    if (entry.listener == listener) {
      return;
    }
  }
  listeners.add((listener: listener, passive: passive));
}

/// Removes [listener] from the list of [type] in [byType], as the DOM
/// `removeEventListener` does. Gives whether a listener went.
bool _removeListener(
  Map<String, List<_Listener>>? byType,
  String type,
  NativeEventListener listener,
) {
  final listeners = byType?[type];
  if (listeners == null) {
    return false;
  }
  final index = listeners.indexWhere((entry) => entry.listener == listener);
  if (index < 0) {
    return false;
  }
  listeners.removeAt(index);
  if (listeners.isEmpty) {
    byType!.remove(type);
  }
  return true;
}

/// Calls the [listeners] with [event], in the order of registration. A
/// listener that a listener adds or removes takes effect with the next
/// event: the calls run on a copy.
void _invokeListeners(List<_Listener>? listeners, NativeEvent event) {
  if (listeners == null) {
    return;
  }
  for (final entry in List.of(listeners)) {
    invokeNativeEventListener(entry.listener, event, passive: entry.passive);
  }
}

/// `canvas.addEventListener(type, listener, {passive})`.
///
/// As in the DOM, a listener that the canvas already has for [type] is not
/// added again, and the first [passive] value stays. The listeners stay on
/// the canvas when no host shows it.
void addCanvasEventListener(
  HTMLCanvasElement canvas,
  String type,
  NativeEventListener listener, {
  bool passive = false,
}) {
  _addListener(
    _eventListeners[canvas] ??= {},
    type,
    listener,
    passive: passive,
  );
}

/// `canvas.removeEventListener(type, listener)`.
void removeCanvasEventListener(
  HTMLCanvasElement canvas,
  String type,
  NativeEventListener listener,
) {
  _removeListener(_eventListeners[canvas], type, listener);
}

/// Whether [canvas] has a listener for [type].
bool hasCanvasEventListener(HTMLCanvasElement canvas, String type) =>
    _eventListeners[canvas]?.containsKey(type) ?? false;

/// The `passive` flag of the [listener] of [type] on [canvas], or Dart
/// `null` when the canvas does not have that listener.
@visibleForTesting
bool? debugCanvasEventListenerPassive(
  HTMLCanvasElement canvas,
  String type,
  NativeEventListener listener,
) {
  for (final entry in _eventListeners[canvas]?[type] ?? const <_Listener>[]) {
    if (entry.listener == listener) {
      return entry.passive;
    }
  }
  return null;
}

/// `canvas.dispatchEvent(event)` (Chart.js ADR 0108): sets the target of
/// [event] to [canvas] and calls the canvas listeners of `event.type` in
/// the order of registration. Then, for a bubbling event that no listener
/// stopped, it calls the listeners of the document
/// ([CanvasDocument.instance]), with the canvas as the target: the bubble
/// phase of the DOM. Gives `!event.defaultPrevented`.
///
/// A listener that a listener adds or removes takes effect with the next
/// event of its target. Thus a document listener that a canvas listener adds
/// gets the bubble phase of the same event, as in the DOM.
bool dispatchCanvasEvent(HTMLCanvasElement canvas, NativeEvent event) {
  setNativeEventTarget(event, canvas);
  _invokeListeners(_eventListeners[canvas]?[event.type], event);
  if (event.bubbles && !nativeEventStopped(event)) {
    CanvasDocument.instance._invoke(event);
  }
  return !event.defaultPrevented;
}

/// The DOM members of a canvas element that the host gives (Chart.js ADR
/// 0108). Port-only.
///
/// They are extension members, so that each [HTMLCanvasElement] has them,
/// also a fake canvas of a test. The upstream lines of an add-on plugin keep
/// their form: `canvas.addEventListener('wheel', listener, passive: false)`,
/// `canvas.getBoundingClientRect()`, `canvas.ownerDocument`.
extension CanvasEventTarget on HTMLCanvasElement {
  /// `addEventListener(type, listener, {passive})`. A Dart `null`
  /// [passive] is the DOM default of an element: false.
  void addEventListener(
    String type,
    NativeEventListener listener, {
    bool? passive,
  }) => addCanvasEventListener(this, type, listener, passive: passive ?? false);

  /// `removeEventListener(type, listener)`.
  void removeEventListener(String type, NativeEventListener listener) =>
      removeCanvasEventListener(this, type, listener);

  /// `dispatchEvent(event)`: the canvas listeners, then the document
  /// listeners for a bubbling event. Gives `!event.defaultPrevented`.
  bool dispatchEvent(NativeEvent event) => dispatchCanvasEvent(this, event);

  /// `ownerDocument`: the one document of the isolate (Chart.js ADR 0108).
  NativeEventTarget get ownerDocument => CanvasDocument.instance;

  /// This canvas as a [NativeEventTarget]. Each read gives the same object
  /// for the same canvas, so that two reads are `==`, as two reads of a DOM
  /// element are `===`.
  NativeEventTarget get eventTarget =>
      _canvasTargets[this] ??= _CanvasEventTarget(this);

  /// `getBoundingClientRect()`: the canvas box in the logical pixels of the
  /// view, the space of `clientX` and `clientY`: the origin of the host and
  /// the display size of the canvas ([RenderChartHost.boundingClientRect]).
  /// A canvas that no attached, laid-out host shows gives [DOMRect.zero], as
  /// a DOM element outside the document does.
  DOMRect getBoundingClientRect() {
    if (this case CanvasNode(parentNode: final RenderChartHost host)) {
      return host.boundingClientRect;
    }
    return DOMRect.zero;
  }
}

/// The [NativeEventTarget] of each canvas: one object for each canvas.
final Expando<_CanvasEventTarget> _canvasTargets = Expando(
  'canvas event target',
);

/// A canvas element as a [NativeEventTarget].
final class _CanvasEventTarget(final HTMLCanvasElement _canvas)
    implements NativeEventTarget {
  @override
  void addEventListener(
    String type,
    NativeEventListener listener, {
    bool? passive,
  }) => _canvas.addEventListener(type, listener, passive: passive);

  @override
  void removeEventListener(String type, NativeEventListener listener) =>
      _canvas.removeEventListener(type, listener);

  @override
  bool dispatchEvent(NativeEvent event) => _canvas.dispatchEvent(event);

  @override
  String toString() => 'EventTarget($_canvas)';
}

// The document.

/// The DOM document of the canvas elements (Chart.js ADR 0108): one for each
/// isolate, as a page has one document. `canvas.ownerDocument` gives it.
///
/// - A bubbling event that a canvas dispatches reaches the document
///   listeners after the canvas listeners ([dispatchCanvasEvent]).
/// - The host also sends the document the `pointermove`, `mousemove`,
///   `pointerup`, `mouseup`, `click` and `pointercancel` of a mouse-like
///   pointer that went down on the host, while the pointer is outside the
///   box. Their target is the document.
/// - While the document has a `keydown`, `keypress` or `keyup` listener, one
///   `HardwareKeyboard` handler sends it each key of the app, whichever
///   widget has the focus, as the DOM document gets each key of the page.
///   The handler runs before the focus tree. Thus the document gets a key
///   before the key listeners of a focused `ChartView`: the DOM order is
///   the reverse.
///
/// [dispatchEvent] is the port of `document.documentElement.dispatchEvent`:
/// it calls the document listeners only.
final class CanvasDocument._() implements NativeEventTarget {
  /// The document of the isolate.
  static final CanvasDocument instance = CanvasDocument._();

  /// The DOM event types whose `passive` default is true on the document
  /// (the default passive value of the DOM).
  static const Set<String> _passiveTypes = {
    'wheel',
    'mousewheel',
    'touchstart',
    'touchmove',
  };

  /// The key event types of the keyboard bridge.
  static const Set<String> _keyTypes = {'keydown', 'keypress', 'keyup'};

  final Map<String, List<_Listener>> _listeners = {};

  bool _keyBridge = false;

  @override
  void addEventListener(
    String type,
    NativeEventListener listener, {
    bool? passive,
  }) {
    _addListener(
      _listeners,
      type,
      listener,
      passive: passive ?? _passiveTypes.contains(type),
    );
    if (_keyTypes.contains(type)) {
      // The test binding clears the keyboard handlers after each test. Thus
      // each key listener installs the handler again, once.
      HardwareKeyboard.instance
        ..removeHandler(_onKey)
        ..addHandler(_onKey);
      _keyBridge = true;
    }
  }

  @override
  void removeEventListener(String type, NativeEventListener listener) {
    if (_removeListener(_listeners, type, listener) &&
        _keyTypes.contains(type) &&
        !_keyTypes.any(_listeners.containsKey)) {
      HardwareKeyboard.instance.removeHandler(_onKey);
      _keyBridge = false;
    }
  }

  @override
  bool dispatchEvent(NativeEvent event) {
    setNativeEventTarget(event, this);
    _invoke(event);
    return !event.defaultPrevented;
  }

  /// Whether the document has a listener for [type].
  bool hasListener(String type) => _listeners.containsKey(type);

  /// The count of the listeners of the document, of all types.
  @visibleForTesting
  int get debugListenerCount {
    var count = 0;
    for (final listeners in _listeners.values) {
      count += listeners.length;
    }
    return count;
  }

  /// Whether the keyboard bridge is on: the document has a key listener.
  @visibleForTesting
  bool get debugKeyBridge => _keyBridge;

  /// The document listeners of `event.type`: the bubble phase, or the
  /// dispatch of [dispatchEvent]. The target stays.
  void _invoke(NativeEvent event) {
    _invokeListeners(_listeners[event.type], event);
  }

  /// The `HardwareKeyboard` handler of the keyboard bridge: `keydown`, then
  /// `keypress` for a key with a character, or `keyup` (the mapping of
  /// Chart.js ADR 0051, section 5). A prevented `keydown` gives no
  /// `keypress`, as in the DOM. Each event has NaN offsets and client
  /// point, the key value of [domKeyValue], the modifiers, `bubbles` and
  /// `cancelable`. The handler gives true when a listener prevented the
  /// default: the event then does not reach the text input and the
  /// platform, as a prevented DOM key has no default action. The focus tree
  /// still gets the event.
  bool _onKey(KeyEvent event) {
    final key = domKeyValue(event);
    final modifiers = _modifiers();

    /// Sends [type] to the document listeners. Gives false when a listener
    /// prevented the default.
    bool send(String type) {
      if (!hasListener(type)) {
        return true;
      }
      return dispatchEvent(
        NativeEvent(
          type: type,
          offsetX: double.nan,
          offsetY: double.nan,
          clientX: double.nan,
          clientY: double.nan,
          source: event,
          bubbles: true,
          cancelable: true,
          key: key,
          ctrlKey: modifiers.ctrl,
          altKey: modifiers.alt,
          shiftKey: modifiers.shift,
          metaKey: modifiers.meta,
        ),
      );
    }

    if (event is KeyUpEvent) {
      return !send('keyup');
    }
    if (!send('keydown')) {
      return true;
    }
    return event.character != null && !send('keypress');
  }

  @override
  String toString() => '#document';
}

/// The UI Events key values of the named keys. `LogicalKeyboardKey.keyLabel`
/// is not the DOM value: it gives `'Arrow Left'`.
final Map<LogicalKeyboardKey, String> _namedKeys = {
  LogicalKeyboardKey.escape: 'Escape',
  LogicalKeyboardKey.enter: 'Enter',
  LogicalKeyboardKey.numpadEnter: 'Enter',
  LogicalKeyboardKey.tab: 'Tab',
  LogicalKeyboardKey.backspace: 'Backspace',
  LogicalKeyboardKey.delete: 'Delete',
  LogicalKeyboardKey.insert: 'Insert',
  LogicalKeyboardKey.home: 'Home',
  LogicalKeyboardKey.end: 'End',
  LogicalKeyboardKey.pageUp: 'PageUp',
  LogicalKeyboardKey.pageDown: 'PageDown',
  LogicalKeyboardKey.arrowUp: 'ArrowUp',
  LogicalKeyboardKey.arrowDown: 'ArrowDown',
  LogicalKeyboardKey.arrowLeft: 'ArrowLeft',
  LogicalKeyboardKey.arrowRight: 'ArrowRight',
  LogicalKeyboardKey.shift: 'Shift',
  LogicalKeyboardKey.shiftLeft: 'Shift',
  LogicalKeyboardKey.shiftRight: 'Shift',
  LogicalKeyboardKey.control: 'Control',
  LogicalKeyboardKey.controlLeft: 'Control',
  LogicalKeyboardKey.controlRight: 'Control',
  LogicalKeyboardKey.alt: 'Alt',
  LogicalKeyboardKey.altLeft: 'Alt',
  LogicalKeyboardKey.altRight: 'Alt',
  LogicalKeyboardKey.meta: 'Meta',
  LogicalKeyboardKey.metaLeft: 'Meta',
  LogicalKeyboardKey.metaRight: 'Meta',
  LogicalKeyboardKey.capsLock: 'CapsLock',
  LogicalKeyboardKey.contextMenu: 'ContextMenu',
  LogicalKeyboardKey.f1: 'F1',
  LogicalKeyboardKey.f2: 'F2',
  LogicalKeyboardKey.f3: 'F3',
  LogicalKeyboardKey.f4: 'F4',
  LogicalKeyboardKey.f5: 'F5',
  LogicalKeyboardKey.f6: 'F6',
  LogicalKeyboardKey.f7: 'F7',
  LogicalKeyboardKey.f8: 'F8',
  LogicalKeyboardKey.f9: 'F9',
  LogicalKeyboardKey.f10: 'F10',
  LogicalKeyboardKey.f11: 'F11',
  LogicalKeyboardKey.f12: 'F12',
  LogicalKeyboardKey.space: ' ',
};

/// The character of the last down of each physical key: a `KeyUpEvent` has
/// no character in Flutter.
final Map<PhysicalKeyboardKey, String> _downCharacters = {};

/// The UI Events `key` value of the Flutter key [event] (Chart.js ADR 0108):
/// the value of a named key ([_namedKeys]), else the character of a down or
/// a repeat, else, for an up, the character of the last down of its
/// physical key, else `'Unidentified'`. The document bridge and the
/// keyboard of `ChartView` use it.
String domKeyValue(KeyEvent event) {
  final named = _namedKeys[event.logicalKey];
  if (named != null) {
    return named;
  }
  if (event is KeyUpEvent) {
    return _downCharacters[event.physicalKey] ?? 'Unidentified';
  }
  final character = event.character;
  if (character == null) {
    _downCharacters.remove(event.physicalKey);
    return 'Unidentified';
  }
  _downCharacters[event.physicalKey] = character;
  return character;
}

// The MutationObserver of the document.

/// The observers of each canvas.
final Expando<List<CanvasMutationObserver>> _mutationObservers = Expando(
  'canvas mutation observers',
);

/// The `MutationObserver` of `createAttachObserver` and
/// `createDetachObserver` (`platform.dom.js:129-159`), for one canvas.
///
/// Upstream observes the whole document and tests whether the added or
/// removed nodes contain the canvas. Here the host of the canvas reports the
/// net change of its attached state: `true` when it shows the canvas in a
/// laid-out render tree, `false` when it stops.
final class CanvasMutationObserver(
  /// The callback of the observer.
  final void Function({required bool connected}) callback,
) {
  /// Creates an observer that calls [callback] with the new attached state.
  this;

  HTMLCanvasElement? _canvas;

  /// `observer.observe(document, {childList: true, subtree: true})`, for
  /// [canvas].
  void observe(HTMLCanvasElement canvas) {
    disconnect();
    _canvas = canvas;
    (_mutationObservers[canvas] ??= []).add(this);
  }

  /// `observer.disconnect()`.
  void disconnect() {
    final canvas = _canvas;
    if (canvas != null) {
      _mutationObservers[canvas]?.remove(this);
      _canvas = null;
    }
  }
}

/// Reports the attached state [connected] of [canvas] to its observers.
void _notifyConnection(HTMLCanvasElement canvas, {required bool connected}) {
  final observers = _mutationObservers[canvas];
  if (observers == null) {
    return;
  }
  for (final observer in List.of(observers)) {
    if (identical(observer._canvas, canvas)) {
      observer.callback(connected: connected);
    }
  }
}

/// The delivery of the `MutationObserver` records at a microtask
/// checkpoint (`platform.dom.js:129-159`): reports now the net attached
/// state of each host with a pending connection check, in the order of the
/// attach and detach changes. The post-frame check of each host then finds
/// no change.
///
/// Only the test harness calls it (Chart.js ADR 0022): its mutation
/// checkpoint gives a detach and an attach to the chart in the task of the
/// DOM write, as the DOM does. Without a call, the post-frame check of
/// Chart.js ADR 0016, decision 9, reports them.
void flushCanvasMutations() {
  final hosts = List.of(RenderChartHost._pendingConnectionChecks);
  RenderChartHost._pendingConnectionChecks.clear();
  for (final host in hosts) {
    host._reportConnection();
  }
}

// The ResizeObserver of the container.

/// The `ResizeObserver` of `createResizeObserver`
/// (`platform.dom.js:191-229`), plus the device pixel ratio changes of the
/// window `resize` listener (`platform.dom.js:161-189`).
///
/// [onResize] gets the content size of the container: the max size of the
/// incoming constraints of the host, `double.infinity` for an unbounded
/// side. As a DOM `ResizeObserver`, the observer gets the current size at
/// the next rendering step after it starts to observe a laid-out container:
/// the next layout of the host (Chart.js ADR 0022). Then it gets each
/// change. A [disconnect] before that layout gives no notification.
/// [onDevicePixelRatio] gets the new device pixel ratio of the host.
final class ContainerResizeObserver({
  /// The `ResizeObserver` callback, with `contentRect.width` and
  /// `contentRect.height`.
  required final void Function(double width, double height) onResize,

  /// The device pixel ratio callback.
  required final void Function(double devicePixelRatio) onDevicePixelRatio,
}) {
  /// Creates an observer with the two callbacks.
  this;

  RenderChartHost? _host;

  /// `observer.observe(container)`. A container that is not a
  /// [RenderChartHost] has no size changes.
  void observe(CanvasContainer container) {
    disconnect();
    if (container is RenderChartHost) {
      _host = container;
      container._addResizeObserver(this);
    }
  }

  /// `observer.disconnect()`.
  void disconnect() {
    _host?._resizeObservers.remove(this);
    _host?._pendingFirstResize.remove(this);
    _host = null;
  }
}

// The host.

/// The internal chart host widget (Chart.js ADR 0037): it shows [canvas]
/// and sends the input on it to the listeners of the canvas.
///
/// It reads the device pixel ratio with `MediaQuery.devicePixelRatioOf`, the
/// ticker state with `TickerMode.valuesOf` and the gesture settings with
/// `MediaQuery.maybeGestureSettingsOf` in [createRenderObject] and
/// [updateRenderObject]. `View.of` does not rebuild on a change of the
/// device pixel ratio.
class const ChartHost({
  /// The canvas element that the host shows.
  required final UiCanvasElement canvas,

  /// Called when the `TickerMode` of the host changes, with the new
  /// `enabled` value. `core.animator` mutes the chart while it is false
  /// (Chart.js ADR 0016, decision 7).
  final ValueChanged<bool>? onTickerModeChanged,

  /// Called in the first layout of the host, after the host is laid out and
  /// reports its attach, before the host takes its size. It is called again
  /// after a canvas swap. The owner starts its chart here: the chart then
  /// attaches in its constructor and takes its size in this layout. A
  /// listener must not call `setState` (Chart.js ADR 0016, ADR 0049).
  final VoidCallback? onFirstLayout,

  /// Whether a trackpad scroll and a trackpad pinch give `wheel` events, as
  /// in Chrome: a scroll gives its deltas, and a pinch gives a `wheel` with
  /// `ctrlKey` (Chart.js ADR 0137).
  final bool trackpadGestures = true,
  super.key,
}) extends LeafRenderObjectWidget {
  /// Creates a host for [canvas].
  this;

  static double _devicePixelRatio(BuildContext context) =>
      MediaQuery.maybeDevicePixelRatioOf(context) ??
      View.maybeOf(context)?.devicePixelRatio ??
      1;

  @override
  RenderChartHost createRenderObject(BuildContext context) {
    return RenderChartHost(
      canvas: canvas,
      devicePixelRatio: _devicePixelRatio(context),
      tickerEnabled: TickerMode.valuesOf(context).enabled,
      gestureSettings: MediaQuery.maybeGestureSettingsOf(context),
      onTickerModeChanged: onTickerModeChanged,
      onFirstLayout: onFirstLayout,
      trackpadGestures: trackpadGestures,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderChartHost renderObject) {
    renderObject
      ..canvas = canvas
      ..onTickerModeChanged = onTickerModeChanged
      ..onFirstLayout = onFirstLayout
      ..devicePixelRatio = _devicePixelRatio(context)
      ..tickerEnabled = TickerMode.valuesOf(context).enabled
      ..gestureSettings = MediaQuery.maybeGestureSettingsOf(context)
      ..trackpadGestures = trackpadGestures;
  }
}

/// The pictures of a canvas as pictures of the scene (Chart.js ADR 0097).
///
/// The layer pushes the transform of the host and the clip to the bitmap, and
/// adds one scene picture for each picture of the context. It has the pixels of
/// `Canvas.drawPicture` of these pictures under the same transform and clip,
/// without the recording canvas of the boundary, whose spatial index merges
/// the regions of each picture on the UI thread.
///
/// It reads the pictures from the context when the scene needs them. Thus it
/// holds no picture that the context can dispose. Each engine layer of a scene
/// keeps its own reference to its picture. A clean layer is retained: the scene
/// keeps what the last paint added.
@internal
final class ChartPicturesLayer() extends Layer {
  final Float64List _matrix = Float64List(16)
    ..[10] = 1
    ..[15] = 1;
  UiCanvasContext? _context;
  ui.ClipRectEngineLayer? _clip;
  Rect _bounds = Rect.zero;

  /// The scale of the bitmap on the x axis, for tests.
  @visibleForTesting
  double get scaleX => _matrix[0];

  /// The scale of the bitmap on the y axis, for tests.
  @visibleForTesting
  double get scaleY => _matrix[5];

  /// Shows the pictures of [context] at [offset], with the scales of the host.
  void update(
    UiCanvasContext context,
    Offset offset,
    double scaleX,
    double scaleY,
  ) {
    _context = context;
    _bounds = context.bitmapBounds;
    _matrix
      ..[0] = scaleX
      ..[5] = scaleY
      ..[12] = offset.dx
      ..[13] = offset.dy;
    markNeedsAddToScene();
  }

  @override
  void addToScene(ui.SceneBuilder builder) {
    final transform = builder.pushTransform(
      _matrix,
      oldLayer: engineLayer as ui.TransformEngineLayer?,
    );
    final oldClip = _clip;
    _clip = builder.pushClipRect(_bounds, oldLayer: oldClip);
    oldClip?.dispose();
    _context?.addPicturesToScene(builder);
    builder
      ..pop()
      ..pop();
    engineLayer = transform;
  }

  @override
  void dispose() {
    _clip?.dispose();
    _clip = null;
    _context = null;
    super.dispose();
  }
}

/// The render object of [ChartHost].
///
/// It is a repaint boundary: a chart frame repaints only the host layer.
class RenderChartHost({
  required var UiCanvasElement _canvas,
  required var double _devicePixelRatio,
  var bool _tickerEnabled = true,

  /// The gesture settings of the view. Their touch slop gives the slop limit
  /// of a touch-like pointer (Chart.js ADR 0037, section 8): the slop, times
  /// 1.5 for a stylus, plus 0.05. Null gives `kTouchSlop`.
  var DeviceGestureSettings? gestureSettings,

  /// Called when [tickerEnabled] changes.
  var ValueChanged<bool>? onTickerModeChanged,

  /// Called in the first layout of the host with its current canvas, after
  /// the attach report and before the host takes its size (see
  /// [ChartHost.onFirstLayout]).
  var VoidCallback? onFirstLayout,

  /// See [ChartHost.trackpadGestures].
  var bool trackpadGestures = true,
}) extends RenderBox implements CanvasContainer, MouseTrackerAnnotation {
  /// Creates the render object of a host for [canvas].
  this {
    _show(_canvas);
  }

  /// The canvas element that the host shows.
  UiCanvasElement get canvas => _canvas;
  set canvas(UiCanvasElement value) {
    if (identical(value, _canvas)) {
      return;
    }
    final old = _canvas;
    _hide(old);
    if (_reportedConnected) {
      // The old canvas leaves the document.
      _reportedConnected = false;
      _notifyConnection(old, connected: false);
    }
    _canvas = value;
    _show(value);
    _laidOut = false;
    _endInput();
    _clearHoverPointers();
    markNeedsLayout();
  }

  /// The device pixel ratio of the view of the host.
  /// `FlutterPlatform.getDevicePixelRatio` reads it, and paint snaps its
  /// scale to `1 / devicePixelRatio` (see [paint]).
  double get devicePixelRatio => _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) {
      return;
    }
    _devicePixelRatio = value;
    markNeedsPaint();
    if (_laidOut) {
      for (final observer in List.of(_resizeObservers)) {
        observer.onDevicePixelRatio(value);
      }
    }
  }

  /// The `enabled` value of the `TickerMode` of the host.
  bool get tickerEnabled => _tickerEnabled;
  set tickerEnabled(bool value) {
    if (value == _tickerEnabled) {
      return;
    }
    _tickerEnabled = value;
    onTickerModeChanged?.call(value);
  }

  void _show(UiCanvasElement canvas) {
    final previous = canvas.parentNode;
    if (previous is RenderChartHost && !identical(previous, this)) {
      // A new host takes over the canvas of an old host in the same frame
      // (a wrapper toggle, a move without a GlobalKey, an AnimatedSwitcher).
      // The canvas stays in the document: the new host takes over the
      // reported state and the ResizeObservers of the old host.
      _reportedConnected = previous._reportedConnected;
      previous._reportedConnected = false;
      for (final observer in previous._resizeObservers) {
        observer._host = this;
        _resizeObservers.add(observer);
      }
      previous._resizeObservers.clear();
      _pendingFirstResize.addAll(previous._pendingFirstResize);
      previous._pendingFirstResize.clear();
    }
    canvas
      ..parentNode = this
      ..getContext2d().onChanged = _handleCanvasChanged;
  }

  void _hide(UiCanvasElement canvas) {
    if (identical(canvas.parentNode, this)) {
      canvas.parentNode = null;
    }
    final context = canvas.getContext2d();
    if (context.onChanged == _handleCanvasChanged) {
      context.onChanged = null;
    }
  }

  // The container.

  double _contentWidth = 0;
  double _contentHeight = 0;

  /// The max width of the incoming constraints, `double.infinity` when they
  /// are unbounded. 0 before the first layout.
  @override
  double get contentWidth => _contentWidth;

  /// The max height of the incoming constraints, `double.infinity` when they
  /// are unbounded. 0 before the first layout.
  @override
  double get contentHeight => _contentHeight;

  /// Whether the host is attached to the render tree and laid out: the DOM
  /// `isConnected` of a container in a rendered document. Thus a chart that
  /// starts before the first layout of its host is detached, and the first
  /// layout attaches it.
  @override
  bool get isConnected => attached && _laidOut;

  /// Whether the host has been laid out with its current canvas.
  bool _laidOut = false;

  /// The attached state of the last report to the mutation observers.
  bool _reportedConnected = false;

  bool _connectionCheckScheduled = false;

  bool _disposed = false;

  final List<ContainerResizeObserver> _resizeObservers = [];

  /// The observers that wait for their first notification: the next layout
  /// of the host gives them the current size.
  final Set<ContainerResizeObserver> _pendingFirstResize = {};

  void _addResizeObserver(ContainerResizeObserver observer) {
    _resizeObservers.add(observer);
    if (_laidOut) {
      // A DOM ResizeObserver gives the first notification at the next
      // rendering step. The host never calls markNeedsLayout inside its own
      // performLayout.
      _pendingFirstResize.add(observer);
      if (_inLayout) {
        _scheduleRelayout();
      } else {
        markNeedsLayout();
      }
    }
  }

  /// Whether the host is the parent node of its canvas. An old host whose
  /// canvas another host took over is not.
  bool get _showsCanvas {
    final parent = _canvas.parentNode;
    return parent == null || identical(parent, this);
  }

  /// Reports a net change of [isConnected] to the mutation observers.
  ///
  /// An old host whose canvas another host took over reports nothing. A
  /// disposed host still reports the detach of an unmount: its post-frame
  /// check runs after the dispose.
  void _reportConnection() {
    if (!_showsCanvas) {
      return;
    }
    final connected = isConnected;
    if (connected != _reportedConnected) {
      _reportedConnected = connected;
      _notifyConnection(_canvas, connected: connected);
    }
  }

  void _scheduleConnectionCheck() {
    _pendingConnectionChecks.add(this);
    if (_connectionCheckScheduled) {
      return;
    }
    _connectionCheckScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _connectionCheckScheduled = false;
      _pendingConnectionChecks.remove(this);
      _reportConnection();
    }, debugLabel: 'RenderChartHost.connection');
  }

  /// The hosts with a pending connection check, in the order of their
  /// attach or detach. [flushCanvasMutations] reports them.
  static final Set<RenderChartHost> _pendingConnectionChecks = {};

  // The display size of the canvas.

  static final RegExp _pixels = RegExp(r'^(\d*\.?\d+(?:e[+-]?\d+)?)px$');

  static double? _readPixels(String value) {
    final match = _pixels.firstMatch(value);
    return match == null ? null : double.tryParse(match[1]!);
  }

  /// The display size of the canvas in logical pixels: the `width` and
  /// `height` styles when both are pixel values, as `retinaScale` writes
  /// them, else the render size. The CSS rule for one style (it keeps the
  /// aspect ratio of the render size) is not here: the harness matcher
  /// `toBeChartOfSize` applies it.
  Size get displaySize {
    final style = _canvas.style;
    final width = _readPixels(style.getPropertyValue('width'));
    final height = _readPixels(style.getPropertyValue('height'));
    if (width != null && height != null) {
      return Size(width, height);
    }
    return Size(_canvas.width.toDouble(), _canvas.height.toDouble());
  }

  /// The DOM `getBoundingClientRect()` of the canvas (Chart.js ADR 0108):
  /// the box of the host origin and the [displaySize], in the logical
  /// pixels of the view, the space of `PointerEvent.position`. Thus for a
  /// host with no transform, `clientX - rect.left` is `offsetX`. A rotated or
  /// scaled host gives the axis-aligned box of the transformed canvas, as
  /// the DOM does. A host that is not attached and laid out gives
  /// [DOMRect.zero].
  DOMRect get boundingClientRect {
    if (!attached || !_laidOut) {
      return DOMRect.zero;
    }
    final rect = MatrixUtils.transformRect(
      getTransformTo(null),
      Offset.zero & _finite(displaySize),
    );
    return DOMRect(rect.left, rect.top, rect.width, rect.height);
  }

  Size _laidOutDisplaySize = Size.zero;

  void _handleCanvasChanged() {
    if (_disposed || !_showsCanvas) {
      return;
    }
    markNeedsPaint();
    // The context calls onChanged once until the next paint, but a chart
    // can change its size after its first draw, before that paint. Thus a
    // microtask after the current run of chart code re-arms onChanged and
    // compares the size. In a frame, the microtasks run after the transient
    // callbacks, before the layout.
    if (!_sizeCheckScheduled) {
      _sizeCheckScheduled = true;
      scheduleMicrotask(_checkDisplaySize);
    }
  }

  bool _sizeCheckScheduled = false;

  void _checkDisplaySize() {
    _sizeCheckScheduled = false;
    if (_disposed || !_showsCanvas) {
      return;
    }
    _canvas.getContext2d().onChanged = _handleCanvasChanged;
    // A change in performLayout (the first size) is read after it.
    if (!_inLayout && _laidOut && displaySize != _laidOutDisplaySize) {
      markNeedsLayout();
    }
  }

  // Layout.

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => false;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    // The chart takes its size in performLayout. A dry layout cannot resize
    // it, so it gives the current display size of the canvas.
    return constraints.constrain(displaySize);
  }

  @override
  double computeMinIntrinsicWidth(double height) => displaySize.width;

  @override
  double computeMaxIntrinsicWidth(double height) => displaySize.width;

  @override
  double computeMinIntrinsicHeight(double width) => displaySize.height;

  @override
  double computeMaxIntrinsicHeight(double width) => displaySize.height;

  bool _inLayout = false;

  @override
  void performLayout() {
    _inLayout = true;
    try {
      _performLayout();
    } finally {
      _inLayout = false;
    }
  }

  void _performLayout() {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final changed = width != _contentWidth || height != _contentHeight;
    _contentWidth = width;
    _contentHeight = height;
    if (!_laidOut) {
      // The first layout attaches the chart at once: it takes its size
      // before the first paint. The observers that the host took over from
      // an old host get the size now. The observers that the attach report
      // adds wait for the next layout.
      final before = List.of(_resizeObservers);
      _laidOut = true;
      _reportConnection();
      // The owner starts its chart attached: the chart takes its size in
      // this layout (Chart.js ADR 0049, section 2).
      onFirstLayout?.call();
      for (final observer in before) {
        if (_resizeObservers.contains(observer)) {
          observer.onResize(width, height);
        }
      }
      _pendingFirstResize.removeAll(before);
    } else if (changed) {
      _pendingFirstResize.clear();
      for (final observer in List.of(_resizeObservers)) {
        observer.onResize(width, height);
      }
    } else if (_pendingFirstResize.isNotEmpty) {
      final pending = List.of(_pendingFirstResize);
      _pendingFirstResize.clear();
      for (final observer in pending) {
        observer.onResize(width, height);
      }
    }
    _laidOutDisplaySize = displaySize;
    size = constraints.constrain(_finite(_laidOutDisplaySize));
  }

  static Size _finite(Size size) => Size(
    size.width.isFinite ? size.width : 0,
    size.height.isFinite ? size.height : 0,
  );

  bool _relayoutScheduled = false;

  void _scheduleRelayout() {
    if (_relayoutScheduled) {
      return;
    }
    _relayoutScheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        _relayoutScheduled = false;
        if (!_disposed && attached) {
          markNeedsLayout();
        }
      }, debugLabel: 'RenderChartHost.relayout')
      // A layout outside a frame (the forced layout of the test harness)
      // needs a frame for the callback.
      ..ensureVisualUpdate();
  }

  // Paint.

  final LayerHandle<ClipRectLayer> _clipLayer = LayerHandle<ClipRectLayer>();
  final LayerHandle<ChartPicturesLayer> _picturesLayer =
      LayerHandle<ChartPicturesLayer>();

  /// Paints the bitmap at the display size, as the DOM stretches a canvas
  /// bitmap to its CSS size: one scale of display size / bitmap size on
  /// each axis. A size of 0 gives a scale of 1. When both scales are within
  /// 1e-3 of `1 / devicePixelRatio`, the scale is exactly that value, so
  /// that the bitmap pixels stay on the device pixels.
  @override
  void paint(PaintingContext context, Offset offset) {
    final display = _finite(displaySize);
    if (display != _finite(_laidOutDisplaySize)) {
      // The chart changed its size without a content change since the last
      // paint, so onChanged did not run. Lay out again after this frame.
      _scheduleRelayout();
    }
    if (display.width > size.width || display.height > size.height) {
      _clipLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        _paintCanvas,
        oldLayer: _clipLayer.layer,
      );
    } else {
      _clipLayer.layer = null;
      _paintCanvas(context, offset);
    }
  }

  void _paintCanvas(PaintingContext context, Offset offset) {
    // The context paints even when it is empty: its paint call re-arms
    // onChanged.
    final display = displaySize;
    final dpr = _devicePixelRatio;
    var scaleX = _canvas.width > 0 ? display.width / _canvas.width : 1.0;
    var scaleY = _canvas.height > 0 ? display.height / _canvas.height : 1.0;
    if ((scaleX * dpr - 1).abs() < 1e-3 && (scaleY * dpr - 1).abs() < 1e-3) {
      scaleX = scaleY = 1 / dpr;
    }
    final canvasContext = _canvas.getContext2d();
    // The host is a repaint boundary, so its ancestors take a layer of it. The
    // merge of the regions in `Canvas.drawPicture` is a cost of the native
    // engine only: the web keeps the draw, and a scale that a transform cannot
    // take keeps it too.
    if (!kIsWeb &&
        scaleX > 0 &&
        scaleY > 0 &&
        scaleX.isFinite &&
        scaleY.isFinite &&
        offset.isFinite &&
        canvasContext.beginScenePaint()) {
      if (canvasContext.hasScenePictures) {
        context.addLayer(
          (_picturesLayer.layer ??= ChartPicturesLayer())
            ..update(canvasContext, offset, scaleX, scaleY),
        );
      } else {
        _picturesLayer.layer = null;
      }
      return;
    }
    _picturesLayer.layer = null;
    canvasContext.paint(context.canvas, offset, scaleX, scaleY);
  }

  // Attach and detach.

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _validForMouseTracker = true;
    if (_laidOut) {
      _scheduleConnectionCheck();
    }
  }

  @override
  void detach() {
    _validForMouseTracker = false;
    super.detach();
    _endInput();
    _clearHoverPointers();
    if (_reportedConnected) {
      _scheduleConnectionCheck();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _endInput();
    _clearHoverPointers();
    _clipLayer.layer = null;
    _picturesLayer.layer = null;
    _resizeObservers.clear();
    _pendingFirstResize.clear();
    _hide(_canvas);
    super.dispose();
  }

  // Input.

  @override
  bool hitTestSelf(Offset position) => true;

  /// The touch-like pointers that are down on the host, by pointer id: the
  /// DOM `targetTouches` of the canvas.
  final SplayTreeMap<int, _HostTouch> _touches = SplayTreeMap();

  List<NativeTouch> get _touchList => [
    for (final MapEntry(:key, :value) in _touches.entries)
      (
        identifier: key,
        x: value.last.localPosition.dx,
        y: value.last.localPosition.dy,
      ),
  ];

  /// Whether the touch sequence of the host has begun the pan: Chromium
  /// `!all_pointers_within_slop_regions_` (`gesture_detector.cc`) and Blink
  /// `non_hovering_pointers_canceled_` (`pointer_event_manager.cc`) for the
  /// touch-like pointers of the host. While it is true, the touch-like
  /// pointers give only `touch*` events (device check P4, D3). A down with
  /// no touch-like pointer on the host starts a new sequence.
  bool _panned = false;

  /// The largest count of touch-like pointers on the host in the sequence:
  /// Chromium `maximum_pointer_count_`. With more than 2, any move with a
  /// change begins the pan.
  int _sequenceTouches = 0;

  /// Whether the touch sequence of the host has `touch-action: none`
  /// (Chart.js ADR 0108): the inline style of the canvas at the first
  /// touch-like down of the sequence. While it is true, no move begins the
  /// pan, and the host claims its touch-like pointers in the gesture arena
  /// ([_claim]).
  bool _touchActionNone = false;

  /// The pointer of a mouse-like down with the primary button on the host,
  /// or null: the DOM click rule (Chart.js ADR 0037, section 7).
  int? _clickPointer;

  /// The tap candidate of the host, or null (Chart.js ADR 0037, section 8).
  _TouchTap? _tap;

  /// The mouse-like pointers that went down on the host, with the last
  /// buttons of each that were not 0. The `button` of a `pointerup` and a
  /// `mouseup` is the lowest of these buttons (Flutter sends one up when all
  /// buttons are up). While such a pointer is outside the box, its events go
  /// to the document (Chart.js ADR 0108).
  final Map<int, int> _mouseButtons = {};

  /// Whether the canvas has a listener for [type], or the document has one
  /// for a bubbling [type].
  bool _has(String type) =>
      hasCanvasEventListener(_canvas, type) ||
      (_bubbles(type) && CanvasDocument.instance.hasListener(type));

  /// Sends the events [types] at [position] to the canvas listeners. A
  /// bubbling event then goes to the document listeners.
  ///
  /// [source] gives the fields of the events ([_nativeEvent]). [client] is
  /// the client point, by default the position of [source]. [compat] marks
  /// the compatibility mouse events of a touch tap or a long press.
  ///
  /// Gives false when a listener prevented the default of one of the
  /// events: the result of `dispatchEvent` (Chart.js ADR 0108).
  bool _emit(
    List<String> types,
    Offset position,
    PointerEvent source, {
    bool touch = false,
    bool compat = false,
    Offset? client,
    Offset? wheelDelta,
    bool wheelCtrl = false,
  }) {
    List<NativeTouch>? touches;
    _Modifiers? modifiers;
    var notPrevented = true;
    for (final type in types) {
      if (!_has(type)) {
        continue;
      }
      final isTouchEvent = touch && type.startsWith('touch');
      if (!dispatchCanvasEvent(
        _canvas,
        _nativeEvent(
          type,
          position,
          source,
          client: client ?? source.position,
          modifiers: modifiers ??= _withCtrl(_modifiers(), wheelCtrl),
          touchEvent: isTouchEvent,
          touches: isTouchEvent ? (touches ??= _touchList) : const [],
          compat: compat,
          wheelDelta: wheelDelta,
        ),
      )) {
        notPrevented = false;
      }
    }
    return notPrevented;
  }

  /// Sends the events [types] of a mouse-like pointer that went down on the
  /// host and is outside the box to the document listeners only (Chart.js
  /// ADR 0108). Their target is the document. The DOM sends them to the
  /// element under the pointer, and they bubble to the document. The canvas
  /// gets none of them: a mouse has no implicit capture.
  void _emitToDocument(
    List<String> types,
    Offset position,
    PointerEvent source,
  ) {
    final document = CanvasDocument.instance;
    _Modifiers? modifiers;
    for (final type in types) {
      if (!document.hasListener(type)) {
        continue;
      }
      document.dispatchEvent(
        _nativeEvent(
          type,
          position,
          source,
          client: source.position,
          modifiers: modifiers ??= _modifiers(),
        ),
      );
    }
  }

  /// The DOM event [type] of the Flutter event [source] at the local
  /// [position] and the client point [client], with the fields of Chrome
  /// (Chart.js ADR 0108).
  ///
  /// A `touch*` event ([touchEvent]) has NaN offsets and client point and
  /// the [touches]. A compatibility mouse event of a tap ([compat]) has the
  /// fields of the mouse event of Chrome for a tap: `buttons` 1 for
  /// `mousedown`, else 0.
  NativeEvent _nativeEvent(
    String type,
    Offset position,
    PointerEvent source, {
    required Offset client,
    required _Modifiers modifiers,
    bool touchEvent = false,
    List<NativeTouch> touches = const [],
    bool compat = false,
    Offset? wheelDelta,
  }) {
    final mouseLike = _isMouseKind(source.kind);
    final pointerEvent = type.startsWith('pointer') || type == 'click';
    final delta = type != 'wheel'
        ? Offset.zero
        : wheelDelta ??
              (source is PointerScrollEvent ? source.scrollDelta : Offset.zero);
    return NativeEvent(
      type: type,
      // A TouchEvent has no offsetX and offsetY.
      offsetX: touchEvent ? double.nan : position.dx,
      offsetY: touchEvent ? double.nan : position.dy,
      touches: touches,
      source: source,
      bubbles: _bubbles(type),
      cancelable: _cancelable(type),
      clientX: touchEvent ? double.nan : client.dx,
      clientY: touchEvent ? double.nan : client.dy,
      button: _button(type, source, mouseLike: mouseLike),
      buttons: _buttons(type, source, mouseLike: mouseLike, compat: compat),
      pointerId: pointerEvent ? _domPointerId(source) : 0,
      pointerType: pointerEvent ? _pointerType(source.kind) : '',
      deltaX: delta.dx,
      deltaY: delta.dy,
      ctrlKey: modifiers.ctrl,
      altKey: modifiers.alt,
      shiftKey: modifiers.shift,
      metaKey: modifiers.meta,
    );
  }

  /// `bubbles` of the DOM event [type]: false for the enter and leave
  /// events.
  static bool _bubbles(String type) => switch (type) {
    'pointerenter' || 'pointerleave' || 'mouseenter' || 'mouseleave' => false,
    _ => true,
  };

  /// `cancelable` of the DOM event [type]: false for the enter and leave
  /// events, `pointercancel` and `touchcancel`, and for a `touchmove` after
  /// the pan begins (Chrome sends uncancelable moves while it scrolls).
  bool _cancelable(String type) => switch (type) {
    'pointerenter' ||
    'pointerleave' ||
    'pointercancel' ||
    'mouseenter' ||
    'mouseleave' ||
    'touchcancel' => false,
    'touchmove' => !_panned,
    _ => true,
  };

  /// `MouseEvent.button` of the DOM event [type] of [source]: the pressed
  /// button of a mouse-like `pointerdown` and `mousedown`, the released
  /// button of a mouse-like `pointerup` and `mouseup`, -1 for a `pointer*`
  /// event with no change of the buttons, and 0 for the other events.
  int _button(String type, PointerEvent source, {required bool mouseLike}) {
    switch (type) {
      case 'pointerdown' || 'mousedown':
        return mouseLike ? _domButton(source.buttons) : 0;
      case 'pointerup' || 'mouseup':
        return mouseLike ? _domButton(_mouseButtons[source.pointer] ?? 0) : 0;
      case 'click':
        return 0;
    }
    return type.startsWith('pointer') ? -1 : 0;
  }

  /// `MouseEvent.buttons` of the DOM event [type] of [source].
  ///
  /// A mouse-like pointer gives its Flutter buttons, whose bits are the DOM
  /// bits. A touch-like pointer gives its buttons in contact, with the
  /// eraser bit 32 for the contact of an inverted stylus, and 0 at the up,
  /// the cancel and the leave. A `touch*` event, which has no buttons in the
  /// DOM, gives 0. A compatibility event of a tap ([compat]) gives 1 for
  /// `mousedown` and 0 for the others.
  static int _buttons(
    String type,
    PointerEvent source, {
    required bool mouseLike,
    required bool compat,
  }) {
    if (mouseLike) {
      return source.buttons;
    }
    if (compat) {
      return type == 'mousedown' ? 1 : 0;
    }
    switch (type) {
      case 'pointerup' || 'pointercancel' || 'pointerout' || 'pointerleave':
        return 0;
    }
    if (type.startsWith('touch')) {
      return 0;
    }
    final buttons = source.buttons;
    if (source.kind == PointerDeviceKind.invertedStylus &&
        buttons & kPrimaryButton != 0) {
      return buttons & ~kPrimaryButton | _eraserButton;
    }
    return buttons;
  }

  /// The DOM `buttons` bit of the eraser of a pen.
  static const int _eraserButton = 32;

  /// The DOM `button` of the lowest bit of the Flutter mouse [buttons]: the
  /// primary bit 1 is 0, the secondary bit 2 is 2, the middle bit 4 is 1,
  /// the back bit 8 is 3 and the forward bit 16 is 4. No bit gives 0.
  static int _domButton(int buttons) {
    if (buttons & kPrimaryMouseButton != 0) return 0;
    if (buttons & kSecondaryMouseButton != 0) return 2;
    if (buttons & kMiddleMouseButton != 0) return 1;
    if (buttons & kBackMouseButton != 0) return 3;
    if (buttons & kForwardMouseButton != 0) return 4;
    return 0;
  }

  /// `PointerEvent.pointerType` of [kind].
  static String _pointerType(PointerDeviceKind kind) => switch (kind) {
    PointerDeviceKind.mouse || PointerDeviceKind.trackpad => 'mouse',
    PointerDeviceKind.touch => 'touch',
    PointerDeviceKind.stylus || PointerDeviceKind.invertedStylus => 'pen',
    PointerDeviceKind.unknown => '',
  };

  /// The DOM pointer ids of the touch-like Flutter pointers, by Flutter
  /// pointer id. The host frees an id after the events of the up or the
  /// cancel of its pointer, or at the hover exit of a hovering pointer.
  static final Map<int, int> _domPointerIds = {};

  /// The next DOM pointer id of a touch-like pointer. Blink counts the ids
  /// up from 2 (`PointerEventFactory`); 1 is the mouse.
  static int _nextDomPointerId = 2;

  /// `PointerEvent.pointerId` of [source]: 1 for a mouse-like pointer, as the
  /// mouse of Blink, else the id of the Flutter pointer, which the first
  /// event of the pointer takes.
  static int _domPointerId(PointerEvent source) => _isMouseKind(source.kind)
      ? 1
      : _domPointerIds.putIfAbsent(source.pointer, () => _nextDomPointerId++);

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    final position = event.localPosition;
    // A stylus in contact gives the touch rows, as in Chrome on Android
    // (device check P4, D5).
    final touch = !_isMouseKind(event.kind);
    switch (event) {
      case PointerHoverEvent():
        if (_isUntrackedHoverKind(event.kind)) {
          _handleUntrackedHoverOver(event);
        }
        _emit(const ['pointermove', 'mousemove'], position, event);
      case PointerDownEvent():
        if (touch) {
          _handleTouchDown(event);
        } else {
          // The DOM click rule: only the primary button gives a click.
          _clickPointer = event.buttons == kPrimaryButton
              ? event.pointer
              : null;
          _mouseButtons[event.pointer] = event.buttons;
          _emit(const ['pointerdown', 'mousedown'], position, event);
        }
      case PointerMoveEvent():
        if (touch) {
          _handleTouchMove(event);
        } else {
          if (event.buttons != 0 && _mouseButtons.containsKey(event.pointer)) {
            _mouseButtons[event.pointer] = event.buttons;
          }
          if (size.contains(position)) {
            _emit(const ['pointermove', 'mousemove'], position, event);
          } else if (_mouseButtons.containsKey(event.pointer)) {
            // A mouse has no implicit capture: the canvas gets no move
            // outside its box, and the document gets it.
            _emitToDocument(
              const ['pointermove', 'mousemove'],
              position,
              event,
            );
          }
        }
      case PointerUpEvent():
        if (touch) {
          _handleTouchUp(event);
        } else {
          final click = _clickPointer == event.pointer;
          _clickPointer = null;
          if (size.contains(position)) {
            // The up goes to the hit path of the down, but a mouse has no
            // implicit capture: the canvas gets no up outside its box.
            _emit(const ['pointerup', 'mouseup'], position, event);
            if (click) {
              _emit(const ['click'], position, event);
            }
          } else if (_mouseButtons.containsKey(event.pointer)) {
            // The document gets the up outside the box, and the click of the
            // click rule: the DOM sends that click to the common ancestor.
            _emitToDocument(const ['pointerup', 'mouseup'], position, event);
            if (click) {
              _emitToDocument(const ['click'], position, event);
            }
          }
          _mouseButtons.remove(event.pointer);
        }
      case PointerCancelEvent():
        if (touch) {
          final hostTouch = _touches.remove(event.pointer);
          if (hostTouch != null) {
            _unclaim(hostTouch);
          }
          if (_tap?.pointer == event.pointer) {
            _endTap();
          }
          _hostPointers.remove(event.pointer);
          // A platform cancel keeps its own position. After the pan, the
          // pointer events of the pointer are already canceled.
          _emit(
            _panned
                ? const ['touchcancel']
                : const [
                    'pointercancel',
                    'pointerout',
                    'pointerleave',
                    'touchcancel',
                  ],
            position,
            event,
            touch: true,
          );
          _domPointerIds.remove(event.pointer);
        } else {
          _clickPointer = null;
          if (size.contains(position)) {
            _emit(const ['pointercancel'], position, event);
          } else if (_mouseButtons.containsKey(event.pointer)) {
            _emitToDocument(const ['pointercancel'], position, event);
          }
          _mouseButtons.remove(event.pointer);
        }
      case PointerPanZoomStartEvent() when trackpadGestures:
        _handlePanZoomStart(event);
      case PointerPanZoomUpdateEvent():
        _handlePanZoomUpdate(event, position);
      case PointerPanZoomEndEvent():
        _handlePanZoomEnd(event);
      case PointerScrollEvent():
        if (!_emit(const ['wheel'], position, event)) {
          // A listener prevented the default of the wheel (Chart.js ADR
          // 0108). The host is deeper than each scrollable, so it registers
          // first, and the first registration wins: no ancestor scrolls.
          GestureBinding.instance.pointerSignalResolver.register(
            event,
            _preventPlatformDefault,
          );
        }
      default:
        break;
    }
  }

  /// The trackpad gestures in progress, by pointer (Chart.js ADR 0137).
  final Map<int, _PanZoom> _panZooms = {};

  /// The start of a trackpad gesture: the host joins the gesture arena of
  /// the pointer, so that it can take the gesture from a scrollable
  /// ancestor when a listener prevents a `wheel` of it.
  void _handlePanZoomStart(PointerPanZoomStartEvent event) {
    _panZooms[event.pointer] = _PanZoom(
      GestureBinding.instance.gestureArena.add(
        event.pointer,
        const _TrackpadClaim(),
      ),
    );
  }

  /// One step of a trackpad gesture, as Chrome sends it: a pinch step is a
  /// `wheel` with `ctrlKey` and `deltaY` -100 times the natural log of the
  /// scale step, and a scroll step is a `wheel` with the opposite of the pan
  /// step. A prevented `wheel` takes the gesture from the arena.
  void _handlePanZoomUpdate(PointerPanZoomUpdateEvent event, Offset position) {
    final gesture = _panZooms[event.pointer];
    if (gesture == null) return;
    final step = event.scale / gesture.scale;
    gesture.scale = event.scale;
    final pinch = step != 1 && step.isFinite && step > 0;
    final delta = pinch ? Offset(0, -100 * math.log(step)) : -event.panDelta;
    if (delta == Offset.zero) return;
    final notPrevented = _emit(
      const ['wheel'],
      position,
      event,
      wheelDelta: delta,
      wheelCtrl: pinch,
    );
    if (!notPrevented && !gesture.claimed) {
      gesture.claimed = true;
      gesture.arena.resolve(GestureDisposition.accepted);
    }
  }

  /// The end of a trackpad gesture: the host gives up an arena that it did
  /// not take.
  void _handlePanZoomEnd(PointerPanZoomEndEvent event) {
    final gesture = _panZooms.remove(event.pointer);
    if (gesture != null && !gesture.claimed) {
      gesture.arena.resolve(GestureDisposition.rejected);
    }
  }

  /// The pointer signal callback of a prevented `wheel`: the platform does
  /// not scroll the page (Chart.js ADR 0108), as for a scrollable that
  /// scrolls.
  static void _preventPlatformDefault(PointerSignalEvent event) =>
      event.respond(allowPlatformDefault: false);

  void _handleTouchDown(PointerDownEvent event) {
    if (_touches.isEmpty) {
      // A new touch sequence: Blink clears the canceled state at a
      // non-hovering event with no active touch (pointer_event_manager.cc).
      _panned = false;
      _sequenceTouches = 0;
      // Chrome fixes the touch action at the start of the touch (Chart.js
      // ADR 0108). Only the canvas style counts: the port has no ancestor
      // elements.
      _touchActionNone =
          _canvas.style.touchAction.trim().toLowerCase() == 'none';
    }
    final limitSquared = _slopLimitSquared(event.kind, gestureSettings);
    final hostTouch = _touches[event.pointer] = _HostTouch(event, limitSquared);
    if (_touches.length > _sequenceTouches) {
      _sequenceTouches = _touches.length;
    }
    if (_touchActionNone) {
      // The host handles the down before GestureBinding closes the arena.
      hostTouch.arena = GestureBinding.instance.gestureArena.add(
        event.pointer,
        const _TouchActionClaim(),
      );
      if (_touches.length > 1) {
        // A second finger: a scale recognizer of an ancestor can accept on
        // the change of the span before a finger passes the hit slop.
        _touches.values.forEach(_claim);
      }
    }
    _hostPointers.add(event.pointer);
    // A second touch-like pointer on the host ends the candidate: it stands
    // for the primary pointer of Pointer Events 3, section 4.1.2.
    _endTap();
    // A touch-like down on a host is a second pointer for the route too: it
    // ends the candidate of a finger that is down outside (Chart.js ADR 0037,
    // sections 8 and 9).
    for (final tap in _outsideTaps.values) {
      tap.dispose();
    }
    _outsideTaps.clear();
    if (_touches.length == 1) {
      _tap = _TouchTap(
        event,
        limitSquared: limitSquared,
        onLongPress: _handleLongPress,
      );
    }
    _emit(
      _panned
          ? const ['touchstart']
          : const ['pointerover', 'pointerenter', 'pointerdown', 'touchstart'],
      event.localPosition,
      event,
      touch: true,
    );
  }

  /// A move of a touch-like pointer (Chart.js ADR 0037, section 8; device
  /// check P4, D1 to D3).
  void _handleTouchMove(PointerMoveEvent event) {
    final touch = _touches[event.pointer];
    if (touch == null || _samePoint(touch.last, event)) {
      // P4 D2: Chrome sends no event for a move with no change of the point
      // (passthrough_touch_event_queue.cc, HasPointChanged).
      return;
    }
    touch.last = event;
    if (_touchActionNone) {
      _handleTouchMoveWithoutPan(touch, event);
      return;
    }
    final position = event.localPosition;
    if (_panned) {
      // P4 D3: after the pan, only the touch events go on.
      _emit(const ['touchmove'], position, event, touch: true);
      return;
    }
    // gesture_detector.cc, IsWithinSlopForTap: each pointer against its own
    // down, and any move with more than 2 pointers in the sequence.
    if (_sequenceTouches > 2 ||
        (event.position - touch.down.position).distanceSquared >
            touch.limitSquared) {
      _emit(const ['pointermove', 'touchmove'], position, event, touch: true);
      _beginPan(event);
    } else if (_tap?.pointer == event.pointer) {
      // P4 D1: no touchmove for the tap candidate inside its slop limit
      // (touch_event_manager.cc, the suppression of touchmove).
      _emit(const ['pointermove'], position, event);
    } else {
      _emit(const ['pointermove', 'touchmove'], position, event, touch: true);
    }
  }

  /// A move with a change of the touch-like pointer [touch] in a sequence
  /// with `touch-action: none` (Chart.js ADR 0108). No move begins the pan,
  /// also with more than 2 pointers: the `pointer*` and `touch*` events go
  /// on, and `touchmove` stays cancelable. The first move farther than the
  /// hit slop from the down claims the pointer ([_claim]). The tap candidate
  /// gives only `pointermove` inside its slop limit (P4 D1), and its first
  /// move past the limit ends it: no `click` and no compatibility event.
  void _handleTouchMoveWithoutPan(_HostTouch touch, PointerMoveEvent event) {
    final distanceSquared =
        (event.position - touch.down.position).distanceSquared;
    if (!touch.claimed) {
      // The drag recognizers accept when one axis passes the same slop. The
      // host sees the move first: its entry of the hit path is deeper than
      // the routes of the recognizers, which GestureBinding.handleEvent
      // runs. Thus it wins a tie.
      final slop = computeHitSlop(event.kind, gestureSettings);
      if (distanceSquared > slop * slop) {
        _claim(touch);
      }
    }
    final position = event.localPosition;
    if (_tap?.pointer == event.pointer) {
      if (distanceSquared <= touch.limitSquared) {
        _emit(const ['pointermove'], position, event);
        return;
      }
      _endTap();
    }
    _emit(const ['pointermove', 'touchmove'], position, event, touch: true);
  }

  /// Accepts the gesture arena of [touch] for the host, once (Chart.js ADR
  /// 0108). The recognizers of the ancestors lose the pointer: their drags,
  /// scales and taps. On an open arena, the host is the eager winner, and
  /// the close of the arena resolves it.
  static void _claim(_HostTouch touch) {
    final arena = touch.arena;
    if (arena != null && !touch.claimed) {
      touch.claimed = true;
      arena.resolve(GestureDisposition.accepted);
    }
  }

  /// Gives up the gesture arena of [touch] at its up, its cancel or the end
  /// of the input of the host, unless the host accepted it (Chart.js ADR
  /// 0108). It runs before the sweep of `GestureBinding.handleEvent`. The
  /// sweep gives an unresolved arena to its first member, the host. Thus a
  /// tap of an ancestor inside the slop still wins, as a DOM click of a
  /// `touch-action: none` canvas still bubbles to the ancestors.
  static void _unclaim(_HostTouch touch) {
    final arena = touch.arena;
    touch.arena = null;
    if (arena != null && !touch.claimed) {
      arena.resolve(GestureDisposition.rejected);
    }
  }

  /// The pan begin at the move [event] (P4 D3): Blink cancels each
  /// non-hovering pointer, with `pointercancel`, `pointerout` and
  /// `pointerleave` at the client point (0, 0) (pointer_event_manager.cc,
  /// pointer_event_factory.cc `CreatePointerCancelEvent`). It also ends the
  /// tap candidate, a long-pressed one too.
  void _beginPan(PointerEvent event) {
    _panned = true;
    _endTap();
    final origin = PointerEvent.transformPosition(event.transform, Offset.zero);
    for (final touch in _touches.values) {
      _emit(
        const ['pointercancel', 'pointerout', 'pointerleave'],
        origin,
        touch.last,
        client: Offset.zero,
      );
    }
  }

  /// Whether the move [b] has the point of [a]: the same position,
  /// pressure, radii, orientation and tilt (Chromium
  /// `passthrough_touch_event_queue.cc`, `HasPointChanged`). The position
  /// comes first: a moving pointer stops at the first compare.
  static bool _samePoint(PointerEvent a, PointerEvent b) =>
      a.position == b.position &&
      a.pressure == b.pressure &&
      a.radiusMajor == b.radiusMajor &&
      a.radiusMinor == b.radiusMinor &&
      a.orientation == b.orientation &&
      a.tilt == b.tilt;

  void _handleTouchUp(PointerUpEvent event) {
    final position = event.localPosition;
    final hostTouch = _touches.remove(event.pointer);
    if (hostTouch != null) {
      _unclaim(hostTouch);
    }
    _emit(
      _panned
          ? const ['touchend']
          : const ['pointerup', 'pointerout', 'pointerleave', 'touchend'],
      position,
      event,
      touch: true,
    );
    final tap = _tap;
    if (tap != null && tap.pointer == event.pointer) {
      _endTap();
      if (!tap.longPressed && attached) {
        // A tap: the compatibility mouse events and the click at the tap
        // point (P4 D4 and STN10). Chrome hit-tests the tap there, so a tap
        // point outside the box moves the compatibility mouse off its owner.
        final source = _tapPoint(tap, event);
        final position = globalToLocal(source.position);
        if (size.contains(position)) {
          _takeMouse(source);
          _emit(
            const ['mousemove', 'mousedown', 'mouseup', 'click'],
            position,
            source,
            compat: true,
          );
        } else if (_mouseOwner != null) {
          _releaseMouse(source, emit: true);
        }
      }
    }
    // The route has no candidate for this pointer: the pointer was in
    // _hostPointers when the route saw its down.
    _hostPointers.remove(event.pointer);
    // The click of the tap has the id of its pointer.
    _domPointerIds.remove(event.pointer);
  }

  /// The long press of the host candidate [tap]: the compatibility mouse
  /// comes over the host at the down position while the pointer is down
  /// (P4 D4; gesture_detector.cc uses the down event).
  void _handleLongPress(_TouchTap tap) {
    if (!identical(tap, _tap) || !attached) {
      return;
    }
    final down = tap.down;
    _takeMouse(down);
    _emit(
      const ['mousemove'],
      globalToLocal(down.position),
      down,
      compat: true,
    );
  }

  void _endTap() {
    _tap?.dispose();
    _tap = null;
  }

  /// Ends the input state of the host at a detach, a dispose or a canvas
  /// swap. An owner of the compatibility mouse ends without an event, as a
  /// DOM element that leaves the document gets no `mouseout`. The host gives
  /// up each gesture arena that it did not accept.
  void _endInput() {
    _endTap();
    _panned = false;
    _sequenceTouches = 0;
    _touchActionNone = false;
    _clickPointer = null;
    _mouseButtons.clear();
    _hostPointers.removeAll(_touches.keys);
    _touches.keys.forEach(_domPointerIds.remove);
    _touches.values.forEach(_unclaim);
    _touches.clear();
    if (identical(_mouseOwner, this)) {
      _releaseMouse(null, emit: false);
    }
  }

  // The compatibility mouse (Chart.js ADR 0037, section 9).

  /// The host that the compatibility mouse is over, or null.
  static RenderChartHost? _mouseOwner;

  /// The pointer of the tap or the long press that made the owner. The
  /// route sees the up of that tap, because it starts in the dispatch of
  /// that up (`PointerRouter.route` copies the global routes after the hit
  /// path ran). It ignores the pointer.
  static int? _ownerPointer;

  /// The touch-like pointers that are down on a host. `GestureBinding` calls
  /// the hit path before the route, so the host adds a pointer at its down
  /// before the route sees it.
  static final Set<int> _hostPointers = {};

  /// The touch-like pointers outside the hosts that the route saw go down.
  static final Set<int> _outsidePointers = {};

  /// The tap candidates of the route, by pointer: at most one.
  static final Map<int, _TouchTap> _outsideTaps = {};

  static bool _routeAdded = false;

  /// The host that the compatibility mouse is over, or null.
  @visibleForTesting
  static RenderChartHost? get debugCompatibilityMouseOwner => _mouseOwner;

  /// Makes this host the owner of the compatibility mouse at the tap or the
  /// long press [source]. The old owner first gets `mouseout` and
  /// `mouseleave`. This host gets `mouseover` and `mouseenter` when the
  /// compatibility mouse is not over it.
  void _takeMouse(PointerEvent source) {
    if (!identical(_mouseOwner, this)) {
      if (_mouseOwner != null) {
        _releaseMouse(source, emit: true);
      }
      _mouseOwner = this;
      if (!_routeAdded) {
        _routeAdded = true;
        GestureBinding.instance.pointerRouter.addGlobalRoute(_route);
      }
      // The position of the source in the coordinates of the host at the
      // time of the event (the tap point: P4 D4 and STN10).
      _emit(
        const ['mouseover', 'mouseenter'],
        globalToLocal(source.position),
        source,
        compat: true,
      );
    }
    _ownerPointer = source.pointer;
  }

  /// Ends the owner of the compatibility mouse and removes the route. With
  /// [emit], an attached old owner gets `mouseout` and `mouseleave` at the
  /// position of [source], in its own coordinates.
  static void _releaseMouse(PointerEvent? source, {required bool emit}) {
    final owner = _mouseOwner;
    _mouseOwner = null;
    _ownerPointer = null;
    for (final tap in _outsideTaps.values) {
      tap.dispose();
    }
    _outsideTaps.clear();
    _outsidePointers.clear();
    if (_routeAdded) {
      _routeAdded = false;
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_route);
    }
    if (emit && source != null && owner != null && owner.attached) {
      owner._emit(
        const ['mouseout', 'mouseleave'],
        owner.globalToLocal(source.position),
        source,
        compat: true,
      );
    }
  }

  /// The global pointer route while an owner exists: it applies the tap
  /// rule to the touch-like pointers that do not go down on a host. A tap or
  /// a long press of such a pointer moves the compatibility mouse off the
  /// owner, at its tap point or its down position (P4 D4 and STN10). A drag
  /// or a scroll gives nothing.
  static void _route(PointerEvent event) {
    final pointer = event.pointer;
    // A real mouse keeps the MouseTracker path.
    if (_isMouseKind(event.kind) ||
        pointer == _ownerPointer ||
        _hostPointers.contains(pointer)) {
      return;
    }
    switch (event) {
      case PointerDownEvent():
        if (_outsidePointers.isEmpty && _hostPointers.isEmpty) {
          _outsideTaps[pointer] = _TouchTap(
            event,
            limitSquared: _slopLimitSquared(
              event.kind,
              _mouseOwner?.gestureSettings,
            ),
            onLongPress: _handleOutsideLongPress,
          );
        } else {
          // A second touch-like pointer is not the primary pointer, and it
          // ends the candidate of the first one.
          for (final tap in _outsideTaps.values) {
            tap.dispose();
          }
          _outsideTaps.clear();
        }
        _outsidePointers.add(pointer);
      case PointerMoveEvent():
        final tap = _outsideTaps[pointer];
        if (tap != null && !tap.move(event)) {
          _outsideTaps.remove(pointer);
          tap.dispose();
        }
      case PointerUpEvent():
        _outsidePointers.remove(pointer);
        final tap = _outsideTaps.remove(pointer);
        if (tap != null) {
          tap.dispose();
          if (!tap.longPressed) {
            _releaseMouse(_tapPoint(tap, event), emit: true);
          }
        }
      case PointerCancelEvent():
        _outsidePointers.remove(pointer);
        _outsideTaps.remove(pointer)?.dispose();
      default:
        break;
    }
  }

  /// The event at the tap point of the tap [tap] that ends with the up
  /// [up]: the up for a stylus and an inverted stylus, else the down.
  /// Chrome on Android gives a pen and an eraser tap no touch adjustment
  /// (Blink `event_handler.cc:1788-1797`). Thus their tap is at the point of
  /// the up event (`gesture_detector.cc:400-417`,
  /// `gesture_provider.cc:693-700`; device check P4, row STN10). The touch
  /// adjustment of a finger keeps its tap at the down point (P4 D4). A long
  /// press is at the down point for each kind (`gesture_detector.cc:531`).
  static PointerEvent _tapPoint(_TouchTap tap, PointerUpEvent up) =>
      switch (up.kind) {
        PointerDeviceKind.stylus || PointerDeviceKind.invertedStylus => up,
        _ => tap.down,
      };

  static void _handleOutsideLongPress(_TouchTap tap) {
    if (identical(_outsideTaps[tap.pointer], tap)) {
      _releaseMouse(tap.down, emit: true);
    }
  }

  // The hovering pointers that MouseTracker does not track.

  static const List<String> _enterTypes = [
    'pointerover',
    'pointerenter',
    'mouseover',
    'mouseenter',
  ];

  static const List<String> _exitTypes = [
    'pointerout',
    'pointerleave',
    'mouseout',
    'mouseleave',
  ];

  /// Whether the host tracks the hover of [kind] itself and ignores the
  /// enter and exit of `MouseTracker`: each kind but the mouse.
  /// `MouseTracker` handles only the mouse and the stylus
  /// (`mouse_tracker.dart`), and it also reports the enter and exit of a
  /// stylus at a contact with no hover (device check P4, row ST1).
  static bool _isUntrackedHoverKind(PointerDeviceKind kind) =>
      kind != PointerDeviceKind.mouse;

  /// Whether [kind] gives the mouse rows (Chart.js ADR 0037, section 6):
  /// the mouse and the trackpad. All other kinds in contact are touch-like,
  /// as in Chrome on Android (device check P4, D5).
  static bool _isMouseKind(PointerDeviceKind kind) =>
      kind == PointerDeviceKind.mouse || kind == PointerDeviceKind.trackpad;

  /// The hovering devices of an untracked kind that are over the host, with
  /// the last hover event of each device that hit the host (its
  /// untransformed event). The key is the device, as in `MouseTracker`: the
  /// engine gives each hover event the pointer id 0
  /// (`pointer_data_packet_converter.cc` does not change the id of a hover,
  /// and `AndroidTouchProcessor` sends 0). Thus a hovering mouse and a
  /// hovering stylus share the pointer id, and its route gets the events of
  /// both.
  final Map<int, PointerEvent> _hoverDevices = {};

  void _handleUntrackedHoverOver(PointerHoverEvent event) {
    final last = _hoverDevices[event.device];
    final original = event.original ?? event;
    if (last != null && last.pointer == event.pointer) {
      _hoverDevices[event.device] = original;
      return;
    }
    // The devices with the same pointer id share one route.
    final routed = _hoverDevices.values.any((e) => e.pointer == event.pointer);
    _hoverDevices[event.device] = original;
    if (last != null) {
      // A new pointer id of the same device. The engine does not give it.
      _removeHoverRoute(last.pointer);
    }
    if (!routed) {
      // The route gets the later events of the pointer id, also the hover
      // events that do not hit the host and the removal.
      GestureBinding.instance.pointerRouter.addRoute(
        event.pointer,
        _handleUntrackedHoverRoute,
      );
    }
    if (last == null) {
      _emit(_enterTypes, event.localPosition, event);
    }
  }

  void _handleUntrackedHoverRoute(PointerEvent event) {
    final last = _hoverDevices[event.device];
    if (last == null) {
      // Another device with the same pointer id, for example a mouse.
      return;
    }
    if (event is PointerHoverEvent) {
      // handleEvent runs before the route for a hover that hits the host.
      if (identical(event.original ?? event, last)) {
        return;
      }
    } else if (event is! PointerRemovedEvent) {
      return;
    }
    _removeHoverDevice(event.device);
    _emit(
      _exitTypes,
      attached ? globalToLocal(event.position) : event.localPosition,
      event,
    );
    _domPointerIds.remove(event.pointer);
  }

  void _removeHoverDevice(int device) {
    final last = _hoverDevices.remove(device);
    if (last != null) {
      _removeHoverRoute(last.pointer);
    }
  }

  /// Removes the route of [pointer] when no hovering device has that id.
  void _removeHoverRoute(int pointer) {
    if (!_hoverDevices.values.any((e) => e.pointer == pointer)) {
      GestureBinding.instance.pointerRouter.removeRoute(
        pointer,
        _handleUntrackedHoverRoute,
      );
    }
  }

  void _clearHoverPointers() {
    for (final event in _hoverDevices.values) {
      _domPointerIds.remove(event.pointer);
    }
    List.of(_hoverDevices.keys).forEach(_removeHoverDevice);
  }

  // MouseTrackerAnnotation.

  bool _validForMouseTracker = true;

  @override
  bool get validForMouseTracker => _validForMouseTracker;

  @override
  MouseCursor get cursor => MouseCursor.defer;

  @override
  PointerEnterEventListener? get onEnter => _handleEnter;

  @override
  PointerExitEventListener? get onExit => _handleExit;

  void _handleEnter(PointerEnterEvent event) {
    if (_isUntrackedHoverKind(event.kind)) {
      return;
    }
    _emit(_enterTypes, event.localPosition, event);
  }

  void _handleExit(PointerExitEvent event) {
    if (_isUntrackedHoverKind(event.kind)) {
      return;
    }
    _emit(_exitTypes, event.localPosition, event);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('devicePixelRatio', devicePixelRatio))
      ..add(
        FlagProperty('tickerEnabled', value: tickerEnabled, ifFalse: 'muted'),
      )
      ..add(FlagProperty('connected', value: isConnected, ifTrue: 'connected'))
      ..add(DiagnosticsProperty<Size>('displaySize', displaySize));
  }
}

/// Chromium `gesture_detector.cc` `kSlopEpsilon` (155.0.8059.84, line 484):
/// a move ends a tap and begins the pan when it is farther than the slop
/// plus 0.05 logical pixels.
const double _slopEpsilon = 0.05;

/// Chromium `gesture_configuration_android.cc` (155.0.8059.84, lines 53-56):
/// the stylus slop is 1.5 times the touch slop.
const double _stylusSlopFactor = 1.5;

/// The square of the slop limit of a touch-like pointer of [kind] (Chart.js
/// ADR 0037, section 8): the touch slop of [settings]
/// (`computeHitSlop`), times 1.5 for a stylus, plus 0.05. An inverted
/// stylus has the touch slop, as an Android eraser in Chromium.
double _slopLimitSquared(
  PointerDeviceKind kind,
  DeviceGestureSettings? settings,
) {
  final touch = computeHitSlop(PointerDeviceKind.touch, settings);
  final limit =
      (kind == PointerDeviceKind.stylus ? touch * _stylusSlopFactor : touch) +
      _slopEpsilon;
  return limit * limit;
}

/// The modifier keys of an event: `ctrlKey`, `altKey`, `shiftKey` and
/// `metaKey`.
typedef _Modifiers = ({bool ctrl, bool alt, bool shift, bool meta});

/// [modifiers] with `ctrlKey` also when [ctrl] is true: the `wheel` of a
/// trackpad pinch (Chart.js ADR 0137).
_Modifiers _withCtrl(_Modifiers modifiers, bool ctrl) => ctrl
    ? (
        ctrl: true,
        alt: modifiers.alt,
        shift: modifiers.shift,
        meta: modifiers.meta,
      )
    : modifiers;

/// A trackpad gesture of the host (Chart.js ADR 0137): its entry in the
/// gesture arena, whether the host took it, and the last scale.
final class _PanZoom(final GestureArenaEntry arena) {
  /// Whether the host accepted [arena].
  bool claimed = false;

  /// The scale of the last step.
  double scale = 1;
}

/// The member of the gesture arena of a trackpad gesture of a host
/// (Chart.js ADR 0137). The host reads the raw pan-zoom events, so a win or
/// a loss changes nothing for it.
final class const _TrackpadClaim() implements GestureArenaMember {
  @override
  void acceptGesture(int pointer) {}

  @override
  void rejectGesture(int pointer) {}

  @override
  String toString() => 'RenderChartHost (trackpad)';
}

/// The modifier keys that are down now, from `HardwareKeyboard`. Flutter
/// updates the pressed keys before it calls the key handlers, so the down of
/// Control has `ctrlKey` true and its up false, as in the DOM.
_Modifiers _modifiers() {
  final keyboard = HardwareKeyboard.instance;
  return (
    ctrl: keyboard.isControlPressed,
    alt: keyboard.isAltPressed,
    shift: keyboard.isShiftPressed,
    meta: keyboard.isMetaPressed,
  );
}

/// One touch-like pointer that is down on the host (Chart.js ADR 0037,
/// section 8).
final class _HostTouch(
  /// The down event.
  final PointerDownEvent down,

  /// The square of the slop limit of the pointer.
  final double limitSquared,
) {
  /// The last event of the pointer that gave DOM events: the down or a move.
  PointerEvent last = down;

  /// The entry of the host in the gesture arena of the pointer, in a
  /// sequence with `touch-action: none` (Chart.js ADR 0108). Null in the
  /// other sequences, and after the host gave up the arena.
  GestureArenaEntry? arena;

  /// Whether the host accepted [arena].
  bool claimed = false;
}

/// The member of the gesture arena with which a host claims its touch-like
/// pointers in a sequence with `touch-action: none` (Chart.js ADR 0108). The
/// host reads the raw pointer events in `handleEvent`, so a win or a loss
/// changes nothing for it: the claim only takes the pointer from the
/// recognizers of the ancestors, as the browser does not pan or zoom such an
/// element.
///
/// Not an `EagerGestureRecognizer`: it accepts at the down, and thus it also
/// takes the taps of a `GestureDetector`, an `InkWell` or a `ListTile`
/// ancestor. In the DOM, `touch-action` stops only the pan and the zoom of
/// the browser.
final class const _TouchActionClaim() implements GestureArenaMember {
  @override
  void acceptGesture(int pointer) {}

  @override
  void rejectGesture(int pointer) {}

  @override
  String toString() => 'RenderChartHost (touch-action: none)';
}

/// One touch-like pointer that can still end as a tap (Chart.js ADR 0037,
/// section 8). The host and the route of the compatibility mouse use the
/// same rule: a move farther than the slop limit from the down ends the
/// candidate, and a timer of `kLongPressTimeout` makes it a long press.
final class _TouchTap(
  /// The down event. A long press, and a tap of a kind other than the
  /// stylus and the inverted stylus, give their compatibility events at its
  /// position (device check P4, D4 and STN10; `RenderChartHost._tapPoint`).
  final PointerDownEvent down, {

  /// The square of the slop limit, in logical pixels.
  required final double limitSquared,
  required void Function(_TouchTap tap) onLongPress,
}) {
  this {
    _timer = Timer(kLongPressTimeout, () {
      longPressed = true;
      onLongPress(this);
    });
  }

  /// The pointer id.
  final int pointer = down.pointer;

  /// Whether the pointer was held for `kLongPressTimeout`.
  bool longPressed = false;

  late final Timer _timer;

  /// False when the move [event] ends the candidate: the pointer is farther
  /// than the slop limit from its down. The route uses it.
  bool move(PointerEvent event) =>
      (event.position - down.position).distanceSquared <= limitSquared;

  /// Cancels the long-press timer.
  void dispose() => _timer.cancel();
}
