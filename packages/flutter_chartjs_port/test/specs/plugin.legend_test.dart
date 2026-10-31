// Ported from Chart.js v4.6.1 test/specs/plugin.legend.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.color.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/color.dart' show Color;
import 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// `Chart` is the class of core.controller.dart, with the static members
// `Chart.registry` and `Chart.defaults`. `window.Chart.helpers.color` is
// `color` of helpers.color.dart. `toEqual` is jasmineEquals of
// test/support/jasmine.dart, and `jasmine.any(Function)` is anyFunction.
// `toEqualOptions` is the matcher of chartjs_test_utils.
//
// Each chart case is a `testWidgets` case with the harness of Chart.js ADR
// 0022, section 2. `chart.legend` is the field of `Chart`: Dart `null`
// stands for JS `undefined`. The spec reads `legendItems` through
// `types.LegendElement` and `legendHitBoxes` through a cast to `Legend`
// (Chart.js ADR 0038, section 6). A hit box is a Map with the upstream
// keys. A write into `chart.options` is the write through `operator []=`
// of the option resolver, the `set` trap of upstream.
// `jasmine.triggerMouseEvent` is triggerMouseEvent of chartjs_test_utils
// (Chart.js ADR 0022, section 6).

/// `chart.legend.legendHitBoxes`.
List<JsObjectFace> _hitBoxes(Chart chart) =>
    (chart.legend! as Legend).legendHitBoxes;

/// `chart.options.plugins`, the option resolver of the plugins.
JsObjectFace _pluginOptions(Chart chart) =>
    jsGet(chart.options, 'plugins')! as JsObjectFace;

/// `chart.options.plugins.legend`, the option resolver of the legend.
JsObjectFace _legendOptions(Chart chart) =>
    jsGet(_pluginOptions(chart), 'legend')! as JsObjectFace;

/// `Chart.defaults.plugins.legend`.
JsObjectFace _legendDefaults() =>
    jsGet(jsGet(Chart.defaults, 'plugins'), 'legend')! as JsObjectFace;

/// The point `{x, y}` at the center of the hit box [hb] (:1094-1097,
/// :1136-1139, :1176-1179).
AnyObject _center(JsObjectFace hb) => <String, Object?>{
  'x': (hb['left']! as double) + ((hb['width']! as double) / 2),
  'y': (hb['top']! as double) + ((hb['height']! as double) / 2),
};

/// The three datasets of `should update bar chart correctly` (:39-57),
/// `should filter items` without its extra keys.
List<Object?> _barDatasets() => <Object?>[
  <String, Object?>{
    'label': 'dataset1',
    'backgroundColor': '#f31',
    'borderCapStyle': 'butt',
    'borderDash': <Object?>[2, 2],
    'borderDashOffset': 5.5,
    'data': <Object?>[],
  },
  <String, Object?>{
    'label': 'dataset2',
    'hidden': true,
    'borderJoinStyle': 'miter',
    'data': <Object?>[],
  },
  <String, Object?>{
    'label': 'dataset3',
    'borderWidth': 10,
    'borderColor': 'green',
    'pointStyle': 'crossRot',
    'data': <Object?>[],
  },
];

/// The three datasets of the line cases (:117-136, :196-215, :358-377).
List<Object?> _lineDatasets() => <Object?>[
  <String, Object?>{
    'label': 'dataset1',
    'backgroundColor': '#f31',
    'borderCapStyle': 'round',
    'borderDash': <Object?>[2, 2],
    'borderDashOffset': 5.5,
    'data': <Object?>[],
  },
  <String, Object?>{
    'label': 'dataset2',
    'hidden': true,
    'borderJoinStyle': 'round',
    'data': <Object?>[],
  },
  <String, Object?>{
    'label': 'dataset3',
    'borderWidth': 10,
    'borderColor': 'green',
    'pointStyle': 'crossRot',
    'fill': false,
    'data': <Object?>[],
  },
];

