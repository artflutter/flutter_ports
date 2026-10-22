// Original code, not ported from Chart.js: the parity generator, tool 6.

/// The parity generator of porting-flow.md section 4, tool 6.
///
/// Tool 6 writes `doc/parity.md` from these inputs:
/// - the files of the pinned reference copies in `third_party/`, with their
///   line counts (`wc -l`): one table row for each file;
/// - the rule-2 headers of the Dart files in `lib/`, `test/` and `tool/` of
///   `flutter_chartjs_port` and `chartjs_test_utils`: the Dart target of a row;
/// - `doc/status.yaml`: the text of the document outside the tables, the
///   status text of each row and the rows of the port-only files;
/// - the case results of tool 5 and the fixture counts of
///   `doc/upstream/manifest.json`;
/// - the `DIVERGES(chartjs)` markers and the rows of `doc/differences.md`.
///
/// A text of `doc/status.yaml` can hold placeholders. Tool 6 replaces each
/// placeholder with a value that it derives:
/// - `{{differences}}`: the `differences.md` rows of the row: the count of
///   each category, then the link of each row. The rows are the
///   markers in the Dart files of the row. For a spec row, they also are the
///   skip reasons `diverges: <row id>` of its cases.
/// - `{{passed}}`, `{{failed}}`, `{{skipped}}`, `{{missing}}` and
///   `{{cases}}`: the case counts of tool 5 for the spec of the row. The spec
///   of a `src/` row is `test/specs/<base>.tests.js`.
///   `{{skipped:<reason>}}` counts the skipped cases with the skip reason
///   `<reason>`, or with a skip reason that starts with `<reason>:`.
/// - `{{platforms}}`: `the VM` for a Dart spec file with `@TestOn('vm')`,
///   else `the VM, dart2js and dart2wasm`.
/// - `{{files:<glob>}}`: the number of files that match the glob. A glob
///   that starts with `packages/` is relative to the repository. Another
///   glob is relative to the package.
/// - `{{rows:<area>:<status>}}`: the number of rows of the area with the
///   label `<area>` of the Summary table and with the status `<status>`.
///
/// A count placeholder can end with `|<word>`: `{{skipped|case}}` gives
/// `1 case` or `2 cases`.
///
/// Errors: a `status.yaml` entry of a file that no table lists, a status
/// text that does not start with a status value of porting-flow.md section 1
/// step 7, an unknown placeholder, a placeholder without its value, a row
/// with `DIVERGES` hunks and no `{{differences}}`, and a Dart target in
/// `status.yaml` for a row whose headers give the target.
///
/// Warnings: a row with a Dart file and the status `not started`, a port-only
/// Dart file that no port-only row names, and a path of a port-only row that
/// does not exist.
library;

import 'dart:convert';
import 'dart:io';

import 'check_support.dart';
import 'dart_source.dart';
import 'headers.dart';
import 'mini_yaml.dart';
import 'port_headers.dart';
import 'spec_cases.dart';

/// The name of the tool in its messages.
const String parityName = 'parity';

/// The path of the generated tracker, relative to the package.
const String parityPath = 'doc/parity.md';

/// The path of the hand-written states, relative to the package.
const String statusPath = 'doc/status.yaml';

/// The path of the upstream manifest of tool 4, relative to the package.
const String manifestPath = 'doc/upstream/manifest.json';

/// The status values of porting-flow.md section 1 step 7.
const List<String> statusValues = [
  'not started',
  'in progress',
  'partial',
  'ported',
  'replaced',
  'distributed',
  'n/a',
];

/// The status of a row that `doc/status.yaml` does not list.
const String defaultStatus = 'not started';

/// The title line of `parity.md`.
const String parityTitle = '# Chart.js parity tracker';

/// The status value at the start of [text], or null.
String? statusValueOf(String text) {
  for (final value in statusValues) {
    if (text == value ||
        (text.startsWith(value) &&
            !RegExp(r'[\w/-]').hasMatch(text[value.length]))) {
      return value;
    }
  }
  return null;
}

/// The category of the `differences.md` row ID [id]: its first part
/// (porting-flow.md section 4). An ID without a category gives the last
/// category; `check:headers` reports it.
String categoryOf(String id) => differenceCategories.firstWhere(
  (category) => id.startsWith('$category-'),
  orElse: () => differenceCategories.last,
);

/// The kind of the table of an area.
enum AreaKind {
  /// Upstream files with their Dart targets.
  sources,

  /// Upstream spec files with their cases and fixtures.
  specs,
}

/// One section of `parity.md` with a table of upstream files.
final class ParityArea {
  /// An area of the [project] files that [selectors] list.
  const ParityArea({
    required this.id,
    required this.heading,
    required this.label,
    required this.project,
    required this.selectors,
    this.kind = AreaKind.sources,
    this.level = 2,
  });

  /// The key of the prose of the area in `doc/status.yaml`.
  final String id;

  /// The heading text. `{version}` is the version of [project] without `v`.
  final String heading;

  /// The label of the area in the Summary table.
  final String label;

  /// The project of `tool/port_sources.yaml`.
  final String project;

  /// The project-relative files of the area, in order. `<dir>/` is each file
  /// under the directory, `<dir>/*` is each file directly in the directory,
  /// and another value is one file. The files of a selector are sorted.
  final List<String> selectors;

  /// The kind of the table.
  final AreaKind kind;

  /// The heading level.
  final int level;

  /// The heading line of the area for the [version] of its project.
  String headingLine(String version) =>
      '${'#' * level} ${heading.replaceAll('{version}', _bare(version))}';
}

String _bare(String version) =>
    version.startsWith('v') ? version.substring(1) : version;

/// The areas of `parity.md`, in document order.
const List<ParityArea> parityAreas = [
  ParityArea(
    id: 'helpers',
    heading: 'Helpers (`src/helpers`)',
    label: 'helpers',
    project: chartJsProject,
    selectors: ['src/helpers/'],
  ),
  ParityArea(
    id: 'core',
    heading: 'Core (`src/core`)',
    label: 'core',
    project: chartJsProject,
    selectors: ['src/core/'],
  ),
  ParityArea(
    id: 'elements',
    heading: 'Elements (`src/elements`)',
    label: 'elements',
    project: chartJsProject,
    selectors: ['src/elements/'],
  ),
  ParityArea(
    id: 'scales',
    heading: 'Scales (`src/scales`)',
    label: 'scales',
    project: chartJsProject,
    selectors: ['src/scales/'],
  ),
  ParityArea(
    id: 'controllers',
    heading: 'Dataset controllers (`src/controllers`)',
    label: 'controllers',
    project: chartJsProject,
    selectors: ['src/controllers/'],
  ),
  ParityArea(
    id: 'plugins',
    heading: 'Plugins (`src/plugins`)',
    label: 'plugins',
    project: chartJsProject,
    selectors: ['src/plugins/'],
  ),
  ParityArea(
    id: 'platform',
    heading: 'Platform (`src/platform`)',
    label: 'platform',
    project: chartJsProject,
    selectors: ['src/platform/'],
  ),
  ParityArea(
    id: 'types',
    heading: 'Type declarations (`src/types`)',
    label: 'types',
    project: chartJsProject,
    selectors: ['src/types/'],
  ),
  ParityArea(
    id: 'entry',
    heading: 'Entry points',
    label: 'entry points',
    project: chartJsProject,
    selectors: ['src/*'],
  ),
  ParityArea(
    id: 'specs',
    heading: 'Upstream tests',
    label: 'upstream specs',
    project: chartJsProject,
    selectors: ['test/specs/'],
    kind: AreaKind.specs,
  ),
  ParityArea(
    id: 'setup',
    heading: 'Test set-up',
    label: 'test set-up',
    project: chartJsProject,
    selectors: ['test/index.js'],
    level: 3,
  ),
  ParityArea(
    id: 'kurkle',
    heading: '@kurkle/color {version}',
    label: '@kurkle/color',
    project: '@kurkle/color',
    selectors: ['src/', 'packed.js', 'test/index.js'],
  ),
  ParityArea(
    id: 'test-utils',
    heading: 'chartjs-test-utils {version}',
    label: 'chartjs-test-utils',
    project: 'chartjs-test-utils',
    selectors: ['src/'],
  ),
];

