// Ported from Chart.js v4.6.1 test/specs/core.animations.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart' show setTimeout, waitForDone;
import 'package:flutter_chartjs_port/src/core/core.animations.dart';
import 'package:flutter_chartjs_port/src/core/core.animator.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

// `Chart.Animations` is the class Animations of core.animations.dart, and
// `Chart.animator` is `animator` of core.animator.dart. The spec reads
// `_properties`: the member `properties` (Chart.js ADR 0019, section 1).
// `jasmine.objectContaining({duration: 1000})` is `containsPair`.
//
// The cases with `done` wait with `setTimeout` and `waitForDone` of the
// harness (Chart.js ADR 0022, section 7, Chart.js ADR 0019, section 12).
// They are `testWidgets` cases: the pumps of `waitForDone` move the fake
// clock of `jsDateNow` in frames of 16 ms, and run the frame callbacks of
// the animator. A task of `setTimeout` runs at the first pump boundary at or
// after its delay. The other cases never start the animator.

/// The chart objects of the spec: `{}` and `{draw: function() {}, options:
/// {}}`. `draw()` does nothing. The other members of `types.Chart` throw.
final class _Chart implements types.Chart {
  @override
  final Map<String, Object?> options = {};

  @override
  void draw() {}

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Chart.animations', () {
    test('should override property collection with property', () {
      final chart = _Chart();
      final anims = Animations(chart, <String, Object?>{
        'collection1': <String, Object?>{
          'properties': ['property1', 'property2'],
          'duration': 1000,
        },
        'property2': <String, Object?>{'duration': 2000},
      });
      expect(
        anims.properties['property1'],
        containsPair('duration', 1000),
      );
      expect(
        anims.properties['property2'],
        containsPair('duration', 2000),
      );
    });

    test('should ignore duplicate definitions from collections', () {
      final chart = _Chart();
      final anims = Animations(chart, <String, Object?>{
        'collection1': <String, Object?>{
          'properties': ['property1'],
          'duration': 1000,
        },
        'collection2': <String, Object?>{
          'properties': ['property1', 'property2'],
          'duration': 2000,
        },
      });
      expect(
        anims.properties['property1'],
        containsPair('duration', 1000),
      );
      expect(
        anims.properties['property2'],
        containsPair('duration', 2000),
      );
    });

    test('should not animate undefined options key', () {
      final chart = _Chart();
      final anims = Animations(chart, <String, Object?>{
        'value': <String, Object?>{'duration': 100},
        'option': <String, Object?>{'duration': 200},
      });
      final target = <String, Object?>{
        'value': 1,
        'options': <String, Object?>{'option': 2},
      };
      expect(
        anims.update(target, <String, Object?>{'options': undefined}),
        isNull,
      );
    });

    test(
      'should assign options directly, if target does not have previous '
      'options',
      () {
        final chart = _Chart();
        final anims = Animations(chart, <String, Object?>{
          'option': <String, Object?>{'duration': 200},
        });
        final target = <String, Object?>{};
        expect(
          anims.update(target, <String, Object?>{
            'options': <String, Object?>{'option': 1},
          }),
          isNull,
        );
      },
    );

    test(
      'should clone the target options, if those are shared and new options '
      'are not',
      () {
        final chart = _Chart();
        final anims = Animations(chart, <String, Object?>{
          'option': <String, Object?>{'duration': 200},
        });
        final options = <String, Object?>{'option': 0, r'$shared': true};
        final target = <String, Object?>{'options': options};
        expect(
          anims.update(target, <String, Object?>{
            'options': <String, Object?>{'option': 1},
          }),
          isTrue,
        );
        expect(
          (target['options']! as Map<String, Object?>)[r'$shared'],
          isNot(isTrue),
        );
        expect(!identical(target['options'], options), isTrue);
      },
    );

    testWidgets(
      'should assign shared options to target after animations complete',
      (tester) async {
        await waitForDone((done) {
          final chart = _Chart();
          final anims = Animations(chart, <String, Object?>{
            'value': <String, Object?>{'duration': 100},
            'option': <String, Object?>{'duration': 200},
          });

          final target = <String, Object?>{
            'value': 1,
            'options': <String, Object?>{'option': 2},
          };
          final sharedOpts = <String, Object?>{'option': 10, r'$shared': true};

          expect(
            anims.update(target, <String, Object?>{'options': sharedOpts}),
            isTrue,
          );

          expect(!identical(target['options'], sharedOpts), isTrue);

          animator.start(chart);

          setTimeout(() {
            expect(animator.running(chart), isFalse);
            expect(identical(target['options'], sharedOpts), isTrue);

            animator.remove(chart);
            done();
          }, 300);
        });
      },
    );

    testWidgets(
      'should not assign shared options to target when animations are '
      'cancelled',
      (tester) async {
        await waitForDone((done) {
          final chart = _Chart();
          final anims = Animations(chart, <String, Object?>{
            'value': <String, Object?>{'duration': 100},
            'option': <String, Object?>{'duration': 200},
          });

          final target = <String, Object?>{
            'value': 1,
            'options': <String, Object?>{'option': 2},
          };
          final sharedOpts = <String, Object?>{'option': 10, r'$shared': true};

          expect(
            anims.update(target, <String, Object?>{'options': sharedOpts}),
            isTrue,
          );

          expect(!identical(target['options'], sharedOpts), isTrue);

          animator.start(chart);

          setTimeout(() {
            expect(animator.running(chart), isTrue);
            animator.stop(chart);
            expect(animator.running(chart), isFalse);

            setTimeout(() {
              expect(identical(target['options'], sharedOpts), isFalse);

              animator.remove(chart);
              done();
            }, 250);
          }, 50);
        });
      },
    );

    testWidgets(
      'should assign final shared options to target after animations '
      'complete',
      (tester) async {
        await waitForDone((done) {
          final chart = _Chart();
          final anims = Animations(chart, <String, Object?>{
            'value': <String, Object?>{'duration': 100},
            'option': <String, Object?>{'duration': 200},
          });

          final origOpts = <String, Object?>{'option': 2};
          final target = <String, Object?>{'value': 1, 'options': origOpts};
          final sharedOpts = <String, Object?>{'option': 10, r'$shared': true};
          final sharedOpts2 = <String, Object?>{
            'option': 20,
            r'$shared': true,
          };

          expect(
            anims.update(target, <String, Object?>{'options': sharedOpts}),
            isTrue,
          );

          expect(!identical(target['options'], sharedOpts), isTrue);

          animator.start(chart);

          setTimeout(() {
            expect(animator.running(chart), isTrue);

            expect(identical(target['options'], origOpts), isTrue);

            expect(
              anims.update(target, <String, Object?>{'options': sharedOpts2}),
              isNull,
            );

            expect(identical(target['options'], origOpts), isTrue);

            setTimeout(() {
              expect(identical(target['options'], sharedOpts2), isTrue);

              animator.remove(chart);
              done();
            }, 250);
          }, 50);
        });
      },
    );
  });
}
