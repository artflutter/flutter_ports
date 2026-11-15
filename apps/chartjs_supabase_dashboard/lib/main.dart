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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Chart.register(registerables);
  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    runApp(const _MissingConfig());
    return;
  }
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  runApp(DashboardApp(source: SupabaseMetricSource(Supabase.instance.client)));
}

/// The page of a run without the Supabase settings.
class const _MissingConfig() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'The app has no Supabase settings. Copy supabase.example.json '
            'to supabase.json, write the URL and the publishable key of the '
            'project into it, and run the app with '
            '--dart-define-from-file=supabase.json.',
          ),
        ),
      ),
    ),
  );
}
