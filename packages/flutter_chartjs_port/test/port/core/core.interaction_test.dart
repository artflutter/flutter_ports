// Original code, not ported from Chart.js: core.interaction cases with no spec.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.interaction.dart';
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/elements/element.line.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    as helpers;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_chartjs_port/src/types/active_element.dart';
import 'package:flutter_chartjs_port/src/types/animation.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

import 'interaction_reference.dart';

// Upstream behavior that test/specs/core.interaction.tests.js checks only
// with charts (AGENTS.md rule 3): the modes, evaluateInteractionItems, the
// binary search with spanGaps and with getRange, and the order of the
// element calls.
//
// Each scene is a fake chart with fake metas, controllers and scales, and
// data elements of the upstream element classes. The expected items, errors
// and element calls come from src/core/core.interaction.js at v4.5.1, run
// with type stripping in Node.js v24.22.1 on arm64 over the same scenes.
// interaction_reference.dart has the data, which
// tool/reference/interaction_reference.mjs writes (Chart.js ADR 0045). The
// tests compare them exactly: the items and the calls are the protected
// behavior of Chart.js ADR 0034, and the positions are the results of
// IEEE operations.
//
// The element calls of a query are the calls of inRange, inXRange, inYRange
// and getCenterPoint, in order. Upstream ArcElement has no inXRange and no
// inYRange, so the spy of an arc does not record them
// (adapt-arc-axis-range, differences.md).

/// The JS animation object `{active: () => active, _to: to}`.
final class _Animation({
  /// The result of [active].
  required final bool isActive,
  @override required final Object? to,
}) implements Animation {
  @override
  bool active() => isActive;
}

/// A data element that records its calls under its [name].
abstract interface class _Spy() {
  /// `<dataset index>:<data index>`.
  String get name;
}

/// A [PointElement] that records its calls in [trace].
final class _SpyPoint(
  @override final String name,

  /// The calls of the query.
  final List<String> trace, [
  super.cfg,
]) extends PointElement implements _Spy {
  @override
  bool inRange(double? mouseX, double? mouseY, [bool? useFinalPosition]) {
    trace.add('inRange $name');
    return super.inRange(mouseX, mouseY, useFinalPosition);
  }

  @override
  bool inXRange(double? mouseX, [bool? useFinalPosition]) {
    trace.add('inXRange $name');
    return super.inXRange(mouseX, useFinalPosition);
  }

  @override
  bool inYRange(double? mouseY, [bool? useFinalPosition]) {
    trace.add('inYRange $name');
    return super.inYRange(mouseY, useFinalPosition);
  }

  @override
  ElementPoint getCenterPoint([bool? useFinalPosition]) {
    trace.add('getCenterPoint $name');
    return super.getCenterPoint(useFinalPosition);
  }
}

/// A [BarElement] that records its calls in [trace].
final class _SpyBar(
  @override final String name,

  /// The calls of the query.
  final List<String> trace, [
  super.cfg,
]) extends BarElement implements _Spy {
  @override
  bool inRange(double? mouseX, double? mouseY, [bool? useFinalPosition]) {
    trace.add('inRange $name');
    return super.inRange(mouseX, mouseY, useFinalPosition);
  }

  @override
  bool inXRange(double? mouseX, [bool? useFinalPosition]) {
    trace.add('inXRange $name');
    return super.inXRange(mouseX, useFinalPosition);
  }

  @override
  bool inYRange(double? mouseY, [bool? useFinalPosition]) {
    trace.add('inYRange $name');
    return super.inYRange(mouseY, useFinalPosition);
  }

  @override
  ElementPoint getCenterPoint([bool? useFinalPosition]) {
    trace.add('getCenterPoint $name');
    return super.getCenterPoint(useFinalPosition);
  }
}

/// An [ArcElement] that records its calls in [trace]. Upstream has no
/// `inXRange` and no `inYRange`: they record nothing.
final class _SpyArc(
  @override final String name,

  /// The calls of the query.
  final List<String> trace, [
  super.cfg,
]) extends ArcElement implements _Spy {
  @override
  bool inRange(double? chartX, double? chartY, [bool? useFinalPosition]) {
    trace.add('inRange $name');
    return super.inRange(chartX, chartY, useFinalPosition);
  }

  @override
  ElementPoint getCenterPoint([bool? useFinalPosition]) {
    trace.add('getCenterPoint $name');
    return super.getCenterPoint(useFinalPosition);
  }
}

