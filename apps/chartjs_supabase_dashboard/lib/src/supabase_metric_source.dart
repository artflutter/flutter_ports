// Original code, not ported from Chart.js: the Supabase data source.

import 'package:chartjs_supabase_dashboard/src/metric_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The table `metric_points` of a Supabase project (`supabase/schema.sql`):
/// PostgREST for the pages and the inserts, and Realtime for the inserts of
/// all clients.
final class SupabaseMetricSource(
  /// The client of the project.
  final SupabaseClient client,
) implements MetricSource {
  /// Creates the source on [client].
  this;

  static const _table = 'metric_points';
  static const _columns = 'id, ts, value';

  RealtimeChannel? _channel;

  @override
  Future<List<MetricPoint>> newest(int limit) async {
    final rows = await client
        .from(_table)
        .select(_columns)
        .order('id', ascending: false)
        .limit(limit);
    return [for (final row in rows) MetricPoint.fromRow(row)];
  }

  @override
  Future<List<MetricPoint>> olderThan(int id, int limit) async {
    final rows = await client
        .from(_table)
        .select(_columns)
        .lt('id', id)
        .order('id', ascending: false)
        .limit(limit);
    return [for (final row in rows) MetricPoint.fromRow(row)];
  }

  @override
  Future<int?> pump() async {
    // The function of supabase/schema.sql makes the value of the row.
    final id = await client.rpc<Object?>('pump_metric');
    return (id as num?)?.toInt();
  }

  @override
  void watch({
    required void Function(MetricPoint point) onInsert,
    required void Function(LinkStatus status) onStatus,
  }) {
    onStatus(LinkStatus.connecting);
    _channel = client
        .channel('public:$_table')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: _table,
          callback: (payload) =>
              onInsert(MetricPoint.fromRow(payload.newRecord)),
        )
        .subscribe(
          (status, error) => onStatus(switch (status) {
            RealtimeSubscribeStatus.subscribed => LinkStatus.live,
            RealtimeSubscribeStatus.channelError ||
            RealtimeSubscribeStatus.closed ||
            RealtimeSubscribeStatus.timedOut => LinkStatus.down,
          }),
        );
  }

  @override
  Future<void> dispose() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) await client.removeChannel(channel);
  }
}
