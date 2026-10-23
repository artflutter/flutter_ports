// Original code, not ported from Chart.js: the JS undefined value.

/// The JavaScript value `undefined` for ported code (Chart.js ADR 0043, "The
/// sentinel").
///
/// A JavaScript object is a `Map<String, Object?>` in the port. A key of it
/// has one of three states, and ported code keeps them apart:
/// - an absent key: the object has no own property. `map.containsKey(key)` is
///   false, and `map[key]` is Dart `null`.
/// - the sentinel: the object owns the property, and its value is
///   `undefined`. `identical(map[key], undefined)` is true.
/// - Dart `null`: the object owns the property, and its value is JS `null`.
///   `map.containsKey(key)` is true, and `map[key]` is `null`.
///
/// A read of the value treats an absent key and the sentinel alike, as
/// JavaScript does. `_mergerIf`, `_cached` and `Object.keys` test own-key
/// presence, so they see the sentinel and not an absent key
/// (Chart.js ADR 0043, "Resolver rule").
///
/// Ported code tests for the sentinel with `identical(value, undefined)`.
library;

/// The type of the JavaScript value [undefined]. Its only instance is
/// [undefined].
final class Undefined {
  const Undefined._();

  /// `String(undefined)`: `'undefined'`.
  @override
  String toString() => 'undefined';
}

/// JavaScript `undefined`, stored as a value: an own property whose value is
/// `undefined`, for example `pointStyle: undefined` at `element.bar.js:153`.
///
/// Compare with `identical(value, undefined)`.
const Undefined undefined = Undefined._();