/// The heading of the Summary section.
const String summaryHeading = '## Summary';

/// The heading of the port-only section.
const String portOnlyHeading = '## Port-only files';

/// The prose keys of `doc/status.yaml` that are not areas.
const List<String> fixedProseKeys = [
  'intro',
  'summary',
  'summary.after',
  'port-only',
];

/// A missing input: the command exits with 2.
final class ParityInputError implements Exception {
  /// The error [message].
  const ParityInputError(this.message);

  /// What is missing.
  final String message;

  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// doc/status.yaml.

/// One row of the port-only table: three cell texts.
final class PortOnlyEntry {
  /// A row with the cells [file], [contents] and [tests].
  const PortOnlyEntry(this.file, this.contents, this.tests);

  /// The text of the File cell.
  final String file;

  /// The text of the Contents cell.
  final String contents;

  /// The text of the Tests cell.
  final String tests;

  /// The three cells, in table order.
  List<String> get cells => [file, contents, tests];
}

/// The content of `doc/status.yaml`.
final class StatusFile {
  /// A status file with its parts.
  StatusFile({
    Map<String, List<String>>? prose,
    Map<String, Map<String, String>>? rows,
    Map<String, Map<String, String>>? dart,
    List<PortOnlyEntry>? portOnly,
  }) : prose = prose ?? {},
       rows = rows ?? {},
       dart = dart ?? {},
       portOnly = portOnly ?? [];

  /// The lines of each prose block. The keys are [fixedProseKeys], the area
  /// ids for the text before a table and `<area id>.after` for the text
  /// after a table.
  final Map<String, List<String>> prose;

  /// The status text of each row, by project and upstream path.
  final Map<String, Map<String, String>> rows;

  /// The Dart target of a row without a header that names its file, by
  /// project and upstream path. The target is relative to its package.
  final Map<String, Map<String, String>> dart;

  /// The rows of the port-only table, in order.
  final List<PortOnlyEntry> portOnly;
}

/// Reads `doc/status.yaml`. Throws a [FormatException].
StatusFile parseStatusFile(String text) {
  final document = parseYamlSubset(text);
  if (document == null) return StatusFile();
  if (document is! Map<String, Object?>) {
    throw const FormatException('the file is not a mapping');
  }
  for (final key in document.keys) {
    if (!const ['prose', 'rows', 'dart', 'port-only'].contains(key)) {
      throw FormatException('unknown key "$key"');
    }
  }
  Map<String, Object?> mapping(Object? value, String what) => switch (value) {
    null => const {},
    final Map<String, Object?> map => map,
    _ => throw FormatException('$what is a mapping'),
  };
  String string(Object? value, String what) => switch (value) {
    null => '',
    final String text => text,
    _ => throw FormatException('$what is a string'),
  };
  Map<String, Map<String, String>> projects(String key) => {
    for (final MapEntry(key: project, :value) in mapping(
      document[key],
      key,
    ).entries)
      project: {
        for (final MapEntry(key: path, :value) in mapping(
          value,
          '$key.$project',
        ).entries)
          path: string(value, '$key.$project.$path'),
      },
  };
  final prose = <String, List<String>>{};
  for (final MapEntry(:key, :value) in mapping(
    document['prose'],
    'prose',
  ).entries) {
    if (value is! List<Object?>) {
      throw FormatException('prose.$key is a list of lines');
    }
    prose[key] = [for (final line in value) string(line, 'a line of $key')];
  }
  final portOnly = <PortOnlyEntry>[];
  final rows = document['port-only'];
  if (rows != null && rows is! List<Object?>) {
    throw const FormatException('port-only is a list');
  }
  for (final row in (rows as List<Object?>?) ?? const []) {
    final map = mapping(row, 'a port-only row');
    for (final key in map.keys) {
      if (!const ['file', 'contents', 'tests'].contains(key)) {
        throw FormatException('a port-only row has the unknown key "$key"');
      }
    }
    portOnly.add(
      PortOnlyEntry(
        string(map['file'], 'file'),
        string(map['contents'], 'contents'),
        string(map['tests'], 'tests'),
      ),
    );
  }
  return StatusFile(
    prose: prose,
    rows: projects('rows'),
    dart: projects('dart'),
    portOnly: portOnly,
  );
}

/// The comment at the start of `doc/status.yaml`.
const String statusFileComment = '''
# The hand-written parts of doc/parity.md (porting-flow.md section 1 step 7).
# Tool 6 (tool/parity.dart, porting-flow.md section 4) writes doc/parity.md
# from this file, the upstream file lists, the headers of the Dart files,
# the case results of tool 5 and doc/differences.md. Edit this file, then run
# "dart run melos run parity". "dart run melos run parity:check" fails when
# doc/parity.md differs from the output.
#
# "dart run melos run parity -- --import" reads the cells of doc/parity.md
# back into this file. It keeps an entry whose output equals the cell. It
# replaces the derived counts of a changed cell with placeholders. Add
# "--base <file>" with the doc/parity.md that this file came from: then a
# cell that did not change after <file> keeps its entry here.
#
# Keys:
# - prose: the lines of the text outside the tables, by section. The keys
#   are intro, summary, summary.after, port-only, the area ids (the text
#   before the table) and "<area id>.after" (the text after the table).
# - rows: the status text of each row, by project and upstream path. A row
#   that is not listed is "not started". The text starts with a status
#   value of porting-flow.md section 1 step 7.
# - dart: the Dart target of a row whose file no header names, for example
#   the replacement file of a "replaced" row. It is relative to its package.
# - port-only: the rows of the port-only table (file, contents, tests).
#
# Placeholders (tool/src/parity.dart):
# - {{differences}}: the differences.md count by category and the links of
#   the DIVERGES hunks of the row.
# - {{passed}}, {{failed}}, {{skipped}}, {{missing}}, {{cases}}: the case
#   counts of tool 5. {{skipped:<reason>}} counts one skip reason.
# - {{platforms}}: "the VM", or "the VM, dart2js and dart2wasm".
# - {{files:<glob>}}: the number of files that match the glob.
# - {{rows:<area>:<status>}}: the number of rows of a Summary area with a
#   status value.
# - A count with "|<word>" adds the word: {{skipped|case}} is "2 cases".
''';

/// The text of `doc/status.yaml` for [status].
String writeStatusFile(StatusFile status) {
  final out = StringBuffer(statusFileComment);
  void section(String key) => out
    ..writeln()
    ..writeln('$key:');
  if (status.prose.isNotEmpty) {
    section('prose');
    for (final MapEntry(:key, :value) in status.prose.entries) {
      out.writeln('  ${_yamlKey(key)}:');
      for (final line in value) {
        out.writeln('    - ${_yamlString(line)}');
      }
    }
  }
  for (final (key, projects) in [
    ('rows', status.rows),
    ('dart', status.dart),
  ]) {
    if (projects.values.every((rows) => rows.isEmpty)) continue;
    section(key);
    for (final MapEntry(key: project, value: rows) in projects.entries) {
      if (rows.isEmpty) continue;
      out.writeln('  ${_yamlKey(project)}:');
      for (final MapEntry(key: path, :value) in rows.entries) {
        out.writeln('    ${_yamlKey(path)}: ${_yamlString(value)}');
      }
    }
  }
  if (status.portOnly.isNotEmpty) {
    section('port-only');
    for (final row in status.portOnly) {
      out
        ..writeln('  - file: ${_yamlString(row.file)}')
        ..writeln('    contents: ${_yamlString(row.contents)}')
        ..writeln('    tests: ${_yamlString(row.tests)}');
    }
  }
  return out.toString();
}

String _yamlKey(String key) =>
    RegExp(r'^[A-Za-z0-9_][A-Za-z0-9_./-]*$').hasMatch(key)
    ? key
    : _yamlString(key);

String _yamlString(String value) {
  final out = StringBuffer('"');
  for (final rune in value.runes) {
    switch (rune) {
      case 0x22:
        out.write(r'\"');
      case 0x5C:
        out.write(r'\\');
      case 0x0A:
        out.write(r'\n');
      case 0x09:
        out.write(r'\t');
      case < 0x20:
        out.write(r'\u' + rune.toRadixString(16).padLeft(4, '0'));
      default:
        out.writeCharCode(rune);
    }
  }
  out.write('"');
  return out.toString();
}

// ---------------------------------------------------------------------------
// The inputs.

/// The inputs of tool 6.
final class ParityInput {
  /// The inputs for the [package] (`flutter_chartjs_port`) in the [repository],
  /// with the JSON reporter output [results] of the spec tests.
  const ParityInput({
    required this.repository,
    required this.package,
    required this.results,
  });

