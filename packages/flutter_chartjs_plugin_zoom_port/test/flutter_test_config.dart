// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/index.js (MIT, chartjs-plugin-zoom contributors).

/// Port of `test/index.js`, the set-up of the zoom specs (Zoom ADR 0002,
/// item 4).
///
/// Flutter runs [testExecutable] around each test file of the package. The
/// file has the set-up of upstream in the form of the host set-up
/// (`packages/flutter_chartjs_port/test/flutter_test_config.dart`), with the
/// public libraries of the host and the harness only (Zoom ADR 0003, item
/// 1):
///
/// - the device pixel ratio 1 and the view of 800 x 600 before each test;
/// - the default date zone UTC (`harness-date-zone`);
/// - the built-in components of the UMD entry of Chart.js and the plugin of
///   the UMD entry of the zoom, registered before `main()` of the test file
///   (`harness-register-builtins`);
/// - the colors plugin off, and the restore of the global scopes after each
///   test (`harness-defaults-restore`);
/// - the release of the charts after each test;
/// - the test font of the host harness (`harness-test-font`).
///
/// The oracle O2 of the host (`foreignAudit`) is internal to the host: the
/// zoom tests run without it.
///
/// The file also has the event helpers that index.js:20-130 puts on
/// `jasmine`: [triggerMouseEvent], [triggerWheelEvent], [dispatchEvent],
/// [dispatchPointer], [simulatePan] and [simulatePinch]. A spec imports this
/// file and `package:chartjs_test_utils/flutter.dart` with
/// `hide triggerMouseEvent`. Each helper is synchronous, as upstream: it
/// dispatches a bubbling, cancelable `NativeEvent` on the canvas
/// (`node.dispatchEvent`), which calls the listeners of the canvas and then
/// those of its document. The point of an event is `clientX: rect.left + x`
/// and `clientY: rect.top + y`, where `rect` is
/// `node.getBoundingClientRect()`.
library;

import 'dart:async';
import 'dart:ui';

// index.js:1-8 imports the helpers of chartjs-test-utils. The specs import
// `acquireChart` and `releaseChart` from package:chartjs_test_utils/flutter.dart.
import 'package:chartjs_test_utils/flutter.dart'
    show afterEachChart, installTestFont, releaseCharts;
import 'package:chartjs_test_utils/pure.dart'
    show setUpBuiltins, setUpDefaultsRestore;
import 'package:flutter_chartjs_plugin_zoom_port/src/index.umd.dart'
    show chartZoom;
import 'package:flutter_chartjs_plugin_zoom_port/src/plugin.dart'
    show zoomPlugin;
import 'package:flutter_chartjs_port/chartjs.dart'
    show
        CanvasEventTarget,
        Chart,
        HTMLCanvasElement,
        JsObjectFace,
        NativeEvent,
        controllers,
        defaults,
        elements,
        plugins,
        scales,
        setDefaultDateZone;
import 'package:flutter_test/flutter_test.dart';

/// The `devicePixelRatio` of the test view (index.js:10-12).
const double _devicePixelRatio = 1;

/// The logical size of the test view: the flutter_test default (2400 x 1800
/// physical pixels at a ratio of 3).
const Size _logicalSize = Size(800, 600);

