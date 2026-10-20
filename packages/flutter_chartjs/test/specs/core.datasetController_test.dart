// Ported from Chart.js v4.5.1 test/specs/core.datasetController.tests.js (MIT, Chart.js Contributors).
import 'dart:convert';

import 'package:chartjs_test_utils/pure.dart';
import 'package:test/test.dart';

// The spec tests Chart.DatasetController, the DatasetController of
// lib/src/core/core.datasetController.dart. Each case acquires a line, bar,
// scatter or radar chart with datasets. Thus each case needs a controller of
// phase 7 and the scales of phase 6. It skips with the blocking module of
// the classification. The bodies come with the controllers. The three
// `Object.isFrozen` assertions of :975, :997 and :1018 become
// `jsObjectIsFrozen` (Chart.js ADR 0021, section 7).
// test/port/core/core.datasetController_test.dart covers the controller with
// a fake chart, fake scales and a test controller.

void main() {
  setUpSpecs();

  group('Chart.DatasetController', () {
    // describe('auto', jasmine.fixture.specs('core.datasetController')): a
    // fixture group of phase 7, not a case.

    test(
      'should listen for dataset data insertions or removals',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should not try to delete non existent stacks',
      () {},
      skip: 'blocked: controller.bar',
    );

    group('inextensible data', () {
      test(
        'should handle a frozen data object',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should handle a sealed data object',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should handle an unextendable data object',
        () {},
        skip: 'blocked: controller.line',
      );
    });

    test(
      'should parse data using correct scales',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should parse using provided keys',
      () {},
      skip: 'blocked: controller.line',
    );

    group('labels array synchronization', () {
      // :255-263 `data1` and `data2`: the data of the cases. They come with
      // the bodies. :264-271 loops over the three `parsing` values.
      for (final parsing in <Object?>[
        true,
        false,
        <String, Object?>{'xAxisKey': 'name', 'yAxisKey': 'value'},
      ]) {
        group('when parsing is ${jsonEncode(parsing)}', () {
          test(
            'should remove old labels when data is updated',
            () {},
            skip: 'blocked: controller.line',
          );

          test(
            'should not remove any user added labels',
            () {},
            skip: 'blocked: controller.line',
          );

          test(
            'should not remove any user defined labels',
            () {},
            skip: 'blocked: controller.line',
          );

          test(
            'should keep up with multiple datasets',
            () {},
            skip: 'blocked: controller.line',
          );
        });
      }
    });

    test(
      'should synchronize metadata when data are inserted or removed and '
      'parsing is on',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should synchronize metadata when data are inserted or removed and '
      'parsing is off',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should synchronize insert before removal when parsing is off',
      () {},
      skip: 'blocked: controller.scatter',
    );

    test(
      'should re-synchronize metadata when the data object reference changes',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should re-synchronize metadata when the data object reference '
      'changes, with animation',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should re-synchronize metadata when data are unusually altered',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should re-synchronize metadata when data is moved and values are equal',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should re-synchronize metadata when data is objects and directly '
      'altered',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should re-synchronize metadata when scaleID changes',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should re-synchronize stacks when stack is changed',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'should re-synchronize stacks when data is removed',
      () {},
      skip: 'blocked: controller.bar',
    );

    test(
      'should cleanup attached properties when the reference changes or when '
      'the chart is destroyed',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should resolve data element options to the default color',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should read parsing from options when default is false',
      () {},
      skip: 'blocked: controller.line',
    );

    test(
      'should not fail to produce stacks when parsing is off',
      () {},
      skip: 'blocked: controller.line',
    );

    group('resolveDataElementOptions', () {
      test(
        'should cache options when possible',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should not cache options when option sharing is disabled',
        () {},
        skip: 'blocked: controller.radar',
      );

      test(
        'should not cache options when functions are used',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should support nested scriptable options',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should support nested scriptable defaults',
        () {},
        skip: 'blocked: controller.line',
      );
    });

    group('_resolveAnimations', () {
      // :1068-1078 `animationsExpectations(anims, props)`: the helper of the
      // case of :1118. It comes with the body of that case.

      test(
        'should resolve to empty Animations when globally disabled',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should resolve to empty Animations when disabled at dataset level',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should fallback properly',
        () {},
        skip: 'blocked: controller.line',
      );
    });

    group('getContext', () {
      test(
        'should reflect updated data',
        () {},
        skip: 'blocked: controller.scatter',
      );
    });
  });
}
