// Ported from Chart.js v4.5.1+7169e651 test/specs/core.layouts.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/core/core.layouts.dart';
import 'package:test/test.dart';

// The spec reads Chart.layouts, which src/index.umd.ts sets to the default
// export of core.layouts.js. Here it is the record `layouts` of
// lib/src/core/core.layouts.dart. The chart cases read the boxes of a chart
// with scales, a legend or a title. They skip with the blocking module of
// the classification. The helper `getLabels` (:1-3) comes with the body of
// the case of :544. test/port/core/core.layouts_test.dart covers the layout
// with fake boxes.

void main() {
  setUpSpecs();

  group('Chart.layouts', () {
    // describe('auto', jasmine.fixture.specs('core.layouts')): a fixture
    // group of phase 7, not a case.

    test('should be exposed through Chart.layouts', () {
      expect(layouts, isNotNull);
      // `typeof Chart.layouts` is 'object': the export is a record.
      expect(layouts, isA<Record>());
      expect(layouts.addBox, isNotNull);
      expect(layouts.removeBox, isNotNull);
      expect(layouts.configure, isNotNull);
      expect(layouts.update, isNotNull);
    });

    test(
      'should fit a simple chart with 2 scales',
      () {},
      skip: 'blocked: plugin.legend',
    );

    test(
      'should fit scales that are in the top and right positions',
      () {},
      skip: 'blocked: plugin.legend',
    );

    test(
      'should fit scales that overlap the chart area',
      () {},
      skip: 'blocked: plugin.legend',
    );

    test(
      'should fit multiple axes in the same position',
      () {},
      skip: 'blocked: plugin.legend',
    );

    test(
      'should fit a full width box correctly',
      () {},
      skip: 'blocked: plugin.legend',
    );

    group('padding settings', () {
      test(
        'should apply a single padding to all dimensions',
        () {},
        skip: 'blocked: controller.bar',
      );

      test(
        'should apply padding in all positions',
        () {},
        skip: 'blocked: controller.bar',
      );

      test(
        'should default to 0 padding if no dimensions specified',
        () {},
        skip: 'blocked: controller.bar',
      );
    });

    group('ordering by weight', () {
      test(
        'should keep higher weights outside',
        () {},
        skip: 'blocked: plugin.legend',
      );

      test(
        'should correctly set weights of scales and order them',
        () {},
        skip: 'blocked: controller.bar',
      );
    });

    group('box sizing', () {
      test(
        'should correctly compute y-axis width to fit labels',
        () {},
        skip: 'blocked: controller.bar',
      );
    });
  });
}