/// A legend item with the values of the spec (each key of :62-77).
AnyObject _item({
  required String text,
  required Object? fillStyle,
  required bool hidden,
  required num lineWidth,
  required Object? strokeStyle,
  required num datasetIndex,
  Object? borderRadius = undefined,
  Object? lineCap = undefined,
  Object? lineDash = undefined,
  Object? lineDashOffset = undefined,
  Object? lineJoin = undefined,
  Object? pointStyle = undefined,
  Object? rotation = undefined,
}) => <String, Object?>{
  'text': text,
  'borderRadius': borderRadius,
  'fillStyle': fillStyle,
  'fontColor': '#666',
  'hidden': hidden,
  'lineCap': lineCap,
  'lineDash': lineDash,
  'lineDashOffset': lineDashOffset,
  'lineJoin': lineJoin,
  'lineWidth': lineWidth,
  'strokeStyle': strokeStyle,
  'pointStyle': pointStyle,
  'rotation': rotation,
  'textAlign': undefined,
  'datasetIndex': datasetIndex,
};

/// The items of the line cases, dataset 1 to 3 (:141-189).
AnyObject _lineItem1() => _item(
  text: 'dataset1',
  fillStyle: '#f31',
  hidden: false,
  lineCap: 'round',
  lineDash: <Object?>[2, 2],
  lineDashOffset: 5.5,
  lineJoin: 'miter',
  lineWidth: 3,
  strokeStyle: 'rgba(0,0,0,0.1)',
  datasetIndex: 0,
);

AnyObject _lineItem2() => _item(
  text: 'dataset2',
  fillStyle: 'rgba(0,0,0,0.1)',
  hidden: true,
  lineCap: 'butt',
  lineDash: <Object?>[],
  lineDashOffset: 0,
  lineJoin: 'round',
  lineWidth: 3,
  strokeStyle: 'rgba(0,0,0,0.1)',
  datasetIndex: 1,
);

AnyObject _lineItem3() => _item(
  text: 'dataset3',
  fillStyle: 'rgba(0,0,0,0.1)',
  hidden: false,
  lineCap: 'butt',
  lineDash: <Object?>[],
  lineDashOffset: 0,
  lineJoin: 'miter',
  lineWidth: 10,
  strokeStyle: 'green',
  datasetIndex: 2,
);

/// A line chart of four labels and one dataset with the legend options
/// [legendOptions] (the config update and callbacks cases).
AnyObject _lineChart([Object? legendOptions]) => <String, Object?>{
  'type': 'line',
  'data': <String, Object?>{
    'labels': <Object?>['A', 'B', 'C', 'D'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[10, 20, 30, 100],
      },
    ],
  },
  if (legendOptions != null)
    'options': <String, Object?>{
      'plugins': <String, Object?>{'legend': legendOptions},
    },
};

