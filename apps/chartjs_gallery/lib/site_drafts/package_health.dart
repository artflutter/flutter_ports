// Original code, not ported from Chart.js: package health snapshots.
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// A checked public-metadata snapshot, shared across the cards of one page.
class PackageHealthSnapshot {
  /// Creates a snapshot from the refresh tool's JSON.
  PackageHealthSnapshot.fromJson(Map<String, Object?> json)
    : checkedAt = DateTime.parse(json['checked_at']! as String),
      packages = (json['packages']! as Map<String, Object?>).map(
        (key, value) => MapEntry(key, value! as Map<String, Object?>),
      );

  /// When the source APIs were queried, in UTC.
  final DateTime checkedAt;

  /// Package-level activity and explicitly repository-level issue/PR counts.
  final Map<String, Map<String, Object?>> packages;

  /// Loads the bundled snapshot without making runtime API requests.
  static Future<PackageHealthSnapshot> load() async {
    final source = await rootBundle.loadString(
      'assets/site_drafts/package_stats.json',
    );
    return PackageHealthSnapshot.fromJson(
      jsonDecode(source) as Map<String, Object?>,
    );
  }
}

/// Compact, responsive project-health metrics with provenance and scope.
class PackageHealth extends StatelessWidget {
  /// Shows [package]'s metrics from the shared [snapshot].
  const PackageHealth({
    required this.package,
    required this.snapshot,
    required this.onSource,
    super.key,
  });

  /// The pub.dev package name, including unpublished workspace package names.
  final String package;

  /// The page's shared metadata load.
  final Future<PackageHealthSnapshot> snapshot;

  /// Opens a reviewable source destination.
  final void Function(String title, String description, String url) onSource;

  String _date(Object? value) {
    if (value is! String) return 'Unknown';
    final date = DateTime.tryParse(value)?.toUtc();
    if (date == null) return 'Unknown';
    return date.toIso8601String().substring(0, 10);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageHealthSnapshot>(
    future: snapshot,
    builder: (context, result) {
      final data = result.data?.packages[package];
      if (data == null) {
        return Text(
          result.connectionState == ConnectionState.waiting
              ? 'Loading project activity…'
              : 'Project activity unavailable',
          style: const TextStyle(fontSize: 11),
        );
      }
      final repo = data['repository']! as String;
      final path = data['activity_path']! as String;
      final repoUrl = 'https://github.com/$repo';
      final commitsUrl =
          '$repoUrl/commits?${Uri(queryParameters: {
            if (path.isNotEmpty) 'path': path,
          }).query}';
      // dart2wasm of Dart 3.14.0-315.3.beta traps on a String switch over a
      // value that is neither null nor a String. Such a value switches as null
      // and takes the default branch, as before.
      final status = data['release_status'];
      final release = switch (status is String ? status : null) {
        'published' =>
          '${data['release_version']} · '
              '${_date(data['release_date'])}',
        'unpublished' => 'Not published',
        _ => 'Unknown',
      };
      final checked = result.data!.checkedAt.toUtc();
      final stale = DateTime.now().toUtc().difference(checked).inDays > 7;
      final checkedText = checked
          .toIso8601String()
          .substring(0, 16)
          .replaceAll('T', ' ');
      final scope = path.isEmpty ? '' : ', filtered to $path';
      final count = data['commits_90d'];
      final activity = count == null ? 'Unknown' : '$count commits / 90 days';
      final muted = Theme.of(context).colorScheme.onSurfaceVariant;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _metric(context, 'Last update', _date(data['last_commit'])),
              _metric(context, 'Activity', activity),
              _metric(context, 'Latest release', release),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => onSource(
                  'Open issues',
                  'Open issues for $repo. '
                      'Pull requests are counted separately. '
                      'These totals cover the whole repository.',
                  '$repoUrl/issues?q=is%3Aissue+is%3Aopen',
                ),
                icon: const Icon(Icons.adjust, size: 14),
                label: Text('${data['open_issues'] ?? '—'} issues'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => onSource(
                  'Open pull requests',
                  'Open pull requests for $repo, including drafts. '
                      'These totals cover the whole repository.',
                  '$repoUrl/pulls?q=is%3Apr+is%3Aopen',
                ),
                icon: const Icon(Icons.merge, size: 14),
                label: Text('${data['open_prs'] ?? '—'} PRs'),
              ),
              TextButton(
                onPressed: () => onSource(
                  'Activity sources',
                  'Last update and 90-day commit activity come from GitHub’s '
                      'default branch$scope. '
                      'Commits include documentation and maintenance. '
                      'Latest release is the pub.dev latest-version record: '
                      'https://pub.dev/packages/$package. '
                      'Unknown values mean the source could not be checked.',
                  commitsUrl,
                ),
                child: const Text('Sources'),
              ),
            ],
          ),
          Text(
            path.isEmpty
                ? 'Activity, issues & PRs: repository-wide'
                : 'Activity: this package · Issues & PRs: shared repository',
            style: TextStyle(fontSize: 10, color: muted, height: 1.5),
          ),
          Text(
            '${stale ? 'Older snapshot' : 'Checked'}: '
            '$checkedText UTC · '
            '${count == null ? 'Activity unavailable' : 'Trailing 90 days'}',
            style: TextStyle(fontSize: 10, color: muted, height: 1.5),
          ),
        ],
      );
    },
  );

  Widget _metric(BuildContext context, String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
