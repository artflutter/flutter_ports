// Ported from Chart.js v4.5.1+7169e651 test/specs/plugin.filler.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:async';

import 'package:chartjs_test_utils/flutter.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/index.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;

// `Chart.Filler` (index.umd.ts:46) is the plugin Map `filler` of
// lib/src/plugins/plugin.filler/index.dart (Chart.js ADR 0038, section 1).
// `Chart.unregister` and `Chart.register` take one List.
//
// `spyOn(console, 'warn')` is a zone that records the `print` lines:
// core.datasetController.dart gives the warning of
// core.datasetController.js:288 through `print`, as
// test/port/core/core.datasetController_test.dart reads it.
//
// `meta.$filler` is the extra property `$filler` of the meta, read by name
// (Chart.js ADR 0040, section 6). Its `fill` is a `double` dataset index, a
// `String` mode, `false` or the option object.
//
// Each case builds a chart. Thus the file runs on the VM, and each case is a
// `testWidgets` case with the harness of Chart.js ADR 0022, section 2.

const String _fillerPluginRegisterWarning =
    "Tried to use the 'fill' option without the 'Filler' plugin enabled. "
    "Please import and register the 'Filler' plugin and make sure it is not "
    'disabled in the options';

/// `decodedFillValues(chart)` (:3-9): the `fill` of `meta.$filler` of each
/// dataset.
List<Object?> _decodedFillValues(Chart chart) {
  final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
  return [
    for (var index = 0; index < datasets.length; index++)
      _decodedFillValue(chart, index),
  ];
}

/// The body of the `map` callback of `decodedFillValues` for [index].
Object? _decodedFillValue(Chart chart, int index) {
  final meta = chart.getDatasetMeta(index.toDouble());
  final source = (meta as types.PropertyAccess)[r'$filler'];
  expect(source, isNot(same(undefined)));
  return (source! as FillerSource).fill;
}

/// `acquireChart(config)` in a zone that records each `print` line into
/// [warnings]: the spy of `console.warn`.
Chart _acquireWithWarnSpy(AnyObject config, List<String> warnings) => runZoned(
  () => acquireChart(config),
  zoneSpecification: ZoneSpecification(
    print: (self, parent, zone, line) => warnings.add(line),
  ),
);

/// A line chart with the [datasets] and the chart [options].
AnyObject _line(List<Object?> datasets, [AnyObject? options]) =>
    <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{'datasets': datasets},
      'options': ?options,
    };

/// A dataset with the fill option [fill].
AnyObject _fill(Object? fill) => <String, Object?>{'fill': fill};

/// A hidden dataset with the fill option [fill].
AnyObject _hiddenFill(Object? fill) => <String, Object?>{
  'fill': fill,
  'hidden': true,
};

/// The options `{plugins: {filler: {propagate: propagate}}}`.
AnyObject _propagate({required bool propagate}) => <String, Object?>{
  'plugins': <String, Object?>{
    'filler': <String, Object?>{'propagate': propagate},
  },
};

