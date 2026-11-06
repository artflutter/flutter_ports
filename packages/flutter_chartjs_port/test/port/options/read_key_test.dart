// Original code, not ported from Chart.js: tests of the read by key of a scope.

// Chart.js ADR 0096: `OptionScope.readKey` and the case of a typed scope in
// `readOption` are the read by name of the face, with no read of a name.

import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show readOption;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/foreign_audit.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:test/test.dart';

/// Expects each read of each key of [scope] to give the read by name.
void _expectTwin(OptionScope scope) {
  for (final key in OptionKey.values) {
    final byName = scope.jsRead(key.jsName);
    expect(scope.readKey(key), same(byName), reason: key.jsName);
    expect(readOption(scope, key), same(byName), reason: key.jsName);
    expect(jsGet(scope, key.jsName), same(byName), reason: key.jsName);
  }
}

void main() {
  test('each key has one name', () {
    for (final key in OptionKey.values) {
      expect(optionKeyOf(key.jsName), key);
    }
  });

  test('an empty scope of each kind gives undefined', () {
    for (final kind in ScopeKind.values) {
      final scope = kind.create();
      _expectTwin(scope);
      expect(scope.readKey(OptionKey.datasets), same(undefined));
    }
  });

  test('the three states of a declared key', () {
    final list = <Object?>[];
    final scope = ChartDataScope();
    expect(readOption(scope, OptionKey.datasets), same(undefined));
    scope.jsWrite('datasets', list);
    expect(readOption(scope, OptionKey.datasets), same(list));
    scope.jsWrite('datasets', null);
    expect(readOption(scope, OptionKey.datasets), isNull);
    scope.jsWrite('datasets', undefined);
    expect(readOption(scope, OptionKey.datasets), same(undefined));
    expect(scope.owns(OptionKey.datasets), isTrue);
    _expectTwin(scope);
    scope.jsDelete('datasets');
    expect(readOption(scope, OptionKey.datasets), same(undefined));
    expect(scope.owns(OptionKey.datasets), isFalse);
    _expectTwin(scope);
  });

  test('a foreign value of a declared key', () {
    final saved = foreignAudit;
    foreignAudit = (owner, key, raw) => true;
    addTearDown(() => foreignAudit = saved);
    final scope = ChartDataScope()..jsWrite('datasets', 'text');
    expect(readOption(scope, OptionKey.datasets), 'text');
    _expectTwin(scope);
  });

  test('a key that the kind does not declare is an extra', () {
    final scope = ChartDataScope();
    expect(scope.hasField(OptionKey.parsing), isFalse);
    expect(readOption(scope, OptionKey.parsing), same(undefined));
    scope.jsWrite('parsing', 5.0);
    expect(readOption(scope, OptionKey.parsing), 5.0);
    scope.jsWrite('parsing', null);
    expect(readOption(scope, OptionKey.parsing), isNull);
    _expectTwin(scope);
  });

  test('a routed key reads its route', () {
    final other = <Object?>['other'];
    final routed = <Object?>['routed'];
    final scope = ChartDataScope()..jsWrite('labels', <Object?>['own']);
    var reads = 0;
    scope.addRoute(
      'labels',
      ScopeRoute(
        (local) {
          reads++;
          return routed;
        },
        targetScope: scope,
        targetName: 'labels',
      ),
    );
    expect(readOption(scope, OptionKey.labels), same(routed));
    expect(reads, 1);
    expect(scope.jsRead('labels'), same(routed));
    // The other keys of the scope stay without a route.
    scope.jsWrite('datasets', other);
    expect(readOption(scope, OptionKey.datasets), same(other));
    // A route of an extra name.
    scope.addRoute(
      'parsing',
      ScopeRoute(
        (local) => 'routed extra',
        targetScope: scope,
        targetName: 'parsing',
      ),
    );
    expect(readOption(scope, OptionKey.parsing), 'routed extra');
  });

  test('a frozen scope reads as before', () {
    final labels = <Object?>['x'];
    final scope = ChartDataScope()
      ..jsWrite('labels', labels)
      ..freeze();
    expect(readOption(scope, OptionKey.labels), same(labels));
    expect(readOption(scope, OptionKey.datasets), same(undefined));
  });

  test('a Map and the other values keep the read by name', () {
    final map = <String, Object?>{'data': 1.0, 'datasets': null};
    expect(readOption(map, OptionKey.data), 1.0);
    expect(readOption(map, OptionKey.datasets), isNull);
    expect(readOption(map, OptionKey.labels), same(undefined));
    expect(readOption(4.0, OptionKey.data), same(undefined));
    expect(readOption(<Object?>[], OptionKey.data), same(undefined));
    expect(() => readOption(null, OptionKey.data), throwsA(isA<TypeError>()));
    expect(
      () => readOption(undefined, OptionKey.data),
      throwsA(isA<TypeError>()),
    );
  });
}
