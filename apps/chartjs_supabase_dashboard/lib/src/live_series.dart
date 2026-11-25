// Original code, not ported from Chart.js: the live series of the dashboard.

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:chartjs_supabase_dashboard/src/metric_source.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The rows of the chart: the newest page first, the older pages on demand,
/// and each insert of the realtime channel. It also asks the table for a
/// new row in each slot of [pumpInterval] while [pumping] is true: the
/// database makes the value (`MetricSource.pump`).
///
/// A page is the rows of one cell of a grid of [pageSpan] in the time since
/// the epoch, so the page splits are at uniform times. A cell with no row
/// gives no page: the next page is the cell of the newest row before it.
///
/// A gap of more than [gapThreshold] between two rows breaks the line: the
/// chart data has a point with no value there. The chart joins the two rows
/// with a dashed line when the gap is at most [dashThreshold].
final class LiveSeries(
  /// The table.
  final MetricSource source, {

  /// The span of a page, the step of the grid of the pages. The default is
  /// 1000 slots of 5 seconds: the shared history and the rows of one
  /// session have at most one row in a slot, so a page has at most 1000
  /// rows, the largest response of the Supabase API.
  final Duration pageSpan = const Duration(seconds: 5000),

  /// The slot of the pump: `pump_metric` of `supabase/schema.sql` gives a
  /// session at most one row in each slot of 5 seconds. The pump sends in
  /// the middle of each slot of the clock of this device, so that a small
  /// offset from the clock of the database still gives one row in each
  /// slot.
  final Duration pumpInterval = const Duration(seconds: 5),

  /// The longest time between two rows that the line joins.
  final Duration gapThreshold = const Duration(hours: 1),

  /// The longest time between two rows that a dashed line joins, across a
  /// gap of more than [gapThreshold]. Rows farther apart have no line
  /// between them.
  final Duration dashThreshold = const Duration(hours: 2),
}) extends ChangeNotifier {
  /// Creates the series of [source].
  this;

  /// The rows in the order of their ids.
  final List<MetricPoint> _rows = [];
  final Set<int> _ids = {};

  /// The chart data: a new List after each change, so that a new config
  /// of the chart updates it. Each point has the time in milliseconds since
  /// the epoch as its x, in the order of the time: the chart reads the List
  /// with `parsing: false`, with no parse of a row.
  List<DataPoint> get points => _points;
  List<DataPoint> _points = const [];

  /// The number of rows in memory.
  int get rowCount => _rows.length;

  /// The time of the oldest row, or Dart `null` with no row.
  DateTime? get oldest => _rows.isEmpty ? null : _rows.first.ts;

  /// The time of the newest row, or Dart `null` with no row.
  DateTime? get newest => _rows.isEmpty ? null : _rows.last.ts;

  /// The longest of the last 20 delays from the `ts` of a realtime row to
  /// its arrival, in milliseconds, or Dart `null` before the first row. It
  /// also holds the offset of the clock of this device from the clock of
  /// the database: the chart reads `now - lagMs` as the newest time that
  /// all rows reached.
  double? get lagMs => _lags.isEmpty ? null : _lags.reduce(math.max);
  final List<double> _lags = [];

  /// The smallest and the largest value of the rows from [fromMs] to
  /// [toMs], with the row before and the row after them, or Dart `null`
  /// with no row. The times are milliseconds since the epoch.
  ({double min, double max})? extent(double fromMs, double toMs) {
    if (_rows.isEmpty) return null;
    var low = 0;
    var high = _rows.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_rows[mid].ts.millisecondsSinceEpoch < fromMs) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    var min = double.infinity;
    var max = double.negativeInfinity;
    for (var i = math.max(0, low - 1); i < _rows.length; i++) {
      final row = _rows[i];
      if (row.value < min) min = row.value;
      if (row.value > max) max = row.value;
      if (row.ts.millisecondsSinceEpoch > toMs) break;
    }
    return (min: min, max: max);
  }

  /// The number of pages of the history that the series loaded.
  int get pages => _pageStarts.length;

  /// The start of each page, the newest page first: a time of the grid of
  /// [pageSpan]. The rows from a page start to the next page start on its
  /// right came in that page.
  List<DateTime> get pageStarts => UnmodifiableListView(_pageStarts);
  final List<DateTime> _pageStarts = [];

  /// The start of the cell of the grid of [pageSpan] that holds [ts].
  DateTime _pageOf(DateTime ts) {
    final span = pageSpan.inMicroseconds;
    final time = ts.microsecondsSinceEpoch;
    return DateTime.fromMicrosecondsSinceEpoch(time - time % span, isUtc: true);
  }

  /// Loads the page of the newest row before [before], or of the newest row
  /// of the table when [before] is Dart `null`. Sets [reachedStart] when no
  /// row is before [before].
  Future<void> _loadPage(DateTime? before) async {
    final newest = await source.newestBefore(before);
    if (_disposed) return;
    if (newest == null) {
      _reachedStart = true;
      return;
    }
    final from = _pageOf(newest);
    final page = await source.between(from, before);
    if (_disposed) return;
    _pageStarts.add(from);
    _merge(page);
  }

  /// Whether the first page came.
  bool get ready => _ready;
  bool _ready = false;

  /// Whether a page of the history is on its way.
  bool get loadingOlder => _loadingOlder;
  bool _loadingOlder = false;

  /// Whether the series has the oldest row of the table.
  bool get reachedStart => _reachedStart;
  bool _reachedStart = false;

  /// The state of the realtime channel.
  LinkStatus get status => _status;
  LinkStatus _status = LinkStatus.connecting;

  /// Whether the pump sends values.
  bool get pumping => _pump != null;
  Timer? _pump;
  int _inFlight = 0;

  /// The number of values that this client sent.
  int get sent => _sent;
  int _sent = 0;

  /// The number of rows that the realtime channel gave.
  int get received => _received;
  int _received = 0;

  /// The time from the insert of the last value of this client to its row
  /// in the realtime channel, or Dart `null` before the first one.
  Duration? get roundTrip => _roundTrip;
  Duration? _roundTrip;
  final Map<int, DateTime> _sentAt = {};
  final Map<int, DateTime> _arrivedAt = {};

  /// The text of the last error, or Dart `null`.
  String? get error => _error;
  String? _error;

  bool _disposed = false;

  /// Starts the realtime channel, loads the newest page and starts the
  /// pump when [pump] is true. The channel starts first, so that no insert
  /// falls between the page and the channel.
  Future<void> start({bool pump = true}) async {
    source.watch(onInsert: _onInsert, onStatus: _onStatus);
    try {
      await _loadPage(null);
      if (_disposed) return;
      _ready = true;
      _error = null;
    } on Object catch (error) {
      _error = 'The first page failed: $error';
    }
    if (_disposed) return;
    _changed();
    if (pump) pumping = true;
  }

  /// Loads the page before the oldest page. It does nothing while a page is
  /// on its way and after the start of the data.
  Future<void> loadOlder() async {
    if (_loadingOlder || _reachedStart || !_ready || _pageStarts.isEmpty) {
      return;
    }
    _loadingOlder = true;
    _changed();
    try {
      await _loadPage(_pageStarts.last);
      if (_disposed) return;
      _error = null;
    } on Object catch (error) {
      _error = 'A page of the history failed: $error';
    } finally {
      _loadingOlder = false;
    }
    if (!_disposed) _changed();
  }

  /// Turns the pump on and off.
  set pumping(bool on) {
    if (on == pumping || _disposed) return;
    if (on) {
      _schedulePump();
    } else {
      _pump?.cancel();
      _pump = null;
    }
    _changed();
  }

  /// Sends in the middle of the next slot of [pumpInterval] of the clock of
  /// this device.
  void _schedulePump() {
    final slot = pumpInterval.inMicroseconds;
    var wait = slot ~/ 2 - clock.now().microsecondsSinceEpoch % slot;
    if (wait <= 0) wait += slot;
    _pump = Timer(Duration(microseconds: wait), () {
      _schedulePump();
      unawaited(_send());
    });
  }

  Future<void> _send() async {
    // A slow network gets at most 4 inserts at a time.
    if (_inFlight >= 4) return;
    _inFlight++;
    final start = DateTime.now();
    try {
      final id = await source.pump();
      if (_disposed || id == null) return;
      _sent++;
      final arrived = _arrivedAt.remove(id);
      if (arrived != null) {
        _roundTrip = arrived.difference(start);
      } else {
        _sentAt[id] = start;
      }
      _error = null;
    } on Object catch (error) {
      _error = 'An insert failed: $error';
    } finally {
      _inFlight--;
    }
    if (!_disposed) _changed();
  }

  void _onInsert(MetricPoint point) {
    if (_disposed) return;
    _received++;
    _lags.add(DateTime.now().difference(point.ts).inMicroseconds / 1000);
    if (_lags.length > 20) _lags.removeAt(0);
    final sentAt = _sentAt.remove(point.id);
    if (sentAt != null) {
      _roundTrip = DateTime.now().difference(sentAt);
    } else if (_inFlight > 0) {
      // The row came before the reply of its insert.
      _arrivedAt[point.id] = DateTime.now();
      if (_arrivedAt.length > 64) _arrivedAt.remove(_arrivedAt.keys.first);
    }
    _merge([point]);
    _changed();
  }

  void _onStatus(LinkStatus status) {
    if (_disposed || status == _status) return;
    _status = status;
    _changed();
  }

  /// Adds the rows that the series does not have, in the order of the ids,
  /// and gives the chart data a new List. Rows after the newest row and a
  /// page before the oldest row reuse the points that the List has: only
  /// the rows of another order make all points again.
  void _merge(List<MetricPoint> rows) {
    final fresh = [
      for (final row in rows)
        if (_ids.add(row.id)) row,
    ]..sort((a, b) => a.id.compareTo(b.id));
    if (fresh.isEmpty) return;
    if (_rows.isEmpty || fresh.first.id > _rows.last.id) {
      final previous = _rows.isEmpty ? null : _rows.last;
      _rows.addAll(fresh);
      _points = [..._points, ..._pointsOf(fresh, previous)];
    } else if (fresh.last.id < _rows.first.id) {
      final next = _rows.first;
      _rows.insertAll(0, fresh);
      final head = _pointsOf(fresh);
      if (_gapBetween(fresh.last, next)) head.add(_gapAfter(fresh.last));
      _points = [...head, ..._points];
    } else {
      for (final row in fresh) {
        _rows.insert(_lowerBound(row.id), row);
      }
      _points = _pointsOf(_rows);
    }
  }

  int _lowerBound(int id) {
    var low = 0;
    var high = _rows.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_rows[mid].id < id) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  bool _gapBetween(MetricPoint a, MetricPoint b) =>
      b.ts.difference(a.ts) > gapThreshold;

  /// The point with no value that breaks the line after [row].
  DataPoint _gapAfter(MetricPoint row) =>
      DataPoint(row.ts.millisecondsSinceEpoch + 1, null);

  /// The chart points of [rows]: a point with no value after each gap of
  /// more than [gapThreshold], also between [previous] and the first row.
  List<DataPoint> _pointsOf(List<MetricPoint> rows, [MetricPoint? previous]) {
    final points = <DataPoint>[];
    var last = previous;
    for (final row in rows) {
      if (last != null && _gapBetween(last, row)) points.add(_gapAfter(last));
      points.add(DataPoint(row.ts.millisecondsSinceEpoch, row.value));
      last = row;
    }
    return points;
  }

  /// The index of the first chart point at or after [ms] (milliseconds
  /// since the epoch), or the length of [points].
  int pointIndexAt(double ms) {
    var low = 0;
    var high = _points.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_points[mid].x! < ms) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _pump?.cancel();
    _pump = null;
    unawaited(source.dispose());
    super.dispose();
  }
}
