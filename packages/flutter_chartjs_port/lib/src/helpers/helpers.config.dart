// Ported from Chart.js v4.6.1 src/helpers/helpers.config.ts (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color values.
// DIVERGES(chartjs): adapt-typed-options, typed resolvers of Chart.js ADR 0054.

/// Port of `src/helpers/helpers.config.ts`: the option resolvers.
///
/// Upstream builds the resolvers as `Proxy` objects over a cache object.
/// Dart has no `Proxy`. Chart.js ADR 0054 §4 makes them typed classes:
/// [OptionResolver] (the target of `_createResolver`) and [OptionView] (the
/// target of `_attachContext`). Their fields are the slots of the upstream
/// cache object (`_scopes`, `_rootScopes`, `_fallback`, `_getTarget`,
/// `override`; `_proxy`, `_context`, `_subProxy`, `_stack`, `_descriptors`,
/// `setContext`), and the cached option values are a typed table by
/// `OptionKey` (a `String` for a name that is not a key of the schema). The
/// functions of this file are the upstream functions, in the upstream order,
/// over these typed targets. A scope list is a `List<Object?>` of typed
/// scopes (`OptionScope`), raw Maps and the other values that
/// `createSubResolver` adds; the walk reads a typed scope with
/// `OptionScope.lookup` and any other scope with [jsGet].
///
/// [Resolver] and [ContextResolver] are the names of the two classes for the
/// code of today. Both classes are a [JsProxyObject], the face by name of
/// Chart.js ADR 0054 §5; neither is a `Map`. They map the traps to these
/// members:
///
/// | Trap | Dart member |
/// |---|---|
/// | `get` | `operator []` and `jsRead`, and the typed read `readKey` |
/// | `set` | `operator []=` and `jsWrite` |
/// | `deleteProperty` | `jsDelete` |
/// | `has` (`in`) | `hasProperty` |
/// | `ownKeys` (`Object.getOwnPropertyNames`) | `ownKeys` |
/// | `getOwnPropertyDescriptor` | `hasOwnProperty`, `jsHas` |
/// | `getPrototypeOf` | none |
///
/// `Object.keys` of a resolver is its `objectKeys()`: `ownKeys` without
/// the keys that `hasOwnProperty` rejects, as the JavaScript engine filters
/// the `ownKeys` result through the `getOwnPropertyDescriptor` trap.
/// [jsObjectKeys] gives that result.
///
/// A write through a resolver (the `set` traps and `subGetTarget`) goes into
/// an object of the scopes: a typed scope classifies the value; a raw Map
/// takes the value only if its value type allows it. A nested Map literal
/// can have a narrow inferred type, for example `Map<String, int>` for
/// `{'a': 1}`. A write of a `String` into it throws a [TypeError].
/// JavaScript sets the property. A scope that takes writes has the runtime
/// type `Map<String, Object?>` or is a typed scope.
///
/// The three JS states of an option key stay apart (Chart.js ADR 0054 §1):
/// an absent key, the [undefined] sentinel and Dart `null` (JS `null`). The
/// resolution goes to the next scope on an absent key and on the sentinel.
/// `null` is a value. A resolver gives the [undefined] sentinel for a key
/// that it does not resolve. The cache keeps a resolved [undefined] as an
/// own key, as `_cached` does.
///
/// A scriptable option is a function value of `lib/src/js/js_function.dart`.
/// The resolver calls it through [jsCall] with the context and the
/// sub-resolver.
library;

import 'dart:collection' show LinkedHashMap;
import 'dart:core' as core;
import 'dart:core';
import 'dart:typed_data' show Uint16List;
import 'dart:ui' show Color, Locale, StrokeJoin;

import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/src/core/bar_bulk_update.dart';
import 'package:flutter_chartjs_port/src/core/data_update.dart'
    show nativeOptionScope;
import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart'
    show ScaleBounds;
import 'package:flutter_chartjs_port/src/helpers/cubic_interpolation_mode.dart'
    show CubicInterpolationMode;
import 'package:flutter_chartjs_port/src/helpers/grace_length.dart'
    show GraceLength;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.types.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show capitalize, isArray, isFunction, isObject, resolveObjectKey;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ContextObject, ScriptableContext;
import 'package:flutter_chartjs_port/src/helpers/point_style.dart'
    show PointStyle;
import 'package:flutter_chartjs_port/src/helpers/radius_length.dart'
    show RadiusLength;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/element_options_base.dart'
    show ElementOptions;
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart' show ParsedItem;
import 'package:flutter_chartjs_port/src/options/resolved.g.dart'
    show ArcOptions, BarOptions, PointOptions;
import 'package:flutter_chartjs_port/src/types/arc_option_enums.dart'
    show ArcBorderAlign, ArcSpacingMode;
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:flutter_chartjs_port/src/types/layout.dart' show ChartPosition;
import 'package:intl/intl.dart' show NumberFormat;
import 'package:meta/meta.dart';

export 'package:flutter_chartjs_port/src/helpers/helpers.config.types.dart';

/// The name [Resolver] of the code of today for [OptionResolver].
typedef Resolver = OptionResolver;

/// The name [ContextResolver] of the code of today for [OptionView].
typedef ContextResolver = OptionView;

/// The type of [_absent].
final class _Absent {
  const _Absent();
}

/// The marker of a property that a target does not own.
const Object _absent = _Absent();

/// The key of the option name [name] in a cache: its [OptionKey], or [name]
/// for a name that is not a key of the schema.
Object _keyOf(String name) => optionKeyOf(name) ?? name;

/// The cached option values of a target, by key (an [OptionKey] or a
/// `String`), in the order of their first write: the typed form of the own
/// properties of the upstream cache object.
///
/// A table of a few keys is scanned: an [OptionKey] compares by identity.
/// The resolver of a scale or of the chart options caches dozens of keys,
/// and a scale reads some of them for each point (`startAngle` and
/// `reverse` of the radial scale in the filler of a radar). Thus a table of
/// more than [_scanMax] keys also has an index of the positions: by
/// [OptionKey.index] for a key, and a hashed one for a name, as the
/// properties of the upstream cache object have.
final class _Cache {
  List<Object>? _keys;
  List<Object?>? _values;

  /// The position plus 1 of each [OptionKey] in [_keys], at its
  /// [OptionKey.index] (0 for an absent key), once the table has more than
  /// [_scanMax] keys. Dart `null` before.
  Uint16List? _keyPositions;

  /// The position of each name in [_keys], once [_keyPositions] exists.
  Map<String, int>? _namePositions;

  /// The most keys that [_index] scans.
  static const int _scanMax = 8;

  int _index(Object key) {
    final keyPositions = _keyPositions;
    if (keyPositions != null) {
      return key is OptionKey
          ? keyPositions[key.index] - 1
          : _namePositions![key as String] ?? -1;
    }
    final keys = _keys;
    if (keys == null) return -1;
    if (key is OptionKey) {
      for (var i = 0; i < keys.length; i++) {
        if (identical(keys[i], key)) return i;
      }
      return -1;
    }
    for (var i = 0; i < keys.length; i++) {
      final k = keys[i];
      if (identical(k, key) || k == key) return i;
    }
    return -1;
  }

  /// The value of [key], or [_absent].
  Object? get(Object key) {
    final index = _index(key);
    return index < 0 ? _absent : _values![index];
  }

  void set(Object key, Object? value) {
    final index = _index(key);
    if (index >= 0) {
      _values![index] = value;
      return;
    }
    final keys = (_keys ??= <Object>[])..add(key);
    (_values ??= <Object?>[]).add(value);
    if (_keyPositions != null) {
      _setPosition(key, keys.length - 1);
    } else if (keys.length > _scanMax) {
      _buildPositions();
    }
  }

  void remove(Object key) {
    final index = _index(key);
    if (index < 0) return;
    _keys!.removeAt(index);
    _values!.removeAt(index);
    if (_keyPositions != null) _buildPositions();
  }

  /// Builds [_keyPositions] and [_namePositions] from [_keys].
  void _buildPositions() {
    final keys = _keys!;
    _keyPositions = Uint16List(OptionKey.values.length);
    _namePositions = <String, int>{};
    for (var i = 0; i < keys.length; i++) {
      _setPosition(keys[i], i);
    }
  }

  void _setPosition(Object key, int position) {
    if (key is OptionKey) {
      _keyPositions![key.index] = position + 1;
    } else {
      _namePositions![key as String] = position;
    }
  }

  /// The names of the cached keys, in their order.
  Iterable<String> get names => (_keys ?? const <Object>[]).map(
    (k) => k is OptionKey ? k.jsName : k as String,
  );
}

// Exact SDK container types only: never probe a user List getter. Values and
// lengths remain live; this is not the data-update source stability contract.
Set<Type> _indexedListTypes<T>() => {
  <T>[].runtimeType,
  List<T>.empty().runtimeType,
  List<T>.unmodifiable(const <Never>[]).runtimeType,
};

final _nativeIndexedLists = <Type>{
  ..._indexedListTypes<Object?>(),
  ..._indexedListTypes<Object>(),
  ..._indexedListTypes<dynamic>(),
  ..._indexedListTypes<Color>(),
  ..._indexedListTypes<Color?>(),
  ..._indexedListTypes<String>(),
  ..._indexedListTypes<String?>(),
  ..._indexedListTypes<num>(),
  ..._indexedListTypes<num?>(),
  ..._indexedListTypes<double>(),
  ..._indexedListTypes<double?>(),
  ..._indexedListTypes<int>(),
  ..._indexedListTypes<int?>(),
  ..._indexedListTypes<bool>(),
  ..._indexedListTypes<bool?>(),
  const <Object?>[].runtimeType,
  const <Object>[].runtimeType,
  const <dynamic>[].runtimeType,
  const <Color>[].runtimeType,
  const <Color?>[].runtimeType,
  const <String>[].runtimeType,
  const <String?>[].runtimeType,
  const <num>[].runtimeType,
  const <num?>[].runtimeType,
  const <double>[].runtimeType,
  const <double?>[].runtimeType,
  const <int>[].runtimeType,
  const <int?>[].runtimeType,
  const <bool>[].runtimeType,
  const <bool?>[].runtimeType,
};

// An enum value (a `StrokeJoin`, an `ArcBorderAlign`) is a constant of its
// type: its identity is its equality, and a read of it runs no user code. A
// point style, a cubic interpolation mode and a length are such values too:
// the resolution keeps the object, and only the draw calls its methods. An
// axis class has no members (row adapt-axis-objects). A `Locale` is a value,
// and the chart only calls `format` of a `NumberFormat` (row
// adapt-intl-number-format).
bool _indexedScalar(Object? value) =>
    value == null ||
    value is Undefined ||
    value is num ||
    value is bool ||
    value is String ||
    value is Enum ||
    value is PointStyle ||
    value is CubicInterpolationMode ||
    value is RadiusLength ||
    value is GraceLength ||
    value is ScaleAxis ||
    value is Locale ||
    value is NumberFormat ||
    (value is Color && !isObject(value));

// DIVERGES(chartjs): adapt-arc-native-options, the read of a non-indexable list
// (helpers.config.ts:233-296) gives the same list unless item 0 is an object.
// The plan keeps the list and asks at each use: its items stay live.
bool _plainRawList(List<Object?> list) => list.isEmpty || !isObject(list[0]);

// `borderDash` is the one key of a built-in descriptor that gives a raw list
// with no conversion or audit: its slot takes any value. Another key with a
// non-indexable list keeps the ordinary path.
bool _nativeRawList(OptionKey key, Object? value, _Descriptor descriptors) =>
    key == OptionKey.borderDash &&
    value is List<Object?> &&
    _nativeIndexedLists.contains(value.runtimeType) &&
    !descriptors.isIndexable(key.jsName) &&
    _plainRawList(value);

// Static values are already cached by the raw resolver. The two contextual
// views remain fresh: callbacks can retain the subview or change the resolver.
typedef _ScriptableColor = ({OptionKey key, Object? callback, int position});

// DIVERGES(chartjs): adapt-varying-color-resolution, ordered varying operations
// and immutable references to the already-cached descriptor inputs.
final class _ScriptableElementPlan {
  _ScriptableElementPlan(
    this.keys,
    this.colors,
    this.template,
    this.scriptable,
    this.indexable,
    this.allKeys,
    this.rawList,
  ) : contextOnly = colors.every(
        (color) =>
            color.callback is Object? Function(Never) &&
            color.callback is! Object? Function(Never, Never),
      );
  final List<OptionKey> keys;
  final List<_ScriptableColor> colors;
  final ElementOptions template;
  final bool contextOnly;
  final Object? scriptable;
  final Object? indexable;
  final Object? allKeys;

  /// The `borderDash` list that the template holds by reference, or null.
  final List<Object?>? rawList;

  /// A callback or a context factory can change the items of [rawList].
  bool get rawListPlain {
    final list = rawList;
    return list == null || _plainRawList(list);
  }

  _Descriptor _descriptors() => _Descriptor(
    scriptable: identical(scriptable, undefined) ? true : scriptable,
    indexable: identical(indexable, undefined) ? true : indexable,
    allKeys: allKeys,
  );

  // Both views and descriptor objects remain fresh. No callback receives a
  // retained view, and setContext/override keep their original live behavior.
  OptionView view(OptionResolver resolver, Object context) => OptionView._(
    resolver,
    context,
    OptionView._(resolver, context, undefined, _descriptors(), null),
    _descriptors(),
    null,
  );

  // DIVERGES(chartjs): adapt-option-resolution-setup, explicit immutable input.
  List<Object>? _immutableKeySource;

