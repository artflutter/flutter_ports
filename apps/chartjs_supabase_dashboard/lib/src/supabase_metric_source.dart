// Original code, not ported from Chart.js: the Supabase data source.

// The typed table access API of supabase_flutter 3 is still experimental.
// ignore_for_file: experimental_member_use

import 'dart:async';

import 'package:chartjs_supabase_dashboard/src/metric_source.dart';
import 'package:chartjs_supabase_dashboard/supabase_schema.g.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The table `metric_points` of a Supabase project (`supabase/schema.sql`),
/// through the typed API of `lib/supabase_schema.g.dart`: PostgREST for the
/// pages and the inserts, and Realtime for the inserts of all clients.
final class SupabaseMetricSource(
  /// The client of the project.
  final SupabaseClient client,
) implements MetricSource {
  /// Creates the source on [client].
  this;

  /// The columns of the chart: the pages and the realtime inserts read the
  /// same columns, so one mapping reads both. The column `owner` stays on
  /// the server.
  static const List<PostgrestStoredColumn<MetricPointsRow, Object>> _columns = [
    MetricPoints.id,
    MetricPoints.ts,
    MetricPoints.value,
  ];

  static MetricPoint _point(PostgrestPartialRow<MetricPointsRow> row) =>
      MetricPoint(id: row.id, ts: row.ts, value: row.value);

  RealtimeChannel? _channel;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  Future<List<MetricPoint>> newest(int limit) async {
    final rows = await client
        .table(MetricPoints.table)
        .selectOnly(_columns)
        .order(MetricPoints.id.desc())
        .limit(limit);
    return [for (final row in rows) _point(row)];
  }

  @override
  Future<List<MetricPoint>> olderThan(int id, int limit) async {
    final rows = await client
        .table(MetricPoints.table)
        .selectOnly(_columns)
        .where(MetricPoints.id.lt(id))
        .order(MetricPoints.id.desc())
        .limit(limit);
    return [for (final row in rows) _point(row)];
  }

  /// The function of supabase/schema.sql makes the value of the row.
  @override
  Future<int?> pump() => client.rpc.pumpMetric();

  @override
  void watch({
    required void Function(MetricPoint point) onInsert,
    required void Function(LinkStatus status) onStatus,
  }) {
    onStatus(LinkStatus.connecting);
    final channel = _channel = client.channel('public:metric_points');
    // Each listener comes before subscribe().
    _subscriptions
      ..add(
        channel
            .onTableChangesOnly(
              MetricPoints.table,
              columns: _columns,
              event: PostgresChangeEvent.insert,
            )
            .listen((change) {
              if (change case TypedPostgresInsert(:final newRow)) {
                onInsert(_point(newRow));
              }
            }),
      )
      ..add(
        channel.onStatusChange.listen(
          (change) => onStatus(switch (change.status) {
            RealtimeSubscribeStatus.subscribed => LinkStatus.live,
            RealtimeSubscribeStatus.channelError ||
            RealtimeSubscribeStatus.closed ||
            RealtimeSubscribeStatus.timedOut => LinkStatus.down,
          }),
        ),
      );
    channel.subscribe();
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    final channel = _channel;
    _channel = null;
    if (channel != null) await client.removeChannel(channel);
  }
}
