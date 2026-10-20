// Ported from Chart.js v4.5.1 test/specs/core.controller.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs, which does not export lib/src
// yet.
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/platform/platform.basic.dart';
import 'package:flutter_test/flutter_test.dart';

// `Chart` is the class of core.controller.dart. The spec runs on the VM: a
// chart reaches the chart host and dart:ui.
//
// Each chart case is a `testWidgets` case with the harness of Chart.js ADR
// 0022, section 2: `acquireChart`, `waitForResize`, `waitForDone`,
// `setTimeout` and `toBeChartOfSize`. A case that needs a module of a later
// phase skips with the missing module of the latest phase.
//
// The spec forms of Chart.js ADR 0022, section 2:
// - `chart.canvas.parentNode` is `chart.canvas!.parentElement`. The
//   `parentNode` of a harness element keeps its text.
// - `window.document.body` is `document.body`.
// - `new Chart(item, config)` is `Chart(item, config)`.
// - `fail()` is `fail('Failed')`, the message of Jasmine.
// - A spec object is a `Map<String, Object?>`. A property chain of the
//   spec, for example `config.data.labels`, is a chain of `jsGet`.
// - `toBeUndefined()` of `chart.chartArea` is `isNull`: Dart null stands
//   for JS undefined.
//
// Three cases without acquireChart build a chart with
// `Chart(canvas, config)` on a canvas of `document.createElement`. Its
// standby host gives FlutterPlatform, and the chart starts detached. The
// append to the harness body attaches it at the mutation checkpoint
// (Chart.js ADR 0022, sections 3 and 4).
//
// :3 `const overrides = Chart.overrides` comes with the bodies that read
// it.

/// `jasmine.objectContaining(expected)` over a Map: each key of [expected]
/// with an equal value.
Matcher _objectContaining(Map<String, Object?> expected) => allOf([
  for (final MapEntry(:key, :value) in expected.entries)
    containsPair(key, value),
]);

