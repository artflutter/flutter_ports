// Original code, not ported from Chart.js: the header check, tool 2.

/// The header check of porting-flow.md section 4, tool 2.
///
/// For each Dart file under `lib/`, `test/` and `tool/` of the examined
/// packages (the command adds the harness package `chartjs_test_utils` when
/// it exists, [withHarnessPackage]):
/// - Line 1 is a `// Ported from` line or the port-only marker. More
///   `// Ported from` lines and backport lines can follow directly.
/// - The project, license and holder of a `// Ported from` line agree with
///   `tool/port_sources.yaml`. The holder is in the package `LICENSE`. The
///   `REUSE.toml` annotation of the file lists the holder and the license.
/// - The source path exists at the pin, and the file is at the Dart path that
///   `tool/port_sources.yaml` maps it to. Files under `test/port/` and
///   `tool/` are port-only. A port-only file is not at the Dart path of a
///   source that exists at a pin.
/// - Each `DIVERGES(chartjs)` marker names a row of `doc/differences.md`, and
///   each row has a marker.
/// - A header version older than the pinned version is stale: a warning.
library;

import 'dart:io';

import 'check_support.dart';
import 'dart_source.dart';
import 'headers.dart';
import 'mini_yaml.dart';
import 'reuse_toml.dart';

/// The path of the source list, relative to the home package.
const String portSourcesPath = 'tool/port_sources.yaml';

/// The path of the differences file, relative to the home package.
const String differencesPath = 'doc/differences.md';

/// The path of the version constant, relative to the home package.
const String upstreamPath = 'lib/src/upstream.dart';

/// The `differences.md` categories (porting-flow.md 4).
const List<String> differenceCategories = [
  'adapt',
  'platform',
  'theme',
  'js-semantics',
  'harness',
  'not-followed',
];

/// The directories of a package that the check examines.
const List<String> examinedDirectories = ['lib', 'test', 'tool'];

/// The directory name of the test harness package, next to the home package
/// (porting-flow.md 3).
const String harnessPackageName = 'chartjs_test_utils';

/// [packages], plus the harness package next to the first package when it
/// has a `pubspec.yaml` and is not in [packages] (porting-flow.md 4, tool 2).
///
/// Each package keeps its own `LICENSE` for the holder check (AGENTS.md
/// Licensing).
List<String> withHarnessPackage(List<String> packages) {
  final home = posixPath(packages.first);
  final slash = home.lastIndexOf('/');
  final harness = '${home.substring(0, slash + 1)}$harnessPackageName';
  if (slash < 0 ||
      packages.map(posixPath).contains(harness) ||
      !File('$harness/pubspec.yaml').existsSync()) {
    return packages;
  }
  return [...packages, harness];
}

/// The package-relative directories whose files are port-only.
const List<String> portOnlyDirectories = ['test/port/', 'tool/'];

/// The longest marker line (porting-flow.md 4).
const int markerLineLimit = 80;

/// The `language` values of `tool/port_sources.yaml`. Tool 3 examines the
/// files of the [jsLanguage] projects.
const List<String> sourceLanguages = [jsLanguage, 'c'];

/// The `language` of a JavaScript or TypeScript project.
const String jsLanguage = 'js';

final RegExp _markerCandidate = RegExp(r'^///?\s*DIVERGES\b');
final RegExp _blockMarkerCandidate = RegExp(r'^/\*+\s*DIVERGES\b');
final RegExp _marker = RegExp(r'^// DIVERGES\(chartjs\): (\S+), (\S.*)$');
final RegExp _chartJsVersion = RegExp(
  "^const String chartJsVersion = '([^']+)';",
  multiLine: true,
);

/// One source-to-Dart mapping of a project.
final class PortTarget {
  /// Maps [source] (a file, or a directory that ends with `/`) to [dart].
  const PortTarget(this.source, this.dart);

  /// The project-relative source path.
  final String source;

  /// The repository-relative Dart path.
  final String dart;

  /// Whether [source] is a directory.
  bool get isDirectory => source.endsWith('/');

