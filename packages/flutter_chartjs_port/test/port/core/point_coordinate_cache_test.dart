// Original code, not ported from Chart.js: weak coordinate cache tests.
import 'dart:collection';

import 'package:flutter_chartjs_port/src/core/point_options.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:test/test.dart';

class _ObservedMap() extends MapBase<String, Object?> {
  int reads = 0;
  int typeReads = 0;
  bool throwsType = false;
  @override
  Type get runtimeType {
    typeReads++;
    if (throwsType) throw StateError('custom type');
    return super.runtimeType;
  }

  @override
  Object? operator [](Object? key) {
    reads++;
    return 1.0;
  }

  @override
  void operator []=(String key, Object? value) {}
  @override
  Iterable<String> get keys => ['x', 'y'];
  @override
  void clear() {}
  @override
  Object? remove(Object? key) => null;
}

void main() {
  test('warm map identities never memoize coordinate values', () {
    final cache = NativePointCoordinateCache()..prepare(2);
    final map = <String, Object?>{'x': 1.0, 'y': 2.0};
    final first = NativePointCoordinates(cache: cache);
    expect(first.accepts(map, 1), isTrue);
    expect(cache.contains(map, 1), isTrue);
    for (final value in [Object(), undefined, null, 3, double.nan, -0.0]) {
      map['y'] = value;
      final next = NativePointCoordinates(cache: cache);
      expect(
        next.accepts(map, 1),
        value is num || value == null || value is Undefined,
      );
    }
    map.remove('x');
    expect(NativePointCoordinates(cache: cache).accepts(map, 1), isTrue);
  });

  test(
    'fill budget bounds cold, churn and mixed allocations per prepared loop',
    () {
      final cache = NativePointCoordinateCache()..prepare(2050);
      var maps = [
        for (var i = 0; i < 2050; i++)
          <String, Object?>{'x': i.toDouble(), 'y': 1},
      ];
      void visit() {
        final guard = NativePointCoordinates(cache: cache);
        for (var i = 0; i < maps.length; i++) {
          expect(guard.accepts(maps[i], i), isTrue);
        }
      }

      int retained() => [
        for (var i = 0; i < maps.length; i++)
          if (cache.contains(maps[i], i)) i,
      ].length;
      visit();
      expect(retained(), 1024);
      cache.prepare(maps.length);
      visit();
      expect(retained(), 2048);
      cache.prepare(maps.length);
      visit();
      expect(retained(), 2050);
      for (var i = 0; i < maps.length; i += 2) {
        maps[i] = <String, Object?>{...maps[i]};
      }
      cache.prepare(maps.length);
      visit();
      expect(retained(), 2049);
      maps = [
        for (final map in maps) <String, Object?>{...map},
      ];
      cache.prepare(maps.length);
      visit();
      expect(retained(), 1024);
      cache.clear();
      expect(retained(), 0);
    },
  );

  test('constructor representations retain backend-specific eligibility', () {
    for (final map in <Map<String, Object?>>[
      <String, double>{'x': 1, 'y': 2},
      Map<String, double>.of({'x': 1, 'y': 2}),
      <String, double>{
        ...<String, double>{'x': 1, 'y': 2},
      },
      Map<String, Object?>.of({'x': 1, 'y': 2}),
      Map<String, Object?>.unmodifiable({'x': 1, 'y': 2}),
    ]) {
      final expected = NativePointCoordinates().accepts(map);
      final cache = NativePointCoordinateCache()..prepare(1);
      for (var pass = 0; pass < 3; pass++) {
        expect(NativePointCoordinates(cache: cache).accepts(map, 0), expected);
        expect(cache.contains(map, 0), expected);
      }
    }
  });

  test('resize keeps only surviving slots and supports partial ranges', () {
    final cache = NativePointCoordinateCache()..prepare(8);
    final maps = [
      for (var i = 0; i < 8; i++) <String, double>{'x': i.toDouble(), 'y': 1},
    ];
    final guard = NativePointCoordinates(cache: cache);
    for (var i = 3; i < 7; i++) {
      expect(guard.accepts(maps[i], i), isTrue);
    }
    expect(cache.contains(maps[0], 0), isFalse);
    cache.prepare(5);
    expect(cache.contains(maps[3], 3), isTrue);
    cache.prepare(9);
    expect(cache.contains(maps[3], 3), isTrue);
    expect(cache.contains(maps[6], 6), isFalse);
    expect(guard.accepts(maps[0], -1), isTrue);
    expect(guard.accepts(maps[0], 10), isTrue);
    cache.prepare(0);
    expect(cache.contains(maps[3], 3), isFalse);
  });

  test(
    'custom type and property reads retain ordinary observations after hits',
    () {
      final cache = NativePointCoordinateCache()..prepare(4);
      final map = <String, Object?>{'x': 1.0, 'y': 2.0};
      expect(NativePointCoordinates(cache: cache).accepts(map, 1), isTrue);
      final custom = _ObservedMap();
      List<int> run(NativePointCoordinates guard) {
        custom.typeReads = 0;
        expect(guard.accepts(custom, 0), isFalse);
        final first = custom.typeReads;
        expect(guard.accepts(map, 1), isTrue);
        expect(guard.accepts(custom, 2), isFalse);
        return [first, custom.typeReads, custom.reads];
      }

      expect(
        run(NativePointCoordinates(cache: cache)),
        run(NativePointCoordinates()),
      );
      expect(cache.contains(custom, 2), isFalse);
      custom.throwsType = true;
      expect(
        () => NativePointCoordinates(cache: cache).accepts(custom, 1),
        throwsStateError,
      );
      custom.throwsType = false;
      expect(NativePointCoordinates(cache: cache).accepts(custom, 1), isFalse);
      expect(custom.reads, 0);
      expect(NativePointCoordinates(cache: cache).accepts(map, 1), isTrue);
    },
  );

  test('scope routes stay live and scopes never enter the identity cache', () {
    final cache = NativePointCoordinateCache()..prepare(1);
    final scope = PointOptionsScope()
      ..store('x', const OptValue<double>(1))
      ..store('y', const OptValue<double>(2));
    expect(NativePointCoordinates(cache: cache).accepts(scope, 0), isTrue);
    expect(cache.contains(scope, 0), isFalse);
    var calls = 0;
    scope.addRoute(
      'x',
      ScopeRoute(
        (local) {
          calls++;
          return local;
        },
        targetScope: null,
        targetName: 'x',
      ),
    );
    expect(NativePointCoordinates(cache: cache).accepts(scope, 0), isFalse);
    expect(calls, 0);
  });
}
