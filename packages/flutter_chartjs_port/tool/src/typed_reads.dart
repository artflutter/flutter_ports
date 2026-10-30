// Original code, not ported from Chart.js: the by-name read ratchet, tool 9.

/// The ratchet of the by-name forms, tool 9 (`check:typed-reads`).
///
/// The port moves from options that it reads by string key to typed options.
/// The check counts the by-name forms ([ByNameForm]) in the code of each Dart
/// file under `lib/src/` of the package. The files under `lib/src/js/` (the
/// JS runtime, which defines `jsGet` and the other functions) and under
/// `lib/src/options/` (the typed options) do not count. The check compares
/// each count with the baseline of its file and fails when a count is above
/// the baseline. Thus no change adds a by-name form. A change that removes
/// forms lowers the baselines with `--update`.
///
/// Counting rules ([findByNameSites]). The check reads the code without
/// comments and without the contents of string literals ([DartSource]). The
/// code of an interpolation `${...}` stays code. A name matches only as a
/// whole identifier: no letter, digit, `_` or `$` directly before or after
/// it. A prefix before the name is allowed (`js.jsGet(`).
/// - [ByNameForm.jsGet], [ByNameForm.jsGetKey] and [ByNameForm.jsObjectKeys]:
///   the name, optional white space and `(`. A declaration counts too. A
///   tear-off without `(` does not count. `jsGetIndex(` (an index read of a
///   List) does not count.
/// - [ByNameForm.jsCall]: an identifier that starts with `jsCall`, optional
///   white space and `(`: `jsCall(`, `jsCall1(`, `jsCall2(`.
/// - [ByNameForm.stringIndex]: an index, read or write, whose content is one
///   string literal, with optional white space around it. Adjacent string
///   literals (`'a' 'b'`) are one literal in Dart. A literal with an
///   interpolation (`x['$name']`, `x['a${b}']`) counts too: it still reads a
///   property by name. A `[` is an index when it follows directly, with no
///   white space:
///   - an identifier that is not an expression keyword
///     ([expressionKeywords], for example `return` and `in`), `)` or `]`:
///     `x['a']`, `f()['a']`, `x['a']['b']` (two), `this['a']`;
///   - the postfix `!` or the null-aware `?` directly after one of these:
///     `x!['a']`, `x?['a']`;
///   - the cascade `..` or `?..`: `..['a'] = 1`.
///
///   Thus a list literal (`['a']`, `<String>['a']`, `!['a'].contains(x)`), a
///   spread (`...['a']`) and a map key (`{'a': 1}`) do not count. An index
///   with another expression (`x[key]`, `x['a' + b]`, `x[0]`) does not count
///   either. The rule assumes formatted code, where a keyword or a `?` of a
///   conditional expression has a space before the `[` of a list literal.
/// - [ByNameForm.extendsMapBase]: `extends MapBase`, with optional white
///   space, prefix and type arguments.
/// - [ByNameForm.withMapMixin]: `MapMixin` as an entry of a `with` clause
///   (`with MapMixin<K, V>`, `with A, MapMixin<K, V>`). The clause ends at
///   `implements`, `{` or `;`.
/// - [ByNameForm.implementsMap]: `Map` as an entry of an `implements` clause
///   (`implements Map<K, V>`, `implements A, Map`). Other types whose name
///   contains `Map` (`HashMap`, `MapBase`) do not count. The clause ends at
///   `{` or `;`.
///
/// Baselines ([formatBaseline], [parseBaseline]). The baseline of the file
/// `lib/src/<path>` is `tool/typed_reads/<path>.txt`, for example
/// `tool/typed_reads/core/core.config.dart.txt`. It has one line
/// `<form> <count>` for each form with a count above 0, in the order of
/// [ByNameForm], and a line end after each line. A missing baseline means
/// that each count is 0. The check ignores empty lines and lines that start
/// with `#`; `--update` writes neither. The update mode owns the folder: it
/// writes each baseline of a file with a count above 0 and deletes every
/// other file of the folder.
library;

import 'dart:io';

import 'check_support.dart';
import 'dart_source.dart';

/// The name of the check in its output.
const String typedReadsName = 'check:typed-reads';

/// The folder of the counted files, relative to the package.
const String sourceDirectory = 'lib/src';

/// The folder of the baseline files, relative to the package.
const String baselineDirectory = 'tool/typed_reads';

/// The folders under [sourceDirectory] whose files do not count.
const List<String> excludedDirectories = ['js/', 'options/'];

