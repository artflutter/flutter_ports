// Original code, not ported from Chart.js: core.layouts cases with no spec.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/core/core.layouts.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_chartjs/src/types/layout.dart';
import 'package:test/test.dart';

import 'layouts_reference.dart';

// Upstream behavior that test/specs/core.layouts.tests.js checks only with
// charts (AGENTS.md rule 3): addBox, removeBox, configure and update with
// fake boxes.
//
// Each scene configures and adds fake boxes to a fake chart, as
// buildOrUpdateScales does (core.controller.js:377-378), and runs
// `layouts.update`. A scene with `reconfigure` configures the boxes again
// after addBox, as the legend and the title do (plugin.legend.js:617,
// plugin.title.js:141). The expected box calls, box sizes and positions, chart
// area and box order come from src/core/core.layouts.js at v4.5.1, run with
// type stripping in Node.js v24.12.0 on x64 over the same scenes.
// layouts_reference.dart has the data, which
// tool/reference/layouts_reference.mjs writes (Chart.js ADR 0032). The
// layout is IEEE arithmetic and `Math.max`. Thus the tests compare the
// numbers exactly.
//
// LayoutItem types `fullSize` as a bool (layout.dart): it keeps the
// truthiness of the option (the difference adapt-layout-configure-types).
// The tests compare it with the JavaScript value through this conversion.
// `weight` keeps the raw value, as upstream does.

/// A fake box of the reference. Its [update] records the call in [log] and
/// sets the size with the rule of the generator.
class _Box implements LayoutItem {
  _Box(this.spec, this.log)
    : options = spec.options == null ? null : {...spec.options!},
      axis = spec.axis;

  /// The box of the reference.
  final LayoutsReferenceBox spec;

  /// The calls of the scene.
  final List<(String, String, List<double>)> log;

  @override
  Object? position = undefined;

  @override
  Object? weight = undefined;

  @override
  bool fullSize = false;

  @override
  double width = double.nan;

  @override
  double height = double.nan;

  @override
  double left = double.nan;

  @override
  double top = double.nan;

  @override
  double right = double.nan;

  @override
  double bottom = double.nan;

  @override
  final Map<String, Object?>? options;

  @override
  final String? axis;

  @override
  List<LayoutLayer> Function()? layers;

  @override
  bool isHorizontal() => spec.horizontal;

  @override
  void update(double width, double height, [TRBL? margins]) {
    log.add((
      'update',
      spec.name,
      [
        width,
        height,
        margins!.left,
        margins.top,
        margins.right,
        margins.bottom,
      ],
    ));
    final (at, thick, thin) = spec.size;
    if (spec.horizontal) {
      this.width = width;
      this.height = width < at ? thick : thin;
    } else {
      this.height = height;
      this.width = height < at ? thick : thin;
    }
  }

  @override
  void draw(ChartArea chartArea) {
    log.add(('draw', spec.name, [chartArea.left, chartArea.top]));
  }
}

/// A fake box with `beforeLayout`.
class _BeforeLayoutBox extends _Box implements LayoutItemBeforeLayout {
  _BeforeLayoutBox(super.spec, super.log);

  @override
  void beforeLayout() {
    log.add(('beforeLayout', spec.name, const []));
  }
}

/// The padding `{left, top, right, bottom}` of `getPadding`.
final class _Padding implements TRBL {
  _Padding(this.left, this.top, this.right, this.bottom);

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;
}

/// A fake box with `getPadding`.
final class _PaddingBox extends _Box implements LayoutItemPadding {
  _PaddingBox(super.spec, super.log);

  @override
  TRBL getPadding() {
    final (left, top, right, bottom) = spec.padding!;
    return _Padding(left, top, right, bottom);
  }
}

/// A fake box with `beforeLayout` and `getPadding`, as a scale.
final class _ScaleBox extends _BeforeLayoutBox implements LayoutItemPadding {
  _ScaleBox(super.spec, super.log);

  @override
  TRBL getPadding() {
    final (left, top, right, bottom) = spec.padding!;
    return _Padding(left, top, right, bottom);
  }
}

/// The fake box of [spec].
_Box _box(LayoutsReferenceBox spec, List<(String, String, List<double>)> log) =>
    switch ((spec.beforeLayout, spec.padding != null)) {
      (true, true) => _ScaleBox(spec, log),
      (true, false) => _BeforeLayoutBox(spec, log),
      (false, true) => _PaddingBox(spec, log),
      (false, false) => _Box(spec, log),
    };

