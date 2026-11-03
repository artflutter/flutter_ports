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
/// text, its icon, its tooltip and its value. With an `icon`, the segment
/// shows the icon only.
typedef SegmentChoiceItem<T> = ({
  String key,
  String text,
  IconData? icon,
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
/// The label of each segment, or its icon when the item has one, has the
/// [ValueKey] of the `key` of its item. A tap on a segment selects its
/// value.
class SegmentChoice<T> extends StatelessWidget {
  /// Creates the control.
  const SegmentChoice({
    required this.items,
    required this.value,
    required this.onChanged,
    this.label,
    this.showLabels = false,
    this.labelAbove = false,
    this.minItemWidth,
    super.key,
  });

  /// The short name of the value, or `null` for none.
  final String? label;

  /// Show names alongside icons, hiding icons when space is tight.
  final bool showLabels;

  /// Put the field label above the choices instead of in the left gutter.
  final bool labelAbove;

  /// Wrap choices into aligned rows at this minimum logical width.
  /// Null retains the original single-row presentation.
  final double? minItemWidth;

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
    final choices = _segmentRows<T>(
      context: context,
      count: items.length,
      minItemWidth: minItemWidth,
      selected: {value},
      onChanged: (selected) {
        if (selected.isNotEmpty) onChanged(selected.single);
      },
      segments: (width) => [
        for (final item in items)
          ButtonSegment<T>(
            value: item.value,
            tooltip: item.tooltip,
            icon:
                item.icon != null &&
                    (!showLabels ||
                        width >=
                            112 *
                                MediaQuery.textScalerOf(context).scale(12) /
                                12)
                ? Icon(item.icon, key: ValueKey(item.key))
                : null,
            label: item.icon == null || showLabels
                ? Text(
                    item.text,
                    key:
                        item.icon != null &&
                            width >=
                                112 *
                                    MediaQuery.textScalerOf(context).scale(12) /
                                    12
                        ? null
                        : ValueKey(item.key),
                    style: showLabels ? theme.textTheme.labelMedium : null,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
          ),
      ],
    );
    if (labelAbove) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) ...[
            Text(label!, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
          ],
          choices,
        ],
      );
    }
    return Row(
      children: [
        if (label != null)
          SizedBox(
            width: 44,
            child: Text(label!, style: theme.textTheme.labelLarge),
          ),
        Expanded(child: choices),
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
  const SegmentToggles({
    required this.items,
    this.labels,
    this.minItemWidth,
    super.key,
  });

  /// Optional readable names for controls that otherwise show only icons.
  final Map<String, String>? labels;

  /// Optional minimum width before choices wrap to another aligned row.
  final double? minItemWidth;

  /// The segments.
  final List<SegmentToggleItem> items;

  /// Whether the option of [key] is on.
  bool isSelected(String key) =>
      items.any((item) => item.key == key && item.value);

  @override
  Widget build(BuildContext context) => _segmentRows<String>(
    context: context,
    count: items.length,
    minItemWidth: minItemWidth,
    multiSelection: true,
    segments: (_) => [
      for (final item in items)
        ButtonSegment<String>(
          value: item.key,
          tooltip: item.tooltip,
          icon: Icon(item.icon, key: ValueKey(item.key)),
          label: labels?[item.key] == null
              ? null
              : Text(
                  labels![item.key]!,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
        ),
    ],
    selected: {
      for (final item in items)
        if (item.value) item.key,
    },
    onChanged: (selected) {
      for (final item in items) {
        final on = selected.contains(item.key);
        if (on != item.value) item.onChanged(on);
      }
    },
  );
}

Widget _segmentRows<T>({
  required BuildContext context,
  required int count,
  required List<ButtonSegment<T>> Function(double width) segments,
  required Set<T> selected,
  required ValueChanged<Set<T>> onChanged,
  double? minItemWidth,
  bool multiSelection = false,
}) => LayoutBuilder(
  builder: (context, constraints) {
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final columns = minItemWidth == null || !constraints.hasBoundedWidth
        ? count
        : (constraints.maxWidth / (minItemWidth * scale)).floor().clamp(
            1,
            count,
          );
    final width = constraints.maxWidth / columns;
    final all = segments(width);
    final rows = <Widget>[];
    for (var i = 0; i < count; i += columns) {
      final row = all.sublist(i, (i + columns).clamp(0, count));
      final values = {for (final segment in row) segment.value};
      if (i > 0) rows.add(const SizedBox(height: 4));
      rows.add(
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: width * row.length,
            child: SegmentedButton<T>(
              style: _segmentStyle,
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              multiSelectionEnabled: multiSelection,
              emptySelectionAllowed: multiSelection || minItemWidth != null,
              segments: row,
              selected: minItemWidth == null
                  ? selected
                  : selected.intersection(values),
              onSelectionChanged: onChanged,
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  },
);

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
