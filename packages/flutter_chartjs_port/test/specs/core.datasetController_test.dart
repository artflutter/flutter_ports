// Ported from Chart.js v4.5.1+7169e651 test/specs/core.datasetController.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:convert';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.animations.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// The spec tests Chart.DatasetController, the DatasetController of
// lib/src/core/core.datasetController.dart. Each case acquires a line, bar,
// scatter or radar chart with datasets. Thus each case needs a controller of
// phase 7 and the scales of phase 6. A chart case is a `testWidgets` case,
// and the file runs on the VM (Chart.js ADR 0030, section 12 item 5). It
// does not call `setUpSpecs()`: its charts need the built-in components.
//
// The spec forms:
// - `chart._stacks` is `chart.stacks`. The keys of a stack are the
//   `ToString` of the index values, as the JS property keys.
// - `chart.data.datasets[i]` is `_dataset(chart, i)`. `meta._parsed` is
//   `meta.parsed`. `meta.data[i].x` is `_element(meta, i).x`.
// - `expect(fn).not.toThrow()` is `expect(fn, returnsNormally)`. `toBe` of
//   an object is `same`. `toEqual` is `jasmineEquals`.
//   `jasmine.objectContaining` is `objectContaining`.
// - `data.push(...)`, `pop()`, `shift()`, `splice(...)` and `unshift(...)`
//   on a data array are `_push`, `_pop`, `_shift`, `_splice` and `_unshift`:
//   the change of the List, then `notifyArrayListeners`, the body of the
//   hooked method (differences.md row platform-array-events).
// - `spyOn(controller, '_onData<X>')` for the five methods is
//   `spyOnArrayListener(data, controller)` of test/support/jasmine.dart.
// - `Object.freeze(array)` is `List.unmodifiable`. `Object.seal(array)` and
//   `Object.preventExtensions(array)` are a List of fixed length: Dart has no
//   List that can lose items but not get them. `Object.isExtensible(array)`
//   is `_isExtensible`.
// - `controller._resolveAnimations(...)._properties` is
//   `controller.resolveAnimations(...).properties` (Chart.js ADR 0012).
//   `toBeInstanceOf(Object)` is `isA<Object>()`. `withContext(text)` is the
//   `reason` of `expect`.
// - `opts.$shared` is `jsGet(opts, r'$shared')`. `Object.isFrozen` is
//   `jsObjectIsFrozen` (Chart.js ADR 0021, section 7).
// - `delete Chart.defaults.datasets.line.fill` is `remove('fill')`.
//
// test/port/core/core.datasetController_test.dart covers the controller with
// a fake chart, fake scales and a test controller.

/// `chart.data.datasets[index]`.
AnyObject _dataset(Chart chart, int index) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>)[index]! as AnyObject;

/// `meta.data[index]`, an element of core.element.dart.
Element _element(types.ChartMeta meta, int index) =>
    meta.data[index] as Element;

/// `meta._parsed.map(p => p[key])`.
List<Object?> _parsedOf(types.ChartMeta meta, String key) => [
  for (final p in (meta as ChartMeta).parsed) jsGet(p, key),
];

/// `data.push(...items)`: the change, then the notification of the hooked
/// method (differences.md row platform-array-events).
void _push(List<Object?> data, List<Object?> items) {
  data.addAll(items);
  notifyArrayListeners(data, 'push', items);
}

/// `data.pop()`.
void _pop(List<Object?> data) {
  if (data.isNotEmpty) data.removeLast();
  notifyArrayListeners(data, 'pop', const []);
}

/// `data.shift()`: the first item, or `undefined` for an empty array.
Object? _shift(List<Object?> data) {
  final item = data.isEmpty ? undefined : data.removeAt(0);
  notifyArrayListeners(data, 'shift', const []);
  return item;
}

/// `data.splice(start, deleteCount, ...items)`.
void _splice(
  List<Object?> data,
  int start,
  int deleteCount,
  List<Object?> items,
) {
  jsSplice(data, start.toDouble(), deleteCount.toDouble(), items);
  notifyArrayListeners(data, 'splice', [start, deleteCount, ...items]);
}

/// `data.unshift(...items)`.
void _unshift(List<Object?> data, List<Object?> items) {
  data.insertAll(0, items);
  notifyArrayListeners(data, 'unshift', items);
}

/// `Object.isExtensible(data)` for a List: whether the List takes a new
/// item. A Dart List has no extensibility state. A List that cannot grow
/// throws an [UnsupportedError] at `add`.
bool _isExtensible(List<Object?> data) {
  try {
    data
      ..add(undefined)
      ..removeLast();
    return true;
    // The add of a List that cannot grow throws this Error.
    // ignore: avoid_catching_errors
  } on UnsupportedError {
    return false;
  }
}

