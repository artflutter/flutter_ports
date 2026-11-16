// Original code, not ported from Chart.js: the dashboard data source.

/// One row of the table `metric_points`.
final class const MetricPoint({
  /// The primary key. The ids grow with [ts].
  required final int id,

  /// The start of the slot of 5 seconds of the row, set by the database.
  required final DateTime ts,

  /// The value.
  required final double value,
}) {
  /// Creates a row.
  this;
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

  /// The time of the newest row before [before], or of the newest row of
  /// the table when [before] is Dart `null`. Dart `null` is the start of
  /// the data: no row is before [before].
  Future<DateTime?> newestBefore(DateTime? before);

  /// The rows from [from] to [before], without [before], or all rows from
  /// [from] when [before] is Dart `null`.
  Future<List<MetricPoint>> between(DateTime from, DateTime? before);

  /// Asks the table for the row of this session in the current slot of 5
  /// seconds: the database makes the value, so that the rows of all clients
  /// give one line. Gives the id of the new row, or Dart `null` when the
  /// database skipped it: the session has the row of this slot, or all
  /// sessions reached their limit of rows in a slot.
  Future<int?> pump();

  /// Starts the realtime channel. [onInsert] gets each new row of each
  /// client, also of this one, and [onStatus] each state of the channel.
  void watch({
    required void Function(MetricPoint point) onInsert,
    required void Function(LinkStatus status) onStatus,
  });

  /// Stops the realtime channel.
  Future<void> dispose();
}
