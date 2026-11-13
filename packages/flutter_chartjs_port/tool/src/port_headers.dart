// Original code, not ported from Chart.js: the header check, tool 2.

/// The header check of porting-flow.md section 4, tool 2.
///
/// The home package is the first package of the command. It holds
/// `tool/port_sources.yaml`, `doc/differences.md` and
/// `lib/src/upstream.dart`. The primary project of the home is the first
/// entry of `tool/port_sources.yaml` whose `version_source` is
/// `<constant> in <home>/lib/src/upstream.dart`: Chart.js for
/// `flutter_chartjs_port`, chartjs-plugin-zoom for the add-on
/// `flutter_chartjs_plugin_zoom_port`. The optional top-level key `marker`
/// of the file gives the tag of the `DIVERGES(<tag>)` markers
/// ([defaultMarker] when the key is absent).
///
/// For each Dart file under `lib/`, `test/` and `tool/` of the examined
/// packages (the given packages, and each package that a `dart` target of
/// the home names, [targetPackages]):
/// - Line 1 is a `// Ported from` line or the port-only marker of the
///   primary project. More `// Ported from` lines and backport lines can
///   follow directly. A backport line names the repository of the primary
///   project.
/// - The project, license and holder of a `// Ported from` line agree with
///   `tool/port_sources.yaml`. The holder is in the package `LICENSE`. The
///   `REUSE.toml` annotation of the file lists the holder and the license.
/// - The source path exists at the pin, and the file is at the Dart path that
///   `tool/port_sources.yaml` maps it to. Files under `test/port/` and
///   `tool/` are port-only. A port-only file is not at the Dart path of a
///   source that exists at a pin. A checked-out submodule must be at the pin
///   commit, because the check reads the source paths from its files.
/// - Each `DIVERGES(<tag>)` marker names a row of `doc/differences.md`, and
///   each row has a marker.
/// - A header version older than the pinned version is stale: a warning.
///
/// A version is a dotted release. Under a commit pin (upstream-tracking.md
/// 2.4), `+<sha8>` follows the release, for example `v4.5.1+7169e651`. A
/// commit pin is newer than its release. Thus a `v4.5.1` header is stale
/// under the pin `v4.5.1+7169e651`. The check cannot put two commits of one
/// release in order without the upstream history. Thus a header with another
/// commit of the pinned release is an error.
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

/// The tag of the `DIVERGES(<tag>)` markers when `tool/port_sources.yaml` has
/// no top-level key `marker`.
const String defaultMarker = 'chartjs';

/// [packages], plus the harness package next to the first package when it
/// has a `pubspec.yaml` and is not in [packages] (porting-flow.md 4, tools 1
/// and 3).
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
final RegExp _markerTag = RegExp(r'^[a-z][a-z0-9-]*$');
final RegExp _packageName = RegExp(r'^[a-z_][a-z0-9_]*$');

/// The marker grammar of porting-flow.md 4 with the tag [tag].
RegExp _markerPattern(String tag) =>
    RegExp('^// DIVERGES\\(${RegExp.escape(tag)}\\): (\\S+), (\\S.*)\$');

/// The line of the version [constant] in `lib/src/upstream.dart`.
RegExp _versionConstantPattern(String constant) => RegExp(
  "^const String ${RegExp.escape(constant)} = '([^']+)';",
  multiLine: true,
);