/// The set-up of each test file in this package.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  // force ratio=1 for tests on high-res/retina devices
  // ref https://github.com/chartjs/Chart.js/issues/4515
  //
  // The flutter_test view has a ratio of 3. `tester.view.reset()` in a test
  // puts back 3, not 1. Thus a `setUp` sets the ratio before each test, as
  // the host set-up does.
  final view = binding.platformDispatcher.implicitView!;
  void forceRatio() {
    if (view.devicePixelRatio != _devicePixelRatio) {
      view.devicePixelRatio = _devicePixelRatio;
    }
    final physicalSize = _logicalSize * _devicePixelRatio;
    if (view.physicalSize != physicalSize) view.physicalSize = physicalSize;
  }

  forceRatio();
  setUp(forceRatio);

  // index.js:14-15 put `acquireChart` and `releaseChart` on `window`. Dart
  // has no globals: the specs import them from
  // package:chartjs_test_utils/flutter.dart.

  // index.js:17-19 `jasmine.fixture`: `specsFromFixtures` is an export of
  // package:chartjs_test_utils/flutter.dart.

  // index.js:20-130 put the event helpers on `jasmine`: they are the
  // top-level functions of this library, after `testExecutable`.

  // Set a fixed time zone (and, in particular, disable Daylight Saving
  // Time) for more stable test results. Upstream runs in the zone of the
  // browser.
  // DIVERGES(zoom): harness-date-zone, the default date zone UTC.
  setDefaultDateZone('Etc/UTC');

  // karma.conf.cjs loads the UMD bundle of Chart.js, which registers the
  // built-in components (`src/index.umd.ts:28` of Chart.js), then
  // `src/index.umd.ts` of the plugin, which registers the plugin
  // (`src/index.umd.ts:4`), before the specs. Dart has no import side
  // effect: the registration runs before `main()` of the test file and
  // before the snapshot of the restore below. The first read of `chartZoom`
  // registers the plugin. Thus the restore keeps the defaults of the
  // components and `defaults.plugins.zoom`.
  // DIVERGES(zoom): harness-register-builtins, the UMD entries of karma.
  setUpBuiltins(
    () {
      Chart.register([controllers, scales, elements, plugins]);
      final _ = chartZoom;
    },
    () =>
        Chart.unregister([zoomPlugin, controllers, scales, elements, plugins]),
  );

  // index.js:140-143
  // Disable colors plugin for tests.
  //
  // Upstream runs the line in a top-level `beforeAll`, once, before the
  // first spec. Here it runs before `main()` of each test file and before
  // the snapshot of the restore, so the restore keeps it.
  ((defaults['plugins']! as JsObjectFace)['colors']!
          as JsObjectFace)['enabled'] =
      false;

  // Upstream restores nothing. The restore keeps the order of the test
  // files from changing their results.
  // DIVERGES(zoom): harness-defaults-restore, restore defaults after tests.
  setUpDefaultsRestore();

  // index.js:132-134 `addMatchers()`: n/a. The matchers are functions of
  // test/support/jasmine.dart and of package:chartjs_test_utils/pure.dart
  // that a spec imports.

  // index.js:136-138 afterEach(function () { releaseCharts() })
  //
  // The unmount of the harness body calls `releaseCharts`, and the
  // `tearDown` is the fallback after a failed test (Chart.js ADR 0022,
  // section 8). The upstream specs have no `afterEach` of their own, so the
  // order of the two is the order of upstream.
  afterEachChart(releaseCharts);
  tearDown(releaseCharts);

  // The text of the scales measures with Liberation Sans under the family
  // names of the Chart.js default font, as in the host specs. Upstream
  // measures with the fonts of the browser.
  // DIVERGES(zoom): harness-test-font, Liberation Sans for Arial/Helvetica.
  await installTestFont();

  await testMain();
}

/// The members of the `init` dictionaries that the specs give to the event
/// helpers (index.js:22-130): the button and the pointer type of the event
/// and its modifier keys.
///
/// Upstream merges an open object into the DOM event init. The port has one
/// typed class with the members that the specs set. A helper takes each
/// member that the DOM event of its type has: a `MouseEvent` and a
/// `WheelEvent` have no `pointerType`.
// DIVERGES(zoom): harness-dom-events, a typed init, offsets of the canvas.
final class EventInit {
  /// An init with the DOM defaults of the members that are not given.
  const EventInit({
    this.button = 0,
    this.pointerType,
    this.ctrlKey = false,
    this.altKey = false,
    this.shiftKey = false,
    this.metaKey = false,
  });

  /// `init[key + 'Key'] = true` (zoom.drag.spec.js:309,
  /// zoom.wheel.spec.js:70): the init with the modifier [key] down. [key]
  /// is `'ctrl'`, `'alt'`, `'shift'` or `'meta'`. Another key names no
  /// member of the DOM init, which ignores it: no modifier is down.
  factory EventInit.withKey(String key) => switch (key) {
    'ctrl' => const EventInit(ctrlKey: true),
    'alt' => const EventInit(altKey: true),
    'shift' => const EventInit(shiftKey: true),
    'meta' => const EventInit(metaKey: true),
    _ => const EventInit(),
  };