void main() {
  group('Chart.DatasetController', () {
    group('auto', fixture.specs('core.datasetController'));

    testWidgets('should listen for dataset data insertions or removals', (
      tester,
    ) async {
      final data = <Object?>[0, 1, 2, 3, 4, 5];
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{'data': data},
          ],
        },
      });

      final controller = chart.getDatasetMeta(0).controller!;
      final methods = <String>[
        '_onDataPush',
        '_onDataPop',
        '_onDataShift',
        '_onDataSplice',
        '_onDataUnshift',
      ];

      // methods.forEach((method) => spyOn(controller, method)): one spy
      // listener takes the place of the controller.
      final calls = spyOnArrayListener(data, controller);

      _push(data, [6, 7, 8]);
      _push(data, [9]);
      _pop(data);
      _shift(data);
      _shift(data);
      _shift(data);
      _splice(data, 1, 4, [10, 11]);
      _unshift(data, [12, 13, 14, 15]);
      _unshift(data, [16, 17]);

      final expected = [2, 1, 3, 1, 2];
      for (var index = 0; index < expected.length; index++) {
        expect(calls[methods[index]]!.count(), expected[index]);
      }
    });

    testWidgets('should not try to delete non existent stacks', (
      tester,
    ) async {
      void createAndUpdateChart() {
        acquireChart(<String, Object?>{
            'data': <String, Object?>{
              'labels': <Object?>['q'],
              'datasets': <Object?>[
                <String, Object?>{
                  'id': 'dismissed',
                  'label': 'Test before',
                  'yAxisID': 'count',
                  'data': <Object?>[816],
                  'type': 'bar',
                  'stack': 'stack',
                },
              ],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'count': <String, Object?>{'axis': 'y', 'type': 'linear'},
              },
            },
          })
          ..data = <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'id': 'tests',
                'yAxisID': 'count',
                'label': 'Test after',
                'data': <Object?>[38300],
                'type': 'bar',
              },
            ],
            'labels': <Object?>['q'],
          }
          ..update();
      }

      expect(createAndUpdateChart, returnsNormally);
    });

    group('inextensible data', () {
      testWidgets('should handle a frozen data object', (tester) async {
        void createChart() {
          final data = List<Object?>.unmodifiable(<Object?>[0, 1, 2, 3, 4, 5]);
          expect(_isExtensible(data), isFalse);

          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{'data': data},
              ],
            },
          });

          final dataset = _dataset(chart, 0);
          dataset['data'] = List<Object?>.unmodifiable(<Object?>[
            5,
            4,
            3,
            2,
            1,
            0,
          ]);
          expect(_isExtensible(dataset['data']! as List<Object?>), isFalse);
          chart
            ..update()
            // Tests that the unlisten path also works for frozen objects
            ..destroy();
        }

        expect(createChart, returnsNormally);
      });

      testWidgets('should handle a sealed data object', (tester) async {
        void createChart() {
          final data = List<Object?>.of(<Object?>[
            0,
            1,
            2,
            3,
            4,
            5,
          ], growable: false);
          expect(_isExtensible(data), isFalse);

          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{'data': data},
              ],
            },
          });

          final dataset = _dataset(chart, 0);
          dataset['data'] = List<Object?>.of(<Object?>[
            5,
            4,
            3,
            2,
            1,
            0,
          ], growable: false);
          expect(_isExtensible(dataset['data']! as List<Object?>), isFalse);
          chart
            ..update()
            // Tests that the unlisten path also works for frozen objects
            ..destroy();
        }

        expect(createChart, returnsNormally);
      });

      testWidgets('should handle an unextendable data object', (tester) async {
        void createChart() {
          final data = List<Object?>.of(<Object?>[
            0,
            1,
            2,
            3,
            4,
            5,
          ], growable: false);
          expect(_isExtensible(data), isFalse);

          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{'data': data},
              ],
            },
          });

          final dataset = _dataset(chart, 0);
          dataset['data'] = List<Object?>.of(<Object?>[
            5,
            4,
            3,
            2,
            1,
            0,
          ], growable: false);
          expect(_isExtensible(dataset['data']! as List<Object?>), isFalse);
          chart
            ..update()
            // Tests that the unlisten path also works for frozen objects
            ..destroy();
        }

        expect(createChart, returnsNormally);
      });
    });

    testWidgets('should parse data using correct scales', (tester) async {
      final data1 = <Object?>[0, 1, 2, 3, 4, 5];
      final data2 = <Object?>['a', 'b', 'c', 'd', 'a'];
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{'data': data1},
            <String, Object?>{'data': data2, 'xAxisID': 'x2', 'yAxisID': 'y2'},
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'type': 'category',
              'labels': <Object?>['one', 'two', 'three', 'four', 'five', 'six'],
            },
            'x2': <String, Object?>{
              'type': 'logarithmic',
              'labels': <Object?>['1', '10', '100', '1000', '2000'],
            },
            'y': <String, Object?>{'type': 'linear'},
            'y2': <String, Object?>{
              'type': 'category',
              'labels': <Object?>['a', 'b', 'c', 'd', 'e'],
            },
          },
        },
      });

      final meta1 = chart.getDatasetMeta(0);
      final parsedXValues1 = _parsedOf(meta1, 'x');
      final parsedYValues1 = _parsedOf(meta1, 'y');

      expect(meta1.data.length, 6);
      expect(
        parsedXValues1,
        jasmineEquals(<Object?>[0, 1, 2, 3, 4, 5]),
      ); // label indices
      expect(parsedYValues1, jasmineEquals(data1));

      final meta2 = chart.getDatasetMeta(1);
      final parsedXValues2 = _parsedOf(meta2, 'x');
      final parsedYValues2 = _parsedOf(meta2, 'y');

      expect(meta2.data.length, 5);
      expect(
        parsedXValues2,
        jasmineEquals(<Object?>[1, 10, 100, 1000, 2000]),
      ); // logarithmic scale labels
      expect(
        parsedYValues2,
        jasmineEquals(<Object?>[0, 1, 2, 3, 0]),
      ); // label indices
    });

    testWidgets('should parse using provided keys', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{
                  'x': 1,
                  'data': <String, Object?>{'key': 'one', 'value': 20},
                },
                <String, Object?>{
                  'data': <String, Object?>{'key': 'two', 'value': 30},
                },
              ],
            },
          ],
        },
        'options': <String, Object?>{
          'parsing': <String, Object?>{
            'xAxisKey': 'data.key',
            'yAxisKey': 'data.value',
          },
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'type': 'category',
              'labels': <Object?>['one', 'two'],
            },
            'y': <String, Object?>{'type': 'linear'},
          },
        },
      });

      final meta = chart.getDatasetMeta(0);
      final parsedXValues = _parsedOf(meta, 'x');
      final parsedYValues = _parsedOf(meta, 'y');

      expect(meta.data.length, 2);
      expect(parsedXValues, jasmineEquals(<Object?>[0, 1])); // label indices
      expect(parsedYValues, jasmineEquals(<Object?>[20, 30]));
    });

    group('labels array synchronization', () {
      final data1 = <Object?>[
        <String, Object?>{'x': 'One', 'name': 'One', 'y': 1, 'value': 1},
        <String, Object?>{'x': 'Two', 'name': 'Two', 'y': 2, 'value': 2},
      ];
      final data2 = <Object?>[
        <String, Object?>{'x': 'Three', 'name': 'Three', 'y': 3, 'value': 3},
        <String, Object?>{'x': 'Four', 'name': 'Four', 'y': 4, 'value': 4},
        <String, Object?>{'x': 'Five', 'name': 'Five', 'y': 5, 'value': 5},
      ];
      List<Object?> xOf(List<Object?> data) => [
        for (final n in data) jsGet(n, 'x'),
      ];
      for (final parsing in <Object?>[
        true,
        false,
        <String, Object?>{'xAxisKey': 'name', 'yAxisKey': 'value'},
      ]) {
        group('when parsing is ${jsonEncode(parsing)}', () {
          testWidgets('should remove old labels when data is updated', (
            tester,
          ) async {
            final chart = acquireChart(<String, Object?>{
              'type': 'line',
              'data': <String, Object?>{
                'datasets': <Object?>[
                  <String, Object?>{'data': data1},
                ],
              },
              'options': <String, Object?>{'parsing': parsing},
            });

            _dataset(chart, 0)['data'] = data2;
            chart.update();

            final meta = chart.getDatasetMeta(0);
            final labels = meta.iScale!.getLabels();
            expect(labels, jasmineEquals(xOf(data2)));
          });

          testWidgets('should not remove any user added labels', (
            tester,
          ) async {
            final chart = acquireChart(<String, Object?>{
              'type': 'line',
              'data': <String, Object?>{
                'datasets': <Object?>[
                  <String, Object?>{'data': data1},
                ],
              },
              'options': <String, Object?>{'parsing': parsing},
            });

            (jsGet(chart.data, 'labels')! as List<Object?>).add('user-added');
            _dataset(chart, 0)['data'] = <Object?>[];
            chart.update();

            final meta = chart.getDatasetMeta(0);
            final labels = meta.iScale!.getLabels();
            expect(labels, jasmineEquals(<Object?>['user-added']));
          });

          testWidgets('should not remove any user defined labels', (
            tester,
          ) async {
            final chart = acquireChart(<String, Object?>{
              'type': 'line',
              'data': <String, Object?>{
                'datasets': <Object?>[
                  <String, Object?>{'data': data1},
                ],
                'labels': <Object?>['user1', 'user2'],
              },
              'options': <String, Object?>{'parsing': parsing},
            });

            final meta = chart.getDatasetMeta(0);

            expect(
              meta.iScale!.getLabels(),
              jasmineEquals(<Object?>['user1', 'user2', ...xOf(data1)]),
            );

            _dataset(chart, 0)['data'] = data2;
            chart.update();

            expect(
              meta.iScale!.getLabels(),
              jasmineEquals(<Object?>['user1', 'user2', ...xOf(data2)]),
            );
          });

          testWidgets('should keep up with multiple datasets', (tester) async {
            final chart = acquireChart(<String, Object?>{
              'type': 'line',
              'data': <String, Object?>{
                'datasets': <Object?>[
                  <String, Object?>{'data': data1},
                  <String, Object?>{'data': data2},
                ],
                'labels': <Object?>['One', 'Three'],
              },
              'options': <String, Object?>{'parsing': parsing},
            });

            final scale = chart.scales['x']!;

            expect(
              scale.getLabels(),
              jasmineEquals(<Object?>['One', 'Three', 'Two', 'Four', 'Five']),
            );

            _dataset(chart, 0)['data'] = data2;
            _dataset(chart, 1)['data'] = data1;
            chart.update();

            expect(
              scale.getLabels(),
              jasmineEquals(<Object?>['One', 'Three', 'Four', 'Five', 'Two']),
            );
          });
        });
      }
    });

    testWidgets(
      'should synchronize metadata when data are inserted or removed and '
      'parsing is on',
      (tester) async {
        final data = <Object?>[0, 1, 2, 3, 4, 5];
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': data},
            ],
          },
        });

        final meta = chart.getDatasetMeta(0);
        List<Object?> parsedYValues() => _parsedOf(meta, 'y');
        late types.Element first;
        late types.Element second;
        late types.Element last;

        first = meta.data[0];
        last = meta.data[5];
        _push(data, [6, 7, 8]);
        _push(data, [9]);
        chart.update();
        expect(meta.data.length, 10);
        expect(meta.data[0], same(first));
        expect(meta.data[5], same(last));
        expect(parsedYValues(), jasmineEquals(data));

        last = meta.data[9];
        _pop(data);
        chart.update();
        expect(meta.data.length, 9);
        expect(meta.data[0], same(first));
        expect(meta.data.indexOf(last), -1);
        expect(parsedYValues(), jasmineEquals(data));

        last = meta.data[8];
        _shift(data);
        _shift(data);
        _shift(data);
        chart.update();
        expect(meta.data.length, 6);
        expect(meta.data.indexOf(first), -1);
        expect(meta.data[5], same(last));
        expect(parsedYValues(), jasmineEquals(data));

        first = meta.data[0];
        second = meta.data[1];
        last = meta.data[5];
        _splice(data, 1, 4, [10, 11]);
        chart.update();
        expect(meta.data.length, 4);
        expect(meta.data[0], same(first));
        expect(meta.data[3], same(last));
        expect(meta.data.indexOf(second), -1);
        expect(parsedYValues(), jasmineEquals(data));

        _unshift(data, [12, 13, 14, 15]);
        _unshift(data, [16, 17]);
        chart.update();
        expect(meta.data.length, 10);
        expect(meta.data[6], same(first));
        expect(meta.data[9], same(last));
        expect(parsedYValues(), jasmineEquals(data));
      },
    );

    testWidgets(
      'should synchronize metadata when data are inserted or removed and '
      'parsing is off',
      (tester) async {
        final data = <Object?>[
          <String, Object?>{'x': 0, 'y': 0},
          <String, Object?>{'x': 1, 'y': 1},
          <String, Object?>{'x': 2, 'y': 2},
          <String, Object?>{'x': 3, 'y': 3},
          <String, Object?>{'x': 4, 'y': 4},
          <String, Object?>{'x': 5, 'y': 5},
        ];
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': data},
            ],
          },
          'options': <String, Object?>{
            'parsing': false,
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear'},
              'y': <String, Object?>{'type': 'linear'},
            },
          },
        });

        final meta = chart.getDatasetMeta(0);
        final controller = meta.controller!;
        Object? first;
        Object? last;

        first = controller.getParsed(0);
        last = controller.getParsed(5);
        _push(data, [
          <String, Object?>{'x': 6, 'y': 6},
          <String, Object?>{'x': 7, 'y': 7},
          <String, Object?>{'x': 8, 'y': 8},
        ]);
        _push(data, [
          <String, Object?>{'x': 9, 'y': 9},
        ]);
        chart.update();
        expect(meta.data.length, 10);
        expect(controller.getParsed(0), same(first));
        expect(controller.getParsed(5), same(last));

        last = controller.getParsed(9);
        _pop(data);
        chart.update();
        expect(meta.data.length, 9);
        expect(controller.getParsed(0), same(first));
        expect(controller.getParsed(9), same(undefined));
        expect(
          controller.getParsed(8),
          jasmineEquals(<String, Object?>{'x': 8, 'y': 8}),
        );

        last = controller.getParsed(8);
        _shift(data);
        _shift(data);
        _shift(data);
        chart.update();
        expect(meta.data.length, 6);
        expect(controller.getParsed(5), same(last));

        first = controller.getParsed(0);
        last = controller.getParsed(5);
        _splice(data, 1, 4, [
          <String, Object?>{'x': 10, 'y': 10},
          <String, Object?>{'x': 11, 'y': 11},
        ]);
        chart.update();
        expect(meta.data.length, 4);
        expect(controller.getParsed(0), same(first));
        expect(controller.getParsed(3), same(last));
        expect(
          controller.getParsed(1),
          jasmineEquals(<String, Object?>{'x': 10, 'y': 10}),
        );

        _unshift(data, [
          <String, Object?>{'x': 12, 'y': 12},
          <String, Object?>{'x': 13, 'y': 13},
          <String, Object?>{'x': 14, 'y': 14},
          <String, Object?>{'x': 15, 'y': 15},
        ]);
        _unshift(data, [
          <String, Object?>{'x': 16, 'y': 16},
          <String, Object?>{'x': 17, 'y': 17},
        ]);
        chart.update();
        expect(meta.data.length, 10);
        expect(controller.getParsed(6), same(first));
        expect(controller.getParsed(9), same(last));
      },
    );

    testWidgets(
      'should synchronize insert before removal when parsing is off',
      (tester) async {
        // https://github.com/chartjs/Chart.js/issues/9511
        final data = <Object?>[
          <String, Object?>{'x': 0, 'y': 1},
          <String, Object?>{'x': 2, 'y': 7},
          <String, Object?>{'x': 3, 'y': 5},
        ];
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': data},
            ],
          },
          'options': <String, Object?>{
            'parsing': false,
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear', 'min': 0, 'max': 10},
              'y': <String, Object?>{'type': 'linear', 'min': 0, 'max': 10},
            },
          },
        });

        final meta = chart.getDatasetMeta(0);
        final controller = meta.controller!;

        _push(data, [
          <String, Object?>{'x': 10, 'y': 6},
        ]);
        _splice(data, 0, 1, const []);
        chart.update();

        expect(meta.data.length, 3);
        expect(controller.getParsed(0), same(data[0]));
        expect(controller.getParsed(2), same(data[2]));
      },
    );

    testWidgets(
      'should re-synchronize metadata when the data object reference changes',
      (tester) async {
        final data0 = <Object?>[0, 1, 2, 3, 4, 5];
        final data1 = <Object?>[6, 7, 8];
        final data2 = <Object?>[1, 2, 3, 4, 5, 6, 7, 8];

        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': data0},
            ],
          },
        });

        final meta = chart.getDatasetMeta(0);

        expect(meta.data.length, 6);
        expect(_parsedOf(meta, 'y'), jasmineEquals(data0));
        final point0 = meta.data[0];

        _dataset(chart, 0)['data'] = data1;
        chart.update();

        expect(meta.data.length, 3);
        expect(_parsedOf(meta, 'y'), jasmineEquals(data1));
        expect(meta.data[0], jasmineEquals(point0));

        _push(data1, [9]);
        chart.update();
        expect(meta.data.length, 4);

        _dataset(chart, 0)['data'] = data0;
        chart.update();

        expect(meta.data.length, 6);
        expect(_parsedOf(meta, 'y'), jasmineEquals(data0));

        _dataset(chart, 0)['data'] = data2;
        chart.update();

        expect(meta.data.length, 8);
        expect(_parsedOf(meta, 'y'), jasmineEquals(data2));
      },
    );

    testWidgets(
      'should re-synchronize metadata when the data object reference '
      'changes, with animation',
      (tester) async {
        final data0 = <Object?>[0, 1, 2, 3, 4, 5];
        final data1 = <Object?>[6, 7, 8];
        final data2 = <Object?>[1, 2, 3, 4, 5, 6, 7, 8];

        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': data0},
            ],
          },
          'options': <String, Object?>{'animation': true},
        });

        final meta = chart.getDatasetMeta(0);

        expect(meta.data.length, 6);
        expect(_parsedOf(meta, 'y'), jasmineEquals(data0));
        final point0 = meta.data[0];

        _dataset(chart, 0)['data'] = data1;
        chart.update();

        expect(meta.data.length, 3);
        expect(_parsedOf(meta, 'y'), jasmineEquals(data1));
        expect(meta.data[0], jasmineEquals(point0));

        _push(data1, [9]);
        chart.update();
        expect(meta.data.length, 4);

        _dataset(chart, 0)['data'] = data0;
        chart.update();

        expect(meta.data.length, 6);
        expect(_parsedOf(meta, 'y'), jasmineEquals(data0));

        _dataset(chart, 0)['data'] = data2;
        chart.update();

        expect(meta.data.length, 8);
        expect(_parsedOf(meta, 'y'), jasmineEquals(data2));
      },
    );

    testWidgets(
      'should re-synchronize metadata when data are unusually altered',
      (tester) async {
        final data = <Object?>[0, 1, 2, 3, 4, 5];
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': data},
            ],
          },
        });

        final meta = chart.getDatasetMeta(0);

        expect(meta.data.length, 6);

        data.length = 2;
        chart.update();

        expect(meta.data.length, 2);

        // `data.length = 42` adds holes: each read of a hole gives
        // `undefined`.
        data.addAll(List<Object?>.filled(40, undefined));
        chart.update();

        expect(meta.data.length, 42);
      },
    );

    // https://github.com/chartjs/Chart.js/issues/7243
    testWidgets(
      'should re-synchronize metadata when data is moved and values are equal',
      (tester) async {
        final data = <Object?>[10, 10, 10, 10, 10, 10];
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
            'datasets': <Object?>[
              <String, Object?>{'data': data, 'fill': true},
            ],
          },
        });

        final meta = chart.getDatasetMeta(0);

        expect(meta.data.length, 6);
        final firstX = _element(meta, 0).x;

        _push(data, [_shift(data)]);
        chart.update();

        expect(meta.data.length, 6);
        expect(_element(meta, 0).x, jasmineEquals(firstX));
      },
    );

    // https://github.com/chartjs/Chart.js/issues/7445
    testWidgets(
      'should re-synchronize metadata when data is objects and directly '
      'altered',
      (tester) async {
        final data = <Object?>[
          <String, Object?>{'x': 'a', 'y': 1},
          <String, Object?>{'x': 'b', 'y': 2},
          <String, Object?>{'x': 'c', 'y': 3},
        ];
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['a', 'b', 'c'],
            'datasets': <Object?>[
              <String, Object?>{'data': data, 'fill': true},
            ],
          },
        });

        final meta = chart.getDatasetMeta(0);

        expect(meta.data.length, 3);
        final y3 = _element(meta, 2).y;

        (data[0]! as AnyObject)['y'] = 3;
        chart.update();
        expect(_element(meta, 0).y, jasmineEquals(y3));
      },
    );

    testWidgets('should re-synchronize metadata when scaleID changes', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[],
              'xAxisID': 'firstXScaleID',
              'yAxisID': 'firstYScaleID',
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'firstXScaleID': <String, Object?>{
              'type': 'category',
              'position': 'bottom',
            },
            'secondXScaleID': <String, Object?>{
              'type': 'category',
              'position': 'bottom',
            },
            'firstYScaleID': <String, Object?>{
              'type': 'linear',
              'position': 'left',
            },
            'secondYScaleID': <String, Object?>{
              'type': 'linear',
              'position': 'left',
            },
          },
        },
      });

      final meta = chart.getDatasetMeta(0);

      expect(meta.xAxisID, 'firstXScaleID');
      expect(meta.yAxisID, 'firstYScaleID');

      _dataset(chart, 0)['xAxisID'] = 'secondXScaleID';
      _dataset(chart, 0)['yAxisID'] = 'secondYScaleID';
      chart.update();

      expect(meta.xAxisID, 'secondXScaleID');
      expect(meta.yAxisID, 'secondYScaleID');
    });

    testWidgets('should re-synchronize stacks when stack is changed', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1, 10],
              'stack': '1',
            },
            <String, Object?>{
              'data': <Object?>[2, 20],
              'stack': '2',
            },
            <String, Object?>{
              'data': <Object?>[3, 30],
              'stack': '1',
            },
          ],
        },
      });

      expect(
        chart.stacks,
        jasmineEquals(<String, Object?>{
          'x.y.1': <String, Object?>{
            '0': <String, Object?>{
              '0': 1,
              '2': 3,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'0': 1, '2': 3},
            },
            '1': <String, Object?>{
              '0': 10,
              '2': 30,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'0': 10, '2': 30},
            },
          },
          'x.y.2': <String, Object?>{
            '0': <String, Object?>{
              '1': 2,
              '_top': 1,
              '_bottom': null,
              '_visualValues': <String, Object?>{'1': 2},
            },
            '1': <String, Object?>{
              '1': 20,
              '_top': 1,
              '_bottom': null,
              '_visualValues': <String, Object?>{'1': 20},
            },
          },
        }),
      );

      _dataset(chart, 2)['stack'] = '2';
      chart.update();

      expect(
        chart.stacks,
        jasmineEquals(<String, Object?>{
          'x.y.1': <String, Object?>{
            '0': <String, Object?>{
              '0': 1,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'0': 1},
            },
            '1': <String, Object?>{
              '0': 10,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'0': 10},
            },
          },
          'x.y.2': <String, Object?>{
            '0': <String, Object?>{
              '1': 2,
              '2': 3,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'1': 2, '2': 3},
            },
            '1': <String, Object?>{
              '1': 20,
              '2': 30,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'1': 20, '2': 30},
            },
          },
        }),
      );
    });

    testWidgets('should re-synchronize stacks when data is removed', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1, 10],
              'stack': '1',
            },
            <String, Object?>{
              'data': <Object?>[2, 20],
              'stack': '2',
            },
            <String, Object?>{
              'data': <Object?>[3, 30],
              'stack': '1',
            },
          ],
        },
      });

      expect(
        chart.stacks,
        jasmineEquals(<String, Object?>{
          'x.y.1': <String, Object?>{
            '0': <String, Object?>{
              '0': 1,
              '2': 3,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'0': 1, '2': 3},
            },
            '1': <String, Object?>{
              '0': 10,
              '2': 30,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'0': 10, '2': 30},
            },
          },
          'x.y.2': <String, Object?>{
            '0': <String, Object?>{
              '1': 2,
              '_top': 1,
              '_bottom': null,
              '_visualValues': <String, Object?>{'1': 2},
            },
            '1': <String, Object?>{
              '1': 20,
              '_top': 1,
              '_bottom': null,
              '_visualValues': <String, Object?>{'1': 20},
            },
          },
        }),
      );

      _dataset(chart, 2)['data'] = <Object?>[4];
      chart.update();

      expect(
        chart.stacks,
        jasmineEquals(<String, Object?>{
          'x.y.1': <String, Object?>{
            '0': <String, Object?>{
              '0': 1,
              '2': 4,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'0': 1, '2': 4},
            },
            '1': <String, Object?>{
              '0': 10,
              '_top': 2,
              '_bottom': null,
              '_visualValues': <String, Object?>{'0': 10},
            },
          },
          'x.y.2': <String, Object?>{
            '0': <String, Object?>{
              '1': 2,
              '_top': 1,
              '_bottom': null,
              '_visualValues': <String, Object?>{'1': 2},
            },
            '1': <String, Object?>{
              '1': 20,
              '_top': 1,
              '_bottom': null,
              '_visualValues': <String, Object?>{'1': 20},
            },
          },
        }),
      );
    });

    // The case reads the stub `_chartjs` of each data array and compares
    // its five methods with `Array.prototype`. A Dart List has no methods
    // that a program can redefine. Thus `listenArrayEvents` hooks no method,
    // and it keeps the stub in a private Expando of helpers.collection
    // (differences.md row platform-array-events). The Dart form of each
    // check is the effect of the listener on the elements of the meta:
    // - "the array has the listener of the controller" (`_chartjs` defined,
    //   the hooked methods): an `unshift` and an update put a new element
    //   at index 0 (`_onDataUnshift`, core.datasetController.js:1074). The
    //   old element moves to index 1.
    // - "the old array has no listener" after the reference change
    //   (core.datasetController.js:378-380): a `push` on data0 and an update
    //   keep `meta.data[2]`. A stale listener calls `_onDataPush`, which
    //   inserts a new element at index 2 of data1.
    // - "data1 has no listener" before the change and after `destroy`
    //   (core.datasetController.js:355): a change of data1 adds no entry to
    //   `chart.dataChanges`. The last update empties it, and a listener of
    //   the controller adds an entry at each notification (`_sync`,
    //   core.datasetController.js:1041). A destroyed chart does not update,
    //   so the check reads `dataChanges` and not the elements. Before the
    //   change, the check removes the pushed item again, so data1 keeps its
    //   upstream items.
    testWidgets(
      'should cleanup attached properties when the reference changes or when '
      'the chart is destroyed',
      (tester) async {
        final data0 = <Object?>[0, 1, 2, 3, 4, 5];
        final data1 = <Object?>[6, 7, 8];
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'data': data0},
            ],
          },
        });

        // expect(data0._chartjs).toBeDefined(), the hooks of data0.
        final a0 = chart.getDatasetMeta(0).data[0];
        _unshift(data0, [-1]);
        chart.update();
        expect(chart.getDatasetMeta(0).data[0], isNot(same(a0)));
        expect(chart.getDatasetMeta(0).data[1], same(a0));

        // expect(data1._chartjs).not.toBeDefined(), the hooks of data1.
        _push(data1, [9]);
        expect(chart.dataChanges, isEmpty);
        data1.removeLast();

        _dataset(chart, 0)['data'] = data1;
        chart.update();

        // expect(data0._chartjs).not.toBeDefined(), the hooks of data0.
        final e2 = chart.getDatasetMeta(0).data[2];
        _push(data0, [9]);
        chart.update();
        expect(chart.getDatasetMeta(0).data[2], same(e2));

        // expect(data1._chartjs).toBeDefined(), the hooks of data1.
        final b0 = chart.getDatasetMeta(0).data[0];
        _unshift(data1, [5]);
        chart.update();
        expect(chart.getDatasetMeta(0).data[0], isNot(same(b0)));
        expect(chart.getDatasetMeta(0).data[1], same(b0));

        chart.destroy();

        // expect(data1._chartjs).not.toBeDefined(), the hooks of data1.
        _unshift(data1, [4]);
        expect(chart.dataChanges, isEmpty);
      },
    );

    testWidgets('should resolve data element options to the default color', (
      tester,
    ) async {
      final data0 = <Object?>[0, 1, 2, 3, 4, 5];
      final oldColor = Chart.defaults['borderColor'];
      Chart.defaults['borderColor'] = 'red';
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{'data': data0},
          ],
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect((meta.dataset! as Element).options!['borderColor'], 'red');
      expect(_element(meta, 0).options!['borderColor'], 'red');

      // Reset old shared state
      Chart.defaults['borderColor'] = oldColor;
    });

    testWidgets('should read parsing from options when default is false', (
      tester,
    ) async {
      final originalDefault = Chart.defaults['parsing'];
      Chart.defaults['parsing'] = false;

      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'t': 1, 'y': 0},
              ],
            },
          ],
        },
        'options': <String, Object?>{
          'parsing': <String, Object?>{'xAxisKey': 't'},
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(_element(meta, 0).x, isNot(isNaN));

      // Reset old shared state
      Chart.defaults['parsing'] = originalDefault;
    });

    testWidgets('should not fail to produce stacks when parsing is off', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'x': 1, 'y': 10},
              ],
            },
            <String, Object?>{
              'data': <Object?>[
                <String, Object?>{'x': 1, 'y': 20},
              ],
            },
          ],
        },
        'options': <String, Object?>{
          'parsing': false,
          'scales': <String, Object?>{
            'x': <String, Object?>{'stacked': true},
            'y': <String, Object?>{'stacked': true},
          },
        },
      });

      final meta = chart.getDatasetMeta(0);
      expect(
        jsGet(meta.parsed[0], '_stacks'),
        objectContaining(<String, Object?>{
          'y': <String, Object?>{
            '0': 10,
            '1': 20,
            '_top': 1,
            '_bottom': null,
            '_visualValues': <String, Object?>{'0': 10, '1': 20},
          },
        }),
      );
    });

    group('resolveDataElementOptions', () {
      testWidgets('should cache options when possible', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 2, 3],
              },
            ],
          },
        });

        final controller = chart.getDatasetMeta(0).controller!;

        expect(controller.enableOptionSharing, isTrue);

        final opts0 = controller.resolveDataElementOptions(0);
        final opts1 = controller.resolveDataElementOptions(1);

        expect(identical(opts0, opts1), isTrue);
        expect(jsGet(opts0, r'$shared'), isTrue);
        expect(jsObjectIsFrozen(opts0), isTrue);
      });

      testWidgets('should not cache options when option sharing is disabled', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'radar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 2, 3],
              },
            ],
          },
        });

        final controller = chart.getDatasetMeta(0).controller!;

        expect(controller.enableOptionSharing, isFalse);

        final opts0 = controller.resolveDataElementOptions(0);
        final opts1 = controller.resolveDataElementOptions(1);

        expect(identical(opts0, opts1), isFalse);
        expect(jsGet(opts0, r'$shared'), isNot(isTrue));
        expect(jsObjectIsFrozen(opts0), isFalse);
      });

      testWidgets('should not cache options when functions are used', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1, 2, 3],
                'backgroundColor': () => 'red',
              },
            ],
          },
        });

        final controller = chart.getDatasetMeta(0).controller!;

        final opts0 = controller.resolveDataElementOptions(0);
        final opts1 = controller.resolveDataElementOptions(1);

        expect(identical(opts0, opts1), isFalse);
        expect(jsGet(opts0, r'$shared'), isNot(isTrue));
        expect(jsObjectIsFrozen(opts0), isFalse);
      });

      testWidgets('should support nested scriptable options', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[100, 120, 130],
                'fill': <String, Object?>{
                  'value': (Object? ctx) =>
                      jsGet(ctx, 'type') == 'dataset' ? 75 : 0,
                },
              },
            ],
          },
        });

        final controller = chart.getDatasetMeta(0).controller!;
        final opts = controller.resolveDatasetElementOptions();
        expect(
          opts,
          toEqualOptions(<String, Object?>{
            'fill': <String, Object?>{'value': 75},
          }),
        );
      });

      testWidgets('should support nested scriptable defaults', (tester) async {
        final line =
            jsGet(jsGet(Chart.defaults, 'datasets'), 'line')! as AnyObject;
        line['fill'] = <String, Object?>{
          'value': (Object? ctx) => jsGet(ctx, 'type') == 'dataset' ? 75 : 0,
        };
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[100, 120, 130],
              },
            ],
          },
        });

        final controller = chart.getDatasetMeta(0).controller!;
        final opts = controller.resolveDatasetElementOptions();
        expect(
          opts,
          toEqualOptions(<String, Object?>{
            'fill': <String, Object?>{'value': 75},
          }),
        );
        line.remove('fill');
      });
    });

    group('_resolveAnimations', () {
      void animationsExpectations(
        Animations anims,
        Map<String, Map<String, Object?>> props,
      ) {
        for (final MapEntry(key: prop, value: opts) in props.entries) {
          final anim = anims.properties[prop];
          expect(anim, isA<Object>(), reason: prop);
          if (anim != null) {
            for (final MapEntry(key: name, :value) in opts.entries) {
              expect(
                anim[name],
                jasmineEquals(value),
                reason: '"$name" of ${jsObjectKeys(anim)}',
              );
            }
          }
        }
      }

      testWidgets(
        'should resolve to empty Animations when globally disabled',
        (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[1],
                  'animation': <String, Object?>{
                    'test': <String, Object?>{'duration': 10},
                  },
                },
              ],
            },
            'options': <String, Object?>{'animation': false},
          });

          final controller = chart.getDatasetMeta(0).controller!;

          expect(
            controller.resolveAnimations(0).properties.length,
            jasmineEquals(0),
          );
        },
      );

      testWidgets(
        'should resolve to empty Animations when disabled at dataset level',
        (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[1],
                  'animation': false,
                },
              ],
            },
          });

          final controller = chart.getDatasetMeta(0).controller!;

          expect(
            controller.resolveAnimations(0).properties.length,
            jasmineEquals(0),
          );
        },
      );

      testWidgets('should fallback properly', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[1],
                'animation': <String, Object?>{'duration': 200},
              },
              <String, Object?>{
                'type': 'bar',
                'data': <Object?>[2],
              },
            ],
          },
          'options': <String, Object?>{
            'animation': <String, Object?>{'delay': 100},
            'animations': <String, Object?>{
              'x': <String, Object?>{'delay': 200},
            },
            'transitions': <String, Object?>{
              'show': <String, Object?>{
                'x': <String, Object?>{'delay': 300},
              },
            },
            'datasets': <String, Object?>{
              'bar': <String, Object?>{
                'animation': <String, Object?>{'duration': 500},
              },
            },
          },
        });
        final controller = chart.getDatasetMeta(0).controller!;

        expect(
          jsGet(jsGet(Chart.defaults, 'animation'), 'duration'),
          jasmineEquals(1000),
        );

        final def0 = controller.resolveAnimations(0, 'default', false);
        animationsExpectations(def0, {
          'x': <String, Object?>{'delay': 200, 'duration': 200},
          'y': <String, Object?>{'delay': 100, 'duration': 200},
        });

        final controller2 = chart.getDatasetMeta(1).controller!;
        final def1 = controller2.resolveAnimations(0, 'default', false);
        animationsExpectations(def1, {
          'x': <String, Object?>{'delay': 200, 'duration': 500},
        });
      });
    });

    group('getContext', () {
      testWidgets('should reflect updated data', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'scatter',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[
                  <String, Object?>{'x': 1, 'y': 0},
                  <String, Object?>{'x': 2, 'y': '1'},
                ],
              },
            ],
          },
        });
        var meta = chart.getDatasetMeta(0);

        expect(
          meta.controller!.getContext(null, true, 'test'),
          objectContaining(<String, Object?>{
            'active': true,
            'datasetIndex': 0,
            'dataset': _dataset(chart, 0),
            'index': 0,
            'mode': 'test',
          }),
        );
        expect(
          meta.controller!.getContext(1, false, 'datatest'),
          objectContaining(<String, Object?>{
            'active': false,
            'datasetIndex': 0,
            'dataset': _dataset(chart, 0),
            'dataIndex': 1,
            'element': meta.data[1],
            'index': 1,
            'parsed': <String, Object?>{'x': 2, 'y': 1},
            'raw': <String, Object?>{'x': 2, 'y': '1'},
            'mode': 'datatest',
          }),
        );

        ((_dataset(chart, 0)['data']! as List<Object?>)[1]!
                as Map<String, Object?>)['y'] =
            5;
        chart.update();

        expect(
          meta.controller!.getContext(1, false, 'datatest'),
          objectContaining(<String, Object?>{
            'active': false,
            'datasetIndex': 0,
            'dataset': _dataset(chart, 0),
            'dataIndex': 1,
            'element': meta.data[1],
            'index': 1,
            'parsed': <String, Object?>{'x': 2, 'y': 5},
            'raw': <String, Object?>{'x': 2, 'y': 5},
            'mode': 'datatest',
          }),
        );

        chart.data['datasets'] = <Object?>[
          <String, Object?>{
            'data': <Object?>[
              <String, Object?>{'x': 0, 'y': 0},
              <String, Object?>{'x': 1, 'y': 1},
            ],
          },
        ];
        chart.update();
        // meta is re-created when dataset is replaced
        meta = chart.getDatasetMeta(0);

        expect(
          meta.controller!.getContext(null, false, 'test2'),
          objectContaining(<String, Object?>{
            'active': false,
            'datasetIndex': 0,
            'dataset': _dataset(chart, 0),
            'index': 0,
            'mode': 'test2',
          }),
        );
        expect(
          meta.controller!.getContext(1, true, 'datatest2'),
          objectContaining(<String, Object?>{
            'active': true,
            'datasetIndex': 0,
            'dataset': _dataset(chart, 0),
            'dataIndex': 1,
            'element': meta.data[1],
            'index': 1,
            'parsed': <String, Object?>{'x': 1, 'y': 1},
            'raw': <String, Object?>{'x': 1, 'y': 1},
            'mode': 'datatest2',
          }),
        );

        _unshift(_dataset(chart, 0)['data']! as List<Object?>, [
          <String, Object?>{'x': -1, 'y': -1},
        ]);
        chart.update();
        expect(
          meta.controller!.getContext(0, true, 'unshift'),
          objectContaining(<String, Object?>{
            'active': true,
            'datasetIndex': 0,
            'dataset': _dataset(chart, 0),
            'dataIndex': 0,
            'element': meta.data[0],
            'index': 0,
            'parsed': <String, Object?>{'x': -1, 'y': -1},
            'raw': <String, Object?>{'x': -1, 'y': -1},
            'mode': 'unshift',
          }),
        );
        expect(
          meta.controller!.getContext(2, true, 'unshift2'),
          objectContaining(<String, Object?>{
            'active': true,
            'datasetIndex': 0,
            'dataset': _dataset(chart, 0),
            'dataIndex': 2,
            'element': meta.data[2],
            'index': 2,
            'parsed': <String, Object?>{'x': 1, 'y': 1},
            'raw': <String, Object?>{'x': 1, 'y': 1},
            'mode': 'unshift2',
          }),
        );

        // `chart.data.datasets.unshift(...)`: no listener watches the
        // datasets array.
        (jsGet(chart.data, 'datasets')! as List<Object?>).insert(
          0,
          <String, Object?>{
            'data': <Object?>[
              <String, Object?>{'x': 10, 'y': 20},
            ],
          },
        );
        chart.update();
        meta = chart.getDatasetMeta(0);
        expect(
          meta.controller!.getContext(0, true, 'unshift3'),
          objectContaining(<String, Object?>{
            'active': true,
            'datasetIndex': 0,
            'dataset': _dataset(chart, 0),
            'dataIndex': 0,
            'element': meta.data[0],
            'index': 0,
            'parsed': <String, Object?>{'x': 10, 'y': 20},
            'raw': <String, Object?>{'x': 10, 'y': 20},
            'mode': 'unshift3',
          }),
        );

        meta = chart.getDatasetMeta(1);
        expect(
          meta.controller!.getContext(2, true, 'unshift4'),
          objectContaining(<String, Object?>{
            'active': true,
            'datasetIndex': 1,
            'dataset': _dataset(chart, 1),
            'dataIndex': 2,
            'element': meta.data[2],
            'index': 2,
            'parsed': <String, Object?>{'x': 1, 'y': 1},
            'raw': <String, Object?>{'x': 1, 'y': 1},
            'mode': 'unshift4',
          }),
        );
      });
    });
  });
}