  bool matches(List<Object> other, {bool immutable = false}) {
    if (immutable && identical(_immutableKeySource, other)) return true;
    if (keys.length != other.length) return false;
    for (var i = 0; i < keys.length; i++) {
      if (!identical(keys[i], other[i])) return false;
    }
    if (immutable) _immutableKeySource = other;
    return true;
  }
}

final class _IndexedElementPlan {
  _IndexedElementPlan(this.keys, this.values, this.rawListAt);
  final List<OptionKey> keys;
  final List<Object?> values;

  /// The position in [values] of the list that stays a raw reference, or -1.
  final int rawListAt;
  ElementOptions? _template;
  late List<int> _varying;

  bool get _rawListPlain =>
      rawListAt < 0 || _plainRawList(values[rawListAt]! as List<Object?>);

  /// Whether the fill of [prepared] accepts each input for any index, so that
  /// no resolve leaves this plan. This reads each item of each list.
  // DIVERGES(chartjs): adapt-data-update-indexed-plan, the items of the lists.
  bool get hasStaticInputs {
    for (var i = 0; i < keys.length; i++) {
      final value = values[i];
      if (i == rawListAt) {
        if (!(value! as List<Object?>).every(_indexedScalar)) return false;
      } else if (value is List<Object?>) {
        if (value.isEmpty) return false;
        for (final item in value) {
          if (!_staticIndexedValue(keys[i], item)) return false;
        }
      } else if (!_staticIndexedValue(keys[i], value)) {
        return false;
      }
    }
    return true;
  }

  // DIVERGES(chartjs): adapt-prepared-indexed-options, copy native static
  // fields when the caller owns the result. Never retain a returned object.
  ElementOptions? prepared(Object context, ElementOptions into) {
    if (context is! ScriptableContext || !context.hasIndexKey) return null;
    final rawIndex = context.index;
    if (rawIndex is! num) return null;
    final index = rawIndex.toDouble();
    if (!index.isFinite ||
        index < 0 ||
        index != index.truncateToDouble() ||
        !_rawListPlain) {
      return null;
    }
    var template = _template;
    if (template == null || template.runtimeType != into.runtimeType) {
      // The constructor/type and scalar checks are the same as fill. Preparing
      // from cached inputs avoids retaining mutations of any previous result.
      template = OptionResolver.newNativeResult(into)
        ..storeKey(OptionKey.dollarShared, false);
      final varying = <int>[];
      for (var i = 0; i < keys.length; i++) {
        final value = values[i];
        if (i == rawListAt) {
          template.storeKey(keys[i], value);
        } else if (value is List<Object?>) {
          varying.add(i);
        } else {
          if (!_nativeIndexedValue(keys[i], value)) return null;
          template.storeKey(keys[i], value);
        }
      }
      _template = template;
      _varying = varying;
    }
    final varying = _varying;
    // Only the varying inputs need preflight on each element. Lists remain live
    // after context refresh, including length changes and unsupported entries.
    for (final i in varying) {
      final list = values[i]! as List<Object?>;
      if (list.isEmpty ||
          !_nativeIndexedValue(
            keys[i],
            list[_indexedSlot(index, list.length)],
          )) {
        return null;
      }
    }
    final result = template.clone();
    for (final i in varying) {
      final list = values[i]! as List<Object?>;
      result.storeKey(keys[i], list[_indexedSlot(index, list.length)]);
    }
    return result;
  }

  // DIVERGES(chartjs): adapt-option-resolution-setup, explicit immutable input.
  List<Object>? _immutableKeySource;

  bool matches(List<Object> other, {bool immutable = false}) {
    if (immutable && identical(_immutableKeySource, other)) return true;
    if (keys.length != other.length) return false;
    for (var i = 0; i < keys.length; i++) {
      if (!identical(keys[i], other[i])) return false;
    }
    if (immutable) _immutableKeySource = other;
    return true;
  }

  /// Whether [prepared] gives a result for each index below [count]: the static
  /// fields are native, and each entry of a varying list at such an index is.
  /// A resolve of such an index runs no user code and throws nothing.
  // DIVERGES(chartjs): adapt-hidden-legend-items, the proof of a legend build.
  bool covers(int count, ScriptableContext at, ElementOptions kind) {
    if (prepared(at..index = 0.0, kind) == null) return false;
    for (final i in _varying) {
      final key = keys[i];
      final list = values[i]! as List<Object?>;
      final end = count < list.length ? count : list.length;
      for (var j = 1; j < end; j++) {
        if (!_nativeIndexedValue(key, list[j])) return false;
      }
    }
    return true;
  }

  bool fill(Object context, ElementOptions into) {
    if (context is! ScriptableContext || !context.hasIndexKey) return false;
    final rawIndex = context.index;
    if (rawIndex is! num) return false;
    // Match jsToNumber before remainder, including VM integers above 2^53.
    final index = rawIndex.toDouble();
    if (!index.isFinite ||
        index < 0 ||
        index != index.truncateToDouble() ||
        !_rawListPlain) {
      return false;
    }
    // No stores before preflight: unsupported selected values must follow the
    // original path, including nested resolvers and empty-array semantics.
    for (var i = 0; i < values.length; i++) {
      if (i == rawListAt) continue;
      var value = values[i];
      if (value is List<Object?>) {
        if (value.isEmpty) return false;
        value = value[_indexedSlot(index, value.length)];
      }
      // Native stores only. Foreign numeric conversions can invoke the debug
      // audit hook; those keep the ordinary observable read/write order too.
      if (!_nativeIndexedValue(keys[i], value)) return false;
    }
    for (var i = 0; i < keys.length; i++) {
      final value = values[i];
      into.storeKey(
        keys[i],
        i != rawListAt && value is List<Object?>
            ? value[_indexedSlot(index, value.length)]
            : value,
      );
    }
    return true;
  }
}

/// The one or two colors of a loop-local plan (`prepareIndexedPointColors` and
/// its twins) that vary with the index. The lists stay live.
// DIVERGES(chartjs): adapt-prepared-indexed-options, the colors of a loop plan.
final class _VaryingColors {
  _VaryingColors(
    this._firstKey,
    this._firstValues,
    this._secondKey,
    this._secondValues,
  );

  final OptionKey _firstKey;
  final List<Object?> _firstValues;
  final OptionKey? _secondKey;
  final List<Object?>? _secondValues;

  /// Stores the colors of [index] into the fresh [result], in the key order.
  void storeInto(ElementOptions result, int index) {
    final first = _firstValues;
    // js-ok: native loop indices are nonnegative and lengths positive.
    result.storeKey(_firstKey, first[index % first.length]);
    final second = _secondValues;
    if (second != null) {
      // js-ok: native loop indices are nonnegative and lengths positive.
      result.storeKey(_secondKey!, second[index % second.length]);
    }
  }
}

/// `index % length` of a finite, whole, nonnegative JS number and a positive
/// length. Below 2^53 the integer form gives the result of the double form with
/// no call of `fmod`. Above it, the double form matches `jsToNumber` of a VM
/// integer.
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
int _indexedSlot(double index, int length) => index < 9007199254740992.0
    // js-ok: nonnegative index and positive length (the callers' preflight).
    ? index.toInt() % length
    : index.remainder(length).toInt();

/// The options of a data element of each index of one native indexed plan, with
/// no context: a legend of a slice chart reads them when it builds its items
/// after the update of that plan (Chart.js ADR 0099). The plan keeps the values
/// that the resolver cached when it qualified, and [at] gives the result of the
/// resolve of a context with this index. The items of the lists stay live.
@internal
// DIVERGES(chartjs): adapt-hidden-legend-items, the styles of a later build.
final class IndexedElementStyles {
  IndexedElementStyles._(this._resolver, this._plan, this._kind);

  final OptionResolver _resolver;
  final _IndexedElementPlan _plan;
  final ElementOptions _kind;

  /// The `index` of the context of a resolve, with no other effect.
  final ScriptableContext _context = ScriptableContext(null);

  /// Whether each resolve of an index below [count] stays on this plan: it runs
  /// no user code and throws nothing, and a write through the resolver has not
  /// ended the plan.
  bool covers(int count) =>
      !_resolver._slotsTouched &&
      identical(_plan, _resolver._indexedElementPlan) &&
      _plan.covers(count, _context, _kind);

  /// The fresh options of a resolve with a context of the index [index], after
  /// [covers] of a higher count, with no user code between.
  ElementOptions at(double index) =>
      _plan.prepared(_context..index = index, _kind)!;
}

bool _nativeIndexedValue(OptionKey key, Object? value) =>
    _indexedScalar(value) &&
    switch (key) {
      OptionKey.borderWidth ||
      OptionKey.hitRadius ||
      OptionKey.hoverBorderWidth ||
      OptionKey.hoverRadius ||
      OptionKey.radius ||
      OptionKey.rotation ||
      OptionKey.borderDashOffset ||
      OptionKey.offset ||
      OptionKey.spacing => value is num,
      OptionKey.backgroundColor ||
      OptionKey.borderColor ||
      OptionKey.pointStyle ||
      OptionKey.borderSkipped ||
      OptionKey.borderRadius ||
      OptionKey.inflateAmount ||
      OptionKey.borderDash => true,
      // DIVERGES(chartjs): adapt-arc-native-options, the slots of the other
      // arc keys. The `undefined` of the two arc defaults is a foreign value:
      // its debug audit runs at the template build, not at each copy.
      // DIVERGES(chartjs): adapt-arc-option-enums, the enum value.
      OptionKey.borderAlign => value is ArcBorderAlign,
      OptionKey.spacingMode => value is ArcSpacingMode,
      OptionKey.circular || OptionKey.selfJoin => value is bool,
      OptionKey.borderJoinStyle => value is StrokeJoin || value is Undefined,
      OptionKey.angle => value is num || value is Undefined,
      _ => false,
    };

/// A value of [_nativeIndexedValue] that is plain in its key: a color key holds
/// an exact [Color] or no value, the only forms that the canvas draws with no
/// error, and no other key holds a color. Any other value is foreign for the
/// proof of a data-only update, though a plan can store it.
// DIVERGES(chartjs): adapt-data-update-indexed-plan, the values of the proof.
bool _staticIndexedValue(OptionKey key, Object? value) =>
    _nativeIndexedValue(key, value) &&
    (key == OptionKey.backgroundColor || key == OptionKey.borderColor
        ? value == null || value is Undefined || value.runtimeType == Color
        : value is! Color);

/// helpers.config.ts:27 `_createResolver`.
///
/// Creates a Proxy for resolving raw values for options.
/// @param scopes - The option scopes to look for values, in resolution order
/// @param prefixes - The prefixes for values, in resolution order.
/// @param rootScopes - The root option scopes
/// @param fallback - Parent scopes fallback
/// @param getTarget - callback for getting the target for changed values
/// @returns Proxy
/// @private
///
/// A null [rootScopes] or [getTarget] is an absent argument. Dart `null`
/// stands for JS `undefined` there: JS `null` never reaches them. The
/// default of [fallback] is the [undefined] sentinel, because a JS `null`
/// fallback is a value (`typeof fallback === 'undefined'` at :38).
OptionResolver createResolver(
  List<Object?> scopes, [
  List<String> prefixes = const [''],
  List<Object?>? rootScopes,
  Object? fallback = undefined,
  Object? Function()? getTarget,
]) {
  final target = getTarget ?? () => _first(scopes);
  final finalRootScopes = rootScopes ?? scopes;
  if (identical(fallback, undefined)) {
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    fallback = _resolve('_fallback', scopes);
  }
  // Upstream also sets `[Symbol.toStringTag]: 'Object'`. A Dart Map is an
  // object for isObject without it.
  return OptionResolver._(scopes, prefixes, finalRootScopes, fallback, target);
}

/// The target of `_createResolver` (helpers.config.ts:41-49) and its
/// `Proxy` (helpers.config.ts:50-107), as one typed class (Chart.js ADR 0054
/// §4).
///
/// The slots of the cache object are fields. The cached option values are a
/// typed table. A write by the `set` trap or a delete by the
/// `deleteProperty` trap of a slot name changes the own property of that
/// name, as upstream does on its cache object. A [OptionResolver] gives the
/// [undefined] sentinel for a key that it does not resolve, and Dart `null`
/// for a JS `null` value.
final class OptionResolver implements ResolverProxy {
  OptionResolver._(
    this._scopes,
    this._prefixes,
    this._rootScopes,
    this._fallback,
    this._getTarget,
  );

  /// The `scopes` parameter of `_createResolver`: `_scopes` of the target.
  final List<Object?> _scopes;

  /// The `prefixes` parameter of `_createResolver`.
  final List<String> _prefixes;

  /// `_rootScopes` of the target.
  final List<Object?> _rootScopes;

  /// `_fallback` of the target.
  final Object? _fallback;

  /// The `getTarget` parameter of `_createResolver`: `_getTarget` of the
  /// target.
  final Object? Function() _getTarget;

  /// `override` of the target (helpers.config.ts:48).
  // One function value for each target, as the upstream cache object
  // holds one.
  // ignore: prefer_function_declarations_over_variables
  late final OptionResolver Function(Object scope) _override = (scope) =>
      createResolver(
        [scope, ..._scopes],
        _prefixes,
        _rootScopes,
        _fallback,
      );

  /// The cached option values, and the own properties of the slot names
  /// that the `set` trap writes.
  final _Cache _cache = _Cache();

  _ScriptableElementPlan? _scriptableElementPlan;
  int _scriptableRejectedSize = -1;
  _IndexedElementPlan? _indexedElementPlan;
  int _indexedRejectedSize = -1;

