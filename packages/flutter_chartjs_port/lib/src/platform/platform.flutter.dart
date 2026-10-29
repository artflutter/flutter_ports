// Original code, not ported from Chart.js: it replaces platform.dom.js.

/// The Flutter platform (Chart.js ADR 0037, porting-flow.md 2.7). It
/// replaces `src/platform/platform.dom.js`: `parity.md` gives that file the
/// status `replaced`.
///
/// The file keeps the upstream structure and names. Each declaration names
/// the `platform.dom.js` lines that it replaces. The DOM parts map to the
/// internal chart host of `chart_host.dart`:
/// - The canvas element is a `UiCanvasElement` of the canvas layer. While a
///   [RenderChartHost] shows it, its parent node is the host
///   (`getParentNode` of `helpers.dom.dart`).
/// - `canvas.addEventListener` is [addCanvasEventListener]: the host sends
///   the [NativeEvent]s that it makes from Flutter pointer events. The
///   listener options `{passive: true}` have no port: the host never claims
///   a pointer for an event listener.
/// - The `MutationObserver` of the document is a [CanvasMutationObserver]
///   of the canvas. The host reports a net change of the attached state
///   once, after the frame of the change. The first layout of the host
///   reports the attach at once, so that the chart has its size before the
///   first paint.
/// - The `ResizeObserver` of the container is a [ContainerResizeObserver].
///   The host reports a change of its incoming constraints, and a change of
///   its device pixel ratio, which replaces the window `resize` listener and
///   its global map (`platform.dom.js:161-189`).
/// - The scrollbar step of `platform.dom.js:198-209` has no port: a Flutter
///   `Scrollbar` paints over its child and takes no layout width.
///
/// The library is not a pure layer: [throttled] and the host import
/// `package:flutter`.
library;

import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isNullOrUndef;
import 'package:flutter_chartjs_port/src/helpers/helpers.dom.dart'
    show getParentNode, getRelativePosition, readUsedSize;
// The method FlutterPlatform.getMaximumSize has the name of the helper.
import 'package:flutter_chartjs_port/src/helpers/helpers.dom.dart'
    as helpers
    show getMaximumSize;
import 'package:flutter_chartjs_port/src/helpers/helpers.extras.dart'
    show throttled;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_chartjs_port/src/platform/platform.base.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// platform.dom.js:14 `EXPANDO_KEY`, the property `$chartjs` of the canvas.
///
/// The port keeps the initial values of a canvas in an [Expando] of that
/// name.
final Expando<_ChartjsExpando> _expando = Expando(r'$chartjs');

/// platform.dom.js:50 the value of `canvas[EXPANDO_KEY]`.
final class _ChartjsExpando {
  _ChartjsExpando(this.initial);

  /// platform.dom.js:51 `initial`.
  final _Initial initial;
}

/// platform.dom.js:51-59 `initial`: the attributes and the inline style of
/// the canvas before the chart changed them.
final class _Initial {
  _Initial({
    required this.height,
    required this.width,
    required this.style,
  });

  /// platform.dom.js:52 `height`: the `height` attribute. Dart `null` is
  /// the JS `null` of an absent attribute.
  final String? height;

  /// platform.dom.js:53 `width`: the `width` attribute, as [height].
  final String? width;

  /// platform.dom.js:54-58 `style`: `display`, `height` and `width`, in this
  /// key order.
  final Map<String, String> style;

  /// platform.dom.js:301 `initial[prop]`, for `'height'` and `'width'`.
  String? operator [](String prop) => prop == 'height' ? height : width;
}

/// platform.dom.js:21 `EVENT_TYPES`.
///
/// DOM event types -> Chart.js event types.
/// Note: only events with different types are mapped.
/// @see https://developer.mozilla.org/en-US/docs/Web/Events
const Map<String, String> eventTypes = {
  'touchstart': 'mousedown',
  'touchmove': 'mousemove',
  'touchend': 'mouseup',
  'pointerenter': 'mouseenter',
  'pointerdown': 'mousedown',
  'pointermove': 'mousemove',
  'pointerup': 'mouseup',
  'pointerleave': 'mouseout',
  'pointerout': 'mouseout',
};

/// platform.dom.js:33 `isNullOrEmpty`.
bool _isNullOrEmpty(String? value) => value == null || value == '';

