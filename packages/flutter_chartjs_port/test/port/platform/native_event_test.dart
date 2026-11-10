// Original code, not ported from Chart.js: tests of the port-only native event.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:test/test.dart';

// Chart.js ADR 0108: the DOM fields of the native event with the defaults of
// the DOM init dictionaries, preventDefault, stopPropagation, the target of
// a dispatch and DOMRect.

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

    test('has the defaults of the DOM init dictionaries', () {
      final event = NativeEvent(type: 'wheel', offsetX: 1, offsetY: 2);
      // EventInit.
      expect(event.bubbles, isFalse);
      expect(event.cancelable, isFalse);
      expect(event.defaultPrevented, isFalse);
      // MouseEventInit.
      expect((event.clientX, event.clientY), (0.0, 0.0));
      expect((event.button, event.buttons), (0, 0));
      expect(
        (event.ctrlKey, event.altKey, event.shiftKey, event.metaKey),
        (false, false, false, false),
      );
      // PointerEventInit.
      expect((event.pointerId, event.pointerType), (0, ''));
      // WheelEventInit.
      expect((event.deltaX, event.deltaY, event.deltaMode), (0.0, 0.0, 0));
      // KeyboardEventInit.
      expect(event.key, '');
    });

    test('keeps the given DOM fields', () {
      final event = NativeEvent(
        type: 'pointerdown',
        offsetX: 1,
        offsetY: 2,
        bubbles: true,
        cancelable: true,
        clientX: 11.5,
        clientY: 12.25,
        button: 2,
        buttons: 3,
        pointerId: 4,
        pointerType: 'pen',
        deltaX: 5,
        deltaY: -6,
        deltaMode: 1,
        key: 'Escape',
        ctrlKey: true,
        altKey: true,
        shiftKey: true,
        metaKey: true,
      );
      expect((event.bubbles, event.cancelable), (true, true));
      expect((event.clientX, event.clientY), (11.5, 12.25));
      expect((event.button, event.buttons), (2, 3));
      expect((event.pointerId, event.pointerType), (4, 'pen'));
      expect((event.deltaX, event.deltaY, event.deltaMode), (5.0, -6.0, 1));
      expect(event.key, 'Escape');
      expect(
        (event.ctrlKey, event.altKey, event.shiftKey, event.metaKey),
        (true, true, true, true),
      );
      // A fraction prints the same on the VM and on the web.
      expect(event.toString(), contains('client: (11.5, 12.25)'));
    });
  });

  group('preventDefault', () {
    test('sets defaultPrevented on a cancelable event', () {
      final event = NativeEvent(
        type: 'wheel',
        offsetX: 0,
        offsetY: 0,
        cancelable: true,
      )..preventDefault();
      expect(event.defaultPrevented, isTrue);
    });

    test('does nothing on an event that is not cancelable', () {
      final event = NativeEvent(type: 'mouseenter', offsetX: 0, offsetY: 0)
        ..preventDefault();
      expect(event.defaultPrevented, isFalse);
    });

    test('does nothing in a passive listener', () {
      final event = NativeEvent(
        type: 'wheel',
        offsetX: 0,
        offsetY: 0,
        cancelable: true,
      );
      invokeNativeEventListener(
        (e) => e.preventDefault(),
        event,
        passive: true,
      );
      expect(event.defaultPrevented, isFalse);
      // The passive state ends with the listener.
      event.preventDefault();
      expect(event.defaultPrevented, isTrue);
    });

    test('works in a listener that is not passive', () {
      final event = NativeEvent(
        type: 'touchmove',
        offsetX: double.nan,
        offsetY: double.nan,
        cancelable: true,
      );
      invokeNativeEventListener(
        (e) => e.preventDefault(),
        event,
        passive: false,
      );
      expect(event.defaultPrevented, isTrue);
    });

    test('a passive listener that throws ends the passive state', () {
      final event = NativeEvent(
        type: 'wheel',
        offsetX: 0,
        offsetY: 0,
        cancelable: true,
      );
      expect(
        () => invokeNativeEventListener(
          (e) => throw StateError('listener'),
          event,
          passive: true,
        ),
        throwsStateError,
      );
      event.preventDefault();
      expect(event.defaultPrevented, isTrue);
    });
  });

  group('stopPropagation and the target', () {
    test('stopPropagation sets the stop flag of the dispatch', () {
      final event = NativeEvent(type: 'click', offsetX: 0, offsetY: 0);
      expect(nativeEventStopped(event), isFalse);
      event.stopPropagation();
      expect(nativeEventStopped(event), isTrue);
    });

    test('a dispatch sets the target and clears the stop flag', () {
      final first = Object();
      final second = Object();
      final event = NativeEvent(
        type: 'click',
        offsetX: 0,
        offsetY: 0,
        target: first,
      )..stopPropagation();
      setNativeEventTarget(event, second);
      expect(event.target, same(second));
      expect(nativeEventStopped(event), isFalse);
    });
  });

  group('DOMRect', () {
    test('gives the edges of a positive size', () {
      const rect = DOMRect(10, 20, 30, 40);
      expect((rect.x, rect.y, rect.width, rect.height), (10, 20, 30, 40));
      expect((rect.left, rect.top, rect.right, rect.bottom), (10, 20, 40, 60));
    });

    test('normalizes the edges of a negative size', () {
      const rect = DOMRect(10, 20, -30, -40);
      expect((rect.width, rect.height), (-30, -40));
      expect(
        (rect.left, rect.top, rect.right, rect.bottom),
        (-20, -20, 10, 20),
      );
    });

    test('zero has all zeros and compares by value', () {
      expect(
        (
          DOMRect.zero.left,
          DOMRect.zero.top,
          DOMRect.zero.right,
          DOMRect.zero.bottom,
        ),
        (0, 0, 0, 0),
      );
      expect(const DOMRect(1, 2, 3, 4), const DOMRect(1, 2, 3, 4));
      expect(const DOMRect(1, 2, 3, 4), isNot(const DOMRect(1, 2, 3, 5)));
      expect(
        const DOMRect(1, 2, 3, 4).hashCode,
        const DOMRect(1, 2, 3, 4).hashCode,
      );
      expect(const DOMRect(1, 2, 3, 4).toString(), contains('DOMRect'));
    });
  });
}
