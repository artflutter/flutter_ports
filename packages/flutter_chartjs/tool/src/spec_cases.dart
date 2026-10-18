// Original code, not ported from Chart.js: spec-case tracking, tool 5.

/// Spec-case tracking, tool 5 of porting-flow.md section 4.
///
/// The upstream manifest (tool 4, `doc/upstream/manifest.json`) lists the
/// cases of each `test/specs/<base>.tests.js`. The JSON reporter of
/// `flutter test` lists the Dart tests of each `test/specs/<base>_test.dart`.
/// A Dart test matches a case when its group names equal the `describe`
/// names and its name equals the Dart name `test` of the case (the `it` name,
/// with ` #2` or ` #3` for a repeated full name, porting-flow.md section 1
/// step 5). Each case is then `passed`, `failed`, `skipped(<reason>)` or
/// `missing`.
///
/// Errors:
/// - a Dart test under `test/specs/` that is not a case (an unknown name), or
///   that is a case that an earlier Dart test already matched;
/// - a Dart spec file without an upstream spec file;
/// - a failed case, or a spec file that does not load;
/// - a skip reason that is not `blocked: <module>`, `n/a: <reason>` or
///   `diverges: <row id>`;
/// - a missing case in a spec file that `parity.md` marks `ported`: the row
///   of the spec file, or every `src/` row of its module.
///
/// A Dart test in a fixture group of the manifest (`describe('auto',
/// jasmine.fixture.specs(...))`) whose name is the path of a fixture of that
/// spec file is a fixture test, not an unknown name. The name is the config
/// path relative to `test/fixtures/` (`controller.bar/aligned-pixels.js`) or
/// the upstream `it` name, the Karma URL of the config
/// (`/base/test/fixtures/controller.bar/aligned-pixels.js`,
/// chartjs-test-utils `src/fixture.js:37`).
///
/// A failed `setUpAll` or `tearDownAll` of a group is an error of its own.
/// It is not an unknown name.
library;

import 'dart:convert';

import 'check_support.dart';

/// The upstream spec file of the Dart spec file [dartPath]
/// (`test/specs/<base>_test.dart` to `<base>.tests.js`), or null.
String? upstreamSpecOf(String dartPath) {
  final match = RegExp(r'(?:^|/)test/specs/(.+)_test\.dart$').firstMatch(
    posixPath(dartPath),
  );
  return match == null ? null : '${match[1]}.tests.js';
}

/// The Dart spec file of the upstream spec file [spec].
String dartSpecOf(String spec) =>
    'test/specs/${spec.substring(0, spec.length - '.tests.js'.length)}'
    '_test.dart';

/// The key of a test path: the group names and the test name.
String _key(Iterable<String> path) => path.join('\u0000');

/// One case of the upstream manifest.
final class ManifestCase {
  /// A case of [spec] with its [describe] names, [it] name and Dart [test]
  /// name.
  const ManifestCase({
    required this.spec,
    required this.describe,
    required this.it,
    required this.test,
    required this.line,
    required this.loop,
    required this.chart,
    required this.pending,
  });

  /// The upstream spec file, for example `helpers.math.tests.js`.
  final String spec;

  /// The `describe` names, outermost first.
  final List<String> describe;

  /// The `it` name.
  final String it;

  /// The name of the Dart test: [it], or [it] with ` #2` or ` #3`.
  final String test;

  /// The line of the `it` call in the upstream spec file.
  final int? line;

  /// Whether a loop made this case (its `it` call site made more cases).
  final bool loop;

  /// Whether the case acquires a chart (`kind` `chart`).
  final bool chart;

  /// Whether Jasmine skips the case upstream (`xit`, `xdescribe`).
  final bool pending;

  /// The group names and the Dart test name.
  List<String> get path => [...describe, test];

  /// The full name of the Dart test: [path] joined with spaces.
  String get fullName => path.join(' ');
}

/// A `describe` whose body is `jasmine.fixture.specs(prefix)`.
final class FixtureGroup {
  /// A fixture group at the [describe] path.
  const FixtureGroup(this.describe, this.prefix);

  /// The `describe` names of the group, outermost first.
  final List<String> describe;

  /// The fixture path prefix.
  final String prefix;
}

/// One upstream spec file of the manifest.
final class ManifestSpec {
  /// The spec [file] with its [cases], [fixtureGroups] and [fixtures].
  ManifestSpec(this.file, this.cases, this.fixtureGroups, this.fixtures);