  /// True only for ordinary SDK lists supported by indexed option probing.
  @internal
  static bool nativeIndexedList(Object? value) =>
      _nativeIndexedLists.contains(value.runtimeType);

  /// Exact native result classes, all final. Other kinds skip all list guards.
  @internal
  static bool nativeIndexedResult(ElementOptions into) =>
      into is PointOptions || into is BarOptions || into is ArcOptions;

  /// A new result of the class of the native result [kind]: a private type
  /// token or the supplied result of the owned path.
  @internal
  // DIVERGES(chartjs): adapt-owned-option-result, the class of a type token.
  static ElementOptions newNativeResult(ElementOptions kind) => switch (kind) {
    PointOptions() => PointOptions(),
    ArcOptions() => ArcOptions(),
    _ => BarOptions(),
  };

  /// True only for an already-prepared, unshared point plan. No raw option,
  /// custom descriptor or context is evaluated to qualify a loop.
  @internal
  // DIVERGES(chartjs): adapt-native-line-resolution, inspect only warm plans.
  bool hasPreparedPointOptions(List<Object> keys) {
    if (_slotsTouched) return false;
    final scriptable = _scriptableElementPlan;
    if (scriptable != null &&
        scriptable.template is PointOptions &&
        identical(scriptable.template.$sharedValue, false) &&
        scriptable.matches(keys, immutable: true)) {
      return true;
    }
    final indexed = _indexedElementPlan;
    return indexed != null &&
        indexed._template is PointOptions &&
        identical(indexed._template!.$sharedValue, false) &&
        indexed.matches(keys, immutable: true) &&
        indexed._varying.every(
          (i) =>
              indexed.keys[i] == OptionKey.backgroundColor ||
              indexed.keys[i] == OptionKey.borderColor,
        );
  }

  /// Whether each resolve of [keys] takes the indexed plan of this resolver,
  /// for any index: each input is a native scalar or a native list of them,
  /// each of the scopes is native, and no write came after the reads of the
  /// plan. The reads went through all scopes, also the defaults and the
  /// overrides, and the plan holds no function. A resolve then runs no user
  /// code. This reads cached values only and never invokes a descriptor or a
  /// resolver.
  @internal
  // DIVERGES(chartjs): adapt-data-update-indexed-plan, the plan as the proof.
  bool hasStaticIndexedOptions(List<Object> keys) {
    final plan = _indexedElementPlan;
    return !_slotsTouched &&
        plan != null &&
        plan._template != null &&
        plan.matches(keys) &&
        _scopes.every(nativeOptionScope) &&
        plan.hasStaticInputs;
  }

  /// A direct executor for an already-prepared native point scalar-color plan.
  /// [keys] must be the native immutable key snapshot used by its source plan.
  /// Null results decline before context. Later failure uses the supplied
  /// continuation, consuming the original context exactly once.
  @internal
  // DIVERGES(chartjs): adapt-prepared-scalar-point-resolution, owned executor.
  ElementOptions? Function(Object Function(), Object Function()?)?
  prepareScalarPointResolution(
    List<Object> keys,
    bool Function() stillCached,
    ElementOptions Function(Object) afterContextFailure,
  ) {
    final plan = _scriptableElementPlan;
    if (_slotsTouched ||
        plan == null ||
        !plan.contextOnly ||
        plan.template is! PointOptions ||
        !identical(plan.template.$sharedValue, false) ||
        !plan.matches(keys, immutable: true)) {
      return null;
    }
    return (context, preparedContext) {
      if (_slotsTouched ||
          !identical(plan, _scriptableElementPlan) ||
          !plan.matches(keys, immutable: true)) {
        return null;
      }
      final ctx = (preparedContext ?? context)();
      if (!stillCached() ||
          !identical(plan, _scriptableElementPlan) ||
          !plan.matches(keys, immutable: true)) {
        return afterContextFailure(ctx);
      }
      return _resolveScalarColors(plan, ctx);
    };
  }

  /// Captures a color-only bar plan for a synchronous native loop. The caller
  /// must prove that no user code or mutation can run until the loop finishes.
  /// This reads cached values only and never invokes a descriptor or resolver.
  @internal
  // DIVERGES(chartjs): adapt-prepared-indexed-options, native bulk color plan.
  BarOptions Function(int)? prepareIndexedBarColors(List<Object> keys) {
    final template = BarOptions()..storeKey(OptionKey.dollarShared, false);
    final varying = _prepareIndexedColors(keys, template);
    if (varying == null) return null;
    return (index) {
      final result = template.clone();
      varying.storeInto(result, index);
      return result;
    };
  }

  /// A fresh options copy per native point, with static fields prepared once.
  /// The caller must stop using it before any user code can run.
  @internal
  // DIVERGES(chartjs): adapt-scatter-point-options, loop-local color plan.
  PointOptions Function(int)? prepareIndexedPointColors(List<Object> keys) {
    final template = PointOptions()..storeKey(OptionKey.dollarShared, false);
    final varying = _prepareIndexedColors(keys, template);
    if (varying == null) return null;
    return (index) {
      final result = template.clone();
      varying.storeInto(result, index);
      return result;
    };
  }

  /// A fresh options copy per native arc, with static fields prepared once.
  /// Only the colors vary and each of their entries is native: the result for
  /// each index differs only in the colors. The caller must stop using it
  /// before any user code can run.
  @internal
  // DIVERGES(chartjs): adapt-arc-native-options, loop-local color plan.
  ArcOptions Function(int)? prepareIndexedArcColors(List<Object> keys) {
    final template = ArcOptions()..storeKey(OptionKey.dollarShared, false);
    final varying = _prepareIndexedColors(keys, template);
    if (varying == null) return null;
    return (index) {
      final result = template.clone();
      varying.storeInto(result, index);
      return result;
    };
  }

  _VaryingColors? _prepareIndexedColors(
    List<Object> keys,
    ElementOptions template,
  ) {
    final plan = _indexedElementPlan;
    if (_slotsTouched ||
        plan == null ||
        !plan.matches(keys) ||
        !plan._rawListPlain) {
      return null;
    }
    OptionKey? firstKey;
    List<Object?>? firstValues;
    OptionKey? secondKey;
    List<Object?>? secondValues;
    for (var i = 0; i < plan.keys.length; i++) {
      final key = plan.keys[i];
      if (!template.knownKeyList.contains(key.jsName)) return null;
      final value = plan.values[i];
      if (i == plan.rawListAt) {
        template.storeKey(key, value);
      } else if (value is List<Object?>) {
        if ((key != OptionKey.backgroundColor &&
                key != OptionKey.borderColor) ||
            value.isEmpty ||
            !value.every(
              (entry) =>
                  entry == null ||
                  entry is Undefined ||
                  (entry is Color && !isObject(entry)),
            )) {
          return null;
        }
        // Each key is once in the plan, and two keys may vary: the colors.
        if (firstValues == null) {
          firstKey = key;
          firstValues = value;
        } else {
          secondKey = key;
          secondValues = value;
        }
      } else {
        if (!_nativeIndexedValue(key, value)) return null;
        template.storeKey(key, value);
      }
    }
    return firstValues == null
        ? null
        : _VaryingColors(firstKey!, firstValues, secondKey, secondValues);
  }

  /// Whether a read of a plain value through this resolver runs no user code:
  /// `operator []` of a custom Map scope is user code, and a write or a delete
  /// of a slot can replace the scopes. [peekKey] needs this.
  @internal
  // DIVERGES(chartjs): adapt-hidden-legend-items, the proof of a legend build.
  bool get scopesAreNative =>
      !_slotsTouched && _scopes.every(nativeOptionScope);

  /// The raw value of [key] with no effect: no write to the cache, and no sub
  /// resolver for an object, whose creation can call a function `_fallback` and
  /// read a custom Map. A proof that fails on this value leaves the read for
  /// its own point of the ordinary path. Only with [scopesAreNative].
  @internal
  // DIVERGES(chartjs): adapt-hidden-legend-items, the proof of a legend build.
  Object? peekKey(OptionKey key) {
    final cached = _cache.get(key);
    if (!identical(cached, _absent)) return cached;
    final name = key.jsName;
    for (final prefix in _prefixes) {
      final value = _resolve(_readKey(prefix, name), _scopes);
      if (!identical(value, undefined)) return value;
    }
    return undefined;
  }

  /// The native indexed plan of [keys] for the indexes below [count], or Dart
  /// `null`. It takes the descriptors, the first reads of a resolve, and calls
  /// none of them. An ordinary resolve stops at the first list and takes its
  /// context, so it reads the keys after that list later: this function peeks
  /// at each key ([peekKey]), and only when all of them are a scalar or a
  /// native list does it read them, which runs no user code and fills the cache
  /// of that resolve. Else the ordinary resolve does each read at its own
  /// point. The scopes are native (their check is for the caller).
  /// [descriptorGuard] and [kind] are the ones of a resolve of the caller.
  @internal
  // DIVERGES(chartjs): adapt-hidden-legend-items, the proof of a legend build.
  IndexedElementStyles? prepareIndexedStyles(
    List<Object> keys,
    ElementOptions kind,
    bool Function(Object?, Object?) descriptorGuard,
    int count,
  ) {
    if (_slotsTouched) return null;
    final warm = _indexedElementPlan;
    if (warm == null || !warm.matches(keys, immutable: true)) {
      descriptors(this);
      if (!descriptorGuard(
        _cache.get(OptionKey.descScriptable),
        _cache.get(OptionKey.descIndexable),
      )) {
        return null;
      }
      for (final key in keys) {
        if (key is! OptionKey || key.jsName.startsWith('_')) return null;
        final value = peekKey(key);
        if (!_indexedScalar(value) && !nativeIndexedList(value)) return null;
      }
      for (final key in keys) {
        readKey(key as OptionKey);
      }
      // Only the qualification of a resolve: no result, no write to [kind] and
      // no reader of this context, and it remembers a rejected key shape.
      resolveIndexedElementOptions(
        keys,
        () => _absent,
        kind,
        descriptorGuard,
        () => true,
        nativeInputs: true,
        immutableKeys: true,
        replacementOnly: true,
      );
    }
    final plan = _indexedElementPlan;
    if (plan == null || !plan.matches(keys, immutable: true)) return null;
    final styles = IndexedElementStyles._(this, plan, kind);
    return styles.covers(count) ? styles : null;
  }

  /// Copies already-resolved static fields while keeping each scriptable read
  /// at its original position, with fresh contextual views and live callbacks.
  /// [replacementOnly] treats [into] only as a type token; it is never written
  /// or returned. [immutableKeys] requires a native immutable key snapshot.
  @internal
  // DIVERGES(chartjs): adapt-scriptable-element-template, static fields.
  ({bool resolved, Object context, ElementOptions? prepared})?
  resolveScriptableElementOptions(
    List<Object> keys,
    Object Function() context,
    ElementOptions into,
    bool Function(Object?, Object?) descriptorGuard,
    bool Function() stillCached, {
    bool immutableKeys = false,
    bool replacementOnly = false,
    Object Function()? preparedContext,
  }) {
    if (_slotsTouched || !nativeIndexedResult(into)) return null;
    var plan = _scriptableElementPlan;
    if (plan == null ||
        !plan.matches(keys, immutable: immutableKeys) ||
        plan.template.runtimeType != into.runtimeType) {
      final size = _cache._keys?.length ?? 0;
      if (_scriptableRejectedSize == size) return null;
      ({bool resolved, Object context, ElementOptions? prepared})? reject() {
        _scriptableRejectedSize = size;
        return null;
      }

      if (!descriptorGuard(
            _cache.get(OptionKey.descScriptable),
            _cache.get(OptionKey.descIndexable),
          ) ||
          identical(_cache.get(OptionKey.descAllKeys), _absent)) {
        return reject();
      }
      final template = OptionResolver.newNativeResult(into)
        ..storeKey(OptionKey.dollarShared, false);
      final descriptors = _Descriptor(
        allKeys: false,
        scriptable: _cache.get(OptionKey.descScriptable) is Undefined
            ? true
            : _cache.get(OptionKey.descScriptable),
        indexable: _cache.get(OptionKey.descIndexable) is Undefined
            ? true
            : _cache.get(OptionKey.descIndexable),
      );
      final planKeys = <OptionKey>[];
      final colors = <_ScriptableColor>[];
      List<Object?>? rawList;
      for (final key in keys) {
        if (key is! OptionKey ||
            key.jsName.startsWith('_') ||
            !into.knownKeyList.contains(key.jsName)) {
          return reject();
        }
        final value = _cache.get(key);
        if (isFunction(value)) {
          // Only colors use the arbitrary-value slot without conversion or
          // foreign auditing. Other callbacks keep ordinary resolution. A key
          // that its descriptor makes not scriptable keeps its raw function.
          if ((key != OptionKey.backgroundColor &&
                  key != OptionKey.borderColor) ||
              !descriptors.isScriptable(key.jsName)) {
            return reject();
          }
          colors.add((key: key, callback: value, position: planKeys.length));
        } else if (_nativeRawList(key, value, descriptors)) {
          rawList = value! as List<Object?>;
          template.storeKey(key, value);
        } else {
          if (!_nativeIndexedValue(key, value)) return reject();
          template.storeKey(key, value);
        }
        planKeys.add(key);
      }
      if (colors.isEmpty) return reject();
      plan = _scriptableElementPlan = _ScriptableElementPlan(
        planKeys,
        colors,
        template,
        _cache.get(OptionKey.descScriptable),
        _cache.get(OptionKey.descIndexable),
        _cache.get(OptionKey.descAllKeys),
        rawList,
      );
    }
    // DIVERGES(chartjs): adapt-owned-option-result, read-only type token.
    if (!replacementOnly) into.storeKey(OptionKey.dollarShared, false);
    // DIVERGES(chartjs): adapt-native-point-context, a proven pure window.
    final ctx = (preparedContext ?? context)();
    if (!stillCached() ||
        !identical(plan, _scriptableElementPlan) ||
        !plan.matches(keys, immutable: immutableKeys) ||
        !plan.rawListPlain) {
      return (resolved: false, context: ctx, prepared: null);
    }
    return (
      resolved: true,
      context: ctx,
      prepared: plan.contextOnly
          ? _resolveScalarColors(plan, ctx)
          : _resolveContextualColors(plan, ctx),
    );
  }

