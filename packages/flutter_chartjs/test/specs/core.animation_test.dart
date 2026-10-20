// Ported from Chart.js v4.5.1 test/specs/core.animation.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/core/core.animation.dart';
import 'package:flutter_chartjs/src/js/js_date.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:test/test.dart';

// `Chart.Animation` is the class Animation of core.animation.dart. The spec
// reads and writes `_start`, `_from`, `_to` and `_duration`: the members
// `start`, `from`, `to` and `duration` (Chart.js ADR 0019, section 1). The
// cases read the real clock. Each date is relative to `anim.start`. Thus the
// results do not depend on the clock. `Date.now()` is `jsDateNow()`.

void main() {
  setUpSpecs();

  group('Chart.Animation', () {
    test('should animate boolean', () {
      final target = <String, Object?>{'prop': false};
      final anim = Animation({'duration': 1000}, target, 'prop', true);
      expect(anim.active(), isTrue);

      anim.tick(anim.start + 500);
      expect(anim.active(), isTrue);
      expect(target['prop'], isFalse);

      anim.tick(anim.start + 501);
      expect(anim.active(), isTrue);
      expect(target['prop'], isTrue);

      anim.tick(anim.start - 100);
      expect(anim.active(), isTrue);
      expect(target['prop'], isFalse);

      anim.tick(anim.start + 1000);
      expect(anim.active(), isFalse);
      expect(target['prop'], isTrue);
    });

    group('color', () {
      test('should fall back to transparent', () {
        final target = <String, Object?>{};
        final anim = Animation(
          {'duration': 1000, 'type': 'color'},
          target,
          'color',
          'red',
        )..from = undefined;
        anim.tick(anim.start + 500);
        expect(target['color'], '#FF000080');

        anim
          ..from = 'blue'
          ..to = undefined
          ..tick(anim.start + 500);
        expect(target['color'], '#0000FF80');
      });

      test('should not try to mix invalid color', () {
        final target = <String, Object?>{'color': 'blue'};
        final anim = Animation(
          {'duration': 1000, 'type': 'color'},
          target,
          'color',
          'invalid',
        );
        anim.tick(anim.start + 500);
        expect(target['color'], 'invalid');
      });
    });

    test('should loop', () {
      final target = <String, Object?>{'value': 0};
      final anim = Animation(
        {'duration': 100, 'loop': true},
        target,
        'value',
        10,
      );
      anim.tick(anim.start + 50);
      expect(target['value'], 5);
      anim.tick(anim.start + 100);
      expect(target['value'], 10);
      anim.tick(anim.start + 150);
      expect(target['value'], 5);
      anim.tick(anim.start + 400);
      expect(target['value'], 0);
    });

    test('should update', () {
      final target = <String, Object?>{'testColor': 'transparent'};
      final anim = Animation(
        {'duration': 100, 'type': 'color'},
        target,
        'testColor',
        'red',
      );

      anim.tick(anim.start + 50);
      expect(target['testColor'], '#FF000080');

      anim
        ..update({'duration': 500}, 'blue', jsDateNow())
        ..tick(anim.start + 250);
      expect(target['testColor'], '#4000BFBF');

      anim.tick(anim.start + 500);
      expect(target['testColor'], 'blue');
    });

    test('should not update when finished', () {
      final target = <String, Object?>{'testColor': 'transparent'};
      final anim = Animation(
        {'duration': 100, 'type': 'color'},
        target,
        'testColor',
        'red',
      );

      anim.tick(anim.start + 100);
      expect(target['testColor'], 'red');
      expect(anim.active(), isFalse);

      anim.update({'duration': 500}, 'blue', jsDateNow());
      expect(anim.duration, 100);
      expect(anim.to, 'red');
    });
  });
}
