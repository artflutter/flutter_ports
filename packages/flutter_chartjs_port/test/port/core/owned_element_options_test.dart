// Original code, not ported from Chart.js: owned option result and setup twins.
import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    as helpers;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/element_options_base.dart';
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/resolved.g.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:test/test.dart';

const red = ChartPaint.solid(Color(0xffff0000));
const blue = ChartPaint.solid(Color(0xff0000ff));

class _ObservedId {
  int calls = 0;
  @override
  String toString() {
    calls++;
    return 'point';
  }
}

class _OrdinaryConfig extends Config {
  final results = <ElementOptions>[];
  @override
  ElementOptions resolveElementNamedOptions(
    List<Object?> scopes,
    List<Object> keys,
    Object Function() context,
    List<String> prefixes,
    ElementOptions into,
  ) {
    results.add(into);
    return super.resolveElementNamedOptions(
      scopes,
      keys,
      context,
      prefixes,
      into,
    );
  }
}

class _Fixture {
  _Fixture({bool ordinary = false, this.point = true})
    : config = ordinary ? _OrdinaryConfig() : Config();
  final Config config;
  final bool point;
  final scope = <String, Object?>{
    '_scriptable': true,
    '_indexable': true,
    'borderWidth': 1.0,
    'backgroundColor': red,
    'borderColor': blue,
  };
  late final scopes = <Object?>[scope];
  final keySource = PointOptionsScope()
    ..borderWidth = 1
    ..backgroundColor = red
    ..borderColor = blue;
  final prefixes = <String>['point', ''];
  int contexts = 0;
  void Function()? beforeContext;
  ElementOptions resolve([double index = 0]) =>
      config.resolveOwnedElementNamedOptions(
        scopes,
        keySource.nativeOwnKeySnapshot,
        () {
          contexts++;
          beforeContext?.call();
          return ScriptableContext.data(null, index, null);
        },
        prefixes,
        point: point,
        immutableKeys: true,
      );
  helpers.OptionResolver get resolver =>
      config.createResolver(scopes, null, prefixes) as helpers.OptionResolver;
}

Object? plain(Object? value) {
  if (value is helpers.OptionView) {
    return {for (final key in value.jsKeys()) key: plain(value.jsRead(key))};
  }
  if (value is List<Object?>) return value.map(plain).toList();
  return value;
}

void expectSame(ElementOptions a, ElementOptions b) {
  expect(a.jsKeys(), b.jsKeys());
  for (final key in b.jsKeys()) {
    expect(plain(a.jsRead(key)), plain(b.jsRead(key)), reason: key);
  }
}

