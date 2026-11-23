// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/defaults.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart';

// `Chart.defaults.plugins.zoom` is one immutable `ZoomPluginOptions`
// (Chart.js ADR 0148), read through the face of the plugins scope, and
// `toEqual` compares it with `==`, field by field. The upstream
// `modifierKey: null` is a field that is not set: the expected object
// leaves it out (row `adapt-native-zoom-options`). `spyOn(plugin,
// 'beforeUpdate')` writes a closure into the hook field of the native plugin
// that records each call and continues the update, with no call-through,
// and `addTearDown` puts the old hook back. The hook arguments
// `{ cancelable: true, mode: undefined }` are the `UpdateHookArgs` of the
// host with no mode: the hook `beforeUpdate` is cancelable (Chart.js ADR
// 0144).

void main() {
  group('defaults', () {
    const upstream = ZoomPluginOptions(
      pan: PanOptions(enabled: false, mode: Mode.xy, threshold: 10),
      zoom: ZoomOptions(
        wheel: WheelOptions(enabled: false, speed: 0.1),
        drag: DragOptions(
          enabled: false,
          drawTime: DrawTime.beforeDatasetsDraw,
        ),
        pinch: PinchOptions(enabled: false),
        mode: Mode.xy,
      ),
    );
    // The run with the port-only option of Chart.js ADR 0111 in the defaults
    // (flutter_test_config.dart).
    final expected = zoomRangeOnlyUpdates
        ? upstream.merge(const ZoomPluginOptions(rangeOnlyUpdates: true))
        : upstream;

    test('should be registered as global plugin options', () {
      // By name: the scope `plugins` has no typed field for the id of an
      // add-on, and the subject is the entry under that id.
      expect((Chart.defaults['plugins']! as JsObjectFace)['zoom'], expected);
    });

    testWidgets('should be called with default options', (tester) async {
      final plugin = Chart.registry.getPlugin<ZoomPlugin>();
      final previous = plugin.beforeUpdate;
      final spyCalls =
          <(Chart chart, UpdateHookArgs args, ZoomPluginOptions options)>[];
      plugin.beforeUpdate = (chart, args, options) {
        spyCalls.add((chart, args, options));
        return true;
      };
      addTearDown(() => plugin.beforeUpdate = previous);

      final chart = acquireChartRoot(
        ChartConfigLowering(
          const ChartConfig(datasets: [LineDataset(data: .values([]))]),
        ).lower(),
      );

      final calls = spyCalls.where(
        (call) => identical(call.$1, chart) && call.$2.mode == null,
      );
      expect(calls, isNotEmpty);
      expect(PluginHook.beforeUpdate.cancelable, isTrue);
      expect(calls.first.$3, expected);
    });
  });
}
