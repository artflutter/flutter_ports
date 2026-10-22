// Original code, not ported from Chart.js: helpers.collection port tests.
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:test/test.dart';

// Upstream behavior that test/specs/helpers.collection.tests.js does not
// check (AGENTS.md rule 3). The expected values come from
// src/helpers/helpers.collection.ts in Node.js v24.12.0 on x64.

/// A point element with only the members that the lookups read. The
/// control points are NaN, which stands for JS `undefined` (`SplinePoint`).
final class _Point implements PointElement {
  _Point(this.x, this.y);

  @override
  final double x;

  @override
  final double y;

  @override
  Map<String, Object?>? get options => null;

  @override
  bool? get skip => null;

  @override
  bool? get stop => null;

  @override
  double cp1x = double.nan;

  @override
  double cp1y = double.nan;

  @override
  double cp2x = double.nan;

  @override
  double cp2y = double.nan;

  // The members of Chart.js ADR 0028 that this test does not read.
  @override
  bool get active => false;

  @override
  Object? get hidden => undefined;

  @override
  double size([Map<String, Object?>? options]) =>
      throw UnsupportedError('size');
}

/// A listener that records each call, as the JavaScript objects of the
/// probe do.
final class _Listener with ArrayListener<double> {
  _Listener(this.name, this.log);

  final String name;
  final List<List<Object?>> log;

  /// Called after each call of [onDataPush].
  void Function()? afterPush;

  @override
  void onDataPush(List<double> items) {
    log.add(['$name push', ...items]);
    afterPush?.call();
  }

  @override
  void onDataPop() => log.add(['$name pop']);

  @override
  void onDataShift() => log.add(['$name shift']);

  @override
  void onDataSplice(double index, double deleteCount, List<double> items) =>
      log.add(['$name splice', index, deleteCount, ...items]);

  @override
  void onDataUnshift(List<double> items) =>
      log.add(['$name unshift', ...items]);
}

/// A listener that keeps the empty default members.
final class _EmptyListener with ArrayListener<double> {}

/// A listener of any element type, as a dataset controller of
/// `unknown[]` data is.
final class _AnyListener with ArrayListener<Object?> {
  final List<List<Object?>> log = [];

  @override
  void onDataPush(List<Object?> items) => log.add(['push', ...items]);

  @override
  void onDataSplice(double index, double deleteCount, List<Object?> items) =>
      log.add(['splice', index, deleteCount, ...items]);
}

/// Negative zero, spelled out. The int literal -0 is 0, not -0.
// ignore: prefer_int_literals
const double _negativeZero = -0.0;

/// Matches a double with the same value as [expected], where -0 differs from
/// +0, as `Object.is` does.
Matcher _isSameNumber(double expected) => predicate<double>(
  (actual) => actual == expected && actual.isNegative == expected.isNegative,
  'Object.is($expected)',
);

