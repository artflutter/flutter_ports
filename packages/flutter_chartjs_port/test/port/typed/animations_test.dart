// Original code, not ported from Chart.js: tests of the property animations.
@TestOn('vm')
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/chartjs.dart' as chartjs show Element;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/options/animated_prop.dart'
    show AnimatedProp;
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_test/flutter_test.dart';

// `ChartConfig.animations` is a List of ready classes, one class for each
// animated property of the elements (row adapt-property-animations). An item
// has no name of a property and no key. The animations of the chart read
// the item that the app made: no option holds a copy. A color animates with
// no `type` (row adapt-color-animation-by-value).

const Color _red = Color(0xFFFF0000);
const Color _blue = Color(0xFF0000FF);

/// [child] at the top left of a box of 400 x 300.
Widget _box(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: 400, height: 300, child: child),
  ),
);

/// The chart of the one ChartView of the tree.
Chart _chart(WidgetTester tester) {
  final host = tester.renderObject<RenderChartHost>(find.byType(ChartHost));
  return Chart.getChart(host.canvas)!;
}

/// A line chart with the border color [color] and the items [animations].
Widget _line(Color color, List<PropertyAnimation> animations) => _box(
  ChartView(
    config: ChartConfig(
      type: .line,
      labels: const ['a', 'b', 'c'],
      datasets: [
        LineDataset(
          key: const ValueKey('line'),
          data: const [1, 2, 3],
          borderColor: ChartValue.constant(.solid(color)),
        ),
      ],
      animations: animations,
    ),
  ),
);

/// A bar chart with the border width [borderWidth] and the items
/// [animations].
Widget _bar(double borderWidth, List<PropertyAnimation> animations) => _box(
  ChartView(
    config: ChartConfig(
      type: .bar,
      labels: const ['a', 'b', 'c'],
      datasets: [
        BarDataset(
          key: const ValueKey('bar'),
          data: const [1, 2, 3],
          borderWidth: borderWidth,
        ),
      ],
      animations: animations,
    ),
  ),
);

/// The animations of the data elements of dataset 0, for the default
/// transition.
Animations _animations(Chart chart) =>
    chart.getDatasetMeta(0).controller!.resolveAnimations(0);

/// The resolved options of [element].
JsObjectFace _optionsOf(Object? element) =>
    (element! as chartjs.Element)['options']! as JsObjectFace;

/// The border color of the line of dataset 0.
Color _borderColor(Chart chart) =>
    (_optionsOf(chart.getDatasetMeta(0).dataset)['borderColor']!
            as SolidChartPaint)
        .color;

/// The border width of bar 0 of dataset 0.
double _borderWidth(Chart chart) =>
    _optionsOf(chart.getDatasetMeta(0).data[0])['borderWidth']! as double;

/// The animation of a property of an element of another library. The type
/// is all that the library needs: it finds its items in the List by it.
final class _BadgeAnimation extends PropertyAnimation {
  const _BadgeAnimation({super.duration});
}

/// The transition of an update mode of another library.
final class _PulseTransition extends ChartTransition {
  const _PulseTransition({super.duration});
}

