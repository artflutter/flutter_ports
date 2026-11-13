// Original code, not ported from Chart.js: axis label-plan invalidation twins.
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/chartjs.dart' show Chart;
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_text.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/scales/scale.category.dart';
// Keep mutations and their subsequent verification as separate test steps.
// ignore_for_file: cascade_invocations

import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

const _n = 1000;

final class _Metrics(@override final double width) implements TextMetrics {
  @override
  double get actualBoundingBoxAscent => 4;
  @override
  double get actualBoundingBoxDescent => 8;
  @override
  double get actualBoundingBoxLeft => 0;
  @override
  double get actualBoundingBoxRight => width;
}

class _Context() extends MockContext {
  int measures = 0;
  int fontWrites = 0;
  double factor = 1;

  @override
  set font(TextStyle? value) {
    fontWrites++;
    super.font = value;
  }

  @override
  TextMetrics measureText(String text) {
    measures++;
    final size = font?.fontSize ?? 12;
    return _Metrics(text.length * size * 0.6 * factor);
  }
}

final class _StableContext()
    extends _Context
    implements CanvasTextMetricsSource {
  @override
  Object textMetricsGeneration = Object();
}

final class _FreshContext()
    extends _Context
    implements CanvasTextMetricsSource {
  // An uncached oracle: every measurement pass observes a new environment.
  @override
  Object get textMetricsGeneration => Object();
}

final class _Ticks(final List<Tick> values) extends ListBase<Tick> {
  void Function(int)? onRead;
  @override
  int get length => values.length;
  @override
  set length(int value) => values.length = value;
  @override
  Tick operator [](int index) {
    onRead?.call(index);
    return values[index];
  }

  @override
  void operator []=(int index, Tick value) => values[index] = value;
}

final class _CustomCategory(super.cfg) extends CategoryScale;

final class _ObservedChart(super.item, super.userConfig) extends Chart {
  int dataReads = 0;
  void Function()? onDataRead;

  @override
  Object get data {
    dataReads++;
    onDataRead?.call();
    return super.data;
  }
}

Map<String, Object?> _config() => {
  'type': 'line',
  'data': {
    'labels': List<Object?>.generate(_n, (i) => 'Point $i'),
    'datasets': [
      {
        'data': List<Map<String, Object?>>.generate(
          _n,
          (i) => {'x': i.toDouble(), 'y': (i % 100 + 1).toDouble()},
        ),
        'showLine': false,
        'backgroundColor': const ChartPaint.solid(ui.Color(0xFF36A2EB)),
      },
    ],
  },
  'options': {
    'responsive': false,
    'maintainAspectRatio': false,
    'animation': false,
    'parsing': false,
    'events': <String>[],
    'plugins': false,
    'scales': {
      'x': {'type': 'category'},
      'y': {'type': 'logarithmic'},
    },
  },
};

Map<String, Object?> _snapshot(Chart chart) => {
  'area': [
    chart.chartArea!.left,
    chart.chartArea!.top,
    chart.chartArea!.right,
    chart.chartArea!.bottom,
  ],
  'axes': {
    for (final entry in chart.scales.entries)
      entry.key: {
        'limits': [entry.value.min, entry.value.max],
        'rotation': entry.value.labelRotation,
        'ticks': [
          for (final tick in entry.value.ticks!)
            [tick.value, tick.label, tick.$context?.index],
        ],
      },
  },
  'points': [
    for (final point in chart.getDatasetMeta(0).data.cast<types.PointElement>())
      [point.x, point.y],
  ],
};

final class _Pair() {
  this {
    for (final chart in [fast, reference]) {
      addTearDown(chart.destroy);
    }
    fast.scales['x']!.ctx = context;
    reference.scales['x']!.ctx = oracle;
  }

  final fast = Chart(UiCanvasElement(width: 800, height: 480), _config());
  final reference = Chart(UiCanvasElement(width: 800, height: 480), _config());
  final context = _StableContext();
  final oracle = _FreshContext();