/// The extension that a baseline adds to the path of its source file.
const String baselineExtension = '.txt';

/// The keywords that a list literal can follow: a `[` directly after one of
/// them starts a list literal, not an index.
const Set<String> expressionKeywords = {
  'await',
  'case',
  'const',
  'do',
  'else',
  'in',
  'is',
  'return',
  'throw',
  'when',
  'yield',
};

/// A by-name form. The order is the line order of a baseline file.
enum ByNameForm {
  /// A call of `jsGet`, the property read `object[key]`.
  jsGet,

  /// A call of `jsGetKey`, the read of a parsed item by key.
  jsGetKey,

  /// An index whose content is one string literal: `x['name']`.
  stringIndex,

  /// A call of a function whose name starts with `jsCall`.
  jsCall,

  /// A call of `jsObjectKeys`, the keys in `Object.keys` order.
  jsObjectKeys,

  /// A class that extends `MapBase`.
  extendsMapBase,

  /// A class with the mixin `MapMixin`.
  withMapMixin,

  /// A class that implements `Map`.
  implementsMap,
}

/// One by-name form in a file.
final class ByNameSite {
  /// The [form] on the 1-based [line].
  const ByNameSite(this.form, this.line);

  /// The form.
  final ByNameForm form;

  /// The 1-based line of the start of the form.
  final int line;

  @override
  String toString() => '$line ${form.name}';
}

/// The count of each [ByNameForm] in a file or a tree.
final class FormCounts {
  /// Counts that are all 0.
  FormCounts() : _counts = List.filled(ByNameForm.values.length, 0);

  /// The counts of the forms of [sites].
  factory FormCounts.of(Iterable<ByNameSite> sites) {
    final counts = FormCounts();
    for (final site in sites) {
      counts[site.form]++;
    }
    return counts;
  }

  final List<int> _counts;

  /// The count of [form].
  int operator [](ByNameForm form) => _counts[form.index];

  /// Sets the count of [form].
  void operator []=(ByNameForm form, int count) => _counts[form.index] = count;

  /// Whether each count is 0.
  bool get isZero => _counts.every((count) => count == 0);

  /// Adds the counts of [other] to these counts.
  void add(FormCounts other) {
    for (var i = 0; i < _counts.length; i++) {
      _counts[i] += other._counts[i];
    }
  }

  /// The counts above 0, by form name, in the order of [ByNameForm].
  Map<String, int> get nonZero => {
    for (final form in ByNameForm.values)
      if (this[form] > 0) form.name: this[form],
  };

  /// Each form with its count, in the order of [ByNameForm]:
  /// `jsGet 3, jsGetKey 0, ...`.
  String describeAll() => [
    for (final form in ByNameForm.values) '${form.name} ${this[form]}',
  ].join(', ');

  @override
  String toString() => describeAll();
}

/// The by-name forms in the Dart [text], in source order. See the library
/// documentation for the rules.
List<ByNameSite> findByNameSites(String text) {
  final source = DartSource(text);
  final code = source.code;
  final sites = <(int, ByNameForm)>[];
  for (final (form, pattern) in _calls) {
    for (final match in pattern.allMatches(code)) {
      sites.add((match.start, form));
    }
  }
  for (final match in _extendsMapBase.allMatches(code)) {
    sites.add((match.start, ByNameForm.extendsMapBase));
  }
  for (final (offset, entry) in _clauseEntries(code, 'with')) {
    if (_typeNamed(entry, 'MapMixin')) {
      sites.add((offset, ByNameForm.withMapMixin));
    }
  }
  for (final (offset, entry) in _clauseEntries(code, 'implements')) {
    if (_typeNamed(entry, 'Map')) sites.add((offset, ByNameForm.implementsMap));
  }
  sites
    ..addAll([
      for (final offset in _stringIndexes(source))
        (offset, ByNameForm.stringIndex),
    ])
    ..sort((a, b) {
      final byOffset = a.$1.compareTo(b.$1);
      return byOffset != 0 ? byOffset : a.$2.index.compareTo(b.$2.index);
    });
  return [
    for (final (offset, form) in sites) ByNameSite(form, source.lineOf(offset)),
  ];
}

/// The counts of the by-name forms in the Dart [text].
FormCounts countByNameForms(String text) =>
    FormCounts.of(findByNameSites(text));

