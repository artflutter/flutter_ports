// Ported from Chart.js v4.6.1 test/specs/plugin.tooltip.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'dart:collection';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart' show merge;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.tooltip.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart' show Point;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;
import '../support/jasmine.dart';

// `Chart` is the class of core.controller.dart, with the static members
// `Chart.registry` and `Chart.defaults`. `Chart.helpers.merge` is `merge` of
// helpers.core.dart. `toEqual` is jasmineEquals of test/support/jasmine.dart,
// and `jasmine.objectContaining` is objectContaining. `toEqualOptions` is the
// matcher of chartjs_test_utils. `jasmine.triggerMouseEvent` is
// triggerMouseEvent of chartjs_test_utils (Chart.js ADR 0022, section 6).
//
// Each chart case is a `testWidgets` case with the harness of Chart.js ADR
// 0022, section 2. `chart.tooltip` is the field of `Chart`, a
// `types.TooltipModel?`: Dart `null` stands for JS `undefined`. A case reads
// the members of `index.d.ts:2648-2699` through the interface, and the
// other members through a cast to `Tooltip` (Chart.js ADR 0039, section
// 14). The access by name of the tooltip (`tooltip['opacity']`) is the JS
// property read. The tooltip items, the body items and the label colors are
// Maps with the upstream keys.
//
// `spyOn(tooltip, 'update')` (:964, :1027) replaces the field `update` of
// the tooltip with a recording closure, as `core.controller_test.dart` does
// for `chart.resize` (differences.md `harness-method-fields`, Chart.js ADR
// 0039, section 6). An active element is the Map `{datasetIndex, index,
// element}` in a Jasmine `toEqual` ([_activeItems]).

/// :2 `Chart.registry.getPlugin('tooltip')`, read in each case.
Object _tooltipPlugin() => Chart.registry.getPlugin('tooltip');

/// :3 `tooltipPlugin._element`, the class value `Tooltip`.
JsClass _tooltipClass() => jsGet(_tooltipPlugin(), '_element')! as JsClass;

/// `tooltipPlugin.positioners`.
AnyObject _positioners() =>
    jsGet(_tooltipPlugin(), 'positioners')! as AnyObject;

/// `Chart.defaults`.
AnyObject _defaults() => Chart.defaults as AnyObject;

/// `Chart.defaults.font`.
Object? _font(String key) => jsGet(jsGet(_defaults(), 'font'), key);

/// `chart.tooltip`, the tooltip of [chart], as the class of the plugin.
Tooltip _tooltipOf(Chart chart) => chart.tooltip! as Tooltip;

/// The point `{x, y}`.
AnyObject _point(num x, num y) => <String, Object?>{'x': x, 'y': y};

/// The active elements [items] as the objects `{datasetIndex, index,
/// element}` of a Jasmine `toEqual`. Dart `null` of an element is JS
/// `undefined`.
List<Object?> _activeItems(List<types.ActiveElement> items) => [
  for (final item in items)
    <String, Object?>{
      'datasetIndex': item.datasetIndex,
      'index': item.index,
      'element': item.element ?? undefined,
    },
];

/// The two datasets of most cases (:10-17, :40-51): `Dataset 1` with the
/// data [10, 20, 30] and `Dataset 2` with [40, 40, 40], each with the
/// options [extra1] and [extra2].
AnyObject _twoDatasets({
  AnyObject extra1 = const {},
  AnyObject extra2 = const {},
}) => <String, Object?>{
  'datasets': <Object?>[
    <String, Object?>{
      'label': 'Dataset 1',
      'data': <Object?>[10, 20, 30],
      'pointHoverBorderColor': 'rgb(255, 0, 0)',
      'pointHoverBackgroundColor': 'rgb(0, 255, 0)',
      ...extra1,
    },
    <String, Object?>{
      'label': 'Dataset 2',
      'data': <Object?>[40, 40, 40],
      'pointHoverBorderColor': 'rgb(0, 0, 255)',
      'pointHoverBackgroundColor': 'rgb(0, 255, 255)',
      ...extra2,
    },
  ],
  'labels': <Object?>['Point 1', 'Point 2', 'Point 3'],
};

/// The one dataset of the `active elements` cases (:1609-1615).
AnyObject _oneDataset() => <String, Object?>{
  'datasets': <Object?>[
    <String, Object?>{
      'label': 'Dataset 1',
      'data': <Object?>[10, 20, 30],
      'pointHoverBorderColor': 'rgb(255, 0, 0)',
      'pointHoverBackgroundColor': 'rgb(0, 255, 0)',
    },
  ],
  'labels': <Object?>['Point 1', 'Point 2', 'Point 3'],
};

/// A line chart with the data [data] and the options [options].
AnyObject _line(AnyObject data, [AnyObject? options]) => <String, Object?>{
  'type': 'line',
  'data': data,
  'options': ?options,
};

/// `{plugins: {tooltip: tooltip}}`.
AnyObject _tooltipOptions(AnyObject tooltip) => <String, Object?>{
  'plugins': <String, Object?>{'tooltip': tooltip},
};

/// The label color of the default `labelColor` for a line point with the
/// default colors (:157-163).
AnyObject _defaultLabelColor() => <String, Object?>{
  'borderColor': jsGet(_defaults(), 'borderColor'),
  'backgroundColor': jsGet(_defaults(), 'backgroundColor'),
  'borderWidth': 1,
  'borderDash': undefined,
  'borderDashOffset': undefined,
  'borderRadius': 0,
};

/// The body item `{before: [], lines: [line], after: []}`.
AnyObject _bodyItem(String line) => <String, Object?>{
  'before': <Object?>[],
  'lines': <Object?>[line],
  'after': <Object?>[],
};

/// The default value of an absent argument of the spy of `update`.
const Object _absent = Object();

/// `spyOn(tooltip, 'update')`: replaces the field `update` of [tooltip] with
/// a recording closure. With [callThrough], the closure also calls the old
/// function with the same arguments. Each record is the list of the
/// arguments that the caller passed, as Jasmine records them: the record of
/// `update(true)` has 1 item, and the record of `update(true, undefined)`
/// has 2 items. Thus `toHaveBeenCalledWith(true, undefined)` accepts
/// the call of `handleEvent` (`plugin.tooltip.js:1167`) and not the call of
/// `setActiveElements` (`plugin.tooltip.js:1128`), as upstream.
List<List<Object?>> _spyOnUpdate(Tooltip tooltip, {bool callThrough = false}) {
  final calls = <List<Object?>>[];
  final original = tooltip.update;
  tooltip.update = ([changed = _absent, replay = _absent]) {
    calls.add([
      if (!identical(changed, _absent)) changed,
      if (!identical(replay, _absent)) replay,
    ]);
    if (callThrough) {
      original(
        identical(changed, _absent) ? undefined : changed,
        identical(replay, _absent) ? undefined : replay,
      );
    }
  };
  return calls;
}

/// `Object.prototype.hasOwnProperty.call(value, key)` for the event
/// position of a positioner call: a chart event (a [Point]) has its own
/// `x` and `y`, and a Map its keys.
bool _hasOwnProperty(Object? value, String key) => switch (value) {
  final Point _ => key == 'x' || key == 'y',
  final Map<String, Object?> map => map.containsKey(key),
  _ => false,
};

/// The font string of the title and the footer of the text align cases.
const String _boldFont =
    "normal bold 12px 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif";

/// The font string of the body of the text align cases.
const String _normalFont =
    "normal 12px 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif";

/// The chart of the text align cases (:1487-1496): `getContext` and
/// `options` only. The draw of these cases reads only `getContext()`.
final class _TextAlignChart implements types.Chart {
  @override
  AnyObject getContext() => <String, Object?>{};