  /// `button`: the button that changed. 0 is the main button.
  final int button;

  /// `pointerType` of a pointer event, or `null` for the default of the
  /// helper.
  final String? pointerType;

  /// `ctrlKey`.
  final bool ctrlKey;

  /// `altKey`.
  final bool altKey;

  /// `shiftKey`.
  final bool shiftKey;

  /// `metaKey`.
  final bool metaKey;
}

/// index.js:20 `jasmine.triggerMouseEvent = triggerMouseEvent` of
/// chartjs-test-utils (`src/utils.js:163-184`): dispatches a `MouseEvent`
/// of [type] at the point [pt] of the canvas of [chart] and gives the event.
///
/// Upstream gives a promise that resolves after the chart handled the
/// event, and the zoom specs never await it. The harness version of the
/// port pumps frames until the chart handled the event, which never comes
/// for a type that is not in `options.events` (`mousedown`, `mouseup`).
/// This version dispatches the event and returns: the plugin handles it in
/// its listeners at once. The event has `offsetX` and `offsetY` at the
/// point, as `harness-trigger-mouse-event` of the host harness.
// DIVERGES(zoom): harness-trigger-mouse-event-sync, no wait for the chart.
NativeEvent triggerMouseEvent(Chart chart, String type, ({num x, num y}) pt) {
  final node = chart.canvas!;
  final rect = node.getBoundingClientRect();
  final event = NativeEvent(
    type: type,
    clientX: rect.left + pt.x,
    clientY: rect.top + pt.y,
    offsetX: pt.x.toDouble(),
    offsetY: pt.y.toDouble(),
    cancelable: true,
    bubbles: true,
  );

  node.dispatchEvent(event);

  return event;
}

/// index.js:22 `jasmine.triggerWheelEvent(chart, init)`: dispatches a
/// `WheelEvent` with the vertical [deltaY] at the point ([x], [y]) of the
/// canvas of [chart]. [init] gives the button and the modifier keys.
///
/// Upstream takes `x`, `y`, `deltaY` and the init members in one object.
void triggerWheelEvent(
  Chart chart, {
  required num x,
  required num y,
  num deltaY = 0,
  EventInit init = const EventInit(),
}) {
  final node = chart.canvas!;
  final rect = node.getBoundingClientRect();
  final event = NativeEvent(
    type: 'wheel',
    clientX: rect.left + x,
    clientY: rect.top + y,
    offsetX: x.toDouble(),
    offsetY: y.toDouble(),
    cancelable: true,
    bubbles: true,
    button: init.button,
    deltaY: deltaY.toDouble(),
    ctrlKey: init.ctrlKey,
    altKey: init.altKey,
    shiftKey: init.shiftKey,
    metaKey: init.metaKey,
  );

  node.dispatchEvent(event);
}

/// index.js:39 `jasmine.dispatchEvent(chart, type, pt, init)`: dispatches
/// a `MouseEvent` of [type] at the point [pt] of the canvas of [chart].
void dispatchEvent(
  Chart chart,
  String type,
  ({num x, num y}) pt, [
  EventInit init = const EventInit(),
]) {
  final node = chart.canvas!;
  final rect = node.getBoundingClientRect();
  final event = NativeEvent(
    type: type,
    clientX: rect.left + pt.x,
    clientY: rect.top + pt.y,
    offsetX: pt.x.toDouble(),
    offsetY: pt.y.toDouble(),
    cancelable: true,
    bubbles: true,
    button: init.button,
    ctrlKey: init.ctrlKey,
    altKey: init.altKey,
    shiftKey: init.shiftKey,
    metaKey: init.metaKey,
  );

  node.dispatchEvent(event);
}

// Native Pointer Events replacement for the former Hammer.js `Simulator`.
// Drives the plugin's gesture handling directly, without a gesture library.
// `init` accepts any PointerEvent property, e.g. `button` or `ctrlKey`.

