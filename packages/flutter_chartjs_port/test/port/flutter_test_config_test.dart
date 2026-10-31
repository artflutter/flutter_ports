// Original code, not ported from Chart.js: tests of test/flutter_test_config.dart.
@TestOn('vm')
library;

import 'dart:ui' as ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.animation.dart';
import 'package:flutter_chartjs_port/src/core/core.animator.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_test/flutter_test.dart';

// The set-up of test/flutter_test_config.dart, the port of Chart.js
// test/index.js. This file does not call setUpSpecs(): the restore of the
// global scopes and the built-in components come from the config file
// alone.

/// `Chart.defaults.elements[id]`.
Object? _elementDefaults(String id) => jsGet(defaults['elements'], id);

/// `Chart.defaults.plugins[id]`.
Object? _pluginDefaults(String id) => jsGet(defaults['plugins'], id);

/// Whether a test of the group `harness-register-builtins` wrote
/// `defaults.plugins.colors.enabled = true`.
bool _colorsWritten = false;

/// Whether a test read `defaults.plugins.colors.enabled` as false after an
/// earlier test wrote true.
bool _colorsRestored = false;

/// The number of tests that read and wrote
/// `defaults.plugins.colors.enabled`.
int _colorsRuns = 0;

/// The hooks of the charts of the group `harness-release-at-unmount`.
final List<String> _releaseLog = [];

/// An inline plugin that logs the destroy hooks of a chart into
/// [_releaseLog].
Map<String, Object?> _destroyLog() => <String, Object?>{
  'id': 'destroyLog',
  'afterDestroy': (Object? chart, Object? args, Object? options) {
    _releaseLog.add('afterDestroy');
  },
};

/// The element class that a test of the group `harness-register-builtins`
/// leaves registered.
final JsClass _keptElement = JsClass(
  'KeptElement',
  superclass: Element.jsClass,
  statics: {
    'id': 'harnessKept',
    'defaults': <String, Object?>{'kept': true},
  },
);

/// Whether a test found [_keptElement] that an earlier test registered.
bool _keptFound = false;

/// The number of tests of the group `harness-register-builtins` that
/// registered or found [_keptElement].
int _keptRuns = 0;

/// The width of 'Hello' in a paragraph of [family] at 12px.
double _helloWidth(String family) {
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle())
    ..pushStyle(ui.TextStyle(fontFamily: family, fontSize: 12))
    ..addText('Hello');
  final paragraph = builder.build()
    ..layout(const ui.ParagraphConstraints(width: double.infinity));
  final width = paragraph.maxIntrinsicWidth;
  paragraph.dispose();
  return width;
}

