// Original code, not ported from Chart.js: shared code of the port checks.

/// Findings, paths, file lists and the command line of the port checks.
library;

import 'dart:async';
import 'dart:io';

/// How much a finding counts.
enum Severity {
  /// The check fails.
  error,

  /// The check reports the finding and passes.
  warning,
}

/// One result of a check, at a file and an optional line.
final class Finding {
  /// A finding in [path] (relative to the repository root) at [line].
  const Finding(
    this.path,
    this.line,
    this.message, {
    this.severity = Severity.error,
  });

  /// A warning in [path] at [line].
  const Finding.warning(this.path, this.line, this.message)
    : severity = Severity.warning;

  /// The file, relative to the repository root, with `/` separators.
  final String path;

  /// The 1-based line, or null for the whole file.
  final int? line;

  /// What is wrong.
  final String message;

  /// Whether the finding fails the check.
  final Severity severity;

  /// Whether [severity] is [Severity.error].
  bool get isError => severity == Severity.error;

  @override
  String toString() {
    final location = line == null ? path : '$path:$line';
    final prefix = isError ? 'error' : 'warning';
    return '$prefix: $location: $message';
  }
}

/// [path] with `/` separators and no trailing `/`.
String posixPath(String path) {
  final result = path.replaceAll(r'\', '/');
  return result.length > 1 && result.endsWith('/')
      ? result.substring(0, result.length - 1)
      : result;
}

/// [path] relative to [root]. Both are absolute or both are relative.
String relativePath(String root, String path) {
  final base = posixPath(root);
  final full = posixPath(path);
  if (full == base) return '';
  return full.startsWith('$base/') ? full.substring(base.length + 1) : full;
}

/// The normalized form of the relative [path]: no `.` segments, and `..`
/// segments applied. Returns null if the path leaves its root.
String? normalizeRelative(String path) {
  final segments = <String>[];
  for (final segment in posixPath(path).split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (segments.isEmpty) return null;
      segments.removeLast();
    } else {
      segments.add(segment);
    }
  }
  return segments.join('/');
}

/// The Dart files under [directory], sorted, as absolute `/` paths.
///
/// Skips directories whose name starts with `.`, and `build` directories.
List<String> dartFilesUnder(String directory) {
  final root = Directory(directory);
  if (!root.existsSync()) return const [];
  final result = <String>[];
  void visit(Directory dir) {
    for (final entity in dir.listSync(followLinks: false)) {
      final name = posixPath(entity.path).split('/').last;
      if (entity is Directory) {
        if (!name.startsWith('.') && name != 'build') visit(entity);
      } else if (entity is File && name.endsWith('.dart')) {
        result.add(posixPath(entity.absolute.path));
      }
    }
  }

  visit(root);
  return result..sort();
}

/// A regular expression for a REUSE-style [glob]: `**` matches any text,
/// `*` matches any text without `/`, and `\` escapes the next character.
RegExp globToRegExp(String glob) {
  final buffer = StringBuffer('^');
  for (var i = 0; i < glob.length; i++) {
    final c = glob[i];
    if (c == r'\' && i + 1 < glob.length) {
      buffer.write(RegExp.escape(glob[++i]));
    } else if (c == '*' && i + 1 < glob.length && glob[i + 1] == '*') {
      buffer.write('.*');
      i++;
    } else if (c == '*') {
      buffer.write('[^/]*');
    } else {
      buffer.write(RegExp.escape(c));
    }
  }
  buffer.write(r'$');
  return RegExp(buffer.toString());
}

/// The closest directory at or above [start] that contains [marker].
String? findAncestorWith(String start, String marker) {
  var dir = Directory(start).absolute;
  while (true) {
    final candidate = '${posixPath(dir.path)}/$marker';
    if (FileSystemEntity.typeSync(candidate) != FileSystemEntityType.notFound) {
      return posixPath(dir.path);
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

/// The package directory of the running tool: the parent of its `tool/`.
String scriptPackage() =>
    posixPath(File.fromUri(Platform.script).absolute.parent.parent.path);

/// The command line of a check.
final class CheckOptions {
  /// Options with the [packages] to examine, and [help] when `--help` is set.
  const CheckOptions(this.packages, {required this.help});

  /// The package directories to examine, absolute, with `/` separators.
  final List<String> packages;

  /// Whether the user asked for the usage text.
  final bool help;
}

/// Parses `[--help] [<package directory>...]`. The default package is the
/// package of the running tool.
CheckOptions parseCheckOptions(List<String> args) {
  final packages = <String>[];
  var help = false;
  for (final arg in args) {
    if (arg == '--help' || arg == '-h') {
      help = true;
    } else if (arg.startsWith('-')) {
      throw FormatException('unknown option $arg');
    } else {
      packages.add(posixPath(Directory(arg).absolute.path));
    }
  }
  if (packages.isEmpty) packages.add(scriptPackage());
  return CheckOptions(packages, help: help);
}

/// Writes [findings] and a summary line to [out]. Returns the exit code: 1
/// if a finding is an error, else 0.
int reportFindings(
  String check,
  List<Finding> findings, {
  required StringSink out,
  required int files,
}) {
  findings.forEach(out.writeln);
  final errors = findings.where((f) => f.isError).length;
  final warnings = findings.length - errors;
  final status = errors == 0 ? 'passed' : 'failed';
  out.writeln(
    '$check: $status, $files files, $errors errors, $warnings warnings.',
  );
  return errors == 0 ? 0 : 1;
}

/// Runs [check] with the command line [args] and returns the exit code: 0
/// when it passes, 1 when it fails and 2 for a usage error.
Future<int> runCheck(
  List<String> args, {
  required String name,
  required String usage,
  required FutureOr<({List<Finding> findings, int files})> Function(
    List<String>,
  )
  check,
  required StringSink out,
}) async {
  final CheckOptions options;
  try {
    options = parseCheckOptions(args);
  } on FormatException catch (e) {
    out
      ..writeln('$name: ${e.message}')
      ..writeln(usage);
    return 2;
  }
  if (options.help) {
    out.writeln(usage);
    return 0;
  }
  for (final package in options.packages) {
    if (!File('$package/pubspec.yaml').existsSync()) {
      out.writeln('$name: $package has no pubspec.yaml');
      return 2;
    }
  }
  final result = await check(options.packages);
  return reportFindings(name, result.findings, out: out, files: result.files);
}
