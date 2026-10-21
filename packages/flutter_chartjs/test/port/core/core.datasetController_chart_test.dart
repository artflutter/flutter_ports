// Original code, not ported from Chart.js: typed element options on charts.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart' show createMockContext;
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.datasetController.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/elements/element.line.dart';
import 'package:flutter_chartjs/src/elements/element_options.dart';
import 'package:flutter_chartjs/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

// The typed element options of Chart.js ADR 0021, section 7, on real charts
// of the harness (Chart.js ADR 0022). core.datasetController_test.dart runs
// the same checks on its fake chart, and the parse paths. This file needs
// the registry and the built-in elements, which that file removes with
// `setUpSpecs()`. Thus the chart cases are a file of their own.
//
// Phase 5 has no concrete controller. main() registers port-only test
// controllers and a test scale as class values (Chart.js ADR 0020, section
// 8), before the snapshot of the restore (Chart.js ADR 0022, section 8). A
// test controller follows the option calls of controller.line.js:41-120:
// the dataset options with the `segment` option, then the data options
// through `getSharedOptions_`. `enableOptionSharing` is true, as
// controller.line.js:35 sets it, unless the dataset gives `sharing: false`.

/// The test controller of the registered class values.
final class _TypedController extends DatasetController {
  _TypedController(
    super.chart,
    super.datasetIndex, [
    super.newTarget,
  ]) : drawElements = true;

  /// A controller whose [draw] draws nothing.
  _TypedController.noDraw(
    super.chart,
    super.datasetIndex, [
    super.newTarget,
  ]) : drawElements = false;

  /// Whether [draw] draws the elements. The bar, arc and custom elements of
  /// these tests have no geometry properties, so their draw would throw.
  final bool drawElements;

  @override
  void draw() {
    if (drawElements) super.draw();
  }

  @override
  void initialize() {
    enableOptionSharing = jsGet(getDataset(), 'sharing') != false;
    super.initialize();
  }

  @override
  void update(String mode) {
    final meta = cachedMeta;
    final line = meta.dataset;
    final points = meta.data;
    if (line != null) {
      // controller.line.js:60-67.
      final options = resolveDatasetElementOptions(mode);
      options['segment'] = jsGet(this.options, 'segment');
      updateElement(line as Element, null, {
        'animated': !jsTruthy(chart.animationsDisabled),
        'options': options,
      }, mode);
    }
    updateElements(points, 0, points.length.toDouble(), mode);
  }

  @override
  void updateElements(
    List<types.Element> points,
    double start,
    double count,
    String mode,
  ) {
    final meta = cachedMeta;
    final iScale = meta.iScale!;
    final vScale = meta.vScale!;
    final (:sharedOptions, :includeOptions) = getSharedOptions_(start, mode);
    for (var i = start; i < start + count; ++i) {
      final point = points[i.toInt()] as Element;
      final parsed = getParsed(i);
      final properties = <String, Object?>{
        'x': iScale.getPixelForValue(jsGet(parsed, 'x'), i),
        'y': vScale.getPixelForValue(jsGet(parsed, 'y'), i),
      };
      if (includeOptions) {
        properties['options'] =
            sharedOptions ??
            resolveDataElementOptions(i, point.active ? 'active' : mode);
      }
      updateElement(point, i, properties, mode);
    }
  }
}

/// The class value of the test controller [id] with the element types
/// [dataset] (`false` for none) and [data], and the scales of the type
/// `typedLinear`. [draw] is [_TypedController.drawElements].
JsClass _controller(
  String id,
  Object dataset,
  String data, {
  bool draw = true,
}) => JsClass(
  'TypedController',
  superclass: DatasetController.jsClass,
  statics: {
    'id': id,
    'defaults': <String, Object?>{
      'datasetElementType': dataset,
      'dataElementType': data,
    },
    'overrides': <String, Object?>{
      'scales': <String, Object?>{
        '_index_': <String, Object?>{'type': 'typedLinear'},
        '_value_': <String, Object?>{'type': 'typedLinear'},
      },
    },
  },
  construct: (newTarget, args) {
    final (:chart, :datasetIndex) = controllerArgs(args);
    return draw
        ? _TypedController(chart, datasetIndex, newTarget)
        : _TypedController.noDraw(chart, datasetIndex, newTarget);
  },
);

