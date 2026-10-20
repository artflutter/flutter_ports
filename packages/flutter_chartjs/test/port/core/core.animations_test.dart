// Original code, not ported from Chart.js: core.animations cases with no spec.
@TestOn('vm')
library;

import 'package:flutter_chartjs/src/core/core.animation.dart';
import 'package:flutter_chartjs/src/core/core.animations.dart';
import 'package:flutter_chartjs/src/core/core.animator.dart';
import 'package:flutter_chartjs/src/core/core.config.dart';
import 'package:flutter_chartjs/src/elements/element.point.dart';
import 'package:flutter_chartjs/src/elements/element_options.dart';
import 'package:flutter_chartjs/src/helpers/helpers.easing.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import 'animation_reference.dart';

// Behavior of Chart.js ADR 0019 that test/specs/core.animations.tests.js
// does not check (AGENTS.md rule 3):
// - the 400 ms hover transition at the level of Animations, with the
//   animation options that the phase 5 Config and resolver give for
//   `transitions.active`, as `_resolveAnimations` resolves them
//   (core.datasetController.js:843-860);
// - an Animations with the duration 0, as the 'themeFrame' transition of a
//   theme gives (Chart.js ADR 0019, section 10);
// - the typed copy of `_resolveTargetOptions` (the row
//   adapt-typed-element-options).
// The expected colors come from src/core/core.animation.js at v4.5.1 in
// Node.js v24.12.0 on x64 (animation_reference.dart). The frames are pumps
// of 16 ms: the fake clock of jsDateNow moves by 16 ms in each one.

/// A chart for the animator: it counts its draws. Its other members throw.
final class _Chart implements types.Chart {
  int draws = 0;

  @override
  final Map<String, Object?> options = {};

