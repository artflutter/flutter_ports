// Original code, not ported from Chart.js: tests of the DOM stand-in.
@TestOn('vm')
library;

import 'dart:async';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:clock/clock.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0022, sections 3, 7 and 8: the DOM stand-in, the harness
// body, the writes that wait, the mutation checkpoint, the harness tasks
// and the unmount. The flutter test view is 800 x 600 logical pixels.

/// The host that shows [canvas], or its standby host.
RenderChartHost _hostOf(HTMLCanvasElement canvas) =>
    (canvas as UiCanvasElement).parentNode! as RenderChartHost;

/// The content box that the host of [canvas] has: the max size of its
/// constraints.
Size _containerOf(HTMLCanvasElement canvas) {
  final host = _hostOf(canvas);
  return Size(host.contentWidth, host.contentHeight);
}

/// A div with the box [box], with [canvas] (a new canvas of 300 x 150 by
/// default) as its child, appended to the body.
(HarnessElement, HTMLCanvasElement) _wrap(
  HarnessBox box, {
  HTMLCanvasElement? canvas,
}) {
  final wrapper = document.createElement<HarnessElement>('div')..box = box;
  final child = canvas ?? document.createElement<HTMLCanvasElement>('canvas');
  wrapper.appendChild(child);
  document.body.appendChild(wrapper);
  return (wrapper, child);
}

/// Lets the microtasks of the test body run: the mutation checkpoint.
Future<void> _checkpoint() => Future<void>.value();

int _unmounts = 0;

late RenderChartHost _standbyOfLastTest;

