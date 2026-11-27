// Ported from d3-hierarchy v3.1.2 test/treemap/index-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

import 'round.dart';

final class const _SimpleNode({
  final double? value,
  @override final List<_SimpleNode>? children,
}) implements HierarchyDatum<_SimpleNode>;

final class const _FooNode({
  final double? foo,
  @override final List<_FooNode>? children,
}) implements HierarchyDatum<_FooNode>;

const _simple2 = _SimpleNode(
  children: [
    _SimpleNode(value: 6),
    _SimpleNode(value: 6),
    _SimpleNode(value: 4),
    _SimpleNode(value: 3),
    _SimpleNode(value: 2),
    _SimpleNode(value: 2),
    _SimpleNode(value: 1),
  ],
);

const _simple3 = _FooNode(
  children: [
    _FooNode(foo: 6),
    _FooNode(foo: 6),
    _FooNode(foo: 4),
    _FooNode(foo: 3),
    _FooNode(foo: 2),
    _FooNode(foo: 2),
    _FooNode(foo: 1),
  ],
);

double? _defaultValue(_SimpleNode d) => d.value;

double _ascendingValue<T>(HierarchyNode<T> a, HierarchyNode<T> b) =>
    (a.value ?? 0) - (b.value ?? 0);

double _descendingValue<T>(HierarchyNode<T> a, HierarchyNode<T> b) =>
    (b.value ?? 0) - (a.value ?? 0);

