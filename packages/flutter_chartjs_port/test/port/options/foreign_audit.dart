// Original code, not ported from Chart.js: the reviewed set of the oracle O2.

/// The oracle O2 of Chart.js ADR 0054: the audit of the foreign values.
///
/// `test/flutter_test_config.dart` sets the hook `foreignAudit` of
/// `lib/src/options/foreign_audit.dart` to [ForeignAuditCollector.record]
/// before `main()` of each test file, and runs
/// [ForeignAuditCollector.check] after the last test of the file. A typed
/// option object calls the hook inside `assert` for each value that it
/// keeps in a foreign slot. The check fails when a pair (owner, key, kind)
/// of the file is not in [reviewedForeignPairs]. Thus a new foreign pair
/// fails the suites until its lane reviews the readers of that key and adds
/// the pair here, in the same change.
///
/// The set is a Dart file, not a TSV file: the test config also runs in
/// Chrome (`test:web`), without `dart:io`. Each entry is one TSV line:
/// the owner (the Dart name of a scope class of `scopes.g.dart` or of a
/// resolved options class of `resolved.g.dart`), the JS property name and
/// the JS kind of the value ([jsKindOf]).
///
/// Collect the pairs of a run: `--dart-define=O2_COLLECT=true` prints each
/// pair of a test file as a line `O2<TAB>owner<TAB>key<TAB>kind` after its
/// last test, and no check fails.
library;

import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsIsFunction;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// Whether the run prints the pairs and checks nothing
/// (`--dart-define=O2_COLLECT=true`).
const bool _collect = bool.fromEnvironment('O2_COLLECT');

/// The JS kind of [value]: `undefined`, `null`, `boolean`, `number`,
/// `string`, `function` (also a class value), `array`, `Date` or `object`.
String jsKindOf(Object? value) => switch (value) {
  null => 'null',
  Undefined() => 'undefined',
  bool() => 'boolean',
  num() => 'number',
  String() => 'string',
  List<Object?>() => 'array',
  DateTime() => 'Date',
  _ when jsIsFunction(value) => 'function',
  _ => 'object',
};

/// The pairs of one test file.
final class ForeignAuditCollector {
  /// The pairs of the file, as TSV lines, in the order of their first store.
  final Set<String> pairs = <String>{};

  /// The hook: records the pair of a foreign value.
  void record(String owner, String key, Object? raw) {
    pairs.add('$owner\t$key\t${jsKindOf(raw)}');
  }

  /// The pairs of the file that [reviewedForeignPairs] does not list.
  List<String> get unreviewed => [
    for (final pair in pairs)
      if (!reviewedForeignPairs.contains(pair)) pair,
  ];

  /// Prints the pairs (`O2_COLLECT`), or throws a [StateError] for an
  /// unreviewed pair ([throwIfUnreviewed]).
  void check() {
    if (_collect) {
      for (final pair in pairs) {
        // The output of the collect mode.
        // ignore: avoid_print
        print('O2\t$pair');
      }
      return;
    }
    throwIfUnreviewed();
  }

  /// Throws a [StateError] that names each unreviewed pair.
  void throwIfUnreviewed() {
    final unreviewed = this.unreviewed;
    if (unreviewed.isEmpty) return;
    throw StateError(
      'O2: a typed option object keeps a value outside the type of its key '
      'in a foreign slot, and test/port/options/foreign_audit.dart does not '
      'list the pair (Chart.js ADR 0054). Review the readers of the key, then '
      'add the pair:\n${unreviewed.join('\n')}',
    );
  }
}

