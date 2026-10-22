// Original code, not ported from Chart.js: tests of lib/src/js/js_promise.dart.
import 'dart:async';

import 'package:flutter_chartjs_port/src/js/js_promise.dart';
import 'package:test/test.dart';

// The job order of Chart.js ADR 0019, section 7: the checkpoint after an
// animation frame callback (probe J3 of the ADR). A browser runs the promise
// jobs of a frame callback before the next frame callback.

void main() {
  group('jsRunWithMicrotaskCheckpoint', () {
    test('runs the queued jobs after the callback, in their order', () {
      final log = <String>[];
      jsRunWithMicrotaskCheckpoint(() {
        jsEnqueuePromiseJob(() => log.add('job 1'));
        jsEnqueuePromiseJob(() {
          log.add('job 2');
          jsEnqueuePromiseJob(() => log.add('job 3'));
        });
        log.add('callback');
      });
      log.add('after');
      expect(log, ['callback', 'job 1', 'job 2', 'job 3', 'after']);
    });

    test('runs a nested checkpoint inside the outer one', () {
      final log = <String>[];
      jsRunWithMicrotaskCheckpoint(() {
        jsEnqueuePromiseJob(() => log.add('outer job'));
        jsRunWithMicrotaskCheckpoint(() {
          jsEnqueuePromiseJob(() => log.add('nested job'));
          log.add('nested callback');
        });
        log.add('outer callback');
      });
      expect(log, [
        'nested callback',
        'outer callback',
        'outer job',
        'nested job',
      ]);
    });

    test('runs the jobs when the callback throws, then rethrows', () {
      final log = <String>[];
      expect(
        () => jsRunWithMicrotaskCheckpoint(() {
          jsEnqueuePromiseJob(() => log.add('job after throw'));
          throw StateError('x');
        }),
        throwsStateError,
      );
      expect(log, ['job after throw']);
      // The checkpoint ended: a job outside it is a microtask.
      jsEnqueuePromiseJob(() => log.add('microtask'));
      expect(log, ['job after throw']);
    });

    test('reports the error of a job and runs the next job', () async {
      final errors = <Object>[];
      final log = <String>[];
      await runZonedGuarded(
        () async {
          jsRunWithMicrotaskCheckpoint(() {
            jsEnqueuePromiseJob(() => throw StateError('job'));
            jsEnqueuePromiseJob(() => log.add('next job'));
          });
        },
        (error, stack) => errors.add(error),
      );
      expect(log, ['next job']);
      expect(errors, [isStateError]);
    });
  });

  group('jsEnqueuePromiseJob', () {
    test('outside a checkpoint, runs the job as a microtask', () async {
      final log = <String>[];
      jsEnqueuePromiseJob(() => log.add('job'));
      log.add('sync');
      await Future<void>.value();
      expect(log, ['sync', 'job']);
    });
  });

  group('jsPromiseAll', () {
    test('settles at the checkpoint with sync completers', () {
      final log = <String>[];
      final a = Completer<void>.sync();
      unawaited(jsPromiseAll([a.future]).then((_) => log.add('then (a)')));
      jsRunWithMicrotaskCheckpoint(() {
        jsEnqueuePromiseJob(a.complete);
        log.add('callback');
      });
      log.add('event callback');
      expect(log, ['callback', 'then (a)', 'event callback']);
    });

    test('runs the continuation one job after the last item settles', () {
      // `Promise.all([p])`: the reaction job of `p` settles the result, and
      // the `.then` of the result runs in a later job. A job that the
      // checkpoint has before that later job runs first. The job of `a`
      // stands for the reaction job of `p`, as `Animation._notify` queues
      // it. Node.js gives the order callback, job 2, then.
      final log = <String>[];
      final a = Completer<void>.sync();
      unawaited(jsPromiseAll([a.future]).then((_) => log.add('then (a)')));
      jsRunWithMicrotaskCheckpoint(() {
        jsEnqueuePromiseJob(a.complete);
        jsEnqueuePromiseJob(() => log.add('job 2'));
        log.add('callback');
      });
      expect(log, ['callback', 'job 2', 'then (a)']);
    });

    test('rejects one job after the first rejection', () {
      final log = <String>[];
      final r = Completer<void>.sync();
      unawaited(
        jsPromiseAll([r.future]).then(
          (_) => log.add('resolved'),
          onError: (Object e) => log.add('rejected $e'),
        ),
      );
      jsRunWithMicrotaskCheckpoint(() {
        jsEnqueuePromiseJob(() => r.completeError('first'));
        jsEnqueuePromiseJob(() => log.add('job 2'));
      });
      expect(log, ['job 2', 'rejected first']);
    });

    test('rejects at the first rejection', () {
      final log = <String>[];
      final r = Completer<void>.sync();
      final r2 = Completer<void>.sync();
      unawaited(
        jsPromiseAll([r.future, r2.future]).then(
          (_) => log.add('resolved'),
          onError: (Object e) => log.add('rejected $e'),
        ),
      );
      jsRunWithMicrotaskCheckpoint(() {
        jsEnqueuePromiseJob(() => r.completeError('first'));
      });
      expect(log, ['rejected first']);
      // The later error of the other future goes to its handler in
      // Future.wait.
      r2.completeError('second');
      expect(log, ['rejected first']);
    });

    test('settles an empty list in a job at the checkpoint', () {
      final log = <String>[];
      jsRunWithMicrotaskCheckpoint(() {
        unawaited(
          jsPromiseAll(<Future<void>>[]).then((values) {
            log.add('then (b) $values');
          }),
        );
        log.add('callback');
      });
      log.add('event callback');
      expect(log, ['callback', 'then (b) []', 'event callback']);
    });

    test(
      'outside a checkpoint, settles an empty list in a microtask',
      () async {
        final log = <String>[];
        unawaited(
          jsPromiseAll(<Future<void>>[]).then((_) => log.add('then (d)')),
        );
        log.add('sync after (d)');
        expect(log, ['sync after (d)']);
        await Future<void>.value();
        await Future<void>.value();
        expect(log, ['sync after (d)', 'then (d)']);
      },
    );
  });
}