  // DIVERGES(chartjs): adapt-scalar-color-resolution, keep the common path
  // outside the closure/view environment needed only by exceptional results.
  ElementOptions _resolveScalarColors(_ScriptableElementPlan plan, Object ctx) {
    final result = plan.template.clone();
    for (final color in plan.colors) {
      final value = jsCall1(color.callback, ctx);
      if (!_indexedScalar(value)) {
        return _finishScalarColors(plan, ctx, result, color.position, value);
      }
      result.storeKey(color.key, value);
      // A callback or a foreign-audit store may invalidate the raw resolver.
      // Resume at the next original key, including intervening static fields.
      if (!identical(plan, _scriptableElementPlan) || !plan.rawListPlain) {
        return _finishScalarColors(
          plan,
          ctx,
          result,
          color.position + 1,
          _absent,
        );
      }
    }
    return result;
  }

  ElementOptions _resolveContextualColors(
    _ScriptableElementPlan plan,
    Object ctx,
  ) {
    final view = plan.view(this, ctx);
    final result = plan.template.clone();
    for (final color in plan.colors) {
      result.storeKey(color.key, view.readKey(color.key));
      if (!identical(plan, _scriptableElementPlan) || !plan.rawListPlain) {
        _resolveColorTail(plan, view, result, color.position + 1);
        break;
      }
    }
    return result;
  }

  ElementOptions _finishScalarColors(
    _ScriptableElementPlan plan,
    Object ctx,
    ElementOptions result,
    int start,
    Object? returned,
  ) {
    final view = plan.view(this, ctx);
    var next = start;
    if (!identical(returned, _absent)) {
      final key = plan.keys[next++];
      result.storeKey(
        key,
        _resolveWithContext(view, key.jsName, key, returned),
      );
    }
    _resolveColorTail(plan, view, result, next);
    return result;
  }

  void _resolveColorTail(
    _ScriptableElementPlan plan,
    OptionView view,
    ElementOptions result,
    int start,
  ) {
    for (var i = start; i < plan.keys.length; i++) {
      final key = plan.keys[i];
      result.storeKey(key, view.readKey(key));
    }
  }

  /// Resolves native indexed scalar options from already cached raw values.
  /// Null means that context was not called. A failed result retains the one
  /// context call so the ordinary path can continue at attachContext.
  /// [replacementOnly] prevents writes/fill into a private type token. The
  /// caller must allocate its final result if this method declines.
  @internal
  // DIVERGES(chartjs): adapt-indexed-element-options, guarded cached plan.
  ({bool resolved, Object context, ElementOptions? prepared})?
  resolveIndexedElementOptions(
    List<Object> keys,
    Object Function() context,
    ElementOptions into,
    bool Function(Object?, Object?) descriptorGuard,
    bool Function() stillCached, {
    bool nativeInputs = false,
    bool allowReplacement = false,
    bool immutableKeys = false,
    bool replacementOnly = false,
    Object Function()? preparedContext,
  }) {
    if (_slotsTouched ||
        (!nativeInputs && !nativeIndexedList(keys)) ||
        !nativeIndexedResult(into)) {
      return null;
    }
    var plan = _indexedElementPlan;
    if (plan == null || !plan.matches(keys, immutable: immutableKeys)) {
      // Rejection is conservative across key shapes. Rechecking when the
      // cache grows lets an initially cold resolver qualify after ordinary
      // resolution, without taxing every scriptable element with a key scan.
      final size = _cache._keys?.length ?? 0;
      if (_indexedRejectedSize == size) return null;
      ({bool resolved, Object context, ElementOptions? prepared})? reject() {
        _indexedRejectedSize = size;
        return null;
      }

      final scriptable = _cache.get(OptionKey.descScriptable);
      final indexable = _cache.get(OptionKey.descIndexable);
      if (!descriptorGuard(scriptable, indexable) ||
          identical(_cache.get(OptionKey.descAllKeys), _absent)) {
        return reject();
      }
      final desc = _Descriptor(
        allKeys: false,
        scriptable: scriptable is Undefined ? true : scriptable,
        indexable: indexable is Undefined ? true : indexable,
      );
      final planKeys = <OptionKey>[];
      final values = <Object?>[];
      var indexed = false;
      var rawListAt = -1;
      for (final key in keys) {
        if (key is! OptionKey ||
            key.jsName.startsWith('_') ||
            !into.knownKeyList.contains(key.jsName)) {
          return reject();
        }
        final value = _cache.get(key);
        if (!_indexedScalar(value)) {
          if (_nativeRawList(key, value, desc)) {
            rawListAt = planKeys.length;
          } else {
            if (value is! List<Object?> ||
                !_nativeIndexedLists.contains(value.runtimeType) ||
                !desc.isIndexable(key.jsName)) {
              return reject();
            }
            indexed = true;
          }
        }
        planKeys.add(key);
        values.add(value);
      }
      if (!indexed) return reject();
      plan = _indexedElementPlan = _IndexedElementPlan(
        planKeys,
        values,
        rawListAt,
      );
    }
    // The context factory can observe or mutate the result supplied by its
    // caller. Preserve the upstream $shared store before invoking it.
    // DIVERGES(chartjs): adapt-owned-option-result, read-only type token.
    if (!replacementOnly) into.storeKey(OptionKey.dollarShared, false);
    // DIVERGES(chartjs): adapt-native-point-context, a proven pure window.
    final ctx = (preparedContext ?? context)();
    // An overridden controller/context factory can write/delete resolver keys.
    // Continue with its original context if it invalidates this snapshot.
    final valid =
        stillCached() &&
        identical(plan, _indexedElementPlan) &&
        plan.matches(keys, immutable: immutableKeys);
    final prepared = valid && allowReplacement
        ? plan.prepared(ctx, into)
        : null;
    final resolved =
        prepared != null || (!replacementOnly && valid && plan.fill(ctx, into));
    return (resolved: resolved, context: ctx, prepared: prepared);
  }

  /// `_keys` of the target (helpers.config.ts:419-425), or Dart `null`.
  List<String>? _keys;

  /// `_storage` of the target (helpers.config.ts:103), or [_absent].
  Object? _storage = _absent;

  /// The slot names that the `deleteProperty` trap removed. Dart `null`
  /// before the first such delete.
  Set<String>? _deletedSlots;

  /// Whether a `set` or a `delete` touched a slot name: then each read of a
  /// slot goes through [_own].
  bool _slotsTouched = false;

  /// The own property [name] of the target, or [_absent]: a cached or set
  /// value, else a slot (helpers.config.ts:41-49, `_keys`, `_storage`).
  Object? _own(String name) => _ownKeyed(name, _keyOf(name));

  /// [_own] with [key], the cache key of [name] ([_keyOf]).
  Object? _ownKeyed(String name, Object key) {
    final cached = _cache.get(key);
    if (!identical(cached, _absent)) return cached;
    if (_deletedSlots?.contains(name) ?? false) return _absent;
    return switch (name) {
      '_cacheable' => true,
      '_scopes' => _scopes,
      '_rootScopes' => _rootScopes,
      '_fallback' => _fallback,
      '_getTarget' => _getTarget,
      'override' => _override,
      '_keys' => _keys ?? _absent,
      '_storage' => _storage,
      _ => _absent,
    };
  }

  /// `target._scopes`, read as `jsGet(target, '_scopes')` upstream.
  Object? get _targetScopes =>
      _slotsTouched ? _ownOrUndefined('_scopes') : _scopes;

  /// `target._rootScopes`.
  Object? get _targetRootScopes =>
      _slotsTouched ? _ownOrUndefined('_rootScopes') : _rootScopes;

  /// `target._fallback`.
  Object? get _targetFallback =>
      _slotsTouched ? _ownOrUndefined('_fallback') : _fallback;

  /// `target._getTarget`.
  Object? get _targetGetTarget =>
      _slotsTouched ? _ownOrUndefined('_getTarget') : _getTarget;

  /// [_own], with [undefined] for a property that the target does not own:
  /// the result of `jsGet(target, name)`.
  Object? _ownOrUndefined(String name) {
    final value = _own(name);
    return identical(value, _absent) ? undefined : value;
  }

  /// helpers.config.ts:64 the `get` trap for the option name [prop]:
  /// `_cached(target, prop, () => _resolveWithPrefixes(...))`.
  Object? _get(String prop) => _getKeyed(prop, _keyOf(prop));

  /// [_get] with [key], the cache key of [prop] ([_keyOf]): the cache read,
  /// the typed scope reads of the empty prefix and the cache write of a
  /// first read take one lookup of the name.
  Object? _getKeyed(String prop, Object key) {
    // DIVERGES(chartjs): adapt-resolver-cached-read, _cached inline.
    final own = _ownKeyed(prop, key);
    if (!identical(own, _absent)) return own;
    if (prop == 'constructor') {
      // DIVERGES(chartjs): js-semantics-resolver-objects, no constructor.
      return undefined;
    }
    final value = _resolveWithPrefixes(prop, _prefixes, _scopes, this, key);
    // cache the resolved value
    _cache.set(key, value);
    return value;
  }

  /// The `get` trap for the key [key]: the typed read of the element step
  /// (Chart.js ADR 0054 §4). It gives the result of `this[key.jsName]`.
  Object? readKey(OptionKey key) {
    final cached = _cache.get(key);
    if (!identical(cached, _absent)) return cached;
    final name = key.jsName;
    // `_keyOf(name)` is [key]: one key for each name.
    if (name.startsWith('_') || _slotsTouched) return _getKeyed(name, key);
    final value = _resolveWithPrefixes(name, _prefixes, _scopes, this, key);
    _cache.set(key, value);
    return value;
  }

  /// The value that [readKey] starts from, with no sub resolver: making one
  /// calls the `_fallback` of an object, which can be a function of the user.
  // DIVERGES(chartjs): adapt-arc-native-options, a probe of a scalar value.
  Object? _rawValueOf(OptionKey key) {
    final cached = _cache.get(key);
    if (!identical(cached, _absent)) return cached;
    final name = key.jsName;
    for (final prefix in _prefixes) {
      final value = _resolve(_readKey(prefix, name), _scopes);
      if (!identical(value, undefined)) return value;
    }
    return undefined;
  }

  /// helpers.config.ts:54 the `deleteProperty` trap.
  ///
  /// A trap for the delete operator.
  void _deleteTrap(String key) {
    // remove from cache
    _removeOwn(key);
    // remove cached keys
    _removeOwn('_keys');
    _deleteProperty(_first(_scopes), key); // remove from top level scope
  }

  /// `delete target[name]` of the cache object.
  void _removeOwn(String name) {
    _scriptableElementPlan = null;
    _scriptableRejectedSize = -1;
    _indexedElementPlan = null;
    _indexedRejectedSize = -1;
    _cache.remove(_keyOf(name));
    switch (name) {
      case '_keys':
        _keys = null;
      case '_storage':
        _storage = _absent;
      case '_cacheable' ||
          '_scopes' ||
          '_rootScopes' ||
          '_fallback' ||
          '_getTarget' ||
          'override':
        (_deletedSlots ??= <String>{}).add(name);
        _slotsTouched = true;
    }
  }

  /// helpers.config.ts:64 the `get` trap.
  ///
  /// A trap for getting property values.
  @core.override
  Object? operator [](String name) => _get(name);

  /// helpers.config.ts:73 the `getOwnPropertyDescriptor` trap: whether the
  /// first scope owns [key].
  ///
  /// A trap for Object.getOwnPropertyDescriptor.
  /// Also used by Object.hasOwnProperty.
  ///
  /// The trap returns the descriptor of the first scope. Ported code reads
  /// only whether it exists: `Object.prototype.hasOwnProperty.call(resolver,
  /// key)` is `resolver.hasOwnProperty(key)`.
  bool hasOwnProperty(String key) {
    return _getOwnProperty(jsGet(_targetScopes, '0'), key);
  }

  // helpers.config.ts:80 the `getPrototypeOf` trap has no Dart form.
  // DIVERGES(chartjs): js-semantics-resolver-objects, no getPrototypeOf trap.

  /// helpers.config.ts:87 the `has` trap.
  ///
  /// A trap for the in operator.
  @core.override
  bool hasProperty(String name) {
    return _getKeysFromAllScopes(this).contains(name);
  }

  /// helpers.config.ts:94 the `ownKeys` trap.
  ///
  /// A trap for Object.getOwnPropertyNames and Object.getOwnPropertySymbols.
  @core.override
  List<String> ownKeys() => _getKeysFromAllScopes(this);

