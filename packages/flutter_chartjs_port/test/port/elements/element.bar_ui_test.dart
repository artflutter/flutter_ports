// Original code, not ported from Chart.js: BarElement on the dart:ui canvas.
@TestOn('vm')
library;

// flutter_test and dart:ui: the web legs cannot compile this file.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart';
import 'package:flutter_test/flutter_test.dart';

import '../canvas/pixel_compare.dart';
import '../helpers/rounded_rect_upstream.dart';

// The draw of the port against the upstream form of the same draw, on the
// dart:ui canvas. The port has two DIVERGES forms (differences.md):
// - adapt-rounded-rect-path: one roundRect call in place of the four arcs
//   and four lines of addRoundedRectPath;
// - adapt-bar-clip: no clip() when inflateAmount is 0.
// The upstream form replays the calls of the port with both translated
// back: each roundRect as the upstream arcs and lines, and the clip of the
// outer rectangle after its path.
//
// Thresholds: no pixel is fully opaque in one render and fully transparent
// in the other, and the inked areas differ by less than 1 %. On an edge,
// the clip multiplies the coverage c of a fill by the coverage c of the
// clip: an edge pixel differs by up to c - c² = 1/4 of a channel, 64 of
// 255. Where the border ring and the fill meet the outer edge, two fills
// and the anti-aliasing of the arc path add up to about 8 more (Chart.js
// ADR 0034). Two fills of other colors on an edge can also change the
// color of an opaque pixel a little.
//
// Each case runs twice (Chart.js ADR 0018, section 6): with plain Map
// options and with a BarOptions with the same entries.

const int _edge = 80;

/// [options] as they are: the plain Map form of the options.
Map<String, Object?> _plainOptions(Map<String, Object?> options) => options;

/// The two forms of the options of a bar (Chart.js ADR 0018, section 6): the
/// plain Map, and a [BarOptions] with the same entries in the same key
/// order.
const Map<String, Object Function(Map<String, Object?>)> _optionsForms = {
  'Map options': _plainOptions,
  'BarOptions': BarOptions.new,
};

/// [cfg] with its `options` Map in the form [form].
Map<String, Object?> _withOptions(
  Map<String, Object?> cfg,
  Object Function(Map<String, Object?>) form,
) => {
  for (final MapEntry(:key, :value) in cfg.entries)
    key: key == 'options' && value is Map<String, Object?>
        ? form(value)
        : value,
};

/// The options of the stress bars of the gallery: a border of 1 and a
/// radius of 4.
Map<String, Object?> _cfg(Map<String, Object?> extra) => {
  'horizontal': false,
  'x': 40.3,
  'y': 20.6,
  'base': 110.2,
  'width': 31.7,
  'height': 89.6,
  'options': <String, Object?>{
    'borderColor': 'rgba(54, 162, 235, 1)',
    'backgroundColor': 'rgba(54, 162, 235, 0.5)',
    'borderWidth': 1,
    'borderRadius': 4,
  },
  'borderSkipped': <String, Object?>{'bottom': true},
  'enableBorderRadius': true,
  'inflateAmount': 0,
  ...extra,
};

/// Replays the [calls] of a draw on [ctx] in the upstream form: each
/// roundRect as the upstream arcs and lines (adapt-rounded-rect-path), and,
/// when [clipAfterOuter], a clip after the first rectangle
/// (adapt-bar-clip).
void _replayUpstream(
  List<ContextCall> calls,
  UiCanvasContext ctx, {
  required bool clipAfterOuter,
}) {
  var shapes = 0;
  for (final call in calls) {
    final args = call['args']! as List<Object?>;
    double at(int i) => args[i]! as double;
    switch (call['name']) {
      case 'save':
        ctx.save();
      case 'restore':
        ctx.restore();
      case 'beginPath':
        ctx.beginPath();
      case 'rect':
        ctx.rect(at(0), at(1), at(2), at(3));
      case 'roundRect':
        replayRoundRectAsUpstream(ctx, at(0), at(1), at(2), at(3), args[4]);
      case 'clip':
        ctx.clip(args[0], args[1] as String?);
      case 'setFillStyle':
        ctx.fillStyle = args[0];
      case 'fill':
        ctx.fill(args[0], args[1] as String?);
      default:
        fail('unexpected call ${call['name']}');
    }
    if (call['name'] == 'rect' || call['name'] == 'roundRect') {
      shapes++;
      if (clipAfterOuter && shapes == 1) ctx.clip();
    }
  }
}

