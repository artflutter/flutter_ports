// Ported from Chart.js v4.5.1+7169e651 test/specs/controller.bar.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs, which does not export lib/src
// yet.
import 'package:flutter_chartjs/src/controllers/controller.bar.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/elements/element.bar.dart';
import 'package:flutter_chartjs/src/helpers/helpers.color.dart' as helpers;
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/jasmine.dart';

// `Chart` is the class of core.controller.dart. The spec runs on the VM: a
// chart reaches the chart host and dart:ui. Each chart case is a
// `testWidgets` case with the harness of Chart.js ADR 0022, section 2. The
// conventions are those of Chart.js ADR 0030, section 13.
//
// flutter_test_config.dart registers the bar controller with the built-in
// components before main(), as index.umd.ts:28 does (Chart.js ADR 0030,
// section 3 item 4).
//
// The spec forms:
// - `Chart.controllers` is `registry.controllers.items` (index.umd.ts:35):
//   `Chart.registry.controllers.items`.
// - `Chart.elements.BarElement` is the class BarElement of element.bar.dart.
//   `instanceof` is `isA`.
// - `Chart.defaults` is the static `Chart.defaults`. A property chain of the
//   spec, for example `Chart.defaults.datasets.bar`, is a chain of `jsGet`.
//   A write into a chain, for example `chart.options.elements.bar.x = v`,
//   writes into the Map of the last `jsGet`.
// - `chart.data.datasets[i]` is `_dataset(chart, i)`. `meta.data[i]` is a
//   `BarElement` (`_bar`). `meta._parsed` is `meta.parsed`.
// - `meta.controller._getStackCount` and `_getStackIndex` are
//   `getStackCount` and `getStackIndex` of BarController (Chart.js ADR 0012,
//   underscore members).
// - Jasmine `this.data`, `this.config` and `this.chart` are `late` variables
//   of the group closure. A `beforeEach` that acquires a chart is a local
//   function `beforeEach()`, and each test calls it first. An `afterEach`
//   that acquires a chart is a local function `afterEach()`, and each test
//   calls it last. A `beforeEach` without a chart is a `setUp`.
// - `spyOn(meta.data[i], 'draw')` is `spyOnElementDraw(meta, i)` of
//   test/support/jasmine.dart.
// - `toEqual` of an object is `jasmineEquals`. `jasmine.objectContaining` is
//   `objectContaining`.
// - `removeHoverStyle(bar)` has no index upstream. The port gives NaN for
//   the two absent numbers: `getStyle` reads `index || 0` and
//   `_resolveAnimations` gives the dataset context for an index that is not
//   `>= 0`, the same results as for `undefined`.
// - `ctx.resetTransform = function() {}` is a subclass of MockContext with a
//   `resetTransform` that does nothing.
//
// Three cases need the line controller of wave 2 (:70, :310, :671). The
// lift of wave 2 gave them their bodies (test-strategy spec, section 4.2).
// One case needs the tooltip plugin of phase 8 (:1808).

/// `chart.data.datasets[index]`.
AnyObject _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as AnyObject;

/// `meta.data[index]` of [meta], a bar.
BarElement _bar(ChartMeta meta, int index) => meta.data[index] as BarElement;

/// `element.options` of [element].
AnyObject? _options(Object element) => (element as Element).options;

/// The mock context of :1677-1678: `ctx.resetTransform = function() {}`.
final class _ResetTransformContext extends MockContext {
  @override
  void resetTransform() {}
}

