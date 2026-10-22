// Original code, not ported from Chart.js: the command of the JS check.

/// `dart run packages/flutter_chartjs_port/tool/check_js_semantics.dart`: the
/// JS-semantics check of porting-flow.md section 4, tool 3. See
/// `src/js_semantics.dart` for the rules.
library;

import 'dart:io';

import 'src/check_support.dart';
import 'src/js_semantics.dart';
import 'src/port_headers.dart' show withHarnessPackage;

const String _usage = '''
Usage: dart run tool/check_js_semantics.dart [<package directory>...]

Flags Dart constructs with JavaScript-incompatible results in the lib/ and
test/ files whose header names a js project of tool/port_sources.yaml
(porting-flow.md section 4, tool 3). A site passes with a
"// js-ok: <reason>" comment at the end of its line, or alone on the line
before. The default package is the package of this tool. The first package
holds tool/port_sources.yaml. The check also examines the harness package
chartjs_test_utils next to the first package when it exists. Exits with 1
when a site is flagged.''';

Future<void> main(List<String> args) async {
  exitCode = await runCheck(
    args,
    name: 'check:js-semantics',
    usage: _usage,
    out: stdout,
    check: (packages) => checkJsSemantics(
      withHarnessPackage(packages),
      base: Directory.current.path,
    ),
  );
}
