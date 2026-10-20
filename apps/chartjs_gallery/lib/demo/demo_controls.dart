import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:flutter/material.dart';

/// Lays out [children] in columns of equal width: one column on a phone,
/// up to [maxColumns] on a wide screen.
class DemoControlGrid extends StatelessWidget {
  /// Creates the grid.
  const DemoControlGrid({
    required this.children,
    this.minColumnWidth = 300,
    this.maxColumns = 3,
    super.key,
  });

  /// The controls.
  final List<Widget> children;

  /// The smallest width of a column.
  final double minColumnWidth;

  /// The largest count of columns.
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        final width = constraints.maxWidth;
        final columns = ((width + gap) / (minColumnWidth + gap)).floor().clamp(
          1,
          maxColumns,
        );
        final columnWidth = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: columnWidth, child: child),
          ],
        );
      },
    );
  }
}

/// A labelled slider with its value in monospace.
class SliderControl extends StatelessWidget {
  /// Creates the control. [sliderKey] keys the [Slider] itself.
  const SliderControl({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.format,
    this.sliderKey,
    super.key,
  });

  /// The name of the value.
  final String label;

  /// The value.
  final double value;

  /// The smallest value.
  final double min;

  /// The largest value.
  final double max;

  /// The count of steps, or `null` for a continuous slider.
  final int? divisions;

  /// Called with each new value; `null` disables the slider.
  final ValueChanged<double>? onChanged;

  /// Formats the value; the default shows it without decimals.
  final String Function(double value)? format;

  /// The key of the [Slider], for tests and automation.
  final Key? sliderKey;

  @override
  Widget build(BuildContext context) {
    final text = (format ?? (v) => v.toStringAsFixed(0))(value);
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            key: sliderKey,
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: text,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 52,
          child: Mono(text, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}

/// A row of filter chips that switch options on and off.
class ToggleChips extends StatelessWidget {
  /// Creates the chips: each entry has a key, a label, its value and the
  /// callback that toggles it.
  const ToggleChips({required this.toggles, super.key});

  /// The toggles.
  final List<
    ({String key, String label, bool value, ValueChanged<bool> onChanged})
  >
  toggles;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final toggle in toggles)
          FilterChip(
            key: ValueKey(toggle.key),
            label: Text(toggle.label),
            selected: toggle.value,
            onSelected: toggle.onChanged,
          ),
      ],
    );
  }
}

/// One segment of a [SegmentChoice]: the key of the segment, its short
/// text, its tooltip and its value.
typedef SegmentChoiceItem<T> = ({
  String key,
  String text,
  String tooltip,
  T value,
});

/// The compact style of [SegmentChoice] and [SegmentToggles].
final ButtonStyle _segmentStyle = SegmentedButton.styleFrom(
  visualDensity: VisualDensity.compact,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  padding: const EdgeInsets.symmetric(horizontal: 8),
);

/// A short [label] and a segmented button with one selected segment, at
/// the full width that it gets.
///
/// The label of each segment has the [ValueKey] of the `key` of its item. A
/// tap on a segment selects its value.
class SegmentChoice<T> extends StatelessWidget {
  /// Creates the control.
  const SegmentChoice({
    required this.items,
    required this.value,
    required this.onChanged,
    this.label,
    super.key,
  });

  /// The short name of the value, or `null` for none.
  final String? label;

  /// The segments.
  final List<SegmentChoiceItem<T>> items;

  /// The selected value.
  final T value;

  /// Called with the value of the tapped segment.
  final ValueChanged<T> onChanged;

  /// Whether the segment of [key] is the selected one.
  bool isSelected(String key) =>
      items.any((item) => item.key == key && item.value == value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (label != null)
          SizedBox(
            width: 44,
            child: Text(label!, style: theme.textTheme.labelLarge),
          ),
        Expanded(
          child: SegmentedButton<T>(
            style: _segmentStyle,
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            segments: [
              for (final item in items)
                ButtonSegment<T>(
                  value: item.value,
                  tooltip: item.tooltip,
                  label: Text(
                    item.text,
                    key: ValueKey(item.key),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            selected: {value},
            onSelectionChanged: (selected) => onChanged(selected.single),
          ),
        ),
      ],
    );
  }
}

/// One segment of a [SegmentToggles]: the key of the segment, its icon, its
/// tooltip, whether it is on, and the callback that switches it.
typedef SegmentToggleItem = ({
  String key,
  IconData icon,
  String tooltip,
  bool value,
  ValueChanged<bool> onChanged,
});

/// A segmented button of on/off options, at the full width that it gets:
/// each segment is an icon, and any count of segments can be on.
///
/// The icon of each segment has the [ValueKey] of the `key` of its item. A
/// tap on a segment switches its option.
class SegmentToggles extends StatelessWidget {
  /// Creates the control.
  const SegmentToggles({required this.items, super.key});

  /// The segments.
  final List<SegmentToggleItem> items;

  /// Whether the option of [key] is on.
  bool isSelected(String key) =>
      items.any((item) => item.key == key && item.value);

  @override
  Widget build(BuildContext context) => SegmentedButton<String>(
    style: _segmentStyle,
    showSelectedIcon: false,
    multiSelectionEnabled: true,
    emptySelectionAllowed: true,
    expandedInsets: EdgeInsets.zero,
    segments: [
      for (final item in items)
        ButtonSegment<String>(
          value: item.key,
          tooltip: item.tooltip,
          icon: Icon(item.icon, key: ValueKey(item.key)),
        ),
    ],
    selected: {
      for (final item in items)
        if (item.value) item.key,
    },
    onSelectionChanged: (selected) {
      for (final item in items) {
        final on = selected.contains(item.key);
        if (on != item.value) item.onChanged(on);
      }
    },
  );
}

/// A list of `name: value` lines in monospace.
class ReadoutTable extends StatelessWidget {
  /// Creates the readout.
  const ReadoutTable({required this.rows, super.key});

  /// The names and the values.
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 20,
      runSpacing: 4,
      children: [
        for (final (name, value) in rows)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$name ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontFamilyFallback: const [
                      'Menlo',
                      'Consolas',
                      'Roboto Mono',
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
