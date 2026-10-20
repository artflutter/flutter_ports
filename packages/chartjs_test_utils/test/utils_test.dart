// Original code, not ported from Chart.js: tests of the chart helpers.
@TestOn('vm')
library;

import 'dart:ui' show Size;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:clock/clock.dart';
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/elements/element.line.dart';
import 'package:flutter_chartjs/src/elements/element.point.dart';
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/platform/native_event.dart';
import 'package:flutter_chartjs/src/platform/platform.basic.dart';
import 'package:flutter_chartjs/src/platform/platform.flutter.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

// The tests replace and call `Chart.eventHandler`, which only the harness
// reads.
// ignore_for_file: invalid_use_of_internal_member

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
// body, with a tearDown as the fallback. The test file registers no
// built-in component: the charts have no type and no dataset.

/// A chart event of [type] at (10, 10).
final class _Event implements types.ChartEvent {
  _Event(this.type)
    : native = NativeEvent(type: type, offsetX: 10, offsetY: 10);

  @override
  final String type;

  @override
  final NativeEvent native;

  @override
  double? get x => 10;

  @override
  double? get y => 10;

  @override
  types.Chart? get chart => null;
}

/// A chart on a new canvas whose `onResize` and `onHover` log into [log].
/// The log starts empty after the construction.
Chart _chart(List<String> log) {
  final chart = Chart(UiCanvasElement(), <String, Object?>{
    'options': <String, Object?>{
      'onResize': (Object? chart, Object? size) => log.add('onResize'),
      'onHover': (Object? e) => log.add('onHover'),
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
String _sizeText(Object? size) {
  final (:width, :height) = size! as ({double width, double height});
  return '${jsToString(width)}x${jsToString(height)}';
}

/// An inline plugin that logs into [log] the hook `resize` with the size
/// and `chart.attached`, and the mode of `beforeUpdate`.
Map<String, Object?> _resizeLog(List<String> log) => <String, Object?>{
  'id': 'resizeLog',
  'resize': (Object? chart, Object? args, Object? options) {
    log.add(
      'resize ${(chart! as Chart).attached} ${_sizeText(jsGet(args, 'size'))}',
    );
  },
  'beforeUpdate': (Object? chart, Object? args, Object? options) {
    log.add('update ${jsToString(jsGet(args, 'mode'))}');
  },
};

/// An inline plugin that logs into [log] each event before and after the
/// handler, and each render. It asks for a render after each event.
Map<String, Object?> _eventLog(List<String> log) => <String, Object?>{
  'id': 'eventLog',
  'beforeEvent': (Object? chart, Object? args, Object? options) {
    final event = jsGet(args, 'event')! as types.ChartEvent;
    log.add('beforeEvent ${event.type} ${event.native!.type}');
  },
  'afterEvent': (Object? chart, Object? args, Object? options) {
    final event = jsGet(args, 'event')! as types.ChartEvent;
    log.add(
      'afterEvent ${event.type} ${event.native!.type} '
      '${jsToString(event.x)},${jsToString(event.y)}',
    );
    (args! as Map<String, Object?>)['changed'] = true;
  },
  'afterRender': (Object? chart, Object? args, Object? options) {
    log.add('afterRender');
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      expect(jsIsFunction(chart.eventHandler), isTrue);
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
      final options = <String, Object?>{};
      final chart = acquireChart(null, options);
      final canvas = chart.canvas!;
      final wrapper = canvas.parentElement!;

      expect(canvas.getAttribute('height'), '512');
      expect(canvas.getAttribute('width'), '512');
      expect(wrapper.getAttribute('class'), 'chartjs-wrapper');
      expect(wrapper.parentNode, same(document.body));
      expect(chart, toBeValidChart());
      expect(
        chart,
        toBeChartOfSize({'dw': 512, 'dh': 512, 'rw': 512, 'rh': 512}),
      );
      // The default wrapper is a box of the display size of the canvas.
      expect(wrapper.clientWidth, 512);
      expect(wrapper.clientHeight, 512);
      // utils.js:43-44 write the defaults into the options.
      expect(options['canvas'], {'height': 512, 'width': 512});
      expect(options['wrapper'], {'class': 'chartjs-wrapper'});
      expect(chart.runtimeType, Chart);
    });

    testWidgets('the attributes of the options canvas and wrapper', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{}, <String, Object?>{
        'canvas': <String, Object?>{
          'style': 'width: 150px; height: 245px',
          'data-index': 3,
        },
        'wrapper': <String, Object?>{
          'style': 'width: 300px; height: 350px',
          'id': 'acquired',
        },
      });
      final canvas = chart.canvas!;
      final wrapper = canvas.parentElement!;

      // initCanvas (platform.dom.js:46-66) adds its style declarations.
      expect(
        canvas.getAttribute('style'),
        'width: 150px; height: 245px; display: block; box-sizing: border-box;',
      );
      // setAttribute applies ToString to the value.
      expect(canvas.getAttribute('data-index'), '3');
      // No height attribute in the options: retinaScale (helpers.dom.ts)
      // writes the render size of the display size into the attribute.
      expect(canvas.getAttribute('height'), '245');
      expect(wrapper.getAttribute('style'), 'width: 300px; height: 350px');
      expect(document.getElementById<HarnessElement>('acquired'), wrapper);
      expect(wrapper.getAttribute('class'), isNull);
      expect(
        chart,
        toBeChartOfSize({'dw': 150, 'dh': 245, 'rw': 150, 'rh': 245}),
      );
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
      expect(options['locale'], 'en-US');
      expect(chart.options['animation'], false);
      expect(chart.options['responsive'], false);
      expect(chart.options['locale'], 'en-US');
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
      expect(kept['locale'], 'en-US');

      final de = <String, Object?>{
        'animation': undefined,
        'responsive': true,
        'locale': 'de-DE',
      };
      acquireChart(<String, Object?>{'options': de});
      expect(de['animation'], false);
      expect(de['responsive'], true);
      expect(de['locale'], 'de-DE');
    });

    testWidgets('FlutterPlatform, and the chart is attached at its '
        'construction', (tester) async {
      final log = <String>[];
      final chart = acquireChart(
        <String, Object?>{
          'options': <String, Object?>{
            'responsive': true,
            'maintainAspectRatio': false,
          },
          'plugins': [_resizeLog(log)],
        },
        <String, Object?>{
          'canvas': <String, Object?>{'style': ''},
          'wrapper': <String, Object?>{'style': 'width: 300px; height: 350px'},
        },
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

      final wrapper = document.createElement<HarnessElement>('div');
      wrapper.style.cssText = 'width: 200px; height: 100px';
      wrapper.appendChild(canvas);
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
      final chart = acquireChart(
        <String, Object?>{
          'options': <String, Object?>{'animation': <String, Object?>{}},
        },
        <String, Object?>{'useOffscreenCanvas': true},
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
        () => acquireChart(null, <String, Object?>{'useShadowDOM': true}),
        throwsUnsupportedError,
      );
      expect(document.body.childNodes, hasLength(children));
    });

    testWidgets('a throw of the chart removes the wrapper', (tester) async {
      final children = document.body.childNodes.length;
      final instances = Chart.instances.length;
      expect(
        () => acquireChart(<String, Object?>{
          'type': 'harnessMissing',
          'data': <String, Object?>{
            'datasets': [<String, Object?>{}],
          },
        }),
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
          acquireChart();
        } on Object catch (e) {
          error = e;
        }
        children.add(document.body.childNodes.length);
      });
      final wrapper = document.createElement<HarnessElement>('div')
        ..appendChild(canvas);
      wrapper.style.cssText = 'width: 200px; height: 100px';
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
    Chart eventChart(List<String> log, [List<String>? events]) => acquireChart(
      <String, Object?>{
        'options': <String, Object?>{'events': ?events},
        'plugins': [_eventLog(log)],
      },
      <String, Object?>{
        'canvas': <String, Object?>{'height': 100, 'width': 200},
      },
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
      expect(jsIsFunction(chart.eventHandler), isTrue);
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
      expect(await offsets(const ElementPoint(5, 6)), (5.0, 6.0));
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
    Map<String, Object?> responsive([List<Object?>? plugins]) =>
        <String, Object?>{
          'options': <String, Object?>{
            'responsive': true,
            'maintainAspectRatio': false,
          },
          'plugins': ?plugins,
        };

    testWidgets(':657 should resize the canvas when parent width changes', (
      tester,
    ) async {
      await waitForDone((done) {
        final chart = acquireChart(responsive(), <String, Object?>{
          'canvas': <String, Object?>{'style': ''},
          'wrapper': <String, Object?>{
            'style': 'width: 300px; height: 350px; position: relative',
          },
        });

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
          wrapper.style.width = '150px';
        });
        wrapper.style.width = '455px';
      });
    });

    testWidgets(':697 should restore the original size when parent became '
        'invisible', (tester) async {
      await waitForDone((done) {
        final chart = acquireChart(responsive(), <String, Object?>{
          'canvas': <String, Object?>{'style': ''},
          'wrapper': <String, Object?>{
            'style': 'width: 300px; height: 350px; position: relative',
          },
        });

        waitForResize(chart, () {
          expect(
            chart,
            toBeChartOfSize({'dw': 300, 'dh': 350, 'rw': 300, 'rh': 350}),
          );

          final original = chart.resize;
          chart.resize = ([width, height]) {
            fail('resize should not have been called');
          };

          final wrapper = chart.canvas!.parentElement!;
          wrapper.style.display = 'none';

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
            wrapper.style.display = 'block';
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
        final chart = acquireChart(responsive(), <String, Object?>{
          'canvas': <String, Object?>{'style': ''},
          'wrapper': <String, Object?>{
            'style': 'display: none; max-width: 600px; max-height: 400px;',
          },
        });

        final wrapper = chart.canvas!.parentElement!;
        waitForResize(chart, () {
          expect(
            chart,
            toBeChartOfSize({'dw': 600, 'dh': 300, 'rw': 600, 'rh': 300}),
          );

          done();
        });
        wrapper.style.display = 'block';
      });
    });

    testWidgets(':1065 should resize the canvas after the wrapper has been '
        're-attached to the DOM', (tester) async {
      final log = <String>[];
      await waitForDone((done) {
        final chart = acquireChart(responsive([_resizeLog(log)]), {
          'canvas': <String, Object?>{'style': ''},
          'wrapper': <String, Object?>{'style': 'width: 320px; height: 350px'},
        });

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
          wrapper.style.width = '455px';
          parent.appendChild(wrapper);
        });

        parent.removeChild(wrapper);
        setTimeout(
          () {
            parent.appendChild(wrapper);
            wrapper.style.height = '355px';
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
        final chart = acquireChart(responsive([_resizeLog(log)]), {
          'canvas': <String, Object?>{'style': ''},
          'wrapper': <String, Object?>{'style': 'width: 320px; height: 350px'},
        });

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
        final chart = acquireChart(responsive([_resizeLog(log)]), {
          'canvas': <String, Object?>{'style': ''},
          'wrapper': <String, Object?>{'style': 'width: 320px; height: 350px'},
        });

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
        final chart = acquireChart(responsive(), <String, Object?>{
          'canvas': <String, Object?>{'style': ''},
          'wrapper': <String, Object?>{'style': 'width: 320px; height: 350px'},
        });

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
        var chart = acquireChart(
          <String, Object?>{
            'options': <String, Object?>{'responsive': true},
          },
          <String, Object?>{
            'wrapper': <String, Object?>{'style': 'width: 320px'},
          },
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
          canvas.parentElement!.style.width = '455px';
          canvas.parentElement!.style.height = '455px';
        });
      });
    });
  });
}

/// A chart event of `type` with a native event of `nativeType`.
final class _NativeEvent extends _Event {
  _NativeEvent(super.type, String nativeType)
    : _native = NativeEvent(type: nativeType, offsetX: 10, offsetY: 10);

  final NativeEvent _native;

  @override
  NativeEvent get native => _native;
}
