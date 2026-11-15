// Original code, not ported from Chart.js: the live dashboard sample.

import 'package:chartjs_supabase_dashboard/src/dashboard_page.dart';
import 'package:chartjs_supabase_dashboard/src/supabase_metric_source.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The project URL, from `--dart-define-from-file=supabase.json`.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

/// The publishable key of the project, from the same file.
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

/// Starts Supabase and an anonymous session of this browser, then the
/// dashboard. The session stays in the storage of the browser: a reload
/// keeps it. The row level security of `supabase/schema.sql` gives the
/// session the shared history and its own rows only.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Chart.register(registerables);
  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    runApp(
      const _Message(
        'The app has no Supabase settings. Copy supabase.example.json to '
        'supabase.json, write the URL and the publishable key of the project '
        'into it, and run the app with --dart-define-from-file=supabase.json.',
      ),
    );
    return;
  }
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  final client = Supabase.instance.client;
  try {
    if (client.auth.currentSession == null) {
      await client.auth.signInAnonymously();
    }
  } on AuthException catch (error) {
    runApp(
      _Message(
        'The anonymous sign-in failed: ${error.message}. Turn on "Allow '
        'anonymous sign-ins" in the Auth settings of the Supabase project.',
      ),
    );
    return;
  }
  runApp(
    DashboardApp(
      source: SupabaseMetricSource(client),
      session: client.auth.currentUser?.id,
    ),
  );
}

/// A page with one message, for a run that cannot start the dashboard.
class const _Message(final String text) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(text)),
      ),
    ),
  );
}
