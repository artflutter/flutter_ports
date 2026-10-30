// Original code, not ported from Chart.js: the base of the typed records.

/// The base of the typed records of Chart.js ADR 0054: a JS object with a
/// fixed set of typed fields, extras and the own-key order of JS.
///
/// A subclass declares its fields by slot ([TypedRecord.fieldNames], at
/// most 30) and keeps each value in a Dart field of its type. The base
/// keeps:
/// - the present bit of each field: a field that the object does not own is
///   absent, and a read by name gives [undefined] (the face) or Dart `null`
///   (the Map read);
/// - the foreign slot of each field: a write by name of a value outside the
///   type of the field keeps the raw value (Chart.js ADR 0054 §6), and the
///   subclass keeps the JS conversion in its field;
/// - the extras: the own keys that are not fields, with their values;
/// - the own-key order: the insertion order of the fields and the extras,
///   as JS keeps it. Up to 7 keys, the order is a sequence of 4-bit groups
///   in one `int` (28 bits, also on the web). More keys make a list.
///
/// The face ([JsObjectFace]) has the JS rules. During the migration a
/// record is also a `MapBase` (the scaffolding of Chart.js ADR 0054 §5):
/// the Map read gives Dart `null` for an absent key, and `keys` gives the
/// own keys in their insertion order.
///
/// This library is a pure layer.
library;

import 'dart:collection';

import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsArrayIndex;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show JsObjectFace;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:meta/meta.dart';

