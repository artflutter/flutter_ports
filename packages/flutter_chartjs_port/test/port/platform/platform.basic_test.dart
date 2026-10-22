// Original code, not ported from Chart.js: BasicPlatform without a chart.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/platform/platform.basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

// test/specs/platform.basic_test.dart covers the chart cases. These tests
// cover the two methods of src/platform/platform.basic.js without a chart.

/// A canvas element whose `getContext('2d')` gives [context].
final class _Canvas implements HTMLCanvasElement {
  _Canvas(this.context);

  final CanvasRenderingContext2D? context;

  final List<String> contextIds = [];

  @override
  CanvasRenderingContext2D? getContext(String contextId) {
    contextIds.add(contextId);
    return context;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Context implements CanvasRenderingContext2D {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Config implements types.ChartConfiguration {
  @override
  final Map<String, Object?> options = {'animation': <String, Object?>{}};

  @override
  final Map<String, Object?> data = {};
}

void main() {
  setUpSpecs();
  group('BasicPlatform', () {
    test('acquireContext gives the 2d context of the canvas', () {
      final context = _Context();
      final canvas = _Canvas(context);
      expect(BasicPlatform().acquireContext(canvas), same(context));
      expect(canvas.contextIds, ['2d']);
    });

    test('acquireContext gives null for a canvas without a context', () {
      expect(BasicPlatform().acquireContext(_Canvas(null)), isNull);
    });

    test('acquireContext gives null for an item that is not a canvas', () {
      expect(BasicPlatform().acquireContext('foobar'), isNull);
      expect(BasicPlatform().acquireContext(null), isNull);
      expect(BasicPlatform().acquireContext([_Canvas(_Context())]), isNull);
    });

    test('updateConfig disables animations', () {
      final config = _Config();
      BasicPlatform().updateConfig(config);
      expect(config.options['animation'], false);
    });

    test('keeps the other base methods', () {
      final platform = BasicPlatform();
      expect(platform.getDevicePixelRatio(), 1);
      expect(platform.isAttached(null), isTrue);
      expect(platform.releaseContext(_Context()), isFalse);
    });
  });
}
