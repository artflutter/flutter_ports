// Original code, not ported from Chart.js: the command of the header check.

/// `dart run packages/flutter_chartjs/tool/check_port_headers.dart`: the
/// header check of porting-flow.md section 4, tool 2. See
/// `src/port_headers.dart` for the rules.
library;

import 'dart:io';

import 'src/check_support.dart';
import 'src/port_headers.dart';

const String _usage = '''
Usage: dart run tool/check_port_headers.dart [<package directory>...]

Checks the file headers, the DIVERGES(chartjs) markers and
tool/port_sources.yaml (porting-flow.md section 4, tool 2). The default
package is the package of this tool. The first package holds
tool/port_sources.yaml, lib/src/upstream.dart and doc/differences.md.
Exits with 1 when a check fails. Stale headers are warnings.''';

Future<void> main(List<String> args) async {
  exitCode = await runCheck(
    args,
    name: 'check:headers',
    usage: _usage,
    out: stdout,
    check: (packages) {
      final repository = findAncestorWith(packages.first, 'REUSE.toml');
      if (repository == null) {
        return (
          findings: [
            Finding(packages.first, null, 'no REUSE.toml in a parent folder.'),
          ],
          files: 0,
        );
      }
      return checkPortHeaders(
        HeaderCheckInput(
          repository: repository,
          home: packages.first,
          packages: packages,
        ),
      );
    },
  );
}