void main() {
  setUp(() {
    final saved = foreignAudit;
    foreignAudit = (_, _, _) {};
    addTearDown(() => foreignAudit = saved);
  });
  for (final point in [true, false]) {
    for (final style in [
      'static',
      'indexed',
      'scriptable',
      'empty',
      'foreign',
      'extra',
    ]) {
      test('fresh owned ${point ? 'point' : 'bar'} results: $style', () {
        final a = _Fixture(point: point);
        final b = _Fixture(point: point, ordinary: true);
        final counts = <int>[0, 0];
        for (var j = 0; j < 2; j++) {
          final f = [a, b][j];
          ChartPaint color(Object? ctx) {
            counts[j]++;
            return (ctx! as ScriptableContext).index == 1 ? blue : red;
          }

          if (style == 'indexed') {
            f.scope['backgroundColor'] = <ChartPaint>[red, blue];
          }
          if (style == 'scriptable') {
            f.scope['backgroundColor'] = color;
          }
          if (style == 'empty') f.scope['backgroundColor'] = <Object?>[];
          if (style == 'foreign') f.scope['borderWidth'] = '4';
          if (style == 'extra') {
            f.keySource.jsWrite('extra', true);
            f.scope['extra'] = true;
          }
        }
        final results = <ElementOptions>[];
        for (var i = 0; i < 4; i++) {
          final x = a.resolve(i.toDouble());
          final y = b.resolve(i.toDouble());
          expectSame(x, y);
          expect(x.isFrozen, isFalse);
          expect(point ? x is PointOptions : x is BarOptions, isTrue);
          results.add(x);
          x
            ..storeKey(OptionKey.borderWidth, 99.0)
            ..freeze();
        }
        expect(results.toSet().length, 4);
        expect(a.contexts, b.contexts);
        expect(counts[0], counts[1]);
        expect((b.config as _OrdinaryConfig).results.toSet().length, 4);
      });
    }
  }
  for (final mutation in ['resolver', 'clear', 'keys', 'context', 'nested']) {
    test(
      'owned fallback preserves $mutation mutation order and one context call',
      () {
        final outputs = <List<ElementOptions>>[];
        final traces = <List<Object?>>[];
        for (final ordinary in [false, true]) {
          final f = _Fixture(ordinary: ordinary);
          final trace = <Object?>[];
          var mutate = false;
          Object? color(Object? ctx, Object? opts) {
            trace.add((ctx! as ScriptableContext).index);
            if (mutate) {
              switch (mutation) {
                case 'resolver':
                  (opts! as helpers.OptionView).jsWrite('borderColor', red);
                case 'clear':
                  f.scope['borderColor'] = red;
                  f.config.clearCache();
                case 'keys':
                  f.keySource.jsDelete('borderColor');
                  f.keySource.jsWrite('extra', true);
                  f.scope['extra'] = 7;
                case 'context':
                  break;
                case 'nested':
                  return <String, Object?>{'inner': 3};
              }
            }
            return red;
          }

          f.scope['backgroundColor'] = color;
          f
            ..resolve()
            ..resolve();
          mutate = true;
          if (mutation == 'context') {
            f.beforeContext = () {
              f.resolver.jsWrite('borderColor', red);
            };
          }
          outputs.add([f.resolve(2), f.resolve(3)]);
          traces.add(trace);
          expect(f.contexts, 4);
        }
        expectSame(outputs[0][0], outputs[1][0]);
        expectSame(outputs[0][1], outputs[1][1]);
        expect(traces[0], traces[1]);
      },
    );
  }
  test('nested resolution never exposes or corrupts a shared type token', () {
    final f = _Fixture();
    ElementOptions? inner;
    ChartPaint color(Object? ctx) {
      final index = (ctx! as ScriptableContext).index;
      if (index == 1) inner = f.resolve(2);
      return index == 1 ? red : blue;
    }

    f.scope['backgroundColor'] = color;
    f.resolve();
    final outer = f.resolve(1);
    expect(outer.valueOf(OptionKey.backgroundColor), red);
    expect(inner!.valueOf(OptionKey.backgroundColor), blue);
    expect(identical(outer, inner), isFalse);
    expect(outer.isFrozen, isFalse);
    expect(inner!.isFrozen, isFalse);
    expect(f.resolve(3).valueOf(OptionKey.backgroundColor), blue);
  });
  test(
    'scope key conversions remain live and joined-string collisions remain',
    () {
      final config = Config();
      final id = _ObservedId();
      final a = config.datasetElementScopeKeys('line', id);
      final b = config.datasetElementScopeKeys('line', id);
      expect(id.calls, 2);
      expect(a, same(b));
      final first = config.datasetElementScopeKeys('setup-a', 'b-c');
      expect(config.datasetElementScopeKeys('setup-a-b', 'c'), same(first));
      first.add(['live']);
      expect(config.datasetElementScopeKeys('setup-a', 'b-c').last, ['live']);
    },
  );
  test('immutable snapshots do not weaken mutable-key context rechecks', () {
    final config = Config();
    final scope = <String, Object?>{
      '_scriptable': true,
      '_indexable': true,
      'borderWidth': 1.0,
      'backgroundColor': <ChartPaint>[red, blue],
    };
    final scopes = <Object?>[scope];
    final keys = <Object>[OptionKey.borderWidth, OptionKey.backgroundColor];
    final prefixes = <String>['point', ''];
    ElementOptions resolve(Object Function() context) =>
        config.resolveOwnedElementNamedOptions(
          scopes,
          keys,
          context,
          prefixes,
          point: true,
        );
    resolve(() => ScriptableContext.data(null, 0, null));
    final result = resolve(() {
      keys.remove(OptionKey.backgroundColor);
      return ScriptableContext.data(null, 0, null);
    });
    expect(result.jsRead('backgroundColor'), same(undefined));
    expect(result.jsRead('borderWidth'), 1);
  });
}
