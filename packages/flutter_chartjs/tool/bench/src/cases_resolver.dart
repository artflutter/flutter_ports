// Original code, not ported from Chart.js: the option resolver benchmarks.

/// The cases of `helpers.config`: the static path of `_createResolver`, the
/// scriptable path of `_attachContext`, nested sub-resolvers,
/// `_descriptors` and `Object.keys` of a resolver.
///
/// Chart.js ADR 0006 measured a prototype at 60 ns per bar element with
/// static options and 1,330 ns with scriptable options (AOT), and chart.js
/// in Node.js at 37 ns and 1,760 ns.
library;

import 'package:flutter_chartjs/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs/src/helpers/helpers.config.dart';
import 'package:flutter_chartjs/src/helpers/helpers.core.dart';
import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/types/basic.dart';

import 'fixtures.dart';
import 'harness.dart';

/// `hasFunction` of `core.config.js:396`.
bool _hasFunction(Object? value) {
  if (!isObject(value)) return false;
  final object = value! as AnyObject;
  return object.keys.any((key) => isFunction(object[key]));
}

/// `needContext` of `core.config.js:399`.
bool _needContext(Object proxy, List<String> names) {
  final d = descriptors(proxy);
  for (final prop in names) {
    final scriptable = d.isScriptable(prop);
    final indexable = d.isIndexable(prop);
    final value = (indexable || scriptable) ? jsGet(proxy, prop) : false;
    if ((scriptable && (isFunction(value) || _hasFunction(value))) ||
        (indexable && isArray(value))) {
      return true;
    }
  }
  return false;
}

/// `Config.resolveNamedOptions` (`core.config.js:353`) with a cached
/// resolver, as `getResolver` gives it, and a context of the element.
AnyObject _resolveNamedOptions(
  Resolver resolver,
  Resolver subResolverBase,
  List<String> names,
  AnyObject context,
) {
  final result = <String, Object?>{r'$shared': true};
  Object options = resolver;
  if (_needContext(resolver, names)) {
    result[r'$shared'] = false;
    final subResolver = attachContext(subResolverBase, context);
    options = attachContext(resolver, context, subResolver);
  }
  for (final prop in names) {
    result[prop] = jsGet(options, prop);
  }
  return result;
}

int _readAll(Object resolver, List<String> names) {
  var acc = 0;
  for (final name in names) {
    final value = jsGet(resolver, name);
    acc += value is String ? value.length : 1;
  }
  return acc;
}