  /// `Object.keys(resolver)`: the `ownKeys` result filtered through the
  /// `getOwnPropertyDescriptor` trap ([hasOwnProperty]), in the trap order.
  @core.override
  List<String> objectKeys() => [
    for (final key in ownKeys())
      if (hasOwnProperty(key)) key,
  ];

  // The face of Chart.js ADR 0054 §5: the traps by name.

  /// `resolver[name]`: the `get` trap ([operator []]).
  @core.override
  Object? jsRead(String name) => _get(name);

  /// `resolver[name] = value`: the `set` trap ([operator []=]).
  @core.override
  void jsWrite(String name, Object? value) => this[name] = value;

  /// `Object.keys(resolver)` ([objectKeys]).
  @core.override
  List<String> jsKeys() => objectKeys();

  /// `Object.prototype.hasOwnProperty.call(resolver, name)`
  /// ([hasOwnProperty]).
  @core.override
  bool jsHas(String name) => hasOwnProperty(name);

  /// `delete resolver[name]`: the `deleteProperty` trap. It returns
  /// whether the resolver owned [name] before.
  @core.override
  bool jsDelete(String name) {
    final owned = hasOwnProperty(name);
    _deleteTrap(name);
    return owned;
  }

  /// helpers.config.ts:101 the `set` trap.
  ///
  /// A trap for setting property values.
  @core.override
  void operator []=(String key, Object? value) {
    _scriptableElementPlan = null;
    _scriptableRejectedSize = -1;
    _indexedElementPlan = null;
    _indexedRejectedSize = -1;
    final current = _ownOrUndefined('_storage');
    final Object? storage;
    if (jsTruthy(current)) {
      storage = current;
    } else {
      storage = _storage = _getTarget();
      _cache.remove(_keyOf('_storage'));
    }
    // set to top level scope + cache
    _set(storage, key, value);
    _cache.set(_keyOf(key), value);
    if (key.startsWith('_') || key == 'override') {
      _deletedSlots?.remove(key);
      _slotsTouched = true;
    }
    _removeOwn('_keys'); // remove cached keys
  }

  /// helpers.config.types.ts:11 `_cacheable`: `true`.
  @internal
  @core.override
  bool get cacheable => jsTruthy(this['_cacheable']);

  /// helpers.config.types.ts:12 `_scopes`.
  @internal
  @core.override
  List<Object?> get scopes => this['_scopes']! as List<Object?>;

  /// helpers.config.types.ts:13 `_rootScopes`.
  @internal
  @core.override
  List<Object?> get rootScopes => this['_rootScopes']! as List<Object?>;

  /// helpers.config.types.ts:14 `_fallback`.
  @internal
  @core.override
  ResolverObjectKey get fallback => this['_fallback'];

  /// helpers.config.types.ts:20 `_getTarget()`.
  @internal
  @core.override
  Object? Function() get getTarget =>
      () => (this['_getTarget']! as Object? Function())();

  /// helpers.config.ts:48 `override(scope)`: a resolver with [scope] in
  /// front of the scopes.
  @core.override
  OptionResolver override(Object scope) {
    return (this['override']! as OptionResolver Function(Object))(scope);
  }

  /// The names of the own properties of the cache object, in their order.
  Iterable<String> get _targetNames sync* {
    final deleted = _deletedSlots;
    for (final name in const [
      '_cacheable',
      '_scopes',
      '_rootScopes',
      '_fallback',
      '_getTarget',
      'override',
    ]) {
      if (deleted == null || !deleted.contains(name)) yield name;
    }
    if (_keys != null) yield '_keys';
    if (!identical(_storage, _absent)) yield '_storage';
    yield* _cache.names;
  }

  /// A description that resolves no option. Upstream has no counterpart.
  /// `String(resolver)` is `jsToString`, which gives `'[object Object]'`.
  @core.override
  String toString() => 'Resolver(cache: ${_targetNames.join(', ')})';
}

/// The typed read `options[key.jsName]` of an options object of another
/// module (Chart.js ADR 0054 §4): `readKey` of an [OptionView] or an
/// [OptionResolver], else the JS property read [jsGet]. The chart options,
/// the scale options, the plugin options and the dataset options are
/// views; a test can give a raw Map. The style object of a controller is a
/// typed [ElementOptions]: its [ElementOptions.valueOf]. A typed scope, for
/// example the root, the data or a dataset of a typed config, reads its cell
/// by [OptionScope.readKey] (Chart.js ADR 0096). Upstream reads the property
/// by name. Port-only.
Object? readOption(Object? options, OptionKey key) => switch (options) {
  final OptionView view => view.readKey(key),
  final OptionResolver resolver => resolver.readKey(key),
  final ElementOptions elementOptions => elementOptions.valueOf(key),
  final OptionScope scope => scope.readKey(key),
  _ => jsGet(options, key.jsName),
};

/// helpers.config.ts:118 `_attachContext`.
///
/// Returns an Proxy for resolving option values with context.
/// @param proxy - The Proxy returned by `_createResolver`
/// @param context - Context object for scriptable/indexable options
/// @param subProxy - The proxy provided for scriptable options
/// @param descriptorDefaults - Defaults for descriptors
/// @private
///
/// [proxy] is `Object?`. `_resolveArray` can give it the `false` of
/// `createSubResolver`, and `_resolveWithContext` a value that a caller has
/// set. The default of [subProxy] is the [undefined] sentinel. A null
/// [descriptorDefaults] is an absent argument: JS `null` never reaches it.
OptionView attachContext(
  Object? proxy,
  Object context, [
  Object? subProxy = undefined,
  DescriptorDefaults? descriptorDefaults,
]) {
  return OptionView._(
    proxy,
    context,
    subProxy,
    descriptors(proxy, descriptorDefaults),
    descriptorDefaults,
  );
}

/// The target of `_attachContext` (helpers.config.ts:127-136) and its
/// `Proxy` (helpers.config.ts:137-194), as one typed class (Chart.js ADR
/// 0054 §4).
///
/// The slots of the cache object are fields. The cached option values are a
/// typed table. The library documentation lists the trap of each member.
final class OptionView implements ContextProxy {
  OptionView._(
    this._proxy,
    this._context,
    this._subProxy,
    this._descriptors,
    this._descriptorDefaults,
  );

  /// The `proxy` parameter of `_attachContext`: `_proxy` of the target.
  final Object? _proxy;

  /// `_context` of the target.
  final Object _context;

  /// `_subProxy` of the target.
  final Object? _subProxy;

  /// `_stack` of the target.
  final Set<String> _stack = <String>{};

  /// `_descriptors` of the target.
  final Descriptor _descriptors;

  /// The `descriptorDefaults` parameter of `_attachContext`.
  final DescriptorDefaults? _descriptorDefaults;

  /// The resolver under this view: the `proxy` parameter of
  /// `_attachContext`. A range update of the chart attaches a new context to
  /// it where `update` makes a new resolver (Chart.js ADR 0111). The read
  /// takes the field: a delete of the slot `_proxy` does not hide it.
  @internal
  // DIVERGES(chartjs): adapt-range-updates, the kept resolver of a view.
  Object? get resolver => _proxy;

  /// `setContext` of the target (helpers.config.ts:134).
  // One function value for each target, as the upstream cache object
  // holds one.
  // ignore: prefer_function_declarations_over_variables
  late final OptionView Function(Object ctx) _setContext = (ctx) =>
      attachContext(_proxy, ctx, _subProxy, _descriptorDefaults);

  /// `override` of the target (helpers.config.ts:135).
  // One function value for each target, as the upstream cache object
  // holds one.
  // ignore: prefer_function_declarations_over_variables
  late final OptionView Function(Object scope) _override = (scope) =>
      attachContext(
        jsCall(jsGet(_proxy, 'override'), [scope], thisArg: _proxy),
        _context,
        _subProxy,
        _descriptorDefaults,
      );

  /// The cached option values.
  final _Cache _cache = _Cache();

  /// The slot names that the `set` or `deleteProperty` trap removed from
  /// the cache object. Dart `null` before the first one.
  Set<String>? _removedSlots;

  /// The already-resolved static `TextStyle` of `ticks.font`, or null when a
  /// fresh context can change it. This probe never resolves an uncached
  /// property, invokes a descriptor, or populates a contextual view's cache.
  ///
  /// Only the ordinary setContext/descriptor path is eligible. The caller
  /// still creates the tick context, checks the global font fallback and
  /// compares the font on every call; resolver writes/deletes are visible.
  /// A font function stays in the cache as a function: no static font.
  @internal
  TextStyle? cachedStaticFont([TextStyle? fallback]) {
    // DIVERGES(chartjs): adapt-static-tick-font, cached static fonts only.
    final proxy = _staticProxy;
    if (proxy == null) return null;
    final font = proxy._cache.get(OptionKey.font);
    // An absent ticks.font uses the live global font. The caller supplies it
    // only after ruling out routed or custom fallback getters.
    if (identical(font, undefined)) return fallback;
    return font is TextStyle ? font : null;
  }

  /// The resolver of this ordinary setContext/descriptor view, or null when a
  /// write or a custom descriptor can make a read differ from the cached one.
  OptionResolver? get _staticProxy {
    if (_removedSlots != null ||
        jsTruthy(_subProxy) ||
        (_descriptorDefaults != null && _descriptorDefaults is! _Descriptor)) {
      return null;
    }
    final proxy = _proxy;
    return proxy is OptionResolver && _hasCachedDescriptors(proxy)
        ? proxy
        : null;
  }

  /// The raw value of [key] that a read through a view of any new context
  /// starts from, without resolving or invoking anything. A private marker
  /// that is none of the plain types stands for an unknown value.
  ///
  /// The caller accepts only values that pass `_resolveWithContext` unchanged
  /// (a number, a string, ...): a function or an array is a value of this
  /// probe, which it must decline.
  @internal
  // DIVERGES(chartjs): adapt-radial-static-plans, inspect only resolved values.
  Object? cachedStaticValue(OptionKey key) {
    final proxy = _staticProxy;
    return proxy == null ? _absent : proxy._cache.get(key);
  }

  /// Whether a read of [key] gives a value of this view's cache: no resolution
  /// and no user code run. The value may come from a scriptable option.
  @internal
  // DIVERGES(chartjs): adapt-radial-static-plans, inspect only resolved values.
  bool hasCachedValue(OptionKey key) => !identical(_cache.get(key), _absent);

  /// These are the reads of attachContext that the fast path omits. A missing
  /// entry or a changed resolver slot must go through the ordinary reads.
  static bool _hasCachedDescriptors(OptionResolver proxy) =>
      !proxy._slotsTouched &&
      !identical(proxy._cache.get(OptionKey.descScriptable), _absent) &&
      !identical(proxy._cache.get(OptionKey.descIndexable), _absent) &&
      !identical(proxy._cache.get(OptionKey.descAllKeys), _absent);

  /// Whether the raw values of [keys] are scalars in native scopes: a read of
  /// them through this view, also its first, runs no user code and stores the
  /// raw value. `operator []` of a custom Map scope is user code: its reads
  /// keep their original order and position.
  @internal
  // DIVERGES(chartjs): adapt-arc-native-options, no user code until a rewrite.
  bool rawOptionsAreScalar(List<OptionKey> keys) {
    final proxy = _proxy;
    if (proxy is! OptionResolver ||
        _removedSlots != null ||
        proxy._slotsTouched ||
        !proxy._scopes.every(nativeOptionScope)) {
      return false;
    }
    for (final key in keys) {
      if (!_indexedScalar(proxy._rawValueOf(key))) return false;
    }
    return true;
  }

