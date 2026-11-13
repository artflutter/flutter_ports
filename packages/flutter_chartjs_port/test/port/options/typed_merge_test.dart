// Original code, not ported from Chart.js: the typed merge of helpers.core.

// The row adapt-typed-scope-merge: `merge` and `mergeIf` of a typed scope
// into a typed scope, and the typed copy of `_cloneToScope`, walk the typed
// keys of the two scopes. Each case runs the same merge twice, with the
// typed walk and with the walk by name (`OptionScope.debugTypedMerge`), from
// the same start, and compares the results: the keys and their order, the
// class of each cell (its kind and type), the values, the kinds of the
// nested scopes, the calls of the foreign audit (oracle O2) and the throws.

import 'dart:ui' show FontWeight;

import 'package:flutter/painting.dart' show TextStyle;

import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show CirclePointStyle;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show clone, merge, mergeIf;
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show JsObjectFace, jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';
import 'package:flutter_chartjs_port/src/types/axis_border.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:flutter_chartjs_port/src/types/layout.dart' show ChartPosition;
import 'package:test/test.dart';

import '../../support/light_theme.dart';

/// A function value of an option.
Object? _fn(Object? ctx) => ctx;

/// An instance of a Dart class: a leaf for clone and merge.
final class const _Instance();

/// A subclass of a scope class: the merge reads and writes it by name.
final class _SubScale() extends ScaleOptionsScope;

/// The structure of [value]: the keys in their order, the class of each
/// cell, the values and the classes of the objects. A function and a class
/// instance print their identity: the two runs of a case share them.
String _describe(Object? value) => switch (value) {
  null => 'null',
  Undefined() => 'undefined',
  final OptionScope scope => '${scope.runtimeType}{${_scopeEntries(scope)}}',
  final Map<String, Object?> map => '${map.runtimeType}{${_mapEntries(map)}}',
  final List<Object?> list =>
    '${list.runtimeType}[${list.map(_describe).join(', ')}]',
  final double number => number == 0 && number.isNegative ? '-0.0' : '$number',
  final String string => '"$string"',
  final Function function => 'function#${identityHashCode(function)}',
  // A font is an immutable value (Chart.js ADR 0116): its fields.
  final TextStyle font => '$font',
  // A scale border is an immutable value too (Chart.js ADR 0141).
  final ScaleBorder border => '$border',
  _ => '${value.runtimeType}#${identityHashCode(value)}',
};

/// Each own key of [scope] in the `Object.keys` order, with its cell.
String _scopeEntries(OptionScope scope) =>
    [for (final name in scope.jsKeys()) '$name: ${_cell(scope.lookup(name))}']
        .join(', ');

/// Each entry of [map] in its order.
String _mapEntries(Map<String, Object?> map) => [
  for (final MapEntry(:key, :value) in map.entries) '$key: ${_describe(value)}',
].join(', ');

String _cell(Opt<Object?>? cell) =>
    cell == null ? 'absent' : '${cell.runtimeType}(${_describe(cell.raw)})';

/// The result of one run of a body: the structure of its value, the audit
/// calls and the type of a throw.
typedef _Run = ({String text, List<String> audits, Type? error});

_Run _run(Object? Function() body) {
  final audits = <String>[];
  final saved = foreignAudit;
  foreignAudit = (owner, key, raw) =>
      audits.add('$owner.$key = ${_describe(raw)}');
  try {
    return (text: _describe(body()), audits: audits, error: null);
    // A JavaScript TypeError of a write into a frozen object.
    // ignore: avoid_catching_errors
  } on TypeError catch (error) {
    return (text: '', audits: audits, error: error.runtimeType);
  } finally {
    foreignAudit = saved;
  }
}

/// Runs [body] with the typed walk and with the walk by name, and expects
/// the same results. [body] builds its scopes at each call.
void _expectTwins(Object? Function() body) {
  final _Run typed;
  final _Run byName;
  try {
    OptionScope.debugTypedMerge = true;
    typed = _run(body);
    OptionScope.debugTypedMerge = false;
    byName = _run(body);
  } finally {
    OptionScope.debugTypedMerge = true;
  }
  expect(typed.text, byName.text);
  expect(typed.audits, byName.audits);
  expect(typed.error, byName.error);
}

/// A scale source with each kind of cell: values of the key types, an int
/// for a number, foreign values, `undefined` and `null`, a function, a
/// list, Maps and typed scopes under declared keys and under extras, the
/// reserved names and a class instance.
ScaleOptionsScope _source() => ScaleOptionsScope()
  ..jsWrite('type', 'linear')
  ..jsWrite('display', true)
  ..jsWrite('min', undefined)
  ..jsWrite('max', null)
  ..jsWrite('weight', 2)
  ..jsWrite('stackWeight', 'heavy')
  ..jsWrite('beforeFit', _fn)
  ..jsWrite('labels', <Object?>[
    'a',
    <String, Object?>{'b': 1.0},
  ])
  ..jsWrite('position', <String, Object?>{'x': 5.0})
  ..jsWrite(
    'ticks',
    TickOptionsScope()
      ..jsWrite('color', 'red')
      ..jsWrite(
        'font',
        const ChartTextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      )
      ..jsWrite('major', <String, Object?>{'enabled': true})
      ..jsWrite('padding', '3')
      ..jsWrite('extraTick', <String, Object?>{
        'deep': <Object?>[1.0],
      }),
  )
  ..jsWrite('grid', <String, Object?>{'color': 'blue', 'lineWidth': 2})
  ..jsWrite('extraScope', MajorTickOptionsScope()..jsWrite('enabled', true))
  ..jsWrite('extraMap', <String, Object?>{'k': 'v'})
  ..jsWrite('__proto__', <String, Object?>{'polluted': true})
  ..jsWrite('prototype', 1.0)
  ..jsWrite('constructor', 2.0)
  ..jsWrite('instance', const _Instance());