  /// The Dart path of [path], or null if this target does not cover it.
  String? map(String path) {
    if (!isDirectory) return path == source ? dart : null;
    if (!path.startsWith(source)) return null;
    final rest = path.substring(source.length);
    final slash = rest.lastIndexOf('/');
    final directory = rest.substring(0, slash + 1);
    final name = rest.substring(slash + 1);
    final String dartName;
    if (name.endsWith('.tests.js')) {
      dartName = '${name.substring(0, name.length - 9)}_test.dart';
    } else if (name.endsWith('.d.ts')) {
      dartName = '${name.substring(0, name.length - 5)}.dart';
    } else if (name.contains('.')) {
      dartName = '${name.substring(0, name.lastIndexOf('.'))}.dart';
    } else {
      dartName = '$name.dart';
    }
    return '$dart$directory$dartName';
  }

  /// The source paths that this target maps to the Dart path [dartPath].
  ///
  /// For a directory, these are the names with the extensions `.js`, `.ts`
  /// and `.d.ts`, and `.tests.js` for a `_test.dart` file.
  List<String> sourcesOf(String dartPath) {
    if (!isDirectory) return dartPath == dart ? [source] : const [];
    if (!dartPath.startsWith(dart) || !dartPath.endsWith('.dart')) {
      return const [];
    }
    final rest = dartPath.substring(dart.length, dartPath.length - 5);
    return [
      for (final extension in const ['.js', '.ts', '.d.ts'])
        '$source$rest$extension',
      if (rest.endsWith('_test'))
        '$source${rest.substring(0, rest.length - 5)}.tests.js',
    ].where((candidate) => map(candidate) == dartPath).toList();
  }
}

/// One entry of `tool/port_sources.yaml`.
final class PortSource {
  /// An entry for the project [header].
  const PortSource({
    required this.header,
    required this.version,
    required this.url,
    required this.language,
    required this.spdx,
    required this.holder,
    required this.pinKind,
    required this.pinPath,
    required this.targets,
    required this.files,
    this.pinRef,
    this.pinCommit,
    this.fileIndex,
  });

  /// Reads the entry [map]. Throws a [FormatException].
  factory PortSource.fromYaml(Object? map) {
    if (map is! Map<String, Object?>) {
      throw const FormatException('each source is a mapping');
    }
    String required(Map<String, Object?> m, String key, String where) {
      final value = m[key];
      if (value is! String || value.isEmpty) {
        throw FormatException('$where: "$key" is missing');
      }
      return value;
    }

    String? optional(Map<String, Object?> m, String key, String where) {
      final value = m[key];
      if (value != null && value is! String) {
        throw FormatException('$where: "$key" is a string');
      }
      return value as String?;
    }

    final header = required(map, 'header', 'a source');
    final pin = map['pin'];
    if (pin is! Map<String, Object?>) {
      throw FormatException('$header: "pin" is missing');
    }
    final kind = required(pin, 'kind', '$header pin');
    if (kind != 'submodule' && kind != 'copy') {
      throw FormatException('$header: pin kind is "submodule" or "copy"');
    }
    final targets = map['targets'];
    if (targets is! List<Object?> || targets.isEmpty) {
      throw FormatException('$header: "targets" is missing');
    }
    final files = map['files'];
    if (files != null && files is! List<Object?>) {
      throw FormatException('$header: "files" is a list');
    }
    final language = required(map, 'language', header);
    if (!sourceLanguages.contains(language)) {
      final names = sourceLanguages.map((l) => '"$l"').join(' or ');
      throw FormatException('$header: language is $names');
    }
    return PortSource(
      header: header,
      version: required(map, 'version', header),
      url: required(map, 'url', header),
      language: language,
      spdx: required(map, 'spdx', header),
      holder: required(map, 'holder', header),
      pinKind: kind,
      pinPath: required(pin, 'path', '$header pin'),
      pinRef: optional(pin, 'ref', '$header pin'),
      pinCommit: kind == 'submodule'
          ? required(pin, 'commit', '$header pin')
          : null,
      targets: [
        for (final target in targets)
          if (target is Map<String, Object?>)
            PortTarget(
              required(target, 'source', '$header target'),
              required(target, 'dart', '$header target'),
            )
          else
            throw FormatException('$header: each target is a mapping'),
      ],
      files: [
        for (final file in (files as List<Object?>?) ?? const []) '$file',
      ],
      fileIndex: optional(map, 'file_index', header),
    );
  }

