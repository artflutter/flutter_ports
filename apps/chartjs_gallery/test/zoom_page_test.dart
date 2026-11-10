// Original code, not ported from chartjs-plugin-zoom: the zoom page tests.

import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:chartjs_gallery/main.dart';
import 'package:chartjs_gallery/plugins/zoom_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A Pixel 8a: 412 x 915 logical pixels at DPR 2.625.
const Size _pixel8a = Size(412, 915);

/// A small phone: 360 x 640 logical pixels at DPR 3.
const Size _smallPhone = Size(360, 640);

/// Sets the test view to [size] logical pixels at [dpr].
void _setView(WidgetTester tester, Size size, double dpr) {
  tester.view
    ..physicalSize = size * dpr
    ..devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
}

/// The host of the chart.
final Finder _host = find.byKey(const ValueKey('zoom.host'));

/// The readout.
final Finder _readout = find.byKey(const ValueKey('zoom.readout'));

/// The segment of the action [name] (`toggleZoom`, `togglePan`,
/// `resetZoom`).
Finder _action(String name) => find.byKey(ValueKey('zoom.action.$name'));

/// Pumps the gallery, opens the page from its tile, selects [variant] and
/// waits for its chart and the end of its first animation.
Future<ZoomPageState> _open(
  WidgetTester tester, [
  String variant = 'basic',
]) async {
  await tester.pumpWidget(const GalleryApp());
  final tile = find.byKey(const ValueKey('gallery.plugin.zoom'));
  await tester.scrollUntilVisible(tile, 100);
  await tester.pump();
  await tester.tap(tile);
  await tester.pumpAndSettle();
  if (variant != zoomPageVariants.first.key) {
    await tester.tap(find.byKey(ValueKey('zoom.variant.$variant')));
    await tester.pumpAndSettle();
  }
  final state = tester.state<ZoomPageState>(find.byType(ZoomPage));
  expect(state.chart, isNotNull, reason: variant);
  expect(tester.takeException(), isNull, reason: variant);
  return state;
}

/// The point at the fractions [fx] and [fy] of the chart area of [chart],
/// in the view, at a whole pixel of the canvas.
Offset _inArea(WidgetTester tester, Chart chart, double fx, double fy) {
  final area = chart.chartArea!;
  final x = (area.left + fx * (area.right - area.left)).roundToDouble();
  final y = (area.top + fy * (area.bottom - area.top)).roundToDouble();
  return tester.getTopLeft(_host) + Offset(x, y);
}

/// A mouse wheel of [deltaY] at [at], then the end of the zoom: its
/// animation and the 250 ms of the debounced `onZoomComplete`.
Future<void> _wheel(WidgetTester tester, Offset at, double deltaY) async {
  final pointer = TestPointer(100, PointerDeviceKind.mouse);
  await tester.sendEventToBinding(pointer.addPointer(location: at));
  await tester.sendEventToBinding(pointer.hover(at));
  await tester.sendEventToBinding(pointer.scroll(Offset(0, deltaY)));
  await tester.sendEventToBinding(pointer.removePointer(location: at));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 300));
}

/// A mouse drag with the left button from [from] to [to] in four steps,
/// one frame each.
Future<void> _mouseDrag(WidgetTester tester, Offset from, Offset to) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: from);
  await gesture.down(from);
  await tester.pump();
  for (var i = 1; i <= 4; i++) {
    await gesture.moveTo(Offset.lerp(from, to, i / 4)!);
    await tester.pump();
  }
  await gesture.up();
  await gesture.removePointer();
  await tester.pumpAndSettle();
}

/// The range `(min, max)` of the scale [id] of [chart].
(double, double) _range(Chart chart, String id) {
  final scale = chart.scales[id]!;
  return (scale.min, scale.max);
}

/// The width of a range.
double _width((double, double) range) => range.$2 - range.$1;

/// The segment line of the actions.
SegmentToggles _toggles(WidgetTester tester) =>
    tester.widget<SegmentToggles>(find.byType(SegmentToggles));

