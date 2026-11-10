// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/specs/module.spec.js (MIT, chartjs-plugin-zoom contributors).
@TestOn('vm')
library;

import 'package:flutter_chartjs_plugin_zoom_port/src/index.umd.dart';
import 'package:flutter_chartjs_port/chartjs.dart' show Chart, Plugin;
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';

// `window.ChartZoom` is the global of the UMD bundle of the plugin
// (`src/index.umd.ts`). Dart has no global object: the UMD value is
// `chartZoom` of `lib/src/index.umd.dart`, whose first read registers the
// plugin (Zoom ADR 0002 item 8). flutter_test_config.dart reads it before
// `main()` (`harness-register-builtins`). The keys of the plugin object that
// the typed `Plugin` does not declare read through its face.

void main() {
  group('module', () {
    test('should be globally exported in ChartZoom', () {
      // `typeof window.ChartZoom === 'object'`: an object, not a function.
      expect(chartZoom, isA<Plugin>());
    });

    test('should be referenced with id "zoom"', () {
      expect(chartZoom.id, toBe('zoom'));
    });

    test(
      'should expose zoomFunctions, zoomRectFunctions, and panFunctions',
      () {
        // `instanceof Object`: the tables are Maps.
        expect(chartZoom['zoomFunctions'] is Map, toBe(true));
        expect(chartZoom['zoomRectFunctions'] is Map, toBe(true));
        expect(chartZoom['panFunctions'] is Map, toBe(true));
      },
    );

    test('should be globally registered', () {
      final plugin = Chart.registry.getPlugin('zoom');
      expect(plugin, toBe(chartZoom));
    });
  });
}
