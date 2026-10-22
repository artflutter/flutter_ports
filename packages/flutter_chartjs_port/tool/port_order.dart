// Original code, not ported from Chart.js: the command of the port order.

/// `dart run packages/flutter_chartjs_port/tool/port_order.dart`: the port-order
/// helper of porting-flow.md section 4, tool 8. See `src/port_order.dart`
/// for the rules.
library;

import 'dart:convert';
import 'dart:io';

import 'src/check_support.dart';
import 'src/port_order.dart';

const String _usage = '''
Usage: dart run tool/port_order.dart [options] [<package directory>]

Lists the Chart.js modules of third_party/Chart.js/src that are ready to
port: each value import is done, and the module is not started. Each ready
module comes with its line count and the interfaces of lib/src/types that
its type-only imports need. The list also gives the modules in progress, and
the blocked modules with their missing imports, in the phase order of
porting-flow.md section 5. The port state comes from the headers of the Dart
files in lib/ and from the status column of doc/parity.md. The default
package is the package of this tool. Exits with 0, or with 2 when an input
is missing.

Through melos, put the options after "--":
dart run melos run port:next -- --check

Options:
  --json    Print the same data as JSON.
  --check   Print only the findings and a summary line. Exit with 1 when a
            module, a header line of lib/ or a parity.md status does not
            parse, or when an import does not resolve.
  --help    Print this text.''';

Future<void> main(List<String> args) async {
  exitCode = run(args, out: stdout);
}

/// Runs the command with [args] and returns the exit code: 0 for the list,
/// 0 or 1 for `--check`, and 2 for a usage error or a missing input.
int run(List<String> args, {required StringSink out}) {
  var json = false;
  var check = false;
  String? package;
  for (final arg in args) {
    switch (arg) {
      case '--help' || '-h':
        out.writeln(_usage);
        return 0;
      case '--json':
        json = true;
      case '--check':
        check = true;
      default:
        if (arg.startsWith('-') || package != null) {
          out
            ..writeln('$portOrderName: unexpected argument $arg')
            ..writeln(_usage);
          return 2;
        }
        package = posixPath(Directory(arg).absolute.path);
    }
  }
  package ??= scriptPackage();
  if (!File('$package/pubspec.yaml').existsSync()) {
    out.writeln('$portOrderName: $package has no pubspec.yaml');
    return 2;
  }
  final repository = findAncestorWith(package, 'REUSE.toml');
  if (repository == null) {
    out.writeln('$portOrderName: no REUSE.toml in a parent folder of $package');
    return 2;
  }

  final PortOrder order;
  try {
    order = computePortOrder(
      PortOrderInput(repository: repository, package: package),
    );
  } on PortOrderInputError catch (e) {
    out.writeln('$portOrderName: ${e.message}');
    return 2;
  }

  final errors = order.findings.where((f) => f.isError).isNotEmpty;
  if (json) {
    out.writeln(
      const JsonEncoder.withIndent('  ').convert(portOrderJson(order)),
    );
    return check && errors ? 1 : 0;
  }
  if (check) {
    return reportFindings(
      '$portOrderName --check',
      order.findings,
      out: out,
      files: order.files,
    );
  }
  out.write(renderPortOrder(order));
  return 0;
}