  /// The file name in `test/specs/`, for example `helpers.math.tests.js`.
  final String file;

  /// The cases, in upstream order.
  final List<ManifestCase> cases;

  /// The fixture groups.
  final List<FixtureGroup> fixtureGroups;

  /// The paths (relative to `test/fixtures/`) of the fixtures that the
  /// fixture groups of this file run.
  final Set<String> fixtures;

  late final Map<String, ManifestCase> _byKey = {
    for (final c in cases) _key(c.path): c,
  };

  /// The case with the group names [groups] and the test name [name].
  ManifestCase? caseAt(List<String> groups, String name) =>
      _byKey[_key([...groups, name])];

  /// Whether [groups] and [name] name a fixture test of this file. [name] is
  /// the config path relative to `test/fixtures/`, or that path after
  /// [fixtureUrlPrefix] (the upstream `it` name).
  bool isFixtureTest(List<String> groups, String name) =>
      fixtures.contains(
        name.startsWith(fixtureUrlPrefix)
            ? name.substring(fixtureUrlPrefix.length)
            : name,
      ) &&
      fixtureGroups.any((g) => _key(g.describe) == _key(groups));
}

/// The prefix of the upstream fixture `it` names: `specFromFixture` of
/// chartjs-test-utils 0.4.0 (`src/fixture.js:37`) names each case with the
/// Karma URL of its config.
const String fixtureUrlPrefix = '/base/test/fixtures/';

/// The upstream manifest of tool 4.
final class Manifest {
  /// A manifest of the Chart.js [version] with its [specs] by file name.
  const Manifest(this.version, this.specs);

  /// Reads the manifest JSON [text]. Throws a [FormatException] when [text]
  /// is not JSON, or when a field is missing or has another type.
  factory Manifest.parse(String text) {
    final json = _as<Map<String, Object?>>(jsonDecode(text), 'the manifest');
    final schema = json['schema'];
    if (schema != 1) {
      throw FormatException('manifest schema $schema, expected 1');
    }
    final source = _field<Map<String, Object?>>(json, 'source', 'manifest');
    final fixtures = <String, Set<String>>{};
    final fixtureItems = _field<List<Object?>>(
      _field<Map<String, Object?>>(json, 'fixtures', 'manifest'),
      'items',
      'fixtures',
    );
    for (final item in _maps(fixtureItems, 'fixtures.items')) {
      final path = _field<String>(item, 'path', 'fixture');
      for (final spec in _strings(item['specs'], 'fixture $path specs')) {
        (fixtures[spec] ??= {}).add(path);
      }
    }
    final specs = <String, ManifestSpec>{};
    for (final spec in _maps(json['specs'], 'specs')) {
      final file = _field<String>(spec, 'file', 'spec');
      final cases = [
        for (final c in _maps(spec['cases'], '$file cases'))
          ManifestCase(
            spec: file,
            describe: _strings(c['describe'], '$file case describe'),
            it: _field<String>(c, 'it', '$file case'),
            test: _field<String>(c, 'test', '$file case'),
            line: _as<int?>(c['line'], '$file case line'),
            loop: c['loop'] == true,
            chart: c['kind'] == 'chart',
            pending: c['pending'] == true,
          ),
      ];
      final groups = [
        for (final g in _maps(spec['fixtureGroups'], '$file fixtureGroups'))
          FixtureGroup(
            _strings(g['describe'], '$file fixture group describe'),
            _field<String>(g, 'prefix', '$file fixture group'),
          ),
      ];
      specs[file] = ManifestSpec(file, cases, groups, fixtures[file] ?? {});
    }
    return Manifest(_field<String>(source, 'version', 'source'), specs);
  }

  /// The Chart.js version of the checkout.
  final String version;

  /// The upstream spec files by file name.
  final Map<String, ManifestSpec> specs;
}

/// [value] as a [T], or a [FormatException] that names [what].
T _as<T>(Object? value, String what) => value is T
    ? value
    : throw FormatException('$what is ${value.runtimeType}, expected $T');

/// The field [key] of [map] as a [T], or a [FormatException].
T _field<T>(Map<String, Object?> map, String key, String what) =>
    _as<T>(map[key], '$what field "$key"');

/// [value] as a list of JSON objects, or a [FormatException].
List<Map<String, Object?>> _maps(Object? value, String what) => [
  for (final item in _as<List<Object?>>(value, what))
    _as<Map<String, Object?>>(item, 'an item of $what'),
];

