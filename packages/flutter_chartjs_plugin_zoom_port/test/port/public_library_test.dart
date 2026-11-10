// Original code, not ported from chartjs-plugin-zoom: the public library test.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/pure.dart' show removeBuiltins;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A file of an app imports the public library of the zoom next to the app
// library of the host and `package:material_ui/material_ui.dart`, with no
// prefix and no `hide` (Chart.js ADR 0048, sections 3 and 5). Each name that
// the zoom library exports is referenced below: a name that another of the
// imports also exports is an `ambiguous_import` error of the analysis of
// this file, and the file does not compile.
//
// flutter_test_config.dart registers the built-in components and the plugin
// before main() (harness-register-builtins). Thus main() removes them first,
// as an app starts with an empty registry, and the app registers the plugin
// with the components of its chart, as the upstream docs do.

/// Each type of the zoom library.
const List<Type> _types = [
  ActivePointer,
  DragOptions,
  DrawTime,
  GenericEvent,
  GestureEvent,
  LimitOptions,
  Mode,
  ModeFn,
  ModifierKey,
  PanAmount,
  PanFunction,
  PanOptions,
  PinchOptions,
  RejectEvent,
  RejectableStartEvent,
  ScaleLimits,
  ScaleRange,
  WheelOptions,
  ZoomAmount,
  ZoomCallback,
  ZoomChartContext,
  ZoomEventContext,
  ZoomFunction,
  ZoomOptions,
  ZoomPluginOptions,
  ZoomRectFunction,
  ZoomStartContext,
  ZoomTrigger,
  ZoomTriggerContext,
];

/// Each value of the zoom library. The extension `ZoomChart` is used in the
/// second test.
final List<Object> _values = [
  chartjsPluginZoomPackageVersion,
  chartjsPluginZoomVersion,
  pan,
  panFunctions,
  resetZoom,
  zoom,
  zoomFunctions,
  zoomPlugin,
  zoomRect,
  zoomRectFunctions,
  zoomScale,
];

/// The components of a line chart on the default scales, and the plugin.
final List<Object?> _components = [
  LineController.jsClass,
  LineElement.jsClass,
  PointElement.jsClass,
  CategoryScale.jsClass,
  LinearScale.jsClass,
  zoomPlugin,
];

void main() {
  removeBuiltins();

  // The compile of this file is the check. A new export of the zoom library
  // gets a reference in a list, and the count here.
  test('the zoom library shares no name with the host and Material', () {
    expect(_types, hasLength(29));
    expect(_values, hasLength(11));
  });

  testWidgets('an app registers the plugin and zooms a ChartView', (
    tester,
  ) async {
    expect(() => registry.getPlugin('zoom'), throwsStateError);
    Chart.register(_components);
    addTearDown(() => Chart.unregister(_components));
    expect(registry.getPlugin('zoom'), same(zoomPlugin));

    final triggers = <ZoomTrigger>[];
    Chart? created;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChartView(
            config: ChartConfig(
              type: .line,
              labels: const ['a', 'b', 'c'],
              datasets: const [
                LineDataset(data: [1, 3, 2]),
              ],
              extra: {
                'animation': false,
                'plugins': <String, Object?>{
                  'zoom': <String, Object?>{
                    'zoom': <String, Object?>{
                      'mode': Mode.y,
                      'onZoom': (ZoomTriggerContext context) =>
                          triggers.add(context.trigger),
                    },
                  },
                },
              },
            ),
            onChartCreated: (chart) => created = chart,
          ),
        ),
      ),
    );
    await tester.pump();
    final chart = created!;
    final x = chart.scales['x']!;
    final y = chart.scales['y']!;
    final (xMin, xMax) = (x.min, x.max);
    expect(chart.isZoomedOrPanned(), isFalse);

    // The start hook gave the options to the state: the mode 'y' zooms only
    // the y scale, and onZoom gets the trigger.
    chart.zoom(const .all(1.5));
    expect(triggers, [ZoomTrigger.api]);
    expect(ZoomChart(chart).getZoomLevel(), 2);
    expect(chart.isZoomedOrPanned(), isTrue);
    expect((x.min, x.max), (xMin, xMax));
    expect(chart.getZoomedScaleBounds().keys, containsAll(['y']));
    expect(chart.getZoomedScaleBounds()['y'], (min: y.min, max: y.max));

    chart.resetZoom();
    expect(chart.isZoomedOrPanned(), isFalse);
    expect(chart.getZoomLevel(), 1);
  });
}
