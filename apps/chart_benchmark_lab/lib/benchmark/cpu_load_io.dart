import 'dart:async';
import 'dart:io';
import 'dart:isolate';

/// One busy background thread while a test runs.
///
/// A chart with a small workload leaves the CPU almost idle, so the system
/// keeps the UI and raster threads on efficiency cores at low clocks, and a
/// frame takes longer than on a busy CPU. A spinning isolate makes the
/// system raise the clocks and move the app to performance cores.
class CpuLoad() {
  /// No load until [start].
  this;

  Future<Isolate?>? _isolate;

  /// Starts the spinning isolate, once. `flutter test` gets no load.
  void start() {
    if (_isolate != null || Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    _isolate = Isolate.spawn(
      _spin,
      null,
      debugName: 'cpu-load',
    ).then<Isolate?>((isolate) => isolate, onError: (Object _) => null);
  }

  /// Kills the spinning isolate. A spin loop stops at its next loop check.
  void stop() {
    final isolate = _isolate;
    _isolate = null;
    unawaited(
      isolate?.then((value) => value?.kill(priority: Isolate.immediate)),
    );
  }
}

// The loop has no end: `stop` kills the isolate.
void _spin(Object? _) {
  var x = 1;
  for (;;) {
    x = (x * 1103515245 + 12345) & 0x7fffffff;
  }
}
