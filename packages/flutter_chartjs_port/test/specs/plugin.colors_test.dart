// Ported from Chart.js v4.6.1 test/specs/plugin.colors.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show JsObjectFace;
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;

// `Chart` is the class of core.controller.dart. The spec runs on the VM: a
// chart reaches the chart host and dart:ui. Each chart case is a
// `testWidgets` case with the harness of Chart.js ADR 0022, section 2.
//
// The spec forms:
// - `Chart.defaults` is `defaults` of core.defaults.dart. A write is
//   `operator []=`.
// - The Jasmine `beforeAll` and `afterAll` of the group
//   `Plugin.colors.chartDefaults` are local functions. The one test calls
//   `beforeAll()` first and gives `afterAll` to `addTearDown`. The defaults
//   restore of flutter_test_config.dart also restores `backgroundColor`
//   after each test (row harness-defaults-restore).
// - `meta.data[i].options.backgroundColor` reads the options of the
//   element. `toBe` of a string is `expect` with the string.

/// `element.options` of [element].
JsObjectFace? _options(Object element) =>
    (element as Element).options as JsObjectFace?;

void main() {
  group('Plugin.colors', () {
    group('auto', fixture.specs('plugin.colors'));

    group('Plugin.colors.chartDefaults', () {
      void beforeAll() {
        defaults['backgroundColor'] = <Object?>['green', 'yellow'];
      }

      void afterAll() {
        defaults['backgroundColor'] = 'rgba(0,0,0,0.1)';
      }

      testWidgets('should not use colors plugin when chart defaults are '
          'given', (tester) async {
        beforeAll();
        addTearDown(afterAll);
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 10],
                'label': 'dataset1',
              },
            ],
            'labels': <Object?>['label1', 'label2'],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'colors': <String, Object?>{'enabled': true},
            },
          },
        });

        final meta = chart.getDatasetMeta(0);
        expect(_options(meta.data[0])!['backgroundColor'], 'green');
        expect(_options(meta.data[1])!['backgroundColor'], 'yellow');
      });
    });
  });
}