void main() {
  group('devicePixelRatio', () {
    testWidgets('the test view has a ratio of 1 and 800 x 600', (tester) async {
      expect(tester.view.devicePixelRatio, 1);
      expect(tester.view.physicalSize, const ui.Size(800, 600));
      // A test that resets the view gets the flutter_test default back.
      tester.view.reset();
      expect(tester.view.devicePixelRatio, 3);
    });

    testWidgets('the next test has a ratio of 1 again', (tester) async {
      expect(tester.view.devicePixelRatio, 1);
      expect(tester.view.physicalSize, const ui.Size(800, 600));
    });
  });

  group('harness-defaults-restore', () {
    // Each test checks the state of the snapshot first and then changes the
    // scopes. In any test order, the other test finds the restored state.
    late Object? color;

    setUpAll(() {
      color = defaults['color'];
    });

    void checkAndChange() {
      expect(defaults['color'], same(color));
      expect(defaults.jsHas('harnessKey'), isFalse);
      expect(overrides.jsHas('harnessType'), isFalse);
      defaults['color'] = 'changed';
      defaults['harnessKey'] = 1;
      overrides['harnessType'] = <String, Object?>{};
    }

    test('a test changes defaults and overrides', checkAndChange);

    test('the next test finds them restored', checkAndChange);
  });

  group('harness-release-at-unmount', () {
    tearDown(() {
      // The release at the unmount of the body ran before the tearDown
      // functions of the groups (Chart.js ADR 0022, section 8).
      expect(_releaseLog, ['afterDestroy']);
      _releaseLog.clear();
    });

    testWidgets('a chart with an animation that runs at the end of the body '
        'passes the end-of-test checks', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'plugins': [_destroyLog()],
      });
      final target = <String, Object?>{'value': 0.0};
      animator
        ..add(chart, [
          Animation(<String, Object?>{'duration': 10000}, target, 'value', 1.0),
        ])
        ..start(chart);
      await tester.pump(frameInterval);
      await tester.pump(frameInterval);
      // Without the release, flutter_test fails the test with "An animation
      // is still running even after the widget tree was disposed."
      expect(animator.running(chart), isTrue);
      expect(target['value'], greaterThan(0));
    });

    testWidgets('a pending resizeDelay timer at the end of the body passes '
        'the end-of-test checks', (tester) async {
      final chart = acquireChart(
        <String, Object?>{
          'options': <String, Object?>{
            'responsive': true,
            'maintainAspectRatio': false,
            'resizeDelay': 100,
          },
          'plugins': [_destroyLog()],
        },
        <String, Object?>{
          'canvas': <String, Object?>{'style': ''},
          'wrapper': <String, Object?>{'style': 'width: 300px; height: 350px'},
        },
      );
      chart.canvas!.parentElement!.style.width = '400px';
      // The first notification at the next layout, then the throttled
      // resize. The debounced update waits for its Timer of 100 ms.
      await tester.pump(frameInterval);
      await tester.pump(frameInterval);
      expect(chart.width, 400);
      // Without the release, flutter_test fails the test with "A Timer is
      // still pending even after the widget tree was disposed."
    });

    testWidgets('releaseCharts on released charts destroys them again '
        'without a throw', (tester) async {
      final chart = acquireChart(<String, Object?>{
        'plugins': [_destroyLog()],
      });
      final wrapper = chart.canvas!.parentElement!;
      releaseCharts();
      expect(chart.canvas, isNull);
      expect(wrapper.parentNode, isNull);
      expect(_releaseLog, ['afterDestroy']);

      // The second release removes the wrapper again. The plugins get no
      // hook after uninstall, as upstream.
      document.body.appendChild(wrapper);
      releaseCharts();
      expect(wrapper.parentNode, isNull);
      expect(_releaseLog, ['afterDestroy']);
    });
  });

  group('harness-register-builtins', () {
    // Each test checks the state of the snapshot first and then changes it.
    // In any test order, the other test finds the restored state.
    void checkAndChange() {
      // Chart.register(controllers, scales, elements, plugins) of
      // src/index.umd.ts:28 registers the elements in the code unit order
      // of the namespace.
      expect(jsObjectKeys(Chart.registry.elements.items).take(4), [
        'arc',
        'bar',
        'line',
        'point',
      ]);
      expect(Chart.registry.getElement('arc'), same(ArcElement.jsClass));
      expect(Chart.registry.getElement('bar'), same(BarElement.jsClass));
      expect(Chart.registry.getElement('line'), same(LineElement.jsClass));
      expect(Chart.registry.getElement('point'), same(PointElement.jsClass));
      expect(jsGet(_elementDefaults('point'), 'radius'), 3);
      expect(jsGet(_elementDefaults('arc'), 'borderWidth'), 2);
      expect(jsGet(descriptors['elements'], 'arc'), isNotNull);

      (_elementDefaults('point')! as JsObjectFace)['radius'] = 99;
      expect(jsGet(_elementDefaults('point'), 'radius'), 99);
    }

    test(
      'a test finds the built-in components and changes a default',
      checkAndChange,
    );

    test('the next test finds the default restored', checkAndChange);

    // The first test of the two registers _keptElement. The other finds it
    // in the items of the registry, without its defaults.
    void registerOrFind() {
      _keptRuns++;
      if (Chart.registry.elements.items.containsKey('harnessKept')) {
        expect(_elementDefaults('harnessKept'), same(undefined));
        _keptFound = true;
      } else {
        Chart.register([_keptElement]);
        expect(jsGet(_elementDefaults('harnessKept'), 'kept'), true);
      }
    }

    test(
      'a component that a test leaves registered stays in the items',
      registerOrFind,
    );

    test('the restore removes the defaults of that component', registerOrFind);

    // A test shard (`--total-shards`) can run one of the two tests only.
    // Then that test registers _keptElement and finds nothing.
    tearDownAll(() {
      expect(_keptFound, _keptRuns == 2);
    });

    // Chart.js ADR 0041, sections 6 and 13. The plugins register with the
    // other components, in the order of src/plugins/index.js:1-7, which is
    // the hook order (core.plugins.js:125-131). Then the config file ports
    // test/index.js:25-28: `defaults.plugins.colors.enabled = false`, before
    // the snapshot of the restore. Each test of the two reads false and then
    // writes true. A test that runs after a write of the other test reads
    // false only because of the restore. A shard (`--total-shards`) can run
    // one of the two tests only: then no test runs after a write.
    void checkColorsAndWrite() {
      expect(jsObjectKeys(Chart.registry.plugins.items), [
        'colors',
        'decimation',
        'filler',
        'legend',
        'subtitle',
        'title',
        'tooltip',
      ]);
      final colors = _pluginDefaults('colors')! as JsObjectFace;
      expect(colors['enabled'], isFalse);
      if (_colorsWritten) _colorsRestored = true;
      colors['enabled'] = true;
      expect(jsGet(_pluginDefaults('colors'), 'enabled'), isTrue);
      _colorsWritten = true;
      _colorsRuns++;
    }

    test(
      'the plugins are registered and the colors plugin is disabled',
      checkColorsAndWrite,
    );

    test(
      'the next test finds the colors plugin disabled again',
      checkColorsAndWrite,
    );

    tearDownAll(() {
      expect(_colorsRestored, _colorsRuns == 2);
    });

    testWidgets('a chart of acquireChart resolves the element defaults', (
      tester,
    ) async {
      final chart = acquireChart();
      final elements = jsGet(chart.options, 'elements');
      expect(jsGet(jsGet(elements, 'point'), 'radius'), 3);
      expect(jsGet(jsGet(elements, 'line'), 'tension'), 0);
      // The resolved option of the colors plugin (probe at the pin:
      // `chart.options.plugins.colors.enabled` is false).
      final plugins = jsGet(chart.options, 'plugins');
      expect(jsGet(jsGet(plugins, 'colors'), 'enabled'), isFalse);
    });
  });

  group('harness-test-font', () {
    test('Arial and the Chart.js default families use Liberation Sans', () {
      // 'Hello' is 4667 units of 2048 in Liberation Sans and in Arial.
      for (final family in ['Helvetica Neue', 'Helvetica', 'Arial']) {
        expect(
          _helloWidth(family),
          closeTo(4667 * 12 / 2048, 0.01),
          reason: family,
        );
      }
    });
  });
}
