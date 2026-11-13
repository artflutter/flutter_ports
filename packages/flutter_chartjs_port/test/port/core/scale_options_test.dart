// Original code, not ported from Chart.js: the scale option facades.
import 'dart:ui' as ui;
import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/core/core.adapters.dart' show TimeUnit;
import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart';
import 'package:flutter_chartjs_port/src/core/scale_options.dart';
import 'package:flutter_chartjs_port/src/helpers/grace_length.dart'
    show PercentGrace;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show ScaleOptionsScope;
import 'package:flutter_chartjs_port/src/types/axis_border.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:flutter_chartjs_port/src/types/layout.dart' show ChartPosition;
import 'package:intl/intl.dart' show NumberFormat;
import 'package:test/test.dart';

// The facades of lib/src/core/scale_options.dart (Chart.js ADR 0054 §4).
// A getter is the typed read readKey of its key: it gives the value of the
// get trap of the view, `view[name]`, with the same cache, also for a
// scriptable option, a nested option object and a value of another type.

/// The view of the options [scopes] with the context [context]: the
/// `ContextProxy` that a scale reads.
OptionView _view(List<Object?> scopes, [AnyObject? context]) =>
    attachContext(createResolver(scopes), context ?? <String, Object?>{});

/// The getters of [CoreScaleOptions], [CartesianScaleOptions],
/// [TimeScaleOptions] and [RadialLinearScaleOptions], by the JS name of their
/// key.
final Map<String, Object? Function(OptionView view)> _scaleGetters = {
  'display': (v) => CoreScaleOptions(v).display,
  'alignToPixels': (v) => CoreScaleOptions(v).alignToPixels,
  'backgroundColor': (v) => CoreScaleOptions(v).backgroundColor,
  'reverse': (v) => CoreScaleOptions(v).reverse,
  'clip': (v) => CoreScaleOptions(v).clip,
  'weight': (v) => CoreScaleOptions(v).weight,
  'min': (v) => CoreScaleOptions(v).min,
  'max': (v) => CoreScaleOptions(v).max,
  'suggestedMin': (v) => CoreScaleOptions(v).suggestedMin,
  'suggestedMax': (v) => CoreScaleOptions(v).suggestedMax,
  'beforeUpdate': (v) => CoreScaleOptions(v).beforeUpdate,
  'afterFit': (v) => CoreScaleOptions(v).afterFit,
  'axis': (v) => CoreScaleOptions(v).axis,
  'position': (v) => CoreScaleOptions(v).position,
  'offset': (v) => CoreScaleOptions(v).offset,
  'bounds': (v) => CoreScaleOptions(v).bounds,
  'labels': (v) => CoreScaleOptions(v).labels,
  'beginAtZero': (v) => CoreScaleOptions(v).beginAtZero,
  'grace': (v) => CoreScaleOptions(v).grace,
  'fullSize': (v) => CoreScaleOptions(v).fullSize,
  'stack': (v) => CartesianScaleOptions(v).stack,
  'stackWeight': (v) => CartesianScaleOptions(v).stackWeight,
  'stacked': (v) => CartesianScaleOptions(v).stacked,
  'offsetAfterAutoskip': (v) => TimeScaleOptions(v).offsetAfterAutoskip,
  'adapters': (v) => TimeScaleOptions(v).adapters,
  'animate': (v) => RadialLinearScaleOptions(v).animate,
  'startAngle': (v) => RadialLinearScaleOptions(v).startAngle,
};

/// A value of each key of [_scaleGetters], with other types than the
/// declared ones for some of them.
Map<String, Object?> _scaleValues() => {
  'display': 'auto',
  'alignToPixels': true,
  'backgroundColor': const ChartPaint.solid(ui.Color.fromRGBO(255, 0, 0, 1)),
  'reverse': true,
  'clip': false,
  'weight': '2',
  'min': 'a',
  'max': 10,
  'suggestedMin': null,
  'suggestedMax': undefined,
  'beforeUpdate': (Object? scale) => null,
  'afterFit': (Object? scale) => null,
  'axis': const YAxis(),
  'position': ChartPosition.left,
  'offset': true,
  'bounds': ScaleBounds.ticks,
  'labels': <Object?>['a', 'b'],
  'beginAtZero': false,
  'grace': const PercentGrace(5),
  'fullSize': false,
  'stack': 'group',
  'stackWeight': 2,
  'stacked': 'single',
  'offsetAfterAutoskip': true,
  'adapters': <String, Object?>{'date': 'utc'},
  'animate': false,
  'startAngle': '30',
};

