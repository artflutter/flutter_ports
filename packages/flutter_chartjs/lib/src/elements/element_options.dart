// Original code, not ported from Chart.js: the typed element options.

/// The typed resolved options of the four element types (Chart.js ADR 0018).
///
/// The resolved options of an element are a JS plain object, thus a
/// `Map<String, Object?>` (Chart.js ADR 0006). An element reads about 11 of
/// its option values in each draw. A Map read with a `String` key is a hash
/// lookup (performance.md §8.2). The classes of this file are Maps with one
/// field for each known key. Thus an element reads an option value with a
/// field read, and every reader of a Map still works: `jsGet`, the resolver,
/// the animations and user code.
///
/// - [ElementOptions] is the Map protocol: [ElementOptions.operator []],
///   [ElementOptions.operator []=], [ElementOptions.containsKey],
///   [ElementOptions.remove], [ElementOptions.keys], [ElementOptions.length]
///   and [ElementOptions.clear] give the same results as a
///   `Map<String, Object?>` with the same entries. Only the key order can
///   differ (see [ElementOptions.keys]).
/// - [PointOptions], [LineOptions], [BarOptions] and [ArcOptions] have the
///   known keys of their element type. These are the names of the option
///   interfaces of `index.d.ts`.
/// - Each known key has a getter `<key>Value` for the element code. It gives
///   the raw value, or [undefined] for an absent key: the result of
///   `jsGet(options, key)`. It does no Map lookup.
/// - [GenericElementOptions] holds the options of an element type without a
///   typed class, in one Map (Chart.js ADR 0021, section 2).
///
/// The producers of the resolver use the classes (Chart.js ADR 0021):
/// - [createElementOptions] gives the new, empty options object of an
///   element type id. `_resolveElementOptions` passes it to
///   `resolveNamedOptions` (core.datasetController.js:821).
/// - [copyOptions] is `Object.assign({}, options)`. The copy of an
///   [ElementOptions] is its [ElementOptions.clone], of the same class.
/// - An [ElementOptions] is a `JsFreezable`. `Object.freeze` of the cached
///   options (core.datasetController.js:831) sets its frozen state. In that
///   state, a write throws a [TypeError], as in the strict mode of an ES
///   module.
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'dart:collection';

import 'package:flutter_chartjs/src/helpers/helpers.canvas.dart'
    show DrawPointOptions;
import 'package:flutter_chartjs/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs/src/js/js_number.dart' show jsToNumber;
import 'package:flutter_chartjs/src/js/js_object.dart' show JsFreezable;
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/basic.dart';

/// The type of [_absent].
final class _Absent {
  const _Absent();
}

/// The value of the field of a known key that the options do not contain.
///
/// No member gives this value to other code. A read of the field gives
/// [undefined] ([_read]) or Dart `null` ([_mapRead]) for it.
const Object _absent = _Absent();

/// The getter result for the field value [raw]: [undefined] for [_absent],
/// else [raw]. This is the result of `jsGet(options, key)`.
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
Object? _read(Object? raw) => identical(raw, _absent) ? undefined : raw;

/// The Map read result for the field value [raw]: Dart `null` for
/// [_absent], else [raw]. This is the result of `options[key]`.
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
Object? _mapRead(Object? raw) => identical(raw, _absent) ? null : raw;