  /// The project name in headers.
  final String header;

  /// The header version.
  final String version;

  /// The project repository.
  final String url;

  /// The language of the source: an item of [sourceLanguages].
  final String language;

  /// Whether the source is JavaScript or TypeScript.
  bool get isJs => language == jsLanguage;

  /// The SPDX license identifier.
  final String spdx;

  /// The copyright holder.
  final String holder;

  /// `submodule` or `copy`.
  final String pinKind;

  /// The repository-relative directory of the reference copy.
  final String pinPath;

  /// The tag or release of the pin.
  final String? pinRef;

  /// The commit of a submodule pin.
  final String? pinCommit;

  /// The source-to-Dart mappings.
  final List<PortTarget> targets;

  /// Source paths that exist at the pin.
  final List<String> files;

  /// A Markdown file whose links name source paths that exist at the pin.
  final String? fileIndex;

  /// The Dart path of the source [path]: an exact target first, else the
  /// longest directory target. Null if no target covers [path].
  String? dartPathOf(String path) {
    for (final target in targets) {
      if (!target.isDirectory && target.source == path) return target.dart;
    }
    PortTarget? best;
    for (final target in targets) {
      if (target.isDirectory &&
          path.startsWith(target.source) &&
          (best == null || target.source.length > best.source.length)) {
        best = target;
      }
    }
    return best?.map(path);
  }
}

/// Reads the `sources` list of `tool/port_sources.yaml` from [text].
List<PortSource> parsePortSources(String text) {
  final document = parseYamlSubset(text);
  if (document is! Map<String, Object?> || document['sources'] is! List) {
    throw const FormatException('the file has no "sources" list');
  }
  final sources = [
    for (final entry in document['sources']! as List<Object?>)
      PortSource.fromYaml(entry),
  ];
  final names = <String>{};
  for (final source in sources) {
    if (!names.add(source.header)) {
      throw FormatException('${source.header} is listed twice');
    }
  }
  return sources;
}

/// One row of `doc/differences.md`.
final class DifferenceRow {
  /// The row [id] on [line].
  const DifferenceRow(this.id, this.line);

  /// The row ID.
  final String id;

  /// The 1-based line.
  final int line;
}

/// The rows of the tables in [text] whose first header cell is `ID`.
List<DifferenceRow> parseDifferences(String text) {
  final rows = <DifferenceRow>[];
  final lines = text.split('\n');
  var inTable = false;
  var isIdTable = false;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (!line.startsWith('|')) {
      inTable = false;
      continue;
    }
    final cells = line
        .substring(1, line.endsWith('|') ? line.length - 1 : null)
        .split('|')
        .map((cell) => cell.trim())
        .toList();
    if (!inTable) {
      inTable = true;
      isIdTable = cells.first.toLowerCase() == 'id';
      continue;
    }
    if (!isIdTable || cells.every((c) => RegExp(r'^:?-+:?$').hasMatch(c))) {
      continue;
    }
    final anchor = RegExp(
      r'''<a\s+(?:id|name)=["']([^"']+)["']''',
    ).firstMatch(cells.first);
    final id =
        anchor?.group(1) ??
        cells.first
            .replaceAll(RegExp('<[^>]*>'), '')
            .replaceAll('`', '')
            .trim();
    rows.add(DifferenceRow(id, i + 1));
  }
  return rows;
}

/// Whether [id] is a valid `differences.md` row ID.
bool isDifferenceId(String id) =>
    RegExp(r'^[A-Za-z0-9-]+$').hasMatch(id) &&
    differenceCategories.any(
      (category) =>
          id.startsWith('$category-') && id.length > category.length + 1,
    );

