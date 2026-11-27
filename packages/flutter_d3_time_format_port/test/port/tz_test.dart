// Original code, not ported from d3-time-format: POSIX TZ subprocess checks.
@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

String _findDartExecutable() {
  final exe = Platform.resolvedExecutable;
  if (exe.endsWith('/dart') || exe.endsWith(r'\dart.exe')) return exe;
  var dir = File(exe).parent;
  for (var i = 0; i < 8; ++i) {
    final cacheDart = File('${dir.path}/cache/dart-sdk/bin/dart');
    if (cacheDart.existsSync()) return cacheDart.path;
    final sdkDart = File('${dir.path}/dart-sdk/bin/dart');
    if (sdkDart.existsSync()) return sdkDart.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return 'dart';
}

void main() {
  final skipPosix = Platform.isWindows
      ? 'IANA TZ env override requires POSIX timezone database'
      : false;
  final dartExe = _findDartExecutable();

  for (final tz in const [
    'America/Los_Angeles',
    'UTC',
    'Asia/Kolkata',
    'Asia/Kathmandu',
  ]) {
    test('timezone-sensitive format/parse checks pass in TZ=$tz', () {
      final env = Map<String, String>.of(Platform.environment)..['TZ'] = tz;
      final result = Process.runSync(dartExe, [
        'run',
        'test/port/tz_worker.dart',
        tz,
      ], environment: env);
      expect(
        result.exitCode,
        0,
        reason: 'TZ=$tz failed:\n${result.stdout}\n${result.stderr}',
      );
    }, skip: skipPosix);
  }
}