/// The resolved options of an element: a Map with a field for each known key
/// (Chart.js ADR 0018).
///
/// ## Keys
///
/// The known keys of a subclass are in its static `knownKeys` list, in this
/// order: `$shared`, the keys of the `defaults` of its element class, the
/// keys of its `defaultRoutes`, and the keys that other code writes into the
/// options of that element type:
/// - `$shared`: `resolveNamedOptions` writes it first (core.config.js:352,
///   :356), and `_resolveElementOptions` writes it again
///   (core.datasetController.js:826).
/// - `$animations`: the animations write it into the options that they
///   animate (core.animations.js:71, :159).
/// - `segment` of [LineOptions]: the line and scatter controllers write it
///   (controller.line.js:66, controller.scatter.js:86).
///
/// Every other key goes to a Map of extra keys. The options create this Map
/// at the first write of such a key.
///
/// ## Map protocol
///
/// [operator []], [operator []=], [containsKey], [remove], [keys], [length]
/// and [clear] give the same results as the same operations on a
/// `Map<String, Object?>` with the same entries. A read of an absent key
/// gives Dart `null`. Thus `jsGet` gives [undefined] for it. The other
/// members of `Map` come from [MapBase], which uses these members.
///
/// [keys] gives the present known keys in the order of the list, and then
/// the extra keys in their insertion order. `resolveNamedOptions` writes
/// `$shared` first and then the names of `defaults.elements[type]` in their
/// order (core.config.js:352-366). Thus the key order of the options that
/// the resolver makes is the upstream insertion order. A write of the known
/// keys in another order gives another key order than JavaScript (Chart.js
/// ADR 0018, section 3).
///
/// ## Typed reads
///
/// Each known key has a getter `<key>Value`, for example
/// [PointOptions.radiusValue]. It gives the raw value, or [undefined] for an
/// absent key, as `jsGet(options, key)` gives. The element code reads each
/// option through one small function that also takes a plain Map (Chart.js
/// ADR 0018, section 4).
///
/// ## Copies and the frozen state
///
/// [clone] is the copy `Object.assign({}, options)` in the same class
/// (Chart.js ADR 0021, section 3). [freeze] is `Object.freeze(options)`
/// (core.datasetController.js:831). In the frozen state, the options behave
/// as a frozen object in strict mode (Chart.js ADR 0021, section 5):
/// - [operator []=] throws a [TypeError] for each key, also for a write of
///   the same value.
/// - [remove] throws a [TypeError] for a present key. It returns Dart `null`
///   for an absent key, as a `delete` of an absent property succeeds.
/// - [clear] throws a [TypeError] when the options contain a key.
/// - The members of [MapBase] that write, for example `addAll` and `update`,
///   write through these three members. Thus they throw too.
/// - The reads do not change.
///
/// The freeze is shallow, as `Object.freeze` is. A Map value of frozen
/// options stays writable, for example `$animations`.
abstract class ElementOptions extends MapBase<String, Object?>
    implements JsFreezable {
  /// Options with the entries of [source], in the key order of [source].
  ///
  /// Each entry goes through [operator []=]. Dart `null` for [source] gives
  /// options with no key.
  ElementOptions([AnyObject? source]) {
    if (source != null) {
      for (final MapEntry(:key, :value) in source.entries) {
        this[key] = value;
      }
    }
  }

  /// The copy of the base fields of [source] for [clone]: `$shared`,
  /// `$animations` and a new Map of extra keys with the same entries in the
  /// same order. The copy is not frozen.
  ElementOptions._copy(ElementOptions source)
    : _shared = source._shared,
      _animations = source._animations,
      _extra = switch (source._extra) {
        null => null,
        final extra => Map<String, Object?>.of(extra),
      };

  Object? _shared = _absent;
  Object? _animations = _absent;

  /// The extra keys: the keys that are not known. Dart `null` before the
  /// first write of an extra key.
  AnyObject? _extra;

  /// Whether [freeze] has run.
  bool _frozen = false;

  /// `Object.isFrozen(options)`: whether [freeze] has run.
  @override
  bool get isFrozen => _frozen;

  /// `Object.freeze(options)` (core.datasetController.js:831): a later write
  /// throws a [TypeError]. No member clears the frozen state.
  @override
  void freeze() {
    _frozen = true;
  }

  /// `Object.assign({}, options)`: new options of the same class with the
  /// same entries in the same order (Chart.js ADR 0021, section 3).
  ///
  /// The copy is shallow, as `Object.assign` is: the values are the same
  /// objects. The copy has a new Map of extra keys. It is not frozen, also
  /// when these options are frozen.
  ElementOptions clone();

  /// The known keys of the subclass, in their order: its static `knownKeys`.
  List<String> get _knownKeys;

  /// core.config.js:352 `$shared`: the raw value, or [undefined] for an
  /// absent key.
  Object? get $sharedValue => _read(_shared);

  /// core.animations.js:71 `$animations`: the raw value, or [undefined] for
  /// an absent key.
  Object? get $animationsValue => _read(_animations);

  /// The field value of the known key [key], or [_absent]. A key that is not
  /// known also gives [_absent].
  ///
  /// A subclass handles its own keys in a `switch` and passes the other keys
  /// to this method.
  Object? _rawOf(String key) => switch (key) {
    r'$shared' => _shared,
    r'$animations' => _animations,
    _ => _absent,
  };

  /// Writes [raw] to the field of the known key [key]. [_absent] removes the
  /// key. Gives false for a key that is not known.
  ///
  /// A subclass handles its own keys in a `switch` and passes the other keys
  /// to this method.
  bool _store(String key, Object? raw) {
    switch (key) {
      case r'$shared':
        _shared = raw;
      case r'$animations':
        _animations = raw;
      default:
        return false;
    }
    return true;
  }

  /// The value of [key], or Dart `null` for an absent key, as the read of a
  /// `Map<String, Object?>` gives.
  @override
  Object? operator [](Object? key) {
    if (key is! String) return null;
    final raw = _rawOf(key);
    if (!identical(raw, _absent)) return raw;
    // A known key is never an extra key, so the extra Map gives null for an
    // absent known key.
    return _extra?[key];
  }

  /// Writes [value] for [key]: to the field of a known key, else to the Map
  /// of extra keys.
  ///
  /// Throws a [TypeError] in the frozen state, as a write into a frozen
  /// object in strict mode does.
  @override
  void operator []=(String key, Object? value) {
    // A JavaScript TypeError: a write into a frozen object.
    if (_frozen) throw TypeError();
    if (!_store(key, value)) {
      (_extra ??= <String, Object?>{})[key] = value;
    }
  }

  @override
  bool containsKey(Object? key) {
    if (key is! String) return false;
    return !identical(_rawOf(key), _absent) ||
        (_extra?.containsKey(key) ?? false);
  }

  /// Removes [key] and returns its value, or Dart `null` for an absent key.
  ///
  /// Throws a [TypeError] for a present key in the frozen state, as a
  /// `delete` of a property of a frozen object in strict mode does.
  @override
  Object? remove(Object? key) {
    if (key is! String) return null;
    final raw = _rawOf(key);
    if (identical(raw, _absent)) {
      final extra = _extra;
      if (extra == null || !extra.containsKey(key)) return null;
      // A JavaScript TypeError: a delete of a property of a frozen object.
      if (_frozen) throw TypeError();
      return extra.remove(key);
    }
    // A JavaScript TypeError: a delete of a property of a frozen object.
    if (_frozen) throw TypeError();
    _store(key, _absent);
    return raw;
  }

  /// The present known keys in the order of the list, then the extra keys in
  /// their insertion order.
  ///
  /// The result is a view, as the keys of a Map are: its length and its
  /// items follow the later changes of the options. Each iteration reads the
  /// keys when it starts. Thus a change during an iteration does not throw a
  /// `ConcurrentModificationError`, as it does for a Map.
  @override
  Iterable<String> get keys => _ElementOptionsKeys(this);

  /// The present keys at this time, in the order of [keys].
  List<String> _keyList() => [
    for (final key in _knownKeys)
      if (!identical(_rawOf(key), _absent)) key,
    ...?_extra?.keys,
  ];

  @override
  int get length {
    var count = _extra?.length ?? 0;
    for (final key in _knownKeys) {
      if (!identical(_rawOf(key), _absent)) count++;
    }
    return count;
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length != 0;

  /// Removes each key.
  ///
  /// Throws a [TypeError] in the frozen state when the options contain a key,
  /// as the `delete` of each property does.
  @override
  void clear() {
    // A JavaScript TypeError: a delete of a property of a frozen object.
    if (_frozen && isNotEmpty) throw TypeError();
    for (final key in _knownKeys) {
      _store(key, _absent);
    }
    _extra = null;
  }
}

/// The view of [ElementOptions.keys].
final class _ElementOptionsKeys extends Iterable<String> {
  _ElementOptionsKeys(this._options);

  final ElementOptions _options;

  @override
  Iterator<String> get iterator => _options._keyList().iterator;

  @override
  int get length => _options.length;

  @override
  bool get isEmpty => _options.isEmpty;

  @override
  bool get isNotEmpty => _options.isNotEmpty;

  @override
  bool contains(Object? element) => _options.containsKey(element);
}

/// index.d.ts:2010 `PointOptions`, the resolved options of a point element
/// (`element.point.ts`).
///
/// It also implements [DrawPointOptions]. Thus `PointElement.draw` passes it
/// to `drawPoint` without an adapter. The members of [DrawPointOptions] read
/// the fields as a Map read does: an absent key is Dart `null`, as for the
/// adapter over a plain Map in `element.point.dart`.
final class PointOptions extends ElementOptions implements DrawPointOptions {
  /// Options with the entries of [source], in its key order (see
  /// [ElementOptions.new]).
  PointOptions([super.source]);

  /// The copy of [source] for [clone]: each field, and the base fields of
  /// `ElementOptions._copy`.
  PointOptions._copy(PointOptions super.source)
    : _borderWidth = source._borderWidth,
      _hitRadius = source._hitRadius,
      _hoverBorderWidth = source._hoverBorderWidth,
      _hoverRadius = source._hoverRadius,
      _pointStyle = source._pointStyle,
      _radius = source._radius,
      _rotation = source._rotation,
      _backgroundColor = source._backgroundColor,
      _borderColor = source._borderColor,
      super._copy();

  /// The known keys: `$shared`, the keys of `PointElement.defaults`
  /// (element.point.ts:31-39), the keys of `PointElement.defaultRoutes`
  /// (element.point.ts:44-47), and `$animations`.
  static const List<String> knownKeys = [
    r'$shared',
    'borderWidth',
    'hitRadius',
    'hoverBorderWidth',
    'hoverRadius',
    'pointStyle',
    'radius',
    'rotation',
    'backgroundColor',
    'borderColor',
    r'$animations',
  ];

  Object? _borderWidth = _absent;
  Object? _hitRadius = _absent;
  Object? _hoverBorderWidth = _absent;
  Object? _hoverRadius = _absent;
  Object? _pointStyle = _absent;
  Object? _radius = _absent;
  Object? _rotation = _absent;
  Object? _backgroundColor = _absent;
  Object? _borderColor = _absent;

  @override
  List<String> get _knownKeys => knownKeys;

  /// `Object.assign({}, options)`: a new [PointOptions] with each field of
  /// these options (Chart.js ADR 0021, section 3). It is not frozen.
  @override
  PointOptions clone() => PointOptions._copy(this);

  /// element.point.ts:32 `borderWidth`: the raw value, or [undefined] for an
  /// absent key.
  Object? get borderWidthValue => _read(_borderWidth);

  /// element.point.ts:33 `hitRadius`: the raw value, or [undefined] for an
  /// absent key.
  Object? get hitRadiusValue => _read(_hitRadius);

  /// element.point.ts:34 `hoverBorderWidth`: the raw value, or [undefined]
  /// for an absent key.
  Object? get hoverBorderWidthValue => _read(_hoverBorderWidth);

  /// element.point.ts:35 `hoverRadius`: the raw value, or [undefined] for an
  /// absent key.
  Object? get hoverRadiusValue => _read(_hoverRadius);

  /// element.point.ts:36 `pointStyle`: the raw value, or [undefined] for an
  /// absent key.
  Object? get pointStyleValue => _read(_pointStyle);

  /// element.point.ts:37 `radius`: the raw value, or [undefined] for an
  /// absent key.
  Object? get radiusValue => _read(_radius);

  /// element.point.ts:38 `rotation`: the raw value, or [undefined] for an
  /// absent key.
  Object? get rotationValue => _read(_rotation);

  /// element.point.ts:45 `backgroundColor`: the raw value, or [undefined]
  /// for an absent key.
  Object? get backgroundColorValue => _read(_backgroundColor);

  /// element.point.ts:46 `borderColor`: the raw value, or [undefined] for an
  /// absent key.
  Object? get borderColorValue => _read(_borderColor);

  /// helpers.canvas.ts:150 `pointStyle`, the value as it is. Dart `null` for
  /// an absent key.
  @override
  Object? get pointStyle => _mapRead(_pointStyle);

  /// helpers.canvas.ts:151 `rotation`, in degrees: the `ToNumber` of the
  /// value, 0 for an absent key.
  @override
  double get rotation => jsToNumber(_mapRead(_rotation));

  /// helpers.canvas.ts:152 `radius`: the `ToNumber` of the value, 0 for an
  /// absent key.
  @override
  double get radius => jsToNumber(_mapRead(_radius));

  /// helpers.canvas.ts:153 `borderWidth`: the `ToNumber` of the value, 0 for
  /// an absent key.
  @override
  double get borderWidth => jsToNumber(_mapRead(_borderWidth));

  @override
  Object? _rawOf(String key) => switch (key) {
    'borderWidth' => _borderWidth,
    'hitRadius' => _hitRadius,
    'hoverBorderWidth' => _hoverBorderWidth,
    'hoverRadius' => _hoverRadius,
    'pointStyle' => _pointStyle,
    'radius' => _radius,
    'rotation' => _rotation,
    'backgroundColor' => _backgroundColor,
    'borderColor' => _borderColor,
    _ => super._rawOf(key),
  };

  @override
  bool _store(String key, Object? raw) {
    switch (key) {
      case 'borderWidth':
        _borderWidth = raw;
      case 'hitRadius':
        _hitRadius = raw;
      case 'hoverBorderWidth':
        _hoverBorderWidth = raw;
      case 'hoverRadius':
        _hoverRadius = raw;
      case 'pointStyle':
        _pointStyle = raw;
      case 'radius':
        _radius = raw;
      case 'rotation':
        _rotation = raw;
      case 'backgroundColor':
        _backgroundColor = raw;
      case 'borderColor':
        _borderColor = raw;
      default:
        return super._store(key, raw);
    }
    return true;
  }
}

/// index.d.ts:1909 `LineOptions`, the resolved options of a line element
/// (`element.line.js`).
final class LineOptions extends ElementOptions {
  /// Options with the entries of [source], in its key order (see
  /// [ElementOptions.new]).
  LineOptions([super.source]);

  /// The copy of [source] for [clone]: each field, and the base fields of
  /// `ElementOptions._copy`.
  LineOptions._copy(LineOptions super.source)
    : _borderCapStyle = source._borderCapStyle,
      _borderDash = source._borderDash,
      _borderDashOffset = source._borderDashOffset,
      _borderJoinStyle = source._borderJoinStyle,
      _borderWidth = source._borderWidth,
      _capBezierPoints = source._capBezierPoints,
      _cubicInterpolationMode = source._cubicInterpolationMode,
      _fill = source._fill,
      _spanGaps = source._spanGaps,
      _stepped = source._stepped,
      _tension = source._tension,
      _backgroundColor = source._backgroundColor,
      _borderColor = source._borderColor,
      _segment = source._segment,
      super._copy();

  /// The known keys: `$shared`, the keys of `LineElement.defaults`
  /// (element.line.js:250-262), the keys of `LineElement.defaultRoutes`
  /// (element.line.js:267-270), `segment` and `$animations`.
  static const List<String> knownKeys = [
    r'$shared',
    'borderCapStyle',
    'borderDash',
    'borderDashOffset',
    'borderJoinStyle',
    'borderWidth',
    'capBezierPoints',
    'cubicInterpolationMode',
    'fill',
    'spanGaps',
    'stepped',
    'tension',
    'backgroundColor',
    'borderColor',
    'segment',
    r'$animations',
  ];

  Object? _borderCapStyle = _absent;
  Object? _borderDash = _absent;
  Object? _borderDashOffset = _absent;
  Object? _borderJoinStyle = _absent;
  Object? _borderWidth = _absent;
  Object? _capBezierPoints = _absent;
  Object? _cubicInterpolationMode = _absent;
  Object? _fill = _absent;
  Object? _spanGaps = _absent;
  Object? _stepped = _absent;
  Object? _tension = _absent;
  Object? _backgroundColor = _absent;
  Object? _borderColor = _absent;
  Object? _segment = _absent;

  @override
  List<String> get _knownKeys => knownKeys;

  /// `Object.assign({}, options)`: a new [LineOptions] with each field of
  /// these options (Chart.js ADR 0021, section 3). It is not frozen.
  @override
  LineOptions clone() => LineOptions._copy(this);

  /// element.line.js:251 `borderCapStyle`: the raw value, or [undefined] for
  /// an absent key.
  Object? get borderCapStyleValue => _read(_borderCapStyle);

  /// element.line.js:252 `borderDash`: the raw value, or [undefined] for an
  /// absent key.
  Object? get borderDashValue => _read(_borderDash);

  /// element.line.js:253 `borderDashOffset`: the raw value, or [undefined]
  /// for an absent key.
  Object? get borderDashOffsetValue => _read(_borderDashOffset);

  /// element.line.js:254 `borderJoinStyle`: the raw value, or [undefined]
  /// for an absent key.
  Object? get borderJoinStyleValue => _read(_borderJoinStyle);

  /// element.line.js:255 `borderWidth`: the raw value, or [undefined] for an
  /// absent key.
  Object? get borderWidthValue => _read(_borderWidth);

  /// element.line.js:256 `capBezierPoints`: the raw value, or [undefined]
  /// for an absent key.
  Object? get capBezierPointsValue => _read(_capBezierPoints);

  /// element.line.js:257 `cubicInterpolationMode`: the raw value, or
  /// [undefined] for an absent key.
  Object? get cubicInterpolationModeValue => _read(_cubicInterpolationMode);

  /// element.line.js:258 `fill`: the raw value, or [undefined] for an absent
  /// key.
  Object? get fillValue => _read(_fill);

  /// element.line.js:259 `spanGaps`: the raw value, or [undefined] for an
  /// absent key.
  Object? get spanGapsValue => _read(_spanGaps);

  /// element.line.js:260 `stepped`: the raw value, or [undefined] for an
  /// absent key.
  Object? get steppedValue => _read(_stepped);

  /// element.line.js:261 `tension`: the raw value, or [undefined] for an
  /// absent key.
  Object? get tensionValue => _read(_tension);

  /// element.line.js:268 `backgroundColor`: the raw value, or [undefined]
  /// for an absent key.
  Object? get backgroundColorValue => _read(_backgroundColor);

  /// element.line.js:269 `borderColor`: the raw value, or [undefined] for an
  /// absent key.
  Object? get borderColorValue => _read(_borderColor);

  /// controller.line.js:66 `segment`, the segment option of the dataset that
  /// the controller writes into the options of the line: the raw value, or
  /// [undefined] for an absent key.
  Object? get segmentValue => _read(_segment);

  @override
  Object? _rawOf(String key) => switch (key) {
    'borderCapStyle' => _borderCapStyle,
    'borderDash' => _borderDash,
    'borderDashOffset' => _borderDashOffset,
    'borderJoinStyle' => _borderJoinStyle,
    'borderWidth' => _borderWidth,
    'capBezierPoints' => _capBezierPoints,
    'cubicInterpolationMode' => _cubicInterpolationMode,
    'fill' => _fill,
    'spanGaps' => _spanGaps,
    'stepped' => _stepped,
    'tension' => _tension,
    'backgroundColor' => _backgroundColor,
    'borderColor' => _borderColor,
    'segment' => _segment,
    _ => super._rawOf(key),
  };

  @override
  bool _store(String key, Object? raw) {
    switch (key) {
      case 'borderCapStyle':
        _borderCapStyle = raw;
      case 'borderDash':
        _borderDash = raw;
      case 'borderDashOffset':
        _borderDashOffset = raw;
      case 'borderJoinStyle':
        _borderJoinStyle = raw;
      case 'borderWidth':
        _borderWidth = raw;
      case 'capBezierPoints':
        _capBezierPoints = raw;
      case 'cubicInterpolationMode':
        _cubicInterpolationMode = raw;
      case 'fill':
        _fill = raw;
      case 'spanGaps':
        _spanGaps = raw;
      case 'stepped':
        _stepped = raw;
      case 'tension':
        _tension = raw;
      case 'backgroundColor':
        _backgroundColor = raw;
      case 'borderColor':
        _borderColor = raw;
      case 'segment':
        _segment = raw;
      default:
        return super._store(key, raw);
    }
    return true;
  }
}

/// index.d.ts:2103 `BarOptions`, the resolved options of a bar element
/// (`element.bar.js`).
final class BarOptions extends ElementOptions {
  /// Options with the entries of [source], in its key order (see
  /// [ElementOptions.new]).
  BarOptions([super.source]);

  /// The copy of [source] for [clone]: each field, and the base fields of
  /// `ElementOptions._copy`.
  BarOptions._copy(BarOptions super.source)
    : _borderSkipped = source._borderSkipped,
      _borderWidth = source._borderWidth,
      _borderRadius = source._borderRadius,
      _inflateAmount = source._inflateAmount,
      _pointStyle = source._pointStyle,
      _backgroundColor = source._backgroundColor,
      _borderColor = source._borderColor,
      super._copy();

  /// The known keys: `$shared`, the keys of `BarElement.defaults`
  /// (element.bar.js:148-154), the keys of `BarElement.defaultRoutes`
  /// (element.bar.js:159-162), and `$animations`.
  static const List<String> knownKeys = [
    r'$shared',
    'borderSkipped',
    'borderWidth',
    'borderRadius',
    'inflateAmount',
    'pointStyle',
    'backgroundColor',
    'borderColor',
    r'$animations',
  ];

  Object? _borderSkipped = _absent;
  Object? _borderWidth = _absent;
  Object? _borderRadius = _absent;
  Object? _inflateAmount = _absent;
  Object? _pointStyle = _absent;
  Object? _backgroundColor = _absent;
  Object? _borderColor = _absent;

  @override
  List<String> get _knownKeys => knownKeys;

  /// `Object.assign({}, options)`: a new [BarOptions] with each field of
  /// these options (Chart.js ADR 0021, section 3). It is not frozen.
  @override
  BarOptions clone() => BarOptions._copy(this);

  /// element.bar.js:149 `borderSkipped`: the raw value, or [undefined] for an
  /// absent key.
  Object? get borderSkippedValue => _read(_borderSkipped);

  /// element.bar.js:150 `borderWidth`: the raw value, or [undefined] for an
  /// absent key.
  Object? get borderWidthValue => _read(_borderWidth);

  /// element.bar.js:151 `borderRadius`: the raw value, or [undefined] for an
  /// absent key.
  Object? get borderRadiusValue => _read(_borderRadius);

  /// element.bar.js:152 `inflateAmount`: the raw value, or [undefined] for an
  /// absent key.
  Object? get inflateAmountValue => _read(_inflateAmount);

  /// element.bar.js:153 `pointStyle`: the raw value, or [undefined] for an
  /// absent key.
  Object? get pointStyleValue => _read(_pointStyle);

  /// element.bar.js:160 `backgroundColor`: the raw value, or [undefined] for
  /// an absent key.
  Object? get backgroundColorValue => _read(_backgroundColor);

  /// element.bar.js:161 `borderColor`: the raw value, or [undefined] for an
  /// absent key.
  Object? get borderColorValue => _read(_borderColor);

  @override
  Object? _rawOf(String key) => switch (key) {
    'borderSkipped' => _borderSkipped,
    'borderWidth' => _borderWidth,
    'borderRadius' => _borderRadius,
    'inflateAmount' => _inflateAmount,
    'pointStyle' => _pointStyle,
    'backgroundColor' => _backgroundColor,
    'borderColor' => _borderColor,
    _ => super._rawOf(key),
  };

  @override
  bool _store(String key, Object? raw) {
    switch (key) {
      case 'borderSkipped':
        _borderSkipped = raw;
      case 'borderWidth':
        _borderWidth = raw;
      case 'borderRadius':
        _borderRadius = raw;
      case 'inflateAmount':
        _inflateAmount = raw;
      case 'pointStyle':
        _pointStyle = raw;
      case 'backgroundColor':
        _backgroundColor = raw;
      case 'borderColor':
        _borderColor = raw;
      default:
        return super._store(key, raw);
    }
    return true;
  }
}

/// index.d.ts:1850 `ArcOptions`, the resolved options of an arc element
/// (`element.arc.ts`).
final class ArcOptions extends ElementOptions {
  /// Options with the entries of [source], in its key order (see
  /// [ElementOptions.new]).
  ArcOptions([super.source]);

  /// The copy of [source] for [clone]: each field, and the base fields of
  /// `ElementOptions._copy`.
  ArcOptions._copy(ArcOptions super.source)
    : _borderAlign = source._borderAlign,
      _borderColor = source._borderColor,
      _borderDash = source._borderDash,
      _borderDashOffset = source._borderDashOffset,
      _borderJoinStyle = source._borderJoinStyle,
      _borderRadius = source._borderRadius,
      _borderWidth = source._borderWidth,
      _offset = source._offset,
      _spacing = source._spacing,
      _angle = source._angle,
      _circular = source._circular,
      _selfJoin = source._selfJoin,
      _backgroundColor = source._backgroundColor,
      super._copy();

  /// The known keys: `$shared`, the keys of `ArcElement.defaults`
  /// (element.arc.ts:304-317), the keys of `ArcElement.defaultRoutes`
  /// (element.arc.ts:319-321), and `$animations`.
  static const List<String> knownKeys = [
    r'$shared',
    'borderAlign',
    'borderColor',
    'borderDash',
    'borderDashOffset',
    'borderJoinStyle',
    'borderRadius',
    'borderWidth',
    'offset',
    'spacing',
    'angle',
    'circular',
    'selfJoin',
    'backgroundColor',
    r'$animations',
  ];

  Object? _borderAlign = _absent;
  Object? _borderColor = _absent;
  Object? _borderDash = _absent;
  Object? _borderDashOffset = _absent;
  Object? _borderJoinStyle = _absent;
  Object? _borderRadius = _absent;
  Object? _borderWidth = _absent;
  Object? _offset = _absent;
  Object? _spacing = _absent;
  Object? _angle = _absent;
  Object? _circular = _absent;
  Object? _selfJoin = _absent;
  Object? _backgroundColor = _absent;

  @override
  List<String> get _knownKeys => knownKeys;

  /// `Object.assign({}, options)`: a new [ArcOptions] with each field of
  /// these options (Chart.js ADR 0021, section 3). It is not frozen.
  @override
  ArcOptions clone() => ArcOptions._copy(this);

  /// element.arc.ts:305 `borderAlign`: the raw value, or [undefined] for an
  /// absent key.
  Object? get borderAlignValue => _read(_borderAlign);

  /// element.arc.ts:306 `borderColor`: the raw value, or [undefined] for an
  /// absent key.
  Object? get borderColorValue => _read(_borderColor);

  /// element.arc.ts:307 `borderDash`: the raw value, or [undefined] for an
  /// absent key.
  Object? get borderDashValue => _read(_borderDash);

  /// element.arc.ts:308 `borderDashOffset`: the raw value, or [undefined]
  /// for an absent key.
  Object? get borderDashOffsetValue => _read(_borderDashOffset);

  /// element.arc.ts:309 `borderJoinStyle`: the raw value, or [undefined] for
  /// an absent key.
  Object? get borderJoinStyleValue => _read(_borderJoinStyle);

  /// element.arc.ts:310 `borderRadius`: the raw value, or [undefined] for an
  /// absent key.
  Object? get borderRadiusValue => _read(_borderRadius);

  /// element.arc.ts:311 `borderWidth`: the raw value, or [undefined] for an
  /// absent key.
  Object? get borderWidthValue => _read(_borderWidth);

  /// element.arc.ts:312 `offset`: the raw value, or [undefined] for an
  /// absent key.
  Object? get offsetValue => _read(_offset);

  /// element.arc.ts:313 `spacing`: the raw value, or [undefined] for an
  /// absent key.
  Object? get spacingValue => _read(_spacing);

  /// element.arc.ts:314 `angle`: the raw value, or [undefined] for an absent
  /// key.
  Object? get angleValue => _read(_angle);

  /// element.arc.ts:315 `circular`: the raw value, or [undefined] for an
  /// absent key.
  Object? get circularValue => _read(_circular);

  /// element.arc.ts:316 `selfJoin`: the raw value, or [undefined] for an
  /// absent key.
  Object? get selfJoinValue => _read(_selfJoin);

  /// element.arc.ts:320 `backgroundColor`: the raw value, or [undefined] for
  /// an absent key.
  Object? get backgroundColorValue => _read(_backgroundColor);

  @override
  Object? _rawOf(String key) => switch (key) {
    'borderAlign' => _borderAlign,
    'borderColor' => _borderColor,
    'borderDash' => _borderDash,
    'borderDashOffset' => _borderDashOffset,
    'borderJoinStyle' => _borderJoinStyle,
    'borderRadius' => _borderRadius,
    'borderWidth' => _borderWidth,
    'offset' => _offset,
    'spacing' => _spacing,
    'angle' => _angle,
    'circular' => _circular,
    'selfJoin' => _selfJoin,
    'backgroundColor' => _backgroundColor,
    _ => super._rawOf(key),
  };

  @override
  bool _store(String key, Object? raw) {
    switch (key) {
      case 'borderAlign':
        _borderAlign = raw;
      case 'borderColor':
        _borderColor = raw;
      case 'borderDash':
        _borderDash = raw;
      case 'borderDashOffset':
        _borderDashOffset = raw;
      case 'borderJoinStyle':
        _borderJoinStyle = raw;
      case 'borderRadius':
        _borderRadius = raw;
      case 'borderWidth':
        _borderWidth = raw;
      case 'offset':
        _offset = raw;
      case 'spacing':
        _spacing = raw;
      case 'angle':
        _angle = raw;
      case 'circular':
        _circular = raw;
      case 'selfJoin':
        _selfJoin = raw;
      case 'backgroundColor':
        _backgroundColor = raw;
      default:
        return super._store(key, raw);
    }
    return true;
  }
}

/// The resolved options of an element type without a typed class (Chart.js
/// ADR 0021, section 2): a custom element type, or a subclass of an element
/// class with its own id.
///
/// It has no known keys. It keeps each key, also `$shared` and
/// `$animations`, in one `LinkedHashMap`. Thus its key order is the
/// insertion order of JavaScript. It has the frozen state and [clone] of
/// [ElementOptions].
final class GenericElementOptions extends ElementOptions {
  /// Options with the entries of [source], in its key order (see
  /// [ElementOptions.new]).
  GenericElementOptions([super.source]) : _map = <String, Object?>{};

  /// The copy of [source] for [clone]: a new Map with the same entries in the
  /// same order.
  GenericElementOptions._copy(GenericElementOptions super.source)
    : _map = Map<String, Object?>.of(source._map),
      super._copy();

  /// Each key, also `$shared` and `$animations`, in insertion order.
  final AnyObject _map;

  @override
  List<String> get _knownKeys => const [];

  /// `Object.assign({}, options)`: a new [GenericElementOptions] with the
  /// entries of these options in their order (Chart.js ADR 0021, section 3).
  /// It is not frozen.
  @override
  GenericElementOptions clone() => GenericElementOptions._copy(this);

  /// core.config.js:352 `$shared`: the raw value, or [undefined] for an
  /// absent key.
  @override
  Object? get $sharedValue => _mapValue(r'$shared');

  /// core.animations.js:71 `$animations`: the raw value, or [undefined] for
  /// an absent key.
  @override
  Object? get $animationsValue => _mapValue(r'$animations');

  /// The value of [key], or [undefined] for an absent key, as
  /// `jsGet(options, key)` gives.
  Object? _mapValue(String key) {
    final value = _map[key];
    return value == null && !_map.containsKey(key) ? undefined : value;
  }

  @override
  Object? operator [](Object? key) => _map[key];

  /// Writes [value] for [key].
  ///
  /// Throws a [TypeError] in the frozen state, as a write into a frozen
  /// object in strict mode does.
  @override
  void operator []=(String key, Object? value) {
    // A JavaScript TypeError: a write into a frozen object.
    if (_frozen) throw TypeError();
    _map[key] = value;
  }

  @override
  bool containsKey(Object? key) => _map.containsKey(key);

  /// Removes [key] and returns its value, or Dart `null` for an absent key.
  ///
  /// Throws a [TypeError] for a present key in the frozen state, as a
  /// `delete` of a property of a frozen object in strict mode does.
  @override
  Object? remove(Object? key) {
    // A JavaScript TypeError: a delete of a property of a frozen object.
    if (_frozen && _map.containsKey(key)) throw TypeError();
    return _map.remove(key);
  }

  /// The keys in insertion order: the keys of a `LinkedHashMap`.
  @override
  Iterable<String> get keys => _map.keys;

  @override
  int get length => _map.length;

  /// Removes each key.
  ///
  /// Throws a [TypeError] in the frozen state when the options contain a key,
  /// as the `delete` of each property does.
  @override
  void clear() {
    // A JavaScript TypeError: a delete of a property of a frozen object.
    if (_frozen && _map.isNotEmpty) throw TypeError();
    _map.clear();
  }
}

/// The new, empty options object of the element type [elementType] (Chart.js
/// ADR 0021, section 1).
///
/// `_resolveElementOptions` passes it to `resolveNamedOptions` as `into`
/// (core.datasetController.js:821), where upstream makes the object literal
/// `{$shared: true}` (core.config.js:352). The ids `'point'`, `'line'`,
/// `'bar'` and `'arc'` of the four element classes (element.point.ts:22,
/// element.line.js:245, element.bar.js:143, element.arc.ts:302) give their
/// typed classes. Another value gives a [GenericElementOptions]. The result
/// is not frozen.
// DIVERGES(chartjs): adapt-typed-element-options, the class of the id.
ElementOptions createElementOptions(Object? elementType) =>
    switch (elementType) {
      'point' => PointOptions(),
      'line' => LineOptions(),
      'bar' => BarOptions(),
      'arc' => ArcOptions(),
      _ => GenericElementOptions(),
    };

/// `Object.assign({}, options)` for an options object (Chart.js ADR 0021,
/// section 3): `cloneIfNotShared` (core.datasetController.js:230),
/// `getSharedOptions` (:871), `resolveTargetOptions` (core.animations.js:159)
/// and the bubble controller (controller.bubble.js:157).
///
/// An [ElementOptions] gives its [ElementOptions.clone], of the same class.
/// Another Map gives a new plain Map with the keys of [jsObjectKeys], in that
/// order, and the values of `options[key]`. Thus a resolver gives the values
/// of its `get` trap. The copy is not frozen.
// DIVERGES(chartjs): adapt-typed-element-options, the copy keeps the class.
AnyObject copyOptions(AnyObject options) => options is ElementOptions
    ? options.clone()
    : {for (final key in jsObjectKeys(options)) key: options[key]};
