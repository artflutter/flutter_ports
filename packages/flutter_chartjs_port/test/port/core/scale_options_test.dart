// Original code, not ported from Chart.js: the scale option facades.
import 'package:flutter_chartjs_port/src/core/scale_options.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show ScaleOptionsScope;
import 'package:flutter_chartjs_port/src/types/basic.dart';
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
  'alignToPixels': 1,
  'backgroundColor': 'red',
  'reverse': true,
  'clip': false,
  'weight': '2',
  'min': 'a',
  'max': 10,
  'suggestedMin': null,
  'suggestedMax': undefined,
  'beforeUpdate': (Object? scale) => null,
  'afterFit': (Object? scale) => null,
  'axis': 'y',
  'position': 'left',
  'offset': true,
  'bounds': 'ticks',
  'labels': <Object?>['a', 'b'],
  'beginAtZero': 0,
  'grace': '5%',
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

    test('an absent key reads undefined', () {
      final view = _view([<String, Object?>{}]);
      expect(CoreScaleOptions(view).offset, same(undefined));
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
              return 'yes';
            },
          },
        ],
        <String, Object?>{'type': 'scale'},
      );
      final options = CoreScaleOptions(view);
      expect(options.reverse, 'yes');
      expect(options.reverse, 'yes');
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
            'border': <String, Object?>{
              'width': 2,
              'dash': <Object?>[4],
            },
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
      expect(options.border.width, 2);
      expect(options.border.dash, [4]);
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
      expect(options.ticks.display, same(undefined));
      expect(options.grid.display, same(undefined));
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
      const ticks = TickOptions(<String, Object?>{'format': 'f'});
      expect(ticks.format, 'f');
      expect(ticks.count, same(undefined));
    });

    test('setContext gives a view with the context', () {
      final options = CoreScaleOptions(
        _view([
          <String, Object?>{
            'ticks': <String, Object?>{
              'color': (Object? ctx) {
                final index = jsToNumber((ctx! as AnyObject)['index']);
                return 'c${jsNumberToString(index)}';
              },
            },
            'grid': <String, Object?>{
              'lineWidth': (Object? ctx) => (ctx! as AnyObject)['index'],
            },
          },
        ]),
      );
      final context = <String, Object?>{'index': 2.0};
      expect(options.ticks.setContext(context).color, 'c2');
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

    test('a string font size stays a string', () {
      final options = CoreScaleOptions(
        _view([
          <String, Object?>{
            'ticks': <String, Object?>{
              'font': <String, Object?>{'size': '12'},
            },
          },
        ]),
      );
      expect(FontSpecOptions(options.ticks.font).size, '12');
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
            'unit': 'day',
            'displayFormats': <String, Object?>{
              'day': 'MMM d',
              'fortnight': 'w',
              'datetime': 'PPpp',
              'millisecond': 'h:mm:ss.SSS',
              'false': 'no',
            },
          },
        },
      ]),
    ).time;

    test('formatOf reads a unit of the schema', () {
      expect(time().displayFormats.formatOf('day'), 'MMM d');
    });

    test('formatOf reads another unit by name', () {
      expect(time().displayFormats.formatOf('fortnight'), 'w');
      expect(time().displayFormats.formatOf('year'), same(undefined));
    });

    test('formatOf reads the property key of another value', () {
      // `displayFormats[false]` reads the key 'false'.
      expect(time().displayFormats.formatOf(false), 'no');
    });

    test('datetime, millisecond and unit', () {
      final t = time();
      expect(t.displayFormats.datetime, 'PPpp');
      expect(t.displayFormats.millisecond, 'h:mm:ss.SSS');
      expect(t.unit, 'day');
      expect(t.parser, same(undefined));
    });
  });
}
