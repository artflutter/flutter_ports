// Ported from d3-time v3.1.0 test/test-time-zones (ISC, Mike Bostock).
@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

// DIVERGES(d3-time): platform-time-tz-tests, runs the 32 upstream timezone
// checks in POSIX VM subprocesses with real IANA TZ environment variables
// (Asia/Kolkata, Asia/Kathmandu, America/Sao_Paulo, America/Los_Angeles).
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
    'Asia/Kolkata',
    'Asia/Kathmandu',
    'America/Sao_Paulo',
    'America/Los_Angeles',
  ]) {
    test('upstream timezone suite passes in TZ=$tz', () {
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
