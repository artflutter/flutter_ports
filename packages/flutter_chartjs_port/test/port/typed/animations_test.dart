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
          borderColor: ChartValue.constant(color),
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
    _optionsOf(chart.getDatasetMeta(0).dataset)['borderColor']! as Color;

/// The border width of bar 0 of dataset 0.
double _borderWidth(Chart chart) =>
    _optionsOf(chart.getDatasetMeta(0).data[0])['borderWidth']! as double;

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
          contains('two items for radius'),
        ),
      );
    });
  });
}
