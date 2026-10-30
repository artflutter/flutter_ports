// Original code, not ported from Chart.js: the command of the ratchet, tool 9.

/// `dart run packages/flutter_chartjs_port/tool/check_typed_reads.dart`: the
/// ratchet of the by-name forms, tool 9. See `src/typed_reads.dart` for the
/// rules.
library;

import 'dart:io';

import 'src/check_support.dart';
import 'src/typed_reads.dart';

const String _usage = '''
Usage: dart run tool/check_typed_reads.dart [--update] [<package directory>]

Counts the by-name forms (jsGet, jsGetKey, stringIndex, jsCall,
jsObjectKeys, extendsMapBase, withMapMixin and implementsMap) in the code of
each Dart file of lib/src/, without the files of lib/src/js/ and
lib/src/options/ (tool 9). Compares each count with the baseline of the file,
tool/typed_reads/<path under lib/src>.txt. A missing baseline means 0. Exits
with 1 when a count is above its baseline, or when a baseline does not parse
or names no counted file. A count below its baseline passes with a line that
asks for --update. The default package is the package of this tool.

Through melos, put the options after "--":
dart run melos run check:typed-reads -- --update

Options:
  --update  Write the baselines from the current tree: create and rewrite the
            baseline of each file with a by-name form, and delete the other
            files of tool/typed_reads/.
  --help    Print this text.''';

void main(List<String> args) {
  exitCode = run(args, out: stdout);
}

/// Runs the command with [args] and returns the exit code: 0 when the check
/// passes or the baselines are written, 1 when the check fails and 2 for a
/// usage error. The paths of the output are relative to [base], by default
/// the current folder.
int run(List<String> args, {required StringSink out, String? base}) {
  var update = false;
  String? package;
  for (final arg in args) {
    switch (arg) {
      case '--help' || '-h':
        out.writeln(_usage);
        return 0;
      case '--update':
        update = true;
      default:
        if (arg.startsWith('-') || package != null) {
          out
            ..writeln('$typedReadsName: unexpected argument $arg')
            ..writeln(_usage);
          return 2;
        }
        package = posixPath(Directory(arg).absolute.path);
    }
  }
  package ??= scriptPackage();
  if (!File('$package/pubspec.yaml').existsSync()) {
    out.writeln('$typedReadsName: $package has no pubspec.yaml');
    return 2;
  }
  final prefix = relativePath(base ?? Directory.current.path, package);
  final display = prefix.isEmpty ? '' : '$prefix/';

  final counts = scanPackage(package);
  final totals = FormCounts();
  counts.values.forEach(totals.add);
  if (update) {
    final result = writeBaselines(package, counts);
    out.writeln(
      '$typedReadsName --update: ${counts.length} files, '
      '${result.written} baselines written, ${result.deleted} deleted, '
      '${result.unchanged} unchanged in $display$baselineDirectory; '
      '${totals.describeAll()}.',
    );
    return 0;
  }

  final report = compareTypedReads(
    counts,
    readBaselines(package),
    sourcePrefix: '$display$sourceDirectory/',
    baselinePrefix: '$display$baselineDirectory/',
  );
  for (final finding in report.findings) {
    final location = finding.line == null
        ? finding.path
        : '${finding.path}:${finding.line}';
    out.writeln('$location: ${finding.message}');
  }
  final below = report.findings.length - report.errors;
  out.writeln(
    '$typedReadsName: ${report.passed ? 'passed' : 'failed'}, '
    '${report.files} files, ${report.errors} errors, $below below the '
    'baseline; ${report.totals.describeAll()}.',
  );
  return report.passed ? 0 : 1;
}
