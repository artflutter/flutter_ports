// Original code, not ported from Chart.js: the internal chart host.

/// The internal chart host (Chart.js ADR 0037, porting-flow.md 2.7): the
/// render object that shows a canvas element of the canvas layer, and the
/// DOM parts of `platform.dom.js` that the host stands in for.
///
/// - [ChartHost] is a `LeafRenderObjectWidget`, and [RenderChartHost] its
///   `RenderBox`. The library is not exported. The public widget of phase 9
///   builds on it.
/// - The host is the parent node of its canvas (`CanvasNode.parentNode`)
///   and its container ([CanvasContainer]): the container size is the max
///   size of its incoming constraints.
/// - The event listeners of a canvas ([addCanvasEventListener]) stand in for
///   the `EventTarget` of the DOM canvas. The host makes [NativeEvent]s from
///   Flutter pointer events and sends them to these listeners.
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
/// to the DOM event names of Chrome by `PointerDeviceKind`. It claims
/// nothing in the gesture arena. Thus parent scrollables keep their drags,
/// and tappable ancestors (`GestureDetector.onTap`, `InkWell`,
/// `ListTile.onTap`) keep their taps, as a DOM click also reaches them by
/// bubbling.
/// - The click rule (section 7): a mouse-like down with the primary button
///   on the host, then the up of that pointer inside the box, gives `click`
///   after `mouseup`. The distance between the down and the up has no limit.
/// - The tap rule (section 8): one touch pointer on the host, no move
///   farther than the touch slop of `MediaQuery.gestureSettings`, no cancel,
///   and the up before `kLongPressTimeout`. A touch gives the boundary
///   events `pointerover`, `pointerenter`, `pointerout` and `pointerleave`
///   around its down and its up. A tap then gives the compatibility mouse
///   events `mouseover` and `mouseenter` (only when the compatibility mouse
///   is not over the host), `mousemove`, `mousedown`, `mouseup` and `click`,
///   at the up position. A touch held past `kLongPressTimeout` within the
///   slop gives `mouseover`, `mouseenter` and `mousemove` while the finger
///   is down. Its lift gives no compatibility event and no `click`.
/// - The compatibility mouse (section 9): one for each isolate, as a browser
///   has one. A tap or a long press on a host makes that host the owner.
///   While an owner exists, one global pointer route watches the touch
///   pointers of the app. A tap or a long press that does not hit a host
///   gives the owner `mouseout` and `mouseleave`. Then the owner ends, and
///   the route goes. The detach or the dispose of the owner ends it without
///   an event.
///
/// A mouse has no implicit capture: a mouse move, up or cancel outside the
/// box gives no event. `MouseTracker` reports enter and exit only for the
/// mouse and the stylus. For the other hovering kinds (the inverted stylus)
/// the host tracks the hovering pointers itself and gives the enter and
/// exit events.
library;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/platform/native_event.dart';

// The EventTarget of the canvas.

/// The listeners of each canvas, by DOM event type: the `EventTarget` part of
/// the DOM canvas element.
final Expando<Map<String, List<void Function(NativeEvent)>>> _eventListeners =
    Expando('canvas event listeners');

/// `canvas.addEventListener(type, listener)`.
///
/// As in the DOM, a listener that the canvas already has for [type] is not
/// added again. The listeners stay on the canvas when no host shows it.
void addCanvasEventListener(
  HTMLCanvasElement canvas,
  String type,
  void Function(NativeEvent) listener,
) {
  final listeners = (_eventListeners[canvas] ??= {}).putIfAbsent(
    type,
    () => [],
  );
  if (!listeners.contains(listener)) {
    listeners.add(listener);
  }
}

/// `canvas.removeEventListener(type, listener)`.
void removeCanvasEventListener(
  HTMLCanvasElement canvas,
  String type,
  void Function(NativeEvent) listener,
) {
  final byType = _eventListeners[canvas];
  final listeners = byType?[type];
  if (listeners == null) {
    return;
  }
  listeners.remove(listener);
  if (listeners.isEmpty) {
    byType!.remove(type);
  }
}

/// Whether [canvas] has a listener for [type].
bool hasCanvasEventListener(HTMLCanvasElement canvas, String type) =>
    _eventListeners[canvas]?.containsKey(type) ?? false;

