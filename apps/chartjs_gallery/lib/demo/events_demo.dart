// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The demo imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:chartjs_gallery/demo/canvas_demo.dart'
    show chartColors, labelColor;
import 'package:chartjs_gallery/demo/demo_chart.dart';
import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs/src/helpers/index.dart'
    show drawPoint, getParentNode, getRelativePosition, renderText, toFont;
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/platform/chart_host.dart'
    show addCanvasEventListener, removeCanvasEventListener;
import 'package:flutter_chartjs/src/platform/index.dart'
    show BasicPlatform, FlutterPlatform;
import 'package:flutter_chartjs/src/platform/native_event.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;

/// The event types of the demo chart: the Chart.js default `events` option
/// (`core.defaults`), plus `mousedown`, `mouseup`, `touchend` and `wheel`.
final List<String> eventsDemoTypes = [
  for (final type in defaults['events']! as List<Object?>) type! as String,
  'mousedown',
  'mouseup',
  'touchend',
  'wheel',
];

/// One delivered event of the log.
typedef _LogEntry = ({
  String native,
  String type,
  double x,
  double y,
  int touches,
});

/// The chart host and the Flutter platform: input events, sizing and the
/// device pixel ratio.
///
/// A demo chart registers `FlutterPlatform` listeners for [eventsDemoTypes].
/// The host turns Flutter pointer events into DOM events, and the platform
/// delivers them through one throttled proxy per type: the events of one
/// type coalesce to one in each frame. The chart draws a crosshair at the
/// position of `getRelativePosition`.
class EventsDemo extends StatefulWidget {
  /// Creates the events tab.
  const EventsDemo({super.key});

  @override
  State<EventsDemo> createState() => _EventsDemoState();
}

class _EventsDemoState extends State<EventsDemo> {
  DemoChart? _chart;
  HTMLCanvasElement? _canvas;

  /// Bumped when the readout changes, without a rebuild of the page.
  final ValueNotifier<int> _readout = ValueNotifier(0);

  final List<_LogEntry> _log = [];
  final List<Offset> _trail = [];
  Offset? _hit;
  int _pointerEvents = 0;
  int _domEvents = 0;
  int _delivered = 0;

  double _widthFraction = 1;
  double _height = 260;
  bool _maintainAspectRatio = false;

  static const int _logLength = 8;

  @override
  void dispose() {
    final canvas = _canvas;
    if (canvas != null) {
      for (final type in eventsDemoTypes) {
        removeCanvasEventListener(canvas, type, _onDomEvent);
      }
    }
    _readout.dispose();
    super.dispose();
  }

  void _onChart(DemoChart chart) {
    _chart = chart;
    final canvas = _canvas = chart.canvas;
    // A second listener on the canvas counts the DOM events of the host
    // before the throttled proxies of the platform coalesce them.
    if (canvas != null) {
      for (final type in eventsDemoTypes) {
        addCanvasEventListener(canvas, type, _onDomEvent);
      }
    }
    _readout.value++;
  }

  void _onDomEvent(NativeEvent event) {
    _domEvents++;
  }

  void _onEvent(types.ChartEvent event) {
    final chart = _chart;
    final native = event.native;
    if (chart == null || native == null) {
      return;
    }
    _delivered++;
    final position = getRelativePosition(native, chart);
    final x = position.x ?? double.nan;
    final y = position.y ?? double.nan;
    _log.insert(0, (
      native: native.type,
      type: event.type,
      x: x,
      y: y,
      touches: native.touches.length,
    ));
    if (_log.length > _logLength) _log.removeLast();
    // The host sends mouseout with the finite exit position, so the leave
    // types come first.
    if (native.type == 'mouseout' ||
        native.type == 'touchend' ||
        !x.isFinite ||
        !y.isFinite) {
      _hit = null;
      _trail.clear();
    } else {
      _hit = Offset(x, y);
      if (event.type == 'mousemove') {
        _trail.insert(0, _hit!);
        if (_trail.length > 24) _trail.removeLast();
      }
    }
    chart.render();
    _readout.value++;
  }

