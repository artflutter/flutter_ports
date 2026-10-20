// Ported from Chart.js v4.5.1 test/specs/core.interaction.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:test/test.dart';

// The spec calls the modes of Chart.Interaction, which is the Interaction of
// lib/src/core/core.interaction.dart. Each case reads the elements of a
// chart that a dataset controller updates (phase 7). Thus each case skips
// with the blocking controller of the classification. The bodies come with
// the controllers. test/port/core/core.interaction_test.dart covers the
// modes with fake charts, metas and elements.

/// core.interaction.tests.js:916 `testCases`, the data of the cases of
/// :997-1024.
const List<
  ({List<Object?> data, int clickPointIndex, int expectedNearestPointIndex})
>
_testCases = [
  (
    data: [12, 19, null, null, null, null, 5, 2],
    clickPointIndex: 0,
    expectedNearestPointIndex: 0,
  ),
  (
    data: [12, 19, null, null, null, null, 5, 2],
    clickPointIndex: 1,
    expectedNearestPointIndex: 1,
  ),
  (
    data: [12, 19, null, null, null, null, 5, 2],
    clickPointIndex: 2,
    expectedNearestPointIndex: 1,
  ),
  (
    data: [12, 19, null, null, null, null, 5, 2],
    clickPointIndex: 3,
    expectedNearestPointIndex: 1,
  ),
  (
    data: [12, 19, null, null, null, null, 5, 2],
    clickPointIndex: 4,
    expectedNearestPointIndex: 6,
  ),
  (
    data: [12, 19, null, null, null, null, 5, 2],
    clickPointIndex: 5,
    expectedNearestPointIndex: 6,
  ),
  (
    data: [12, 19, null, null, null, null, 5, 2],
    clickPointIndex: 6,
    expectedNearestPointIndex: 6,
  ),
  (
    data: [12, 19, null, null, null, null, 5, 2],
    clickPointIndex: 7,
    expectedNearestPointIndex: 7,
  ),
  (
    data: [12, 0, null, null, null, null, 0, 2],
    clickPointIndex: 3,
    expectedNearestPointIndex: 1,
  ),
  (
    data: [12, 0, null, null, null, null, 0, 2],
    clickPointIndex: 4,
    expectedNearestPointIndex: 6,
  ),
  (
    data: [12, -1, null, null, null, null, -1, 2],
    clickPointIndex: 3,
    expectedNearestPointIndex: 1,
  ),
  (
    data: [12, -1, null, null, null, null, -1, 2],
    clickPointIndex: 4,
    expectedNearestPointIndex: 6,
  ),
  (data: [null, 2], clickPointIndex: 0, expectedNearestPointIndex: 1),
  (data: [2, null], clickPointIndex: 1, expectedNearestPointIndex: 0),
  (data: [null, null, 2], clickPointIndex: 0, expectedNearestPointIndex: 2),
  (data: [2, null, null], clickPointIndex: 2, expectedNearestPointIndex: 0),
];