void main() {
  group('Chart.controllers.bar', () {
    // describe('auto', jasmine.fixture.specs('controller.bar')): a fixture
    // group of phase 7 (Chart.js ADR 0029), not a case.

    test('should be registered as dataset controller', () {
      expect(jsTypeof(Chart.registry.controllers.items['bar']), 'function');
    });

    testWidgets('should be constructed', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{'data': <Object?>[]},
            <String, Object?>{'data': <Object?>[]},
          ],
          'labels': <Object?>[],
        },
      });

      final meta = chart.getDatasetMeta(1);
      expect(meta.type, 'bar');
      expect(meta.data, jasmineEquals(<Object?>[]));
      expect(meta.hidden, isNull);
      expect(meta.controller, isNot(same(undefined)));
      expect(meta.controller, isNotNull);
      expect(meta.controller!.index, 1);
      expect(meta.xAxisID, isNotNull);
      expect(meta.yAxisID, isNotNull);

      meta.controller!.updateIndex(0);
      expect(meta.controller!.index, 0);
    });

    testWidgets('should set null bars to the reset state', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, null, 0, -4],
              'label': 'dataset1',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
      });

      final meta = chart.getDatasetMeta(0);
      final bar = _bar(meta, 1);
      final props = bar.getProps(const ['x', 'y', 'base'], true);
      expect(jsIsNaN(props['x']), false);
      expect(jsIsNaN(props['y']), false);
      expect(jsIsNaN(props['base']), false);
    });

    testWidgets(
      'should use the first scale IDs if the dataset does not specify them',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
        });

        final meta = chart.getDatasetMeta(1);
        expect(meta.xAxisID, 'x');
        expect(meta.yAxisID, 'y');
      },
    );

    // :70
    testWidgets(
      'should correctly count the number of stacks ignoring datasets of '
      'other types and hidden datasets',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[], 'type': 'line'},
              <String, Object?>{'data': <Object?>[], 'hidden': true},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
        });

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackCount(), 2);
      },
    );

    // :88
    testWidgets(
      'should correctly count the number of stacks when a group is not '
      'specified',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
        });

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackCount(), 4);
      },
    );

    // :106
    testWidgets(
      'should correctly count the number of stacks when a group is not '
      'specified and the scale is stacked',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'stacked': true},
              'y': <String, Object?>{'stacked': true},
            },
          },
        });

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackCount(), 1);
      },
    );

    // :134
    testWidgets(
      'should correctly count the number of stacks when a group is not '
      'specified and the scale is not stacked',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'stacked': false},
              'y': <String, Object?>{'stacked': false},
            },
          },
        });

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackCount(), 4);
      },
    );

    // :162
    testWidgets(
      'should correctly count the number of stacks when a group is '
      'specified for some',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
        });

        final meta = chart.getDatasetMeta(3);
        final controller = meta.controller! as BarController;
        expect(controller.getStackCount(), 3);
      },
    );

    // :180
    testWidgets(
      'should correctly count the number of stacks when a group is '
      'specified for some and the scale is stacked',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'stacked': true},
              'y': <String, Object?>{'stacked': true},
            },
          },
        });

        final meta = chart.getDatasetMeta(3);
        final controller = meta.controller! as BarController;
        expect(controller.getStackCount(), 2);
      },
    );

    // :208
    testWidgets(
      'should correctly count the number of stacks when a group is '
      'specified for some and the scale is not stacked',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'stacked': false},
              'y': <String, Object?>{'stacked': false},
            },
          },
        });

        final meta = chart.getDatasetMeta(3);
        final controller = meta.controller! as BarController;
        expect(controller.getStackCount(), 4);
      },
    );

    // :236
    testWidgets(
      'should correctly count the number of stacks when a group is '
      'specified for all',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack2'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack2'},
            ],
            'labels': <Object?>[],
          },
        });

        final meta = chart.getDatasetMeta(3);
        final controller = meta.controller! as BarController;
        expect(controller.getStackCount(), 2);
      },
    );

    // :254
    testWidgets(
      'should correctly count the number of stacks when a group is '
      'specified for all and the scale is stacked',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack2'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack2'},
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'stacked': true},
              'y': <String, Object?>{'stacked': true},
            },
          },
        });

        final meta = chart.getDatasetMeta(3);
        final controller = meta.controller! as BarController;
        expect(controller.getStackCount(), 2);
      },
    );

    // :282
    testWidgets(
      'should correctly count the number of stacks when a group is '
      'specified for all and the scale is not stacked',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack2'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack2'},
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'stacked': false},
              'y': <String, Object?>{'stacked': false},
            },
          },
        });

        final meta = chart.getDatasetMeta(3);
        final controller = meta.controller! as BarController;
        expect(controller.getStackCount(), 4);
      },
    );

    // :310
    testWidgets(
      'should correctly get the stack index accounting for datasets of '
      'other types and hidden datasets',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[], 'hidden': true},
              <String, Object?>{'data': <Object?>[], 'type': 'line'},
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
        });

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(3), 1);
      },
    );

    // :329
    testWidgets(
      'should correctly get the stack index when a group is not '
      'specified',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
        });

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(1), 1);
        expect(controller.getStackIndex(2), 2);
        expect(controller.getStackIndex(3), 3);
      },
    );

    // :350
    testWidgets(
      'should correctly get the stack index when a group is not '
      'specified and the scale is stacked',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'stacked': true},
              'y': <String, Object?>{'stacked': true},
            },
          },
        });

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(1), 0);
        expect(controller.getStackIndex(2), 0);
        expect(controller.getStackIndex(3), 0);
      },
    );

    // :381
    testWidgets(
      'should correctly get the stack index when a group is not '
      'specified and the scale is not stacked',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'stacked': false},
              'y': <String, Object?>{'stacked': false},
            },
          },
        });

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(1), 1);
        expect(controller.getStackIndex(2), 2);
        expect(controller.getStackIndex(3), 3);
      },
    );

    // :412
    testWidgets(
      'should correctly get the stack index when a group is specified '
      'for some',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
        });

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(1), 0);
        expect(controller.getStackIndex(2), 1);
        expect(controller.getStackIndex(3), 2);
      },
    );

    // :433
    testWidgets(
      'should correctly get the stack index when a group is specified '
      'for some and the scale is stacked',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'stacked': true},
              'y': <String, Object?>{'stacked': true},
            },
          },
        });

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(1), 0);
        expect(controller.getStackIndex(2), 1);
        expect(controller.getStackIndex(3), 1);
      },
    );

    // :464
    testWidgets(
      'should correctly get the stack index when a group is specified '
      'for some and the scale is not stacked',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'stacked': false},
              'y': <String, Object?>{'stacked': false},
            },
          },
        });

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(1), 1);
        expect(controller.getStackIndex(2), 2);
        expect(controller.getStackIndex(3), 3);
      },
    );

    // :495
    testWidgets(
      'should correctly get the stack index when a group is specified '
      'for all',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack2'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack2'},
            ],
            'labels': <Object?>[],
          },
        });

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(1), 0);
        expect(controller.getStackIndex(2), 1);
        expect(controller.getStackIndex(3), 1);
      },
    );

    // :516
    testWidgets(
      'should correctly get the stack index when a group is specified '
      'for all and the scale is stacked',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack2'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack2'},
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'stacked': true},
              'y': <String, Object?>{'stacked': true},
            },
          },
        });

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(1), 0);
        expect(controller.getStackIndex(2), 1);
        expect(controller.getStackIndex(3), 1);
      },
    );

    // :547
    testWidgets(
      'should correctly get the stack index when a group is specified '
      'for all and the scale is not stacked',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack1'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack2'},
              <String, Object?>{'data': <Object?>[], 'stack': 'stack2'},
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'stacked': false},
              'y': <String, Object?>{'stacked': false},
            },
          },
        });

        final meta = chart.getDatasetMeta(1);
        final controller = meta.controller! as BarController;
        expect(controller.getStackIndex(0), 0);
        expect(controller.getStackIndex(1), 1);
        expect(controller.getStackIndex(2), 2);
        expect(controller.getStackIndex(3), 3);
      },
    );

    testWidgets(
      'should create bar elements for each data item during initialization',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': <Object?>[]},
              <String, Object?>{
                'data': <Object?>[10, 15, 0, -4],
              },
            ],
            'labels': <Object?>[],
          },
        });

        final meta = chart.getDatasetMeta(1);
        expect(meta.data.length, 4); // 4 bars created
        expect(meta.data[0], isA<BarElement>());
        expect(meta.data[1], isA<BarElement>());
        expect(meta.data[2], isA<BarElement>());
        expect(meta.data[3], isA<BarElement>());
      },
    );

    testWidgets('should update elements when modifying data', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1, 2],
              'label': 'dataset1',
            },
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -4],
              'label': 'dataset2',
              'borderColor': 'blue',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'elements': <String, Object?>{
            'bar': <String, Object?>{
              'backgroundColor': 'red',
              'borderSkipped': 'top',
              'borderColor': 'green',
              'borderWidth': 2,
            },
          },
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'category', 'display': false},
            'y': <String, Object?>{
              'type': 'linear',
              'display': false,
              'beginAtZero': false,
            },
          },
        },
      });

      final meta = chart.getDatasetMeta(1);
      expect(meta.data.length, 4);

      _dataset(chart, 1)['data'] = <Object?>[1, 2]; // remove 2 items
      _dataset(chart, 1)['borderWidth'] = 1;
      chart.update();

      expect(meta.data.length, 2);
      expect(meta.parsed.length, 2);

      final expectedValues = [
        (x: 89, y: 512),
        (x: 217, y: 0),
      ];
      for (var i = 0; i < expectedValues.length; i++) {
        final expected = expectedValues[i];
        expect(_bar(meta, i).x, toBeCloseToPixel(expected.x));
        expect(_bar(meta, i).y, toBeCloseToPixel(expected.y));
        expect(_bar(meta, i).base, toBeCloseToPixel(1024));
        expect(_bar(meta, i).width, toBeCloseToPixel(46));
        expect(
          _options(meta.data[i]),
          objectContaining(<String, Object?>{
            'backgroundColor': 'red',
            'borderSkipped': 'top',
            'borderColor': 'blue',
            'borderWidth': 1,
          }),
        );
      }

      _dataset(chart, 1)['data'] = <Object?>[1, 2, 3]; // add 1 items
      chart.update();

      expect(meta.data.length, 3); // should add a new meta data item
    });

    // :671
    testWidgets(
      'should get the correct bar points when datasets of different types '
      'exist',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 2],
                'label': 'dataset1',
              },
              <String, Object?>{
                'type': 'line',
                'data': <Object?>[4, 6],
                'label': 'dataset2',
              },
              <String, Object?>{
                'data': <Object?>[8, 10],
                'label': 'dataset3',
              },
            ],
            'labels': <Object?>['label1', 'label2'],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{'legend': false, 'title': false},
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'category', 'display': false},
              'y': <String, Object?>{
                'type': 'linear',
                'display': false,
                'beginAtZero': false,
              },
            },
          },
        });

        final meta = chart.getDatasetMeta(2);
        expect(meta.data.length, 2);

        final bar1 = _bar(meta, 0);
        final bar2 = _bar(meta, 1);

        expect(bar1.x, toBeCloseToPixel(179));
        expect(bar1.y, toBeCloseToPixel(117));
        expect(bar2.x, toBeCloseToPixel(431));
        expect(bar2.y, toBeCloseToPixel(4));
      },
    );

    testWidgets('should get the bar points for hidden dataset', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1, 2],
              'label': 'dataset1',
              'hidden': true,
            },
          ],
          'labels': <Object?>['label1', 'label2'],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'category', 'display': false},
            'y': <String, Object?>{
              'type': 'linear',
              'min': 0,
              'max': 2,
              'display': false,
            },
          },
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(meta.data.length, 2);

      final bar1 = _bar(meta, 0);
      final bar2 = _bar(meta, 1);

      expect(bar1.x, toBeCloseToPixel(128));
      expect(bar1.y, toBeCloseToPixel(256));
      expect(bar2.x, toBeCloseToPixel(384));
      expect(bar2.y, toBeCloseToPixel(0));
    });

    testWidgets('should update elements when the scales are stacked', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, -10, 10, -10],
              'label': 'dataset1',
            },
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -4],
              'label': 'dataset2',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'category', 'display': false},
            'y': <String, Object?>{
              'type': 'linear',
              'display': false,
              'stacked': true,
            },
          },
        },
      });

      final meta0 = chart.getDatasetMeta(0);

      _expectBars(meta0, const [
        (b: 293, w: 92 / 2, x: 38, y: 146),
        (b: 293, w: 92 / 2, x: 166, y: 439),
        (b: 293, w: 92 / 2, x: 295, y: 146),
        (b: 293, w: 92 / 2, x: 422, y: 439),
      ]);

      final meta1 = chart.getDatasetMeta(1);

      _expectBars(meta1, const [
        (b: 146, w: 92 / 2, x: 89, y: 0),
        (b: 293, w: 92 / 2, x: 217, y: 73),
        (b: 146, w: 92 / 2, x: 345, y: 146),
        (b: 439, w: 92 / 2, x: 473, y: 497),
      ]);
    });

    testWidgets(
      'should update elements when the scales are stacked and the y axis has '
      'a user defined minimum',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[50, 20, 10, 100],
                'label': 'dataset1',
              },
              <String, Object?>{
                'data': <Object?>[50, 80, 90, 0],
                'label': 'dataset2',
              },
            ],
            'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{'legend': false, 'title': false},
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'category', 'display': false},
              'y': <String, Object?>{
                'type': 'linear',
                'display': false,
                'stacked': true,
                'min': 50,
                'max': 100,
              },
            },
          },
        });

        final meta0 = chart.getDatasetMeta(0);

        _expectBars(meta0, const [
          (b: 1024, w: 92 / 2, x: 38, y: 512),
          (b: 1024, w: 92 / 2, x: 166, y: 819),
          (b: 1024, w: 92 / 2, x: 294, y: 922),
          (b: 1024, w: 92 / 2, x: 422.5, y: 0),
        ]);

        final meta1 = chart.getDatasetMeta(1);

        _expectBars(meta1, const [
          (b: 512, w: 92 / 2, x: 89, y: 0),
          (b: 819.2, w: 92 / 2, x: 217, y: 0),
          (b: 921.6, w: 92 / 2, x: 345, y: 0),
          (b: 0, w: 92 / 2, x: 473.5, y: 0),
        ]);
      },
    );

    testWidgets('should update elements when only the category scale is '
        'stacked', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[20, -10, 10, -10],
              'label': 'dataset1',
            },
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -14],
              'label': 'dataset2',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'type': 'category',
              'display': false,
              'stacked': true,
            },
            'y': <String, Object?>{'type': 'linear', 'display': false},
          },
        },
      });

      final meta0 = chart.getDatasetMeta(0);

      _expectBars(meta0, const [
        (b: 293, w: 92, x: 64, y: 0),
        (b: 293, w: 92, x: 192, y: 439),
        (b: 293, w: 92, x: 320, y: 146),
        (b: 293, w: 92, x: 448, y: 439),
      ]);

      final meta1 = chart.getDatasetMeta(1);

      _expectBars(meta1, const [
        (b: 293, w: 92, x: 64, y: 146),
        (b: 293, w: 92, x: 192, y: 73),
        (b: 293, w: 92, x: 320, y: 293),
        (b: 293, w: 92, x: 448, y: 497),
      ]);
    });

    testWidgets('should update elements when the scales are stacked and data '
        'is strings', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>['10', '-10', '10', '-10'],
              'label': 'dataset1',
            },
            <String, Object?>{
              'data': <Object?>['10', '15', '0', '-4'],
              'label': 'dataset2',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'category', 'display': false},
            'y': <String, Object?>{
              'type': 'linear',
              'display': false,
              'stacked': true,
            },
          },
        },
      });

      final meta0 = chart.getDatasetMeta(0);

      _expectBars(meta0, const [
        (b: 293, w: 92 / 2, x: 38, y: 146),
        (b: 293, w: 92 / 2, x: 166, y: 439),
        (b: 293, w: 92 / 2, x: 295, y: 146),
        (b: 293, w: 92 / 2, x: 422, y: 439),
      ]);

      final meta1 = chart.getDatasetMeta(1);

      _expectBars(meta1, const [
        (b: 146, w: 92 / 2, x: 89, y: 0),
        (b: 293, w: 92 / 2, x: 217, y: 73),
        (b: 146, w: 92 / 2, x: 345, y: 146),
        (b: 439, w: 92 / 2, x: 473, y: 497),
      ]);
    });

    testWidgets(
      'should get the correct bar points for grouped stacked chart if the '
      'group name is same',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, -10, 10, -10],
                'label': 'dataset1',
                'stack': 'stack1',
              },
              <String, Object?>{
                'data': <Object?>[10, 15, 0, -4],
                'label': 'dataset2',
                'stack': 'stack1',
              },
            ],
            'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{'legend': false, 'title': false},
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'category', 'display': false},
              'y': <String, Object?>{
                'type': 'linear',
                'display': false,
                'stacked': true,
              },
            },
          },
        });

        final meta0 = chart.getDatasetMeta(0);

        _expectBars(meta0, const [
          (b: 293, w: 92, x: 64, y: 146),
          (b: 293, w: 92, x: 192, y: 439),
          (b: 293, w: 92, x: 320, y: 146),
          (b: 293, w: 92, x: 448, y: 439),
        ]);

        final meta = chart.getDatasetMeta(1);

        _expectBars(meta, const [
          (b: 146, w: 92, x: 64, y: 0),
          (b: 293, w: 92, x: 192, y: 73),
          (b: 146, w: 92, x: 320, y: 146),
          (b: 439, w: 92, x: 448, y: 497),
        ]);
      },
    );

    testWidgets(
      'should get the correct bar points for grouped stacked chart if the '
      'group name is different',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 2],
                'stack': 'stack1',
              },
              <String, Object?>{
                'data': <Object?>[1, 2],
                'stack': 'stack2',
              },
            ],
            'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{'legend': false, 'title': false},
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'category', 'display': false},
              'y': <String, Object?>{
                'type': 'linear',
                'display': false,
                'stacked': true,
              },
            },
          },
        });

        final meta = chart.getDatasetMeta(1);

        final values = [
          (x: 89, y: 256),
          (x: 217, y: 0),
        ];
        for (var i = 0; i < values.length; i++) {
          expect(_bar(meta, i).base, toBeCloseToPixel(512));
          expect(_bar(meta, i).width, toBeCloseToPixel(46));
          expect(_bar(meta, i).x, toBeCloseToPixel(values[i].x));
          expect(_bar(meta, i).y, toBeCloseToPixel(values[i].y));
        }
      },
    );

    testWidgets('should get the correct bar points for grouped stacked chart', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1, 2],
              'stack': 'stack1',
            },
            <String, Object?>{
              'data': <Object?>[0.5, 1],
              'stack': 'stack2',
            },
            <String, Object?>{
              'data': <Object?>[0.5, 1],
              'stack': 'stack2',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'category', 'display': false},
            'y': <String, Object?>{
              'type': 'linear',
              'display': false,
              'stacked': true,
            },
          },
        },
      });

      final meta = chart.getDatasetMeta(2);

      final values = [
        (b: 384, x: 89, y: 256),
        (b: 256, x: 217, y: 0),
      ];
      for (var i = 0; i < values.length; i++) {
        expect(_bar(meta, i).base, toBeCloseToPixel(values[i].b));
        expect(_bar(meta, i).width, toBeCloseToPixel(46));
        expect(_bar(meta, i).x, toBeCloseToPixel(values[i].x));
        expect(_bar(meta, i).y, toBeCloseToPixel(values[i].y));
      }
    });

    testWidgets('should draw all bars', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{'data': <Object?>[]},
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -4],
              'label': 'dataset2',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
      });

      final meta = chart.getDatasetMeta(1);

      final draw0 = spyOnElementDraw(meta, 0);
      final draw1 = spyOnElementDraw(meta, 1);
      final draw2 = spyOnElementDraw(meta, 2);
      final draw3 = spyOnElementDraw(meta, 3);

      chart.update();

      expect(draw0.count(), 1);
      expect(draw1.count(), 1);
      expect(draw2.count(), 1);
      expect(draw3.count(), 1);
    });

    testWidgets('should set hover styles on bars', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{'data': <Object?>[]},
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -4],
              'label': 'dataset2',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
        'options': <String, Object?>{
          'elements': <String, Object?>{
            'bar': <String, Object?>{
              'backgroundColor': 'rgb(255, 0, 0)',
              'borderColor': 'rgb(0, 0, 255)',
              'borderWidth': 2,
            },
          },
        },
      });

      final meta = chart.getDatasetMeta(1);
      final bar = _bar(meta, 0);

      meta.controller!.setHoverStyle(bar, 1, 0);
      expect(jsGet(bar.options, 'backgroundColor'), '#E60000');
      expect(jsGet(bar.options, 'borderColor'), '#0000E6');
      expect(jsGet(bar.options, 'borderWidth'), 2);

      // Set a dataset style
      _dataset(chart, 1)['hoverBackgroundColor'] = 'rgb(128, 128, 128)';
      _dataset(chart, 1)['hoverBorderColor'] = 'rgb(0, 0, 0)';
      _dataset(chart, 1)['hoverBorderWidth'] = 5;
      chart.update();

      meta.controller!.setHoverStyle(bar, 1, 0);
      expect(jsGet(bar.options, 'backgroundColor'), 'rgb(128, 128, 128)');
      expect(jsGet(bar.options, 'borderColor'), 'rgb(0, 0, 0)');
      expect(jsGet(bar.options, 'borderWidth'), 5);

      // Should work with array styles so that we can set per bar
      _dataset(chart, 1)['hoverBackgroundColor'] = <Object?>[
        'rgb(255, 255, 255)',
        'rgb(128, 128, 128)',
      ];
      _dataset(chart, 1)['hoverBorderColor'] = <Object?>[
        'rgb(9, 9, 9)',
        'rgb(0, 0, 0)',
      ];
      _dataset(chart, 1)['hoverBorderWidth'] = <Object?>[2.5, 5];
      chart.update();

      meta.controller!.setHoverStyle(bar, 1, 0);
      expect(jsGet(bar.options, 'backgroundColor'), 'rgb(255, 255, 255)');
      expect(jsGet(bar.options, 'borderColor'), 'rgb(9, 9, 9)');
      expect(jsGet(bar.options, 'borderWidth'), 2.5);
    });

    testWidgets('should remove a hover style from a bar', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{'data': <Object?>[]},
            <String, Object?>{
              'data': <Object?>[10, 15, 0, -4],
              'label': 'dataset2',
            },
          ],
          'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
        },
        'options': <String, Object?>{
          'elements': <String, Object?>{
            'bar': <String, Object?>{
              'backgroundColor': 'rgb(255, 0, 0)',
              'borderColor': 'rgb(0, 0, 255)',
              'borderWidth': 2,
            },
          },
        },
      });

      final meta = chart.getDatasetMeta(1);
      final bar = _bar(meta, 0);

      // Change default
      final barOptions =
          jsGet(jsGet(chart.options, 'elements'), 'bar')! as AnyObject;
      barOptions['backgroundColor'] = 'rgb(128, 128, 128)';
      barOptions['borderColor'] = 'rgb(15, 15, 15)';
      barOptions['borderWidth'] = 3.14;

      chart.update();
      expect(jsGet(bar.options, 'backgroundColor'), 'rgb(128, 128, 128)');
      expect(jsGet(bar.options, 'borderColor'), 'rgb(15, 15, 15)');
      expect(jsGet(bar.options, 'borderWidth'), 3.14);
      meta.controller!.setHoverStyle(bar, 1, 0);
      expect(
        jsGet(bar.options, 'backgroundColor'),
        helpers.getHoverColor('rgb(128, 128, 128)'),
      );
      expect(
        jsGet(bar.options, 'borderColor'),
        helpers.getHoverColor('rgb(15, 15, 15)'),
      );
      expect(jsGet(bar.options, 'borderWidth'), 3.14);
      meta.controller!.removeHoverStyle(bar, double.nan, double.nan);
      expect(jsGet(bar.options, 'backgroundColor'), 'rgb(128, 128, 128)');
      expect(jsGet(bar.options, 'borderColor'), 'rgb(15, 15, 15)');
      expect(jsGet(bar.options, 'borderWidth'), 3.14);

      // Should work with array styles so that we can set per bar
      _dataset(chart, 1)['backgroundColor'] = <Object?>[
        'rgb(255, 255, 255)',
        'rgb(128, 128, 128)',
      ];
      _dataset(chart, 1)['borderColor'] = <Object?>[
        'rgb(9, 9, 9)',
        'rgb(0, 0, 0)',
      ];
      _dataset(chart, 1)['borderWidth'] = <Object?>[2.5, 5];

      chart.update();
      expect(jsGet(bar.options, 'backgroundColor'), 'rgb(255, 255, 255)');
      expect(jsGet(bar.options, 'borderColor'), 'rgb(9, 9, 9)');
      expect(jsGet(bar.options, 'borderWidth'), 2.5);
      meta.controller!.setHoverStyle(bar, 1, 0);
      expect(
        jsGet(bar.options, 'backgroundColor'),
        helpers.getHoverColor('rgb(255, 255, 255)'),
      );
      expect(
        jsGet(bar.options, 'borderColor'),
        helpers.getHoverColor('rgb(9, 9, 9)'),
      );
      expect(jsGet(bar.options, 'borderWidth'), 2.5);
      meta.controller!.removeHoverStyle(bar, double.nan, double.nan);
      expect(jsGet(bar.options, 'backgroundColor'), 'rgb(255, 255, 255)');
      expect(jsGet(bar.options, 'borderColor'), 'rgb(9, 9, 9)');
      expect(jsGet(bar.options, 'borderWidth'), 2.5);
    });

    group('Bar width', () {
      late AnyObject data;
      late AnyObject config;

      setUp(() {
        // 2 datasets
        data = <String, Object?>{
          'labels': <Object?>[
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
          ],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 20, 30, 40, 50, 60, 70],
            },
            <String, Object?>{
              'data': <Object?>[10, 20, 30, 40, 50, 60, 70],
            },
          ],
        };
      });

      // :1325 the afterEach acquires a chart: each test calls it last.
      void afterEach() {
        final chart = acquireChart(config);
        final meta = chart.getDatasetMeta(0);
        final xScale = chart.scales[meta.xAxisID]!;
        final options = jsGet(jsGet(Chart.defaults, 'datasets'), 'bar');

        final categoryPercentage = jsGet(options, 'categoryPercentage');
        final barPercentage = jsGet(options, 'barPercentage');
        final stacked = jsGet(xScale.options, 'stacked');

        var totalBarWidth = 0.0;
        final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
        for (var i = 0; i < datasets.length; i++) {
          final bars = chart.getDatasetMeta(i.toDouble()).data;
          for (var j = xScale.min; j <= xScale.max; j++) {
            totalBarWidth += (bars[j.toInt()] as BarElement).width;
          }
          if (jsTruthy(stacked)) {
            break;
          }
        }

        final actualValue = totalBarWidth;
        final expectedValue =
            xScale.width *
            jsToNumber(categoryPercentage) *
            jsToNumber(barPercentage);
        expect(actualValue, toBeCloseToPixel(expectedValue));
      }

      testWidgets('should correctly set bar width when min and max option is '
          'set.', (tester) async {
        config = <String, Object?>{
          'type': 'bar',
          'data': data,
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'min': 'March', 'max': 'May'},
            },
          },
        };
        afterEach();
      });

      testWidgets('should correctly set bar width when scale are stacked with '
          'min and max options.', (tester) async {
        config = <String, Object?>{
          'type': 'bar',
          'data': data,
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'min': 'March', 'max': 'May'},
              'y': <String, Object?>{'stacked': true},
            },
          },
        };
        afterEach();
      });
    });

    // The two cases of this group belong to decision D1 of the phase lead:
    // the default legend changes the asserted heights, but the assertion is
    // relative to the scale height and passes without the legend.
    group('Bar height (horizontal type)', () {
      late AnyObject data;
      late AnyObject config;

      setUp(() {
        // 2 datasets
        data = <String, Object?>{
          'labels': <Object?>[
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
          ],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 20, 30, 40, 50, 60, 70],
            },
            <String, Object?>{
              'data': <Object?>[10, 20, 30, 40, 50, 60, 70],
            },
          ],
        };
      });

      // :1399 the afterEach acquires a chart: each test calls it last.
      void afterEach() {
        final chart = acquireChart(config);
        final meta = chart.getDatasetMeta(0);
        final yScale = chart.scales[meta.yAxisID]!;

        final config0 = meta.controller!.options;
        final categoryPercentage = jsGet(config0, 'categoryPercentage');
        final barPercentage = jsGet(config0, 'barPercentage');
        final stacked = jsGet(yScale.options, 'stacked');

        var totalBarHeight = 0.0;
        final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
        for (var i = 0; i < datasets.length; i++) {
          final bars = chart.getDatasetMeta(i.toDouble()).data;
          for (var j = yScale.min; j <= yScale.max; j++) {
            totalBarHeight += (bars[j.toInt()] as BarElement).height;
          }
          if (jsTruthy(stacked)) {
            break;
          }
        }

        final actualValue = totalBarHeight;
        final expectedValue =
            yScale.height *
            jsToNumber(categoryPercentage) *
            jsToNumber(barPercentage);
        expect(actualValue, toBeCloseToPixel(expectedValue));
      }

      testWidgets('should correctly set bar height when min and max option is '
          'set.', (tester) async {
        config = <String, Object?>{
          'type': 'bar',
          'data': data,
          'options': <String, Object?>{
            'indexAxis': 'y',
            'scales': <String, Object?>{
              'y': <String, Object?>{'min': 'March', 'max': 'May'},
            },
          },
        };
        afterEach();
      });

      testWidgets('should correctly set bar height when scale are stacked '
          'with min and max options.', (tester) async {
        config = <String, Object?>{
          'type': 'bar',
          'data': data,
          'options': <String, Object?>{
            'indexAxis': 'y',
            'scales': <String, Object?>{
              'x': <String, Object?>{'stacked': true},
              'y': <String, Object?>{'min': 'March', 'max': 'May'},
            },
          },
        };
        afterEach();
      });
    });

    group('Bar thickness with a category scale', () {
      for (final barThickness in <Object?>[undefined, 20]) {
        group('When barThickness is ${jsToString(barThickness)}', () {
          late Chart chart;

          // :1465 the beforeEach acquires a chart: each test calls it first.
          void beforeEach() {
            chart = acquireChart(<String, Object?>{
              'type': 'bar',
              'data': <String, Object?>{
                'datasets': <Object?>[
                  <String, Object?>{
                    'data': <Object?>[1, 2],
                  },
                  <String, Object?>{
                    'data': <Object?>[1, 2],
                  },
                ],
                'labels': <Object?>['label1', 'label2', 'label3'],
              },
              'options': <String, Object?>{
                'legend': false,
                'title': false,
                'datasets': <String, Object?>{
                  'bar': <String, Object?>{'barThickness': barThickness},
                },
                'scales': <String, Object?>{
                  'x': <String, Object?>{'id': 'x', 'type': 'category'},
                  'y': <String, Object?>{'type': 'linear'},
                },
              },
            });
          }

          testWidgets('should correctly set bar width', (tester) async {
            beforeEach();
            Object? expected;

            if (jsTruthy(barThickness)) {
              expected = barThickness;
            } else {
              final scale = chart.scales['x']!;
              final options = jsGet(jsGet(Chart.defaults, 'datasets'), 'bar');
              final categoryPercentage = jsToNumber(
                jsGet(options, 'categoryPercentage'),
              );
              final barPercentage = jsToNumber(jsGet(options, 'barPercentage'));
              final tickInterval =
                  scale.getPixelForTick(1)! - scale.getPixelForTick(0)!;

              expected = tickInterval * categoryPercentage / 2 * barPercentage;
            }

            final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
            for (var i = 0, ilen = datasets.length; i < ilen; ++i) {
              final meta = chart.getDatasetMeta(i.toDouble());
              expect(_bar(meta, 0).width, toBeCloseToPixel(expected));
              expect(_bar(meta, 1).width, toBeCloseToPixel(expected));
            }
          });

          testWidgets(
            'should correctly set bar width if maxBarThickness is specified',
            (tester) async {
              beforeEach();

              _dataset(chart, 0)['maxBarThickness'] = 10;
              _dataset(chart, 1)['maxBarThickness'] = 10;
              chart.update();

              final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
              for (var i = 0, ilen = datasets.length; i < ilen; ++i) {
                final meta = chart.getDatasetMeta(i.toDouble());
                expect(_bar(meta, 0).width, toBeCloseToPixel(10));
                expect(_bar(meta, 1).width, toBeCloseToPixel(10));
              }
            },
          );
        });
      }
    });

    // Decision D1 of the phase lead: the default legend changes the y
    // positions of the bars, but the assertion is relative to `base` and
    // passes without the legend.
    testWidgets('minBarLength settings should be used on Y axis on bar chart', (
      tester,
    ) async {
      const minBarLength = 4;
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'minBarLength': minBarLength,
              'data': <Object?>[0.05, -0.05, 10, 15, 20, 25, 30, 35],
            },
          ],
        },
      });

      final data = chart.getDatasetMeta(0).data;
      final halfBaseLine = chart.scales['y']!.getLineWidthForValue(0) / 2;

      final bar0 = data[0] as BarElement;
      final bar1 = data[1] as BarElement;
      expect(bar0.base - minBarLength + halfBaseLine, bar0.y);
      expect(bar1.base + minBarLength - halfBaseLine, bar1.y);
    });

    testWidgets(
      'minBarLength settings should be used on X axis on horizontal bar chart',
      (tester) async {
        const minBarLength = 4;
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'indexAxis': 'y',
                'minBarLength': minBarLength,
                'data': <Object?>[0.05, -0.05, 10, 15, 20, 25, 30, 35],
              },
            ],
          },
        });

        final data = chart.getDatasetMeta(0).data;
        final halfBaseLine = chart.scales['x']!.getLineWidthForValue(0) / 2;

        final bar0 = data[0] as BarElement;
        final bar1 = data[1] as BarElement;
        expect(bar0.base + minBarLength - halfBaseLine, bar0.x);
        expect(bar1.base - minBarLength + halfBaseLine, bar1.x);
      },
    );

    testWidgets('should respect the data visibility settings', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1, 2, 3, 4],
            },
          ],
          'labels': <Object?>['A', 'B', 'C', 'D'],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'category', 'display': false},
            'y': <String, Object?>{'type': 'linear', 'display': false},
          },
        },
      });

      var data = chart.getDatasetMeta(0).data;
      expect((data[0] as BarElement).base, toBeCloseToPixel(512));
      expect((data[0] as BarElement).y, toBeCloseToPixel(384));

      chart
        ..toggleDataVisibility(0)
        ..update();

      data = chart.getDatasetMeta(0).data;
      expect((data[0] as BarElement).base, toBeCloseToPixel(512));
      expect((data[0] as BarElement).y, toBeCloseToPixel(512));
    });

    testWidgets('should hide bar dataset beneath the chart for correct '
        'animations', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1, 2, 3, 4],
            },
            <String, Object?>{
              'data': <Object?>[1, 2, 3, 4],
            },
          ],
          'labels': <Object?>['A', 'B', 'C', 'D'],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{'legend': false, 'title': false},
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'type': 'category',
              'display': false,
              'stacked': true,
            },
            'y': <String, Object?>{
              'type': 'linear',
              'display': false,
              'stacked': true,
            },
          },
        },
      });

      var data = chart.getDatasetMeta(0).data;
      expect((data[0] as BarElement).base, toBeCloseToPixel(512));
      expect((data[0] as BarElement).y, toBeCloseToPixel(448));

      chart
        ..setDatasetVisibility(0, false)
        ..update();

      data = chart.getDatasetMeta(0).data;
      expect((data[0] as BarElement).base, toBeCloseToPixel(640));
      expect((data[0] as BarElement).y, toBeCloseToPixel(512));
    });

    group('Float bar', () {
      testWidgets('Should return correct values from getMinMax', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'labels': <Object?>['a'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  <Object?>[10, -10],
                ],
              },
            ],
          },
        });

        // `getMinMax()` without an argument: `canStack` is `undefined`,
        // falsy.
        final minMax = chart.scales['y']!.getMinMax(false);
        expect(
          <String, Object?>{'min': minMax.min, 'max': minMax.max},
          jasmineEquals(<String, Object?>{'min': -10, 'max': 10}),
        );
      });
    });

    group('clip', () {
      testWidgets('Should not use ctx.clip when clip=false', (tester) async {
        final ctx = _ResetTransformContext();

        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'labels': <Object?>['a', 'b', 'c'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 2, 3],
                'clip': false,
              },
            ],
          },
        });
        final orig = chart.ctx;

        // Draw on mock context
        chart
          ..ctx = ctx
          ..draw()
          ..ctx = orig;

        expect(
          ctx.getCalls().where((x) => x['name'] == 'clip').length,
          0,
        );
      });
    });

    testWidgets('should not crash with skipNull and uneven datasets', (
      tester,
    ) async {
      void unevenChart() {
        acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'labels': <Object?>[1, 2],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 2],
              },
              <String, Object?>{
                'data': <Object?>[1, 2, 3],
              },
            ],
          },
          'options': <String, Object?>{'skipNull': true},
        });
      }

      expect(unevenChart, returnsNormally);
    });

    testWidgets('should correctly count the number of stacks when skipNull '
        'and different order datasets', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'id': '1',
              'label': 'USA',
              'data': <Object?>[
                <String, Object?>{
                  'xScale': 'First',
                  'Country': 'USA',
                  'yScale': 524,
                },
                <String, Object?>{
                  'xScale': 'Second',
                  'Country': 'USA',
                  'yScale': 325,
                },
              ],

              'yAxisID': 'yScale',
              'xAxisID': 'xScale',

              'parsing': <String, Object?>{
                'yAxisKey': 'yScale',
                'xAxisKey': 'xScale',
              },
            },
            <String, Object?>{
              'id': '2',
              'label': 'BRA',
              'data': <Object?>[
                <String, Object?>{
                  'xScale': 'Second',
                  'Country': 'BRA',
                  'yScale': 183,
                },
                <String, Object?>{
                  'xScale': 'First',
                  'Country': 'BRA',
                  'yScale': 177,
                },
              ],

              'yAxisID': 'yScale',
              'xAxisID': 'xScale',

              'parsing': <String, Object?>{
                'yAxisKey': 'yScale',
                'xAxisKey': 'xScale',
              },
            },
            <String, Object?>{
              'id': '3',
              'label': 'DEU',
              'data': <Object?>[
                <String, Object?>{
                  'xScale': 'First',
                  'Country': 'DEU',
                  'yScale': 162,
                },
              ],

              'yAxisID': 'yScale',
              'xAxisID': 'xScale',

              'parsing': <String, Object?>{
                'yAxisKey': 'yScale',
                'xAxisKey': 'xScale',
              },
            },
          ],
        },
        'options': <String, Object?>{'skipNull': true},
      });

      final meta = chart.getDatasetMeta(0);
      final controller = meta.controller! as BarController;
      expect(controller.getStackCount(0), 3);
      expect(controller.getStackCount(1), 2);
    });

    // :1808 The case reads chart.tooltip: it needs the tooltip plugin of
    // phase 8.
    test(
      'should not override tooltip title and label callbacks',
      () {},
      skip: 'blocked: plugin.tooltip',
    );
  });
}

/// The `forEach` of :797-807 and of the same blocks: `base`, `width`, `x`
/// and `y` of each bar of [meta] against [values].
void _expectBars(
  ChartMeta meta,
  List<({num b, num w, num x, num y})> values,
) {
  for (var i = 0; i < values.length; i++) {
    final bar = _bar(meta, i);
    expect(bar.base, toBeCloseToPixel(values[i].b));
    expect(bar.width, toBeCloseToPixel(values[i].w));
    expect(bar.x, toBeCloseToPixel(values[i].x));
    expect(bar.y, toBeCloseToPixel(values[i].y));
  }
}