/// The call forms: a whole identifier, optional white space and `(`.
final List<(ByNameForm, RegExp)> _calls = [
  (ByNameForm.jsGet, RegExp(r'(?<![\w$])jsGet\s*\(')),
  (ByNameForm.jsGetKey, RegExp(r'(?<![\w$])jsGetKey\s*\(')),
  (ByNameForm.jsCall, RegExp(r'(?<![\w$])jsCall[\w$]*\s*\(')),
  (ByNameForm.jsObjectKeys, RegExp(r'(?<![\w$])jsObjectKeys\s*\(')),
];

final RegExp _extendsMapBase = RegExp(
  r'(?<![\w$])extends\s+(?:[A-Za-z_$][\w$]*\s*\.\s*)?MapBase(?![\w$])',
);

final RegExp _implementsKeyword = RegExp(r'(?<![\w$])implements(?![\w$])');

/// Whether the clause [entry] is the type [name], with an optional prefix,
/// type arguments and `?`.
bool _typeNamed(String entry, String name) => RegExp(
  '^(?:[A-Za-z_\$][\\w\$]*\\s*\\.\\s*)?$name(?![\\w\$])',
).hasMatch(entry);

/// The entries of each [keyword] clause of [code], each with the offset of
/// its first character. A clause ends at `{` or `;`, and a `with` clause also
/// at `implements`. The entries are the parts between the commas outside
/// type arguments, without white space around them.
Iterable<(int, String)> _clauseEntries(String code, String keyword) sync* {
  final pattern = RegExp('(?<![\\w\$])$keyword(?![\\w\$])');
  for (final match in pattern.allMatches(code)) {
    var end = match.end;
    while (end < code.length && code[end] != '{' && code[end] != ';') {
      end++;
    }
    if (keyword != 'implements') {
      final next = _implementsKeyword.firstMatch(
        code.substring(match.end, end),
      );
      if (next != null) end = match.end + next.start;
    }
    var depth = 0;
    var start = match.end;
    for (var i = match.end; i <= end; i++) {
      final c = i < end ? code[i] : ',';
      if (c == '<' || c == '(') {
        depth++;
      } else if (c == '>' || c == ')') {
        depth--;
      } else if (c == ',' && depth <= 0) {
        final entry = code.substring(start, i);
        final trimmed = entry.trimLeft();
        if (trimmed.isNotEmpty) {
          yield (start + entry.length - trimmed.length, trimmed.trimRight());
        }
        start = i + 1;
      }
    }
  }
}

/// The offsets of the `[` of the string indexes of [source].
Iterable<int> _stringIndexes(DartSource source) sync* {
  final code = source.code;
  final literals = {
    for (final literal in source.strings) literal.start: literal,
  };
  for (var i = code.indexOf('['); i >= 0; i = code.indexOf('[', i + 1)) {
    if (!_isIndex(code, i)) continue;
    var position = _skipSpace(code, i + 1);
    var count = 0;
    for (
      var literal = literals[position];
      literal != null;
      literal = literals[position]
    ) {
      count++;
      position = _skipSpace(code, literal.end);
    }
    if (count > 0 && position < code.length && code[position] == ']') {
      yield i;
    }
  }
}

/// Whether the `[` at [bracket] of [code] starts an index, not a list
/// literal.
bool _isIndex(String code, int bracket) {
  if (bracket < 1) return false;
  final before = code[bracket - 1];
  if (before == '.') {
    // The cascade `..[` or `?..[`, not the spread `...[`.
    return bracket >= 2 &&
        code[bracket - 2] == '.' &&
        (bracket < 3 || code[bracket - 3] != '.');
  }
  if (before == '!' || before == '?') return _endsOperand(code, bracket - 1);
  return _endsOperand(code, bracket);
}

/// Whether the code before [end] ends an operand: `)`, `]` or an identifier
/// that is not one of the [expressionKeywords].
bool _endsOperand(String code, int end) {
  if (end < 1) return false;
  final last = code.codeUnitAt(end - 1);
  if (last == 0x29 || last == 0x5D) return true; // `)` or `]`.
  if (!_isIdentifierPart(last)) return false;
  var start = end - 1;
  while (start > 0 && _isIdentifierPart(code.codeUnitAt(start - 1))) {
    start--;
  }
  return !expressionKeywords.contains(code.substring(start, end));
}

bool _isIdentifierPart(int c) =>
    (c >= 0x41 && c <= 0x5A) ||
    (c >= 0x61 && c <= 0x7A) ||
    (c >= 0x30 && c <= 0x39) ||
    c == 0x5F ||
    c == 0x24;