/// A JS object with typed fields (Chart.js ADR 0054). See the library
/// documentation.
abstract base class TypedRecord extends MapBase<String, Object?>
    implements JsObjectFace {
  /// The JS names of the fields, by slot. At most 30 names.
  @protected
  List<String> get fieldNames;

  /// The slot of the field [name], or -1 for a name that is not a field.
  @protected
  int slotOf(String name);

  /// The value of the field [slot]. The base calls it only for a present
  /// field without a foreign value.
  @protected
  Object? readSlot(int slot);

  /// Stores [value] into the field [slot]. Returns false when [value] is
  /// outside the type of the field: the subclass then keeps the JS
  /// conversion of [value] in its field, and the base keeps [value] in the
  /// foreign slot.
  @protected
  bool writeSlot(int slot, Object? value);

  /// Puts the field [slot] back to its absent value.
  @protected
  void clearSlot(int slot);

  /// The bits of the present fields.
  int _present = 0;

  /// The bits of the fields with a foreign value.
  int _foreign = 0;

  /// The foreign values, by slot.
  List<Object?>? _foreignValues;

  /// The key order as 4-bit groups: a slot + 1, or [_extraGroup] for the
  /// next extra.
  int _order = 0;

  /// The number of groups in [_order].
  int _count = 0;

  /// The key order when it does not fit into [_order].
  List<String>? _orderList;

  /// The names of the extras, in insertion order.
  List<String>? _extraNames;

  /// The values of the extras.
  List<Object?>? _extraValues;

  static const int _bits = 4;
  static const int _mask = 15;
  static const int _extraGroup = 15;
  static const int _maxGroups = 7;

  /// Whether the field [slot] is present.
  @protected
  bool hasSlot(int slot) => _present & (1 << slot) != 0;

  /// Whether the field [slot] has a foreign value.
  bool isForeignSlot(int slot) => _foreign & (1 << slot) != 0;

  /// The foreign value of the field [slot], or Dart `null`.
  Object? foreignSlot(int slot) =>
      isForeignSlot(slot) ? _foreignValues![slot] : null;

  /// Marks the field [slot] present after a typed store of a subclass: a
  /// new key goes to the end of the key order, and a foreign value goes.
  @protected
  void touchSlot(int slot) {
    final bit = 1 << slot;
    if (_foreign & bit != 0) {
      _foreign &= ~bit;
      _foreignValues![slot] = null;
    }
    if (_present & bit != 0) return;
    _present |= bit;
    _append(slot + 1, fieldNames[slot]);
  }

  /// Marks the field [slot] absent after a subclass reset its field.
  @protected
  void untouchSlot(int slot) {
    final bit = 1 << slot;
    if (_present & bit == 0) return;
    _present &= ~bit;
    if (_foreign & bit != 0) {
      _foreign &= ~bit;
      _foreignValues![slot] = null;
    }
    _removeFromOrder(fieldNames[slot], slot + 1, -1);
  }

  /// The write by name into the field [slot].
  void _storeSlot(int slot, Object? value) {
    final bit = 1 << slot;
    if (writeSlot(slot, value)) {
      if (_foreign & bit != 0) {
        _foreign &= ~bit;
        _foreignValues![slot] = null;
      }
    } else {
      _foreign |= bit;
      (_foreignValues ??= List<Object?>.filled(fieldNames.length, null))[slot] =
          value;
    }
    if (_present & bit == 0) {
      _present |= bit;
      _append(slot + 1, fieldNames[slot]);
    }
  }

  /// Appends the key [name] with its [group] to the key order.
  void _append(int group, String name) {
    final list = _orderList;
    if (list != null) {
      list.add(name);
    } else if (_count < _maxGroups) {
      _order |= group << (_bits * _count);
      _count++;
    } else {
      _orderList = _decode()..add(name);
    }
  }

  /// Removes the key [name] from the key order: the field group [group], or
  /// the extra at [extraIndex] of the extras.
  void _removeFromOrder(String name, int group, int extraIndex) {
    final list = _orderList;
    if (list != null) {
      list.remove(name);
      return;
    }
    var extra = 0;
    for (var p = 0; p < _count; p++) {
      final g = (_order >> (_bits * p)) & _mask;
      final bool match;
      if (g == _extraGroup) {
        match = group == _extraGroup && extra == extraIndex;
        extra++;
      } else {
        match = g == group;
      }
      if (match) {
        final low = _order & ((1 << (_bits * p)) - 1);
        final high = _order >> (_bits * (p + 1));
        _order = low | (high << (_bits * p));
        _count--;
        return;
      }
    }
  }

  /// The own keys in their insertion order.
  List<String> _decode() {
    final list = _orderList;
    if (list != null) return List<String>.of(list);
    final names = fieldNames;
    final out = <String>[];
    var extra = 0;
    for (var p = 0; p < _count; p++) {
      final g = (_order >> (_bits * p)) & _mask;
      out.add(g == _extraGroup ? _extraNames![extra++] : names[g - 1]);
    }
    return out;
  }

  /// The own value of [name], or [undefined].
  Object? _own(String name) {
    final slot = slotOf(name);
    if (slot >= 0) {
      final bit = 1 << slot;
      if (_present & bit == 0) return undefined;
      return _foreign & bit != 0 ? _foreignValues![slot] : readSlot(slot);
    }
    final index = _extraNames?.indexOf(name) ?? -1;
    return index < 0 ? undefined : _extraValues![index];
  }

  // The Map protocol (the scaffolding of Chart.js ADR 0054 §5).

  @override
  Object? operator [](Object? key) {
    if (key is! String) return null;
    final value = _own(key);
    return identical(value, undefined) && !containsKey(key) ? null : value;
  }

  @override
  void operator []=(String key, Object? value) {
    final slot = slotOf(key);
    if (slot >= 0) {
      _storeSlot(slot, value);
      return;
    }
    final names = _extraNames ??= <String>[];
    final values = _extraValues ??= <Object?>[];
    final index = names.indexOf(key);
    if (index >= 0) {
      values[index] = value;
      return;
    }
    names.add(key);
    values.add(value);
    _append(_extraGroup, key);
  }

  @override
  bool containsKey(Object? key) {
    if (key is! String) return false;
    final slot = slotOf(key);
    if (slot >= 0) return _present & (1 << slot) != 0;
    return _extraNames?.contains(key) ?? false;
  }

  @override
  Iterable<String> get keys => _decode();

  @override
  int get length => _orderList?.length ?? _count;

  @override
  Object? remove(Object? key) {
    if (key is! String) return null;
    final slot = slotOf(key);
    if (slot >= 0) {
      if (!hasSlot(slot)) return null;
      final value = _own(key);
      clearSlot(slot);
      untouchSlot(slot);
      return value;
    }
    final names = _extraNames;
    if (names == null) return null;
    final index = names.indexOf(key);
    if (index < 0) return null;
    final value = _extraValues![index];
    _removeFromOrder(key, _extraGroup, index);
    names.removeAt(index);
    _extraValues!.removeAt(index);
    return value;
  }

  @override
  void clear() => _decode().forEach(remove);

  // The face of Chart.js ADR 0054 §5.

  @override
  Object? jsRead(String name) => _own(name);

  @override
  void jsWrite(String name, Object? value) => this[name] = value;

  @override
  List<String> jsKeys() {
    final keys = _decode();
    if (!keys.any((name) => jsArrayIndex(name) != null)) return keys;
    // The indices are distinct integers: an unstable sort gives one order.
    final indices =
        [
            for (final name in keys)
              if (jsArrayIndex(name) case final int index) (index, name),
          ]
          // js-ok: distinct keys, as jsObjectKeys sorts them
          ..sort((a, b) => a.$1.compareTo(b.$1));
    return [
      for (final (_, name) in indices) name,
      for (final name in keys)
        if (jsArrayIndex(name) == null) name,
    ];
  }

  @override
  bool jsHas(String name) => containsKey(name);

  @override
  bool jsDelete(String name) {
    if (!containsKey(name)) return false;
    remove(name);
    return true;
  }
}