/// The reviewed pairs (owner, key, kind) of the suites, as TSV lines, in
/// code unit order.
///
/// B4 of Chart.js ADR 0054 recorded the set over `flutter test
/// --exclude-tags golden`. Each lane reviews the pairs of its keys: a
/// reader of a key with a foreign pair that applies a kind-sensitive JS
/// operator reads `foreignOf(key)` (§6).
const Set<String> reviewedForeignPairs = {
  'ArcOptions\tangle\tarray',
  'ArcOptions\tangle\tboolean',
  'ArcOptions\tangle\tnull',
  'ArcOptions\tangle\tobject',
  'ArcOptions\tangle\tstring',
  'ArcOptions\tangle\tundefined',
  'ArcOptions\tborderAlign\tarray',
  'ArcOptions\tborderAlign\tboolean',
  'ArcOptions\tborderAlign\tnull',
  'ArcOptions\tborderAlign\tnumber',
  'ArcOptions\tborderAlign\tobject',
  'ArcOptions\tborderAlign\tundefined',
  'ArcOptions\tborderDashOffset\tarray',
  'ArcOptions\tborderDashOffset\tboolean',
  'ArcOptions\tborderDashOffset\tnull',
  'ArcOptions\tborderDashOffset\tobject',
  'ArcOptions\tborderDashOffset\tstring',
  'ArcOptions\tborderDashOffset\tundefined',
  'ArcOptions\tborderJoinStyle\tarray',
  'ArcOptions\tborderJoinStyle\tboolean',
  'ArcOptions\tborderJoinStyle\tnull',
  'ArcOptions\tborderJoinStyle\tnumber',
  'ArcOptions\tborderJoinStyle\tobject',
  'ArcOptions\tborderJoinStyle\tundefined',
  'ArcOptions\tborderWidth\tarray',
  'ArcOptions\tborderWidth\tboolean',
  'ArcOptions\tborderWidth\tnull',
  'ArcOptions\tborderWidth\tobject',
  'ArcOptions\tborderWidth\tstring',
  'ArcOptions\tborderWidth\tundefined',
  'ArcOptions\tcircular\tarray',
  'ArcOptions\tcircular\tnull',
  'ArcOptions\tcircular\tnumber',
  'ArcOptions\tcircular\tobject',
  'ArcOptions\tcircular\tstring',
  'ArcOptions\tcircular\tundefined',
  'ArcOptions\toffset\tarray',
  'ArcOptions\toffset\tboolean',
  'ArcOptions\toffset\tnull',
  'ArcOptions\toffset\tobject',
  'ArcOptions\toffset\tstring',
  'ArcOptions\toffset\tundefined',
  'ArcOptions\tselfJoin\tarray',
  'ArcOptions\tselfJoin\tnull',
  'ArcOptions\tselfJoin\tnumber',
  'ArcOptions\tselfJoin\tobject',
  'ArcOptions\tselfJoin\tstring',
  'ArcOptions\tselfJoin\tundefined',
  'ArcOptions\tspacing\tarray',
  'ArcOptions\tspacing\tboolean',
  'ArcOptions\tspacing\tnull',
  'ArcOptions\tspacing\tobject',
  'ArcOptions\tspacing\tstring',
  'ArcOptions\tspacing\tundefined',
  'ArcOptions\tspacingMode\tarray',
  'ArcOptions\tspacingMode\tboolean',
  'ArcOptions\tspacingMode\tnull',
  'ArcOptions\tspacingMode\tnumber',
  'ArcOptions\tspacingMode\tobject',
  'ArcOptions\tspacingMode\tundefined',
  'DescriptorsScope\t_rootDesc\tboolean',
  'LineControllerDatasetOptionsScope\tborderWidth\tstring',
  'LineOptions\tborderCapStyle\tarray',
  'LineOptions\tborderCapStyle\tboolean',
  'LineOptions\tborderCapStyle\tnull',
  'LineOptions\tborderCapStyle\tnumber',
  'LineOptions\tborderCapStyle\tobject',
  'LineOptions\tborderCapStyle\tundefined',
  'LineOptions\tborderDashOffset\tarray',
  'LineOptions\tborderDashOffset\tboolean',
  'LineOptions\tborderDashOffset\tnull',
  'LineOptions\tborderDashOffset\tobject',
  'LineOptions\tborderDashOffset\tstring',
  'LineOptions\tborderDashOffset\tundefined',
  'LineOptions\tborderJoinStyle\tarray',
  'LineOptions\tborderJoinStyle\tboolean',
  'LineOptions\tborderJoinStyle\tnull',
  'LineOptions\tborderJoinStyle\tnumber',
  'LineOptions\tborderJoinStyle\tobject',
  'LineOptions\tborderJoinStyle\tundefined',
  'LineOptions\tborderWidth\tarray',
  'LineOptions\tborderWidth\tboolean',
  'LineOptions\tborderWidth\tnull',
  'LineOptions\tborderWidth\tobject',
  'LineOptions\tborderWidth\tstring',
  'LineOptions\tborderWidth\tundefined',
  'LineOptions\tcapBezierPoints\tarray',
  'LineOptions\tcapBezierPoints\tnull',
  'LineOptions\tcapBezierPoints\tnumber',
  'LineOptions\tcapBezierPoints\tobject',
  'LineOptions\tcapBezierPoints\tstring',
  'LineOptions\tcapBezierPoints\tundefined',
  'LineOptions\tcubicInterpolationMode\tarray',
  'LineOptions\tcubicInterpolationMode\tboolean',
  'LineOptions\tcubicInterpolationMode\tnull',
  'LineOptions\tcubicInterpolationMode\tnumber',
  'LineOptions\tcubicInterpolationMode\tobject',
  'LineOptions\tcubicInterpolationMode\tundefined',
  'LineOptions\ttension\tarray',
  'LineOptions\ttension\tboolean',
  'LineOptions\ttension\tnull',
  'LineOptions\ttension\tobject',
  'LineOptions\ttension\tstring',
  'LineOptions\ttension\tundefined',
  'PointOptions\tborderWidth\tarray',
  'PointOptions\tborderWidth\tboolean',
  'PointOptions\tborderWidth\tnull',
  'PointOptions\tborderWidth\tobject',
  'PointOptions\tborderWidth\tstring',
  'PointOptions\tborderWidth\tundefined',
  'PointOptions\thitRadius\tarray',
  'PointOptions\thitRadius\tboolean',
  'PointOptions\thitRadius\tnull',
  'PointOptions\thitRadius\tobject',
  'PointOptions\thitRadius\tstring',
  'PointOptions\thitRadius\tundefined',
  'PointOptions\thoverBorderWidth\tarray',
  'PointOptions\thoverBorderWidth\tboolean',
  'PointOptions\thoverBorderWidth\tnull',
  'PointOptions\thoverBorderWidth\tobject',
  'PointOptions\thoverBorderWidth\tstring',
  'PointOptions\thoverBorderWidth\tundefined',
  'PointOptions\thoverRadius\tarray',
  'PointOptions\thoverRadius\tboolean',
  'PointOptions\thoverRadius\tnull',
  'PointOptions\thoverRadius\tobject',
  'PointOptions\thoverRadius\tstring',
  'PointOptions\thoverRadius\tundefined',
  'PointOptions\tradius\tarray',
  'PointOptions\tradius\tboolean',
  'PointOptions\tradius\tfunction',
  'PointOptions\tradius\tnull',
  'PointOptions\tradius\tobject',
  'PointOptions\tradius\tstring',
  'PointOptions\tradius\tundefined',
  'PointOptions\trotation\tarray',
  'PointOptions\trotation\tboolean',
  'PointOptions\trotation\tnull',
  'PointOptions\trotation\tobject',
  'PointOptions\trotation\tstring',
  'PointOptions\trotation\tundefined',
  'PointOptionsScope\tradius\tstring',
  'ScaleOptionsByIdScope\tx\tstring',
  'TickOptionsScope\tmirror\tstring',
};
