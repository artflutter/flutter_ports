import 'package:chart_benchmark_lab/benchmark/controller.dart';
import 'package:chart_benchmark_lab/benchmark/ranking.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

const _bestColor = Color(0xff15803d);
const _winnerRow = Color(0xfff0fdf4);

/// The saved captures, best first in each setup, with the winner marked.
///
/// A click on a column header sorts by that column. The first click puts the
/// best value first.
class ResultsTable extends StatefulWidget {
  /// Creates the table for [results].
  const ResultsTable({
    required this.results,
    required this.currentKey,
    super.key,
  });

  /// The captures to compare.
  final List<BenchmarkResult> results;

  /// The comparison key of the current window. A row with another key comes
  /// from another size, pixel ratio or display rate.
  final String currentKey;

  @override
  State<ResultsTable> createState() => _ResultsTableState();
}

class _ResultsTableState extends State<ResultsTable> {
  int _column = 0;
  bool _ascending = true;
  late List<RankedResult> _ranked = rankResults(widget.results);
  late String? _summary = winnerSummary(_ranked);
  late bool _otherWindow = _hasOtherWindow();

  /// The last result of [build]. The same instance stops a rebuild of the rows,
  /// which a resize and the filter of the page would otherwise repeat.
  Widget? _built;

  bool _hasOtherWindow() =>
      widget.results.any((r) => r.comparisonKey != widget.currentKey);

