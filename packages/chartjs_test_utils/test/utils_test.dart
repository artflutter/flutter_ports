// Original code, not ported from Chart.js: tests of the chart helpers.
@TestOn('vm')
library;

import 'dart:ui';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:clock/clock.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// The chart helpers of chartjs-test-utils 0.4.0 src/utils.js (Chart.js ADR
// 0022, sections 4 to 6).
//
// The groups waitForResize and afterEvent draw on a canvas that no chart
// host shows. Thus their charts get BasicPlatform, with no animations and
// no event listeners. The tests call `chart.resize` and
// `chart.eventHandler` as the platform listeners do.
//
// The other groups use acquireChart in testWidgets bodies. main() has the
// set-up of flutter_test_config.dart that they need: a device pixel ratio
// of 1 (test/index.js:5) and releaseCharts at the unmount of the harness
// body, with a tearDown as the fallback. A chart of a test is the typed
// config of `_config` (Chart.js ADR 0195): a typed config has one dataset
// at least (Chart.js ADR 0190), and a doughnut chart needs no scale. Thus
// main() registers the doughnut controller and the arc element alone. The
// test of the defaults of animation, responsive and locale keeps the Map
// configs of the spec with no type and no dataset: its subject is the Map
// handling of `_acquireChart`.

/// The typed config of a doughnut chart with one dataset and no data, with
/// the options [responsive], [maintainAspectRatio], [animation] and
/// [events] and the inline plugins [plugins].
ChartConfig _config({
  bool? responsive,
  bool? maintainAspectRatio,
  ChartAnimation? animation,
  List<String>? events,
  List<Plugin<Object?>>? plugins,
}) => ChartConfig(
  datasets: const [DoughnutDataset()],
  responsive: responsive,
  maintainAspectRatio: maintainAspectRatio,
  animation: animation,
  events: events,
  plugins: plugins,
);

/// The chart of the typed [config] with the acquisition options [options].
Chart _acquire(ChartConfig config, [Object? options]) =>
    acquireChartRoot(ChartConfigLowering(config).lower(), options);

/// A dataset of the controller id [kind], which no test registers.
final class const _KindDataset(@override final ChartKind kind) extends Dataset {
  @override
  List<Object?>? get chartData => null;

  @override
  void lowerOwn(OptionScope scope) {}

  @override
  List<TypedProperty> get props => [('kind', kind)];
}

/// A chart event of [type] at (10, 10).
final class _Event(@override final String type) implements ChartEvent {
  @override
  final NativeEvent native = NativeEvent(type: type, offsetX: 10, offsetY: 10);

  @override
  double? get x => 10;

  @override
  double? get y => 10;

  @override
  IChart? get chart => null;
}

/// A chart on a new canvas whose `onResize` and `onHover` log into [log].
/// The log starts empty after the construction.
Chart _chart(List<String> log) {
  final chart = Chart(UiCanvasElement(), <String, Object?>{
    'options': <String, Object?>{
      'onResize': (Object? chart, Object? size) => log.add('onResize'),
      'onHover': (Object? e, Object? elements, Object? chart) =>
          log.add('onHover'),
    },
  });
  addTearDown(chart.destroy);
  log.clear();
  return chart;
}

/// The device pixel ratio 1 and the logical size 800 x 600 of the test
/// view, as `flutter_test_config.dart` sets them before each test.
void _forceRatio() {
  TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.implicitView!
    ..devicePixelRatio = 1
    ..physicalSize = const Size(800, 600);
}

/// The size of a `resize` hook, the record of `getMaximumSize`, as text.
String _sizeText(Size size) =>
    '${jsToString(size.width)}x${jsToString(size.height)}';

/// An inline plugin that logs into [log] the hook `resize` with the size
/// and `chart.attached`, and the mode of `beforeUpdate`. It is a native
/// plugin (Chart.js ADRs 0144 and 0148). An absent mode is Dart `null`: the
/// log writes the upstream `undefined`.
Plugin<Object?> _resizeLog(List<String> log) => ChartPlugin<Object?>(
  id: 'resizeLog',
  resize: (chart, args, _) {
    log.add('resize ${chart.attached} ${_sizeText(args.size)}');
  },
  beforeUpdate: (chart, args, _) {
    log.add('update ${jsToString(args.mode ?? undefined)}');
    return true;
  },
);

