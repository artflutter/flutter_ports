// Original code, not ported from Chart.js: controller setup guards.
@TestOn('vm')
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableContext;
import 'package:flutter_chartjs_port/src/options/element_options_base.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:flutter_test/flutter_test.dart';

class _ObservedConfig(super.config) extends Config {
  final prefixesSeen = <List<String>>[];
  int ownedCalls = 0;
  @override
  ElementOptions resolveNativeElementNamedOptions(
    List<Object?> scopes,
    List<Object> keys,
    Object Function() context,
    List<String> prefixes,
    ElementOptions into, {
    bool allowReplacement = false,
  }) {
    if (prefixes.length == 2 && prefixes.first == 'point') {
      prefixesSeen.add(prefixes);
    }
    return super.resolveNativeElementNamedOptions(
      scopes,
      keys,
      context,
      prefixes,
      into,
      allowReplacement: allowReplacement,
    );
  }

  @override
  ElementOptions resolveOwnedElementNamedOptions(
    List<Object?> scopes,
    List<Object> keys,
    Object Function() context,
    List<String> prefixes, {
    required bool point,
    bool immutableKeys = false,
  }) {
    ownedCalls++;
    return super.resolveOwnedElementNamedOptions(
      scopes,
      keys,
      context,
      prefixes,
      point: point,
      immutableKeys: immutableKeys,
    );
  }
}

class _ConfigChart(Object item, final Config supplied) extends Chart {
  this : super(item, <String, Object?>{});
  @override
  Config get config => supplied;
}

final class _ObservedPointScope(final PointOptionsScope source)
    extends OptionScope {
  int reads = 0;
  @override
  ScopeKind get kind => source.kind;
  @override
  Opt<Object?>? cellOf(OptionKey key) => source.cellOf(key);
  @override
  void setCell(OptionKey key, Opt<Object?>? value) =>
      source.setCell(key, value);
  @override
  bool hasField(OptionKey key) => source.hasField(key);
  @override
  Opt<Object?> classify(OptionKey key, Object? raw) =>
      source.classify(key, raw);
  @override
  List<Object> jsOwnKeys() {
    reads++;
    return source.jsOwnKeys();
  }
}

Map<String, Object?> config() => {
  'type': 'line',
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[
          for (var i = 0; i < 8; i++)
            <String, Object?>{'x': i.toDouble(), 'y': i.toDouble()},
        ],
        'backgroundColor': (Object? ctx) =>
            const ChartPaint.solid(Color(0xff0000ff)),
      },
    ],
  },
  'options': <String, Object?>{
    'responsive': false,
    'animation': false,
    'parsing': false,
    'plugins': <String, Object?>{'legend': false},
    'scales': <String, Object?>{
      'x': <String, Object?>{'type': 'linear', 'display': false},
      'y': <String, Object?>{'type': 'linear', 'display': false},
    },
  },
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'custom Config keeps native virtual dispatch and fresh prefix lists',
    () {
      final cfg = _ObservedConfig(config());
      final chart = _ConfigChart(UiCanvasElement(width: 400, height: 300), cfg);
      addTearDown(chart.destroy);
      chart.update('none');
      expect(cfg.ownedCalls, 0);
      expect(cfg.prefixesSeen.length, greaterThan(8));
      expect(cfg.prefixesSeen.toSet().length, cfg.prefixesSeen.length);
    },
  );
  test('custom default-key producer still enumerates for each resolution', () {
    final chart = Chart(UiCanvasElement(width: 400, height: 300), config());
    addTearDown(chart.destroy);
    final elements =
        Chart.defaults.elementsCell!.raw! as ElementOptionsByTypeScope;
    final original = elements.pointCell!.raw! as PointOptionsScope;
    final observed = _ObservedPointScope(original);
    elements.jsWrite('point', observed);
    addTearDown(() => elements.jsWrite('point', original));
    final controller = chart.getDatasetMeta(0).controller!;
    for (var i = 0; i < 4; i++) {
      controller.resolveDataElementOptions(i.toDouble(), 'none');
    }
    expect(observed.reads, 4);
  });
  test('default key changes inside a callback reach the next point', () {
    final elements =
        Chart.defaults.elementsCell!.raw! as ElementOptionsByTypeScope;
    final defaults = elements.pointCell!.raw! as PointOptionsScope;
    final saved = defaults.saveState();
    final observations = <Object>[];
    final traces = <List<Object?>>[];
    for (final ordinary in [false, true]) {
      defaults.restoreState(saved);
      final cfg = config();
      var mutate = false;
      final trace = <Object?>[];
      ChartPaint color(Object? context) {
        final index = (context! as ScriptableContext).index;
        if (mutate) trace.add(index);
        if (mutate && index == 1.0) {
          defaults
            ..jsDelete('radius')
            ..jsWrite('lateOption', 7.0);
        }
        return const ChartPaint.solid(Color(0xff0000ff));
      }

      final datasets =
          (cfg['data']! as Map<String, Object?>)['datasets']! as List<Object?>;
      (datasets.first! as Map<String, Object?>)['backgroundColor'] = color;
      final canvas = UiCanvasElement(width: 400, height: 300);
      final chart = ordinary
          ? _ConfigChart(canvas, _ObservedConfig(cfg))
          : Chart(canvas, cfg);
      try {
        mutate = true;
        final controller = chart.getDatasetMeta(0).controller!;
        observations.add([
          for (var i = 0; i < 4; i++)
            switch (controller.resolveDataElementOptions(
              i.toDouble(),
              'none',
            )) {
              final ElementOptions options => [
                options.jsKeys(),
                {for (final key in options.jsKeys()) key: options.jsRead(key)},
              ],
            },
        ]);
        traces.add(trace);
      } finally {
        mutate = false;
        chart.destroy();
        defaults.restoreState(saved);
      }
    }
    expect(observations[0], observations[1]);
    expect(traces[0], [0.0, 1.0, 2.0, 3.0]);
    expect(traces[0], traces[1]);
  });
}