  @override
  void didUpdateWidget(covariant ResultsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.results, widget.results)) {
      _ranked = rankResults(widget.results);
      _summary = winnerSummary(_ranked);
      _built = null;
    }
    final otherWindow = _hasOtherWindow();
    if (otherWindow != _otherWindow) {
      _otherWindow = otherWindow;
      _built = null;
    }
  }

  /// The header, the direction of the first click and the sort value of each
  /// column. A null value keeps the rank order.
  static final List<
    ({
      String label,
      bool numeric,
      bool firstAscending,
      Comparable<Object?>? Function(RankedResult) value,
    })
  >
  _columns = [
    (label: '#', numeric: false, firstAscending: true, value: (_) => null),
    (
      label: 'Library',
      numeric: false,
      firstAscending: true,
      value: (r) => r.result.library.label,
    ),
    (
      label: 'Setup',
      numeric: false,
      firstAscending: true,
      value: (r) =>
          '${r.result.config.type.label} '
          '${r.result.config.count.toString().padLeft(9, '0')} '
          '${r.result.durationSeconds.toString().padLeft(4, '0')}',
    ),
    _metric('FPS', RankMetric.fps),
    (
      label: 'Vs best',
      numeric: true,
      firstAscending: true,
      value: (r) => r.slowerBy ?? 1.0,
    ),
    _metric('Frame p90', RankMetric.frame),
    _metric('UI p90', RankMetric.ui),
    _metric('Raster p90', RankMetric.raster),
    _metric('Over budget', RankMetric.overBudget),
  ];

  static ({
    String label,
    bool numeric,
    bool firstAscending,
    Comparable<Object?>? Function(RankedResult) value,
  })
  _metric(String label, RankMetric metric) => (
    label: label,
    numeric: true,
    firstAscending: !metric.higherIsBetter,
    value: (r) => metric.of(r.result.metrics),
  );

  void _sort(int column) => setState(() {
    _built = null;
    if (_column == column) {
      _ascending = !_ascending;
    } else {
      _column = column;
      _ascending = _columns[column].firstAscending;
    }
  });

  List<RankedResult> _sorted(List<RankedResult> rows) {
    final value = _columns[_column].value;
    final index = {for (final (i, r) in rows.indexed) r: i};
    int byValue(RankedResult a, RankedResult b) {
      final x = value(a);
      final y = value(b);
      return x == null || y == null ? 0 : x.compareTo(y);
    }

    return List<RankedResult>.of(rows)..sort((a, b) {
      final order = byValue(a, b);
      if (order != 0) return _ascending ? order : -order;
      final place = index[a]!.compareTo(index[b]!);
      // The rank column has no value, so its direction applies here.
      return value(a) == null && !_ascending ? -place : place;
    });
  }

  Widget _value(RankedResult row, RankMetric metric) => Text(
    metric.shown(row.result.metrics),
    style: row.best.contains(metric)
        ? const TextStyle(color: _bestColor, fontWeight: FontWeight.w700)
        : null,
  );

  @override
  Widget build(BuildContext context) => _built ??= _table();

  Widget _table() {
    final summary = _summary;
    final otherWindow = _otherWindow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary != null)
          Container(
            key: const ValueKey('results.summary'),
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _winnerRow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffbbf7d0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 20,
                  color: Color(0xffb7791f),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        if (otherWindow)
          const Padding(
            key: ValueKey('results.otherWindow'),
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Some rows come from another chart size, pixel ratio or display '
              'rate. Their figures do not compare, so each one ranks apart.',
              style: TextStyle(color: Color(0xff64748b), fontSize: 12),
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // A sideways scroll moves the finished layer of the table.
          child: RepaintBoundary(
            child: DataTable(
              columnSpacing: 22,
              horizontalMargin: 8,
              sortColumnIndex: _column,
              sortAscending: _ascending,
              columns: [
                for (final (i, column) in _columns.indexed)
                  DataColumn(
                    label: Text(column.label),
                    numeric: column.numeric,
                    onSort: (_, _) => _sort(i),
                  ),
              ],
              rows: [
                // A key moves a row in a sort, with its finished text layout.
                for (final row in _sorted(_ranked))
                  DataRow(
                    key: ObjectKey(row.result),
                    color: row.winner
                        ? const WidgetStatePropertyAll(_winnerRow)
                        : null,
                    cells: [
                      DataCell(
                        row.winner
                            ? const Icon(
                                Icons.emoji_events,
                                key: ValueKey('results.winner'),
                                size: 20,
                                color: Color(0xffb7791f),
                              )
                            : Text('${row.rank}'),
                      ),
                      DataCell(
                        Text(
                          row.result.library.label,
                          style: TextStyle(
                            color: row.result.library.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${row.result.config.type.label} · '
                          '${_count(row.result.config.count)} · '
                          '${row.result.durationSeconds}s'
                          '${otherWindow ? ' · ${_size(row.result)}' : ''}',
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 64,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _value(row, RankMetric.fps),
                              const SizedBox(height: 3),
                              SizedBox(
                                height: 4,
                                width: double.infinity,
                                child: CustomPaint(
                                  painter: _FpsBarPainter(
                                    row.fpsShare,
                                    row.result.library.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Text(switch (row.slowerBy) {
                          final times? => '${times.toStringAsFixed(1)}× slower',
                          null => row.winner ? 'best' : '—',
                        }),
                      ),
                      DataCell(_value(row, RankMetric.frame)),
                      DataCell(_value(row, RankMetric.ui)),
                      DataCell(_value(row, RankMetric.raster)),
                      DataCell(_value(row, RankMetric.overBudget)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The share of the best FPS, as a bar on a track. It draws two shapes, with no
/// clip: the table stays on screen in each frame of a run.
class _FpsBarPainter extends CustomPainter {
  const _FpsBarPainter(this.share, this.color);

  final double share;
  final Color color;

  static const _radius = Radius.circular(2);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, _radius),
      Paint()..color = const Color(0xffe2e8f0),
    );
    if (share <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & Size(size.width * share, size.height),
        _radius,
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_FpsBarPainter oldDelegate) =>
      oldDelegate.share != share || oldDelegate.color != color;
}

String _size(BenchmarkResult result) =>
    '${result.viewport.width.round()}×${result.viewport.height.round()}';

String _count(int value) => value >= 1000
    ? '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k'
    : '$value';
