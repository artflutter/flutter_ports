// Original code, not ported from Chart.js: a table zone for the date tests.

/// A [DateZone] from a table of offset changes, for the local cases of the
/// default date adapter (Chart.js ADR 0024, decision 9).
///
/// The tool `tool/reference/date_adapter_reference.mjs` writes the offset
/// changes of three zones of the tz data of Node.js. The local cases run
/// through this zone, so that they give the same results on each machine
/// and each compiler. [TableZone.fromWall] applies the rule of JS `Date`
/// without the cache rule of `LocalZone`. Thus the tests of the calendar do
/// not depend on the cache.
library;

import 'package:flutter_chartjs_port/src/core/date_zone.dart';

import 'date_adapter_reference.dart';

/// One day in ms.
const int _day = 86400000;

/// A zone with the offsets of a table.
final class TableZone implements DateZone {
  /// A zone with the offset [initialOffset] before the first change, and
  /// the offset `offsets[i]` from the instant `changes[i]` on.
  TableZone(this.initialOffset, this.changes, this.offsets);

  /// The zone of the reference data [zone].
  TableZone.of(DateReferenceZone zone)
    : this(zone.initialOffset, zone.changes, zone.offsets);

  /// The offset before the first change, in ms.
  final int initialOffset;

  /// The instants of the offset changes, in increasing order.
  final List<int> changes;

  /// The offset from each change on, in ms.
  final List<int> offsets;

  /// The number of changes at or before [t].
  int _changesUpTo(int t) {
    var low = 0;
    var high = changes.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (changes[middle] <= t) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  @override
  int offsetAt(int t) {
    final count = _changesUpTo(t);
    return count == 0 ? initialOffset : offsets[count - 1];
  }

  /// The instant of the wall time [wall]: the earliest instant `t` with
  /// `t + offsetAt(t) == wall`. A skipped wall time uses the offset before
  /// the change. This is the rule of JS `Date` (ECMAScript `UTC(t)`).
  @override
  int fromWall(int wall) {
    // Each offset is less than one day. Thus each instant of the wall time
    // is in the two days around it.
    final first = _changesUpTo(wall - 2 * _day);
    final last = _changesUpTo(wall + 2 * _day);
    final candidates = {
      offsetAt(wall - 2 * _day),
      for (var i = first; i < last; i++) offsets[i],
    };
    int? earliest;
    for (final offset in candidates) {
      final t = wall - offset;
      if (offsetAt(t) == offset && (earliest == null || t < earliest)) {
        earliest = t;
      }
    }
    if (earliest != null) return earliest;
    for (var i = first; i < last; i++) {
      final before = i == 0 ? initialOffset : offsets[i - 1];
      final after = offsets[i];
      if (wall - before >= changes[i] && wall - after < changes[i]) {
        return wall - before;
      }
    }
    return wall - offsetAt(wall);
  }
}
