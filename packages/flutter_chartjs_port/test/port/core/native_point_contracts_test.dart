// Original code, not ported from Chart.js: native point contract lifetimes.
import 'package:flutter_chartjs_port/src/core/bar_bulk_update.dart';
import 'package:flutter_chartjs_port/src/core/point_options.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/options/resolved.g.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

class _Capability() implements NativePointChart, NativePointElement {
  bool allowed = true;
  int reads = 0;
  @override
  bool get supportsNativePointOptions {
    reads++;
    return allowed;
  }
}

class _Scale() implements types.Scale, BulkBarScale {
  bool allowed = true;
  int reads = 0;
  @override
  bool get supportsBulkBarUpdate {
    reads++;
    return allowed;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected ${invocation.memberName}');
}

class _UnknownScale() implements types.Scale {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected ${invocation.memberName}');
}

void main() {
  test('point and chart capabilities are live, never identity proofs', () {
    final object = _Capability();
    expect(nativePointChart(object), isTrue);
    expect(nativePointElement(object), isTrue);
    object.allowed = false;
    expect(nativePointChart(object), isFalse);
    expect(nativePointElement(object), isFalse);
    expect(object.reads, 4);
    expect(nativePointChart(Object()), isFalse);
    expect(nativePointElement(Object()), isFalse);
  });

  test(
    'projection capability does not imply grid purity or chart ownership',
    () {
      final scale = _Scale();
      expect(nativePointProjection(scale), isTrue);
      scale.allowed = false;
      expect(nativePointProjection(scale), isFalse);
      expect(scale.reads, 2);
      expect(nativePointProjection(_UnknownScale()), isFalse);
    },
  );

  test('class identity and dataset indices remain independent live facts', () {
    final cls = JsClass('Point', statics: {'id': 'point'});
    expect(nativePointClass(cls), isTrue);
    cls['id'] = 'other';
    expect(nativePointClass(cls), isFalse);
    cls['id'] = 1;
    expect(nativePointClass(cls), isFalse);
    expect(nativePointClass({'id': 'point'}), isFalse);
    expect(nativePointClass(null), isFalse);
    for (final index in [0.0, -0.0, 2.0]) {
      expect(nativePointDatasetIndex(index), isTrue);
    }
    for (final index in [-1.0, .5, double.nan, double.infinity]) {
      expect(nativePointDatasetIndex(index), isFalse);
    }
  });

  test('resolution owns validation before either context or executor', () {
    final events = <String>[];
    var allowed = false;
    final result = PointOptions();
    Object context() {
      events.add('context');
      return Object();
    }

    Object prepared() {
      events.add('prepared');
      return Object();
    }

    final plan = NativePointResolution(
      data: Object(),
      raw: [],
      valid: () {
        events.add('validate');
        return allowed;
      },
      resolve: (context, preparedContext) {
        events.add('execute');
        context();
        preparedContext?.call();
        allowed = false;
        return result;
      },
    );
    expect(plan.resolve(context, prepared), isNull);
    expect(events, ['validate']);
    events.clear();
    allowed = true;
    expect(plan.resolve(context, prepared), same(result));
    expect(events, ['validate', 'execute', 'context', 'prepared']);
    events.clear();
    expect(plan.resolve(context, prepared), isNull);
    expect(events, ['validate']);
  });

  test('validation errors propagate before the resolver can run', () {
    final plan = NativePointResolution(
      data: Object(),
      raw: [],
      valid: () => throw StateError('changed source'),
      resolve: (_, _) => fail('executor must not run'),
    );
    expect(
      () => plan.resolve(() => fail('context must not run'), null),
      throwsStateError,
    );
  });
}
