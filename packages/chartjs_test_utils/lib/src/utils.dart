// Ported from chartjs-test-utils v0.4.0 src/utils.js (MIT, chartjs-test-utils Contributors).

/// Port of `src/utils.js`: the chart helpers of the harness (Chart.js ADR
/// 0022, sections 4 to 6).
///
/// - [acquireChart] and [releaseChart] port `_acquireChart` (:36) and
///   `_releaseChart` (:107). The underscore drops, because `index.dart`
///   calls them (Chart.js ADR 0012, Underscore members). Their Dart names
///   are the names of `acquireChart` and `releaseChart` of `index.dart`.
///   Thus `index.dart` imports this library with the prefix `utils`
///   (Chart.js ADR 0012, Collisions). [$test] stands for the own property
///   `chart.$test`.
/// - [waitForResize] and [afterEvent] replace a function field of one
///   chart, as upstream replaces a JS own property of the chart:
///   `Chart.resize` and `Chart.eventHandler` (`harness-method-fields`).
///   They are line-by-line ports with no hunk.
/// - [triggerMouseEvent] dispatches a `NativeEvent` to the listeners of the
///   canvas and pumps frames until the chart handled it.
///
/// `createCanvas` and `readImageData` (:3-23) are `n/a`: the port compares
/// no image (Chart.js ADR 0034). `injectCSS` (:117) is `n/a`: Flutter has no
/// CSS. The DOM stand-in `dom.dart` gives the class `chartjs-wrapper` the
/// effect of the rule of `injectWrapperCSS`.
///
/// This library is not a pure layer: it imports `core.controller`, the chart
/// host and `dom.dart`.
library;

// The harness replaces a member of the chart that only the harness reads.
// ignore_for_file: invalid_use_of_internal_member

import 'package:chartjs_test_utils/src/dom.dart';
// flutter_chartjs_port does not export lib/src. The harness reads the canvas
// interface,
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
// the canvas element of the canvas layer,
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
// the chart,
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
// the line element, which has no upstream getCenterPoint,
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
// Object.keys,
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/js/js_array.dart';
// ToBoolean, ToNumber and ToString,
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/js/js_number.dart';
// the JS property read,
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/js/js_object.dart';
// the undefined sentinel,
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
// the EventTarget of the canvas,
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
// the native event,
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
// and the interfaces of the elements and points.
// ignore: implementation_imports
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

// utils.js:1 imports spritingOn and spritingOff: n/a. The port compares no
// image (Chart.js ADR 0034).

// utils.js:3 `createCanvas(w, h)` and utils.js:10 `readImageData(url,
// callback)`: n/a. Only the image comparison of fixtures calls them.

/// The own property `chart.$test` of a chart of [acquireChart]
/// (utils.js:99-102): the Map `{persistent, wrapper}`. A chart of `Chart(...)`
/// has none.
final Expando<Map<String, Object?>> $test = Expando(r'$test');

/// `a || b` of a JS value.
Object? _or(Object? a, Object? b) => jsTruthy(a) ? a : b;

