// Original code, not ported from Chart.js: scriptable option template twins.
import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    as helpers;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/options/element_options_base.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/resolved.g.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:test/test.dart';

const red = ChartPaint.solid(Color(0xffff0000));
const blue = ChartPaint.solid(Color(0xff0000ff));

class _OrdinaryConfig extends Config;

class _Fixture {
  _Fixture({bool ordinary = false})
    : config = ordinary ? _OrdinaryConfig() : Config() {
    scopes = [scope];
    Object? background(Object? ctx, Object? options) {
      final view = options! as helpers.OptionView;
      retained.add(view);
      calls.add((ctx! as ScriptableContext).index);
      action?.call(view);
      return color;
    }

    scope['backgroundColor'] = background;
  }
  final Config config;
  final scope = <String, Object?>{
    '_scriptable': true,
    '_indexable': true,
    'radius': 3.0,
    'borderWidth': 1.0,
    'borderColor': blue,
  };
  late final List<Object?> scopes;
  final keys = <Object>[
    OptionKey.radius,
    OptionKey.backgroundColor,
    OptionKey.borderWidth,
    OptionKey.borderColor,
  ];
  final prefixes = <String>['point', ''];
  final calls = <Object?>[];
  final retained = <helpers.OptionView>[];
  void Function(helpers.OptionView)? action;
  void Function()? beforeContext;
  Object? color = red;
  PointOptions resolve([double index = 0]) =>
      config.resolveNativeElementNamedOptions(
        scopes,
        keys,
        () {
          beforeContext?.call();
          return ScriptableContext.data(null, index, null);
        },
        prefixes,
        PointOptions(),
        allowReplacement: true,
      ) as PointOptions;
  helpers.OptionResolver get resolver =>
      config.createResolver(scopes, null, prefixes) as helpers.OptionResolver;
  bool probe() =>
      resolver
          .resolveScriptableElementOptions(
            keys,
            () => ScriptableContext.data(null, 0, null),
            PointOptions(),
            Defaults.nativeElementDescriptors,
            () => true,
          )
          ?.resolved ??
      false;
}

Object? plain(Object? value) => value is helpers.OptionView
    ? {for (final key in value.jsKeys()) key: plain(value.jsRead(key))}
    : value;
void same(ElementOptions a, ElementOptions b) {
  expect(a.jsKeys(), b.jsKeys());
  for (final k in b.jsKeys()) {
    expect(plain(a.jsRead(k)), plain(b.jsRead(k)), reason: k);
  }
}

void main() {
  test(
    'warm template activates, callbacks and returned options remain fresh',
    () {
      final f = _Fixture()..resolve();
      expect(f.probe(), isTrue);
      final first = f.resolve(1)
        ..storeKey(OptionKey.radius, 99.0)
        ..freeze();
      final next = f.resolve(2);
      expect(identical(first, next), isFalse);
      expect(next.radius, 3);
      expect(next.$sharedValue, isFalse);
      expect(f.calls, [0.0, 0.0, 1.0, 2.0]);
      expect(f.retained.toSet().length, 4);
      expect((f.retained[2].context as ScriptableContext).index, 1);
    },
  );
  for (final change in [
    'write',
    'delete',
    'retained',
    'clear',
    'context',
    'nested',
    'array',
  ]) {
    test('callback $change matches ordinary resolution after warmup', () {
      final fixtures = [_Fixture(), _Fixture(ordinary: true)];
      final results = <List<PointOptions>>[];
      for (final f in fixtures) {
        f
          ..resolve()
          ..resolve();
        final old = f.retained.first;
        var acted = false;
        f.action = (view) {
          if (acted) return;
          acted = true;
          switch (change) {
            case 'write':
              view.jsWrite('borderWidth', 7.0);
            case 'delete':
              f.scope['borderWidth'] = 9.0;
              view.jsDelete('borderWidth');
            case 'retained':
              old.jsWrite('borderWidth', 8.0);
            case 'clear':
              f.scope['borderWidth'] = 6.0;
              f.config.clearCache();
            case 'context':
              break;
            case 'nested':
              f.color = <String, Object?>{'inner': 42};
            case 'array':
              f.color = <ChartPaint>[red, blue];
          }
        };
        if (change == 'context') {
          f.beforeContext = () {
            f.resolver.jsWrite('borderWidth', 11.0);
          };
        }
        results.add([f.resolve(3), f.resolve(4)]);
      }
      for (var i = 0; i < 2; i++) {
        same(results[0][i], results[1][i]);
      }
      expect(fixtures[0].calls, fixtures[1].calls);
    });
  }
  test('callback reads of later static fields retain subview caching', () {
    final a = _Fixture();
    final b = _Fixture(ordinary: true);
    for (final f in [a, b]) {
      f.resolve();
      f.action = (v) {
        expect(v.jsRead('borderWidth'), 1);
        f.scope['borderWidth'] = 12.0;
      };
    }
    same(a.resolve(), b.resolve());
  });
  test(
    'custom descriptors and numeric callbacks retain ordinary traversal',
    () {
      for (final ordinary in [false, true]) {
        final f = _Fixture(ordinary: ordinary);
        var calls = 0;
        f.scope['_scriptable'] = (name) {
          calls++;
          return true;
        };
        f.scope['radius'] = (ctx) => 5.0;
        f.resolve();
        expect(f.probe(), isFalse);
        expect(f.resolve().radius, 5);
        expect(calls, greaterThan(0));
      }
    },
  );
  for (final change in [
    'scalar',
    'write',
    'delete',
    'nested',
    'array',
    'function',
  ]) {
    test('context-only callback $change preserves ordinary results', () {
      final outputs = <List<PointOptions>>[];
      final counts = <int>[];
      for (final ordinary in [false, true]) {
        final f = _Fixture(ordinary: ordinary);
        var calls = 0;
        var mutate = false;
        Object? callback(Object? ctx) {
          calls++;
          if (mutate) {
            if (change == 'write') f.resolver.jsWrite('borderWidth', 8.0);
            if (change == 'delete') {
              f.scope['borderWidth'] = 9.0;
              f.resolver.jsDelete('borderWidth');
            }
          }
          return switch (change) {
            'nested' => <String, Object?>{'value': 42},
            'array' => <ChartPaint>[red, blue],
            'function' => callback,
            _ => red,
          };
        }

        f.scope['backgroundColor'] = callback;
        f
          ..resolve()
          ..resolve();
        mutate = true;
        outputs.add([f.resolve(3), f.resolve(4)]);
        counts.add(calls);
      }
      if (change == 'function') {
        expect(outputs[0][0].backgroundColorValue, isA<Function>());
        expect(outputs[1][0].backgroundColorValue, isA<Function>());
      } else {
        for (var i = 0; i < 2; i++) {
          same(outputs[0][i], outputs[1][i]);
        }
      }
      expect(counts[0], counts[1]);
    });
  }

  test('optional second argument still receives a fresh resolver', () {
    final f = _Fixture();
    final seen = <Object?>[];
    ChartPaint background(Object? ctx, [Object? options]) {
      seen.add(options);
      expect(options, isA<helpers.OptionView>());
      return red;
    }

    f.scope['backgroundColor'] = background;
    f
      ..resolve()
      ..resolve()
      ..resolve();
    expect(seen.toSet().length, 3);
  });

  test('recursive callback still throws', () {
    final f = _Fixture()
      ..resolve()
      ..action = (v) {
        v.jsRead('backgroundColor');
      };
    expect(f.resolve, throwsStateError);
  });
}
