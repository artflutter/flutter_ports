// Original code, not ported from Chart.js: the typed parsed items.

/// The typed parsed data of Chart.js ADR 0054 §8: [ParsedItem], its
/// `_stacks` ([ItemStacks]), the stack objects of `getOrCreateStack`
/// ([StackEntry], [IndexValues]), the `_custom` of a floating bar
/// ([FloatingBar]). The axis of the hot read is a [ScaleAxis]: each read
/// takes the field of its axis by pattern matching.
///
/// The types replace the plain objects of the parse functions of
/// `core.datasetController.js` and the controllers (lane L1). Each one is a
/// [TypedRecord]: typed fields, extras for the keys that user code writes,
/// the own-key order of JS and the face. None is a `Map` (Chart.js ADR
/// 0054 §5).
///
/// This library is a pure layer.
library;

import 'dart:collection' show SplayTreeMap;

import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsArrayIndex;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsToNumber;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show JsObjectFace;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/typed_record.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';

/// One parsed item of a dataset (U `core.datasetController.js:502-578`):
/// the object that `getParsed(index)` gives each time, and that a
/// scriptable option can write into (`ctx.parsed`).
///
/// The fields are `x`, `y` and `r` (`Object?`: the type of a parse result
/// is `unknown`, U `index.d.ts:1385`), `_custom` ([custom]: a number for a
/// bubble, a [FloatingBar] for a floating bar) and `_stacks` ([stacks]).
/// A typed getter gives [undefined] for an absent field. Another key is an
/// extra.
final class ParsedItem extends TypedRecord {
  /// An item without own keys.
  new();

  /// The item `{[a]: aValue, [b]: bValue}` of the parse functions, in this
  /// key order (`{[iAxis]: ..., [vAxis]: ...}`). Two equal axes are one key
  /// with the second value. The axes [XAxis], [YAxis] and [RAxis] write
  /// their fields at once. Another axis class has no field: its value goes
  /// (row `adapt-axis-objects`).
  new of(ScaleAxis a, Object? aValue, ScaleAxis b, Object? bValue) {
    final aSlot = _axisSlot(a);
    final bSlot = _axisSlot(b);
    if (aSlot < 0 || bSlot < 0) {
      setValue(a, aValue);
      setValue(b, bValue);
      return;
    }
    _setAxisField(a, aValue);
    _setAxisField(b, bValue);
    initializeTwoSlots(aSlot, bSlot);
  }

  /// The slot of the field of [axis], or -1 for an axis class with no field.
  static int _axisSlot(ScaleAxis axis) => switch (axis) {
    XAxis() => 0,
    YAxis() => 1,
    RAxis() => 2,
    _ => -1,
  };