/// The resolver cases.
List<BenchCase> resolverCases() => [
  BenchCase(
    'resolver',
    'resolver/cold_create_read10',
    () {
      final scopes = barElementScopes(staticBarDataset(0), barChartOptions());
      final names = barOptionNames();
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          acc += _readAll(createResolver(scopes, ['bar', '']), names);
        }
        return acc;
      };
    },
    per: 'createResolver over 7 bar scopes + 10 first reads',
  ),
  BenchCase(
    'resolver',
    'resolver/warm_read10',
    () {
      final scopes = barElementScopes(staticBarDataset(0), barChartOptions());
      final names = barOptionNames();
      final resolver = createResolver(scopes, ['bar', '']);
      _readAll(resolver, names);
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          acc += _readAll(resolver, names);
        }
        return acc;
      };
    },
    per: '10 cached reads of one resolver',
  ),
  BenchCase(
    'resolver',
    'resolver/named_static_element',
    () {
      final scopes = barElementScopes(staticBarDataset(0), barChartOptions());
      final names = barOptionNames();
      final resolver = createResolver(scopes, ['bar', '']);
      final sub = createResolver(scopes, ['bar', '']);
      final contexts = dataContexts(100);
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          acc += _resolveNamedOptions(
            resolver,
            sub,
            names,
            contexts[i % 100],
          ).length;
        }
        return acc;
      };
    },
    per: 'resolveNamedOptions of a bar element, static options, 10 names',
  ),
  BenchCase(
    'resolver',
    'resolver/scriptable_attach_read10',
    () {
      final scopes = barElementScopes(
        scriptableBarDataset(0),
        barChartOptions(),
      );
      final names = barOptionNames();
      final resolver = createResolver(scopes, ['bar', '']);
      final contexts = dataContexts(100);
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          final proxy = attachContext(resolver, contexts[i % 100]);
          acc += _readAll(proxy, names);
        }
        return acc;
      };
    },
    per: '_attachContext + 10 reads (2 scriptable, 1 indexable)',
  ),
  BenchCase(
    'resolver',
    'resolver/named_scriptable_element',
    () {
      final scopes = barElementScopes(
        scriptableBarDataset(0),
        barChartOptions(),
      );
      final names = barOptionNames();
      final resolver = createResolver(scopes, ['bar', '']);
      final sub = createResolver(scopes, ['bar', '']);
      final contexts = dataContexts(100);
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          acc += _resolveNamedOptions(
            resolver,
            sub,
            names,
            contexts[i % 100],
          ).length;
        }
        return acc;
      };
    },
    per: 'resolveNamedOptions of a bar element, scriptable, 10 names',
  ),
  BenchCase(
    'resolver',
    'resolver/nested_font_cold',
    () {
      final scale = <String, Object?>{
        'ticks': <String, Object?>{
          'font': <String, Object?>{'size': 14.0},
        },
      };
      final scopes = <Object?>[scale, defaults['scale'], defaults];
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          final resolver = createResolver(scopes);
          final font = jsGet(jsGet(resolver, 'ticks'), 'font');
          acc +=
              _readAll(font!, const [
                'size',
                'family',
                'style',
                'weight',
                'lineHeight',
              ]) +
              (jsGet(resolver, 'font') == null ? 0 : 1);
        }
        return acc;
      };
    },
    per: 'createResolver + ticks.font sub-resolvers + 5 font reads',
  ),
  BenchCase(
    'resolver',
    'resolver/nested_font_warm',
    () {
      final scale = <String, Object?>{
        'ticks': <String, Object?>{
          'font': <String, Object?>{'size': 14.0},
        },
      };
      final resolver = createResolver(<Object?>[
        scale,
        defaults['scale'],
        defaults,
      ]);
      jsGet(jsGet(jsGet(resolver, 'ticks'), 'font'), 'size');
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          final size = jsGet(jsGet(jsGet(resolver, 'ticks'), 'font'), 'size');
          acc += size == null ? 0 : 1;
        }
        return acc;
      };
    },
    per: 'resolver.ticks.font.size, all cached',
  ),
  BenchCase(
    'resolver',
    'resolver/descriptors',
    () {
      final scopes = barElementScopes(staticBarDataset(0), barChartOptions());
      final resolver = createResolver(scopes, ['bar', '']);
      descriptors(resolver);
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          final d = descriptors(resolver);
          acc += d.isScriptable('backgroundColor') ? 1 : 0;
          acc += d.isIndexable('backgroundColor') ? 1 : 0;
        }
        return acc;
      };
    },
    per: '_descriptors + isScriptable + isIndexable',
  ),
  BenchCase(
    'resolver',
    'resolver/object_keys_warm',
    () {
      final scopes = barElementScopes(staticBarDataset(0), barChartOptions());
      final resolver = createResolver(scopes, ['bar', '']);
      jsObjectKeys(resolver);
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          acc += jsObjectKeys(resolver).length;
        }
        return acc;
      };
    },
    per: 'Object.keys(resolver), _keys cached',
  ),
  BenchCase(
    'resolver',
    'resolver/object_keys_cold',
    () {
      final scopes = barElementScopes(staticBarDataset(0), barChartOptions());
      return (n) {
        var acc = 0;
        for (var i = 0; i < n; i++) {
          acc += jsObjectKeys(createResolver(scopes, ['bar', ''])).length;
        }
        return acc;
      };
    },
    per: 'createResolver + Object.keys over 7 scopes',
  ),
];