void main() {
  group('Chart', () {
    // https://github.com/chartjs/Chart.js/issues/2481
    // See global.deprecations.tests.js for backward compatibility
    testWidgets('should be defined and prototype of chart instances', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{});
      expect(Chart, isNotNull);
      expect(Chart, isA<Object>());
      // `chart.constructor` is the runtime type.
      expect(chart.runtimeType, Chart);
      expect(chart, isA<Chart>());
    });

    test(
      'should throw an error if the canvas is already in use',
      () {},
      skip: 'blocked: controller.line',
    );

    group('config initialization', () {
      testWidgets('should create missing config.data properties', (
        tester,
      ) async {
        final chart = acquireChart(<String, Object?>{});
        final data = chart.data;

        expect(data, isA<Map<String, Object?>>());
        expect(data['labels'], isA<List<Object?>>());
        expect(jsGet(data['labels'], 'length'), 0);
        expect(data['datasets'], isA<List<Object?>>());
        expect(jsGet(data['datasets'], 'length'), 0);
      });

      test(
        'should not alter config.data references',
        () {},
        skip: 'blocked: controller.line',
      );

      testWidgets('should define chart.data as an alias for config.data', (
        tester,
      ) async {
        final config = <String, Object?>{
          'data': <String, Object?>{
            'labels': <Object?>[],
            'datasets': <Object?>[],
          },
        };
        final chart = acquireChart(config);

        expect(chart.data, same(config['data']));

        chart.data = <String, Object?>{
          'labels': <Object?>[1, 2, 3],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[4, 5, 6],
            },
          ],
        };

        expect(config['data'], same(chart.data));
        expect(jsGet(config['data'], 'labels'), [1, 2, 3]);
        expect(
          jsGet(jsGet(jsGet(config['data'], 'datasets'), 0), 'data'),
          [4, 5, 6],
        );

        config['data'] = <String, Object?>{
          'labels': <Object?>[7, 8, 9],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[10, 11, 12],
            },
          ],
        };

        expect(chart.data, same(config['data']));
        expect(jsGet(chart.data, 'labels'), [7, 8, 9]);
        expect(
          jsGet(jsGet(jsGet(chart.data, 'datasets'), 0), 'data'),
          [10, 11, 12],
        );
      });

      test(
        'should initialize config with default interaction options',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should initialize config with default hover options',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should override default options',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should initialize config with default dataset options',
        () {},
        skip: 'blocked: controller.pie',
      );

      test(
        'should override axis positions that are incorrect',
        () {},
        skip: 'blocked: scale.category',
      );

      test(
        'should throw an error if the chart type is incorrect',
        () {},
        skip: 'blocked: scale.linear',
      );

      testWidgets('should initialize the data object', (tester) async {
        final chart = acquireChart(<String, Object?>{'type': 'bar'});
        expect(
          chart.data,
          _objectContaining({'labels': <Object?>[], 'datasets': <Object?>[]}),
        );
        chart.data = <String, Object?>{};
        expect(
          chart.data,
          _objectContaining({'labels': <Object?>[], 'datasets': <Object?>[]}),
        );
        chart.data = null;
        expect(
          chart.data,
          _objectContaining({'labels': <Object?>[], 'datasets': <Object?>[]}),
        );
        chart.data = undefined;
        expect(
          chart.data,
          _objectContaining({'labels': <Object?>[], 'datasets': <Object?>[]}),
        );
      });

      group('should disable hover', () {
        testWidgets('when options.hover=false', (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'options': <String, Object?>{'hover': false},
          });
          expect(chart.options['hover'], isFalse);
        });

        testWidgets(
          'when options.interaction=false and options.hover is not defined',
          (tester) async {
            final chart = acquireChart(<String, Object?>{
              'type': 'line',
              'options': <String, Object?>{'interaction': false},
            });
            expect(chart.options['hover'], isFalse);
          },
        );

        testWidgets(
          'when options.interaction=false and options.hover is defined',
          (tester) async {
            final chart = acquireChart(<String, Object?>{
              'type': 'line',
              'options': <String, Object?>{
                'interaction': false,
                'hover': <String, Object?>{'mode': 'nearest'},
              },
            });
            expect(chart.options['hover'], isFalse);
          },
        );
      });

      test(
        'should activate element on hover',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should handle changing the events at runtime',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should activate element on hover when minPadding pixels outside '
        'chart area',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should not activate elements when hover is disabled',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should not change the active elements when outside chartArea, except '
        'for mouseout',
        () {},
        skip: 'blocked: plugin.tooltip',
      );
    });

    group('when merging scale options', () {
      // :400-419 the beforeEach and afterEach merge and delete keys of
      // Chart.defaults.scale and Chart.defaults.scales.logarithmic. They come
      // with the bodies: the logarithmic scale is a module of phase 6.

      test(
        'should default to "category" for x scales and "linear" for y scales',
        () {},
        skip: 'blocked: scale.category',
      );

      test(
        'should correctly apply defaults on central scale',
        () {},
        skip: 'blocked: scale.logarithmic',
      );

      test(
        'should correctly apply defaults on xy scales',
        () {},
        skip: 'blocked: scale.logarithmic',
      );

      test(
        'should not alter defaults when merging config',
        () {},
        skip: 'blocked: controller.line',
      );

      // :536 and :566 give `data: []`. An array data gives a new Map (row
      // adapt-config-objects), and no Chart.js code reads the items of the
      // array. Thus the two cases need no diverges skip when their scale is
      // ported.
      test(
        'should ignore proxy passed as scale options',
        () {},
        skip: 'blocked: scale.category',
      );

      test(
        'should ignore array passed as scale options',
        () {},
        skip: 'blocked: scale.logarithmic',
      );
    });

    group('Updating options', () {
      // :584 the config has `data: []`. Upstream writes `datasets` and
      // `labels` into the array. The port gives a new Map (row
      // adapt-config-objects). The case reads only the options.
      testWidgets('update should result to same set of options as construct', (
        tester,
      ) async {
        final chart = acquireChart({
          'type': 'line',
          'data': <Object?>[],
          'options': <String, Object?>{
            'animation': false,
            'locale': 'en-US',
            'responsive': false,
          },
        });
        final options = chart.options;
        chart
          ..options = <String, Object?>{
            'animation': false,
            'locale': 'en-US',
            'responsive': false,
          }
          ..update();
        expect(chart.options, toEqualOptions(options));
      });
    });

    group('config.options.responsive: true (maintainAspectRatio: false)', () {
      testWidgets('should fill parent width and height', (tester) async {
        final chart = acquireChart(
          <String, Object?>{
            'options': <String, Object?>{
              'responsive': true,
              'maintainAspectRatio': false,
            },
          },
          <String, Object?>{
            'canvas': <String, Object?>{'style': 'width: 150px; height: 245px'},
            'wrapper': <String, Object?>{
              'style': 'width: 300px; height: 350px',
            },
          },
        );

        expect(
          chart,
          toBeChartOfSize({'dw': 300, 'dh': 350, 'rw': 300, 'rh': 350}),
        );
      });

      testWidgets('should call onResize with correct arguments and context', (
        tester,
      ) async {
        var count = 0;
        var correctThis = false;
        final size = <String, Object?>{'width': 0, 'height': 0};
        acquireChart(
          <String, Object?>{
            'options': <String, Object?>{
              'responsive': true,
              'maintainAspectRatio': false,
              // `onResize(chart, newSize)` reads `this`. `newSize` is the
              // record of `getMaximumSize`.
              'onResize': JsFunction((
                Object? self,
                Object? chart,
                Object? newSize,
              ) {
                count++;
                correctThis = identical(self, chart);
                final (:width, :height) =
                    newSize! as ({double width, double height});
                size['width'] = width;
                size['height'] = height;
              }),
            },
          },
          <String, Object?>{
            'canvas': <String, Object?>{'style': 'width: 150px; height: 245px'},
            'wrapper': <String, Object?>{
              'style': 'width: 300px; height: 350px',
            },
          },
        );

        expect(count, 1);
        expect(correctThis, isTrue);
        expect(size, {'width': 300, 'height': 350});
      });

      testWidgets('should resize the canvas when parent width changes', (
        tester,
      ) async {
        await waitForDone((done) {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': false,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{'style': ''},
              'wrapper': <String, Object?>{
                'style': 'width: 300px; height: 350px; position: relative',
              },
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 300, 'dh': 350, 'rw': 300, 'rh': 350}),
          );

          final wrapper = chart.canvas!.parentElement!;
          waitForResize(chart, () {
            expect(
              chart,
              toBeChartOfSize({'dw': 455, 'dh': 350, 'rw': 455, 'rh': 350}),
            );

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 150, 'dh': 350, 'rw': 150, 'rh': 350}),
              );

              done();
            });
            wrapper.style.width = '150px';
          });
          wrapper.style.width = '455px';
        });
      });

      testWidgets(
        'should restore the original size when parent became invisible',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': false,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': ''},
                'wrapper': <String, Object?>{
                  'style': 'width: 300px; height: 350px; position: relative',
                },
              },
            );

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 300, 'dh': 350, 'rw': 300, 'rh': 350}),
              );

              final original = chart.resize;
              chart.resize = ([width, height]) {
                fail('resize should not have been called');
              };

              final wrapper = chart.canvas!.parentElement!;
              wrapper.style.display = 'none';

              setTimeout(() {
                expect(wrapper.clientWidth, 0);
                expect(wrapper.clientHeight, 0);

                expect(
                  chart,
                  toBeChartOfSize({
                    'dw': 300,
                    'dh': 350,
                    'rw': 300,
                    'rh': 350,
                  }),
                );

                chart.resize = original;

                waitForResize(chart, () {
                  expect(
                    chart,
                    toBeChartOfSize({
                      'dw': 300,
                      'dh': 350,
                      'rw': 300,
                      'rh': 350,
                    }),
                  );

                  done();
                });
                wrapper.style.display = 'block';
              }, 200);
            });
          });
        },
      );

      testWidgets(
        'should resize the canvas when parent is RTL and width changes',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': false,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': ''},
                'wrapper': <String, Object?>{
                  'style':
                      'width: 300px; height: 350px; position: relative; '
                      'direction: rtl',
                },
              },
            );

            expect(
              chart,
              toBeChartOfSize({'dw': 300, 'dh': 350, 'rw': 300, 'rh': 350}),
            );

            final wrapper = chart.canvas!.parentElement!;
            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 455, 'dh': 350, 'rw': 455, 'rh': 350}),
              );

              waitForResize(chart, () {
                expect(
                  chart,
                  toBeChartOfSize({
                    'dw': 150,
                    'dh': 350,
                    'rw': 150,
                    'rh': 350,
                  }),
                );

                done();
              });
              wrapper.style.width = '150px';
            });
            wrapper.style.width = '455px';
          });
        },
      );

      testWidgets('should resize the canvas when parent height changes', (
        tester,
      ) async {
        await waitForDone((done) {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': false,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{'style': ''},
              'wrapper': <String, Object?>{
                'style': 'width: 300px; height: 350px; position: relative',
              },
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 300, 'dh': 350, 'rw': 300, 'rh': 350}),
          );

          final wrapper = chart.canvas!.parentElement!;
          waitForResize(chart, () {
            expect(
              chart,
              toBeChartOfSize({'dw': 300, 'dh': 455, 'rw': 300, 'rh': 455}),
            );

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 300, 'dh': 150, 'rw': 300, 'rh': 150}),
              );

              done();
            });
            wrapper.style.height = '150px';
          });
          wrapper.style.height = '455px';
        });
      });

      testWidgets(
        'should not include parent padding when resizing the canvas',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'type': 'line',
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': false,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': ''},
                'wrapper': <String, Object?>{
                  'style':
                      'padding: 50px; width: 320px; height: 350px; '
                      'position: relative',
                },
              },
            );

            expect(
              chart,
              toBeChartOfSize({'dw': 320, 'dh': 350, 'rw': 320, 'rh': 350}),
            );

            final wrapper = chart.canvas!.parentElement!;
            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 455, 'dh': 355, 'rw': 455, 'rh': 355}),
              );

              done();
            });
            wrapper.style
              ..height = '355px'
              ..width = '455px';
          });
        },
      );

      testWidgets(
        'should resize the canvas when the canvas display style changes from '
        '"none" to "block"',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': false,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': 'display: none;'},
                'wrapper': <String, Object?>{
                  'style': 'width: 320px; height: 350px',
                },
              },
            );

            final canvas = chart.canvas!;
            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 320, 'dh': 350, 'rw': 320, 'rh': 350}),
              );

              done();
            });
            canvas.style.display = 'block';
          });
        },
      );

      testWidgets(
        'should resize the canvas when the wrapper display style changes from '
        '"none" to "block"',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': false,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': ''},
                'wrapper': <String, Object?>{
                  'style': 'display: none; width: 460px; height: 380px',
                },
              },
            );

            final wrapper = chart.canvas!.parentElement!;
            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 460, 'dh': 380, 'rw': 460, 'rh': 380}),
              );

              done();
            });
            wrapper.style.display = 'block';
          });
        },
      );

      testWidgets(
        'should resize the canvas when the wrapper has display style changes '
        'from "none" to "block"',
        (tester) async {
          await waitForDone((done) {
            // https://github.com/chartjs/Chart.js/issues/4659
            final chart = acquireChart(
              <String, Object?>{
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': false,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': ''},
                'wrapper': <String, Object?>{
                  'style':
                      'display: none; max-width: 600px; max-height: 400px;',
                },
              },
            );

            final wrapper = chart.canvas!.parentElement!;
            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 600, 'dh': 300, 'rw': 600, 'rh': 300}),
              );

              done();
            });
            wrapper.style.display = 'block';
          });
        },
      );

      // https://github.com/chartjs/Chart.js/issues/5485
      testWidgets(
        'should resize the canvas when the devicePixelRatio changes',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': false,
                  'devicePixelRatio': 1,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': ''},
                'wrapper': <String, Object?>{
                  'style': 'width: 400px; height: 200px; position: relative',
                },
              },
            );

            expect(
              chart,
              toBeChartOfSize({'dw': 400, 'dh': 200, 'rw': 400, 'rh': 200}),
            );

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 400, 'dh': 200, 'rw': 800, 'rh': 400}),
              );

              done();
            });
            chart.options['devicePixelRatio'] = 2;
            chart.resize();
          });
        },
      );

      // https://github.com/chartjs/Chart.js/issues/3790
      testWidgets(
        'should resize the canvas if attached to the DOM after construction',
        (tester) async {
          await waitForDone((done) {
            final canvas = document.createElement<HTMLCanvasElement>('canvas');
            final wrapper = document.createElement<HarnessElement>('div');
            final body = document.body;
            final chart = Chart(canvas, <String, Object?>{
              'type': 'line',
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': false,
              },
            });

            expect(
              chart,
              toBeChartOfSize({'dw': 0, 'dh': 0, 'rw': 0, 'rh': 0}),
            );
            expect(chart.chartArea, isNull);

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 455, 'dh': 355, 'rw': 455, 'rh': 355}),
              );

              expect(chart.chartArea, isNotNull);

              body.removeChild(wrapper);
              chart.destroy();
              done();
            });

            wrapper.style.cssText = 'width: 455px; height: 355px';
            wrapper.appendChild(canvas);
            body.appendChild(wrapper);
          });
        },
      );

      testWidgets(
        'should resize the canvas when attached to a different parent',
        (tester) async {
          await waitForDone((done) {
            final canvas = document.createElement<HTMLCanvasElement>('canvas');
            final wrapper = document.createElement<HarnessElement>('div');
            final body = document.body;
            final chart = Chart(canvas, <String, Object?>{
              'type': 'line',
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': false,
              },
            });

            expect(
              chart,
              toBeChartOfSize({'dw': 0, 'dh': 0, 'rw': 0, 'rh': 0}),
            );

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 455, 'dh': 355, 'rw': 455, 'rh': 355}),
              );

              final target = document.createElement<HarnessElement>('div');

              waitForResize(chart, () {
                expect(
                  chart,
                  toBeChartOfSize({'dw': 640, 'dh': 480, 'rw': 640, 'rh': 480}),
                );

                body
                  ..removeChild(wrapper)
                  ..removeChild(target);
                chart.destroy();
                done();
              });

              target.style.cssText = 'width: 640px; height: 480px';
              target.appendChild(canvas);
              body.appendChild(target);
            });

            wrapper.style.cssText = 'width: 455px; height: 355px';
            wrapper.appendChild(canvas);
            body.appendChild(wrapper);
          });
        },
      );

      // https://github.com/chartjs/Chart.js/issues/3521
      testWidgets(
        'should resize the canvas after the wrapper has been re-attached to '
        'the DOM',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': false,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': ''},
                'wrapper': <String, Object?>{
                  'style': 'width: 320px; height: 350px',
                },
              },
            );

            expect(
              chart,
              toBeChartOfSize({'dw': 320, 'dh': 350, 'rw': 320, 'rh': 350}),
            );

            final wrapper = chart.canvas!.parentElement!;
            final parent = wrapper.parentNode!;

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 320, 'dh': 355, 'rw': 320, 'rh': 355}),
              );

              waitForResize(chart, () {
                expect(
                  chart,
                  toBeChartOfSize({'dw': 455, 'dh': 355, 'rw': 455, 'rh': 355}),
                );

                done();
              });

              parent.removeChild(wrapper);
              wrapper.style.width = '455px';
              parent.appendChild(wrapper);
            });

            parent.removeChild(wrapper);
            setTimeout(
              () {
                parent.appendChild(wrapper);
                wrapper.style.height = '355px';
              },
              // The upstream text passes the delay 0.
              // ignore: avoid_redundant_argument_values
              0,
            );
          });
        },
      );

      // https://github.com/chartjs/Chart.js/issues/9875
      testWidgets('should detect detach/attach in series', (tester) async {
        await waitForDone((done) {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': false,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{'style': ''},
              'wrapper': <String, Object?>{
                'style': 'width: 320px; height: 350px',
              },
            },
          );

          final wrapper = chart.canvas!.parentElement!;
          final parent = wrapper.parentNode!;

          waitForResize(chart, () {
            expect(
              chart,
              toBeChartOfSize({'dw': 320, 'dh': 350, 'rw': 320, 'rh': 350}),
            );

            done();
          });

          parent
            ..removeChild(wrapper)
            ..appendChild(wrapper);
        });
      });

      testWidgets('should detect detach/attach/detach in series', (
        tester,
      ) async {
        await waitForDone((done) {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': false,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{'style': ''},
              'wrapper': <String, Object?>{
                'style': 'width: 320px; height: 350px',
              },
            },
          );

          final wrapper = chart.canvas!.parentElement!;
          final parent = wrapper.parentNode!;

          waitForResize(chart, () {
            fail('Failed');
          });

          parent
            ..removeChild(wrapper)
            ..appendChild(wrapper)
            ..removeChild(wrapper);

          setTimeout(() {
            expect(chart.attached, isFalse);
            done();
          }, 100);
        });
      });

      testWidgets('should detect attach/detach in series', (tester) async {
        await waitForDone((done) {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': false,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{'style': ''},
              'wrapper': <String, Object?>{
                'style': 'width: 320px; height: 350px',
              },
            },
          );

          final wrapper = chart.canvas!.parentElement!;
          final parent = wrapper.parentNode!;

          // The upstream statements stay apart.
          // ignore: cascade_invocations
          parent.removeChild(wrapper);

          setTimeout(() {
            expect(chart.attached, isFalse);

            waitForResize(chart, () {
              fail('Failed');
            });

            parent
              ..appendChild(wrapper)
              ..removeChild(wrapper);

            setTimeout(() {
              expect(chart.attached, isFalse);

              done();
            }, 100);
          }, 100);
        });
      });

      // https://github.com/chartjs/Chart.js/issues/4737
      testWidgets('should resize the canvas when re-creating the chart', (
        tester,
      ) async {
        await waitForDone((done) {
          var chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{'responsive': true},
            },
            <String, Object?>{
              'wrapper': <String, Object?>{'style': 'width: 320px'},
            },
          );

          final wrapper = chart.canvas!.parentElement!;

          waitForResize(chart, () {
            final canvas = chart.canvas!;
            expect(
              chart,
              toBeChartOfSize({'dw': 320, 'dh': 320, 'rw': 320, 'rh': 320}),
            );

            chart.destroy();
            chart = Chart(canvas, <String, Object?>{
              'type': 'line',
              'options': <String, Object?>{'responsive': true},
            });

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 455, 'dh': 455, 'rw': 455, 'rh': 455}),
              );

              chart.destroy();
              document.body.removeChild(wrapper);
              done();
            });
            canvas.parentElement!.style.width = '455px';
            canvas.parentElement!.style.height = '455px';
          });
        });
      });

      testWidgets(
        'should resize the canvas if attached to the DOM after construction '
        'with multiple parents',
        (tester) async {
          await waitForDone((done) {
            final canvas = document.createElement<HTMLCanvasElement>('canvas');
            final wrapper = document.createElement<HarnessElement>('div');
            final wrapper2 = document.createElement<HarnessElement>('div');
            final wrapper3 = document.createElement<HarnessElement>('div');
            final body = document.body;

            final chart = Chart(canvas, <String, Object?>{
              'type': 'line',
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': false,
              },
            });

            expect(
              chart,
              toBeChartOfSize({'dw': 0, 'dh': 0, 'rw': 0, 'rh': 0}),
            );
            expect(chart.chartArea, isNull);

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 455, 'dh': 355, 'rw': 455, 'rh': 355}),
              );

              expect(chart.chartArea, isNotNull);

              body.removeChild(wrapper3);
              chart.destroy();
              done();
            });

            wrapper3.appendChild(wrapper2);
            wrapper2.appendChild(wrapper);
            wrapper.style.cssText = 'width: 455px; height: 355px';
            wrapper.appendChild(canvas);
            body.appendChild(wrapper3);
          });
        },
      );
    });

    group('config.options.responsive: true (maintainAspectRatio: true)', () {
      testWidgets(
        'should resize the canvas with correct aspect ratio when parent width '
        'changes',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'type': 'line', // AR == 2
                'options': <String, Object?>{
                  'responsive': true,
                  'maintainAspectRatio': true,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': ''},
                'wrapper': <String, Object?>{
                  'style': 'width: 300px; height: 350px; position: relative',
                },
              },
            );

            expect(
              chart,
              toBeChartOfSize({'dw': 300, 'dh': 150, 'rw': 300, 'rh': 150}),
            );

            final wrapper = chart.canvas!.parentElement!;
            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 450, 'dh': 225, 'rw': 450, 'rh': 225}),
              );

              waitForResize(chart, () {
                expect(
                  chart,
                  toBeChartOfSize({'dw': 150, 'dh': 75, 'rw': 150, 'rh': 75}),
                );

                done();
              });
              wrapper.style.width = '150px';
            });
            wrapper.style.width = '450px';
          });
        },
      );

      testWidgets('should maintain aspect ratio when parent height changes', (
        tester,
      ) async {
        await waitForDone((done) {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': true,
                'maintainAspectRatio': true,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{'style': ''},
              'wrapper': <String, Object?>{
                'style': 'width: 320px; height: 350px; position: relative',
              },
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 320, 'dh': 160, 'rw': 320, 'rh': 160}),
          );

          final wrapper = chart.canvas!.parentElement!;
          waitForResize(chart, () {
            expect(
              chart,
              toBeChartOfSize({'dw': 320, 'dh': 160, 'rw': 320, 'rh': 160}),
            );

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 300, 'dh': 150, 'rw': 300, 'rh': 150}),
              );

              done();
            });
            wrapper.style.height = '150px';
          });
          wrapper.style.height = '455px';
        });
      });
    });

    group('Retina scale (a.k.a. device pixel ratio)', () {
      late double devicePixelRatio;

      setUp(() {
        devicePixelRatio = window.devicePixelRatio;
        window.devicePixelRatio = 3;
      });

      tearDown(() {
        window.devicePixelRatio = devicePixelRatio;
      });

      // see https://github.com/chartjs/Chart.js/issues/3575
      testWidgets(
        'should scale the render size but not the "implicit" display size',
        (tester) async {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{'responsive': false},
            },
            <String, Object?>{
              'canvas': <String, Object?>{'width': 320, 'height': 240},
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 320, 'dh': 240, 'rw': 960, 'rh': 720}),
          );
        },
      );

      testWidgets(
        'should scale the render size but not the "explicit" display size',
        (tester) async {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{'responsive': false},
            },
            <String, Object?>{
              'canvas': <String, Object?>{
                'style': 'width: 320px; height: 240px',
              },
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 320, 'dh': 240, 'rw': 960, 'rh': 720}),
          );
        },
      );
    });

    group('config.options.devicePixelRatio', () {
      late double devicePixelRatio;

      setUp(() {
        devicePixelRatio = window.devicePixelRatio;
        window.devicePixelRatio = 1;
      });

      tearDown(() {
        window.devicePixelRatio = devicePixelRatio;
      });

      // see https://github.com/chartjs/Chart.js/issues/3575
      testWidgets(
        'should scale the render size but not the "implicit" display size',
        (tester) async {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': false,
                'devicePixelRatio': 3,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{'width': 320, 'height': 240},
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 320, 'dh': 240, 'rw': 960, 'rh': 720}),
          );
        },
      );

      testWidgets(
        'should scale the render size but not the "explicit" display size',
        (tester) async {
          final chart = acquireChart(
            <String, Object?>{
              'options': <String, Object?>{
                'responsive': false,
                'devicePixelRatio': 3,
              },
            },
            <String, Object?>{
              'canvas': <String, Object?>{
                'style': 'width: 320px; height: 240px',
              },
            },
          );

          expect(
            chart,
            toBeChartOfSize({'dw': 320, 'dh': 240, 'rw': 960, 'rh': 720}),
          );
        },
      );
    });

    group('config.options.aspectRatio', () {
      testWidgets(
        'should resize the canvas when the aspectRatio option changes',
        (tester) async {
          await waitForDone((done) {
            final chart = acquireChart(
              <String, Object?>{
                'options': <String, Object?>{
                  'responsive': true,
                  'aspectRatio': 1,
                },
              },
              <String, Object?>{
                'canvas': <String, Object?>{'style': '', 'width': 400},
              },
            );

            expect(
              chart,
              toBeChartOfSize({'dw': 400, 'dh': 400, 'rw': 400, 'rh': 400}),
            );

            waitForResize(chart, () {
              expect(
                chart,
                toBeChartOfSize({'dw': 400, 'dh': 200, 'rw': 400, 'rh': 200}),
              );

              done();
            });
            chart.options['aspectRatio'] = 2;
            chart.resize();
          });
        },
      );
    });

    group('controller.reset', () {
      test(
        'should reset the chart elements',
        () {},
        skip: 'blocked: plugin.legend',
      );
    });

    group('config update', () {
      test('should update options', () {}, skip: 'blocked: controller.line');

      test(
        'should update scales options',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should update scales options from new object',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should remove discarded scale',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should update tooltip options',
        () {},
        skip: 'blocked: plugin.tooltip',
      );

      test(
        'should update the tooltip on update',
        () {},
        skip: 'blocked: plugin.tooltip',
      );

      test(
        'should update the metadata',
        () {},
        skip: 'blocked: controller.line',
      );
    });

    group('plugin.extensions', () {
      test(
        'should notify plugin in correct order',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should notify initially disabled plugin in correct order',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should not notify before/afterDatasetDraw if dataset is hidden',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should not crash when accessing options of a blank inline plugin',
        () {},
        skip: 'blocked: controller.line',
      );
    });

    group('metasets', () {
      // :1955-1975 the beforeEach acquires a chart, and the afterEach reads
      // it. They come with the bodies as local functions (Chart.js ADR 0022,
      // section 2).

      test(
        'should build metasets array in order',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should build sorted metasets array in correct order',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should be moved when datasets are removed from beginning',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should be moved when datasets are removed from middle',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should be moved when datasets are inserted',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should be replaced when dataset is replaced',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should update properly when dataset locations are swapped',
        () {},
        skip: 'blocked: controller.line',
      );
    });

    group('_destroyDatasetMeta', () {
      // :2053-2065 the beforeEach acquires a chart. It comes with the body as
      // a local function (Chart.js ADR 0022, section 2).

      test(
        'cleans up metasets when the chart is destroyed',
        () {},
        skip: 'blocked: controller.line',
      );
    });

    group('data visibility', () {
      test('should hide a dataset', () {}, skip: 'blocked: controller.line');

      test(
        'should toggle data visibility by index',
        () {},
        skip: 'blocked: controller.pie',
      );

      test(
        'should maintain data visibility indices when data changes',
        () {},
        skip: 'blocked: controller.pie',
      );

      test(
        'should leave data visibility indices intact when data changes in '
        'non-uniform way',
        () {},
        skip: 'blocked: controller.pie',
      );
    });

    group('isDatasetVisible', () {
      test(
        'should return false if index is out of bounds',
        () {},
        skip: 'blocked: controller.line',
      );
    });

    group('getChart', () {
      test(
        'should get the chart from the canvas ID',
        () {},
        skip: 'n/a: Flutter has no DOM element ids',
      );

      test(
        'should get the chart from an HTMLCanvasElement',
        () {},
        skip: 'blocked: controller.pie',
      );

      test(
        'should get the chart from an CanvasRenderingContext2D',
        () {},
        skip: 'blocked: controller.pie',
      );

      test(
        'should return undefined when a chart is not found or bad data is '
        'provided',
        () {
          expect(Chart.getChart(1), isNull);
        },
      );
    });

    group('active elements', () {
      test(
        'should set the active elements',
        () {},
        skip: 'blocked: controller.pie',
      );
    });

    test(
      'should not replace the user set active elements by event replay',
      () {},
      skip: 'blocked: controller.line',
    );

    group('platform', () {
      testWidgets('should use the platform constructor provided in config', (
        tester,
      ) async {
        // `Chart.platforms.BasicPlatform` (src/index.umd.ts:41) is the class
        // value `BasicPlatform.jsClass` (Chart.js ADR 0020, section 3).
        final chart = acquireChart(<String, Object?>{
          'platform': BasicPlatform.jsClass,
          'type': 'line',
        });
        expect(chart.platform, isA<BasicPlatform>());
      });
    });
  });
}
