// The fixed CPU test of the timed drivers: it shows a phone that throttles.
import 'dart:typed_data';

import 'perf_matrix_host.dart';

final Float64List _list = Float64List(4096);
double _sink = 0;
double _best = double.infinity;

/// The best time of [cpuTest] in this process, in milliseconds.
double get cpuTestBest => _best;

/// The best of 6 runs of fixed floating point and list work on the UI thread,
/// in milliseconds. A phone with a lower clock takes longer.
double cpuTest() {
  final watch = Stopwatch();
  var best = double.infinity;
  // The first 6 runs wake the fast core: after an idle time, a phone can start
  // the thread on a slow core, which looks like a hot phone.
  for (var run = 0; run < 12; run++) {
    if (run == 6) best = double.infinity;
    watch
      ..reset()
      ..start();
    var s = _sink;
    for (var k = 0; k < 2000; k++) {
      for (var i = 0; i < 4096; i++) {
        final v = s * .5 + i;
        _list[i] = v;
        s = v * 1e-3 + _list[(i + 7) & 4095] * 1e-4;
      }
    }
    _sink = s;
    watch.stop();
    final ms = watch.elapsedMicroseconds / 1000;
    if (ms < best) best = ms;
  }
  if (best < _best) _best = best;
  return best;
}

/// When [enabled], waits until [cpuTest] is within 10% of its best time, for at
/// most 5 minutes. Gives the last time of the test and the seconds of the wait.
Future<(double, int)> coolDown({required bool enabled}) async {
  var cal = cpuTest();
  final waited = Stopwatch()..start();
  if (enabled) {
    while (cal > _best * 1.10 && waited.elapsed.inSeconds < 300) {
      hostLine(
        'MATRIX_COOLING cal $cal best $_best ${waited.elapsed.inSeconds}',
      );
      await Future<void>.delayed(const Duration(seconds: 10));
      cal = cpuTest();
    }
  }
  return (cal, waited.elapsed.inSeconds);
}