/// platform.dom.js:41 `initCanvas(canvas, aspectRatio)`.
///
/// Initializes the canvas style and render size without modifying the canvas
/// display size, since responsiveness is handled by the controller.resize()
/// method. The config is used to determine the aspect ratio to apply in case
/// no explicit height has been specified.
///
/// The `display` and `box-sizing` styles have no effect in Flutter. The port
/// still sets them, so that [FlutterPlatform.releaseContext] restores the
/// same values.
HTMLCanvasElement initCanvas(HTMLCanvasElement canvas, [double? aspectRatio]) {
  final style = canvas.style;

  // NOTE(SB) canvas.getAttribute('width') !== canvas.width: in the first case
  // it returns null or '' if no explicit value has been set to the canvas
  // attribute.
  final renderHeight = canvas.getAttribute('height');
  final renderWidth = canvas.getAttribute('width');

  // Chart.js modifies some canvas values that we want to restore on destroy
  _expando[canvas] = _ChartjsExpando(
    _Initial(
      height: renderHeight,
      width: renderWidth,
      style: {
        'display': style.getPropertyValue('display'),
        'height': style.getPropertyValue('height'),
        'width': style.getPropertyValue('width'),
      },
    ),
  );

  // Force canvas to display as block to avoid extra space caused by inline
  // elements, which would interfere with the responsive resize process.
  // https://github.com/chartjs/Chart.js/issues/2538
  if (style.getPropertyValue('display').isEmpty) {
    style.setProperty('display', 'block');
  }
  // Include possible borders in the size
  if (style.getPropertyValue('box-sizing').isEmpty) {
    style.setProperty('box-sizing', 'border-box');
  }

  if (_isNullOrEmpty(renderWidth)) {
    final displayWidth = readUsedSize(canvas, 'width');
    if (displayWidth != null) {
      canvas.width = displayWidth.toInt();
    }
  }

  if (_isNullOrEmpty(renderHeight)) {
    if (canvas.style.getPropertyValue('height') == '') {
      // If no explicit render height and style height, let's apply the
      // aspect ratio, which one can be specified by the user but also by
      // charts as default option (i.e. options.aspectRatio). If not
      // specified, use canvas aspect ratio of 2.
      // The DOM assigns the quotient with ToUint32 (canvas.dart).
      canvas.height = _toUint32(
        canvas.width / (jsTruthy(aspectRatio) ? aspectRatio! : 2),
      );
    } else {
      final displayHeight = readUsedSize(canvas, 'height');
      if (displayHeight != null) {
        canvas.height = displayHeight.toInt();
      }
    }
  }

  return canvas;
}

/// The WebIDL conversion of a number to `unsigned long` (ECMAScript
/// `ToUint32`) of the assignments `canvas.width = …` and
/// `canvas.height = …`: it truncates a fraction, and NaN and the infinities
/// give 0.
int _toUint32(double value) {
  if (!value.isFinite) return 0;
  const twoTo32 = 4294967296.0;
  var uint32 = value.truncateToDouble().remainder(twoTo32);
  if (uint32 < 0) uint32 += twoTo32;
  return uint32.toInt();
}

// platform.dom.js:95 `eventListenerOptions` has no port: the host never
// claims a pointer for an event listener, which is what `passive: true`
// promises the browser.

/// platform.dom.js:97 `addListener(node, type, listener)`.
void _addListener(
  HTMLCanvasElement? node,
  String type,
  void Function(NativeEvent) listener,
) {
  if (node != null) {
    addCanvasEventListener(node, type, listener);
  }
}

/// platform.dom.js:103 `removeListener(chart, type, listener)`.
void _removeListener(types.Chart chart, String type, Object? listener) {
  final canvas = chart.canvas;
  if (canvas != null && listener is void Function(NativeEvent)) {
    removeCanvasEventListener(canvas, type, listener);
  }
}

/// platform.dom.js:109 `fromNativeEvent(event, chart)`.
///
/// `x !== undefined ? x : null`: the position of a [NativeEvent] is never
/// `undefined` (`getRelativePosition` of `helpers.dom.dart`). A `touchend`
/// without touches gives NaN, which stays NaN, as upstream.
types.ChartEvent fromNativeEvent(NativeEvent event, types.Chart chart) {
  final type = eventTypes[event.type] ?? event.type;
  final position = getRelativePosition(event, chart);
  return _ChartEvent(
    type: type,
    chart: chart,
    native: event,
    x: position.x,
    y: position.y,
  );
}

/// platform.dom.js:112-118 the object literal `{type, chart, native, x, y}`
/// of `fromNativeEvent`.
final class _ChartEvent implements types.ChartEvent {
  _ChartEvent({
    required this.type,
    required this.chart,
    required this.native,
    required this.x,
    required this.y,
  });