Future<void> _expectUpstreamPixels(Map<String, Object?> cfg) async {
  final recorder = createMockContext();
  BarElement(cfg).draw(recorder);
  final calls = recorder.getCalls();
  final fills = calls.where((call) => call['name'] == 'fill').length;
  final bar = BarElement(cfg);
  final port = await renderContext(
    (ctx) {
      ctx.setTransform(2.625, 0, 0, 2.625, 0, 0);
      bar.draw(ctx);
    },
    width: 400,
    height: 400,
  );
  final upstream = await renderContext(
    (ctx) {
      ctx.setTransform(2.625, 0, 0, 2.625, 0, 0);
      _replayUpstream(
        calls,
        ctx,
        clipAfterOuter: fills == 2 && bar.inflateAmount == 0,
      );
    },
    width: 400,
    height: 400,
  );
  final diff = comparePixels(port, upstream);
  final reason = '$cfg: $diff';
  expect(diff.inkA, greaterThan(1000), reason: reason);
  expect(diff.opaqueFlips, 0, reason: reason);
  expect(diff.maxChannel, lessThanOrEqualTo(_edge), reason: reason);
  expect(diff.inkRatio, lessThan(0.01), reason: reason);
}

void main() {
  for (final MapEntry(key: name, value: form) in _optionsForms.entries) {
    /// [_expectUpstreamPixels] with the options of [cfg] in the form of
    /// this group.
    Future<void> expectUpstreamPixels(Map<String, Object?> cfg) =>
        _expectUpstreamPixels(_withOptions(cfg, form));

    group('the draw of the port and the upstream form, $name', () {
      test('a bar with a border of 1 and a radius of 4', () async {
        await expectUpstreamPixels(_cfg({}));
      });

      test('a bar with a radius object and borders of other widths', () async {
        await expectUpstreamPixels(
          _cfg({
            'options': <String, Object?>{
              'borderColor': 'red',
              'backgroundColor': 'blue',
              'borderWidth': <String, Object?>{
                'top': 3,
                'right': 1,
                'bottom': 0,
                'left': 6,
              },
              'borderRadius': <String, Object?>{
                'topLeft': 9,
                'topRight': 9,
                'bottomLeft': 9,
                'bottomRight': 9,
              },
            },
            'borderSkipped': <String, Object?>{},
          }),
        );
      });

      test('a bar with a border and no radius', () async {
        await expectUpstreamPixels(
          _cfg({
            'options': <String, Object?>{
              'borderColor': 'red',
              'backgroundColor': 'blue',
              'borderWidth': 2,
              'borderRadius': 0,
            },
          }),
        );
      });

      test('a horizontal bar with the left edge skipped', () async {
        await expectUpstreamPixels(
          _cfg({
            'horizontal': true,
            'x': 120.4,
            'y': 50.2,
            'base': 10.1,
            'height': 24.3,
            'borderSkipped': <String, Object?>{'left': true},
          }),
        );
      });

      test('a bar with inflateAmount 0.33 keeps the clip', () async {
        await expectUpstreamPixels(_cfg({'inflateAmount': 0.33}));
      });

      test('a bar with a radius and no border', () async {
        await expectUpstreamPixels(
          _cfg({
            'options': <String, Object?>{
              'backgroundColor': 'green',
              'borderWidth': 0,
              'borderRadius': 6,
            },
          }),
        );
      });
    });
  }
}