  static const List<String> _fieldNames = ['x', 'y', 'r', '_custom', '_stacks'];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'x' => 0,
    'y' => 1,
    'r' => 2,
    '_custom' => 3,
    '_stacks' => 4,
    _ => -1,
  };

  Object? _x;
  Object? _y;
  Object? _r;
  Object? _custom;
  ItemStacks? _stacks;

  /// `x`, or [undefined] when absent.
  Object? get x => hasSlot(0) ? _x : undefined;

  set x(Object? value) {
    _x = value;
    touchSlot(0);
  }

  /// `y`, or [undefined] when absent.
  Object? get y => hasSlot(1) ? _y : undefined;

  set y(Object? value) {
    _y = value;
    touchSlot(1);
  }

  /// `r`, or [undefined] when absent.
  Object? get r => hasSlot(2) ? _r : undefined;

  set r(Object? value) {
    _r = value;
    touchSlot(2);
  }

  /// `_custom`, or [undefined] when absent.
  Object? get custom => hasSlot(3) ? _custom : undefined;

  set custom(Object? value) {
    _custom = value;
    touchSlot(3);
  }

  /// `_stacks` when it is an [ItemStacks], else Dart `null`.
  ItemStacks? get stacks => hasSlot(4) && !isForeignSlot(4) ? _stacks : null;

  set stacks(ItemStacks? value) {
    _stacks = value;
    touchSlot(4);
  }

  /// The field of the axis [axis], with no change of the own keys.
  void _setAxisField(ScaleAxis axis, Object? value) {
    switch (axis) {
      case XAxis():
        _x = value;
      case YAxis():
        _y = value;
      case RAxis():
        _r = value;
    }
  }

  /// The value of the axis [axis]: `item[axis]`. An axis class with no field
  /// gives [undefined].
  Object? valueOf(ScaleAxis axis) => switch (axis) {
    XAxis() => x,
    YAxis() => y,
    RAxis() => r,
    _ => undefined,
  };

  /// `item[axis] = value`. An axis class with no field takes no write.
  void setValue(ScaleAxis axis, Object? value) {
    switch (axis) {
      case XAxis():
        x = value;
      case YAxis():
        y = value;
      case RAxis():
        r = value;
    }
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _x,
    1 => _y,
    2 => _r,
    3 => _custom,
    _ => _stacks,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0:
        _x = value;
      case 1:
        _y = value;
      case 2:
        _r = value;
      case 3:
        _custom = value;
      default:
        if (value is ItemStacks?) {
          _stacks = value;
        } else {
          _stacks = null;
          return false;
        }
    }
    return true;
  }

  @override
  void clearSlot(int slot) => writeSlot(slot, null);
}

/// `item._stacks` (U `core.datasetController.js:152-175`): the stack
/// object of each value axis of the item, by axis name. The axes `x`, `y`
/// and `r` are fields; another axis name is an extra.
final class ItemStacks() extends TypedRecord {
  /// An object without own keys.
  this;

  static const List<String> _fieldNames = ['x', 'y', 'r'];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'x' => 0,
    'y' => 1,
    'r' => 2,
    _ => -1,
  };

  final List<StackEntry?> _entries = List<StackEntry?>.filled(3, null);

  /// The stack object of the axis [axis], or Dart `null`. An axis class
  /// with no field gives Dart `null`.
  StackEntry? entryOf(ScaleAxis axis) {
    final slot = ParsedItem._axisSlot(axis);
    if (slot < 0) return null;
    return hasSlot(slot) && !isForeignSlot(slot) ? _entries[slot] : null;
  }

  /// `item._stacks[axis] = entry`. An axis class with no field takes no
  /// write.
  void setEntry(ScaleAxis axis, StackEntry entry) {
    final slot = ParsedItem._axisSlot(axis);
    if (slot < 0) return;
    _entries[slot] = entry;
    touchSlot(slot);
  }

  @override
  Object? readSlot(int slot) => _entries[slot];

  @override
  bool writeSlot(int slot, Object? value) {
    if (value is StackEntry?) {
      _entries[slot] = value;
      return true;
    }
    _entries[slot] = null;
    return false;
  }

  @override
  void clearSlot(int slot) => _entries[slot] = null;
}

/// The stack object of `getOrCreateStack` (U
/// `core.datasetController.js:136-139`): the value of each dataset index
/// ([datasetValues]), `_top` ([top]), `_bottom` ([bottom]) and
/// `_visualValues` ([visualValues]).
///
/// A name that is a canonical array index is a dataset index: it reads and
/// writes [datasetValues]. `Object.keys` gives the indices first, in
/// ascending order, as JS does.
final class StackEntry() extends TypedRecord {
  /// An object without own keys.
  this;

  /// The value of each dataset index (`stack[datasetIndex]`).
  final IndexValues datasetValues = IndexValues();

