// Original code, not ported from Chart.js: immutable native key snapshots.
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:test/test.dart';

void main() {
  test(
    'snapshots reuse identity for values and preserve previous key order',
    () {
      final scope = PointOptionsScope()
        ..radius = 3
        ..borderWidth = 1;
      final first = scope.nativeOwnKeySnapshot;
      expect(first, scope.jsOwnKeys());
      scope.radius = 8;
      expect(scope.nativeOwnKeySnapshot, same(first));
      expect(first.clear, throwsUnsupportedError);
      scope.backgroundColor = 'red';
      final next = scope.nativeOwnKeySnapshot;
      expect(next, isNot(same(first)));
      expect(first, [OptionKey.radius, OptionKey.borderWidth]);
      expect(next, scope.jsOwnKeys());
      scope
        ..jsDelete('radius')
        ..radius = 4;
      expect(scope.nativeOwnKeySnapshot, [
        OptionKey.borderWidth,
        OptionKey.backgroundColor,
        OptionKey.radius,
      ]);
    },
  );

  test('numeric extras follow JS ordering through insertion and deletion', () {
    final scope = PointOptionsScope()..radius = 3;
    final first = scope.nativeOwnKeySnapshot;
    scope
      ..jsWrite('12', 'a')
      ..jsWrite('2', 'b')
      ..jsWrite('extra', true);
    expect(scope.nativeOwnKeySnapshot, ['2', '12', OptionKey.radius, 'extra']);
    expect(first, [OptionKey.radius]);
    scope.jsDelete('2');
    expect(scope.nativeOwnKeySnapshot, ['12', OptionKey.radius, 'extra']);
    scope.jsWrite('2', false);
    expect(scope.nativeOwnKeySnapshot, scope.jsOwnKeys());
  });

  test(
    'route creation and state restore invalidate only structural snapshots',
    () {
      final scope = PointOptionsScope()..radius = 3;
      final saved = scope.saveState();
      final first = scope.nativeOwnKeySnapshot;
      scope.addRoute(
        'borderWidth',
        ScopeRoute((_) => 2, targetScope: scope, targetName: 'radius'),
      );
      expect(scope.nativeOwnKeySnapshot, [
        OptionKey.radius,
        OptionKey.borderWidth,
      ]);
      expect(first, [OptionKey.radius]);
      scope.restoreState(saved);
      expect(scope.nativeOwnKeySnapshot, [OptionKey.radius]);
      expect(scope.nativeOwnKeySnapshot, isNot(same(first)));
      final restored = scope.nativeOwnKeySnapshot;
      scope.freeze();
      expect(scope.nativeOwnKeySnapshot, same(restored));
      expect(() => scope.radius = 2, throwsA(isA<TypeError>()));
      expect(scope.nativeOwnKeySnapshot, same(restored));
    },
  );
}
