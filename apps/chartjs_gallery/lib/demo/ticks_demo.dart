// The reason of each import of lib/src is the comment above it.
// ignore_for_file: implementation_imports

import 'dart:math' as math;

import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show Tick, ticks;
// Not public: the interfaces types.Chart and types.Scale of the stand-ins.
import 'package:flutter_chartjs_port/src/types/index.dart' show Chart, Scale;
import 'package:material_ui/material_ui.dart';

/// The locales of the locale menu.
const List<Locale> tickLocales = [
  Locale('en', 'US'),
  Locale('de', 'DE'),
  Locale('fr', 'FR'),
  Locale('ru', 'RU'),
  Locale('ja', 'JP'),
];

/// The `chart` of the `this` object: the formatters read only
/// `chart.options.locale`. The same stand-in as the ported spec
/// `test/specs/core.ticks_test.dart` uses, until `core.controller` lands.
final class _DemoChart(@override final Map<String, Object?> options)
    implements Chart {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The scale that the formatters get as `this`: they read only `chart` and
/// `options.ticks.format`.
final class _DemoScale(
  @override final Chart chart,
  @override final Map<String, Object?> options,
) implements Scale {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One tick range of the tab.
typedef _Range = ({String title, String note, bool log, List<Tick> ticks});

/// Linear ticks `i * step / scale` for `i` in 0..[count]: an exact division,
/// so that 0.3 is 0.3 and not 0.30000000000000004.
List<Tick> _linear(int count, double step, double scale) => [
  for (var i = 0; i <= count; i++) Tick(value: i * step / scale),
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
    result.add(Tick(value: value, significand: significand));
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
  result.add(Tick(value: max, significand: significand));
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
    ticks: [for (var i = -10; i <= 10; i++) Tick(value: i / 20)],
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
/// The formatters are tick callbacks: the scale is the first argument. The
/// tab calls them with a stand-in scale, as `core.scale.js` calls the tick
/// callback. The locale menu sets `chart.options.locale`.
class const TicksDemo({super.key}) extends StatefulWidget {
  /// Creates the tick labels tab.
  this;

  @override
  State<TicksDemo> createState() => _TicksDemoState();
}

class _TicksDemoState() extends State<TicksDemo> {
  Locale _locale = const Locale('en', 'US');

  @override
  Widget build(BuildContext context) {
    final scale = _DemoScale(
      _DemoChart(<String, Object?>{'locale': _locale}),
      <String, Object?>{'ticks': <String, Object?>{}},
    );
    final formatters = ticks['formatters']!;
    return DemoPageBody(
      children: [
        DemoCard(
          title: 'Locale',
          source:
              "ticks['formatters']['numeric' | 'logarithmic'](scale, value, "
              'index, ticks)',
          child: Wrap(
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('chart.options.locale'),
              DropdownButton<Locale>(
                key: const ValueKey('ticks.locale'),
                value: _locale,
                items: [
                  for (final l in tickLocales)
                    DropdownMenuItem(value: l, child: Text(l.toLanguageTag())),
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
              label: (index) =>
                  formatters[range.log ? 'logarithmic' : 'numeric']!(
                    scale,
                    range.ticks[index].value,
                    index,
                    range.ticks,
                  )?.join('\n'),
            ),
          ),
      ],
    );
  }
}

/// The ticks of a range as chips `value → label`.
class const _TickLabels({
  required final List<Tick> ticks,
  required final Object? Function(int index) label,
}) extends StatelessWidget {
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
