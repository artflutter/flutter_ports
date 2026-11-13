// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/defaults.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart' show acquireChart;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show DrawTime, Mode;
import 'package:flutter_chartjs_port/chartjs.dart'
    show Chart, JsObjectFace, Plugin, undefined;
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart' show zoomRangeOnlyUpdates;
import '../support/jasmine.dart';

// `Chart.defaults.plugins.zoom` is the typed plugins scope of the host read
// through its face, and `toEqual` compares it by its own keys
// (`jasmineEquals`). `spyOn(plugin, 'beforeUpdate')` writes a spy through
// the face of the typed plugin (`spyOnHook`), with no call-through, and the
// hook arguments `{ cancelable: true, mode: undefined }` are the typed
// `UpdateHookArgs` of the host, compared by their own keys.

void main() {
  group('defaults', () {
    final expected = <String, Object?>{
      'pan': <String, Object?>{
        'enabled': false,
        'mode': Mode.xy,
        'threshold': 10,
        'modifierKey': null,
      },
      'zoom': <String, Object?>{
        'wheel': <String, Object?>{
          'enabled': false,
          'speed': 0.1,
          'modifierKey': null,
        },
        'drag': <String, Object?>{
          'enabled': false,
          'drawTime': DrawTime.beforeDatasetsDraw,
          'modifierKey': null,
        },
        'pinch': <String, Object?>{'enabled': false},
        'mode': Mode.xy,
      },
      // The run with the port-only option of Chart.js ADR 0111 in the
      // defaults (flutter_test_config.dart).
      if (zoomRangeOnlyUpdates) 'rangeOnlyUpdates': true,
    };

    test('should be registered as global plugin options', () {
      expect(
        (Chart.defaults['plugins']! as JsObjectFace)['zoom'],
        jasmineEquals(expected),
      );
    });

    testWidgets('should be called with default options', (tester) async {
      final plugin = Chart.registry.getPlugin('zoom');
      final spy = spyOnHook(plugin as Plugin, 'beforeUpdate');

      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{'data': <Object?>[]},
          ],
        },
      });

      expect(
        spy,
        toHaveBeenCalledWith([
          chart,
          <String, Object?>{'cancelable': true, 'mode': undefined},
          expected,
        ]),
      );
    });
  });
}