  @override
  void draw() {
    draws++;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The animations of the transition [mode] of a line dataset: the
/// `animations` of the resolver of `_resolveAnimations`
/// (core.datasetController.js:851-856).
Animations _resolveAnimations(types.Chart chart, String mode) {
  final config = Config(<String, Object?>{'type': 'line'});
  final scopeKeys = config.datasetAnimationScopeKeys('line', mode);
  final scopes = config.getOptionScopes(<String, Object?>{}, scopeKeys);
  final options = config.createResolver(scopes, <String, Object?>{
    'active': mode == 'active',
    'mode': mode,
  });
  return Animations(chart, options['animations']);
}

/// The shared options of a point: `$shared` and the background color and
/// radius of [backgroundColor] and [radius], frozen as the cache of
/// `_resolveElementOptions` freezes them (core.datasetController.js:831).
PointOptions _shared(String backgroundColor, double radius) => PointOptions()
  ..[r'$shared'] = true
  ..['backgroundColor'] = backgroundColor
  ..['radius'] = radius
  ..freeze();

/// The radius at [elapsed] ms of the 400 ms transition from 3 to 4.
double _radius(double elapsed) =>
    3 + (4 - 3) * effects['easeOutQuart']!(elapsed / 400);

void main() {
  group('active transition', () {
    test('the resolver gives the options of transitions.active', () {
      final anims = _resolveAnimations(_Chart(), 'active');
      final colors = anims.properties['backgroundColor']!;
      final numbers = anims.properties['radius']!;
      expect(colors.durationValue, 400);
      expect(colors.easingValue, 'easeOutQuart');
      expect(colors.typeValue, 'color');
      expect(numbers.durationValue, 400);
      expect(numbers.typeValue, 'number');
      expect(anims.properties['x'], same(numbers));
      expect(anims.properties['borderColor'], same(colors));
    });

    testWidgets('a hover and an un-hover of a point in frames of 16 ms', (
      tester,
    ) async {
      final chart = _Chart();
      final shared = _shared(animationHoverFrom, 3);
      final hover = _shared(animationHoverTo, 4);
      final point = PointElement({'x': 10, 'y': 20, 'options': shared});
      final progress = <double?>[];
      final complete = <double?>[];
      animator
        ..listen(chart, 'progress', (e) => progress.add(e.currentStep))
        ..listen(chart, 'complete', (e) => complete.add(e.currentStep));

      // setHoverStyle: _setStyle(element, index, 'active', true).
      point.active = true;
      expect(
        _resolveAnimations(chart, 'active').update(point, {'options': hover}),
        isTrue,
      );
      // The animations change a copy of the shared options.
      final copy = point.options!;
      expect(copy, isA<PointOptions>());
      expect(copy, isNot(same(shared)));
      expect(copy[r'$shared'], isFalse);
      animator.start(chart);

      for (var k = 1; k <= 25; k++) {
        await tester.pump(const Duration(milliseconds: 16));
        final options = point.options!;
        if (k < 25) {
          expect(options, same(copy), reason: 'frame $k');
          expect(options['radius'], _radius(16.0 * k), reason: 'frame $k');
        } else {
          // Frame 25 (400 ms) ends both animations. The checkpoint of the
          // frame gives the point the hover options.
          expect(copy['radius'], 4);
          expect(options, same(hover), reason: 'frame $k');
        }
        expect(
          copy['backgroundColor'],
          animationHoverFrames[k - 1],
          reason: 'frame $k',
        );
      }
      expect(progress, hasLength(25));
      expect(chart.draws, 25);
      expect(complete, isEmpty);
      expect(animator.running(chart), isTrue);

      // Frame 26 removes the items and calls the complete listener.
      await tester.pump(const Duration(milliseconds: 16));
      expect(complete, [400]);
      expect(animator.running(chart), isFalse);
      expect(progress, hasLength(25));

      // removeHoverStyle: the shared options of the default mode.
      point.active = false;
      expect(
        _resolveAnimations(chart, 'active').update(point, {'options': shared}),
        isTrue,
      );
      final back = point.options!;
      expect(back, isNot(same(hover)));
      expect(back, isA<PointOptions>());
      animator.start(chart);
      for (var k = 1; k <= 26; k++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(back['backgroundColor'], animationHoverFrom);
      expect(back['radius'], 3);
      expect(point.options, same(shared));
      expect(animator.running(chart), isFalse);
      expect(complete, [400, 400]);
      animator.remove(chart);
    });

    testWidgets('the color at 200 ms is the mix at easeOutQuart(0.5)', (
      tester,
    ) async {
      final chart = _Chart();
      final point = PointElement({
        'options': _shared(animationHoverFrom, 3),
      });
      final hover = _shared(animationHoverTo, 4);
      _resolveAnimations(chart, 'active').update(point, {'options': hover});
      animator.start(chart);
      for (var k = 1; k <= 12; k++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump(const Duration(milliseconds: 8));
      final options = point.options!;
      expect(effects['easeOutQuart']!(0.5), 0.9375);
      expect(options['radius'], 3.9375);
      expect(options['backgroundColor'], animationHoverAt200);
      // Let the transition end. Then remove the chart.
      for (var k = 0; k < 14; k++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(point.options, same(hover));
      expect(animator.running(chart), isFalse);
      animator.remove(chart);
    });
  });

  group('themeFrame', () {
    test('the duration 0 writes the values at once and returns null', () {
      final anims = Animations(_Chart(), <String, Object?>{
        'numbers': <String, Object?>{
          'type': 'number',
          'properties': ['x', 'y'],
          'duration': 0,
        },
      });
      final target = <String, Object?>{'x': 0.0, 'y': 0.0};
      expect(anims.update(target, {'x': 10.0, 'y': 20.0}), isNull);
      expect(target['x'], 10.0);
      expect(target['y'], 20.0);
    });

    test('an active animation gets the new target and keeps its end', () {
      final chart = _Chart();
      final config = <String, Object?>{
        'numbers': <String, Object?>{
          'type': 'number',
          'properties': ['x'],
          'duration': 1000,
        },
      };
      final target = <String, Object?>{'x': 0.0};
      expect(Animations(chart, config).update(target, {'x': 10.0}), isTrue);
      final running = target[r'$animations']! as Map<String, Object?>;
      final animation = running['x']! as Animation;
      final end = animation.start + animation.duration;

      final themeFrame = Animations(chart, <String, Object?>{
        'numbers': <String, Object?>{
          'type': 'number',
          'properties': ['x'],
          'duration': 0,
        },
      });
      expect(themeFrame.update(target, {'x': 20.0}), isNull);
      expect(running['x'], same(animation));
      expect(animation.active(), isTrue);
      expect(animation.to, 20.0);
      // Math.max(remain, 0) keeps the end time (core.animation.js:59).
      expect(animation.start + animation.duration, end);
      animator.remove(chart);
    });
  });

  group('adapt-typed-element-options', () {
    test('the copy of shared options keeps their class', () {
      final anims = Animations(_Chart(), <String, Object?>{
        'radius': <String, Object?>{'duration': 400},
      });
      final shared = PointOptions()
        ..[r'$shared'] = true
        ..['radius'] = 3.0
        ..['extra'] = 'x'
        ..freeze();
      final point = PointElement({'options': shared});
      expect(
        anims.update(point, {
          'options': <String, Object?>{'radius': 4.0},
        }),
        isTrue,
      );
      final copy = point.options!;
      expect(copy, isA<PointOptions>());
      expect(copy, isNot(same(shared)));
      expect(jsObjectIsFrozen(copy), isFalse);
      expect(copy[r'$shared'], isFalse);
      expect(copy['extra'], 'x');
      expect(copy['radius'], 3.0);
      final animations = copy[r'$animations']! as Map<String, Object?>;
      expect(animations.keys, ['radius']);
      expect(animations['radius'], isA<Animation>());
      // The source does not change.
      expect(shared[r'$shared'], isTrue);
      expect(shared.containsKey(r'$animations'), isFalse);
    });

    test('the copy of plain shared options is a plain Map', () {
      final anims = Animations(_Chart(), <String, Object?>{
        'radius': <String, Object?>{'duration': 400},
      });
      final shared = <String, Object?>{
        'b': 1,
        '10': 2,
        r'$shared': true,
        'radius': 3.0,
      };
      final target = <String, Object?>{'options': shared};
      anims.update(target, {
        'options': <String, Object?>{'radius': 4.0},
      });
      final copy = target['options']! as AnyObject;
      expect(copy, isNot(isA<ElementOptions>()));
      expect(copy.keys, ['10', 'b', r'$shared', 'radius', r'$animations']);
      expect(copy[r'$shared'], isFalse);
    });

    test('options that are not shared get no copy', () {
      final anims = Animations(_Chart(), <String, Object?>{
        'radius': <String, Object?>{'duration': 400},
      });
      final options = PointOptions()..['radius'] = 3.0;
      final point = PointElement({'options': options});
      anims.update(point, {
        'options': <String, Object?>{'radius': 4.0},
      });
      expect(point.options, same(options));
      expect(options[r'$animations'], isA<Map<String, Animation>>());
    });
  });
}
