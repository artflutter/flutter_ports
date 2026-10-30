// Original code, not ported from Chart.js: the hook of the oracle O2.

/// The hook of the foreign-value audit, the oracle O2 of Chart.js ADR 0054.
///
/// A typed option object keeps a value outside the type of its key in a
/// foreign slot (Chart.js ADR 0054 §6): an `OptForeign` cell of a typed
/// scope, or the foreign bit of a resolved element options class. Each
/// store of a foreign value calls [auditForeign] inside `assert`. Thus a
/// release build has no call. The tests set [foreignAudit]: the test config
/// of the package counts each (owner, key, kind) of the suites and fails a
/// test file on a pair that `test/port/options/foreign_audit.dart` does not
/// list.
///
/// This library is a pure layer.
library;

import 'package:meta/meta.dart';

/// The function that receives each foreign value: the owner (the Dart name
/// of a scope class or of a resolved options class), the JS property name
/// and the raw value. Dart `null` turns the audit off.
@internal
void Function(String owner, String key, Object? raw)? foreignAudit;

/// Gives the foreign value [raw] of the key [key] of [owner] to
/// [foreignAudit]. Returns true, for a call inside `assert`.
@internal
bool auditForeign(String owner, String key, Object? raw) {
  foreignAudit?.call(owner, key, raw);
  return true;
}