void main() {
  group('the getters of the scale options', () {
    for (final MapEntry(key: name, value: getter) in _scaleGetters.entries) {
      test('$name reads as view[name]', () {
        final values = _scaleValues();
        final expected = _view([values])[name];
        final view = _view([values]);
        final actual = getter(view);
        expect(actual, same(expected));
        // The getter and the trap share the cache of the view.
        expect(view[name], same(actual));
      });
    }

    test('an absent key reads undefined, and false for an on/off key', () {
      final view = _view([<String, Object?>{}]);
      // Row adapt-bool-options: an absent on/off option is false.
      expect(CoreScaleOptions(view).offset, isFalse);
      expect(CoreScaleOptions(view).min, same(undefined));
      expect(CoreScaleOptions(view).ticks.raw, same(undefined));
    });

    test('stack is the option, not the _stack of the view', () {
      final view = _view([
        <String, Object?>{'stack': 'group'},
      ]);
      expect(CartesianScaleOptions(view).stack, 'group');
      expect(view.stack, isA<Set<String>>());
    });

    test('a scriptable option gets the context of the view', () {
      final calls = <Object?>[];
      final view = _view(
        [
          <String, Object?>{
            'reverse': (Object? ctx) {
              calls.add(ctx);
              return true;
            },
          },
        ],
        <String, Object?>{'type': 'scale'},
      );
      final options = CoreScaleOptions(view);
      expect(options.reverse, isTrue);
      expect(options.reverse, isTrue);
      // The view caches the value: one call.
      expect(calls, hasLength(1));
      expect((calls.single! as AnyObject)['type'], 'scale');
    });
  });

  group('the nested option objects', () {
    test('a nested object is a view of its sub-resolver', () {
      final options = CoreScaleOptions(
        _view([
          <String, Object?>{
            'ticks': <String, Object?>{'padding': '3', 'mirror': true},
            'grid': <String, Object?>{'tickLength': '8', 'drawTicks': true},
            'border': const AxisBorder(width: 2, dash: <double>[4]),
            'title': <String, Object?>{'display': true, 'text': 'T'},
          },
        ]),
      );
      expect(options.ticks.raw, isA<OptionView>());
      // A string padding and a string tickLength stay strings: their
      // readers join or convert them, as upstream.
      expect(options.ticks.padding, '3');
      expect(options.ticks.mirror, isTrue);
      expect(options.grid.tickLength, '8');
      expect(options.grid.drawTicks, isTrue);
      // The border is one object (Chart.js ADR 0141).
      expect(options.border, const AxisBorder(width: 2, dash: <double>[4]));
      expect(options.title.text, 'T');
      // No scope has `ticks.major` (the scale defaults hold `major: {}`):
      // the nested facade holds `undefined`, and its read throws the
      // `TypeError` of `undefined.enabled`, as upstream.
      expect(options.ticks.major.raw, same(undefined));
      expect(() => options.ticks.major.enabled, throwsA(isA<TypeError>()));
    });

    test('a primitive gives undefined for each key', () {
      final options = CoreScaleOptions(
        _view([
          <String, Object?>{'ticks': false, 'grid': 0},
        ]),
      );
      expect(options.ticks.raw, isFalse);
      // An absent on/off option is false (row adapt-bool-options).
      expect(options.ticks.display, isFalse);
      expect(options.grid.display, isFalse);
    });

    test('null and undefined throw a TypeError', () {
      final options = CoreScaleOptions(
        _view([
          <String, Object?>{'ticks': null},
        ]),
      );
      expect(() => options.ticks.display, throwsA(isA<TypeError>()));
      expect(() => options.grid.display, throwsA(isA<TypeError>()));
    });

    test('a plain Map reads by name', () {
      // The options of a fake scale of a test (core.ticks, autoskip).
      final format = NumberFormat.compact();
      final ticks = TickOptions(<String, Object?>{'format': format});
      expect(ticks.format, same(format));
      expect(ticks.count, same(undefined));
    });

    test('setContext gives a view with the context', () {
      final options = CoreScaleOptions(
        _view([
          <String, Object?>{
            'ticks': <String, Object?>{
              'color': (Object? ctx) {
                final index = jsToNumber((ctx! as AnyObject)['index']);
                return ChartPaint.solid(Color(0xff000000 + index.toInt()));
              },
            },
            'grid': <String, Object?>{
              'lineWidth': (Object? ctx) => (ctx! as AnyObject)['index'],
            },
          },
        ]),
      );
      final context = <String, Object?>{'index': 2.0};
      expect(
        options.ticks.setContext(context).color,
        const ChartPaint.solid(Color(0xff000002)),
      );
      expect(options.grid.setContext(context).lineWidth, 2.0);
    });

    test('setContext of a value that is not a view throws', () {
      const ticks = TickOptions(false);
      expect(
        () => ticks.setContext(<String, Object?>{}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('the foreign values of the scopes', () {
    test('a string startAngle of a typed scope stays a string', () {
      final scope = ScaleOptionsScope()..jsWrite('startAngle', '30');
      final options = RadialLinearScaleOptions(_view([scope]));
      expect(options.startAngle, '30');
    });

    test('a string point label padding stays a string', () {
      final options = RadialLinearScaleOptions(
        _view([
          <String, Object?>{
            'pointLabels': <String, Object?>{'padding': '5'},
          },
        ]),
      );
      expect(options.pointLabels.padding, '5');
    });
  });

  group('the display formats of the time scale', () {
    TimeScaleTimeOptions time() => TimeScaleOptions(
      _view([
        <String, Object?>{
          'time': <String, Object?>{
            'unit': TimeUnit.day,
            'displayFormats': <String, Object?>{
              'day': 'MMM d',
              'datetime': 'PPpp',
              'millisecond': 'h:mm:ss.SSS',
            },
          },
        },
      ]),
    ).time;

    test('formatOf reads the format of a unit', () {
      expect(time().displayFormats.formatOf(TimeUnit.day), 'MMM d');
      expect(time().displayFormats.formatOf(TimeUnit.year), same(undefined));
    });

    test('datetime, millisecond and unit', () {
      final t = time();
      expect(t.displayFormats.datetime, 'PPpp');
      expect(t.displayFormats.millisecond, 'h:mm:ss.SSS');
      expect(t.unit, TimeUnit.day);
      expect(t.parser, same(undefined));
    });
  });
}
