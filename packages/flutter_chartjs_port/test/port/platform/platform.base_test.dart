// Original code, not ported from Chart.js: platform.base has no own spec.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/platform/platform.base.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

// test/specs has no platform.base.tests.js. These tests cover the methods of
// src/platform/platform.base.js (AGENTS.md rule 3). The expected sizes follow
// the upstream lines: `width || element.width`, `Math.max(0, …)` and
// `Math.floor(width / aspectRatio)`.

/// A canvas element with a render size. Only `width` and `height` are read.
final class _Canvas implements HTMLCanvasElement {
  _Canvas(this.width, this.height);

  @override
  int width;

  @override
  int height;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A chart object. The base platform reads none of its members.
final class _Chart implements types.Chart {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A context object. The base platform reads none of its members.
final class _Context implements CanvasRenderingContext2D {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A config object `{options}`.
final class _Config implements types.ChartConfiguration {
  @override
  final Map<String, Object?> options = {'animation': true};
}

void main() {
  setUpSpecs();
  group('BasePlatform', () {
    final platform = BasePlatform();

    test('acquireContext gives undefined', () {
      expect(platform.acquireContext(_Canvas(300, 150)), isNull);
      expect(platform.acquireContext('foobar', 2), isNull);
    });

    test('releaseContext gives false', () {
      expect(platform.releaseContext(_Context()), isFalse);
    });

    test('the listener methods do nothing', () {
      final chart = _Chart();
      var called = false;
      void listener() {
        called = true;
      }

      expect(
        () => platform
          ..addEventListener(chart, 'click', listener)
          ..removeEventListener(chart, 'click', listener)
          ..removeEventListener(chart, 'click'),
        returnsNormally,
      );
      expect(called, isFalse);
    });

    test('getDevicePixelRatio gives 1', () {
      expect(platform.getDevicePixelRatio(), 1);
    });

    test('isAttached gives true', () {
      expect(platform.isAttached(_Canvas(300, 150)), isTrue);
      expect(platform.isAttached(null), isTrue);
    });

    test('updateConfig does not change the config', () {
      final config = _Config();
      platform.updateConfig(config);
      expect(config.options, {'animation': true});
    });

    group('getMaximumSize', () {
      final canvas = _Canvas(300, 150);

      ({double width, double height}) size(
        double? width,
        double? height, [
        double? aspectRatio,
      ]) => platform.getMaximumSize(canvas, width, height, aspectRatio);

      test('takes the canvas size for an undefined, 0 or NaN size', () {
        expect(size(null, null), (width: 300.0, height: 150.0));
        expect(size(0, 0), (width: 300.0, height: 150.0));
        expect(size(double.nan, double.nan), (width: 300.0, height: 150.0));
      });

      test('takes the given size', () {
        expect(size(401.5, 99.25), (width: 401.5, height: 99.25));
      });

      test('gives the floor of width / aspectRatio', () {
        expect(size(401, 1000, 3), (width: 401.0, height: 133.0));
        expect(size(null, null, 2), (width: 300.0, height: 150.0));
      });

      test('ignores a falsy aspect ratio', () {
        expect(size(400, 300, 0), (width: 400.0, height: 300.0));
        expect(size(400, 300, double.nan), (width: 400.0, height: 300.0));
      });

      test('clamps negative sizes to 0', () {
        expect(size(-5, -7), (width: 0.0, height: 0.0));
        expect(size(400, 300, -2), (width: 400.0, height: 0.0));
      });
    });
  });
}