  /// The repository root, absolute, with `/` separators.
  final String repository;

  /// The `flutter_chartjs_port` package, absolute, with `/` separators.
  final String package;

  /// The tests of the spec files.
  final ReporterOutput results;
}

/// One table row of an upstream file.
final class UpstreamRow {
  /// The row of [path] of the project [source] in [area].
  const UpstreamRow({
    required this.area,
    required this.source,
    required this.path,
    required this.lines,
    required this.targets,
    required this.differences,
    this.spec,
    this.specFile,
    this.vmOnly,
    this.fixtures,
  });

  /// The area of the row.
  final ParityArea area;

  /// The project.
  final PortSource source;

  /// The project-relative upstream path.
  final String path;

  /// The line count of the upstream file.
  final int lines;

  /// The Dart files whose headers name [path], relative to their packages.
  final List<String> targets;

  /// The `differences.md` row IDs of the row, in the order of the
  /// categories and then of `differences.md`.
  final List<String> differences;

  /// The tool 5 report of the spec of the row, or null.
  final SpecReport? spec;

  /// The upstream spec file of [spec], for messages.
  final String? specFile;

  /// Whether the Dart spec file of [spec] has `@TestOn('vm')`, or null
  /// without a Dart spec file.
  final bool? vmOnly;

  /// The fixture count of a spec row, or null.
  final int? fixtures;

  /// The link of the upstream file, at the pinned tree.
  String get url => '${source.url}/blob/${source.treeRef}/$path';

  /// The first cell of the row.
  String get link => '[`$path`]($url)';
}

/// The derived data of `parity.md`.
final class ParityModel {
  /// The model of the [package] in the [repository].
  ParityModel({
    required this.repository,
    required this.package,
    required this.sources,
    required this.rows,
    required this.portOnlyFiles,
  });

  /// The repository root.
  final String repository;

  /// The `flutter_chartjs_port` package.
  final String package;

  /// The projects of `tool/port_sources.yaml` by header name.
  final Map<String, PortSource> sources;

  /// The rows of every area, in document order.
  final List<UpstreamRow> rows;

  /// The repository-relative Dart files that the port-only section lists:
  /// the files with the port-only marker and the files of projects without
  /// an area.
  final List<String> portOnlyFiles;

  /// The row of [path] in [project], or null.
  UpstreamRow? rowOf(String project, String path) => _index['$project $path'];

  late final Map<String, UpstreamRow> _index = {
    for (final row in rows) '${row.source.header} ${row.path}': row,
  };

  /// The rows of [area].
  Iterable<UpstreamRow> rowsOf(ParityArea area) =>
      rows.where((row) => row.area == area);
}

final RegExp _marker = RegExp(r'^// DIVERGES\(chartjs\): (\S+), ');

/// Reads the inputs and derives the rows. Throws a [ParityInputError] when
/// an input is missing or does not parse.
ParityModel computeParity(ParityInput input) {
  final repository = input.repository;
  final package = input.package;
  String read(String path) {
    final file = File('$package/$path');
    if (!file.existsSync()) {
      throw ParityInputError(
        '${relativePath(repository, file.path)} '
        'does not exist.',
      );
    }
    return file.readAsStringSync();
  }

  final Map<String, PortSource> sources;
  final Manifest manifest;
  try {
    sources = {
      for (final source in parsePortSources(read(portSourcesPath)))
        source.header: source,
    };
    manifest = Manifest.parse(read(manifestPath));
  } on FormatException catch (e) {
    throw ParityInputError(e.message);
  }
  final differenceRows = parseDifferences(read(differencesPath));
  final order = {
    for (final (index, row) in differenceRows.indexed) row.id: index,
  };

  // The headers and the markers of the Dart files.
  final targets = <String, List<String>>{};
  final headerFiles = <String, List<String>>{};
  final markers = <String, List<String>>{};
  final vmOnly = <String, bool>{};
  final portOnlyFiles = <String>[];
  final areaProjects = {for (final area in parityAreas) area.project};
  for (final dir in withHarnessPackage([package])) {
    for (final directory in examinedDirectories) {
      for (final file in dartFilesUnder('$dir/$directory')) {
        final source = DartSource(File(file).readAsStringSync());
        final header = Header.parse(source.lines);
        final shown = relativePath(dir, file);
        final ids = <String>[
          for (final comment in source.comments)
            if (comment.isLineComment)
              if (_marker.firstMatch(comment.text) case final match?) match[1]!,
        ];
        markers[file] = ids;
        if (dir == package && shown.startsWith('test/specs/')) {
          vmOnly[shown] = source.isVmOnly;
        }
        if (header.kind == HeaderKind.portOnly ||
            header.portedFrom.any((p) => !areaProjects.contains(p.project))) {
          portOnlyFiles.add(relativePath(repository, file));
        }
        for (final portedFrom in header.portedFrom) {
          final key = '${portedFrom.project} ${portedFrom.path}';
          (targets[key] ??= []).add(shown);
          (headerFiles[key] ??= []).add(file);
        }
      }
    }
  }

  final reports = {
    for (final report in compareCases(
      manifest,
      input.results,
      const {},
    ).reports)
      report.spec: report,
  };

  List<String> ordered(Iterable<String> ids) {
    final unique = ids.toSet().toList();
    int rank(String id) => differenceCategories.indexOf(categoryOf(id));
    return unique..sort((a, b) {
      final byCategory = rank(a).compareTo(rank(b));
      if (byCategory != 0) return byCategory;
      final byRow = (order[a] ?? order.length).compareTo(
        order[b] ?? order.length,
      );
      return byRow != 0 ? byRow : a.compareTo(b);
    });
  }

  final rows = <UpstreamRow>[];
  for (final area in parityAreas) {
    final source = sources[area.project];
    if (source == null) {
      throw ParityInputError(
        '$portSourcesPath has no entry ${area.project}.',
      );
    }
    final pin = '$repository/${source.pinPath}';
    final pinDir = Directory(pin);
    if (!pinDir.existsSync() || pinDir.listSync().isEmpty) {
      throw ParityInputError(
        '${source.pinPath} is not checked out: run '
        '"dart run melos run upstream".',
      );
    }
    for (final path in _select(pin, area.selectors)) {
      final key = '${source.header} $path';
      final files = headerFiles[key] ?? const <String>[];
      final ids = [for (final file in files) ...?markers[file]];
      final String? specFile;
      if (area.kind == AreaKind.specs) {
        specFile = path.substring('test/specs/'.length);
      } else if (area.project == chartJsProject && path.startsWith('src/')) {
        final name = path.split('/').last;
        final base = name.replaceFirst(RegExp(r'(\.d)?\.[jt]s$'), '');
        specFile = manifest.specs.containsKey('$base.tests.js')
            ? '$base.tests.js'
            : null;
      } else {
        specFile = null;
      }
      final spec = specFile == null ? null : reports[specFile];
      if (area.kind == AreaKind.specs && spec != null) {
        ids.addAll([
          for (final result in spec.results)
            if (result.status == CaseStatus.skipped)
              if (result.test?.skipReason case final reason?
                  when reason.startsWith('diverges: '))
                reason.substring('diverges: '.length),
        ]);
      }
      rows.add(
        UpstreamRow(
          area: area,
          source: source,
          path: path,
          lines: _lineCount('$pin/$path'),
          targets: targets[key] ?? const [],
          differences: ordered(ids),
          spec: spec,
          specFile: specFile,
          vmOnly: specFile == null ? null : vmOnly[dartSpecOf(specFile)],
          fixtures: area.kind == AreaKind.specs
              ? manifest.specs[specFile]?.fixtures.length ?? 0
              : null,
        ),
      );
    }
  }
  return ParityModel(
    repository: repository,
    package: package,
    sources: sources,
    rows: rows,
    portOnlyFiles: portOnlyFiles,
  );
}

/// The project-relative files of [selectors] under [pin].
List<String> _select(String pin, List<String> selectors) {
  final result = <String>[];
  for (final selector in selectors) {
    final files = <String>[];
    if (selector.endsWith('/') || selector.endsWith('/*')) {
      final dir = Directory(
        '$pin/${selector.substring(0, selector.lastIndexOf('/'))}',
      );
      if (dir.existsSync()) {
        for (final entity in dir.listSync(recursive: selector.endsWith('/'))) {
          if (entity is File) files.add(relativePath(pin, entity.path));
        }
      }
    } else if (File('$pin/$selector').existsSync()) {
      files.add(selector);
    }
    for (final file in files..sort()) {
      if (!result.contains(file)) result.add(file);
    }
  }
  return result;
}

/// The `wc -l` count of [path]: the number of line feeds.
int _lineCount(String path) =>
    File(path).readAsBytesSync().where((byte) => byte == 0x0A).length;

// ---------------------------------------------------------------------------
// Placeholders.

final RegExp _placeholder = RegExp(r'\{\{([^{}]*)\}\}');

/// The values of the placeholders of one text.
final class _Scope {
  const _Scope(this.model, {this.row, this.statuses = const {}});

