// Original code, not ported from Chart.js: ordered color resolution twins.
import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    as helpers;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:test/test.dart';

class _Ordinary extends Config {}

const red = Color(0xffff0000);
const blue = Color(0xff0000ff);
const green = Color(0xff00ff00);

Object? _plain(Object? value) {
  if (value is helpers.OptionView) {
    return {for (final key in value.jsKeys()) key: _plain(value.jsRead(key))};
  }
  return value;
}

void main() {
  for (final arity in ['one', 'two', 'this']) {
    for (final change in [
      'plain',
      'middle',
      'trailing',
      'descriptor',
      'array',
      'object',
      'index',
      'delete',
      'clear',
      'audit',
      'throw',
    ]) {
      test('$arity arguments preserve $change order and results', () {
        final outputs = <Object>[];
        final traces = <List<Object?>>[];
        for (final ordinary in [false, true]) {
          final config = ordinary ? _Ordinary() : Config();
          final scope = <String, Object?>{
            '_scriptable': true,
            '_indexable': true,
            'borderWidth': 1.0,
            'hitRadius': 1.0,
          };
          final scopes = <Object?>[scope];
          final prefixes = <String>['point', ''];
          final keys = <Object>[
            OptionKey.backgroundColor,
            OptionKey.borderWidth,
            OptionKey.borderColor,
            OptionKey.hitRadius,
          ];
          final trace = <Object?>[];
          var armed = false;
          helpers.OptionResolver raw() =>
              config.createResolver(scopes, null, prefixes)
                  as helpers.OptionResolver;
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
                case 'array' || 'index':
                  ctx.index = 1.0;
                case 'delete':
                  scope['borderWidth'] = 7.0;
                  raw().jsDelete('borderWidth');
                case 'clear':
                  config.clearCache();
                case 'audit':
                  raw().jsWrite('borderWidth', '5');
                case 'throw':
                  throw StateError('color failure');
              }
            }
            if (change == 'array') return <Color>[red, blue];
            if (change == 'object') return <String, Object?>{'value': 3};
            return red;
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

          Object wrap(Object? Function(Object?) callback) {
            Object? withOptions(Object? context, Object? options) {
              final view = options! as helpers.OptionView;
              expect(view.descriptors.allKeys, same(undefined));
              return callback(context);
            }

            return switch (arity) {
              'one' => callback,
              'two' => withOptions,
              _ => JsFunction((Object? self, Object? context, Object? options) {
                expect(self, same(undefined));
                return withOptions(context, options);
              }),
            };
          }

          scope['backgroundColor'] = wrap(background);
          scope['borderColor'] = wrap(border);
          final savedAudit = foreignAudit;
          foreignAudit = (_, key, _) {
            if (armed && change == 'audit' && key == 'borderWidth') {
              trace.add('audit');
              raw().jsWrite('borderColor', const ChartPaint.solid(green));
            }
          };
          try {
            for (var i = 0; i < 3; i++) {
              config.resolveOwnedElementNamedOptions(
                scopes,
                keys,
                () => ScriptableContext.data(null, 0, null),
                prefixes,
                point: true,
              );
            }
            armed = true;
            try {
              final result = config.resolveOwnedElementNamedOptions(
                scopes,
                keys,
                () => ScriptableContext.data(null, 0, null),
                prefixes,
                point: true,
              );
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
            foreignAudit = savedAudit;
          }
        }
        expect(outputs[0], outputs[1]);
        expect(traces[0], traces[1]);
        if (change == 'middle') expect(traces[0][1], 'width');
        if (change == 'trailing') expect(traces[0].last, 'hit');
        if (change == 'audit') {
          expect(traces[0], [
            ['background', 0.0],
            'audit',
          ]);
        }
      });
    }
  }
}
