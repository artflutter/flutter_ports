// Original code, not ported from Chart.js: core.animator cases with no spec.
@TestOn('vm')
library;

import 'package:flutter/scheduler.dart';
import 'package:flutter_chartjs/src/core/core.animation.dart';
import 'package:flutter_chartjs/src/core/core.animations.dart';
import 'package:flutter_chartjs/src/core/core.animator.dart';
import 'package:flutter_chartjs/src/js/js_date.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

// Behavior of Chart.js ADR 0019 that test/specs/core.animator.tests.js does
// not check (AGENTS.md rule 3): the promise checkpoint of the animator
// callback, jsMapForEach in `_update`, `stop()` inside a listener, one long
// pump, the mute of Chart.js ADR 0016 (decision 7), `listen`, and the members
// `getAnims`, `update` and `refresh` of Chart.js ADR 0029 (section 6).
//
// A test registers a frame callback after the animator callback of a frame
// with SchedulerBinding.scheduleFrameCallback between two pumps. The frame
// callbacks of one frame run in registration order, and the animator
// registers its next callback inside its callback of the frame before. Thus
// the test callback stands for a throttled event callback of the same frame
// (Chart.js ADR 0019, "Frame order"). The expected orders are the browser
// orders of probe F8 of the ADR (the pinned files in Node.js with a fake
// requestAnimationFrame that runs the promise jobs after each callback).

/// A chart for the animator: it counts its draws. Its other members throw.
final class _Chart implements types.Chart {
  _Chart([this.name = 'chart']);

  final String name;
  int draws = 0;

  @override
  final Map<String, Object?> options = {};

  @override
  void draw() {
    draws++;
  }

