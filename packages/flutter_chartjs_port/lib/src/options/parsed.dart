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

import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:meta/meta.dart';

/// The object form of the option `parsing` of a dataset controller
/// (U `core.datasetController.js:443`): the keys that the parse functions
/// read in a data item. The value `parsing: false` is Dart `null` in place
/// of an object, and `parsing: true` is `const ParsingKeys()`.
///
/// A null key takes the default of its reader: `'x'` and `'y'` for the
/// object parse (U `core.datasetController.js:561`, `controller.bar.js:326`),
/// `'value'` for the doughnut (U `controller.doughnut.js:158`) and `'r'` for
/// the radial parse (U `helpers.config.ts:444`).
///
/// ```dart
/// final keys = ParsingKeys(xAxisKey: 'time', yAxisKey: 'value');
/// ```
@immutable
final class const ParsingKeys({
  /// `xAxisKey`: the key of the x value, or Dart `null` for `'x'`.
  final String? xAxisKey,

  /// `yAxisKey`: the key of the y value, or Dart `null` for `'y'`.
  final String? yAxisKey,

  /// `key`: the key of the one value of a doughnut, pie, polar area or
  /// radar item, or Dart `null` for the default of the controller.
  final String? key,
}) {
  /// Creates the keys.
  this;

  /// The keys of the resolved option `parsing` [value]: Dart `null` for
  /// `false`, the default keys for `true` and [undefined], and the string
  /// keys of an object. A key that is not a string stops a debug build, and
  /// a release build takes the default key.
  static ParsingKeys? of(Object? value) {
    if (value == false) return null;
    if (value == null || value is bool || value is Undefined) {
      return const ParsingKeys();
    }
    if (value is ParsingKeys) return value;
    String? keyOf(OptionKey key) {
      final read = readOption(value, key);
      if (read is String) return read;
      assert(
        read == null || read is Undefined,
        'The parsing key ${key.name} takes a String, not $read.',
      );
      return null;
    }

    return ParsingKeys(
      xAxisKey: keyOf(OptionKey.xAxisKey),
      yAxisKey: keyOf(OptionKey.yAxisKey),
      key: keyOf(OptionKey.key),
    );
  }

  /// Whether each key takes the default of its reader.
  bool get isDefault => xAxisKey == null && yAxisKey == null && key == null;

  @override
  bool operator ==(Object other) =>
      other is ParsingKeys &&
      other.xAxisKey == xAxisKey &&
      other.yAxisKey == yAxisKey &&
      other.key == key;

  @override
  int get hashCode => Object.hash(xAxisKey, yAxisKey, key);
}

/// The parsed items of the data [data] of `parsing: false`
/// (U `core.datasetController.js:461`, `controller.doughnut.js:153`): the data
/// List itself when it is a List of [ParsedItem] (for example a
/// `List<DataPoint>`), else a List of the same items.
///
/// Upstream takes any data items there. In the port, each data item of
/// `parsing: false` is a [ParsedItem] (row `adapt-parsed-data-items`):
/// another item stops a debug build, and a release build takes an empty
/// item, which has no value.
List<ParsedItem?> parsedDataItems(Object? data) {
  if (data is List<ParsedItem?>) return data;
  final items = data! as List<Object?>;
  return [
    for (final item in items)
      if (item is ParsedItem?) item else _foreignDataItem(item),
  ];
}

/// `meta._parsed[index]` of a controller that parses one number for each
/// item, the doughnut and the pie (U `controller.doughnut.js:153-165`): the
/// [ParsedItem.r] of the item, or [undefined] for an index that names no
/// parsed item and for a hole (row `adapt-parsed-data-items`).
Object? parsedNumberOf(List<ParsedItem?> parsed, int index) {
  final item = index >= 0 && index < parsed.length ? parsed[index] : null;
  return item == null ? undefined : item.r;
}

/// The parsed item of a data item [item] of `parsing: false` that is not a
/// [ParsedItem]: a debug build stops, and a release build takes an empty
/// item.
ParsedItem _foreignDataItem(Object? item) {
  assert(
    false,
    'With parsing: false, each data item is a ParsedItem (for example a '
    'DataPoint), not $item.',
  );
  return ParsedItem();
}

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

/// A data item in the object form `{x, y}` or `{x, y, r}`
/// (`docs/general/data-structures.md`, "Object[]"), for the typed API and
/// for `parsing: false`.
///
/// A data point is a [ParsedItem]: the chart reads its fields where Chart.js
/// reads the keys of the object `{x, y}`. Thus a `List<DataPoint>` goes to
/// the chart with no copy, also as the parsed items of `parsing: false`. A
/// data point does not implement `Map`.
///
/// A number is a `double`, as each number of Chart.js. A `null` [y] is a
/// gap in the line. A bubble keeps its radius in [r], for the parse, and in
/// [custom], the parsed form `_custom` of `parsing: false`.
///
/// ```dart
/// final points = [DataPoint(1, 2), DataPoint(2, null), DataPoint(3, 4)];
/// final bubble = DataPoint.bubble(1, 2, 8);
/// ```
final class DataPoint extends ParsedItem {
  /// `{x, y}` with a number [x]: a value of a linear or a logarithmic x
  /// axis, or an index of a category x axis.
  new(num x, num? y) : super() {
    this
      ..x = _double(x)
      ..y = y == null ? null : _double(y);
  }

  /// `{x, y}` with a time [x], for a time or a time series x axis.
  new time(DateTime x, num? y) : super() {
    this
      ..x = x
      ..y = y == null ? null : _double(y);
  }

