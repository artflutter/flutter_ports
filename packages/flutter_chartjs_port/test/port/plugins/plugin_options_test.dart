// Original code, not ported from Chart.js: the resolved plugin option classes.
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

/// Options of an add-on with no field `events`.
final class const _NoEvents() extends PluginOptions<_NoEvents> {
  @override
  String get pluginId => 'noEvents';

  @override
  _NoEvents merge(_NoEvents over) => over;
}

// Each field has the type of its schema key, with the conversion that `of`
// applies at its one read of the key (Chart.js ADR 0182). A plain Map stands
// for the resolved options.
void main() {
  // Maps: the subject is `of`, the read of raw resolved options into the
  // classes of Chart.js ADR 0182.
  group('the fields that `of` reads from the resolved options', () {
    test('a number of a truthy value, else null', () {
      expect(
        LegendOptions.of(<String, Object?>{'maxWidth': 120.0}).maxWidth,
        120,
      );
      expect(
        LegendOptions.of(<String, Object?>{'maxHeight': '80'}).maxHeight,
        80,
      );
      expect(
        LegendOptions.of(<String, Object?>{'maxWidth': 0.0}).maxWidth,
        isNull,
      );
      expect(LegendOptions.of(<String, Object?>{}).maxHeight, isNull);
      expect(
        LegendLabelOptions.of(<String, Object?>{'pointStyleWidth': 12.0})
            .pointStyleWidth,
        12,
      );
      expect(
        DecimationOptions.of(<String, Object?>{'samples': 50.0}).samples,
        50,
      );
      expect(
        DecimationOptions.of(<String, Object?>{'threshold': 0.0}).threshold,
        isNull,
      );
    });

    test('a number of a defined value, else null', () {
      final labels = LegendLabelOptions.of(<String, Object?>{
        'boxWidth': 30.0,
        'boxHeight': null,
      });
      expect(labels.boxWidth, 30);
      // `ToNumber(null)` is 0: only `undefined` takes the default.
      expect(labels.boxHeight, 0);
      expect(LegendLabelOptions.of(<String, Object?>{}).boxWidth, isNull);
    });

    test('a number', () {
      expect(LegendLabelOptions.of(<String, Object?>{}).padding, isNaN);
    });

    test('the lines of a text', () {
      expect(
        TitleOptions.of(<String, Object?>{
          'text': ['a'],
        }).text,
        ['a'],
      );
      expect(
        TitleOptions.of(<String, Object?>{
          'text': ['a', 'b'],
        }).text,
        ['a', 'b'],
      );
      expect(
        LegendTitleOptions.of(<String, Object?>{
          'text': ['a'],
        }).text,
        ['a'],
      );
      expect(
        TitleOptions.of(<String, Object?>{'text': <String>[]}).text,
        isEmpty,
      );
      // A text takes its lines (row adapt-title-text-lines): `of` stops a
      // debug build at a String.
      expect(
        () => TitleOptions.of(<String, Object?>{'text': 'a'}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a font, a text align and an enum', () {
      final font = TitleOptions.of(<String, Object?>{
        'font': const ChartTextStyle(fontSize: 20),
      }).font;
      expect(font.fontSize, 20);
      expect(LegendLabelOptions.of(<String, Object?>{}).textAlign, isNull);
      expect(
        FillerOptions.of(<String, Object?>{
          'drawTime': FillerDrawTime.beforeDraw,
        }).drawTime,
        FillerDrawTime.beforeDraw,
      );
    });

    test('a position', () {
      expect(
        TitleOptions.of(<String, Object?>{'position': ChartPosition.left})
            .position,
        ChartPosition.left,
      );
      expect(
        LegendOptions.of(<String, Object?>{
          'position': const ScaleValuePosition('x', 0.0),
        }).position,
        const ScaleValuePosition('x', 0.0),
      );
      expect(TitleOptions.of(<String, Object?>{}).position, isNull);
    });
  });

  // The tooltip options are one object of the app (Chart.js ADR 0192): the
  // plugin service merges the objects of the scopes with `merge`, and
  // `ChartView` compares two configs with `==`.
  group('TooltipOptions', () {
    List<String> title(TooltipModel tooltip, List<TooltipItem> items) => [
      'title',
    ];
    List<String> label(TooltipModel tooltip, TooltipItem item) => ['label'];

    test('merge takes each field that the other options set', () {
      const base = TooltipOptions(
        enabled: true,
        caretSize: 5,
        bodyAlign: TextAlign.left,
        padding: EdgeInsets.all(6),
        borderWidth: 0,
      );
      final merged = base.merge(
        const TooltipOptions(caretSize: 8, bodyAlign: TextAlign.right),
      );
      expect(merged.enabled, isTrue);
      expect(merged.caretSize, 8);
      expect(merged.bodyAlign, TextAlign.right);
      expect(merged.padding, const EdgeInsets.all(6));
      expect(merged.borderWidth, 0);
      expect(merged.boxWidth, isNull);
      expect(base.merge(const TooltipOptions()), base);
      expect(const TooltipOptions().merge(base), base);
    });

    test(
      'merge merges the fonts, the animation and the callbacks by field',
      () {
        final base = TooltipOptions(
          titleFont: const ChartTextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          animation: const TooltipAnimation(
            duration: Duration(milliseconds: 400),
          ),
          callbacks: TooltipCallbacks(title: title),
        );
        final merged = base.merge(
          TooltipOptions(
            titleFont: const ChartTextStyle(fontSize: 20),
            animation: const TooltipAnimation(delay: Duration(milliseconds: 5)),
            callbacks: TooltipCallbacks(label: label),
          ),
        );
        expect(merged.titleFont!.fontWeight, FontWeight.bold);
        expect(merged.titleFont!.fontSize, 20);
        expect(merged.animation!.duration, const Duration(milliseconds: 400));
        expect(merged.animation!.delay, const Duration(milliseconds: 5));
        expect(merged.callbacks!.title, same(title));
        expect(merged.callbacks!.label, same(label));
        // `off` ends the fallback, as the `false` of a scope upstream.
        expect(
          base
              .merge(const TooltipOptions(animation: TooltipAnimation.off))
              .animation,
          TooltipAnimation.off,
        );
      },
    );

    test('merge keeps the animation items of the classes that the other '
        'options have no item of', () {
      const x = XAnimation(duration: Duration(milliseconds: 100));
      const opacity = OpacityAnimation(duration: Duration(milliseconds: 200));
      const newOpacity = OpacityAnimation.off();
      final merged = const TooltipOptions(animations: [x, opacity])
          .merge(const TooltipOptions(animations: [newOpacity]));
      expect(merged.animations, [same(x), same(newOpacity)]);
    });

    test('== and hashCode compare the fields', () {
      TooltipOptions make({double caretSize = 5}) => TooltipOptions(
        enabled: true,
        caretSize: caretSize,
        backgroundColor: const ChartPaint.solid(Color(0xcc000000)),
        titleFont: const ChartTextStyle(fontWeight: FontWeight.bold),
        cornerRadius: const BorderRadius.all(Radius.circular(6)),
        animations: const [OpacityAnimation(easing: Curves.linear)],
        mode: const IndexInteractionMode(),
        events: const ['click'],
      );
      expect(make(), make());
      expect(make().hashCode, make().hashCode);
      expect(make(), isNot(make(caretSize: 6)));
      expect(const TooltipOptions(), const TooltipOptions());
      expect(
        const TooltipOptions(events: ['click']),
        isNot(const TooltipOptions(events: ['click', 'mousemove'])),
      );
      expect(
        const TooltipOptions(enabled: false),
        isNot(const TooltipOptions()),
      );
    });

    test('the plugin id is tooltip', () {
      expect(const TooltipOptions().pluginId, 'tooltip');
    });
  });

  test('the options of an add-on give no events by default', () {
    expect(const _NoEvents().events, isNull);
  });
}