  @override
  final String type;

  @override
  final types.Chart chart;

  @override
  final NativeEvent native;

  @override
  final double? x;

  @override
  final double? y;

  @override
  String toString() => 'ChartEvent($type, $x, $y)';
}

// platform.dom.js:121 `nodeListContains` has no port: a
// CanvasMutationObserver observes one canvas, so the host reports the canvas
// itself.

/// platform.dom.js:129 `createAttachObserver(chart, type, listener)`.
///
/// [listener] is the `attached` function of core.controller.js:1022, a
/// `void Function()`. The host reports a net attach once, after the frame
/// of the change, as the DOM delivers the mutation records of one task
/// together (Chart.js ADR 0016, decision 9). The first layout of the host
/// reports it at once.
CanvasMutationObserver createAttachObserver(
  types.Chart chart,
  String type,
  Function listener,
) {
  final canvas = chart.canvas;
  final observer = CanvasMutationObserver(({required connected}) {
    if (connected) {
      (listener as void Function())();
    }
  });
  if (canvas != null) {
    observer.observe(canvas);
  }
  return observer;
}

/// platform.dom.js:145 `createDetachObserver(chart, type, listener)`.
///
/// [listener] is the `detached` function of core.controller.js:1032, a
/// `void Function()`.
CanvasMutationObserver createDetachObserver(
  types.Chart chart,
  String type,
  Function listener,
) {
  final canvas = chart.canvas;
  final observer = CanvasMutationObserver(({required connected}) {
    if (!connected) {
      (listener as void Function())();
    }
  });
  if (canvas != null) {
    observer.observe(canvas);
  }
  return observer;
}

// platform.dom.js:161-189 `drpListeningCharts`, `oldDevicePixelRatio`,
// `onWindowResize`, `listenDevicePixelRatioChanges` and
// `unlistenDevicePixelRatioChanges` have no port. Flutter has no window
// `resize` event. The host reads the device pixel ratio of its view
// (`MediaQuery.devicePixelRatioOf`), and its ContainerResizeObserver reports
// a change. The test of :171 stays in createResizeObserver.

/// platform.dom.js:191 `createResizeObserver(chart, type, listener)`.
///
/// [listener] is the resize listener of core.controller.js:1015, a
/// `void Function([double? width, double? height])`. One `throttled<Size?>`
/// function takes the size and device pixel ratio changes (Chart.js ADR
/// 0016, decision 9). A `null` size is a device pixel ratio change, for
/// which upstream calls `resize()` without arguments (:172).
///
/// The container size is the max size of the incoming constraints of the
/// host. An unbounded side is `double.infinity`: [FlutterPlatform] gives it
/// a size (see [FlutterPlatform.getMaximumSize]).
ContainerResizeObserver? createResizeObserver(
  types.Chart chart,
  String type,
  Function listener,
) {
  final canvas = chart.canvas;
  final container = canvas != null ? getParentNode(canvas) : null;
  if (container == null) {
    return null;
  }
  final resizeListener = listener as void Function([double? w, double? h]);
  final resize = throttled<ui.Size?>((size) {
    // The scrollbar step of :198-209 has no port (see the library comment).
    if (size == null) {
      resizeListener();
    } else {
      resizeListener(size.width, size.height);
    }
  });

  final observer = ContainerResizeObserver(
    onResize: (width, height) {
      // When its container's display is set to 'none' the callback will be
      // called with a size of (0, 0), which will cause the chart to lose its
      // original height, so skip resizing in such case.
      if (width == 0 && height == 0) {
        return;
      }
      resize(ui.Size(width, height));
    },
    // platform.dom.js:170-173, for the device pixel ratio of the host.
    onDevicePixelRatio: (dpr) {
      if (chart.currentDevicePixelRatio != dpr) {
        resize(null);
      }
    },
  )..observe(container);

  return observer;
}

/// platform.dom.js:231 `releaseObserver(chart, type, observer)`.
///
/// The `unlistenDevicePixelRatioChanges` call of :235-237 has no port: the
/// [ContainerResizeObserver] also carries the device pixel ratio.
void releaseObserver(types.Chart chart, String type, Object? observer) {
  switch (observer) {
    case final CanvasMutationObserver observer:
      observer.disconnect();
    case final ContainerResizeObserver observer:
      observer.disconnect();
  }
}