  final ParityModel model;
  final UpstreamRow? row;

  /// The expanded status of each row, for `{{rows:...}}`.
  final Map<UpstreamRow, String> statuses;
}

/// [template] with each placeholder replaced. Adds a message to [errors] for
/// each placeholder without a value.
String _expand(String template, _Scope scope, List<String> errors) {
  final rest = template.replaceAll(_placeholder, '');
  if (rest.contains('{{') || rest.contains('}}')) {
    errors.add('an unclosed "{{" or a lone "}}".');
  }
  return template.replaceAllMapped(_placeholder, (match) {
    final body = match[1]!.trim();
    final bar = body.lastIndexOf('|');
    final expression = bar < 0 ? body : body.substring(0, bar).trim();
    final word = bar < 0 ? null : body.substring(bar + 1).trim();
    final colon = expression.indexOf(':');
    final name = colon < 0 ? expression : expression.substring(0, colon);
    final argument = colon < 0 ? null : expression.substring(colon + 1);
    final value = _value(name, argument, scope, errors, match[0]!);
    if (value == null) return match[0]!;
    if (value is String) {
      if (word != null) errors.add('${match[0]} takes no "|<word>".');
      return value;
    }
    if (word == null || word.isEmpty) return '$value';
    return value == 1 ? '1 $word' : '$value ${word}s';
  });
}

/// The value of the placeholder [name] with [argument]: a [String], an
/// [int], or null after a message in [errors].
Object? _value(
  String name,
  String? argument,
  _Scope scope,
  List<String> errors,
  String text,
) {
  final row = scope.row;
  switch (name) {
    case 'differences' when argument == null:
      if (row == null) {
        errors.add('$text is only for a row.');
        return null;
      }
      if (row.differences.isEmpty) {
        errors.add(
          '$text: the Dart files of the row have no DIVERGES hunk. '
          'Remove the placeholder.',
        );
        return 'differences: none';
      }
      return _differencesText(row.differences);
    case 'passed' || 'failed' || 'missing' || 'cases' || 'skipped':
      final spec = row?.spec;
      if (spec == null) {
        errors.add(
          row?.specFile == null
              ? '$text needs a row with an upstream spec.'
              : '$text: tool 5 has no cases of ${row!.specFile}.',
        );
        return null;
      }
      if (argument != null && name != 'skipped') break;
      return switch (name) {
        'passed' => spec.count(CaseStatus.passed),
        'failed' => spec.count(CaseStatus.failed),
        'missing' => spec.count(CaseStatus.missing),
        'cases' => spec.results.length,
        _ when argument == null => spec.count(CaseStatus.skipped),
        _ => spec.results.where((result) {
          final reason = result.test?.skipReason;
          return result.status == CaseStatus.skipped &&
              reason != null &&
              (reason == argument || reason.startsWith('$argument:'));
        }).length,
      };
    case 'platforms' when argument == null:
      final vmOnly = row?.vmOnly;
      if (vmOnly == null) {
        errors.add('$text needs a row with a Dart spec file.');
        return null;
      }
      return vmOnly ? 'the VM' : 'the VM, dart2js and dart2wasm';
    case 'files' when argument != null && argument.isNotEmpty:
      return _countFiles(scope.model, argument);
    case 'rows' when argument != null:
      final colon = argument.indexOf(':');
      final label = colon < 0 ? argument : argument.substring(0, colon);
      final status = colon < 0 ? null : argument.substring(colon + 1);
      final area = parityAreas.where((a) => a.label == label).firstOrNull;
      if (area == null || status == null) {
        errors.add('$text names no Summary area and status.');
        return null;
      }
      return scope.model
          .rowsOf(area)
          .where(
            (r) => statusValueOf(scope.statuses[r] ?? defaultStatus) == status,
          )
          .length;
  }
  errors.add('unknown placeholder $text.');
  return null;
}

/// The text of `{{differences}}` for the row IDs [ids]: the count of each
/// category, then the link of each row.
String _differencesText(List<String> ids) {
  final counts = <String, int>{};
  for (final id in ids) {
    final category = categoryOf(id);
    counts[category] = (counts[category] ?? 0) + 1;
  }
  final byCategory = [
    for (final category in differenceCategories)
      if (counts[category] case final count?) '$count `$category`',
  ];
  return [
    'differences: ${byCategory.join(', ')}',
    for (final id in ids) '[differences.md](differences.md#$id)',
  ].join(', ');
}

/// The number of files that match [glob].
int _countFiles(ParityModel model, String glob) {
  final base = glob.startsWith('packages/') ? model.repository : model.package;
  final star = glob.indexOf('*');
  final fixed = star < 0 ? glob : glob.substring(0, star);
  final dir = fixed.contains('/')
      ? fixed.substring(0, fixed.lastIndexOf('/'))
      : '';
  final root = Directory(dir.isEmpty ? base : '$base/$dir');
  if (!root.existsSync()) return 0;
  final pattern = globToRegExp(glob);
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => pattern.hasMatch(relativePath(base, file.path)))
      .length;
}

// ---------------------------------------------------------------------------
// The document.