  void _draw(DemoChart chart, CanvasRenderingContext2D ctx) {
    final w = chart.width;
    final h = chart.height;
    // A 40 px grid.
    ctx
      ..strokeStyle = 'rgba(0, 0, 0, 0.08)'
      ..lineWidth = 1
      ..beginPath();
    for (var x = 40.0; x < w; x += 40) {
      ctx
        ..moveTo(x + 0.5, 0)
        ..lineTo(x + 0.5, h);
    }
    for (var y = 40.0; y < h; y += 40) {
      ctx
        ..moveTo(0, y + 0.5)
        ..lineTo(w, y + 0.5);
    }
    ctx.stroke();
    final small = toFont(<String, Object?>{'size': 12});
    renderText(
      ctx,
      [
        'chart ${jsNumberToString(w)} x ${jsNumberToString(h)}',
        'canvas ${chart.canvas?.width} x ${chart.canvas?.height} px',
      ],
      8,
      8,
      small,
      const TextOpts(color: labelColor, textBaseline: 'top'),
    );

    // The last coalesced mousemove positions.
    for (var i = _trail.length - 1; i >= 0; i--) {
      final alpha = (1 - i / _trail.length) * 0.5;
      ctx.fillStyle = 'rgba(54, 162, 235, ${alpha.toStringAsFixed(2)})';
      drawPoint(
        ctx,
        const PointOptions(pointStyle: 'circle', radius: 3, borderWidth: 0),
        _trail[i].dx,
        _trail[i].dy,
      );
    }

    final hit = _hit;
    if (hit == null) {
      return;
    }
    ctx
      ..strokeStyle = 'rgba(255, 99, 132, 0.8)'
      ..lineWidth = 1
      ..setLineDash([5, 4])
      ..beginPath()
      ..moveTo(0, hit.dy)
      ..lineTo(w, hit.dy)
      ..moveTo(hit.dx, 0)
      ..lineTo(hit.dx, h)
      ..stroke()
      ..setLineDash([])
      ..fillStyle = 'rgba(255, 99, 132, 0.35)'
      ..strokeStyle = '#FF6384'
      ..lineWidth = 2;
    drawPoint(
      ctx,
      const PointOptions(pointStyle: 'circle', radius: 8, borderWidth: 2),
      hit.dx,
      hit.dy,
    );
    drawPoint(
      ctx,
      const PointOptions(pointStyle: 'crossRot', radius: 14, borderWidth: 2),
      hit.dx,
      hit.dy,
    );
    final right = hit.dx > w - 120;
    renderText(
      ctx,
      '(${jsNumberToString(hit.dx)}, ${jsNumberToString(hit.dy)})',
      hit.dx + (right ? -16 : 16),
      hit.dy - 12,
      toFont(<String, Object?>{'size': 13, 'weight': 'bold'}),
      TextOpts(
        color: chartColors[1],
        textAlign: right ? 'right' : 'left',
        textBaseline: 'bottom',
      ),
    );
  }

  /// One line of the log. A long text fades out at the end of its column,
  /// because a second line would not fit the 20 px row.
  static Widget _logText(String text) => Mono(
    text,
    style: const TextStyle(fontSize: 12.5),
    softWrap: false,
    overflow: TextOverflow.fade,
    maxLines: 1,
  );

