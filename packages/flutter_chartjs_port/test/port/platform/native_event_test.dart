// Original code, not ported from Chart.js: tests of the port-only native event.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:test/test.dart';

void main() {
  setUpSpecs();
  group('NativeEvent', () {
    test('keeps the DOM event fields', () {
      final target = Object();
      final source = Object();
      final event = NativeEvent(
        type: 'touchstart',
        offsetX: double.nan,
        offsetY: double.nan,
        touches: const [(identifier: 1, x: 10, y: 20)],
        target: target,
        source: source,
      );
      expect(event.type, 'touchstart');
      expect(event.offsetX, isNaN);
      expect(event.offsetY, isNaN);
      expect(event.touches, [(identifier: 1, x: 10.0, y: 20.0)]);
      expect(event.target, same(target));
      expect(event.source, same(source));
    });

    test('has no touches, target or source by default', () {
      final event = NativeEvent(type: 'mousemove', offsetX: 1, offsetY: 2);
      expect(event.touches, isEmpty);
      expect(event.target, isNull);
      expect(event.source, isNull);
      expect(event.toString(), contains('mousemove'));
    });
  });
}