/// The Markdown cell text of [text]: a `|` that is not escaped gets a `\`.
String _cell(String text) => text.replaceAll(RegExp(r'(?<!\\)\|'), r'\|');

/// One table row of [cells]. An empty cell is one space.
String _tableRow(List<String> cells) {
  final padded = [
    for (final cell in cells)
      if (cell.isEmpty) ' ' else ' $cell ',
  ];
  return '|${padded.join('|')}|';
}

/// The header and the separator lines of a table.
List<String> _tableHead(List<String> names, List<bool> numeric) {
  final separators = [
    for (final n in numeric)
      if (n) '---:' else '---',
  ];
  return [_tableRow(names), '|${separators.join('|')}|'];
}

/// The result of [renderParity].
final class ParityOutput {
  /// The [text] of `parity.md` and the [findings].
  const ParityOutput(this.text, this.findings);

  /// The text of `parity.md`.
  final String text;

  /// The errors and the warnings.
  final List<Finding> findings;
}

/// Renders `parity.md` from [model] and [status]. Paths in findings are
/// relative to the repository.
ParityOutput renderParity(ParityModel model, StatusFile status) {
  final findings = <Finding>[];
  final statusFile = relativePath(
    model.repository,
    '${model.package}/$statusPath',
  );
  void error(String message) =>
      findings.add(Finding(statusFile, null, message));
  void warn(String message) =>
      findings.add(Finding.warning(statusFile, null, message));

  // The entries of status.yaml without a row.
  for (final projects in [status.rows, status.dart]) {
    for (final entry in projects.entries) {
      for (final path in entry.value.keys) {
        if (model.rowOf(entry.key, path) == null) {
          error('${entry.key} $path is not a file of a table of parity.md.');
        }
      }
    }
  }
  for (final key in status.prose.keys) {
    final area = key.endsWith('.after')
        ? key.substring(0, key.length - '.after'.length)
        : key;
    if (!fixedProseKeys.contains(key) &&
        !parityAreas.any((a) => a.id == area)) {
      error('prose key "$key" is not a section of parity.md.');
    }
  }

  // The status of each row.
  final statuses = <UpstreamRow, String>{};
  final rowTexts = <UpstreamRow, ({String status, String dart})>{};
  for (final row in model.rows) {
    final project = row.source.header;
    final template = status.rows[project]?[row.path] ?? defaultStatus;
    final errors = <String>[];
    final text = _expand(template, _Scope(model, row: row), errors);
    for (final message in errors) {
      error('$project ${row.path}: $message');
    }
    final value = statusValueOf(text);
    if (value == null) {
      error(
        '$project ${row.path}: the status "${_short(text)}" does not start '
        'with a value of porting-flow.md section 1 step 7 '
        '(${statusValues.join(', ')}).',
      );
    }
    if (row.differences.isNotEmpty && !template.contains('{{differences}}')) {
      error(
        '$project ${row.path}: the Dart files of the row have DIVERGES hunks '
        '(${row.differences.join(', ')}). Add {{differences}} to its status.',
      );
    }
    if (text.contains('\n')) {
      error('$project ${row.path}: the status has a line break.');
    }
    final override = status.dart[project]?[row.path];
    if (override != null && row.targets.isNotEmpty) {
      error(
        '$project ${row.path}: the headers give the Dart target '
        '${row.targets.join(', ')}. Remove its "dart" entry.',
      );
    }
    final dart = [
      for (final target in row.targets.isNotEmpty ? row.targets : [?override])
        '`$target`',
    ].join(', ');
    if (value == defaultStatus && row.targets.isNotEmpty) {
      warn(
        '$project ${row.path}: ${row.targets.join(', ')} exists, but the '
        'status is "$defaultStatus".',
      );
    }
    statuses[row] = text;
    rowTexts[row] = (status: text, dart: dart);
  }

  final lines = <String>[parityTitle, ''];
  void prose(String key) {
    final block = status.prose[key];
    if (block == null || block.isEmpty) return;
    final errors = <String>[];
    final text = _expand(
      block.join('\n'),
      _Scope(model, statuses: statuses),
      errors,
    );
    for (final message in errors) {
      error('prose $key: $message');
    }
    lines
      ..addAll(text.split('\n'))
      ..add('');
  }

  prose('intro');
  lines.addAll([summaryHeading, '']);
  prose('summary');
  lines.addAll(
    _tableHead(['Area', 'Files', 'Lines', 'Ported'], [false, true, true, true]),
  );
  for (final area in parityAreas) {
    final rows = model.rowsOf(area).toList();
    lines.add(
      _tableRow([
        area.label,
        '${rows.length}',
        '${rows.fold(0, (sum, row) => sum + row.lines)}',
        '${rows.where((r) => statusValueOf(statuses[r]!) == 'ported').length}',
      ]),
    );
  }
  lines.add('');
  prose('summary.after');

  for (final area in parityAreas) {
    final source = model.sources[area.project]!;
    lines.addAll([area.headingLine(source.version), '']);
    prose(area.id);
    if (area.kind == AreaKind.specs) {
      lines.addAll(
        _tableHead(
          [
            'Upstream spec',
            'Lines',
            'Cases',
            'Fixtures',
            'Dart test',
            'Status',
          ],
          [false, true, true, true, false, false],
        ),
      );
    } else {
      lines.addAll(
        _tableHead(
          ['Upstream file', 'Lines', 'Dart target', 'Status'],
          [false, true, false, false],
        ),
      );
    }
    for (final row in model.rowsOf(area)) {
      final text = rowTexts[row]!;
      lines.add(
        _tableRow([
          row.link,
          '${row.lines}',
          if (area.kind == AreaKind.specs) ...[
            '${row.spec?.results.length ?? 0}',
            '${row.fixtures ?? 0}',
          ],
          text.dart,
          _cell(text.status),
        ]),
      );
    }
    lines.add('');
    prose('${area.id}.after');
  }

  lines.addAll([portOnlyHeading, '']);
  prose('port-only');
  lines.addAll(
    _tableHead(['File', 'Contents', 'Tests'], [false, false, false]),
  );
  for (final (index, entry) in status.portOnly.indexed) {
    final errors = <String>[];
    final cells = [
      for (final cell in entry.cells)
        _cell(_expand(cell, _Scope(model), errors)),
    ];
    for (final message in errors) {
      error('port-only row ${index + 1}: $message');
    }
    if (cells.first.trim().isEmpty) {
      error('port-only row ${index + 1} has no file.');
    }
    lines.add(_tableRow(cells));
  }
  _checkPortOnly(model, status, warn);
  return ParityOutput('${lines.join('\n')}\n', findings);
}

String _short(String text) =>
    text.length <= 60 ? text : '${text.substring(0, 57)}...';

/// The backticked paths of [text].
Iterable<String> _paths(String text) => [
  for (final match in RegExp('`([^`]+)`').allMatches(text))
    if (RegExp(r'^[\w.*/-]+$').hasMatch(match[1]!) && match[1]!.contains('/'))
      match[1]!,
];