void main() {
  group('PropertyAnimation', () {
    test('two items of one class with equal parameters are equal', () {
      const a = RadiusAnimation(duration: Duration(milliseconds: 300));
      // The same value, not a constant.
      // ignore: prefer_const_constructors
      final b = RadiusAnimation(duration: Duration(milliseconds: 300));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const RadiusAnimation(loop: true)));
    });

    test('items of two classes with equal parameters differ', () {
      expect(const RadiusAnimation(), isNot(const BorderWidthAnimation()));
      expect(const XAnimation(), isNot(const YAnimation()));
    });

    test('off is the duration 0', () {
      expect(const YAnimation.off(), const YAnimation(duration: Duration.zero));
      expect(const YAnimation.off(), isNot(const YAnimation()));
    });

    test('a config with other items is another config', () {
      const one = ChartConfig(
        type: .bar,
        datasets: [],
        animations: [RadiusAnimation()],
      );
      const same = ChartConfig(
        type: .bar,
        datasets: [],
        animations: [RadiusAnimation()],
      );
      const other = ChartConfig(
        type: .bar,
        datasets: [],
        animations: [RadiusAnimation(loop: true)],
      );
      expect(one, same);
      expect(one, isNot(other));
      expect(one.copyWith(animations: const [YAnimation()]), isNot(one));
    });
  });

  group('ChartConfig.animation', () {
    /// A line chart with the border color [color] and the animation
    /// [animation].
    Widget chartOf(Color color, ChartAnimation animation) => _box(
      ChartView(
        config: ChartConfig(
          type: .line,
          labels: const ['a', 'b', 'c'],
          datasets: [
            LineDataset(
              key: const ValueKey('line'),
              data: const [1, 2, 3],
              borderColor: ChartValue.constant(.solid(color)),
            ),
          ],
          animation: animation,
        ),
      ),
    );

    testWidgets('the options hold the object of the app, not a copy', (
      tester,
    ) async {
      const animation = ChartAnimation(
        duration: Duration(milliseconds: 400),
        easing: Curves.linear,
      );
      await tester.pumpWidget(chartOf(_red, animation));
      final options =
          (_chart(tester).options as JsObjectFace)['animation']!
              as JsObjectFace;
      expect(options['duration'], same(animation));
      expect(options['easing'], same(animation));
      // A parameter that the app did not give has no cell of the app.
      expect(options['delay'], isNot(same(animation)));
      await tester.pumpAndSettle();
    });

    testWidgets('an animation takes the duration and the curve of the object', (
      tester,
    ) async {
      const animation = ChartAnimation(
        duration: Duration(milliseconds: 400),
        easing: Curves.linear,
      );
      await tester.pumpWidget(chartOf(_red, animation));
      await tester.pumpAndSettle();
      final chart = _chart(tester);

      await tester.pumpWidget(chartOf(_blue, animation));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final mid = _borderColor(chart);
      expect(mid.r, inExclusiveRange(0, 1));
      expect(mid.b, inExclusiveRange(0, 1));
      // 400 ms of the object, not the default 1000 ms.
      await tester.pump(const Duration(milliseconds: 250));
      expect(_borderColor(chart), _blue);
      await tester.pumpAndSettle();
    });

    testWidgets('an item of animations goes before the object', (tester) async {
      Widget chartOf(Color color) => _box(
        ChartView(
          config: ChartConfig(
            type: .line,
            labels: const ['a', 'b', 'c'],
            datasets: [
              LineDataset(
                key: const ValueKey('line'),
                data: const [1, 2, 3],
                borderColor: ChartValue.constant(.solid(color)),
              ),
            ],
            animation: const ChartAnimation(
              duration: Duration(milliseconds: 2000),
              easing: Curves.linear,
            ),
            animations: const [
              BorderColorAnimation(duration: Duration(milliseconds: 400)),
            ],
          ),
        ),
      );
      await tester.pumpWidget(chartOf(_red));
      await tester.pumpAndSettle();
      final chart = _chart(tester);

      await tester.pumpWidget(chartOf(_blue));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      // The item gives 400 ms. The curve comes from the object.
      expect(_borderColor(chart), _blue);
      await tester.pumpAndSettle();
    });
  });

  group('a chart', () {
    testWidgets('reads the item that the app made', (tester) async {
      const radius = RadiusAnimation(
        duration: Duration(milliseconds: 300),
        easing: Curves.elasticOut,
      );
      const y = YAnimation.off();
      await tester.pumpWidget(_line(_red, const [radius, y]));
      final animations = _animations(_chart(tester));
      expect(animations.itemOf(AnimatedProp.radius), same(radius));
      expect(animations.itemOf(AnimatedProp.y), same(y));
      expect(animations.itemOf(AnimatedProp.x), isNull);
      await tester.pumpAndSettle();
    });

    testWidgets('animates a color for the duration of its item', (
      tester,
    ) async {
      const animations = [
        BorderColorAnimation(
          duration: Duration(milliseconds: 400),
          easing: Curves.linear,
        ),
      ];
      await tester.pumpWidget(_line(_red, animations));
      await tester.pumpAndSettle();
      final chart = _chart(tester);
      expect(_borderColor(chart), _red);

      await tester.pumpWidget(_line(_blue, animations));
      // The update starts in a post-frame callback.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final mid = _borderColor(chart);
      expect(mid.r, inExclusiveRange(0, 1));
      expect(mid.b, inExclusiveRange(0, 1));

      // The item gives 400 ms, the default is 1000 ms.
      await tester.pump(const Duration(milliseconds: 250));
      expect(_borderColor(chart), _blue);
      await tester.pumpAndSettle();
    });

    testWidgets('changes a property at once when its item is off', (
      tester,
    ) async {
      const animations = [BorderColorAnimation.off()];
      await tester.pumpWidget(_line(_red, animations));
      await tester.pumpAndSettle();
      final chart = _chart(tester);

      await tester.pumpWidget(_line(_blue, animations));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(_borderColor(chart), _blue);
      await tester.pumpAndSettle();
    });

    testWidgets('animates a property that has no options without the item', (
      tester,
    ) async {
      // A bar chart animates x, y, base, width and height. The border width
      // has no animation options there (controller.bar.js:276).
      const animations = [
        BorderWidthAnimation(
          duration: Duration(milliseconds: 400),
          easing: Curves.linear,
        ),
      ];
      await tester.pumpWidget(_bar(1, animations));
      await tester.pumpAndSettle();
      final chart = _chart(tester);
      expect(_borderWidth(chart), 1);

      await tester.pumpWidget(_bar(5, animations));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(_borderWidth(chart), inExclusiveRange(1, 5));
      await tester.pumpAndSettle();
      expect(_borderWidth(chart), 5);
    });

    testWidgets('two items of one class stop a debug build', (tester) async {
      await tester.pumpWidget(
        _line(_red, const [
          RadiusAnimation(loop: true),
          RadiusAnimation(duration: Duration(milliseconds: 300)),
        ]),
      );
      expect(
        tester.takeException(),
        isA<AssertionError>().having(
          (e) => '${e.message}',
          'message',
          contains('ChartConfig.animations has two items of one class'),
        ),
      );
    });
  });
  group('ChartConfig.transitions', () {
    /// A line chart with the border color [color] that updates in the mode
    /// `active`.
    Widget chartOf(
      Color color, {
      List<ChartTransition>? transitions,
      ChartAnimation? animation,
      List<PropertyAnimation>? animations,
    }) => _box(
      ChartView(
        updateMode: 'active',
        config: ChartConfig(
          type: .line,
          labels: const ['a', 'b', 'c'],
          datasets: [
            LineDataset(
              key: const ValueKey('line'),
              data: const [1, 2, 3],
              borderColor: ChartValue.constant(.solid(color)),
            ),
          ],
          animation: animation,
          animations: animations,
          transitions: transitions,
        ),
      ),
    );

    test('two items of one class with equal parameters are equal', () {
      const a = HoverTransition(
        duration: Duration(milliseconds: 150),
        animations: [RadiusAnimation.off()],
      );
      // The same value, not a constant.
      // ignore: prefer_const_constructors
      final b = HoverTransition(
        duration: const Duration(milliseconds: 150),
        // The same value, not a constant.
        // ignore: prefer_const_literals_to_create_immutables
        animations: [const RadiusAnimation.off()],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const HoverTransition()));
      expect(const HoverTransition(), isNot(const HideTransition()));
    });

    testWidgets('an update in the mode takes the duration of its item', (
      tester,
    ) async {
      const transitions = [
        HoverTransition(
          duration: Duration(milliseconds: 200),
          easing: Curves.linear,
        ),
      ];
      await tester.pumpWidget(chartOf(_red, transitions: transitions));
      await tester.pumpAndSettle();
      final chart = _chart(tester);

      await tester.pumpWidget(chartOf(_blue, transitions: transitions));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = _borderColor(chart);
      expect(mid.r, inExclusiveRange(0, 1));
      // 200 ms of the item, not the 400 ms of the default of the mode: the
      // color at 250 ms is the last color. The mode `active` gives the
      // hover color of the line, so the last color is not the plain blue.
      await tester.pump(const Duration(milliseconds: 150));
      final at250 = _borderColor(chart);
      expect(at250, isNot(mid));
      await tester.pumpAndSettle();
      expect(_borderColor(chart), at250);
    });

    testWidgets('the item of the mode goes before the chart animation', (
      tester,
    ) async {
      const transitions = [
        HoverTransition(duration: Duration(milliseconds: 200)),
      ];
      const animation = ChartAnimation(
        duration: Duration(milliseconds: 2000),
        easing: Curves.linear,
      );
      await tester.pumpWidget(
        chartOf(_red, transitions: transitions, animation: animation),
      );
      await tester.pumpAndSettle();
      final chart = _chart(tester);

      await tester.pumpWidget(
        chartOf(_blue, transitions: transitions, animation: animation),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      final at250 = _borderColor(chart);
      await tester.pumpAndSettle();
      // Done at 250 ms: the 200 ms of the item, not the 2000 ms.
      expect(_borderColor(chart), at250);
    });

    testWidgets('the property items of the mode go before those of the chart', (
      tester,
    ) async {
      const mode = BorderColorAnimation.off();
      const transitions = [
        HoverTransition(animations: [mode]),
      ];
      const animations = [
        BorderColorAnimation(duration: Duration(milliseconds: 2000)),
      ];
      await tester.pumpWidget(
        chartOf(_red, transitions: transitions, animations: animations),
      );
      await tester.pumpAndSettle();
      final chart = _chart(tester);
      final controller = chart.getDatasetMeta(0).controller!;
      expect(
        controller
            .resolveAnimations(0, 'active')
            .itemOf(
              AnimatedProp.borderColor,
            ),
        same(mode),
      );
      expect(
        controller.resolveAnimations(0).itemOf(AnimatedProp.borderColor),
        same(animations.single),
      );

      await tester.pumpWidget(
        chartOf(_blue, transitions: transitions, animations: animations),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      // Off in the mode: the color changes at once.
      final atOnce = _borderColor(chart);
      expect(atOnce.r, 0);
      await tester.pumpAndSettle();
      expect(_borderColor(chart), atOnce);
    });
  });

  group('a class of another library', () {
    testWidgets('is not an item of the chart', (tester) async {
      const badge = _BadgeAnimation(duration: Duration(milliseconds: 200));
      const pulse = _PulseTransition(duration: Duration(milliseconds: 300));
      const radius = RadiusAnimation(loop: true);
      await tester.pumpWidget(
        _box(
          const ChartView(
            config: ChartConfig(
              type: .line,
              labels: ['a', 'b', 'c'],
              datasets: [
                LineDataset(data: [1, 2, 3]),
              ],
              animations: [badge, radius],
              transitions: [pulse],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      // The chart reads its own classes and leaves the other ones.
      final animations = _animations(_chart(tester));
      expect(animations.itemOf(AnimatedProp.radius), same(radius));
      await tester.pumpAndSettle();
    });
  });
}