void main() {
  // Test the rectangle element
  group('Legend block tests', () {
    group('auto', fixture.specs('plugin.legend'));

    test('should have the correct default config', () {
      final actual = _legendDefaults();
      final labels = jsGet(actual, 'labels')! as JsObjectFace;
      final title = jsGet(actual, 'title')! as JsObjectFace;
      // jasmine.any(Function): each function value of the expected object.
      expect(jsGet(actual, 'onClick'), anyFunction);
      expect(jsGet(labels, 'color'), anyFunction);
      expect(jsGet(labels, 'generateLabels'), anyFunction);
      expect(jsGet(title, 'color'), anyFunction);
      expect(
        actual,
        jasmineEquals(<String, Object?>{
          'display': true,
          'position': 'top',
          'align': 'center',
          'fullSize': true,
          'reverse': false,
          'weight': 1000,

          // a callback that will handle
          'onClick': jsGet(actual, 'onClick'),
          'onHover': null,
          'onLeave': null,

          'labels': <String, Object?>{
            'color': jsGet(labels, 'color'),
            'boxWidth': 40,
            'padding': 10,
            'generateLabels': jsGet(labels, 'generateLabels'),
          },

          'title': <String, Object?>{
            'color': jsGet(title, 'color'),
            'display': false,
            'position': 'center',
            'text': '',
          },
        }),
      );
    });

    testWidgets('should update bar chart correctly', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': _barDatasets(),
          'labels': <Object?>[],
        },
      });

      expect(
        chart.legend!.legendItems,
        jasmineEquals(<Object?>[
          _item(
            text: 'dataset1',
            fillStyle: '#f31',
            hidden: false,
            lineWidth: 0,
            strokeStyle: 'rgba(0,0,0,0.1)',
            datasetIndex: 0,
          ),
          _item(
            text: 'dataset2',
            fillStyle: 'rgba(0,0,0,0.1)',
            hidden: true,
            lineWidth: 0,
            strokeStyle: 'rgba(0,0,0,0.1)',
            datasetIndex: 1,
          ),
          _item(
            text: 'dataset3',
            fillStyle: 'rgba(0,0,0,0.1)',
            hidden: false,
            lineWidth: 10,
            strokeStyle: 'green',
            pointStyle: 'crossRot',
            datasetIndex: 2,
          ),
        ]),
      );
    });

    testWidgets('should update line chart correctly', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': _lineDatasets(),
          'labels': <Object?>[],
        },
      });

      expect(
        chart.legend!.legendItems,
        jasmineEquals(<Object?>[_lineItem1(), _lineItem2(), _lineItem3()]),
      );
    });

    testWidgets('should reverse correctly', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': _lineDatasets(),
          'labels': <Object?>[],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{
            'legend': <String, Object?>{'reverse': true},
          },
        },
      });

      expect(
        chart.legend!.legendItems,
        jasmineEquals(<Object?>[_lineItem3(), _lineItem2(), _lineItem1()]),
      );
    });

    testWidgets('should filter items', (tester) async {
      final datasets = _barDatasets();
      (datasets[1]! as AnyObject)['legendHidden'] = true;
      (datasets[2]! as AnyObject)['borderRadius'] = 10;
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{'datasets': datasets, 'labels': <Object?>[]},
        'options': <String, Object?>{
          'plugins': <String, Object?>{
            'legend': <String, Object?>{
              'labels': <String, Object?>{
                'filter': (Object? legendItem, Object? data) {
                  final dataset = jsGetIndex(
                    jsGet(data, 'datasets'),
                    (jsGet(legendItem, 'datasetIndex')! as num).toDouble(),
                  );
                  return !jsTruthy(jsGet(dataset, 'legendHidden'));
                },
              },
            },
          },
        },
      });

      expect(
        chart.legend!.legendItems,
        jasmineEquals(<Object?>[
          _item(
            text: 'dataset1',
            fillStyle: '#f31',
            hidden: false,
            lineWidth: 0,
            strokeStyle: 'rgba(0,0,0,0.1)',
            datasetIndex: 0,
          ),
          _item(
            text: 'dataset3',
            fillStyle: 'rgba(0,0,0,0.1)',
            hidden: false,
            lineWidth: 10,
            strokeStyle: 'green',
            pointStyle: 'crossRot',
            datasetIndex: 2,
          ),
        ]),
      );
    });

    testWidgets('should sort items', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': _lineDatasets(),
          'labels': <Object?>[],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{
            'legend': <String, Object?>{
              'labels': <String, Object?>{
                'sort': (Object? a, Object? b) =>
                    (jsGet(b, 'datasetIndex')! as num) >
                        (jsGet(a, 'datasetIndex')! as num)
                    ? 1
                    : -1,
              },
            },
          },
        },
      });

      expect(
        chart.legend!.legendItems,
        jasmineEquals(<Object?>[_lineItem3(), _lineItem2(), _lineItem1()]),
      );
    });

    testWidgets('should not throw when the label options are missing', (
      tester,
    ) async {
      void makeChart() {
        acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'label': 'dataset1',
                'backgroundColor': '#f31',
                'borderCapStyle': 'butt',
                'borderDash': <Object?>[2, 2],
                'borderDashOffset': 5.5,
                'data': <Object?>[],
              },
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'legend': <String, Object?>{'labels': false},
            },
          },
        });
      }

      expect(makeChart, returnsNormally);
    });

    testWidgets('should not draw legend items outside of the chart bounds', (
      tester,
    ) async {
      final chart = acquireChart(
        <String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              for (final n in [1, 2, 3])
                <String, Object?>{'label': 'dataset$n', 'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'legend': <String, Object?>{'position': 'right'},
            },
          },
        },
        <String, Object?>{
          'canvas': <String, Object?>{'width': 512, 'height': 105},
        },
      );

      // Check some basic assertions about the test setup
      expect(chart.width, 512);
      expect(_hitBoxes(chart).length, 3);

      // Check whether any legend items reach outside the established bounds
      for (final item in _hitBoxes(chart)) {
        expect(
          (item['left']! as double) + (item['width']! as double),
          lessThanOrEqualTo(chart.width),
        );
      }
    });

    testWidgets('should draw legend with multiline labels', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'doughnut',
        'data': <String, Object?>{
          'labels': <Object?>[
            'ABCDE',
            <Object?>['ABCDE', 'ABCDE'],
            <Object?>['Some Text', 'Some Text', 'Some Text'],
            'ABCDE',
          ],
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'test',
              'data': <Object?>[73.42, 18.13, 7.54, 0.9, 0.0025, 1.8e-5],
              'backgroundColor': <Object?>[
                '#0078C2',
                '#56CAF5',
                '#B1E3F9',
                '#FBBC8D',
                '#F6A3BE',
                '#4EC2C1',
              ],
            },
          ],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{
            'legend': <String, Object?>{
              'labels': <String, Object?>{
                'usePointStyle': true,
                'pointStyle': 'rect',
              },
              'position': 'right',
              'align': 'center',
              'maxWidth': 860,
            },
          },
          'aspectRatio': 3,
        },
      });

      // Check some basic assertions about the test setup
      expect(_hitBoxes(chart).length, 4);

      // Check whether any legend items reach outside the established bounds
      for (final item in _hitBoxes(chart)) {
        expect(
          (item['left']! as double) + (item['width']! as double),
          lessThanOrEqualTo(chart.width),
        );
      }
    });

    testWidgets('should draw items with a custom boxHeight', (tester) async {
      final chart = acquireChart(
        <String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{'label': 'dataset1', 'data': <Object?>[]},
            ],
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'legend': <String, Object?>{
                'position': 'right',
                'labels': <String, Object?>{'boxHeight': 40},
              },
            },
          },
        },
        <String, Object?>{
          'canvas': <String, Object?>{'width': 512, 'height': 105},
        },
      );
      final hitBox = _hitBoxes(chart)[0];
      expect(hitBox['height'], 40);
    });

    testWidgets('should pick up the first item when the property is an array', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'dataset1',
              'backgroundColor': <Object?>['#f31', '#666', '#14e'],
              'borderWidth': <Object?>[5, 10, 15],
              'borderColor': <Object?>['red', 'green', 'blue'],
              'data': <Object?>[],
            },
          ],
          'labels': <Object?>[],
        },
      });

      expect(
        chart.legend!.legendItems,
        jasmineEquals(<Object?>[
          _item(
            text: 'dataset1',
            fillStyle: '#f31',
            hidden: false,
            lineWidth: 5,
            strokeStyle: 'red',
            datasetIndex: 0,
          ),
        ]),
      );
    });

    testWidgets('should use the borderRadius in the legend', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'dataset1',
              'backgroundColor': <Object?>['#f31', '#666', '#14e'],
              'borderWidth': <Object?>[5, 10, 15],
              'borderColor': <Object?>['red', 'green', 'blue'],
              'borderRadius': 10,
              'data': <Object?>[],
            },
          ],
          'labels': <Object?>[],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{
            'legend': <String, Object?>{
              'labels': <String, Object?>{'useBorderRadius': true},
            },
          },
        },
      });

      expect(
        chart.legend!.legendItems,
        jasmineEquals(<Object?>[
          _item(
            text: 'dataset1',
            borderRadius: 10,
            fillStyle: '#f31',
            hidden: false,
            lineWidth: 5,
            strokeStyle: 'red',
            datasetIndex: 0,
          ),
        ]),
      );
    });

    testWidgets(
      'should use the value for the first item when the property is a function',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'label': 'dataset1',
                'backgroundColor': (Object? ctx) {
                  final value = _dataValue(ctx);
                  return (color(<String, Object?>{
                    'r': value * 10,
                    'g': 0,
                    'b': 0,
                  }) as Color).rgbString();
                },
                'borderWidth': _dataValue,
                'borderColor': (Object? ctx) {
                  final value = _dataValue(ctx);
                  return (color(<String, Object?>{
                    'r': 255 - value * 10,
                    'g': 0,
                    'b': 0,
                  }) as Color).rgbString();
                },
                'data': <Object?>[5, 10, 15, 20],
              },
            ],
            'labels': <Object?>['A', 'B', 'C', 'D'],
          },
        });

        expect(
          chart.legend!.legendItems,
          jasmineEquals(<Object?>[
            _item(
              text: 'dataset1',
              fillStyle: 'rgb(50, 0, 0)',
              hidden: false,
              lineWidth: 5,
              strokeStyle: 'rgb(205, 0, 0)',
              datasetIndex: 0,
            ),
          ]),
        );
      },
    );

    testWidgets('should draw correctly when usePointStyle is true', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': _pointStyleDatasets(),
          'labels': <Object?>[],
        },
        'options': <String, Object?>{
          'plugins': <String, Object?>{
            'legend': <String, Object?>{
              'labels': <String, Object?>{'usePointStyle': true},
            },
          },
        },
      });

      expect(
        chart.legend!.legendItems,
        jasmineEquals(_pointStyleItems('crossRot')),
      );
    });

    testWidgets(
      'should draw correctly when usePointStyle is true and pointStyle '
      'override is set',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'datasets': _pointStyleDatasets(),
            'labels': <Object?>[],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'legend': <String, Object?>{
                'labels': <String, Object?>{
                  'usePointStyle': true,
                  'pointStyle': 'star',
                },
              },
            },
          },
        });

        expect(
          chart.legend!.legendItems,
          jasmineEquals(_pointStyleItems('star')),
        );
      },
    );

    testWidgets('should not crash when the legend defaults are false', (
      tester,
    ) async {
      final oldDefaults = _legendDefaults();

      Chart.defaults.set(<String, Object?>{
        'plugins': <String, Object?>{'legend': false},
      });

      final chart = acquireChart(<String, Object?>{
        'type': 'doughnut',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'dataset1',
              'data': <Object?>[1, 2, 3, 4],
            },
          ],
          'labels': <Object?>['', '', '', ''],
        },
      });
      expect(chart, isNotNull);

      Chart.defaults.set(<String, Object?>{
        'plugins': <String, Object?>{'legend': oldDefaults},
      });
    });

    testWidgets('should not read onClick from chart options', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'labels': <Object?>['Jan', 'Feb', 'Mar', 'Apr', 'May'],
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'dataset',
              'backgroundColor': 'red',
              'borderColor': 'red',
              'data': <Object?>[120, 23, 24, 45, 51],
            },
          ],
        },
        'options': <String, Object?>{
          'responsive': true,
          'onClick': () {},
          'plugins': <String, Object?>{
            'legend': <String, Object?>{'display': true},
          },
        },
      });
      expect(
        jsGet(chart.legend!.options, 'onClick'),
        same(jsGet(_legendDefaults(), 'onClick')),
      );
    });

    testWidgets('should read labels.color from chart options', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'labels': <Object?>['Jan', 'Feb', 'Mar', 'Apr', 'May'],
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'dataset',
              'backgroundColor': 'red',
              'borderColor': 'red',
              'data': <Object?>[120, 23, 24, 45, 51],
            },
          ],
        },
        'options': <String, Object?>{
          'responsive': true,
          'color': 'green',
          'plugins': <String, Object?>{
            'legend': <String, Object?>{'display': true},
          },
        },
      });
      expect(
        jsGet(jsGet(chart.legend!.options, 'labels'), 'color'),
        'green',
      );
      expect(jsGet(jsGet(chart.legend!.options, 'title'), 'color'), 'green');
    });

    group('config update', () {
      testWidgets('should update the options', (tester) async {
        final chart = acquireChart(
          _lineChart(<String, Object?>{'display': true}),
        );
        expect(jsGet(chart.legend!.options, 'display'), true);

        _legendOptions(chart)['display'] = false;
        chart.update();
        expect(jsGet(chart.legend!.options, 'display'), false);
      });

      testWidgets('should update the associated layout item', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{},
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'legend': <String, Object?>{
                'fullSize': true,
                'position': 'top',
                'weight': 150,
              },
            },
          },
        });

        // `chart.legend` as a layout box, read at each assertion, as
        // upstream does.
        Legend legend() => chart.legend! as Legend;
        expect(legend().fullSize, true);
        expect(legend().position, 'top');
        expect(legend().weight, 150);

        _legendOptions(chart)
          ..['fullSize'] = false
          ..['position'] = 'left'
          ..['weight'] = 42;
        chart.update();

        expect(legend().fullSize, false);
        expect(legend().position, 'left');
        expect(legend().weight, 42);
      });

      testWidgets('should remove the legend if the new options are false', (
        tester,
      ) async {
        final chart = acquireChart(_lineChart());
        expect(chart.legend, isNotNull);

        _pluginOptions(chart)['legend'] = false;
        chart.update();
        expect(chart.legend, isNull);
      });

      testWidgets(
        'should create the legend if the legend options are changed to exist',
        (tester) async {
          final chart = acquireChart(_lineChart(false));
          expect(chart.legend, isNull);

          _pluginOptions(chart)['legend'] = <String, Object?>{};
          chart.update();
          expect(chart.legend, isNotNull);
          final legendDefaults = _legendDefaults();
          expect(
            chart.legend!.options,
            toEqualOptions(<String, Object?>{
              // Object.assign({}, Chart.defaults.plugins.legend, ...)
              for (final key in jsObjectKeys(legendDefaults))
                key: jsGet(legendDefaults, key),
              // replace scriptable options with resolved values
              'labels': <String, Object?>{
                'color': jsGet(Chart.defaults, 'color'),
              },
              'title': <String, Object?>{
                'color': jsGet(Chart.defaults, 'color'),
              },
            }),
          );
        },
      );
    });

    group('callbacks', () {
      testWidgets(
        'should call onClick, onHover and onLeave at the correct times',
        (tester) async {
          Object? clickItem;
          Object? hoverItem;
          Object? leaveItem;

          final chart = acquireChart(
            _lineChart(<String, Object?>{
              'onClick': (Object? _, Object? item) {
                clickItem = item;
              },
              'onHover': (Object? _, Object? item) {
                hoverItem = item;
              },
              'onLeave': (Object? _, Object? item) {
                leaveItem = item;
              },
            }),
          );

          final hb = _hitBoxes(chart)[0];
          final el = _center(hb);

          await triggerMouseEvent(chart, 'click', el);
          expect(clickItem, same(chart.legend!.legendItems![0]));

          await triggerMouseEvent(chart, 'mousemove', el);
          expect(hoverItem, same(chart.legend!.legendItems![0]));

          await triggerMouseEvent(
            chart,
            'mousemove',
            chart.getDatasetMeta(0).data[0],
          );
          expect(leaveItem, same(chart.legend!.legendItems![0]));
        },
      );

      testWidgets('should call onLeave when the mouse leaves the canvas', (
        tester,
      ) async {
        Object? hoverItem;
        Object? leaveItem;

        final chart = acquireChart(
          _lineChart(<String, Object?>{
            'onHover': (Object? _, Object? item) {
              hoverItem = item;
            },
            'onLeave': (Object? _, Object? item) {
              leaveItem = item;
            },
          }),
        );

        final hb = _hitBoxes(chart)[0];
        final el = _center(hb);

        await triggerMouseEvent(chart, 'mousemove', el);
        expect(hoverItem, same(chart.legend!.legendItems![0]));

        await triggerMouseEvent(chart, 'mouseout');
        expect(leaveItem, same(chart.legend!.legendItems![0]));
      });

      testWidgets('should call onClick for the correct item when in RTL mode', (
        tester,
      ) async {
        Object? clickItem;

        final chart = acquireChart(<String, Object?>{
          'type': 'line',
          'data': <String, Object?>{
            'labels': <Object?>['A', 'B', 'C', 'D'],
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 20, 30, 100],
                'label': 'dataset 1',
              },
              <String, Object?>{
                'data': <Object?>[10, 20, 30, 100],
                'label': 'dataset 2',
              },
            ],
          },
          'options': <String, Object?>{
            'plugins': <String, Object?>{
              'legend': <String, Object?>{
                'onClick': (Object? _, Object? item) {
                  clickItem = item;
                },
              },
            },
          },
        });

        final hb = _hitBoxes(chart)[0];
        final el = _center(hb);

        await triggerMouseEvent(chart, 'click', el);
        expect(clickItem, same(chart.legend!.legendItems![0]));
      });
    });
  });
}