/// [value] as a list of strings, or a [FormatException].
List<String> _strings(Object? value, String what) => [
  for (final item in _as<List<Object?>>(value, what))
    _as<String>(item, 'an item of $what'),
];

/// The result of a Dart test.
enum TestResult {
  /// The test passed.
  success,

  /// The test failed, or threw.
  failure,

  /// The test was skipped.
  skipped,
}

/// One Dart test of the JSON reporter.
final class DartTest {
  /// A test of the Dart spec [file] with its [groups] and [name].
  const DartTest({
    required this.file,
    required this.groups,
    required this.name,
    required this.result,
    this.line,
    this.skipReason,
  });

  /// The spec file, as `test/specs/<base>_test.dart`.
  final String file;

  /// The group names, outermost first, without the root group.
  final List<String> groups;

  /// The test name without the group names.
  final String name;

  /// The result.
  final TestResult result;

  /// The line of the test in [file].
  final int? line;

  /// The skip reason, when [result] is [TestResult.skipped].
  final String? skipReason;

  /// The full name: [groups] and [name], joined with spaces.
  String get fullName => [...groups, name].join(' ');
}

/// A `setUpAll` or `tearDownAll` of a group that did not pass.
final class HookFailure {
  /// The [hook] of the group [groups] in the spec [file] failed with [error].
  const HookFailure({
    required this.file,
    required this.groups,
    required this.hook,
    required this.error,
    this.line,
  });

  /// The spec file, as `test/specs/<base>_test.dart`.
  final String file;

  /// The group names, outermost first, without the root group.
  final List<String> groups;

  /// `setUpAll` or `tearDownAll`.
  final String hook;

  /// The error, or the result of the hook.
  final String error;

  /// The line of the hook in [file].
  final int? line;
}

/// The tests and the load errors of a JSON reporter output.
final class ReporterOutput {
  /// The [tests], the [loadErrors] (one message for each file) and the
  /// [hookFailures].
  const ReporterOutput(
    this.tests,
    this.loadErrors, [
    this.hookFailures = const [],
  ]);

  /// The tests, in the order of their `testStart` events.
  final List<DartTest> tests;

  /// The files that did not load, with the error.
  final Map<String, String> loadErrors;

  /// The `setUpAll` and `tearDownAll` hooks that did not pass. The JSON
  /// reporter shows a failed hook as a test named `<group> (setUpAll)` or
  /// `<group> (tearDownAll)`. The tests of a group whose `setUpAll` failed
  /// do not run.
  final List<HookFailure> hookFailures;
}

/// The names of the tests that the JSON reporter makes for group hooks.
const Map<String, String> _hookTests = {
  '(setUpAll)': 'setUpAll',
  '(tearDownAll)': 'tearDownAll',
};

/// The `test/specs/...` part of the suite [path], or [path].
String _specPath(String path) {
  final posix = posixPath(path);
  final index = posix.lastIndexOf('test/specs/');
  return index < 0 ? posix : posix.substring(index);
}

