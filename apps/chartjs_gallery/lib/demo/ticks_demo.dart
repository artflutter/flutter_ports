// The reason of each import of lib/src is the comment above it.
// ignore_for_file: implementation_imports

import 'dart:math' as math;

import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show Tick, ticks;
// Not public: JsFunction and jsCall, the call of a formatter with a `this`.
import 'package:flutter_chartjs_port/src/js/js_function.dart'
    show JsFunction, jsCall;
// Not public: the interfaces types.Chart and types.Scale of the stand-ins.
import 'package:flutter_chartjs_port/src/types/index.dart' show Chart, Scale;

/// The locales of the locale menu.
const List<String> tickLocales = ['en-US', 'de-DE', 'fr-FR', 'ru-RU', 'ja-JP'];

/// The `chart` of the `this` object: the formatters read only
/// `chart.options.locale`. The same stand-in as the ported spec
/// `test/specs/core.ticks_test.dart` uses, until `core.controller` lands.
final class _DemoChart implements Chart {
  _DemoChart(this.options);

  @override
  final Map<String, Object?> options;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The scale that the formatters get as `this`: they read only `chart` and
/// `options.ticks.format`.
final class _DemoScale implements Scale {
  _DemoScale(this.chart, this.options);

  @override
  final Chart chart;

  @override
  final Map<String, Object?> options;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A tick `{value, significand}`. Linear ticks have no significand.
final class _DemoTick implements Tick {
  const _DemoTick(this.value, [this.significand]);

  @override
  final double value;

  @override
  final double? significand;
}

/// One tick range of the tab.
typedef _Range = ({String title, String note, bool log, List<Tick> ticks});

/// Linear ticks `i * step / scale` for `i` in 0..[count]: an exact division,
/// so that 0.3 is 0.3 and not 0.30000000000000004.
List<Tick> _linear(int count, double step, double scale) => [
  for (var i = 0; i <= count; i++) _DemoTick(i * step / scale),
];

/// Logarithmic ticks from 1 to [maxExp] as `scale.logarithmic.js`
/// `generateTicks` makes them for `{min: 1, max: 10^maxExp}`: the
/// significands 1..10, 15, then 2..10, 15 in each next decade.
List<Tick> _logarithmic(int maxExp) {
  final max = math.pow(10, maxExp).toDouble();
  final result = <Tick>[];
  var exp = 0;
  var significand = 1.0;
  var value = 1.0;
  while (value < max) {
    result.add(_DemoTick(value, significand));
    if (significand >= 10) {
      significand = significand < 15 ? 15 : 20;
    } else {
      significand++;
    }
    if (significand >= 20) {
      exp++;
      significand = 2;
    }
    value = (significand * math.pow(10, exp)).roundToDouble();
  }
  result.add(_DemoTick(max, significand));
  return result;
}

final List<_Range> _ranges = [
  (
    title: 'Linear 0 … 1, step 0.1',
    note: 'delta 0.1 → one decimal',
    log: false,
    ticks: _linear(10, 1, 10),
  ),
  (
    title: 'Linear 0 … 1,000,000, step 100,000',
    note: 'grouping separators of the locale',
    log: false,
    ticks: _linear(10, 100000, 1),
  ),
  (
    title: 'Linear 0 … 1e-7, step 1e-8',
    note: 'max tick < 1e-4 → scientific notation',
    log: false,
    ticks: _linear(10, 1, 100000000),
  ),
  (
    title: 'Linear -0.5 … 0.5, step 0.05',
    note: 'delta 0.05 → two decimals (-floor(log10 delta))',
    log: false,
    ticks: [for (var i = -10; i <= 10; i++) _DemoTick(i / 20)],
  ),
  (
    title: 'Logarithmic 1 … 1e9',
    note:
        'labels only for significands 1, 2, 3, 5, 10, 15 and the last 20% '
        'of ticks; the others are empty strings',
    log: true,
    ticks: _logarithmic(9),
  ),
];

/// Tick labels of the ported `core.ticks` formatters `numeric` and
/// `logarithmic`, through `helpers.intl` `formatNumber`.
///
/// The formatters are [JsFunction] values that read `this`, the scale. The
/// tab calls them with [jsCall] and a stand-in scale as `thisArg`, as
/// `core.scale.js` calls the tick callback. The locale menu sets
/// `chart.options.locale`.
class TicksDemo extends StatefulWidget {
  /// Creates the tick labels tab.
  const TicksDemo({super.key});

  @override
  State<TicksDemo> createState() => _TicksDemoState();
}

class _TicksDemoState extends State<TicksDemo> {
  String _locale = 'en-US';

  @override
  Widget build(BuildContext context) {
    final scale = _DemoScale(
      _DemoChart(<String, Object?>{'locale': _locale}),
      <String, Object?>{
        'ticks': <String, Object?>{'format': <String, Object?>{}},
      },
    );
    final formatters = ticks['formatters']! as Map<String, Object?>;
    return DemoPageBody(
      children: [
        DemoCard(
          title: 'Locale',
          source:
              "jsCall(ticks['formatters']['numeric' | 'logarithmic'], "
              '[value, index, ticks], thisArg: scale)',
          child: Wrap(
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('chart.options.locale'),
              DropdownButton<String>(
                key: const ValueKey('ticks.locale'),
                value: _locale,
                items: [
                  for (final l in tickLocales)
                    DropdownMenuItem(value: l, child: Text(l)),
                ],
                onChanged: (v) => setState(() => _locale = v ?? _locale),
              ),
            ],
          ),
        ),
        for (final range in _ranges)
          DemoCard(
            title: range.title,
            source: '${range.log ? 'logarithmic' : 'numeric'} · ${range.note}',
            child: _TickLabels(
              ticks: range.ticks,
              label: (index) => jsCall(
                formatters[range.log ? 'logarithmic' : 'numeric'],
                [range.ticks[index].value, index.toDouble(), range.ticks],
                thisArg: scale,
              ),
            ),
          ),
      ],
    );
  }
}

/// The ticks of a range as chips `value → label`.
class _TickLabels extends StatelessWidget {
  const _TickLabels({required this.ticks, required this.label});

  final List<Tick> ticks;
  final Object? Function(int index) label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < ticks.length; i++)
          Builder(
            builder: (context) {
              final text = label(i);
              final empty = text == '';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: empty
                      ? theme.colorScheme.surfaceContainerLow
                      : theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      jsNumberText(ticks[i].value),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      empty ? "''" : '$text',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: empty ? theme.colorScheme.outline : null,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