/// `ctx.dataset.data[ctx.dataIndex] || 0` (:693, :697, :701).
num _dataValue(Object? ctx) {
  final value = jsGetIndex(
    jsGet(jsGet(ctx, 'dataset'), 'data'),
    (jsGet(ctx, 'dataIndex')! as num).toDouble(),
  );
  return jsTruthy(value) ? value! as num : 0;
}

/// The two datasets of the usePointStyle cases (:733-755, :808-830).
List<Object?> _pointStyleDatasets() => <Object?>[
  <String, Object?>{
    'label': 'dataset1',
    'backgroundColor': '#f31',
    'borderCapStyle': 'butt',
    'borderDash': <Object?>[2, 2],
    'borderDashOffset': 5.5,
    'borderWidth': 0,
    'borderColor': '#f31',
    'pointStyle': 'crossRot',
    'pointBackgroundColor': 'rgba(0,0,0,0.1)',
    'pointBorderWidth': 5,
    'pointBorderColor': 'green',
    'data': <Object?>[],
  },
  <String, Object?>{
    'label': 'dataset2',
    'backgroundColor': '#f31',
    'borderJoinStyle': 'miter',
    'borderWidth': 2,
    'borderColor': '#f31',
    'pointStyle': 'crossRot',
    'pointRotation': 15,
    'data': <Object?>[],
  },
];

/// The items of the usePointStyle cases with the point style [pointStyle]
/// (:769-801, :845-877).
List<Object?> _pointStyleItems(String pointStyle) => <Object?>[
  _item(
    text: 'dataset1',
    fillStyle: 'rgba(0,0,0,0.1)',
    hidden: false,
    lineWidth: 5,
    strokeStyle: 'green',
    pointStyle: pointStyle,
    rotation: 0,
    datasetIndex: 0,
  ),
  _item(
    text: 'dataset2',
    fillStyle: '#f31',
    hidden: false,
    lineWidth: 2,
    strokeStyle: '#f31',
    pointStyle: pointStyle,
    rotation: 15,
    datasetIndex: 1,
  ),
];
