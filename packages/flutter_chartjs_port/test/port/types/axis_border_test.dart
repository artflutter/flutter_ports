// Original code, not ported from Chart.js: the scale border values.
// The value tests build equal borders that are not identical.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/types/axis_border.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:test/test.dart';

// The scale option border holds a ScaleBorder (Chart.js ADR 0141, row
// adapt-native-scale-border). The scopes merge with ScaleBorder.merge.

const ChartPaint _red = ChartPaint.solid(Color(0xFFFF0000));
const ChartPaint _blue = ChartPaint.solid(Color(0xFF0000FF));

void main() {
  group('AxisBorder.merge', () {
    const base = AxisBorder(
      display: true,
      color: _red,
      width: 1,
      dash: [],
      dashOffset: 0,
    );

    test('a field of the other border wins, and a null field keeps', () {
      expect(
        base.merge(const AxisBorder(width: 3, color: _blue, z: 2)),
        const AxisBorder(
          display: true,
          color: _blue,
          width: 3,
          dash: [],
          dashOffset: 0,
          z: 2,
        ),
      );
      expect(base.merge(const AxisBorder()), base);
    });

    test('null keeps the border', () {
      expect(base.merge(null), same(base));
    });

    test('a border of another class replaces it', () {
      const radial = RadialAxisBorder(dash: [2, 2]);
      expect(base.merge(radial), same(radial));
    });
  });

  group('RadialAxisBorder.merge', () {
    const base = RadialAxisBorder(dash: [], dashOffset: 0);

    test('a field of the other border wins, and a null field keeps', () {
      expect(
        base.merge(const RadialAxisBorder(dash: [4, 2])),
        const RadialAxisBorder(dash: [4, 2], dashOffset: 0),
      );
      expect(
        base.merge(const RadialAxisBorder(dashOffset: 1)),
        const RadialAxisBorder(dash: [], dashOffset: 1),
      );
    });

    test('null keeps the border', () {
      expect(base.merge(null), same(base));
    });

    test('a border of another class replaces it', () {
      const axis = AxisBorder(width: 7);
      expect(base.merge(axis), same(axis));
    });
  });

  group('the value semantics', () {
    test('== and hashCode compare the fields, the dash by its lengths', () {
      final a = AxisBorder(dash: [4, 4], width: 2, color: _red);
      final b = AxisBorder(dash: [4, 4], width: 2, color: _red);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(AxisBorder(dash: [4, 3], width: 2, color: _red)));
      expect(a, isNot(const AxisBorder(width: 2, color: _red)));
      expect(RadialAxisBorder(dash: [2, 2]), RadialAxisBorder(dash: [2, 2]));
      expect(
        RadialAxisBorder(dash: [2, 2]).hashCode,
        RadialAxisBorder(dash: [2, 2]).hashCode,
      );
      // A border of another class is not equal, also with the same dash.
      expect(
        const AxisBorder(dash: [2, 2]),
        isNot(const RadialAxisBorder(dash: [2, 2])),
      );
    });

    test('copyWith keeps the fields that it does not get', () {
      const border = AxisBorder(display: false, width: 2);
      expect(
        border.copyWith(width: 3),
        const AxisBorder(display: false, width: 3),
      );
      expect(
        const RadialAxisBorder(dash: [1]).copyWith(dashOffset: 2),
        const RadialAxisBorder(dash: [1], dashOffset: 2),
      );
    });

    test('toString names each field', () {
      // A double prints as 1 or 1.0 by the platform: the test reads names.
      final text = const RadialAxisBorder(dash: [1], dashOffset: 2).toString();
      expect(text, startsWith('RadialAxisBorder(dash: [1'));
      expect(text, contains('dashOffset: 2'));
      expect(
        const AxisBorder(width: 2).toString(),
        startsWith('AxisBorder(display: null'),
      );
    });
  });
}