/// platform.dom.js:240 `createProxyAndListen(chart, type, listener)`.
///
/// [listener] is the event listener of core.controller.js:985, a
/// `void Function(ChartEvent)`. The proxy is a throttled function: the
/// events of one type coalesce to the last one in each frame (Chart.js ADR
/// 0016, decision 9).
void Function(NativeEvent) createProxyAndListen(
  types.Chart chart,
  String type,
  Function listener,
) {
  final canvas = chart.canvas;
  final eventListener = listener as void Function(types.ChartEvent);
  final proxy = throttled<NativeEvent>((event) {
    // This case can occur if the chart is destroyed while waiting
    // for the throttled function to occur. We prevent crashes by checking
    // for a destroyed chart
    if (chart.ctx != null) {
      eventListener(fromNativeEvent(event, chart));
    }
  });

  _addListener(canvas, type, proxy);

  return proxy;
}

/// platform.dom.js:260 `DomPlatform`, as the Flutter platform.
///
/// Platform class for charts that a chart host shows (Chart.js ADR 0037).
/// `detectPlatform` gives it for a canvas whose parent node is a host.
class FlutterPlatform extends BasePlatform {
  /// platform.dom.js:260 the implicit constructor.
  FlutterPlatform();

  /// platform.dom.js:260 `class DomPlatform` as a value, as the Flutter
  /// platform (Chart.js ADR 0037, section 1, and Chart.js ADR 0048, section
  /// 7).
  ///
  /// It extends [BasePlatform.jsClass] and has no statics, as
  /// `BasicPlatform.jsClass`. Its name is `FlutterPlatform`. The key
  /// `DomPlatform` of `Chart.platforms` (`lib/src/index.umd.dart`) gives it
  /// (`platform-umd-dom-platform`).
  // DIVERGES(chartjs): platform-umd-dom-platform, the class of DomPlatform.
  static final JsClass jsClass = JsClass(
    'FlutterPlatform',
    superclass: BasePlatform.jsClass,
    construct: (newTarget, args) => FlutterPlatform(),
  );

  /// The canvas of the last [acquireContext] call, whose host gives
  /// [getDevicePixelRatio].
  HTMLCanvasElement? _canvas;

  /// platform.dom.js:267 `acquireContext(canvas, aspectRatio)`.
  ///
  /// To prevent canvas fingerprinting, some add-ons undefine the getContext
  /// method, for example: https://github.com/kkapsner/CanvasBlocker
  /// https://github.com/chartjs/Chart.js/issues/2807
  ///
  /// An item that is not an [HTMLCanvasElement] has no `getContext`, so it
  /// gives `null`.
  @override
  CanvasRenderingContext2D? acquireContext(
    Object? canvas, [
    double? aspectRatio,
  ]) {
    final context = canvas is HTMLCanvasElement
        ? canvas.getContext('2d')
        : null;

    // `instanceof HTMLCanvasElement/CanvasRenderingContext2D` fails when the
    // canvas is inside an iframe or when running in a protected environment.
    // We could guess the types from their toString() value but let's keep
    // things flexible and assume it's a sufficient condition if the canvas
    // has a context2D which has canvas as `canvas`.
    // https://github.com/chartjs/Chart.js/issues/3887
    // https://github.com/chartjs/Chart.js/issues/4102
    // https://github.com/chartjs/Chart.js/issues/4152
    if (context != null && identical(context.canvas, canvas)) {
      // Load platform resources on first chart creation, to make it possible
      // to import the library before setting platform options.
      initCanvas(canvas! as HTMLCanvasElement, aspectRatio);
      _canvas = canvas as HTMLCanvasElement;
      return context;
    }

    return null;
  }

  /// platform.dom.js:293 `releaseContext(context)`.
  @override
  bool releaseContext(CanvasRenderingContext2D context) {
    final canvas = context.canvas;
    final expando = _expando[canvas];
    if (expando == null) {
      return false;
    }

    final initial = expando.initial;
    for (final prop in const ['height', 'width']) {
      final value = initial[prop];
      if (isNullOrUndef(value)) {
        canvas.removeAttribute(prop);
      } else {
        canvas.setAttribute(prop, value!);
      }
    }

    final style = initial.style;
    for (final MapEntry(:key, :value) in style.entries) {
      canvas.style.setProperty(key, value);
    }

    // The canvas render size might have been changed (and thus the state
    // stack discarded), we can't use save() and restore() to restore the
    // initial state. So make sure that at least the canvas context is reset
    // to the default state by setting the canvas width.
    // https://www.w3.org/TR/2011/WD-html5-20110525/the-canvas-element.html
    // The assignment resets the context (canvas.dart).
    // ignore: no_self_assignments
    canvas.width = canvas.width;

    _expando[canvas] = null;
    return true;
  }

