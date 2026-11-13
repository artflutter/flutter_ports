// Original code, not ported from Chart.js: native legend hit-box contracts.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart'
    show Legend;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('equalsTo extension', () {
    LegendHitBox box() =>
        LegendHitBox.row(left: 10, top: 20, width: 30, height: 40, row: 1);

    test('compares every field and keeps identity equality and hashing', () {
      final a = box();
      final b = box();
      expect(a.equalsTo(b), isTrue);
      expect(a == b, isFalse);
      final set = {a, b};
      expect(set, hasLength(2));
      for (final changed in [
        b.copyWith(left: 11),
        b.copyWith(top: 21),
        b.copyWith(width: 31),
        b.copyWith(height: 41),
        b.copyWith(row: 2),
        b.copyWith(col: 1),
      ]) {
        expect(a.equalsTo(changed), isFalse);
        expect(changed.equalsTo(a), isFalse);
      }
      b.left = 11;
      expect(a.equalsTo(b), isFalse);
      expect(set.contains(b), isTrue);
      a.left = 11;
      expect(a.equalsTo(b), isTrue);
    });

    test('retains the reference matcher tolerance', () {
      final a = box();
      expect(a.equalsTo(a.copyWith(left: 10 + 5e-10)), isTrue);
      expect(a.equalsTo(a.copyWith(left: 10 + 2e-9)), isFalse);
      final large = a.copyWith(width: 1000000000);
      expect(large.equalsTo(large.copyWith(width: 1e9 + 0.0005)), isTrue);
      expect(large.equalsTo(large.copyWith(width: 1e9 + 0.002)), isFalse);
    });

    test('handles NaN, infinities and signed zero explicitly', () {
      final a = box().copyWith(left: double.nan);
      expect(a.equalsTo(a.copyWith()), isTrue);
      expect(a.equalsTo(box()), isFalse);
      final infinite = box().copyWith(width: double.infinity);
      expect(infinite.equalsTo(infinite.copyWith()), isTrue);
      expect(
        infinite.equalsTo(infinite.copyWith(width: double.negativeInfinity)),
        isFalse,
      );
      expect(infinite.equalsTo(box()), isFalse);
      expect(
        // Preserve negative zero explicitly to exercise signed-zero comparison.
        // ignore: prefer_int_literals
        box().copyWith(top: -0.0).equalsTo(box().copyWith(top: 0)),
        isTrue,
      );
    });

    test('compares the shared contract of a plugin subclass', () {
      final plugin = _PluginBox.row(
        'owner',
        left: 10,
        top: 20,
        width: 30,
        height: 40,
        row: 1,
      );
      expect(plugin.equalsTo(box()), isTrue);
      expect(box().equalsTo(plugin), isTrue);
    });
  });

  test('geometry is mutable; edges and center follow the current values', () {
    final box = LegendHitBox.row(left: 1, top: 2, width: 8, height: 6, row: 3);
    expect(box.row, 3);
    expect(box.col, isNull);
    expect(box.right, 9);
    expect(box.bottom, 8);
    expect(box.center, const Offset(5, 5));
    box
      ..left = 10
      ..height = 10;
    expect(box.right, 18);
    expect(box.bottom, 12);
    expect(box.center, const Offset(14, 7));
  });

  test(
    'contains preserves inclusive edges, tolerance, reversed bounds and NaN',
    () {
      final box = LegendHitBox.col(
        left: 10,
        top: 20,
        width: 8,
        height: 6,
        col: 1,
      );
      expect(box.contains(10, 20), isTrue);
      expect(box.contains(18, 26), isTrue);
      expect(box.contains(18 + 0.5e-6, 26), isTrue);
      expect(box.contains(18 + 2e-6, 26), isFalse);
      expect(box.contains(double.nan, 20), isFalse);
      box
        ..left = 18
        ..top = 26
        ..width = -8
        ..height = -6;
      expect(box.contains(10, 20), isTrue);
      expect(box.contains(14, 23), isTrue);
      box.width = double.nan;
      expect(box.contains(14, 23), isFalse);
    },
  );

  test('copyWith selects membership without retaining a conflicting index', () {
    final box = LegendHitBox.row(left: 1, top: 2, width: 8, height: 6, row: 3);
    expect(box.copyWith().equalsTo(box), isTrue);
    final column = box.copyWith(col: 2, width: 0);
    expect(column.row, isNull);
    expect(column.col, 2);
    expect(column.width, 0);
    expect(column.left, box.left);
    expect(column.copyWith(row: 4).row, 4);
    expect(column.copyWith(row: 4).col, isNull);
    expect(() => box.copyWith(row: 0, col: 0), throwsArgumentError);
    expect(() => box.copyWith(row: -1), throwsAssertionError);
    expect(() => box.copyWith(col: -1), throwsAssertionError);
    expect(box.row, 3);
    expect(box.width, 8);
  });

  test(
    'merge replaces the complete layout result through virtual copyWith',
    () {
      final box = _PluginBox.row(
        'owner',
        left: 1,
        top: 2,
        width: 8,
        height: 6,
        row: 3,
      );
      final other = LegendHitBox.col(
        left: 10,
        top: 20,
        width: 0,
        height: 60,
        col: 2,
      );
      expect(box.merge(null), same(box));
      final merged = box.merge(other);
      expect(merged, isA<_PluginBox>());
      expect((merged as _PluginBox).owner, 'owner');
      expect(merged.equalsTo(other), isTrue);
      expect(box.row, 3);
      expect(box.left, 1);
      expect(box.copyCalls, 1);
    },
  );

  testWidgets('pointer hits dispatch to plugin contains in order', (
    tester,
  ) async {
    LegendItem? clicked;
    final chart = acquireChart({
      'type': 'bar',
      'data': {
        'labels': ['x'],
        'datasets': [
          {
            'label': 'one',
            'data': [1],
          },
          {
            'label': 'two',
            'data': [2],
          },
        ],
      },
      'options': {
        'animation': false,
        'plugins': {
          'legend': {
            'onClick': (ChartEvent e, LegendItem item, LegendElement legend) =>
                clicked = item,
          },
        },
      },
    });
    final legend = chart.legend! as Legend;
    final first = _CustomHit(legend.legendHitBoxes.first, accepts: false);
    final second = _CustomHit(legend.legendHitBoxes[1], accepts: true);
    legend.legendHitBoxes = [first, second];
    final point = first.center;
    await triggerMouseEvent(chart, 'click', {'x': point.dx, 'y': point.dy});
    expect(clicked, same(legend.legendItems![1]));
    expect(first.calls, greaterThan(0));
    expect(second.calls, greaterThan(0));
    expect(legend.legendHitBoxes.first, same(first));
    final calls = first.calls + second.calls;
    clicked = null;
    await triggerMouseEvent(chart, 'click', {
      'x': legend.right + 10,
      'y': point.dy,
    });
    expect(clicked, isNull);
    expect(first.calls + second.calls, calls);
  });
}

