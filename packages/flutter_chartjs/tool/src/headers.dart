// Original code, not ported from Chart.js: the file header grammar.

/// The header block of AGENTS.md rule 2 and porting-flow.md section 4, tool
/// 2: line 1 is a `// Ported from` line or the port-only marker, and the
/// lines directly after it are more `// Ported from` lines or backport lines.
library;

/// A `// Ported from` line.
///
/// The version is a dotted release, with or without `v`. Under a commit pin
/// (upstream-tracking.md 2.4), `+<sha8>` follows the release, for example
/// `v4.5.1+7169e651`.
final RegExp portedFromPattern = RegExp(
  r'^// Ported from (\S+) (v?\d+(?:\.\d+)*(?:\+[0-9a-f]{8})?) (\S+) '
  r'\(([^,]+), (.+)\)\.$',
);

/// The port-only marker.
final RegExp portOnlyPattern = RegExp(
  r'^// Original code, not ported from Chart\.js: (\S.*)\.$',
);

/// A backport line (upstream-tracking.md 4.2).
final RegExp backportPattern = RegExp(
  r'^// Upstream backport: chartjs/Chart\.js@([0-9a-f]{8}) \(#(\d+)\)\.$',
);

/// The start of a `// Ported from` line, also of a malformed one.
const String portedFromPrefix = '// Ported from';

/// The start of a backport line, also of a malformed one.
const String backportPrefix = '// Upstream backport';

/// The project name of Chart.js in headers.
const String chartJsProject = 'Chart.js';

/// One `// Ported from` line.
final class PortedFrom {
  /// The parts of a `// Ported from` line on [line].
  const PortedFrom({
    required this.line,
    required this.project,
    required this.version,
    required this.path,
    required this.license,
    required this.holder,
  });

  /// The 1-based line.
  final int line;

  /// The project, for example `Chart.js`.
  final String project;

  /// The version as written, for example `v4.5.1` or `v4.5.1+7169e651`.
  final String version;

  /// The source path in the project, for example `src/helpers/helpers.math.ts`.
  final String path;

  /// The SPDX license identifier.
  final String license;

  /// The copyright holder.
  final String holder;
}

/// One backport line.
final class Backport {
  /// The backport of commit [sha] (8 hex digits) from pull request [pr].
  const Backport(this.line, this.sha, this.pr);

  /// The 1-based line.
  final int line;

  /// The abbreviated upstream commit.
  final String sha;

  /// The upstream pull request number.
  final int pr;
}

/// What line 1 of a file is.
enum HeaderKind {
  /// A `// Ported from` line.
  ported,

  /// The port-only marker.
  portOnly,

  /// Neither.
  missing,
}

/// The header block of a Dart file.
final class Header {
  const Header._({
    required this.kind,
    required this.portedFrom,
    required this.backports,
    required this.malformed,
    required this.lastLine,
    this.portOnlyReason,
  });

  /// Parses the header block at the start of [lines].
  factory Header.parse(List<String> lines) {
    final first = lines.isEmpty ? '' : lines.first;
    final marker = portOnlyPattern.firstMatch(first);
    if (marker != null) {
      return Header._(
        kind: HeaderKind.portOnly,
        portedFrom: const [],
        backports: const [],
        malformed: const [],
        lastLine: 1,
        portOnlyReason: marker.group(1),
      );
    }
    if (portedFromPattern.firstMatch(first) == null) {
      return Header._(
        kind: HeaderKind.missing,
        portedFrom: const [],
        backports: const [],
        malformed: first.startsWith(portedFromPrefix) ? const [1] : const [],
        lastLine: 0,
      );
    }
    final portedFrom = <PortedFrom>[];
    final backports = <Backport>[];
    final malformed = <int>[];
    var index = 0;
    while (index < lines.length) {
      final text = lines[index];
      final line = index + 1;
      if (text.startsWith(portedFromPrefix)) {
        final match = portedFromPattern.firstMatch(text);
        if (match == null) {
          malformed.add(line);
        } else {
          portedFrom.add(
            PortedFrom(
              line: line,
              project: match.group(1)!,
              version: match.group(2)!,
              path: match.group(3)!,
              license: match.group(4)!,
              holder: match.group(5)!,
            ),
          );
        }
      } else if (text.startsWith(backportPrefix)) {
        final match = backportPattern.firstMatch(text);
        if (match == null) {
          malformed.add(line);
        } else {
          backports.add(
            Backport(line, match.group(1)!, int.parse(match.group(2)!)),
          );
        }
      } else {
        break;
      }
      index++;
    }
    return Header._(
      kind: HeaderKind.ported,
      portedFrom: portedFrom,
      backports: backports,
      malformed: malformed,
      lastLine: index,
    );
  }

  /// What line 1 is.
  final HeaderKind kind;

  /// The `// Ported from` lines, in order.
  final List<PortedFrom> portedFrom;

  /// The backport lines, in order.
  final List<Backport> backports;

  /// The lines of the block that start like a header line but do not match
  /// its grammar.
  final List<int> malformed;

  /// The last line of the block, or 0 when line 1 is not a header.
  final int lastLine;

  /// The reason of the port-only marker.
  final String? portOnlyReason;

  /// Whether line 1 is a `// Ported from Chart.js` line.
  bool get isChartJsPort =>
      kind == HeaderKind.ported &&
      portedFrom.isNotEmpty &&
      portedFrom.first.line == 1 &&
      portedFrom.first.project == chartJsProject;
}