/// `canvas.dispatchEvent(event)`: calls the listeners of `event.type` in
/// the order of registration. A listener that a listener adds or removes
/// takes effect with the next event.
void dispatchCanvasEvent(HTMLCanvasElement canvas, NativeEvent event) {
  final listeners = _eventListeners[canvas]?[event.type];
  if (listeners == null) {
    return;
  }
  for (final listener in List.of(listeners)) {
    listener(event);
  }
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
final class CanvasMutationObserver {
  /// Creates an observer that calls [callback] with the new attached state.
  CanvasMutationObserver(this.callback);

  /// The callback of the observer.
  final void Function({required bool connected}) callback;

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
final class ContainerResizeObserver {
  /// Creates an observer with the two callbacks.
  ContainerResizeObserver({
    required this.onResize,
    required this.onDevicePixelRatio,
  });

  /// The `ResizeObserver` callback, with `contentRect.width` and
  /// `contentRect.height`.
  final void Function(double width, double height) onResize;

  /// The device pixel ratio callback.
  final void Function(double devicePixelRatio) onDevicePixelRatio;

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
class ChartHost extends LeafRenderObjectWidget {
  /// Creates a host for [canvas].
  const ChartHost({
    required this.canvas,
    this.onTickerModeChanged,
    super.key,
  });

  /// The canvas element that the host shows.
  final UiCanvasElement canvas;

  /// Called when the `TickerMode` of the host changes, with the new
  /// `enabled` value. `core.animator` mutes the chart while it is false
  /// (Chart.js ADR 0016, decision 7).
  final ValueChanged<bool>? onTickerModeChanged;

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
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderChartHost renderObject) {
    renderObject
      ..canvas = canvas
      ..onTickerModeChanged = onTickerModeChanged
      ..devicePixelRatio = _devicePixelRatio(context)
      ..tickerEnabled = TickerMode.valuesOf(context).enabled
      ..gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
  }
}

/// The render object of [ChartHost].
///
/// It is a repaint boundary: a chart frame repaints only the host layer.
class RenderChartHost extends RenderBox
    implements CanvasContainer, MouseTrackerAnnotation {
  /// Creates the render object of a host for [canvas].
  RenderChartHost({
    required UiCanvasElement canvas,
    required double devicePixelRatio,
    bool tickerEnabled = true,
    this.gestureSettings,
    this.onTickerModeChanged,
  }) : _canvas = canvas,
       // The field has a setter with side effects.
       // ignore: prefer_initializing_formals
       _devicePixelRatio = devicePixelRatio,
       // The field has a setter with side effects.
       // ignore: prefer_initializing_formals
       _tickerEnabled = tickerEnabled {
    _show(canvas);
  }

  /// The canvas element that the host shows.
  UiCanvasElement get canvas => _canvas;
  UiCanvasElement _canvas;
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
  double _devicePixelRatio;
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
  bool _tickerEnabled;
  set tickerEnabled(bool value) {
    if (value == _tickerEnabled) {
      return;
    }
    _tickerEnabled = value;
    onTickerModeChanged?.call(value);
  }

  /// Called when [tickerEnabled] changes.
  ValueChanged<bool>? onTickerModeChanged;

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
    _canvas.getContext2d().paint(context.canvas, offset, scaleX, scaleY);
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
    _resizeObservers.clear();
    _pendingFirstResize.clear();
    _hide(_canvas);
    super.dispose();
  }

  // Input.

  @override
  bool hitTestSelf(Offset position) => true;

  /// The gesture settings of the view: the touch slop of the tap rule
  /// (Chart.js ADR 0037, section 8). Null gives `kTouchSlop`.
  DeviceGestureSettings? gestureSettings;

  /// The touch pointers that are down on the host, by pointer id: the DOM
  /// `targetTouches` of the canvas.
  final SplayTreeMap<int, Offset> _touches = SplayTreeMap();

  List<NativeTouch> get _touchList => [
    for (final MapEntry(:key, :value) in _touches.entries)
      (identifier: key, x: value.dx, y: value.dy),
  ];

  /// The pointer of a mouse-like down with the primary button on the host,
  /// or null: the DOM click rule (Chart.js ADR 0037, section 7).
  int? _clickPointer;

  /// The tap candidate of the host, or null (Chart.js ADR 0037, section 8).
  _TouchTap? _tap;

  bool _has(String type) => hasCanvasEventListener(_canvas, type);

  /// Sends the events [types] at [position] to the canvas listeners.
  void _emit(
    List<String> types,
    Offset position,
    Object? source, {
    bool touch = false,
  }) {
    List<NativeTouch>? touches;
    for (final type in types) {
      if (!_has(type)) {
        continue;
      }
      final isTouchEvent = touch && type.startsWith('touch');
      dispatchCanvasEvent(
        _canvas,
        NativeEvent(
          type: type,
          // A TouchEvent has no offsetX and offsetY.
          offsetX: isTouchEvent ? double.nan : position.dx,
          offsetY: isTouchEvent ? double.nan : position.dy,
          touches: isTouchEvent ? (touches ??= _touchList) : const [],
          target: _canvas,
          source: source,
        ),
      );
    }
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    final position = event.localPosition;
    final touch = event.kind == PointerDeviceKind.touch;
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
          _emit(const ['pointerdown', 'mousedown'], position, event);
        }
      case PointerMoveEvent():
        if (touch) {
          _touches[event.pointer] = position;
          final tap = _tap;
          if (tap != null && tap.pointer == event.pointer && !tap.move(event)) {
            _endTap();
          }
          _emit(
            const ['pointermove', 'touchmove'],
            position,
            event,
            touch: true,
          );
        } else if (size.contains(position)) {
          // A mouse has no implicit capture: the canvas gets no move outside
          // its box.
          _emit(const ['pointermove', 'mousemove'], position, event);
        }
      case PointerUpEvent():
        if (touch) {
          _handleTouchUp(event);
        } else {
          final click = _clickPointer == event.pointer;
          _clickPointer = null;
          if (size.contains(position)) {
            // The up goes to the hit path of the down, but a mouse has no
            // implicit capture: the canvas gets no up outside its box. An up
            // outside the box gives no click, because the DOM sends the
            // click to the common ancestor.
            _emit(const ['pointerup', 'mouseup'], position, event);
            if (click) {
              _emit(const ['click'], position, event);
            }
          }
        }
      case PointerCancelEvent():
        if (touch) {
          _touches.remove(event.pointer);
          if (_tap?.pointer == event.pointer) {
            _endTap();
          }
          _hostPointers.remove(event.pointer);
          _emit(
            const [
              'pointercancel',
              'pointerout',
              'pointerleave',
              'touchcancel',
            ],
            position,
            event,
            touch: true,
          );
        } else {
          _clickPointer = null;
          if (size.contains(position)) {
            _emit(const ['pointercancel'], position, event);
          }
        }
      case PointerScrollEvent():
        _emit(const ['wheel'], position, event);
      default:
        break;
    }
  }

  void _handleTouchDown(PointerDownEvent event) {
    _touches[event.pointer] = event.localPosition;
    _hostPointers.add(event.pointer);
    // A second touch pointer on the host ends the candidate: it stands for
    // the primary pointer of Pointer Events 3, section 4.1.2.
    _endTap();
    // A touch down on a host is a second touch pointer for the route too: it
    // ends the candidate of a finger that is down outside (Chart.js ADR 0037,
    // sections 8 and 9).
    for (final tap in _outsideTaps.values) {
      tap.dispose();
    }
    _outsideTaps.clear();
    if (_touches.length == 1) {
      _tap = _TouchTap(
        event,
        slop: computeHitSlop(PointerDeviceKind.touch, gestureSettings),
        onLongPress: _handleLongPress,
      );
    }
    _emit(
      const ['pointerover', 'pointerenter', 'pointerdown', 'touchstart'],
      event.localPosition,
      event,
      touch: true,
    );
  }

  void _handleTouchUp(PointerUpEvent event) {
    final position = event.localPosition;
    _touches.remove(event.pointer);
    _emit(
      const ['pointerup', 'pointerout', 'pointerleave', 'touchend'],
      position,
      event,
      touch: true,
    );
    final tap = _tap;
    if (tap != null && tap.pointer == event.pointer) {
      _endTap();
      if (!tap.longPressed && attached) {
        // A tap: the compatibility mouse events and the click, at the up
        // position (Touch Events, "Interaction with Mouse Events and click").
        _takeMouse(event);
        _emit(
          const ['mousemove', 'mousedown', 'mouseup', 'click'],
          position,
          event,
        );
      }
    }
    // The route has no candidate for this pointer: the pointer was in
    // _hostPointers when the route saw its down.
    _hostPointers.remove(event.pointer);
  }

  /// The long press of the host candidate [tap]: the compatibility mouse
  /// comes over the host while the finger is down.
  void _handleLongPress(_TouchTap tap) {
    if (!identical(tap, _tap) || !attached) {
      return;
    }
    final last = tap.last;
    _takeMouse(last);
    _emit(const ['mousemove'], last.localPosition, last);
  }

  void _endTap() {
    _tap?.dispose();
    _tap = null;
  }

  /// Ends the input state of the host at a detach, a dispose or a canvas
  /// swap. An owner of the compatibility mouse ends without an event, as a
  /// DOM element that leaves the document gets no `mouseout`.
  void _endInput() {
    _endTap();
    _clickPointer = null;
    _hostPointers.removeAll(_touches.keys);
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

  /// The touch pointers that are down on a host. `GestureBinding` calls the
  /// hit path before the route, so the host adds a pointer at its down
  /// before the route sees it.
  static final Set<int> _hostPointers = {};

  /// The touch pointers outside the hosts that the route saw go down.
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
      _emit(const ['mouseover', 'mouseenter'], source.localPosition, source);
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
      );
    }
  }

  /// The global pointer route while an owner exists: it applies the tap
  /// rule to the touch pointers that do not go down on a host. A tap or a
  /// long press of such a pointer moves the compatibility mouse off the
  /// owner. A drag or a scroll gives nothing.
  static void _route(PointerEvent event) {
    final pointer = event.pointer;
    // A real mouse keeps the MouseTracker path.
    if (event.kind != PointerDeviceKind.touch ||
        pointer == _ownerPointer ||
        _hostPointers.contains(pointer)) {
      return;
    }
    switch (event) {
      case PointerDownEvent():
        if (_outsidePointers.isEmpty && _hostPointers.isEmpty) {
          _outsideTaps[pointer] = _TouchTap(
            event,
            slop: computeHitSlop(
              PointerDeviceKind.touch,
              _mouseOwner?.gestureSettings,
            ),
            onLongPress: _handleOutsideLongPress,
          );
        } else {
          // A second touch pointer is not the primary pointer, and it ends
          // the candidate of the first one.
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
            _releaseMouse(event, emit: true);
          }
        }
      case PointerCancelEvent():
        _outsidePointers.remove(pointer);
        _outsideTaps.remove(pointer)?.dispose();
      default:
        break;
    }
  }

  static void _handleOutsideLongPress(_TouchTap tap) {
    if (identical(_outsideTaps[tap.pointer], tap)) {
      _releaseMouse(tap.last, emit: true);
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

  /// Whether `MouseTracker` skips the enter and exit of [kind]: it handles
  /// only the mouse and the stylus (`mouse_tracker.dart`).
  static bool _isUntrackedHoverKind(PointerDeviceKind kind) =>
      kind != PointerDeviceKind.mouse && kind != PointerDeviceKind.stylus;

  /// The hovering pointers of an untracked kind that are over the host, with
  /// the last hover event that hit the host (its untransformed event).
  final Map<int, PointerEvent> _hoverPointers = {};

  void _handleUntrackedHoverOver(PointerHoverEvent event) {
    final original = event.original ?? event;
    final isNew = !_hoverPointers.containsKey(event.pointer);
    _hoverPointers[event.pointer] = original;
    if (isNew) {
      // The route gets the later events of the pointer, also the hover
      // events that do not hit the host and the removal.
      GestureBinding.instance.pointerRouter.addRoute(
        event.pointer,
        _handleUntrackedHoverRoute,
      );
      _emit(_enterTypes, event.localPosition, event);
    }
  }

  void _handleUntrackedHoverRoute(PointerEvent event) {
    if (event is PointerHoverEvent) {
      // handleEvent runs before the route for a hover that hits the host.
      if (identical(event.original ?? event, _hoverPointers[event.pointer])) {
        return;
      }
    } else if (event is! PointerRemovedEvent) {
      return;
    }
    _removeHoverPointer(event.pointer);
    _emit(
      _exitTypes,
      attached ? globalToLocal(event.position) : event.localPosition,
      event,
    );
  }

  void _removeHoverPointer(int pointer) {
    if (_hoverPointers.remove(pointer) != null) {
      GestureBinding.instance.pointerRouter.removeRoute(
        pointer,
        _handleUntrackedHoverRoute,
      );
    }
  }

  void _clearHoverPointers() {
    List.of(_hoverPointers.keys).forEach(_removeHoverPointer);
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
    _emit(_enterTypes, event.localPosition, event);
  }

  void _handleExit(PointerExitEvent event) {
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

/// One touch pointer that can still end as a tap (Chart.js ADR 0037,
/// section 8). The host and the route of the compatibility mouse use the
/// same rule: a move farther than [slop] from the down ends the candidate,
/// and a timer of `kLongPressTimeout` makes it a long press.
final class _TouchTap {
  _TouchTap(
    PointerDownEvent down, {
    required this.slop,
    required void Function(_TouchTap tap) onLongPress,
  }) : pointer = down.pointer,
       _downPosition = down.position,
       last = down {
    _timer = Timer(kLongPressTimeout, () {
      longPressed = true;
      onLongPress(this);
    });
  }

  /// The pointer id.
  final int pointer;

  /// The global position of the down.
  final Offset _downPosition;

  /// The touch slop, in logical pixels.
  final double slop;

  /// The last event of the pointer: the down or a move.
  PointerEvent last;

  /// Whether the pointer was held for `kLongPressTimeout`.
  bool longPressed = false;

  late final Timer _timer;

  /// Records the move [event]. False when the move ends the candidate: the
  /// pointer is farther than [slop] from its down, the rule of
  /// `PrimaryPointerGestureRecognizer`.
  bool move(PointerEvent event) {
    last = event;
    return (event.position - _downPosition).distance <= slop;
  }

  /// Cancels the long-press timer.
  void dispose() => _timer.cancel();
}
