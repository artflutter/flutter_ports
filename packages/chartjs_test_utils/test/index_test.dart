// Original code, not ported from Chart.js: tests of the chart registry.
@TestOn('vm')
library;

import 'dart:ui' show Size;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/src/index.dart' show charts;
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_test/flutter_test.dart';

// acquireChart, releaseChart and releaseCharts of chartjs-test-utils 0.4.0
// src/index.js, with _releaseChart of src/utils.js (Chart.js ADR 0022,
// sections 4 and 8). main() has the set-up of flutter_test_config.dart:
// releaseCharts at the unmount of the harness body, and in a tearDown as
// the fallback (`harness-release-at-unmount`).

/// The hooks `beforeDestroy` and `afterDestroy` of each chart, by the name
/// of its plugin.
final List<String> _destroys = [];

/// An inline plugin that logs the destroy hooks into [_destroys] as
/// `'<name> <hook>'`.
Map<String, Object?> _destroyLog(String name) => <String, Object?>{
  'id': 'destroyLog',
  'beforeDestroy': (Object? chart, Object? args, Object? options) {
    _destroys.add('$name beforeDestroy');
  },
  'afterDestroy': (Object? chart, Object? args, Object? options) {
    _destroys.add('$name afterDestroy');
  },
};

/// A chart of [acquireChart] whose plugin logs as [name].
Chart _acquire(String name, [Map<String, Object?>? options]) => acquireChart(
  <String, Object?>{
    'plugins': [_destroyLog(name)],
  },
  options,
);

/// The wrapper of the chart of the unmount test.
late HarnessElement _released;

/// The count of the `beforeDestroy` hooks of [name].
int _destroyCount(String name) =>
    _destroys.where((line) => line == '$name beforeDestroy').length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The set-up of flutter_test_config.dart (Chart.js ADR 0022, section 8).
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
          .platformDispatcher
          .implicitView!
      ..devicePixelRatio = 1
      ..physicalSize = const Size(800, 600);
  });
  afterEachChart(releaseCharts);
  tearDown(releaseCharts);

  group('the registry charts', () {
    testWidgets('acquireChart adds the chart, and releaseChart releases and '
        'deletes it', (tester) async {
      final chart = _acquire('a');
      final wrapper = chart.canvas!.parentElement!;
      expect(charts[chart.id], same(chart));
      expect(wrapper.parentNode, same(document.body));

      releaseChart(chart);
      expect(charts.containsKey(chart.id), isFalse);
      expect(chart.canvas, isNull);
      expect(wrapper.parentNode, isNull);
      expect(_destroyCount('a'), 1);
    });

    testWidgets('releaseCharts releases each chart, keeps it, and releases '
        'it again without a throw', (tester) async {
      final first = _acquire('b1');
      final second = _acquire('b2');
      final wrapper = first.canvas!.parentElement!;
      final keys = charts.keys.toList();
      // The ids grow: the insertion order is the order of Object.keys.
      expect(keys.indexOf(first.id), lessThan(keys.indexOf(second.id)));

      releaseCharts();
      expect(first.canvas, isNull);
      expect(second.canvas, isNull);
      expect(wrapper.parentNode, isNull);
      expect(charts[first.id], same(first));
      expect(charts[second.id], same(second));
      expect(_destroyCount('b1'), 1);

      // A second call destroys the chart again and removes its wrapper
      // again. The plugins get no hook after `uninstall`
      // (core.plugins.js:40-42, :49), as upstream.
      document.body.appendChild(wrapper);
      releaseCharts();
      expect(wrapper.parentNode, isNull);
      expect(_destroyCount('b1'), 1);
      expect(_destroyCount('b2'), 1);
    });

    testWidgets('releaseCharts keeps a persistent chart', (tester) async {
      final chart = _acquire('c', <String, Object?>{'persistent': true});
      releaseCharts();
      expect(chart.canvas, isNotNull);
      expect(_destroyCount('c'), 0);
      // releaseChart releases it.
      releaseChart(chart);
      expect(_destroyCount('c'), 1);
    });
  });

  group('harness-release-at-unmount', () {
    final log = <String>[];

    tearDown(() {
      log.add('tearDown');
    });

    testWidgets('the unmount of the body releases the charts', (tester) async {
      final chart = _acquire('d');
      final wrapper = chart.canvas!.parentElement!;
      _released = wrapper;
      addTearDown(() {
        // The release ran before the tearDown functions.
        log.add('addTearDown ${_destroyCount('d')} ${chart.canvas == null}');
        // After the unmount, the append changes only the element tree. The
        // tearDown fallback removes the wrapper again.
        document.body.appendChild(wrapper);
      });
    });

    testWidgets('the tearDown fallback runs after the tearDown functions of '
        'the groups', (tester) async {
      expect(log, ['addTearDown 1 true', 'tearDown']);
      expect(_released.parentNode, isNull);
    });
  });
}