/// utils.js:36 `_acquireChart(config, options)`.
///
/// Injects a new canvas (and div wrapper) and creates the associated Chart
/// instance using the given config. Additional options allow tweaking
/// elements generation.
/// - [config]: Chart config.
/// - [options]: Chart acquisition options.
///   - `canvas`: Canvas attributes.
///   - `wrapper`: Canvas wrapper attributes.
///   - `useOffscreenCanvas`: use an OffscreenCanvas instead of the normal
///     HTMLCanvasElement.
///   - `useShadowDOM`: use shadowDom.
///   - `persistent`: If true, the chart will not be released after the spec.
///
/// Both are JS objects: Maps (Chart.js ADR 0043). As upstream, the function
/// writes `canvas` and `wrapper` into [options], and `options` into
/// [config]. It writes `animation`, `responsive` and `locale` into the
/// options of [config]. A nested Map literal of a spec thus needs the type
/// `<String, Object?>`: a narrower Map throws a `TypeError` at the write.
///
/// The hunks of `harness-acquire-chart` (Chart.js ADR 0022, section 4):
/// - The function works only in the body of a `testWidgets` test. Outside
///   such a body, it throws a [StateError] before the first DOM write.
/// - After `document.body.appendChild(wrapper)` (:73), the forced build and
///   layout of the harness body runs (`forceHarnessLayout`). It is the
///   counterpart of the layout that a browser forces when `getMaximumSize`
///   reads the container. Thus `Chart(ctx, config)` finds the canvas in a
///   laid-out chart host, and the chart is attached at its construction, as
///   upstream. During build, layout or paint, the forced layout throws a
///   [StateError]. Then the wrapper leaves the body again.
/// - `useOffscreenCanvas: true` gives the chart the context of a second
///   `UiCanvasElement` with the size of the canvas, as
///   `transferControlToOffscreen()` gives. No chart host shows it. Thus
///   `detectPlatform` gives `BasicPlatform`, as `platform/index.js:7` does
///   for an `OffscreenCanvas`.
/// - `useShadowDOM: true` throws an [UnsupportedError], in place of the
///   `pending()` of a browser without the shadow DOM (:64-68).
/// - `spriteText` (:90-92) has no port: the port compares no image.
Chart acquireChart([
  Map<String, Object?>? config,
  Map<String, Object?>? options,
]) {
  // DIVERGES(chartjs): harness-acquire-chart, only in a testWidgets body.
  if (!TestWidgetsFlutterBinding.ensureInitialized().inTest) {
    throw StateError(
      'acquireChart works only in the body of a testWidgets test '
      '(Chart.js ADR 0022, section 4).',
    );
  }
  final wrapper = document.createElement<HarnessElement>('div');
  final canvas = document.createElement<HTMLCanvasElement>('canvas');
  Chart chart;

  // `config || {}` and `options || {}`: a Map is truthy.
  config ??= <String, Object?>{};
  options ??= <String, Object?>{};
  options['canvas'] = _or(options['canvas'], <String, Object?>{
    'height': 512,
    'width': 512,
  });
  options['wrapper'] = _or(options['wrapper'], <String, Object?>{
    'class': 'chartjs-wrapper',
  });

  // `for (key in object)` with `hasOwnProperty`: the own enumerable keys, in
  // the order of `Object.keys`. `setAttribute` converts the value with
  // `ToString`.
  final canvasAttributes = options['canvas']! as Map<String, Object?>;
  for (final key in jsObjectKeys(canvasAttributes)) {
    canvas.setAttribute(key, jsToString(canvasAttributes[key]));
  }

  final wrapperAttributes = options['wrapper']! as Map<String, Object?>;
  for (final key in jsObjectKeys(wrapperAttributes)) {
    wrapper.setAttribute(key, jsToString(wrapperAttributes[key]));
  }

  // by default, remove chart animation and auto resize
  config['options'] = _or(config['options'], <String, Object?>{});
  final chartOptions = config['options']! as Map<String, Object?>;
  final animation = jsGet(chartOptions, 'animation');
  chartOptions['animation'] = identical(animation, undefined)
      ? false
      : animation;
  final responsive = jsGet(chartOptions, 'responsive');
  chartOptions['responsive'] = identical(responsive, undefined)
      ? false
      : responsive;
  chartOptions['locale'] = _or(chartOptions['locale'], 'en-US');

  if (jsTruthy(options['useShadowDOM'])) {
    // If shadowDOM is not supported by the browsers, mark test as 'pending'.
    // Flutter has no shadow DOM: a spec case with it skips as
    // 'n/a: Flutter has no shadow DOM'.
    // DIVERGES(chartjs): harness-acquire-chart, Flutter has no shadow DOM.
    throw UnsupportedError('useShadowDOM: Flutter has no shadow DOM.');
  } else {
    wrapper.appendChild(canvas);
  }
  document.body.appendChild(wrapper);
  // DIVERGES(chartjs): harness-acquire-chart, the forced layout of a read.
  try {
    forceHarnessLayout();
  } on Object {
    document.body.removeChild(wrapper);
    rethrow;
  }

  try {
    CanvasRenderingContext2D? ctx;
    if (jsTruthy(options['useOffscreenCanvas'])) {
      // The port always has an offscreen canvas. Thus the `pending()` of a
      // browser without `transferControlToOffscreen` (:78-84) has no port.
      // DIVERGES(chartjs): harness-acquire-chart, a canvas that no host shows.
      final offscreenCanvas = UiCanvasElement(
        width: canvas.width,
        height: canvas.height,
      );
      ctx = offscreenCanvas.getContext('2d');
    } else {
      ctx = canvas.getContext('2d');
    }
    // utils.js:90-92 `spritingOn(ctx)` for `options.spriteText`: n/a.
    chart = Chart(ctx, config);
  } on Object {
    document.body.removeChild(wrapper);
    rethrow;
  }

  $test[chart] = <String, Object?>{
    'persistent': jsGet(options, 'persistent'),
    'wrapper': wrapper,
  };

  return chart;
}

/// utils.js:107 `_releaseChart(chart)`.
///
/// Destroys [chart]. Then it removes the wrapper of `chart.$test` from its
/// parent. A second call destroys the chart again, which does not throw
/// (core.controller.js:944). After the unmount of the harness body, the
/// removal changes only the element tree (Chart.js ADR 0022, section 8).
void releaseChart(Chart chart) {
  // utils.js:108 `spritingOff(chart.ctx)`: n/a.
  chart.destroy();

  final wrapper = jsGet($test[chart] ?? <String, Object?>{}, 'wrapper');
  if (wrapper is HarnessElement && wrapper.parentNode != null) {
    wrapper.parentNode!.removeChild(wrapper);
  }
}

// utils.js:117 `injectCSS(css)`: n/a. Flutter has no CSS.