/// A chart area `{left, top, right, bottom, width, height}`.
final class _Area(
  @override final double left,
  @override final double top,
  @override final double right,
  @override final double bottom,
) implements types.ChartArea {
  @override
  double get width => right - left;

  @override
  double get height => bottom - top;
}

/// A position `{x, y}`.
final class const _Point(@override final double x, @override final double y)
    implements types.Point;

/// A scale with the two members that core.interaction.js reads.
final class _Scale(
  @override final ScaleAxis axis, {
  @override final bool reversePixels = false,
}) implements types.Scale {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A controller with `_cachedMeta` and `_sharedOptions`.
final class _Controller(@override final Map<String, Object?>? sharedOptions)
    implements types.DatasetController {
  @override
  late final types.ChartMeta cachedMeta;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A meta with the members that core.interaction.js reads.
final class _Meta({
  @override required final int index,
  @override required final bool sorted,
  @override required final List<types.Element> data,
  @override required final List<Map<String, Object?>> parsed,
  @override required final types.Element? dataset,
  @override required final types.Scale? iScale,
  @override required final types.Scale? vScale,
  @override required final types.DatasetController controller,
}) implements types.ChartMeta {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A chart with the members that core.interaction.js reads.
/// `isPointInArea` is `_isPointInArea(point, chartArea, minPadding)`, as
/// core.controller.js:816-818.
final class _Chart(
  @override var types.ChartArea chartArea,
  final double _minPadding,
  final List<types.ChartMeta> _metas,
) implements types.Chart {
  @override
  List<types.ChartMeta> getSortedVisibleDatasetMetas() => [..._metas];

  @override
  types.ChartMeta getDatasetMeta(num datasetIndex) =>
      _metas.firstWhere((meta) => meta.index == datasetIndex.toDouble());

  @override
  bool isPointInArea(types.Point point) =>
      helpers.isPointInArea(point, chartArea, _minPadding);

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The event `{type: 'click', native: true, chart, x, y}` of the specs.
final class _Event(
  @override final double? x,
  @override final double? y,
  @override final types.Chart? chart,
) implements types.ChartEvent {
  @override
  String get type => 'click';

  @override
  NativeEvent? get native => null;
}

/// The data element [e] of the dataset [datasetIndex] at [index], which
/// records its calls in [trace].
Element _element(
  InteractionReferenceElement e,
  int datasetIndex,
  int index,
  List<String> trace,
) {
  final name = '$datasetIndex:$index';
  final cfg = AnyObject.of(e.cfg);
  final element = switch (e.type) {
    'point' => _SpyPoint(name, trace, cfg),
    'bar' => _SpyBar(name, trace, cfg),
    _ => _SpyArc(name, trace, cfg),
  };
  if (e.animations.isNotEmpty) {
    element.$animations = {
      for (final (prop, active, to) in e.animations)
        prop: _Animation(isActive: active, to: to),
    };
  }
  return element;
}

/// The fake chart of [scene], whose elements record their calls in [trace].
_Chart _chart(InteractionReferenceScene scene, List<String> trace) {
  final (left, top, right, bottom) = scene.chartArea;
  final metas = <types.ChartMeta>[];
  for (final m in scene.metas) {
    final controller = _Controller(
      m.sharedOptions ? <String, Object?>{} : null,
    );
    final meta = _Meta(
      index: m.index.toInt(),
      sorted: m.sorted,
      data: [
        for (final (i, e) in m.data.indexed)
          _element(e, m.index.toInt(), i, trace),
      ],
      parsed: m.parsed,
      dataset: identical(m.spanGaps, undefined)
          ? null
          : (Element()..options = {'spanGaps': m.spanGaps}),
      iScale: m.iAxis == null
          ? null
          : _Scale(m.iAxis!, reversePixels: m.reversePixels),
      vScale: _Scale(m.vAxis),
      controller: controller,
    );
    controller.cachedMeta = meta;
    metas.add(meta);
  }
  return _Chart(_Area(left, top, right, bottom), scene.minPadding, metas);
}

/// The items of [items] as `(datasetIndex, index, element name)`.
List<(int, int, String)> _results(List<ActiveElement> items) => [
  for (final item in items)
    (item.datasetIndex, item.index, (item.element! as _Spy).name),
];

void main() {
  setUpSpecs();

  group('reference', () {
    test('has the reference of Node.js v24.22.1 on arm64', () {
      expect(interactionReferenceNode, 'v24.22.1');
      expect(interactionReferenceArch, 'arm64');
      expect(interactionReference, hasLength(37));
    });
  });

  group('modes against upstream', () {
    for (final scene in interactionReference) {
      group(scene.name, () {
        for (final (i, q) in scene.queries.indexed) {
          test('query $i: ${q.mode.runtimeType} ${q.options} at '
              '(${q.x}, ${q.y})', () {
            final trace = <String>[];
            final chart = _chart(scene, trace);
            final event = _Event(q.x, q.y, chart);
            final mode = q.mode;
            if (q.error != null) {
              expect(
                () => mode.itemsAt(chart, event, q.options, q.useFinalPosition),
                throwsA(isA<TypeError>()),
              );
              expect(q.error, 'TypeError');
            } else {
              final items = mode.itemsAt(
                chart,
                event,
                q.options,
                q.useFinalPosition,
              );
              expect(_results(items), q.result);
            }
            expect(trace, q.trace);
          });
        }
      });
    }
  });

  group('Interaction', () {
    test('a program gives its own mode as a subclass', () {
      final trace = <String>[];
      final scene = interactionReference.first;
      final chart = _chart(scene, trace);
      const mode = _NoItemsMode();

      expect(mode.itemsAt(chart, _Event(0, 0, chart), const {}), isEmpty);
      expect(InteractionMode.of(mode), same(mode));
      expect(InteractionMode.of(null), isNull);
      expect(InteractionMode.of(undefined), isNull);
      expect(InteractionMode.of(3), isNull);
    });

    test('a mode name is not a mode: a debug build stops', () {
      expect(() => InteractionMode.of('index'), throwsA(isA<AssertionError>()));
    });

    test('an axis of another type takes the fallback axis of the mode', () {
      // adapt-interaction-axis-enum: the option holds an InteractionAxis.
      // Upstream gives a number, a boolean, an object or an array to
      // `axis.indexOf` (core.interaction.js:95): a TypeError, or the result of
      // Array.prototype.indexOf. The port has no such form: a value that is
      // not an axis is the falsy `options.axis` of :272 and :354.
      final scene = interactionReference.first;
      List<(int, int, String)> run(
        InteractionMode mode,
        Map<String, Object?> options,
      ) {
        final chart = _chart(scene, <String>[]);
        return _results(mode.itemsAt(chart, _Event(150, 100, chart), options));
      }

      for (final other in <Object>[5, true, <String, Object?>{}, <Object?>[]]) {
        expect(
          run(const NearestInteractionMode(), {
            'axis': other,
            'intersect': false,
          }),
          run(const NearestInteractionMode(), {
            'axis': InteractionAxis.xy,
            'intersect': false,
          }),
          reason: '$other',
        );
        expect(
          run(const IndexInteractionMode(), {
            'axis': other,
            'intersect': false,
          }),
          run(const IndexInteractionMode(), {
            'axis': InteractionAxis.x,
            'intersect': false,
          }),
          reason: '$other',
        );
      }
    });

    test('an axis keyword is not an axis: a debug build stops', () {
      expect(() => InteractionAxis.of('x'), throwsA(isA<AssertionError>()));
      expect(InteractionAxis.of(null), isNull);
      expect(InteractionAxis.of(InteractionAxis.r), InteractionAxis.r);
    });

    test('the axes of the distance of each value', () {
      // `axis.indexOf('x') !== -1` and `axis.indexOf('y') !== -1` of :95-96.
      expect(
        [
          for (final axis in InteractionAxis.values)
            (axis.name, axis.usesX, axis.usesY),
        ],
        [
          ('x', true, false),
          ('y', false, true),
          ('xy', true, true),
          ('r', false, false),
        ],
      );
    });

    test('evaluateInteractionItems gives each element that is not '
        'skipped', () {
      final trace = <String>[];
      final scene = interactionReference.first;
      final chart = _chart(scene, trace);
      final visits = <(String, int, int)>[];
      Interaction.evaluateInteractionItems(
        chart,
        InteractionAxis.xy,
        const _Point(0, 0),
        (element, datasetIndex, index) =>
            visits.add(((element as _Spy).name, datasetIndex, index)),
      );

      // Dataset 1 skips its element 2 (core.interaction.js:82).
      expect(visits, [
        ('0:0', 0, 0),
        ('0:1', 0, 1),
        ('0:2', 0, 2),
        ('0:3', 0, 3),
        ('0:4', 0, 4),
        ('1:0', 1, 0),
        ('1:1', 1, 1),
        ('1:3', 1, 3),
        ('1:4', 1, 4),
      ]);
      expect(trace, isEmpty);
    });

    test('evaluateInteractionItems searches the index axis of a sorted '
        'meta', () {
      final trace = <String>[];
      final chart = _chart(interactionReference.first, trace);
      final visits = <String>[];
      // x: 200 lies between the elements 1 (150) and 2 (250).
      Interaction.evaluateInteractionItems(
        chart,
        InteractionAxis.x,
        const _Point(200, 0),
        (element, datasetIndex, index) => visits.add((element as _Spy).name),
      );

      expect(visits, ['0:1', '0:2', '1:1']);
    });
  });

  group('getRange (Chart.js ADR 0020, section 9)', () {
    test('PointElement and BarElement implement VisualElementRange', () {
      expect(PointElement(), isA<types.VisualElementRange>());
      expect(BarElement(), isA<types.VisualElementRange>());
    });

    test('ArcElement and LineElement do not implement it', () {
      expect(ArcElement(), isNot(isA<types.VisualElementRange>()));
      expect(LineElement(), isNot(isA<types.VisualElementRange>()));
    });

    test('a BarElement with shared options gives the range of the binary '
        'search', () {
      // The index mode searches the axis x. The bars are 30 wide and 55
      // apart: x 95 hits bar 1 only. The search of x +- 15 visits the bars
      // 0 to 2.
      final scene = interactionReference.firstWhere(
        (s) => s.name == 'bars with shared options',
      );
      final trace = <String>[];
      final chart = _chart(scene, trace);
      final items = const IndexInteractionMode().itemsAt(
        chart,
        _Event(95, 200, chart),
        const {'intersect': true},
      );

      expect(_results(items), [(0, 1, '0:1')]);
      expect(trace, ['inRange 0:0', 'inRange 0:1', 'inRange 0:2']);
    });

    test('a data element without VisualElementRange gives the full '
        'range', () {
      // The arcs have shared options but no getRange: each arc gets a call.
      final scene = interactionReference.firstWhere(
        (s) => s.name == 'arcs on an x index scale with shared options',
      );
      final trace = <String>[];
      final chart = _chart(scene, trace);
      const IndexInteractionMode().itemsAt(
        chart,
        _Event(180, 150, chart),
        const {'intersect': true},
      );

      expect(trace, [
        'inRange 0:0',
        'inRange 0:1',
        'inRange 0:2',
        'inRange 0:3',
      ]);
    });
  });

  group('ActiveElement', () {
    final element = PointElement();

    test('equals an item with the same element and indices', () {
      expect(
        ActiveElement(element: element, datasetIndex: 0, index: 1),
        ActiveElement(element: element, datasetIndex: 0, index: 1),
      );
      expect(
        ActiveElement(element: element, datasetIndex: 0, index: 1).hashCode,
        ActiveElement(element: element, datasetIndex: 0, index: 1).hashCode,
      );
    });

    test('compares the elements by identity', () {
      expect(
        ActiveElement(element: element, datasetIndex: 0, index: 1),
        isNot(
          ActiveElement(element: PointElement(), datasetIndex: 0, index: 1),
        ),
      );
    });

    test('prints its element and its indexes', () {
      final item = ActiveElement(element: element, datasetIndex: 2, index: 3);
      expect(
        item.toString(),
        '{element: PointElement, datasetIndex: 2, '
        'index: 3}',
      );
    });
  });
}

/// A mode of the test: it finds no item.
final class const _NoItemsMode() extends InteractionMode {
  @override
  List<ActiveElement> itemsAt(
    types.Chart chart,
    Object e,
    Object options, [
    bool? useFinalPosition,
  ]) => const [];
}
