// Original code, not ported from d3-quadtree: structural node matchers.

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';
import 'package:test/test.dart';

/// Builds a [QuadtreeLeafNode] concisely in test expectations.
QuadtreeLeafNode<T> leaf<T>(T data, [QuadtreeLeafNode<T>? next]) =>
    QuadtreeLeafNode<T>(data, next);

/// Builds a [QuadtreeInternalNode] concisely in test expectations.
QuadtreeInternalNode<T> branch<T>({
  QuadtreeNode<T>? nw,
  QuadtreeNode<T>? ne,
  QuadtreeNode<T>? sw,
  QuadtreeNode<T>? se,
}) => QuadtreeInternalNode<T>(nw: nw, ne: ne, sw: sw, se: se);

/// Asserts that two [QuadtreeNode] trees are structurally equal, comparing leaf
/// data using [equals] (which handles lists and records deeply).
void expectNodeEquals<T>(QuadtreeNode<T>? actual, QuadtreeNode<T>? expected) {
  if (expected == null) {
    expect(actual, isNull);
    return;
  }
  expect(actual, isNotNull);
  switch (expected) {
    case QuadtreeLeafNode<T>():
      expect(actual, isA<QuadtreeLeafNode<T>>());
      final a = actual! as QuadtreeLeafNode<T>;
      expect(a.data, equals(expected.data));
      expectNodeEquals<T>(a.next, expected.next);
    case QuadtreeInternalNode<T>():
      expect(actual, isA<QuadtreeInternalNode<T>>());
      final a = actual! as QuadtreeInternalNode<T>;
      expectNodeEquals<T>(a.nw, expected.nw);
      expectNodeEquals<T>(a.ne, expected.ne);
      expectNodeEquals<T>(a.sw, expected.sw);
      expectNodeEquals<T>(a.se, expected.se);
  }
}

/// Asserts that two [Quadtree] instances have identical extent and node tree.
void expectTreeEquals<T>(Quadtree<T> actual, Quadtree<T> expected) {
  expect(actual.extent, expected.extent);
  expectNodeEquals<T>(actual.root, expected.root);
}