/// A scale target that owns some keys of [_source]: a leaf, objects under
/// both, a leaf under an object of the source and a Map under an extra.
ScaleOptionsScope _target() => ScaleOptionsScope()
  ..jsWrite('display', false)
  ..jsWrite('ticks', TickOptionsScope()..jsWrite('color', 'green'))
  ..jsWrite('grid', 5.0)
  ..jsWrite('extraMap', <String, Object?>{'k2': 'v2'})
  ..jsWrite('min', 0.0);

/// A tick scope with routes: an object local value gives a new merged
/// object at each read, a scalar route gives a foreign value, and a route
/// of a key that the scope did not own appends it.
TickOptionsScope _routedTicks() => TickOptionsScope()
  ..jsWrite('color', <String, Object?>{'a': 1.0})
  ..jsWrite('padding', 3.0)
  ..addRoute(
    'color',
    ScopeRoute(
      (local) => local is Map<String, Object?>
          ? <String, Object?>{'from': 'route', ...local}
          : local,
      targetScope: null,
      targetName: 'color',
    ),
  )
  ..addRoute(
    'padding',
    ScopeRoute((local) => 'routed', targetScope: null, targetName: 'padding'),
  )
  ..addRoute(
    'display',
    ScopeRoute((local) => true, targetScope: null, targetName: 'display'),
  );

