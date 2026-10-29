// Original code, not ported from Chart.js: the tests of the UMD entry of src/index.umd.ts.
@TestOn('vm')
library;

import 'package:flutter_chartjs_port/src/core/core.adapters.dart';
import 'package:flutter_chartjs_port/src/core/core.animation.dart';
import 'package:flutter_chartjs_port/src/core/core.animations.dart';
import 'package:flutter_chartjs_port/src/core/core.animator.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.interaction.dart';
import 'package:flutter_chartjs_port/src/core/core.layouts.dart';
import 'package:flutter_chartjs_port/src/core/core.registry.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/core/core.ticks.dart';
import 'package:flutter_chartjs_port/src/index.dart'
    show controllers, elements, plugins, scales;
import 'package:flutter_chartjs_port/src/index.umd.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/platform/index.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

import 'index_umd_reference.dart';

// The UMD entry of Chart.js ADR 0048, section 1: `chartUmd` is the class
// value `Chart.jsClass` after the body of src/index.umd.ts:28-47. The
// reference data come from dist/chart.umd.js of the pinned build
// (tool/reference/index_umd_reference.mjs): `Object.keys(Chart)`,
// `Object.keys(Chart.helpers)` and `Object.keys(Chart.platforms)` in order.
// A JsClass has no key order and no `Object.keys` (js_class.dart). Thus the
// test reads each key of `Object.keys(Chart)` with `has` and compares its
// value with the Dart object.
//
// flutter_test_config.dart registers the built-in components before main()
// (harness-register-builtins). The registration of :28 then finds each
// component in the registry and adds nothing. Each test reads `chartUmd`
// itself: the first read in the isolate runs the body, in any shard.

/// The matcher of the value of each key of `Object.keys(Chart)`: the Dart
/// object of the key.
final Map<String, Matcher> _chartValues = {
  // core.controller.js:105-110, the statics of `class Chart`.
  'defaults': same(Chart.defaults),
  'instances': same(Chart.instances),
  'overrides': same(Chart.overrides),
  'registry': same(registry),
  'version': equals(Chart.version),
  'getChart': same(Chart.getChart),
  // index.umd.ts:30-43. `helpers` is a new copy and `Interaction` a new
  // Map: the groups below test them.
  'helpers': isA<Map<String, Object?>>(),
  '_adapters': same(adapters),
  'Animation': same(Animation.jsClass),
  'Animations': same(Animations.jsClass),
  'animator': same(animator),
  'controllers': same(registry.controllers.items),
  'DatasetController': same(DatasetController.jsClass),
  'Element': same(Element.jsClass),
  'elements': same(elements),
  'Interaction': isA<Map<String, Object?>>(),
  'layouts': same(layouts),
  'platforms': isA<Map<String, Object?>>(),
  'Scale': same(Scale.jsClass),
  'Ticks': same(ticks),
  // index.umd.ts:46, the keys of the five sources.
  for (final source in [controllers, scales, elements, plugins])
    for (final key in jsObjectKeys(source)) key: same(source[key]),
  'BasePlatform': same(BasePlatform.jsClass),
  'BasicPlatform': same(BasicPlatform.jsClass),
  'DomPlatform': same(FlutterPlatform.jsClass),
  '_detectPlatform': same(detectPlatform),
  // index.umd.ts:47.
  'Chart': same(Chart.jsClass),
};

/// The keys of `Object.keys(Chart)` with no Dart member, each with its
/// reason. Each key of the pinned bundle has a Dart member.
const Map<String, String> _noDartMember = {};