/// The parts of a `v`-prefixed or plain dotted version, or null.
List<int>? parseVersion(String version) {
  final match = RegExp(r'^v?(\d+(?:\.\d+)*)$').firstMatch(version);
  return match?.group(1)!.split('.').map(int.parse).toList();
}

/// Negative if [a] is older than [b], 0 if equal, positive if newer.
int compareVersions(List<int> a, List<int> b) {
  for (var i = 0; i < a.length || i < b.length; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x - y;
  }
  return 0;
}

/// The gitlink of [path] in the index of the repository [repository], or
/// null if git or the gitlink is not available.
String? gitlinkOf(String repository, String path) {
  try {
    final result = Process.runSync('git', [
      '-C',
      repository,
      'ls-files',
      '--stage',
      '--',
      path,
    ]);
    if (result.exitCode != 0) return null;
    final match = RegExp(
      '^160000 ([0-9a-f]{40}) ',
      multiLine: true,
    ).firstMatch('${result.stdout}');
    return match?.group(1);
  } on ProcessException {
    return null;
  }
}

/// The inputs of the header check.
final class HeaderCheckInput {
  /// The check of [packages] in the repository [repository]. [home] is the
  /// package with `tool/port_sources.yaml`, `doc/differences.md` and
  /// `lib/src/upstream.dart`. All are absolute paths with `/` separators.
  const HeaderCheckInput({
    required this.repository,
    required this.home,
    required this.packages,
    this.gitlink = gitlinkOf,
  });

  /// The repository root, with `REUSE.toml`.
  final String repository;

  /// The `flutter_chartjs` package.
  final String home;

  /// The packages to examine.
  final List<String> packages;

  /// Reads a gitlink; replaceable for tests.
  final String? Function(String repository, String path) gitlink;
}

/// The source paths that exist at the pin of one project.
final class _PinIndex {
  _PinIndex(this.directory, {required this.checkedOut, required this.listed});

  /// The absolute directory of the reference copy.
  final String directory;

  /// Whether the reference copy is on disk.
  final bool checkedOut;

  /// The `files` and `file_index` paths, for a pin that is not on disk.
  final Set<String> listed;

  bool has(String path) => checkedOut
      ? File('$directory/$path').existsSync()
      : listed.contains(path);
}

const String _malformedMarker =
    'a malformed DIVERGES marker: write the line comment '
    '"DIVERGES(chartjs): <row id>, <reason>" (porting-flow.md 4).';

/// One `DIVERGES(chartjs)` marker.
final class _Marker {
  const _Marker(this.path, this.line, this.id);

  final String path;
  final int line;
  final String id;
}