  /// `{x, y}` with a label [x], for a category x axis. A label that is not
  /// in the labels of the chart becomes a new label: the category scale adds
  /// it to `data.labels`.
  new label(String x, num? y) : super() {
    this
      ..x = x
      ..y = y == null ? null : _double(y);
  }

  /// `{x, y, r}`: a bubble at ([x], [y]) with the radius [r] in pixels. The
  /// radius is also `_custom`, the parsed radius of a bubble.
  // DIVERGES(chartjs): adapt-bubble-typed-radius, the radius in `_custom`.
  new bubble(num x, num y, num r) : super() {
    final radius = _double(r);
    this
      ..x = _double(x)
      ..y = _double(y)
      ..r = radius
      ..custom = radius;
  }

  /// The `double` of [value]: the product of an `int` and 1.0 is an inline
  /// conversion (dart-lang/sdk issue 64209).
  static double _double(num value) =>
      value is double ? value : (value as int) * 1.0;

  @override
  String toString() {
    final r = this.r;
    return r is double ? 'DataPoint($x, $y, $r)' : 'DataPoint($x, $y)';
  }
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

/// `chart._stacks` (core.controller.js:156): the sub-stack of each stack
/// key, and in a sub-stack the [StackEntry] of each index value, by the
/// `ToString` of the index value (core.datasetController.js:136-140).
typedef ChartStacks = Map<String, Map<String, StackEntry>>;

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

  // DIVERGES(chartjs): adapt-dense-index-values, a dense list by index.
  // The keys are dataset indexes: small and dense. [_dense] holds the value
  // of each index below its length, or [_absent]; it is null until the
  // first write. A negative key, a key past [_denseLimit], or a key far past
  // the count of the own indices ([_fitsDense]) moves all values into
  // [_sparse], which keeps the ascending key order of `Object.keys` too.
  List<Object?>? _dense;
  SplayTreeMap<int, Object?>? _sparse;
  int _count = 0;

  Map<String, Object?>? _named;

  /// The largest index that the dense list takes.
  static const int _denseLimit = 1024;

  /// Whether the dense list grows to take the index [index] past its end.
  /// The list stays at most about two slots for each own index: a stack that
  /// few datasets with high indexes share keeps the tree.
  bool _fitsDense(int index) =>
      index >= 0 && index <= _denseLimit && index <= 2 * _count + 16;

  /// Whether the object owns the index [index].
  bool hasIndex(int index) {
    final sparse = _sparse;
    if (sparse != null) return sparse.containsKey(index);
    final dense = _dense;
    return dense != null &&
        index >= 0 &&
        index < dense.length &&
        !identical(dense[index], _absent);
  }

  /// `object[index]`, or [undefined] when absent.
  Object? valueAt(int index) {
    final sparse = _sparse;
    if (sparse != null) {
      return sparse.containsKey(index) ? sparse[index] : undefined;
    }
    final dense = _dense;
    if (dense == null || index < 0 || index >= dense.length) return undefined;
    final value = dense[index];
    return identical(value, _absent) ? undefined : value;
  }

  /// `object[index] = value`.
  void setAt(int index, Object? value) {
    final sparse = _sparse;
    if (sparse != null) {
      sparse[index] = value;
      return;
    }
    final dense = _dense;
    if (dense != null && index >= 0 && index < dense.length) {
      if (identical(dense[index], _absent)) _count++;
      dense[index] = value;
      return;
    }
    if (_fitsDense(index)) {
      final list = dense ?? (_dense = <Object?>[]);
      while (list.length < index) {
        list.add(_absent);
      }
      list.add(value);
      _count++;
      return;
    }
    // A negative, a large or a far index: the tree keeps each key.
    final tree = _sparse = SplayTreeMap<int, Object?>();
    if (dense != null) {
      for (var i = 0; i < dense.length; i++) {
        if (!identical(dense[i], _absent)) tree[i] = dense[i];
      }
    }
    tree[index] = value;
    _dense = null;
    _count = 0;
  }

  /// `delete object[index]`. Returns whether the object owned [index].
  bool removeAt(int index) {
    final sparse = _sparse;
    if (sparse != null) {
      if (!sparse.containsKey(index)) return false;
      sparse.remove(index);
      return true;
    }
    if (!hasIndex(index)) return false;
    _dense![index] = _absent;
    _count--;
    return true;
  }

  /// The slots of the dense list, 0 in the tree form. For tests.
  int get denseSlots => _dense?.length ?? 0;

  /// The owned indices in ascending order.
  Iterable<int> get indices {
    final sparse = _sparse;
    if (sparse != null) return sparse.keys;
    final dense = _dense;
    if (dense == null) return const <int>[];
    return [
      for (var i = 0; i < dense.length; i++)
        if (!identical(dense[i], _absent)) i,
    ];
  }

  /// The count of the own keys.
  int get ownKeyCount => (_sparse?.length ?? _count) + (_named?.length ?? 0);

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
      setAt(index, value);
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
    for (final index in indices) '$index',
    ...?_named?.keys,
  ];

  @override
  bool jsHas(String name) {
    final index = jsArrayIndex(name);
    return index != null
        ? hasIndex(index)
        : (_named?.containsKey(name) ?? false);
  }

  @override
  bool jsDelete(String name) {
    if (!jsHas(name)) return false;
    final index = jsArrayIndex(name);
    if (index != null) {
      removeAt(index);
    } else {
      _named!.remove(name);
    }
    return true;
  }
}

/// The marker of an absent index in the dense list of [IndexValues].
const Object _absent = _AbsentIndex();

final class const _AbsentIndex();

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