/// The resolved text of the title of [chart]: the options of the chart
/// call the scriptable `text` with the chart context.
Object? _titleText(Chart chart) {
  final plugins = chart.options['plugins']! as JsObjectFace;
  return (plugins['title']! as JsObjectFace)['text'];
}

/// The rect of the host lies inside the view of [size].
void _expectInView(WidgetTester tester, Size size, String reason) {
  final view = Offset.zero & size;
  final host = tester.getRect(_host);
  expect(host.height, greaterThan(0), reason: '$reason $host');
  expect(view.contains(host.topLeft), isTrue, reason: '$reason $host');
  expect(
    view.contains(host.bottomRight - const Offset(0.01, 0.01)),
    isTrue,
    reason: '$reason $host in $size',
  );
}

/// The page has none of the controls that the layout rule forbids
/// (Chart.js ADR 0031, section 10.2).
void _expectNoForbiddenControls(String reason) {
  expect(find.byType(ChoiceChip), findsNothing, reason: reason);
  expect(find.byType(FilterChip), findsNothing, reason: reason);
  expect(find.byType(ToggleChips), findsNothing, reason: reason);
  expect(find.byType(SliderControl), findsNothing, reason: reason);
  expect(
    find.byWidgetPredicate((w) => w is PopupMenuButton),
    findsNothing,
    reason: reason,
  );
  expect(
    find.byWidgetPredicate((w) => w is DropdownButton),
    findsNothing,
    reason: reason,
  );
  expect(
    find.byWidgetPredicate(
      (w) =>
          w is Scrollable &&
          axisDirectionToAxis(w.axisDirection) == .horizontal,
    ),
    findsNothing,
    reason: reason,
  );
}