  void update() {
    fast.update('none');
    reference.update('none');
    expect(_snapshot(fast), _snapshot(reference));
  }

  void each(void Function(Chart chart) change) {
    change(fast);
    change(reference);
  }

  void tickOption(String key, Object? value) => each((chart) {
    (chart.scales['x']!.options.ticks.raw! as OptionView)[key] = value;
  });
}

Map<String, Object?> _data(Chart chart) => chart.data as Map<String, Object?>;

List<Map<String, Object?>> _points(Chart chart) =>
    ((_data(chart)['datasets']! as List<Object?>).first!
            as Map<String, Object?>)['data']!
        as List<Map<String, Object?>>;

void main() {
  setUpDefaultsRestore();

  test('prepared contexts capture their original parent and index', () {
    final parent = ScriptableScaleContext(null)..jsWrite('type', 'scale');
    final tick = Tick(value: 17)..prepareContextForLayout(parent, 4);
    tick.value = 23;
    final context = tick.$context!;
    expect(context.prototype, same(parent));
    expect(context.tick, same(tick));
    expect(context.index, 4.0);
    expect(context.jsKeys(), ['tick', 'index', 'type']);
    expect(tick.$context, same(context));
    context.jsWrite('extra', 'kept');
    expect(tick.$context!.jsRead('extra'), 'kept');
  });

  test('explicit context writes and clears replace pending creation', () {
    final parent = ScriptableScaleContext(null);
    final supplied = ScriptableScaleContext(parent)..jsWrite('index', 99.0);
    final tick = Tick(value: 0)..prepareContextForLayout(parent, 1);
    tick.$context = supplied;
    tick.prepareContextForLayout(parent, 2);
    expect(tick.$context, same(supplied));
    tick.$context = null;
    expect(tick.$context, isNull);
    tick.prepareContextForLayout(parent, 3);
    tick.$context = null;
    expect(tick.$context, isNull);
  });

  test('repeated preparation preserves the first context identity', () {
    final first = ScriptableScaleContext(null);
    final second = ScriptableScaleContext(null);
    final tick = Tick(value: 0)
      ..prepareContextForLayout(first, 1)
      ..prepareContextForLayout(second, 2);
    final context = tick.$context!;
    expect(context.prototype, same(first));
    expect(context.index, 1.0);
    tick.prepareContextForLayout(second, 3);
    expect(tick.$context, same(context));
  });

  test('hooks observe the same contexts before and after measurement', () {
    final pair = _Pair()
      ..update()
      ..update();
    var before = 0;
    var after = 0;
    void beforeRotation(Scale scale) {
      for (final tick in scale.ticks!) {
        expect(tick.$context, isNull);
        before++;
      }
    }

    void afterRotation(Scale scale) {
      final ticks = scale.ticks!;
      for (var i = 0; i < ticks.length; i++) {
        expect(ticks[i].$context!.index, i.toDouble());
        expect(ticks[i].$context!.tick, same(ticks[i]));
        after++;
      }
    }

    pair.each((chart) {
      chart.scales['x']!.options
        ..['beforeCalculateLabelRotation'] = beforeRotation
        ..['afterCalculateLabelRotation'] = afterRotation;
    });
    pair.update();
    expect(before, _n * 2);
    expect(after, _n * 2);
  });

  test('retained skipped ticks keep the parent from their own update', () {
    final pair = _Pair()
      ..update()
      ..update();
    late List<Tick> built;
    void capture(Scale scale) => built = scale.ticks!;
    pair.fast.scales['x']!.options['afterBuildTicks'] = capture;
    pair.update();
    final retained = built[1];
    final scale = pair.fast.scales['x']!;
    expect(scale.ticks!.contains(retained), isFalse);
    final oldParent = scale.$context!;
    scale.$context = ScriptableScaleContext(oldParent.prototype)
      ..jsWrite('scale', scale)
      ..jsWrite('type', 'scale');
    pair.update();
    expect(retained.$context!.prototype, same(oldParent));
    expect(retained.$context!.index, 1.0);
    expect(retained.$context!.tick, same(retained));
  });

  test('a warm plan skips full sizing and keeps every fresh tick context', () {
    final pair = _Pair()..update();
    final previous = pair.fast.scales['x']!.ticks!.first;
    pair.context
      ..measures = 0
      ..fontWrites = 0;
    pair.update();
    expect(pair.context.measures, lessThan(128));
    expect(pair.context.fontWrites, lessThan(128));
    expect(pair.fast.scales['x']!.ticks!.first, isNot(same(previous)));
    expect(pair.fast.scales['x']!.ticks!.first.$context, isNotNull);
    for (final tick in pair.fast.scales['x']!.ticks!) {
      expect(tick.$context!.tick, same(tick));
      expect(tick.$context!.index, tick.value);
      expect(tick.$context!.jsKeys(), ['tick', 'index', 'type']);
    }
  });

  test('resizing and changed y limits refit against current geometry', () {
    final pair = _Pair()
      ..update()
      ..update();
    pair.each((chart) => chart.resize(640, 400));
    pair.update();
    pair.each((chart) => _points(chart)[123]['y'] = 1e8);
    pair.update();
  });

  test('in-place label edits, replacement and growth invalidate content', () {
    final pair = _Pair()
      ..update()
      ..update();
    pair.each((chart) {
      (_data(chart)['labels']! as List<Object?>)[123] = 'very wide label ' * 20;
    });
    pair.update();
    pair.each((chart) {
      _data(chart)['labels'] = List<Object?>.generate(_n, (i) => 'New $i');
    });
    pair.update();
    pair.each((chart) {
      (_data(chart)['labels']! as List<Object?>).add('Added label');
      _points(chart).add({'x': _n.toDouble(), 'y': 123.0});
    });
    pair.update();
  });

  test('font and global default changes invalidate measurements', () {
    final pair = _Pair()
      ..update()
      ..update();
    defaults.font = (defaults.fontCell!.raw! as TextStyle).merge(
      const ChartTextStyle(fontSize: 18),
    );
    pair.update();
    pair.tickOption(
      'font',
      const ChartTextStyle(
        fontSize: 24,
        fontFamily: 'serif',
        fontFamilyFallback: [],
      ),
    );
    pair.update();
  });

  test('rotation, tick limits and sampling retain live fitting rules', () {
    final pair = _Pair()
      ..update()
      ..update();
    for (final entry in {
      'maxRotation': 0.0,
      'maxTicksLimit': 12.0,
      'sampleSize': 100.0,
      'padding': 15.0,
    }.entries) {
      pair.tickOption(entry.key, entry.value);
      pair.update();
    }
  });

  test('dynamic font callbacks run for every candidate', () {
    final pair = _Pair()
      ..update()
      ..update();
    var calls = 0;
    Object font(Object? context) {
      calls++;
      final index = (context! as ContextObject)['index']! as num;
      return ChartTextStyle(fontSize: index.toInt().isEven ? 12 : 18);
    }

    pair.tickOption('font', font);
    pair.update();
    calls = 0;
    pair.update();
    expect(calls, greaterThanOrEqualTo(_n * 2));
  });

  test('dynamic label callbacks and multiline labels retain their results', () {
    final pair = _Pair()
      ..update()
      ..update();
    var calls = 0;
    var phase = 'first';
    Object label(double value, double index, List<Tick> ticks) {
      calls++;
      return '$phase $value';
    }

    pair.tickOption('callback', label);
    pair.update();
    phase = 'changed much wider';
    calls = 0;
    pair.update();
    expect(calls, _n * 2);
    pair.tickOption('callback', (double v) => ['top $v', 'bottom']);
    pair.update();
  });

  test('custom tick lists keep the full virtual-read path', () {
    final pair = _Pair()
      ..update()
      ..update();
    void replaceTicks(Scale scale) => scale.ticks = _Ticks(scale.ticks!);
    pair.each((chart) {
      chart.scales['x']!.options['afterBuildTicks'] = replaceTicks;
    });
    pair.context.fontWrites = 0;
    pair.update();
    expect(pair.context.fontWrites, greaterThanOrEqualTo(_n));
  });

  test('a new text generation remeasures widths', () {
    final pair = _Pair()
      ..update()
      ..update();
    pair.context
      ..factor = 2
      ..textMetricsGeneration = Object()
      ..measures = 0;
    pair.oracle.factor = 2;
    pair.update();
    expect(pair.context.measures, greaterThanOrEqualTo(_n));
  });

  test('custom scale subclasses keep the full virtual font path', () {
    final pair = _Pair();
    pair.each((chart) {
      chart.scales['x'] = _CustomCategory({
        'id': 'x',
        'type': 'category',
        'ctx': chart.scales['x']!.ctx,
        'chart': chart,
      });
    });
    pair.update();
    pair.context.fontWrites = 0;
    pair.update();
    expect(pair.context.fontWrites, greaterThanOrEqualTo(_n));
  });

  test(
    'effectful Chart getters and callback changes retain per-tick reads',
    () {
      final chart = _ObservedChart(
        UiCanvasElement(width: 800, height: 480),
        _config(),
      );
      addTearDown(chart.destroy);
      final scale = chart.scales['x']!;
      final ticks = [for (var i = 0; i < 3; i++) Tick(value: i.toDouble())];
      chart.dataReads = 0;
      String changedLabel(double value) => 'changed $value';
      chart.onDataRead = () {
        if (chart.dataReads == 2) {
          (scale.options.ticks.raw! as OptionView)['callback'] = changedLabel;
        }
      };
      scale.generateTickLabels(ticks);
      expect(ticks.map((tick) => tick.label), [
        'Point 0',
        'Point 1',
        changedLabel(2),
      ]);
      expect(chart.dataReads, 2);
    },
  );

  test('a cleared scale context keeps normal context construction timing', () {
    final pair = _Pair()
      ..update()
      ..update();
    void clearContext(Scale scale) => scale.$context = null;
    pair.each((chart) {
      chart.scales['x']!.options['beforeCalculateLabelRotation'] = clearContext;
    });
    pair.context.fontWrites = 0;
    pair.update();
    expect(pair.context.fontWrites, greaterThanOrEqualTo(_n));
  });

  test('custom tick-list reads may replace the live label source', () {
    final chart = Chart(UiCanvasElement(width: 800, height: 480), _config());
    addTearDown(chart.destroy);
    chart.data = <String, Object?>{..._data(chart)};
    expect(chart.categoryLabels(null, horizontal: true), isNotNull);
    final ticks = _Ticks([
      for (var i = 0; i < 3; i++) Tick(value: i.toDouble()),
    ]);
    ticks.onRead = (index) {
      if (index == 1) {
        _data(chart)['labels'] = <Object?>['New 0', 'New 1', 'New 2'];
      }
    };
    chart.scales['x']!.generateTickLabels(ticks);
    expect(ticks.values.map((tick) => tick.label), [
      'Point 0',
      'New 1',
      'New 2',
    ]);
  });

  testWidgets('Flutter font notifications invalidate native text caches', (
    tester,
  ) async {
    final canvas = UiCanvasElement();
    final ctx = canvas.getContext2d();
    final generation = ctx.textMetricsGeneration;
    expect(generation, isNotNull);
    ctx.measureText('font generation');
    expect(canvasMetricsCacheLength, greaterThan(0));
    await tester.binding.handleSystemMessage({'type': 'fontsChange'});
    expect(ctx.textMetricsGeneration, isNot(same(generation)));
    expect(canvasMetricsCacheLength, 0);
  });
}
