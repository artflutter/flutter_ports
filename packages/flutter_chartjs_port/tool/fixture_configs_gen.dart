// Original code, not ported from Chart.js: the fixture config generator.

/// `dart run packages/flutter_chartjs_port/tool/fixture_configs_gen.dart`:
/// writes `test/fixtures/data_fixtures.g.dart`, the typed configs of the
/// pure data fixtures of `doc/upstream/fixtures.json` that have no hand port
/// (Chart.js ADR 0199). See `src/fixture_configs.dart` for the rules.
library;

import 'dart:convert';
import 'dart:io';

import 'src/check_support.dart';
import 'src/fixture_configs.dart';

const String _usage = '''
Usage: dart run tool/fixture_configs_gen.dart [--check]

Reads doc/upstream/fixtures.json and doc/upstream/manifest.json and writes
test/fixtures/data_fixtures.g.dart, formatted with dart format: the typed
config of each pure data fixture without a hand port in test/fixtures/hand/
(Chart.js ADR 0199).

Options:
  --check  Write nothing. Generate into .dart_tool/fixture_configs_check/ of
           the package, format there, and exit with 1 when the committed file
           differs from its output.
  --help   Print this text.''';

/// The path of the output, relative to the package root.
const String outputPath = 'test/fixtures/data_fixtures.g.dart';

void main(List<String> args) {
  exitCode = run(args, out: stdout);
}