  static const List<String> _fieldNames = ['_top', '_bottom', '_visualValues'];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    '_top' => 0,
    '_bottom' => 1,
    '_visualValues' => 2,
    _ => -1,
  };

  int? _top;
  int? _bottom;
  IndexValues? _visualValues;

  /// `_top`: the index of the last dataset with a positive value, or Dart
  /// `null` for JS `null` and for an absent key.
  int? get top => hasSlot(0) && !isForeignSlot(0) ? _top : null;

  set top(int? value) {
    _top = value;
    touchSlot(0);
  }

  /// `_bottom`: the index of the last dataset with a negative value, as
  /// [top].
  int? get bottom => hasSlot(1) && !isForeignSlot(1) ? _bottom : null;

  set bottom(int? value) {
    _bottom = value;
    touchSlot(1);
  }

  /// `_visualValues`, or Dart `null`.
  IndexValues? get visualValues =>
      hasSlot(2) && !isForeignSlot(2) ? _visualValues : null;

  set visualValues(IndexValues? value) {
    _visualValues = value;
    touchSlot(2);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _top,
    1 => _bottom,
    _ => _visualValues,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 0 || 1:
        // An index is an int. Another value of user code is a foreign value.
        final int? number;
        final bool typed;
        if (value == null) {
          number = null;
          typed = true;
        } else if (value is num &&
            value.isFinite &&
            value == value.truncateToDouble()) {
          number = value.toInt();
          typed = true;
        } else {
          number = null;
          typed = false;
        }
        if (slot == 0) {
          _top = number;
        } else {
          _bottom = number;
        }
        return typed;
      default:
        if (value is IndexValues?) {
          _visualValues = value;
          return true;
        }
        _visualValues = null;
        return false;
    }
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 0:
        _top = null;
      case 1:
        _bottom = null;
      default:
        _visualValues = null;
    }
  }

  @override
  Object? jsRead(String name) => jsArrayIndex(name) != null
      ? datasetValues.jsRead(name)
      : super.jsRead(name);

  @override
  void jsWrite(String name, Object? value) {
    if (jsArrayIndex(name) != null) {
      datasetValues.jsWrite(name, value);
    } else {
      super.jsWrite(name, value);
    }
  }

  @override
  Object? operator [](String name) => jsRead(name);

  @override
  void operator []=(String name, Object? value) => jsWrite(name, value);

  @override
  bool jsHas(String name) => jsArrayIndex(name) != null
      ? datasetValues.jsHas(name)
      : super.jsHas(name);

  @override
  bool jsDelete(String name) => jsArrayIndex(name) != null
      ? datasetValues.jsDelete(name)
      : super.jsDelete(name);

  @override
  List<String> jsKeys() => [...datasetValues.jsKeys(), ...super.jsKeys()];

  @override
  String keyAt(int position) => jsKeys()[position];

  @override
  int slotAt(int position) => slotOf(keyAt(position));
}

/// A JS object whose keys are canonical array indices, for example the
/// values of a stack by dataset index (`stack[datasetIndex]`,
/// `_visualValues`). The values are by `int` index. `Object.keys` gives the
/// indices in ascending order. A key that is not an index is an extra
/// after them.
final class IndexValues() implements JsObjectFace {
  /// An object without own keys.
  this;

  final SplayTreeMap<int, Object?> _values = SplayTreeMap<int, Object?>();

  Map<String, Object?>? _named;

  /// Whether the object owns the index [index].
  bool hasIndex(int index) => _values.containsKey(index);

  /// `object[index]`, or [undefined] when absent.
  Object? valueAt(int index) =>
      _values.containsKey(index) ? _values[index] : undefined;

  /// `object[index] = value`.
  void setAt(int index, Object? value) => _values[index] = value;

  /// `delete object[index]`. Returns whether the object owned [index].
  bool removeAt(int index) {
    if (!_values.containsKey(index)) return false;
    _values.remove(index);
    return true;
  }

  /// The owned indices in ascending order.
  Iterable<int> get indices => _values.keys;

  /// The count of the own keys.
  int get ownKeyCount => _values.length + (_named?.length ?? 0);

  @override
  Object? jsRead(String name) {
    final index = jsArrayIndex(name);
    if (index != null) return valueAt(index);
    final named = _named;
    return named != null && named.containsKey(name) ? named[name] : undefined;
  }

