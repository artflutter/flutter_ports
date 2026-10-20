// Original code, not ported from Chart.js: JS promise jobs and Promise.all.

/// The promise jobs of JavaScript for ported code, and `Promise.all`
/// (Chart.js ADR 0019, section 7).
///
/// A JavaScript promise is a Dart `Future`. A browser runs the promise jobs
/// at a microtask checkpoint: at the end of each task and after each
/// `requestAnimationFrame` callback. Flutter runs the microtasks of a frame
/// one time, after all the frame callbacks of that frame (Chart.js ADR
/// 0016). Thus a promise chain that the animator callback starts would
/// finish after the event callbacks of the same frame.
///
/// - [jsRunWithMicrotaskCheckpoint] runs a callback and then the jobs that
///   it queued: the checkpoint after an animation frame callback.
/// - [jsEnqueuePromiseJob] queues a job for the running checkpoint, or
///   schedules it as a Dart microtask outside a checkpoint.
/// - [jsPromiseAll] is `Promise.all`. It settles an empty list in a job,
///   and a list with items one job after the last item settles.
///
/// The ported code settles its promises with a `Completer.sync()` inside a
/// job. A sync completer calls the listeners of its future at once. Thus a
/// continuation runs in the job that settles its future.
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'dart:async';

/// The jobs of the running checkpoint, or Dart `null` outside a checkpoint.
List<void Function()>? _jobs;

/// `HostEnqueuePromiseJob` (ECMAScript 9.5.5): queues [job].
///
/// Inside [jsRunWithMicrotaskCheckpoint], [job] runs at the end of the
/// checkpoint, after the jobs before it. Outside a checkpoint, it runs as a
/// Dart microtask ([scheduleMicrotask]), after the synchronous code.
void jsEnqueuePromiseJob(void Function() job) {
  final jobs = _jobs;
  if (jobs != null) {
    jobs.add(job);
  } else {
    scheduleMicrotask(job);
  }
}

/// Runs [callback], then the jobs that [callback] and these jobs queue with
/// [jsEnqueuePromiseJob], in their order, until no job is left.
///
/// This is the microtask checkpoint that a browser runs after each
/// `requestAnimationFrame` callback (HTML, "update the rendering").
///
/// - A nested call runs its [callback] inside the outer checkpoint. Its jobs
///   run at the end of the outer checkpoint.
/// - The jobs also run when [callback] throws. Then the error of [callback]
///   continues after the jobs.
/// - A job that throws does not stop the checkpoint. Its error goes to the
///   uncaught-error handler of the current zone, as a browser reports an
///   exception of a microtask.
// DIVERGES(chartjs): platform-animation-promise-checkpoint, the checkpoint.
void jsRunWithMicrotaskCheckpoint(void Function() callback) {
  if (_jobs != null) {
    callback();
    return;
  }
  final jobs = _jobs = <void Function()>[];
  try {
    callback();
  } finally {
    try {
      // A job can queue more jobs: the length grows during the loop.
      for (var i = 0; i < jobs.length; i++) {
        try {
          jobs[i]();
          // The checkpoint reports the error of a job and runs the next job.
          // ignore: avoid_catches_without_on_clauses
        } catch (error, stackTrace) {
          Zone.current.handleUncaughtError(error, stackTrace);
        }
      }
    } finally {
      _jobs = null;
    }
  }
}

/// `Promise.all(futures)`: a future of the values of [futures], in their
/// order.
///
/// - A list with items waits with `Future.wait(futures, eagerError: true)`.
///   The result rejects at the first rejection, as `Promise.all` does. The
///   later errors of the other futures go to their handlers in
///   `Future.wait`. The result is the future of a `Completer.sync()`, which
///   a job of [jsEnqueuePromiseJob] settles. `Promise.all` settles in the
///   reaction job of the last item, and the continuations of the result run
///   in a later job. `Future.wait` completes in the job of the last item.
///   Thus without the extra job a continuation would run one job early. A
///   program can see that order: two `_animateOptions` chains on one target
///   end on another options object (Chart.js ADR 0019, section 7).
/// - An empty list gives the future of a `Completer.sync()`. A job of
///   [jsEnqueuePromiseJob] completes it with an empty list. `Promise.all([])`
///   also settles before its continuations run in a later job.
///   `Future.wait([])` completes in a Dart microtask, also inside a
///   checkpoint.
///
/// This function translates a JS builtin. It is not a `DIVERGES` hunk.
Future<List<T>> jsPromiseAll<T>(List<Future<T>> futures) {
  final result = Completer<List<T>>.sync();
  if (futures.isEmpty) {
    jsEnqueuePromiseJob(() => result.complete(<T>[]));
    return result.future;
  }
  unawaited(
    Future.wait(futures, eagerError: true).then(
      (values) => jsEnqueuePromiseJob(() => result.complete(values)),
      onError: (Object error, StackTrace stackTrace) =>
          jsEnqueuePromiseJob(() => result.completeError(error, stackTrace)),
    ),
  );
  return result.future;
}
