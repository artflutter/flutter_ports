// Original code, not ported from Chart.js: tests of the typed config.
@TestOn('vm')
library;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0052, sections 1 and 7: the chart type `ChartKind` names the
// 8 controllers of Chart.js, and `IndexAxis` gives the names of the
// `indexAxis` option.
//
// flutter_test_config.dart registers the built-in components before
// main() (harness-register-builtins), so the registry has the controllers.
//
// VM only: the test imports the app library, which imports dart:ui.

/// [value], as a value that is not a constant.
T _runtime<T>(T value) => value;

void main() {
  group('ChartKind', () {
    const kinds = <ChartKind>[
      .bar,
      .line,
      .scatter,
      .bubble,
      .pie,
      .doughnut,
      .polarArea,
      .radar,
    ];

    test('each constant is the id of a registered controller', () {
      for (final kind in kinds) {
        expect((registry.getController(kind.name) as JsClass)['id'], kind.name);
      }
    });

    test('the constants are the 8 controllers of Chart.js', () {
      expect(
        [for (final kind in kinds) kind.name]..sort(),
        [
          for (final controller in controllers.values)
            (controller! as JsClass)['id']! as String,
        ]..sort(),
      );
    });

    test('a custom kind has its name, and equal names are ==', () {
      expect(const ChartKind('myType').name, 'myType');
      expect(ChartKind(_runtime('bar')), ChartKind.bar);
    });
  });

  group('IndexAxis', () {
    test('the names of the indexAxis option', () {
      expect([for (final axis in IndexAxis.values) axis.name], ['x', 'y']);
    });
  });
}