/// Runs the header check.
({List<Finding> findings, int files}) checkPortHeaders(
  HeaderCheckInput input,
) {
  final findings = <Finding>[];
  final repo = input.repository;
  String rel(String path) => relativePath(repo, path);

  final sourcesFile = '${input.home}/$portSourcesPath';
  final List<PortSource> sources;
  try {
    sources = parsePortSources(File(sourcesFile).readAsStringSync());
  } on FileSystemException catch (e) {
    return (findings: [Finding(rel(sourcesFile), null, e.message)], files: 0);
  } on FormatException catch (e) {
    return (findings: [Finding(rel(sourcesFile), null, e.message)], files: 0);
  }

  final upstreamFile = '${input.home}/$upstreamPath';
  final upstreamText = File(upstreamFile).existsSync()
      ? File(upstreamFile).readAsStringSync()
      : '';
  final pinnedVersion = _chartJsVersion.firstMatch(upstreamText)?.group(1);
  if (pinnedVersion == null) {
    findings.add(Finding(rel(upstreamFile), null, 'no chartJsVersion found.'));
  }

  var annotations = const <ReuseAnnotation>[];
  try {
    annotations = parseReuseToml(File('$repo/REUSE.toml').readAsStringSync());
  } on FileSystemException catch (e) {
    findings.add(Finding('REUSE.toml', null, e.message));
  } on FormatException catch (e) {
    findings.add(Finding('REUSE.toml', null, e.message));
  }

  final pins = _validateSources(
    sources,
    input,
    pinnedVersion,
    rel(sourcesFile),
    findings,
  );

  final differencesFile = '${input.home}/$differencesPath';
  final rows = File(differencesFile).existsSync()
      ? parseDifferences(File(differencesFile).readAsStringSync())
      : const <DifferenceRow>[];
  for (final row in rows) {
    if (!isDifferenceId(row.id)) {
      findings.add(
        Finding(
          rel(differencesFile),
          row.line,
          'row ID "${row.id}" does not start with a category '
          '(${differenceCategories.join(', ')}) and a hyphen.',
        ),
      );
    }
  }

  final context = _FileContext(
    sources: {for (final source in sources) source.header: source},
    pins: pins,
    annotations: annotations,
    pinnedVersion: pinnedVersion,
    findings: findings,
  );
  var files = 0;
  for (final package in input.packages) {
    final licenseFile = '$package/LICENSE';
    final license = File(licenseFile).existsSync()
        ? File(licenseFile).readAsStringSync()
        : null;
    for (final directory in examinedDirectories) {
      for (final file in dartFilesUnder('$package/$directory')) {
        files++;
        context.check(
          text: File(file).readAsStringSync(),
          path: rel(file),
          packagePath: relativePath(package, file),
          licensePath: rel(licenseFile),
          license: license,
        );
      }
    }
  }

  final rowIds = {for (final row in rows) row.id};
  final markerIds = {for (final marker in context.markers) marker.id};
  for (final marker in context.markers) {
    if (!rowIds.contains(marker.id)) {
      findings.add(
        Finding(
          marker.path,
          marker.line,
          'the DIVERGES(chartjs) marker names "${marker.id}", which is not a '
          'row of ${rel(differencesFile)}.',
        ),
      );
    }
  }
  for (final row in rows) {
    if (!markerIds.contains(row.id)) {
      findings.add(
        Finding(
          rel(differencesFile),
          row.line,
          'row ${row.id} has no DIVERGES(chartjs) marker in the code.',
        ),
      );
    }
  }
  return (findings: findings, files: files);
}

/// Checks the entries of `tool/port_sources.yaml` and returns the pin index
/// of each project.
Map<String, _PinIndex> _validateSources(
  List<PortSource> sources,
  HeaderCheckInput input,
  String? pinnedVersion,
  String sourcesPath,
  List<Finding> findings,
) {
  void report(String message) =>
      findings.add(Finding(sourcesPath, null, message));

  final chartJs = sources.where((s) => s.header == chartJsProject).firstOrNull;
  if (chartJs == null) {
    report('there is no $chartJsProject entry.');
  } else if (pinnedVersion != null && chartJs.version != 'v$pinnedVersion') {
    report(
      '$chartJsProject version is ${chartJs.version}, but chartJsVersion is '
      '$pinnedVersion: write v$pinnedVersion.',
    );
  }

  final pins = <String, _PinIndex>{};
  for (final source in sources) {
    final name = source.header;
    if (parseVersion(source.version) == null) {
      report('$name version "${source.version}" is not a dotted version.');
    }
    final directory = '${input.repository}/${source.pinPath}';
    final dir = Directory(directory);
    final checkedOut = dir.existsSync() && dir.listSync().isNotEmpty;
    if (source.pinKind == 'submodule') {
      final gitlink = input.gitlink(input.repository, source.pinPath);
      if (gitlink != null && gitlink != source.pinCommit) {
        report(
          '$name pin commit is ${source.pinCommit}, but the gitlink of '
          '${source.pinPath} is $gitlink.',
        );
      }
      if (source.pinRef != null && source.pinRef != source.version) {
        report(
          '$name pin ref ${source.pinRef} differs from version '
          '${source.version}.',
        );
      }
    } else if (!checkedOut) {
      report('$name: the copy ${source.pinPath} is missing or empty.');
    }

    final listed = {...source.files};
    final index = source.fileIndex;
    if (index != null) {
      final file = File('${input.repository}/$index');
      if (file.existsSync()) {
        final link = RegExp(
          '${RegExp.escape('${source.url}/blob/${source.version}/')}'
          r'([^)\s#>]+)',
        );
        listed.addAll([
          for (final match in link.allMatches(file.readAsStringSync()))
            match.group(1)!,
        ]);
      } else {
        report('$name file_index $index does not exist.');
      }
    }
    if (checkedOut) {
      for (final path in source.files) {
        if (!File('$directory/$path').existsSync()) {
          report('$name file $path does not exist in ${source.pinPath}.');
        }
      }
    }
    pins[name] = _PinIndex(directory, checkedOut: checkedOut, listed: listed);
  }
  return pins;
}