/// The readout shows [text].
void _expectReadout(String text) {
  expect(
    find.descendant(of: _readout, matching: find.textContaining(text)),
    findsOneWidget,
    reason: text,
  );
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('the home list has the tile of the zoom plugin after the chart '
      'types', (tester) async {
    await tester.pumpWidget(const GalleryApp());
    final tile = find.byKey(const ValueKey('gallery.plugin.zoom'));
    await tester.scrollUntilVisible(tile, 100);
    expect(
      find.descendant(of: tile, matching: find.text('Zoom and pan')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: tile,
        matching: find.text(
          'chartjs-plugin-zoom $chartjsPluginZoomVersion: docs/samples',
        ),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(tile).dy,
      greaterThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('gallery.type.scatter')))
            .dy,
      ),
    );
  });

  for (final variant in zoomPageVariants) {
    final key = variant.key;

    testWidgets('$key: the chart of the sample is in view at 412 x 915', (
      tester,
    ) async {
      _setView(tester, _pixel8a, 2.625);
      final state = await _open(tester, key);
      final chart = state.chart!;
      _expectInView(tester, _pixel8a, key);
      _expectNoForbiddenControls(key);
      expect(chart.config.type, key == 'wheel' ? 'bar' : 'scatter');
      expect(chart.width, tester.getSize(_host).width);
      // The aspect ratio 2 of Chart.js.
      expect(
        tester.getSize(_host).height,
        closeTo(tester.getSize(_host).width / 2, 1),
      );
      // The zoom plugin runs on the chart with the options of the sample.
      expect(registry.getPlugin('zoom'), same(zoomPlugin));
      expect(chart.isZoomedOrPanned(), isFalse);
      expect(chart.getZoomLevel(), 1);
      _expectReadout('1x');
      // The docs defaults: no legend.
      expect(chart.legend, isNull);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('zoom.help'))).data,
        contains(variant.source),
      );
      expect(
        find.bySemanticsLabel('Zoom and pan chart: ${variant.text}'),
        findsOneWidget,
      );
      // One segment for each action of the sample, with its key.
      expect(
        _toggles(tester).items.map((item) => item.tooltip),
        state.sample.actions.map((action) => action.name),
      );
      expect(_action('resetZoom'), findsOneWidget);
    });

    testWidgets('$key: the chart is in view at 360 x 640', (tester) async {
      _setView(tester, _smallPhone, 3);
      await _open(tester, key);
      _expectInView(tester, _smallPhone, key);
      _expectNoForbiddenControls(key);
    });
  }

  testWidgets('basic: a wheel over the chart zooms both axes, and reset puts '
      'back the first range', (tester) async {
    _setView(tester, _pixel8a, 2.625);
    final state = await _open(tester);
    final chart = state.chart!;
    final x = _range(chart, 'x');
    final y = _range(chart, 'y');
    expect(_titleText(chart), 'Zoom: enabled (1x), Pan: enabled');

    await _wheel(tester, _inArea(tester, chart, 0.5, 0.5), -100);
    // A wheel step of 24 pixels or more zooms by the full speed 0.1, which
    // takes 10 % of the range away (src/handlers.ts:262-265,
    // src/scale.types.ts:36-41).
    // getZoomLevel rounds to two decimals (src/core.ts:183).
    expect(chart.getZoomLevel(), 1.11);
    expect(_width(_range(chart, 'x')), closeTo(_width(x) * 0.9, 1e-6));
    expect(_width(_range(chart, 'y')), closeTo(_width(y) * 0.9, 1e-6));
    expect(chart.isZoomedOrPanned(), isTrue);
    // onZoomComplete updated the chart: the title shows the new level.
    expect(_titleText(chart), 'Zoom: enabled (1.11x), Pan: enabled');
    _expectReadout('1.11x');
    _expectReadout('yes');

    await tester.tap(_action('resetZoom'));
    await tester.pumpAndSettle();
    expect(chart.isZoomedOrPanned(), isFalse);
    expect(_range(chart, 'x'), x);
    expect(_range(chart, 'y'), y);
    _expectReadout('1x');
    expect(tester.takeException(), isNull);
  });

  testWidgets('basic: zoom turns the wheel off and on', (tester) async {
    _setView(tester, _pixel8a, 2.625);
    final state = await _open(tester);
    final chart = state.chart!;
    final x = _range(chart, 'x');
    expect(_toggles(tester).isSelected('zoom.action.toggleZoom'), isTrue);

    await tester.tap(_action('toggleZoom'));
    await tester.pumpAndSettle();
    expect(_toggles(tester).isSelected('zoom.action.toggleZoom'), isFalse);
    expect(_titleText(chart), 'Zoom: disabled (1x), Pan: enabled');
    await _wheel(tester, _inArea(tester, chart, 0.5, 0.5), -100);
    expect(_range(chart, 'x'), x);
    expect(chart.isZoomedOrPanned(), isFalse);

    await tester.tap(_action('toggleZoom'));
    await tester.pumpAndSettle();
    expect(_toggles(tester).isSelected('zoom.action.toggleZoom'), isTrue);
    await _wheel(tester, _inArea(tester, chart, 0.5, 0.5), -100);
    expect(chart.getZoomLevel(), 1.11);
    expect(tester.takeException(), isNull);
  });

  testWidgets('basic: a mouse drag pans the chart, and a click logs its type '
      'in output', (tester) async {
    _setView(tester, _pixel8a, 2.625);
    final state = await _open(tester);
    final chart = state.chart!;
    final x = _range(chart, 'x');
    final y = _range(chart, 'y');
    _expectReadout('Clicks are logged here');

    await _mouseDrag(
      tester,
      _inArea(tester, chart, 0.4, 0.5),
      _inArea(tester, chart, 0.6, 0.5),
    );
    final panned = _range(chart, 'x');
    expect(panned, isNot(x));
    expect(_width(panned), closeTo(_width(x), 1e-6));
    expect(_range(chart, 'y'), y);
    expect(chart.getZoomLevel(), 1);
    expect(chart.isZoomedOrPanned(), isTrue);

    await tester.tapAt(
      _inArea(tester, chart, 0.5, 0.5),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(state.output, 'click');
    _expectReadout('click');
    expect(tester.takeException(), isNull);
  });

  testWidgets('basic: a one-finger drag pans the chart, and a two-finger '
      'pinch zooms it', (tester) async {
    _setView(tester, _smallPhone, 3);
    final state = await _open(tester);
    final chart = state.chart!;
    final x = _range(chart, 'x');
    final y = _range(chart, 'y');

    final finger = await tester.startGesture(_inArea(tester, chart, 0.3, 0.5));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await finger.moveBy(const Offset(15, 0));
      await tester.pump();
    }
    await finger.up();
    await tester.pumpAndSettle();
    final panned = _range(chart, 'x');
    expect(panned, isNot(x));
    expect(_width(panned), closeTo(_width(x), 1e-6));
    expect(_range(chart, 'y'), y);
    expect(chart.getZoomLevel(), 1);

    await tester.tap(_action('resetZoom'));
    await tester.pumpAndSettle();
    expect(_range(chart, 'x'), x);

    // Two fingers move apart on the diagonal: both axes zoom
    // (src/gestures.ts:63-77).
    final first = await tester.startGesture(
      _inArea(tester, chart, 0.4, 0.4),
      pointer: 7,
    );
    final second = await tester.startGesture(
      _inArea(tester, chart, 0.6, 0.6),
      pointer: 8,
    );
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await first.moveBy(const Offset(-6, -6));
      await second.moveBy(const Offset(6, 6));
      await tester.pump();
    }
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(chart.getZoomLevel(), greaterThan(1));
    expect(_width(_range(chart, 'x')), lessThan(_width(x)));
    expect(_width(_range(chart, 'y')), lessThan(_width(y)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('basic: an action and a new size of the view keep the zoom '
      'range', (tester) async {
    _setView(tester, _pixel8a, 2.625);
    final state = await _open(tester);
    final chart = state.chart!;
    await _wheel(tester, _inArea(tester, chart, 0.5, 0.5), -100);
    final x = _range(chart, 'x');
    final y = _range(chart, 'y');
    expect(chart.isZoomedOrPanned(), isTrue);

    // The action updates the chart: the zoom wrote its range into the
    // options of the scales, which the update keeps.
    await tester.tap(_action('togglePan'));
    await tester.pumpAndSettle();
    expect(_toggles(tester).isSelected('zoom.action.togglePan'), isFalse);
    expect(_range(chart, 'x'), x);
    expect(_range(chart, 'y'), y);

    // A turn of the phone: the page rebuilds with the same config, and the
    // chart resizes.
    tester.view.physicalSize = const Size(915, 412) * 2.625;
    await tester.pumpAndSettle();
    expect(state.chart, same(chart));
    expect(_range(chart, 'x'), x);
    expect(_range(chart, 'y'), y);
    expect(chart.getZoomLevel(), 1.11);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag: a mouse drag zooms to its box, and reset puts back the '
      'first range', (tester) async {
    _setView(tester, _pixel8a, 2.625);
    final state = await _open(tester, 'drag');
    final chart = state.chart!;
    final x = _range(chart, 'x');
    final y = _range(chart, 'y');
    expect(_titleText(chart), 'Zoom: enabled');

    await _mouseDrag(
      tester,
      _inArea(tester, chart, 0.25, 0.25),
      _inArea(tester, chart, 0.75, 0.75),
    );
    expect(chart.isZoomingOrPanning(), isFalse);
    expect(chart.getZoomLevel(), closeTo(2, 0.1));
    expect(_width(_range(chart, 'x')), lessThan(_width(x) * 0.6));
    expect(_width(_range(chart, 'y')), lessThan(_width(y) * 0.6));
    _expectReadout('yes');

    await tester.tap(_action('resetZoom'));
    await tester.pumpAndSettle();
    expect(chart.isZoomedOrPanned(), isFalse);
    expect(_range(chart, 'x'), x);
    expect(_range(chart, 'y'), y);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag: Escape cancels the box, and Ctrl with a mouse drag pans', (
    tester,
  ) async {
    _setView(tester, _pixel8a, 2.625);
    final state = await _open(tester, 'drag');
    final chart = state.chart!;
    final x = _range(chart, 'x');

    final from = _inArea(tester, chart, 0.25, 0.25);
    final to = _inArea(tester, chart, 0.75, 0.75);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: from);
    await gesture.down(from);
    await tester.pump();
    await gesture.moveTo(to);
    await tester.pump();
    expect(chart.isZoomingOrPanning(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(chart.isZoomingOrPanning(), isFalse);
    await gesture.up();
    await gesture.removePointer();
    await tester.pumpAndSettle();
    expect(_range(chart, 'x'), x);
    expect(chart.isZoomedOrPanned(), isFalse);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await _mouseDrag(
      tester,
      _inArea(tester, chart, 0.4, 0.5),
      _inArea(tester, chart, 0.6, 0.5),
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    final panned = _range(chart, 'x');
    expect(panned, isNot(x));
    expect(_width(panned), closeTo(_width(x), 1e-6));
    expect(chart.getZoomLevel(), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag: zoom turns the box off', (tester) async {
    _setView(tester, _pixel8a, 2.625);
    final state = await _open(tester, 'drag');
    final chart = state.chart!;
    final x = _range(chart, 'x');

    await tester.tap(_action('toggleZoom'));
    await tester.pumpAndSettle();
    expect(_toggles(tester).isSelected('zoom.action.toggleZoom'), isFalse);
    expect(_titleText(chart), 'Zoom: disabled');
    await _mouseDrag(
      tester,
      _inArea(tester, chart, 0.25, 0.25),
      _inArea(tester, chart, 0.75, 0.75),
    );
    expect(_range(chart, 'x'), x);
    expect(chart.isZoomedOrPanned(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wheel: a wheel zooms the months and the values, and reset '
      'puts back the months 5 to 11', (tester) async {
    _setView(tester, _pixel8a, 2.625);
    final state = await _open(tester, 'wheel');
    final chart = state.chart!;
    expect(_range(chart, 'x'), (5.0, 11.0));
    final y = _range(chart, 'y');

    final at = _inArea(tester, chart, 0.5, 0.5);
    for (var i = 0; i < 5; i++) {
      await _wheel(tester, at, -100);
    }
    final x = _range(chart, 'x');
    expect(_width(x), lessThan(6));
    expect(x.$1, greaterThanOrEqualTo(5));
    expect(x.$2, lessThanOrEqualTo(11));
    expect(_width(_range(chart, 'y')), lessThan(_width(y)));
    expect(chart.isZoomedOrPanned(), isTrue);

    await tester.tap(_action('resetZoom'));
    await tester.pumpAndSettle();
    expect(_range(chart, 'x'), (5.0, 11.0));
    expect(_range(chart, 'y'), y);
    expect(chart.isZoomedOrPanned(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pan: the pan is off first, pan turns it on, a mouse drag then '
      'pans, and reset puts back the first range', (tester) async {
    _setView(tester, _pixel8a, 2.625);
    final state = await _open(tester, 'pan');
    final chart = state.chart!;
    final x = _range(chart, 'x');
    expect(_toggles(tester).isSelected('zoom.action.togglePan'), isFalse);

    // The wheel does not zoom, and the pan is off.
    await _wheel(tester, _inArea(tester, chart, 0.5, 0.5), -100);
    await _mouseDrag(
      tester,
      _inArea(tester, chart, 0.4, 0.5),
      _inArea(tester, chart, 0.6, 0.5),
    );
    expect(_range(chart, 'x'), x);
    expect(chart.isZoomedOrPanned(), isFalse);

    await tester.tap(_action('togglePan'));
    await tester.pumpAndSettle();
    expect(_toggles(tester).isSelected('zoom.action.togglePan'), isTrue);
    await _mouseDrag(
      tester,
      _inArea(tester, chart, 0.4, 0.5),
      _inArea(tester, chart, 0.6, 0.5),
    );
    expect(_range(chart, 'x'), isNot(x));
    expect(chart.isZoomedOrPanned(), isTrue);

    await tester.tap(_action('resetZoom'));
    await tester.pumpAndSettle();
    expect(_range(chart, 'x'), x);
    expect(chart.isZoomedOrPanned(), isFalse);
    // A rebuild of the page keeps the options that the action wrote.
    expect(_toggles(tester).isSelected('zoom.action.togglePan'), isTrue);
    expect(tester.takeException(), isNull);
  });
}