/// Reads the output of `flutter test --reporter json` (or `dart test`).
/// Lines that are not JSON objects, for example the output of
/// `pub get`, are skipped.
ReporterOutput parseReporterOutput(String output) {
  final suites = <int, String>{};
  final groups = <int, ({String name, int? parent})>{};
  final starts = <int, Map<String, Object?>>{};
  final tests = <int, DartTest>{};
  final order = <int>[];
  final loadErrors = <String, String>{};
  final hookFailures = <HookFailure>[];
  final errors = <int, String>{};
  for (final line in const LineSplitter().convert(output)) {
    if (!line.startsWith('{')) continue;
    final Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on FormatException {
      continue;
    }
    if (decoded is! Map<String, Object?>) continue;
    switch (decoded['type']) {
      case 'suite':
        final suite = decoded['suite']! as Map<String, Object?>;
        suites[suite['id']! as int] = _specPath(suite['path']! as String);
      case 'group':
        final group = decoded['group']! as Map<String, Object?>;
        groups[group['id']! as int] = (
          name: group['name']! as String,
          parent: group['parentID'] as int?,
        );
      case 'testStart':
        final test = decoded['test']! as Map<String, Object?>;
        starts[test['id']! as int] = test;
      case 'error':
        final id = decoded['testID']! as int;
        errors[id] ??= '${decoded['error']}';
      case 'testDone':
        final id = decoded['testID']! as int;
        final start = starts[id];
        if (start == null) continue;
        final file = suites[start['suiteID']! as int] ?? '';
        final name = start['name']! as String;
        final groupIds = (start['groupIDs']! as List<Object?>).cast<int>();
        if (groupIds.isEmpty || decoded['hidden'] == true) {
          if (decoded['result'] != 'success') {
            loadErrors[file] = errors[id] ?? '$name: ${decoded['result']}';
          }
          continue;
        }
        final leaf = _leafName(name, groupIds, groups);
        if (_hookTests[leaf] case final hook?) {
          if (decoded['result'] != 'success') {
            hookFailures.add(
              HookFailure(
                file: file,
                groups: _groupNames(groupIds, groups),
                hook: hook,
                error: errors[id] ?? '${decoded['result']}',
                line: start['line'] as int?,
              ),
            );
          }
          continue;
        }
        final metadata = start['metadata'] as Map<String, Object?>? ?? {};
        final skipped = decoded['skipped'] == true;
        tests[id] = DartTest(
          file: file,
          groups: _groupNames(groupIds, groups),
          name: leaf,
          result: skipped
              ? TestResult.skipped
              : decoded['result'] == 'success'
              ? TestResult.success
              : TestResult.failure,
          line: start['line'] as int?,
          skipReason: skipped ? metadata['skipReason'] as String? : null,
        );
        order.add(id);
    }
  }
  return ReporterOutput(
    [for (final id in order) tests[id]!],
    loadErrors,
    hookFailures,
  );
}

/// The group names of [ids] (the root group first), each without the name
/// of its parent group. The root group has an empty name and is left out.
List<String> _groupNames(
  List<int> ids,
  Map<int, ({String name, int? parent})> groups,
) {
  final names = <String>[];
  var parent = '';
  for (final id in ids) {
    final full = groups[id]?.name ?? '';
    if (full.isEmpty) continue;
    names.add(_strip(full, parent));
    parent = full;
  }
  return names;
}

/// The test [name] without the full name of its innermost group.
String _leafName(
  String name,
  List<int> ids,
  Map<int, ({String name, int? parent})> groups,
) {
  final parent = ids.isEmpty ? '' : groups[ids.last]?.name ?? '';
  return _strip(name, parent);
}

String _strip(String full, String parent) =>
    parent.isNotEmpty && full.startsWith('$parent ')
    ? full.substring(parent.length + 1)
    : full;

/// The status of one upstream case.
enum CaseStatus {
  /// The Dart test passed.
  passed,

  /// The Dart test failed.
  failed,

  /// The Dart test was skipped.
  skipped,

  /// No Dart test matches the case.
  missing,
}

/// One upstream case and its Dart test.
final class CaseResult {
  /// The [status] of [upstream], from [test].
  const CaseResult(this.upstream, this.status, this.test);

  /// The upstream case.
  final ManifestCase upstream;

  /// The status.
  final CaseStatus status;

  /// The matching Dart test, or null when [status] is
  /// [CaseStatus.missing].
  final DartTest? test;

  /// `passed`, `failed`, `skipped(<reason>)` or `missing`.
  String get label => status == CaseStatus.skipped
      ? 'skipped(${test?.skipReason ?? ''})'
      : status.name;
}

/// The cases of one upstream spec file.
final class SpecReport {
  /// The report of [spec].
  const SpecReport({
    required this.spec,
    required this.results,
    required this.hasDartFile,
    required this.parityStatus,
    required this.required,
    required this.fixtureTests,
  });

  /// The upstream spec file.
  final String spec;

  /// The status of each case, in upstream order.
  final List<CaseResult> results;

  /// Whether `test/specs/<base>_test.dart` reported tests.
  final bool hasDartFile;

  /// The `parity.md` status that applies, or null.
  final String? parityStatus;

  /// Whether a missing case is an error.
  final bool required;

  /// The number of fixture tests.
  final int fixtureTests;

  /// The number of cases with [status].
  int count(CaseStatus status) =>
      results.where((r) => r.status == status).length;
}

/// The `Status` column of the `parity.md` tables, by upstream path
/// (`src/...` and `test/specs/...`).
Map<String, String> parseParityStatuses(String markdown) {
  final row = RegExp(r'^\|\s*\[`([^`]+)`\]\([^)]*\)\s*\|.*\|\s*([^|]*?)\s*\|$');
  return {
    for (final line in const LineSplitter().convert(markdown))
      if (row.firstMatch(line.trim()) case final match?) match[1]!: match[2]!,
  };
}

