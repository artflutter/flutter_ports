// Original code, not ported from Chart.js: the namespaces of src/index.ts.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

// The namespaces and `registerables` of src/index.ts:8-25 (Chart.js ADR
// 0204). In the published bundle, a namespace is a frozen object
// with the export names in code unit order. `Chart.register(
// ...registerables)` then registers the element classes in the order arc,
// bar, line, point (Chart.js ADR 0020, probe 2). The source order of
// elements/index.js (:1-4) is arc, line, point, bar. The scale classes
// register in the order category, linear, logarithmic, radialLinear, time,
// timeseries: the code unit order and the source order of scales/index.js
// (:1-6) are the same. The namespace `controllers` has the eight
// controllers of phase 7. The namespace `plugins` has the seven plugin
// objects of src/plugins/index.js:1-7, and `Chart.register(
// ...registerables)` registers the plugin ids in the order colors,
// decimation, filler, legend, subtitle, title, tooltip (Chart.js ADR 0038,
// section 2).
//
// The library also exports the names of src/core/index.ts and of the other
// index modules. The test reads some of them, so that a missing export
// fails the analysis.
//
// flutter_test_config.dart registers the built-in components before main()
// (harness-register-builtins). A second registration of an element or of
// the radial linear scale through a new Registry throws, as a second
// `Object.defineProperties` of a route does. Thus the file removes them
// first.

