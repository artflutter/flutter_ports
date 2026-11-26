// Ported from d3-shape v3.2.0 test/pie-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

void main() {
  test('pie() returns a default pie shape', () {
    final p = pie<double>();
    expect(p.value(42, 0, const []), 42);
    expect(p.sortValues!(1, 2), greaterThan(0));
    expect(p.sortValues!(2, 1), lessThan(0));
    expect(p.sortValues!(1, 1), 0);
    expect(p.sort, isNull);
    expect(p.startAngle(const []), 0);
    expect(p.endAngle(const []), 2 * math.pi);
    expect(p.padAngle(const []), 0);
  });

  test('pie(data) returns arcs in input order', () {
    final p = pie<double>();
    expect(p([1, 3, 2]), [
      const PieArc<double>(
        data: 1,
        value: 1,
        index: 2,
        startAngle: 5.235987755982988,
        endAngle: 6.283185307179585,
        padAngle: 0,
      ),
      const PieArc<double>(
        data: 3,
        value: 3,
        index: 0,
        startAngle: 0,
        endAngle: 3.141592653589793,
        padAngle: 0,
      ),
      const PieArc<double>(
        data: 2,
        value: 2,
        index: 1,
        startAngle: 3.141592653589793,
        endAngle: 5.235987755982988,
        padAngle: 0,
      ),
    ]);
  });

  test('pie(data) accepts an iterable', () {
    final p = pie<double>();
    expect(p({1, 3, 2}), [
      const PieArc<double>(
        data: 1,
        value: 1,
        index: 2,
        startAngle: 5.235987755982988,
        endAngle: 6.283185307179585,
        padAngle: 0,
      ),
      const PieArc<double>(
        data: 3,
        value: 3,
        index: 0,
        startAngle: 0,
        endAngle: 3.141592653589793,
        padAngle: 0,
      ),
      const PieArc<double>(
        data: 2,
        value: 2,
        index: 1,
        startAngle: 3.141592653589793,
        endAngle: 5.235987755982988,
        padAngle: 0,
      ),
    ]);
  });

  test(
    'pie(data) coerces the specified value to a number',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test('pie(data) treats negative values as zero', () {
    final p = pie<double>();
    expect(p([1, 0, -1]), [
      const PieArc<double>(
        data: 1,
        value: 1,
        index: 0,
        startAngle: 0,
        endAngle: 6.283185307179586,
        padAngle: 0,
      ),
      const PieArc<double>(
        data: 0,
        value: 0,
        index: 1,
        startAngle: 6.283185307179586,
        endAngle: 6.283185307179586,
        padAngle: 0,
      ),
      const PieArc<double>(
        data: -1,
        value: -1,
        index: 2,
        startAngle: 6.283185307179586,
        endAngle: 6.283185307179586,
        padAngle: 0,
      ),
    ]);
  });

  test('pie(data) treats NaN values as zero', () {
    final p = pie<double?>();
    final actual = p([1, double.nan, null]);
    expect(
      actual[0],
      const PieArc<double?>(
        data: 1,
        value: 1,
        index: 0,
        startAngle: 0,
        endAngle: 6.283185307179586,
        padAngle: 0,
      ),
    );
    expect(actual[1].data!.isNaN, isTrue);
    expect(actual[1].value.isNaN, isTrue);
    expect(actual[1].index, 1);
    expect(actual[1].startAngle, 6.283185307179586);
    expect(actual[1].endAngle, 6.283185307179586);
    expect(actual[1].padAngle, 0);
    expect(actual[2].data, isNull);
    expect(actual[2].value.isNaN, isTrue);
    expect(actual[2].index, 2);
    expect(actual[2].startAngle, 6.283185307179586);
    expect(actual[2].endAngle, 6.283185307179586);
    expect(actual[2].padAngle, 0);
  });

  test('pie(data) puts everything at the startAngle when the sum is zero', () {
    final p = pie<double>();
    expect(p([0, 0]), [
      const PieArc<double>(
        data: 0,
        value: 0,
        index: 0,
        startAngle: 0,
        endAngle: 0,
        padAngle: 0,
      ),
      const PieArc<double>(
        data: 0,
        value: 0,
        index: 1,
        startAngle: 0,
        endAngle: 0,
        padAngle: 0,
      ),
    ]);
    p.startAngleConst(1);
    expect(p([0, 0]), [
      const PieArc<double>(
        data: 0,
        value: 0,
        index: 0,
        startAngle: 1,
        endAngle: 1,
        padAngle: 0,
      ),
      const PieArc<double>(
        data: 0,
        value: 0,
        index: 1,
        startAngle: 1,
        endAngle: 1,
        padAngle: 0,
      ),
    ]);
  });

  test('pie(data) restricts |endAngle - startAngle| to τ', () {
    final p = pie<double>();
    expect(
      (p
        ..startAngleConst(0)
        ..endAngleConst(7))([1, 2]),
      [
        const PieArc<double>(
          data: 1,
          value: 1,
          index: 1,
          startAngle: 4.1887902047863905,
          endAngle: 6.2831853071795860,
          padAngle: 0,
        ),
        const PieArc<double>(
          data: 2,
          value: 2,
          index: 0,
          startAngle: 0,
          endAngle: 4.1887902047863905,
          padAngle: 0,
        ),
      ],
    );
    expect(
      (p
        ..startAngleConst(7)
        ..endAngleConst(0))([1, 2]),
      [
        const PieArc<double>(
          data: 1,
          value: 1,
          index: 1,
          startAngle: 2.8112097952136095,
          endAngle: 0.7168146928204142,
          padAngle: 0,
        ),
        const PieArc<double>(
          data: 2,
          value: 2,
          index: 0,
          startAngle: 7,
          endAngle: 2.8112097952136095,
          padAngle: 0,
        ),
      ],
    );
    expect(
      (p
        ..startAngleConst(1)
        ..endAngleConst(8))([1, 2]),
      [
        const PieArc<double>(
          data: 1,
          value: 1,
          index: 1,
          startAngle: 5.1887902047863905,
          endAngle: 7.2831853071795860,
          padAngle: 0,
        ),
        const PieArc<double>(
          data: 2,
          value: 2,
          index: 0,
          startAngle: 1,
          endAngle: 5.1887902047863905,
          padAngle: 0,
        ),
      ],
    );
    expect(
      (p
        ..startAngleConst(8)
        ..endAngleConst(1))([1, 2]),
      [
        const PieArc<double>(
          data: 1,
          value: 1,
          index: 1,
          startAngle: 3.8112097952136095,
          endAngle: 1.7168146928204142,
          padAngle: 0,
        ),
        const PieArc<double>(
          data: 2,
          value: 2,
          index: 0,
          startAngle: 8,
          endAngle: 3.8112097952136095,
          padAngle: 0,
        ),
      ],
    );
  });

  test('pie.value(value)(data) observes the specified value function', () {
    expect(
      (pie<Null>()..value = (_, i, _) => i.toDouble())([null, null, null]),
      [
        const PieArc<Null>(
          data: null,
          value: 0,
          index: 2,
          startAngle: 6.2831853071795860,
          endAngle: 6.2831853071795860,
          padAngle: 0,
        ),
        const PieArc<Null>(
          data: null,
          value: 1,
          index: 1,
          startAngle: 4.1887902047863905,
          endAngle: 6.2831853071795860,
          padAngle: 0,
        ),
        const PieArc<Null>(
          data: null,
          value: 2,
          index: 0,
          startAngle: 0,
          endAngle: 4.1887902047863905,
          padAngle: 0,
        ),
      ],
    );
  });

  test(
    'pie.value(f)(data) passes d, i and data to the specified function f',
    () {
      final data = ['a', 'b'];
      final actual = <(String, int, List<String>)>[];
      (pie<String>()
        ..value = (d, i, all) {
          actual.add((d, i, all));
          return 0;
        })(data);
      expect(actual, [('a', 0, data), ('b', 1, data)]);
    },
  );

  test(
    'pie().startAngle(f)(…) propagates the context and arguments to the '
    'specified function f',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test('pie().startAngle(θ)(data) observes the specified start angle', () {
    expect(pie<double>(startAngle: math.pi)([1, 2, 3]), [
      const PieArc<double>(
        data: 1,
        value: 1,
        index: 2,
        startAngle: 5.759586531581287,
        endAngle: 6.283185307179586,
        padAngle: 0,
      ),
      const PieArc<double>(
        data: 2,
        value: 2,
        index: 1,
        startAngle: 4.712388980384690,
        endAngle: 5.759586531581287,
        padAngle: 0,
      ),
      const PieArc<double>(
        data: 3,
        value: 3,
        index: 0,
        startAngle: 3.141592653589793,
        endAngle: 4.712388980384690,
        padAngle: 0,
      ),
    ]);
  });

  test('pie().endAngle(θ)(data) observes the specified end angle', () {
    expect(pie<double>(endAngle: math.pi)([1, 2, 3]), [
      const PieArc<double>(
        data: 1,
        value: 1,
        index: 2,
        startAngle: 2.6179938779914940,
        endAngle: 3.1415926535897927,
        padAngle: 0,
      ),
      const PieArc<double>(
        data: 2,
        value: 2,
        index: 1,
        startAngle: 1.5707963267948966,
        endAngle: 2.6179938779914940,
        padAngle: 0,
      ),
      const PieArc<double>(
        data: 3,
        value: 3,
        index: 0,
        startAngle: 0,
        endAngle: 1.5707963267948966,
        padAngle: 0,
      ),
    ]);
  });

  test('pie().padAngle(δ)(data) observes the specified pad angle', () {
    expect(pie<double>(padAngle: 0.1)([1, 2, 3]), [
      const PieArc<double>(
        data: 1,
        value: 1,
        index: 2,
        startAngle: 5.1859877559829880,
        endAngle: 6.2831853071795850,
        padAngle: 0.1,
      ),
      const PieArc<double>(
        data: 2,
        value: 2,
        index: 1,
        startAngle: 3.0915926535897933,
        endAngle: 5.1859877559829880,
        padAngle: 0.1,
      ),
      const PieArc<double>(
        data: 3,
        value: 3,
        index: 0,
        startAngle: 0,
        endAngle: 3.0915926535897933,
        padAngle: 0.1,
      ),
    ]);
  });

  test(
    'pie().endAngle(f)(…) propagates the context and arguments to the '
    'specified function f',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test(
    'pie().padAngle(f)(…) propagates the context and arguments to the '
    'specified function f',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );

  test('pie().startAngle(θ₀).endAngle(θ₁).padAngle(δ)(data) restricts the pad '
      'angle to |θ₁ - θ₀| / data.length', () {
    expect(
      pie<double>(startAngle: 0, endAngle: math.pi, padAngle: double.infinity)([
        1,
        2,
        3,
      ]),
      [
        const PieArc<double>(
          data: 1,
          value: 1,
          index: 2,
          startAngle: 2.0943951023931953,
          endAngle: 3.1415926535897930,
          padAngle: 1.0471975511965976,
        ),
        const PieArc<double>(
          data: 2,
          value: 2,
          index: 1,
          startAngle: 1.0471975511965976,
          endAngle: 2.0943951023931953,
          padAngle: 1.0471975511965976,
        ),
        const PieArc<double>(
          data: 3,
          value: 3,
          index: 0,
          startAngle: 0,
          endAngle: 1.0471975511965976,
          padAngle: 1.0471975511965976,
        ),
      ],
    );
    expect(
      pie<double>(startAngle: 0, endAngle: -math.pi, padAngle: double.infinity)(
        [1, 2, 3],
      ),
      [
        const PieArc<double>(
          data: 1,
          value: 1,
          index: 2,
          startAngle: -2.0943951023931953,
          endAngle: -3.1415926535897930,
          padAngle: 1.0471975511965976,
        ),
        const PieArc<double>(
          data: 2,
          value: 2,
          index: 1,
          startAngle: -1.0471975511965976,
          endAngle: -2.0943951023931953,
          padAngle: 1.0471975511965976,
        ),
        const PieArc<double>(
          data: 3,
          value: 3,
          index: 0,
          startAngle: 0,
          endAngle: -1.0471975511965976,
          padAngle: 1.0471975511965976,
        ),
      ],
    );
  });

  test('pie.sortValues(f) sorts arcs by value per the specified comparator '
      'function f', () {
    final p = pie<double>();
    expect((p..sortValues = (a, b) => a - b)([1, 3, 2]), [
      const PieArc<double>(
        data: 1,
        value: 1,
        index: 0,
        startAngle: 0,
        endAngle: 1.0471975511965976,
        padAngle: 0,
      ),
      const PieArc<double>(
        data: 3,
        value: 3,
        index: 2,
        startAngle: 3.1415926535897930,
        endAngle: 6.2831853071795860,
        padAngle: 0,
      ),
      const PieArc<double>(
        data: 2,
        value: 2,
        index: 1,
        startAngle: 1.0471975511965976,
        endAngle: 3.1415926535897930,
        padAngle: 0,
      ),
    ]);
    expect((p..sortValues = (a, b) => b - a)([1, 3, 2]), [
      const PieArc<double>(
        data: 1,
        value: 1,
        index: 2,
        startAngle: 5.2359877559829880,
        endAngle: 6.2831853071795850,
        padAngle: 0,
      ),
      const PieArc<double>(
        data: 3,
        value: 3,
        index: 0,
        startAngle: 0,
        endAngle: 3.1415926535897930,
        padAngle: 0,
      ),
      const PieArc<double>(
        data: 2,
        value: 2,
        index: 1,
        startAngle: 3.1415926535897930,
        endAngle: 5.2359877559829880,
        padAngle: 0,
      ),
    ]);
    expect(p.sort, isNull);
  });

  test(
    'pie.sort(f) sorts arcs by data per the specified comparator function f',
    () {
      const a = (value: 1.0, name: 'a');
      const b = (value: 2.0, name: 'b');
      const c = (value: 3.0, name: 'c');
      final p = pie<({double value, String name})>()
        ..value = (d, _, _) => d.value;
      expect((p..sort = (x, y) => x.name.compareTo(y.name))([a, c, b]), [
        const PieArc(
          data: a,
          value: 1,
          index: 0,
          startAngle: 0,
          endAngle: 1.0471975511965976,
          padAngle: 0,
        ),
        const PieArc(
          data: c,
          value: 3,
          index: 2,
          startAngle: 3.1415926535897930,
          endAngle: 6.2831853071795860,
          padAngle: 0,
        ),
        const PieArc(
          data: b,
          value: 2,
          index: 1,
          startAngle: 1.0471975511965976,
          endAngle: 3.1415926535897930,
          padAngle: 0,
        ),
      ]);
      expect((p..sort = (x, y) => y.name.compareTo(x.name))([a, c, b]), [
        const PieArc(
          data: a,
          value: 1,
          index: 2,
          startAngle: 5.2359877559829880,
          endAngle: 6.2831853071795850,
          padAngle: 0,
        ),
        const PieArc(
          data: c,
          value: 3,
          index: 0,
          startAngle: 0,
          endAngle: 3.1415926535897930,
          padAngle: 0,
        ),
        const PieArc(
          data: b,
          value: 2,
          index: 1,
          startAngle: 3.1415926535897930,
          endAngle: 5.2359877559829880,
          padAngle: 0,
        ),
      ]);
      expect(p.sortValues, isNull);
    },
  );
}
