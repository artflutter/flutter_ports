// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/defaults.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart' show acquireChart;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show
        DragOptions,
        DrawTime,
        Mode,
        PanOptions,
        PinchOptions,
        WheelOptions,
        ZoomOptions,
        ZoomPluginOptions;
import 'package:flutter_chartjs_port/chartjs.dart'
    show Chart, ChartPlugin, JsObjectFace, PluginHook, UpdateHookArgs;
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart' show zoomRangeOnlyUpdates;
import '../support/jasmine.dart';

// `Chart.defaults.plugins.zoom` is one immutable `ZoomPluginOptions`
// (Chart.js ADR 0148), read through the face of the plugins scope, and
// `toEqual` compares it with `==`, field by field. The upstream
// `modifierKey: null` is a field that is not set: the expected object
// leaves it out (row `adapt-native-zoom-options`). `spyOn(plugin,
// 'beforeUpdate')` writes a spy into the hook field of the native plugin
// (`spyOnBeforeUpdate`), with no call-through. The hook arguments
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
      expect((Chart.defaults['plugins']! as JsObjectFace)['zoom'], expected);
    });

    testWidgets('should be called with default options', (tester) async {
      final plugin = Chart.registry.getPlugin('zoom');
      final spy = spyOnBeforeUpdate(plugin as ChartPlugin<ZoomPluginOptions>);

      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{'data': <Object?>[]},
          ],
        },
      });

      final calls = spy.calls.where(
        (call) =>
            identical(call[0], chart) &&
            call[1] is UpdateHookArgs &&
            (call[1]! as UpdateHookArgs).mode == null,
      );
      expect(calls, isNotEmpty);
      expect(PluginHook.beforeUpdate.cancelable, isTrue);
      expect(calls.first[2], expected);
    });
  });
}