void main() {
  removeBuiltins();

  test('registerables is the List of the items of the four namespaces', () {
    // The items, not the namespaces (Chart.js ADR 0204).
    expect(registerables, [
      ...controllers.values,
      ...elements.values,
      ...plugins.values,
      ...scales.values,
    ]);
    expect(() => registerables.add(colors), throwsA(isA<UnsupportedError>()));
  });

  test('the namespace elements has the export names in code unit order', () {
    expect(jsObjectKeys(elements), [
      'ArcElement',
      'BarElement',
      'LineElement',
      'PointElement',
    ]);
    expect(elements['ArcElement'], same(ArcElement.component));
    expect(elements['BarElement'], same(BarElement.component));
    expect(elements['LineElement'], same(LineElement.component));
    expect(elements['PointElement'], same(PointElement.component));
  });

  test('the namespace scales has the export names in code unit order', () {
    // The order of the x64 Node.js v24.12.0 run of the chart.js 4.5.1 dist:
    // `Object.keys(scales)`. `LinearScaleBase` is not an export of
    // scales/index.js.
    expect(jsObjectKeys(scales), [
      'CategoryScale',
      'LinearScale',
      'LogarithmicScale',
      'RadialLinearScale',
      'TimeScale',
      'TimeSeriesScale',
    ]);
    expect(scales['CategoryScale'], same(CategoryScale.component));
    expect(scales['LinearScale'], same(LinearScale.component));
    expect(scales['LogarithmicScale'], same(LogarithmicScale.component));
    expect(scales['RadialLinearScale'], same(RadialLinearScale.component));
    expect(scales['TimeScale'], same(TimeScale.component));
    expect(scales['TimeSeriesScale'], same(TimeSeriesScale.component));
  });

  test('the namespace controllers has the export names in code unit order', () {
    // The bundle keys of `Object.keys(controllers)` are BarController,
    // BubbleController, DoughnutController, LineController, PieController,
    // PolarAreaController, RadarController and ScatterController (code unit
    // order). controllers/index.js lists PolarAreaController before
    // PieController (:5-6).
    expect(jsObjectKeys(controllers), [
      'BarController',
      'BubbleController',
      'DoughnutController',
      'LineController',
      'PieController',
      'PolarAreaController',
      'RadarController',
      'ScatterController',
    ]);
    expect(controllers['BarController'], same(BarController.component));
    expect(controllers['BubbleController'], same(BubbleController.component));
    expect(
      controllers['DoughnutController'],
      same(DoughnutController.component),
    );
    expect(controllers['LineController'], same(LineController.component));
    expect(controllers['PieController'], same(PieController.component));
    expect(
      controllers['PolarAreaController'],
      same(PolarAreaController.component),
    );
    expect(controllers['RadarController'], same(RadarController.component));
    expect(controllers['ScatterController'], same(ScatterController.component));
    expect(
      () => controllers['X'] = BarController.component,
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('the namespace plugins has the export names in code unit order', () {
    // The order of the x64 Node.js v24.12.0 run of the pinned build:
    // `Object.keys(plugins)` (Chart.js ADR 0038, section 2). Each value is
    // the plugin object of its module, the default export of
    // src/plugins/index.js:1-7.
    expect(jsObjectKeys(plugins), [
      'Colors',
      'Decimation',
      'Filler',
      'Legend',
      'SubTitle',
      'Title',
      'Tooltip',
    ]);
    expect(plugins['Colors'], same(colors));
    expect(plugins['Decimation'], same(decimation));
    expect(plugins['Filler'], same(filler));
    expect(plugins['Legend'], same(legend));
    expect(plugins['SubTitle'], same(subTitle));
    expect(plugins['Title'], same(title));
    expect(plugins['Tooltip'], same(tooltip));
    expect(() => plugins['X'] = colors, throwsA(isA<UnsupportedError>()));
  });

  test('a namespace is unmodifiable, as a frozen object', () {
    expect(
      () => elements['X'] = ArcElement.component,
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('add(registerables) registers the components in the bundle order', () {
    // The orders of the x64 Node.js v24.12.0 run of the chart.js 4.5.1 dist:
    // `Chart.register(...registerables)`, then the keys of
    // `Chart.registry.scales.items` and of `Chart.defaults.scales`.
    final registry = Registry()..add(registerables);
    expect(jsObjectKeys(registry.elements.items), [
      'arc',
      'bar',
      'line',
      'point',
    ]);
    expect(jsObjectKeys(registry.scales.items), [
      'category',
      'linear',
      'logarithmic',
      'radialLinear',
      'time',
      'timeseries',
    ]);
    expect(jsObjectKeys(defaults.get('scales')), [
      'category',
      'linear',
      'logarithmic',
      'radialLinear',
      'time',
      'timeseries',
    ]);
    // The controllers register in the order bar, bubble, doughnut, line,
    // pie, polarArea, radar, scatter. Each one adds its defaults to
    // `defaults.datasets` and its overrides to `overrides`. The pie gives
    // the overrides of the doughnut (Chart.js ADR 0204).
    const ids = [
      'bar',
      'bubble',
      'doughnut',
      'line',
      'pie',
      'polarArea',
      'radar',
      'scatter',
    ];
    expect(jsObjectKeys(registry.controllers.items), ids);
    expect(registry.controllers.items['bar'], same(BarController.component));
    expect(
      registry.controllers.items['bubble'],
      same(BubbleController.component),
    );
    // controller.doughnut.tests.js:4-7.
    expect(
      registry.controllers.items['doughnut'],
      same(DoughnutController.component),
    );
    expect(registry.controllers.items['line'], same(LineController.component));
    expect(registry.controllers.items['pie'], same(PieController.component));
    expect(
      registry.controllers.items['polarArea'],
      same(PolarAreaController.component),
    );
    expect(
      registry.controllers.items['radar'],
      same(RadarController.component),
    );
    expect(
      registry.controllers.items['scatter'],
      same(ScatterController.component),
    );
    expect(jsObjectKeys(defaults.get('datasets')), ids);
    expect(jsObjectKeys(Chart.overrides), ids);
    // The plugins register in the order of the namespace, and each one adds
    // its defaults to `defaults.plugins`. The orders of the x64 Node.js
    // v24.12.0 run of the pinned build: `Object.keys` of
    // `Chart.registry.plugins.items` and of `Chart.defaults.plugins`.
    const pluginIds = [
      'colors',
      'decimation',
      'filler',
      'legend',
      'subtitle',
      'title',
      'tooltip',
    ];
    expect(jsObjectKeys(registry.plugins.items), pluginIds);
    expect(jsObjectKeys(defaults.get('plugins')), pluginIds);
    for (final name in jsObjectKeys(plugins)) {
      final plugin = plugins[name]!;
      expect(
        registry.plugins.items[plugin.id],
        same(plugin),
        reason: 'the registry item of $name',
      );
    }
  });

  test('the library exports the names of src/core/index.ts', () {
    expect(Chart.version, '4.6.1');
    expect(registry, same(Chart.registry));
    expect(defaults, same(Chart.defaults));
    expect(animator, isNotNull);
    expect(layouts.addBox, isNotNull);
    expect(Interaction.evaluateInteractionItems, isNotNull);
    expect(adapters.date, same(DefaultDateAdapter.new));
    expect(ticks, contains('formatters'));
    expect(DatasetController.new, isNotNull);
    expect(Element.new, isNotNull);
    expect(Scale.new, isNotNull);
    expect(PluginService.new, isNotNull);
    expect(Animations.new, isNotNull);
    expect(Animation.new, isNotNull);
    expect(BasicPlatform.new, isNotNull);
    expect(detectPlatform, isNotNull);
  });
}
