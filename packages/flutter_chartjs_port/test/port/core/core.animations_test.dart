// Original code, not ported from Chart.js: core.animations cases with no spec.
@TestOn('vm')
library;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart'
    show HTMLCanvasElement;
import 'package:flutter_chartjs_port/src/core/core.animation.dart';
import 'package:flutter_chartjs_port/src/core/core.animations.dart';
import 'package:flutter_chartjs_port/src/core/core.animator.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/reduced_motion.dart';
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.easing.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/animated_prop.dart';
import 'package:flutter_chartjs_port/src/options/props.dart';
import 'package:flutter_chartjs_port/src/options/typed_record.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
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
//   adapt-typed-element-options);
// - the reduced-motion flag of a canvas (the row platform-reduced-motion,
//   Chart.js ADR 0049, section 7).
// The expected colors come from src/core/core.animation.js at v4.5.1 in
// Node.js v24.22.1 on arm64 (animation_reference.dart). The frames are pumps
// of 16 ms: the fake clock of jsDateNow moves by 16 ms in each one.

/// A chart for the animator: it counts its draws. Its other members throw.
final class _Chart implements types.Chart {
  int draws = 0;

  // The chart object of the test has no canvas: JS `undefined`. The
  // reduced-motion read of `_createAnimations` reads it (Chart.js ADR 0049,
  // section 7).
  @override
  HTMLCanvasElement? get canvas => null;

  @override
  final Map<String, Object?> options = {};