/// The scale `typedLinear`: the range 0 to 10, with the ticks 0, 5 and 10.
final class _TypedScale extends Scale {
  _TypedScale(super.cfg);

  @override
  void determineDataLimits() {
    min = 0;
    max = 10;
  }

  @override
  List<Tick>? buildTicks() => [Tick(value: 0), Tick(value: 5), Tick(value: 10)];

  @override
  double getPixelForValue(Object? value, [double? index]) {
    return getPixelForDecimal((jsToNumber(value) - min) / (max - min));
  }
}

/// The class value of the scale `typedLinear`.
final JsClass _typedScale = JsClass(
  'TypedScale',
  superclass: Scale.jsClass,
  statics: {'id': 'typedLinear', 'defaults': <String, Object?>{}},
  construct: (newTarget, args) => _TypedScale(scaleCfgArg(args)),
);

/// `class CustomElement extends Element` with the id `custom` and its own
/// defaults.
final JsClass _customElement = JsClass(
  'CustomElement',
  superclass: Element.jsClass,
  statics: {
    'id': 'custom',
    'defaults': <String, Object?>{'size': 3.0, 'label': 'c'},
  },
);

/// The data of a dataset: two points.
List<Object?> _points() => <Object?>[
  <String, Object?>{'x': 1, 'y': 2},
  <String, Object?>{'x': 5, 'y': 8},
];

/// A chart of the controller [type] with one dataset of [_points]. [dataset]
/// adds keys to the dataset, and [options] gives the chart options.
Chart _chart(
  String type, {
  Map<String, Object?> dataset = const {},
  Map<String, Object?>? options,
}) => acquireChart({
  'type': type,
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{'data': _points(), ...dataset},
    ],
  },
  'options': ?options,
});

/// The test controller of the dataset 0 of [chart].
DatasetController _controllerOf(Chart chart) =>
    chart.getDatasetMeta(0).controller!;