/// utils.js:130 `waitForResize(chart, callback)`.
///
/// The replacement restores the old function, calls it, and then calls
/// [callback]. Thus [callback] runs after the whole `resize` call, also
/// after the plugin hook `resize`, `onResize` and the update.
/// `override.apply(this, arguments)` passes the arguments of the call.
void waitForResize(Chart chart, void Function() callback) {
  final override = chart.resize;
  chart.resize = ([width, height]) {
    chart.resize = override;
    override(width, height);
    callback();
  };
}

/// utils.js:139 `afterEvent(chart, type, callback)`.
///
/// `override.call(this, event)` passes the event alone: the replacement
/// drops the argument `replay`, as upstream. [callback] runs after the
/// whole handler, also after `render()`.
void afterEvent(Chart chart, String type, void Function() callback) {
  final override = chart.eventHandler;
  chart.eventHandler = (event, [replay]) {
    override(event);
    if (event.type == type || event.native?.type == type) {
      chart.eventHandler = override;
      // eslint-disable-next-line callback-return
      callback();
    }
  };
}

/// The JS property read `el[key]` of a point or an element.
///
/// An element gives its property read, with [undefined] for a coordinate
/// that it does not have. Another `types.Point` gives its `x` and `y`,
/// where Dart `null` stands for JS `null`. A Map gives [jsGet]. Any other
/// value gives [undefined].
Object? _property(Object el, String key) => switch (el) {
  final types.ElementPropertyRead element => element[key],
  final types.Point point => key == 'x' ? point.x : point.y,
  _ => jsGet(el, key),
};

/// utils.js:151 `_resolveElementPoint(el)`.
///
/// `typeof el.getCenterPoint === 'function'` is a test for a
/// `types.VisualElement`. `element.line.js` has no `getCenterPoint`: the
/// Dart `LineElement` throws for it. Thus a line element takes the next
/// branch, as upstream. The point is a record of the two coordinates. The
/// addition `rect.left + point.x` of :168 applies `ToNumber` to them.
({double x, double y}) _resolveElementPoint(Object? el) {
  var point = (x: 0.0, y: 0.0);
  if (el != null && jsTruthy(el)) {
    if (el is types.VisualElement && el is! LineElement) {
      final center = el.getCenterPoint();
      point = (x: jsToNumber(center.x), y: jsToNumber(center.y));
    } else if (!identical(_property(el, 'x'), undefined) &&
        !identical(_property(el, 'y'), undefined)) {
      point = (
        x: jsToNumber(_property(el, 'x')),
        y: jsToNumber(_property(el, 'y')),
      );
    }
  }
  return point;
}

/// utils.js:163 `triggerMouseEvent(chart, type, el)`.
///
/// Dispatches an event of [type] at the point of [el] to the listeners of
/// the canvas of [chart]. The Future completes with the event after the
/// chart handled it. The hunks of `harness-trigger-mouse-event` (Chart.js
/// ADR 0022, section 6):
/// - The event is a `NativeEvent` with `offsetX` and `offsetY` at the point
///   and the canvas as its target. The DOM `offsetX` of the upstream event
///   is `clientX - rect.left`: the point, for a canvas without a border.
///   Chrome rounds the offsets of a synthetic `MouseEvent` to integers.
///   `getRelativePosition` applies `Math.round` to the offsets. Thus the
///   chart event gets the Chrome position. Only `event.native.offsetX`
///   keeps the fraction.
/// - `dispatchCanvasEvent` replaces `node.dispatchEvent(event)` (:179). It
///   calls the listeners of the canvas without a hit test and without the
///   gesture arena, as the DOM call does. The throttled proxy of the
///   platform then calls the chart in the next frame.
/// - `await promise` (:181) pumps frames of 16 ms until the `afterEvent`
///   callback ran (`pumpFrames` of `dom.dart`). One frame is enough. A type
///   without a listener never resolves: `pumpFrames` then fails with the
///   Jasmine timeout message.
///
/// A spec calls it only in the body of a `testWidgets` test.
Future<NativeEvent> triggerMouseEvent(
  Chart chart,
  String type, [
  Object? el,
]) async {
  final node = chart.canvas!;
  // utils.js:165 `node.getBoundingClientRect()`: the event has the offsets
  // in the canvas, which `getRelativePosition` reads.
  final point = _resolveElementPoint(el);
  // DIVERGES(chartjs): harness-trigger-mouse-event, offsets in the canvas.
  final event = NativeEvent(
    type: type,
    offsetX: point.x,
    offsetY: point.y,
    target: node,
  );

  var resolved = false;
  afterEvent(chart, type, () => resolved = true);

  // DIVERGES(chartjs): harness-trigger-mouse-event, the canvas listeners.
  dispatchCanvasEvent(node, event);

  // DIVERGES(chartjs): harness-trigger-mouse-event, frames until resolved.
  await pumpFrames(() => resolved);

  return event;
}