/// One source-to-Dart mapping of a project.
final class const PortTarget(
  /// The project-relative source path.
  final String source,

  /// The repository-relative Dart path.
  final String dart,
) {
  /// Maps [source] (a file, or a directory that ends with `/`) to [dart].
  this;

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
    } else if (name.endsWith('.spec.js')) {
      dartName = '${name.substring(0, name.length - 8)}_test.dart';
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
  /// For a directory, these are the names with the extensions `.js`, `.ts`,
  /// `.d.ts` and `.json` (a hand port of a data fixture, Chart.js ADR 0115),
  /// and `.tests.js` and `.spec.js` for a `_test.dart` file.
  List<String> sourcesOf(String dartPath) {
    if (!isDirectory) return dartPath == dart ? [source] : const [];
    if (!dartPath.startsWith(dart) || !dartPath.endsWith('.dart')) {
      return const [];
    }
    final rest = dartPath.substring(dart.length, dartPath.length - 5);
    return [
      for (final extension in const ['.js', '.ts', '.d.ts', '.json'])
        '$source$rest$extension',
      if (rest.endsWith('_test')) ...[
        '$source${rest.substring(0, rest.length - 5)}.tests.js',
        '$source${rest.substring(0, rest.length - 5)}.spec.js',
      ],
    ].where((candidate) => map(candidate) == dartPath).toList();
  }
}

