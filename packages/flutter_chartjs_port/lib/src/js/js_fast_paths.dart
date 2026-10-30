// Original code, not ported from Chart.js: the fast-path switch.

/// The switch of the fast paths of the resolver and the hot paths (Chart.js
/// ADR 0053).
///
/// A fast path is a second Dart form of a ported statement or of a
/// port-only helper. It gives the result of the ported form for the same
/// input, and the ported form stays its fallback. Each fast path tests
/// [portFastPaths] at its entry and takes the ported form when it is false.
///
/// The three states:
/// - A build with `--dart-define=PORT_FAST_PATHS=false` turns every fast
///   path off. The melos script `test:nofast` runs the tests of the package
///   so.
/// - In a run with assertions (`flutter test`, `dart test`, a debug build),
///   a test sets [debugFastPaths] to compare the two forms in one process
///   (`test/port/js/js_fast_paths_test.dart`). It restores the value with
///   `addTearDown`.
/// - In a run without assertions (a profile or release build of Flutter,
///   `dart compile exe`, `dart compile wasm` and `dart compile js`), the
///   compiler removes the `assert` of [portFastPaths]. Then the getter gives
///   the constant [_allowed], and the compiler removes the branch of the
///   form that the constant does not take. Thus the switch costs nothing in
///   a timed build. Chart.js ADR 0053 gives the check of this claim.
library;

import 'package:meta/meta.dart';

/// The define `PORT_FAST_PATHS`: true when it is absent.
const bool _allowed = bool.fromEnvironment(
  'PORT_FAST_PATHS',
  defaultValue: true,
);

/// The test switch of the fast paths. It counts only in a run with
/// assertions and when the define `PORT_FAST_PATHS` is not `false`.
@visibleForTesting
bool debugFastPaths = true;

/// Whether the fast paths of Chart.js ADR 0053 run.
///
/// It is the define `PORT_FAST_PATHS` (true when it is absent), and in a run
/// with assertions also [debugFastPaths].
bool get portFastPaths {
  if (!_allowed) return false;
  var on = true;
  // Only a run with assertions runs this closure. A run without assertions
  // keeps the constant.
  assert(() {
    on = debugFastPaths;
    return true;
  }(), 'not reached');
  return on;
}

/// The count of the runs of each fast path, by the id of the fast path, in
/// a run with assertions. A test reads it to show that a case takes a fast
/// path (Chart.js ADR 0053 §3), and clears it first. A run without
/// assertions never writes it.
@visibleForTesting
final Map<String, int> debugFastPathHits = <String, int>{};

/// Counts one run of the fast path [id] in [debugFastPathHits] and returns
/// true. A fast path calls it inside an `assert`, so a run without
/// assertions does not call it:
///
/// ```dart
/// assert(debugFastPathHit('z1'), 'debugFastPathHit returns true');
/// ```
bool debugFastPathHit(String id) {
  debugFastPathHits[id] = (debugFastPathHits[id] ?? 0) + 1;
  return true;
}