void main() {
  setUpSpecs();

  group('Core.Interaction', () {
    // describe('auto', jasmine.fixture.specs('core.interaction')): a fixture
    // group of phase 7, not a case.

    group('point mode', () {
      // beforeEach: acquireChart of a line chart.

      test(
        'should return all items under the point',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should return an empty array when no items are found',
        () {},
        skip: 'blocked: controller.line',
      );
    });

    group('index mode', () {
      group('intersect: true', () {
        // beforeEach: acquireChart of a line chart.

        test('gets correct items', () {}, skip: 'blocked: controller.line');

        test(
          'returns empty array when nothing found',
          () {},
          skip: 'blocked: controller.line',
        );
      });

      group('intersect: false', () {
        // beforeEach: acquireChart of a line chart. The case of :153
        // acquires a bar chart.

        test(
          'axis: x gets correct items',
          () {},
          skip: 'blocked: controller.line',
        );

        test(
          'axis: y gets correct items',
          () {},
          skip: 'blocked: controller.bar',
        );

        test(
          'axis: xy gets correct items',
          () {},
          skip: 'blocked: controller.line',
        );
      });
    });

    group('dataset mode', () {
      group('intersect: true', () {
        // beforeEach: acquireChart of a line chart.

        test(
          'should return all items in the dataset of the first item found',
          () {},
          skip: 'blocked: controller.line',
        );

        test(
          'should return an empty array if nothing found',
          () {},
          skip: 'blocked: controller.line',
        );
      });

      group('intersect: false', () {
        // beforeEach: acquireChart of a line chart and of a bar chart.

        test(
          'axis: x gets correct items',
          () {},
          skip: 'blocked: controller.bar',
        );

        test(
          'axis: y gets correct items',
          () {},
          skip: 'blocked: controller.line',
        );

        test(
          'axis: xy gets correct items',
          () {},
          skip: 'blocked: controller.line',
        );
      });
    });

    group('nearest mode', () {
      group('intersect: false', () {
        // beforeEach: acquireChart of a line chart and of a polar area chart.

        group('axis: xy', () {
          test(
            'should return the nearest item',
            () {},
            skip: 'blocked: controller.line',
          );

          test(
            'should return all items at the same nearest distance',
            () {},
            skip: 'blocked: controller.line',
          );
        });

        group('axis: x', () {
          test(
            'should return all items at current x',
            () {},
            skip: 'blocked: controller.line',
          );

          test(
            'should return all items at nearest x-distance',
            () {},
            skip: 'blocked: controller.line',
          );
        });

        group('axis: y', () {
          test(
            'should return item with value 30',
            () {},
            skip: 'blocked: controller.line',
          );

          test(
            'should return all items at value 40',
            () {},
            skip: 'blocked: controller.line',
          );
        });

        group('axis: r', () {
          test(
            'should return item with value 9',
            () {},
            skip: 'blocked: controller.polarArea',
          );

          test(
            'should return item with value 1 when clicked outside of it',
            () {},
            skip: 'blocked: controller.polarArea',
          );
        });
      });

      group('intersect: true', () {
        // beforeEach: acquireChart of a line chart.

        group('axis=xy', () {
          test(
            'should return the nearest item',
            () {},
            skip: 'blocked: controller.line',
          );

          test(
            'should return the nearest item even if 2 intersect',
            () {},
            skip: 'blocked: controller.line',
          );

          test(
            'should return the all items if more than 1 are at the same '
            'distance',
            () {},
            skip: 'blocked: controller.line',
          );
        });
      });
    });

    group('x mode', () {
      // beforeEach: acquireChart of a line chart.

      test(
        'should return items at the same x value when intersect is false',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should return items at the same x value when intersect is true',
        () {},
        skip: 'blocked: controller.line',
      );
    });

    group('y mode', () {
      // beforeEach: acquireChart of a line chart.

      test(
        'should return items at the same y value when intersect is false',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should return items at the same y value when intersect is true',
        () {},
        skip: 'blocked: controller.line',
      );
    });

    group('tooltip element of scatter chart', () {
      test(
        'out-of-range datapoints are not shown in tooltip',
        () {},
        skip: 'blocked: controller.scatter',
      );

      test(
        'out-of-range datapoints are shown in tooltip if included',
        () {},
        skip: 'blocked: controller.scatter',
      );
    });

    for (var i = 0; i < _testCases.length; i++) {
      // The `data` of the case goes to the line chart of the body (phase 7).
      final (:clickPointIndex, :expectedNearestPointIndex, data: _) =
          _testCases[i];
      test(
        'should select nearest non-null element with index '
        '$expectedNearestPointIndex when clicking on element with index '
        '$clickPointIndex in test case ${i + 1} if spanGaps=true',
        () {},
        skip: 'blocked: controller.line',
      );
    }
  });
}