int _skipSpace(String code, int from) {
  var i = from;
  while (i < code.length) {
    final c = code.codeUnitAt(i);
    if (c != 0x20 && c != 0x09 && c != 0x0A && c != 0x0D) break;
    i++;
  }
  return i;
}

/// The baseline text of [counts]: one `<form> <count>` line for each form
/// with a count above 0, in the order of [ByNameForm], each with a line end.
String formatBaseline(FormCounts counts) => [
  for (final form in ByNameForm.values)
    if (counts[form] > 0) '${form.name} ${counts[form]}\n',
].join();

/// A baseline line that does not parse.
final class BaselineFormatException implements Exception {
  /// The error [message] for the 1-based [line].
  const BaselineFormatException(this.line, this.message);

  /// The 1-based line.
  final int line;

  /// What is wrong.
  final String message;

  @override
  String toString() => 'line $line: $message';
}

final RegExp _baselineLine = RegExp(r'^(\S+) (\d+)$');

/// The counts of the baseline [text]. Empty lines and lines that start with
/// `#` do not count. Throws a [BaselineFormatException] for a line that is
/// not `<form> <count>`, for an unknown form, for a second line of a form
/// and for a count of 0.
FormCounts parseBaseline(String text) {
  final counts = FormCounts();
  final seen = <ByNameForm>{};
  final lines = text.split('\n');
  for (final (index, raw) in lines.indexed) {
    final line = raw.endsWith('\r') ? raw.substring(0, raw.length - 1) : raw;
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final number = index + 1;
    final match = _baselineLine.firstMatch(line);
    if (match == null) {
      throw BaselineFormatException(
        number,
        'the line is not "<form> <count>".',
      );
    }
    final form = ByNameForm.values
        .where((form) => form.name == match[1])
        .firstOrNull;
    if (form == null) {
      throw BaselineFormatException(
        number,
        'unknown form "${match[1]}"; the forms are '
        '${ByNameForm.values.map((form) => form.name).join(', ')}.',
      );
    }
    if (!seen.add(form)) {
      throw BaselineFormatException(number, 'a second line of ${form.name}.');
    }
    final count = int.parse(match[2]!);
    if (count == 0) {
      throw BaselineFormatException(
        number,
        'the count of ${form.name} is 0: a baseline names only the forms '
        'with a count above 0.',
      );
    }
    counts[form] = count;
  }
  return counts;
}

/// The result of [compareTypedReads].
final class TypedReadsReport {
  /// A report with the [findings], the number of counted [files] and the
  /// [totals] over these files.
  const TypedReadsReport({
    required this.findings,
    required this.files,
    required this.totals,
  });

  /// The errors (a count above its baseline, a stale or malformed baseline)
  /// and the warnings (a count below its baseline).
  final List<Finding> findings;

  /// The number of counted files.
  final int files;

  /// The sum of the counts of the counted files.
  final FormCounts totals;

  /// The number of errors.
  int get errors => findings.where((finding) => finding.isError).length;

  /// Whether the check passes: no finding is an error.
  bool get passed => errors == 0;
}

/// Compares the [counts] of the counted files with the [baselines].
///
/// The keys of [counts] are the paths relative to `lib/src/`. The keys of
/// [baselines] are the paths relative to `tool/typed_reads/`, the values are
/// the file texts. The paths of the findings start with [sourcePrefix] for a
/// source file and with [baselinePrefix] for a baseline file. The findings
/// come in the order of the paths: the source files first, then the
/// baselines without a counted file.
TypedReadsReport compareTypedReads(
  Map<String, FormCounts> counts,
  Map<String, String> baselines, {
  String sourcePrefix = '$sourceDirectory/',
  String baselinePrefix = '$baselineDirectory/',
}) {
  final findings = <Finding>[];
  final totals = FormCounts();
  for (final path in counts.keys.toList()..sort()) {
    final current = counts[path]!;
    totals.add(current);
    final baselinePath = '$path$baselineExtension';
    final text = baselines[baselinePath];
    final FormCounts baseline;
    try {
      baseline = text == null ? FormCounts() : parseBaseline(text);
    } on BaselineFormatException catch (e) {
      findings.add(
        Finding('$baselinePrefix$baselinePath', e.line, e.message),
      );
      continue;
    }
    for (final form in ByNameForm.values) {
      final count = current[form];
      final limit = baseline[form];
      if (count > limit) {
        findings.add(
          Finding(
            '$sourcePrefix$path',
            null,
            '${form.name} $count > baseline $limit',
          ),
        );
      } else if (count < limit) {
        findings.add(
          Finding.warning(
            '$sourcePrefix$path',
            null,
            '${form.name} $count < baseline $limit; run with --update to '
                'lower it',
          ),
        );
      }
    }
  }
  for (final path in baselines.keys.toList()..sort()) {
    if (!path.endsWith(baselineExtension)) {
      findings.add(
        Finding(
          '$baselinePrefix$path',
          null,
          'not a baseline: the name does not end with $baselineExtension; '
              'run with --update to delete it',
        ),
      );
      continue;
    }
    final source = path.substring(0, path.length - baselineExtension.length);
    if (!counts.containsKey(source)) {
      final excluded = [
        for (final directory in excludedDirectories) '$sourcePrefix$directory',
      ].join(' or ');
      findings.add(
        Finding(
          '$baselinePrefix$path',
          null,
          'stale baseline: $sourcePrefix$source is not a counted file (it '
              'does not exist, or it is under $excluded); run with --update to '
              'delete it',
        ),
      );
    }
  }
  return TypedReadsReport(
    findings: findings,
    files: counts.length,
    totals: totals,
  );
}

