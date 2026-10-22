// Original code, not ported from Chart.js: js_number.dart on charts.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_test/flutter_test.dart';

// The coercions of js_number.dart where a chart reads their results. The
// expected values come from Node.js v24.12.0 on x64 with the build at the
// pin and TZ=UTC (Chart.js ADR 0032).

void main() {
  group('platform-date-zone-name', () {
    // A Date label of a category scale is measured through String(label)
    // (core.scale.js `_computeLabelSizes`). V8 ends the text with the zone
    // name ' (Coordinated Universal Time)'. The width of the name rotates
    // the labels at 800 x 300. At 1600 x 300 the labels fit without a
    // rotation.
    final labels = [
      for (final ms in const [0, 86400000, 172800000])
        DateTime.fromMillisecondsSinceEpoch(ms),
    ];
    // The VM gives the V8 name only for UTC (differences.md row
    // platform-date-zone-name).
    final utcHost = labels.every(
      (date) =>
          date.timeZoneOffset == Duration.zero &&
          const {
            'UTC',
            'Coordinated Universal Time',
          }.contains(date.timeZoneName),
    );

    Map<String, Object?> config() => {
      'type': 'bar',
      'data': <String, Object?>{
        'labels': <Object?>[...labels],
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[1, 2, 3],
          },
        ],
      },
      'options': <String, Object?>{
        'plugins': <String, Object?>{
          'legend': false,
          'title': false,
          'tooltip': false,
        },
      },
    };

    testWidgets('Date labels give the upstream layout at 800 x 300', (
      tester,
    ) async {
      final chart = acquireChart(config(), <String, Object?>{
        'canvas': <String, Object?>{'width': 800, 'height': 300},
      });
      final area = chart.chartArea!;
      final x = chart.scales['x']!;
      expect(area.left, closeTo(282.60132464539663, 1e-9));
      expect(area.bottom, closeTo(229.29081368440143, 1e-9));
      expect(x.labelRotation, closeTo(6.705126459070494, 1e-9));
      expect(x.height, closeTo(70.70918631559857, 1e-9));
    }, skip: !utcHost);

    testWidgets('Date labels give the upstream layout at 1600 x 300', (
      tester,
    ) async {
      final chart = acquireChart(config(), <String, Object?>{
        'canvas': <String, Object?>{'width': 1600, 'height': 300},
      });
      final area = chart.chartArea!;
      final x = chart.scales['x']!;
      expect(area.left, closeTo(30.681640625, 1e-9));
      expect(area.bottom, closeTo(271.6, 1e-9));
      expect(x.labelRotation, 0);
      expect(x.height, closeTo(28.4, 1e-9));
    }, skip: !utcHost);
  });

  group('js-semantics-resolver-objects', () {
    testWidgets('an object angle of a polar area gives a NaN arc', (
      tester,
    ) async {
      // The angle option of the second arc resolves to a sub-resolver with
      // the context (`_attachContext`). In the reference engine, the
      // ToNumber of `toRadians(this.resolveDataElementOptions(...).angle ||
      // defaultAngle)` (controller.polarArea.js:234) reads `valueOf`
      // through `_resolveScriptable`, which calls `Object.prototype.valueOf`
      // with `this` undefined and throws `TypeError: Cannot convert
      // undefined or null to object`. In the port, `valueOf` resolves as an
      // absent key, and jsToNumber gives NaN: the arc has the endAngle NaN.
      final chart = acquireChart({
        'type': 'polarArea',
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1, 2],
              'angle': <Object?>[90, <String, Object?>{}],
            },
          ],
        },
      });
      final arcs = chart.getDatasetMeta(0).data.cast<Element>();
      expect(arcs[0]['startAngle'], closeTo(-1.5707963267948966, 1e-12));
      expect(arcs[0]['endAngle'], 0);
      expect(arcs[1]['startAngle'], 0);
      expect(arcs[1]['endAngle'], isNaN);
    });
  });
}
