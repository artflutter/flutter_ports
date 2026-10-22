// Original code, not ported from Chart.js: core.scale.defaults tests.
import 'package:flutter_chartjs_port/src/core/core.scale.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.ticks.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show createResolver;
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:test/test.dart';

import 'recording_defaults.dart';

// core.scale.defaults.js has no spec. The expected values come from Node.js
// v24.12.0 (V8 13.6) on x64. It ran the upstream applyScaleDefaults on an
// object that records each call (recording_defaults.dart), and called the
// recorded functions.

void main() {
  group('applyScaleDefaults', () {
    late RecordingDefaults defaults;

    setUp(() {
      defaults = RecordingDefaults();
      applyScaleDefaults(defaults);
    });

    /// The values argument of the call at [index].
    Map<String, Object?> values(int index) =>
        defaults.calls[index][2]! as Map<String, Object?>;

    test('sets, routes and describes the scale defaults', () {
      const setScale =
          '["set","scale",{"display":true,"offset":false,"reverse":false,'
          '"beginAtZero":false,"bounds":"ticks","clip":true,"grace":0,'
          '"grid":{"display":true,"lineWidth":1,"drawOnChartArea":true,'
          '"drawTicks":true,"tickLength":8,"tickWidth":"<fn>",'
          '"tickColor":"<fn>","offset":false},'
          '"border":{"display":true,"dash":[],"dashOffset":0,"width":1},'
          '"title":{"display":false,"text":"",'
          '"padding":{"top":4,"bottom":4}},'
          '"ticks":{"minRotation":0,"maxRotation":50,"mirror":false,'
          '"textStrokeWidth":0,"textStrokeColor":"","padding":3,'
          '"display":true,"autoSkip":true,"autoSkipPadding":3,'
          '"labelOffset":0,"callback":"<values>","minor":{},"major":{},'
          '"align":"center","crossAlign":"near","showLabelBackdrop":false,'
          '"backdropColor":"rgba(255, 255, 255, 0.75)","backdropPadding":2}}]';
      const describeScale =
          '["describe","scale",{"_fallback":false,"_scriptable":"<fn>",'
          '"_indexable":"<fn>"}]';
      const describeScaleTicks =
          '["describe","scale.ticks",{"_scriptable":"<fn>",'
          '"_indexable":"<fn>"}]';
      expect(defaults.calls.map(probeJson), [
        setScale,
        '["route","scale.ticks","color","","color"]',
        '["route","scale.grid","color","","borderColor"]',
        '["route","scale.border","color","","borderColor"]',
        '["route","scale.title","color","","color"]',
        describeScale,
        '["describe","scales",{"_fallback":"scale"}]',
        describeScaleTicks,
      ]);
    });

    test('ticks.callback is Ticks.formatters.values', () {
      final ticks = values(0)['ticks']! as Map<String, Object?>;
      expect(identical(ticks['callback'], formatters['values']), isTrue);
    });

    test('grid.tickWidth and grid.tickColor read the grid options', () {
      final grid = values(0)['grid']! as Map<String, Object?>;
      final context = <String, Object?>{};
      expect(
        jsCall(grid['tickWidth'], [
          context,
          <String, Object?>{'lineWidth': 3.0},
        ]),
        3,
      );
      expect(
        jsCall(grid['tickColor'], [
          context,
          <String, Object?>{'color': 'red'},
        ]),
        'red',
      );
    });

    test('grid.tickWidth and grid.tickColor read a property', () {
      final grid = values(0)['grid']! as Map<String, Object?>;
      final context = <String, Object?>{};
      // options.lineWidth of {} is undefined, not null.
      expect(
        jsCall(grid['tickWidth'], [context, <String, Object?>{}]),
        same(undefined),
      );
      expect(
        jsCall(grid['tickColor'], [
          context,
          <String, Object?>{'color': null},
        ]),
        isNull,
      );
      // A property read of a number gives undefined.
      expect(jsCall(grid['tickWidth'], [context, 5.0]), same(undefined));
      // A property read of undefined or null throws a TypeError.
      for (final options in [undefined, null]) {
        expect(
          () => jsCall(grid['tickWidth'], [context, options]),
          throwsA(isA<TypeError>()),
        );
      }
    });

    test('grid.tickWidth and grid.tickColor read a resolver', () {
      final grid = values(0)['grid']! as Map<String, Object?>;
      // The has trap of a prefixed resolver does not know 'lineWidth' and
      // 'color'. The get trap gives the null of the prefixed keys.
      final options = createResolver(
        [
          <String, Object?>{'hoverLineWidth': null, 'hoverColor': null},
        ],
        ['hover', ''],
      );
      final context = <String, Object?>{};
      expect(jsCall(grid['tickWidth'], [context, options]), isNull);
      expect(jsCall(grid['tickColor'], [context, options]), isNull);
    });

    test('scale._scriptable and scale._indexable', () {
      final descriptor = values(5);
      final scriptable = descriptor['_scriptable'];
      for (final (name, expected) in [
        ('beforeFit', false),
        ('afterFit', false),
        ('callback', false),
        ('parser', false),
        ('color', true),
        ('before', false),
        ('after', false),
        ('Before', true),
        ('ticks', true),
      ]) {
        expect(jsCall(scriptable, [name]), expected, reason: name);
      }
      final indexable = descriptor['_indexable'];
      for (final (name, expected) in [
        ('borderDash', false),
        ('tickBorderDash', false),
        ('dash', false),
        ('color', true),
      ]) {
        expect(jsCall(indexable, [name]), expected, reason: name);
      }
    });

    test('scale.ticks._scriptable and scale.ticks._indexable', () {
      final descriptor = values(7);
      final scriptable = descriptor['_scriptable'];
      final indexable = descriptor['_indexable'];
      for (final (name, isScriptable, isIndexable) in [
        ('backdropPadding', false, false),
        ('callback', false, true),
        ('color', true, true),
      ]) {
        expect(jsCall(scriptable, [name]), isScriptable, reason: name);
        expect(jsCall(indexable, [name]), isIndexable, reason: name);
      }
    });
  });
}