void main() {
  group('lookup', () {
    test('an empty table gives {lo: 0, hi: -1}', () {
      expect(lookup(<double>[], 5), (lo: 0, hi: -1));
      expect(lookup(<double>[1], 5), (lo: 0, hi: 0));
    });

    test('calls cmp with the indices of the search', () {
      final indices = <int>[];
      final result = lookup(<double>[0, 1, 2, 3, 4, 5, 6, 7], 0, (index) {
        indices.add(index);
        return index < 5;
      });
      expect(result, (lo: 4, hi: 5));
      expect(indices, [3, 5, 4]);
    });
  });

  group('lookupByKey', () {
    test('a missing key reads as undefined', () {
      expect(
        lookupByKey(
          [
            {'y': 1.0},
            {'y': 2.0},
            {'y': 3.0},
          ],
          'x',
          2,
        ),
        (lo: 0, hi: 1),
      );
      expect(
        lookupByKey(
          [
            {'x': undefined},
            {'x': undefined},
            {'x': undefined},
          ],
          'x',
          2,
        ),
        (lo: 0, hi: 1),
      );
    });

    test('compares null and strings through ToNumber', () {
      expect(
        lookupByKey(
          [
            {'x': null},
            {'x': 1.0},
            {'x': 2.0},
            {'x': 3.0},
          ],
          'x',
          0.5,
        ),
        (lo: 0, hi: 1),
      );
      expect(
        lookupByKey(
          [
            {'x': '1'},
            {'x': '2'},
            {'x': '3'},
            {'x': '4'},
          ],
          'x',
          2.5,
        ),
        (lo: 1, hi: 2),
      );
    });

    test('last compares with === and not through ToNumber', () {
      expect(
        lookupByKey(
          [
            {'x': 0.0},
            {'x': '5'},
            {'x': '5'},
            {'x': 9.0},
          ],
          'x',
          5,
          true,
        ),
        (lo: 0, hi: 1),
      );
      expect(
        lookupByKey(
          [
            {'x': 0.0},
            {'x': 5.0},
            {'x': 5.0},
            {'x': 9.0},
          ],
          'x',
          5,
          true,
        ),
        (lo: 1, hi: 2),
      );
      expect(
        lookupByKey(
          [
            {'x': 0.0},
            {'x': double.nan},
            {'x': double.nan},
            {'x': 9.0},
          ],
          'x',
          double.nan,
          true,
        ),
        (lo: 0, hi: 1),
      );
    });

    test('reads x and y of point elements', () {
      final points = [
        _Point(0, 9),
        _Point(2, 6),
        _Point(6, 2),
        _Point(9, 0),
      ];
      expect(lookupByKey(points, 'x', 3), (lo: 1, hi: 2));
      expect(lookupByKey(points, 'x', 9, true), (lo: 2, hi: 3));
      expect(rlookupByKey(points, 'y', 5), (lo: 1, hi: 2));
      expect(lookupByKey(points, 'r', 3), (lo: 0, hi: 1));
    });

    test('reads a map with other type arguments', () {
      final table = [
        <dynamic, dynamic>{'x': 0.0},
        <dynamic, dynamic>{'x': 1.0},
        <dynamic, dynamic>{'x': 2.0},
        <dynamic, dynamic>{'x': 3.0},
      ];
      expect(lookupByKey(table, 'x', 1.5), (lo: 1, hi: 2));
      expect(lookupByKey(table, 'x', 1, true), (lo: 0, hi: 1));
      expect(rlookupByKey(table, 'x', 1.5), (lo: 0, hi: 1));
    });

    test('throws a TypeError for a null entry', () {
      expect(
        () => lookupByKey(
          [
            {'x': 0.0},
            null,
            {'x': 2.0},
          ],
          'x',
          1,
        ),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('rlookupByKey', () {
    test('compares null and a missing key through ToNumber', () {
      expect(
        rlookupByKey(
          [
            {'x': 3.0},
            {'x': 2.0},
            {'x': null},
            <String, Object?>{},
          ],
          'x',
          1,
        ),
        (lo: 1, hi: 2),
      );
    });
  });

  group('filterBetween', () {
    test('returns the same array when no value is outside', () {
      final values = <double>[1, 2, 3];
      expect(filterBetween(values, 0, 9), same(values));
      expect(filterBetween(<double>[], 0, 1), <double>[]);
      expect(filterBetween(<double>[3, 2, 1], 2, 2), <double>[3, 2, 1]);
    });
  });

  group('arrayUnique', () {
    test('returns the same array when all items differ', () {
      final items = <double>[1, 2, 3];
      expect(arrayUnique(items), same(items));
      final zeros = <double>[_negativeZero, 1];
      expect(arrayUnique(zeros), same(zeros));
      expect(arrayUnique(zeros).first, _isSameNumber(_negativeZero));
    });

    test('compares with SameValueZero', () {
      final unique = arrayUnique(<double>[double.nan, 1, double.nan, 2, 1]);
      expect(unique, hasLength(3));
      expect(unique[0].isNaN, isTrue);
      expect(unique.sublist(1), <double>[1, 2]);
      expect(arrayUnique(<String>['a', 'b', 'a']), ['a', 'b']);
    });

    test('stores -0 as +0, as a Set does', () {
      final a = arrayUnique(<double>[0, _negativeZero]);
      expect(a, hasLength(1));
      expect(a.single, _isSameNumber(0));
      final b = arrayUnique(<double>[_negativeZero, 0]);
      expect(b, hasLength(1));
      expect(b.single, _isSameNumber(0));
    });

    test('compares objects by identity', () {
      final o = <String, Object?>{};
      expect(arrayUnique([o, o, <String, Object?>{}]), hasLength(2));
    });
  });

  group('platform-array-events', () {
    test('calls the listeners as the hooked methods do', () {
      // The calls of the probe: listen L1, L2, L1; push(3, 4), push(5),
      // pop(), splice(1, 1, 9, 8), shift(), unshift(0); unlisten L1;
      // push(6); unlisten L1; push(7). L2 unlistens itself in its push.
      final log = <List<Object?>>[];
      final a = <double>[1, 2];
      final l1 = _Listener('L1', log);
      final l2 = _Listener('L2', log);
      l2.afterPush = () => unlistenArrayEvents(a, l2);
      listenArrayEvents(a, l1);
      listenArrayEvents(a, l2);
      listenArrayEvents(a, l1);

      a.addAll([3, 4]);
      notifyArrayListeners(a, 'push', [3.0, 4.0]);
      a.add(5);
      notifyArrayListeners(a, 'push', [5.0]);
      a.removeLast();
      notifyArrayListeners(a, 'pop', []);
      a.replaceRange(1, 2, [9, 8]);
      notifyArrayListeners(a, 'splice', [1.0, 1.0, 9.0, 8.0]);
      a.removeAt(0);
      notifyArrayListeners(a, 'shift', []);
      a.insert(0, 0);
      notifyArrayListeners(a, 'unshift', [0.0]);
      unlistenArrayEvents(a, l1);
      a.add(6);
      notifyArrayListeners(a, 'push', [6.0]);
      unlistenArrayEvents(a, l1);
      a.add(7);
      notifyArrayListeners(a, 'push', [7.0]);

      expect(log, [
        ['L1 push', 3, 4],
        ['L2 push', 3, 4],
        ['L1 push', 5],
        ['L1 push', 5],
        ['L1 pop'],
        ['L1 pop'],
        ['L1 splice', 1, 1, 9, 8],
        ['L1 splice', 1, 1, 9, 8],
        ['L1 shift'],
        ['L1 shift'],
        ['L1 unshift', 0],
        ['L1 unshift', 0],
        ['L1 push', 6],
      ]);
      expect(a, <double>[0, 9, 8, 3, 4, 6, 7]);
    });

    test('does nothing for an array without listeners', () {
      final log = <List<Object?>>[];
      final listener = _Listener('L', log);
      final a = <double>[1];
      unlistenArrayEvents(a, listener);
      notifyArrayListeners(a, 'push', [2.0]);
      listenArrayEvents(<double>[1], listener);
      notifyArrayListeners(a, 'push', [2.0]);
      expect(log, isEmpty);
    });

    test('ignores the methods that are not hooked', () {
      final log = <List<Object?>>[];
      final a = <double>[1];
      listenArrayEvents(a, _Listener('L', log));
      notifyArrayListeners(a, 'reverse', []);
      expect(log, isEmpty);
    });

    test('calls a listener of another element type', () {
      // JavaScript has no element types: each listener gets the call.
      final data = <double>[1, 2];
      final any = _AnyListener();
      listenArrayEvents(data, any);
      notifyArrayListeners(data, 'push', [3.0]);
      expect(any.log, [
        ['push', 3.0],
      ]);

      final log = <List<Object?>>[];
      final typed = _Listener('L', log);
      listenArrayEvents(data, typed);
      final List<Object?> view = data;
      notifyArrayListeners(view, 'push', [4.0]);
      expect(any.log.last, ['push', 4.0]);
      expect(log, [
        ['L push', 4.0],
      ]);
    });

    test('gives int arguments as JavaScript numbers', () {
      final data = <double>[1, 2];
      final log = <List<Object?>>[];
      final any = _AnyListener();
      listenArrayEvents(data, _Listener('L', log));
      listenArrayEvents(data, any);
      notifyArrayListeners(data, 'push', [3]);
      notifyArrayListeners(data, 'splice', [1, 0, 7]);
      expect(log, [
        ['L push', 3.0],
        ['L splice', 1.0, 0.0, 7.0],
      ]);
      expect(any.log, [
        ['push', 3.0],
        ['splice', 1.0, 0.0, 7.0],
      ]);
      expect(
        any.log.expand((call) => call.skip(1)),
        everyElement(isA<double>()),
      );
    });

    test('a splice needs index and deleteCount', () {
      final log = <List<Object?>>[];
      final data = <double>[1, 2];
      listenArrayEvents(data, _Listener('L', log));
      expect(
        () => notifyArrayListeners(data, 'splice', [1.0]),
        throwsArgumentError,
      );
      expect(
        () => notifyArrayListeners(data, 'splice', []),
        throwsArgumentError,
      );
      expect(log, isEmpty);
    });

    test('the default members do nothing', () {
      final a = <double>[1];
      listenArrayEvents(a, _EmptyListener());
      for (final key in ['push', 'pop', 'shift', 'unshift']) {
        notifyArrayListeners(a, key, [2.0]);
      }
      notifyArrayListeners(a, 'splice', [0.0, 1.0, 2.0]);
    });
  });
}
