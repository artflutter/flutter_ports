// Original code, not ported from Chart.js: JS Map iteration as in ECMAScript.

/// `Map.prototype.forEach` for ported code that iterates a JavaScript `Map`
/// while its callback changes it (Chart.js ADR 0019, section 8).
///
/// A JavaScript `Map` is a Dart `Map`. Both keep the insertion order. A Dart
/// `Map.forEach` throws a `ConcurrentModificationError` when its callback
/// adds or removes a key. The ECMAScript `forEach` continues: it visits a
/// key that the callback adds, and it skips a key that the callback deletes
/// before its visit. The animator needs this rule (`core.animator.js:60`): a
/// listener can destroy a chart or start a new chart.
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

/// `map.forEach(callback)`: calls [callback] with the value and the key of
/// each entry of [map], in insertion order (ECMAScript 24.1.3.5).
///
/// The function takes the list of the keys first. It calls [callback] with
/// the current value of each key that [map] still contains. Then it repeats
/// with the keys that it did not visit, until no such key exists. Thus:
/// - a key that [callback] adds gets its visit after the keys before it, as
///   in ECMAScript;
/// - a key that [callback] deletes before its visit gets no visit, as in
///   ECMAScript;
/// - a key that [callback] changes gets its visit with the new value, as in
///   ECMAScript.
///
/// Two rare cases differ from ECMAScript. No Chart.js code reaches them:
/// - A key that [callback] deletes and adds again after its visit gets no
///   second visit. ECMAScript gives it a second visit.
/// - A key that [callback] deletes and adds again before its visit gets its
///   visit at its old place. ECMAScript visits it at its new place, at the
///   end.
///
/// The visited keys are in a `Set` with the default equality. Thus [map]
/// must compare its keys with `==` and `hashCode`, as a default `Map` does.
/// This function translates a JS builtin. It is not a `DIVERGES` hunk.
void jsMapForEach<K, V>(Map<K, V> map, void Function(V value, K key) callback) {
  var keys = map.keys.toList(growable: false);
  final visited = <K>{};
  while (keys.isNotEmpty) {
    for (final key in keys) {
      // A key that the callback deleted before its visit.
      if (!map.containsKey(key)) continue;
      visited.add(key);
      callback(map[key] as V, key);
    }
    // The keys that the callback added.
    keys = [
      for (final key in map.keys)
        if (!visited.contains(key)) key,
    ];
  }
}
