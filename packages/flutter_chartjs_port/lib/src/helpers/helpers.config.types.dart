// Ported from Chart.js v4.5.1+7169e651 src/helpers/helpers.config.types.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/helpers.config.types.ts`: the types of the option
/// resolvers of `helpers.config.ts`.
///
/// The upstream module declares types only. Its Dart form follows Chart.js
/// ADR 0003: each interface is an `abstract interface class`, and a
/// TypeScript property is an abstract getter. The library imports only
/// `basic.dart`, `js_undefined.dart` and `package:meta`, so it is a pure
/// layer.
/// `helpers.config.dart` exports it, as `helpers.config.ts:15` does.
///
/// - The generic parameters `T` and `R` (the scope list types) have no Dart
///   form. A scope list is a `List<Object?>`. Its items are mostly
///   [AnyObject] scopes, but `createSubResolver` (helpers.config.ts:335) also
///   adds the arrays and other truthy values that a key gives.
/// - The proxy types `ResolverProxy` and `ContextProxy` are `Merge<...>` with
///   the cache type. The `Resolver` and `ContextResolver` classes of
///   `helpers.config.dart` implement them, and they are
///   `Map<String, Object?>` (Chart.js ADR 0006).
/// - The members of the caches are underscore members that other modules
///   read (`_cacheable`, `_scopes`, ...). They drop the underscore and carry
///   `@internal` (Chart.js ADR 0012). The concrete classes carry it too.
/// - The optional cache members `_keys`, `_scriptable`, `_indexable`,
///   `_allKeys` and `_storage` (helpers.config.types.ts:15-19) have no
///   getter. Only `helpers.config.ts` reads them, through the cache Map or
///   the `get` trap. A `keys` getter would also clash with `Map.keys`.
/// - `[Symbol.toStringTag]: 'Object'` (helpers.config.types.ts:10) makes
///   `isObject` true for a resolver. A resolver is a Map here, so `isObject`
///   is true without it.
library;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:meta/meta.dart';

/// helpers.config.types.ts:4 `ResolverObjectKey`: `string | boolean`.
///
/// Dart has no union type. A value is a `String` or a `bool`. At run time a
/// `_fallback` can also be a function value, Dart `null` (JS `null`) or the
/// `undefined` sentinel (helpers.config.ts:298-333).
typedef ResolverObjectKey = Object?;

/// helpers.config.types.ts:6 `ResolverCache`: the cache object of a
/// `_createResolver` proxy.
abstract interface class ResolverCache {
  /// helpers.config.types.ts:11 `_cacheable: boolean`.
  @internal
  bool get cacheable;

  /// helpers.config.types.ts:12 `_scopes: T`.
  @internal
  List<Object?> get scopes;

  /// helpers.config.types.ts:13 `_rootScopes: T | R`.
  @internal
  List<Object?> get rootScopes;

  /// helpers.config.types.ts:14 `_fallback: ResolverObjectKey`.
  @internal
  ResolverObjectKey get fallback;

  /// helpers.config.types.ts:20 `_getTarget(): T[number]`: the scope that
  /// takes the values that a caller sets.
  @internal
  Object? Function() get getTarget;

  /// helpers.config.types.ts:21 `override(scope)`.
  ResolverProxy override(AnyObject scope);
}

/// helpers.config.types.ts:24 `ResolverProxy`: `Merge<T[number]>` and
/// [ResolverCache]. The `Map` gives the merged options.
abstract interface class ResolverProxy
    implements ResolverCache, Map<String, Object?> {}

/// helpers.config.types.ts:29 `DescriptorDefaults`.
///
/// The members are `boolean` upstream. At run time a member can also hold
/// the function value of a `_scriptable` or `_indexable` option, because
/// `_resolveWithContext` passes a [Descriptor] as the defaults of a
/// sub-resolver (helpers.config.ts:250). Thus they are `Object?`.
abstract interface class DescriptorDefaults {
  /// The object literal `{scriptable, indexable, allKeys}`. An [allKeys]
  /// that the literal leaves out is the `undefined` sentinel.
  const factory DescriptorDefaults({
    required Object? scriptable,
    required Object? indexable,
    Object? allKeys,
  }) = _DescriptorDefaults;

  /// helpers.config.types.ts:30 `scriptable: boolean`.
  Object? get scriptable;

  /// helpers.config.types.ts:31 `indexable: boolean`.
  Object? get indexable;

  /// helpers.config.types.ts:32 `allKeys?: boolean`. The `undefined`
  /// sentinel when absent.
  Object? get allKeys;
}

/// helpers.config.types.ts:35 `Descriptor`.
abstract interface class Descriptor implements DescriptorDefaults {
  /// helpers.config.types.ts:39 `isScriptable(key: string): boolean`.
  bool isScriptable(String key);

  /// helpers.config.types.ts:40 `isIndexable(key: string): boolean`.
  bool isIndexable(String key);
}

/// helpers.config.types.ts:43 `ContextCache`: the cache object of an
/// `_attachContext` proxy.
abstract interface class ContextCache {
  /// helpers.config.types.ts:47 `_cacheable: boolean`.
  @internal
  bool get cacheable;

  /// helpers.config.types.ts:48 `_proxy: ResolverProxy<T, R>`.
  ///
  /// It is `Object?`: `_resolveArray` can attach a context to the `false`
  /// that `createSubResolver` returns (helpers.config.ts:291-292).
  @internal
  Object? get proxy;

  /// helpers.config.types.ts:49 `_context: AnyObject`.
  @internal
  AnyObject get context;

  /// helpers.config.types.ts:50 `_subProxy: ResolverProxy<T, R>`. The
  /// `undefined` sentinel when the caller gives none.
  @internal
  Object? get subProxy;

  /// helpers.config.types.ts:51 `_stack: Set<string>`.
  @internal
  Set<String> get stack;

  /// helpers.config.types.ts:52 `_descriptors: Descriptor`.
  @internal
  Descriptor get descriptors;

  /// helpers.config.types.ts:53 `setContext(ctx)`.
  ContextProxy setContext(AnyObject ctx);

  /// helpers.config.types.ts:54 `override(scope)`.
  ContextProxy override(AnyObject scope);
}

/// helpers.config.types.ts:57 `ContextProxy`: `Merge<T[number]>` and
/// [ContextCache]. The `Map` gives the merged options.
abstract interface class ContextProxy
    implements ContextCache, Map<String, Object?> {}

/// The object literal of [DescriptorDefaults].
final class _DescriptorDefaults implements DescriptorDefaults {
  const _DescriptorDefaults({
    required this.scriptable,
    required this.indexable,
    this.allKeys = undefined,
  });

  @override
  final Object? scriptable;

  @override
  final Object? indexable;

  @override
  final Object? allKeys;
}