/// The per-file part of the header check.
final class _FileContext {
  _FileContext({
    required this.sources,
    required this.pins,
    required this.annotations,
    required this.pinnedVersion,
    required this.findings,
  });

  final Map<String, PortSource> sources;
  final Map<String, _PinIndex> pins;
  final List<ReuseAnnotation> annotations;
  final String? pinnedVersion;
  final List<Finding> findings;
  final List<_Marker> markers = [];

  void check({
    required String text,
    required String path,
    required String packagePath,
    required String licensePath,
    required String? license,
  }) {
    void report(int? line, String message) =>
        findings.add(Finding(path, line, message));

    final source = DartSource(text);
    final header = Header.parse(source.lines);
    for (final line in header.malformed) {
      report(
        line,
        'the header line does not match the grammar of porting-flow.md 4, '
        'tool 2.',
      );
    }
    switch (header.kind) {
      case HeaderKind.missing:
        report(
          1,
          'line 1 is neither a "// Ported from" header (AGENTS.md rule 2) nor '
          'the port-only marker "// Original code, not ported from Chart.js: '
          '<reason>.".',
        );
      case HeaderKind.portOnly:
        final mapped = _sourceAt(path);
        if (mapped != null) {
          report(
            1,
            'the file is at the Dart path of ${mapped.project} '
            '${mapped.source}: start it with its "// Ported from" header, not '
            'the port-only marker.',
          );
        }
      case HeaderKind.ported:
        if (portOnlyDirectories.any(packagePath.startsWith)) {
          report(
            1,
            'files under ${portOnlyDirectories.join(' and ')} are port-only: '
            'start the file with the port-only marker.',
          );
        }
        for (final portedFrom in header.portedFrom) {
          _checkPortedFrom(portedFrom, path, licensePath, license, report);
        }
        if (header.backports.isNotEmpty &&
            !header.portedFrom.any((p) => p.project == chartJsProject)) {
          report(
            header.backports.first.line,
            'a backport line needs a "// Ported from $chartJsProject" line.',
          );
        }
    }

    for (final comment in source.comments) {
      if (!comment.isLineComment) {
        if (_blockMarkerCandidate.hasMatch(comment.text)) {
          report(comment.line, _malformedMarker);
        }
        continue;
      }
      final text = comment.text;
      if (comment.line > header.lastLine &&
          !header.malformed.contains(comment.line) &&
          (text.startsWith(portedFromPrefix) ||
              text.startsWith(backportPrefix))) {
        report(
          comment.line,
          'a header line outside the header block: header lines come '
          'directly after line 1.',
        );
      }
      if (!_markerCandidate.hasMatch(text)) continue;
      final match = _marker.firstMatch(text);
      if (match == null) {
        report(comment.line, _malformedMarker);
        continue;
      }
      final id = match.group(1)!;
      if (!isDifferenceId(id)) {
        report(
          comment.line,
          'the DIVERGES(chartjs) row ID "$id" does not start with a '
          'category (${differenceCategories.join(', ')}) and a hyphen.',
        );
      }
      if (source.lines[comment.line - 1].length > markerLineLimit) {
        report(
          comment.line,
          'the DIVERGES(chartjs) marker line is longer than '
          '$markerLineLimit columns.',
        );
      }
      markers.add(_Marker(path, comment.line, id));
    }
  }

