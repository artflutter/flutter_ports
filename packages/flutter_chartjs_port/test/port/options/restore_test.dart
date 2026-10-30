// Original code, not ported from Chart.js: the restore of the typed defaults.
@TestOn('vm')
library;

// The defaults restore of the harness (`setUpDefaultsRestore`, the row
// `harness-defaults-restore`) over the typed roots of Chart.js ADR 0054: the
// key order, the cells, the extras and the routes of each typed scope come
// back after each test. Each of the two tests first checks the state of the
// snapshot and then changes the typed scopes. In any test order and in any
// shard, the second test finds the state that the restore after the first
// test made.

import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:test/test.dart';

/// `defaults.elements.point`.
PointOptionsScope _point() =>
    jsGet(jsGet(defaults, 'elements'), 'point')! as PointOptionsScope;

void main() {
  late List<String> pointKeys;
  late Object? font;
  late Object? pointCell;
  late List<String> descriptorKeys;

  setUpAll(() {
    pointKeys = _point().jsKeys();
    font = defaults.fontCell!.raw;
    pointCell = _point().radiusCell;
    descriptorKeys = descriptors.jsKeys();
  });

  void checkSnapshot() {
    final point = _point();
    expect(point.jsKeys(), pointKeys);
    expect(point.jsRead('radius'), 3.0);
    expect(identical(point.radiusCell, pointCell), isTrue);
    expect(point.jsHas('extraKey'), isFalse);
    expect(identical(defaults.fontCell!.raw, font), isTrue);
    expect(descriptors.jsKeys(), descriptorKeys);
    // The route of `backgroundColor` reads the root.
    expect(point.jsRead('backgroundColor'), 'rgba(0,0,0,0.1)');
    expect(point.routeOf('backgroundColor'), isNotNull);
  }

  void changeScopes() {
    final point = _point()
      ..radius = 9.0
      ..jsDelete('rotation')
      ..jsWrite('extraKey', 5.0);
    expect(point.jsKeys().last, 'extraKey');
    defaults
      ..font = (FontSpecScope()..size = 30.0)
      ..backgroundColor = 'red';
    expect(point.jsRead('backgroundColor'), 'red');
    descriptors.jsWrite('leak', DescriptorsScope());
  }

  test('a typed write, a delete and an extra are restored (first)', () {
    checkSnapshot();
    changeScopes();
  });

  test('a typed write, a delete and an extra are restored (second)', () {
    checkSnapshot();
    changeScopes();
  });
}
