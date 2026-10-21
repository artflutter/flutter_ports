// Original code, not ported from Chart.js: the namespaces of src/index.ts.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/core/core.registry.dart' show Registry;
import 'package:flutter_chartjs/src/index.dart';
import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_test/flutter_test.dart';

// The namespaces and `registerables` of src/index.ts:8-25 (Chart.js ADR
// 0020, section 6). In the published bundle, a namespace is a frozen object
// with the export names in code unit order. `Chart.register(
// ...registerables)` then registers the element classes in the order arc,
// bar, line, point (Chart.js ADR 0020, probe 2). The source order of
// elements/index.js (:1-4) is arc, line, point, bar. The scale classes
// register in the order category, linear, logarithmic, radialLinear, time,
// timeseries: the code unit order and the source order of scales/index.js
// (:1-6) are the same. The namespace `controllers` has the controllers of
// the waves of phase 7 that are ported (wave 1: `BarController`), and
// `plugins` has no entry before phase 8.
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

  test('registerables is the List of the four namespaces', () {
    expect(registerables, hasLength(4));
    expect(registerables[0], same(controllers));
    expect(registerables[1], same(elements));
    expect(registerables[2], same(plugins));
    expect(registerables[3], same(scales));
  });

  test('the namespace elements has the export names in code unit order', () {
    expect(jsObjectKeys(elements), [
      'ArcElement',
      'BarElement',
      'LineElement',
      'PointElement',
    ]);
    expect(elements['ArcElement'], same(ArcElement.jsClass));
    expect(elements['BarElement'], same(BarElement.jsClass));
    expect(elements['LineElement'], same(LineElement.jsClass));
    expect(elements['PointElement'], same(PointElement.jsClass));
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
    expect(scales['CategoryScale'], same(CategoryScale.jsClass));
    expect(scales['LinearScale'], same(LinearScale.jsClass));
    expect(scales['LogarithmicScale'], same(LogarithmicScale.jsClass));
    expect(scales['RadialLinearScale'], same(RadialLinearScale.jsClass));
    expect(scales['TimeScale'], same(TimeScale.jsClass));
    expect(scales['TimeSeriesScale'], same(TimeSeriesScale.jsClass));
  });

  test('the namespace controllers has the export names in code unit order', () {
    // The bundle keys of `Object.keys(controllers)` are BarController,
    // BubbleController, DoughnutController, LineController, PieController,
    // PolarAreaController, RadarController and ScatterController (code unit
    // order). The Map has the keys of the ported controllers in that order.
    expect(jsObjectKeys(controllers), ['BarController']);
    expect(controllers['BarController'], same(BarController.jsClass));
    expect(
      () => controllers['X'] = BarController.jsClass,
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('the namespaces of later phases are empty', () {
    expect(plugins, isEmpty);
  });

  test('a namespace is unmodifiable, as a frozen object', () {
    expect(
      () => elements['X'] = ArcElement.jsClass,
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
    // pie, polarArea, radar, scatter (the registered subset). Each one adds
    // its defaults to `defaults.datasets` and its overrides to `overrides`.
    expect(jsObjectKeys(registry.controllers.items), ['bar']);
    expect(registry.controllers.items['bar'], same(BarController.jsClass));
    expect(jsObjectKeys(defaults.get('datasets')), ['bar']);
    expect(jsObjectKeys(Chart.overrides), ['bar']);
    expect(registry.plugins.items, isEmpty);
  });

  test('Chart.register([registerables]) throws at the first namespace', () {
    // Upstream throws a TypeError: the namespaces of the bundle have a null
    // prototype, and `'id' in null` throws. Both throw before a write
    // (Chart.js ADR 0020, section 6).
    expect(
      () => Chart.register([registerables]),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'class does not have id: [object Object]',
        ),
      ),
    );
  });

  test('the library exports the names of src/core/index.ts', () {
    expect(Chart.version, '4.5.1');
    expect(registry, same(Chart.registry));
    expect(defaults, same(Chart.defaults));
    expect(animator, isNotNull);
    expect(layouts.addBox, isNotNull);
    expect(Interaction.modes, contains('nearest'));
    expect(adapters, contains('_date'));
    expect(ticks, contains('formatters'));
    expect(DatasetController.jsClass.name, 'DatasetController');
    expect(Element.jsClass.name, 'Element');
    expect(Scale.jsClass.name, 'Scale');
    expect(PluginService.new, isNotNull);
    expect(Animations.new, isNotNull);
    expect(Animation.new, isNotNull);
    expect(BasicPlatform.jsClass.name, 'BasicPlatform');
    expect(detectPlatform, isNotNull);
  });
}
