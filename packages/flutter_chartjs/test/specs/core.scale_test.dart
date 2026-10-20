// Ported from Chart.js v4.5.1 test/specs/core.scale.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
// The spec builds charts of flutter_chartjs, which does not export lib/src
// yet.
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.defaults.dart';
import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

// The spec reads Chart.defaults, which is `defaults` of core.defaults.dart.
// Its chart cases call `acquireChart`. Thus they are `testWidgets` cases, and
// the file runs on the VM (Chart.js ADR 0022, sections 1 and 2). A case that
// needs a module of a later phase skips with the missing module of the
// latest phase. The helper `getLabels(scale)` (core.scale.tests.js:1-3)
// comes with the bodies of the afterBuildTicks cases.
//
// A class `class X extends Chart.Scale` of the spec is a Dart subclass of
// Scale and a class value that constructs it: `JsClass('X', superclass:
// Scale.jsClass, construct: ...)`. The static properties that the spec writes
// after the class are writes with `operator []=` (Chart.js ADR 0020, section
// 8). Dart has no local classes, so the classes of the spec are private
// classes of this file. `chart.scales.x` is `chart.scales['x']!`, and
// `scale._layers()` is `scale.layers!()` (Chart.js ADR 0012, Underscore
// members). `new Error(m)` is a StateError with the message m.

/// The member read `object.key` of the option object [object].
Object? _member(Object? object, String key) =>
    (object! as Map<String, Object?>)[key];

/// core.scale.tests.js:514-519 `class CustomScale extends Chart.Scale`.
final class _CustomScale extends Scale {
  _CustomScale(super.cfg);

  @override
  void draw([types.ChartArea? chartArea]) {}

  /// core.scale.tests.js:516 `convertTicksToLabels()`. Scale of v4.5.1 has
  /// no member with this name, and nothing calls it.
  List<Object?> convertTicksToLabels() {
    return ['tick'];
  }
}

/// core.scale.tests.js:547-552 `class CustomScale1 extends Chart.Scale`.
final class _CustomScale1 extends Scale {
  _CustomScale1(super.cfg);

  @override
  void draw([types.ChartArea? chartArea]) {}

  /// core.scale.tests.js:549 `convertTicksToLabels()`. Scale of v4.5.1 has
  /// no member with this name, and nothing calls it.
  List<Object?> convertTicksToLabels() {
    return ['tick'];
  }
}

/// core.scale.tests.js:580-582 `class CustomScale2 extends Chart.Scale`.
final class _CustomScale2 extends Scale {
  _CustomScale2(super.cfg);

  @override
  void draw([types.ChartArea? chartArea]) {}
}

/// The eight items of `gridLineTests` (core.scale.tests.js:110-150). The
/// last four repeat the flags of the first four with one label. Their test
/// names get ` #2` (porting-flow.md section 1, step 5).
const List<({bool offsetGridLines, bool offset})> _gridLineTests = [
  (offsetGridLines: false, offset: false),
  (offsetGridLines: false, offset: true),
  (offsetGridLines: true, offset: false),
  (offsetGridLines: true, offset: true),
  (offsetGridLines: false, offset: false),
  (offsetGridLines: false, offset: true),
  (offsetGridLines: true, offset: false),
  (offsetGridLines: true, offset: true),
];

/// The names of the cases that `gridLineTests.forEach` makes from [prefix],
/// with ` #2` for a repeated name.
List<String> _gridLineNames(String prefix) {
  final names = <String>[];
  for (final test in _gridLineTests) {
    final name =
        '$prefix when offsetGridLines is ${test.offsetGridLines} and offset '
        'is ${test.offset}';
    names.add(names.contains(name) ? '$name #2' : name);
  }
  return names;
}