/// One entry of `tool/port_sources.yaml`.
final class const PortSource({
  /// The project name in headers.
  required final String header,

  /// The header version.
  required final String version,

  /// The project repository.
  required final String url,

  /// The language of the source: an item of [sourceLanguages].
  required final String language,

  /// The SPDX license identifier.
  required final String spdx,

  /// The copyright holder.
  required final String holder,

  /// `submodule` or `copy`.
  required final String pinKind,

  /// The repository-relative directory of the reference copy.
  required final String pinPath,

  /// The source-to-Dart mappings.
  required final List<PortTarget> targets,

  /// Source paths that exist at the pin.
  required final List<String> files,

  /// Where [version] comes from. For the primary project of a package, this
  /// is `<constant> in <package>/lib/src/upstream.dart`.
  final String? versionSource,

  /// The tag or release of the pin. For a commit pin, the full pin commit.
  final String? pinRef,

  /// The commit of a submodule pin.
  final String? pinCommit,

  /// A Markdown file whose links name source paths that exist at the pin.
  final String? fileIndex,
}) {
  /// An entry for the project [header].
  this;

  /// Reads the entry [map]. Throws a [FormatException].
  factory fromYaml(Object? map) {
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
      versionSource: optional(map, 'version_source', header),
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

  /// The constant of `<package>/lib/src/upstream.dart` that [versionSource]
  /// names, or null. [package] is relative to the repository.
  String? versionConstantIn(String package) {
    final source = versionSource;
    if (source == null) return null;
    final suffix = ' in $package/$upstreamPath';
    if (!source.endsWith(suffix)) return null;
    final constant = source.substring(0, source.length - suffix.length);
    return RegExp(r'^[A-Za-z_]\w*$').hasMatch(constant) ? constant : null;
  }

  /// The `<owner>/<repo>` of [url], for example `chartjs/Chart.js`: the
  /// repository that a backport line names. Null when the path of [url] has
  /// fewer than two segments.
  String? get repository {
    final segments = [
      for (final segment in Uri.tryParse(url)?.pathSegments ?? const <String>[])
        if (segment.isNotEmpty) segment,
    ];
    return segments.length < 2 ? null : '${segments[0]}/${segments[1]}';
  }

  /// Whether the source is JavaScript or TypeScript.
  bool get isJs => language == jsLanguage;

  /// Whether [version] is a commit pin, `<release>+<sha8>`
  /// (upstream-tracking.md 2.4).
  bool get isCommitPin => parsePortVersion(version)?.commit != null;

  /// The git name of the pinned tree in the links of the project: the full
  /// pin commit for a commit pin, else [version]. A git host has no tree
  /// with the name `<release>+<sha8>`.
  String get treeRef => isCommitPin ? pinCommit ?? version : version;

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

/// The contents of `tool/port_sources.yaml`.
final class const PortSourcesFile({
  /// The entries of the `sources` list.
  required final List<PortSource> sources,

  /// The tag of the `DIVERGES(<tag>)` markers: the top-level key `marker`,
  /// else [defaultMarker].
  final String marker = defaultMarker,

  /// The host package of an add-on port (ADR 0009): the top-level key
  /// `host`, for example `flutter_chartjs_port`. Null for a host port.
  final String? host,
}) {
  /// The [sources], the [marker] tag and the [host] package.
  this;
}

/// The top-level keys of `tool/port_sources.yaml`.
const List<String> portSourcesKeys = ['sources', 'marker', 'host'];

/// Reads `tool/port_sources.yaml` from [text]: the `sources` list and the
/// optional top-level keys `marker` and `host`. Throws a [FormatException].
PortSourcesFile parsePortSourcesFile(String text) {
  final document = parseYamlSubset(text);
  if (document is! Map<String, Object?> || document['sources'] is! List) {
    throw const FormatException('the file has no "sources" list');
  }
  for (final key in document.keys) {
    if (!portSourcesKeys.contains(key)) {
      throw FormatException(
        'the top-level key "$key" is not one of ${portSourcesKeys.join(', ')}',
      );
    }
  }
  final marker = document['marker'] ?? defaultMarker;
  if (marker is! String || !_markerTag.hasMatch(marker)) {
    throw const FormatException(
      '"marker" is a tag of lowercase letters, digits and hyphens',
    );
  }
  final host = document['host'];
  if (host != null && (host is! String || !_packageName.hasMatch(host))) {
    throw const FormatException('"host" is the name of a package');
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
  return PortSourcesFile(
    sources: sources,
    marker: marker,
    host: host as String?,
  );
}

/// Reads the `sources` list of `tool/port_sources.yaml` from [text]
/// ([parsePortSourcesFile]).
List<PortSource> parsePortSources(String text) =>
    parsePortSourcesFile(text).sources;

/// The packages that the `dart` targets of [sources] name, in the order of
/// the targets, as absolute paths with `/` separators. The package of a
/// target is the closest directory under [repository] with a `pubspec.yaml`
/// at or above its `dart` path. A target outside a package names none.
List<String> targetPackages(String repository, List<PortSource> sources) {
  final packages = <String>[];
  for (final source in sources) {
    for (final target in source.targets) {
      var path = normalizeRelative(target.dart);
      while (path != null && path.isNotEmpty) {
        if (File('$repository/$path/pubspec.yaml').existsSync()) {
          final package = '$repository/$path';
          if (!packages.contains(package)) packages.add(package);
          break;
        }
        final slash = path.lastIndexOf('/');
        path = slash < 0 ? null : path.substring(0, slash);
      }
    }
  }
  return packages;
}

/// One row of `doc/differences.md`.
final class const DifferenceRow(
  /// The row ID.
  final String id,

  /// The 1-based line.
  final int line,
) {
  /// The row [id] on [line].
  this;
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
    final anchor = RegExp(r'''<a\s+(?:id|name)=["']([^"']+)["']''')
        .firstMatch(cells.first);
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

/// A header or pin version: a dotted release, and the commit of a commit pin
/// (upstream-tracking.md 2.4).
final class const PortVersion(
  /// The parts of the dotted release, for example `[4, 5, 1]`.
  final List<int> release, [

  /// The abbreviated commit of a commit pin (8 lowercase hex digits), or
  /// null for a release.
  final String? commit,
]) {
  /// The [release] parts, with the 8 hex digits [commit] of a commit pin.
  this;
}

final RegExp _portVersion = RegExp(r'^v?(\d+(?:\.\d+)*)(?:\+([0-9a-f]{8}))?$');

/// The parts of a `v`-prefixed or plain dotted version with an optional
/// `+<sha8>`, for example `v4.5.1+7169e651`, or null.
PortVersion? parsePortVersion(String version) {
  final match = _portVersion.firstMatch(version);
  if (match == null) return null;
  return PortVersion(
    match.group(1)!.split('.').map(int.parse).toList(),
    match.group(2),
  );
}

/// Negative if [a] is older than [b], 0 if equal, positive if newer. Null if
/// [a] and [b] are other commits of the same release: their order is in the
/// upstream history only.
///
/// A commit pin is newer than its release: the commit comes after the tag.
int? comparePortVersions(PortVersion a, PortVersion b) {
  final order = compareVersions(a.release, b.release);
  if (order != 0) return order;
  if (a.commit == b.commit) return 0;
  if (a.commit == null) return -1;
  if (b.commit == null) return 1;
  return null;
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

/// The commit that the submodule checkout [directory] has checked out, or
/// null if [directory] has no `.git` entry or git is not available.
///
/// Without the `.git` test, git reads the repository of a parent directory.
String? checkoutHeadOf(String directory) {
  final git = '$directory/.git';
  if (FileSystemEntity.typeSync(git) == FileSystemEntityType.notFound) {
    return null;
  }
  try {
    final result = Process.runSync('git', [
      '-C',
      directory,
      'rev-parse',
      'HEAD',
    ]);
    if (result.exitCode != 0) return null;
    final head = '${result.stdout}'.trim();
    return RegExp(r'^[0-9a-f]{40}$').hasMatch(head) ? head : null;
  } on ProcessException {
    return null;
  }
}

/// The inputs of the header check.
final class const HeaderCheckInput({
  /// The repository root, with `REUSE.toml`.
  required final String repository,

  /// The home package, for example `flutter_chartjs_port`.
  required final String home,

  /// The packages to examine. The check also examines each package that a
  /// `dart` target of the home names ([targetPackages]).
  required final List<String> packages,

  /// Reads a gitlink; replaceable for tests.
  final String? Function(String repository, String path) gitlink = gitlinkOf,

  /// Reads the checked-out commit of a submodule directory; replaceable for
  /// tests.
  final String? Function(String directory) checkoutHead = checkoutHeadOf,
}) {
  /// The check of [packages] in the repository [repository]. [home] is the
  /// package with `tool/port_sources.yaml`, `doc/differences.md` and
  /// `lib/src/upstream.dart`. All are absolute paths with `/` separators.
  this;
}

/// The source paths that exist at the pin of one project.
final class _PinIndex(
  /// The absolute directory of the reference copy.
  final String directory, {

  /// Whether the reference copy is on disk.
  required final bool checkedOut,

  /// The `files` and `file_index` paths, for a pin that is not on disk.
  required final Set<String> listed,
}) {
  bool has(String path) => checkedOut
      ? File('$directory/$path').existsSync()
      : listed.contains(path);
}

/// The message of a malformed marker with the tag [tag].
String _malformedMarker(String tag) =>
    'a malformed DIVERGES marker: write the line comment '
    '"DIVERGES($tag): <row id>, <reason>" (porting-flow.md 4).';

/// One `DIVERGES(<tag>)` marker.
final class const _Marker(final String path, final int line, final String id);

/// The version constant of `lib/src/upstream.dart` that a project of
/// `tool/port_sources.yaml` follows, and its value (null when the file has
/// no such constant).
typedef _VersionPin = ({String constant, String? pinned});

/// Runs the header check.
({List<Finding> findings, int files}) checkPortHeaders(HeaderCheckInput input) {
  final findings = <Finding>[];
  final repo = input.repository;
  String rel(String path) => relativePath(repo, path);

  final sourcesFile = '${input.home}/$portSourcesPath';
  final PortSourcesFile sourcesList;
  try {
    sourcesList = parsePortSourcesFile(File(sourcesFile).readAsStringSync());
  } on FileSystemException catch (e) {
    return (findings: [Finding(rel(sourcesFile), null, e.message)], files: 0);
  } on FormatException catch (e) {
    return (findings: [Finding(rel(sourcesFile), null, e.message)], files: 0);
  }
  final sources = sourcesList.sources;

  final upstreamFile = '${input.home}/$upstreamPath';
  final upstreamText = File(upstreamFile).existsSync()
      ? File(upstreamFile).readAsStringSync()
      : '';
  final versions = <String, _VersionPin>{};
  for (final source in sources) {
    final constant = source.versionConstantIn(rel(input.home));
    if (constant == null) continue;
    final pinned = _versionConstantPattern(constant)
        .firstMatch(upstreamText)
        ?.group(1);
    if (pinned == null) {
      findings.add(Finding(rel(upstreamFile), null, 'no $constant found.'));
    }
    versions[source.header] = (constant: constant, pinned: pinned);
  }
  final primary = sources
      .where((source) => versions.containsKey(source.header))
      .firstOrNull;

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
    versions,
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

  final tag = sourcesList.marker;
  final context = _FileContext(
    sources: {for (final source in sources) source.header: source},
    pins: pins,
    annotations: annotations,
    versions: versions,
    primary: primary,
    markerTag: tag,
    findings: findings,
  );
  final packages = <String>[];
  for (final package in [...input.packages, ...targetPackages(repo, sources)]) {
    if (!packages.contains(package)) packages.add(package);
  }
  var files = 0;
  for (final package in packages) {
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
          'the DIVERGES($tag) marker names "${marker.id}", which is not a '
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
          'row ${row.id} has no DIVERGES($tag) marker in the code.',
        ),
      );
    }
  }
  return (findings: findings, files: files);
}

/// Checks the entries of `tool/port_sources.yaml` and returns the pin index
/// of each project. [versions] has the version constants of the projects of
/// `lib/src/upstream.dart`.
Map<String, _PinIndex> _validateSources(
  List<PortSource> sources,
  HeaderCheckInput input,
  Map<String, _VersionPin> versions,
  String sourcesPath,
  List<Finding> findings,
) {
  void report(String message) =>
      findings.add(Finding(sourcesPath, null, message));

  if (versions.isEmpty) {
    final home = relativePath(input.repository, input.home);
    report(
      'no entry has the version_source "<constant> in $home/$upstreamPath": '
      'the entry of the project that the package ports names its version '
      'constant there.',
    );
  }
  for (final source in sources) {
    final pin = versions[source.header];
    final pinned = pin?.pinned;
    if (pin != null && pinned != null && source.version != 'v$pinned') {
      report(
        '${source.header} version is ${source.version}, but ${pin.constant} '
        'is $pinned: write v$pinned.',
      );
    }
  }

  final pins = <String, _PinIndex>{};
  for (final source in sources) {
    final name = source.header;
    final version = parsePortVersion(source.version);
    if (version == null) {
      report(
        '$name version "${source.version}" is not a dotted version or '
        '<version>+<sha8>.',
      );
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
      final commit = version?.commit;
      if (commit == null) {
        if (source.pinRef != null && source.pinRef != source.version) {
          report(
            '$name pin ref ${source.pinRef} differs from version '
            '${source.version}.',
          );
        }
      } else {
        if (!source.pinCommit!.startsWith(commit)) {
          report(
            '$name version ${source.version} names the commit $commit, but '
            'the pin commit is ${source.pinCommit}.',
          );
        }
        if (source.pinRef != null && source.pinRef != source.pinCommit) {
          report(
            '$name pin ref ${source.pinRef} differs from the pin commit '
            '${source.pinCommit}. The ref of a commit pin is its full commit '
            '(upstream-tracking.md 2.4).',
          );
        }
      }
      final head = checkedOut ? input.checkoutHead(directory) : null;
      if (head != null && head != source.pinCommit) {
        report(
          '${source.pinPath} has the commit $head checked out, but the $name '
          'pin commit is ${source.pinCommit}. The check reads the source '
          'paths from the checked-out files: check out the pin (dart run '
          'melos run upstream).',
        );
      }
    } else {
      if (version?.commit != null) {
        report(
          '$name version ${source.version} is a commit pin, but the pin kind '
          'is "${source.pinKind}", not "submodule".',
        );
      }
      if (!checkedOut) {
        report('$name: the copy ${source.pinPath} is missing or empty.');
      }
    }

    final listed = {...source.files};
    final index = source.fileIndex;
    if (index != null) {
      final file = File('${input.repository}/$index');
      if (file.existsSync()) {
        final link = RegExp(
          '${RegExp.escape('${source.url}/blob/${source.treeRef}/')}'
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
final class _FileContext({
  required final Map<String, PortSource> sources,
  required final Map<String, _PinIndex> pins,
  required final List<ReuseAnnotation> annotations,

  /// The version constants of the projects of `lib/src/upstream.dart`.
  required final Map<String, _VersionPin> versions,

  /// The primary project of the home package, or null when no entry names
  /// `lib/src/upstream.dart` (a finding of the source list).
  required final PortSource? primary,

  /// The tag of the `DIVERGES(<tag>)` markers.
  required final String markerTag,
  required final List<Finding> findings,
}) {
  final RegExp _marker = _markerPattern(markerTag);
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
    final project = primary?.header;
    final repository = primary?.repository;
    // A backport line of another repository does not match the grammar of
    // the home package.
    bool isForeign(Backport backport) =>
        primary != null && backport.repository != repository;
    final malformed = {
      ...header.malformed,
      for (final backport in header.backports)
        if (isForeign(backport)) backport.line,
    }.toList()..sort();
    for (final line in malformed) {
      report(
        line,
        'the header line does not match the grammar of porting-flow.md 4, '
        'tool 2.',
      );
    }
    // A port-only marker of another project is no marker of the home package.
    final kind =
        header.kind == HeaderKind.portOnly &&
            project != null &&
            header.portOnlyProject != project
        ? HeaderKind.missing
        : header.kind;
    switch (kind) {
      case HeaderKind.missing:
        report(
          1,
          'line 1 is neither a "// Ported from" header (AGENTS.md rule 2) nor '
          'the port-only marker "// Original code, not ported from '
          '${project ?? '<project>'}: <reason>.".',
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
        final backports = [
          for (final backport in header.backports)
            if (!isForeign(backport)) backport,
        ];
        if (project != null &&
            backports.isNotEmpty &&
            !header.portedFrom.any((p) => p.project == project)) {
          report(
            backports.first.line,
            'a backport line needs a "// Ported from $project" line.',
          );
        }
    }

    for (final comment in source.comments) {
      if (!comment.isLineComment) {
        if (_blockMarkerCandidate.hasMatch(comment.text)) {
          report(comment.line, _malformedMarker(markerTag));
        }
        continue;
      }
      final text = comment.text;
      if (comment.line > header.lastLine &&
          !malformed.contains(comment.line) &&
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
        report(comment.line, _malformedMarker(markerTag));
        continue;
      }
      final id = match.group(1)!;
      if (!isDifferenceId(id)) {
        report(
          comment.line,
          'the DIVERGES($markerTag) row ID "$id" does not start with a '
          'category (${differenceCategories.join(', ')}) and a hyphen.',
        );
      }
      if (source.lines[comment.line - 1].length > markerLineLimit) {
        report(
          comment.line,
          'the DIVERGES($markerTag) marker line is longer than '
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
    final pin = versions[source.header];
    final pinned = pin?.pinned;
    final expected = pinned != null ? 'v$pinned' : source.version;
    final actual = parsePortVersion(portedFrom.version);
    final wanted = parsePortVersion(expected);
    if (actual == null || wanted == null) return;
    final order = comparePortVersions(actual, wanted);
    if (order == null) {
      report(
        line,
        '${source.header} ${portedFrom.version} names another commit than '
        'the pin $expected. Restamp it (upstream-tracking.md 4.8).',
      );
    } else if (order < 0) {
      findings.add(
        Finding.warning(
          path,
          line,
          'stale header: ${source.header} ${portedFrom.version} is older than '
          '$expected${pin != null ? ' (${pin.constant})' : ''}. Restamp it '
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