final RegExp _done = RegExp(r'^ported\b');

/// The `parity.md` status that makes the cases of [spec] required, or the
/// status of its spec row, and whether it is required.
///
/// The spec row is `test/specs/<spec>`. The module rows are the `src/` rows
/// whose file name without its extension is `<base>`, or that are in a
/// `<base>/` directory (`plugin.filler`).
({String? status, bool required}) requiredBy(
  String spec,
  Map<String, String> parity,
) {
  final base = spec.substring(0, spec.length - '.tests.js'.length);
  final specStatus = parity['test/specs/$spec'];
  if (specStatus != null && _done.hasMatch(specStatus)) {
    return (status: specStatus, required: true);
  }
  final modules = [
    for (final MapEntry(:key, :value) in parity.entries)
      if (key.startsWith('src/') &&
          (key.contains('/$base/') ||
              key.split('/').last.replaceFirst(RegExp(r'\.[^.]+$'), '') ==
                  base))
        value,
  ];
  if (modules.isNotEmpty && modules.every(_done.hasMatch)) {
    return (status: modules.first, required: true);
  }
  return (
    status: specStatus ?? (modules.isEmpty ? null : modules.first),
    required: false,
  );
}

final RegExp _skipReason = RegExp(
  r'^(blocked: \S.*|n/a: \S.*|'
  r'diverges: (adapt|platform|theme|js-semantics|harness|not-followed)-\S+)$',
);

/// Whether [reason] is a skip reason of porting-flow.md section 1 step 5.
bool isValidSkipReason(String? reason) =>
    reason != null && _skipReason.hasMatch(reason);

/// The result of [compareCases].
final class SpecCasesResult {
  /// The [reports] of all upstream spec files and the [findings].
  const SpecCasesResult(this.reports, this.findings);

  /// One report for each upstream spec file, in manifest order.
  final List<SpecReport> reports;

  /// The errors.
  final List<Finding> findings;
}

/// Maps the Dart [output] onto the cases of [manifest]. [parity] holds the
/// `parity.md` statuses. Paths in findings start with [displayPrefix] (the
/// package directory relative to the working directory, with a `/`).
SpecCasesResult compareCases(
  Manifest manifest,
  ReporterOutput output,
  Map<String, String> parity, {
  String displayPrefix = '',
}) {
  final findings = <Finding>[];
  for (final MapEntry(:key, :value) in output.loadErrors.entries) {
    findings.add(Finding('$displayPrefix$key', null, 'does not load: $value'));
  }
  for (final hook in output.hookFailures) {
    final group = hook.groups.isEmpty
        ? 'the top level'
        : '"${hook.groups.join(' ')}"';
    findings.add(
      Finding(
        '$displayPrefix${hook.file}',
        hook.line,
        '${hook.hook} of $group failed: ${hook.error}',
      ),
    );
  }
  final byFile = <String, List<DartTest>>{};
  for (final test in output.tests) {
    (byFile[test.file] ??= []).add(test);
  }
  for (final file in byFile.keys) {
    final spec = upstreamSpecOf(file);
    if (spec == null || !manifest.specs.containsKey(spec)) {
      findings.add(
        Finding(
          '$displayPrefix$file',
          null,
          'no upstream spec file test/specs/${spec ?? '?'} in the manifest.',
        ),
      );
    }
  }

  final reports = <SpecReport>[];
  for (final spec in manifest.specs.values) {
    final dartFile = dartSpecOf(spec.file);
    final shown = '$displayPrefix$dartFile';
    final tests = byFile[dartFile] ?? const <DartTest>[];
    final matched = <ManifestCase, DartTest>{};
    var fixtureTests = 0;
    for (final test in tests) {
      final upstream = spec.caseAt(test.groups, test.name);
      if (upstream == null) {
        if (spec.isFixtureTest(test.groups, test.name)) {
          fixtureTests++;
        } else {
          findings.add(
            Finding(
              shown,
              test.line,
              '"${test.fullName}" is not a case of '
              'test/specs/${spec.file}.',
            ),
          );
        }
        continue;
      }
      if (matched.containsKey(upstream)) {
        findings.add(
          Finding(
            shown,
            test.line,
            '"${test.fullName}" repeats the case of line '
            '${matched[upstream]!.line}.',
          ),
        );
        continue;
      }
      matched[upstream] = test;
      if (test.result == TestResult.failure) {
        findings.add(Finding(shown, test.line, '"${test.fullName}" failed.'));
      }
      if (test.result == TestResult.skipped &&
          !isValidSkipReason(test.skipReason)) {
        findings.add(
          Finding(
            shown,
            test.line,
            test.skipReason == null
                ? '"${test.fullName}" is skipped without a skip reason. '
                      'testWidgets takes only `skip: true`, so write a '
                      'skipped case as a test() with '
                      "`skip: 'blocked: <module>'`, `'n/a: <reason>'` or "
                      "`'diverges: <row id>'`."
                : '"${test.fullName}" has the skip reason '
                      '"${test.skipReason}". '
                      "Use 'blocked: <module>', 'n/a: <reason>' or "
                      "'diverges: <row id>'.",
          ),
        );
      }
    }
    final parityState = requiredBy(spec.file, parity);
    final results = [
      for (final upstream in spec.cases)
        CaseResult(upstream, _status(matched[upstream]), matched[upstream]),
    ];
    if (parityState.required) {
      for (final result in results) {
        if (result.status != CaseStatus.missing || result.upstream.pending) {
          continue;
        }
        findings.add(
          Finding(
            shown,
            null,
            'missing "${result.upstream.fullName}" '
            '(test/specs/${spec.file}:${result.upstream.line}). parity.md '
            'says "${parityState.status}".',
          ),
        );
      }
    }
    reports.add(
      SpecReport(
        spec: spec.file,
        results: results,
        hasDartFile: tests.isNotEmpty,
        parityStatus: parityState.status,
        required: parityState.required,
        fixtureTests: fixtureTests,
      ),
    );
  }
  return SpecCasesResult(reports, findings);
}