void main() {
  group('Plugin.filler', () {
    group('auto', fixture.specs('plugin.filler'));

    group('dataset.fill', () {
      testWidgets(
        'Should show a warning when trying to use the filler plugin in the '
        "dataset when it's not registered",
        (tester) async {
          final warnings = <String>[];
          Chart.unregister([filler]);
          _acquireWithWarnSpy(
            _line([
              <String, Object?>{'fill': true},
            ]),
            warnings,
          );

          expect(warnings, contains(_fillerPluginRegisterWarning));

          Chart.register([filler]);
        },
      );

      testWidgets(
        'Should show a warning when trying to use the filler plugin in the '
        "root options when it's not registered",
        (tester) async {
          // jasmine.createSpy('warn');
          final warnings = <String>[];
          Chart.unregister([filler]);
          _acquireWithWarnSpy(
            _line(
              [<String, Object?>{}],
              <String, Object?>{'fill': true},
            ),
            warnings,
          );

          expect(warnings, contains(_fillerPluginRegisterWarning));

          Chart.register([filler]);
        },
      );

      testWidgets('should support boundaries', (tester) async {
        final chart = acquireChart(
          _line([_fill('origin'), _fill('start'), _fill('end')]),
        );

        expect(_decodedFillValues(chart), ['origin', 'start', 'end']);
      });

      testWidgets('should support absolute dataset index', (tester) async {
        final chart = acquireChart(
          _line([_fill(1), _fill(3), _fill(0), _fill(2)]),
        );

        expect(_decodedFillValues(chart), [1.0, 3.0, 0.0, 2.0]);
      });

      testWidgets('should support relative dataset index', (tester) async {
        final chart = acquireChart(
          _line([_fill('+3'), _fill('-1'), _fill('+1'), _fill('-2')]),
        );

        expect(_decodedFillValues(chart), [
          3.0, // 0 + 3
          0.0, // 1 - 1
          3.0, // 2 + 1
          1.0, // 3 - 2
        ]);
      });

      testWidgets('should handle default fill when true (origin)', (
        tester,
      ) async {
        final chart = acquireChart(_line([_fill(true), _fill(false)]));

        expect(_decodedFillValues(chart), ['origin', false]);
      });

      testWidgets('should ignore self dataset index', (tester) async {
        final chart = acquireChart(
          _line([_fill(0), _fill('-0'), _fill('+0'), _fill(3)]),
        );

        expect(_decodedFillValues(chart), [
          false, // 0 === 0
          false, // 1 === 1 - 0
          false, // 2 === 2 + 0
          false, // 3 === 3
        ]);
      });

      testWidgets('should ignore out of bounds dataset index', (tester) async {
        final chart = acquireChart(
          _line([_fill(-2), _fill(4), _fill('-3'), _fill('+1')]),
        );

        expect(_decodedFillValues(chart), [
          false, // 0 - 2 < 0
          false, // 1 + 4 > 3
          false, // 2 - 3 < 0
          false, // 3 + 1 > 3
        ]);
      });

      testWidgets('should ignore invalid values', (tester) async {
        final chart = acquireChart(
          _line([
            _fill('foo'),
            _fill('+foo'),
            _fill('-foo'),
            _fill('+1.1'),
            _fill('-2.2'),
            _fill(3.3),
            _fill(-4.4),
            _fill(double.nan),
            _fill(double.infinity),
            _fill(''),
            _fill(null),
            _fill(<Object?>[]),
          ]),
        );

        expect(_decodedFillValues(chart), [
          false, // NaN (string)
          false, // NaN (string)
          false, // NaN (string)
          false, // float (string)
          false, // float (string)
          false, // float (number)
          false, // float (number)
          false, // NaN
          false, // !isFinite
          false, // empty string
          false, // null
          false, // array
        ]);
      });
    });

    group('options.plugins.filler.propagate', () {
      testWidgets('should compute propagated fill targets if true', (
        tester,
      ) async {
        final chart = acquireChart(
          _line([
            _hiddenFill('start'),
            _hiddenFill('-1'),
            _hiddenFill(1),
            _hiddenFill('-2'),
            _fill('+1'),
            _fill('+2'),
            _fill('-1'),
            _hiddenFill('end'),
          ], _propagate(propagate: true)),
        );

        expect(_decodedFillValues(chart), [
          'start', // 'start'
          'start', // 1 - 1 -> 0 (hidden) -> 'start'
          'start', // 1 (hidden) -> 0 (hidden) -> 'start'
          'start', // 3 - 2 -> 1 (hidden) -> 0 (hidden) -> 'start'
          5.0, // 4 + 1
          'end', // 5 + 2 -> 7 (hidden) -> 'end'
          5.0, // 6 - 1 -> 5
          'end', // 'end'
        ]);
      });

      testWidgets('should preserve initial fill targets if false', (
        tester,
      ) async {
        final chart = acquireChart(
          _line([
            _hiddenFill('start'),
            _hiddenFill('-1'),
            _hiddenFill(1),
            _hiddenFill('-2'),
            _fill('+1'),
            _fill('+2'),
            _fill('-1'),
            _hiddenFill('end'),
          ], _propagate(propagate: false)),
        );

        expect(_decodedFillValues(chart), [
          'start', // 'origin'
          0.0, // 1 - 1
          1.0, // 1
          1.0, // 3 - 2
          5.0, // 4 + 1
          7.0, // 5 + 2
          5.0, // 6 - 1
          'end', // 'end'
        ]);
      });

      testWidgets('should prevent recursive propagation', (tester) async {
        final chart = acquireChart(
          _line([
            _hiddenFill('+2'),
            _hiddenFill('-1'),
            _hiddenFill('-1'),
            _fill('-2'),
          ], _propagate(propagate: true)),
        );

        expect(_decodedFillValues(chart), [
          false, // 0 + 2 -> 2 (hidden) -> 1 (hidden) -> 0 (loop)
          false, // 1 - 1 -> 0 (hidden) -> 2 (hidden) -> 1 (loop)
          false, // 2 - 1 -> 1 (hidden) -> 0 (hidden) -> 2 (loop)
          false, // 3 - 2 -> 1 (hidden) -> 0 (hidden) -> 2 (hidden) -> 1 (loop)
        ]);
      });
    });
  });
}
