// Original code, not ported from Chart.js: the eased factors of one tick loop.
import 'package:flutter/animation.dart' show Cubic, Curve, Curves;
import 'package:flutter_chartjs_port/src/core/animation_ease.dart';
import 'package:flutter_chartjs_port/src/core/core.animation.dart';
import 'package:test/test.dart';

import '../../support/animation_spec_input.dart';

// The table of `lib/src/core/animation_ease.dart` (row
// `adapt-animation-ease-table`): each result is the result of the curve call
// that the table stands for, and each guard declines to that call. The twin
// of a `Cubic` is an object of a subclass with the same fields: the class
// guard declines it, so each of its ticks calls the curve.

/// The count of the solves of each [_TwinCubic] object. A curve class is
/// immutable, so the count is not a field. Each test starts it at 0.
int _twinSolves = 0;

/// A subclass of [Cubic] with the fields of [Cubic]: it gives the values of
/// the SDK class and counts its solves in [_twinSolves].
final class const _TwinCubic(super.a, super.b, super.c, super.d) extends Cubic {
  factory of(Cubic curve) => _TwinCubic(curve.a, curve.b, curve.c, curve.d);

  @override
  double transformInternal(double t) {
    _twinSolves++;
    return super.transformInternal(t);
  }
}

/// The count of the calls of each [_Square] object.
int _squareCalls = 0;

/// A curve of another class than [Cubic]: it counts its calls in
/// [_squareCalls].
final class const _Square() extends Curve {
  @override
  double transformInternal(double t) {
    _squareCalls++;
    return t * t;
  }
}

/// Whether [a] and [b] are the same double: the same value and the same
/// sign of a zero, or NaN both.
bool _same(double a, double b) =>
    (a.isNaN && b.isNaN) || (a == b && a.isNegative == b.isNegative);

/// Whether this run counts the hits and the misses: only an `assert` counts
/// them.
bool get _counts {
  var on = false;
  assert(() {
    return on = true;
  }(), 'Sets the flag.');
  return on;
}

/// Runs [body] with the table on, as inside one `Animator.update` call.
void _inTable(void Function() body) {
  easeTableBegin();
  try {
    body();
  } finally {
    easeTableEnd();
  }
}

/// A number animation of `target.value` from 0 to 10 with [cfg].
Animation _animation(Map<String, Object?> target, Map<String, Object?> cfg) =>
    Animation(animationSpecOf(cfg), target, 'value', 10.0);

