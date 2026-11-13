// Ported from Chart.js v4.6.1 test/specs/plugin.filler.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:async';

import 'package:chartjs_test_utils/flutter.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/index.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
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
// (Chart.js ADR 0040, section 6). Its `fill` is a `FillTarget` (Chart.js ADR
// 0140): `FillTarget.none` for `false`, a `DatasetFill` for a dataset index,
// a boundary or a `ValueFill` for the option object.
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
  final meta = chart.getDatasetMeta(index);
  final source = fillerSourceOf(meta);
  expect(source, isNotNull);
  return source!.fill;
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
              <String, Object?>{'fill': FillTarget.toOrigin},
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
              <String, Object?>{'fill': FillTarget.toOrigin},
            ),
            warnings,
          );

          expect(warnings, contains(_fillerPluginRegisterWarning));

          Chart.register([filler]);
        },
      );

      testWidgets('should support boundaries', (tester) async {
        // DIVERGES(chartjs): adapt-fill-target-objects, the target values.
        final chart = acquireChart(
          _line([
            _fill(FillTarget.toOrigin),
            _fill(FillTarget.toStart),
            _fill(FillTarget.toEnd),
          ]),
        );

        expect(_decodedFillValues(chart), [
          FillTarget.toOrigin,
          FillTarget.toStart,
          FillTarget.toEnd,
        ]);
      });

      testWidgets('should support absolute dataset index', (tester) async {
        final chart = acquireChart(
          _line([
            _fill(const FillTarget.toDataset(1)),
            _fill(const FillTarget.toDataset(3)),
            _fill(const FillTarget.toDataset(0)),
            _fill(const FillTarget.toDataset(2)),
          ]),
        );

        expect(_decodedFillValues(chart), [
          const FillTarget.toDataset(1),
          const FillTarget.toDataset(3),
          const FillTarget.toDataset(0),
          const FillTarget.toDataset(2),
        ]);
      });

      testWidgets('should support relative dataset index', (tester) async {
        // DIVERGES(chartjs): adapt-fill-target-objects, the target values.
        final chart = acquireChart(
          _line([
            _fill(const FillTarget.toRelative(3)),
            _fill(FillTarget.toPrevious),
            _fill(FillTarget.toNext),
            _fill(const FillTarget.toRelative(-2)),
          ]),
        );

        expect(_decodedFillValues(chart), [
          const FillTarget.toDataset(3), // 0 + 3
          const FillTarget.toDataset(0), // 1 - 1
          const FillTarget.toDataset(3), // 2 + 1
          const FillTarget.toDataset(1), // 3 - 2
        ]);
      });

      testWidgets('should handle default fill when true (origin)', (
        tester,
      ) async {
        // DIVERGES(chartjs): adapt-fill-target-objects, the target values.
        final chart = acquireChart(
          _line([_fill(FillTarget.toOrigin), _fill(FillTarget.none)]),
        );

        expect(_decodedFillValues(chart), [
          FillTarget.toOrigin,
          FillTarget.none,
        ]);
      });

      testWidgets('should ignore self dataset index', (tester) async {
        // DIVERGES(chartjs): adapt-fill-target-objects, the target values.
        final chart = acquireChart(
          _line([
            _fill(const FillTarget.toDataset(0)),
            _fill(const FillTarget.toRelative(0)),
            _fill(const FillTarget.toRelative(0)),
            _fill(const FillTarget.toDataset(3)),
          ]),
        );

        expect(_decodedFillValues(chart), [
          FillTarget.none, // 0 === 0
          FillTarget.none, // 1 === 1 - 0
          FillTarget.none, // 2 === 2 + 0
          FillTarget.none, // 3 === 3
        ]);
      });

      testWidgets('should ignore out of bounds dataset index', (tester) async {
        // DIVERGES(chartjs): adapt-fill-target-objects, the target values.
        final chart = acquireChart(
          _line([
            _fill(const FillTarget.toDataset(-2)),
            _fill(const FillTarget.toDataset(4)),
            _fill(const FillTarget.toRelative(-3)),
            _fill(FillTarget.toNext),
          ]),
        );

        expect(_decodedFillValues(chart), [
          FillTarget.none, // 0 - 2 < 0
          FillTarget.none, // 1 + 4 > 3
          FillTarget.none, // 2 - 3 < 0
          FillTarget.none, // 3 + 1 > 3
        ]);
      });

      testWidgets('should ignore invalid values', (tester) async {
        // The texts, the floats, the infinities and the array of the spec
        // are no FillTarget (Chart.js ADR 0140): a debug build stops on
        // them. The cases of NaN and `null` stay, NaN as a value fill.
        // DIVERGES(chartjs): adapt-fill-target-objects, the target values.
        final chart = acquireChart(
          _line([_fill(const FillTarget.toValue(double.nan)), _fill(null)]),
        );

        expect(_decodedFillValues(chart), [
          FillTarget.none, // NaN
          FillTarget.none, // null
        ]);
      });
    });

    group('options.plugins.filler.propagate', () {
      testWidgets('should compute propagated fill targets if true', (
        tester,
      ) async {
        // DIVERGES(chartjs): adapt-fill-target-objects, the target values.
        final chart = acquireChart(
          _line([
            _hiddenFill(FillTarget.toStart),
            _hiddenFill(FillTarget.toPrevious),
            _hiddenFill(const FillTarget.toDataset(1)),
            _hiddenFill(const FillTarget.toRelative(-2)),
            _fill(FillTarget.toNext),
            _fill(const FillTarget.toRelative(2)),
            _fill(FillTarget.toPrevious),
            _hiddenFill(FillTarget.toEnd),
          ], _propagate(propagate: true)),
        );

        expect(_decodedFillValues(chart), [
          FillTarget.toStart, // 'start'
          FillTarget.toStart, // 1 - 1 -> 0 (hidden) -> 'start'
          FillTarget.toStart, // 1 (hidden) -> 0 (hidden) -> 'start'
          FillTarget.toStart, // 3 - 2 -> 1 (hidden) -> 0 (hidden) -> 'start'
          const FillTarget.toDataset(5), // 4 + 1
          FillTarget.toEnd, // 5 + 2 -> 7 (hidden) -> 'end'
          const FillTarget.toDataset(5), // 6 - 1 -> 5
          FillTarget.toEnd, // 'end'
        ]);
      });

      testWidgets('should preserve initial fill targets if false', (
        tester,
      ) async {
        // DIVERGES(chartjs): adapt-fill-target-objects, the target values.
        final chart = acquireChart(
          _line([
            _hiddenFill(FillTarget.toStart),
            _hiddenFill(FillTarget.toPrevious),
            _hiddenFill(const FillTarget.toDataset(1)),
            _hiddenFill(const FillTarget.toRelative(-2)),
            _fill(FillTarget.toNext),
            _fill(const FillTarget.toRelative(2)),
            _fill(FillTarget.toPrevious),
            _hiddenFill(FillTarget.toEnd),
          ], _propagate(propagate: false)),
        );

        expect(_decodedFillValues(chart), [
          FillTarget.toStart, // 'origin'
          const FillTarget.toDataset(0), // 1 - 1
          const FillTarget.toDataset(1), // 1
          const FillTarget.toDataset(1), // 3 - 2
          const FillTarget.toDataset(5), // 4 + 1
          const FillTarget.toDataset(7), // 5 + 2
          const FillTarget.toDataset(5), // 6 - 1
          FillTarget.toEnd, // 'end'
        ]);
      });

      testWidgets('should prevent recursive propagation', (tester) async {
        // DIVERGES(chartjs): adapt-fill-target-objects, the target values.
        final chart = acquireChart(
          _line([
            _hiddenFill(const FillTarget.toRelative(2)),
            _hiddenFill(FillTarget.toPrevious),
            _hiddenFill(FillTarget.toPrevious),
            _fill(const FillTarget.toRelative(-2)),
          ], _propagate(propagate: true)),
        );

        expect(_decodedFillValues(chart), [
          FillTarget.none, // 0 + 2 -> 2 (hidden) -> 1 (hidden) -> 0 (loop)
          FillTarget.none, // 1 - 1 -> 0 (hidden) -> 2 (hidden) -> 1 (loop)
          FillTarget.none, // 2 - 1 -> 1 (hidden) -> 0 (hidden) -> 2 (loop)
          // 3 - 2 -> 1 (hidden) -> 0 (hidden) -> 2 (hidden) -> 1 (loop)
          FillTarget.none,
        ]);
      });
    });
  });
}
