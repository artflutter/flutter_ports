// Original code, not ported from Chart.js: prepared scalar point continuations.
import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    as helpers;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:test/test.dart';

class _Ordinary extends Config {
  _Ordinary(super.config);
}

const red = Color(0xffff0000);
const blue = Color(0xff0000ff);

Object? _plain(Object? value) => value is helpers.OptionView
    ? {for (final key in value.jsKeys()) key: _plain(value.jsRead(key))}
    : value;

void main() {
  for (final change in [
    'plain',
    'context-clear',
    'prepared-context-clear',
    'replan',
    'context-resolver',
    'context-keys',
    'context-throw',
    'middle',
    'trailing',
    'descriptor',
    'delete',
    'clear',
    'array',
    'object',
    'null',
    'undefined',
    'throw',
    'nested',
  ]) {
    test('prepared scalar executor preserves $change calls and results', () {
      final outputs = <Object>[];
      final traces = <List<Object?>>[];
      for (final ordinary in [false, true]) {
        final saved = defaults.saveState();
        try {
          final point = PointOptionsScope()
            ..backgroundColor = red
            ..borderWidth = 1
            ..borderColor = blue
            ..hitRadius = 1;
          defaults.elements = ElementOptionsByTypeScope()..point = point;
          final dataset = <String, Object?>{
            '_scriptable': true,
            '_indexable': true,
            'data': <Object?>[
              <String, double>{'x': 1, 'y': 2},
            ],
          };
          final root = <String, Object?>{
            'type': 'line',
            'data': <String, Object?>{
              'datasets': <Object?>[dataset],
            },
          };
          final config = ordinary ? _Ordinary(root) : Config(root);
          final scopes = config.getOptionScopes(
            dataset,
            config.datasetElementScopeKeys('line', 'point'),
          );
          final keys = point.nativeOwnKeySnapshot;
          final prefixes = <String>['point', ''];
          helpers.OptionResolver raw() =>
              config.createResolver(scopes, null, prefixes)
                  as helpers.OptionResolver;
          final trace = <Object?>[];
          var armed = false;
          var nested = false;
          Object? background(Object? context) {
            final ctx = context! as ScriptableContext;
            if (armed) {
              trace.add(['background', ctx.index]);
              switch (change) {
                case 'middle':
                  raw().jsWrite('borderWidth', (Object? _) {
                    trace.add('width');
                    return 5.0;
                  });
                case 'descriptor':
                  raw().jsWrite('_scriptable', false);
                case 'delete':
                  dataset['borderWidth'] = 7.0;
                  raw().jsDelete('borderWidth');
                case 'clear':
                  config.clearCache();
                case 'throw':
                  throw StateError('color failure');
                case 'nested':
                  if (!nested) {
                    nested = true;
                    config.resolveOwnedElementNamedOptions(
                      scopes,
                      keys,
                      () => ScriptableContext.data(null, 2, null),
                      prefixes,
                      point: true,
                      immutableKeys: true,
                    );
                    nested = false;
                  }
              }
            }
            return switch (change) {
              'array' => <Color>[red, blue],
              'object' => <String, Object?>{'value': 3},
              'null' => null,
              'undefined' => undefined,
              _ => red,
            };
          }

          Object? border(Object? context) {
            if (armed) {
              trace.add(['border', (context! as ScriptableContext).index]);
              if (change == 'trailing') {
                raw().jsWrite('hitRadius', (Object? _) {
                  trace.add('hit');
                  return 9.0;
                });
              }
            }
            return blue;
          }

          dataset['backgroundColor'] = background;
          dataset['borderColor'] = border;
          for (var i = 0; i < 3; i++) {
            config.resolveOwnedElementNamedOptions(
              scopes,
              keys,
              () => ScriptableContext.data(null, 0, null),
              prefixes,
              point: true,
              immutableKeys: true,
            );
          }
          final plan = ordinary ? null : config.prepareLineResolution(0)!;
          if (change == 'replan') {
            raw().jsWrite('backgroundColor', (Object? _) => blue);
            for (var i = 0; i < 3; i++) {
              config.resolveOwnedElementNamedOptions(
                scopes,
                keys,
                () => ScriptableContext.data(null, 0, null),
                prefixes,
                point: true,
                immutableKeys: true,
              );
            }
          }
          armed = true;
          Object context() {
            trace.add('context');
            switch (change) {
              case 'context-clear' || 'prepared-context-clear':
                config.clearCache();
              case 'context-resolver':
                raw().jsWrite('borderWidth', 7.0);
              case 'context-keys':
                point.jsWrite('extra', 9);
              case 'context-throw':
                throw StateError('context failure');
            }
            return ScriptableContext.data(null, 1, null);
          }

          try {
            final result = ordinary
                ? config.resolveOwnedElementNamedOptions(
                    scopes,
                    keys,
                    context,
                    prefixes,
                    point: true,
                    immutableKeys: true,
                  )
                : plan!.resolve(
                    change == 'prepared-context-clear'
                        ? () => fail('ordinary context must not run')
                        : context,
                    change == 'prepared-context-clear' ? context : null,
                  )!;
            outputs.add([
              result.jsKeys(),
              {
                for (final key in result.jsKeys())
                  key: _plain(result.jsRead(key)),
              },
              result.isFrozen,
            ]);
          } on Object catch (error) {
            expect(error, isA<StateError>());
            outputs.add((error as StateError).message);
          }
          traces.add(trace);
        } finally {
          defaults.restoreState(saved);
        }
      }
      expect(outputs[0], outputs[1]);
      expect(traces[0], traces[1]);
      expect(traces[0].where((e) => e == 'context'), hasLength(1));
    });
  }
}
