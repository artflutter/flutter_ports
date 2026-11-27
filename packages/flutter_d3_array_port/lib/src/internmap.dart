// Original code, not ported from d3-array: typed InternMap and InternSet.

/// Typed [InternMap] and [InternSet] for custom key canonicalization
/// (D3 ADR 0017).
///
/// Dart's native [Map] and [Set] already use value equality for `DateTime`,
/// `String`, `num`, records, and value classes, so `d3-array` grouping and set
/// operations return native Dart `Map<K, V>` and `Set<T>` directly. Use
/// [InternMap] or [InternSet] when you want to intern keys under a custom
/// projection `I Function(K) key` while preserving the first-inserted `K`.
library;

import 'dart:collection';

/// A typed [Map] that canonicalizes keys using a projection `key` from `K` to
/// `I`, retaining the first `K` inserted for each canonical key `I`.
final class InternMap<K, V, I>({
  required I Function(K) key,
  Iterable<(K, V)>? entries,
}) extends MapBase<K, V> {
  /// Creates an [InternMap] canonicalizing keys with [key], optionally seeded
  /// with [entries].
  this {
    if (entries != null) {
      for (final (k, v) in entries) {
        this[k] = v;
      }
    }
  }

  final I Function(K) _key = key;
  final Map<I, K> _intern = <I, K>{};
  final Map<K, V> _map = <K, V>{};

  @override
  V? operator [](Object? key) {
    if (key is! K) return null;
    final canonical = _key(key);
    final stored = _intern[canonical];
    return stored != null ? _map[stored] : _map[key];
  }

  @override
  void operator []=(K key, V value) {
    final canonical = _key(key);
    final stored = _intern.putIfAbsent(canonical, () => key);
    _map[stored] = value;
  }

  @override
  bool containsKey(Object? key) {
    if (key is! K) return false;
    final canonical = _key(key);
    return _intern.containsKey(canonical);
  }

  @override
  V? remove(Object? key) {
    if (key is! K) return null;
    final canonical = _key(key);
    if (_intern.containsKey(canonical)) {
      final stored = _intern.remove(canonical) as K;
      return _map.remove(stored);
    }
    return null;
  }

  @override
  void clear() {
    _intern.clear();
    _map.clear();
  }

  @override
  Iterable<K> get keys => _map.keys;

  @override
  int get length => _map.length;
}

/// A typed [Set] that canonicalizes values using a projection `key` from `T` to
/// `I`, retaining the first `T` inserted for each canonical key `I`.
final class InternSet<T, I>({required I Function(T) key, Iterable<T>? values})
    extends SetBase<T> {
  /// Creates an [InternSet] canonicalizing elements with [key], optionally
  /// seeded with [values].
  this {
    if (values != null) {
      addAll(values);
    }
  }

  final I Function(T) _key = key;
  final Map<I, T> _intern = <I, T>{};
  final Set<T> _set = <T>{};

  @override
  bool add(T value) {
    final canonical = _key(value);
    if (_intern.containsKey(canonical)) return false;
    _intern[canonical] = value;
    return _set.add(value);
  }

  @override
  bool contains(Object? element) {
    if (element is! T) return false;
    return _intern.containsKey(_key(element));
  }

  @override
  T? lookup(Object? element) {
    if (element is! T) return null;
    return _intern[_key(element)];
  }

  @override
  bool remove(Object? value) {
    if (value is! T) return false;
    final canonical = _key(value);
    if (_intern.containsKey(canonical)) {
      final stored = _intern.remove(canonical) as T;
      return _set.remove(stored);
    }
    return false;
  }

  @override
  void clear() {
    _intern.clear();
    _set.clear();
  }

  @override
  Iterator<T> get iterator => _set.iterator;

  @override
  int get length => _set.length;

  @override
  Set<T> toSet() => InternSet<T, I>(key: _key, values: _set);
}