/// A chart with the members that core.layouts.js reads and writes.
final class _Chart implements types.Chart {
  _Chart(Object? padding)
    : options = {
        'layout': <String, Object?>{'padding': padding},
      };

  @override
  final Map<String, Object?> options;

  @override
  final List<LayoutItem> boxes = [];

  @override
  late ChartArea chartArea;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The configure options of [spec]: its present keys only.
Map<String, Object?> _configureOptions(LayoutsReferenceBox spec) => {
  if (!identical(spec.fullSize, undefined)) 'fullSize': spec.fullSize,
  if (!identical(spec.position, undefined)) 'position': spec.position,
  if (!identical(spec.weight, undefined)) 'weight': spec.weight,
};

/// The calls [log] as lists, which `equals` compares item by item. A
/// record compares a list by identity.
List<List<Object>> _flat(List<(String, String, List<double>)> log) => [
  for (final (call, name, args) in log) [call, name, ...args],
];

/// A matcher of the number [expected]: `isNaN` for NaN, else `equals`.
Matcher _number(double expected) => expected.isNaN ? isNaN : equals(expected);

/// A matcher of the JavaScript value [expected]: `isNaN` for NaN, `same`
/// for the [undefined] sentinel, else `equals`.
Matcher _value(Object? expected) => switch (expected) {
  final double d when d.isNaN => isNaN,
  Undefined() => same(undefined),
  _ => equals(expected),
};

void main() {
  setUpSpecs();

  group('reference', () {
    test('has the reference of Node.js v24.12.0 on x64', () {
      expect(layoutsReferenceNode, 'v24.12.0');
      expect(layoutsReferenceArch, 'x64');
      expect(layoutsReference, hasLength(23));
    });
  });

  group('update against upstream', () {
    for (final scene in layoutsReference) {
      test(scene.name, () {
        final log = <(String, String, List<double>)>[];
        final chart = _Chart(scene.padding);
        final boxes = <_Box>[];
        for (final spec in scene.boxes) {
          final box = _box(spec, log);
          layouts
            ..configure(chart, box, _configureOptions(spec))
            ..addBox(chart, box);
          boxes.add(box);
        }
        if (scene.reconfigure) {
          for (final box in boxes) {
            layouts.configure(chart, box, _configureOptions(box.spec));
          }
        }

        void update() => layouts.update(
          chart,
          scene.width,
          scene.height,
          scene.minPadding,
        );
        if (scene.error != null) {
          expect(scene.error, 'TypeError');
          expect(update, throwsA(isA<TypeError>()));
        } else {
          update();
          final (left, top, right, bottom, width, height) = scene.chartArea!;
          expect(chart.chartArea.left, left);
          expect(chart.chartArea.top, top);
          expect(chart.chartArea.right, right);
          expect(chart.chartArea.bottom, bottom);
          expect(chart.chartArea.width, width);
          expect(chart.chartArea.height, height);
        }

        expect(_flat(log), _flat(scene.log));
        for (final (i, r) in scene.results.indexed) {
          final box = boxes[i];
          expect(box.spec.name, r.name);
          expect(box.left, _number(r.left), reason: '${r.name} left');
          expect(box.top, _number(r.top), reason: '${r.name} top');
          expect(box.right, _number(r.right), reason: '${r.name} right');
          expect(box.bottom, _number(r.bottom), reason: '${r.name} bottom');
          expect(box.width, _number(r.width), reason: '${r.name} width');
          expect(box.height, _number(r.height), reason: '${r.name} height');
          expect(box.fullSize, jsTruthy(r.fullSize), reason: r.name);
          expect(box.position, r.position, reason: '${r.name} position');
          expect(box.weight, _value(r.weight), reason: '${r.name} weight');
        }
        expect(
          [for (final box in chart.boxes) (box as _Box).spec.name],
          [
            ...scene.order,
          ],
        );
      });
    }
  });

  group('addBox', () {
    final spec = layoutsReference.first.boxes.first;

    test('gives a box without layers one layer that draws the box', () {
      final log = <(String, String, List<double>)>[];
      final chart = _Chart(0);
      final box = _box(spec, log);
      layouts.addBox(chart, box);

      final layers = box.layers!();
      expect(layers, hasLength(1));
      expect(layers.single.z, 0);
      expect(layers.single.idx, isNaN);
      final area = _Padding(1, 2, 3, 4);
      layers.single.draw(_Area(area));
      expect(_flat(log), [
        ['draw', spec.name, 1.0, 2.0],
      ]);
    });

    test('keeps the layers of a box', () {
      final chart = _Chart(0);
      final box = _box(spec, []);
      List<LayoutLayer> own() => const [];
      box.layers = own;
      layouts.addBox(chart, box);

      expect(box.layers, same(own));
    });

    test('gives the start values of an unconfigured box', () {
      final chart = _Chart(0);
      final box = _box(spec, []);
      layouts.addBox(chart, box);

      // `fullSize || false`, `position || 'top'` and `weight || 0`
      // (core.layouts.js:297-299).
      expect(box.fullSize, isFalse);
      expect(box.position, 'top');
      expect(box.weight, 0);
      expect(chart.boxes, [box]);
    });
  });

  group('removeBox', () {
    final spec = layoutsReference.first.boxes.first;

    test('removes the box', () {
      final chart = _Chart(0);
      final a = _box(spec, []);
      final b = _box(spec, []);
      layouts
        ..addBox(chart, a)
        ..addBox(chart, b)
        ..removeBox(chart, a);

      expect(chart.boxes, [b]);
    });

    test('ignores a box that the chart does not have', () {
      final chart = _Chart(0);
      final a = _box(spec, []);
      layouts
        ..addBox(chart, a)
        ..removeBox(chart, _box(spec, []));

      expect(chart.boxes, [a]);
    });
  });

  group('configure', () {
    final spec = layoutsReference.first.boxes.first;

    test('writes the three options', () {
      final box = _box(spec, []);
      final position = <String, Object?>{'x': 0};
      layouts.configure(_Chart(0), box, {
        'fullSize': true,
        'position': position,
        'weight': 7,
      });

      expect(box.fullSize, isTrue);
      expect(box.position, same(position));
      expect(box.weight, 7);
    });
  });

  group('adapt-layout-configure-types', () {
    final spec = layoutsReference.first.boxes.first;

    test('writes the truthiness of fullSize', () {
      final box = _box(spec, []);
      layouts.configure(_Chart(0), box, {'fullSize': 1, 'weight': null});

      expect(box.fullSize, isTrue);
      expect(box.position, same(undefined));

      layouts.configure(_Chart(0), box, const {});
      expect(box.fullSize, isFalse);
    });
  });

  group('configure keeps the raw weight', () {
    // The vertical scale 'y' of the first scene.
    final spec = layoutsReference.first.boxes[1];

    test('stores null, undefined and a string as they are', () {
      final box = _box(spec, []);
      layouts.configure(_Chart(0), box, {'weight': null});
      expect(box.weight, isNull);

      layouts.configure(_Chart(0), box, const {});
      expect(box.weight, same(undefined));

      layouts.configure(_Chart(0), box, {'weight': '5'});
      expect(box.weight, '5');
    });

    test('sorts two absent weights by the reversed index on the left', () {
      // Upstream `undefined === undefined` is true, so the comparator
      // returns the index difference (core.layouts.js:22-24). A NaN weight
      // would keep the order.
      final chart = _Chart(0);
      final a = _box(spec, []);
      final b = _box(spec, []);
      for (final box in [a, b]) {
        layouts
          ..configure(chart, box, {'position': 'left'})
          ..addBox(chart, box);
      }
      for (final box in [a, b]) {
        layouts.configure(chart, box, {'position': 'left'});
      }
      layouts.update(chart, 300, 200);

      expect(b.left, lessThan(a.left));
    });

    test('keeps the order of a null and a 0 weight on the left', () {
      // Upstream `null === 0` is false, and `null - 0` is 0, so the order
      // stays. Equal numbers would reverse it.
      final chart = _Chart(0);
      final a = _box(spec, []);
      final b = _box(spec, []);
      for (final box in [a, b]) {
        layouts.addBox(chart, box);
      }
      layouts
        ..configure(chart, a, {'position': 'left', 'weight': null})
        ..configure(chart, b, {'position': 'left', 'weight': 0});
      layouts.update(chart, 300, 200);

      expect(a.left, lessThan(b.left));
    });
  });

  group('update', () {
    test('returns for a falsy chart', () {
      expect(() => layouts.update(null, 100, 100), returnsNormally);
    });
  });
}

/// A chart area over the four edges of [edges].
final class _Area implements ChartArea {
  _Area(this.edges);

  /// The four edges.
  final TRBL edges;

  @override
  double get left => edges.left;

  @override
  double get top => edges.top;

  @override
  double get right => edges.right;

  @override
  double get bottom => edges.bottom;

  @override
  double get width => right - left;

  @override
  double get height => bottom - top;
}