  @override
  AnyObject get options => <String, Object?>{
    'plugins': <String, Object?>{
      'tooltip': <String, Object?>{'animation': false},
    },
  };

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'The text align chart has no member '
    '${invocation.memberName}.',
  );
}

void main() {
  group('Plugin.Tooltip', () {
    group('auto', fixture.specs('plugin.tooltip'));

    group('config', () {
      test(
        'should not include the dataset label in the body string if not '
        'defined',
        () {
          final data = <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[10, 20, 30],
                'pointHoverBorderColor': 'rgb(255, 0, 0)',
                'pointHoverBackgroundColor': 'rgb(0, 255, 0)',
              },
            ],
            'labels': <Object?>['Point 1', 'Point 2', 'Point 3'],
          };
          final dataset0 =
              (data['datasets']! as List<Object?>)[0]! as AnyObject;
          final tooltipItem = <String, Object?>{
            'index': 1,
            'datasetIndex': 0,
            'dataset': dataset0,
            'label': 'Point 2',
            'formattedValue': '20',
          };

          Object? label() => jsCall(
            jsGet(
              jsGet(
                jsGet(jsGet(_defaults(), 'plugins'), 'tooltip'),
                'callbacks',
              ),
              'label',
            ),
            [tooltipItem],
          );

          var value = label();
          expect(value, '20');

          dataset0['label'] = 'My dataset';
          value = label();
          expect(value, 'My dataset: 20');
        },
      );
    });

    group('index mode', () {
      testWidgets('Should only use x distance when intersect is false', (
        tester,
      ) async {
        final chart = acquireChart(
          _line(_twoDatasets(), <String, Object?>{
            'plugins': <String, Object?>{
              'tooltip': <String, Object?>{
                'mode': 'index',
                'intersect': false,
                'padding': <String, Object?>{
                  'left': 6,
                  'top': 6,
                  'right': 6,
                  'bottom': 6,
                },
              },
            },
            'hover': <String, Object?>{'mode': 'index', 'intersect': false},
          }),
        );

        // Trigger an event over top of the
        final meta = chart.getDatasetMeta(0);
        final point = meta.data[1];

        // Check and see if tooltip was displayed
        final tooltip = _tooltipOf(chart);

        await triggerMouseEvent(
          chart,
          'mousemove',
          _point(point.x, chart.chartArea!.top + 10),
        );

        final options = tooltip.options!;
        expect(
          jsGet(options, 'padding')! as AnyObject,
          toEqualOptions(<String, Object?>{
            'left': 6,
            'top': 6,
            'right': 6,
            'bottom': 6,
          }),
        );
        expect(tooltip.xAlign, 'left');
        expect(tooltip.yAlign, 'center');
        expect(jsGet(options, 'bodyColor'), '#fff');

        expect(
          jsGet(options, 'bodyFont')! as AnyObject,
          toEqualOptions(<String, Object?>{
            'family': _font('family'),
            'style': _font('style'),
            'size': _font('size'),
          }),
        );

        expect(
          options,
          toEqualOptions(<String, Object?>{
            'bodyAlign': 'left',
            'bodySpacing': 2,
          }),
        );

        expect(jsGet(options, 'titleColor'), '#fff');
        expect(
          jsGet(options, 'titleFont')! as AnyObject,
          toEqualOptions(<String, Object?>{
            'family': _font('family'),
            'weight': 'bold',
            'size': _font('size'),
          }),
        );

        expect(
          options,
          toEqualOptions(<String, Object?>{
            'titleAlign': 'left',
            'titleSpacing': 2,
            'titleMarginBottom': 6,
          }),
        );

        expect(jsGet(options, 'footerColor'), '#fff');
        expect(
          jsGet(options, 'footerFont')! as AnyObject,
          toEqualOptions(<String, Object?>{
            'family': _font('family'),
            'weight': 'bold',
            'size': _font('size'),
          }),
        );

        expect(
          options,
          toEqualOptions(<String, Object?>{
            'footerAlign': 'left',
            'footerSpacing': 2,
            'footerMarginTop': 6,
          }),
        );

        expect(
          options,
          toEqualOptions(<String, Object?>{
            // Appearance
            'caretSize': 5,
            'caretPadding': 2,
            'cornerRadius': 6,
            'backgroundColor': 'rgba(0,0,0,0.8)',
            'multiKeyBackground': '#fff',
            'displayColors': true,
          }),
        );

        expect(
          tooltip,
          objectContaining(<String, Object?>{
            'opacity': 1,

            // Text
            'title': <Object?>['Point 2'],
            'beforeBody': <Object?>[],
            'body': <Object?>[
              _bodyItem('Dataset 1: 20'),
              _bodyItem('Dataset 2: 40'),
            ],
            'afterBody': <Object?>[],
            'footer': <Object?>[],
            'labelColors': <Object?>[
              _defaultLabelColor(),
              _defaultLabelColor(),
            ],
          }),
        );

        expect(tooltip.x, toBeCloseToPixel(266));
        expect(tooltip.y, toBeCloseToPixel(150));
      });

      testWidgets('Should only display if intersecting if intersect is set', (
        tester,
      ) async {
        final chart = acquireChart(
          _line(
            _twoDatasets(),
            _tooltipOptions(<String, Object?>{
              'mode': 'index',
              'intersect': true,
            }),
          ),
        );

        // Trigger an event over top of the
        final meta = chart.getDatasetMeta(0);
        final point = meta.data[1];

        await triggerMouseEvent(chart, 'mousemove', _point(point.x, 0));
        // Check and see if tooltip was displayed
        final tooltip = _tooltipOf(chart);

        expect(tooltip, objectContaining(<String, Object?>{'opacity': 0}));
      });
    });

    testWidgets('Should display in single mode', (tester) async {
      final chart = acquireChart(
        _line(
          _twoDatasets(),
          _tooltipOptions(<String, Object?>{
            'mode': 'nearest',
            'intersect': true,
          }),
        ),
      );

      // Trigger an event over top of the
      final meta = chart.getDatasetMeta(0);
      final point = meta.data[1];

      await triggerMouseEvent(chart, 'mousemove', point);
      // Check and see if tooltip was displayed
      final tooltip = _tooltipOf(chart);
      final options = tooltip.options!;

      expect(jsGet(options, 'padding'), 6);
      expect(tooltip.xAlign, 'left');
      expect(tooltip.yAlign, 'center');

      expect(
        JasmineOptions(jsGet(options, 'bodyFont')! as AnyObject),
        objectContaining(<String, Object?>{
          'family': _font('family'),
          'style': _font('style'),
          'size': _font('size'),
        }),
      );

      expect(
        options,
        toEqualOptions(<String, Object?>{
          'bodyAlign': 'left',
          'bodySpacing': 2,
        }),
      );

      expect(
        JasmineOptions(jsGet(options, 'titleFont')! as AnyObject),
        objectContaining(<String, Object?>{
          'family': _font('family'),
          'weight': 'bold',
          'size': _font('size'),
        }),
      );

      expect(
        options,
        toEqualOptions(<String, Object?>{
          'titleAlign': 'left',
          'titleSpacing': 2,
          'titleMarginBottom': 6,
        }),
      );

      expect(
        jsGet(options, 'footerFont')! as AnyObject,
        toEqualOptions(<String, Object?>{
          'family': _font('family'),
          'weight': 'bold',
          'size': _font('size'),
        }),
      );

      expect(
        options,
        toEqualOptions(<String, Object?>{
          'footerAlign': 'left',
          'footerSpacing': 2,
          'footerMarginTop': 6,
        }),
      );

      expect(
        options,
        toEqualOptions(<String, Object?>{
          // Appearance
          'caretSize': 5,
          'caretPadding': 2,
          'cornerRadius': 6,
          'backgroundColor': 'rgba(0,0,0,0.8)',
          'multiKeyBackground': '#fff',
          'displayColors': true,
        }),
      );

      expect(tooltip.opacity, 1);
      expect(tooltip.title, jasmineEquals(<Object?>['Point 2']));
      expect(tooltip.beforeBody, jasmineEquals(<Object?>[]));
      expect(
        tooltip.body,
        jasmineEquals(<Object?>[_bodyItem('Dataset 1: 20')]),
      );
      expect(tooltip.afterBody, jasmineEquals(<Object?>[]));
      expect(tooltip.footer, jasmineEquals(<Object?>[]));
      expect(tooltip.labelTextColors, jasmineEquals(<Object?>['#fff']));

      expect(
        tooltip.labelColors,
        jasmineEquals(<Object?>[_defaultLabelColor()]),
      );

      expect(tooltip.x, toBeCloseToPixel(267));
      expect(tooltip.y, toBeCloseToPixel(308));
    });

    testWidgets('Should display information from user callbacks', (
      tester,
    ) async {
      final chart = acquireChart(
        _line(
          _twoDatasets(),
          _tooltipOptions(<String, Object?>{
            'mode': 'index',
            'callbacks': <String, Object?>{
              'beforeTitle': () => 'beforeTitle',
              'title': () => 'title',
              'afterTitle': () => 'afterTitle',
              'beforeBody': () => 'beforeBody',
              'beforeLabel': () => 'beforeLabel',
              'label': () => 'label',
              'afterLabel': () => 'afterLabel',
              'afterBody': () => 'afterBody',
              'beforeFooter': () => 'beforeFooter',
              'footer': () => 'footer',
              'afterFooter': () => 'afterFooter',
              'labelTextColor': () => 'labelTextColor',
              'labelPointStyle': () => <String, Object?>{
                'pointStyle': 'labelPointStyle',
                'rotation': 42,
              },
            },
          }),
        ),
      );

      // Trigger an event over top of the
      final meta = chart.getDatasetMeta(0);
      final point = meta.data[1];

      await triggerMouseEvent(chart, 'mousemove', point);
      // Check and see if tooltip was displayed
      final tooltip = _tooltipOf(chart);
      final options = tooltip.options!;

      expect(jsGet(options, 'padding'), 6);
      expect(tooltip.xAlign, 'left');
      expect(tooltip.yAlign, 'center');

      expect(
        JasmineOptions(jsGet(options, 'bodyFont')! as AnyObject),
        objectContaining(<String, Object?>{
          'family': _font('family'),
          'style': _font('style'),
          'size': _font('size'),
        }),
      );

      expect(
        options,
        toEqualOptions(<String, Object?>{
          'bodyAlign': 'left',
          'bodySpacing': 2,
        }),
      );

      expect(
        JasmineOptions(jsGet(options, 'titleFont')! as AnyObject),
        objectContaining(<String, Object?>{
          'family': _font('family'),
          'weight': 'bold',
          'size': _font('size'),
        }),
      );

      expect(
        options,
        toEqualOptions(<String, Object?>{
          'titleSpacing': 2,
          'titleMarginBottom': 6,
        }),
      );

      expect(
        JasmineOptions(jsGet(options, 'footerFont')! as AnyObject),
        objectContaining(<String, Object?>{
          'family': _font('family'),
          'weight': 'bold',
          'size': _font('size'),
        }),
      );

      expect(
        options,
        toEqualOptions(<String, Object?>{
          'footerAlign': 'left',
          'footerSpacing': 2,
          'footerMarginTop': 6,
        }),
      );

      expect(
        options,
        toEqualOptions(<String, Object?>{
          // Appearance
          'caretSize': 5,
          'caretPadding': 2,
          'cornerRadius': 6,
          'backgroundColor': 'rgba(0,0,0,0.8)',
          'multiKeyBackground': '#fff',
        }),
      );

      AnyObject callbackBodyItem() => <String, Object?>{
        'before': <Object?>['beforeLabel'],
        'lines': <Object?>['label'],
        'after': <Object?>['afterLabel'],
      };
      AnyObject pointStyle() => <String, Object?>{
        'pointStyle': 'labelPointStyle',
        'rotation': 42,
      };
      expect(
        tooltip,
        objectContaining(<String, Object?>{
          'opacity': 1,

          // Text
          'title': <Object?>['beforeTitle', 'title', 'afterTitle'],
          'beforeBody': <Object?>['beforeBody'],
          'body': <Object?>[callbackBodyItem(), callbackBodyItem()],
          'afterBody': <Object?>['afterBody'],
          'footer': <Object?>['beforeFooter', 'footer', 'afterFooter'],
          'labelTextColors': <Object?>['labelTextColor', 'labelTextColor'],
          'labelColors': <Object?>[_defaultLabelColor(), _defaultLabelColor()],
          'labelPointStyles': <Object?>[pointStyle(), pointStyle()],
        }),
      );

      expect(tooltip.x, toBeCloseToPixel(267));
      expect(tooltip.y, toBeCloseToPixel(58));
    });

    testWidgets('Should provide context object to user callbacks', (
      tester,
    ) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'Dataset 1',
              'data': <Object?>[
                <String, Object?>{'x': 1, 'y': 10},
                <String, Object?>{'x': 2, 'y': 20},
                <String, Object?>{'x': 3, 'y': 30},
              ],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'linear'},
          },
          'plugins': <String, Object?>{
            'tooltip': <String, Object?>{
              'mode': 'index',
              'callbacks': <String, Object?>{
                'beforeLabel': (Object? ctx) {
                  final parsed = jsGet(ctx, 'parsed');
                  return jsAdd(
                    jsAdd(jsGet(parsed, 'x'), ','),
                    jsGet(parsed, 'y'),
                  );
                },
              },
            },
          },
        },
      });

      // Trigger an event over top of the
      final meta = chart.getDatasetMeta(0);
      final point = meta.data[1];

      await triggerMouseEvent(chart, 'mousemove', point);
      expect(
        jsGet(_tooltipOf(chart).body![0], 'before'),
        jasmineEquals(<Object?>['2,20']),
      );
    });

    testWidgets('Should allow sorting items', (tester) async {
      final chart = acquireChart(
        _line(
          _twoDatasets(),
          _tooltipOptions(<String, Object?>{
            'mode': 'index',
            'itemSort': (Object? a, Object? b) =>
                (jsGet(a, 'datasetIndex')! as num) >
                    (jsGet(b, 'datasetIndex')! as num)
                ? -1
                : 1,
          }),
        ),
      );

      // Trigger an event over top of the
      final meta0 = chart.getDatasetMeta(0);
      final point0 = meta0.data[1];

      await triggerMouseEvent(chart, 'mousemove', point0);
      // Check and see if tooltip was displayed
      final tooltip = _tooltipOf(chart);

      expect(
        tooltip,
        objectContaining(<String, Object?>{
          // Positioning
          'xAlign': 'left',
          'yAlign': 'center',

          // Text
          'title': <Object?>['Point 2'],
          'beforeBody': <Object?>[],
          'body': <Object?>[
            _bodyItem('Dataset 2: 40'),
            _bodyItem('Dataset 1: 20'),
          ],
          'afterBody': <Object?>[],
          'footer': <Object?>[],
          'labelColors': <Object?>[_defaultLabelColor(), _defaultLabelColor()],
        }),
      );

      expect(tooltip.x, toBeCloseToPixel(267));
      expect(tooltip.y, toBeCloseToPixel(150));
    });

    testWidgets('Should allow reversing items', (tester) async {
      final chart = acquireChart(
        _line(
          _twoDatasets(),
          _tooltipOptions(<String, Object?>{'mode': 'index', 'reverse': true}),
        ),
      );

      // Trigger an event over top of the
      final meta0 = chart.getDatasetMeta(0);
      final point0 = meta0.data[1];

      await triggerMouseEvent(chart, 'mousemove', point0);
      // Check and see if tooltip was displayed
      final tooltip = _tooltipOf(chart);

      expect(
        tooltip,
        objectContaining(<String, Object?>{
          // Positioning
          'xAlign': 'left',
          'yAlign': 'center',

          // Text
          'title': <Object?>['Point 2'],
          'beforeBody': <Object?>[],
          'body': <Object?>[
            _bodyItem('Dataset 2: 40'),
            _bodyItem('Dataset 1: 20'),
          ],
          'afterBody': <Object?>[],
          'footer': <Object?>[],
          'labelColors': <Object?>[_defaultLabelColor(), _defaultLabelColor()],
        }),
      );

      expect(tooltip.x, toBeCloseToPixel(267));
      expect(tooltip.y, toBeCloseToPixel(150));
    });

    testWidgets('Should follow dataset order', (tester) async {
      final chart = acquireChart(
        _line(
          _twoDatasets(
            extra1: const {'order': 10},
            extra2: const {'order': 5},
          ),
          _tooltipOptions(<String, Object?>{'mode': 'index'}),
        ),
      );

      // Trigger an event over top of the
      final meta0 = chart.getDatasetMeta(0);
      final point0 = meta0.data[1];

      await triggerMouseEvent(chart, 'mousemove', point0);
      // Check and see if tooltip was displayed
      final tooltip = _tooltipOf(chart);

      expect(
        tooltip,
        objectContaining(<String, Object?>{
          // Positioning
          'xAlign': 'left',
          'yAlign': 'center',

          // Text
          'title': <Object?>['Point 2'],
          'beforeBody': <Object?>[],
          'body': <Object?>[
            _bodyItem('Dataset 2: 40'),
            _bodyItem('Dataset 1: 20'),
          ],
          'afterBody': <Object?>[],
          'footer': <Object?>[],
          'labelColors': <Object?>[_defaultLabelColor(), _defaultLabelColor()],
        }),
      );

      expect(tooltip.x, toBeCloseToPixel(267));
      expect(tooltip.y, toBeCloseToPixel(150));
    });

    testWidgets('should filter items from the tooltip using the callback', (
      tester,
    ) async {
      final chart = acquireChart(
        _line(
          _twoDatasets(extra1: const {'tooltipHidden': true}),
          _tooltipOptions(<String, Object?>{
            'mode': 'index',
            'filter':
                (
                  Object? tooltipItem,
                  Object? index,
                  Object? items,
                  Object? data,
                ) {
                  // For testing purposes remove the first dataset that has a
                  // tooltipHidden property
                  return !jsTruthy(
                    jsGet(
                      jsGet(
                        jsGet(data, 'datasets'),
                        jsGet(tooltipItem, 'datasetIndex'),
                      ),
                      'tooltipHidden',
                    ),
                  );
                },
          }),
        ),
      );

      // Trigger an event over top of the
      final meta0 = chart.getDatasetMeta(0);
      final point0 = meta0.data[1];

      await triggerMouseEvent(chart, 'mousemove', point0);
      // Check and see if tooltip was displayed
      final tooltip = _tooltipOf(chart);

      expect(
        tooltip,
        objectContaining(<String, Object?>{
          // Positioning
          'xAlign': 'left',
          'yAlign': 'center',

          // Text
          'title': <Object?>['Point 2'],
          'beforeBody': <Object?>[],
          'body': <Object?>[_bodyItem('Dataset 2: 40')],
          'afterBody': <Object?>[],
          'footer': <Object?>[],
          'labelColors': <Object?>[_defaultLabelColor()],
        }),
      );
    });

    testWidgets('should set the caretPadding based on a config setting', (
      tester,
    ) async {
      final chart = acquireChart(
        _line(
          _twoDatasets(extra1: const {'tooltipHidden': true}),
          _tooltipOptions(<String, Object?>{'caretPadding': 10}),
        ),
      );

      // Trigger an event over top of the
      final meta0 = chart.getDatasetMeta(0);
      final point0 = meta0.data[1];

      await triggerMouseEvent(chart, 'mousemove', point0);
      // Check and see if tooltip was displayed
      final tooltip = _tooltipOf(chart);

      expect(
        tooltip.options,
        toEqualOptions(<String, Object?>{
          // Positioning
          'caretPadding': 10,
        }),
      );
    });

    for (final type in ['line', 'bar']) {
      testWidgets('Should have dataPoints in a $type chart', (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': type,
          'data': _twoDatasets(),
          'options': _tooltipOptions(<String, Object?>{
            'mode': 'nearest',
            'intersect': true,
          }),
        });

        // Trigger an event over top of the element
        const pointIndex = 1;
        const datasetIndex = 0;
        final point = chart
            .getDatasetMeta(datasetIndex.toDouble())
            .data[pointIndex];

        await triggerMouseEvent(chart, 'mousemove', point);
        // Check and see if tooltip was displayed
        final tooltip = chart.tooltip;

        expect(tooltip, isA<Object>());
        expect(tooltip!.dataPoints, isA<List<Object?>>());
        expect(tooltip.dataPoints!.length, 1);

        final tooltipItem = tooltip.dataPoints![0];

        expect(jsGet(tooltipItem, 'dataIndex'), pointIndex);
        expect(jsGet(tooltipItem, 'datasetIndex'), datasetIndex);
        expect(jsGet(tooltipItem, 'label'), isA<String>());
        expect(
          jsGet(tooltipItem, 'label'),
          (chart.data['labels']! as List<Object?>)[pointIndex],
        );
        expect(jsGet(tooltipItem, 'formattedValue'), isA<String>());
        expect(
          jsGet(tooltipItem, 'formattedValue'),
          jsAdd(
            '',
            jsGet(
              jsGet(
                (chart.data['datasets']! as List<Object?>)[datasetIndex],
                'data',
              ),
              pointIndex,
            ),
          ),
        );
      });
    }

    testWidgets('Should not update if active element has not changed', (
      tester,
    ) async {
      final chart = acquireChart(
        _line(
          _twoDatasets(),
          _tooltipOptions(<String, Object?>{
            'mode': 'nearest',
            'intersect': true,
            'callbacks': <String, Object?>{
              'title': () => 'registering callback...',
            },
          }),
        ),
      );

      // Trigger an event over top of the
      final meta = chart.getDatasetMeta(0);
      final firstPoint = meta.data[1];

      final tooltip = _tooltipOf(chart);
      final calls = _spyOnUpdate(tooltip, callThrough: true);

      // First dispatch change event, should update tooltip
      await triggerMouseEvent(chart, 'mousemove', firstPoint);
      expect(
        calls,
        contains(jasmineEquals(<Object?>[true, undefined])),
      );

      // Reset calls
      calls.clear();

      // Second dispatch change event (same event), should not update tooltip
      await triggerMouseEvent(chart, 'mousemove', firstPoint);
      expect(calls, isEmpty);
    });

    testWidgets(
      'Should update if active elements are the same, but the position has '
      'changed',
      (tester) async {
        final chart = acquireChart(
          _line(_twoDatasets(), <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'stacked': true},
              'y': <String, Object?>{'stacked': true},
            },
            'plugins': <String, Object?>{
              'tooltip': <String, Object?>{
                'mode': 'nearest',
                'position': 'nearest',
                'intersect': true,
                'callbacks': <String, Object?>{
                  'title': () => 'registering callback...',
                },
              },
            },
          }),
        );

        // Trigger an event over top of the
        final meta = chart.getDatasetMeta(0);
        final firstPoint = meta.data[1];

        final meta2 = chart.getDatasetMeta(1);
        final secondPoint = meta2.data[1];

        final tooltip = _tooltipOf(chart);
        final calls = _spyOnUpdate(tooltip);

        // First dispatch change event, should update tooltip
        await triggerMouseEvent(chart, 'mousemove', firstPoint);
        expect(
          calls,
          contains(jasmineEquals(<Object?>[true, undefined])),
        );

        // Reset calls
        calls.clear();

        // Second dispatch change event (same event), should update tooltip
        // because position mode is 'nearest'
        await triggerMouseEvent(chart, 'mousemove', secondPoint);
        expect(
          calls,
          contains(jasmineEquals(<Object?>[true, undefined])),
        );
      },
    );

    group('positioners', () {
      testWidgets(
        'Should call custom positioner with correct parameters and scope',
        (tester) async {
          final positioners = _positioners();
          positioners['test'] = () => <String, Object?>{'x': 0, 'y': 0};
          // Upstream keeps the key `test` after the case. The port removes
          // it, so a case of a later shard sees the same positioners.
          addTearDown(() => positioners.remove('test'));

          spyOn(positioners, 'test').and.callThrough();

          final chart = acquireChart(
            _line(
              _twoDatasets(),
              _tooltipOptions(<String, Object?>{
                'mode': 'nearest',
                'position': 'test',
              }),
            ),
          );

          // Trigger an event over top of the
          const pointIndex = 1;
          const datasetIndex = 0;
          final meta = chart.getDatasetMeta(datasetIndex.toDouble());
          final point = meta.data[pointIndex];
          final fn = positioners['test'];

          await triggerMouseEvent(chart, 'mousemove', point);
          expect(fn.calls.count(), 2);
          expect(fn.calls.first().args[0], isA<List<Object?>>());
          expect(_hasOwnProperty(fn.calls.first().args[1], 'x'), isTrue);
          expect(_hasOwnProperty(fn.calls.first().args[1], 'y'), isTrue);
          // `instanceof Tooltip` with `Tooltip = tooltipPlugin._element`
          // (:3): the object is a Dart `Tooltip`, and `_element` is the
          // class value of `Tooltip`. Thus the case has one assertion more
          // than upstream.
          expect(fn.calls.first().object, isA<Tooltip>());
          expect(identical(_tooltipClass(), Tooltip.jsClass), isTrue);
        },
      );

      testWidgets(
        'Should ignore same x position when calculating average position '
        'with index interaction on stacked bar',
        (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'bar',
            'data': <String, Object?>{
              'datasets': <Object?>[
                <String, Object?>{
                  'label': 'Dataset 1',
                  'data': <Object?>[10, 20, 30],
                  'pointHoverBorderColor': 'rgb(255, 0, 0)',
                  'pointHoverBackgroundColor': 'rgb(0, 255, 0)',
                  'stack': 'stack1',
                },
                <String, Object?>{
                  'label': 'Dataset 2',
                  'data': <Object?>[40, 40, 40],
                  'pointHoverBorderColor': 'rgb(0, 0, 255)',
                  'pointHoverBackgroundColor': 'rgb(0, 255, 255)',
                  'stack': 'stack1',
                },
                <String, Object?>{
                  'label': 'Dataset 3',
                  'data': <Object?>[90, 100, 110],
                  'pointHoverBorderColor': 'rgb(0, 0, 255)',
                  'pointHoverBackgroundColor': 'rgb(0, 255, 255)',
                },
              ],
              'labels': <Object?>['Point 1', 'Point 2', 'Point 3'],
            },
            'options': <String, Object?>{
              'interaction': <String, Object?>{'mode': 'index'},
              'plugins': <String, Object?>{'position': 'average'},
            },
          });

          // Trigger an event over top of the
          const pointIndex = 1;
          const datasetIndex = 0;
          final meta = chart.getDatasetMeta(datasetIndex.toDouble());
          final point = meta.data[pointIndex];
          await triggerMouseEvent(chart, 'mousemove', point);

          final tooltipModel = chart.tooltip!;
          final activeElements = tooltipModel.getActiveElements();

          final xPositionArray = [
            for (final element in activeElements) element.element!.x,
          ];
          final xPositionArrayAverage =
              xPositionArray.reduce((a, b) => a + b) / xPositionArray.length;

          final xPositionSet = LinkedHashSet<double>.of(xPositionArray);
          final xPositionSetAverage =
              xPositionSet.reduce((a, b) => a + b) / xPositionSet.length;

          expect(xPositionArray.length, 3);
          expect(xPositionSet.length, 2);
          expect(tooltipModel.caretX, isNot(xPositionArrayAverage));
          expect(tooltipModel.caretX, xPositionSetAverage);
        },
      );

      test(
        'Should not fail with all hiden data elements on the average '
        'positioner',
        () {
          final averagePositioner = jsGet(_positioners(), 'average');

          // Simulate `hasValue` returns false
          Object? call() => jsCall(averagePositioner, [
            <Object?>[
              <String, Object?>{'x': 'invalidNumber', 'y': 'invalidNumber'},
            ],
          ]);
          expect(call, returnsNormally);
          final result = call();
          expect(result, false);
        },
      );
    });

    testWidgets(
      'Should avoid tooltip truncation in x axis if there is enough space to '
      'show tooltip without truncation',
      (tester) async {
        final chart = acquireChart(<String, Object?>{
          'type': 'pie',
          'data': <String, Object?>{
            'datasets': <Object?>[
              <String, Object?>{
                'data': <Object?>[50, 50],
                'backgroundColor': <Object?>[
                  'rgb(255, 0, 0)',
                  'rgb(0, 255, 0)',
                ],
                'label': 'Dataset 1',
              },
            ],
            'labels': <Object?>[
              'Red long tooltip text to avoid unnecessary loop steps',
              'Green long tooltip text to avoid unnecessary loop steps',
            ],
          },
          'options': <String, Object?>{
            'responsive': true,
            'animation': <String, Object?>{
              // without this slice center point is calculated wrong
              'animateRotate': false,
            },
            'plugins': <String, Object?>{
              'tooltip': <String, Object?>{'animation': false},
            },
          },
        });

        Future<void> testSlice(int slice, int count) async {
          final meta = chart.getDatasetMeta(0);
          final element = meta.data[slice];
          final center = (element as types.VisualElement).getCenterPoint();
          final point = _point(center.x!, center.y!);
          final tooltipPosition = (meta.data[slice] as Element)
              .tooltipPosition();

          Future<void> recursive(int left) async {
            final labels = chart.data['labels']! as List<Object?>;
            labels[slice] = '${labels[slice]}XX';
            chart.update();

            await triggerMouseEvent(chart, 'mouseout', point);
            await triggerMouseEvent(chart, 'mousemove', point);
            final tooltip = chart.tooltip!;
            expect(tooltip.dataPoints!.length, 1);
            expect(tooltip.x, greaterThanOrEqualTo(0));
            if (tooltip.width <= chart.width) {
              expect(
                tooltip.x + tooltip.width,
                lessThanOrEqualTo(chart.width),
              );
            }
            expect(tooltip.caretX, toBeCloseToPixel(tooltipPosition.x));
            // if tooltip is longer than chart area then all tests done
            if (left == 0) {
              throw StateError('max iterations reached');
            }
            if (tooltip.width < chart.width) {
              await recursive(left - 1);
            }
          }

          await recursive(count);
        }

        // Trigger an event over top of the slice
        for (var slice = 0; slice < 2; slice++) {
          await testSlice(slice, 20);
        }
      },
    );

    testWidgets('Should split newlines into separate lines in user callbacks', (
      tester,
    ) async {
      final chart = acquireChart(
        _line(
          _twoDatasets(),
          _tooltipOptions(<String, Object?>{
            'mode': 'index',
            'callbacks': <String, Object?>{
              'beforeTitle': () => 'beforeTitle\nnewline',
              'title': () => 'title\nnewline',
              'afterTitle': () => 'afterTitle\nnewline',
              'beforeBody': () => 'beforeBody\nnewline',
              'beforeLabel': () => 'beforeLabel\nnewline',
              'label': () => 'label',
              'afterLabel': () => 'afterLabel\nnewline',
              'afterBody': () => 'afterBody\nnewline',
              'beforeFooter': () => 'beforeFooter\nnewline',
              'footer': () => 'footer\nnewline',
              'afterFooter': () => 'afterFooter\nnewline',
              'labelTextColor': () => 'labelTextColor',
            },
          }),
        ),
      );

      // Trigger an event over top of the
      final meta = chart.getDatasetMeta(0);
      final point = meta.data[1];

      await triggerMouseEvent(chart, 'mousemove', point);

      // Check and see if tooltip was displayed
      final tooltip = _tooltipOf(chart);
      final options = tooltip.options!;

      expect(jsGet(options, 'padding'), 6);
      expect(tooltip.xAlign, 'center');
      expect(tooltip.yAlign, 'top');

      expect(
        jsGet(options, 'bodyFont')! as AnyObject,
        toEqualOptions(<String, Object?>{
          'family': _font('family'),
          'style': _font('style'),
          'size': _font('size'),
        }),
      );

      expect(
        options,
        toEqualOptions(<String, Object?>{
          'bodyAlign': 'left',
          'bodySpacing': 2,
        }),
      );

      expect(
        jsGet(options, 'titleFont')! as AnyObject,
        toEqualOptions(<String, Object?>{
          'family': _font('family'),
          'weight': 'bold',
          'size': _font('size'),
        }),
      );

      expect(
        options,
        toEqualOptions(<String, Object?>{
          'titleAlign': 'left',
          'titleSpacing': 2,
          'titleMarginBottom': 6,
        }),
      );

      expect(
        jsGet(options, 'footerFont')! as AnyObject,
        toEqualOptions(<String, Object?>{
          'family': _font('family'),
          'weight': 'bold',
          'size': _font('size'),
        }),
      );

      expect(
        options,
        toEqualOptions(<String, Object?>{
          'footerAlign': 'left',
          'footerSpacing': 2,
          'footerMarginTop': 6,
        }),
      );

      expect(
        options,
        toEqualOptions(<String, Object?>{
          // Appearance
          'caretSize': 5,
          'caretPadding': 2,
          'cornerRadius': 6,
          'backgroundColor': 'rgba(0,0,0,0.8)',
          'multiKeyBackground': '#fff',
        }),
      );

      AnyObject newlineBodyItem() => <String, Object?>{
        'before': <Object?>['beforeLabel', 'newline'],
        'lines': <Object?>['label'],
        'after': <Object?>['afterLabel', 'newline'],
      };
      AnyObject labelColor() => <String, Object?>{
        'borderColor': jsGet(_defaults(), 'borderColor'),
        'backgroundColor': jsGet(_defaults(), 'backgroundColor'),
      };
      expect(
        tooltip,
        toEqualOptions(<String, Object?>{
          'opacity': 1,

          // Text
          'title': <Object?>[
            'beforeTitle',
            'newline',
            'title',
            'newline',
            'afterTitle',
            'newline',
          ],
          'beforeBody': <Object?>['beforeBody', 'newline'],
          'body': <Object?>[newlineBodyItem(), newlineBodyItem()],
          'afterBody': <Object?>['afterBody', 'newline'],
          'footer': <Object?>[
            'beforeFooter',
            'newline',
            'footer',
            'newline',
            'afterFooter',
            'newline',
          ],
          'labelTextColors': <Object?>['labelTextColor', 'labelTextColor'],
          'labelColors': <Object?>[labelColor(), labelColor()],
        }),
      );
    });

    group('text align', () {
      AnyObject makeView(String title, String body, String footer) {
        final model = <String, Object?>{};
        return model..addAll(<String, Object?>{
          // Positioning
          'x': 100,
          'y': 100,
          'width': 100,
          'height': 100,
          'xAlign': 'left',
          'yAlign': 'top',

          'options': <String, Object?>{
            'setContext': () => model['options'],
            'enabled': true,

            'padding': 5,

            // Body
            'bodyFont': <String, Object?>{
              'family': _font('family'),
              'style': _font('style'),
              'size': _font('size'),
            },
            'bodyColor': '#fff',
            'bodyAlign': body,
            'bodySpacing': 2,

            // Title
            'titleFont': <String, Object?>{
              'family': _font('family'),
              'weight': 'bold',
              'size': _font('size'),
            },
            'titleColor': '#fff',
            'titleAlign': title,
            'titleSpacing': 2,
            'titleMarginBottom': 6,

            // Footer
            'footerFont': <String, Object?>{
              'family': _font('family'),
              'weight': 'bold',
              'size': _font('size'),
            },
            'footerColor': '#fff',
            'footerAlign': footer,
            'footerSpacing': 2,
            'footerMarginTop': 6,

            // Appearance
            'caretSize': 5,
            'cornerRadius': 6,
            'caretPadding': 2,
            'borderColor': '#aaa',
            'borderWidth': 1,
            'backgroundColor': 'rgba(0,0,0,0.8)',
            'multiKeyBackground': '#fff',
            'displayColors': false,
          },
          'opacity': 1,

          // Text
          'title': <Object?>['title'],
          'beforeBody': <Object?>[],
          'body': <Object?>[_bodyItem('label')],
          'afterBody': <Object?>[],
          'footer': <Object?>['footer'],
          'labelTextColors': <Object?>['#fff'],
          'labelColors': <Object?>[
            <String, Object?>{
              'borderColor': 'rgb(255, 0, 0)',
              'backgroundColor': 'rgb(0, 255, 0)',
            },
            <String, Object?>{
              'borderColor': 'rgb(0, 0, 255)',
              'backgroundColor': 'rgb(0, 255, 255)',
            },
          ],
        });
      }

      // The mock records each declared parameter: the absent arguments of
      // `fill`, `stroke` and `fillText` are `null`
      // (harness-mock-optional-args).
      List<Object?> drawBody() => <Object?>[
        <String, Object?>{'name': 'save', 'args': <Object?>[]},
        <String, Object?>{
          'name': 'setFillStyle',
          'args': <Object?>['rgba(0,0,0,0.8)'],
        },
        <String, Object?>{
          'name': 'setStrokeStyle',
          'args': <Object?>['#aaa'],
        },
        <String, Object?>{
          'name': 'setLineWidth',
          'args': <Object?>[1],
        },
        <String, Object?>{'name': 'beginPath', 'args': <Object?>[]},
        <String, Object?>{
          'name': 'moveTo',
          'args': <Object?>[106, 100],
        },
        <String, Object?>{
          'name': 'lineTo',
          'args': <Object?>[106, 100],
        },
        <String, Object?>{
          'name': 'lineTo',
          'args': <Object?>[111, 95],
        },
        <String, Object?>{
          'name': 'lineTo',
          'args': <Object?>[116, 100],
        },
        <String, Object?>{
          'name': 'lineTo',
          'args': <Object?>[194, 100],
        },
        <String, Object?>{
          'name': 'quadraticCurveTo',
          'args': <Object?>[200, 100, 200, 106],
        },
        <String, Object?>{
          'name': 'lineTo',
          'args': <Object?>[200, 194],
        },
        <String, Object?>{
          'name': 'quadraticCurveTo',
          'args': <Object?>[200, 200, 194, 200],
        },
        <String, Object?>{
          'name': 'lineTo',
          'args': <Object?>[106, 200],
        },
        <String, Object?>{
          'name': 'quadraticCurveTo',
          'args': <Object?>[100, 200, 100, 194],
        },
        <String, Object?>{
          'name': 'lineTo',
          'args': <Object?>[100, 106],
        },
        <String, Object?>{
          'name': 'quadraticCurveTo',
          'args': <Object?>[100, 100, 106, 100],
        },
        <String, Object?>{'name': 'closePath', 'args': <Object?>[]},
        <String, Object?>{
          'name': 'fill',
          'args': <Object?>[null, null],
        },
        <String, Object?>{
          'name': 'stroke',
          'args': <Object?>[null],
        },
      ];

      /// The calls of the title, the body and the footer after [drawBody]:
      /// the aligns [titleAlign], [bodyAlign] and [footerAlign] at the x
      /// positions [titleX], [bodyX] and [footerX].
      List<Object?> textCalls(
        String titleAlign,
        num titleX,
        String bodyAlign,
        num bodyX,
        String footerAlign,
        num footerX,
      ) => <Object?>[
        <String, Object?>{
          'name': 'setTextAlign',
          'args': <Object?>[titleAlign],
        },
        <String, Object?>{
          'name': 'setTextBaseline',
          'args': <Object?>['middle'],
        },
        <String, Object?>{
          'name': 'setFillStyle',
          'args': <Object?>['#fff'],
        },
        <String, Object?>{
          'name': 'setFont',
          'args': <Object?>[_boldFont],
        },
        <String, Object?>{
          'name': 'fillText',
          'args': <Object?>['title', titleX, 112.2, null],
        },
        <String, Object?>{
          'name': 'setTextAlign',
          'args': <Object?>[bodyAlign],
        },
        <String, Object?>{
          'name': 'setTextBaseline',
          'args': <Object?>['middle'],
        },
        <String, Object?>{
          'name': 'setFont',
          'args': <Object?>[_normalFont],
        },
        <String, Object?>{
          'name': 'setFillStyle',
          'args': <Object?>['#fff'],
        },
        <String, Object?>{
          'name': 'setFillStyle',
          'args': <Object?>['#fff'],
        },
        <String, Object?>{
          'name': 'fillText',
          'args': <Object?>['label', bodyX, 132.6, null],
        },
        <String, Object?>{
          'name': 'setTextAlign',
          'args': <Object?>[footerAlign],
        },
        <String, Object?>{
          'name': 'setTextBaseline',
          'args': <Object?>['middle'],
        },
        <String, Object?>{
          'name': 'setFillStyle',
          'args': <Object?>['#fff'],
        },
        <String, Object?>{
          'name': 'setFont',
          'args': <Object?>[_boldFont],
        },
        <String, Object?>{
          'name': 'fillText',
          'args': <Object?>['footer', footerX, 153, null],
        },
        <String, Object?>{'name': 'restore', 'args': <Object?>[]},
      ];

      // :1485-1497. The tooltip is one object for the four cases, as the
      // `var` of the describe body. The chart is a `types.Chart` stub with
      // `getContext` and `options` (Chart.js ADR 0039, section 15).
      final mockContext = createMockContext();
      late final tooltip = jsConstruct(_tooltipClass(), [
        <String, Object?>{'chart': _TextAlignChart()},
      ]) as Tooltip;

      test('Should go left', () {
        mockContext.resetCalls();
        merge(tooltip, makeView('left', 'left', 'left'));
        tooltip.draw(mockContext);

        expect(
          mockContext.getCalls(),
          jasmineEquals(<Object?>[
            ...drawBody(),
            ...textCalls('left', 105, 'left', 105, 'left', 105),
          ]),
        );
      });

      test('Should go right', () {
        mockContext.resetCalls();
        merge(tooltip, makeView('right', 'right', 'right'));
        tooltip.draw(mockContext);

        expect(
          mockContext.getCalls(),
          jasmineEquals(<Object?>[
            ...drawBody(),
            ...textCalls('right', 195, 'right', 195, 'right', 195),
          ]),
        );
      });

      test('Should center', () {
        mockContext.resetCalls();
        merge(tooltip, makeView('center', 'center', 'center'));
        tooltip.draw(mockContext);

        expect(
          mockContext.getCalls(),
          jasmineEquals(<Object?>[
            ...drawBody(),
            ...textCalls('center', 150, 'center', 150, 'center', 150),
          ]),
        );
      });

      test('Should allow mixed', () {
        mockContext.resetCalls();
        merge(tooltip, makeView('right', 'center', 'left'));
        tooltip.draw(mockContext);

        expect(
          mockContext.getCalls(),
          jasmineEquals(<Object?>[
            ...drawBody(),
            ...textCalls('right', 195, 'center', 150, 'left', 105),
          ]),
        );
      });
    });

    group('active elements', () {
      testWidgets('should set the active elements', (tester) async {
        final chart = acquireChart(_line(_oneDataset()));

        final meta = chart.getDatasetMeta(0);
        chart.tooltip!.setActiveElements([
          <String, Object?>{'datasetIndex': 0, 'index': 0},
        ], _point(0, 0));
        expect(
          chart.tooltip!.getActiveElements()[0].element,
          same(meta.data[0]),
        );
      });

      testWidgets(
        'should not replace the user set active elements by event replay',
        (tester) async {
          final chart = acquireChart(
            _line(_oneDataset(), <String, Object?>{
              'events': <Object?>['pointerdown', 'pointerup'],
            }),
          );

          final meta = chart.getDatasetMeta(0);
          final point0 = meta.data[0];
          final point1 = meta.data[1];

          await triggerMouseEvent(
            chart,
            'pointerdown',
            _point(point0.x, point0.y),
          );
          expect(chart.tooltip!.opacity, 1);
          expect(
            _activeItems(chart.tooltip!.getActiveElements()),
            jasmineEquals(<Object?>[
              <String, Object?>{
                'datasetIndex': 0,
                'index': 0,
                'element': point0,
              },
            ]),
          );

          chart.tooltip!.setActiveElements([
            <String, Object?>{'datasetIndex': 0, 'index': 1},
          ]);
          chart.update();
          expect(chart.tooltip!.opacity, 1);
          expect(
            _activeItems(chart.tooltip!.getActiveElements()),
            jasmineEquals(<Object?>[
              <String, Object?>{
                'datasetIndex': 0,
                'index': 1,
                'element': point1,
              },
            ]),
          );

          chart.tooltip!.setActiveElements([]);
          chart.update();
          expect(chart.tooltip!.opacity, 0);
          expect(chart.tooltip!.getActiveElements().length, 0);
        },
      );

      testWidgets(
        'should not change the active elements on events outside chartArea, '
        'except for mouseout',
        (tester) async {
          final chart = acquireChart(<String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'labels': <Object?>['A', 'B', 'C', 'D'],
              'datasets': <Object?>[
                <String, Object?>{
                  'data': <Object?>[10, 20, 30, 100],
                },
              ],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{
                'x': <String, Object?>{'display': false},
                'y': <String, Object?>{'display': false},
              },
              'layout': <String, Object?>{'padding': 5},
            },
          });

          final point = chart.getDatasetMeta(0).data[0];

          await triggerMouseEvent(chart, 'mousemove', _point(point.x, point.y));
          expect(
            _activeItems(chart.tooltip!.getActiveElements()),
            jasmineEquals(<Object?>[
              <String, Object?>{
                'datasetIndex': 0,
                'index': 0,
                'element': point,
              },
            ]),
          );

          await triggerMouseEvent(chart, 'mousemove', _point(1, 1));
          expect(
            _activeItems(chart.tooltip!.getActiveElements()),
            jasmineEquals(<Object?>[
              <String, Object?>{
                'datasetIndex': 0,
                'index': 0,
                'element': point,
              },
            ]),
          );

          await triggerMouseEvent(chart, 'mouseout', _point(1, 1));
          expect(
            _activeItems(chart.tooltip!.getActiveElements()),
            jasmineEquals(<Object?>[]),
          );
        },
      );

      testWidgets(
        'should update active elements when datasets are removed and added',
        (tester) async {
          final dataset = <String, Object?>{
            'label': 'Dataset 1',
            'data': <Object?>[10, 20, 30],
            'pointHoverBorderColor': 'rgb(255, 0, 0)',
            'pointHoverBackgroundColor': 'rgb(0, 255, 0)',
          };
          final chart = acquireChart(
            _line(
              <String, Object?>{
                'datasets': <Object?>[dataset],
                'labels': <Object?>['Point 1', 'Point 2', 'Point 3'],
              },
              _tooltipOptions(<String, Object?>{
                'mode': 'nearest',
                'intersect': true,
              }),
            ),
          );

          final meta = chart.getDatasetMeta(0);
          final point = meta.data[1];
          final expectedPoint = objectContaining(<String, Object?>{
            'datasetIndex': 0,
            'index': 1,
          });

          await triggerMouseEvent(chart, 'mousemove', point);

          expect(_activeItems(chart.tooltip!.getActiveElements()), [
            expectedPoint,
          ]);

          chart.data['datasets'] = <Object?>[];
          chart.update();

          expect(
            _activeItems(chart.tooltip!.getActiveElements()),
            jasmineEquals(<Object?>[]),
          );

          chart.data['datasets'] = <Object?>[dataset];
          chart.update();

          expect(_activeItems(chart.tooltip!.getActiveElements()), [
            expectedPoint,
          ]);
        },
      );
    });

    testWidgets(
      'should tolerate datasets removed on events outside chartArea',
      (
        tester,
      ) async {
        final dataset1 = <String, Object?>{
          'label': 'Dataset 1',
          'data': <Object?>[10, 20, 30],
        };
        final dataset2 = <String, Object?>{
          'label': 'Dataset 2',
          'data': <Object?>[10, 25, 35],
        };
        final chart = acquireChart(
          _line(
            <String, Object?>{
              'datasets': <Object?>[dataset1, dataset2],
              'labels': <Object?>['Point 1', 'Point 2', 'Point 3'],
            },
            _tooltipOptions(<String, Object?>{
              'mode': 'index',
              'intersect': false,
            }),
          ),
        );

        final meta = chart.getDatasetMeta(0);
        final point = meta.data[1];
        final expectedPoints = [
          objectContaining(<String, Object?>{'datasetIndex': 0, 'index': 1}),
          objectContaining(<String, Object?>{'datasetIndex': 1, 'index': 1}),
        ];

        await triggerMouseEvent(chart, 'mousemove', point);
        await triggerMouseEvent(
          chart,
          'mousemove',
          _point(chart.chartArea!.left - 5, point.y),
        );

        expect(
          _activeItems(chart.tooltip!.getActiveElements()),
          expectedPoints,
        );

        chart.data['datasets'] = <Object?>[dataset1];
        chart.update();

        await triggerMouseEvent(chart, 'mousemove', _point(2, 1));

        expect(_activeItems(chart.tooltip!.getActiveElements()), [
          expectedPoints[0],
        ]);
      },
    );

    testWidgets(
      'should tolerate elements removed on events outside chartArea',
      (
        tester,
      ) async {
        final dataset1 = <String, Object?>{
          'label': 'Dataset 1',
          'data': <Object?>[10, 20, 30],
        };
        final dataset2 = <String, Object?>{
          'label': 'Dataset 2',
          'data': <Object?>[10, 25, 35],
        };
        final chart = acquireChart(
          _line(
            <String, Object?>{
              'datasets': <Object?>[dataset1, dataset2],
              'labels': <Object?>['Point 1', 'Point 2', 'Point 3'],
            },
            _tooltipOptions(<String, Object?>{
              'mode': 'index',
              'intersect': false,
            }),
          ),
        );

        final meta = chart.getDatasetMeta(0);
        final point = meta.data[1];
        final expectedPoints = [
          objectContaining(<String, Object?>{'datasetIndex': 0, 'index': 1}),
          objectContaining(<String, Object?>{'datasetIndex': 1, 'index': 1}),
        ];

        await triggerMouseEvent(chart, 'mousemove', point);
        await triggerMouseEvent(
          chart,
          'mousemove',
          _point(chart.chartArea!.left - 5, point.y),
        );

        expect(
          _activeItems(chart.tooltip!.getActiveElements()),
          expectedPoints,
        );

        dataset1['data'] = (dataset1['data']! as List<Object?>).sublist(0, 1);
        chart.data['datasets'] = <Object?>[dataset1];
        chart.update();

        await triggerMouseEvent(chart, 'mousemove', _point(2, 1));

        expect(
          _activeItems(chart.tooltip!.getActiveElements()),
          jasmineEquals(<Object?>[]),
        );
      },
    );

    group('events', () {
      testWidgets('should not be called on events not in plugin events array', (
        tester,
      ) async {
        final chart = acquireChart(
          _line(
            _oneDataset(),
            _tooltipOptions(<String, Object?>{
              'events': <Object?>['click'],
            }),
          ),
        );

        final meta = chart.getDatasetMeta(0);
        final point = meta.data[1];

        await triggerMouseEvent(chart, 'mousemove', point);
        expect(chart.tooltip!.opacity, 0);
        await triggerMouseEvent(chart, 'click', point);
        expect(chart.tooltip!.opacity, 1);
      });
    });

    testWidgets(
      'should use default callback if user callback returns undefined',
      (
        tester,
      ) async {
        Undefined returnsUndefined() => undefined;
        final chart = acquireChart(
          _line(
            _twoDatasets(),
            _tooltipOptions(<String, Object?>{
              'callbacks': <String, Object?>{
                'beforeTitle': returnsUndefined,
                'title': returnsUndefined,
                'afterTitle': returnsUndefined,
                'beforeBody': returnsUndefined,
                'beforeLabel': returnsUndefined,
                'label': returnsUndefined,
                'afterLabel': returnsUndefined,
                'afterBody': returnsUndefined,
                'beforeFooter': returnsUndefined,
                'footer': returnsUndefined,
                'afterFooter': returnsUndefined,
                'labelTextColor': returnsUndefined,
                'labelPointStyle': returnsUndefined,
              },
            }),
          ),
        );
        final tooltip = _tooltipOf(chart);
        final point = chart.getDatasetMeta(0).data[0];

        await triggerMouseEvent(chart, 'mousemove', point);

        expect(
          tooltip,
          objectContaining(<String, Object?>{
            'opacity': 1,

            // Text
            'title': <Object?>['Point 1'],
            'beforeBody': <Object?>[],
            'body': <Object?>[_bodyItem('Dataset 1: 10')],
            'afterBody': <Object?>[],
            'footer': <Object?>[],
            'labelTextColors': <Object?>['#fff'],
            'labelColors': <Object?>[_defaultLabelColor()],
            'labelPointStyles': <Object?>[
              <String, Object?>{'pointStyle': 'circle', 'rotation': 0},
            ],
          }),
        );
      },
    );
  });
}