/// Runs the command with [args]. Returns the exit code: 0 when the file is
/// written or equal, 1 when the check fails, 2 for a usage error.
int run(List<String> args, {required IOSink out}) {
  var check = false;
  for (final arg in args) {
    switch (arg) {
      case '--check':
        check = true;
      case '--help' || '-h':
        out.writeln(_usage);
        return 0;
      default:
        out.writeln('fixture_configs_gen: unknown option $arg\n\n$_usage');
        return 2;
    }
  }
  final package = scriptPackage();
  final String text;
  try {
    text = generateDataFixtures(package);
  } on FormatException catch (e) {
    out.writeln('fixture_configs_gen: ${e.message}');
    return 1;
  }
  final dir = Directory(
    check
        ? '$package/.dart_tool/fixture_configs_check'
        : '$package/test/fixtures',
  );
  if (check && dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
  final file = File('${dir.path}/data_fixtures.g.dart')
    ..writeAsStringSync(text);
  final format = Process.runSync(Platform.resolvedExecutable, [
    'format',
    file.path,
  ], workingDirectory: package);
  if (format.exitCode != 0) {
    out.writeln('fixture_configs_gen: dart format failed:\n${format.stderr}');
    return 1;
  }
  if (!check) {
    out.writeln('fixture_configs_gen: wrote $outputPath.');
    return 0;
  }
  final committed = File('$package/$outputPath');
  if (!committed.existsSync() ||
      committed.readAsStringSync() != file.readAsStringSync()) {
    out.writeln(
      'fixture_configs_gen: $outputPath differs from the output of '
      'doc/upstream/fixtures.json. Run "dart run melos run fixtures:gen".',
    );
    return 1;
  }
  out.writeln('fixture_configs_gen: $outputPath is up to date.');
  return 0;
}

/// The moment patterns of the twins and their ICU patterns (row
/// `adapt-date-moment-format`).
const Map<String, String> icuPatterns = {'YYYY': 'yyyy', 'YYYY-MM': 'yyyy-MM'};

/// Whether [json] holds a moment pattern: a `parser` text or a text of a
/// `displayFormats` object.
bool hasMomentPattern(Object? json) => switch (json) {
  final Map<String, Object?> map => map.entries.any(
    (entry) =>
        (entry.key == 'parser' && entry.value is String) ||
        (entry.key == 'displayFormats' &&
            entry.value is Map<String, Object?> &&
            (entry.value! as Map<String, Object?>).values.any(
              (format) => format is String,
            )) ||
        hasMomentPattern(entry.value),
  ),
  final List<Object?> list => list.any(hasMomentPattern),
  _ => false,
};

/// [json] with each moment pattern of a `parser` key and of a
/// `displayFormats` object replaced with its ICU pattern of [icuPatterns].
/// Throws a [FormatException] for another pattern.
Object? toIcu(Object? json, String path) => switch (json) {
  final Map<String, Object?> map => <String, Object?>{
    for (final MapEntry(:key, :value) in map.entries)
      key: switch ((key, value)) {
        ('parser', final String pattern) => _icu(pattern, path),
        ('displayFormats', final Map<String, Object?> formats) => {
          for (final MapEntry(key: unit, value: format) in formats.entries)
            unit: format is String ? _icu(format, path) : format,
        },
        _ => toIcu(value, path),
      },
  },
  final List<Object?> list => [for (final item in list) toIcu(item, path)],
  _ => json,
};

String _icu(String pattern, String path) =>
    icuPatterns[pattern] ??
    (throw FormatException(
      '$path: the moment pattern "$pattern" has no ICU pattern.',
    ));

/// The Dart name of the config function of the fixture [path].
String functionName(String path) {
  final stem = path.substring(0, path.lastIndexOf('.')).toLowerCase();
  return '_${stem.replaceAll(RegExp('[^a-z0-9]+'), '_')}';
}

/// The fixture paths of the hand ports of [package]: `hand/<stem>.dart` is
/// `<stem>.json` when [data] has that path, else `<stem>.js`.
Set<String> handPorts(String package, Set<String> data) {
  final root = '$package/test/fixtures/hand/';
  final dir = Directory(root);
  if (!dir.existsSync()) return {};
  return {
    for (final entity in dir.listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        () {
          final stem = posixPath(
            entity.path.substring(root.length, entity.path.length - 5),
          );
          return data.contains('$stem.json') ? '$stem.json' : '$stem.js';
        }(),
  };
}

/// The source of `test/fixtures/data_fixtures.g.dart`, before the format.
String generateDataFixtures(String package) {
  final manifest =
      jsonDecode(
            File('$package/doc/upstream/manifest.json').readAsStringSync(),
          )!
          as Map<String, Object?>;
  final items =
      ((manifest['fixtures']! as Map<String, Object?>)['items']!
              as List<Object?>)
          .cast<Map<String, Object?>>();
  final sha = {
    for (final item in items)
      item['path']! as String: item['sha256']! as String,
  };
  final data =
      jsonDecode(
            File('$package/doc/upstream/fixtures.json').readAsStringSync(),
          )!
          as Map<String, Object?>;
  final hand = handPorts(package, data.keys.toSet());
  final entries = StringBuffer();
  final twins = StringBuffer();
  final functions = StringBuffer();
  for (final MapEntry(key: path, value: json) in data.entries) {
    if (hand.contains(path)) continue;
    final hash = sha[path];
    if (hash == null) {
      throw FormatException('$path is not a fixture of the manifest.');
    }
    final moment = hasMomentPattern(json);
    for (final twin in [false, if (moment) true]) {
      final emitter = FixtureEmitter(path);
      final value = fixtureValueOf(twin ? toIcu(json, path) : json);
      if (value is! FixtureMap) {
        throw FormatException('$path: the fixture is no object.');
      }
      final body = emitter.emit(value);
      final name = '${functionName(path)}${twin ? '_icu' : ''}';
      (twin ? twins : entries).write(
        '  ${dartString(path)}: (load: $name, sha256: '
        "'${hash.substring(0, 12)}'),\n",
      );
      functions
        ..writeln()
        ..writeln(twin ? '/// The ICU twin of `$path`.' : '/// `$path`.');
      if (emitter.mapReason case final reason?) {
        functions
          ..writeln('///')
          ..writeln('/// The config keeps its Map: $reason.');
      }
      if (emitter.declarations.isEmpty) {
        functions.writeln('FixtureConfig $name() => $body;');
      } else {
        functions
          ..writeln('FixtureConfig $name() {')
          ..writeln(emitter.declarations.join('\n'))
          ..writeln('return $body;')
          ..writeln('}');
      }
    }
  }
  return '''
// Original code, not ported from Chart.js: the typed configs of the pure data fixtures, generated from doc/upstream/fixtures.json.
// Generated by tool/fixture_configs_gen.dart (Chart.js ADR 0199). Do not edit:
// run "dart run melos run fixtures:gen".

/// The typed configs of the pure data fixtures of `doc/upstream/fixtures.json`
/// that have no hand port in `test/fixtures/hand/` (Chart.js ADR 0199).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

/// The config of each pure data fixture without a hand port, by fixture
/// path, with the first 12 hex digits of its manifest `sha256`. The runner
/// skips a fixture with a moment pattern: its ICU twin is in [momentTwins].
final Map<String, HandFixture> dataFixtures = {
$entries};

/// The ICU twin of each pure data fixture with a moment pattern (row
/// `adapt-date-moment-format`): each moment pattern of a `parser` key and of
/// a `displayFormats` object is its ICU pattern (${icuPatterns.entries.map((e) => '`${e.key}` is `${e.value}`').join(', ')}).
final Map<String, HandFixture> momentTwins = {
$twins};
$functions''';
}