void main() {
  group('adapt-typed-scope-merge', () {
    // The sources hold foreign values on purpose: each test keeps the audit
    // of the oracle O2 to itself (AGENTS.md, Tests).
    setUp(() {
      final saved = foreignAudit;
      foreignAudit = (owner, key, raw) {};
      addTearDown(() => foreignAudit = saved);
    });

    test('mergeIf of a typed source into an empty typed target', () {
      _expectTwins(() => mergeIf(ScaleOptionsScope(), _source()));
    });

    test('mergeIf into a target that owns some keys', () {
      _expectTwins(() => mergeIf(_target(), _source()));
    });

    test('merge (the default merger) into a target that owns some keys', () {
      _expectTwins(() => merge(_target(), _source()));
    });

    test('a list of sources: a Map, typed scopes and values', () {
      _expectTwins(
        () => mergeIf(_target(), [
          <String, Object?>{'axis': const XAxis(), 'display': 'auto'},
          _source(),
          null,
          5.0,
          ScaleOptionsScope()
            ..jsWrite('offset', true)
            ..jsWrite('ticks', TickOptionsScope()..jsWrite('z', 1.0)),
        ]),
      );
    });

    test('a Map source into a typed target', () {
      _expectTwins(
        () => mergeIf(_target(), <String, Object?>{
          'ticks': <String, Object?>{'font': const ChartTextStyle(fontSize: 3)},
          'title': MajorTickOptionsScope()..jsWrite('enabled', true),
        }),
      );
    });

    test('a source with routes: the reads of jsRead', () {
      _expectTwins(
        () => mergeIf(
          ScaleOptionsScope(),
          ScaleOptionsScope()..jsWrite('ticks', _routedTicks()),
        ),
      );
      _expectTwins(
        () => mergeIf(
          TickOptionsScope()..jsWrite('color', 'own'),
          _routedTicks(),
        ),
      );
      _expectTwins(() => merge(TickOptionsScope(), _routedTicks()));
    });

    test('a target with routes is merged by name', () {
      _expectTwins(() => mergeIf(_routedTicks(), _source().jsRead('ticks')));
      _expectTwins(() => merge(_routedTicks(), _source().jsRead('ticks')));
    });

    test('array-index extras keep the Object.keys order', () {
      ScaleOptionsScope indexed() => ScaleOptionsScope()
        ..jsWrite('b', 1.0)
        ..jsWrite('10', 'ten')
        ..jsWrite('2', 'two')
        ..jsWrite('a', 2.0);
      _expectTwins(() => mergeIf(ScaleOptionsScope(), indexed()));
      _expectTwins(
        () => mergeIf(
          ScaleOptionsScope(),
          ScaleOptionsScope()..jsWrite(
            'ticks',
            TickOptionsScope()
              ..jsWrite('9', 1.0)
              ..jsWrite('color', 'c')
              ..jsWrite('1', 2.0),
          ),
        ),
      );
    });

    test('scopes of other kinds', () {
      PointOptionsScope point() => PointOptionsScope()
        ..radius = 3.0
        ..jsWrite('borderWidth', 2)
        ..jsWrite('pointStyle', const CirclePointStyle())
        ..jsWrite('tension', 'loose');
      final split = FillTarget.toOrigin.split();
      LineOptionsScope line() => LineOptionsScope()
        ..jsWrite('tension', 0.4)
        ..jsWrite('fill', split)
        ..jsWrite('radius', 'wide')
        ..jsWrite('segment', <String, Object?>{'borderColor': _fn});
      _expectTwins(() => mergeIf(LineOptionsScope(), point()));
      _expectTwins(() => mergeIf(PointOptionsScope(), line()));
      _expectTwins(() => merge(point(), line()));
      _expectTwins(
        () => mergeIf(
          ChartOptionsScope(),
          ChartOptionsScope()
            ..jsWrite(
              'elements',
              ElementOptionsByTypeScope()
                ..jsWrite('point', point())
                ..jsWrite('custom', line()),
            )
            ..jsWrite(
              'scales',
              ScaleOptionsByIdScope()..jsWrite('x', _source()),
            ),
        ),
      );
    });

    test('a frozen target throws at the same write', () {
      _expectTwins(() {
        final target = _target()..freeze();
        try {
          mergeIf(target, _source());
          // A JavaScript TypeError of a write into a frozen object.
          // ignore: avoid_catching_errors
        } on TypeError {
          return <Object?>['threw', target];
        }
        return <Object?>['no throw', target];
      });
      _expectTwins(() {
        final ticks = TickOptionsScope()..jsWrite('color', 'green');
        final target = ScaleOptionsScope()
          ..jsWrite('display', false)
          ..jsWrite('ticks', ticks);
        ticks.freeze();
        try {
          merge(target, _source());
          // A JavaScript TypeError of a write into a frozen object.
          // ignore: avoid_catching_errors
        } on TypeError {
          return <Object?>['threw', target];
        }
        return <Object?>['no throw', target];
      });
    });

    test('a scope of a subclass is merged by name', () {
      _expectTwins(
        () => mergeIf(_SubScale()..jsWrite('display', false), _source()),
      );
      _expectTwins(
        () => mergeIf(_target(), _SubScale()..jsWrite('ticks', _source())),
      );
    });

    test('a scope merged into itself', () {
      _expectTwins(() {
        final scope = _source();
        mergeIf(scope, scope);
        return scope;
      });
      _expectTwins(() {
        final scope = _source();
        merge(scope, scope);
        return scope;
      });
    });

    test('the result shares no scope, Map or List with the source', () {
      final source = _source();
      final target = mergeIf(ScaleOptionsScope(), source)! as OptionScope;
      final ticks = target.jsRead('ticks')! as TickOptionsScope;
      expect(ticks, isNot(same(source.jsRead('ticks'))));
      // A font is an immutable TextStyle (Chart.js ADR 0116): a leaf.
      expect(ticks.jsRead('font'), same(jsGet(source['ticks'], 'font')));
      expect(ticks.jsRead('major'), isA<MajorTickOptionsScope>());
      expect(target.jsRead('grid'), isA<GridLineOptionsScope>());
      expect(target.jsRead('labels'), isNot(same(source.jsRead('labels'))));
      expect(
        (target.jsRead('labels')! as List<Object?>)[1],
        isNot(same((source.jsRead('labels')! as List<Object?>)[1])),
      );
      expect(target.jsRead('extraScope'), isA<MajorTickOptionsScope>());
      expect(
        target.jsRead('extraScope'),
        isNot(same(source.jsRead('extraScope'))),
      );
      expect(target.jsRead('beforeFit'), same(_fn));
      expect(target.jsRead('instance'), same(const _Instance()));
      expect(target.jsKeys(), isNot(contains('__proto__')));
      expect(target.jsKeys(), isNot(contains('constructor')));
      expect(target.jsKeys(), isNot(contains('prototype')));
    });

    test('a clone of a typed scope', () {
      _expectTwins(() => clone(_source()));
    });

    test('the scale configs of a chart, also with a theme', () {
      // One compiled theme for both runs: its values print their identity.
      final light = compileLightTheme();
      Map<String, Object?> config({bool theme = false}) => {
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1.0, 2.0],
              'yAxisID': 'y2',
            },
            <String, Object?>{
              'type': 'bar',
              'data': <Object?>[3.0],
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'ticks': <String, Object?>{'color': 'red'},
            },
            'y2': <String, Object?>{
              'type': 'logarithmic',
              'position': ChartPosition.right,
              'grid': <String, Object?>{'display': false},
            },
            'r': <String, Object?>{'type': 'radialLinear'},
          },
        },
        if (theme) themeConfigKey: light,
      };
      _expectTwins(() => Config(config()).options);
      _expectTwins(() => Config(config(theme: true)).options);
      final scales =
          (Config(config()).options as Map<String, Object?>)['scales']!
              as JsObjectFace;
      expect(scales.jsKeys(), containsAll(<String>['x', 'y', 'y2', 'r']));
    });
  });
}