/// Warns about a port-only Dart file that no port-only row names, and about
/// a path of a port-only row that does not exist.
///
/// The paths of a row are the backticked paths of its File and Tests cells.
/// A path that starts with `packages/` is relative to the repository. Another
/// path is relative to the package, or to the package of the last
/// `packages/<name>/` path before it in the same cell.
void _checkPortOnly(
  ParityModel model,
  StatusFile status,
  void Function(String) warn,
) {
  final packageDir = relativePath(model.repository, model.package);
  bool exists(String path) => path.contains('*')
      ? _countFiles(model, path) > 0
      : FileSystemEntity.typeSync('${model.repository}/$path') !=
            FileSystemEntityType.notFound;
  final named = <String>[];
  for (final entry in status.portOnly) {
    for (final (index, cell) in [entry.file, entry.tests].indexed) {
      var base = packageDir;
      for (final path in _paths(cell.replaceAll(_placeholder, ''))) {
        final String full;
        if (path.startsWith('packages/')) {
          final parts = path.split('/');
          base = parts.length > 2 ? '${parts[0]}/${parts[1]}' : packageDir;
          full = path;
        } else {
          final own = '$packageDir/$path';
          full = exists(own) ? own : '$base/$path';
        }
        named.add(full);
        if (index == 0 && !exists(full)) {
          warn('the port-only row of $path names a path that does not exist.');
        }
      }
    }
  }
  bool covers(String pattern, String file) {
    if (pattern.contains('*')) return globToRegExp(pattern).hasMatch(file);
    return pattern == file ||
        (pattern.endsWith('/') && file.startsWith(pattern));
  }

  for (final file in model.portOnlyFiles) {
    if (!named.any((pattern) => covers(pattern, file))) {
      warn('no port-only row names $file.');
    }
  }
}

// ---------------------------------------------------------------------------
// The import of parity.md into status.yaml.

/// One table of a parsed `parity.md`.
final class _Table {
  _Table(this.line, this.head);

  final int line;
  final List<String> head;
  final List<({int line, List<String> cells})> rows = [];
}

/// One section of a parsed `parity.md`.
final class _Section {
  _Section(this.heading, this.line);

  final String heading;
  final int line;
  final List<String> before = [];
  final List<String> after = [];
  _Table? table;
}

/// The cells of the table row [line].
List<String> _cells(String line) {
  var text = line.trim();
  if (text.startsWith('|')) text = text.substring(1);
  if (text.endsWith('|') && !text.endsWith(r'\|')) {
    text = text.substring(0, text.length - 1);
  }
  return [
    for (final cell in text.split(RegExp(r'(?<!\\)\|')))
      cell.trim().replaceAll(r'\|', '|'),
  ];
}

List<String> _trimBlank(List<String> lines) {
  var start = 0;
  var end = lines.length;
  while (start < end && lines[start].trim().isEmpty) {
    start++;
  }
  while (end > start && lines[end - 1].trim().isEmpty) {
    end--;
  }
  return lines.sublist(start, end);
}

/// The sections of [markdown]: the text before the first `##` heading is
/// the section with the heading `''`.
List<_Section> _sections(String markdown) {
  final sections = [_Section('', 1)];
  final lines = const LineSplitter().convert(markdown);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final section = sections.last;
    if (line.startsWith('## ') || line.startsWith('### ')) {
      sections.add(_Section(line, i + 1));
    } else if (line.startsWith('# ') && i == 0) {
      continue;
    } else if (line.trimLeft().startsWith('|')) {
      final table = section.table;
      if (table == null) {
        section.table = _Table(i + 1, _cells(line));
      } else if (!RegExp(r'^\|?[\s:|-]+\|?$').hasMatch(line.trim())) {
        table.rows.add((line: i + 1, cells: _cells(line)));
      }
    } else if (section.table == null) {
      section.before.add(line);
    } else {
      section.after.add(line);
    }
  }
  for (final section in sections) {
    final before = _trimBlank(section.before);
    final after = _trimBlank(section.after);
    section.before
      ..clear()
      ..addAll(before);
    section.after
      ..clear()
      ..addAll(after);
  }
  return sections;
}

/// The result of [importParity].
final class ParityImport {
  /// The new [status] and the [findings].
  const ParityImport(this.status, this.findings);

  /// The content of the new `doc/status.yaml`.
  final StatusFile status;

  /// The differences between the cells of `parity.md` and the derived
  /// values, and the cells that tool 6 cannot read.
  final List<Finding> findings;
}

/// Reads the hand-written parts of the `parity.md` text [markdown] into a
/// new status file. An entry of [previous] whose output equals the cell
/// stays as it is. Another cell becomes the new entry, with placeholders in
/// place of its derived counts. [markdownPath] is the path of [markdown] in
/// findings.
///
/// [base] is the `parity.md` text that [previous] came from. With [base], a
/// cell that equals its cell in [base] keeps the entry of [previous]: only
/// the cells that changed after [base] replace entries. A row of [previous]
/// that [markdown] does not have stays at its place.
ParityImport importParity(
  String markdown,
  ParityModel model,
  StatusFile previous, {
  String markdownPath = 'doc/parity.md',
  String? base,
}) {
  final findings = <Finding>[];
  void warn(int? line, String message) =>
      findings.add(Finding.warning(markdownPath, line, message));

  final result = StatusFile();
  final previousOutput = renderParity(model, previous);
  final previousSections = {
    for (final section in _sections(previousOutput.text))
      section.heading: section,
  };
  final headings = <String, ({ParityArea? area, String key})>{
    '': (area: null, key: 'intro'),
    summaryHeading: (area: null, key: 'summary'),
    portOnlyHeading: (area: null, key: 'port-only'),
    for (final area in parityAreas)
      area.headingLine(model.sources[area.project]!.version): (
        area: area,
        key: area.id,
      ),
  };

  final baseCells = base == null ? null : _baseCells(base, model, headings);

  final proseSeen = <String>{};
  void proseOf(String key, List<String> lines, List<String>? old) {
    proseSeen.add(key);
    if (lines.isEmpty) return;
    final kept = previous.prose[key];
    final was = baseCells?.prose[key];
    final unchanged = was != null && _sameLines(was, lines);
    if (kept != null &&
        (unchanged || (old != null && _sameLines(old, lines)))) {
      result.prose[key] = kept;
      return;
    }
    if (kept != null && (was == null || old == null || !_sameLines(old, was))) {
      warn(
        null,
        'the prose "$key" of $statusPath differs. The text of '
        'parity.md replaces it.',
      );
    }
    result.prose[key] = key == 'summary' ? _summaryProse(lines) : lines;
  }

  final rowsSeen = <String>{};
  _Section? summary;
  for (final section in _sections(markdown)) {
    final known = headings[section.heading];
    if (known == null) {
      warn(
        section.line,
        'the section "${section.heading}" is not a section '
        'of tool 6. Its text is not imported.',
      );
      continue;
    }
    final old = previousSections[section.heading];
    proseOf(known.key, section.before, old?.before);
    if (known.key == 'summary') {
      proseOf('summary.after', section.after, old?.after);
      summary = section;
      continue;
    }
    if (known.area != null) {
      proseOf('${known.key}.after', section.after, old?.after);
    }
    final table = section.table;
    if (table == null) continue;
    if (known.key == 'port-only') {
      _importPortOnly(
        table,
        model,
        previous,
        result,
        warn,
        baseCells?.portOnly,
      );
      continue;
    }
    final area = known.area;
    if (area == null) continue;
    final source = model.sources[area.project]!;
    final statusColumn = table.head.length - 1;
    final linesColumn = table.head.indexOf('Lines');
    final dartColumn = table.head.indexWhere(
      (name) => name == 'Dart target' || name == 'Dart test',
    );
    for (final (:line, :cells) in table.rows) {
      final match = RegExp(r'^\[`([^`]+)`\]\(([^)\s]*)\)$').firstMatch(
        cells.first,
      );
      final row = match == null ? null : model.rowOf(source.header, match[1]!);
      if (row == null || match![2] != row.url) {
        warn(
          line,
          'the row "${_short(cells.first)}" is not a file of '
          '${source.header} in ${section.heading}.',
        );
        continue;
      }
      rowsSeen.add('${source.header} ${row.path}');
      if (linesColumn >= 0 &&
          linesColumn < cells.length &&
          cells[linesColumn] != '${row.lines}') {
        warn(
          line,
          '${row.path}: Lines is ${cells[linesColumn]}, the file '
          'has ${row.lines} lines.',
        );
      }
      final cell = statusColumn < cells.length ? cells[statusColumn] : '';
      final dart = dartColumn >= 0 && dartColumn < cells.length
          ? cells[dartColumn]
          : '';
      final was = baseCells?.rows['${source.header} ${row.path}'];
      _importRow(
        row,
        (cell: cell, dart: dart, line: line),
        model,
        previous,
        result,
        warn,
        was,
      );
    }
  }
  for (final row in model.rows) {
    final project = row.source.header;
    if (rowsSeen.contains('$project ${row.path}')) continue;
    final kept = previous.rows[project]?[row.path];
    if (kept != null) (result.rows[project] ??= {})[row.path] = kept;
    final dart = previous.dart[project]?[row.path];
    if (dart != null) (result.dart[project] ??= {})[row.path] = dart;
    warn(null, '$project ${row.path} has no row in $markdownPath.');
  }
  // The prose of a section that parity.md does not have stays.
  for (final MapEntry(:key, :value) in previous.prose.entries) {
    if (!proseSeen.contains(key)) result.prose[key] = value;
  }
  // Keep the order of the rows of the tables.
  final ordered = StatusFile(prose: result.prose, portOnly: result.portOnly);
  for (final row in model.rows) {
    final project = row.source.header;
    if (result.rows[project]?[row.path] case final text?) {
      (ordered.rows[project] ??= {})[row.path] = text;
    }
    if (result.dart[project]?[row.path] case final dart?) {
      (ordered.dart[project] ??= {})[row.path] = dart;
    }
  }
  final prose = {
    for (final key in [
      'intro',
      'summary',
      'summary.after',
      for (final area in parityAreas) ...[area.id, '${area.id}.after'],
      'port-only',
    ])
      key: ?ordered.prose[key],
  };
  ordered.prose
    ..clear()
    ..addAll(prose);
  if (summary != null) {
    _compareSummary(summary, renderParity(model, ordered).text, warn);
  }
  return ParityImport(ordered, findings);
}