  /// One row of the log. Below 400 px, the name columns are narrower and
  /// the position has no `x=` and `y=` labels.
  static Widget _logRow(_LogEntry e, {required bool narrow}) {
    final x = jsNumberToString(e.x);
    final y = jsNumberToString(e.y);
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          SizedBox(width: narrow ? 76 : 92, child: _logText(e.native)),
          _logText('→ '),
          SizedBox(width: narrow ? 72 : 84, child: _logText(e.type)),
          Expanded(
            child: _logText(
              narrow
                  ? 'touches=${e.touches} $x,$y'
                  : 'touches=${e.touches} x=$x y=$y',
            ),
          ),
        ],
      ),
    );
  }

  /// A device pixel ratio with at most 4 decimals: the web engine gives a
  /// float32 value such as 2.6249998807907104.
  static String _ratio(double v) =>
      jsNumberToString(double.parse(v.toStringAsFixed(4)));

  String _size(double v) => v.isFinite ? jsNumberToString(v) : 'Infinity';

  Widget _buildReadout(BuildContext context) {
    final chart = _chart;
    final canvas = chart?.canvas;
    final container = canvas == null ? null : getParentNode(canvas);
    final style = canvas?.style;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Column(
      key: const ValueKey('events.readout'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReadoutTable(
          rows: [
            (
              'platform',
              switch (chart?.platform) {
                null => '-',
                FlutterPlatform() => 'FlutterPlatform',
                BasicPlatform() => 'BasicPlatform',
                _ => 'BasePlatform',
              },
            ),
            ('MediaQuery DPR', _ratio(dpr)),
            (
              'getDevicePixelRatio()',
              chart == null
                  ? '-'
                  : _ratio(chart.platform.getDevicePixelRatio()),
            ),
            (
              'currentDevicePixelRatio',
              chart == null ? '-' : _ratio(chart.currentDevicePixelRatio),
            ),
            (
              'canvas.width x height',
              canvas == null ? '-' : '${canvas.width} x ${canvas.height}',
            ),
            (
              'display size (style)',
              style == null
                  ? '-'
                  : '${style.getPropertyValue('width')} x '
                        '${style.getPropertyValue('height')}',
            ),
            (
              'container',
              container == null
                  ? '-'
                  : '${_size(container.contentWidth)} x '
                        '${_size(container.contentHeight)}',
            ),
            (
              'chart.width x height',
              chart == null
                  ? '-'
                  : '${jsNumberToString(chart.width)} x '
                        '${jsNumberToString(chart.height)}',
            ),
            (
              'crosshair',
              switch (_hit) {
                null => 'none',
                final hit =>
                  '(${jsNumberToString(hit.dx)}, '
                      '${jsNumberToString(hit.dy)})',
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          key: const ValueKey('events.counters'),
          spacing: 12,
          runSpacing: 8,
          children: [
            _Counter(
              label: 'Flutter pointer events',
              value: _pointerEvents,
              color: chartColors[6],
            ),
            _Counter(
              label: 'DOM events from the host',
              value: _domEvents,
              color: chartColors[0],
            ),
            _Counter(
              label: 'ChartEvents delivered',
              value: _delivered,
              color: chartColors[1],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Last events (DOM name → Chart.js type)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        SizedBox(
          key: const ValueKey('events.log'),
          height: _logLength * 20.0,
          child: _log.isEmpty
              ? Text(
                  'Move the mouse, tap, drag or scroll on the chart.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 400;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final e in _log) _logRow(e, narrow: narrow),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DemoPageBody(
      children: [
        DemoCard(
          title: 'Input events',
          source:
              'ChartHost → NativeEvent → FlutterPlatform.addEventListener '
              '(throttled proxy per type) → fromNativeEvent → '
              'getRelativePosition',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Events: ${eventsDemoTypes.join(', ')}. A vertical drag on '
                'the chart still scrolls this page (the host claims no '
                'drag) and the chart gets touchmove; a tap gives click.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth * _widthFraction;
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: width,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Listener(
                        onPointerDown: (_) => _pointerEvents++,
                        onPointerMove: (_) => _pointerEvents++,
                        onPointerUp: (_) => _pointerEvents++,
                        onPointerHover: (_) => _pointerEvents++,
                        onPointerSignal: (_) => _pointerEvents++,
                        child: DemoCanvas(
                          key: const ValueKey('events.host'),
                          height: _maintainAspectRatio ? null : _height,
                          events: eventsDemoTypes,
                          onEvent: _onEvent,
                          onChart: _onChart,
                          onResize: () => _readout.value++,
                          draw: _draw,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<int>(
                valueListenable: _readout,
                builder: (context, _, _) => _buildReadout(context),
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'Container size and device pixel ratio',
          source:
              'helpers.dom: getMaximumSize(canvas, width, height, '
              'aspectRatio) · retinaScale(chart, devicePixelRatio, true)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DemoControlGrid(
                children: [
                  SliderControl(
                    label: 'width',
                    sliderKey: const ValueKey('events.width'),
                    value: _widthFraction * 100,
                    min: 30,
                    max: 100,
                    divisions: 14,
                    format: (v) => '${v.toStringAsFixed(0)}%',
                    onChanged: (v) => setState(() => _widthFraction = v / 100),
                  ),
                  SliderControl(
                    label: 'height',
                    sliderKey: const ValueKey('events.height'),
                    value: _height,
                    min: 120,
                    max: 480,
                    divisions: 36,
                    onChanged: _maintainAspectRatio
                        ? null
                        : (v) => setState(() => _height = v),
                  ),
                ],
              ),
              SwitchListTile(
                key: const ValueKey('events.maintainAspectRatio'),
                contentPadding: EdgeInsets.zero,
                title: const Text('maintainAspectRatio (aspectRatio: 2)'),
                subtitle: const Text(
                  'On: the height is unbounded and getMaximumSize gives '
                  'width / 2. Off: the chart fills a box of the given height.',
                ),
                value: _maintainAspectRatio,
                onChanged: (v) => setState(() => _maintainAspectRatio = v),
              ),
              Text(
                'retinaScale sets the canvas render size to the display size '
                'times the device pixel ratio, and the display size as the '
                'canvas style; the readout above shows both.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final String color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final swatch = cssColor(color) ?? theme.colorScheme.primary;
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: swatch.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: swatch, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: theme.textTheme.titleLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
