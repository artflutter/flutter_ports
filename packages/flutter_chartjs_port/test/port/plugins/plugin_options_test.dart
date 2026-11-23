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
        DecimationOptions.of(<String, Object?>{'samples': 50.0}).samples,
        50,
      );
      expect(
        DecimationOptions.of(<String, Object?>{'threshold': 0.0}).threshold,
        isNull,
      );
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
      expect(TitleOptions.of(<String, Object?>{}).position, isNull);
    });
  });

  // The legend options are one object of the app (Chart.js ADR 0193): the
  // plugin service merges the objects of the scopes with `merge`, and
  // `ChartView` compares two configs with `==`.
  group('LegendOptions', () {
    bool filter(LegendItem item, Object data) => true;
    int sort(LegendItem a, LegendItem b, Object data) => 0;

    test('merge takes each field that the other options set', () {
      final base = LegendOptions(
        display: true,
        position: ChartPosition.top,
        weight: 1000,
        labels: LegendLabelOptions(
          boxWidth: 40,
          padding: 10,
          font: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          filter: filter,
        ),
        title: const LegendTitleOptions(display: false, text: ['']),
      );
      final merged = base.merge(
        LegendOptions(
          position: const ScaleValuePosition('x', 0),
          maxWidth: 120,
          labels: LegendLabelOptions(
            padding: 4,
            font: const TextStyle(fontSize: 20),
            sort: sort,
          ),
          title: const LegendTitleOptions(display: true, text: ['Series']),
        ),
      );
      expect(merged.display, isTrue);
      expect(merged.position, const ScaleValuePosition('x', 0));
      expect(merged.maxWidth, 120);
      expect(merged.weight, 1000);
      // The label and title options merge by field, and a font merges by
      // field as the resolver merges the keys of a font object.
      expect(merged.labels!.boxWidth, 40);
      expect(merged.labels!.padding, 4);
      expect(merged.labels!.font!.fontSize, 20);
      expect(merged.labels!.font!.fontWeight, FontWeight.bold);
      expect(merged.labels!.filter, same(filter));
      expect(merged.labels!.sort, same(sort));
      expect(merged.title!.display, isTrue);
      expect(merged.title!.text, ['Series']);
      expect(base.merge(const LegendOptions()), base);
      expect(const LegendOptions().merge(base), base);
    });

    test('== and hashCode compare the fields', () {
      LegendOptions make({double boxWidth = 40}) => LegendOptions(
        display: true,
        position: ChartPosition.bottom,
        labels: LegendLabelOptions(
          boxWidth: boxWidth,
          color: const ChartPaint.solid(Color(0xff666666)),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          filter: filter,
        ),
        title: const LegendTitleOptions(
          display: true,
          text: ['a', 'b'],
          padding: EdgeInsets.all(6),
        ),
        events: const ['click'],
      );
      expect(make(), make());
      expect(make().hashCode, make().hashCode);
      expect(make(), isNot(make(boxWidth: 20)));
      expect(const LegendOptions(), const LegendOptions());
      expect(
        const LegendOptions(title: LegendTitleOptions(text: ['a'])),
        isNot(const LegendOptions(title: LegendTitleOptions(text: ['a', 'b']))),
      );
      expect(const LegendOptions(display: false), isNot(const LegendOptions()));
      // A new closure is a new value.
      expect(
        LegendOptions(onClick: (e, item, legend) {}),
        isNot(LegendOptions(onClick: (e, item, legend) {})),
      );
    });

    test('the layout reads display, fullSize, position and weight', () {
      const options = LegendOptions(
        display: false,
        fullSize: true,
        position: ChartPosition.left,
        weight: 5,
        align: ChartAlign.end,
      );
      expect(readOption(options, OptionKey.display), isFalse);
      expect(readOption(options, OptionKey.fullSize), isTrue);
      expect(readOption(options, OptionKey.position), ChartPosition.left);
      expect(readOption(options, OptionKey.weight), 5);
      expect(readOption(options, OptionKey.align), same(undefined));
      expect(
        readOption(const LegendOptions(), OptionKey.display),
        same(undefined),
      );
    });

    test('the plugin id is legend', () {
      expect(const LegendOptions().pluginId, 'legend');
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
