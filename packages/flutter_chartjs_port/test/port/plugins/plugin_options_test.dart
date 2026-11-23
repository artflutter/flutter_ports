// Original code, not ported from Chart.js: the resolved plugin option classes.
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

/// A new List with the items of [items], not a constant.
List<T> _copy<T>(List<T> items) => List.of(items);

/// Options of an add-on with no field `events`.
final class const _NoEvents() extends PluginOptions<_NoEvents> {
  @override
  String get pluginId => 'noEvents';

  @override
  _NoEvents merge(_NoEvents over) => over;
}

// The option objects of the built-in plugins (Chart.js ADRs 0192 to 0197):
// `merge`, `==`, `hashCode`, the plugin id and the layout keys.
void main() {
  // The title and the subtitle options are one object each (Chart.js ADR
  // 0197), with the fields of their shared base.
  group('TitleOptions and SubtitleOptions', () {
    TitleOptions? script(ScriptableChartContext context, TitleOptions o) =>
        null;

    test('merge takes each field that the other options set', () {
      const base = TitleOptions(
        align: ChartAlign.center,
        display: false,
        font: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        fullSize: true,
        padding: EdgeInsets.all(10),
        position: ChartPosition.top,
        text: [''],
        weight: 2000,
      );
      final merged = base.merge(
        TitleOptions(
          display: true,
          color: const ChartPaint.solid(Color(0xff112233)),
          font: const TextStyle(fontSize: 20),
          text: const ['Sales', '2026'],
          scripted: script,
          events: const ['click'],
        ),
      );
      expect(merged, isA<TitleOptions>());
      expect(merged.align, ChartAlign.center);
      expect(merged.display, isTrue);
      expect(merged.color, const ChartPaint.solid(Color(0xff112233)));
      // A font merges by field, as the resolver merges the font objects.
      expect(merged.font!.fontSize, 20);
      expect(merged.font!.fontWeight, FontWeight.bold);
      expect(merged.fullSize, isTrue);
      expect(merged.padding, const EdgeInsets.all(10));
      expect(merged.position, ChartPosition.top);
      expect(merged.text, ['Sales', '2026']);
      expect(merged.weight, 2000);
      expect(merged.scripted, same(script));
      expect(merged.events, ['click']);
      expect(base.merge(const TitleOptions()), base);
    });

    test('a subtitle merges into a subtitle', () {
      const merged = SubtitleOptions(weight: 1500);
      final result = merged.merge(const SubtitleOptions(display: true));
      expect(result, isA<SubtitleOptions>());
      expect(result, const SubtitleOptions(weight: 1500, display: true));
    });

    test('== and hashCode compare the fields and the class', () {
      final a = TitleOptions(text: _copy(['a']), events: _copy(['click']));
      final b = TitleOptions(text: _copy(['a']), events: _copy(['click']));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const TitleOptions(text: ['b'], events: ['click'])));
      expect(a, isNot(TitleOptions(text: _copy(['a']))));
      expect(
        const TitleOptions(display: true),
        isNot(const SubtitleOptions(display: true)),
      );
      expect(const TitleOptions(), isNot(TitleOptions(scripted: script)));
    });

    test('the layout reads display, fullSize, position and weight', () {
      const options = TitleOptions(
        display: true,
        fullSize: false,
        position: ChartPosition.left,
        weight: 42,
      );
      expect(options.layoutOption(OptionKey.display), isTrue);
      expect(options.layoutOption(OptionKey.fullSize), isFalse);
      expect(options.layoutOption(OptionKey.position), ChartPosition.left);
      expect(options.layoutOption(OptionKey.weight), 42);
      expect(options.layoutOption(OptionKey.text), same(undefined));
      expect(
        const TitleOptions().layoutOption(OptionKey.weight),
        same(undefined),
      );
    });

    test('the plugin ids are title and subtitle', () {
      expect(const TitleOptions().pluginId, 'title');
      expect(const SubtitleOptions().pluginId, 'subtitle');
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

  // The decimation options are one object of the app (Chart.js ADR 0194).
  group('DecimationOptions', () {
    test('merge takes each field that the other options set', () {
      const base = DecimationOptions(
        enabled: false,
        algorithm: MinMaxDecimationAlgorithm(),
        threshold: 20,
      );
      final merged = base.merge(
        const DecimationOptions(
          enabled: true,
          algorithm: LttbDecimationAlgorithm(),
          samples: 50,
          events: ['click'],
        ),
      );
      expect(merged.enabled, isTrue);
      expect(merged.algorithm, const LttbDecimationAlgorithm());
      expect(merged.samples, 50);
      expect(merged.threshold, 20);
      expect(merged.events, ['click']);
      expect(base.merge(const DecimationOptions()), base);
      expect(const DecimationOptions().merge(base), base);
    });

    test('== and hashCode compare the fields', () {
      DecimationOptions make({double samples = 50}) => DecimationOptions(
        enabled: true,
        algorithm: const LttbDecimationAlgorithm(),
        samples: samples,
        threshold: 100,
        events: const ['click'],
      );
      expect(make(), make());
      expect(make().hashCode, make().hashCode);
      expect(make(), isNot(make(samples: 60)));
      expect(const DecimationOptions(), const DecimationOptions());
      expect(
        const DecimationOptions(algorithm: LttbDecimationAlgorithm()),
        isNot(const DecimationOptions(algorithm: MinMaxDecimationAlgorithm())),
      );
      expect(
        const DecimationOptions(events: ['click']),
        isNot(const DecimationOptions(events: ['click', 'mousemove'])),
      );
    });

    test('the plugin id is decimation', () {
      expect(const DecimationOptions().pluginId, 'decimation');
    });
  });

  // The filler and colors options are one object each (Chart.js ADR 0196).
  group('FillerOptions', () {
    test('merge takes each field that the other options set', () {
      const base = FillerOptions(
        propagate: true,
        drawTime: FillerDrawTime.beforeDatasetDraw,
      );
      expect(
        base.merge(const FillerOptions(drawTime: FillerDrawTime.beforeDraw)),
        const FillerOptions(
          propagate: true,
          drawTime: FillerDrawTime.beforeDraw,
        ),
      );
      expect(base.merge(const FillerOptions()), base);
      expect(const FillerOptions().merge(base), base);
      expect(base.merge(const FillerOptions(events: ['click'])).events, [
        'click',
      ]);
    });

    test('== and hashCode compare the fields', () {
      expect(
        FillerOptions(propagate: false, events: _copy(['click'])),
        const FillerOptions(propagate: false, events: ['click']),
      );
      expect(
        FillerOptions(propagate: false, events: _copy(['click'])).hashCode,
        const FillerOptions(propagate: false, events: ['click']).hashCode,
      );
      expect(
        const FillerOptions(propagate: false),
        isNot(const FillerOptions(propagate: true)),
      );
      expect(
        const FillerOptions(drawTime: FillerDrawTime.beforeDraw),
        isNot(const FillerOptions()),
      );
    });

    test('the plugin id is filler', () {
      expect(const FillerOptions().pluginId, 'filler');
    });
  });

  group('ColorsPluginOptions', () {
    const red = Color(0xffff0000);
    const blue = Color(0xff0000ff);

    test('merge takes each field that the other options set', () {
      const base = ColorsPluginOptions(enabled: true, forceOverride: false);
      expect(
        base.merge(const ColorsPluginOptions(enabled: false)),
        const ColorsPluginOptions(enabled: false, forceOverride: false),
      );
      expect(base.merge(const ColorsPluginOptions()), base);
      expect(const ColorsPluginOptions().merge(base), base);
      expect(
        base.merge(const ColorsPluginOptions(borderColors: [red])),
        const ColorsPluginOptions(
          enabled: true,
          forceOverride: false,
          borderColors: [red],
        ),
      );
    });

    test('== and hashCode compare the fields and the palette items', () {
      expect(
        ColorsPluginOptions(borderColors: _copy([red, blue])),
        const ColorsPluginOptions(borderColors: [red, blue]),
      );
      expect(
        ColorsPluginOptions(backgroundColors: _copy([red])).hashCode,
        const ColorsPluginOptions(backgroundColors: [red]).hashCode,
      );
      expect(
        const ColorsPluginOptions(borderColors: [red, blue]),
        isNot(const ColorsPluginOptions(borderColors: [blue, red])),
      );
      expect(
        const ColorsPluginOptions(forceOverride: true),
        isNot(const ColorsPluginOptions()),
      );
    });

    test('the plugin id is colors', () {
      expect(const ColorsPluginOptions().pluginId, 'colors');
    });
  });

  test('the options of an add-on give no events by default', () {
    expect(const _NoEvents().events, isNull);
  });
}