  @override
  void draw() {
    draws++;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A canvas for the reduced-motion flag. Its members throw.
final class _Canvas implements HTMLCanvasElement {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A chart for the animator on the canvas [canvas].
final class _CanvasChart extends _Chart {
  _CanvasChart(this.canvas);

  @override
  final HTMLCanvasElement canvas;
}

/// The animation options of the properties `x` and `y`: 1000 ms, numbers.
Map<String, Object?> _xConfig() => <String, Object?>{
  'numbers': <String, Object?>{
    'type': 'number',
    'properties': ['x', 'y'],
    'duration': 1000,
  },
};

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
      final copy = point.options! as JsObjectFace;
      expect(copy, isA<PointOptions>());
      expect(copy, isNot(same(shared)));
      expect(copy[r'$shared'], isFalse);
      animator.start(chart);

      for (var k = 1; k <= 25; k++) {
        await tester.pump(const Duration(milliseconds: 16));
        final options = point.options! as JsObjectFace;
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
      final back = point.options! as JsObjectFace;
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
      final options = point.options! as JsObjectFace;
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
      final copy = point.options! as JsObjectFace;
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
      expect(shared.jsHas(r'$animations'), isFalse);
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

  group('platform-reduced-motion', () {
    test('with the flag, update writes the values and starts no animation', () {
      final canvas = _Canvas();
      setReducedMotion(canvas, enabled: true);
      final chart = _CanvasChart(canvas);
      final target = <String, Object?>{'x': 0.0, 'y': 0.0};
      expect(
        Animations(chart, _xConfig()).update(target, {'x': 10.0, 'y': 20.0}),
        isNull,
      );
      expect(target['x'], 10.0);
      expect(target['y'], 20.0);
      // `_createAnimations` still makes the running Map (:71).
      expect(target[r'$animations'], isEmpty);
      expect(animator.has(chart), isFalse);
    });

    test('with the flag, an options update writes the options at once', () {
      final canvas = _Canvas();
      setReducedMotion(canvas, enabled: true);
      final anims = Animations(_CanvasChart(canvas), <String, Object?>{
        'radius': <String, Object?>{'duration': 400},
      });
      final options = PointOptions()..['radius'] = 3.0;
      final point = PointElement({'options': options});
      expect(
        anims.update(point, {
          'options': <String, Object?>{'radius': 4.0},
        }),
        isNull,
      );
      expect(point.options, same(options));
      expect(options['radius'], 4.0);
      expect(options[r'$animations'], isEmpty);
    });

    test('a running animation ends at its target', () {
      final canvas = _Canvas();
      final chart = _CanvasChart(canvas);
      final target = <String, Object?>{'x': 0.0};
      expect(Animations(chart, _xConfig()).update(target, {'x': 10.0}), isTrue);
      final running = target[r'$animations']! as Map<String, Object?>;
      final animation = running['x']! as Animation;
      expect(animation.active(), isTrue);

      setReducedMotion(canvas, enabled: true);
      expect(Animations(chart, _xConfig()).update(target, {'x': 20.0}), isNull);
      // :94-97 cancel the animation, and :99-103 write the new value.
      expect(animation.active(), isFalse);
      expect(running['x'], same(animation));
      expect(target['x'], 20.0);
      animator.remove(chart);
    });

    test('without the flag, the upstream path', () {
      final canvas = _Canvas();
      setReducedMotion(canvas, enabled: true);
      setReducedMotion(canvas, enabled: false);
      for (final chart in [_CanvasChart(canvas), _Chart()]) {
        final target = <String, Object?>{'x': 0.0};
        expect(
          Animations(chart, _xConfig()).update(target, {'x': 10.0}),
          isTrue,
        );
        final running = target[r'$animations']! as Map<String, Object?>;
        expect((running['x']! as Animation).active(), isTrue);
        expect(target['x'], 0.0);
        expect(animator.has(chart), isTrue);
        animator.remove(chart);
      }
    });
  });

  // Chart.js ADR 0054 §10: the typed keys of a property object of a
  // controller, and the same results as the object by name.
  group('typed keys', () {
    test('animatedPropOf names the key of each field', () {
      final classes = <(TypedRecord Function(), List<String>)>[
        (
          PointProperties.new,
          ['x', 'y', 'skip', 'stop', 'parsed', 'raw', 'options', 'angle'],
        ),
        (
          BarProperties.new,
          [
            'horizontal',
            'base',
            'enableBorderRadius',
            'x',
            'y',
            'height',
            'width',
            'options',
            'borderSkipped',
            'inflateAmount',
          ],
        ),
        (
          ArcProperties.new,
          [
            'x',
            'y',
            'startAngle',
            'endAngle',
            'circumference',
            'outerRadius',
            'innerRadius',
            'options',
          ],
        ),
        (LineProperties.new, ['animated', 'options', '_loop', '_fullLoop']),
      ];
      for (final (make, names) in classes) {
        for (final name in names) {
          final record = make()..[name] = 1;
          expect(record.slotAt(0), greaterThanOrEqualTo(0), reason: name);
          expect(record.keyAt(0), name);
          expect(animatedPropOf(record, 0).name, name);
          // A built-in name gives its constant, as AnimatedProp.of does.
          final builtIn = AnimatedProp.of(name);
          if (!builtIn.isCustom) {
            expect(animatedPropOf(record, 0), same(builtIn), reason: name);
          }
        }
      }
      final extra = PointProperties()..['other'] = 1;
      expect(animatedPropOf(extra, 0).name, 'other');
      expect(animatedPropOf(extra, 0).isCustom, isTrue);
    });

    test('a property object animates as the same object by name', () {
      final chart = _Chart();
      final typedPoint = PointElement()
        ..x = 0
        ..y = 0;
      final plainPoint = PointElement()
        ..x = 0
        ..y = 0;
      final options = PointOptions()..['radius'] = 3;
      final typed = PointProperties()
        ..y = 20
        ..x = 10
        ..skip = false
        ..options = options;
      final plain = <String, Object?>{
        'y': 20.0,
        'x': 10.0,
        'skip': false,
        'options': options,
      };
      expect(Animations(chart, _xConfig()).update(typedPoint, typed), isTrue);
      expect(Animations(chart, _xConfig()).update(plainPoint, plain), isTrue);
      for (final point in [typedPoint, plainPoint]) {
        // The keys from the last: options, skip, x, y.
        expect(point.$animations!.keys, ['x', 'y']);
        expect(point.skip, isFalse);
        expect(point.options, same(options));
        expect(point.x, 0.0);
        expect(point.$animations!['x']!.to, 10.0);
        expect(point.$animations!['y']!.to, 20.0);
      }
      animator.remove(chart);
    });

    test('with no animated key, assign takes the typed setters', () {
      final chart = _Chart();
      final bar = BarElement();
      final typed = BarProperties()
        ..horizontal = false
        ..base = 100
        ..x = 5
        ..width = 2;
      expect(Animations(chart, <String, Object?>{}).update(bar, typed), isNull);
      expect(bar['horizontal'], isFalse);
      expect(bar['base'], 100.0);
      expect(bar['x'], 5.0);
      expect(bar['width'], 2.0);
      expect(bar['height'], same(undefined));
    });
  });
}