void main() {
  setUp(() {
    _twinSolves = 0;
    _squareCalls = 0;
  });

  // No test leaves the table on for the next test.
  tearDown(() => expect(easeTableActive, isFalse));

  group('easeTableAt', () {
    test('gives the result of the curve for each input, bit for bit', () {
      // A second object with the fields of the default curve, made at run
      // time: it is not the constant object.
      final copy = Cubic(
        Curves.easeOutQuart.a,
        Curves.easeOutQuart.b,
        Curves.easeOutQuart.c,
        Curves.easeOutQuart.d,
      );
      final curves = <Cubic>[
        Curves.easeOutQuart,
        Curves.easeInOutCubic,
        Curves.easeInBack,
        Curves.fastOutSlowIn,
        copy,
      ];
      _inTable(() {
        final hits = debugEaseTableHits;
        final misses = debugEaseTableMisses;
        var inRange = 0;
        for (final curve in curves) {
          for (var i = 0; i <= 2000; i++) {
            // Whole milliseconds of 1000, of 400 and of 3 ms.
            for (final t in [i / 2000, (i % 401) / 400, (i % 4) / 3]) {
              final expected = curve.transform(t);
              // The first call can make the entry, the second call reads it.
              for (var call = 0; call < 2; call++) {
                expect(
                  _same(easeTableAt(curve, t), expected),
                  isTrue,
                  reason: '$curve at $t, call $call',
                );
              }
              if (t > 0 && t < 1) inRange++;
            }
          }
        }
        if (_counts) {
          // Each call above 0 and below 1 is a hit or a miss, and each
          // second call is a hit.
          final newHits = debugEaseTableHits - hits;
          final newMisses = debugEaseTableMisses - misses;
          expect(newHits + newMisses, 2 * inRange);
          expect(newHits, greaterThanOrEqualTo(inRange));
          expect(newMisses, greaterThan(curves.length * 256));
        }
        expect(debugEaseTableEntries, greaterThan(0));
      });
    });

    test('the inputs 0, -0 and 1 make no entry', () {
      const curve = Curves.easeOutQuart;
      final negativeZero = double.parse('-0');
      _inTable(() {
        final hits = debugEaseTableHits;
        final misses = debugEaseTableMisses;
        for (var pass = 0; pass < 2; pass++) {
          for (final t in [0.0, negativeZero, 1.0]) {
            expect(_same(easeTableAt(curve, t), curve.transform(t)), isTrue);
          }
        }
        expect(easeTableAt(curve, negativeZero).isNegative, isTrue);
        expect(debugEaseTableEntries, 0);
        expect(debugEaseTableHits, hits);
        expect(debugEaseTableMisses, misses);
      });
    });

    test('a value outside the range gives the result or the error of the '
        'curve', () {
      const curve = Curves.easeOutQuart;
      // The result of [call], or the type of its error.
      Object outcome(double Function() call) {
        try {
          return call();
        } on Object catch (error) {
          return error.runtimeType;
        }
      }

      _inTable(() {
        for (final t in [double.nan, -0.5, 1.5]) {
          final direct = outcome(() => curve.transform(t));
          final table = outcome(() => easeTableAt(curve, t));
          expect(table, direct, reason: 'at $t');
        }
        expect(debugEaseTableEntries, 0);
      });
    });

    test('a curve of another class keeps each call', () {
      const square = _Square();
      _inTable(() {
        final hits = debugEaseTableHits;
        for (var i = 0; i < 5; i++) {
          expect(easeTableAt(square, 0.3), 0.3 * 0.3);
        }
        expect(_squareCalls, 5);
        for (final curve in <Curve>[
          Curves.linear,
          Curves.bounceIn,
          Curves.elasticOut,
          Curves.ease.flipped,
        ]) {
          for (var i = 0; i < 3; i++) {
            expect(_same(easeTableAt(curve, 0.3), curve.transform(0.3)), true);
          }
        }
        expect(debugEaseTableEntries, 0);
        expect(debugEaseTableHits, hits);
      });
    });

    test('a subclass of Cubic keeps each call', () {
      final twin = _TwinCubic.of(Curves.easeOutQuart);
      _inTable(() {
        final hits = debugEaseTableHits;
        // An entry of the SDK object with the same fields and input.
        final expected = easeTableAt(Curves.easeOutQuart, 0.3);
        for (var i = 0; i < 5; i++) {
          expect(_same(easeTableAt(twin, 0.3), expected), isTrue);
        }
        expect(_twinSolves, 5);
        expect(debugEaseTableEntries, 1);
        expect(debugEaseTableHits, hits);
      });
    });

    test('an entry of another curve object is a miss', () {
      const first = Curves.easeOutQuart;
      const second = Curves.easeInQuart;
      _inTable(() {
        final misses = debugEaseTableMisses;
        final hits = debugEaseTableHits;
        for (var i = 0; i < 4; i++) {
          expect(_same(easeTableAt(first, 0.3), first.transform(0.3)), isTrue);
          expect(
            _same(easeTableAt(second, 0.3), second.transform(0.3)),
            isTrue,
          );
        }
        expect(first.transform(0.3), isNot(second.transform(0.3)));
        // One slot: the two curves replace each other.
        expect(debugEaseTableEntries, 1);
        if (_counts) {
          expect(debugEaseTableMisses - misses, 8);
          expect(debugEaseTableHits, hits);
        }
      });
    });

    test('two inputs of one slot replace each other', () {
      const curve = Curves.easeOutQuart;
      const first = 0.3;
      // The first input after 0.5 that takes the slot of `first`: the table
      // then has one entry for the two inputs.
      var second = 0.5;
      var found = false;
      while (!found) {
        second += 1 / 4096;
        expect(second, lessThan(1));
        _inTable(() {
          easeTableAt(curve, first);
          easeTableAt(curve, second);
          found = debugEaseTableEntries == 1;
        });
      }
      expect(curve.transform(first), isNot(curve.transform(second)));
      _inTable(() {
        final misses = debugEaseTableMisses;
        final hits = debugEaseTableHits;
        for (var i = 0; i < 4; i++) {
          expect(
            _same(easeTableAt(curve, first), curve.transform(first)),
            isTrue,
          );
          expect(debugEaseTableEntries, 1);
          expect(
            _same(easeTableAt(curve, second), curve.transform(second)),
            isTrue,
          );
          expect(debugEaseTableEntries, 1);
        }
        if (_counts) {
          expect(debugEaseTableMisses - misses, 8);
          expect(debugEaseTableHits, hits);
        }
      });
    });

    test('the end of the last call that runs removes each entry', () {
      const curve = Curves.easeOutQuart;
      expect(easeTableActive, isFalse);
      _inTable(() {
        easeTableAt(curve, 0.25);
        expect(debugEaseTableEntries, 1);
        // An `Animator.update` call inside the first one.
        _inTable(() => easeTableAt(curve, 0.5));
        expect(easeTableActive, isTrue);
        expect(debugEaseTableEntries, 2);
        final hits = debugEaseTableHits;
        expect(_same(easeTableAt(curve, 0.25), curve.transform(0.25)), isTrue);
        expect(_same(easeTableAt(curve, 0.5), curve.transform(0.5)), isTrue);
        if (_counts) expect(debugEaseTableHits, hits + 2);
      });
      expect(easeTableActive, isFalse);
      expect(debugEaseTableEntries, 0);
      // A later call starts with no entry.
      _inTable(() {
        final misses = debugEaseTableMisses;
        easeTableAt(curve, 0.25);
        if (_counts) expect(debugEaseTableMisses, misses + 1);
      });
    });
  });

  group('Animation.tick', () {
    /// Ticks [count] animations with [curve] at each of [dates] (relative to
    /// the start) and gives the values of the targets after each date.
    List<List<Object?>> run(
      Curve curve,
      List<double> dates, {
      required bool table,
      int count = 6,
      bool loop = false,
      double duration = 1000,
      Interpolator? fn,
    }) {
      final targets = [
        for (var i = 0; i < count; i++) <String, Object?>{'value': 0.0},
      ];
      final animations = [
        for (final target in targets)
          _animation(target, {
            'duration': duration,
            'easing': curve,
            'loop': loop,
            'fn': ?fn,
          }),
      ];
      final frames = <List<Object?>>[];
      void tickAll(double date) {
        for (final animation in animations) {
          animation.tick(animation.start + date);
        }
        frames.add([for (final target in targets) target['value']]);
      }

      for (final date in dates) {
        if (table) {
          _inTable(() => tickAll(date));
        } else {
          tickAll(date);
        }
      }
      return frames;
    }

    /// Whether the frames [a] and [b] hold the same doubles.
    void expectSame(List<List<Object?>> a, List<List<Object?>> b) {
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        for (var j = 0; j < a[i].length; j++) {
          expect(
            _same(a[i][j]! as double, b[i][j]! as double),
            isTrue,
            reason: 'frame $i target $j: ${a[i][j]} and ${b[i][j]}',
          );
        }
      }
    }

    const dates = <double>[-16, 0, 16, 33, 250, 500, 999, 1000, 1016];

    test('the table gives the values of a tick outside the table', () {
      const curve = Curves.easeOutQuart;
      final hits = debugEaseTableHits;
      final misses = debugEaseTableMisses;
      final outside = run(curve, dates, table: false);
      // A tick outside `Animator.update` reads no table.
      expect(debugEaseTableHits, hits);
      expect(debugEaseTableMisses, misses);
      final inside = run(curve, dates, table: true);
      expectSame(inside, outside);
      if (_counts) {
        // The dates 16, 33, 250, 500 and 999 are above 0 and below 1: one
        // curve call for each date and five table reads for the other
        // animations.
        expect(debugEaseTableMisses - misses, 5);
        expect(debugEaseTableHits - hits, 5 * 5);
      }
      expect(inside[4].first, 10 * curve.transform(0.25));
      expect(easeTableActive, isFalse);
      expect(debugEaseTableEntries, 0);
    });

    test('the twin of another class solves for each tick', () {
      final twin = _TwinCubic.of(Curves.easeOutQuart);
      final inside = run(Curves.easeOutQuart, dates, table: true);
      final hits = debugEaseTableHits;
      final declined = run(twin, dates, table: true);
      expectSame(inside, declined);
      // Five dates above 0 and below 1, six animations.
      expect(_twinSolves, 5 * 6);
      expect(debugEaseTableHits, hits);
    });

    test('a loop takes the table on its way back too', () {
      const loopDates = <double>[100, 900, 1100, 1900, 2100, 2500, 3900];
      final twin = _TwinCubic.of(Curves.easeInOutCubic);
      final inside = run(
        Curves.easeInOutCubic,
        loopDates,
        table: true,
        loop: true,
      );
      final declined = run(twin, loopDates, table: true, loop: true);
      final outside = run(
        Curves.easeInOutCubic,
        loopDates,
        table: false,
        loop: true,
      );
      expectSame(inside, declined);
      expectSame(inside, outside);
    });

    test('the NaN factor of a loop with the duration 0 reads no table', () {
      final hits = debugEaseTableHits;
      final misses = debugEaseTableMisses;
      final inside = run(
        Curves.easeOutQuart,
        const [0],
        table: true,
        loop: true,
        duration: 0,
      );
      final outside = run(
        Curves.easeOutQuart,
        const [0],
        table: false,
        loop: true,
        duration: 0,
      );
      expect((inside.single.first! as double).isNaN, isTrue);
      expectSame(inside, outside);
      expect(debugEaseTableHits, hits);
      expect(debugEaseTableMisses, misses);
    });

    test('an interpolator of the app gets the factor of the curve', () {
      final factors = <double>[];
      Object? record(Object? from, Object? to, double factor) {
        factors.add(factor);
        return factor;
      }

      const someDates = <double>[16, 250, 500];
      run(Curves.easeOutQuart, someDates, table: true, fn: record);
      final inside = factors.toList();
      factors.clear();
      final twin = _TwinCubic.of(Curves.easeOutQuart);
      run(twin, someDates, table: true, fn: record);
      expect(inside.length, 3 * 6);
      expect(_twinSolves, 3 * 6);
      for (var i = 0; i < inside.length; i++) {
        expect(_same(inside[i], factors[i]), isTrue, reason: 'call $i');
      }
    });
  });
}
