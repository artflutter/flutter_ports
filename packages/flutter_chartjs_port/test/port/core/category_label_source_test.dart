// Original code, not ported from Chart.js: native category-source guards.
import 'dart:collection';

import 'package:flutter_chartjs_port/src/core/category_label_source.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:test/test.dart';

final class _ObservedMap(final Map<String, Object?> entriesByKey)
    extends MapBase<String, Object?> {
  int reads = 0;
  @override
  Object? operator [](Object? key) {
    reads++;
    return entriesByKey[key];
  }

  @override
  void operator []=(String key, Object? value) => entriesByKey[key] = value;
  @override
  void clear() => entriesByKey.clear();
  @override
  Iterable<String> get keys => entriesByKey.keys;
  @override
  Object? remove(Object? key) => entriesByKey.remove(key);
}

final class _ObservedList() extends ListBase<Object?> {
  int reads = 0;
  final values = <Object?>['a', 'b'];
  @override
  int get length => values.length;
  @override
  set length(int value) => values.length = value;
  @override
  Object? operator [](int index) {
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, Object? value) => values[index] = value;
}

void main() {
  test('nonempty native config literals qualify on each backend', () {
    Map<String, Object?> config() => {
      'type': 'line',
      'data': <String, Object?>{
        'labels': <Object?>['a', 'b'],
        'datasets': <Object?>[],
      },
      'options': <String, Object?>{},
    };
    expect(nativeCategoryLabels(config(), null, horizontal: true), ['a', 'b']);
  });

  test('native constructor maps retain their own lookup semantics', () {
    for (final create in [
      Map<String, Object?>.new,
      Map<String, Object?>.identity,
    ]) {
      final labels = <Object?>['a', 'b'];
      final data = create()..['labels'] = labels;
      final config = create()..['data'] = data;
      expect(
        nativeCategoryLabels(config, null, horizontal: true),
        same(labels),
      );
      final replacement = <Object?>['changed'];
      data['labels'] = replacement;
      expect(
        nativeCategoryLabels(config, null, horizontal: true),
        same(replacement),
      );
    }
  });

  test('keeps explicit, axis-specific and ordinary label precedence', () {
    final ordinary = <Object?>['ordinary'];
    final x = <String>['x'];
    final y = List<String>.filled(1, 'y');
    final config = <String, Object?>{
      'data': <String, Object?>{'labels': ordinary, 'xLabels': x, 'yLabels': y},
    };
    expect(nativeCategoryLabels(config, null, horizontal: true), same(x));
    expect(nativeCategoryLabels(config, null, horizontal: false), same(y));
    final explicit = <Object?>[];
    expect(
      nativeCategoryLabels(config, explicit, horizontal: true),
      same(explicit),
    );
    (config['data']! as Map<String, Object?>).remove('xLabels');
    expect(
      nativeCategoryLabels(config, false, horizontal: true),
      same(ordinary),
    );
  });

  test('custom root and data Maps are rejected without reading their keys', () {
    final data = _ObservedMap({
      'labels': <Object?>['a'],
    });
    final root = _ObservedMap({'data': data});
    expect(nativeCategoryLabels(root, null, horizontal: true), isNull);
    expect(root.reads, 0);
    expect(
      nativeCategoryLabels(
        <String, Object?>{'data': data},
        null,
        horizontal: true,
      ),
      isNull,
    );
    expect(data.reads, 0);
  });

  test('custom lists are rejected without reading elements', () {
    final labels = _ObservedList();
    final config = <String, Object?>{
      'data': <String, Object?>{'labels': labels},
    };
    expect(nativeCategoryLabels(config, null, horizontal: true), isNull);
    expect(labels.reads, 0);
  });

  test('the native list remains live and is never replaced by a copy', () {
    final labels = <Object?>['a'];
    final config = <String, Object?>{
      'data': <String, Object?>{'labels': labels},
    };
    final first = nativeCategoryLabels(config, null, horizontal: true)!;
    labels[0] = 'changed';
    expect(first.single, 'changed');
    final replacement = <Object?>['replacement'];
    (config['data']! as Map<String, Object?>)['labels'] = replacement;
    expect(
      nativeCategoryLabels(config, null, horizontal: true),
      same(replacement),
    );
  });
  test(
    'exact typed roots and data scopes preserve the native label source',
    () {
      final labels = <String>['a', 'b'];
      final data = ChartDataScope()..labels = labels;
      final root = ChartConfigurationScope()..data = data;
      expect(nativeCategoryLabels(root, null, horizontal: true), same(labels));
      data.xLabels = <String>['x', 'y'];
      expect(
        nativeCategoryLabels(root, null, horizontal: true),
        same(data.xLabelsCell!.raw),
      );
      expect(
        nativeCategoryLabels(root, labels, horizontal: true),
        same(labels),
      );
    },
  );
  test('typed routes never run merely to qualify label reuse', () {
    var calls = 0;
    final data = ChartDataScope()..labels = <String>['a'];
    final root = ChartConfigurationScope()..data = data;
    data.addRoute(
      'labels',
      ScopeRoute(
        (value) {
          calls++;
          return value;
        },
        targetScope: null,
        targetName: 'labels',
      ),
    );
    calls = 0;
    expect(nativeCategoryLabels(root, null, horizontal: true), isNull);
    expect(calls, 0);
  });
}
