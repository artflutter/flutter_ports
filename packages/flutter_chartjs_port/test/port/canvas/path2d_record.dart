// Original code, not ported from Chart.js: the record form of Path2D arguments.

/// The record form of a `Path2D` argument of a recorded call: the form of
/// the reference generators (`jsonValue` of
/// `tool/reference/scale_chart_common.mjs`, and
/// `tool/reference/line_reference.mjs`).
///
/// A `Path2D` argument becomes `{'path': id, 'calls': [...]}`: the id of the
/// path in its record (1 for the first path, in the order of the first
/// sight) and the calls of its commands on a mock context.
///
/// This library is a helper of the tests, not a test file. It imports only
/// pure layers and `package:chartjs_test_utils/pure.dart`. Thus a pure test
/// can import it.
library;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';

/// The ids of the Path2D objects of one record, in the order of the first
/// sight, as the generators number them.
final class PathIds {
  final Map<Path2D, int> _ids = {};

  /// The id of [path], or null for no path. A path that this object has not
  /// seen gets the next id.
  int? of(Path2D? path) =>
      path == null ? null : _ids.putIfAbsent(path, () => _ids.length + 1);
}

/// The recorded calls [calls] with each Path2D argument as
/// `{'path': id, 'calls': [...]}`, the form of the generators. Each call is
/// `{'name': name, 'args': [...]}`, as a [ContextCall].
///
/// [ids] numbers the paths. Give the same [ids] to the calls of one record.
/// Without [ids], the paths of [calls] get the ids from 1.
List<Object?> recordedCalls(List<ContextCall> calls, [PathIds? ids]) {
  final pathIds = ids ?? PathIds();
  return [
    for (final call in calls)
      <String, Object?>{
        'name': call['name'],
        'args': [
          for (final arg in call['args']! as List<Object?>)
            _recorded(arg, pathIds),
        ],
      },
  ];
}

/// A recorded argument [value] with each Path2D as its id and its commands.
Object? _recorded(Object? value, PathIds ids) => switch (value) {
  final Path2D path => <String, Object?>{
    'path': ids.of(path),
    'calls': recordedCalls(replayPath(path), ids),
  },
  final List<Object?> list => [for (final item in list) _recorded(item, ids)],
  _ => value,
};

/// The calls of the commands of [path] on a new mock context.
List<ContextCall> replayPath(Path2D path) {
  final ctx = createMockContext();
  path.replay(ctx);
  return ctx.getCalls();
}
