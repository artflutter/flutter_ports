// Original code, not ported from Chart.js: native legend item contracts.
@TestOn('vm')
library;

import 'dart:ui' show Color, StrokeCap, StrokeJoin, TextAlign;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copyWith preserves omitted fields and leaves the source unchanged', () {
    final lines = ['first', 'second'];
    final dash = [2.0, 3.0];
    final item = LegendItem(
      text: lines,
      hidden: true,
      datasetIndex: 2,
      lineDash: dash,
      lineWidth: 3,
      fillStyle: const ChartPaint.solid(Color(0xff123456)),
    );
    final copy = item.copyWith(hidden: false, lineWidth: 0);
    expect(copy, isNot(same(item)));
    expect(copy.text, same(lines));
    expect(copy.lineDash, same(dash));
    expect(copy.fillStyle, same(item.fillStyle));
    expect(copy.datasetIndex, 2);
    expect(copy.hidden, isFalse);
    expect(copy.lineWidth, 0);
    expect(item.hidden, isTrue);
    expect(item.lineWidth, 3);
    copy.datasetIndex = null;
    expect(copy.datasetIndex, isNull);
    expect(item.datasetIndex, 2);
  });

  test('merge inherits nullable fields and unchanged paints', () {
    final base = LegendItem(
      text: ['base'],
      hidden: true,
      datasetIndex: 2,
      lineWidth: 4,
      fillStyle: const ChartPaint.solid(Color(0xffff0000)),
      strokeStyle: const ChartPaint.solid(Color(0xff000000)),
    );
    final other = LegendItem(
      text: ['override'],
      lineWidth: 0,
      strokeStyle: const ChartPaint.solid(Color(0xff0000ff)),
    );
    final result = base.merge(other);
    expect(base.merge(null), same(base));
    expect(result.text, same(other.text));
    expect(result.hidden, isFalse);
    expect(result.lineWidth, 0);
    expect(result.datasetIndex, 2);
    expect(result.fillStyle, same(base.fillStyle));
    expect(result.strokeStyle, same(other.strokeStyle));
    expect(base.text, ['base']);
    expect(base.hidden, isTrue);
  });

  test('merge dispatches to a plugin copyWith override', () {
    final item = _PluginItem('plugin', text: ['original']);
    final merged = item.merge(LegendItem(text: ['replacement'], hidden: true));
    expect(merged, isA<_PluginItem>());
    expect((merged as _PluginItem).owner, 'plugin');
    expect(merged.text, ['replacement']);
    expect(merged.hidden, isTrue);
    expect(item.copyCalls, 1);
  });

  for (final reverse in [false, true]) {
    testWidgets(
      'plugin item identity through filter, sort and click: $reverse',
      (tester) async {
        final a = _PluginItem('first', text: ['first'])..datasetIndex = 0;
        final b = _PluginItem('second', text: ['second'])..datasetIndex = 1;
        final filtered = <LegendItem>[];
        final compared = <LegendItem>[];
        LegendItem? clicked;
        final chart = acquireChart({
          'type': 'bar',
          'data': {
            'labels': ['x'],
            'datasets': [
              {
                'label': 'first',
                'data': [1],
              },
              {
                'label': 'second',
                'data': [2],
              },
            ],
          },
          'options': {
            'animation': false,
            'plugins': {
              'legend': {
                'reverse': reverse,
                'labels': {
                  'generateLabels': (Chart chart) => [a, b],
                  'filter': (LegendItem item, Object data) {
                    filtered.add(item);
                    return true;
                  },
                  'sort': (LegendItem x, LegendItem y, Object data) {
                    compared.addAll([x, y]);
                    return x.datasetIndex!.compareTo(y.datasetIndex!);
                  },
                },
                'onClick':
                    (ChartEvent event, LegendItem item, LegendElement legend) {
                      clicked = item;
                      item.hidden = true;
                    },
              },
            },
          },
        });
        expect(
          chart.legend!.legendItems,
          reverse ? [same(b), same(a)] : [same(a), same(b)],
        );
        expect(filtered, isNotEmpty);
        expect(compared, isNotEmpty);
        expect(
          filtered.every((i) => identical(i, a) || identical(i, b)),
          isTrue,
        );
        expect(
          compared.every((i) => identical(i, a) || identical(i, b)),
          isTrue,
        );
        final hit = chart.legend!.legendHitBoxes.first;
        await triggerMouseEvent(chart, 'click', {
          'x': hit.left + hit.width / 2,
          'y': hit.top + hit.height / 2,
        });
        expect(clicked, same(reverse ? b : a));
        expect(clicked!.hidden, isTrue);
        expect(a.copyCalls + b.copyCalls, 0);
      },
    );
  }

  testWidgets('an invalid item is rejected even with a hidden legend', (
    tester,
  ) async {
    expect(
      () => acquireChart({
        'type': 'bar',
        'data': {
          'labels': ['x'],
          'datasets': [
            {
              'data': [1],
            },
          ],
        },
        'options': {
          'animation': false,
          'plugins': {
            'legend': {
              'display': false,
              'labels': {
                'generateLabels': (Chart chart) => [
                  {'text': 'map'},
                ],
              },
            },
          },
        },
      }),
      throwsA(isA<TypeError>()),
    );
  });
}

class _PluginItem(final String owner, {required super.text})
    extends LegendItem {
  int copyCalls = 0;

  @override
  _PluginItem copyWith({
    List<String>? text,
    ChartPaint? fillStyle,
    ChartPaint? fontColor,
    bool? hidden,
    StrokeCap? lineCap,
    List<double>? lineDash,
    double? lineDashOffset,
    StrokeJoin? lineJoin,
    double? lineWidth,
    ChartPaint? strokeStyle,
    PointStyle? pointStyle,
    double? rotation,
    TextAlign? textAlign,
    TRBLCorners? borderRadius,
    int? datasetIndex,
    int? index,
  }) {
    copyCalls++;
    final copied = super.copyWith(
      text: text,
      fillStyle: fillStyle,
      fontColor: fontColor,
      hidden: hidden,
      lineCap: lineCap,
      lineDash: lineDash,
      lineDashOffset: lineDashOffset,
      lineJoin: lineJoin,
      lineWidth: lineWidth,
      strokeStyle: strokeStyle,
      pointStyle: pointStyle,
      rotation: rotation,
      textAlign: textAlign,
      borderRadius: borderRadius,
      datasetIndex: datasetIndex,
      index: index,
    );
    return _PluginItem(owner, text: copied.text)
      ..fillStyle = copied.fillStyle
      ..fontColor = copied.fontColor
      ..hidden = copied.hidden
      ..lineCap = copied.lineCap
      ..lineDash = copied.lineDash
      ..lineDashOffset = copied.lineDashOffset
      ..lineJoin = copied.lineJoin
      ..lineWidth = copied.lineWidth
      ..strokeStyle = copied.strokeStyle
      ..pointStyle = copied.pointStyle
      ..rotation = copied.rotation
      ..textAlign = copied.textAlign
      ..borderRadius = copied.borderRadius
      ..datasetIndex = copied.datasetIndex
      ..index = copied.index;
  }
}