/// An inline plugin that logs into [log] each event before and after the
/// handler, and each render. It asks for a render after each event. It is
/// a native plugin (Chart.js ADR 0144).
Plugin<Object?> _eventLog(List<String> log) => Plugin<Object?>(
  id: 'eventLog',
  beforeEvent: (chart, args, _) {
    final event = args.event;
    log.add('beforeEvent ${event.type} ${event.native!.type}');
    return true;
  },
  afterEvent: (chart, args, _) {
    final event = args.event;
    log.add(
      'afterEvent ${event.type} ${event.native!.type} '
      '${jsToString(event.x)},${jsToString(event.y)}',
    );
    args.changed = true;
  },
  afterRender: (chart, args, _) {
    log.add('afterRender');
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Chart.register([DoughnutController.jsClass, ArcElement.jsClass]);

  // The set-up of flutter_test_config.dart (Chart.js ADR 0022, section 8).
  _forceRatio();
  setUp(_forceRatio);
  afterEachChart(releaseCharts);
  tearDown(releaseCharts);

  group('waitForResize', () {
    test('calls the callback after the whole resize call', () {
      final log = <String>[];
      final chart = _chart(log);
      final original = chart.resize;
      waitForResize(chart, () => log.add('callback'));
      expect(chart.resize, isNot(same(original)));

      chart.resize(200, 100);
      expect(log, ['onResize', 'callback']);
      expect(chart.width, 200);
      expect(chart.resize, same(original));

      // The replacement runs once.
      chart.resize(150, 100);
      expect(log, ['onResize', 'callback', 'onResize']);
    });
  });

  group('afterEvent', () {
    test('calls the callback after the handler of an event of its type', () {
      final log = <String>[];
      final chart = _chart(log);
      final original = chart.eventHandler;
      afterEvent(chart, 'click', () => log.add('callback'));

      // Another type keeps the replacement.
      chart.eventHandler(_Event('mousemove'));
      expect(log, ['onHover']);
      expect(chart.eventHandler, isNot(same(original)));

      chart.eventHandler(_Event('click'));
      expect(log, ['onHover', 'onHover', 'callback']);
      expect(chart.eventHandler, same(original));
    });

    test('drops the argument replay, as override.call(this, event)', () {
      final log = <String>[];
      final chart = _chart(log);
      final replays = <bool?>[];
      chart.eventHandler = (e, [replay]) => replays.add(replay);
      afterEvent(chart, 'mousemove', () {});

      chart.eventHandler(_Event('mousemove'), true);
      expect(replays, [null]);
    });

    test('matches the type of the native event', () {
      final log = <String>[];
      final chart = _chart(log);
      var called = 0;
      afterEvent(chart, 'pointermove', () => called++);
      // A chart event of the type `mousemove` with a native `pointermove`.
      chart.eventHandler(_NativeEvent('mousemove', 'pointermove'));
      expect(called, 1);
      expect(chart.eventHandler, isA<Function>());
    });
  });

  group('harness-acquire-chart', () {
    test('acquireChart throws a StateError outside a testWidgets body', () {
      final children = document.body.childNodes.length;
      expect(acquireChart, throwsStateError);
      expect(document.body.childNodes, hasLength(children));
    });

    testWidgets('the canvas of 512 x 512 through attributes, in a wrapper of '
        'the class chartjs-wrapper', (tester) async {
      final chart = _acquire(_config());
      final canvas = chart.canvas!;
      final wrapper = canvas.parentElement!;

      expect(canvas.getAttribute('height'), '512');
      expect(canvas.getAttribute('width'), '512');
      // The class chartjs-wrapper with the rule of injectWrapperCSS is an
      // absolute box (Chart.js ADR 0200).
      expect(wrapper.box, const HarnessBox(absolute: true));
      expect(wrapper.parentNode, same(document.body));
      expect(chart, toBeValidChart());
      expect(
        chart,
        toBeChartOfSize({'dw': 512, 'dh': 512, 'rw': 512, 'rh': 512}),
      );
      // The default wrapper is a box of the display size of the canvas.
      expect(wrapper.clientWidth, 512);
      expect(wrapper.clientHeight, 512);
      expect(chart.runtimeType, Chart);
    });

    testWidgets('the canvas and the wrapper of the options', (tester) async {
      final chart = _acquire(
        _config(),
        const AcquireOptions(
          canvas: HarnessCanvas(displayWidth: 150, displayHeight: 245),
          wrapper: HarnessBox(width: 300, height: 350),
        ),
      );
      final canvas = chart.canvas!;
      final wrapper = canvas.parentElement!;

      expect((canvas.displayWidth, canvas.displayHeight), (150, 245));
      // No height attribute in the options: retinaScale (helpers.dom.ts)
      // writes the render size of the display size into the attribute.
      expect(canvas.getAttribute('height'), '245');
      expect(wrapper.box, const HarnessBox(width: 300, height: 350));
      expect(
        chart,
        toBeChartOfSize({'dw': 150, 'dh': 245, 'rw': 150, 'rh': 245}),
      );
    });

    testWidgets('the Map options of the fixture runner', (tester) async {
      // Chart.js ADR 0200, item 8: the numbers of a canvas Map.
      final chart = _acquire(_config(), <String, Object?>{
        'canvas': <String, Object?>{'width': 300.0, 'height': '150'},
        'persistent': true,
      });
      expect(chart.canvas!.getAttribute('width'), '300');
      expect(chart.canvas!.getAttribute('height'), '150');
      expect($test[chart]!.persistent, isTrue);
    });

    test('a Map with CSS text throws an ArgumentError', () {
      expect(
        () => AcquireOptions.of(<String, Object?>{
          'canvas': <String, Object?>{'style': 'width: 150px'},
        }),
        throwsArgumentError,
      );
      expect(
        () => AcquireOptions.of(<String, Object?>{
          'wrapper': <String, Object?>{'style': 'width: 150px'},
        }),
        throwsArgumentError,
      );
      expect(() => AcquireOptions.of(3), throwsArgumentError);
      expect(AcquireOptions.of(null).canvas, isNull);
    });

    testWidgets('the defaults of animation, responsive and locale', (
      tester,
    ) async {
      final config = <String, Object?>{};
      final chart = acquireChart(config);
      final options = config['options']! as Map<String, Object?>;
      // initOptions of core.config adds `plugins` and `scales` after them.
      expect(options.keys.take(3), ['animation', 'responsive', 'locale']);
      expect(options['animation'], false);
      expect(options['responsive'], false);
      // DIVERGES(chartjs): adapt-intl-number-format, the locale is a Locale.
      expect(options['locale'], const Locale('en', 'US'));
      expect(chart.options['animation'], false);
      expect(chart.options['responsive'], false);
      expect(chart.options['locale'], const Locale('en', 'US'));
      expect(chart.config.options, same(options));

      // `=== undefined` keeps every other value, also null. `||` replaces a
      // falsy locale.
      final animation = <String, Object?>{'duration': 0};
      final kept = <String, Object?>{
        'animation': animation,
        'responsive': null,
        'locale': '',
      };
      acquireChart(<String, Object?>{'options': kept});
      expect(kept['animation'], same(animation));
      expect(kept.containsKey('responsive'), isTrue);
      expect(kept['responsive'], isNull);
      expect(kept['locale'], const Locale('en', 'US'));

      final de = <String, Object?>{
        'animation': undefined,
        'responsive': true,
        'locale': const Locale('de', 'DE'),
      };
      acquireChart(<String, Object?>{'options': de});
      expect(de['animation'], false);
      expect(de['responsive'], true);
      expect(de['locale'], const Locale('de', 'DE'));
    });

    testWidgets('FlutterPlatform, and the chart is attached at its '
        'construction', (tester) async {
      final log = <String>[];
      final chart = _acquire(
        _config(
          responsive: true,
          maintainAspectRatio: false,
          plugins: [_resizeLog(log)],
        ),
        const AcquireOptions(
          canvas: HarnessCanvas(),
          wrapper: HarnessBox(width: 300, height: 350),
        ),
      );

      expect(chart.platform, isA<FlutterPlatform>());
      expect(chart.attached, isTrue);
      expect(
        chart,
        toBeChartOfSize({'dw': 300, 'dh': 350, 'rw': 300, 'rh': 350}),
      );
      // The resize of _initialize (core.controller.js:241) runs before
      // bindEvents, and the update of the constructor (:205) follows. No
      // update has the mode 'attach'.
      expect(log, ['resize false 300x350', 'update undefined']);

      // The first notification of the resize observer gives the same size.
      await tester.pump(frameInterval);
      await tester.pump(frameInterval);
      expect(log, ['resize false 300x350', 'update undefined']);
    });

    testWidgets('a chart of Chart() on a canvas of createElement starts '
        'detached on its standby host', (tester) async {
      final canvas = document.createElement<HTMLCanvasElement>('canvas');
      final chart = Chart(canvas, <String, Object?>{
        'options': <String, Object?>{'responsive': true},
      });
      addTearDown(chart.destroy);
      expect(chart.platform, isA<FlutterPlatform>());
      expect(chart.attached, isFalse);
      expect(chart, toBeChartOfSize({'dw': 0, 'dh': 0, 'rw': 0, 'rh': 0}));

      final wrapper = document.createElement<HarnessElement>('div')
        ..box = const HarnessBox(width: 200, height: 100)
        ..appendChild(canvas);
      document.body.appendChild(wrapper);
      addTearDown(wrapper.remove);
      // The mutation checkpoint of the append attaches the chart.
      await Future<void>.value();
      expect(chart.attached, isTrue);
      expect(
        chart,
        toBeChartOfSize({'dw': 200, 'dh': 100, 'rw': 200, 'rh': 100}),
      );
    });

    testWidgets('useOffscreenCanvas gives the chart a canvas that no host '
        'shows, thus BasicPlatform', (tester) async {
      final chart = _acquire(
        _config(animation: const ChartAnimation()),
        const AcquireOptions(useOffscreenCanvas: true),
      );
      final wrappers = document.body.childNodes.whereType<HarnessElement>();
      final placeholder = wrappers.last.childNodes.single;

      expect(chart.platform, isA<BasicPlatform>());
      expect(chart.canvas, isA<UiCanvasElement>());
      expect(chart.canvas, isNot(same(placeholder)));
      expect(chart.canvas!.width, 512);
      expect(chart.canvas!.height, 512);
      // BasicPlatform.updateConfig (platform.basic.js:20-22).
      expect(chart.options['animation'], false);
    });

    testWidgets('useShadowDOM throws an UnsupportedError before the append', (
      tester,
    ) async {
      final children = document.body.childNodes.length;
      expect(
        () => _acquire(_config(), const AcquireOptions(useShadowDOM: true)),
        throwsUnsupportedError,
      );
      expect(document.body.childNodes, hasLength(children));
    });

    testWidgets('a throw of the chart removes the wrapper', (tester) async {
      final children = document.body.childNodes.length;
      final instances = Chart.instances.length;
      expect(
        () => _acquire(
          const ChartConfig(
            datasets: [_KindDataset(ChartKind('harnessMissing'))],
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            '"harnessMissing" is not a registered controller.',
          ),
        ),
      );
      expect(document.body.childNodes, hasLength(children));
      // The chart of the throw stays in Chart.instances, as upstream.
      expect(Chart.instances, hasLength(instances + 1));
      Chart.instances.values.last.destroy();
    });

    testWidgets('acquireChart throws a StateError in a layout, and the '
        'wrapper leaves the body', (tester) async {
      final canvas = document.createElement<HTMLCanvasElement>('canvas');
      final chart = Chart(canvas, <String, Object?>{
        'options': <String, Object?>{'responsive': true},
      });
      addTearDown(chart.destroy);
      final children = <int>[];
      Object? error;
      // The attach of the host calls the replacement inside the forced
      // layout of the mutation checkpoint.
      waitForResize(chart, () {
        children.add(document.body.childNodes.length);
        try {
          _acquire(_config());
        } on Object catch (e) {
          error = e;
        }
        children.add(document.body.childNodes.length);
      });
      final wrapper = document.createElement<HarnessElement>('div')
        ..appendChild(canvas)
        ..box = const HarnessBox(width: 200, height: 100);
      document.body.appendChild(wrapper);
      addTearDown(wrapper.remove);
      await Future<void>.value();
      expect(error, isA<StateError>());
      expect(children, hasLength(2));
      expect(children[1], children[0]);
    });
  });

  group('harness-trigger-mouse-event', () {
    /// A chart of 200 x 100 with the events [events], whose plugin logs
    /// into [log].
    Chart eventChart(List<String> log, [List<String>? events]) => _acquire(
      _config(events: events, plugins: [_eventLog(log)]),
      const AcquireOptions(canvas: HarnessCanvas(width: 200, height: 100)),
    );

    testWidgets('one frame of 16 ms, after the whole handler', (tester) async {
      final log = <String>[];
      final chart = eventChart(log);
      // The first render of the chart.
      log.clear();
      final start = clock.now();

      final future = triggerMouseEvent(chart, 'mousemove', {'x': 10, 'y': 20});
      // The throttled proxy calls the chart in the next frame.
      expect(log, isEmpty);
      final event = await future;
      log.add('resolved');

      expect(clock.now().difference(start), frameInterval);
      expect(log, [
        'beforeEvent mousemove mousemove',
        'afterEvent mousemove mousemove 10,20',
        'afterRender',
        'resolved',
      ]);
      expect(event.type, 'mousemove');
      expect(event.offsetX, 10);
      expect(event.offsetY, 20);
      expect(event.target, same(chart.canvas));
      // The afterEvent replacement is gone after the callback.
      expect(chart.eventHandler, isA<Function>());
    });

    testWidgets('the event is cancelable and bubbles to the document of the '
        'canvas', (tester) async {
      final chart = eventChart(<String>[]);
      final canvas = chart.canvas!;
      final owner = canvas.ownerDocument;
      final seen = <String>[];
      void onCanvas(NativeEvent event) => seen.add('canvas');
      void onDocument(NativeEvent event) {
        seen.add('document ${identical(event.target, canvas)}');
        event.preventDefault();
      }

      canvas.addEventListener('mousemove', onCanvas);
      owner.addEventListener('mousemove', onDocument, passive: false);
      addTearDown(() {
        canvas.removeEventListener('mousemove', onCanvas);
        owner.removeEventListener('mousemove', onDocument);
      });

      final event = await triggerMouseEvent(chart, 'mousemove', {
        'x': 10,
        'y': 20,
      });
      // utils.js:167-173: the event of the canvas reaches the document in
      // the bubble phase, with the canvas as its target.
      expect(seen, ['canvas', 'document true']);
      expect(event.bubbles, isTrue);
      expect(event.cancelable, isTrue);
      expect(event.defaultPrevented, isTrue);
      expect(event.target, same(canvas));
    });

    testWidgets('the client point is the box of the canvas plus the point', (
      tester,
    ) async {
      // The wrapper of zoom.drag.spec.js:441 of chartjs-plugin-zoom.
      final log = <String>[];
      final chart = _acquire(
        _config(plugins: [_eventLog(log)]),
        const AcquireOptions(
          canvas: HarnessCanvas(width: 200, height: 100),
          wrapper: HarnessBox(absolute: true, offset: Offset(50, 30)),
        ),
      );
      expect(
        chart.canvas!.getBoundingClientRect(),
        const DOMRect(50, 30, 200, 100),
      );
      log.clear();

      final event = await triggerMouseEvent(chart, 'mousemove', {
        'x': 10.5,
        'y': 20,
      });
      expect((event.clientX, event.clientY), (60.5, 50.0));
      // The offsets stay the point, which getRelativePosition reads.
      expect((event.offsetX, event.offsetY), (10.5, 20.0));
      expect(log[1], 'afterEvent mousemove mousemove 11,20');

      // The default wrapper of acquireChart is at the top left corner of
      // the body: the client point is the point.
      final other = eventChart(<String>[]);
      expect(
        other.canvas!.getBoundingClientRect(),
        const DOMRect(0, 0, 200, 100),
      );
      final second = await triggerMouseEvent(other, 'mousemove', {
        'x': 7,
        'y': 8,
      });
      expect((second.clientX, second.clientY), (7.0, 8.0));
    });

    testWidgets('the event types: click, mouseout, the custom types test and '
        'test2, and pointerleave', (tester) async {
      final log = <String>[];
      final chart = eventChart(log, [
        'click',
        'mouseout',
        'test',
        'test2',
        'pointerleave',
      ]);
      log.clear();

      await triggerMouseEvent(chart, 'click', {'x': 1, 'y': 2});
      await triggerMouseEvent(chart, 'test', {'x': 0, 'y': 0});
      await triggerMouseEvent(chart, 'test2', {'x': 0, 'y': 0});
      // platform.dom.js:21 EVENT_TYPES maps pointerleave to mouseout.
      await triggerMouseEvent(chart, 'pointerleave', {'x': 0, 'y': 0});
      // A mouseout keeps the point of the spec, also inside the chart.
      await triggerMouseEvent(chart, 'mouseout', {'x': 100, 'y': 50});

      expect(log.where((line) => line.startsWith('afterEvent')), [
        'afterEvent click click 1,2',
        'afterEvent test test 0,0',
        'afterEvent test2 test2 0,0',
        'afterEvent mouseout pointerleave 0,0',
        'afterEvent mouseout mouseout 100,50',
      ]);
    });

    testWidgets('the chart event has the Chrome position of a synthetic '
        'MouseEvent', (tester) async {
      final log = <String>[];
      final chart = eventChart(log);
      // Chart.js ADR 0022, probe SP1 (headless Chrome 155): the point and
      // the offsets of the event.
      const points = [
        ((100.0, 50.0), '100,50'),
        ((100.2, 50.2), '100,50'),
        ((100.5, 50.5), '101,51'),
        ((100.7, 50.7), '101,51'),
        ((30.4999, 0.6), '30,1'),
        ((255.75, 128.25), '256,128'),
      ];
      for (final ((x, y), expected) in points) {
        log.clear();
        final event = await triggerMouseEvent(chart, 'mousemove', {
          'x': x,
          'y': y,
        });
        expect(log[1], 'afterEvent mousemove mousemove $expected');
        // The native event keeps the fraction.
        expect(event.offsetX, x);
        expect(event.offsetY, y);
      }
    });

    testWidgets('the point of an element, of a point, of a Map and of '
        'another value', (tester) async {
      final chart = eventChart(<String>[]);
      final element = PointElement(<String, Object?>{'x': 30.0, 'y': 40.0});

      Future<(double, double)> offsets(Object? el) async {
        final event = await triggerMouseEvent(chart, 'mousemove', el);
        return (event.offsetX, event.offsetY);
      }

      // `getCenterPoint()` of an element.
      expect(await offsets(element), (30.0, 40.0));
      // `el.x` and `el.y` of a point and of a Map.
      expect(await offsets(const _XY(5, 6)), (5.0, 6.0));
      expect(await offsets({'x': 7, 'y': 8}), (7.0, 8.0));
      // JS null gives 0 in `rect.left + point.x`.
      expect(await offsets({'x': null, 'y': 8}), (0.0, 8.0));
      // An undefined coordinate, no value and a line element (no
      // getCenterPoint, no x) give (0, 0).
      expect(await offsets({'x': 7}), (0.0, 0.0));
      expect(await offsets({'x': 7, 'y': undefined}), (0.0, 0.0));
      expect(await offsets(null), (0.0, 0.0));
      expect(await offsets(LineElement()), (0.0, 0.0));
    });

    testWidgets('a type without a listener fails with the Jasmine timeout', (
      tester,
    ) async {
      final chart = eventChart(<String>[]);
      final start = clock.now();
      await expectLater(
        triggerMouseEvent(chart, 'pointerdown'),
        throwsA(
          isA<TestFailure>().having(
            (e) => e.message,
            'message',
            'Timeout - Async function did not complete within 5000ms',
          ),
        ),
      );
      expect(clock.now().difference(start), greaterThanOrEqualTo(specTimeout));
    });
  });

  // The spec shapes of the host changes (Chart.js ADR 0022, sections 10 and
  // 11). Each test ports one case of core.controller.tests.js line by line,
  // as a check of the harness: the spec file ports the case itself.
  group('the host changes, on the shapes of core.controller.tests.js', () {
    ChartConfig responsive([List<Plugin<Object?>>? plugins]) =>
        _config(responsive: true, maintainAspectRatio: false, plugins: plugins);

    testWidgets(':657 should resize the canvas when parent width changes', (
      tester,
    ) async {
      await waitForDone((done) {
        final chart = _acquire(
          responsive(),
          const AcquireOptions(
            canvas: HarnessCanvas(),
            wrapper: HarnessBox(width: 300, height: 350),
          ),
        );

        expect(
          chart,
          toBeChartOfSize({'dw': 300, 'dh': 350, 'rw': 300, 'rh': 350}),
        );

        final wrapper = chart.canvas!.parentElement!;
        waitForResize(chart, () {
          expect(
            chart,
            toBeChartOfSize({'dw': 455, 'dh': 350, 'rw': 455, 'rh': 350}),
          );

          waitForResize(chart, () {
            expect(
              chart,
              toBeChartOfSize({'dw': 150, 'dh': 350, 'rw': 150, 'rh': 350}),
            );

            done();
          });
          wrapper.width = 150;
        });
        wrapper.width = 455;
      });
    });

    testWidgets(':697 should restore the original size when parent became '
        'invisible', (tester) async {
      await waitForDone((done) {
        final chart = _acquire(
          responsive(),
          const AcquireOptions(
            canvas: HarnessCanvas(),
            wrapper: HarnessBox(width: 300, height: 350),
          ),
        );

        waitForResize(chart, () {
          expect(
            chart,
            toBeChartOfSize({'dw': 300, 'dh': 350, 'rw': 300, 'rh': 350}),
          );

          final original = chart.resize;
          chart.resize = ([width, height]) {
            fail('resize should not have been called');
          };

          final wrapper = chart.canvas!.parentElement!..hidden = true;

          setTimeout(() {
            expect(wrapper.clientWidth, 0);
            expect(wrapper.clientHeight, 0);

            expect(
              chart,
              toBeChartOfSize({'dw': 300, 'dh': 350, 'rw': 300, 'rh': 350}),
            );

            chart.resize = original;

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 300, 'dh': 350, 'rw': 300, 'rh': 350}),
              );

              done();
            });
            wrapper.hidden = false;
          }, 200);
        });
      });
    });

    // The auto height of a static block wrapper (an Open item of Chart.js
    // ADR 0022). The wrapper takes the width 600 of its max-width. Its
    // content height is the display height 0 of the canvas. Then
    // getMaximumSize gives the height `width / 2` (helpers.dom.ts:186-190).
    testWidgets(':918 should resize the canvas when the wrapper has display '
        'style changes from "none" to "block"', (tester) async {
      await waitForDone((done) {
        // https://github.com/chartjs/Chart.js/issues/4659
        final chart = _acquire(
          responsive(),
          const AcquireOptions(
            canvas: HarnessCanvas(),
            wrapper: HarnessBox(maxWidth: 600, maxHeight: 400, hidden: true),
          ),
        );

        final wrapper = chart.canvas!.parentElement!;
        waitForResize(chart, () {
          expect(
            chart,
            toBeChartOfSize({'dw': 600, 'dh': 300, 'rw': 600, 'rh': 300}),
          );

          done();
        });
        wrapper.hidden = false;
      });
    });

    testWidgets(':1065 should resize the canvas after the wrapper has been '
        're-attached to the DOM', (tester) async {
      final log = <String>[];
      await waitForDone((done) {
        final chart = _acquire(
          responsive([_resizeLog(log)]),
          const AcquireOptions(
            canvas: HarnessCanvas(),
            wrapper: HarnessBox(width: 320, height: 350),
          ),
        );

        expect(
          chart,
          toBeChartOfSize({'dw': 320, 'dh': 350, 'rw': 320, 'rh': 350}),
        );

        final wrapper = chart.canvas!.parentElement!;
        final parent = wrapper.parentNode!;

        waitForResize(chart, () {
          expect(
            chart,
            toBeChartOfSize({'dw': 320, 'dh': 355, 'rw': 320, 'rh': 355}),
          );

          waitForResize(chart, () {
            expect(
              chart,
              toBeChartOfSize({'dw': 455, 'dh': 355, 'rw': 455, 'rh': 355}),
            );

            done();
          });

          parent.removeChild(wrapper);
          wrapper.width = 455;
          parent.appendChild(wrapper);
        });

        parent.removeChild(wrapper);
        setTimeout(
          () {
            parent.appendChild(wrapper);
            wrapper.height = 355;
          },
          // The upstream text passes the delay 0.
          // ignore: avoid_redundant_argument_values
          0,
        );
      });
      // The attach at the construction, the detach and the attach of the
      // setTimeout task, with the update modes default (undefined), attach
      // and resize (core.controller.js:276 `this.width ? 'resize' :
      // 'attach'`).
      expect(log, [
        'resize false 320x350',
        'update undefined',
        'resize false 0x0',
        'resize true 320x355',
        'update attach',
        'resize true 455x355',
        'update resize',
      ]);
    });

    testWidgets(':1116 should detect detach/attach in series', (tester) async {
      final log = <String>[];
      await waitForDone((done) {
        final chart = _acquire(
          responsive([_resizeLog(log)]),
          const AcquireOptions(
            canvas: HarnessCanvas(),
            wrapper: HarnessBox(width: 320, height: 350),
          ),
        );

        final wrapper = chart.canvas!.parentElement!;
        final parent = wrapper.parentNode!;

        waitForResize(chart, () {
          expect(
            chart,
            toBeChartOfSize({'dw': 320, 'dh': 350, 'rw': 320, 'rh': 350}),
          );

          done();
        });

        parent
          ..removeChild(wrapper)
          ..appendChild(wrapper);
      });
      // The removal and the append of one task give no detach.
      expect(log, ['resize false 320x350', 'update undefined']);
    });

    testWidgets(':1147 should detect detach/attach/detach in series', (
      tester,
    ) async {
      final log = <String>[];
      await waitForDone((done) {
        final chart = _acquire(
          responsive([_resizeLog(log)]),
          const AcquireOptions(
            canvas: HarnessCanvas(),
            wrapper: HarnessBox(width: 320, height: 350),
          ),
        );

        final wrapper = chart.canvas!.parentElement!;
        final parent = wrapper.parentNode!;

        waitForResize(chart, () {
          fail('Failed');
        });

        parent
          ..removeChild(wrapper)
          ..appendChild(wrapper)
          ..removeChild(wrapper);

        setTimeout(() {
          expect(chart.attached, isFalse);
          done();
        }, 100);
      });
      expect(log, [
        'resize false 320x350',
        'update undefined',
        'resize false 0x0',
      ]);
    });

    testWidgets(':1179 should detect attach/detach in series', (tester) async {
      await waitForDone((done) {
        final chart = _acquire(
          responsive(),
          const AcquireOptions(
            canvas: HarnessCanvas(),
            wrapper: HarnessBox(width: 320, height: 350),
          ),
        );

        final wrapper = chart.canvas!.parentElement!;
        final parent = wrapper.parentNode!;

        // The upstream statements stay apart.
        // ignore: cascade_invocations
        parent.removeChild(wrapper);

        setTimeout(() {
          expect(chart.attached, isFalse);

          waitForResize(chart, () {
            fail('Failed');
          });

          parent
            ..appendChild(wrapper)
            ..removeChild(wrapper);

          setTimeout(() {
            expect(chart.attached, isFalse);

            done();
          }, 100);
        }, 100);
      });
    });

    testWidgets(':1218 should resize the canvas when re-creating the chart', (
      tester,
    ) async {
      await waitForDone((done) {
        var chart = _acquire(
          _config(responsive: true),
          const AcquireOptions(wrapper: HarnessBox(width: 320)),
        );

        final wrapper = chart.canvas!.parentElement!;

        waitForResize(chart, () {
          final canvas = chart.canvas!;
          expect(
            chart,
            toBeChartOfSize({'dw': 320, 'dh': 320, 'rw': 320, 'rh': 320}),
          );

          chart.destroy();
          chart = Chart(canvas, <String, Object?>{
            'type': 'line',
            'options': <String, Object?>{'responsive': true},
          });

          waitForResize(chart, () {
            expect(
              chart,
              toBeChartOfSize({'dw': 455, 'dh': 455, 'rw': 455, 'rh': 455}),
            );

            chart.destroy();
            document.body.removeChild(wrapper);
            done();
          });
          canvas.parentElement!.width = 455;
          canvas.parentElement!.height = 455;
        });
      });
    });
  });
}

/// A chart event of `type` with a native event of `nativeType`.
final class _NativeEvent(super.type, String nativeType) extends _Event {
  final NativeEvent _native = NativeEvent(
    type: nativeType,
    offsetX: 10,
    offsetY: 10,
  );

  @override
  NativeEvent get native => _native;
}

/// A point `{x, y}` that is not an element.
final class const _XY(@override final double x, @override final double y)
    implements Point;
