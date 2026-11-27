// Ported from d3-array v3.2.4 src/cross.js (ISC, Mike Bostock).

/// Port of `src/cross.js` of d3-array 3.2.4.
library;

/// Returns the Cartesian product of [a] and [b] as `(A, B)` records.
// DIVERGES(d3-array): adapt-array-typed-api, strongly typed binary cross,
// ternary cross3, reducer crossWith/cross3With, and homogeneous N-ary crossAll.
List<(A, B)> cross<A, B>(Iterable<A> a, Iterable<B> b) {
  final listA = a is List<A> ? a : List<A>.of(a, growable: false);
  final listB = b is List<B> ? b : List<B>.of(b, growable: false);
  final na = listA.length;
  final nb = listB.length;
  if (na == 0 || nb == 0) return <(A, B)>[];
  final out = <(A, B)>[];
  for (var i = 0; i < na; ++i) {
    final va = listA[i];
    for (var j = 0; j < nb; ++j) {
      out.add((va, listB[j]));
    }
  }
  return out;
}

/// Returns the Cartesian product of [a] and [b] mapped through [reduce].
List<R> crossWith<A, B, R>(
  Iterable<A> a,
  Iterable<B> b,
  R Function(A a, B b) reduce,
) {
  final listA = a is List<A> ? a : List<A>.of(a, growable: false);
  final listB = b is List<B> ? b : List<B>.of(b, growable: false);
  final na = listA.length;
  final nb = listB.length;
  if (na == 0 || nb == 0) return <R>[];
  final out = <R>[];
  for (var i = 0; i < na; ++i) {
    final va = listA[i];
    for (var j = 0; j < nb; ++j) {
      out.add(reduce(va, listB[j]));
    }
  }
  return out;
}

/// Returns the 3-way Cartesian product of [a], [b], and [c] as `(A, B, C)`
/// records.
List<(A, B, C)> cross3<A, B, C>(Iterable<A> a, Iterable<B> b, Iterable<C> c) {
  final listA = a is List<A> ? a : List<A>.of(a, growable: false);
  final listB = b is List<B> ? b : List<B>.of(b, growable: false);
  final listC = c is List<C> ? c : List<C>.of(c, growable: false);
  final na = listA.length;
  final nb = listB.length;
  final nc = listC.length;
  if (na == 0 || nb == 0 || nc == 0) return <(A, B, C)>[];
  final out = <(A, B, C)>[];
  for (var i = 0; i < na; ++i) {
    final va = listA[i];
    for (var j = 0; j < nb; ++j) {
      final vb = listB[j];
      for (var k = 0; k < nc; ++k) {
        out.add((va, vb, listC[k]));
      }
    }
  }
  return out;
}

/// Returns the 3-way Cartesian product of [a], [b], and [c] mapped through
/// [reduce].
List<R> cross3With<A, B, C, R>(
  Iterable<A> a,
  Iterable<B> b,
  Iterable<C> c,
  R Function(A a, B b, C c) reduce,
) {
  final listA = a is List<A> ? a : List<A>.of(a, growable: false);
  final listB = b is List<B> ? b : List<B>.of(b, growable: false);
  final listC = c is List<C> ? c : List<C>.of(c, growable: false);
  final na = listA.length;
  final nb = listB.length;
  final nc = listC.length;
  if (na == 0 || nb == 0 || nc == 0) return <R>[];
  final out = <R>[];
  for (var i = 0; i < na; ++i) {
    final va = listA[i];
    for (var j = 0; j < nb; ++j) {
      final vb = listB[j];
      for (var k = 0; k < nc; ++k) {
        out.add(reduce(va, vb, listC[k]));
      }
    }
  }
  return out;
}

/// Returns the homogeneous N-way Cartesian product of [iterables].
List<List<T>> crossAll<T>(Iterable<Iterable<T>> iterables) {
  final lists = <List<T>>[
    for (final it in iterables)
      if (it is List<T>) it else List<T>.of(it),
  ];
  final k = lists.length;
  if (k == 0) return <List<T>>[];
  final lengths = List<int>.generate(
    k,
    (i) => lists[i].length,
    growable: false,
  );
  for (var i = 0; i < k; ++i) {
    if (lengths[i] == 0) return <List<T>>[];
  }
  final index = List<int>.filled(k, 0);
  final product = <List<T>>[];
  final last = k - 1;
  while (true) {
    product.add(List<T>.generate(k, (i) => lists[i][index[i]]));
    var i = last;
    while (++index[i] == lengths[i]) {
      if (i == 0) return product;
      index[i--] = 0;
    }
  }
}

/// Returns the homogeneous N-way Cartesian product of [iterables] mapped
/// through [reduce].
List<R> crossAllWith<T, R>(
  Iterable<Iterable<T>> iterables,
  R Function(List<T> tuple) reduce,
) {
  final tuples = crossAll<T>(iterables);
  return <R>[for (final tuple in tuples) reduce(tuple)];
}
