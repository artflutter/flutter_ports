// Original code, not ported from Chart.js: own keys of a test object.

/// `key in object` and `delete object[key]` for the observations of the
/// tests, on a `Map` or a typed object with a face (Chart.js ADR 0175).
library;

import 'package:flutter_chartjs_port/src/js/js_object.dart' show JsObjectFace;

/// Whether [object] has the own key [key]: a `Map` key or a key of the face.
bool hasOwnKey(Object? object, String key) => switch (object) {
  final JsObjectFace face => face.jsHas(key),
  final Map<Object?, Object?> map => map.containsKey(key),
  _ => false,
};

/// Removes the own key [key] of [object] and gives whether [object] had it.
/// A typed object can throw the `TypeError` of a frozen object.
bool deleteOwnKey(Object? object, String key) {
  switch (object) {
    case final JsObjectFace face:
      return face.jsDelete(key);
    case final Map<Object?, Object?> map:
      final had = map.containsKey(key);
      map.remove(key);
      return had;
  }
  return false;
}