  /// Whether each option that the resolver of this view read so far has a raw
  /// value that is no function, in native scopes: a data-only update keeps the
  /// results of this view, and a scriptable option would run again in a full
  /// update. The scopes include the defaults and the overrides.
  @internal
  // DIVERGES(chartjs): adapt-data-update-indexed-plan, the dataset options.
  bool get readsNoFunctionValue {
    final proxy = _proxy;
    if (proxy is! OptionResolver ||
        _removedSlots != null ||
        proxy._slotsTouched ||
        !proxy._scopes.every(nativeOptionScope)) {
      return false;
    }
    final keys = proxy._cache._keys ?? const <Object>[];
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final name = key is OptionKey ? key.jsName : key as String;
      // A name with `_` is a descriptor or a slot, not an option.
      if (!name.startsWith('_') && isFunction(proxy._cache._values![i])) {
        return false;
      }
    }
    return true;
  }

  /// A cached cartesian index axis, without resolving or invoking anything.
  @internal
  // DIVERGES(chartjs): adapt-live-bar-layout, inspect only resolved values.
  CartesianAxis? get cachedBarIndexAxis {
    if (runtimeType != OptionView) return null;
    return switch (_cache.get(OptionKey.indexAxis)) {
      final XAxis axis => axis,
      final YAxis axis => axis,
      _ => null,
    };
  }

  /// True only when category-trait reads are cached primitives. The normal
  /// range computation then cannot invoke user code between topology reads.
  @internal
  bool get hasCachedStaticBarTraits {
    if (runtimeType != OptionView) return false;
    final thickness = _cache.get(OptionKey.barThickness);
    if (thickness is num) return true;
    return (identical(thickness, undefined) ||
            (thickness is String && thickness == 'flex')) &&
        _cache.get(OptionKey.categoryPercentage) is num &&
        _cache.get(OptionKey.barPercentage) is num;
  }

  /// Already-resolved inputs for a numeric, uniform-category bulk update.
  /// Missing values are rejected rather than resolved during qualification.
  @internal
  // DIVERGES(chartjs): adapt-bulk-bar-update, cached scalar probes only.
  BulkBarOptions? get cachedBulkBarOptions {
    final base = _cache.get(OptionKey.base);
    final minimum = _cache.get(OptionKey.minBarLength);
    final skip = _cache.get(OptionKey.skipNull);
    final thickness = _cache.get(OptionKey.barThickness);
    final maximum = _cache.get(OptionKey.maxBarThickness);
    // Undefined converts to NaN: the min-length comparison is then false.
    final noMinimum =
        identical(minimum, undefined) ||
        minimum == null ||
        (minimum is num && (minimum.isNaN || minimum <= 0));
    if (!noMinimum ||
        !(identical(skip, undefined) ||
            skip == null ||
            identical(skip, false) ||
            (skip is num && skip == 0))) {
      return null;
    }
    final double baseNumber;
    if (base == null || identical(base, undefined)) {
      baseNumber = 0;
    } else if (base is num && base.isFinite && base == base.toDouble()) {
      baseNumber = base.toDouble();
    } else {
      return null;
    }
    final double? thicknessNumber;
    if (thickness == null || identical(thickness, undefined)) {
      thicknessNumber = null;
    } else if (thickness is num && thickness.isFinite && thickness >= 0) {
      thicknessNumber = thickness.toDouble();
    } else {
      return null;
    }
    final double maxNumber;
    if (identical(maximum, undefined)) {
      maxNumber = double.infinity;
    } else if (maximum is num && !maximum.isNaN && maximum >= 0) {
      maxNumber = maximum.toDouble();
    } else {
      return null;
    }
    var category = 1.0;
    var bar = 1.0;
    if (thicknessNumber == null) {
      final cp = _cache.get(OptionKey.categoryPercentage);
      final bp = _cache.get(OptionKey.barPercentage);
      if (cp is! num ||
          bp is! num ||
          !cp.isFinite ||
          !bp.isFinite ||
          cp < 0 ||
          bp < 0) {
        return null;
      }
      category = cp.toDouble();
      bar = bp.toDouble();
    }
    return (
      base: baseNumber,
      thickness: thicknessNumber,
      categoryPercentage: category,
      barPercentage: bar,
      maxThickness: maxNumber,
    );
  }

  /// Null means unsupported; false means the cached visibility/display path
  /// returns zero before reading ticks; true means a static numeric grid.
  @internal
  bool? get cachedBulkBarGridUsesTicks {
    final display = _cache.get(OptionKey.display);
    final grid = _cache.get(OptionKey.grid);
    if (identical(grid, _absent)) return null;
    if (identical(display, false)) return false;
    if (!identical(display, true) || grid is! OptionView) return null;
    final gridDisplay = grid._cache.get(OptionKey.display);
    if (identical(gridDisplay, false)) return false;
    if (!identical(gridDisplay, true) ||
        grid._removedSlots != null ||
        jsTruthy(grid._subProxy) ||
        (grid._descriptorDefaults != null &&
            grid._descriptorDefaults is! _Descriptor)) {
      return null;
    }
    final proxy = grid._proxy;
    if (proxy is! OptionResolver ||
        !_hasCachedDescriptors(proxy) ||
        proxy._cache.get(OptionKey.lineWidth) is! num) {
      return null;
    }
    return true;
  }

  /// Whether the normal grouped read is already a cached boolean.
  @internal
  bool get hasCachedBarGrouping =>
      runtimeType == OptionView && _cache.get(OptionKey.grouped) is bool;

  /// Whether the normal stacked read is cached and cannot call user code.
  @internal
  bool get hasCachedBarStacking {
    if (runtimeType != OptionView) return false;
    final value = _cache.get(OptionKey.stacked);
    return value is bool || identical(value, undefined);
  }

  /// Label-source options already read by the first category callback. Never
  /// execute a scriptable option merely to qualify a bulk-label fast path.
  @internal
  ({Object? labels, ChartPosition? position})? cachedCategoryLabelSource() {
    // DIVERGES(chartjs): adapt-category-label-dispatch, cached source inputs.
    final labels = _cache.get(OptionKey.labels);
    if (identical(labels, _absent)) return null;
    if (jsTruthy(labels)) return (labels: labels, position: null);
    final position = _cache.get(OptionKey.position);
    return position is ChartPosition
        ? (labels: labels, position: position)
        : null;
  }

  /// A fixed numeric range must come from numeric inputs, not a callback that
  /// happened to resolve to a number in the preceding full update.
  @internal
  bool get cachedFixedDataBounds {
    final proxy = _proxy;
    if (proxy is! OptionResolver || _removedSlots != null) return false;
    final min = proxy._cache.get(OptionKey.min);
    final max = proxy._cache.get(OptionKey.max);
    return min is num && max is num && min.isFinite && max.isFinite;
  }

  /// Category bounds/source may be absent, but cannot be scriptable inputs.
  /// The limits of a category scale come from the data unless `bounds` is
  /// `'ticks'` (scale.category.js:84).
  @internal
  bool get cachedCategoryDataInputs {
    final proxy = _proxy;
    if (proxy is! OptionResolver || _removedSlots != null) return false;
    bool bound(Object? value) =>
        value == null ||
        identical(value, undefined) ||
        value is String ||
        (value is num && value.isFinite);
    final labels = proxy._cache.get(OptionKey.labels);
    // DIVERGES(chartjs): adapt-scale-option-enums, the enum value.
    return proxy._cache.get(OptionKey.bounds) == ScaleBounds.ticks &&
        bound(proxy._cache.get(OptionKey.min)) &&
        bound(proxy._cache.get(OptionKey.max)) &&
        !identical(labels, _absent) &&
        !jsIsFunction(labels);
  }

  /// The own property [name] of the target, or [_absent].
  Object? _own(String name) => _ownKeyed(name, _keyOf(name));

  /// [_own] with [key], the cache key of [name] ([_keyOf]).
  Object? _ownKeyed(String name, Object key) {
    final cached = _cache.get(key);
    if (!identical(cached, _absent)) return cached;
    if (_removedSlots?.contains(name) ?? false) return _absent;
    return switch (name) {
      '_cacheable' => false,
      '_proxy' => _proxy,
      '_context' => _context,
      '_subProxy' => _subProxy,
      '_stack' => _stack,
      '_descriptors' => _descriptors,
      'setContext' => _setContext,
      'override' => _override,
      _ => _absent,
    };
  }

  /// `jsGet(target, name)` of a slot name.
  Object? _slot(String name) {
    if (_removedSlots == null) {
      return switch (name) {
        '_proxy' => _proxy,
        '_context' => _context,
        '_subProxy' => _subProxy,
        '_stack' => _stack,
        '_descriptors' => _descriptors,
        _ => _own(name),
      };
    }
    final value = _own(name);
    return identical(value, _absent) ? undefined : value;
  }

  /// helpers.config.ts:150 the `get` trap for the option name [prop]. The
  /// receiver is this view.
  Object? _get(String prop) {
    // One lookup of the name for the cache read and the cache write.
    final key = _keyOf(prop);
    // DIVERGES(chartjs): adapt-resolver-cached-read, _cached inline.
    final own = _ownKeyed(prop, key);
    if (!identical(own, _absent)) return own;
    if (prop == 'constructor') {
      // DIVERGES(chartjs): js-semantics-resolver-objects, no constructor.
      return undefined;
    }
    final value = _resolveWithContext(this, prop, null);
    // cache the resolved value
    _cache.set(key, value);
    return value;
  }

  /// The `get` trap for the key [key]: the typed read of the element step
  /// (Chart.js ADR 0054 §4). It gives the result of `this[key.jsName]`.
  Object? readKey(OptionKey key) {
    final cached = _cache.get(key);
    if (!identical(cached, _absent)) return cached;
    final name = key.jsName;
    if (name.startsWith('_')) return _get(name);
    final value = _resolveWithContext(this, name, key);
    _cache.set(key, value);
    return value;
  }

  /// helpers.config.ts:141 the `deleteProperty` trap.
  ///
  /// A trap for the delete operator.
  void _deleteTrap(String key) {
    _removeOwn(key); // remove from cache
    _deleteProperty(_proxy, key); // remove from proxy
  }

  /// `delete target[name]` of the cache object.
  void _removeOwn(String name) {
    _cache.remove(_keyOf(name));
    switch (name) {
      case '_cacheable' ||
          '_proxy' ||
          '_context' ||
          '_subProxy' ||
          '_stack' ||
          '_descriptors' ||
          'setContext' ||
          'override':
        (_removedSlots ??= <String>{}).add(name);
    }
  }

  /// helpers.config.ts:150 the `get` trap. The receiver is this resolver.
  ///
  /// A trap for getting property values.
  @core.override
  Object? operator [](String name) => _get(name);

  /// helpers.config.ts:159 the `getOwnPropertyDescriptor` trap: whether a
  /// descriptor exists for [key].
  ///
  /// A trap for Object.getOwnPropertyDescriptor.
  /// Also used by Object.hasOwnProperty.
  bool hasOwnProperty(String key) {
    final descriptors = _slot('_descriptors')! as Descriptor;
    return jsTruthy(descriptors.allKeys)
        ? _has(_proxy, key)
        : _getOwnProperty(_proxy, key);
  }

  // helpers.config.ts:168 the `getPrototypeOf` trap has no Dart form.
  // DIVERGES(chartjs): js-semantics-resolver-objects, no getPrototypeOf trap.

  /// helpers.config.ts:175 the `has` trap.
  ///
  /// A trap for the in operator.
  @core.override
  bool hasProperty(String name) {
    return _has(_proxy, name);
  }

  /// helpers.config.ts:182 the `ownKeys` trap.
  ///
  /// A trap for Object.getOwnPropertyNames and Object.getOwnPropertySymbols.
  @core.override
  List<String> ownKeys() => _reflectOwnKeys(_proxy);

  /// `Object.keys(resolver)`: the `ownKeys` result filtered through the
  /// `getOwnPropertyDescriptor` trap ([hasOwnProperty]), in the trap order.
  @core.override
  List<String> objectKeys() => [
    for (final key in ownKeys())
      if (hasOwnProperty(key)) key,
  ];

  // The face of Chart.js ADR 0054 §5: the traps by name.

  /// `resolver[name]`: the `get` trap ([operator []]).
  @core.override
  Object? jsRead(String name) => _get(name);

  /// `resolver[name] = value`: the `set` trap ([operator []=]).
  @core.override
  void jsWrite(String name, Object? value) => this[name] = value;

  /// `Object.keys(resolver)` ([objectKeys]).
  @core.override
  List<String> jsKeys() => objectKeys();

  /// `Object.prototype.hasOwnProperty.call(resolver, name)`
  /// ([hasOwnProperty]).
  @core.override
  bool jsHas(String name) => hasOwnProperty(name);

  /// `delete resolver[name]`: the `deleteProperty` trap. It returns
  /// whether the resolver owned [name] before.
  @core.override
  bool jsDelete(String name) {
    final owned = hasOwnProperty(name);
    _deleteTrap(name);
    return owned;
  }

  /// helpers.config.ts:189 the `set` trap.
  ///
  /// A trap for setting property values.
  @core.override
  void operator []=(String key, Object? value) {
    _set(_proxy, key, value); // set to proxy
    _removeOwn(key); // remove from cache
  }

  /// helpers.config.types.ts:47 `_cacheable`: `false`.
  @internal
  @core.override
  bool get cacheable => jsTruthy(this['_cacheable']);

  /// helpers.config.types.ts:48 `_proxy`.
  @internal
  @core.override
  Object? get proxy => this['_proxy'];

  /// helpers.config.types.ts:49 `_context`.
  @internal
  @core.override
  Object get context => this['_context']!;

  /// helpers.config.types.ts:50 `_subProxy`.
  @internal
  @core.override
  Object? get subProxy => this['_subProxy'];

  /// helpers.config.types.ts:51 `_stack`.
  @internal
  @core.override
  Set<String> get stack => this['_stack']! as Set<String>;

  /// helpers.config.types.ts:52 `_descriptors`.
  @internal
  @core.override
  Descriptor get descriptors => this['_descriptors']! as Descriptor;

  /// helpers.config.ts:134 `setContext(ctx)`: a resolver over the same
  /// proxy with the context [ctx].
  @core.override
  OptionView setContext(Object ctx) {
    return (this['setContext']! as OptionView Function(Object))(ctx);
  }

  /// helpers.config.ts:135 `override(scope)`: a resolver with [scope] in
  /// front of the scopes.
  @core.override
  OptionView override(Object scope) {
    return (this['override']! as OptionView Function(Object))(scope);
  }

  /// The names of the own properties of the cache object, in their order.
  Iterable<String> get _targetNames sync* {
    final removed = _removedSlots;
    for (final name in const [
      '_cacheable',
      '_proxy',
      '_context',
      '_subProxy',
      '_stack',
      '_descriptors',
      'setContext',
      'override',
    ]) {
      if (removed == null || !removed.contains(name)) yield name;
    }
    yield* _cache.names;
  }

  /// A description that resolves no option. Upstream has no counterpart.
  /// `String(resolver)` is `jsToString`, which gives `'[object Object]'`.
  @core.override
  String toString() => 'ContextResolver(cache: ${_targetNames.join(', ')})';
}

