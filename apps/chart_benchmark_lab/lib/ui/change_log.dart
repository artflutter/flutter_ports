// Each entry is one long text, split over lines of the source.
// ignore_for_file: no_adjacent_strings_in_list

import 'package:material_ui/material_ui.dart';

/// One dated group of changes that a lab run can show.
class const ChangeLogEntry(
  /// The day of the changes, as `YYYY-MM-DD`.
  final String date,

  /// The changes, in plain words, with the figures that they gave.
  final List<String> items,
) {
  /// A group of [items], as of [date].
  this;
}

/// The changes that affect what this lab measures, newest first. Add a line
/// when a change of the library or of the lab moves a figure. The full records
/// are in `doc/performance.md` of the Chart.js port.
const List<ChangeLogEntry> changeLog = [
  ChangeLogEntry('2026-11-13', [
    'Lab: a ninth chart type, Sankey, with one flow for each item between '
        'nodes in three columns. Only the Chart.js port has it, through the '
        'port of chartjs-chart-sankey: fl_chart, Graphic and Syncfusion have '
        'no sankey chart, and the lab shows that in place of a chart. The '
        'sankey chart takes the raw config of the port, so each tick of new '
        'data is a full update. It has no axes, no zoom and no shadow.',
  ]),
  ChangeLogEntry('2026-11-10', [
    'Lab: a Zoom and pan setting for line, bar, scatter and bubble charts. '
        'Each library zooms and pans only the x axis through its public API, '
        'inside the data and at most 100 times: a touch pinch or the mouse '
        'wheel zooms, and a drag pans. A trackpad of the native desktop app '
        'differs: its pinch zooms fl_chart and Graphic, and it does not zoom '
        'the Chart.js port. '
        'The Chart.js port uses the port of chartjs-plugin-zoom. A run '
        'without zoom is unchanged, and so is its comparison key.',
  ]),
  ChangeLogEntry('2026-11-06', [
    'Web: the lab now has one page for each Flutter channel, on the newest '
        'build of stable, of beta and of master. Figures of different pages do '
        'not compare, because each page has its own engine. The header shows '
        'the Flutter version, and the bottom of the page shows the lab '
        'version.',
    'Lab page: each section now builds and paints on its own, so that a chart '
        'frame, a scroll and a readout no longer record the page around them. '
        'An idle chart stays mounted through a resize, and a load mounts it '
        'once. With 24 saved rows, a resize went from 42 to 60 FPS in Firefox '
        'and from 52 to 60 FPS in Safari. On a Pixel 8a, the UI time of a '
        'chart frame went from 2.3 to 1.1 ms, and its raster time from 2.4 to '
        '2.9 ms. Older exported captures can differ by this amount.',
    'Lab page: a browser load shows a splash in the color of the page, and no '
        'blank white page. The first paint in Chrome went from about 3.4 s to '
        'about 80 ms on a 20 Mbit/s connection.',
    'Web: long lines and their fills draw in small pieces. Line 5,000 full '
        'went from 3.5 to 120 FPS on WebAssembly, and from 3.8 to 82 FPS on '
        'JavaScript. A dense fill now has its true area: one draw missed it '
        'by up to 57%.',
    'Lab: the web build is on GitHub Pages. A small service worker adds the '
        'headers that rendering threads need, and the header of the page shows '
        'the mode. A browser that takes the JavaScript build has no threads.',
    'Lab: saved comparisons rank each setup, mark the winner and the best '
        'value of each column, and sort by a click on a column header. A '
        'resize keeps them in view, and rows of another chart size rank apart. '
        'Small differences are ties: 1% of FPS, 1 point of over budget, one '
        'display frame of frame p90 and 10% of the UI and raster work.',
    'Lab: on a phone, Run and Capture move the chart into view first, and the '
        'header shows icons and takes less height.',
    'Lab: a note that does not scroll says why a scroll or another outside '
        'cause stopped a test, and why a web page has its mode.',
    'Toolchain: Flutter 3.50.0-0.4.pre, the beta channel. Material comes from '
        'the package material_ui.',
    'Lab: the matrix runs in a browser and on phones, with a fixed CPU test in '
        'each row. New drivers measure first paint, animated updates, hover, '
        'resize, several series, stacked bars and time axes.',
    'Line draw: less repeated curve work, and one batch call for each marker. '
        'On macOS at 20,000 items, line full went from 101 to 116 FPS, scatter '
        'full from 117 to 120 FPS, and bubble full from 93 to 108 FPS.',
    'All chart types: a hidden legend waits for a read, loops read each option '
        'once, arcs and circles take native routes, and data-only updates skip '
        'the layout. On macOS, cells at 119 FPS or above went from 22 to 39 of '
        '48. Pie 20,000 full went from 2 to 84 FPS.',
  ]),
  ChangeLogEntry('2026-11-05', [
    'Lab: bubble, doughnut, polar area and radar join the matrix of all '
        'libraries.',
    'Lab: first version, with the Chart.js port, fl_chart, Graphic and '
        'Syncfusion through their public widgets.',
  ]),
];

/// The header button of the change log. It opens a dialog, so that the log
/// needs no scrolling and does not move the chart. It waits while a run is
/// active, because a dialog over the chart would disturb the frames of that
/// run.
class const ChangeLogButton({
  /// Whether a press opens the log.
  required final bool enabled,

  /// Whether the button shows only its icon, with a tooltip, as on a phone.
  final bool iconOnly = false,
  super.key,
}) extends StatelessWidget {
  /// Creates the button.
  this;

  @override
  Widget build(BuildContext context) {
    final open = enabled
        ? () => showDialog<void>(
            context: context,
            builder: (_) => const _ChangeLogDialog(),
          )
        : null;
    const key = ValueKey('changelog');
    return iconOnly
        ? IconButton(
            key: key,
            style: IconButton.styleFrom(
              fixedSize: const Size.square(36),
              minimumSize: const Size.square(36),
              padding: EdgeInsets.zero,
              iconSize: 20,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Change log',
            onPressed: open,
            icon: const Icon(Icons.history),
          )
        : TextButton.icon(
            key: key,
            onPressed: open,
            icon: const Icon(Icons.history),
            label: const Text('Change log'),
          );
  }
}

class const _ChangeLogDialog() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Change log'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in changeLog) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  entry.date,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              for (final item in entry.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• $item',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xff475569),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        key: const ValueKey('changelog.close'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    ],
  );
}
