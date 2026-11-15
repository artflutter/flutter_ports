// Original code, not ported from Chart.js: the dashboard data source.

/// One row of the table `metric_points`.
final class const MetricPoint({
  /// The primary key. The ids grow with [ts]: the pages go by id.
  required final int id,

  /// The time of the insert, set by the database.
  required final DateTime ts,

  /// The value.
  required final double value,
}) {
  /// Creates a row.
  this;

  /// Reads a row of PostgREST or of a realtime insert: `id` is a number,
  /// `ts` an ISO 8601 text and `value` a number.
  factory fromRow(Map<String, dynamic> row) => MetricPoint(
    id: (row['id'] as num).toInt(),
    ts: DateTime.parse(row['ts'] as String),
    value: (row['value'] as num).toDouble(),
  );
}

/// The state of the realtime channel.
enum LinkStatus() {
  /// The channel waits for its first reply.
  connecting,

  /// The channel gets each insert of the table.
  live,

  /// The channel failed, closed or timed out.
  down,
}

/// The table `metric_points` as the dashboard uses it: the pages of the
/// history, the insert of a value and the inserts of all clients.
abstract interface class MetricSource() {
  /// The constructor of a subclass.
  this;

  /// The newest [limit] rows, the newest first.
  Future<List<MetricPoint>> newest(int limit);

  /// The [limit] rows before the row [id], the newest first. An empty List
  /// is the start of the data.
  Future<List<MetricPoint>> olderThan(int id, int limit);

  /// Inserts [value] and gives the id of the new row.
  Future<int> insert(double value);

  /// Starts the realtime channel. [onInsert] gets each new row of each
  /// client, also of this one, and [onStatus] each state of the channel.
  void watch({
    required void Function(MetricPoint point) onInsert,
    required void Function(LinkStatus status) onStatus,
  });

  /// Stops the realtime channel.
  Future<void> dispose();
}