bool _leakedTaskRan = false;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  afterEachChart(() => _unmounts++);

  // The DOM stays between the tests, as upstream. Each test leaves an empty
  // body.
  tearDown(() {
    List.of(document.body.childNodes).forEach(document.body.removeChild);
  });

  group('document', () {
    testWidgets('createElement gives a div and a canvas with a standby host', (
      tester,
    ) async {
      final div = document.createElement<HarnessElement>('div');
      final canvas = document.createElement<HTMLCanvasElement>('canvas');
      expect(div.parentNode, isNull);
      expect(div.childNodes, isEmpty);
      expect(canvas, isA<UiCanvasElement>());
      final standby = _hostOf(canvas);
      expect(standby.attached, isFalse);
      // A chart on the canvas gets FlutterPlatform and starts detached.
      expect(detectPlatform(canvas)(), isA<FlutterPlatform>());
      expect(FlutterPlatform().isAttached(canvas), isFalse);
      expect((canvas.width, canvas.height), (300, 150));
      _standbyOfLastTest = standby;
    });

    testWidgets('the end of a test disposes its standby hosts', (tester) async {
      expect(_standbyOfLastTest.debugDisposed, isTrue);
    });

    test('createElement throws for another tag or type', () {
      expect(
        () => document.createElement<HarnessElement>('span'),
        throwsArgumentError,
      );
      expect(
        () => document.createElement<HTMLCanvasElement>('div'),
        throwsArgumentError,
      );
      expect(document.createElement<Object>('DIV'), isA<HarnessElement>());
    });

    testWidgets('getElementById searches the tree of the body', (tester) async {
      final wrapper = document.createElement<HarnessElement>('div')
        ..setAttribute('id', 'wrapper');
      final canvas = document.createElement<HTMLCanvasElement>('canvas')
        ..setAttribute('id', 'chart-canvas');
      wrapper.appendChild(canvas);
      expect(document.getElementById<Object>('wrapper'), isNull);
      document.body.appendChild(wrapper);
      expect(document.getElementById<HarnessElement>('wrapper'), same(wrapper));
      expect(
        document.getElementById<HTMLCanvasElement>('chart-canvas'),
        same(canvas),
      );
      expect(
        () => document.getElementById<HTMLCanvasElement>('wrapper'),
        throwsArgumentError,
      );
      canvas.remove();
      expect(document.getElementById<Object>('chart-canvas'), isNull);
      expect(document.getElementById<Object>('none'), isNull);
    });
  });

  group('tree', () {
    test('appendChild moves a node, and removeChild removes it', () {
      final first = document.createElement<HarnessElement>('div');
      final second = document.createElement<HarnessElement>('div');
      final child = document.createElement<HarnessElement>('div');
      first.appendChild(child);
      expect(child.parentNode, same(first));
      second.appendChild(child);
      expect(child.parentNode, same(second));
      expect(first.childNodes, isEmpty);
      expect(second.childNodes, [same(child)]);
      expect(second.contains(child), isTrue);
      expect(second.contains(second), isTrue);
      expect(child.contains(second), isFalse);
      second.removeChild(child);
      expect(child.parentNode, isNull);
      // remove() without a parent does nothing.
      child.remove();
    });

    testWidgets('a canvas has its element as the parent element', (
      tester,
    ) async {
      final wrapper = document.createElement<HarnessElement>('div');
      final canvas = document.createElement<HTMLCanvasElement>('canvas');
      expect(canvas.parentElement, isNull);
      wrapper.appendChild(canvas);
      expect(canvas.parentElement, same(wrapper));
      expect(wrapper.contains(canvas), isTrue);
      canvas.remove();
      expect(canvas.parentElement, isNull);
      expect(wrapper.childNodes, isEmpty);
    });

    test('the DOM errors', () {
      final parent = document.createElement<HarnessElement>('div');
      final child = document.createElement<HarnessElement>('div');
      parent.appendChild(child);
      // HierarchyRequestError.
      expect(() => child.appendChild(parent), throwsStateError);
      expect(() => child.appendChild(child), throwsStateError);
      expect(() => child.appendChild(document.body), throwsStateError);
      // NotFoundError.
      expect(() => child.removeChild(parent), throwsStateError);
      // Not a node.
      expect(() => parent.appendChild('text'), throwsArgumentError);
    });
  });

  group('box and attributes', () {
    test('the box fields of an element', () {
      final div = document.createElement<HarnessElement>('div')
        ..box = const HarnessBox(width: 300, height: 350);
      expect((div.width, div.height), (300, 350));
      div.hidden = true;
      expect(div.box, const HarnessBox(width: 300, height: 350, hidden: true));
      // A box write replaces each field, as a write of `style.cssText`.
      div.box = const HarnessBox(width: 455, height: 355);
      expect(div.hidden, isFalse);
      div
        ..maxWidth = 10
        ..maxHeight = 20
        ..padding = const EdgeInsets.all(1)
        ..absolute = true
        ..offset = const Offset(5, -6)
        ..direction = TextDirection.rtl
        ..width = null;
      expect(
        div.box,
        const HarnessBox(
          height: 355,
          maxWidth: 10,
          maxHeight: 20,
          padding: EdgeInsets.all(1),
          absolute: true,
          offset: Offset(5, -6),
          direction: TextDirection.rtl,
        ),
      );
    });

    test('the element has no style attribute', () {
      final div = document.createElement<HarnessElement>('div');
      expect(
        () => div.setAttribute('style', 'width: 300px'),
        throwsArgumentError,
      );
      expect(() => div.getAttribute('STYLE'), throwsArgumentError);
      expect(() => div.removeAttribute('style'), throwsArgumentError);
    });

    test('other attributes keep their value', () {
      final div = document.createElement<HarnessElement>('div')
        ..setAttribute('class', 'chartjs-wrapper')
        ..setAttribute('id', 'a');
      expect(div.getAttribute('CLASS'), 'chartjs-wrapper');
      expect(div.getAttribute('id'), 'a');
      // The class has no effect on the layout (Chart.js ADR 0200).
      expect(div.box, const HarnessBox());
      div.removeAttribute('id');
      expect(div.getAttribute('id'), isNull);
    });

    testWidgets('the display of a canvas', (tester) async {
      final canvas = document.createElement<HTMLCanvasElement>('canvas');
      expect(canvas.hidden, isFalse);
      canvas
        ..hidden = true
        ..displayWidth = 345;
      expect(canvas.hidden, isTrue);
      expect(canvas.displayWidth, 345);
    });
  });

  group('layout', () {
    testWidgets('the px width and height give the content box', (tester) async {
      final (wrapper, canvas) = _wrap(
        const HarnessBox(width: 300, height: 350),
      );
      await _checkpoint();
      expect(_containerOf(canvas), const Size(300, 350));
      expect((wrapper.clientWidth, wrapper.clientHeight), (300, 350));
      expect(_hostOf(canvas).attached, isTrue);
      // The host has the display size of the canvas, in its content box.
      expect(_hostOf(canvas).size, const Size(300, 150));
    });

    testWidgets('no width gives the content width of the parent', (
      tester,
    ) async {
      final (wrapper, canvas) = _wrap(const HarnessBox(height: 100));
      await _checkpoint();
      expect(_containerOf(canvas), const Size(800, 100));
      expect(wrapper.clientWidth, 800);
    });

    testWidgets('position absolute gives the width of the content', (
      tester,
    ) async {
      final canvas = document.createElement<HTMLCanvasElement>('canvas')
        ..setAttribute('width', '200')
        ..setAttribute('height', '100');
      final (wrapper, _) = _wrap(
        const HarnessBox(absolute: true),
        canvas: canvas,
      );
      await _checkpoint();
      expect(_containerOf(canvas), const Size(200, 100));
      expect((wrapper.clientWidth, wrapper.clientHeight), (200, 100));
    });

    testWidgets('the default wrapper is a box of the display size of the '
        'canvas', (tester) async {
      // acquireChart: an absolute wrapper (the class chartjs-wrapper) and a
      // canvas of 512 x 512.
      final canvas = document.createElement<HTMLCanvasElement>('canvas')
        ..setAttribute('height', '512')
        ..setAttribute('width', '512');
      final wrapper = document.createElement<HarnessElement>('div')
        ..absolute = true
        ..appendChild(canvas);
      document.body.appendChild(wrapper);
      await _checkpoint();
      expect(_containerOf(canvas), const Size(512, 512));
      expect((wrapper.clientWidth, wrapper.clientHeight), (512, 512));
    });

    testWidgets('the padding of a static box', (tester) async {
      final (wrapper, canvas) = _wrap(
        const HarnessBox(padding: EdgeInsets.all(10)),
      );
      await _checkpoint();
      expect(_containerOf(canvas), const Size(780, 150));
      expect((wrapper.clientWidth, wrapper.clientHeight), (800, 170));
    });

    testWidgets('no height gives the height of the content', (tester) async {
      final canvas = document.createElement<HTMLCanvasElement>('canvas')
        ..displayWidth = 400
        ..displayHeight = 120;
      final (wrapper, _) = _wrap(const HarnessBox(width: 500), canvas: canvas);
      await _checkpoint();
      expect(_containerOf(canvas), const Size(500, 120));
      expect(wrapper.clientHeight, 120);

      // A canvas with its own display none has no content.
      canvas.hidden = true;
      await tester.pump();
      expect(_containerOf(canvas), const Size(500, 0));
      expect(wrapper.clientHeight, 0);
    });

    testWidgets('max-width and max-height cap the content box', (tester) async {
      final (wrapper, canvas) = _wrap(
        const HarnessBox(maxWidth: 600, maxHeight: 50),
      );
      await _checkpoint();
      expect(_containerOf(canvas), const Size(600, 50));
      expect((wrapper.clientWidth, wrapper.clientHeight), (600, 50));
      final (fixed, fixedCanvas) = _wrap(
        const HarnessBox(
          width: 700,
          height: 700,
          maxWidth: 650,
          maxHeight: 300,
        ),
      );
      await _checkpoint();
      expect(_containerOf(fixedCanvas), const Size(650, 300));
      expect((fixed.clientWidth, fixed.clientHeight), (650, 300));
    });

    testWidgets('the padding lies outside the content box', (tester) async {
      final (wrapper, canvas) = _wrap(
        const HarnessBox(width: 320, height: 350, padding: EdgeInsets.all(50)),
      );
      await _checkpoint();
      expect(_containerOf(canvas), const Size(320, 350));
      expect((wrapper.clientWidth, wrapper.clientHeight), (420, 450));
      final offset = _hostOf(canvas).localToGlobal(Offset.zero);
      expect(offset, const Offset(50, 50));
    });

    testWidgets('display none gives the size 0 and keeps the host', (
      tester,
    ) async {
      final (wrapper, canvas) = _wrap(
        const HarnessBox(width: 460, height: 380, hidden: true),
      );
      await _checkpoint();
      final host = _hostOf(canvas);
      expect(_containerOf(canvas), Size.zero);
      expect((wrapper.clientWidth, wrapper.clientHeight), (0, 0));
      expect(host.attached, isTrue);
      wrapper.hidden = false;
      await tester.pump();
      expect(_hostOf(canvas), same(host));
      expect(_containerOf(canvas), const Size(460, 380));
      expect((wrapper.clientWidth, wrapper.clientHeight), (460, 380));
    });

    testWidgets('display none of an ancestor gives the subtree the size 0', (
      tester,
    ) async {
      // CSS hides the whole subtree. The getBoundingClientRect of the inner
      // div is 0 x 0, so getMaximumSize (helpers.dom.ts:163-200) gives 0 x 0.
      final outer = document.createElement<HarnessElement>('div')
        ..box = const HarnessBox(hidden: true);
      final inner = document.createElement<HarnessElement>('div')
        ..box = const HarnessBox(width: 300, height: 200);
      final canvas = document.createElement<HTMLCanvasElement>('canvas');
      inner.appendChild(canvas);
      outer.appendChild(inner);
      document.body.appendChild(outer);
      await _checkpoint();
      expect(_containerOf(canvas), Size.zero);
      expect((inner.clientWidth, inner.clientHeight), (0, 0));
      expect(_hostOf(canvas).attached, isTrue);
      outer.hidden = false;
      await tester.pump();
      expect(_containerOf(canvas), const Size(300, 200));
      expect((inner.clientWidth, inner.clientHeight), (300, 200));
    });

    testWidgets('a canvas with one display side gives its CSS display size', (
      tester,
    ) async {
      // A replaced element with one display side keeps the aspect ratio of
      // its render size (Chart.js ADR 0022, section 9): 400 x 200 for a
      // canvas of 300 x 150 with the display width 400.
      final canvas = document.createElement<HTMLCanvasElement>('canvas')
        ..displayWidth = 400;
      final wrapper = document.createElement<HarnessElement>('div')
        ..absolute = true
        ..appendChild(canvas);
      document.body.appendChild(wrapper);
      await _checkpoint();
      expect((wrapper.clientWidth, wrapper.clientHeight), (400, 200));
      expect(_containerOf(canvas), const Size(400, 200));
    });

    testWidgets('direction rtl gives the subtree a right-to-left '
        'Directionality', (tester) async {
      _wrap(
        const HarnessBox(width: 300, height: 100, direction: TextDirection.rtl),
      );
      await _checkpoint();
      final context = tester.element(find.byType(ChartHost));
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets('a static block div with max-width takes that width', (
      tester,
    ) async {
      // core.controller.tests.js:918, after the display change.
      final (wrapper, canvas) = _wrap(
        const HarnessBox(maxWidth: 600, maxHeight: 400),
      );
      await _checkpoint();
      expect(_containerOf(canvas), const Size(600, 150));
      expect(wrapper.clientWidth, 600);
    });

    testWidgets('a nested div takes the content width of its parent', (
      tester,
    ) async {
      final outer = document.createElement<HarnessElement>('div')
        ..box = const HarnessBox(width: 400, height: 300);
      final inner = document.createElement<HarnessElement>('div')
        ..box = const HarnessBox(height: 100);
      final canvas = document.createElement<HTMLCanvasElement>('canvas');
      inner.appendChild(canvas);
      outer.appendChild(inner);
      document.body.appendChild(outer);
      await _checkpoint();
      expect(_containerOf(canvas), const Size(400, 100));
      expect((inner.clientWidth, inner.clientHeight), (400, 100));
    });

    testWidgets('left and top place an element with position absolute', (
      tester,
    ) async {
      // zoom.drag.spec.js:441 of chartjs-plugin-zoom (Chart.js ADR 0108).
      final canvas = document.createElement<HTMLCanvasElement>('canvas')
        ..setAttribute('width', '200')
        ..setAttribute('height', '100');
      final (wrapper, _) = _wrap(
        const HarnessBox(absolute: true, offset: Offset(50, 30)),
        canvas: canvas,
      );
      await _checkpoint();
      expect(_hostOf(canvas).localToGlobal(Offset.zero), const Offset(50, 30));
      expect(canvas.getBoundingClientRect(), const DOMRect(50, 30, 200, 100));
      // The offset does not change the shrink-to-fit width.
      expect((wrapper.clientWidth, wrapper.clientHeight), (200, 100));

      // A write moves the box at the next frame. A child of the body is a
      // relayout boundary: the body places it again.
      wrapper.offset = const Offset(-10, 0);
      await tester.pump();
      expect(canvas.getBoundingClientRect(), const DOMRect(-10, 0, 200, 100));
    });

    testWidgets('an offset has no effect without absolute', (tester) async {
      final (_, canvas) = _wrap(
        const HarnessBox(width: 300, height: 150, offset: Offset(50, 30)),
      );
      await _checkpoint();
      expect(_hostOf(canvas).localToGlobal(Offset.zero), Offset.zero);
    });

    testWidgets('without an offset, an absolute box keeps the static '
        'position in the padding box of the parent', (tester) async {
      final outer = document.createElement<HarnessElement>('div')
        ..box = const HarnessBox(
          width: 400,
          height: 300,
          padding: EdgeInsets.all(10),
        );
      final first = document.createElement<HarnessElement>('div')
        ..box = const HarnessBox(height: 40);
      final unplaced = document.createElement<HarnessElement>('div')
        ..box = const HarnessBox(width: 50, height: 20, absolute: true);
      final placed = document.createElement<HarnessElement>('div')
        ..box = const HarnessBox(
          width: 50,
          height: 20,
          absolute: true,
          offset: Offset(20, 100),
        );
      final staticCanvas = document.createElement<HTMLCanvasElement>('canvas');
      final placedCanvas = document.createElement<HTMLCanvasElement>('canvas');
      unplaced.appendChild(staticCanvas);
      placed.appendChild(placedCanvas);
      outer
        ..appendChild(first)
        ..appendChild(unplaced)
        ..appendChild(placed);
      document.body.appendChild(outer);
      await _checkpoint();
      // The offset starts at the padding edge of the parent. The static
      // position is in the content box, after the elements in the flow: an
      // absolute element is out of the flow.
      expect(
        _hostOf(staticCanvas).localToGlobal(Offset.zero),
        const Offset(10, 50),
      );
      expect(
        _hostOf(placedCanvas).localToGlobal(Offset.zero),
        const Offset(20, 100),
      );
    });

    testWidgets('a canvas child of the body gets the body width', (
      tester,
    ) async {
      final canvas = document.createElement<HTMLCanvasElement>('canvas');
      document.body.appendChild(canvas);
      await _checkpoint();
      expect(_containerOf(canvas), const Size(800, 150));
      expect(document.body.clientWidth, 800);
    });

    testWidgets('a style write alone waits for the next frame', (tester) async {
      final (wrapper, canvas) = _wrap(
        const HarnessBox(width: 300, height: 350),
      );
      await _checkpoint();
      wrapper.width = 455;
      await _checkpoint();
      expect(_hostOf(canvas).contentWidth, 300);
      await tester.pump();
      expect(_hostOf(canvas).contentWidth, 455);
    });

    testWidgets('a read of clientWidth lays out the body first', (
      tester,
    ) async {
      final (wrapper, canvas) = _wrap(
        const HarnessBox(width: 300, height: 350),
      );
      await _checkpoint();
      wrapper.width = 455;
      expect(wrapper.clientWidth, 455);
      expect(_hostOf(canvas).contentWidth, 455);
    });
  });

  group('writes that wait', () {
    group('in a frame', () {
      late HarnessElement wrapper;
      late HTMLCanvasElement canvas;

      // A tree that a setUp builds: the first write of the test body attaches
      // the body, and its first frame lays out the host.
      setUp(() {
        canvas = document.createElement<HTMLCanvasElement>('canvas');
        wrapper = document.createElement<HarnessElement>('div')
          ..box = const HarnessBox(width: 300, height: 300)
          ..appendChild(canvas);
        document.body.appendChild(wrapper);
      });

      testWidgets('a write in the frame layout of a host waits for a '
          'post-frame callback', (tester) async {
        final other = document.createElement<HarnessElement>('div');
        var calls = 0;
        final observer = CanvasMutationObserver(({required connected}) {
          calls++;
          wrapper.width = 200;
          document.body.appendChild(other);
        })..observe(canvas);
        // The setUp changed only the tree. This write attaches the body.
        wrapper.height = 350;
        expect(find.byType(ChartHost), findsNothing);
        await tester.pump();
        expect(calls, 1);
        // A setState in the layout of the frame throws "Build scheduled
        // during frame.". The rebuild waits for the post-frame callback, and
        // the append adds a checkpoint after the frame.
        expect(tester.takeException(), isNull);
        expect(other.parentNode, same(document.body));
        expect(_containerOf(canvas), const Size(200, 350));
        observer.disconnect();
      });
    });

    testWidgets('a write in the forced layout of a checkpoint waits for the '
        'frame', (tester) async {
      final canvas = document.createElement<HTMLCanvasElement>('canvas');
      final wrapper = document.createElement<HarnessElement>('div')
        ..box = const HarnessBox(width: 300, height: 350);
      final other = document.createElement<HarnessElement>('div');
      Object? error;
      var calls = 0;
      // The attach of the host runs in the forced layout of the checkpoint.
      final observer = CanvasMutationObserver(({required connected}) {
        calls++;
        try {
          wrapper.width = 200;
          document.body.appendChild(other);
        } on Object catch (e) {
          error = e;
        }
      })..observe(canvas);
      wrapper.appendChild(canvas);
      document.body.appendChild(wrapper);
      await _checkpoint();
      expect(calls, 1);
      expect(error, isNull);
      // The tree changed at once. The layout waits.
      expect(wrapper.width, 200);
      expect(other.parentNode, same(document.body));
      expect(_hostOf(canvas).contentWidth, 300);
      await tester.pump();
      await _checkpoint();
      expect(_hostOf(canvas).contentWidth, 200);
      expect(tester.takeException(), isNull);
      observer.disconnect();
    });
  });

  group('mutation checkpoint', () {
    Future<(HarnessElement, List<bool>, CanvasMutationObserver)> attached(
      WidgetTester tester,
    ) async {
      final (wrapper, canvas) = _wrap(
        const HarnessBox(width: 320, height: 350),
      );
      await _checkpoint();
      await tester.pump();
      final calls = <bool>[];
      final observer = CanvasMutationObserver(
        ({required connected}) => calls.add(connected),
      )..observe(canvas);
      return (wrapper, calls, observer);
    }

    testWidgets('a removal and a later append reach the chart at the '
        'checkpoint of their task', (tester) async {
      final (wrapper, calls, observer) = await attached(tester);
      document.body.removeChild(wrapper);
      expect(calls, isEmpty);
      await _checkpoint();
      expect(calls, [false]);
      document.body.appendChild(wrapper);
      await _checkpoint();
      expect(calls, [false, true]);
      await tester.pump();
      expect(calls, [false, true]);
      observer.disconnect();
    });

    testWidgets('a removal and an append in one task give no report', (
      tester,
    ) async {
      final (wrapper, calls, observer) = await attached(tester);
      document.body
        ..removeChild(wrapper)
        ..appendChild(wrapper);
      await _checkpoint();
      await tester.pump();
      expect(calls, isEmpty);
      observer.disconnect();
    });

    testWidgets('a removal, an append and a removal in one task give one '
        'detach', (tester) async {
      final (wrapper, calls, observer) = await attached(tester);
      document.body
        ..removeChild(wrapper)
        ..appendChild(wrapper)
        ..removeChild(wrapper);
      await _checkpoint();
      expect(calls, [false]);
      await tester.pump();
      expect(calls, [false]);
      observer.disconnect();
    });

    testWidgets('a removal in a frame callback reaches the chart before the '
        'layout of the frame', (tester) async {
      final (wrapper, canvas) = _wrap(
        const HarnessBox(width: 320, height: 350),
      );
      await _checkpoint();
      await tester.pump();
      final phases = <SchedulerPhase>[];
      final observer = CanvasMutationObserver(
        ({required connected}) =>
            phases.add(SchedulerBinding.instance.schedulerPhase),
      )..observe(canvas);
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        document.body.removeChild(wrapper);
      });
      await tester.pump();
      expect(phases, [SchedulerPhase.midFrameMicrotasks]);
      observer.disconnect();
    });

    testWidgets('a removed canvas gets its standby host back', (tester) async {
      final canvas = document.createElement<HTMLCanvasElement>('canvas');
      final standby = _hostOf(canvas);
      final (wrapper, _) = _wrap(
        const HarnessBox(width: 100, height: 100),
        canvas: canvas,
      );
      await _checkpoint();
      expect(_hostOf(canvas), isNot(same(standby)));
      wrapper.remove();
      await _checkpoint();
      await tester.pump();
      expect(_hostOf(canvas), same(standby));
      expect(detectPlatform(canvas)(), isA<FlutterPlatform>());
      expect(canvas.parentElement, same(wrapper));
    });
  });

  group('the body', () {
    test('a write outside a testWidgets body changes only the tree', () {
      final div = document.createElement<HarnessElement>('div');
      document.body.appendChild(div);
      expect(div.parentNode, same(document.body));
      expect(div.clientWidth, 0);
    });

    testWidgets('the unmount calls the afterEachChart functions once', (
      tester,
    ) async {
      final unmounts = _unmounts;
      _wrap(const HarnessBox(width: 100, height: 100));
      await _checkpoint();
      expect(find.byType(ChartHost), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(_unmounts, unmounts + 1);
      // A later write changes only the tree.
      final div = document.createElement<HarnessElement>('div');
      document.body.appendChild(div);
      await _checkpoint();
      await tester.pump();
      expect(find.byType(ChartHost), findsNothing);
      expect(div.parentNode, same(document.body));
      expect(_unmounts, unmounts + 1);
    });

    testWidgets('afterEachChart adds a function once', (tester) async {
      var count = 0;
      void callback() => count++;
      afterEachChart(callback);
      afterEachChart(callback);
      _wrap(const HarnessBox(width: 100, height: 100));
      await _checkpoint();
      await tester.pumpWidget(const SizedBox());
      expect(count, 1);
    });
  });

  group('window', () {
    testWidgets('devicePixelRatio writes the ratio of the view and keeps its '
        'logical size', (tester) async {
      addTearDown(tester.view.reset);
      final standbyCanvas = document.createElement<HTMLCanvasElement>('canvas');
      final (_, canvas) = _wrap(const HarnessBox(width: 100, height: 100));
      await _checkpoint();
      window.devicePixelRatio = 2;
      expect(window.devicePixelRatio, 2);
      expect(tester.view.devicePixelRatio, 2);
      expect(tester.view.physicalSize / 2, const Size(800, 600));
      expect(_hostOf(standbyCanvas).devicePixelRatio, 2);
      await tester.pump();
      expect(_hostOf(canvas).devicePixelRatio, 2);
    });
  });

  group('forceHarnessLayout', () {
    test('throws outside a testWidgets body', () {
      expect(_forceLayout, throwsStateError);
    });

    testWidgets('lays out the body at once', (tester) async {
      final (_, canvas) = _wrap(const HarnessBox(width: 320, height: 350));
      _forceLayout();
      expect(_containerOf(canvas), const Size(320, 350));
      expect(_hostOf(canvas).isConnected, isTrue);
    });

    testWidgets('throws in a layout', (tester) async {
      final canvas = document.createElement<HTMLCanvasElement>('canvas');
      Object? error;
      final observer = CanvasMutationObserver(({required connected}) {
        try {
          _forceLayout();
        } on Object catch (e) {
          error = e;
        }
      })..observe(canvas);
      _wrap(const HarnessBox(width: 320, height: 350), canvas: canvas);
      await _checkpoint();
      expect(error, isA<StateError>());
      observer.disconnect();
    });
  });

  group('harness tasks', () {
    testWidgets('run in the order of the due time, then of the insertion', (
      tester,
    ) async {
      final log = <String>[];
      await waitForDone((done) {
        setTimeout(() {
          log.add('a');
          done();
        }, 32);
        setTimeout(() => log.add('b'));
        setTimeout(() => log.add('c'));
        setTimeout(() => log.add('d'), 16);
        setTimeout(() => log.add('e'), -5);
      });
      expect(log, ['b', 'c', 'e', 'd', 'a']);
    });

    testWidgets('the microtasks run before each task', (tester) async {
      final log = <String>[];
      await waitForDone((done) {
        setTimeout(() {
          log.add('task 1');
          scheduleMicrotask(() => log.add('microtask'));
        });
        setTimeout(() {
          log.add('task 2');
          done();
        });
      });
      expect(log, ['task 1', 'microtask', 'task 2']);
    });

    testWidgets('nested microtasks run before the next task', (tester) async {
      // A browser microtask checkpoint runs the queue until it is empty,
      // also the microtasks that a microtask queues.
      final log = <String>[];
      await waitForDone((done) {
        setTimeout(() {
          log.add('task A');
          scheduleMicrotask(() {
            log.add('micro 1');
            scheduleMicrotask(() {
              log.add('micro 2');
              scheduleMicrotask(() => log.add('micro 3'));
            });
          });
        });
        setTimeout(() {
          log.add('task B');
          done();
        });
      });
      expect(log, ['task A', 'micro 1', 'micro 2', 'micro 3', 'task B']);
    });

    testWidgets('an expect in a task works', (tester) async {
      await waitForDone((done) {
        setTimeout(() {
          expect(clock.now(), isA<DateTime>());
          done();
        }, 100);
      });
    });

    testWidgets('a task with a delay of 200 ms runs after 13 frames', (
      tester,
    ) async {
      final start = clock.now();
      var ran = false;
      setTimeout(() => ran = true, 200);
      final frames = await pumpFrames(() => ran);
      expect(frames, 13);
      expect(clock.now().difference(start), const Duration(milliseconds: 208));
    });

    testWidgets('a pump advances the fake clock by one frame', (tester) async {
      final start = clock.now();
      expect(await pumpFrames(() => true), 0);
      final frames = await pumpFrames(
        () => clock.now().difference(start) >= frameInterval * 2,
      );
      expect(frames, 2);
      expect(frameInterval, const Duration(milliseconds: 16));
    });

    testWidgets('pumpFrames fails with the Jasmine timeout message', (
      tester,
    ) async {
      final start = clock.now();
      TestFailure? failure;
      try {
        await pumpFrames(() => false);
      } on TestFailure catch (e) {
        failure = e;
      }
      expect(
        failure?.message,
        'Timeout - Async function did not complete within 5000ms',
      );
      expect(clock.now().difference(start), greaterThanOrEqualTo(specTimeout));
    });

    testWidgets('two pumpFrames loops at the same time end', (tester) async {
      // The fixture runner settles a run hook that awaits triggerMouseEvent:
      // two loops at the same time. Before the fix, the two drains waited
      // for each other without end.
      var inner = false;
      unawaited(pumpFrames(() => true).then((_) => inner = true));
      expect(await pumpFrames(() => inner), 0);
      expect(inner, isTrue);
    });

    testWidgets('a waiting pumpFrames loop sees each step of the other loop', (
      tester,
    ) async {
      final start = clock.now();
      var frameRan = false;
      var innerDone = false;
      // The inner loop starts in a microtask of the drain of the outer loop,
      // as a hook of the runner does. It waits for the frame of the outer
      // loop, and it tests its condition after that step.
      scheduleMicrotask(() {
        unawaited(pumpFrames(() => frameRan).then((_) => innerDone = true));
      });
      SchedulerBinding.instance.scheduleFrameCallback((_) => frameRan = true);
      expect(await pumpFrames(() => innerDone), 1);
      // One frame for the callback, and no second loop that pumps.
      expect(clock.now().difference(start), frameInterval);
    });

    testWidgets('pumpFrame runs the due tasks, then pumps one frame', (
      tester,
    ) async {
      final start = clock.now();
      final log = <String>[];
      setTimeout(() => log.add('task at ${clock.now().difference(start)}'));
      setTimeout(() => log.add('late task'), 100);
      SchedulerBinding.instance.scheduleFrameCallback(
        (_) => log.add('frame at ${clock.now().difference(start)}'),
      );
      await pumpFrame();
      expect(log, ['task at ${Duration.zero}', 'frame at $frameInterval']);
      expect(clock.now().difference(start), frameInterval);
    });

    testWidgets('a pending task at the end of a test is not a Timer', (
      tester,
    ) async {
      setTimeout(() => _leakedTaskRan = true);
    });

    testWidgets('a task does not reach the next test', (tester) async {
      // pumpFrames runs the due tasks before it tests the condition.
      expect(await pumpFrames(() => true), 0);
      expect(_leakedTaskRan, isFalse);
    });
  });
}

/// The forced layout of the harness (`forceHarnessLayout` of
/// `src/dom.dart`), which `acquireChart` calls.
void _forceLayout() => forceHarnessLayout();