class _CustomHit extends LegendHitBox {
  _CustomHit(LegendHitBox source, {required this.accepts})
    : super.row(
        left: source.left,
        top: source.top,
        width: source.width,
        height: source.height,
        row: source.row!,
      );
  final bool accepts;
  int calls = 0;

  @override
  bool contains(double x, double y) {
    calls++;
    return accepts;
  }
}

class _PluginBox extends LegendHitBox {
  _PluginBox.row(
    this.owner, {
    required super.left,
    required super.top,
    required super.width,
    required super.height,
    required super.row,
  }) : super.row();
  _PluginBox.col(
    this.owner, {
    required super.left,
    required super.top,
    required super.width,
    required super.height,
    required super.col,
  }) : super.col();
  final String owner;
  int copyCalls = 0;

  @override
  _PluginBox copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
    int? row,
    int? col,
  }) {
    copyCalls++;
    final copy = super.copyWith(
      left: left,
      top: top,
      width: width,
      height: height,
      row: row,
      col: col,
    );
    return copy.row != null
        ? _PluginBox.row(
            owner,
            left: copy.left,
            top: copy.top,
            width: copy.width,
            height: copy.height,
            row: copy.row!,
          )
        : _PluginBox.col(
            owner,
            left: copy.left,
            top: copy.top,
            width: copy.width,
            height: copy.height,
            col: copy.col!,
          );
  }
}
