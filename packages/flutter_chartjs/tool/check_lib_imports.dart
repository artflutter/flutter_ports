// Original code, not ported from Chart.js: the command of the import guard.

/// `dart run packages/flutter_chartjs/tool/check_lib_imports.dart`: the
/// library import guard of porting-flow.md section 4, tool 1. See
/// `src/lib_imports.dart` for the rules.
library;

import 'dart:io';

import 'src/check_support.dart';
import 'src/lib_imports.dart';

const String _usage = '''
Usage: dart run tool/check_lib_imports.dart [<package directory>...]

Checks the imports of lib/ and test/ against the allowlists of
porting-flow.md section 4, tool 1. The default package is the package of
this tool. Exits with 1 when a check fails.''';

Future<void> main(List<String> args) async {
  exitCode = await runCheck(
    args,
    name: 'check:lib-imports',
    usage: _usage,
    out: stdout,
    check: (packages) {
      final findings = <Finding>[];
      var files = 0;
      for (final package in packages) {
        final prefix = relativePath(Directory.current.path, package);
        final result = checkLibImports(
          package,
          displayPrefix: prefix.isEmpty ? '' : '$prefix/',
        );
        findings.addAll(result.findings);
        files += result.files;
      }
      return (findings: findings, files: files);
    },
  );
}