  @override
  String toString() => name;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Registers [callback] for the next frame, after the callbacks that the
/// frame already has.
void _afterAnimator(void Function() callback) {
  SchedulerBinding.instance.scheduleFrameCallback((_) => callback());
}

/// Pumps [count] frames of 16 ms.
Future<void> _frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// A number animation of `target.value` from 0 to 10 over [duration] ms,
/// added to [chart] and started.
Animation _start(
  types.Chart chart,
  Map<String, Object?> target, {
  double duration = 100,
  bool loop = false,
}) {
  final animation = Animation(
    {'duration': duration, 'loop': loop},
    target,
    'value',
    10.0,
  );
  animator
    ..add(chart, [animation])
    ..start(chart);
  return animation;
}

void main() {
  group('platform-animation-promise-checkpoint', () {
    testWidgets('a later callback of the last frame sees the shared options', (
      tester,
    ) async {
      final chart = _Chart();
      final anims = Animations(chart, <String, Object?>{
        'option': <String, Object?>{'duration': 200},
      });
      final target = <String, Object?>{
        'options': <String, Object?>{'option': 2.0},
      };
      final sharedOpts = <String, Object?>{'option': 10.0, r'$shared': true};
      expect(anims.update(target, {'options': sharedOpts}), isTrue);
      animator.start(chart);

      // Frame 13 (208 ms) ends the animation of 200 ms.
      await _frames(tester, 12);
      expect(target['options'], isNot(same(sharedOpts)));
      Object? seen;
      _afterAnimator(() => seen = target['options']);
      await _frames(tester, 1);
      expect(seen, same(sharedOpts));
      await _frames(tester, 1);
      expect(animator.running(chart), isFalse);
      animator.remove(chart);
    });

    testWidgets('a re-hover in the last frame of an un-hover keeps the hover', (
      tester,
    ) async {
      final chart = _Chart();
      final config = <String, Object?>{
        'colors': <String, Object?>{
          'type': 'color',
          'properties': ['backgroundColor'],
          'duration': 400,
        },
      };
      final hover = <String, Object?>{
        r'$shared': true,
        'backgroundColor': '#FF0000',
      };
      final normal = <String, Object?>{
        r'$shared': true,
        'backgroundColor': '#0000FF',
      };
      final target = <String, Object?>{'options': hover};
      // The un-hover.
      expect(
        Animations(chart, config).update(target, {'options': normal}),
        isTrue,
      );
      animator.start(chart);
      await _frames(tester, 24);
      // The re-hover in frame 25 (400 ms), after the animator callback.
      _afterAnimator(() {
        expect(target['options'], same(normal));
        expect(
          Animations(chart, config).update(target, {'options': hover}),
          isTrue,
        );
        animator.start(chart);
      });
      await _frames(tester, 2);
      // A new copy animates to the hover color. A browser gives the same.
      final copy = target['options']! as Map<String, Object?>;
      expect(copy, isNot(same(normal)));
      expect(copy, isNot(same(hover)));
      expect(copy[r'$shared'], isFalse);
      await _frames(tester, 25);
      expect(copy['backgroundColor'], '#FF0000');
      expect(target['options'], same(hover));
      expect(animator.running(chart), isFalse);
      animator.remove(chart);
    });

    testWidgets('an update with no animation settles at the checkpoint', (
      tester,
    ) async {
      final chart = _Chart();
      final targetA = <String, Object?>{'value': 0.0};
      _start(chart, targetA);
      final targetB = <String, Object?>{
        'options': <String, Object?>{'option': 1.0},
      };
      final sharedB = <String, Object?>{'option': 2.0, r'$shared': true};
      // The option has no animation config: _createAnimations writes it at
      // once, and awaitAll gives jsPromiseAll an empty list.
      final animsB = Animations(chart, <String, Object?>{
        'other': <String, Object?>{'duration': 100},
      });
      var first = true;
      animator.listen(chart, 'progress', (event) {
        if (!first) return;
        first = false;
        expect(animsB.update(targetB, {'options': sharedB}), isNull);
        expect(targetB['options'], isNot(same(sharedB)));
        _afterAnimator(() {});
      });
      Object? seen;
      _afterAnimator(() => seen = targetB['options']);
      await _frames(tester, 1);
      expect(seen, same(sharedB));
      await _frames(tester, 8);
      expect(animator.running(chart), isFalse);
      animator.remove(chart);
    });

    testWidgets(
      'an instant update in the last frame keeps the earlier options',
      (
        tester,
      ) async {
        // A chain to h1 ends in a frame. The progress listener of that frame
        // starts an update to h2 with the duration 0, so its awaitAll is
        // empty. Upstream, `Promise.all` of the h1 chain settles in the
        // reaction job of the end, and its `.then` runs one job later, after
        // the `.then` of the h2 update. Thus the target ends on h1. The pinned
        // files in Node.js v24.12.0 on x64, in browser order, give h1.
        final chart = _Chart();
        final h1 = <String, Object?>{'option': 20.0, r'$shared': true};
        final h2 = <String, Object?>{'option': 30.0, r'$shared': true};
        final target = <String, Object?>{
          'options': <String, Object?>{'option': 10.0, r'$shared': true},
        };
        expect(
          Animations(chart, <String, Object?>{
            'option': <String, Object?>{'duration': 200},
          }).update(target, {'options': h1}),
          isTrue,
        );
        final instant = Animations(chart, <String, Object?>{
          'option': <String, Object?>{'duration': 0},
        });
        final t0 = jsDateNow();
        animator.start(chart);
        var fired = false;
        animator.listen(chart, 'progress', (event) {
          if (fired || jsDateNow() - t0 < 200) return;
          fired = true;
          instant.update(target, {'options': h2});
        });
        await _frames(tester, 20);
        expect(fired, isTrue);
        expect(target['options'], same(h1));
        animator.remove(chart);
      },
    );

    test('an update outside a frame rejects after the synchronous code', () {
      return Future<void>(() async {
        final target = <String, Object?>{'value': 0.0};
        final animation = Animation({'duration': 100}, target, 'value', 10.0);
        Object? error = 'none';
        final wait = animation.wait().catchError((Object e) => error = e);
        animation.update({'duration': 100}, 20.0, animation.start + 10);
        expect(error, 'none');
        await wait;
        expect(error, same(undefined));
      });
    });
  });

  group('jsMapForEach in _update', () {
    testWidgets('a destroy in onComplete throws nothing', (tester) async {
      final a = _Chart('a');
      final b = _Chart('b');
      _start(a, <String, Object?>{'value': 0.0}, duration: 50);
      final targetB = <String, Object?>{'value': 0.0};
      _start(b, targetB, duration: 200);
      // destroy() removes the chart from the animator (core.controller.js:941,
      // :930).
      animator.listen(a, 'complete', (event) => animator.remove(a));
      await _frames(tester, 5);
      expect(animator.has(a), isFalse);
      expect(b.draws, 5);
      await _frames(tester, 10);
      expect(targetB['value'], 10.0);
      expect(animator.running(b), isFalse);
      animator
        ..remove(a)
        ..remove(b);
    });

    testWidgets('a chart that starts in onComplete ticks in the same frame', (
      tester,
    ) async {
      final a = _Chart('a');
      final c = _Chart('c');
      _start(a, <String, Object?>{'value': 0.0}, duration: 50);
      final targetC = <String, Object?>{'value': 0.0};
      var startFrame = -1;
      var frame = 0;
      animator.listen(a, 'complete', (event) {
        startFrame = frame;
        _start(c, targetC, duration: 50);
      });
      for (frame = 1; frame <= 12; frame++) {
        await _frames(tester, 1);
      }
      // a ends in frame 4 (64 ms) and completes in frame 5. c starts in
      // that frame, after a in the Map, and ticks in it.
      expect(startFrame, 5);
      expect(c.draws, 5);
      expect(targetC['value'], 10.0);
      expect(animator.running(c), isFalse);
      animator
        ..remove(a)
        ..remove(c);
    });
  });

  testWidgets('stop() in a progress listener counts the old list', (
    tester,
  ) async {
    final chart = _Chart();
    _start(chart, <String, Object?>{'value': 0.0}, duration: 1000);
    animator.listen(chart, 'progress', (event) => animator.stop(chart));
    await _frames(tester, 1);
    expect(animator.running(chart), isFalse);
    // update counted the items of its old list: the loop scheduled the
    // next frame (core.animator.js:99).
    expect(SchedulerBinding.instance.transientCallbackCount, 1);
    await _frames(tester, 1);
    expect(SchedulerBinding.instance.transientCallbackCount, 0);
    animator.remove(chart);
  });

  testWidgets('one pump of 300 ms leaves running(chart) true', (tester) async {
    final chart = _Chart();
    final target = <String, Object?>{'value': 0.0};
    _start(chart, target);
    await tester.pump(const Duration(milliseconds: 300));
    expect(target['value'], 10.0);
    expect(animator.running(chart), isTrue);
    await tester.pump();
    expect(animator.running(chart), isFalse);
    animator.remove(chart);
  });

  group('platform-animator-mute', () {
    testWidgets('a muted chart schedules no frame, and continues at unmute', (
      tester,
    ) async {
      final chart = _Chart();
      final target = <String, Object?>{'value': 0.0};
      final animation = _start(chart, target, duration: 1000, loop: true);
      await _frames(tester, 2);
      expect(chart.draws, 2);
      animator.mute(chart);
      await _frames(tester, 1);
      // The loop ends: no frame callback is left.
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
      final value = target['value'];
      await tester.pump(const Duration(milliseconds: 500));
      expect(chart.draws, 2);
      expect(target['value'], value);
      animator.unmute(chart);
      expect(SchedulerBinding.instance.transientCallbackCount, 1);
      await _frames(tester, 1);
      expect(chart.draws, 3);
      // The animation continues at the current time: 16 * 4 + 500 ms.
      expect(target['value'], 10 * (564 / 1000));
      expect(animation.active(), isTrue);
      animator.remove(chart);
      await _frames(tester, 1);
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
    });

    testWidgets('unmute without animations schedules no frame', (
      tester,
    ) async {
      final chart = _Chart();
      animator
        ..mute(chart)
        ..unmute(chart);
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
      animator.remove(chart);
    });

    test('unmute of a removed chart creates no record', () {
      // destroy() removes the record (core.controller.js:930). An owner can
      // still call unmute at a TickerMode change.
      final chart = _Chart();
      animator.listen(chart, 'complete', (event) {});
      expect(animator.remove(chart), isTrue);
      animator
        ..mute(chart)
        ..unmute(chart);
      expect(animator.remove(chart), isFalse);
    });
  });

  group('platform-animator-skip-muted', () {
    testWidgets('_update skips a muted chart and does not count it', (
      tester,
    ) async {
      final a = _Chart('a');
      final b = _Chart('b');
      final targetA = <String, Object?>{'value': 0.0};
      _start(a, targetA);
      final completeA = <double?>[];
      final progressA = <double?>[];
      animator
        ..listen(a, 'complete', (event) => completeA.add(event.currentStep))
        ..listen(a, 'progress', (event) => progressA.add(event.currentStep))
        ..mute(a);
      final targetB = <String, Object?>{'value': 0.0};
      _start(b, targetB, duration: 50);
      await _frames(tester, 6);
      // b ended. a waits: no tick, no draw and no listener call.
      expect(targetB['value'], 10.0);
      expect(b.draws, 4);
      expect(targetA['value'], 0.0);
      expect(a.draws, 0);
      expect(progressA, isEmpty);
      expect(completeA, isEmpty);
      // The loop ended although a has active animations.
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
      expect(animator.has(a), isTrue);
      animator
        ..unmute(a)
        ..remove(a)
        ..remove(b);
      await _frames(tester, 1);
    });
  });

  test('listen throws for an unknown event name', () {
    final chart = _Chart();
    expect(
      () => animator.listen(chart, 'start', (event) {}),
      throwsA(isA<TypeError>()),
    );
    animator
      ..listen(chart, 'complete', (event) {})
      ..listen(chart, 'progress', (event) {});
    expect(animator.remove(chart), isTrue);
    expect(animator.remove(chart), isFalse);
  });

  test('the listeners get a new event with the chart and the steps', () {
    // stop() calls the complete listeners (core.animator.js:201). Without a
    // start, the start and the duration are undefined: currentStep is NaN.
    final chart = _Chart();
    final events = <AnimationEvent>[];
    final target = <String, Object?>{'value': 0.0};
    animator
      ..listen(chart, 'complete', events.add)
      ..listen(chart, 'complete', events.add)
      ..add(chart, [
        Animation({'duration': 100}, target, 'value', 10.0),
      ])
      ..stop(chart);
    expect(events, hasLength(2));
    expect(events[0], isNot(same(events[1])));
    expect(events[0].chart, same(chart));
    expect(events[0].initial, isTrue);
    expect(events[0].numSteps, isNull);
    expect(events[0].currentStep, isNaN);
    animator.remove(chart);
  });

  group('harness-method-fields', () {
    // Six fixtures (Chart.js ADR 0029, section 6) replace
    // `Chart.animator._refresh`, read `_getAnims(chart).items[0]._start` and
    // call `_update`: controller.doughnut/doughnut-animation.js and
    // doughnut-animation-hide-last.js, controller.polarArea/
    // polar-area-animation-rotate.js, polar-area-animation-scale.js and
    // last-slice-animate.js call `_update(start + i * 500)`.
    // controller.bar/bar-animation-hide-show.js calls
    // `_update(Date.now() * 2)` and `_update(start + i * 2000)` (:53-70).
    testWidgets('a replaced refresh ends the loop, and the restore resumes', (
      tester,
    ) async {
      final saved = animator.refresh;
      addTearDown(() => animator.refresh = saved);
      final chart = _Chart();
      final target = <String, Object?>{'value': 0.0};
      _start(chart, target, duration: 1000);
      expect(SchedulerBinding.instance.transientCallbackCount, 1);
      var calls = 0;
      animator.refresh = () => calls++;
      // The callback of the frame runs update and then the replaced field
      // (core.animator.js:45-49). Thus it registers no frame callback.
      await _frames(tester, 1);
      expect(chart.draws, 1);
      expect(calls, 1);
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
      await _frames(tester, 3);
      expect(chart.draws, 1);
      expect(calls, 1);
      expect(target['value'], 10 * (16 / 1000));
      // The restore and start (:171) resume the loop.
      animator
        ..refresh = saved
        ..start(chart);
      expect(SchedulerBinding.instance.transientCallbackCount, 1);
      await _frames(tester, 2);
      expect(chart.draws, 3);
      expect(calls, 1);
      expect(target['value'], 10 * (96 / 1000));
      animator.remove(chart);
      await _frames(tester, 1);
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
    });

    testWidgets('start and unmute call the field', (tester) async {
      final saved = animator.refresh;
      addTearDown(() => animator.refresh = saved);
      final chart = _Chart();
      var calls = 0;
      animator.refresh = () => calls++;
      _start(chart, <String, Object?>{'value': 0.0}, duration: 1000);
      expect(calls, 1);
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
      animator
        ..mute(chart)
        ..unmute(chart);
      expect(calls, 2);
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
      await _frames(tester, 1);
      expect(chart.draws, 0);
      animator.remove(chart);
    });

    testWidgets('update(date) ticks the items of getAnims at the date', (
      tester,
    ) async {
      final saved = animator.refresh;
      addTearDown(() => animator.refresh = saved);
      final chart = _Chart();
      final target = <String, Object?>{'value': 0.0};
      final progress = <(double?, double?)>[];
      final complete = <(double?, double?)>[];
      animator
        ..refresh = () {}
        ..listen(
          chart,
          'progress',
          (event) => progress.add((event.currentStep, event.numSteps)),
        )
        ..listen(
          chart,
          'complete',
          (event) => complete.add((event.currentStep, event.numSteps)),
        );
      final animation = _start(chart, target, duration: 1000);
      final anims = animator.getAnims(chart);
      expect(anims.items, [same(animation)]);
      final start = anims.items[0].start;
      expect(anims.start, start);

      animator.update(start + 250);
      expect(target['value'], 2.5);
      expect(chart.draws, 1);
      // currentStep is Math.min(date - anims.start, numSteps) (:31).
      expect(progress, [(250.0, 1000.0)]);

      animator.update(start + 1500);
      expect(target['value'], 10.0);
      expect(animation.active(), isFalse);
      expect(chart.draws, 2);
      expect(progress.last, (1000.0, 1000.0));
      expect(complete, isEmpty);

      // The next update removes the ended item and completes (:80-96).
      animator.update(start + 2000);
      expect(anims.items, isEmpty);
      expect(anims.running, isFalse);
      expect(anims.initial, isFalse);
      expect(chart.draws, 2);
      expect(progress, hasLength(2));
      expect(complete, [(1000.0, 1000.0)]);
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
      animator.remove(chart);
    });

    test('getAnims of a new chart gives a new record', () {
      final chart = _Chart();
      final anims = animator.getAnims(chart);
      expect(anims.running, isFalse);
      expect(anims.initial, isTrue);
      expect(anims.items, isEmpty);
      expect(anims.listeners.keys, ['complete', 'progress']);
      expect(anims.listeners['complete'], isEmpty);
      expect(anims.listeners['progress'], isEmpty);
      expect(anims.start, isNull);
      expect(anims.duration, isNull);
      expect(animator.getAnims(chart), same(anims));
      expect(animator.remove(chart), isTrue);
      expect(animator.getAnims(chart), isNot(same(anims)));
      expect(animator.remove(chart), isTrue);
    });
  });
}