void main() {
  group('Core.scale', () {
    // describe('auto', jasmine.fixture.specs('core.scale')): a fixture group
    // of phase 7, not a case.

    test('should provide default scale label options', () {
      final scale = _member(defaults, 'scale');
      expect(
        _member(scale, 'title'),
        equals(<String, Object?>{
          'color': defaults['color'],
          'display': false,
          'text': '',
          'padding': <String, Object?>{'top': 4, 'bottom': 4},
        }),
      );
    });

    group('displaying xAxis ticks with autoSkip=true', () {
      test(
        'should use autoSkip amount of ticks when maxTicksLimit is set to a '
        'larger number as autoSkip calculation',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should use maxTicksLimit amount of ticks when maxTicksLimit is set '
        'to a smaller number as autoSkip calculation',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should display the last tick if it fits evenly with other ticks',
        () {},
        skip: 'blocked: controller.line',
      );

      test(
        'should not display the last tick if it does not fit evenly',
        () {},
        skip: 'blocked: controller.line',
      );
    });

    for (final name in _gridLineNames(
      'should get the correct pixels for gridLine(s) for the horizontal scale',
    )) {
      test(name, () {}, skip: 'blocked: controller.line');
    }

    for (final name in _gridLineNames(
      'should get the correct pixels for gridLine(s) for the vertical scale',
    )) {
      test(name, () {}, skip: 'blocked: controller.line');
    }

    test(
      'should add the correct padding for long tick labels',
      () {},
      skip: 'blocked: controller.line',
    );

    group('given the axes display option is set to auto', () {
      group('for the x axes', () {
        test(
          'should draw the axes if at least one associated dataset is '
          'visible',
          () {},
          skip: 'blocked: controller.line',
        );

        test(
          'should not draw the axes if no associated datasets are visible',
          () {},
          skip: 'blocked: controller.line',
        );
      });

      group('for the y axes', () {
        test(
          'should draw the axes if at least one associated dataset is '
          'visible',
          () {},
          skip: 'blocked: controller.line',
        );

        test(
          'should not draw the axes if no associated datasets are visible',
          () {},
          skip: 'blocked: controller.line',
        );
      });
    });

    group('afterBuildTicks', () {
      test(
        'should allow filtering of ticks',
        () {},
        skip: 'blocked: scale.category',
      );

      test(
        'should allow no return value from callback',
        () {},
        skip: 'blocked: scale.category',
      );

      test('should allow empty ticks', () {}, skip: 'blocked: scale.category');
    });

    group('_layers', () {
      test(
        'should default to three layers',
        () {},
        skip: 'blocked: scale.linear',
      );

      test(
        'should create the chart with custom scale ids without axis or '
        'position options',
        () {},
        skip: 'blocked: controller.scatter',
      );

      testWidgets('should default to one layer for custom scales', (
        tester,
      ) async {
        final customScale = JsClass(
          'CustomScale',
          superclass: Scale.jsClass,
          construct: (newTarget, args) => _CustomScale(scaleCfgArg(args)),
        );
        customScale['id'] = 'customScale';
        customScale['defaults'] = <String, Object?>{};
        Chart.register([customScale]);

        final chart = acquireChart({
          'type': 'line',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'type': 'customScale',
                'grid': <String, Object?>{'z': 10},
                'ticks': <String, Object?>{'z': 20},
              },
            },
          },
        });

        final scale = chart.scales['x']!;
        expect(scale.layers!().length, 1);
        expect(scale.layers!()[0].z, 20);
      });

      testWidgets('should default to one layer for custom scales for axis', (
        tester,
      ) async {
        final customScale1 = JsClass(
          'CustomScale1',
          superclass: Scale.jsClass,
          construct: (newTarget, args) => _CustomScale1(scaleCfgArg(args)),
        );
        customScale1['id'] = 'customScale1';
        customScale1['defaults'] = <String, Object?>{'axis': 'x'};
        Chart.register([customScale1]);

        final chart = acquireChart({
          'type': 'line',
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'my': <String, Object?>{
                'type': 'customScale1',
                'grid': <String, Object?>{'z': 10},
                'ticks': <String, Object?>{'z': 20},
              },
            },
          },
        });

        final scale = chart.scales['my']!;
        expect(scale.layers!().length, 1);
        expect(scale.layers!()[0].z, 20);
      });

      testWidgets(
        'should fail for custom scales without any axis or position',
        (tester) async {
          final customScale2 = JsClass(
            'CustomScale2',
            superclass: Scale.jsClass,
            construct: (newTarget, args) => _CustomScale2(scaleCfgArg(args)),
          );
          customScale2['id'] = 'customScale2';
          customScale2['defaults'] = <String, Object?>{};
          Chart.register([customScale2]);

          Chart createChart() {
            return acquireChart({
              'type': 'line',
              'options': <String, Object?>{
                'scales': <String, Object?>{
                  'my': <String, Object?>{'type': 'customScale2'},
                },
              },
            });
          }

          expect(
            createChart,
            throwsA(
              isA<StateError>().having(
                (error) => error.message,
                'message',
                "Cannot determine type of 'my' axis. Please provide 'axis' "
                    "or 'position' option.",
              ),
            ),
          );
        },
      );

      test(
        'should return 3 layers when z is not equal between ticks and grid',
        () {},
        skip: 'blocked: scale.linear',
      );
    });

    group('min and max', () {
      test(
        'should be limited to visible data',
        () {},
        skip: 'blocked: controller.scatter',
      );
    });

    group('overrides', () {
      test(
        'should create new scale',
        () {},
        skip: 'blocked: controller.scatter',
      );

      test(
        'should create new scale with custom name',
        () {},
        skip: 'blocked: controller.scatter',
      );

      // :743-763 expects the Error of determineAxis (core.config.js:52).
      // The upstream suite registers every built-in (src/index.umd.ts:28),
      // so `defaults.scales.linear` exists and determineAxis reaches its
      // throw. In phase 5 `defaults.scales.linear` is undefined, and
      // determineAxis throws a TypeError first. Thus the case needs
      // scale.linear. When phase 6 lifts the skip, the body is
      // `expect(() => acquireChart({type: 'scatter', ...}), throwsA(...))`
      // with the upstream config.
      test(
        'should throw error on scale with custom name without axis type',
        () {},
        skip: 'blocked: scale.linear',
      );

      test(
        'should read options first to determine axis',
        () {},
        skip: 'blocked: controller.scatter',
      );

      test(
        'should center labels when rotated in x axis',
        () {},
        skip: 'blocked: controller.line',
      );
    });
  });
}