void main() {
  Chart.register([
    _controller('typedLine', 'line', 'point'),
    _controller('typedLineLine', 'line', 'line'),
    _controller('typedPointPoint', 'point', 'point'),
    _controller('typedBar', false, 'bar', draw: false),
    _controller('typedArc', false, 'arc', draw: false),
    _controller('typedCustom', false, 'custom', draw: false),
    _typedScale,
    _customElement,
  ]);

  group('the writable ctx (Chart.js ADR 0030)', () {
    testWidgets('a write of ctx changes the context of the next draw', (
      tester,
    ) async {
      // core.datasetController.js:257 `this._ctx = chart.ctx`, and :713
      // draws the elements on `this._ctx`. The property is writable.
      final chart = _chart('typedLine');
      final controller = _controllerOf(chart);
      expect(identical(controller.ctx, chart.ctx), isTrue);
      final recording = createMockContext();
      controller.ctx = recording;
      expect(identical(controller.ctx, recording), isTrue);
      expect(identical(chart.ctx, recording), isFalse);
      chart.draw();
      final names = recording.getCalls().map((call) => call['name']).toList();
      // The line and the two points of the dataset draw on the recording
      // context: the points as circles (helpers.canvas.ts drawPoint).
      expect(names.where((name) => name == 'arc'), hasLength(2));
      expect(names, contains('stroke'));
      // The chart keeps its own context.
      expect(identical(chart.ctx, recording), isFalse);
      recording.resetCalls();
      controller.ctx = chart.ctx;
      chart.draw();
      expect(recording.getCalls(), isEmpty);
    });
  });

  group('adapt-typed-element-options', () {
    testWidgets('the shared data options are a frozen PointOptions', (
      tester,
    ) async {
      // core.datasetController.tests.js:956-976 in the typed form.
      final controller = _controllerOf(_chart('typedLine'));
      final opts0 = controller.resolveDataElementOptions(0);
      final opts1 = controller.resolveDataElementOptions(1);
      expect(opts0, isA<PointOptions>());
      expect(opts0, same(opts1));
      expect(opts0[r'$shared'], isTrue);
      expect(jsObjectIsFrozen(opts0), isTrue);
    });

    testWidgets(r'without sharing, the cache entry is frozen with $shared '
        'false', (tester) async {
      final controller = _controllerOf(
        _chart('typedLine', dataset: {'sharing': false}),
      );
      final opts0 = controller.resolveDataElementOptions(0);
      final opts1 = controller.resolveDataElementOptions(0);
      expect(opts0, isA<PointOptions>());
      expect(opts1, isA<PointOptions>());
      expect(opts0, isNot(same(opts1)));
      expect(opts0[r'$shared'], isFalse);
      expect(jsObjectIsFrozen(opts0), isFalse);
      expect(jsObjectIsFrozen(opts1), isFalse);
      // `cloneIfNotShared(cached, sharing)` (core.datasetController.js:845)
      // returns the cache entry itself when sharing is on.
      controller.enableOptionSharing = true;
      final cached = controller.resolveDataElementOptions(0);
      expect(cached, isA<PointOptions>());
      expect(jsObjectIsFrozen(cached), isTrue);
      expect(cached[r'$shared'], isFalse);
      expect(controller.resolveDataElementOptions(1), same(cached));
    });

    testWidgets('a scriptable option gives a PointOptions that is not frozen', (
      tester,
    ) async {
      // core.datasetController.tests.js:1000-1019 in the typed form.
      final controller = _controllerOf(
        _chart(
          'typedLine',
          dataset: {
            'backgroundColor': (Object? context) =>
                jsGet(context, 'dataIndex') == 0 ? 'blue' : 'red',
          },
        ),
      );
      final opts0 = controller.resolveDataElementOptions(0);
      final opts1 = controller.resolveDataElementOptions(1);
      expect(opts0, isA<PointOptions>());
      expect(opts0, isNot(same(opts1)));
      expect(opts0[r'$shared'], isFalse);
      expect(jsObjectIsFrozen(opts0), isFalse);
      expect(opts0['backgroundColor'], 'blue');
      expect(opts1['backgroundColor'], 'red');
    });

    testWidgets('the dataset options are a new LineOptions for each call', (
      tester,
    ) async {
      final chart = _chart('typedLine');
      final controller = _controllerOf(chart);
      final first = controller.resolveDatasetElementOptions();
      final second = controller.resolveDatasetElementOptions();
      expect(first, isA<LineOptions>());
      expect(second, isA<LineOptions>());
      expect(first, isNot(same(second)));
      expect(jsObjectIsFrozen(first), isFalse);
      expect(first[r'$shared'], isFalse);
      // The line holds the dataset options with `segment` at the end
      // (controller.line.js:66).
      final line = chart.getDatasetMeta(0).dataset! as LineElement;
      final options = line.options!;
      expect(options, isA<LineOptions>());
      final keys = jsObjectKeys(options);
      expect(keys.first, r'$shared');
      expect(keys.last, 'segment');
      expect(keys.where((key) => key == 'segment'), hasLength(1));
    });

    testWidgets('the cache entry of the dataset options is frozen', (
      tester,
    ) async {
      // The data elements have the type of the dataset element. The dataset
      // call fills the cache entry `line-default` without an index, so its
      // `$shared` is false. The data call with an index returns that entry
      // (core.datasetController.js:836-846).
      final controller = _controllerOf(_chart('typedLineLine'));
      final cached = controller.resolveDataElementOptions(0);
      expect(cached, isA<LineOptions>());
      expect(jsObjectIsFrozen(cached), isTrue);
      expect(cached[r'$shared'], isFalse);
      expect(controller.resolveDatasetElementOptions(), isNot(same(cached)));
    });

    testWidgets('getSharedOptions keeps the class and the key order', (
      tester,
    ) async {
      final chart = _chart('typedLine');
      final controller = _controllerOf(chart);
      final source = controller.resolveDataElementOptions(0);
      final shared = controller.getSharedOptions(source)!;
      expect(shared, isA<PointOptions>());
      expect(shared, isNot(same(source)));
      expect(jsObjectIsFrozen(shared), isFalse);
      expect(jsObjectKeys(shared), jsObjectKeys(source));
      chart.update('none');
      final points = chart.getDatasetMeta(0).data;
      for (final point in points) {
        expect(point.options, same(controller.sharedOptions));
      }
      // A write into the frozen cache entry throws. A write into the options
      // of a point does not throw.
      expect(() => source['radius'] = 9.0, throwsA(isA<TypeError>()));
      points[0].options!['radius'] = 9.0;
      expect(points[0].options!['radius'], 9.0);
    });

    testWidgets('after the hover animation, the point holds a copy with '
        r'$shared false', (tester) async {
      // _setStyle (core.datasetController.js:919-927) animates a copy of
      // the shared options with `$shared` false. The options of the mode
      // 'active' need the context: the hover colors of core.defaults.js are
      // scriptable. Thus their `$shared` is false, `_animateOptions` waits
      // for no animation (core.animations.js:51-58), and the point keeps the
      // copy after the end.
      final chart = _chart(
        'typedLine',
        options: <String, Object?>{
          'animation': <String, Object?>{'duration': 100},
        },
      );
      await tester.pump(const Duration(seconds: 2));
      final controller = _controllerOf(chart);
      final point = chart.getDatasetMeta(0).data[0] as Element;
      final shared = point.options;
      expect(shared![r'$shared'], isTrue);
      controller.setHoverStyle(point, 0, 0);
      final copy = point.options;
      expect(copy, isA<PointOptions>());
      expect(copy, isNot(same(shared)));
      chart.render();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final active = controller.resolveDataElementOptions(0, 'active');
      expect(active[r'$shared'], isFalse);
      expect(point.options, same(copy));
      expect(copy![r'$shared'], isFalse);
      expect(jsObjectIsFrozen(copy), isFalse);
      expect(copy['radius'], active['radius']);
      expect(copy['backgroundColor'], active['backgroundColor']);
    });

    testWidgets('bar, arc and custom element types', (tester) async {
      final barOptions = _controllerOf(
        _chart('typedBar'),
      ).resolveDataElementOptions(0);
      expect(barOptions, isA<BarOptions>());
      expect(jsObjectIsFrozen(barOptions), isTrue);
      final arcOptions = _controllerOf(
        _chart('typedArc'),
      ).resolveDataElementOptions(0);
      expect(arcOptions, isA<ArcOptions>());
      expect(jsObjectIsFrozen(arcOptions), isTrue);
      final customOptions = _controllerOf(
        _chart('typedCustom', dataset: {'size': 4.0}),
      ).resolveDataElementOptions(0);
      expect(customOptions, isA<GenericElementOptions>());
      expect(jsObjectIsFrozen(customOptions), isTrue);
      expect(jsObjectKeys(customOptions), [r'$shared', 'size', 'label']);
      expect(customOptions['size'], 4.0);
    });

    testWidgets('case 6: the build of an animated chart throws a TypeError', (
      tester,
    ) async {
      // The dataset and the data elements have the type `point`. The
      // dataset call fills the cache entry `point-default` with `$shared`
      // false, and the data calls return that frozen entry. With an
      // animation, `_createAnimations` writes `$animations` into it
      // (core.animations.js:71). acquireChart sets `animation: false` only
      // when the config gives no `animation` (chartjs-test-utils
      // src/utils.js:60).
      expect(
        () => _chart(
          'typedPointPoint',
          options: <String, Object?>{
            'animation': <String, Object?>{'duration': 100},
          },
        ),
        throwsA(isA<TypeError>()),
      );
      // Without an animation, the data elements hold the frozen entry.
      final chart = _chart('typedPointPoint');
      final options = chart.getDatasetMeta(0).data[0].options;
      expect(options, isA<PointOptions>());
      expect(jsObjectIsFrozen(options), isTrue);
      expect(options![r'$shared'], isFalse);
    });
  });

  group('js-semantics-resolver-objects', () {
    // With `parsing: false` and a stacked value scale, updateStacks writes
    // `item._stacks = {}` into each data item
    // (core.datasetController.js:165). A List item keeps the property
    // through stacksOf (Chart.js ADR 0036). Each test registers its own test
    // controller and removes it at its end (Chart.js ADR 0022, section 8).

    /// Registers the test controller `stacksPoint` (point data elements, no
    /// dataset element) for the current test.
    void registerController() {
      final controller = _controller(
        'stacksPoint',
        false,
        'point',
        draw: false,
      );
      Chart.register([controller]);
      addTearDown(() => Chart.unregister([controller]));
    }

    /// A chart of `stacksPoint` with the data [data], `parsing: false` and
    /// a stacked y scale.
    Chart stackedChart(List<Object?> data) => acquireChart({
      'type': 'stacksPoint',
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{'data': data},
        ],
      },
      'options': <String, Object?>{
        'parsing': false,
        'scales': <String, Object?>{
          'y': <String, Object?>{'stacked': true},
        },
      },
    });

    testWidgets('List data items take the stacks', (tester) async {
      registerController();
      final items = <Object?>[
        <Object?>[0.0, 1.0],
        <Object?>[1.0, 2.0],
      ];
      final chart = stackedChart(items);
      final meta = chart.getDatasetMeta(0);
      expect(jsTruthy(meta.stacked), isTrue);
      expect(identical(meta.parsed, items), isTrue);
      for (final item in items) {
        final itemStacks = stacksOf(item);
        expect(itemStacks, isA<Map<String, Object?>>());
        expect(jsObjectKeys(itemStacks! as Map<String, Object?>), ['y']);
      }
      expect(chart.stacks, isNotNull);
      // A second update reads the stacks of the items again.
      chart.update();
      expect(jsObjectKeys(stacksOf(items[0])! as Map<String, Object?>), [
        'y',
      ]);
    });

    testWidgets('DateTime data items take the stacks', (tester) async {
      // A Date is an object (Chart.js ADR 0024). The Node.js probe of the
      // pinned build gives no throw and the key y.
      registerController();
      final items = <Object?>[DateTime.utc(1970), DateTime.utc(1971)];
      final chart = stackedChart(items);
      expect(jsTruthy(chart.getDatasetMeta(0).stacked), isTrue);
      for (final item in items) {
        final itemStacks = stacksOf(item);
        expect(itemStacks, isA<Map<String, Object?>>());
        expect(jsObjectKeys(itemStacks! as Map<String, Object?>), ['y']);
      }
    });

    testWidgets('number and string data items throw at the write', (
      tester,
    ) async {
      // A property write into a primitive in the strict code of an ES
      // module. The port throws the plain TypeError of the write, not the
      // Dart _TypeError of a later cast.
      registerController();
      for (final items in <List<Object?>>[
        <Object?>[1.0, 2.0],
        <Object?>['a', 'b'],
      ]) {
        expect(
          () => stackedChart(items),
          throwsA(predicate((e) => e.runtimeType == TypeError)),
          reason: '$items',
        );
      }
    });

    testWidgets('a data item of a narrow Map type throws a TypeError', (
      tester,
    ) async {
      // The differences.md row: the write of `_stacks` into a
      // Map<String, double> throws, where upstream writes into the object.
      registerController();
      expect(
        () => stackedChart(<Object?>[
          <String, double>{'x': 0, 'y': 1},
          <String, double>{'x': 1, 'y': 2},
        ]),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