/// The baseline files of [counts]: for each file with a count above 0, the
/// path relative to `tool/typed_reads/` and the text, sorted by path.
Map<String, String> baselineFiles(Map<String, FormCounts> counts) => {
  for (final path in counts.keys.toList()..sort())
    if (!counts[path]!.isZero)
      '$path$baselineExtension': formatBaseline(counts[path]!),
};

/// Whether the file at [path] (relative to `lib/src/`) counts.
bool isCountedSource(String path) =>
    path.endsWith('.dart') &&
    !excludedDirectories.any((directory) => path.startsWith(directory));

/// The counts of each counted Dart file under `lib/src/` of [package], by
/// the path relative to `lib/src/`, sorted.
Map<String, FormCounts> scanPackage(String package) {
  final root = '$package/$sourceDirectory';
  return {
    for (final file in dartFilesUnder(root))
      if (isCountedSource(relativePath(root, file)))
        relativePath(root, file): countByNameForms(
          File(file).readAsStringSync(),
        ),
  };
}

/// The files under `tool/typed_reads/` of [package]: the path relative to
/// that folder and the text, sorted by path.
Map<String, String> readBaselines(String package) {
  final root = '$package/$baselineDirectory';
  return {
    for (final file in _filesUnder(root))
      relativePath(root, file): File(file).readAsStringSync(),
  };
}

/// The result of [writeBaselines]: the numbers of baseline files.
typedef BaselineUpdate = ({int written, int deleted, int unchanged});

/// Writes the baselines of [counts] into `tool/typed_reads/` of [package]:
/// creates and rewrites the baselines of the files with a count above 0, and
/// deletes every other file and each folder that becomes empty.
BaselineUpdate writeBaselines(String package, Map<String, FormCounts> counts) {
  final root = '$package/$baselineDirectory';
  final wanted = baselineFiles(counts);
  var written = 0;
  var deleted = 0;
  var unchanged = 0;
  for (final file in _filesUnder(root)) {
    if (!wanted.containsKey(relativePath(root, file))) {
      File(file).deleteSync();
      deleted++;
    }
  }
  for (final MapEntry(key: path, value: text) in wanted.entries) {
    final file = File('$root/$path');
    if (file.existsSync() && file.readAsStringSync() == text) {
      unchanged++;
    } else {
      file
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(text);
      written++;
    }
  }
  _deleteEmptyFolders(Directory(root));
  return (written: written, deleted: deleted, unchanged: unchanged);
}

/// The files under [directory], sorted, as absolute `/` paths.
List<String> _filesUnder(String directory) {
  final root = Directory(directory);
  if (!root.existsSync()) return const [];
  return [
    for (final entity in root.listSync(recursive: true, followLinks: false))
      if (entity is File) posixPath(entity.absolute.path),
  ]..sort();
}

/// Deletes the empty folders under [directory], not [directory] itself.
void _deleteEmptyFolders(Directory directory) {
  if (!directory.existsSync()) return;
  for (final entity in directory.listSync(followLinks: false)) {
    if (entity is Directory) {
      _deleteEmptyFolders(entity);
      if (entity.listSync().isEmpty) entity.deleteSync();
    }
  }
}
