// Original code, not ported from Chart.js: an in-memory table for the tests.

import 'dart:async';

import 'package:chartjs_supabase_dashboard/src/metric_source.dart';

/// The table `metric_points` in memory: row `id` has the time [start] plus
/// `id` seconds and the value `id % 100`. An insert gives the next id and
/// sends the row to the watcher in a microtask, as a realtime channel.
final class MemoryMetricSource({int rows = 0}) implements MetricSource {
  /// Creates a table with the rows 1 to [rows].
  this {
    for (var id = 1; id <= rows; id++) {
      _rows.add(_row(id, (id % 100).toDouble()));
    }
  }

  /// The time of row 0.
  static final DateTime start = DateTime.utc(2026, 11, 15, 12);

  final List<MetricPoint> _rows = [];
  void Function(MetricPoint point)? _onInsert;

  /// The number of calls of [newest] and [olderThan].
  int pageCalls = 0;

  /// Whether [dispose] ran.
  bool disposed = false;

  /// The rows in the order of their ids.
  List<MetricPoint> get rows => List.unmodifiable(_rows);

  MetricPoint _row(int id, double value) => MetricPoint(
    id: id,
    ts: start.add(Duration(seconds: id)),
    value: value,
  );

  /// Adds a row with [ts], as another client, and sends it to the watcher.
  void addRow(int id, DateTime ts, double value) {
    final row = MetricPoint(id: id, ts: ts, value: value);
    _rows.add(row);
    _onInsert?.call(row);
  }

  @override
  Future<List<MetricPoint>> newest(int limit) async {
    pageCalls++;
    return _rows.reversed.take(limit).toList();
  }

  @override
  Future<List<MetricPoint>> olderThan(int id, int limit) async {
    pageCalls++;
    return _rows.reversed.where((row) => row.id < id).take(limit).toList();
  }

  @override
  Future<int> insert(double value) async {
    final id = _rows.isEmpty ? 1 : _rows.last.id + 1;
    final row = _row(id, value);
    _rows.add(row);
    scheduleMicrotask(() => _onInsert?.call(row));
    return id;
  }

  @override
  void watch({
    required void Function(MetricPoint point) onInsert,
    required void Function(LinkStatus status) onStatus,
  }) {
    _onInsert = onInsert;
    onStatus(LinkStatus.connecting);
    scheduleMicrotask(() => onStatus(LinkStatus.live));
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    _onInsert = null;
  }
}