  /// The project and source path of the first source that exists at its pin
  /// and has the Dart path [path], or null.
  ({String project, String source})? _sourceAt(String path) {
    for (final source in sources.values) {
      final pin = pins[source.header]!;
      for (final target in source.targets) {
        for (final candidate in target.sourcesOf(path)) {
          if (pin.has(candidate)) {
            return (project: source.header, source: candidate);
          }
        }
      }
    }
    return null;
  }

  void _checkPortedFrom(
    PortedFrom portedFrom,
    String path,
    String licensePath,
    String? license,
    void Function(int? line, String message) report,
  ) {
    final line = portedFrom.line;
    final source = sources[portedFrom.project];
    if (source == null) {
      report(line, '"${portedFrom.project}" is not in $portSourcesPath.');
      return;
    }
    if (portedFrom.license != source.spdx) {
      report(
        line,
        'the license is ${portedFrom.license}, but $portSourcesPath names '
        '${source.spdx}.',
      );
    }
    if (portedFrom.holder != source.holder) {
      report(
        line,
        'the holder is "${portedFrom.holder}", but $portSourcesPath names '
        '"${source.holder}".',
      );
    }
    if (license == null) {
      report(line, '$licensePath does not exist.');
    } else if (!license.contains(source.holder)) {
      report(line, '$licensePath does not name "${source.holder}".');
    }
    final annotation = annotationFor(annotations, path);
    if (annotation == null) {
      report(line, 'no REUSE.toml annotation matches the file.');
    } else {
      if (!annotation.copyrights.any((c) => c.contains(source.holder))) {
        report(
          line,
          'the last REUSE.toml annotation that matches the file (line '
          '${annotation.line}) does not list "${source.holder}".',
        );
      }
      if (!annotation.licenseIds.contains(source.spdx)) {
        report(
          line,
          'the last REUSE.toml annotation that matches the file (line '
          '${annotation.line}) does not list ${source.spdx}.',
        );
      }
    }

    _checkVersion(portedFrom, source, path, report);

    if (normalizeRelative(portedFrom.path) != portedFrom.path) {
      report(line, 'the source path ${portedFrom.path} is not normalized.');
    }
    final pin = pins[source.header]!;
    if (!pin.has(portedFrom.path)) {
      report(
        line,
        pin.checkedOut
            ? '${portedFrom.path} does not exist in ${source.pinPath}.'
            : '${portedFrom.path} is not in the files of $portSourcesPath or '
                  'its file_index, and ${source.pinPath} is not checked out '
                  '(dart run melos run upstream).',
      );
    }
    final dart = source.dartPathOf(portedFrom.path);
    if (dart == null) {
      report(line, 'no target of $portSourcesPath maps ${portedFrom.path}.');
    } else if (dart != path) {
      report(
        line,
        'the Dart path of ${portedFrom.path} is $dart (porting-flow.md 2.5), '
        'not this file.',
      );
    }
  }

  void _checkVersion(
    PortedFrom portedFrom,
    PortSource source,
    String path,
    void Function(int? line, String message) report,
  ) {
    final line = portedFrom.line;
    final isChartJs = source.header == chartJsProject;
    final expected = isChartJs && pinnedVersion != null
        ? 'v$pinnedVersion'
        : source.version;
    final actual = parseVersion(portedFrom.version);
    final wanted = parseVersion(expected);
    if (actual == null || wanted == null) return;
    final order = compareVersions(actual, wanted);
    if (order < 0) {
      findings.add(
        Finding.warning(
          path,
          line,
          'stale header: ${source.header} ${portedFrom.version} is older than '
          '$expected${isChartJs ? ' (chartJsVersion)' : ''}. Restamp it '
          '(upstream-tracking.md 4.8).',
        ),
      );
    } else if (order > 0) {
      report(
        line,
        '${source.header} ${portedFrom.version} is newer than the pin '
        '$expected.',
      );
    } else if (portedFrom.version != expected) {
      report(line, 'write the version as $expected.');
    }
  }
}