/// helpers.config.ts:200 `_descriptors`.
/// @private
///
/// The destructuring defaults of upstream apply to the [undefined]
/// sentinel. Dart `null` (JS `null`) is a value. A null [defaults] is an
/// absent argument: JS `null` never reaches it.
Descriptor descriptors(Object? proxy, [DescriptorDefaults? defaults]) {
  final descriptorDefaults =
      defaults ?? const DescriptorDefaults(scriptable: true, indexable: true);
  var scriptable = jsGet(proxy, '_scriptable');
  if (identical(scriptable, undefined)) {
    scriptable = descriptorDefaults.scriptable;
  }
  var indexable = jsGet(proxy, '_indexable');
  if (identical(indexable, undefined)) {
    indexable = descriptorDefaults.indexable;
  }
  var allKeys = jsGet(proxy, '_allKeys');
  if (identical(allKeys, undefined)) {
    allKeys = descriptorDefaults.allKeys;
  }
  return _Descriptor(
    allKeys: allKeys,
    scriptable: scriptable,
    indexable: indexable,
  );
}

/// The object literal that `_descriptors` returns (helpers.config.ts:205).
///
/// `isScriptable` and `isIndexable` call a function value through [jsCall1]
/// with no `this`, as the detached calls of upstream do
/// (`core.config.js:409-410` and helpers.config.ts:283). The method call at
/// :242 is `_isScriptableMethod`. They return the ToBoolean of the result
/// ([jsTruthy]), because every caller tests only its truth.
final class _Descriptor implements Descriptor {
  _Descriptor({
    required this.allKeys,
    required this.scriptable,
    required this.indexable,
  });

  /// helpers.config.ts:206 `allKeys`.
  @override
  final Object? allKeys;

  /// helpers.config.ts:207 `scriptable`.
  @override
  final Object? scriptable;

  /// helpers.config.ts:208 `indexable`.
  @override
  final Object? indexable;

  /// helpers.config.ts:209 `isScriptable`.
  @override
  bool isScriptable(String key) => jsTruthy(
    isFunction(scriptable) ? jsCall1(scriptable, key) : scriptable,
  );

  /// helpers.config.ts:210 `isIndexable`.
  @override
  bool isIndexable(String key) =>
      jsTruthy(isFunction(indexable) ? jsCall1(indexable, key) : indexable);
}

/// helpers.config.ts:214 `readKey`.
String _readKey(String prefix, String name) =>
    prefix.isNotEmpty ? prefix + capitalize(name) : name;

/// helpers.config.ts:215 `needsSubResolver`.
///
/// Upstream also requires `Object.getPrototypeOf(value) === null ||
/// value.constructor === Object`. [isObject] is true only for a Map and a
/// typed scope, and both stand for a plain object (Chart.js ADR 0054 §5). A
/// resolver is a Map too: upstream finds `Object` as its constructor
/// through `_cached`.
bool _needsSubResolver(String prop, Object? value) =>
    isObject(value) && prop != 'adapters';

/// helpers.config.ts:233 `_resolveWithContext`. The receiver is [view].
/// [key] is the [OptionKey] of [prop] for the typed read of the proxy, or
/// Dart `null`.
Object? _resolveWithContext(
  OptionView view,
  String prop,
  OptionKey? key, [
  Object? returned = _absent,
]) {
  final proxy = view._slot('_proxy');
  final context = view._slot('_context');
  final subProxy = view._slot('_subProxy');
  final descriptors = view._slot('_descriptors')! as Descriptor;
  // resolve from proxy
  final alreadyCalled = !identical(returned, _absent);
  var value = alreadyCalled
      ? returned
      : proxy is OptionResolver
      ? key == null
            ? proxy._get(prop)
            : proxy.readKey(key)
      : jsGet(proxy, prop);
  if (alreadyCalled) value = _resolveScriptableReturn(prop, value, proxy);

  // resolve with context
  if (!alreadyCalled &&
      isFunction(value) &&
      _isScriptableMethod(descriptors, prop)) {
    value = _resolveScriptable(prop, value, view, view);
  }
  if (isArray(value) && (value! as List<Object?>).isNotEmpty) {
    value = _resolveArray(
      prop,
      value as List<Object?>,
      view,
      descriptors.isIndexable,
    );
  }
  if (_needsSubResolver(prop, value)) {
    // if the resolved value is an object, create a sub resolver for it
    value = attachContext(
      value,
      context!,
      jsTruthy(subProxy) ? jsGet(subProxy, prop) : subProxy,
      descriptors,
    );
  }
  return value;
}

/// `descriptors.isScriptable(prop)` at helpers.config.ts:242: a method call.
///
/// A function `_scriptable` gets [descriptors] as `this`, as upstream gives
/// the descriptor object. The result is the ToBoolean of its result.
bool _isScriptableMethod(Descriptor descriptors, String prop) {
  final scriptable = descriptors.scriptable;
  return jsTruthy(
    isFunction(scriptable)
        ? jsCall1(scriptable, prop, thisArg: descriptors)
        : scriptable,
  );
}

/// helpers.config.ts:255 `_resolveScriptable`.
///
/// [getValue] is a function value. It gets the context and the
/// sub-resolver, or the [receiver], through [jsCall]. Upstream throws an
/// `Error` on recursion. The port throws a [StateError] with the same
/// message.
Object? _resolveScriptable(
  String prop,
  Object? getValue,
  OptionView target,
  OptionView receiver,
) {
  final proxy = target._slot('_proxy');
  final context = target._slot('_context');
  final subProxy = target._slot('_subProxy');
  final stack = target._slot('_stack')! as Set<String>;
  if (stack.contains(prop)) {
    throw StateError('Recursion detected: ${stack.join('->')}->$prop');
  }
  stack.add(prop);
  final options = jsTruthy(subProxy) ? subProxy : receiver;
  final value = jsCall(getValue, [context, options]);
  stack.remove(prop);
  return _resolveScriptableReturn(prop, value, proxy);
}

Object? _resolveScriptableReturn(String prop, Object? value, Object? proxy) {
  // DIVERGES(chartjs): adapt-text-style-fonts, a returned font merges too.
  if (value is TextStyle) {
    return _mergeTextStyles(
      _targetGet(proxy, '_scopes')! as List<Object?>,
      proxy,
      prop,
      value,
    );
  }
  if (_needsSubResolver(prop, value)) {
    // When scriptable option returns an object, create a resolver on that.
    return _createSubResolver(
      jsGet(proxy, '_scopes')! as List<Object?>,
      proxy,
      prop,
      value,
    );
  }
  return value;
}

/// helpers.config.ts:275 `_resolveArray`.
///
/// `value[_context.index % value.length]` is a property read with the
/// ToString of the remainder. Thus an index that is not an integer from 0
/// gives the [undefined] sentinel, as in JavaScript.
Object? _resolveArray(
  String prop,
  List<Object?> value,
  OptionView target,
  bool Function(String key) isIndexable,
) {
  final proxy = target._slot('_proxy');
  final context = target._slot('_context');
  final subProxy = target._slot('_subProxy');
  final descriptors = target._slot('_descriptors')! as Descriptor;

  final index = jsGet(context, 'index');
  if (!identical(index, undefined) && isIndexable(prop)) {
    final remainder = jsToNumber(index).remainder(value.length);
    return jsGet(
      value,
      jsNumberToString(remainder),
    );
  } else if (isObject(value[0])) {
    // Array of objects, return array or resolvers
    final arr = value;
    final scopes = (jsGet(proxy, '_scopes')! as List<Object?>)
        .where((s) => !identical(s, arr))
        .toList();
    final resolvers = <Object?>[];
    for (final item in arr) {
      final resolver = _createSubResolver(scopes, proxy, prop, item);
      resolvers.add(
        attachContext(
          resolver,
          context!,
          jsTruthy(subProxy) ? jsGet(subProxy, prop) : subProxy,
          descriptors,
        ),
      );
    }
    return resolvers;
  }
  return value;
}

/// helpers.config.ts:298 `resolveFallback`.
ResolverObjectKey _resolveFallback(
  Object? fallback,
  ResolverObjectKey prop,
  Object? value,
) {
  return isFunction(fallback) ? jsCall(fallback, [prop, value]) : fallback;
}

/// helpers.config.ts:306 `getScope`.
Object? _getScope(ResolverObjectKey key, Object? parent) => key == true
    ? parent
    : key is String
    ? resolveObjectKey(parent, key)
    : undefined;

/// helpers.config.ts:309 `addScopes`.
///
/// `===` and `!==` are `==` and `!=`: the keys are strings and booleans.
///
/// With [twice], [parentScopes] stands for the list `[...parentScopes,
/// ...parentScopes]` of `createSubResolver` when its parent scopes and its
/// root scopes are one list: the walk goes over the list two times. The
/// second time adds nothing to [set] and returns nothing when each step of
/// the first time reads the same values again with no code of the user:
/// each parent is read by a plain read ([_plainScopeRead]), each scope that
/// it finds is a plain scope ([_plainScope]) with a `_fallback` that is not
/// a function ([_plainFallback]), and [key] is a name with no dot or `true`
/// ([_plainScopeKey]). A step that the first time took early ends the walk,
/// as before. Then the walk skips the second time (the row
/// `adapt-resolver-single-walk`). Any other walk goes over the list again.
ResolverObjectKey _addScopes(
  Set<Object?> set,
  List<Object?> parentScopes,
  ResolverObjectKey key,
  ResolverObjectKey parentFallback,
  Object? value, [
  bool twice = false,
]) {
  // DIVERGES(chartjs): adapt-resolver-single-walk, one pass when it is all.
  var settled = twice && _plainScopeKey(key);
  for (var pass = twice ? 2 : 1; pass > 0; pass--) {
    if (pass == 1 && settled) break;
    final first = pass == 2;
    for (final parent in parentScopes) {
      if (first && settled && !_plainScopeRead(parent, key)) settled = false;
      final scope = _getScope(key, parent);
      if (jsTruthy(scope)) {
        set.add(scope);
        final raw = jsGet(scope, '_fallback');
        if (first && settled && !(_plainScope(scope) && _plainFallback(raw))) {
          settled = false;
        }
        final fallback = _resolveFallback(raw, key, value);
        if (!identical(fallback, undefined) &&
            fallback != key &&
            fallback != parentFallback) {
          // When we reach the descriptor that defines a new _fallback, return
          // that. The fallback will resume to that new scope.
          return fallback;
        }
      } else if (scope == false &&
          !identical(parentFallback, undefined) &&
          key != parentFallback) {
        // Fallback to `false` results to `false`, when falling back to
        // different key. For example `interaction` from `hover` or
        // `plugins.tooltip` and `animation` from `animations`
        return null;
      }
    }
  }
  return false;
}

/// Whether `getScope(key, parent)` of [_addScopes] reads no property for
/// [key] (`true`), or reads one property with no code of the user (a name
/// with no dot). A dotted name and any other key take the second walk.
bool _plainScopeKey(ResolverObjectKey key) =>
    identical(key, true) || (key is String && !key.contains('.'));

/// Whether `getScope(key, parent)` for a key of [_plainScopeKey] reads
/// [parent] with no code of the user, so that a second read gives the same
/// value: a primitive value (`resolveObjectKey` reads no property of a
/// falsy value, and the property of a string, a number or a boolean is an
/// index, `length` or `undefined`), a Map of the SDK (`LinkedHashMap`, the
/// class of a Map literal: a user Map class can run any code in a read), or
/// a typed scope with the face of its class and no route of [key] (a route
/// can give a new merged object at each read, core.defaults.js:144-153).
bool _plainScopeRead(Object? parent, ResolverObjectKey key) {
  if (parent is OptionScope) {
    return parent.nativeFace && (key is! String || parent.routeOf(key) == null);
  }
  return parent is LinkedHashMap ||
      parent == null ||
      parent is Undefined ||
      parent is bool ||
      parent is num ||
      parent is String;
}

/// Whether `set.add(scope)` and `scope._fallback` of [_addScopes] run no
/// code of the user and read the same value again: a Map of the SDK, a
/// typed scope with the face of its class and no route of `_fallback`, or a
/// primitive value.
bool _plainScope(Object? scope) {
  if (scope is OptionScope) {
    return scope.nativeFace && scope.routeOf('_fallback') == null;
  }
  return scope is LinkedHashMap ||
      scope is bool ||
      scope is num ||
      scope is String;
}

/// Whether the `_fallback` value [raw] gives itself in [_resolveFallback]
/// and compares with `!==` with no code of the user: not a function, and a
/// string, a boolean, `null` or `undefined`.
bool _plainFallback(Object? raw) =>
    raw == null || raw is Undefined || raw is bool || raw is String;

/// The own property [name] of the target of the resolver [resolver]: a
/// field of an [OptionResolver], else the result of [jsGet] (the target of
/// upstream is the cache object, helpers.config.ts:66).
Object? _targetGet(Object? resolver, String name) {
  if (resolver is OptionResolver) {
    return switch (name) {
      '_rootScopes' => resolver._targetRootScopes,
      '_fallback' => resolver._targetFallback,
      '_getTarget' => resolver._targetGetTarget,
      '_scopes' => resolver._targetScopes,
      _ => resolver._ownOrUndefined(name),
    };
  }
  return jsGet(resolver, name);
}