  /// platform.dom.js:331 `addEventListener(chart, type, listener)`.
  @override
  void addEventListener(types.Chart chart, String type, Function listener) {
    // Can have only one listener per type, so make sure previous is removed
    removeEventListener(chart, type);

    final proxies = chart.platformProxies ??= <String, Object?>{};
    const handlers =
        <
          String,
          Object? Function(types.Chart chart, String type, Function listener)
        >{
          'attach': createAttachObserver,
          'detach': createDetachObserver,
          'resize': createResizeObserver,
        };
    final handler = handlers[type] ?? createProxyAndListen;
    proxies[type] = handler(chart, type, listener);
  }

  /// platform.dom.js:350 `removeEventListener(chart, type)`.
  ///
  /// `proxies[type] = undefined` keeps the key. Dart `null` stands for that
  /// `undefined`.
  @override
  void removeEventListener(
    types.Chart chart,
    String type, [
    Function? listener,
  ]) {
    final proxies = chart.platformProxies ??= <String, Object?>{};
    final proxy = proxies[type];

    if (proxy == null) {
      return;
    }

    const handlers =
        <String, void Function(types.Chart chart, String type, Object? proxy)>{
          'attach': releaseObserver,
          'detach': releaseObserver,
          'resize': releaseObserver,
        };
    final handler = handlers[type] ?? _removeListener;
    handler(chart, type, proxy);
    proxies[type] = null;
  }

  /// platform.dom.js:368 `getDevicePixelRatio()`.
  ///
  /// Upstream reads `window.devicePixelRatio`. The port reads the device
  /// pixel ratio of the host that shows the canvas of [acquireContext]: the
  /// `MediaQuery.devicePixelRatioOf` of its view. Without a host, it reads
  /// the implicit view, and 1 without one.
  @override
  double getDevicePixelRatio() {
    final canvas = _canvas;
    final container = canvas != null ? getParentNode(canvas) : null;
    if (container is RenderChartHost) {
      return container.devicePixelRatio;
    }
    return ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1;
  }

  /// platform.dom.js:378 `getMaximumSize(canvas, width, height,
  /// aspectRatio)`.
  ///
  /// The size of `getMaximumSize` of `helpers.dom.dart`, with the rule of
  /// Chart.js ADR 0037, section 5, for unbounded constraints. The container
  /// of an unbounded side is `double.infinity`, which gives an infinite size.
  /// Then an unbounded side takes the size of the HTML canvas default, 300 x
  /// 150 logical pixels, unless the other side is bounded and [aspectRatio]
  /// is truthy: then the bounded side and the aspect ratio give it.
  @override
  ({double width, double height}) getMaximumSize(
    HTMLCanvasElement canvas, [
    double? width,
    double? height,
    double? aspectRatio,
  ]) {
    final size = helpers.getMaximumSize(canvas, width, height, aspectRatio);
    if (size.width.isFinite && size.height.isFinite) {
      return size;
    }
    final container = getParentNode(canvas);
    final containerWidth = width ?? container?.contentWidth ?? 0;
    final containerHeight = height ?? container?.contentHeight ?? 0;
    final unboundedWidth = !containerWidth.isFinite;
    final unboundedHeight = !containerHeight.isFinite;
    final ratio = jsTruthy(aspectRatio);
    final unbounded = helpers.getMaximumSize(
      canvas,
      unboundedWidth && (unboundedHeight || !ratio)
          ? _defaultWidth
          : containerWidth,
      unboundedHeight && (unboundedWidth || !ratio)
          ? _defaultHeight
          : containerHeight,
      aspectRatio,
    );
    if (unbounded.width.isFinite && unbounded.height.isFinite) {
      return unbounded;
    }
    // A zero bounded side and an aspect ratio: the default canvas box.
    return helpers.getMaximumSize(
      canvas,
      _defaultWidth,
      _defaultHeight,
      aspectRatio,
    );
  }

  /// The width of the HTML canvas default, in logical pixels.
  static const double _defaultWidth = 300;

  /// The height of the HTML canvas default, in logical pixels.
  static const double _defaultHeight = 150;

  /// platform.dom.js:385 `isAttached(canvas)`.
  ///
  /// The container is the host that shows the canvas. Its `isConnected` is
  /// true while the host is attached to the render tree and laid out.
  @override
  bool isAttached(HTMLCanvasElement? canvas) {
    final container = canvas != null ? getParentNode(canvas) : null;
    return container != null && container.isConnected;
  }
}