CaseStatus _status(DartTest? test) => switch (test?.result) {
  null => CaseStatus.missing,
  TestResult.success => CaseStatus.passed,
  TestResult.failure => CaseStatus.failed,
  TestResult.skipped => CaseStatus.skipped,
};

/// The table of [reports]: one row for each spec file with Dart tests or
/// with required cases, then one row for the other spec files, then the
/// totals. With [verbose], each row is followed by its cases.
String renderTable(List<SpecReport> reports, {bool verbose = false}) {
  final buffer = StringBuffer();
  const headers = ['upstream spec', 'cases', 'passed', 'failed', 'skipped'];
  final shown = reports.where((r) => r.hasDartFile || r.required).toList();
  final others = reports.where((r) => !r.hasDartFile && !r.required).toList();
  final othersLabel = '${others.length} files, no Dart tests';
  final widths = [
    [
      headers[0],
      othersLabel,
      for (final r in shown) r.spec,
    ].fold(0, (w, label) => label.length > w ? label.length : w),
    7,
    7,
    7,
    8,
    8,
  ];
  String row(String spec, List<int> counts, String status) {
    final cells = [
      spec.padRight(widths[0]),
      for (var i = 0; i < counts.length; i++)
        '${counts[i]}'.padLeft(widths[i + 1]),
    ];
    return '${cells.join(' ')}  $status'.trimRight();
  }

  List<int> countsOf(Iterable<SpecReport> rows) => [
    rows.fold(0, (n, r) => n + r.results.length),
    for (final status in CaseStatus.values)
      rows.fold(0, (n, r) => n + r.count(status)),
  ];

  final header = [
    headers[0].padRight(widths[0]),
    for (var i = 1; i < headers.length; i++) headers[i].padLeft(widths[i]),
    'missing'.padLeft(widths[5]),
  ].join(' ');
  buffer.writeln('$header  parity.md');
  for (final report in shown) {
    final status = [
      report.parityStatus ?? '-',
      if (report.required) '(required)',
      if (report.fixtureTests > 0) '+${report.fixtureTests} fixture tests',
    ].join(' ');
    buffer.writeln(row(report.spec, countsOf([report]), status));
    if (verbose) {
      for (final result in report.results) {
        final label = result.label.padRight(20);
        buffer.writeln('  $label ${result.upstream.fullName}');
      }
    }
  }
  if (others.isNotEmpty) {
    buffer.writeln(
      row(othersLabel, countsOf(others), ''),
    );
  }
  buffer.writeln(row('total', countsOf(reports), ''));
  return buffer.toString();
}