void main() {
  group('platform-umd-entry', () {
    test('chartUmd is the class value of Chart', () {
      expect(chartUmd, same(Chart.jsClass));
      expect(chartUmd.name, 'Chart');
      expect(jsGet(chartUmd, 'Chart'), same(chartUmd));
    });

    test('a second read gives the same object, and the body runs once', () {
      final first = chartUmd;
      final helpers = jsGet(first, 'helpers');
      expect(chartUmd, same(first));
      expect(jsGet(chartUmd, 'helpers'), same(helpers));
    });

    test('Chart.controllers is the items of the controllers registry', () {
      expect(jsGet(chartUmd, 'controllers'), same(registry.controllers.items));
      // A second read registers nothing more: the 8 controller ids once.
      expect(chartUmd, same(Chart.jsClass));
      expect(jsObjectKeys(registry.controllers.items), [
        'bar',
        'bubble',
        'doughnut',
        'line',
        'pie',
        'polarArea',
        'radar',
        'scatter',
      ]);
    });

    test('each key of Object.keys(Chart) has its Dart object', () {
      expect(indexUmdReferenceCommit, startsWith('76d8cf89'));
      for (final key in indexUmdReferenceChartKeys) {
        if (_noDartMember.containsKey(key)) continue;
        final matcher = _chartValues[key];
        expect(matcher, isNotNull, reason: 'the key $key has no Dart member');
        expect(chartUmd.has(key), isTrue, reason: key);
        expect(jsGet(chartUmd, key), matcher, reason: key);
      }
      expect(
        _chartValues.keys.toSet(),
        indexUmdReferenceChartKeys.toSet(),
        reason: 'the test has a key that the bundle does not have',
      );
    });

    test('the static methods register and unregister are statics', () {
      // core.controller.js:112-120: not enumerable, so not in the reference
      // keys, but `Chart.register` is a static property.
      expect(indexUmdReferenceChartKeys, isNot(contains('register')));
      expect(jsGet(chartUmd, 'register'), same(Chart.register));
      expect(jsGet(chartUmd, 'unregister'), same(Chart.unregister));
    });

    test('Chart.helpers has the helpers keys in order', () {
      final helpers = jsGet(chartUmd, 'helpers')! as AnyObject;
      expect(jsObjectKeys(helpers), indexUmdReferenceHelpersKeys);
      for (final key in indexUmdReferenceHelpersKeys) {
        expect(helpers[key], isNotNull, reason: key);
        expect(helpers[key], isNot(same(undefined)), reason: key);
      }
      // The spread of :30 gives a plain object: a write changes it.
      helpers['custom'] = 1;
      expect(helpers['custom'], 1);
      helpers.remove('custom');
    });

    test('Chart.platforms has the platform keys in order', () {
      final platforms = jsGet(chartUmd, 'platforms')! as AnyObject;
      expect(jsObjectKeys(platforms), indexUmdReferencePlatformsKeys);
      expect(platforms['_detectPlatform'], same(detectPlatform));
      expect(
        jsConstruct(platforms['BasePlatform'], const []),
        isA<BasePlatform>(),
      );
      expect(
        jsConstruct(platforms['BasicPlatform'], const []),
        isA<BasicPlatform>(),
      );
      // DomPlatform gives the class value of the replacement
      // (platform-umd-dom-platform).
      final domPlatform = platforms['DomPlatform']! as JsClass;
      expect(domPlatform.name, 'FlutterPlatform');
      expect(domPlatform.superclass, same(BasePlatform.jsClass));
      expect(jsConstruct(domPlatform, const []), isA<FlutterPlatform>());
      expect(() => platforms['X'] = 1, throwsA(isA<UnsupportedError>()));
    });

    testWidgets('new Chart(item) constructs a Chart', (tester) async {
      // core.controller.js:123. An item that is not a canvas gives a chart
      // without a context (`Failed to create chart`).
      final chart = jsConstruct(chartUmd, ['foobar']);
      expect(chart, isA<Chart>());
      expect((chart as Chart).canvas, isNull);
      chart.destroy();
      expect(Chart.instances, isEmpty);
    });
  });

  group('adapt-umd-namespace-objects', () {
    test('Chart.Interaction is a Map of the two statics', () {
      final interaction = jsGet(chartUmd, 'Interaction')! as AnyObject;
      expect(jsObjectKeys(interaction), ['evaluateInteractionItems', 'modes']);
      expect(
        interaction['evaluateInteractionItems'],
        same(Interaction.evaluateInteractionItems),
      );
      expect(interaction['modes'], same(Interaction.modes));
    });

    test('a mode added through Chart.Interaction.modes reaches the class', () {
      final modes = jsGet(jsGet(chartUmd, 'Interaction'), 'modes')! as Map;
      addTearDown(() => Interaction.modes.remove('custom'));
      modes['custom'] = Interaction.modes['index'];
      expect(Interaction.modes['custom'], same(Interaction.modes['index']));
    });

    test('a write of a new key into Chart.Interaction throws', () {
      // Upstream adds a property to the plain object.
      final interaction = jsGet(chartUmd, 'Interaction')! as AnyObject;
      expect(
        () => interaction['custom'] = 1,
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('Chart.layouts is the record of core.layouts', () {
      expect(jsGet(chartUmd, 'layouts'), same(layouts));
      // A record has no read by name.
      expect(jsGet(jsGet(chartUmd, 'layouts'), 'addBox'), same(undefined));
    });
  });
}