/// helpers.config.ts:335 `createSubResolver`.
///
/// It returns an [OptionResolver], or `false`.
Object _createSubResolver(
  List<Object?> parentScopes,
  Object? resolver,
  String prop,
  Object? value,
) {
  final rootScopes = _targetGet(resolver, '_rootScopes')! as List<Object?>;
  final fallback = _resolveFallback(
    _targetGet(resolver, '_fallback'),
    prop,
    value,
  );
  // The parent scopes of a top-level resolver are its root scopes: then
  // the copy holds the list once, and [_addScopes] walks it two times, or
  // one time when the second time adds nothing (adapt-resolver-single-walk).
  final twice = identical(parentScopes, rootScopes);
  final allScopes = twice
      ? [...parentScopes]
      : [...parentScopes, ...rootScopes];
  final set = <Object?>{value};
  var key = _addScopesFromKey(
    set,
    allScopes,
    prop,
    jsTruthy(fallback) ? fallback : prop,
    value,
    twice,
  );
  if (key == null) {
    return false;
  }
  if (!identical(fallback, undefined) && fallback != prop) {
    key = _addScopesFromKey(set, allScopes, fallback, key, value, twice);
    if (key == null) {
      return false;
    }
  }
  return createResolver(
    set.toList(),
    [''],
    rootScopes,
    fallback,
    () => _subGetTarget(resolver, prop, value),
  );
}

/// The font of [prop] (Chart.js ADR 0116, row `adapt-text-style-fonts`):
/// the `TextStyle`s of the scopes that `createSubResolver` gathers for a font
/// object upstream (the scopes of [prop], then the scopes of its `_fallback`
/// key), merged with [TextStyle.merge]. A style of a scope with higher
/// priority wins for each field that it sets, as a key of a font object
/// wins in the sub-resolver upstream. The result is a [ChartTextStyle] when
/// the lowest style is one, or `false` where `createSubResolver` gives
/// `false`.
Object _mergeTextStyles(
  List<Object?> parentScopes,
  Object? resolver,
  String prop,
  TextStyle value,
) {
  final rootScopes = _targetGet(resolver, '_rootScopes')! as List<Object?>;
  final fallback = _resolveFallback(
    _targetGet(resolver, '_fallback'),
    prop,
    value,
  );
  final twice = identical(parentScopes, rootScopes);
  final allScopes = twice
      ? [...parentScopes]
      : [...parentScopes, ...rootScopes];
  final set = <Object?>{value};
  var key = _addScopesFromKey(
    set,
    allScopes,
    prop,
    jsTruthy(fallback) ? fallback : prop,
    value,
    twice,
  );
  if (key == null) {
    return false;
  }
  if (!identical(fallback, undefined) && fallback != prop) {
    key = _addScopesFromKey(set, allScopes, fallback, key, value, twice);
    if (key == null) {
      return false;
    }
  }
  var merged = value;
  var first = true;
  for (final style in set.toList().reversed) {
    if (style is! TextStyle) continue;
    merged = first ? style : merged.merge(style);
    first = false;
  }
  return merged;
}

/// helpers.config.ts:360 `addScopesFromKey`.
///
/// [twice] is the flag of [_addScopes]: [allScopes] stands for itself two
/// times.
ResolverObjectKey _addScopesFromKey(
  Set<Object?> set,
  List<Object?> allScopes,
  ResolverObjectKey key,
  ResolverObjectKey fallback,
  Object? item, [
  bool twice = false,
]) {
  var scopeKey = key;
  while (jsTruthy(scopeKey)) {
    scopeKey = _addScopes(set, allScopes, scopeKey, fallback, item, twice);
  }
  return scopeKey;
}

/// helpers.config.ts:373 `subGetTarget`.
///
/// A new nested object of a typed scope is a typed scope of the kind of
/// [prop] (Chart.js ADR 0054 §3); another one is the `{}` of upstream.
Object? _subGetTarget(Object? resolver, String prop, Object? value) {
  // The port's own `_getTarget` closure reads neither `this` nor arguments.
  final parent = (_targetGet(resolver, '_getTarget')! as Object? Function())();
  if (!_has(parent, prop)) {
    _set(parent, prop, _newObject(parent, prop));
  }
  final target = jsGet(parent, prop);
  if (isArray(target) && isObject(value)) {
    // For array of objects, the object is used to store updated values
    return value;
  }
  return jsTruthy(target) ? target : <String, Object?>{};
}

/// A new empty object under [prop] of [parent]: a typed scope of the kind
/// of [prop] for a typed [parent] with one, else a raw Map.
Object _newObject(Object? parent, String prop) =>
    (parent is OptionScope ? parent.childKindFor(prop)?.create() : null) ??
    <String, Object?>{};

/// helpers.config.ts:390 `_resolveWithPrefixes`.
///
/// [key] is the cache key of [prop] ([_keyOf]) when the caller has it: the
/// typed scopes read the empty prefix with it.
Object? _resolveWithPrefixes(
  String prop,
  List<String> prefixes,
  List<Object?> scopes,
  Object? proxy, [
  Object? key,
]) {
  Object? value;
  for (final prefix in prefixes) {
    // `readKey('', prop)` is [prop], whose cache key is [key].
    value = _resolve(
      _readKey(prefix, prop),
      scopes,
      prefix.isEmpty ? key : null,
    );
    if (!identical(value, undefined)) {
      // DIVERGES(chartjs): adapt-text-style-fonts, the fonts merge.
      if (value is TextStyle) {
        return _mergeTextStyles(scopes, proxy, prop, value);
      }
      return _needsSubResolver(prop, value)
          ? _createSubResolver(scopes, proxy, prop, value)
          : value;
    }
  }
  return undefined;
}

/// helpers.config.ts:407 `_resolve`.
///
/// An absent key and the [undefined] sentinel go to the next scope. Dart
/// `null` (JS `null`) is the result. A typed scope is read by the typed
/// lookup of its kind (Chart.js ADR 0054 §4); any other scope with [jsGet].
/// [scopeKey] is `_keyOf(key)` when the caller has it, else Dart `null`.
Object? _resolve(String key, List<Object?> scopes, [Object? scopeKey]) {
  for (final scope in scopes) {
    if (!jsTruthy(scope)) {
      continue;
    }
    final Object? value;
    if (scope is OptionScope) {
      final cell = scope.lookup(scopeKey ??= _keyOf(key));
      value = cell == null ? undefined : cell.raw;
    } else {
      value = jsGet(scope, key);
    }
    if (!identical(value, undefined)) {
      return value;
    }
  }
  return undefined;
}

/// helpers.config.ts:419 `getKeysFromAllScopes`.
List<String> _getKeysFromAllScopes(OptionResolver target) {
  var keys = target._ownOrUndefined('_keys');
  if (!jsTruthy(keys)) {
    keys = target._keys = _resolveKeysFromAllScopes(
      target._targetScopes! as List<Object?>,
    );
  }
  return keys! as List<String>;
}

/// helpers.config.ts:427 `resolveKeysFromAllScopes`.
///
/// `Object.keys` of a scope is `_objectKeys`. A key that a scope owns with
/// the [undefined] sentinel or Dart `null` is a key.
List<String> _resolveKeysFromAllScopes(List<Object?> scopes) {
  final set = <String>{};
  for (final scope in scopes) {
    set.addAll(_objectKeys(scope).where((k) => !k.startsWith('_')));
  }
  return set.toList();
}

/// helpers.config.ts:437 `_parseObjectDataRadialScale`.
///
/// The function reads `this`, the dataset controller that
/// `controller.polarArea.js:110` binds. Thus it is a [JsFunction]
/// (`lib/src/js/js_function.dart`). Its closure takes `this` (a
/// [DatasetController]), `meta` (a [ChartMeta]), `data` (a `List<Object?>`),
/// `start` and `count` (`double`s). Call it with [jsCall] and the controller
/// as `thisArg`. It returns a `List<ParsedItem>`: each item is the object
/// `{r}` of upstream, a typed parsed item (Chart.js ADR 0054 §8) with the
/// one key `r`.
const JsFunction parseObjectDataRadialScale = JsFunction(
  _parseObjectDataRadialScale,
);

/// The closure of [parseObjectDataRadialScale]: the typed body with the
/// reads of `this` and `meta`, in the upstream order.
List<ParsedItem> _parseObjectDataRadialScale(
  DatasetController self,
  ChartMeta meta,
  List<Object?> data,
  double start,
  double count,
) => parseObjectDataRadialScaleOf(
  meta.iScale,
  self.parsing,
  data,
  start,
  count,
);

/// helpers.config.ts:437 `_parseObjectDataRadialScale`, the typed body for
/// the radar and polar area controllers: no [jsCall].
///
/// [iScale] is `meta.iScale` and [parsing] is `this._parsing` of the
/// controller, the two values that upstream reads from `meta` and `this`. A
/// caller reads them in that order, as the argument order is. The result
/// is the one of [parseObjectDataRadialScale].
@internal
List<ParsedItem> parseObjectDataRadialScaleOf(
  Scale? iScale,
  Object? parsing,
  List<Object?> data,
  double start,
  double count,
) {
  final parsingKey = jsGet(parsing, 'key');
  final key = identical(parsingKey, undefined) ? 'r' : parsingKey;
  final parsed = <ParsedItem>[];

  for (var i = 0.0, ilen = count; i < ilen; ++i) {
    final index = i + start;
    final item = jsGetIndex(data, index);
    parsed.add(
      ParsedItem()
        ..r = iScale!.parse(resolveObjectKey(item, key! as String), index),
    );
  }
  return parsed;
}

// The JavaScript object operations of the traps, for the Dart values of
// Chart.js ADR 0054 §5: a raw Map, a typed object with a face, a List, a
// function value. Upstream has no counterpart: the JavaScript engine does
// them.

/// The first scope, `scopes[0]`: the [undefined] sentinel for an empty
/// list.
Object? _first(List<Object?> scopes) => scopes.isEmpty ? undefined : scopes[0];

/// The property write `object[key] = value` (`[[Set]]`) in strict mode.
///
/// Only an object takes a property: a typed object through its face (a
/// resolver through its `set` trap) and a Map. Every other value throws a
/// [TypeError]. JavaScript also adds a property to an array or a function. A
/// Map whose value type does not allow [value] also throws a [TypeError]
/// (see the library documentation).
// DIVERGES(chartjs): js-semantics-resolver-objects, set on an object only.
void _set(Object? object, String key, Object? value) {
  if (object is JsObjectFace) {
    object.jsWrite(key, value);
    return;
  }
  if (object is Map) {
    object[key] = value;
    return;
  }
  // A JavaScript TypeError for null, undefined and the primitives.
  throw TypeError();
}

/// The property delete `delete object[key]`.
///
/// It calls the `deleteProperty` trap of a resolver, and the face of
/// another typed object. It removes an own [key] from a Map. It does nothing
/// for other values. Throws a [TypeError] for `null` and [undefined], as
/// JavaScript does.
///
/// A delete of an absent key succeeds also on a frozen object, as in strict
/// mode. Thus an unmodifiable Map (`Object.freeze`) throws only for a key
/// that it contains.
void _deleteProperty(Object? object, String key) {
  if (object == null || identical(object, undefined)) {
    throw TypeError();
  }
  if (object is JsObjectFace) {
    object.jsDelete(key);
  } else if (object is Map && object.containsKey(key)) {
    object.remove(key);
  }
}

/// The `in` operator and `Reflect.has` (`[[HasProperty]]`).
///
/// A resolver gives its `has` trap, and a context its prototype chain. Another
/// typed object and a Map give their own keys. A List has its array indices
/// and `length`. A function value has no property here. Throws a [TypeError]
/// for a value that is not an object, as JavaScript does.
bool _has(Object? object, String key) {
  if (object is JsProxyObject) {
    return object.hasProperty(key);
  }
  if (object is ContextObject) {
    return object.hasProperty(key);
  }
  if (object is JsObjectFace) {
    return object.jsHas(key);
  }
  if (object is Map) {
    return object.containsKey(key);
  }
  if (object is List) {
    if (key == 'length') return true;
    final index = jsArrayIndex(key);
    return index != null && index < object.length;
  }
  if (jsIsFunction(object)) {
    return false;
  }
  throw TypeError();
}

/// `Reflect.getOwnPropertyDescriptor(object, key) !== undefined`
/// (`[[GetOwnProperty]]`).
///
/// A resolver gives its `getOwnPropertyDescriptor` trap. Throws a
/// [TypeError] for a value that is not an object, as JavaScript does.
bool _getOwnProperty(Object? object, String key) {
  if (object is Resolver) {
    return object.hasOwnProperty(key);
  }
  if (object is ContextResolver) {
    return object.hasOwnProperty(key);
  }
  return _has(object, key);
}

/// `Reflect.ownKeys(object)` (`[[OwnPropertyKeys]]`).
///
/// A resolver gives its `ownKeys` trap. Another typed object and a Map give
/// their keys in the [jsObjectKeys] order. A List gives its indices and
/// `length`. A function value has no key here. Throws a [TypeError] for a
/// value that is not an object, as JavaScript does.
List<String> _reflectOwnKeys(Object? object) {
  if (object is JsProxyObject) {
    return object.ownKeys();
  }
  if (object is JsObjectFace || object is Map<String, Object?>) {
    return jsObjectKeys(object);
  }
  if (object is List) {
    return [for (var i = 0; i < object.length; i++) '$i', 'length'];
  }
  if (jsIsFunction(object)) {
    return [];
  }
  throw TypeError();
}

/// `Object.keys(object)`.
///
/// A typed object and a Map give [jsObjectKeys]: `objectKeys()` for a
/// resolver. A List or a String gives its indices. Any other value gives no
/// key. Throws a [TypeError] for `null` and [undefined], as JavaScript does.
List<String> _objectKeys(Object? object) {
  if (object == null || identical(object, undefined)) {
    throw TypeError();
  }
  if (object is JsObjectFace || object is Map<String, Object?>) {
    return jsObjectKeys(object);
  }
  if (object is List || object is String) {
    final length = object is List ? object.length : (object as String).length;
    return [for (var i = 0; i < length; i++) '$i'];
  }
  return [];
}