bool _sameLines(List<String> a, List<String> b) =>
    a.length == b.length &&
    [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((same) => same);

/// The Summary prose [lines] with a placeholder for each count of rows.
List<String> _summaryProse(List<String> lines) {
  final labels = [
    for (final area in parityAreas) RegExp.escape(area.label),
  ].join('|');
  final pattern = RegExp(
    '(\\bThe\\s+($labels)\\s+area\\s+has\\s+)(\\d+)(\\s+`'
    '(${statusValues.map(RegExp.escape).join('|')})`)',
  );
  return lines
      .join('\n')
      .replaceAllMapped(
        pattern,
        (m) => '${m[1]}{{rows:${m[2]!.replaceAll('\n', ' ')}:${m[5]}}}${m[4]}',
      )
      .split('\n');
}

/// Warns about each cell of the Summary table that differs from [generated].
void _compareSummary(
  _Section section,
  String generated,
  void Function(int?, String) warn,
) {
  final table = section.table;
  if (table == null) return;
  final derived = {
    for (final derivedSection in _sections(generated))
      if (derivedSection.heading == summaryHeading)
        for (final row in derivedSection.table?.rows ?? const <Never>[])
          row.cells.first: row.cells,
  };
  for (final (:line, :cells) in table.rows) {
    final expected = derived[cells.first];
    if (expected == null) {
      warn(
        line,
        'the Summary area "${cells.first}" is not an area of '
        'tool 6.',
      );
      continue;
    }
    for (var i = 1; i < cells.length && i < expected.length; i++) {
      if (cells[i] != expected[i]) {
        warn(
          line,
          'Summary ${cells.first}: ${table.head[i]} is ${cells[i]}, '
          'tool 6 derives ${expected[i]}.',
        );
      }
    }
  }
}

void _importRow(
  UpstreamRow row,
  ({String cell, String dart, int line}) cells,
  ParityModel model,
  StatusFile previous,
  StatusFile result,
  void Function(int?, String) warn,
  ({String status, String dart})? base,
) {
  final (:cell, dart: dartCell, :line) = cells;
  final project = row.source.header;
  final scope = _Scope(model, row: row);
  final kept = previous.rows[project]?[row.path];
  final keptText = _expand(kept ?? defaultStatus, scope, []);
  String template;
  if (keptText == cell || (base != null && base.status == cell)) {
    template = kept ?? defaultStatus;
  } else {
    if (kept != null && (base == null || keptText != base.status)) {
      warn(
        line,
        '${row.path}: the text of $statusPath differs. The cell '
        'replaces it.',
      );
    }
    template = _recognizeRow(cell, row, (message) {
      warn(line, '${row.path}: $message');
    });
    final errors = <String>[];
    final derived = _expand(template, scope, errors);
    if (derived != cell) {
      warn(
        line,
        '${row.path}: the derived status differs from the cell: '
        '${_difference(cell, derived)}.',
      );
    }
  }
  if (template != defaultStatus) {
    (result.rows[project] ??= {})[row.path] = template;
  }

  final keptDart = previous.dart[project]?[row.path];
  if (keptDart != null && base != null && base.dart == dartCell) {
    (result.dart[project] ??= {})[row.path] = keptDart;
    return;
  }
  final derivedDart = row.targets.map((t) => '`$t`').join(', ');
  if (dartCell == derivedDart) return;
  final shown = [
    for (final match in RegExp('`([^`]+)`').allMatches(dartCell)) match[1]!,
  ];
  if (row.targets.isEmpty && shown.length == 1) {
    (result.dart[project] ??= {})[row.path] = shown.single;
  } else {
    warn(
      line,
      '${row.path}: the Dart target is "$dartCell", the headers '
      'give "$derivedDart".',
    );
  }
}

/// The status template of the cell [text] of [row]: placeholders in place
/// of its derived counts.
String _recognizeRow(String text, UpstreamRow row, void Function(String) warn) {
  var result = text;
  final fragment = RegExp(
    r'differences: (?:\d+ `[a-z-]+`(?:, | and ))*'
    r'\[differences\.md\]\(differences\.md#[A-Za-z0-9-]+\)'
    r'(?:,? \[differences\.md\]\(differences\.md#[A-Za-z0-9-]+\))*',
  );
  if (fragment.hasMatch(result)) {
    if (row.differences.isEmpty) {
      warn(
        'the cell names differences.md rows, but the Dart files of the '
        'row have no DIVERGES hunk. The text stays.',
      );
    } else {
      result = result.replaceFirst(fragment, '{{differences}}');
    }
  } else if (row.differences.isNotEmpty &&
      !result.contains('{{differences}}')) {
    final value = statusValueOf(result);
    final note = value == null
        ? null
        : RegExp(r'^ \((.*)\)$').firstMatch(result.substring(value.length));
    if (value != null && result == value) {
      result = '$value ({{differences}})';
    } else if (value != null && note != null) {
      result = '$value ({{differences}}; ${note[1]})';
    } else {
      result = '$result ({{differences}})';
    }
    warn(
      'the Dart files of the row have DIVERGES hunks, and the cell has no '
      'differences. Tool 6 adds them.',
    );
  }
  if (row.spec == null) return result;
  result = result.replaceFirstMapped(
    RegExp(r'(?<![\w{/])\d+/\d+ cases'),
    (_) => '{{passed}}/{{cases}} cases',
  );
  if (row.area.kind != AreaKind.specs) return result;
  result = result
      .replaceFirst(
        'cases pass on the VM, dart2js and dart2wasm',
        'cases pass on {{platforms}}',
      )
      .replaceFirst(
        RegExp('cases pass on the VM(?!, dart2js)'),
        'cases pass on {{platforms}}',
      );
  const reason = '(?:(?:blocked|diverges|n/a)(?:: [^`]+)?)';
  final item = RegExp('(\\d+) `($reason)`(?: \\([^)]*\\))?(, and |, | and )?');
  result = result.replaceAllMapped(
    RegExp(
      '(?<![\\w{/])\\d+ cases? skipped(: `($reason)`|, `($reason)`|: |)',
    ),
    (m) {
      final named = m[2] ?? m[3];
      final rest = m[1]!;
      if (named != null) return '{{skipped:$named|case}} skipped$rest';
      // A list of skip reasons: the sum of its reasons. One kind of reason
      // (blocked, n/a or diverges) gives the count of that kind.
      final kinds = <String>{};
      var at = m.end;
      while (rest == ': ') {
        final next = item.matchAsPrefix(result, at);
        if (next == null) break;
        kinds.add(next[2]!.split(':').first);
        at = next.end;
        if (next[3] == null) break;
      }
      final kind = kinds.length == 1 ? ':${kinds.single}' : '';
      return '{{skipped$kind|case}} skipped$rest';
    },
  );
  return result.replaceAllMapped(
    RegExp('(?<![\\w{/|])\\d+ `($reason)`'),
    (m) => '{{skipped:${m[1]}}} `${m[1]}`',
  );
}

/// The first place where [a] and [b] differ, with some text around it.
String _difference(String a, String b) {
  var start = 0;
  while (start < a.length && start < b.length && a[start] == b[start]) {
    start++;
  }
  var endA = a.length;
  var endB = b.length;
  while (endA > start && endB > start && a[endA - 1] == b[endB - 1]) {
    endA--;
    endB--;
  }
  String part(String text, int end) {
    final from = start < 20 ? 0 : start - 20;
    final to = end + 20 > text.length ? text.length : end + 20;
    return '${from > 0 ? '...' : ''}${text.substring(from, to)}'
        '${to < text.length ? '...' : ''}';
  }

  return '"${part(a, endA)}" becomes "${part(b, endB)}"';
}

void _importPortOnly(
  _Table table,
  ParityModel model,
  StatusFile previous,
  StatusFile result,
  void Function(int?, String) warn,
  List<List<String>>? base,
) {
  final scope = _Scope(model);
  String expand(String text) => _cell(_expand(text, scope, []));
  String normal(String text) => text.replaceAll(RegExp(r'\d+'), '#');
  bool same(List<String> a, List<String> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((s) => s);
  final unused = [...previous.portOnly];
  // The entry of each row of the output, and the entry of previous that it
  // came from.
  final output = <({PortOnlyEntry entry, PortOnlyEntry? from})>[];
  for (final (:line, :cells) in table.rows) {
    if (cells.length != 3) {
      warn(line, 'a port-only row has ${cells.length} cells, not 3.');
      continue;
    }
    final file = cells[0];
    PortOnlyEntry? kept;
    for (final entry in unused) {
      final expanded = expand(entry.file);
      if (expanded == _cell(file) || normal(expanded) == normal(_cell(file))) {
        kept = entry;
        break;
      }
    }
    unused.remove(kept);
    final escaped = [for (final cell in cells) _cell(cell)];
    final unchanged =
        base != null &&
        base.any((row) => same([for (final c in row) _cell(c)], escaped));
    if (unchanged && kept == null) {
      // The row of base is not in previous: status.yaml removed it.
      continue;
    }
    if (kept != null &&
        (unchanged || same([for (final c in kept.cells) expand(c)], escaped))) {
      output.add((entry: kept, from: kept));
      continue;
    }
    final keptCells = kept == null
        ? null
        : [for (final c in kept.cells) expand(c)];
    if (keptCells != null &&
        (base == null ||
            !base.any(
              (row) => same([for (final c in row) _cell(c)], keptCells),
            ))) {
      warn(
        line,
        'port-only row ${_short(file)}: the row of $statusPath '
        'differs. The cells replace it.',
      );
    }
    final template = PortOnlyEntry(
      file.replaceAllMapped(
        RegExp(r'`([^`]*\*[^`]*)` \(((?:\d+ \+ )?)(\d+) files\)'),
        (m) => '`${m[1]}` (${m[2]}{{files:${m[1]}}} files)',
      ),
      cells[1],
      cells[2],
    );
    final derived = expand(template.file);
    if (derived != _cell(file)) {
      warn(
        line,
        'port-only row $file: the derived file count differs: '
        '${_difference(file, derived)}.',
      );
    }
    output.add((entry: template, from: kept));
  }
  // A row of status.yaml that parity.md does not have stays after the row
  // that is before it in status.yaml.
  for (final entry in unused) {
    warn(
      table.line,
      '$statusPath keeps the port-only row ${_short(entry.file)}, which '
      'parity.md does not have.',
    );
    final index = previous.portOnly.indexOf(entry);
    var at = 0;
    for (var i = index - 1; i >= 0; i--) {
      final before = previous.portOnly[i];
      final position = output.indexWhere((row) => row.from == before);
      if (position >= 0) {
        at = position + 1;
        break;
      }
    }
    output.insert(at, (entry: entry, from: entry));
  }
  result.portOnly.addAll([for (final row in output) row.entry]);
}

/// The cells of the `parity.md` text [base] by key: the prose blocks, the
/// status and Dart target cells of each row, and the port-only rows.
({
  Map<String, List<String>> prose,
  Map<String, ({String status, String dart})> rows,
  List<List<String>> portOnly,
})
_baseCells(
  String base,
  ParityModel model,
  Map<String, ({ParityArea? area, String key})> headings,
) {
  final prose = <String, List<String>>{};
  final rows = <String, ({String status, String dart})>{};
  final portOnly = <List<String>>[];
  for (final section in _sections(base)) {
    final known = headings[section.heading];
    if (known == null) continue;
    prose[known.key] = section.before;
    if (known.key == 'summary') {
      prose['summary.after'] = section.after;
      continue;
    }
    if (known.area != null) prose['${known.key}.after'] = section.after;
    final table = section.table;
    if (table == null) continue;
    if (known.key == 'port-only') {
      portOnly.addAll([for (final row in table.rows) row.cells]);
      continue;
    }
    final project = model.sources[known.area!.project]!.header;
    final dartColumn = table.head.indexWhere(
      (name) => name == 'Dart target' || name == 'Dart test',
    );
    for (final (line: _, :cells) in table.rows) {
      final match = RegExp(r'^\[`([^`]+)`\]').firstMatch(cells.first);
      if (match == null) continue;
      rows['$project ${match[1]}'] = (
        status: cells.last,
        dart: dartColumn >= 0 && dartColumn < cells.length
            ? cells[dartColumn]
            : '',
      );
    }
  }
  return (prose: prose, rows: rows, portOnly: portOnly);
}

// ---------------------------------------------------------------------------
// The check.

/// The findings of `--check`: each line of [actual] that differs from
/// [expected], up to [limit] lines, and a summary.
List<Finding> compareText(
  String expected,
  String actual,
  String path, {
  int limit = 5,
}) {
  final want = expected.split('\n');
  final have = actual.split('\n');
  final findings = <Finding>[];
  var differing = 0;
  final length = want.length > have.length ? want.length : have.length;
  for (var i = 0; i < length; i++) {
    final a = i < want.length ? want[i] : null;
    final b = i < have.length ? have[i] : null;
    if (a == b) continue;
    differing++;
    if (differing > limit) continue;
    findings.add(
      Finding(
        path,
        i + 1,
        a == null
            ? 'the file has a line that tool 6 does not write.'
            : b == null
            ? 'the file ends before this line of tool 6: "${_short(a)}".'
            : 'the file differs from tool 6: ${_difference(b, a)}.',
      ),
    );
  }
  if (differing > 0) {
    findings.add(
      Finding(
        path,
        null,
        '$differing lines differ from the output of tool 6. Run '
        '"dart run melos run parity". Edit $statusPath, not $parityPath.',
      ),
    );
  }
  return findings;
}