  @override
  void jsWrite(String name, Object? value) {
    final index = jsArrayIndex(name);
    if (index != null) {
      _values[index] = value;
    } else {
      (_named ??= <String, Object?>{})[name] = value;
    }
  }

  @override
  Object? operator [](String name) => jsRead(name);

  @override
  void operator []=(String name, Object? value) => jsWrite(name, value);

  @override
  List<String> jsKeys() => [
    for (final index in _values.keys) '$index',
    ...?_named?.keys,
  ];

  @override
  bool jsHas(String name) {
    final index = jsArrayIndex(name);
    return index != null
        ? _values.containsKey(index)
        : (_named?.containsKey(name) ?? false);
  }

  @override
  bool jsDelete(String name) {
    if (!jsHas(name)) return false;
    final index = jsArrayIndex(name);
    if (index != null) {
      _values.remove(index);
    } else {
      _named!.remove(name);
    }
    return true;
  }
}

/// `item._custom` of a floating bar (U `controller.bar.js:117-142`):
/// `{barStart, barEnd, start, end, min, max}` in this key order.
final class FloatingBar({
  required double barStart,
  required double barEnd,
  required Object? start,
  required Object? end,
  required double min,
  required double max,
}) extends TypedRecord {
  /// The object of `parseFloatBar`.
  this {
    this
      ..barStart = barStart
      ..barEnd = barEnd
      ..start = start
      ..end = end
      ..min = min
      ..max = max;
  }

  static const List<String> _fieldNames = [
    'barStart',
    'barEnd',
    'start',
    'end',
    'min',
    'max',
  ];

  @override
  List<String> get fieldNames => _fieldNames;

  @override
  int slotOf(String name) => switch (name) {
    'barStart' => 0,
    'barEnd' => 1,
    'start' => 2,
    'end' => 3,
    'min' => 4,
    'max' => 5,
    _ => -1,
  };

  double _barStart = double.nan;
  double _barEnd = double.nan;
  Object? _start;
  Object? _end;
  double _min = double.nan;
  double _max = double.nan;

  /// `barStart`: NaN when absent.
  double get barStart => _barStart;

  set barStart(double value) {
    _barStart = value;
    touchSlot(0);
  }

  /// `barEnd`: NaN when absent.
  double get barEnd => _barEnd;

  set barEnd(double value) {
    _barEnd = value;
    touchSlot(1);
  }

  /// `start`, or [undefined] when absent.
  Object? get start => hasSlot(2) ? _start : undefined;

  set start(Object? value) {
    _start = value;
    touchSlot(2);
  }

  /// `end`, or [undefined] when absent.
  Object? get end => hasSlot(3) ? _end : undefined;

  set end(Object? value) {
    _end = value;
    touchSlot(3);
  }

  /// `min`: NaN when absent.
  double get min => _min;

  set min(double value) {
    _min = value;
    touchSlot(4);
  }

  /// `max`: NaN when absent.
  double get max => _max;

  set max(double value) {
    _max = value;
    touchSlot(5);
  }

  @override
  Object? readSlot(int slot) => switch (slot) {
    0 => _barStart,
    1 => _barEnd,
    2 => _start,
    3 => _end,
    4 => _min,
    _ => _max,
  };

  @override
  bool writeSlot(int slot, Object? value) {
    switch (slot) {
      case 2:
        _start = value;
        return true;
      case 3:
        _end = value;
        return true;
    }
    final number = value is num ? value.toDouble() : jsToNumber(value);
    switch (slot) {
      case 0:
        _barStart = number;
      case 1:
        _barEnd = number;
      case 4:
        _min = number;
      default:
        _max = number;
    }
    return value is num;
  }

  @override
  void clearSlot(int slot) {
    switch (slot) {
      case 2:
        _start = null;
      case 3:
        _end = null;
      default:
        writeSlot(slot, double.nan);
    }
  }
}
