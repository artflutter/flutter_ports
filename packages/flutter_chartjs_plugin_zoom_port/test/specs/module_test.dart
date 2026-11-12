// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/module.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show zoomPlugin;
import 'package:flutter_chartjs_port/chartjs.dart' show Chart, Plugin;
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';

// `window.ChartZoom` is the global of the UMD bundle of the plugin
// (`src/index.umd.ts`). Dart has no global object, and the port has no UMD
// bundle (Chart.js ADR 0120, Zoom ADR 0002 item 8): the module value is
// `zoomPlugin` of the public library. flutter_test_config.dart registers it
// before `main()` (`harness-register-builtins`). The keys of the plugin
// object that the typed `Plugin` does not declare read through its face.

void main() {
  group('module', () {
    test('should be globally exported in ChartZoom', () {
      // `typeof window.ChartZoom === 'object'`: an object, not a function.
      expect(zoomPlugin, isA<Plugin>());
    });

    test('should be referenced with id "zoom"', () {
      expect(zoomPlugin.id, toBe('zoom'));
    });

    test(
      'should expose zoomFunctions, zoomRectFunctions, and panFunctions',
      () {
        // `instanceof Object`: the tables are Maps.
        expect(zoomPlugin['zoomFunctions'] is Map, toBe(true));
        expect(zoomPlugin['zoomRectFunctions'] is Map, toBe(true));
        expect(zoomPlugin['panFunctions'] is Map, toBe(true));
      },
    );

    test('should be globally registered', () {
      final plugin = Chart.registry.getPlugin('zoom');
      expect(plugin, toBe(zoomPlugin));
    });
  });
}