void main() {
  test('treemap() has the expected defaults', () {
    final t = treemap<_SimpleNode>();
    expect(t.size, (1.0, 1.0));
    expect(t.round, isFalse);
    // Default tile behaves identically to treemapSquarify.
    final r1 = t(hierarchy(_simple2).sum(_defaultValue).sort(_descendingValue));
    final r2 = treemap<_SimpleNode>(tile: treemapSquarify.call)(
      hierarchy(_simple2).sum(_defaultValue).sort(_descendingValue),
    );
    expect(
      r1.descendants().map(roundRect).toList(),
      r2.descendants().map(roundRect).toList(),
    );
  });

  test('treemap.round(round) observes the specified rounding', () {
    final t = treemap<_SimpleNode>(size: (600, 400), round: true);
    final root = t(
      hierarchy(_simple2).sum(_defaultValue).sort(_descendingValue),
    );
    final nodes = root.descendants().map(roundRect).toList();
    expect(t.round, isTrue);
    expect(nodes, [
      (x0: 0.0, y0: 0.0, x1: 600.0, y1: 400.0),
      (x0: 0.0, y0: 0.0, x1: 300.0, y1: 200.0),
      (x0: 0.0, y0: 200.0, x1: 300.0, y1: 400.0),
      (x0: 300.0, y0: 0.0, x1: 471.0, y1: 233.0),
      (x0: 471.0, y0: 0.0, x1: 600.0, y1: 233.0),
      (x0: 300.0, y0: 233.0, x1: 540.0, y1: 317.0),
      (x0: 300.0, y0: 317.0, x1: 540.0, y1: 400.0),
      (x0: 540.0, y0: 233.0, x1: 600.0, y1: 400.0),
    ]);
  });

  test(
    'treemap.round(round) coerces the specified round to boolean',
    () {},
    skip: 'diverges: adapt-hierarchy-typed-api',
  );

  test('treemap.padding(padding) sets the inner and outer padding to the '
      'specified value', () {
    final t = treemap<_SimpleNode>()..paddingConst(42);
    final dummy = HierarchyRectangularNode<_SimpleNode>(_simple2);
    expect(t.padding(dummy), 42);
    expect(t.paddingInner(dummy), 42);
    expect(t.paddingOuter(dummy), 42);
    expect(t.paddingTop(dummy), 42);
    expect(t.paddingRight(dummy), 42);
    expect(t.paddingBottom(dummy), 42);
    expect(t.paddingLeft(dummy), 42);
  });

  test('treemap.paddingInner(padding) observes the specified padding', () {
    final t = treemap<_SimpleNode>(size: (6, 4), paddingInnerConst: 0.5);
    final root = t(
      hierarchy(_simple2).sum(_defaultValue).sort(_descendingValue),
    );
    final nodes = root.descendants().map(roundRect).toList();
    expect(t.paddingInner(root), 0.5);
    expect(t.size, (6.0, 4.0));
    expect(nodes, [
      (x0: 0.00, y0: 0.00, x1: 6.00, y1: 4.00),
      (x0: 0.00, y0: 0.00, x1: 2.75, y1: 1.75),
      (x0: 0.00, y0: 2.25, x1: 2.75, y1: 4.00),
      (x0: 3.25, y0: 0.00, x1: 4.61, y1: 2.13),
      (x0: 5.11, y0: 0.00, x1: 6.00, y1: 2.13),
      (x0: 3.25, y0: 2.63, x1: 5.35, y1: 3.06),
      (x0: 3.25, y0: 3.56, x1: 5.35, y1: 4.00),
      (x0: 5.85, y0: 2.63, x1: 6.00, y1: 4.00),
    ]);
  });

  test('treemap.paddingOuter(padding) observes the specified padding', () {
    final t = treemap<_SimpleNode>(size: (6, 4), paddingOuterConst: 0.5);
    final root = t(
      hierarchy(_simple2).sum(_defaultValue).sort(_descendingValue),
    );
    final nodes = root.descendants().map(roundRect).toList();
    expect(t.paddingOuter(root), 0.5);
    expect(t.paddingTop(root), 0.5);
    expect(t.paddingRight(root), 0.5);
    expect(t.paddingBottom(root), 0.5);
    expect(t.paddingLeft(root), 0.5);
    expect(t.size, (6.0, 4.0));
    expect(nodes, [
      (x0: 0.00, y0: 0.00, x1: 6.00, y1: 4.00),
      (x0: 0.50, y0: 0.50, x1: 3.00, y1: 2.00),
      (x0: 0.50, y0: 2.00, x1: 3.00, y1: 3.50),
      (x0: 3.00, y0: 0.50, x1: 4.43, y1: 2.25),
      (x0: 4.43, y0: 0.50, x1: 5.50, y1: 2.25),
      (x0: 3.00, y0: 2.25, x1: 5.00, y1: 2.88),
      (x0: 3.00, y0: 2.88, x1: 5.00, y1: 3.50),
      (x0: 5.00, y0: 2.25, x1: 5.50, y1: 3.50),
    ]);
  });

  test('treemap.size(size) observes the specified size', () {
    final t = treemap<_SimpleNode>(size: (6, 4));
    final root = t(
      hierarchy(_simple2).sum(_defaultValue).sort(_descendingValue),
    );
    final nodes = root.descendants().map(roundRect).toList();
    expect(t.size, (6.0, 4.0));
    expect(nodes, [
      (x0: 0.00, y0: 0.00, x1: 6.00, y1: 4.00),
      (x0: 0.00, y0: 0.00, x1: 3.00, y1: 2.00),
      (x0: 0.00, y0: 2.00, x1: 3.00, y1: 4.00),
      (x0: 3.00, y0: 0.00, x1: 4.71, y1: 2.33),
      (x0: 4.71, y0: 0.00, x1: 6.00, y1: 2.33),
      (x0: 3.00, y0: 2.33, x1: 5.40, y1: 3.17),
      (x0: 3.00, y0: 3.17, x1: 5.40, y1: 4.00),
      (x0: 5.40, y0: 2.33, x1: 6.00, y1: 4.00),
    ]);
  });

  test(
    'treemap.size(size) coerces the specified size to numbers',
    () {},
    skip: 'diverges: adapt-hierarchy-typed-api',
  );

  test('treemap.size(size) makes defensive copies', () {
    // DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, immutable Dart record
    // `(double, double)` prevents external mutation by construction.
    const size = (6.0, 4.0);
    final t = treemap<_SimpleNode>(size: size);
    final root = t(
      hierarchy(_simple2).sum(_defaultValue).sort(_descendingValue),
    );
    final nodes = root.descendants().map(roundRect).toList();
    expect(t.size, (6.0, 4.0));
    expect(nodes, [
      (x0: 0.00, y0: 0.00, x1: 6.00, y1: 4.00),
      (x0: 0.00, y0: 0.00, x1: 3.00, y1: 2.00),
      (x0: 0.00, y0: 2.00, x1: 3.00, y1: 4.00),
      (x0: 3.00, y0: 0.00, x1: 4.71, y1: 2.33),
      (x0: 4.71, y0: 0.00, x1: 6.00, y1: 2.33),
      (x0: 3.00, y0: 2.33, x1: 5.40, y1: 3.17),
      (x0: 3.00, y0: 3.17, x1: 5.40, y1: 4.00),
      (x0: 5.40, y0: 2.33, x1: 6.00, y1: 4.00),
    ]);
  });

  test('treemap.tile(tile) observes the specified tile function', () {
    final t = treemap<_SimpleNode>(size: (6, 4), tile: treemapSlice);
    final root = t(
      hierarchy(_simple2).sum(_defaultValue).sort(_descendingValue),
    );
    final nodes = root.descendants().map(roundRect).toList();
    expect(t.tile, treemapSlice<_SimpleNode>);
    expect(nodes, [
      (x0: 0.00, y0: 0.00, x1: 6.00, y1: 4.00),
      (x0: 0.00, y0: 0.00, x1: 6.00, y1: 1.00),
      (x0: 0.00, y0: 1.00, x1: 6.00, y1: 2.00),
      (x0: 0.00, y0: 2.00, x1: 6.00, y1: 2.67),
      (x0: 0.00, y0: 2.67, x1: 6.00, y1: 3.17),
      (x0: 0.00, y0: 3.17, x1: 6.00, y1: 3.50),
      (x0: 0.00, y0: 3.50, x1: 6.00, y1: 3.83),
      (x0: 0.00, y0: 3.83, x1: 6.00, y1: 4.00),
    ]);
  });

  test('treemap(data) observes the specified values', () {
    final t = treemap<_FooNode>(size: (6, 4));
    final root = t(
      hierarchy(_simple3).sum((d) => d.foo).sort(_descendingValue),
    );
    final nodes = root.descendants().map(roundRect).toList();
    expect(t.size, (6.0, 4.0));
    expect(nodes, [
      (x0: 0.00, y0: 0.00, x1: 6.00, y1: 4.00),
      (x0: 0.00, y0: 0.00, x1: 3.00, y1: 2.00),
      (x0: 0.00, y0: 2.00, x1: 3.00, y1: 4.00),
      (x0: 3.00, y0: 0.00, x1: 4.71, y1: 2.33),
      (x0: 4.71, y0: 0.00, x1: 6.00, y1: 2.33),
      (x0: 3.00, y0: 2.33, x1: 5.40, y1: 3.17),
      (x0: 3.00, y0: 3.17, x1: 5.40, y1: 4.00),
      (x0: 5.40, y0: 2.33, x1: 6.00, y1: 4.00),
    ]);
  });

  test('treemap(data) observes the specified sibling order', () {
    final t = treemap<_SimpleNode>();
    final root = t(
      hierarchy(_simple2).sum(_defaultValue).sort(_ascendingValue),
    );
    expect(root.descendants().map((d) => d.value).toList(), [
      24.0,
      1.0,
      2.0,
      2.0,
      3.0,
      4.0,
      6.0,
      6.0,
    ]);
  });
}