/// index.js:59 `dispatchPointer(node, type, pointerId, clientX, clientY,
/// init)`, also `jasmine.dispatchPointer` (index.js:80): dispatches a
/// `PointerEvent` of [type] for the pointer [pointerId] at the client point
/// ([clientX], [clientY]) on the canvas [node].
///
/// The pointer type is `'touch'` unless [init] gives another. The event has
/// the offsets of the point in the canvas, `clientX - rect.left` and
/// `clientY - rect.top`, as the DOM gives them. `isPrimary` (`pointerId ===
/// 1`) has no field: no listener reads it.
void dispatchPointer(
  HTMLCanvasElement node,
  String type,
  int pointerId,
  num clientX,
  num clientY, [
  EventInit init = const EventInit(),
]) {
  final rect = node.getBoundingClientRect();
  node.dispatchEvent(
    NativeEvent(
      type: type,
      pointerId: pointerId,
      pointerType: init.pointerType ?? 'touch',
      clientX: clientX.toDouble(),
      clientY: clientY.toDouble(),
      offsetX: clientX.toDouble() - rect.left,
      offsetY: clientY.toDouble() - rect.top,
      cancelable: true,
      bubbles: true,
      button: init.button,
      ctrlKey: init.ctrlKey,
      altKey: init.altKey,
      shiftKey: init.shiftKey,
      metaKey: init.metaKey,
    ),
  );
}

/// index.js:82 `jasmine.simulatePan(chart, {deltaX, deltaY, steps,
/// ...init}, done)`: one pointer goes down at the center of the canvas of
/// [chart], moves by ([deltaX], [deltaY]) in [steps] steps and goes up.
/// [init] goes to each pointer event. [done] runs at the end.
///
/// Upstream takes the deltas, the steps and the init members in one object.
/// Dart has no optional positional parameter next to named ones, so [done]
/// is named.
void simulatePan(
  Chart chart, {
  num deltaX = 0,
  num deltaY = 0,
  int steps = 5,
  EventInit init = const EventInit(),
  void Function()? done,
}) {
  final node = chart.canvas!;
  final rect = node.getBoundingClientRect();
  final startX = rect.left + rect.width / 2;
  final startY = rect.top + rect.height / 2;

  dispatchPointer(node, 'pointerdown', 1, startX, startY, init);
  for (var i = 1; i <= steps; i++) {
    final t = i / steps;
    dispatchPointer(
      node,
      'pointermove',
      1,
      startX + deltaX * t,
      startY + deltaY * t,
      init,
    );
  }
  dispatchPointer(
    node,
    'pointerup',
    1,
    startX + deltaX,
    startY + deltaY,
    init,
  );

  if (done != null) {
    done();
  }
}

/// index.js:100 `jasmine.simulatePinch(chart, {pos, scale, steps}, done)`:
/// two pointers go down 80 pixels apart around [pos] of the canvas of
/// [chart] (its center for `null`), spread to [scale] times that gap in
/// [steps] steps and go up. [done] runs at the end.
///
/// [done] is named, as in [simulatePan].
void simulatePinch(
  Chart chart, {
  (num, num)? pos,
  num scale = 2,
  int steps = 5,
  void Function()? done,
}) {
  final node = chart.canvas!;
  final rect = node.getBoundingClientRect();
  final cx = pos != null ? rect.left + pos.$1 : rect.left + rect.width / 2;
  final cy = pos != null ? rect.top + pos.$2 : rect.top + rect.height / 2;
  const startGap = 40;

  List<({double x, double y})> finger(num gap) => [
    (x: cx - gap, y: cy),
    (x: cx + gap, y: cy),
  ];

  final start = finger(startGap);
  dispatchPointer(node, 'pointerdown', 1, start[0].x, start[0].y);
  dispatchPointer(node, 'pointerdown', 2, start[1].x, start[1].y);

  for (var i = 1; i <= steps; i++) {
    final gap = startGap * (1 + (scale - 1) * (i / steps));
    final pts = finger(gap);
    dispatchPointer(node, 'pointermove', 1, pts[0].x, pts[0].y);
    dispatchPointer(node, 'pointermove', 2, pts[1].x, pts[1].y);
  }

  final end = finger(startGap * scale);
  dispatchPointer(node, 'pointerup', 1, end[0].x, end[0].y);
  dispatchPointer(node, 'pointerup', 2, end[1].x, end[1].y);

  if (done != null) {
    done();
  }
}
